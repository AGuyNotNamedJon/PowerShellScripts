<#
.SYNOPSIS
    This script synchronizes Azure AD with Active Directory on a remote server.

.DESCRIPTION
    The script establishes a remote session to the specified server, imports the ADSync module,
    and performs an initial delta sync cycle. After a 60-second wait, it performs a second delta sync cycle
    to confirm changes with Azure AD.

.PARAMETER server
    The name or IP address of the remote server where the ADSync module is installed.

.EXAMPLE
    PS C:\> .\Invoke-EntraSyncRemotely.ps1
    Enter server name or IP: server01
#>

# Prompt user for the server name or IP address
$server = read-host 'Enter server name or IP'

# Define the script blocks for importing the ADSync module and starting the sync cycle
$cmdImport = {Import-Module ADSync}
$cmdStartSync = {Start-ADSyncSyncCycle -PolicyType Delta}
$output = ''

# Start the remote session and perform the sync operations
Write-Host 'Starting remote session to ' $server ' to synchronise AzureAD with Active Directory'
Write-Host 'Importing ADSync module'
Invoke-Command -ComputerName $server -ScriptBlock $cmdImport

Write-Host 'Starting Initial Delta Sync Cycle'
$output = Invoke-Command -ComputerName $server -ScriptBlock $cmdStartSync
Write-Host 'Command Status'
Out-String -InputObject $output

Write-Host 'Waiting for ' $server ' to finish running the sync'
Write-Host 'Will perform a second sync cycle in 60 seconds to have changes confirmed by Azure AD'
Start-Sleep 60

Write-Host 'Starting Delta Sync Cycle'
$output = Invoke-Command -ComputerName $server -ScriptBlock $cmdStartSync
Write-Host 'Command Status'
Out-String -InputObject $output

Write-Host 'Exiting session'
Exit-PSSession
Write-Host 'Press any key to continue...'
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')