$dt = @()
foreach($line in Get-Content ".\IN.txt") {
    $dt += $line 
    } 
 $dt | ForEach-Object -Parallel { nslookup $_ }