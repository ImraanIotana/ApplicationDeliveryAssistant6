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
    [System.Windows.Forms.GroupBox]
    [System.String]
.OUTPUTS
    [System.Windows.Forms.GroupBox]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.1
    Author          : Imraan Iotana
    Creation Date   : May 2026
    Last Update     : July 2026
#>
####################################################################################################
function Import-FeatureRegistryLauncher {
    [CmdletBinding()]
    [OutputType([System.Windows.Forms.GroupBox])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The ApplicationObject containing the Settings.')]
        [PSCustomObject]$InputObject,

        [Parameter(Mandatory=$true,HelpMessage='The Parent TabPage to which this Feature will be added.')]
        [System.Windows.Forms.TabPage]$ParentTabPage,

        [Parameter(Mandatory=$false,HelpMessage='The GroupBox underneath which this Feature will be added.')]
        [System.Windows.Forms.GroupBox]$GroupBoxAbove,

        [Parameter(Mandatory=$false,HelpMessage='The color of the GroupBox.')]
        [System.String]$Color
    )

    try {
        # PREPARATION - GROUPBOX PROPERTIES
        # Set the GroupBox properties
        [System.Collections.Hashtable]$GroupBoxProperties = @{
            InputObject     = $InputObject
            ParentTabPage   = $ParentTabPage
            Title           = 'REGISTRY'
            Color           = $Color
            NumberOfRows    = 2
            GroupBoxAbove   = $GroupBoxAbove
        }

        # EXECUTION - GROUPBOX
        # Create the GroupBox
        [System.Windows.Forms.GroupBox]$FeatureGroupBox = New-GroupBox @GroupBoxProperties

        # PREPARATION - BUTTON PROPERTIES
        # Set the Button properties
        [System.Collections.Hashtable[]]$ButtonPropertiesArray1 = @(
            @{
                ColumnNumber    = 1
                Text            = 'Registry Editor'
                PNGFileName     = 'regedit'
                SizeType        = 'Large'
                Function        = { Start-RegistryEditor }
            },
            @{
                ColumnNumber    = 2
                Text            = '64-bit Uninstall Key'
                PNGFileName     = 'regedit'
                SizeType        = 'Large'
                Function        = { Start-RegistryEditor -UninstallKey64bit }
            },
            @{
                ColumnNumber    = 3
                Text            = '32-bit Uninstall Key'
                PNGFileName     = 'regedit'
                SizeType        = 'Large'
                Function        = { Start-RegistryEditor -UninstallKey32bit }
            },
            @{
                ColumnNumber    = 4
                Text            = 'PowerShell Policy Key'
                PNGFileName     = 'regedit'
                SizeType        = 'Large'
                Function        = { Start-RegistryEditor -PowerShellPolicyKey }
            },
            @{
                ColumnNumber    = 5
                Text            = 'Application Settings Key'
                PNGFileName     = 'regedit'
                SizeType        = 'Large'
                Function        = { Start-RegistryEditor -ApplicationSettingsKey -InputObject $InputObject }.GetNewClosure()
            }
        )

        # EXECUTION - BUTTONS
        # Create the Buttons
        New-ButtonLine -InputObject $InputObject -ButtonPropertiesArray $ButtonPropertiesArray1 -ParentGroupBox $FeatureGroupBox -RowNumber 1

        # POST-EXECUTION
        # Return the GroupBox object
        $FeatureGroupBox
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}

### END OF FUNCTION
####################################################################################################
