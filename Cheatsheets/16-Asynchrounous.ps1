###################################################
# Asynchronous Event Registration
###################################################

#### Register for filesystem events
$Watcher = [System.IO.FileSystemWatcher]::new('c:\tmp')
Register-ObjectEvent -InputObject $Watcher -EventName Created -Action {
  Write-Host -Object 'New file created!!!'
}

#### Perform a task on a timer (ie. every 5000 milliseconds)
$Timer = [System.Timers.Timer]::new(5000)
Register-ObjectEvent -InputObject $Timer -EventName Elapsed -Action {
  Write-Host -ForegroundColor Blue -Object 'Timer elapsed! Doing some work.'
}
$Timer.Start()

###################################################
# Jobs and Asynchronous Operations
###################################################

<#
 Asynchronous functions exist in the form of jobs.
 Typically a procedural language,
 Powershell can operate non-blocking functions when invoked as Jobs.
#>

# This function is known to be non-optimized, and therefore slow.
$installedApps = Get-CimInstance -ClassName Win32_Product

# If we had a script, it would hang at this func for a period of time.
$scriptBlock = {Get-CimInstance -ClassName Win32_Product}
Start-Job -ScriptBlock $scriptBlock

# This will start a background job that runs the command.
# You can then obtain the status of jobs and their returned results.
$allJobs = Get-Job
$jobResponse = Get-Job | Receive-Job
