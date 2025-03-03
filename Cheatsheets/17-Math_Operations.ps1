###################################################
# Math Operations
###################################################

# Math is built in to powershell and has many functions.
$r=2
$pi=[math]::pi
$r2=[math]::pow( $r, 2 )
$area = $pi*$r2
$area

# To see all possibilities, check the members.
[System.Math] | Get-Member -Static -MemberType All
