####################################################################################################
<#
.SYNOPSIS
    Imports the Files sub-tab into the Tools tab.
.DESCRIPTION
    This function imports the Files sub-tab into the Tools tab by creating a new TabPage and adding it to the specified parent TabControl.
.EXAMPLE
    Import-SubTabFiles -InputObject $MyApplicationObject -ParentTabControl $MySubTabControl
.INPUTS
    [PSCustomObject]
    [System.Windows.Forms.TabControl]
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.4.0
    Author          : Imraan Iotana
    Creation Date   : May 2026
    Last Update     : August 2026
#>
####################################################################################################
function Import-SubTabFiles {
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
            Title               = 'FILES'
            Version             = '6.1.0'
            BackGroundColor     = 'DarkBlue'
        }
        # Set the main color for the GroupBoxes in this sub-tab
        [System.String]$MainColor = 'Cyan'

        # EXECUTION - TAB
        # Create the TabPage
        [System.Windows.Forms.TabPage]$ParentTabPage = New-TabPage @TabProperties

        # EXECUTION - FEATURES
        # Import the Features
        $FilePropertiesGroupBox = Import-FeatureFileProperties -InputObject $InputObject -ParentTabPage $ParentTabPage -Color $MainColor
        $CompareFilesGroupBox   = Import-FeatureCompareFiles -InputObject $InputObject -ParentTabPage $ParentTabPage -Color $MainColor -GroupBoxAbove $FilePropertiesGroupBox
        $null                   = Import-FeatureFileBitness -InputObject $InputObject -ParentTabPage $ParentTabPage -Color $MainColor -GroupBoxAbove $CompareFilesGroupBox
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}

### END OF FUNCTION
####################################################################################################
