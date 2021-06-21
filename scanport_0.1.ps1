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
        $net
    
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

Clear-Host

$errorLOG
$ips.GetEnumerator() | Sort-Object { [version] $_.Name } | ForEach-Object {"{0}`t{1}" -f $_.Name,($_.Value -join ", ")}

$watch.Stop()
"Call request: " + $dt.Count
"Run time: " + $watch.Elapsed