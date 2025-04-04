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
    
    Write-Host "Removing Group Memberships" -ForegroundColor DarkYellow
    $ADGroups = $Groups | Where-Object { $_.Name -ne "Domain Users" }
    Remove-ADPrincipalGroupMembership -Identity $Username -MemberOf $ADGroups -Confirm:$false -Verbose
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
        Write-Host "Press any key to continue …"
        $x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        exit
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
