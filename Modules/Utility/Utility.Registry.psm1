####################################################################################################
<#
.SYNOPSIS
    Retrieves a list of installed applications from the Windows registry.
.DESCRIPTION
    This function queries the Windows registry to gather information about installed applications.
    It can include incomplete entries and system components based on the provided parameters.
.EXAMPLE
    Get-InstalledApplicationsFromRegistry
.INPUTS
    [System.Management.Automation.SwitchParameter]
.OUTPUTS
    [PSCustomObject[]]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. All rights reserved.
    Version         : 6.0.0.0
    Author          : Imraan Iotana
    Creation Date   : May 2026
    Last Update     : May 2026
#>
####################################################################################################
function Get-InstalledApplicationsFromRegistry {
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param (
        [Parameter(Mandatory=$false,HelpMessage='Include entries without an UninstallString.')]
        [System.Management.Automation.SwitchParameter]$IncludeIncomplete,

        [Parameter(Mandatory=$false,HelpMessage='Include SystemComponent entries (usually Windows components).')]
        [System.Management.Automation.SwitchParameter]$IncludeSystemComponents
    )

    # PREPARATION
    # Set up registry paths to query for installed applications
    [PSCustomObject[]]$KeysContainingUninstallInformation = @(
        @{
            Path         = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*'
            Architecture = 'x64'
            Scope        = 'Machine'
        },
        @{
            Path         = 'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
            Architecture = 'x86'
            Scope        = 'Machine'
        },
        @{
            Path         = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*'
            Architecture = 'User'
            Scope        = 'User'
        }
    )

    # EXECUTION
    # Query the registry and build a list of application objects
    [PSCustomObject[]]$ApplicationObjectsFromRegistry = foreach ($KeyContainingUninstallInformation in $KeysContainingUninstallInformation) {

        # Get all registry entries under the specified path, and filter them based on the presence of DisplayName, UninstallString, and SystemComponent properties
        [PSCustomObject[]]$Apps = Get-ItemProperty -Path $KeyContainingUninstallInformation.Path -ErrorAction SilentlyContinue |
        Where-Object {
            $_.DisplayName -and
            (
                $IncludeIncomplete -or
                $_.UninstallString
            ) -and
            (
                $IncludeSystemComponents -or
                $_.SystemComponent -ne 1
            )
        }

        # For each application found, create a rich object with all the relevant information
        $Apps | ForEach-Object {

            # Build a rich object (data model)
            [PSCustomObject]@{
                DisplayName         = $_.DisplayName
                DisplayVersion      = $_.DisplayVersion
                Publisher           = $_.Publisher
                InstallLocation     = $_.InstallLocation
                InstallDate         = $_.InstallDate
                UninstallString     = $_.UninstallString
                QuietUninstall      = $_.QuietUninstallString
                EstimatedSizeKB     = $_.EstimatedSize
                Architecture        = $KeyContainingUninstallInformation.Architecture
                Scope               = $KeyContainingUninstallInformation.Scope
                RegistryPath        = $_.PSPath          # Unique identifier
                RegistryKeyName     = $_.PSChildName     # Often a GUID for MSI
                SystemComponent     = $_.SystemComponent
                WindowsInstaller    = $_.WindowsInstaller
                # Create a unique name to show in the ComboBox
                ComboBoxName        = "[$($KeyContainingUninstallInformation.Architecture)] $($_.DisplayName)"
            }

        }
    }

    # OUTPUT
    # Sort the applications by the ComboBoxName for better user experience in the ComboBox, and output the result to the pipeline
    $ApplicationObjectsFromRegistry | Sort-Object ComboBoxName
}