
$line = @("1.2.3.4", "22")
$ip =[IPAddress]$line[0]
$mask = [IPAddress](ConvertTo-IPv4MaskString $line[1])
$net = [IPAddress]($ip.Address -band $mask.Address)
$broad = [IPAddress]($ip.Address -bor (-bnot [uint]$mask.Address))



# $net 
# $mask 
# $broad 
# $net_b..($net_b+$range) | ForEach-Object{
#      [ipaddress](ReversIP -IP $_)
# }



# $ip_int = ConvertIP_ToBit -IP "192.168.10.168"
# $mask_int = ConvertIP_ToBit -IP $mask.IPAddressToString

# $count = 


  