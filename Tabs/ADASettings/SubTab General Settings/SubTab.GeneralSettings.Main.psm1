####################################################################################################
<#
.SYNOPSIS
    Imports the General Settings sub-tab into the Application Settings tab.
.DESCRIPTION
    This function imports the General Settings sub-tab into the Application Settings tab by creating a new TabPage and adding it to the specified parent TabControl.
.EXAMPLE
    Import-SubTabGeneralSettings -InputObject $MyApplicationObject -ParentTabControl $MySubTabControl
.INPUTS
    [PSCustomObject]
    [System.Windows.Forms.TabControl]
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.1
    Author          : Imraan Iotana
    Creation Date   : May 2026
    Last Update     : July 2026
#>
####################################################################################################
function Import-SubTabGeneralSettings {
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
            Title               = 'GENERAL SETTINGS'
            Version             = '6.0.0.1'
            BackGroundColor     = 'Cornsilk'
        }
        # Set the main color for the GroupBoxes in this sub-tab
        [System.String]$MainColor = 'Brown'

        # EXECUTION - TAB
        # Create the TabPage
        [System.Windows.Forms.TabPage]$ParentTabPage = New-TabPage @TabProperties

        # EXECUTION - FEATURES
        # Import the Features
        $null = Import-FeatureUserFolders -InputObject $InputObject -Color $MainColor -ParentTabPage $ParentTabPage
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}

### END OF FUNCTION
####################################################################################################
