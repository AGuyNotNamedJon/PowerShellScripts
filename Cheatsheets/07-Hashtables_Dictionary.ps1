###################################################
# Hashtables (Dictionary)
###################################################

# Hashtables store mappings from keys to values, similar to (but distinct from) Dictionaries.
# Hashtables do not hold entry order as arrays do.
$emptyHash = @{}
# Here is a prefilled hashtable
$filledHash = @{"one"= 1
                "two"= 2
                "three"= 3}

# Look up values with []
$filledHash["one"]  # => 1

# Get all keys as an iterable with ".Keys".
$filledHash.Keys  # => ["one", "two", "three"]

# Get all values as an iterable with ".Values".
$filledHash.Values  # => [1, 2, 3]

# Check for existence of keys or values in a hash with "-in"
"one" -in $filledHash.Keys  # => True
1 -in $filledHash.Values    # => True (in PowerShell 7)

# Looking up a non-existing key returns $null
$filledHash["four"]  # $null

# Adding to a hashtable
$filledHash.Add("five",5)  # $filledHash["five"] is set to 5
$filledHash.Add("five",6)  # exception "Item with key "five" has already been added"
$filledHash["four"] = 4    # $filledHash["four"] is set to 4, running again does nothing

# Remove keys from a hashtable
$filledHash.Remove("one") # Removes the key "one" from filled hashtable

# Create a more complex hashtable
$Person = @{
  FirstName = 'Trevor'
  LastName = 'Sullivan'
  Likes = @(
    'Bacon',
    'Beer',
    'Software'
  )
}                                                           # Create a PowerShell HashTable

$Person.FirstName                                           # Retrieve an item from a HashTable
$Person.Likes[-1]                                           # Returns the last item in the "Likes" array, in the $Person HashTable (software)
$Person.Age = 50                                            # Add a new property to a HashTable
