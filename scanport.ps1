class Hosts {
    $hostIP
    $port
}
$dt = @()
foreach($line in Get-Content ".\IN.txt") {
foreach($port in Get-Content ".\ports.txt"){
$myhost = New-Object -TypeName Hosts
$myhost.hostIP = $line
$myhost.port = $port
$dt += $myhost
}
} 
$dt | ForEach-Object -Parallel {
    tnc $_.hostIP -p $_.port -ErrorAction SilentlyContinue -WarningAction SilentlyContinue} |
     Format-Table ComputerName, RemoteAddress, RemotePort, TcpTestSucceeded -AutoSize 
