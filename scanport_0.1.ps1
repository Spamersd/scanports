
# Params 
$showempty = $true
$PathHostList = ".\IN.txt"
$PathPortList = ".\ports.txt"

class Hosts {
    $hostIP
    $port
}

$ips=@{}
$dt = @()

foreach($line in Get-Content $PathHostList) {
    
    if ($line -notmatch "([0-9]{1,3}[\.]){3}[0-9]{1,3}") {
        continue    
    }
    foreach($port in Get-Content $PathPortList){
        
        if ($port -notmatch "^\d+$") {
            continue
        }

        $myhost = New-Object -TypeName Hosts
        $myhost.hostIP = $line
        $myhost.port = $port
        $dt += $myhost
    }
} 
$dt
$dt | ForEach-Object -Parallel {
  $data += tnc $_.hostIP -p $_.port -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
} 
foreach ($item in $data) {
    if (($ips[$item.ComputerName] -eq $null) -and $showempty) {
            $ips[$item.ComputerName]=@() 
        } 
    if ($item.TcpTestSucceeded -eq $true) { 
        if ($ips[$item.ComputerName] -eq $null) {
            $ips[$item.ComputerName]=@() 
        }
        $ips[$item.ComputerName] += $item.RemotePort    
    } 
}

$ips.GetEnumerator() | sort {[version] $_.Name}