###################################################
# Advanced Techniques
###################################################

# The powershell pipeline allows things like High-Order Functions.

# Group-Object is a handy cmdlet that does incredible things.
# It works much like a GROUP BY in SQL.

<#
 The following will get all the running processes,
 group them by Name,
 and tell us how many instances of each process we have running.
 Tip: Chrome and svcHost are usually big numbers in this regard.
#>
Get-Process | Foreach-Object ProcessName | Group-Object

# Useful pipeline examples are iteration and filtering.
1..10 | ForEach-Object { "Loop number $PSITEM" }
1..10 | Where-Object { $PSITEM -gt 5 } | ConvertTo-Json

# A notable pitfall of the pipeline is its performance when
# compared with other options.
# Additionally, raw bytes are not passed through the pipeline,
# so passing an image causes some issues.
