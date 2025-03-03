###################################################
# Classes
###################################################

# We use the "class" statement to create a class
class Instrument {
    [string]$Type
    [string]$Family
}

$instrument = [Instrument]::new()
$instrument.Type = "String Instrument"
$instrument.Family = "Plucked String"

$instrument

<# Output:
Type              Family
----              ------
String Instrument Plucked String
#>
