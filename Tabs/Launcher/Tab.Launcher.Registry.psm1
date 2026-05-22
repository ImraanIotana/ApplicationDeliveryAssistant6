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
