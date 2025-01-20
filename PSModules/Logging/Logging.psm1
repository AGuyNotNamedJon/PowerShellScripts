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
        [parameter(Mandatory = $true)]
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
