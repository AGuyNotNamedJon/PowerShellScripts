#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Converts a Dynamic Distribution List to a Static Distribution List in Exchange.

.DESCRIPTION
    This script takes a Dynamic Distribution List and converts it to a regular (static) Distribution List
    while preserving its properties and membership. It performs the following steps:
    1. Gets the Dynamic Distribution List and its members
    2. Stores original properties (name, display name, email, managed by, hidden status)
    3. Removes the Dynamic Distribution List
    4. Creates a new static Distribution List with identical properties
    5. Adds all original members to the new Distribution List
    6. Restores hidden from GAL status if applicable

.PARAMETER DynamicDLName
    The name or email address of the Dynamic Distribution List to convert.

.PARAMETER BypassAndQuit
    When set to TRUE, bypasses the script execution without processing anything.

.PARAMETER Force
    When set to TRUE, skips confirmation prompts and proceeds with conversion.

.INPUTS
    String. You can pipe a string that contains the Dynamic Distribution List name.

.OUTPUTS
    None. The script writes status messages using a structured logging system.

.EXAMPLE
    .\Convert-DynamicDLtoStaticDL.ps1 -DynamicDLName "Sales Team DL"
    Converts the Dynamic Distribution List "Sales Team DL" to a static Distribution List with confirmation prompt.

.EXAMPLE
    .\Convert-DynamicDLtoStaticDL.ps1 -DynamicDLName "salesteam@contoso.com" -Force
    Converts the Dynamic Distribution List without asking for confirmation.

.NOTES
    Version:        1.0.0.0
    Author:         Saul Rodgers
    Creation Date:  29/01/2025
#>


[CmdletBinding()]
param(
    [Parameter(
        Mandatory = $true,
        Position = 0,
        ValueFromPipeline = $true,
        HelpMessage = "Name or email address of the Dynamic Distribution List to convert"
    )]
    [string]$DynamicDLName,

    [Parameter(
        Mandatory = $false,
        HelpMessage = "Bypasses the script execution without processing anything"
    )]
    [PSDefaultValue(Help = 'When set to TRUE, bypasses the script execution', Value = $false)]
    [switch]$BypassAndQuit,

    [Parameter(
        Mandatory = $false,
        HelpMessage = "Forces the conversion without prompting for confirmation"
    )]
    [PSDefaultValue(Help = 'When set to TRUE, skips confirmation prompts', Value = $false)]
    [switch]$Force
)

$ScriptDetails = @{
    Version      = [version]'1.0.0.0'
    InternalName = "Convert-DynamicDLtoStaticDL"
}

$LoggingSettings = @{
    LogFileName   = $ScriptDetails.InternalName
    Console       = $true
    WriteLogFile  = $false
    DateTimeIsUTC = $false
}

# *******************************************************
# *******************************************************
# **                                                   **
# **            DO NOT EDIT BELOW THIS BLOCK           **
# **                                                   **
# **                INITIALISATION BLOCK               **
# **                                                   **
# *******************************************************
# *******************************************************

# A simple test to enable 'bypass & quit' mode. IE immediately quit when called
If ($BypassAndQuit) {
    $OutputLog = "Command line said to exit"
    Write-Host $OutputLog
    exit
}

# Load (if) any custom modules
$CurrentModules = Get-Module

# A simple test to enable 'bypass & quit' mode. IE immediately quit when called
If ($BypassAndQuit) {
    exit
}

# *******************************************************
# *******************************************************
# **                                                   **
# **              INTERNAL VARIABLES BLOCK             **
# **                                                   **
# *******************************************************
# *******************************************************

# Internal Variables go here

# *******************************************************
# *******************************************************
# **                                                   **
# **                 FUNCTIONS BLOCK                   **
# **                                                   **
# *******************************************************
# *******************************************************

Function Write-Log {
    param (
        [parameter(Mandatory = $true)]    
        [String]$Comment,

        [parameter(Mandatory = $true)]
        [String]$LogFileName,

        [parameter(Mandatory = $true)]
        [bool]$Console,

        [parameter(Mandatory = $true)]
        [bool]$WriteLogFile,

        [parameter(Mandatory = $true)]
        [bool]$DateTimeIsUTC,

        [parameter(Mandatory = $false)]
        [ValidateSet("Continue", "Ignore", "Inquire", "SilentlyContinue", "Stop", "Suspend")]
        [String]$ErrorAct = "Continue",

        [parameter(Mandatory = $true)]
        [ValidateSet("Debug", "Error", "Info", "Warning", "Verbose")]
        [String]$Level
    )

    If ($DateTimeIsUTC) {
        $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff UTC"
    }
    else {
        $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff UTCK"
    }

    $TextColour = @{
        Foregound  = "Gray"
        Background = "Black"
    }

    Switch ($Level) {
        "Debug" {
            $LogLevel = "[DBG]"
            $TextColour.Foregound = "DarkYellow"
            break
        }
        "Error" {
            $LogLevel = "[ERR]"
            $TextColour.Foregound = "White"
            $TextColour.Background = "Red"
            break
        }
        "Info" {
            $LogLevel = "[INF]"
            $TextColour.Foregound = "DarkGray"
            break
        }
        "Warning" {
            $LogLevel = "[WRN]"
            $TextColour.Foregound = "Black"
            $TextColour.Background = "Yellow"
            break
        }
        "Verbose" {
            $LogLevel = "[VRB]"
            $TextColour.Foregound = "Cyan"
            break
        }
    }

    $LogOutput = $TimeStamp + " -- " + $LogLevel + " -- " + $Comment

    if ($WriteLogFile) {
        Add-Content -Value $LogOutput -LiteralPath $LogFileName
    }

    if ($Console) {
        Write-Host $LogOutput -ForegroundColor $TextColour.Foregound -BackgroundColor $TextColour.Background
    }

    Switch ($Level) {
        "Debug" {
            Write-Debug $LogOutput -ErrorAction $ErrorAct
            break
        }
        "Error" {
            Write-Error $LogOutput -ErrorAction $ErrorAct
            break
        }
        "Info" {
            Write-Information $LogOutput -ErrorAction $ErrorAct
            break
        }
        "Warning" {
            Write-Warning $LogOutput -ErrorAction $ErrorAct
            break
        }
        "Verbose" {
            Write-Verbose $LogOutput -ErrorAction $ErrorAct
            break
        }
    }
}

# Import the Read-InYesNo function for confirmation prompts
function Read-InYesNo {
    <#
	.SYNOPSIS
		Reads in if the user pressed Y or N
	.PARAMETER Prompt
		Specifies the prompt to show to the user, when requesting the input
	.PARAMETER CancelOption
		Specifies what the user should input to cancel the current request. E.G. Entering Q to abort
	.INPUTS
		N/A
	.DESCRIPTION
		Reads in if the user pressed Y or N. Code taken & Modified from https://stackoverflow.com/a/56207486
	.OUTPUTS
		A boolean (TRUE or FALSE) in response to the user's input
	.EXAMPLE
		PS> Read-InYesNo
		Requests the user to enter Y or N, doesnt allow the question to be aborted
	.EXAMPLE
		PS> Read-InYesNo -Prompt "Do you wish to continue (Y/N)? "
		Requests if the user wishes to continue the operation.
	.EXAMPLE
		PS> Read-InYesNo -Prompt "Do you wish to continue (Y/N), press Q to go back? " -CancelOption "Q"
		Requests if the user wishes to continue the operation. Allows the user to press Q to go back
	.NOTES
		Version:	1.2
		Author:		Nathaniel Mitchell
		Creation:	15 July 2022
		Changes:	Updated the way the prompt is shown
		
		Version:	1.1
		Author:		Nathaniel Mitchell
		Creation:	14 July 2022
		Changes:	Updated the way the prompt is shown
		
		Version:	1.0
		Author:		Nathaniel Mitchell
		Creation:	8 November 2021
		Changes:	Initial build
	#>

    [CmdletBinding()]
    param(
        [string]$Prompt = 'Please enter Y or N: ',
        [string]$CancelOption = $null
    )
    $ToPrompt = $Prompt + " (Y/N): "
    if ($CancelOption) { 
        Write-Host "Type $CancelOption to cancel." -ForegroundColor Yellow
    }
    while ($true) {
        Write-Host -NoNewLine $ToPrompt
        $TMPresult = [console]::ReadKey()
        [string]$result = $TMPresult.Key
        if ($result -eq $CancelOption) { Write-Host ""; return $null }
        switch ($result.ToUpper()) {
            "Y" { Write-Host ""; return $true; break }
            "N" { Write-Host ""; return $false; break }
            default { Write-Host ""; Write-Warning "Invalid input... Please enter Y or N."; Start-Sleep -Seconds 1; break }
        }
    }
}

# *******************************************************
# *******************************************************
# **                                                   **
# **                  MAIN CODE BLOCK                  **
# **                                                   **
# *******************************************************
# *******************************************************

try {
    # First, try to find the Dynamic Distribution List in Exchange
    # If not found, log error and exit with error code 1
    try {
        $dynamicDL = Get-DynamicDistributionGroup -Identity $DynamicDLName -ErrorAction Stop
        if (-not $dynamicDL) {
            Write-Log @LoggingSettings -Comment "Dynamic Distribution List '$DynamicDLName' not found." -Level "Error"
            exit 1
        }
    }
    catch {
        Write-Log @LoggingSettings -Comment "Error retrieving Dynamic Distribution List: $_" -Level "Error"
        exit 1
    }
    
    # If -Force parameter wasn't specified, show details and ask for confirmation
    # This provides a safety check before making changes
    if (-not $Force) {
        Write-Log @LoggingSettings -Comment "Distribution List Details:" -Level "Info"
        Write-Log @LoggingSettings -Comment "Name: $($dynamicDL.Name)" -Level "Info"
        Write-Log @LoggingSettings -Comment "Aliases: $($dynamicDL.EmailAddresses -join ', ')" -Level "Info"
        Write-Log @LoggingSettings -Comment "Primary Email: $($dynamicDL.PrimarySmtpAddress)" -Level "Info"
        
        # Prompt user for confirmation using custom Read-InYesNo function
        $confirm = Read-InYesNo -Prompt "Are you sure you want to convert this Dynamic Distribution List to a Static Distribution List?"
        if (-not $confirm) {
            Write-Log @LoggingSettings -Comment "Operation cancelled by user." -Level "Info"
            exit
        }
    }
    
    # Store all important properties from original DL
    # These will be used to create the new static DL with identical settings
    $originalName = $dynamicDL.Name
    $originalDisplayName = $dynamicDL.DisplayName
    $originalPrimarySmtpAddress = $dynamicDL.PrimarySmtpAddress
    $originalManagedBy = $dynamicDL.ManagedBy
    $originalHiddenStatus = $dynamicDL.HiddenFromAddressListsEnabled
    
    # Get all secondary email aliases while excluding the primary SMTP address
    try {
        $originalAliases = @()  # Initialize as empty array
        $emailAddresses = $dynamicDL.EmailAddresses
        
        if (($null -ne $emailAddresses) -and ($emailAddresses.Count -gt 0)) {
            $originalAliases = $emailAddresses | 
                Where-Object {
                    # Match only lowercase smtp: (secondary) and exclude uppercase SMTP: (primary)
                    $_ -match "^smtp:" -and 
                    $_ -notmatch "^SMTP:"
                } | 
                ForEach-Object {
                    # Extract just the email address part after the "smtp:" prefix
                    $_.Split(':')[1].Trim()
                }
            
            if ($originalAliases.Count -gt 0) {
                Write-Log @LoggingSettings -Comment "Successfully retrieved $($originalAliases.Count) secondary email aliases" -Level "Info"
            }
            else {
                Write-Log @LoggingSettings -Comment "No secondary email aliases found" -Level "Info"
            }
        }
        else {
            Write-Log @LoggingSettings -Comment "No email addresses found on the distribution list" -Level "Info"
        }
    }
    catch {
        Write-Log @LoggingSettings -Comment "Error retrieving secondary email aliases: $_" -Level "Error"
        $originalAliases = @()
    }

    Write-Log @LoggingSettings -Comment "Starting conversion process..." -Level "Info"
    
    try {
        # Get all current members before removing the Dynamic DL
        # This is crucial as we need the member list to recreate the static DL
        $members = Get-DynamicDistributionGroupMember -Identity $DynamicDLName
        Write-Log @LoggingSettings -Comment "Retrieved $($members.Count) members from Dynamic Distribution List" -Level "Info"
    }
    catch {
        Write-Log @LoggingSettings -Comment "An error occurred when getting membership of the Dynamic Distribution List: $_" -Level "Error"
    }
    
    try {
        # Remove the original Dynamic DL after properties are safely stored
        # Confirm:$false prevents additional prompts
        Write-Log @LoggingSettings -Comment "Removing original Dynamic Distribution List..." -Level "Info"
        Remove-DynamicDistributionGroup -Identity $DynamicDLName -Confirm:$false
    }
    catch {
        Write-Log @LoggingSettings -Comment "An error occurred when removing the Dynamic Distribution List: $_" -Level "Error"
    }
        
    try {
        # Create new static DL using stored properties
        # Type parameter is set to "Distribution" to create a static DL
        Write-Log @LoggingSettings -Comment "Creating new static Distribution List..." -Level "Info"
        $newDLParams = @{
            Name               = $originalName
            DisplayName        = $originalDisplayName
            PrimarySmtpAddress = $originalPrimarySmtpAddress
            Type               = "Distribution"
            ManagedBy          = $originalManagedBy
        }
        New-DistributionGroup @newDLParams
    }
    catch {
        Write-Log @LoggingSettings -Comment "An error occurred when creating the new Distribution List: $_" -Level "Error"
    }
    
    try {
        # Add each member from the stored member list to the new static DL
        # Uses PrimarySmtpAddress to ensure correct member identification
        Write-Log @LoggingSettings -Comment "Adding members to new Distribution List..." -Level "Info"
        foreach ($member in $members) {
            Add-DistributionGroupMember -Identity $originalName -Member $member.PrimarySmtpAddress
        }
    }
    catch {
        Write-Log @LoggingSettings -Comment "An error occurred when attempting to add members to the new Distribution list: $_" -Level "Error"
    }
    
    # If the original DL was hidden from GAL, restore that setting
    # This preserves the original visibility status
    if ($originalHiddenStatus) {
        try {
            Set-DistributionGroup -Identity $originalName -HiddenFromAddressListsEnabled $originalHiddenStatus
        }
        catch {
            Write-Log @LoggingSettings -Comment "An error occurred during the process of setting the Distribution List to be hidden from the GAL: $_" -Level "Error"
        }
    }
    else {
        Write-Log @LoggingSettings -Comment "Original Distribution List was not hidden from the GAL. Skipping..." -Level "Info"
    }
    
    # Add secondary email addresses to the new DL if they exist
    if ($originalAliases) {
        try {
            Write-Log @LoggingSettings -Comment "Adding secondary email aliases..." -Level "Info"
            foreach ($alias in $originalAliases) {
                Set-DistributionGroup -Identity $originalName -EmailAddresses @{Add = "smtp:$alias" }
            }
            Write-Log @LoggingSettings -Comment "Successfully added $($originalAliases.Count) email aliases" -Level "Info"
        }
        catch {
            Write-Log @LoggingSettings -Comment "Error adding secondary email aliases: $_" -Level "Error"
        }
    }
    else {
        Write-Log @LoggingSettings -Comment "No secondary email aliases found. Skipping..." -Level "Info"
    }
        
    Write-Log @LoggingSettings -Comment "Successfully converted Dynamic DL to static Distribution List with $($members.Count) members" -Level "Info"
}
catch {
    # Main try-catch block to handle any unexpected errors
    # Ensures proper error logging for troubleshooting
    Write-Log @LoggingSettings -Comment "An unknown error occurred: $_" -Level "Error"
}

# *******************************************************
# *******************************************************
# **                                                   **
# **                CLEAN UP CODE BLOCK                **
# **                                                   **
# *******************************************************
# *******************************************************

# Removes all previously loaded modules
$LoadedModules = Get-Module
ForEach ($ModuleLoaded in (Compare-Object -ReferenceObject $CurrentModules -DifferenceObject $LoadedModules)) {
    Remove-Module $ModuleLoaded.InputObject 
}
