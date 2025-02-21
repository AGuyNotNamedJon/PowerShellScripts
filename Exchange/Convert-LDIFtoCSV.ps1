# Define the input and output file paths
$ldifFilePath = "C:\Users\SaulRodgers\Downloads\Personal Address Book.ldif"
$csvFilePath = "C:\Users\SaulRodgers\Downloads\Personal Address Book.csv"

# Initialize an array to hold the CSV data
$csvData = @()

# Initialize a hashtable to hold the current entry's attributes
$currentEntry = @{}

# Start logging
Write-Host "Starting LDIF to CSV conversion."

try {
    # Read the LDIF file line by line
    $ldifContent = Get-Content -Path $ldifFilePath -ErrorAction Stop
    Write-Host "Successfully read LDIF file: $ldifFilePath"
} catch {
    Write-Host "Error reading LDIF file: $_"
    throw
}

try {
    foreach ($line in $ldifContent) {
        if ($line -match "^(dn|cn|mail|givenName|sn):\s*(.*)$") {
            $attribute = $matches[1]
            $value = $matches[2]
            $currentEntry[$attribute] = $value
        } elseif ($line -eq "") {
            # End of an entry, add it to the CSV data array
            $csvData += New-Object PSObject -Property $currentEntry
            $currentEntry = @{}
        }
    }

    # Add the last entry if the file does not end with a blank line
    if ($currentEntry.Count -gt 0) {
        $csvData += New-Object PSObject -Property $currentEntry
    }

    Write-Host "Successfully processed LDIF content."
} catch {
    Write-Host "Error processing LDIF content: $_"
    throw
}

try {
    # Export the CSV data to a file
    $csvData | Select-Object dn, cn, mail, givenName, sn | Export-Csv -Path $csvFilePath -NoTypeInformation -ErrorAction Stop
    Write-Host "Successfully exported CSV file: $csvFilePath"
} catch {
    Write-Host "Error exporting CSV file: $_"
    throw
}

Write-Host "Conversion complete. CSV file saved to $csvFilePath"
