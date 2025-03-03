###################################################
# Variables and Collections
###################################################

$a = 0                                                    # Initialize a variable
[int] $a = 'Trevor'                                       # Initialize a variable, with the specified type (throws an exception)
[string] $a = 'Trevor'                                    # Initialize a variable, with the specified type (doesn't throw an exception)

Get-Command -Name *varia*                                 # Get a list of commands related to variable management

Get-Variable                                              # Get an array of objects, representing the variables in the current and parent scopes
Get-Variable | ? { $PSItem.Options -contains 'constant' } # Get variables with the "Constant" option set
Get-Variable | ? { $PSItem.Options -contains 'readonly' } # Get variables with the "ReadOnly" option set

New-Variable -Name FirstName -Value Trevor
New-Variable FirstName -Value Trevor -Option Constant     # Create a constant variable, that can only be removed by restarting PowerShell
New-Variable FirstName -Value Trevor -Option ReadOnly     # Create a variable that can only be removed by specifying the -Force parameter on Remove-Variable

Remove-Variable -Name firstname                           # Remove a variable, with the specified name
Remove-Variable -Name firstname -Force                    # Remove a variable, with the specified name, that has the "ReadOnly" option set

# Simple way to get input data from console
$userInput = Read-Host "Enter some data: " # Returns the data as a string

# Accessing a previously unassigned variable does not throw exception.
# The value is $null by default

# Collections

# The default array object in Powershell is a fixed length array.
$defaultArray = "thing","thing2","thing3"
# you can add objects with '+=', but cannot remove objects.
$defaultArray.Add("thing4") # => Exception "Collection was of a fixed size."
# To have a more workable array, you'll want the .NET [ArrayList] class
# It is also worth noting that ArrayLists are significantly faster

# ArrayLists store sequences
[System.Collections.ArrayList]$array = @()
# You can start with a prefilled ArrayList
[System.Collections.ArrayList]$otherArray = @(5, 6, 7, 8)

# Add to the end of a list with 'Add' (Note: produces output, append to $null)
$array.Add(1) > $null    # $array is now [1]
$array.Add(2) > $null    # $array is now [1, 2]
$array.Add(4) > $null    # $array is now [1, 2, 4]
$array.Add(3) > $null    # $array is now [1, 2, 4, 3]
# Remove from end with index of count of objects-1; array index starts at 0
$array.RemoveAt($array.Count-1) # => 3 and array is now [1, 2, 4]
# Let's put it back
$array.Add(3) > $null   # array is now [1, 2, 4, 3] again.

# Access a list like you would any array
$array[0]   # => 1
# Look at the last element
$array[-1]  # => 3
# Looking out of bounds returns nothing
$array[4]  # blank line returned

# Remove elements from a array
$array.Remove($array[3])  # $array is now [1, 2, 4]

# Insert at index an element
$array.Insert(2, 3)  # $array is now [1, 2, 3, 4]

# Get the index of the first item found matching the argument
$array.IndexOf(2)  # => 1
$array.IndexOf(6)  # Returns -1 as "outside array"

# You can add arrays
# Note: values for $array and for $otherArray are not modified.
$array + $otherArray  # => [1, 2, 3, 4, 5, 6, 7, 8]

# Concatenate arrays with "AddRange()"
$array.AddRange($otherArray)  # Now $array is [1, 2, 3, 4, 5, 6, 7, 8]

# Check for existence in a array with "in"
1 -in $array  # => True

# Examine length with "Count" (Note: "Length" on arrayList = each items length)
$array.Count  # => 8

# You can look at ranges with slice syntax.
$array[1,3,5]     # Return selected index  => [2, 4, 6]
$array[1..3]      # Return from index 1 to 3 => [2, 3, 4]
$array[-3..-1]    # Return from last 3 to last 1 => [6, 7, 8]
$array[-1..-3]    # Return from last 1 to last 3 => [8, 7, 6]
$array[2..-1]     # Return from index 2 to last (NOT as most expect) => [3, 2, 1, 8]
$array[0,2+4..6]  # Return multiple ranges with the + => [1, 3, 5, 6, 7]

# -eq doesn't compare array but extract the matching elements
$array = 1,2,3,1,1
$array -eq 1          # => 1,1,1
($array -eq 1).Count  # => 3

# Tuples are like arrays but are immutable.
# To use Tuples in powershell, you must use the .NET tuple class.
$tuple = [System.Tuple]::Create(1, 2, 3)
$tuple.Item(0)      # => 1
$tuple.Item(0) = 3  # Raises a TypeError

# You can do some of the array methods on tuples, but they are limited.
$tuple.Length       # => 3