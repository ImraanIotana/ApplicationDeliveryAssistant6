####################################################################################################
<#
.SYNOPSIS
    Imports the Other sub-tab into the Tools tab.
.DESCRIPTION
    This function imports the Other sub-tab into the Tools tab by creating a new TabPage and adding it to the specified parent TabControl.
.EXAMPLE
    Import-SubTabToolsOther -InputObject $MyApplicationObject -ParentTabControl $MySubTabControl
.INPUTS
    [PSCustomObject]
    [System.Windows.Forms.TabControl]
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.10.3
    Author          : Imraan Iotana
    Creation Date   : May 2026
    Last Update     : October 2026
#>
####################################################################################################
function Import-SubTabToolsOther {
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
            Title               = 'OTHER'
            Version             = '6.10.3'
            BackGroundColor     = 'DarkBlue'
        }
        # Set the main color for the GroupBoxes in this sub-tab
        [System.String]$MainColor = 'Cyan'

        # EXECUTION - TAB
        # Create the TabPage
        [System.Windows.Forms.TabPage]$ParentTabPage = New-TabPage @TabProperties

        # EXECUTION - FEATURES
        # Import the Features and store the returned GroupBoxes in variables to be used as the GroupBoxAbove parameter for the next Feature
        $PingComputersGroupBox = Import-FeaturePingComputer -InputObject $InputObject -ParentTabPage $ParentTabPage -Color $MainColor
        $FilePropertiesGroupBox = Import-FeatureFileProperties -InputObject $InputObject -ParentTabPage $ParentTabPage -Color $MainColor -GroupBoxAbove $PingComputersGroupBox
        $CompareFilesGroupBox = Import-FeatureCompareFiles -InputObject $InputObject -ParentTabPage $ParentTabPage -Color $MainColor -GroupBoxAbove $FilePropertiesGroupBox
        $FolderPropertiesGroupBox = Import-FeatureFolderProperties -InputObject $InputObject -ParentTabPage $ParentTabPage -Color $MainColor -GroupBoxAbove $CompareFilesGroupBox
        $null = Import-FeatureCompareFolders -InputObject $InputObject -ParentTabPage $ParentTabPage -Color $MainColor -GroupBoxAbove $FolderPropertiesGroupBox
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}

### END OF FUNCTION
####################################################################################################
