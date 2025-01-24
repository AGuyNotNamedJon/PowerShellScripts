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

function Get-WanIp {
	<#
	.SYNOPSIS
		Gets the external (WAN) IP address of the current computer
	.DESCRIPTION
		Uses ipify API to retrieve the current external IPv4 and/or IPv6 address
	.PARAMETER IpVersion
		Specifies which IP version to retrieve: 'IPv4', 'IPv6', or 'Both'. Defaults to 'IPv4'
	.OUTPUTS
		System.String or PSCustomObject. Returns the WAN IP address(es)
	.EXAMPLE
		PS> Get-WanIp
		Returns the current external IPv4 address
	.EXAMPLE
		PS> Get-WanIp -IpVersion IPv6
		Returns the current external IPv6 address
	.EXAMPLE
		PS> Get-WanIp -IpVersion Both
		Returns both IPv4 and IPv6 addresses as a custom object
	.NOTES
		Version: 1.0
		Author: Saul Rodgers
		Creation: 24/01/2025
	#>
	[CmdletBinding()]
	param(
		[ValidateSet('IPv4', 'IPv6', 'Both')]
		[string]$IpVersion = 'IPv4'
	)
	
	try {
		switch ($IpVersion) {
			'IPv4' {
				$response = Invoke-RestMethod -Uri 'https://api.ipify.org?format=json' -Method Get
				return $response.ip
			}
			'IPv6' {
				$response = Invoke-RestMethod -Uri 'https://api6.ipify.org?format=json' -Method Get
				return $response.ip
			}
			'Both' {
				$ipv4 = Invoke-RestMethod -Uri 'https://api.ipify.org?format=json' -Method Get
				$ipv6 = Invoke-RestMethod -Uri 'https://api6.ipify.org?format=json' -Method Get
				return [PSCustomObject]@{
					IPv4 = $ipv4.ip
					IPv6 = $ipv6.ip
				}
			}
		}
	}
	catch {
		Write-Error "Failed to retrieve WAN IP: $_"
		return $null
	}
}

function Get-IpGeoLocation {
	<#
	.SYNOPSIS
		Gets detailed geolocation information for an IP address
	.DESCRIPTION
		Uses ip-api.com to retrieve detailed information about an IP address including
		hostname, city, region, country, location, and organization
	.PARAMETER IpAddress
		The IP address to look up. If not specified, uses the current external IP
	.OUTPUTS
		PSCustomObject containing the geolocation information
	.EXAMPLE
		PS> Get-IpGeoLocation
		Returns geolocation information for the current external IP
	.EXAMPLE
		PS> Get-IpGeoLocation -IpAddress "9.9.9.9"
		Returns geolocation information for the specified IP address
	.NOTES
		Version: 1.0
		Author: Saul Rodgers
		Creation: 24/01/2025
		Uses free ip-api.com service - limited to 45 requests per minute
	#>
	[CmdletBinding()]
	param(
		[string]$IpAddress
	)
	
	try {
		# If no IP provided, get current external IP
		if (-not $IpAddress) {
			$IpAddress = Get-WanIp
		}

		# Query ip-api.com for geolocation data
		$uri = "http://ip-api.com/json/$IpAddress"
		$response = Invoke-RestMethod -Uri $uri -Method Get

		# Return formatted results
		return [PSCustomObject]@{
			IPAddress    = $IpAddress
			Hostname    = $response.reverse
			City       = $response.city
			Region     = $response.regionName
			Country    = $response.country
			Location   = "$($response.lat), $($response.lon)"
			ISP        = $response.isp
			ASN        = $response.as
			Organization = $response.org
		}
	}
	catch {
		Write-Error "Failed to retrieve geolocation data: $_"
		return $null
	}
}
