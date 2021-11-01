$dt = @()
foreach($line in Get-Content ".\OUT.txt") {
    $dt += $line 
    } 

#$dt
 #$dt | ForEach-Object { Resolve-DnsName -Name $_   -Type PTR } | Select-Object IPAddress
 $dt | ForEach-Object {
     $site = "http://"+$_+"/"
     $site
     Start-Process $site
    }
 #$dt | ForEach-Object { nslookup  $_ 10.81.0.14}