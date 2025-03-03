###################################################
# Execution Policies
###################################################

# Check current execution policy
Get-ExecutionPolicy                                             # Get the effective execution policy for the current PowerShell session
Get-ExecutionPolicy -List                                       # List execution policies for all scopes
Get-ExecutionPolicy -Scope CurrentUser                          # Get execution policy for a specific scope

# Set execution policy (requires admin privileges for some scopes)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned               # Set execution policy for the default scope (usually LocalMachine)
Set-ExecutionPolicy -ExecutionPolicy AllSigned -Scope CurrentUser # Set for current user only
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process      # Set for current PowerShell session only

# Execution policy types:
# - Restricted: Default policy. No scripts can run, interactive commands only.
# - AllSigned: All scripts must be digitally signed by a trusted publisher.
# - RemoteSigned: Downloaded scripts must be signed by a trusted publisher.
# - Unrestricted: All scripts can run, regardless of origin or signature.
# - Bypass: Nothing is blocked, no warnings or prompts (use with caution).
# - Default: Sets the default execution policy (usually Restricted).
# - Undefined: No execution policy set for the specified scope.

# Execution policy scopes (in order of precedence):
# - MachinePolicy: Set by Group Policy for all users of the computer
# - UserPolicy: Set by Group Policy for current user
# - Process: Affects only the current PowerShell session
# - CurrentUser: Affects only the current user
# - LocalMachine: Default scope, affects all users on the current computer

# Bypass execution policy temporarily for a single command
PowerShell -ExecutionPolicy Bypass -File ".\MyScript.ps1"       # Run script with bypass policy
PowerShell -Command "& {Set-ExecutionPolicy Bypass -Scope Process; .\MyScript.ps1}" # Another method

# Check if a script is blocked
Get-Item -Path .\MyScript.ps1 -Stream Zone.Identifier -ErrorAction SilentlyContinue # Check if file is marked as downloaded
Unblock-File -Path .\MyScript.ps1                               # Remove the "downloaded from internet" flag

# Get detailed help on execution policies
help about_Execution_Policies                                   # Detailed documentation
