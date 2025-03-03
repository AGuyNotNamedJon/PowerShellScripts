###################################################
# Inheritance
###################################################

# Inheritance allows new child classes to be defined that inherit
# methods and variables from their parent class.

class Guitar : Instrument
{
    [string]$Brand
    [string]$SubType
    [string]$ModelType
    [string]$ModelNumber
}

$myGuitar = [Guitar]::new()
$myGuitar.Brand       = "Taylor"
$myGuitar.SubType     = "Acoustic"
$myGuitar.ModelType   = "Presentation"
$myGuitar.ModelNumber = "PS14ce Blackwood"

$myGuitar.GetType()

<#
IsPublic IsSerial Name                                     BaseType
-------- -------- ----                                     --------
True     False    Guitar                                   Instrument
#>
