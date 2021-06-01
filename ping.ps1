$dt = @()
foreach($line in Get-Content ".\IN.txt") {
    $dt += $line 
    } 
 $dt | ForEach-Object -Parallel {
        tnc $_ -ErrorAction SilentlyContinue -WarningAction SilentlyContinue} |
         Format-Table ComputerName, RemoteAddress, PingSucceeded -AutoSize 
    