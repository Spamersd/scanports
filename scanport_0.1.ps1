class Hosts {
    $hostIP
    $port
}

$ips=@{}
$dt = @()
foreach($line in Get-Content ".\IN.txt") {
    
    if ($line -notmatch "([0-9]{1,3}[\.]){3}[0-9]{1,3}") {
        continue    
    }
    foreach($port in Get-Content ".\ports.txt"){
        
        if ($port -notmatch "^\d+$") {
            continue
        }

        $myhost = New-Object -TypeName Hosts
        $myhost.hostIP = $line
        $myhost.port = $port
        $dt += $myhost
    }
} 

$data = $dt | ForEach-Object -Parallel {
tnc $_.hostIP -p $_.port -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
} 

foreach ($item in $data) {
    if ($ips[$item.ComputerName] -eq $null) {
            $ips[$item.ComputerName]=@() 
        } 
    if ($item.TcpTestSucceeded -eq $true) { 
        $ips[$item.ComputerName] += $item.RemotePort    
    } 
}

$ips