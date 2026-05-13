#
# Module 'Tab.Launcher.UserFolders.psm1'
# Last Update: May 2026
#

####################################################################################################
<#
.SYNOPSIS
    Imports the User Folder feature into the Launcher tab.
.DESCRIPTION
    This function imports the User Folder feature into the Launcher tab by creating a new GroupBox and adding it to the specified parent TabPage.
.EXAMPLE
    Import-FeatureUserFolderLauncher -InputObject $Global:ApplicationObject -ParentTabPage $MyTabPage
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
                Function        = { Start-Process regedit.exe }
            },
            @{
                ColumnNumber    = 2
                Text            = 'Program Files (32bit)'
                PNGFileName     = '32_bit.png'
                SizeType        = 'Large'
                Function        = { Open-Folder -Path 'C:\Program Files (x86)' }
            },
            @{
                ColumnNumber    = 3
                Text            = 'ProgramData'
                PNGFileName     = 'folder_page.png'
                SizeType        = 'Large'
                Function        = { Open-Folder -Path 'C:\ProgramData' }
            },
            @{
                ColumnNumber    = 4
                Text            = 'Windows'
                PNGFileName     = 'folder_wrench.png'
                SizeType        = 'Large'
                Function        = { Open-Folder -Path 'C:\Windows' }
            },
            @{
                ColumnNumber    = 5
                Text            = 'SCCM Cache'
                PNGFileName     = 'package_link.png'
                SizeType        = 'Large'
                Function        = { Open-Folder -Path 'C:\Windows\ccmcache' }
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
    This function opens the Registry Editor.
.DESCRIPTION
    This function starts the Registry Editor (regedit.exe) with elevated privileges. Optionally, it can open directly to the 32-bit or 64-bit Uninstall keys.
.EXAMPLE
    Start-RegistryEditor
.EXAMPLE
    Start-RegistryEditor -UninstallKey32bit
.EXAMPLE
    Start-RegistryEditor -UninstallKey64bit
.INPUTS
    [System.Management.Automation.SwitchParameter]
.OUTPUTS
    This function returns no stream output.
.NOTES
    This function is part of the Packaging Assistant. It contains functions and variables that are in other files.
    Version         : 5.7.2
    Author          : Imraan Iotana
    Creation Date   : February 2026
    Last Update     : February 2026
#>
####################################################################################################

function Start-RegistryEditor {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false, HelpMessage='Open the 32-bit Uninstall key.')]
        [System.Management.Automation.SwitchParameter]$UninstallKey32bit,

        [Parameter(Mandatory=$false, HelpMessage='Open the 64-bit Uninstall key.')]
        [System.Management.Automation.SwitchParameter]$UninstallKey64bit,

        [Parameter(Mandatory=$false, HelpMessage='Open the Settings of this application in the registry.')]
        [System.Management.Automation.SwitchParameter]$ApplicationSettingsKey
    )

    ####################################################################################################
    ### MAIN PROPERTIES ###

    # Set the Last Opened Key
    [System.String]$KeyContainingLastOpenedKey  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Applets\Regedit'

    # Set the selectable Registry Keys
    [System.String]$RegKeyUninstall32bit        = 'Computer\HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall'
    [System.String]$RegKeyUninstall64bit        = 'Computer\HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall'
    [System.String]$RegKeyApplicationSettings   = 'Computer\HKEY_CURRENT_USER\Software\Packaging Assistant'


    try {
        # PREPARATION
        # Determine which key to open
        [System.String]$LastKeyValue = [System.String]::Empty
        if ($UninstallKey32bit) {
            $LastKeyValue = $RegKeyUninstall32bit
        } elseif ($UninstallKey64bit) {
            $LastKeyValue = $RegKeyUninstall64bit
        } elseif ($ApplicationSettingsKey) {
            $LastKeyValue = $RegKeyApplicationSettings
        }
        # If a specific key is requested, set it as the last opened key in regedit
            if (Test-String -IsPopulated $LastKeyValue) {
            Set-ItemProperty -Path $KeyContainingLastOpenedKey -Name 'LastKey' -Value $LastKeyValue -Force
        }

        # EXECUTION
        # Start the Registry Editor
        Start-ApplicationAsAdmin -Name 'RegistryEditor'
    }
    catch {
        Write-FullError
    }
}

### END OF FUNCTION
####################################################################################################
