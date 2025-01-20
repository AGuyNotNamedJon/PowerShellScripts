# Logging Module

## Write-Log

### Overview
The **Logging** module is a versatile logging utility for PowerShell scripts. It allows users to log messages with different levels of importance (Debug, Error, Info, Warning, Verbose) to various outputs such as console, log files, or GUI interfaces.

### Features
- Logs messages with customizable severity levels.
- Supports output to console, log files, and GUI text boxes.
- Includes options for UTC or local timestamps.
- Customizable error handling behavior.

### Usage
#### Parameters
- **`-Comment`** (String, Mandatory): The message to log.
- **`-LogFileName`** (String, Mandatory): The path of the log file where the message should be written.
- **`-Console`** (Boolean, Mandatory): Indicates whether the message should be displayed on the console.
- **`-WriteLogFile`** (Boolean, Mandatory): Indicates whether the message should be written to the log file.
- **`-DateTimeIsUTC`** (Boolean, Mandatory): Specifies if the timestamp should be in UTC format.
- **`-ErrorAct`** (String, Optional): Defines the error action preference for logging operations. Default is `Continue`.
- **`-Level`** (String, Mandatory): The severity level of the log message. Valid values are: Debug, Error, Info, Warning, Verbose.
- **`-UseGUI`** (Boolean, Mandatory): Indicates whether the message should be displayed in a GUI text box.

#### Examples
##### Example 1: Log an informational message
```powershell
Write-Log -Comment "This is a test message" -LogFileName "C:\Logs\AppLog.txt" -Console $true -WriteLogFile $true -DateTimeIsUTC $false -Level "Info" -UseGUI $false
```
Logs an informational message to both the console and a log file with a local timestamp.

##### Example 2: Log an error message with UTC timestamp
```powershell
Write-Log -Comment "An error occurred" -LogFileName "C:\Logs\ErrorLog.txt" -Console $true -WriteLogFile $true -DateTimeIsUTC $true -Level "Error" -UseGUI $true
```
Logs an error message with a UTC timestamp to the console, log file, and GUI text box.

### Notes
- Ensure the `$Script:GUITextBox` variable is initialized if `UseGUI` is enabled.
- The function supports only the defined log levels and error actions.