###################################################
# Comments
###################################################

# Single line comments start with a number symbol.

<#
  Multi-line comments
  like so
#>

###################################################
# Comment-based help for functions (special comments)
###################################################
# These should be placed before function definitions
<#
.SYNOPSIS
    Brief description of what the function does.

.DESCRIPTION
    Detailed description of the function's purpose and functionality.
    Can span multiple lines.

.PARAMETER ParamName1
    Description of the first parameter.

.PARAMETER ParamName2
    Description of the second parameter.

.EXAMPLE
    Get-Something -ParamName1 "Value1"
    Description of what this example does.

.EXAMPLE
    Get-Something -ParamName1 "Value1" -ParamName2 "Value2"
    Shows another way to use the function.

.INPUTS
    [String] # Type of object that can be piped into the function

.OUTPUTS
    [System.Object] # Type of object that the function returns

.NOTES
    Author: Your Name
    Date: Current Date
    Version: 1.0
    Additional notes and requirements

.LINK
    https://related-link.com
    Online version or related functions

.COMPONENT
    The technology or feature that the function uses

.ROLE
    The user role this function is meant for

.FUNCTIONALITY
    The intended use of this function

.FORWARDHELPTARGETNAME
    The name of the function to forward help to

.FORWARDHELPCATEGORY
    The help category to forward help to

.REMOTEHELPRUNSPACE
    The session or runspace where the help should be retrieved from
#>
function Get-Something {
    # Function code here
  }