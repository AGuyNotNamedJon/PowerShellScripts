# Connect to Microsoft Graph with required scopes
$AppId = ""
$TenantId = ""
$CertThumbPrint = ""
Connect-MgGraph  -NoWelcome -TenantId $TenantId -ClientId $AppId -CertificateThumbprint $CertThumbPrint

Import-Module Microsoft.Graph.PersonalContacts

# Define the email address of the shared mailbox to target
$SharedMailboxEmail = ""

# Import contacts from CSV file
# CSV should have headers: FullName,FirstName,LastName,PhoneNumber,Email,City,Description
$CsvPath = ".\contacts.csv"
If (!(Test-Path $CsvPath)) {
    Write-Host "CSV file not found at $CsvPath"
    Break
}

$ItemData = Import-Csv -Path $CsvPath | Select-Object @{
    Name = 'FullName'; Expression = {
        $parts = @($_.'First Name', $_.'Middle Name', $_.'Last Name') | Where-Object { $_ }
        $parts -join ' '
    }
},
@{Name = 'FirstName'; Expression = { $_.'First Name' } },
@{Name = 'MiddleName'; Expression = { $_.'Middle Name' } },
@{Name = 'LastName'; Expression = { $_.'Last Name' } },
@{Name = 'Title'; Expression = { $_.Title } },
@{Name = 'Suffix'; Expression = { $_.Suffix } },
@{Name = 'Nickname'; Expression = { $_.Nickname } },
@{Name = 'GivenYomi'; Expression = { $_.'Given Yomi' } },
@{Name = 'SurnameYomi'; Expression = { $_.'Surname Yomi' } },
@{Name = 'Email'; Expression = { $_.'E-mail Address' } },
@{Name = 'Email2'; Expression = { $_.'E-mail 2 Address' } },
@{Name = 'Email3'; Expression = { $_.'E-mail 3 Address' } },
@{Name = 'HomePhone'; Expression = { $_.'Home Phone' } },
@{Name = 'HomePhone2'; Expression = { $_.'Home Phone 2' } },
@{Name = 'BusinessPhone'; Expression = { $_.'Business Phone' } },
@{Name = 'BusinessPhone2'; Expression = { $_.'Business Phone 2' } },
@{Name = 'MobilePhone'; Expression = { $_.'Mobile Phone' } },
@{Name = 'Company'; Expression = { $_.Company } },
@{Name = 'JobTitle'; Expression = { $_.'Job Title' } },
@{Name = 'Department'; Expression = { $_.Department } },
@{Name = 'OfficeLocation'; Expression = { $_.'Office Location' } },
@{Name = 'BusinessStreet'; Expression = { $_.'Business Street' } },
@{Name = 'BusinessCity'; Expression = { $_.'Business City' } },
@{Name = 'BusinessState'; Expression = { $_.'Business State' } },
@{Name = 'BusinessPostalCode'; Expression = { $_.'Business Postal Code' } },
@{Name = 'BusinessCountry'; Expression = { $_.'Business Country/Region' } },
@{Name = 'Notes'; Expression = { $_.Notes } }

Write-Host ("Found {0} contacts to process from CSV" -f $ItemData.Count)

# Retrieve the shared mailbox by its email address
$SharedMailbox = Get-MgUser -Filter "userPrincipalName eq '$SharedMailboxEmail'"

If (!$SharedMailbox) {
    Write-Host "Shared mailbox not found"
    Break 
}
Else {
    Write-Host ("Found shared mailbox {0}" -f $SharedMailbox.displayName)
}

[int]$ContactAdded = 0

# Get the existing contacts of the shared mailbox to avoid duplicates
$SharedMailboxId = $SharedMailbox.Id
$Contacts = Get-MgUserContact -UserId $SharedMailboxId -All | Select-Object -ExpandProperty $EmailAddresses
$ContactsHash = @{}
ForEach ($Contact in $Contacts) {
    # Before adding, check that the contact has an email address and that it's not already in the hash
    $EmailAddress = $Contact.emailAddresses[0].address
    If ($EmailAddress -and $null -eq $ContactsHash[$EmailAddress]) {
        $ContactsHash.Add($EmailAddress, $Contact.displayName)
    }
}

ForEach ($Item in $ItemData) {
    $ContactAddCompleted = $false

    $NewContactEmail1 = @{
        address = $($Item.Email)
        name    = $($Item.FullName)
    }
    $NewContactEmail2 = @{
        address = $($Item.Email2)
        name    = $($Item.FullName)
    }
    $NewContactEmail3 = @{
        address = $($Item.Email3)
        name    = $($Item.FullName)
    }
    $NewContactEmails = @($NewContactEmail1, $NewContactEmail2, $NewContactEmail3) | Where-Object { $_.address } 

    # Build body for new contact
    $NewContact = @{
        givenName       = $Item.FirstName
        surname         = $Item.LastName
        displayName     = $Item.FullName
        emailAddresses  = $NewContactEmails
        businessPhones  = @($Item.BusinessPhone, $Item.BusinessPhone2) | Where-Object { $_ }
        mobilePhone     = $Item.MobilePhone
        homePhones      = @($Item.HomePhone, $Item.HomePhone2) | Where-Object { $_ }
        jobTitle        = $Item.JobTitle
        companyName     = $Item.Company
        department      = $Item.Department
        businessAddress = @{
            street          = $Item.BusinessStreet
            city            = $Item.BusinessCity
            state           = $Item.BusinessState
            postalCode      = $Item.BusinessPostalCode
            countryOrRegion = $Item.BusinessCountry
        } | Where-Object { $_ }
    }

    $NewContact

    # Check if the contact already exists and add it if it's not there
    #If ($null -eq $ContactsHash[$Item.Email]) {
    Write-Host ("Adding contact {0} to {1}" -f $Item.FullName, $SharedMailbox.displayName)
    Try {
        New-MgUserContact -UserId $SharedMailboxEmail -DisplayName $NewContact
        $ContactAddCompleted = $true
    }
    Catch {
        Write-Host ("Failed to add contact {0} to {1}" -f $Item.FullName, $SharedMailbox.displayName)
    }
    If ($ContactAddCompleted) {
        $ContactAdded++
        $ContactAddCompleted = $false
    }   
    #}
}

Write-Host ("Added {0} contacts to the shared mailbox {1}" -f $ContactAdded, $SharedMailbox.displayName)
