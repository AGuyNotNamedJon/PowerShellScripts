###################################################
# Filesystem Operations
###################################################

# Creating directories and files
New-Item -Path c:\test -ItemType Directory                  # Create a directory
mkdir c:\test2                                              # Create a directory (short-hand)

New-Item -Path c:\test\myrecipes.txt                        # Create an empty file
Set-Content -Path c:\test.txt -Value ''                     # Create an empty file
[System.IO.File]::WriteAllText('testing.txt', '')           # Create an empty file using .NET Base Class Library

# Deleting files
Remove-Item -Path testing.txt                               # Delete a file
[System.IO.File]::Delete('testing.txt')                     # Delete a file using .NET Base Class Library

# Writing to a file
$contents = @{"aa"= 12
              "bb"= 21}
$contents | Export-CSV "$env:HOMEDRIVE\file.csv" # writes to a file

$contents = "test string here"
$contents | Out-File "$env:HOMEDRIVE\file.txt" # writes to another file

# Read file contents and convert to json
Get-Content "$env:HOMEDRIVE\file.csv" | ConvertTo-Json
