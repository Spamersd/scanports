class Hosts {
    $hostIP
    $port
}

$ips=@{}
$dt = @()
foreach($line in Get-Content ".\IN.txt") {
    foreach($port in Get-Content ".\ports.txt"){
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