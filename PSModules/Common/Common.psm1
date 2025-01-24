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
	.INPUTS
		[System.String]
		You can pipe a string containing an IP address to this function.
	.OUTPUTS
		[PSCustomObject] Returns a custom object containing the following properties:
		- Status: Success or fail status of the query
		- Message: Error message if status is fail
		- DetailedMessage: Additional information about the error message
		- IPAddress: IP address that was queried
		- Query: Queried IP address according to API
		- Continent: Continent name
		- ContinentCode: Two-letter continent code
		- Hostname: Reverse DNS of the IP
		- PostCode: Postal/ZIP code
		- City: City name
		- District: District/neighborhood
		- Region: State/region name
		- RegionCode: Region code
		- Country: Country name 
		- CountryCode: Two-letter country code (ISO 3166-1 alpha-2)
		- Latitude: Decimal latitude
		- Longitude: Decimal longitude
		- Coordinates: Combined latitude and longitude
		- TimeZone: IANA timezone
		- UTCOffset: UTC offset in seconds
		- Currency: Local currency code
		- ISP: Internet Service Provider
		- ASN: Autonomous System Number
		- ASName: AS name
		- Organization: Organization name
		- IsMobile: Mobile network flag
		- IsProxy: Proxy/VPN detection
		- IsHosting: Hosting provider flag
	.EXAMPLE
		PS> Get-IpGeoLocation
		Returns geolocation information for the current external IP
	.EXAMPLE
		PS> Get-IpGeoLocation -IpAddress "9.9.9.9"
		Returns geolocation information for the specified IP address
	.NOTES
		Uses free ip-api.com service - limited to 45 requests per minute

		Version: 1.1
			Added additional returned fields for geolocation data
			Added data input validation and error handling
			Implemented retry mechanism for rate-limited requests
			Improved commenting for easier understanding
		Version: 1.0
			Intial version
		Author: Saul Rodgers
		Creation: 24/01/2025
	#>
	[CmdletBinding()]
	param(
		[Parameter(
			Position = 0,
			ValueFromPipeline = $true,
			HelpMessage = "IP address to lookup. If not specified, uses current external IP"
		)]
		[string]$IpAddress,

		[Parameter(
			HelpMessage = "Maximum number of retry attempts for rate-limited requests",
			Mandatory = $false
		)]
		[ValidateRange(1, 10)]
		[int]$MaxRetries = 3,

		[Parameter(
			HelpMessage = "Maximum wait time in seconds between retries",
			Mandatory = $false
		)]
		[ValidateRange(60, 600)]
		[int]$MaxRetryWaitSeconds = 300
	)

	# If no IP provided, get current external IP
	if (-not $IpAddress) {
		$IpAddress = Get-WanIp
	}

	# Define API parameters
	$APIBasePath = "http://ip-api.com/json" # API endpoint
	$APIFields = "66846719" # All fields provided by the API
	$retryCount = 0 # Retry counter reset to 0

	# Main execution loop for handling rate limits and retries
	# This loop continues until successful or max retries reached
	do {
		try {
			# Construct the API request URL by combining base path, IP address, and fields parameter
			# fields parameter is a bitmask that determines which data fields to return
			$uri = "$APIBasePath/$IpAddress`?fields=$APIFields"
			# Execute HTTP GET request to the API endpoint
			$response = Invoke-WebRequest -Uri $uri -Method Get
			
			# Check for rate limiting via X-R1 header
			# X-R1=0 indicates we've hit the rate limit
			if ($response.Headers["X-R1"] -eq "0") {
				# X-Ttl header contains the time to wait before next request
				$waitTime = [int]$response.Headers["X-Ttl"]
				Write-Warning "Rate limit reached. Waiting $waitTime seconds..."
				Start-Sleep -Seconds $waitTime
				continue  # Restart the loop after waiting period
			}

			# Convert JSON response to PowerShell object
			# Handle API error responses where status="fail"
			# This block processes error cases and provides detailed feedback
			# Returns a simplified object with error information instead of full geolocation data
			if ($data.status -eq "fail") {
				# Map API error messages to more detailed explanations using regex pattern matching
				switch -Regex ($data.message) {
					"private range" { 
						# Handle cases where IP is in private network ranges (RFC 1918)
						$detailedMessage = "The IP address is in a private range (e.g., 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16) and cannot be geolocated."
					}
					"reserved range" { 
						# Handle cases where IP is in IANA reserved ranges
						$detailedMessage = "The IP address is in a reserved range (e.g., 127.0.0.1, 0.0.0.0) and cannot be geolocated."
					}
					"invalid query" { 
						# Handle malformed IP addresses or invalid API queries
						$detailedMessage = "The IP address format is invalid or the query is malformed."
					}
				}
				# Log error and return simplified error object
				Write-Error "API endpoint returned a failure status: $($data.message) : $detailedMessage"
				return [PSCustomObject]@{
					IPAddress       = $IpAddress             # Original queried IP
					Query           = $data.query            # Queried IP address according to API. Usful in determining if IP was resolved correctly
					Status          = $data.status           # API failure status
					Message         = $data.message          # Original API error message
					DetailedMessage = $detailedMessage       # Human-friendly error explanation
				}
			}

			# Create and return a structured PSCustomObject with all geolocation data
			# Data is organized into logical groupings for better readability
			return [PSCustomObject]@{
				# Query metadata section
				IPAddress     = $IpAddress                     # Queried IP address
				Query         = $data.query                    # Queried IP address according to API. Usful in determining if IP was resolved correctly
				Status        = $data.status                   # API response status (success or fail). Fail would have returned a message in previous block

				# Geographic location section
				Continent     = $data.continent                # Continent name
				ContinentCode = $data.continentCode            # Two-letter continent code (ISO 3166-1 alpha-2)
				Hostname      = $data.reverse                  # Reverse DNS lookup
				PostCode      = $data.zip                      # Postal/ZIP code
				City          = $data.city                     # City name
				District      = $data.district                 # District/neighborhood
				Region        = $data.regionName               # State/region name
				RegionCode    = $data.region                   # Region code
				Country       = $data.country                  # Country name
				CountryCode   = $data.countryCode              # Two-letter country code

				# Geographical coordinates and time section
				Latitude      = $data.lat                      # Decimal latitude
				Longitude     = $data.lon                      # Decimal longitude
				Coordinates   = "$($data.lat), $($data.lon)"   # Combined coordinates
				TimeZone      = $data.timezone                 # IANA timezone
				UTCOffset     = $data.offset                   # UTC offset in seconds
				Currency      = $data.currency                 # Local currency code

				# Network information section
				ISP           = $data.isp                      # Internet Service Provider
				ASN           = $data.as                       # Autonomous System Number
				ASName        = $data.asname                   # AS name
				Organization  = $data.org                      # Organization name

				# Connection characteristics
				IsMobile      = $data.mobile                   # Mobile network flag
				IsProxy       = $data.proxy                    # Proxy/VPN detection
				IsHosting     = $data.hosting                  # Hosting provider flag
			}
		}
		catch {
			# Handle rate limiting errors (HTTP 429)
			# Implements exponential backoff strategy
			if ($_.Exception.Response.StatusCode -eq 429) {
				$retryCount++
				if ($retryCount -le $MaxRetries) {
					# Calculate random wait time between 60s and MaxRetryWaitSeconds
					$waitTime = Get-Random -Minimum 60 -Maximum $MaxRetryWaitSeconds
					Write-Warning "Rate limit (429) hit. Attempt $retryCount of $MaxRetries. Waiting $waitTime seconds..."
					Start-Sleep -Seconds $waitTime
					continue
				}
			}
			# Handle all other exceptions
			Write-Error "Failed to retrieve geolocation data: $_"
			return $null
		}
	} while ($retryCount -le $MaxRetries)
}

function Get-DnsServerList {
	<#
	.SYNOPSIS
		Gets configured DNS servers from all network adapters
	.DESCRIPTION
		Retrieves a unique list of DNS server addresses from all network adapters on the system.
		Can filter results to show only IPv4, IPv6, or both address types.
	.PARAMETER IpVersion
		Specifies which IP version to retrieve: 'IPv4', 'IPv6', or 'Both'. Defaults to 'Both'
	.OUTPUTS
		[System.String[]] Array of unique DNS server IP addresses
	.EXAMPLE
		PS> Get-DnsServerList
		Returns all unique DNS server addresses (both IPv4 and IPv6)
	.EXAMPLE
		PS> Get-DnsServerList -IpVersion IPv4 
		Returns only IPv4 DNS server addresses
	.NOTES
		Version: 1.0
		Author: Saul Rodgers
		Creation: 24/01/2025
	#>

	[CmdletBinding()]
	param(
		[ValidateSet('IPv4', 'IPv6', 'Both')]
		[string]$IpVersion = 'Both'
	)

	try {
		$dnsServers = Get-DnsClientServerAddress | Where-Object {
			switch ($IpVersion) {
				'IPv4' { $_.AddressFamily -eq 'IPv4' }
				'IPv6' { $_.AddressFamily -eq 'IPv6' }
				'Both' { $_.AddressFamily -in @('IPv4', 'IPv6') }
			}
		} | Where-Object ServerAddresses | 
		Select-Object -ExpandProperty ServerAddresses |
		Sort-Object -Unique

		return $dnsServers
	}
	catch {
		Write-Error "Failed to retrieve DNS servers: $_"
		return $null
	}
}