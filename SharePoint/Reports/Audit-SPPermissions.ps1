#Requires -Version 7.4
#Requires -RunAsAdministrator
#Requires -Modules PnP.PowerShell

<#
.SYNOPSIS
    Generates a comprehensive report of permissions across all SharePoint sites in a tenant.
.DESCRIPTION
    This script connects to a SharePoint Online tenant and retrieves detailed information about permissions at various levels, including sites, lists, folders, and items.
    It generates a CSV report that outlines user and group permissions, permission types, and inheritance settings.
    The script is useful for auditing SharePoint permissions and ensuring compliance with organizational policies.
.EXAMPLE
    Run the script to generate a permissions report for all sites in the tenant:
    PS> .\GenerateSharePointPermissionsReport.ps1

.EXAMPLE
    Include item-level permissions in the report:
    PS> .\GenerateSharePointPermissionsReport.ps1 -ScanItemLevel

.EXAMPLE
    Generate a report recursively, including sub-sites and folders:
    PS> .\GenerateSharePointPermissionsReport.ps1 -Recursive -ScanFolders

.EXAMPLE
    Generate a report for a specific site collection:
    PS> .\GenerateSharePointPermissionsReport.ps1 -SiteURL "https://contoso.sharepoint.com/sites/ExampleSite"

.NOTES
    Dependencies:
    - PowerShell 7.4 or later
    - PnP.PowerShell module
    
    Limitations:
    - Ensure the Entra ID App is configured with the necessary permissions.
    - The script assumes administrative access to SharePoint Online.

    Usage considerations:
    - Update the variables for your tenant, such as tenant name and certificate path.
    - Error handling is included for most operations, but edge cases should be tested in your environment.
#>

# *******************************************************
# *******************************************************
# **                                                   **
# **              INTERNAL VARIABLES BLOCK             **
# **                                                   **
# *******************************************************
# *******************************************************

# Tenant name
$tenant = "contoso"

# Connect to SharePoint Online using Entra ID App for Interactive Login
# Define the Entra ID App's client ID, tenant ID
$clientId = "01234567-89ab-cdef-0123-456789abcdef"
#$tenantId = "01234567-89ab-cdef-0123-456789abcdef"

# Defines the location of the path to the application certificate
$certificatePath = "C:\temp\certificates\appauthentications\Audit-SPPermissions.pfx"

# Define the output CSV file path
$outputFile = "C:\temp\reports\Audit-SPPermissions\SharePointPermissions.csv"

# Defines different URL types based on the tenant name
$tenantM365URL = $tenant + ".onmicrosoft.com"
#$tenantSPURL = $tenant + ".sharepoint.com"
$tenantSPAdminURL = $tenant + "-admin.sharepoint.com"

# *******************************************************
# *******************************************************
# **                                                   **
# **            DO NOT EDIT BELOW THIS BLOCK           **
# **                                                   **
# **                INITIALISATION BLOCK               **
# **                                                   **
# *******************************************************
# *******************************************************

# Initialize an array to hold the permissions data
$permissions = @()

# *******************************************************
# *******************************************************
# **                                                   **
# **                 FUNCTIONS BLOCK                   **
# **                                                   **
# *******************************************************
# *******************************************************

# Function to retrieve permissions for a given SharePoint object (site, list, folder, item)
Function Get-PnPPermissions([Microsoft.SharePoint.Client.SecurableObject]$Object) {
    # Determine the type of the object (e.g., Site, List, Folder, Item)
    Switch ($Object.TypedObject.ToString()) {
        "Microsoft.SharePoint.Client.Web" {
            $ObjectType = "Site"
            $ObjectURL = $Object.URL
            $ObjectTitle = $Object.Title
        }
        "Microsoft.SharePoint.Client.ListItem" { 
            If ($Object.FileSystemObjectType -eq "Folder") {
                $ObjectType = "Folder"
                # Get the URL and name of the Folder
                $Folder = Get-PnPProperty -ClientObject $Object -Property Folder
                $ObjectTitle = $Object.Folder.Name
                $ObjectURL = $("{0}{1}" -f $Web.Url.Replace($Web.ServerRelativeUrl, ''), $Object.Folder.ServerRelativeUrl)
            }
            Else {
                # Determine if the object is a File or List Item
                # Get the URL of the Object
                Get-PnPProperty -ClientObject $Object -Property File, ParentList
                If ($Object.File.Name) {
                    $ObjectType = "File"
                    $ObjectTitle = $Object.File.Name
                    $ObjectURL = $("{0}{1}" -f $Web.Url.Replace($Web.ServerRelativeUrl, ''), $Object.File.ServerRelativeUrl)
                }
                else {
                    $ObjectType = "List Item"
                    $ObjectTitle = $Object["Title"]
                    # Get the URL of the List Item
                    $DefaultDisplayFormUrl = Get-PnPProperty -ClientObject $Object.ParentList -Property DefaultDisplayFormUrl                     
                    $ObjectURL = $("{0}{1}?ID={2}" -f $Web.Url.Replace($Web.ServerRelativeUrl, ''), $DefaultDisplayFormUrl, $Object.ID)
                }
            }
        }
        Default { 
            $ObjectType = "List or Library"
            $ObjectTitle = $Object.Title
            # Get the URL of the List or Library
            $RootFolder = Get-PnPProperty -ClientObject $Object -Property RootFolder     
            $ObjectURL = $("{0}{1}" -f $Web.Url.Replace($Web.ServerRelativeUrl, ''), $RootFolder.ServerRelativeUrl)
        }
    }
   
    # Retrieve permissions assigned to the object
    Get-PnPProperty -ClientObject $Object -Property HasUniqueRoleAssignments, RoleAssignments
 
    # Check if the object has unique permissions
    $HasUniquePermissions = $Object.HasUniqueRoleAssignments
     
    # Loop through each permission assignment and extract details
    $PermissionCollection = @()
    Foreach ($RoleAssignment in $Object.RoleAssignments) { 
        # Get the Permission Levels assigned to the object and memberships
        Get-PnPProperty -ClientObject $RoleAssignment -Property RoleDefinitionBindings, Member
 
        # Identify the principal type (User, SP Group, AD Group)
        $PermissionType = $RoleAssignment.Member.PrincipalType
    
        # Extract assigned permission levels, excluding "Limited Access"
        $PermissionLevels = $RoleAssignment.RoleDefinitionBindings | Select-Object -ExpandProperty Name
        #Remove Limited Access
        $PermissionLevels = ($PermissionLevels | Where-Object { $_ -ne "Limited Access" }) -join ","
 
        # Skip principals with no permissions
        If ($PermissionLevels.Length -eq 0) { Continue }
 
        # Handle SharePoint group members
        If ($PermissionType -eq "SharePointGroup") {
            # Get Group Members of the SharePoint Group
            $GroupMembers = Get-PnPGroupMember -Identity $RoleAssignment.Member.LoginName
                 
            # Skip empty groups
            If ($GroupMembers.count -eq 0) { Continue }
            $GroupUsers = ($GroupMembers | Select-Object -ExpandProperty Title) -join ","
 
            # Add permission data to the collection
            $Permissions = New-Object PSObject
            $Permissions | Add-Member NoteProperty Object($ObjectType)
            $Permissions | Add-Member NoteProperty Title($ObjectTitle)
            $Permissions | Add-Member NoteProperty URL($ObjectURL)
            $Permissions | Add-Member NoteProperty HasUniquePermissions($HasUniquePermissions)
            $Permissions | Add-Member NoteProperty Users($GroupUsers)
            $Permissions | Add-Member NoteProperty Type($PermissionType)
            $Permissions | Add-Member NoteProperty Permissions($PermissionLevels)
            $Permissions | Add-Member NoteProperty GrantedThrough("SharePoint Group: $($RoleAssignment.Member.LoginName)")
            $PermissionCollection += $Permissions
        }
		# Handle Directly Assigned individual users
        Else {
            # Add permission data to the collection
            $Permissions = New-Object PSObject
            $Permissions | Add-Member NoteProperty Object($ObjectType)
            $Permissions | Add-Member NoteProperty Title($ObjectTitle)
            $Permissions | Add-Member NoteProperty URL($ObjectURL)
            $Permissions | Add-Member NoteProperty HasUniquePermissions($HasUniquePermissions)
            $Permissions | Add-Member NoteProperty Users($RoleAssignment.Member.Title)
            $Permissions | Add-Member NoteProperty Type($PermissionType)
            $Permissions | Add-Member NoteProperty Permissions($PermissionLevels)
            $Permissions | Add-Member NoteProperty GrantedThrough("Direct Permissions")
            $PermissionCollection += $Permissions
        }
    }
    # Export permissions data to the CSV file
    $PermissionCollection | Export-CSV $outputFile -NoTypeInformation -Append
}

# Function to retrieve permissions for all lists in a given web
Function Get-PnPListPermission([Microsoft.SharePoint.Client.Web]$Web) {
    # Retrieve all lists from the web
    $Lists = Get-PnPProperty -ClientObject $Web -Property Lists
   
    # Exclude system lists
    $ExcludedLists = @("Access Requests","App Packages","appdata","appfiles","Apps in Testing","Cache Profiles","Composed Looks","Content and Structure Reports","Content type publishing error log","Converted Forms","Device Channels","Form Templates","fpdatasources","Get started with Apps for Office and SharePoint","List Template Gallery","Long Running Operation Status","Maintenance Log Library","Images","site collection images","Master Docs","Master Page Gallery","MicroFeed","NintexFormXml","Quick Deploy Items","Relationships List","Reusable Content","Reporting Metadata","Reporting Templates","Search Config List","Site Assets","Preservation Hold Library","Site Pages","Solution Gallery","Style Library","Suggested Content Browser Locations","Theme Gallery","TaxonomyHiddenList","User Information List","Web Part Gallery","wfpub","wfsvc","Workflow History","Workflow Tasks","Pages")
             
    $ListCounter = 0
    # Loop through each list in the web
    ForEach ($List in $Lists) {
        # Exclude system lists
        If ($List.Hidden -eq $False -and $ExcludedLists -notcontains $List.Title) {
            $ListCounter++
            $ListProgressParameters = @{
                Activity         = "Exporting Permissions from List '$($List.Title)' in $($Web.URL)"
                Status           = "Processing Lists $ListCounter of $($Lists.Count)"
                PercentComplete  = $ItemCounter / ($Lists.Count) * 100
                Id               = 1
                ParentId         = 0
            }
            Write-Progress @ListProgressParameters
            # Retrieve folder-level permissions if the ScanFolders switch is enabled
            If($ScanFolders)
            {
                # Get Folder Permissions
                Get-PnPFolderPermission -List $List
            }

            # Retrieve item-level permissions if the ScanItemLevel switch is enabled
            If ($ScanItemLevel) {
                # Get List Items Permissions
                Get-PnPListItemsPermission -List $List
            }
 
            # Retrieve permissions for lists with unique permissions or inherited permissions based on the IncludeInheritedPermissions switch
            If ($IncludeInheritedPermissions) {
                Get-PnPPermissions -Object $List
            }
            Else {
                # Check if the list has unique permissions
                $HasUniquePermissions = Get-PnPProperty -ClientObject $List -Property HasUniqueRoleAssignments
                If ($HasUniquePermissions -eq $True) {
					# Call the function to generate Permissions Report
                    Get-PnPPermissions -Object $List
                }
            }
        }
    }
}

# Function to retrieve permissions for folders in a given list
Function Get-PnPFolderPermission([Microsoft.SharePoint.Client.List]$List) {
    Write-host -f Yellow "`t `t Getting Permissions of Folders in the List:"$List.Title
     
    # Retrieve all folders from the list
    $ListItems = Get-PnPListItem -List $List -PageSize 2000
    $Folders = $ListItems | Where-Object { ($_.FileSystemObjectType -eq "Folder") -and ($_.FieldValues.FileLeafRef -ne "Forms") -and (-Not($_.FieldValues.FileLeafRef.StartsWith("_"))) }

    $FolderCounter = 0
    # Loop through each folder
    ForEach ($Folder in $Folders) {
        $FolderCounter++
        $FolderProgressParameters = @{
            Activity         = "Getting Permissions of Folders in List '$($List.Title)'"
            Status           = "Processing Folder '$($Folder.FieldValues.FileLeafRef)' at '$($Folder.FieldValues.FileRef)' ($FolderCounter of $($Folders.Count))"
            PercentComplete  = $FolderCounter / ($Folders.Count) * 100
            Id               = 2
            ParentId         = 1
        }
        Write-Progress @FolderProgressParameters
        
        # Retrieve permissions for folders with unique or inherited permissions based on IncludeInheritedPermissions switch
        If ($IncludeInheritedPermissions) {
            Get-PnPPermissions -Object $Folder
        }
        Else {
            # Check if the folder has unique permissions
            $HasUniquePermissions = Get-PnPProperty -ClientObject $Folder -Property HasUniqueRoleAssignments
            If ($HasUniquePermissions -eq $True) {
                # Call the function to generate Permissions Report
                Get-PnPPermissions -Object $Folder
            }
        }
    }
}

# Function to retrieve permissions for all items in a given list
Function Get-PnPListItemsPermission([Microsoft.SharePoint.Client.List]$List) {
    Write-host -f Yellow "`t `t Getting Permissions of List Items in the List:"$List.Title
  
    # Retrieve all items from the list in batches
    $ListItems = Get-PnPListItem -List $List -PageSize 500
  
    $ItemCounter = 0
    # Loop through each list item
    ForEach ($ListItem in $ListItems) {
        $ItemCounter++
        $ItemProgressParameters = @{
            Activity         = "Processing Items $ItemCounter of $($List.ItemCount)"
            Status           = "Searching Unique Permissions in List Items of '$($List.Title)'"
            PercentComplete  = $ItemCounter / ($List.ItemCount) * 100
            Id               = 3
            ParentId         = 1
        }
        Write-Progress @ItemProgressParameters
        
        # Retrieve permissions for items with unique or inherited permissions based on IncludeInheritedPermissions switch
        If ($IncludeInheritedPermissions) {
            Get-PnPPermissions -Object $ListItem
        }
        Else {
            # Check if the List Item has unique permissions
            $HasUniquePermissions = Get-PnPProperty -ClientObject $ListItem -Property HasUniqueRoleAssignments
            If ($HasUniquePermissions -eq $True) {
                # Call the function to generate Permissions Report
                Get-PnPPermissions -Object $ListItem
            }
        }
    }
}

# Function to retrieve permissions for a web and its lists from the given URL
Function Get-PnPWebPermission([Microsoft.SharePoint.Client.Web]$Web) {
    # Call the function to retrieve permissions for the web
    Write-host -f Yellow "Getting Permissions of the Web: $($Web.URL)..." 
    Get-PnPPermissions -Object $Web
   
    # Retrieve permissions for lists and libraries
    Write-host -f Yellow "`t Getting Permissions of Lists and Libraries..."
    Get-PnPListPermission($Web)
 
    # Recursively retrieve permissions for all sub-webs based on the Recursive switch
    If ($Recursive) {
        # Recursivly get a list of Subwebs for the Web
        $Subwebs = Get-PnPProperty -ClientObject $Web -Property Webs
 
        # Iterate through each subsite in the current web
        Foreach ($Subweb in $Subwebs) {
            # Retrieve permissions for webs with unique or inherited permissions based on IncludeInheritedPermissions switch
            If ($IncludeInheritedPermissions) {
                Get-PnPWebPermission($Subweb)
            }
            Else {
                # Check if the web has unique permissions
                $HasUniquePermissions = Get-PnPProperty -ClientObject $SubWeb -Property HasUniqueRoleAssignments
   
                # Get the Web's Permissions
                If ($HasUniquePermissions -eq $true) { 
                    # Call the function recursively                            
                    Get-PnPWebPermission($Subweb)
                }
            }
        }
    }
}

# Function to generate a SharePoint Online site permissions report
Function Get-PnPSitePermissionRpt() {
    [cmdletbinding()]
    Param 
    (    
        [Parameter(Mandatory = $false)] [String] $SiteURL, 
        [Parameter(Mandatory = $false)] [String] $ReportFile,         
        [Parameter(Mandatory = $false)] [switch] $Recursive,
        [Parameter(Mandatory = $false)] [switch] $ScanItemLevel,
        [Parameter(Mandatory = $false)] [switch] $ScanFolders,
        [Parameter(Mandatory = $false)] [switch] $IncludeInheritedPermissions       
    )  
    Try {
        # Connect to the specified SharePoint site
        Connect-PnPOnline -Url $site.Url -ClientId $clientId -Tenant $tenantM365URL -CertificatePath $certificatePath -CertificatePassword $certificatePassword
        # Retrieve the site web object
        $Web = Get-PnPWeb
 
        Write-host -f Yellow "Getting Site Collection Administrators..."
        # Retrieve site collection administrators
        $SiteAdmins = Get-PnPSiteCollectionAdmin
         
        $SiteCollectionAdmins = ($SiteAdmins | Select-Object -ExpandProperty Title) -join ","
        # Add site collection administrator data to the report
        $Permissions = New-Object PSObject
        $Permissions | Add-Member NoteProperty Object("Site Collection")
        $Permissions | Add-Member NoteProperty Title($Web.Title)
        $Permissions | Add-Member NoteProperty URL($Web.URL)
        $Permissions | Add-Member NoteProperty HasUniquePermissions("TRUE")
        $Permissions | Add-Member NoteProperty Users($SiteCollectionAdmins)
        $Permissions | Add-Member NoteProperty Type("Site Collection Administrators")
        $Permissions | Add-Member NoteProperty Permissions("Site Owner")
        $Permissions | Add-Member NoteProperty GrantedThrough("Direct Permissions")
               
        # Export permissions data to the CSV file
        $Permissions | Export-CSV $ReportFile -NoTypeInformation -Append

        # Retrieve site collection permissions
        Get-PnPWebPermission $Web
   
        Write-host -f Green "`n*** Site Permission Report Generated Successfully!***"
    }
    Catch {
        write-host -f Red "Error Generating Site Permission Report!" $_.Exception.Message
    }
}

# *******************************************************
# *******************************************************
# **                                                   **
# **                  MAIN CODE BLOCK                  **
# **                                                   **
# *******************************************************
# *******************************************************

# Attempt to authenticate the user against the SharePoint Online tenant using the Entra ID App credentials
Try {
    Write-Host -ForegroundColor Yellow "Authenticating to SharePoint Online..."
    $certificatePassword = Read-Host "Enter certificate Password" -AsSecureString
    Connect-PnPOnline $tenantSPAdminURL -ClientId $clientId -Tenant $tenantM365URL -CertificatePath $certificatePath -CertificatePassword $certificatePassword
    Write-Host -ForegroundColor Green "Authentication successful."
} Catch {
    Write-Host -ForegroundColor Red "Authentication failed. Error in connecting to SharePoint Online:'$($tenantSPAdminURL)'" $_.Exception.Message
}

# Check if the output file already exists and delete it if necessary
If (Test-Path $outputFile) {
    Try {
        Write-Host -ForegroundColor Yellow "Deleting existing report file: $outputFile"
        Remove-Item -Path $outputFile -Force
    } Catch {
        Write-Host -ForegroundColor Red "Unable to delete the existing file. Error: $_.Exception.Message"
        Exit 1
    }
}

# Retrieve all site collections in the tenant
Write-Output "Retrieving all site collections..."
$sites = Get-PnPTenantSite

# Generate permissions report
Write-Host -ForegroundColor Yellow "Starting permissions report generation..."
$SiteCounter = 0
foreach ($site in $sites) {
    Write-Output "Processing site collection: $($site.Url)"

    $SiteCounter++
    $SiteProgressParameters = @{
        Activity         = "Processing Site $SiteCounter of $($sites.Count)"
        Status           = "Searching for permissions located with-in: '$($site.Title)'"
        PercentComplete  = $SiteCounter / ($sites.Count) * 100
        Id               = 0
    }
    Write-Progress @SiteProgressParameters

    # Connect to the current site collection
    Connect-PnPOnline -Url $site.Url -ClientId $clientId -Tenant $tenantM365URL -CertificatePath $certificatePath -CertificatePassword $certificatePassword

    try {
        $Web = Get-PnPWeb -Includes RoleAssignments
        #Get-PnPSitePermissionRpt -SiteURL $SiteURL -ReportFile $outputFile -Recursive
        #Get-PnPSitePermissionRpt -SiteURL $SiteURL -ReportFile $outputFile -Recursive -ScanItemLevel -IncludeInheritedPermissions
        #Get-PnPSitePermissionRpt -SiteURL $SiteURL -ReportFile $outputFile -Recursive -ScanFolders -IncludeInheritedPermissions
        Get-PnPSitePermissionRpt -SiteURL $SiteURL -ReportFile $outputFile -Recursive -ScanFolders
		
		Write-Host -ForegroundColor Green "Permissions report successfully generated for site collection: $($site.Url)"
    }
    catch {
        Write-Host -ForegroundColor Red "Error during report generation for site collection: $($site.Url)"
		Write-Host -ForegroundColor Red "Error: $_.Exception.Message"
    }
}

# Completion message
Write-Host -ForegroundColor Green "Script execution completed successfully."

# End of script
