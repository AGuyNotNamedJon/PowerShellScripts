<#
.SYNOPSIS
    Manages Active Directory group memberships for user off-boarding.

.DESCRIPTION
    This script provides functionality to export and/or remove Active Directory group memberships
    for a specified user. It can be used to:
    - Export a user's group memberships to a CSV file
    - Remove a user from all groups (except Domain Users)
    - Perform both operations in sequence

.PARAMETER Username
    The username (UPN) of the user to process (e.g., "john.doe" for john.doe@domain.com)

.PARAMETER Export
    Switch to export the user's group memberships to a CSV file

.PARAMETER Remove
    Switch to remove the user from all groups (except Domain Users)

.PARAMETER ExportPath
    Optional path where the export file will be saved. Defaults to "C:\DisabledUsers"

.EXAMPLE
    .\Script.ps1 -Username "john.doe" -Export
    Exports john.doe's group memberships to a CSV file

.EXAMPLE
    .\Script.ps1 -Username "john.doe" -Remove
    Removes john.doe from all groups (except Domain Users)

.EXAMPLE
    .\Script.ps1 -Username "john.doe" -Export -Remove
    Exports john.doe's group memberships and then removes them

.EXAMPLE
    .\Script.ps1 -Username "john.doe" -Export -ExportPath "D:\Backups"
    Exports john.doe's group memberships to a custom location

.NOTES
    Author: Saul Rodgers
    Last Modified: 2025-04-04
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Username,
    
    [Parameter()]
    [switch]$Export,
    
    [Parameter()]
    [switch]$Remove,
    
    [Parameter()]
    [string]$ExportPath = "C:\DisabledUsers"
)

# *******************************************************
# *******************************************************
# **                                                   **
# **            DO NOT EDIT BELOW THIS BLOCK           **
# **                                                   **
# **                INITIALISATION BLOCK               **
# **                                                   **
# *******************************************************
# *******************************************************

if (-not (Get-Module ActiveDirectory)) {
    Import-Module ActiveDirectory -ErrorAction Stop
}

# *******************************************************
# *******************************************************
# **                                                   **
# **                 FUNCTIONS BLOCK                   **
# **                                                   **
# *******************************************************
# *******************************************************

function Export-ADGroupMembership {
    param($Username, $ExportPath)
    
    $filename = "$Username - $((get-date).ToString('dd.MM.yyyy (HHmm)'))"
    $fullPath = Join-Path $ExportPath "$filename.txt"
    
    Write-Host "Displaying group memberships for $Username" -ForegroundColor Yellow
    $groups = Get-ADPrincipalGroupMembership -Identity $Username
    $groups | Format-Table -Property name
    
    Write-Host "Creating a backup of the permissions at: $fullPath"
    $groups | Select-Object Name | Export-csv -Path $fullPath -NoTypeInformation
    
    return $groups
}

function Remove-ADGroupMembership {
    param($Username, $Groups)

    $Confirmation = Read-InYesNo -Prompt "Do you wish to continue (Y/N)? "
    if($Confirmation) {
        Write-Host "Removing Group Memberships" -ForegroundColor DarkYellow
        $ADGroups = $Groups | Where-Object { $_.Name -ne "Domain Users" }
        Remove-ADPrincipalGroupMembership -Identity $Username -MemberOf $ADGroups -Confirm:$false -Verbose
    }
    else {
        Write-Host "Confirmation was declined. Exiting."
    }
    
}

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
    if (-not $Export -and -not $Remove) {
        Write-Host "Please specify either -Export or -Remove (or both)" -ForegroundColor Red
        exit
    }

    #check if user exists
    $Userexist = Get-ADUser -LDAPFilter "(sAMAccountName=$Username)"
    If ($Userexist -eq $Null) {
        Write-Host "User $Username not found." -foregroundcolor green
    }
    Else {
        Write-Host "User $Username found." -foregroundcolor green
    }
    
    $groups = $null
    if ($Export) {
        $groups = Export-ADGroupMembership -Username $Username -ExportPath $ExportPath
    }
    
    if ($Remove) {
        if (-not $groups) {
            $groups = Get-ADPrincipalGroupMembership -Identity $Username
        }
        Remove-ADGroupMembership -Username $Username -Groups $groups
    }
}
catch {
    Write-Host "An error occurred: $_" -ForegroundColor Red
}
