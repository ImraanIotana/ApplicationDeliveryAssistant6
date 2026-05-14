####################################################################################################
<#
.SYNOPSIS
    Imports the Registry feature into the Launcher tab.
.DESCRIPTION
    This function imports the Registry feature into the Launcher tab by creating a new GroupBox and adding it to the specified parent TabPage.
.EXAMPLE
    Import-FeatureRegistryLauncher -InputObject $MyApplicationObject -ParentTabPage $MyTabPage
.INPUTS
    [PSCustomObject]
    [System.Windows.Forms.TabPage]
.OUTPUTS
    No objects are returned to the pipeline. All output is written to the host.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. All rights reserved.
    Version         : 6.0.0.0
    Author          : Imraan Iotana
    Creation Date   : May 2026
    Last Update     : May 2026
#>
####################################################################################################
function Import-FeatureRegistryLauncher {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The ApplicationObject containing the Settings.')]
        [PSCustomObject]$InputObject,

        [Parameter(Mandatory=$true,HelpMessage='The Parent TabPage to which this Feature will be added.')]
        [System.Windows.Forms.TabPage]$ParentTabPage,

        [Parameter(Mandatory=$false,HelpMessage='The GroupBox above which this Feature will be added.')]
        [System.Windows.Forms.GroupBox]$GroupBoxAbove
    )

    try {
        # Feature properties
        [System.Collections.Hashtable]$FeatureProperties = @{
            InputObject     = $InputObject
            ParentTabPage   = $ParentTabPage
            Title           = 'REGISTRY'
            Color           = 'Cyan'
            NumberOfRows    = 2
        }
        # If the GroupBoxAbove parameter is provided, set the GroupBoxAbove property
        if ($PSBoundParameters.ContainsKey('GroupBoxAbove')) { $FeatureProperties.GroupBoxAbove = $GroupBoxAbove }

        # Create the Feature GroupBox
        [System.Windows.Forms.GroupBox]$FeatureGroupBox = New-GroupBox @FeatureProperties

        # Set the Button properties
        [System.Collections.Hashtable[]]$ButtonPropertiesArray1 = @(
            @{
                ColumnNumber    = 1
                Text            = 'Registry Editor'
                PNGFileName     = 'regedit.png'
                SizeType        = 'Large'
                Function        = { Start-RegistryEditor }
            },
            @{
                ColumnNumber    = 2
                Text            = '64-bit Uninstall Key'
                PNGFileName     = 'regedit.png'
                SizeType        = 'Large'
                Function        = { Start-RegistryEditor -UninstallKey64bit }
            },
            @{
                ColumnNumber    = 3
                Text            = '32-bit Uninstall Key'
                PNGFileName     = 'regedit.png'
                SizeType        = 'Large'
                Function        = { Start-RegistryEditor -UninstallKey32bit }
            },
            @{
                ColumnNumber    = 4
                Text            = 'PowerShell Policy Key'
                PNGFileName     = 'regedit.png'
                SizeType        = 'Large'
                Function        = { Start-RegistryEditor -PowerShellPolicyKey }
            }
            @{
                ColumnNumber    = 5
                Text            = 'Application Settings Key'
                PNGFileName     = 'regedit.png'
                SizeType        = 'Large'
                Function        = { Start-RegistryEditor -ApplicationSettingsKey -InputObject $InputObject }.GetNewClosure()
            }
        )

        # Add the Buttons
        New-ButtonLine -InputObject $InputObject -ButtonPropertiesArray $ButtonPropertiesArray1 -ParentGroupBox $FeatureGroupBox -RowNumber 1

        # Return the GroupBox object
        $FeatureGroupBox
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
