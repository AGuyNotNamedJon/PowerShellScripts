# Manage-WiFiNetworks.ps1

<#
.SYNOPSIS
    This PowerShell script allows you to manage saved Wi-Fi networks on a Windows system. It provides functionalities for listing, backing up, restoring, wiping, and exporting Wi-Fi profiles, with an optional GUI interface.

.DESCRIPTION
    This script allows users to perform various tasks to manage their Wi-Fi network profiles. 
    It uses the `netsh` command-line tool to interact with Wi-Fi profiles. Users can:
    - Back up saved Wi-Fi profiles to a folder on the desktop.
    - Restore profiles from a backup.
    - Delete (wipe) all saved Wi-Fi profiles.
    - Export Wi-Fi profile names and passwords to a plain text file.
    - Compress backup files into a .zip archive.
    - View saved or backed-up profiles.
	- Optional GUI for managing Wi-Fi profiles.
	
.PARAMETER UseGUI
    Launches the script with a GUI interface for easier interaction. Without this parameter, the script runs in CLI mode.

.PARAMETER Backup
    Creates a backup of all saved Wi-Fi network profiles to a folder on the desktop.

.PARAMETER Restore
    Restores Wi-Fi network profiles from a previously created backup.

.PARAMETER Wipe
    Deletes all saved Wi-Fi network profiles from the system.

.PARAMETER Cleanup
    Deletes the backup folder and all its contents created during the Backup process.

.PARAMETER ListCurrent
    Lists all saved Wi-Fi networks currently added to Windows.

.PARAMETER ListBackup
    Lists all Wi-Fi networks that have been backed up.

.PARAMETER NetworkName
    Specify the name of a specific Wi-Fi network to selectively back up or restore.

.PARAMETER ExportToText
    Exports all saved Wi-Fi network profiles and passwords to a plain text file.

.PARAMETER CompressBackup
    Compresses the backup folder into a .zip file.

.EXAMPLE
    Run with GUI:
        .\Manage-WiFiNetworks.ps1 -UseGUI

.EXAMPLE
    Run in CLI mode to back up all saved Wi-Fi networks:
        .\Manage-WiFiNetworks.ps1 -Backup

.EXAMPLE
    Run in CLI mode to restore Wi-Fi networks from a backup:
        .\Manage-WiFiNetworks.ps1 -Restore

.EXAMPLE
    Run in CLI mode to back up a specific network by name:
        .\Manage-WiFiNetworks.ps1 -Backup -NetworkName "MyNetwork"

.EXAMPLE
    Run in CLI mode to export Wi-Fi profiles and passwords to a plain text file:
        .\Manage-WiFiNetworks.ps1 -ExportToText
#>

param (
    [Parameter(Mandatory = $false, HelpMessage = "Back up all saved Wi-Fi networks to a folder on your desktop.")]
    [switch]$Backup,

    [Parameter(Mandatory = $false, HelpMessage = "Restore Wi-Fi networks from a previously created backup.")]
    [switch]$Restore,

    [Parameter(Mandatory = $false, HelpMessage = "Forget (delete) all saved Wi-Fi networks.")]
    [switch]$Wipe,

    [Parameter(Mandatory = $false, HelpMessage = "Delete the backup folder created during the Backup process.")]
    [switch]$Cleanup,

    [Parameter(Mandatory = $false, HelpMessage = "List all saved Wi-Fi networks currently added to Windows.")]
    [switch]$ListCurrent,

    [Parameter(Mandatory = $false, HelpMessage = "List all Wi-Fi networks that have been backed up.")]
    [switch]$ListBackup,

    [Parameter(Mandatory = $false, HelpMessage = "Specify the name of the Wi-Fi network for selective backup or restore.")]
    [string]$NetworkName,

    [Parameter(Mandatory = $false, HelpMessage = "Export Wi-Fi profiles and passwords to a plain text file.")]
    [switch]$ExportToText,
	
    [Parameter(Mandatory = $false, HelpMessage = "Compress the backup folder into a .zip file.")]
    [switch]$CompressBackup,
	
	[Parameter(Mandatory = $false, HelpMessage = "Launch the script with a GUI interface.")]
	[switch]$UseGUI
)

$ScriptDetails = @{
    Version      = [version]'1.2.0.0'
    InternalName = "Manage-WiFiNetworks"
}

$LoggingSettings = @{
    LogFileName   = $ScriptDetails.InternalName
    Console       = $true
    WriteLogFile  = $true
    DateTimeIsUTC = $false
}

# *******************************************************
# *******************************************************
# **                                                   **
# **                 PARAMETER BLOCK                   **
# **                                                   **
# *******************************************************
# *******************************************************

# Folder to backup and restore Wi-Fi networks from/to
$BackupDirName = "Wi-Fi Passwords"
# Gets the path for the users desktop
$DesktopPath = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::Desktop)
# Joins the folder name provided by the variable $BackupDirName to the user's desktop path
$BackupPath = Join-Path -Path $DesktopPath -ChildPath $BackupDirName

# Path to the script for execution when GUI has been used
$ScriptPath = $PSScriptRoot

# 
$LogFileTitle
$LogFilePath = Join-Path -Path "C:\temp" -ChildPath "WiFiManager.log"

# *******************************************************
# *******************************************************
# **                                                   **
# **            DO NOT EDIT BELOW THIS BLOCK           **
# **                                                   **
# **                INITIALISATION BLOCK               **
# **                                                   **
# *******************************************************
# *******************************************************

# Centralized logging
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

    if ($UseGUI -and $Script:GUITextBox -ne $null) {
        $Script:GUITextBox.AppendText("$LogOutput`n")
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

# Ensure elevated privileges
try {
    if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Log -Comment "This script must be run as an administrator." -Level ERROR
        exit
    }
} catch {
    Write-Log -Comment "Error checking for administrator privileges: $_" -Level ERROR
    exit
}

# Check for netsh availability
try {
    if (-not (Get-Command "netsh" -ErrorAction SilentlyContinue)) {
        Write-Log -Comment "The 'netsh' command is not available on this system. Aborting." -Level ERROR
        exit
    }
} catch {
    Write-Log -Comment "Error checking for netsh command: $_" -Level ERROR
    exit
}

# Ensure incompatible parameters are not used together
# Define parameter conflicts with descriptions
$conflictingGroups = @(
    @{ Params = @($Restore, $Wipe); Message = "Restore and Wipe operations cannot be used together. These are distinct actions that modify Wi-Fi profiles." },
    @{ Params = @($Backup, $Wipe); Message = "Backup and Wipe operations cannot be used together. These are distinct actions that modify Wi-Fi profiles." },
    @{ Params = @($Backup, $Restore); Message = "Backup and Restore operations cannot be used together. These are distinct actions that modify Wi-Fi profiles." },
    @{ Params = @($Backup, $Cleanup); Message = "Backup and Cleanup cannot be used together. Cleanup deletes the backup folder required for the backup process." },
    @{ Params = @($Restore, $Cleanup); Message = "Restore and Cleanup cannot be used together. Cleanup deletes the backup folder required for restoring profiles." },
    @{ Params = @($CompressBackup, $Cleanup); Message = "CompressBackup and Cleanup cannot be used together. Cleanup deletes the backup folder required for compression." },
    @{ Params = @($ExportToText, $Wipe); Message = "ExportToText and Wipe operations cannot be used together. Wipe deletes profiles, making export meaningless." },
    @{ Params = @($CompressBackup, $Wipe); Message = "CompressBackup and Wipe operations cannot be used together. Wipe removes all profiles, leaving nothing to compress." },
    @{ Params = @($ListCurrent, $Wipe); Message = "ListCurrent and Wipe cannot be used together. Wipe removes profiles, making listing meaningless." },
    @{ Params = @($ListBackup, $Cleanup); Message = "ListBackup and Cleanup cannot be used together. Cleanup deletes the backup folder required for listing backed-up profiles." },
)

# Loop to check for parameter conflicts in the command run
foreach ($group in $conflictingGroups) {
    $activeParams = $group.Params | Where-Object { $_ -eq $true }
    if ($activeParams.Count -gt 1) {
        $conflictingNames = $group.Params | ForEach-Object { ($_ | Get-Variable).Name } | Where-Object { $activeParams -contains $($_ | Get-Variable).Value }
        Write-Log -Comment "Conflicting parameters detected: $($conflictingNames -join ', ')." -Level ERROR
        Write-Log -Comment "${group.Message}" -Level ERROR
        Write-Log -Message "Try running the script with a single parameter from this group." -Level INFO
        exit
    }
}

# Validate NetworkName input
if ($NetworkName) {
    if ($NetworkName -notmatch '^[a-zA-Z0-9 _-!@#]{1,32}$') {
		Write-Log -Message "Invalid network name: '$NetworkName'." -Level ERROR
		Write-Log -Message "Allowed characters: alphanumerics, spaces, underscores, hyphens, and special characters (!, @, #)." -Level ERROR
		Write-Log -Message "Must be between 1 and 32 characters long." -Level ERROR
		exit
	}
}

# *******************************************************
# *******************************************************
# **                                                   **
# **                 FUNCTIONS BLOCK                   **
# **                                                   **
# *******************************************************
# *******************************************************

# *******************************************************
# **              REOCCURRING FUNCTIONS                **
# *******************************************************

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

# GUI confirmation function
function Confirm-Action {
    param (
        [string]$Comment
    )

    $Result = [System.Windows.Forms.MessageBox]::Show($Comment, "Confirmation", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question)
    return $Result -eq [System.Windows.Forms.DialogResult]::Yes
}

function Add-GUIButton {
    param (
        [string]$Text,
        [int]$Top,
        [int]$Left,
        [scriptblock]$OnClick
    )
    $Button = New-Object System.Windows.Forms.Button
    $Button.Text = $Text
    $Button.Top = $Top
    $Button.Left = $Left
    $Button.AutoSize = $true
    $Button.Anchor = "Top,Left"
    $Button.Add_Click($OnClick)
    return $Button
}

function Create-BackupFolder {
	# Checks for and creates the backup folder location if it doesn't exist
	if ($UseGUI -or $Backup) {
		if (-not (Test-Path -Path $BackupPath)) {
			Write-Log -Comment "Backup folder not found. Creating backup folder at $BackupPath..." -Level INFO
			New-Item -ItemType Directory -Path $BackupPath -Force | Out-Null
		}
	}
}

# *******************************************************
# **                  CORE FUNCTIONS                   **
# *******************************************************

# Function: ListSavedNetworks
function ListSavedNetworks {
    <#
    .SYNOPSIS
        Lists all Wi-Fi networks currently saved in Windows.
    .DESCRIPTION
        Uses the `netsh wlan show profiles` command to retrieve and display all saved Wi-Fi network profiles.
    #>

    Write-Log -Comment "Listing all saved Wi-Fi networks currently added to Windows..." -Level INFO
    $Networks = netsh wlan show profiles | ForEach-Object {
        if ($_ -match "All User Profile\s*:\s*(.+)$") {
            $matches[1]
        }
    }
    if ($Networks) {
        $Networks | ForEach-Object { Write-Log -Comment $_ -Level INFO }
    } else {
        Write-Log -Comment "No saved Wi-Fi networks found." -Level WARNING
    }
}

# Function: ListBackedUpNetworks
function ListBackedUpNetworks {
    <#
    .SYNOPSIS
        Lists all Wi-Fi networks that have been backed up.
    .DESCRIPTION
        Scans the backup folder to list all profiles that were previously exported.
    #>
    Write-Log -Comment "Listing all Wi-Fi networks that have been backed up..." -Level INFO
    if (Test-Path $BackupPath) {
        Get-ChildItem $BackupPath -Filter *.xml | ForEach-Object { $_.BaseName }
    } else {
        Write-Log -Comment "No backup folder found. Please perform a backup first." -Level WARNING
    }
}

# Function: Backup
function Backup {
    <#
    .SYNOPSIS
        Back up saved Wi-Fi network profiles to a folder.
    .DESCRIPTION
        Exports all or a specific Wi-Fi profile using the `netsh wlan export profile` command.
        Saves the profiles as XML files in the backup folder.
    #>
    
	# Check and create the backup folder if it doesn't exist
    Create-BackupFolder

    Write-Log -Comment "Backing up saved Wi-Fi networks..." -Level INFO
    try {
        if ($NetworkName) {
            Write-Log -Comment "Backing up Wi-Fi network: $NetworkName..." -Level INFO
            $result = netsh wlan export profile name="$NetworkName" key=clear folder="$BackupPath" 2>&1
            if ($result -notmatch "successfully exported") {
                Write-Log -Comment "Failed to back up network: $NetworkName. Ensure the network name is correct." -Level ERROR
                return
            }
            Write-Log -Comment "Backup completed successfully for network: $NetworkName" -Level INFO
        } else {
            $result = netsh wlan export profile key=clear folder="$BackupPath" 2>&1
            if ($result -notmatch "successfully exported") {
                Write-Log -Comment "Failed to back up one or more networks. Check permissions and network availability." -Level ERROR
                return
            }
            Write-Log -Comment "Backup complete for all network profiles." -Level INFO
        }
    } catch {
        Write-Log -Comment "Error during backup operation: $_" -Level ERROR
    }
}


# Function: Restore (with confirmation)
function Restore {
    <#
    .SYNOPSIS
        Restores Wi-Fi network profiles from a backup.
    .DESCRIPTION
        Imports saved Wi-Fi profiles from XML files in the backup folder using the `netsh wlan add profile` command.
    #>
	
	# Checks if the backup folder exists, if it doesn't it reports that the backup folder doesn't exist and exits as there is no work to do
    if (-not (Test-Path -Path $BackupPath)) {
        Write-Log -Comment "Backup folder not found. Cannot restore profiles. Please ensure backups are available." -Level ERROR
        return
    }

    Write-Log -Comment "Restoring Wi-Fi networks..." -Level INFO
    try {
        if ($NetworkName) {
            Write-Log -Comment "Restoring Wi-Fi network: $NetworkName..." -Level INFO
            $File = Get-ChildItem -Path $BackupPath -Filter "$NetworkName.xml" | Select-Object -First 1
            if ($File) {
                $result = netsh wlan add profile filename="$($File.FullName)" user=current 2>&1
                if ($result -notmatch "added to the system successfully") {
                    Write-Log -Comment "Failed to restore network: $NetworkName. Ensure the backup exists and is valid." -Level ERROR
                    return
                }
                Write-Log -Comment "Restored network: $NetworkName" -Level INFO
            } else {
                Write-Log -Comment "No backup found for network: $NetworkName" -Level ERROR
            }
        } else {
            $Files = Get-ChildItem -Path $BackupPath -Filter "*.xml"
            foreach ($File in $Files) {
                $result = netsh wlan add profile filename="$($File.FullName)" user=current 2>&1
                if ($result -notmatch "added to the system successfully") {
                    Write-Log -Comment "Failed to restore profile from file: $($File.FullName)" -Level ERROR
                } else {
                    Write-Log -Comment "Restored profile from file: $($File.FullName)" -Level INFO
                }
            }
        }
    } catch {
        Write-Log -Comment "Error during restore operation: $_" -Level ERROR
    }
}

# Function: Wipe (with confirmation)
function Wipe {
    <#
    .SYNOPSIS
        Deletes all saved Wi-Fi network profiles from the system.
    .DESCRIPTION
        Removes all Wi-Fi profiles using the `netsh wlan delete profile` command.
    #>

    Write-Log -Comment "WARNING: This will delete ALL saved Wi-Fi network profiles on this system. This action is irreversible and cannot be undone unless you have a backup." -Level WARNING

    # Confirm the action
    $Confirm = if ($UseGUI) { Confirm-Action "Are you sure you want to delete ALL saved Wi-Fi networks?" } else { Read-InYesNo -Prompt "Are you sure you want to delete ALL saved Wi-Fi networks?" }
    if (-not $Confirm) {
        Write-Log -Comment "Wipe operation cancelled by user." -Level WARNING
        return
    }

    Write-Log -Comment "Deleting all saved Wi-Fi network profiles..." -Level INFO

    try {
        $result = netsh wlan delete profile name="*" 2>&1
        if ($result -match "Profile.*on interface.*successfully deleted") {
            Write-Log -Comment "Successfully deleted all saved Wi-Fi profiles." -Level INFO
        } elseif ($result -match "No profiles.*") {
            Write-Log -Comment "No Wi-Fi profiles were found to delete." -Level WARNING
        } else {
            Write-Log -Comment "Failed to delete Wi-Fi profiles. Error: $result" -Level ERROR
        }
    } catch {
        Write-Log -Comment "Error during Wipe operation: $_" -Level ERROR
    }
}

# Function: ExportToPlainText  (with confirmation)
function ExportToPlainText {
    <#
    .SYNOPSIS
        Export Wi-Fi network names and passwords to a plain text file.
    .DESCRIPTION
        Extracts Wi-Fi profile names and passwords and writes them to a text file in the backup folder.
    #>

    Write-Log -Comment "WARNING: This will export Wi-Fi network names and passwords to a plain text file. Ensure this file is kept secure." -Level WARNING

    # Confirm the action
    $Confirm = if ($UseGUI) { Confirm-Action "Are you sure you want to export Wi-Fi networks and passwords to a text file?" } else { Read-InYesNo -Prompt "Are you sure you want to export Wi-Fi networks and passwords to a text file?" }
    if (-not $Confirm) {
        Write-Log -Comment "Export operation cancelled by user." -Level WARNING
        return
    }
	
	# Check and create the backup folder if it doesn't exist
    Create-BackupFolder

    $ExportPath = Join-Path -Path $DesktopPath -ChildPath "WiFi_Networks_Passwords.txt"
    Write-Log -Comment "Exporting Wi-Fi profiles and passwords to $ExportPath..." -Level INFO

    try {
        $Profiles = netsh wlan show profiles | ForEach-Object {
            if ($_ -match "All User Profile\s*:\s*(.+)$") {
                $matches[1]
            }
        }

        if ($Profiles) {
            $Output = "Wi-Fi Network Profiles and Passwords:`n`n"

            foreach ($Profile in $Profiles) {
                try {
                    $Details = netsh wlan show profile name="$Profile" key=clear 2>&1
                    if ($Details -match "Key Content\s*:\s*(.+)$") {
                        $Password = $matches[1]
                    } else {
                        $Password = "(No password saved)"
                    }
					# Writes to log the profile being recorded while not recording the password to the log
					Write-Log -Message "Network Name: $Profile, Password: <hidden>" -Level INFO
					
                    $Output += "Network Name: $Profile`nPassword: $Password`n`n"
                } catch {
                    Write-Log -Comment "Error retrieving details for profile: $Profile. Skipping." -Level WARNING
                    continue
                }
            }

            $Output | Set-Content -Path $ExportPath
            Write-Log -Comment "Export complete: $ExportPath." -Level INFO
        } else {
            Write-Log -Comment "No Wi-Fi profiles found to export." -Level INFO
        }
    } catch {
        Write-Log -Comment "Error during Export operation: $_" -Level ERROR
    }
}

# Function: CompressBackup
function CompressBackup {
    <#
    .SYNOPSIS
        Compresses the backup folder into a .zip file.
    .DESCRIPTION
        Uses the `Compress-Archive` cmdlet to compress the backup folder into a .zip archive for easier storage or sharing.
    #>

    Write-Log -Comment "Compressing backup folder..." -Level INFO

    try {
        if (-not (Test-Path $BackupPath)) {
            Write-Log -Comment "Backup path does not exist. Perform a backup first." -Level ERROR
            return
        }

        $Timestamp = Get-Date -Format "yyyy-MM-dd-HHmmss"
        $ZIPFileName = "$BackupDirName-$Timestamp.zip"
        $ZipFilePath = Join-Path -Path $DesktopPath -ChildPath $ZIPFileName

		if (Test-Path $ZipFilePath) {
			Write-Log -Message "A ZIP file with the same name already exists: $ZipFilePath." -Level WARNING
			$ConfirmOverwrite = if ($UseGUI) { Confirm-Action "Overwrite existing ZIP file?" } else { Read-InYesNo -Prompt "Overwrite existing ZIP file?" }
			if (-not $ConfirmOverwrite) {
				Write-Log -Message "Compression operation cancelled by user." -Level WARNING
				return
			}
		}

        Compress-Archive -Path $BackupPath -DestinationPath $ZipFilePath -Force

        if (-not (Test-Path $ZipFilePath)) {
            Write-Log -Comment "Error: ZIP file was not created successfully." -Level ERROR
        } else {
            Write-Log -Comment "Backup folder compressed: $ZipFilePath" -Level INFO
        }
    } catch {
        Write-Log -Comment "Error compressing backup folder: $_" -Level ERROR
    }
}

# Function: Cleanup backup folder (with confirmation)
function Cleanup {
    <#
    .SYNOPSIS
        Deletes the backup folder and all its contents.
    .DESCRIPTION
        Removes the backup folder and all exported XML files. This action is irreversible.
    #>
	
	# Checks if the backup folder exists, if it doesn't it reports that the backup folder doesn't exist and exits as there is no work to do
	if (-not (Test-Path -Path $BackupPath)) {
    Write-Log -Comment "Backup folder not found. Nothing to clean up." -Level INFO
    return
	}

    Write-Log -Comment "WARNING: This will delete the backup folder and all saved Wi-Fi profile backups." -Level WARNING
    Write-Log -Comment "WARNING: This action is irreversible. Ensure you no longer need these files before proceeding." -Level WARNING

    $Confirm = if ($UseGUI) { Confirm-Action "Delete backup folder?" } else { Read-InYesNo -Prompt "Delete backup folder?" }
    if (-not $Confirm) {
        Write-Log -Comment "Cleanup operation cancelled by user." -Level WARNING
        return
    }

    Write-Log -Comment "Deleting backup folder..." -Level INFO
    Remove-Item -Recurse -Force $BackupPath
    Write-Log -Comment "Done: Backup folder has been deleted." -Level INFO
}

# *******************************************************
# **                  GUI FUNCTIONS                    **
# *******************************************************
# Function to detect if Windows is in dark mode
function Get-DarkModePreference {
	<#
	.SYNOPSIS
		Detects if Windows is using dark mode.
	.DESCRIPTION
		This function checks the Windows registry to determine whether the operating system is currently using dark mode for applications.
	.INPUTS
		None.
	.OUTPUTS
		[bool] - Returns $true if dark mode is enabled, otherwise $false.
	.NOTES
		The function uses the registry path HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize to fetch the AppsUseLightTheme key.
	#>
	
	try {
		$RegPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"
		$AppsUseLightTheme = Get-ItemProperty -Path $RegPath -Name AppsUseLightTheme -ErrorAction Stop
		return -not [bool]$AppsUseLightTheme.AppsUseLightTheme
	} catch {
		# Default to light mode if the registry key is missing or unreadable
		return $false
	}
}

# Function to create styled buttons for consistency
function Create-StyledButton {
	<#
	.SYNOPSIS
		Creates a styled button for the GUI.
	.DESCRIPTION
		This function generates a button with consistent styling, including background color, font, and size. It also defines the action to perform when the button is clicked.
	.PARAMETER Text
		The text to display on the button.
	.PARAMETER X
		The X-coordinate (horizontal position) of the button.
	.PARAMETER Y
		The Y-coordinate (vertical position) of the button.
	.PARAMETER OnClick
		A script block that defines the action to perform when the button is clicked.
	.INPUTS
		[string] - Text
		[int] - X, Y
		[scriptblock] - OnClick
	.OUTPUTS
		[System.Windows.Forms.Button] - A configured button object.
	#>

	param (
		[string]$Text,  # Button label text
		[int]$X,  # X-coordinate position of the button
		[int]$Y,  # Y-coordinate position of the button
		[scriptblock]$OnClick  # Action to perform on button click
	)

	$Button = New-Object System.Windows.Forms.Button
	$Button.Text = $Text  # Assign the button's label
	$Button.Font = New-Object System.Drawing.Font("Segoe UI", 10)  # Font styling for button text
	$Button.BackColor = $ButtonColor  # Button background color based on theme
	$Button.ForeColor = $TextColor  # Button text color based on theme
	$Button.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat  # Flat styling for modern appearance
	$Button.Size = New-Object System.Drawing.Size($ButtonWidth, $ButtonHeight)  # Set button size
	$Button.Location = New-Object System.Drawing.Point($X, $Y)  # Position the button
	$Button.Add_Click($OnClick)  # Define the click action for the button
	return $Button  # Return the configured button
}

# Function to create the overall GUI
function Show-GUI {
	<#
	.SYNOPSIS
		Displays a GUI for managing Wi-Fi networks.
	.DESCRIPTION
		This function creates a graphical user interface (GUI) for managing Wi-Fi networks. 
		It provides buttons to perform actions such as backing up Wi-Fi profiles, restoring them, 
		wiping existing profiles, exporting network information, cleaning up files, listing saved 
		and backed-up networks, and compressing backup files. Logs are displayed in a dedicated text box.
	.EXAMPLE
		Show-GUI
		Launches the GUI for managing Wi-Fi networks.
	.NOTES
		- Requires Windows PowerShell with .NET Framework support.
		- Uses `System.Windows.Forms` to create the GUI.
		- Ensure that necessary functions (Backup, Restore, Wipe, etc.) are defined in the script.
	.INPUTS
		None. User interactions occur through the GUI.
	.OUTPUTS
		None. Logs and actions are displayed in the GUI.
	#>

	# Ensure GUI components (Windows Forms) are available. If not, provide a clear error message and fallback to CLI mode.
	if (-not (Get-Command -Name Add-Type -ErrorAction SilentlyContinue)) {
		Write-Log -Comment "Windows Forms components are not available. Falling back to CLI mode." -Level WARNING
		$UseGUI = $false		
		return
	}
	# Run the Add-Type command
    Add-Type -AssemblyName System.Windows.Forms
	
    # Detect dark mode preference
    $IsDarkMode = Get-DarkModePreference

    # Set colors based on theme
    if ($IsDarkMode) {
        $BackgroundColor = [System.Drawing.Color]::FromArgb(45, 45, 48)  # Dark gray background for dark mode
        $TextColor = [System.Drawing.Color]::WhiteSmoke  # Light text color for contrast in dark mode
        $ButtonColor = [System.Drawing.Color]::DimGray  # Buttons styled for dark mode
    } else {
        $BackgroundColor = [System.Drawing.Color]::WhiteSmoke  # Light gray background for light mode
        $TextColor = [System.Drawing.Color]::Black  # Dark text color for contrast in light mode
        $ButtonColor = [System.Drawing.Color]::LightGray  # Buttons styled for light mode
    }

    # Create the main form
    $Form = New-Object System.Windows.Forms.Form
    $Form.Text = "Wi-Fi Manager"  # Title of the form
    $Form.Size = New-Object System.Drawing.Size(720, 600)  # Size of the form
    $Form.StartPosition = "CenterScreen"  # Position the form at the center of the screen
    $Form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedSingle  # Restrict resizing for a cleaner appearance
    $Form.BackColor = $BackgroundColor  # Set the form's background color based on the theme

    # Add a header label
    $HeaderLabel = New-Object System.Windows.Forms.Label
    $HeaderLabel.Text = "Wi-Fi Network Manager"  # Header text
    $HeaderLabel.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)  # Font styling
    $HeaderLabel.Size = New-Object System.Drawing.Size(700, 30)  # Define label size
    $HeaderLabel.Location = New-Object System.Drawing.Point(10, 10)  # Position the label
    $HeaderLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter  # Center-align the text
    $HeaderLabel.ForeColor = $TextColor  # Set text color based on theme
    $Form.Controls.Add($HeaderLabel)

    # Add a description label for the network name TextBox on the left side of the TextBox
    $NetworkLabel = New-Object System.Windows.Forms.Label
    $NetworkLabel.Text = "Enter specific network name (optional):"  # Description for the TextBox
    $NetworkLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10)  # Font styling for the label
    $NetworkLabel.ForeColor = $TextColor  # Match the label text color to the theme
    $NetworkLabel.Location = New-Object System.Drawing.Point(10, 83)  # Position the label beside the TextBox
    $NetworkLabel.Size = New-Object System.Drawing.Size(240, 20)  # Define label size
    $Form.Controls.Add($NetworkLabel)  # Add the label to the form

    # Add a TextBox for specifying a network name
    $NetworkTextBox = New-Object System.Windows.Forms.TextBox
    $NetworkTextBox.Size = New-Object System.Drawing.Size(300, 30)  # Width and height of the TextBox
    $NetworkTextBox.Location = New-Object System.Drawing.Point(250, 80)  # Adjusted position of the TextBox
    $NetworkTextBox.Font = New-Object System.Drawing.Font("Segoe UI", 10)  # Font styling
    $Form.Controls.Add($NetworkTextBox)  # Add the TextBox to the form

    # Add a TextBox for logs
    $LogBox = New-Object System.Windows.Forms.TextBox
    $LogBox.Multiline = $true  # Enable multi-line text for logs
    $LogBox.ScrollBars = "Vertical"  # Add vertical scroll bar for longer logs
    $LogBox.ReadOnly = $true  # Prevent user editing of logs
    $LogBox.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right  # Allow the log box to resize with the form
    $LogBox.Size = New-Object System.Drawing.Size(680, 250)  # Set the size of the log box
    $LogBox.Location = New-Object System.Drawing.Point(10, 320)  # Adjust position to create space for buttons
    $LogBox.BackColor = $BackgroundColor  # Match the log box background to the form theme
    $LogBox.ForeColor = $TextColor  # Match the log box text color to the theme
    $Script:GUITextBox = $LogBox  # Assign the log box for centralized logging use

    # Define button dimensions and spacing
    $ButtonWidth = 150  # Set width for all buttons
    $ButtonHeight = 50  # Set height for all buttons
    $Margin = 20  # Space between buttons

    # Add buttons with actions
    $Form.Controls.Add((Create-StyledButton -Text "Backup Profiles" -X $Margin -Y ($Margin + 120) -OnClick {
        $NetworkName = $NetworkTextBox.Text  # Get the network name from the TextBox
        Write-Log "Initiating Backup for network: $NetworkName via GUI..." -Level "Info"
        Backup -NetworkName $NetworkName  # Call the Backup function with the network name
    }))

    $Form.Controls.Add((Create-StyledButton -Text "Restore Profiles" -X (($Margin * 2) + $ButtonWidth) -Y ($Margin + 120) -OnClick {
        $NetworkName = $NetworkTextBox.Text  # Get the network name from the TextBox
        Write-Log "Initiating Restore for network: $NetworkName via GUI..." -Level "Info"
        Restore -NetworkName $NetworkName  # Call the Restore function with the network name
    }))

    $Form.Controls.Add((Create-StyledButton -Text "Wipe System Profiles" -X (($Margin * 3) + ($ButtonWidth * 2)) -Y ($Margin + 120) -OnClick {
        Write-Log "Initiating Wipe via GUI..." -Level "Info"  # Log the action
        Wipe  # Call the Wipe function
    }))

    $Form.Controls.Add((Create-StyledButton -Text "Export To Plain-Text" -X (($Margin * 4) + ($ButtonWidth * 3)) -Y ($Margin + 120) -OnClick {
        Write-Log "Initiating Export via GUI..." -Level "Info"  # Log the action
        ExportToPlainText  # Call the ExportToPlainText function
    }))

    $Form.Controls.Add((Create-StyledButton -Text "Cleanup Backups" -X $Margin -Y (($Margin * 2) + $ButtonHeight + 120) -OnClick {
        Write-Log "Initiating Cleanup via GUI..." -Level "Info"  # Log the action
        Cleanup  # Call the Cleanup function
    }))

    $Form.Controls.Add((Create-StyledButton -Text "List Current System Profiles" -X (($Margin * 2) + $ButtonWidth) -Y (($Margin * 2) + $ButtonHeight + 120) -OnClick {
        Write-Log "Listing current Wi-Fi networks via GUI..." -Level "Info"  # Log the action
        ListSavedNetworks  # Call the ListSavedNetworks function
    }))

    $Form.Controls.Add((Create-StyledButton -Text "List Backup Profiles" -X (($Margin * 3) + ($ButtonWidth * 2)) -Y (($Margin * 2) + $ButtonHeight + 120) -OnClick {
        Write-Log "Listing backed-up Wi-Fi networks via GUI..." -Level "Info"  # Log the action
        ListBackedUpNetworks  # Call the ListBackedUpNetworks function
    }))

    $Form.Controls.Add((Create-StyledButton -Text "Compress Backup to ZIP" -X (($Margin * 4) + ($ButtonWidth * 3)) -Y (($Margin * 2) + $ButtonHeight + 120) -OnClick {
        Write-Log "Initiating Compression via GUI..." -Level "Info"  # Log the action
        CompressBackup  # Call the CompressBackup function
    }))

    # Add the log box to the form
    $Form.Controls.Add($LogBox)  # Attach the log box to the form to display activity logs

    # Show the form
    $Form.Add_Shown({ $Form.Activate() })  # Activate the form upon showing it
    [void]$Form.ShowDialog()  # Display the form to the user
}

# *******************************************************
# *******************************************************
# **                                                   **
# **                  MAIN CODE BLOCK                  **
# **                                                   **
# *******************************************************
# *******************************************************

if ($UseGUI) {
    Show-GUI
} else {
	if ($Backup) {
		Backup
	}
	if ($Wipe) {
		Wipe
	}
	if ($Restore) {
		Restore
	}
	if ($Cleanup) {
		Cleanup
	}
	if ($ListCurrent) {
		ListSavedNetworks
	}
	if ($ListBackup) {
		ListBackedUpNetworks
	}
	if ($ExportToText) {
		ExportToPlainText
	}
	if ($CompressBackup) {
		CompressBackup
	}
}

Write-Log -Comment "Script execution complete." -Level INFO
