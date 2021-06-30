$dt = @()
foreach($line in Get-Content ".\OUT.txt") {
    $dt += $line 
    } 

$dt
 $dt | ForEach-Object { Start "http://$_ "}
 #$dt | ForEach-Object { nslookup  $_ 10.81.0.14}