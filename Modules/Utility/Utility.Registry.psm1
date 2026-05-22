####################################################################################################
<#
.SYNOPSIS
    Starts the Registry Editor with specific keys based on the provided parameters.
.DESCRIPTION
    This function starts the Registry Editor (regedit.exe) and can optionally set the last opened key to a specific location before launching.
    The key to open can be specified using the parameters, allowing for quick access to commonly used registry locations.
.EXAMPLE
    Start-RegistryEditor
.EXAMPLE
    Start-RegistryEditor -UninstallKey32bit
.EXAMPLE
    Start-RegistryEditor -UninstallKey64bit
.INPUTS
    [System.Management.Automation.SwitchParameter]
.OUTPUTS
    No objects are returned to the pipeline. All output is written to the host.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. All rights reserved.
    Version         : 6.0.0.0
    Author          : Imraan Iotana
    Creation Date   : February 2026
    Last Update     : May 2026
#>
####################################################################################################
function Start-RegistryEditor {
    [CmdletBinding(DefaultParameterSetName='None')]
    param (
        [Parameter(Mandatory=$false,ParameterSetName='ApplicationSettingsKey',HelpMessage='The ApplicationObject containing the Settings.')]
        [PSCustomObject]$InputObject,

        [Parameter(Mandatory=$false,ParameterSetName='ApplicationSettingsKey',HelpMessage='Open the 64-bit Uninstall key.')]
        [System.Management.Automation.SwitchParameter]$ApplicationSettingsKey,

        [Parameter(Mandatory=$false,ParameterSetName='UninstallKey64bit',HelpMessage='Open the 64-bit Uninstall key.')]
        [System.Management.Automation.SwitchParameter]$UninstallKey64bit,

        [Parameter(Mandatory=$false,ParameterSetName='UninstallKey32bit',HelpMessage='Open the 32-bit Uninstall key.')]
        [System.Management.Automation.SwitchParameter]$UninstallKey32bit,
        
        [Parameter(Mandatory=$false,ParameterSetName='PowerShellPolicyKey',HelpMessage='Open the PowerShell policy key.')]
        [System.Management.Automation.SwitchParameter]$PowerShellPolicyKey,

        [Parameter(Mandatory=$false,ParameterSetName='LastOpenedSettingKey',HelpMessage='Open the last-opened-setting key.')]
        [System.Management.Automation.SwitchParameter]$LastOpenedSettingKey
    )

    try {
        # PREPARATION - DEFINE VARIABLES
        # Define a hashtable to store the registry paths for different keys
        [System.Collections.Hashtable]$Context = @{
            UninstallKey64bit       = 'Computer\HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall'
            UninstallKey32bit       = 'Computer\HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall'
            PowerShellPolicyKey     = 'Computer\HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\PowerShell\1\ShellIds\Microsoft.PowerShell'
            LastOpenedSettingKey    = 'Computer\HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Applets\Regedit'
        }
        # Set the registry key that contains the last opened key value for regedit
        [System.String]$KeyContainingLastOpenedKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Applets\Regedit'

        # PREPARATION - DETERMINE LAST OPENED KEY
        # Determine which key to open
        [System.String]$LastKeyValue = switch ($PSCmdlet.ParameterSetName) {
            'UninstallKey64bit'         { $Context.UninstallKey64bit }
            'UninstallKey32bit'         { $Context.UninstallKey32bit }
            'PowerShellPolicyKey'       { $Context.PowerShellPolicyKey }
            'LastOpenedSettingKey'      { $Context.LastOpenedSettingKey }
            'ApplicationSettingsKey'    {
                # Get the User Settings registry path from the Application Settings
                [System.String]$UserSettingsRegistryPath = $InputObject.ApplicationSettings.UserSettingsRegistryPath
                # Convert the User Settings registry path to the format used by regedit for the last opened key
                [System.String]$UserSettingsRegistryPathForRegedit = $UserSettingsRegistryPath.Replace('HKCU:\','Computer\HKEY_CURRENT_USER\')
                # Return the converted registry path
                $UserSettingsRegistryPathForRegedit
            }
            Default                     { [System.String]::Empty }
        }

        # PREPARATION - SET LAST OPENED KEY
        # If a specific key is requested, set it as the last opened key in regedit
        if (Test-String -IsPopulated $LastKeyValue) { Set-ItemProperty -Path $KeyContainingLastOpenedKey -Name 'LastKey' -Value $LastKeyValue -Force }

        # EXECUTION
        # Start the Registry Editor
        Write-Line "Starting the Registry Editor at the key: ($LastKeyValue)"
        Start-Process regedit.exe
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}

### END OF FUNCTION
####################################################################################################


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
    $ApplicationObjectsFromRegistry | Sort-Object DisplayName
}

### END OF FUNCTION
####################################################################################################
