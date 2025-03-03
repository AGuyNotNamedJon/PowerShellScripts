###################################################
# Primitive Datatypes and Operators
###################################################

# Numbers
3                                                       # => 3

# Math
1 + 1                                                   # => 2
8 - 1                                                   # => 7
10 * 2                                                  # => 20
35 / 5                                                  # => 7.0

# Powershell uses banker's rounding, which means [int]1.5 would round to 2 but so would [int]2.5
# Division always returns a float. To get an integer result, you must cast result to [int] to round.
[int]5 / [int]3       # => 1.66666666666667
[int]-5 / [int]3      # => -1.66666666666667
5.0 / 3.0   # => 1.66666666666667
-5.0 / 3.0  # => -1.66666666666667
[int]$result = 5 / 3
$result # => 2

# Modulo operation
7 % 3  # => 1

# Exponentiation requires longform or the built-in [Math] class.
[Math]::Pow(2,3)  # => 8

# Enforce order of operations with parentheses.
1 + 3 * 2  # => 7
(1 + 3) * 2  # => 8

# Boolean values are primitives (Note: the $)
$True  # => True
$False  # => False

# Operators

$a = 2                                                    # Basic variable assignment operator
$a += 1                                                   # Incremental assignment operator
$a -= 1                                                   # Decrement assignment operator

$a -eq 0                                                  # Equality comparison operator
$a -ne 5                                                  # Not-equal comparison operator
$a -gt 2                                                  # Greater than comparison operator
$a -lt 3                                                  # Less than comparison operator

$FirstName = 'Trevor'
$FirstName -like 'T*'                                     # Perform string comparison using the -like operator, which supports the wildcard (*) character. Returns $true

$BaconIsYummy = $true
$FoodToEat = $BaconIsYummy ? 'bacon' : 'beets'            # Sets the $FoodToEat variable to 'bacon' using the ternary operator

'Celery' -in @('Bacon', 'Sausage', 'Steak', 'Chicken')    # Returns boolean value indicating if left-hand operand exists in right-hand array
'Celery' -notin @('Bacon', 'Sausage', 'Steak')            # Returns $true, because Celery is not part of the right-hand list

5 -is [string]                                            # Is the number 5 a string value? No. Returns $false.
5 -is [int32]                                             # Is the number 5 a 32-bit integer? Yes. Returns $true.
5 -is [int64]                                             # Is the number 5 a 64-bit integer? No. Returns $false.
'Trevor' -is [int64]                                      # Is 'Trevor' a 64-bit integer? No. Returns $false.
'Trevor' -isnot [string]                                  # Is 'Trevor' NOT a string? No. Returns $false.
'Trevor' -is [string]                                     # Is 'Trevor' a string? Yes. Returns $true.
$true -is [bool]                                          # Is $true a boolean value? Yes. Returns $true.
$false -is [bool]                                         # Is $false a boolean value? Yes. Returns $true.
5 -is [bool]                                              # Is the number 5 a boolean value? No. Returns $false.

# Boolean Operators
# Note "-and" and "-or" usage
$True -and $False  # => False
$False -or $True   # => True

# True and False are actually 1 and 0 but only support limited arithmetic.
# However, casting the bool to int resolves this.
$True + $True # => 2
$True * 8    # => '[System.Boolean] * [System.Int32]' is undefined
[int]$True * 8 # => 8
$False - 5   # => -5

# Bitwise operators
0 -band 2     # => 0
-5 -bor 0     # => -5
