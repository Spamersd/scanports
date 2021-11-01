Clear-Host

$summ = 0
$a = 3.5115471
for ($i = 1; $i -le 2021; $i++){
    $res = ([math]::Pow($i,2)-1)%10

    if ($res -eq 0 )
    {
        $summ ++
    }
 
}

$summ/2021