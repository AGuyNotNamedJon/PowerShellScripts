###################################################
# Remote Management
###################################################

# Remoting into computers is easy.
Enter-PSSession -ComputerName RemoteComputer

# Once remoted in, you can run commands as if you're local.
RemoteComputer\PS> Get-Process powershell

<#
Handles  NPM(K)    PM(K)      WS(K)     CPU(s)     Id  SI ProcessName
-------  ------    -----      -----     ------     --  -- -----------
   1096      44   156324     179068      29.92  11772   1 powershell
    545      25    49512      49852             25348   0 powershell
#>
RemoteComputer\PS> Exit-PSSession

<#
 Powershell is an incredible tool for Windows management and Automation.
 Let's take the following scenario:
 You have 10 servers.
 You need to check whether a service is running on all of them.
 You can RDP and log in, or PSSession to all of them, but why?
 Check out the following
#>

$serverList = @(
    'server1',
    'server2',
    'server3',
    'server4',
    'server5',
    'server6',
    'server7',
    'server8',
    'server9',
    'server10'
)

[scriptblock]$script = {
    Get-Service -DisplayName 'Task Scheduler'
}

foreach ($server in $serverList) {
    $cmdSplat = @{
        ComputerName  = $server
        JobName       = 'checkService'
        ScriptBlock   = $script
        AsJob         = $true
        ErrorAction   = 'SilentlyContinue'
    }
    Invoke-Command @cmdSplat | Out-Null
}

<#
 Here we've invoked jobs across many servers.
 We can now Receive-Job and see if they're all running.
 Now scale this up 100x as many servers :)
#>
