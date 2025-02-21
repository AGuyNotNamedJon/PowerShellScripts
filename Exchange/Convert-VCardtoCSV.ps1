# Define the path to the VCard file and the output CSV file
$vcardFilePath = "e:\path\to\your\input.vcf"
$csvFilePath = "e:\path\to\your\output.csv"

# Initialize an array to hold the contact information
$contacts = @()

# Read the VCard file
$vcardContent = Get-Content -Path $vcardFilePath -Raw

# Split the content by "END:VCARD" to separate individual contacts
$vcardEntries = $vcardContent -split "END:VCARD"

foreach ($entry in $vcardEntries) {
    if ($entry -match "BEGIN:VCARD") {
        $contact = @{
            FullName = ""
            FirstName = ""
            LastName = ""
            Email = ""
            Phone = ""
            Address = ""
        }

        # Extract the contact details
        if ($entry -match "FN:(.*)") { $contact.FullName = $matches[1] }
        if ($entry -match "N:(.*?);(.*?);") {
            $contact.LastName = $matches[1]
            $contact.FirstName = $matches[2]
        }
        if ($entry -match "EMAIL.*:(.*)") { $contact.Email = $matches[1] }
        if ($entry -match "TEL.*:(.*)") { $contact.Phone = $matches[1] }
        if ($entry -match "ADR.*:(.*)") { $contact.Address = $matches[1] }

        # Add the contact to the array
        $contacts += New-Object PSObject -Property $contact
    }
}

# Export the contacts to a CSV file
$contacts | Export-Csv -Path $csvFilePath -NoTypeInformation

Write-Output "Conversion complete. CSV file saved to $csvFilePath"