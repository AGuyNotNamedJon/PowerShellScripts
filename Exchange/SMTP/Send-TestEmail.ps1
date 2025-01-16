# Requires the MailKit module. Install it if not present
# Check if the module is installed, if not, install it
if (-not (Get-Module -ListAvailable -Name Send-MailKitMessage)) {
    Write-Host "MailKit module not found. Installing..."
    try {
        Install-Module -Name Send-MailKitMessage -Scope CurrentUser -Force
        Write-Host "MailKit module installed successfully."
    } catch {
        Write-Host "Failed to install MailKit module: $_"
        exit
    }
}

# Import the MailKit module
Import-Module Send-MailKitMessage

# Add GUI dependencies
Add-Type -AssemblyName System.Windows.Forms

# Create the main form
$form = New-Object System.Windows.Forms.Form
$form.Text = "SMTP Email Sender"
$form.Size = New-Object System.Drawing.Size(600, 800)
$form.StartPosition = "CenterScreen"

# Create input fields and labels
$labels = @("SMTP Server", "Port", "Username", "Password", "From Email", "To Email (comma-separated)", "CC (optional)", "BCC (optional)", "Subject", "Text Body", "HTML Body", "Attachment (optional, full paths)")
$inputs = @()

# Loop to create labels and text boxes dynamically
for ($i = 0; $i -lt $labels.Length; $i++) {
    # Label
    $label = New-Object System.Windows.Forms.Label
    $label.Text = $labels[$i]
    $label.Location = New-Object System.Drawing.Point(10, (20 + ($i * 40)))
    $label.Size = New-Object System.Drawing.Size(150, 20)
    $form.Controls.Add($label)

    # TextBox
    $textbox = New-Object System.Windows.Forms.TextBox
    $textbox.Location = New-Object System.Drawing.Point(170, (20 + ($i * 40)))
    $textbox.Size = New-Object System.Drawing.Size(400, 20)
    if ($labels[$i] -eq "Password") {
        $textbox.UseSystemPasswordChar = $true
    }
    $form.Controls.Add($textbox)
    $inputs += $textbox
}

# Add a checkbox for UseSecureConnectionIfAvailable
$secureConnectionLabel = New-Object System.Windows.Forms.Label
$secureConnectionLabel.Text = "Use Secure Connection If Available"
$secureConnectionLabel.Location = New-Object System.Drawing.Point(10, (20 + ($labels.Length * 40)))
$secureConnectionLabel.Size = New-Object System.Drawing.Size(250, 20)
$form.Controls.Add($secureConnectionLabel)

$secureConnectionCheckbox = New-Object System.Windows.Forms.CheckBox
$secureConnectionCheckbox.Location = New-Object System.Drawing.Point(270, (20 + ($labels.Length * 40)))
$secureConnectionCheckbox.Checked = $true # Default to true
$form.Controls.Add($secureConnectionCheckbox)

<# Add a dropdown for .eml templates
$templateLabel = New-Object System.Windows.Forms.Label
$templateLabel.Text = "Select Email Template"
$templateLabel.Location = New-Object System.Drawing.Point(10, (60 + ($labels.Length * 40)))
$templateLabel.Size = New-Object System.Drawing.Size(150, 20)
$form.Controls.Add($templateLabel)

$templateDropdown = New-Object System.Windows.Forms.ComboBox
$templateDropdown.Location = New-Object System.Drawing.Point(170, (60 + ($labels.Length * 40)))
$templateDropdown.Size = New-Object System.Drawing.Size(400, 20)
$templateDropdown.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$form.Controls.Add($templateDropdown)

# Load .eml templates from folder
$templateFolder = ".\MailTemplates"
if (-not (Test-Path -Path $templateFolder)) {
    New-Item -ItemType Directory -Path $templateFolder | Out-Null
}
$templateFiles = Get-ChildItem -Path $templateFolder -Filter "*.eml" | Select-Object -ExpandProperty Name
$templateDropdown.Items.AddRange($templateFiles)#>

# Add a log box
$logBox = New-Object System.Windows.Forms.TextBox
$logBox.Multiline = $true
$logBox.ScrollBars = "Vertical"
$logBox.Location = New-Object System.Drawing.Point(10, (100 + ($labels.Length * 40)))
$logBox.Size = New-Object System.Drawing.Size(560, 100)
$form.Controls.Add($logBox)

# Add a button to send email
$sendButton = New-Object System.Windows.Forms.Button
$sendButton.Text = "Send Email"
$sendButton.Location = New-Object System.Drawing.Point(250, (220 + ($labels.Length * 40)))
$form.Controls.Add($sendButton)

# Button click event to send email
$sendButton.Add_Click({
    $logBox.AppendText("Starting email send process...`n")
    try {
        # Extract input values
        $SMTPServer = $inputs[0].Text
        $Port = [int]$inputs[1].Text
        $Username = $inputs[2].Text
        $Password = $inputs[3].Text
        $From = [MimeKit.MailboxAddress]::Parse($inputs[4].Text)

        # Parse recipients, CC, BCC
        $RecipientList = [MimeKit.InternetAddressList]::new()
        foreach ($email in $inputs[5].Text -split ",") {
            $RecipientList.Add([MimeKit.InternetAddress]::Parse($email.Trim()))
        }

        $CCList = [MimeKit.InternetAddressList]::new()
        if ($inputs[6].Text) {
            foreach ($email in $inputs[6].Text -split ",") {
                $CCList.Add([MimeKit.InternetAddress]::Parse($email.Trim()))
            }
        }

        $BCCList = [MimeKit.InternetAddressList]::new()
        if ($inputs[7].Text) {
            foreach ($email in $inputs[7].Text -split ",") {
                $BCCList.Add([MimeKit.InternetAddress]::Parse($email.Trim()))
            }
        }

        # Create credentials
        $Credential = [System.Management.Automation.PSCredential]::new(
            $Username,
            (ConvertTo-SecureString -String $Password -AsPlainText -Force)
        )

        # Create email details
        $Subject = $inputs[8].Text
        $TextBody = $inputs[9].Text
        $HTMLBody = $inputs[10].Text

        # Parse selected template
        if ($templateDropdown.SelectedItem) {
            $templatePath = Join-Path -Path $templateFolder -ChildPath $templateDropdown.SelectedItem
            $HTMLBody = Get-Content -Path $templatePath -Raw
            $logBox.AppendText("Loaded email template: $templatePath`n")
        }

        # Parse attachments
        $AttachmentList = [System.Collections.Generic.List[string]]::new()
        if ($inputs[11].Text) {
            foreach ($file in $inputs[11].Text -split ";") {
                $AttachmentList.Add($file.Trim())
            }
        }

        # Splat parameters
        $Parameters = @{
            "UseSecureConnectionIfAvailable" = $secureConnectionCheckbox.Checked
            "Credential" = $Credential
            "SMTPServer" = $SMTPServer
            "Port" = $Port
            "From" = $From
            "RecipientList" = $RecipientList
            "CCList" = $CCList
            "BCCList" = $BCCList
            "Subject" = $Subject
            "TextBody" = $TextBody
            "HTMLBody" = $HTMLBody
            "AttachmentList" = $AttachmentList
        }

        # Send email
        Send-MailKitMessage @Parameters
        $logBox.AppendText("Email sent successfully.`n")
    } catch {
        $logBox.AppendText("Error sending email: $_`n")
    }
})

# Show the form
[void]$form.ShowDialog()
