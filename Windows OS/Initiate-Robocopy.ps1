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

.EXAMPLE
    PS> .\CopyFiles.ps1 -Source "\\Server\SharedFolder" -Destination "D:\BackupFolder"
    Basic usage with source and destination

.EXAMPLE
    PS> .\CopyFiles.ps1 -Source "\\Server\SharedFolder" -Destination "D:\BackupFolder" -Schedule Daily -Times "09:00","15:00"
    Schedule the script to run daily at 9:00 AM and 3:00 PM

.EXAMPLE
    PS> .\CopyFiles.ps1 -Source "\\Server\SharedFolder" -Destination "D:\BackupFolder" -Schedule Weekly -Days Monday,Wednesday -Times "10:00"
    Schedule the script to run weekly on Mondays and Wednesdays at 10:00 AM

.EXAMPLE
    PS> .\CopyFiles.ps1 -Source "\\Server\SharedFolder" -Destination "D:\BackupFolder" -Schedule Monthly -Weeks First,Third -Times "11:00"
    Schedule the script to run monthly on the first and third weeks at 11:00 AM

.EXAMPLE
    PS> .\CopyFiles.ps1 -Source "\\Server\SharedFolder" -Destination "D:\BackupFolder" -DryRun
    Perform a dry run to test the script
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
	Source = $("$Source") # Source folder
	Destination = $("$Destination") # Destination folder
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

# Ensure the log directory exists
if (-not (Test-Path -Path $LogPath)) {
    # Create the log directory if it does not exist.
    New-Item -ItemType Directory -Path $LogPath -Force | Out-Null
}

# Centralized logging
Function Write-Log {
    <#
    .SYNOPSIS
    Logs messages to a console, log file, or GUI with customizable options.

    .DESCRIPTION
    The Write-Log function enables users to log messages with various levels of importance (Debug, Error, Info, Warning, Verbose). 
    It supports writing to console output, a log file, and a GUI text box if available. Additionally, the function allows users to specify 
    whether the timestamp should be in UTC and customize error handling behavior.

    .INPUTS
    None. This function does not take input from the pipeline.

    .OUTPUTS
    None. This function does not produce output to the pipeline.

    .PARAMETER Comment
    The message to log.

    .PARAMETER LogFileName
    The path of the log file where the message should be written.

    .PARAMETER Console
    Indicates whether the message should be displayed on the console.

    .PARAMETER WriteLogFile
    Indicates whether the message should be written to the log file.

    .PARAMETER DateTimeIsUTC
    Specifies if the timestamp should be in UTC format.

    .PARAMETER ErrorAct
    Defines the error action preference for logging operations. Valid values are: Continue, Ignore, Inquire, SilentlyContinue, Stop, Suspend.

    .PARAMETER Level
    The severity level of the log message. Valid values are: Debug, Error, Info, Warning, Verbose.

    .PARAMETER UseGUI
    Indicates whether the message should be displayed in a GUI text box.

    .EXAMPLES
    Example 1:
    Write-Log -Comment "This is a test message" -LogFileName "C:\Logs\AppLog.txt" -Console $true -WriteLogFile $true -DateTimeIsUTC $false -Level "Info" -UseGUI $false

    Logs an informational message to both the console and a log file with a local timestamp.

    Example 2:
    Write-Log -Comment "An error occurred" -LogFileName "C:\Logs\ErrorLog.txt" -Console $true -WriteLogFile $true -DateTimeIsUTC $true -Level "Error" -UseGUI $true

    Logs an error message with a UTC timestamp to the console, log file, and GUI text box.

    .NOTES
    Ensure the $Script:GUITextBox variable is initialized if UseGUI is enabled. 
    The function supports only the defined log levels and error actions.
    #>

    param (
        # The message to log.
        [parameter(Mandatory = $true)]    
        [String]$Comment,

        # The path of the log file where the message should be written.
        [parameter(Mandatory = $true)]
        [String]$LogFileName,

        # Indicates whether the message should be displayed on the console.
        [parameter(Mandatory = $true)]
        [bool]$Console,

        # Indicates whether the message should be written to the log file.
        [parameter(Mandatory = $true)]
        [bool]$WriteLogFile,

        # Specifies if the timestamp should be in UTC format.
        [parameter(Mandatory = $true)]
        [bool]$DateTimeIsUTC,

        # Defines the error action preference for logging operations.
        [parameter(Mandatory = $false)]
        [ValidateSet("Continue", "Ignore", "Inquire", "SilentlyContinue", "Stop", "Suspend")]
        [String]$ErrorAct = "Continue",

        # The severity level of the log message.
        [parameter(Mandatory = $true)]
        [ValidateSet("Debug", "Error", "Info", "Warning", "Verbose")]
        [String]$Level,

        # Indicates whether the message should be displayed in a GUI text box.
        [parameter(Mandatory = $false)]
        [bool]$UseGUI
    )

    # Determine the timestamp format based on the UTC parameter.
    If ($DateTimeIsUTC) {
        $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff UTC"
    }
    else {
        $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff UTCK"
    }

    # Initialize default text colors for console output.
    $TextColour = @{
        Foregound  = "Gray"
        Background = "Black"
    }

    # Set log level prefix and color based on the severity level.
    Switch ($Level) {
        # Debug messages are highlighted in yellow.
        "Debug" {
            $LogLevel = "[DBG]"
            $TextColour.Foregound = "DarkYellow"
            break
        }
        # Errors are highlighted with a red background.
        "Error" {
            $LogLevel = "[ERR]"
            $TextColour.Foregound = "White"
            $TextColour.Background = "Red"
            break
        }
        # Informational messages are gray.
        "Info" {
            $LogLevel = "[INF]"
            $TextColour.Foregound = "DarkGray"
            break
        }
        # Warnings have a yellow background.
        "Warning" {
            $LogLevel = "[WRN]"
            $TextColour.Foregound = "Black"
            $TextColour.Background = "Yellow"
            break
        }
        # Verbose messages are cyan.
        "Verbose" {
            $LogLevel = "[VRB]"
            $TextColour.Foregound = "Cyan"
            break
        }
    }

    # Combine timestamp, log level, and comment into the log output string.
    $LogOutput = $TimeStamp + " -- " + $LogLevel + " -- " + $Comment

    # Write to the log file if enabled.
    if ($WriteLogFile) {
        Add-Content -Value $LogOutput -LiteralPath $LogFileName
    }

    # Write to the console if enabled.
    if ($Console) {
        Write-Host $LogOutput -ForegroundColor $TextColour.Foregound -BackgroundColor $TextColour.Background
    }

    # Append to the GUI text box if UseGUI is enabled and the GUITextBox variable is initialized.
    if ($UseGUI -and ($null -ne $Script:GUITextBox)) {
        $Script:GUITextBox.AppendText("$LogOutput`n")
    }

    # Handle log output based on the severity level and error action preference.
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
    Write-Log @LoggingSettings -Comment "Interval must be specified for custom schedules." -Level ERROR
    exit
}
if ($Schedule -eq "Weekly" -and (-not $Days -or $Days.Count -eq 0)) {
    Write-Log @LoggingSettings -Comment "At least one day must be specified for Weekly schedules." -Level ERROR
    exit
}
if ($Schedule -eq "Monthly" -and (-not $Days -or $Days.Count -eq 0 -or -not $Weeks -or $Weeks.Count -eq 0)) {
    Write-Log @LoggingSettings -Comment "Both days and weeks must be specified for Monthly schedules." -Level ERROR
    exit
}
if ($Schedule -and !$Times) {
    Write-Log @LoggingSettings -Comment "At least one time must be provided when using a schedule." -Level ERROR
    exit
}
if ($Schedule -eq "Weekly" -and (!$Days -or $Days.Count -eq 0)) {
    Write-Log @LoggingSettings -Comment "At least one day must be specified for Weekly schedules." -Level ERROR
    exit
}
if ($Schedule -eq "Monthly" -and (!$Weeks -or $Weeks.Count -eq 0)) {
    Write-Log @LoggingSettings -Comment "At least one week must be specified for Monthly schedules." -Level ERROR
    exit
}

# Validate Source and Destination paths
if (-not (Test-Path -Path $Source)) {
    Write-Log @LoggingSettings -Comment "Source path does not exist: $Source" -Level ERROR
    exit
}
if (-not (Test-Path -Path $Destination)) {
    Write-Log @LoggingSettings -Comment "Destination path does not exist: $Destination" -Level ERROR
    exit
}

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
Write-Log @LoggingSettings -Comment "Starting backup operation on $(Get-Date)" -Level Info
Write-Log @LoggingSettings -Comment "Source: $Source" -Level Info
Write-Log @LoggingSettings -Comment "Destination: $Destination" -Level Info
Write-Log @LoggingSettings -Comment "Log Path: $LogPath" -Level Info

# Clean up old logs based on retention period (Default older than 7 days)
$OldLogs = Get-ChildItem -Path $LogPath -Filter *.txt | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-$LogRetentionDays) }  # Identify old log files.
if ($OldLogs) {
    $OldLogs | Remove-Item -Force  # Remove old log files.
    Write-Log @LoggingSettings -Comment "Logs older than $LogRetentionDays days have been removed." -Level Info
}

# Add Task Scheduler job if -Schedule is specified
if ($Schedule) {
    Write-Log @LoggingSettings -Comment "Scheduling the script in Task Scheduler..." -Level Info

    foreach ($time in $Times) {
        # Define the action for the Task Scheduler to run this script
        $TaskAction = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-File `"$PSCommandPath`" -Source `"$Source`" -Destination `"$Destination`" -LogPath `"$LogPath`""

        switch ($Schedule) {
            "Daily" {
                # Create daily trigger for specified time.
                $TaskTrigger = New-ScheduledTaskTrigger -Daily -At $time
            }
            "Weekly" {
                foreach ($day in $Days) {
                    # Weekly trigger for specified days and time.
                    $TaskTrigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek $day -At $time
                }
            }
            "Monthly" {
                foreach ($week in $Weeks) {
                    # Monthly trigger for specific weeks, days, and time.
                    $TaskTrigger = New-ScheduledTaskTrigger -Monthly -WeeksOfMonth $week -DaysOfWeek $Days -At $time
                }
            }
            "Custom" {
                if (-not $Interval) {
                    # Ensure Interval is provided for custom schedules.
                    Write-Log @LoggingSettings -Comment "Interval must be specified for custom schedules." -Level Error
                    exit
                }
                # Custom interval-based trigger.
                $TaskTrigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(5) -RepetitionInterval (New-TimeSpan -Hours $Interval) -RepetitionDuration ([timespan]::MaxValue)
            }
        }

        # Define task settings
        $TaskSettings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
        # Unique task name based on time.
        $TaskName = "RobocopyBackupTask_$($TaskHash)_$($time)"

        # Register the task in Task Scheduler
        Register-ScheduledTask -Action $TaskAction -Trigger $TaskTrigger -Settings $TaskSettings -TaskName $TaskName -Description "Scheduled Robocopy backup task at $time"

        Write-Log @LoggingSettings -Comment "Task Scheduler job created successfully with the name '$TaskName'." -Level Info
    }
}

# Execute the Robocopy command
if ($DryRun) {
    Write-Log @LoggingSettings -Comment "Dry run enabled. No changes will be made." -Level Info
    # Add dry run parameter
    $RobocopyParams.DryRun = "/L"
}

# Set the multithreading parameter
if ($MTThreads) {
	$RobocopyParams.MultiThread = "/MT:$MTThreads"
}

try {
    Write-Log @LoggingSettings -Comment "Executing Robocopy..." -Level Info
	robocopy @RobocopyParams
	
    # Log successful completion status
	Write-Log @LoggingSettings -Comment "Robocopy completed successfully on $(Get-Date)." -Level Info
    Write-Log @LoggingSettings -Comment "Robocopy log file: $RobocopyLogFile" -Level Info
} catch {
    # Log failed completion status
    Write-Log @LoggingSettings -Comment "Robocopy encountered an error on $(Get-Date)." -Level Error
    Write-Log @LoggingSettings -Comment "Check the Robocopy log file for details: $RobocopyLogFile" -Level Error
    exit
}

try {
	# Parse the Robocopy log to extract summary details
	$Summary = Get-Content $RobocopyLogFile | Select-String -Pattern "^Total\|Copied\|Skipped\|Failed" -Context 0,0
    Write-Log @LoggingSettings -Comment "Robocopy completed successfully on $(Get-Date)." -Level Info
    Write-Log @LoggingSettings -Comment "Summary:" -Level Info
	$Summary | ForEach-Object { Write-Log @LoggingSettings -Comment $_ -Level Info }
} catch {
    Write-Log @LoggingSettings -Comment "An unknown error occured when parsing the log for summary details: $_" -Level Error
}

Write-Log @LoggingSettings -Comment "Backup completed. Check the logs for details:" -Level Info
Write-Log @LoggingSettings -Comment "Robocopy log: $RobocopyLogFile" -Level Info
Write-Log @LoggingSettings -Comment "Script log: $ScriptLogFile" -Level Info