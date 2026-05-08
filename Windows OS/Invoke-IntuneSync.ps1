<#
.SYNOPSIS
    Triggers a sync with the Intune Management Extension.
.DESCRIPTION
    This script triggers a sync with the Intune Management Extension and verifies the completion of the sync operation.
.EXAMPLE
    Run the script to trigger a sync with the Intune Management Extension:
    PS> .\Invoke-IntuneSync.ps1

.NOTES

#>

# *******************************************************
# *******************************************************
# **                                                   **
# **              INTERNAL VARIABLES BLOCK             **
# **                                                   **
# *******************************************************
# *******************************************************

# Path to the Intune Management Extension log file
$IntuneManagementExtensionLogPath = "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log"

# *******************************************************
# *******************************************************
# **                                                   **
# **            DO NOT EDIT BELOW THIS BLOCK           **
# **                  MAIN CODE BLOCK                  **
# **                                                   **
# *******************************************************
# *******************************************************

# Trigger the Intune sync by opening the intunemanagementextension URI scheme
try {
    $Shell = New-Object -ComObject Shell.Application
    $Shell.open("intunemanagementextension://syncapp")
}
catch {
    Write-Output "FAILURE: An error occurred while triggering the Intune sync. Error: $_"
    exit 1
}

# Wait for Intune Management Extension to process the sync request
Start-Sleep -Seconds 60

# Check the IME log for confirmation that the sync completed successfully
try {
    # Retrieve the last 50 log entries and filter for sync completion indicators
    $RecentIMESyncLogs = Get-Content $IntuneManagementExtensionLogPath -Tail 50 -ErrorAction Stop | Where-Object { $_ -match "Starting app check in|done processing 200" }

    if ($RecentIMESyncLogs) {
        Write-Output "SUCCESS: Sync activity confirmed in IME log."
        exit 0
    }
    else {
        Write-Output "FAILURE: No recent sync activity found in IME log."
        exit 1
    }
}
catch {
    Write-Output "FAILURE: Unable to read IME log file. Error: $_"
    exit 1
}
