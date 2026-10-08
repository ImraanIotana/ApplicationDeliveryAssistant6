####################################################################################################
<#
.SYNOPSIS
    Imports the Maintenance sub-tab into the Application Settings tab.
.DESCRIPTION
    This function imports the Maintenance sub-tab into the Application Settings tab by creating a new TabPage and adding it to the specified parent TabControl.
.EXAMPLE
    Import-SubTabMaintenance -InputObject $MyApplicationObject -ParentTabControl $MySubTabControl
.INPUTS
    [PSCustomObject]
    [System.Windows.Forms.TabControl]
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.9.1
    Author          : Imraan Iotana
    Creation Date   : July 2026
    Last Update     : October 2026
#>
####################################################################################################
function Import-SubTabMaintenance {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The ApplicationObject containing the Settings.')]
        [PSCustomObject]$InputObject,

        [Parameter(Mandatory=$true,HelpMessage='The Parent TabControl to which this TabPage will be added.')]
        [System.Windows.Forms.TabControl]$ParentTabControl
    )

    try {
        # PREPARATION - TAB PROPERTIES
        # Tab properties
        [System.Collections.Hashtable]$TabProperties = @{
            ParentTabControl    = $ParentTabControl
            Title               = 'MAINTENANCE'
            Version             = '6.9.1'
            BackGroundColor     = 'Cornsilk'
        }
        # Set the main color for the GroupBoxes in this sub-tab
        [System.String]$MainColor = 'Brown'

        # EXECUTION - TAB
        # Create the TabPage
        [System.Windows.Forms.TabPage]$ParentTabPage = New-TabPage @TabProperties

        # EXECUTION - FEATURES
        # Import the Features
        $ApplicationMaintenanceGroupBox = Import-FeatureApplicationMaintenance  -InputObject $InputObject -ParentTabPage $ParentTabPage -Color $MainColor
        $null                           = Import-FeatureTabColorSelection       -InputObject $InputObject -ParentTabPage $ParentTabPage -Color $MainColor -GroupBoxAbove $ApplicationMaintenanceGroupBox
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}

### END OF FUNCTION
####################################################################################################
