# PowerShellScripts

PowerShell scripts that I use for my job or other things I have created to potentially make my life easier in the future.

## Table of Contents

- [Overview](#overview)
- [Repository Structure](#repository-structure)
- [Script Categories](#script-categories)
  - [Active Directory](#active-directory)
  - [Cheatsheets](#cheatsheets)
  - [Exchange](#exchange)
  - [Intune](#intune)
  - [PSModules](#psmodules)
  - [SharePoint](#sharepoint)
  - [Windows OS](#windows-os)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
- [Usage](#usage)
- [Contributing](#contributing)
- [License](#license)

## Overview

This repository contains a collection of PowerShell scripts organized by category for various administrative tasks and automation scenarios. The scripts range from simple utilities to more complex administrative tools for managing Windows environments, Active Directory, Exchange, SharePoint, and more.

## Repository Structure

```
PowerShellScripts/
├── Active Directory/       # Active Directory management scripts
├── Cheatsheets/            # PowerShell reference guides and examples
├── Exchange/               # Exchange and email-related scripts
│   └── SMTP/               # SMTP testing and configuration
├── Intune/                 # Microsoft Intune management scripts
│   └── Application Deployment/ # Scripts for deploying applications via Intune
├── PSModules/              # Custom PowerShell modules
│   ├── Common/             # Common utility functions
│   └── Logging/            # Logging functionality for scripts
├── SharePoint/             # SharePoint administration scripts
│   └── Reports/            # SharePoint reporting tools
└── Windows OS/             # Windows operating system management scripts
```

## Script Categories

### Active Directory

Scripts for managing and automating Active Directory tasks.

- **Invoke-EntraSyncRemotely.ps1** - Remotely trigger Microsoft Entra (Azure AD) synchronization

### Cheatsheets

A comprehensive collection of PowerShell reference guides covering basic to advanced topics. These cheatsheets provide quick access to PowerShell syntax, commands, and techniques for various scenarios.

Each file contains code snippets and reference examples for different PowerShell concepts. These files are **not meant to be run directly** as scripts, but rather serve as:

- Reference material when working with PowerShell
- A collection of code snippets that can be copied and adapted for your own scripts
- Learning resources to understand PowerShell concepts and syntax

Topics covered include:
- Basic commands and syntax
- Data types and operators
- Flow control and functions
- File system operations
- Modules and classes
- Remote management
- REST APIs
- And many more

See the [Cheatsheets README](./Cheatsheets/README.md) for a complete list of available reference guides.

### Exchange

Scripts for managing Microsoft Exchange and email-related tasks.

- **Convert-DynamicDLtoStaticDL.ps1** - Convert Dynamic Distribution Lists to Static Distribution Lists
- **Convert-LDIFtoCSV.ps1** - Convert LDIF files to CSV format
- **Convert-VCardtoCSV.ps1** - Convert vCard files to CSV format

SMTP subfolder:
- **Send-TestEmail.ps1** - Send test emails for SMTP configuration validation

### Intune

Scripts for Microsoft Intune management and application deployment.

Application Deployment subfolder:
- **Deploy-NordPass.ps1** - Script for deploying NordPass application via Intune

### PSModules

Custom PowerShell modules that can be imported into other scripts.

#### Common Module

- **Common.psm1** - Common utility functions for PowerShell scripts

#### Logging Module

The **Logging** module is a versatile logging utility for PowerShell scripts. It allows users to log messages with different levels of importance (Debug, Error, Info, Warning, Verbose) to various outputs such as console, log files, or GUI interfaces.

Features:
- Logs messages with customizable severity levels
- Supports output to console, log files, and GUI text boxes
- Includes options for UTC or local timestamps
- Customizable error handling behavior

See the [Logging Module README](./PSModules/Logging/README.md) for detailed usage instructions and examples.

### SharePoint

Scripts for SharePoint administration and management.

Reports subfolder:
- **Audit-SPPermissions.ps1** - Audit and report on SharePoint permissions

### Windows OS

Scripts for Windows operating system management and automation.

- **Initiate-Robocopy.ps1** - Wrapper script for Robocopy with enhanced functionality
- **Manage-WiFiNetworks.ps1** - Manage WiFi network profiles on Windows

## Getting Started

### Prerequisites

- Windows PowerShell 5.1 and PowerShell Core 7.x, will depend on the script
- Appropriate permissions for the tasks you want to perform
- Module-specific requirements (see individual script headers)

### Installation

1. Clone this repository or download the scripts you need:
   ```powershell
   git clone https://github.com/AGuyNotNamedJon/PowerShellScripts.git
   ```

2. For modules, you may want to copy them to your PowerShell modules directory:
   ```powershell
   Copy-Item -Path ".\PSModules\Logging" -Destination "$env:USERPROFILE\Documents\WindowsPowerShell\Modules\" -Recurse
   ```

## Usage

Each script contains documentation in the header section explaining its purpose, parameters, and usage examples. You can also use PowerShell's built-in help system if the scripts include comment-based help:

```powershell
Get-Help -Full .\Path\To\Script.ps1
```

For the Cheatsheets, refer to the individual files for examples and reference material on specific PowerShell topics.

## Contributing

Contributions are welcome! If you have improvements or additional scripts to share please do so via a pull request.

Please ensure your scripts include proper documentation and follow PowerShell best practices.

## License

This project is licensed under the terms of the license included in the repository. See the [LICENSE](./LICENSE) file for details.
