$watch = [System.Diagnostics.Stopwatch]::StartNew()
$watch.Start() 
# Params 
$showempty = $true
$PathHostList = ".\IN.txt"
$PathPortList = ".\ports.txt"
$errorLOG =@()

class Hosts {
    $hostIP
    $port
}

$ips=@{}
$dt = @()
$ListPort = @();

foreach($port in Get-Content $PathPortList){
    if ($port -notmatch "^\d+$") {
        $errorLOG += "'$port' is not port"
        continue
        
    }
    $ListPort += $port
}

foreach($line in Get-Content $PathHostList) {
    
    if ($line -notmatch "([0-9]{1,3}[\.]){3}[0-9]{1,3}") {
        $errorLOG += "'$line' is not IP adress" 
        continue   
        
    }
    foreach($port in  $ListPort){
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
$errorLOG

$ips.GetEnumerator() | sort {[version] $_.Name}
$watch.Stop()

"Run time: "+ $watch.Elapsed