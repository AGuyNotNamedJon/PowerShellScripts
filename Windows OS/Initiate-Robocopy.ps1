<#
.SYNOPSIS
A PowerShell script to copy files from a shared network folder to a local drive using Robocopy.

.DESCRIPTION
This script is designed to:
1. Copy files from a network share to a local drive.
2. Preserve all file attributes and permissions.
3. Avoid modifications to the source files.
4. Generate two separate logs: one for Robocopy operations and another for script execution details.
5. Minimize network impact by optimizing Robocopy parameters.
6. Clean up old log files to save disk space.
7. Optionally schedule itself in Task Scheduler for periodic execution.

.PARAMETER Source
The full path of the source network folder.

.PARAMETER Destination
The full path of the local destination folder.

.PARAMETER LogPath
(Optional) The directory where log files will be saved. Defaults to the user's Documents\RobocopyLogs folder.

.PARAMETER Schedule
(Optional) Adds the script to Task Scheduler with a specified frequency (Daily, Weekly, Monthly, or custom intervals such as every 1, 2, 4, 6, 8, or 12 hours).

.PARAMETER Interval
(Optional) Specifies the interval in hours for custom schedules (e.g., every 1, 2, 4, 6, 8, or 12 hours). Used only when Schedule is set to "Custom".

.PARAMETER Times
(Optional) Specifies one or more times for the script to run, in HH:mm format. Applies to Daily, Weekly, and Monthly schedules.

.PARAMETER Days
(Optional) Specifies one or more days of the week for Weekly schedules (e.g., Monday, Wednesday).

.PARAMETER Weeks
(Optional) Specifies one or more weeks of the month for Monthly schedules (e.g., First, Second, Third).

.PARAMETER MTThreads
(Optional) Specifies the number of threads to use for Robocopy multithreading (default is 4).

.PARAMETER LogRetentionDays
(Optional) Specifies the number of days to retain log files. Defaults to 7.

.PARAMETER DryRun
(Optional) If set, performs a dry run without making actual changes or copying files.

.EXAMPLES
# Example 1: Basic usage with source and destination
.\CopyFiles.ps1 -Source "\\Server\SharedFolder" -Destination "D:\BackupFolder"

# Example 2: Schedule the script to run daily at 9:00 AM and 3:00 PM
.\CopyFiles.ps1 -Source "\\Server\SharedFolder" -Destination "D:\BackupFolder" -Schedule Daily -Times "09:00","15:00"

# Example 3: Schedule the script to run weekly on Mondays and Wednesdays at 10:00 AM
.\CopyFiles.ps1 -Source "\\Server\SharedFolder" -Destination "D:\BackupFolder" -Schedule Weekly -Days Monday,Wednesday -Times "10:00"

# Example 4: Schedule the script to run monthly on the first and third weeks at 11:00 AM
.\CopyFiles.ps1 -Source "\\Server\SharedFolder" -Destination "D:\BackupFolder" -Schedule Monthly -Weeks First,Third -Times "11:00"

# Example 5: Perform a dry run to test the script
.\CopyFiles.ps1 -Source "\\Server\SharedFolder" -Destination "D:\BackupFolder" -DryRun
#>

param (
    [Parameter(Mandatory=$true)]
    [string]$Source,  # Source network folder

    [Parameter(Mandatory=$true)]
    [string]$Destination,  # Local backup folder

    [Parameter(Mandatory=$false)]
    [string]$LogPath = "$env:USERPROFILE\Documents\RobocopyLogs",  # Default log location

    [Parameter(Mandatory=$false)]
    [ValidateSet("Daily", "Weekly", "Monthly", "Custom")]
    [string]$Schedule,  # Schedule frequency

    [Parameter(Mandatory=$false)]
    [ValidateSet(1, 2, 4, 6, 8, 12)]
    [int]$Interval,  # Interval in hours for custom schedules

    [Parameter(Mandatory=$false)]
    [string[]]$Times,  # One or more times for the task to run

    [Parameter(Mandatory=$false)]
    [ValidateSet("Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday")]
    [string[]]$Days,  # Days of the week for Weekly schedules

    [Parameter(Mandatory=$false)]
    [ValidateSet("First", "Second", "Third", "Fourth", "Last")]
    [string[]]$Weeks,  # Weeks of the month for Monthly schedules

    [Parameter(Mandatory=$false)]
    [int]$MTThreads = 4,  # Number of threads for Robocopy multithreading

    [Parameter(Mandatory=$false)]
    [int]$LogRetentionDays = 7,  # Retention period for log files (in days)

    [Parameter(Mandatory=$false)]
    [switch]$DryRun  # Perform a dry run without actual changes
)

$ScriptDetails = @{
    Version      = [version]'0.1.0.0'
    InternalName = "Initiate-Robocopy"
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

# Generate unique hash for Task Scheduler names
$TaskHash = [System.BitConverter]::ToString((New-Object System.Security.Cryptography.SHA256Managed).ComputeHash([System.Text.Encoding]::UTF8.GetBytes("$Source|$Destination|$Schedule"))).Replace("-", "").Substring(0, 8)

# Generate log file names
$RobocopyLogFile = Join-Path -Path $LogPath -ChildPath "RobocopyLog_$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss').txt"
$ScriptLogFile = Join-Path -Path $LogPath -ChildPath "ScriptLog_$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss').txt"

# Parameter block for Robocopy settings
$RobocopyParams = @{
	Source = '"$($Source)"' # Source folder
	Destination = '"$($Destination)"' # Destination folder
    Recursive = "/E" # Copies all subdirectories, including empty ones, to ensure a complete backup.
    CopyAll = "/COPYALL" # Copies all file attributes, including security permissions.
    RetryCount = "/R:3" # Retries up to 3 times on failing files to minimize network impact.
    WaitTime = "/W:5" # Waits 5 seconds between retries.
    BackupMode = "/ZB" # Uses restartable mode and switches to backup mode if access is denied.
    MultiThread = "/MT:4" # Enables multithreading with 4 threads to optimize performance without overwhelming the network.
    Log = "/LOG:" # Logs the output to a specified file.
    NoProgress = "/NP"  # Suppresses progress information to make logs more readable.
    Display = "/TEE" # Displays the log on the console while writing to the log file.
	# Additional optional parameters for other scenarios (commented out):
	# $Mirror = "/MIR"  # Mirrors the directory structure, including deletions (use with caution).
	# $Move = "/MOV"  # Moves files instead of copying them (deletes from source).
	# $ExcludeDirs = "/XD Temp Logs"  # Excludes specific directories (e.g., Temp, Logs).
	# $ExcludeFiles = "/XF *.tmp *.bak"  # Excludes specific file types (e.g., .tmp, .bak).
	# $FileAge = "/MAXAGE:30"  # Copies only files modified within the last 30 days.
	# $MinSize = "/MIN:1024"  # Copies only files larger than 1024 bytes.
	# $Compress = "/COMPRESS"  # Compresses file data during transfer.
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
        Write-Log @LoggingSettings -Comment "This script must be run as an administrator." -Level ERROR
        exit
    }
} catch {
    Write-Log @LoggingSettings -Comment "Error checking for administrator privileges: $_" -Level ERROR
    exit
}

# Validate schedule parameters
if ($Schedule -eq "Custom" -and -not $Interval) {
    throw "Interval must be specified for custom schedules."
}
if ($Schedule -eq "Weekly" -and (-not $Days -or $Days.Count -eq 0)) {
    throw "At least one day must be specified for Weekly schedules."
}
if ($Schedule -eq "Monthly" -and (-not $Days -or $Days.Count -eq 0 -or -not $Weeks -or $Weeks.Count -eq 0)) {
    throw "Both days and weeks must be specified for Monthly schedules."
}

# Validate Source and Destination paths
if (-not (Test-Path -Path $Source)) {
    throw "Source path does not exist: $Source"
}
if (-not (Test-Path -Path $Destination)) {
    throw "Destination path does not exist: $Destination"
}

# Ensure the log directory exists
if (-not (Test-Path -Path $LogPath)) {
    New-Item -ItemType Directory -Path $LogPath -Force | Out-Null  # Create the log directory if it does not exist.
}

$RobocopySuccess = $False

# *******************************************************
# *******************************************************
# **                                                   **
# **                 FUNCTIONS BLOCK                   **
# **                                                   **
# *******************************************************
# *******************************************************

# Add functions here

# *******************************************************
# *******************************************************
# **                                                   **
# **                  MAIN CODE BLOCK                  **
# **                                                   **
# *******************************************************
# *******************************************************

# Write script execution details to the script log
Add-Content -Path $ScriptLogFile -Value "Starting backup operation on $(Get-Date)"
Add-Content -Path $ScriptLogFile -Value "Source: $Source"
Add-Content -Path $ScriptLogFile -Value "Destination: $Destination"
Add-Content -Path $ScriptLogFile -Value "Log Path: $LogPath"

# Validate schedule parameters
if ($Schedule -and !$Times) {
    throw "At least one time must be provided when using a schedule."
}
if ($Schedule -eq "Weekly" -and (!$Days -or $Days.Count -eq 0)) {
    throw "At least one day must be specified for Weekly schedules."
}
if ($Schedule -eq "Monthly" -and (!$Weeks -or $Weeks.Count -eq 0)) {
    throw "At least one week must be specified for Monthly schedules."
}

# Clean up old logs based on retention period (Default older than 7 days)
$OldLogs = Get-ChildItem -Path $LogPath -Filter *.txt | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-$LogRetentionDays) }  # Identify old log files.
if ($OldLogs) {
    $OldLogs | Remove-Item -Force  # Remove old log files.
    Add-Content -Path $ScriptLogFile -Value "Logs older than $LogRetentionDays days have been removed."  # Log the cleanup action.
}

# Add Task Scheduler job if -Schedule is specified
if ($Schedule) {
    Write-Output "Scheduling the script in Task Scheduler..."

    foreach ($time in $Times) {
        # Define the action for the Task Scheduler to run this script
        $TaskAction = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-File `"$PSCommandPath`" -Source `"$Source`" -Destination `"$Destination`" -LogPath `"$LogPath`""

        switch ($Schedule) {
            "Daily" {
                $TaskTrigger = New-ScheduledTaskTrigger -Daily -At $time  # Create daily trigger for specified time.
            }
            "Weekly" {
                foreach ($day in $Days) {
                    $TaskTrigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek $day -At $time  # Weekly trigger for specified days and time.
                }
            }
            "Monthly" {
                foreach ($week in $Weeks) {
                    $TaskTrigger = New-ScheduledTaskTrigger -Monthly -WeeksOfMonth $week -DaysOfWeek $Days -At $time  # Monthly trigger for specific weeks, days, and time.
                }
            }
            "Custom" {
                if (-not $Interval) {
                    throw "Interval must be specified for custom schedules."  # Ensure Interval is provided for custom schedules.
                }
                $TaskTrigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(5) -RepetitionInterval (New-TimeSpan -Hours $Interval) -RepetitionDuration ([timespan]::MaxValue)  # Custom interval-based trigger.
            }
        }

        # Define task settings
        $TaskSettings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
        $TaskName = "RobocopyBackupTask_$($TaskHash)_$($time)"  # Unique task name based on time.

        # Register the task in Task Scheduler
        Register-ScheduledTask -Action $TaskAction -Trigger $TaskTrigger -Settings $TaskSettings -TaskName $TaskName -Description "Scheduled Robocopy backup task at $time"

        Write-Output "Task Scheduler job created successfully with the name '$TaskName'."
    }
}

# Execute the Robocopy command
if ($DryRun) {
    Write-Output "Dry run enabled. No changes will be made."
    $RobocopyParams.DryRun = "/L"  # Add dry run parameter
}

if ($MTThreads) {
	$RobocopyParams.MultiThread = "/MT:$MTThreads"  # Set the multithreading parameter
}

try {
	Write-Output "Executing Robocopy..."
	robocopy @RobocopyParams
	
	$RobocopySuccess = $True
} catch {
	Add-Content -Path $ScriptLogFile -Value "Robocopy encountered an error on $(Get-Date): $_"
	throw $_  # Re-throw the error after logging
}

try {
	# Parse the Robocopy log to extract summary details
	$Summary = Get-Content $RobocopyLogFile | Select-String -Pattern "^Total\|Copied\|Skipped\|Failed" -Context 0,0
	Add-Content -Path $ScriptLogFile -Value "Robocopy completed successfully on $(Get-Date)."  
	Add-Content -Path $ScriptLogFile -Value "Summary:"  
	$Summary | ForEach-Object { Add-Content -Path $ScriptLogFile -Value $_ }
} catch {
	Add-Content -Path $ScriptLogFile -Value "An unknown error occured when parsing the log for summary details: $_"
	throw $_  # Re-throw the error after logging
}

# Log completion status to the script log
if ($RobocopySuccess) {
    Add-Content -Path $ScriptLogFile -Value "Robocopy completed successfully on $(Get-Date)."
    Add-Content -Path $ScriptLogFile -Value "Robocopy log file: $RobocopyLogFile"
} else {
    Add-Content -Path $ScriptLogFile -Value "Robocopy encountered an error on $(Get-Date)."
    Add-Content -Path $ScriptLogFile -Value "Check the Robocopy log file for details: $RobocopyLogFile"
}

Write-Output "Backup completed. Check the logs for details:"
Write-Output "Robocopy log: $RobocopyLogFile"
Write-Output "Script log: $ScriptLogFile"  # Inform the user where logs can be found.
