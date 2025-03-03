###################################################
# Functions
###################################################

# Use "function" to create new functions
# Keep the Verb-Noun naming convention for functions
function Add-Numbers {
    $args[0] + $args[1]
   }
   
   Add-Numbers 1 2 # => 3
   
   # Calling functions with parameters
   function Add-ParamNumbers {
    param( [int]$firstNumber, [int]$secondNumber )
    $firstNumber + $secondNumber
   }
   
   Add-ParamNumbers -FirstNumber 1 -SecondNumber 2 # => 3
   
   # Functions with named parameters, parameter attributes, parsable documentation
   <#
   .SYNOPSIS
   Setup a new website
   .DESCRIPTION
   Creates everything your new website needs for much win
   .PARAMETER siteName
   The name for the new website
   .EXAMPLE
   New-Website -Name FancySite -Po 5000
   New-Website SiteWithDefaultPort
   New-Website siteName 2000 # ERROR! Port argument could not be validated
   ('name1','name2') | New-Website -Verbose
   #>
   function New-Website() {
       [CmdletBinding()]
       param (
           [Parameter(ValueFromPipeline=$true, Mandatory=$true)]
           [Alias('name')]
           [string]$siteName,
           [ValidateSet(3000,5000,8000)]
           [int]$port = 3000
       )
       BEGIN { Write-Output 'Creating new website(s)' }
       PROCESS { Write-Output "name: $siteName, port: $port" }
       END { Write-Output 'Website(s) created' }
   }
   
   # Handle exceptions with a try/catch block
   try {
       # Use "throw" to raise an error
       throw "This is an error"
   }
   catch {
       Write-Output $Error.ExceptionMessage
   }
   finally {
       Write-Output "We can clean up resources here"
   }
   