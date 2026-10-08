####################################################################################################
<#
.SYNOPSIS
    Imports the Folders sub-tab into the Tools tab.
.DESCRIPTION
    This function imports the Folders sub-tab into the Tools tab by creating a new TabPage and adding it to the specified parent TabControl.
.EXAMPLE
    Import-SubTabFolders -InputObject $MyApplicationObject -ParentTabControl $MySubTabControl
.INPUTS
    [PSCustomObject]
    [System.Windows.Forms.TabControl]
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.8.1
    Author          : Imraan Iotana
    Creation Date   : July 2026
    Last Update     : September 2026
#>
####################################################################################################
function Import-SubTabFolders {
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
            Title               = 'FOLDERS'
            Version             = '6.8.1'
            BackGroundColor     = '#2F6F6D'
        }
        # Set the main color for the GroupBoxes in this sub-tab
        [System.String]$MainColor = '#E6F4F1'

        # EXECUTION - TAB
        # Create the TabPage
        [System.Windows.Forms.TabPage]$ParentTabPage = New-TabPage @TabProperties

        # EXECUTION - FEATURES
        # Import the features
        [System.Windows.Forms.GroupBox]$FolderPropertiesGroupBox = Import-FeatureFolderProperties -InputObject $InputObject -ParentTabPage $ParentTabPage -Color $MainColor
        [System.Windows.Forms.GroupBox]$CompareFoldersGroupBox = Import-FeatureCompareFolders -InputObject $InputObject -ParentTabPage $ParentTabPage -Color $MainColor -GroupBoxAbove $FolderPropertiesGroupBox
        $null = Import-FeatureFolderCopy -InputObject $InputObject -ParentTabPage $ParentTabPage -Color $MainColor -GroupBoxAbove $CompareFoldersGroupBox
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}

### END OF FUNCTION
####################################################################################################
