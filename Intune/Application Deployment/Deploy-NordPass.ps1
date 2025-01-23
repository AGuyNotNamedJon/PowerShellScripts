#Requires -Version 5.1
#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Installs or uninstalls NordPass password manager.
.DESCRIPTION
    Downloads and installs the latest version of NordPass password manager from the official source.
    Can also uninstall NordPass if specified. Includes retry logic for downloads and proper error handling.
.EXAMPLE
    Install NordPass
    PS> .\Deploy-NordPass.ps1 -Install
.EXAMPLE
    Install NordPass with a forced hard reboot
    PS> .\Deploy-NordPass.ps1 -Install -ForceHardReboot
.EXAMPLE
    Install NordPass with a forced soft reboot
    PS> .\Deploy-NordPass.ps1 -Install -ForceSoftReboot
.EXAMPLE
    Uninstall NordPass
    PS> .\Deploy-NordPass.ps1 -Uninstall
.EXAMPLE
    Install NordPass in User Mode
    PS> .\Deploy-NordPass.ps1 -Install -UserMode
#>

param (
    [PSDefaultValue(Help = 'Uninstall the previously installed NordPass.', Value = 'FALSE')]
    [switch]$Uninstall,
    [PSDefaultValue(Help = 'Bypasses the script and do not process anything', Value = 'FALSE')]
    [switch]$BypassAndQuit,
    [PSDefaultValue(Help = 'Force hard reboot once the script has completed. User will be notified, will trigger with-in 120 minutes.', Value = 'FALSE')]
    [switch]$ForceHardReboot,
    [PSDefaultValue(Help = 'Force soft reboot once the script has completed. User will be notified, will not occur forcably.', Value = 'FALSE')]
    [switch]$ForceSoftReboot,
    [PSDefaultValue(Help = 'Perform the installation in User Mode. Makes the required Reg Key, Logging, and other modifications for monitoring and automations.', Value = 'FALSE')]
    [Switch]$UserMode
)

$ScriptDetails = @{
    Version      = [version]'1.0.0.0'
    InternalName = "Deploy-NordPass"
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
# **            DO NOT EDIT BELOW THIS BLOCK           **
# **                                                   **
# **                INITIALISATION BLOCK               **
# **                                                   **
# *******************************************************
# *******************************************************

# Reset Error Code catching variable
$ExitCode = 0

# If we are running as a 32-bit process on an x64 system, re-launch as a 64-bit process
If ([Environment]::Is64BitProcess -ne [Environment]::Is64BitOperatingSystem) {
    & "$($env:WINDIR)\SysNative\WindowsPowerShell\v1.0\powershell.exe" -ExecutionPolicy bypass -NoProfile -File "$PSCommandPath"
    $Output_Log = "Process launched as 32-bit. Relaunching as 64-bit process."
    Write-Host $OutputLog
    Exit $lastexitcode
}

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

# Path where the NordPass installer will be downloaded
$DownloadPath = "$env:TEMP\NordPassSetup.exe"
# URL to download the latest version of NordPass
$DownloadURL = "https://downloads.npass.app/windows/NordPassSetup.exe"

# Retry logic settings
# Number of times to retry downloading the NordPass installer
$maxRetries = 3
# Time to wait between download retries in seconds
$RetrySleep = 30
# Flag to indicate if the download was successful
$downloadSuccess = $false

# Location of the NordPass installation folder and executables
$InstalltionFolder = "$env:SYSTEMDRIVE\Users\$env:USERNAME\Appdata\Local\Programs\nordpass"
$InstallationFile = "NordPass.exe"
$UninstallFile = "Uninstall NordPass.exe"
# Full path to the NordPass executable
$InstallationPath = Join-Path -Path $InstalltionFolder -ChildPath $InstallationFile
# Local path to the NordPass uninstaller
$UninstallationPath = Join-Path -Path $InstalltionFolder -ChildPath $UninstallFile


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

# Internal Functions go here

# *******************************************************
# *******************************************************
# **                                                   **
# **                  MAIN CODE BLOCK                  **
# **                                                   **
# *******************************************************
# *******************************************************

if (-not $Uninstall) {
    # Number of times the download has been attempted
    $retryCount = 0
    # Download the latest version of NordPass with retry logic
    while (-not $downloadSuccess -and $retryCount -lt $maxRetries) {
        try {
            Invoke-WebRequest -Uri $DownloadURL -OutFile $DownloadPath -UseBasicParsing
            $downloadSuccess = $true
            Write-Log @LoggingSettings -Comment "NordPass downloaded successfully." -Level Info
        }
        catch {
            $retryCount++
            Write-Log @LoggingSettings -Comment "Failed to download NordPass. Attempt $retryCount of $maxRetries. Error: $_" -Level Warning
            Start-Sleep -Seconds $RetrySleep
        }
    }

    if (-not $downloadSuccess) {
        Write-Log @LoggingSettings -Comment "Failed to download NordPass after $maxRetries attempts." -Level Error
        $ExitCode = 1
    }

    try {
        # Check if NordPass is installed
        $NordPassInstalled = Test-Path "$env:PROGRAMFILES\NordPass"
        if ($nordPassInstalled) {
            # Check if the NordPass application is running
            $NordPassProcess = Get-Process -Name "NordPass" -ErrorAction SilentlyContinue
            if ($NordPassProcess) {
                # Close the NordPass application if it is running
                $NordPassProcess | Stop-Process -Force
                Write-Log @LoggingSettings -Comment "NordPass application closed successfully." -Level Info
            }
            else {
                Write-Log @LoggingSettings -Comment "NordPass application is not running." -Level Info
            }
        }
        else {
            Write-Log @LoggingSettings -Comment "NordPass is not installed." -Level Warning
        }
    }
    catch {
        Write-Log @LoggingSettings -Comment "Failed to close NordPass application: $_" -Level Error
        $ExitCode = 1
    }

    if ($ExitCode -ne 1) {
        # Install the latest version of NordPass silently
        try {
            & $DownloadPath /S
            Start-Sleep -Seconds 60 # Wait for the installation to complete
        }
        catch {
            Write-Log @LoggingSettings -Comment "Failed to install NordPass: $_" -Level Error
            $ExitCode = 1
        }
    }

    if ($ExitCode -ne 1) {
        # Check if the installation was successful
        Start-Sleep -Seconds 60 # Wait for the installation to complete
        if (Test-Path $InstallationPath) {
            Write-Log @LoggingSettings -Comment "NordPass installed successfully." -Level Info
        }
        else {
            Write-Log @LoggingSettings -Comment "NordPass installation failed. The application file was not found at $InstallationPath." -Level Error
            $ExitCode = 1
        }    
    }
}

if ($Uninstall) {
    try {
        # Check if NordPass is installed
        if (Test-Path $InstallationPath) {
            # Uninstall NordPass silently
            & $UninstallationPath /S
            Start-Sleep -Seconds 60 # Wait for the uninstallation to complete

            # Check if the uninstallation was successful
            if (-not (Test-Path $InstallationPath)) {
                Write-Log @LoggingSettings -Comment "NordPass uninstalled successfully." -Level Info
            }
            else {
                Write-Log @LoggingSettings -Comment "NordPass uninstallation failed. The application is still present." -Level Error
                $ExitCode = 1
            }
        }
        else {
            Write-Log @LoggingSettings -Comment "NordPass is not installed. Nothing to uninstall." -Level Warning
        }
    }
    catch {
        Write-Log @LoggingSettings -Comment "Failed to uninstall NordPass: $_" -Level Error
        $ExitCode = 1
    }
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

# Sets the correct type of Exit Code Type based on the Exit Code
$ExitCodeType = switch ($ExitCode) {
    0 { 'Success' }
	   1707 { 'Success' }
	   3010 { 'SoftReboot' }
	   1641 { 'HardReboot' }
	   1618 { 'Retry' }
    default { 'Failed' }
}

# Force a soft reboot if set to irregardless of the Exit Code
if ($ForceSoftReboot) {
    $ExitCodeType = "SoftReboot"
    $ExitCode = 3010
}

# Force a hard reboot if set to irregardless of the Exit Code
if ($ForceHardReboot) {
    $ExitCodeType = "HardReboot"
    $ExitCode = 1641
}

# Outputs the correct log value of the 
Switch ($ExitCodeType) {
    "Su`cess" {
        If ($Uninstall) {
            $Output_Log = "Completed Uninstallation."
            Write-Log @LoggingSettings -Comment $Output_Log -Level Debug
        }
        Else {
            $Output_Log = "Completed Installation."
            Write-Log @LoggingSettings -Comment $Output_Log -Level Debug
        }
    }
    "SoftReboot" {
        $Output_Log = "**** Soft Reboot of computer is required before continuing. User will be prompted to reboot at their discression."
        Write-Log @LoggingSettings -Comment $Output_Log -Level Warning
    }
    "HardReboot" {
        $Output_Log = "**** Hard Reboot of computer is required before continuing. Forcing the reboot to complete in the next 120 minutes."
        Write-Log @LoggingSettings -Comment $Output_Log -Level Warning
    }
    "Retry" {
        $Output_Log = "**** Script needs to be retryed before success. Will try again in 5 minutes."
        Write-Log @LoggingSettings -Comment $Output_Log -Level Warning
    }
    "Failed" {
        $Output_Log = "**** Script failed to complete."
        Write-Log @LoggingSettings -Comment $Output_Log -Level Error
    }
}

$Output_Log = "**** **** **** **** ****"
Write-Log @LoggingSettings -Comment $Output_Log -Level Debug
# Exits script with the Exit Code defined in the script
Exit $ExitCode