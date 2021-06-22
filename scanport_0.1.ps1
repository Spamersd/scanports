$watch = [System.Diagnostics.Stopwatch]::StartNew()
$watch.Start() 
# Params 
$showempty = $false
$PathHostList = ".\IN.txt"
$PathPortList = ".\ports.txt"
$errorLOG = @()

class Hosts {
    $hostIP
    $port
}

function GetIPrange {
    param (
      [string]$start,
      [string]$stop
    )
    $IP_start = $start -split "\."
    $IP_stop = $stop -split "\."
  
    $ips = @()
    foreach ($okt0 in ($IP_start[0]..$IP_stop[0])) {   
    foreach ($okt1 in ($IP_start[1]..$IP_stop[1])) {
    foreach ($okt2 in ($IP_start[2]..$IP_stop[2])) {
    foreach ($okt3 in ($IP_start[3]..$IP_stop[3])) {
      $ips += "$okt0.$okt1.$okt2.$okt3"
    }}}}
    return $ips
    
  }

  function ConvertTo-IPv4MaskString {
    param(
      [Parameter(Mandatory = $true)]
      [ValidateRange(0, 32)]
      [Int] $MaskBits
    )
    $mask = ([Math]::Pow(2, $MaskBits) - 1) * [Math]::Pow(2, (32 - $MaskBits))
    $bytes = [BitConverter]::GetBytes([UInt32] $mask)
    (($bytes.Count - 1)..0 | ForEach-Object { [String] $bytes[$_] }) -join "."

}
$ips = @{}
$dt = @()
$ListPort = @();

foreach ($port in Get-Content $PathPortList) {
    if ($port -notmatch "^\d+$") {
     
        $errorLOG += "'$port' is not port"
        continue
        
    }
    $ListPort += $port
}

foreach ($line in Get-Content $PathHostList) {
    if ($line -match "([0-9]{1,3}[\.]){3}[0-9]{1,3}(?=\s|$)") {
        
        foreach ($port in  $ListPort) {
            $myhost = New-Object -TypeName Hosts
            $myhost.hostIP = $line
            $myhost.port = $port
            $dt += $myhost
        }
    }

    elseif ($line -match "([0-9]{1,3}[\.]){3}[0-9]{1,3}[\/][0-9]{2}(?=\s|$)") {
    
        $net = $line -split "/"
        $ip =[IPAddress]$net[0]
        $mask = [IPAddress](ConvertTo-IPv4MaskString $net[1])
        $net = [IPAddress]($ip.Address -band $mask.Address)
        $broad = [IPAddress]($ip.Address -bor (-bnot [uint]$mask.Address))
        $list = GetIPrange -start $net.IPAddressToString -stop $broad.IPAddressToString
        foreach ($ip in $list) {
            foreach ($port in  $ListPort) {
                $myhost = New-Object -TypeName Hosts
                $myhost.hostIP = $ip
                $myhost.port = $port
                $dt += $myhost
            }
        }
    }
    else {
    
        $errorLOG += "'$line' is not IP adress" 
        continue           
    
    }   
} 

$data = $dt | Foreach-Object -Parallel {
    function NetPortTest {
        param (
            [String]$IPaddr,
            [Int]$Port,
            [Int]$Timeout
        )
        begin {
            $result = @{
                ComputerName     = $IPaddr
                RemotePort       = $Port
                TcpTestSucceeded = $false
            }
        }
        process {
            $tcpClient = New-Object System.Net.Sockets.TcpClient
            $result["TcpTestSucceeded"] = $tcpClient.ConnectAsync($IPaddr, $Port).Wait($Timeout)
        }  
        
        end {
            return $result
        }
        
    }
    #tnc $_.hostIP -p $_.port -ErrorAction SilentlyContinue -WarningAction SilentlyContinue # Wery wery slowly
    NetPortTest -IPaddr $_.hostIP -Port $_.port -Timeout 1000 #wery fast
} 

foreach ($item in $data) {
    if (($null -eq $ips[$item.ComputerName]) -and $showempty) {
        $ips[$item.ComputerName] = @() 
    } 
    if ($item.TcpTestSucceeded -eq $true) { 
        if ($null -eq $ips[$item.ComputerName]) {
            $ips[$item.ComputerName] = @() 
        }
        $ips[$item.ComputerName] += $item.RemotePort    
    } 
}


$errorLOG
$ips.GetEnumerator() | Sort-Object { [version] $_.Name } | ForEach-Object {"{0}`t{1}" -f $_.Name,($_.Value -join ", ")}

$watch.Stop()
"Call request: " + $dt.Count
"Run time: " + $watch.Elapsed