###################################################
# Calling External Commands
###################################################

# Calling external commands, executables,
# and functions with the call operator.
# Exe paths with arguments passed or containing spaces can create issues.
C:\Program Files\dotnet\dotnet.exe
# The term 'C:\Program' is not recognized as a name of a cmdlet,
# function, script file, or executable program.
# Check the spelling of the name, or if a path was included,
# verify that the path is correct and try again

"C:\Program Files\dotnet\dotnet.exe"
C:\Program Files\dotnet\dotnet.exe    # returns string rather than execute

&"C:\Program Files\dotnet\dotnet.exe --help"   # fail
&"C:\Program Files\dotnet\dotnet.exe" --help   # success
# Alternatively, you can use dot-sourcing here
."C:\Program Files\dotnet\dotnet.exe" --help   # success

# the call operator (&) is similar to Invoke-Expression,
# but IEX runs in current scope.
# One usage of '&' would be to invoke a scriptblock inside of your script.
# Notice the variables are scoped
$i = 2
$scriptBlock = { $i=5; Write-Output $i }
& $scriptBlock # => 5
$i # => 2

invoke-expression ' $i=5; Write-Output $i ' # => 5
$i # => 5

# Alternatively, to preserve changes to public variables
# you can use "Dot-Sourcing". This will run in the current scope.
$x=1
&{$x=2};$x # => 1

.{$x=2};$x # => 2
