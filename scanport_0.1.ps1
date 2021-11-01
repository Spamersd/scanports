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
                }
            }
        }
    }
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
$ListIP = @();

foreach ($port in Get-Content $PathPortList) {
    $port_range = $port.split("-")

    if ($port_range.count -eq 2){
        foreach ($item in $port_range[0]..$port_range[1] ) {
            $ListPort += $item
        } 
    }
    else {
        $ListPort += $port_range[0]       
    }
    
  
}

foreach ($line in Get-Content $PathHostList) {
   
    $line = $line.Trim().Replace(" ", "")

    if ($line -match "([0-9]{1,3}[\.]){3}[0-9]{1,3}[\/][0-9]{2}(?=\s|$)") {
       
        $net = $line -split "/"
        $ip = [IPAddress]$net[0]
        $mask = [IPAddress](ConvertTo-IPv4MaskString $net[1])
        $net = [IPAddress]($ip.Address -band $mask.Address)
        $broad = [IPAddress]($ip.Address -bor (-bnot [uint]$mask.Address))

        $ListIP += GetIPrange -start $net.IPAddressToString -stop $broad.IPAddressToString
        

    }
    elseif ($line -match "([0-9]{1,3}[\.]){3}[0-9]{1,3}[\-]([0-9]{1,3}[\.]){3}[0-9]{1,3}") {
       
        $range = $line -split "-"
        $ListIP += GetIPrange -start $range[0] -stop $range[1]
        
    }
    elseif ($line -match "([0-9]{1,3}[\.]){3}[0-9]{1,3}(?=\s|$)" ) {
    
        $ListIP += $line

    }
    else {
    
        $errorLOG += "'$line' is not IP adress/subnet/ip range" 
        continue           
    }
} 

foreach ($ip in $ListIP) {
    foreach ($port in  $ListPort) {
        $myhost = New-Object -TypeName Hosts
        $myhost.hostIP = $ip
        $myhost.port = $port
        $dt += $myhost
    }   
}

$strListPort = $ListPort -join ", "
"Check ports: {0} on {1} hosts" -f $strListPort, $ListIP.Count

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
    NetPortTest -IPaddr $_.hostIP -Port $_.port -Timeout 300 #wery fast
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

""
$errorLOG

""
"Host`t`tAvailable ports"
$ips.GetEnumerator() | Sort-Object { [version] $_.Name } | ForEach-Object { "{0}`t{1}" -f $_.Name, ($_.Value -join ", ") }

""
$watch.Stop()

"Call request: " + $dt.Count
"Run time: " + $watch.Elapsed