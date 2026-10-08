####################################################################################################
<#
.SYNOPSIS
    Imports the Search sub-tab into the DSL Management tab.
.DESCRIPTION
    This function imports the Search sub-tab into the DSL Management tab by creating a new TabPage and adding it to the specified parent TabControl.
.EXAMPLE
    Import-SubTabDSLManagementSearch -InputObject $MyApplicationObject -ParentTabControl $MySubTabControl
.INPUTS
    [PSCustomObject]
    [System.Windows.Forms.TabControl]
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.8.0
    Author          : Imraan Iotana
    Creation Date   : July 2026
    Last Update     : September 2026
#>
####################################################################################################
function Import-SubTabDSLManagementSearch {
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
            Title               = 'DSL SEARCH'
            Version             = '6.8.0'
            BackGroundColor     = 'SteelBlue'
        }
        # Set the main color for the GroupBoxes in this sub-tab
        [System.String]$MainColor = 'Cyan'

        # EXECUTION - TAB
        # Create the TabPage
        [System.Windows.Forms.TabPage]$ParentTabPage = New-TabPage @TabProperties

        # EXECUTION - FEATURES
        # Import the Search feature
        $null = Import-FeatureDSLManagementSearch -InputObject $InputObject -ParentTabPage $ParentTabPage -Color $MainColor
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}

### END OF FUNCTION
####################################################################################################
