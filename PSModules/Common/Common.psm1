# Import the Read-InYesNo function for confirmation prompts
function Read-InYesNo {
    <#
		.SYNOPSIS
			Reads in if the user pressed Y or N
		.PARAMETER Prompt
			Specifies the prompt to show to the user, when requesting the input
		.PARAMETER CancelOption
			Specifies what the user should input to cancel the current request. E.G. Entering Q to abort
		.INPUTS
			N/A
		.DESCRIPTION
			Reads in if the user pressed Y or N. Code taken & Modified from https://stackoverflow.com/a/56207486
		.OUTPUTS
			A boolean (TRUE or FALSE) in response to the user's input
		.EXAMPLE
			PS> Read-InYesNo
			Requests the user to enter Y or N, doesnt allow the question to be aborted
		.EXAMPLE
			PS> Read-InYesNo -Prompt "Do you wish to continue (Y/N)? "
			Requests if the user wishes to continue the operation.
		.EXAMPLE
			PS> Read-InYesNo -Prompt "Do you wish to continue (Y/N), press Q to go back? " -CancelOption "Q"
			Requests if the user wishes to continue the operation. Allows the user to press Q to go back
		.NOTES
			Version:	1.2
			Author:		Nathaniel Mitchell
			Creation:	15 July 2022
			Changes:	Updated the way the prompt is shown
			
			Version:	1.1
			Author:		Nathaniel Mitchell
			Creation:	14 July 2022
			Changes:	Updated the way the prompt is shown
			
			Version:	1.0
			Author:		Nathaniel Mitchell
			Creation:	8 November 2021
			Changes:	Initial build
	#>
    [CmdletBinding()]
    param(
        [string]$Prompt = 'Please enter Y or N: ',
        [string]$CancelOption = $null
    )
    $ToPrompt = $Prompt + " (Y/N): "
    if ($CancelOption) { 
        Write-Host "Type $CancelOption to cancel." -ForegroundColor Yellow
    }
    while ($true) {
        Write-Host -NoNewLine $ToPrompt
        $TMPresult = [console]::ReadKey()
        [string]$result = $TMPresult.Key
        if ($result -eq $CancelOption) { Write-Host ""; return $null }
        switch ($result.ToUpper()) {
            "Y" { Write-Host ""; return $true; break }
            "N" { Write-Host ""; return $false; break }
            default { Write-Host ""; Write-Warning "Invalid input... Please enter Y or N."; Start-Sleep -Seconds 1; break }
        }
    }
}