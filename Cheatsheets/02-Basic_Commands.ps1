###################################################
# Basic Commands
###################################################

# Get information about available commands
Get-Command                                             # Lists all commands, including: PowerShell cmdlets and functions, Aliases, Native Windows commands in PATH, and Scripts in PATH

Get-Command -Module Microsoft*                          # Lists commands from "Microsoft" modules only
                                                        # Example: Useful for finding built-in Windows management commands

Get-Command -Name *item                                 # Lists commands with "item" in their name. Useful for finding related commands.
                                                        # Example matches: Get-Item, Remove-Item, etc.

# Help system commands
Get-Help                                                # Displays PowerShell's help system overview
                                                        # Shows categories of help available
Get-Help -Name about_Variables                          # Shows conceptual help topics (manual pages)
                                                        # 'about_*' topics explain PowerShell concepts in detail
Get-Help -Name Get-Command                              # Displays detailed help for a specific command
                                                        # Including syntax, parameters, and examples
Get-Help -Name Get-Command -Parameter Module            # Shows help for a specific parameter
                                                        # Useful when you need to understand one parameter deeply

# Command discovery and exploration
Get-Command about_*                                     # Lists all conceptual help topics

Get-Command -Verb Add                                   # Lists all commands that start with "Add-"

Get-Alias ps                                            # Shows what command 'ps' is an alias for (in this case, Get-Process)

Get-Alias -Definition Get-Process                       # Shows all aliases for the specified command. Helps find shorter ways to write commands

ps | Get-Member                                         # Shows all properties and methods of command output

Show-Command Get-WinEvent                               # Opens a graphical interface for command parameters

Update-Help                                             # Downloads and installs newest help content. Should be run periodically to keep help current
                                                        # Requires admin privileges

# Version information
$PSVersionTable                                         # Shows detailed PowerShell version information
                                                        # Includes CLR version, OS details, and platform info
