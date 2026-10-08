####################################################################################################
<#
.SYNOPSIS
    Imports the Launcher tab into the main application.
.DESCRIPTION
    This function imports the Launcher tab into the main application by creating a new TabPage and adding it to the specified parent TabControl.
.EXAMPLE
    Import-TabLauncher -InputObject $MyApplicationObject -ParentTabControl $Global:MainTabControl
.INPUTS
    [PSCustomObject]
    [System.Windows.Forms.TabControl]
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.8.0
    Author          : Imraan Iotana
    Creation Date   : May 2026
    Last Update     : September 2026
#>
####################################################################################################
function Import-TabLauncher {
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
            Title               = 'LAUNCHER'
            Version             = '6.8.0'
            BackGroundColor     = 'ForestGreen'
        }

        # EXECUTION - TAB
        # Create the TabPage
        [System.Windows.Forms.TabPage]$ParentTabPage = New-TabPage @TabProperties

        # PREPARATION - COLORS
        # Define the colors for the features in this tab
        [System.String]$AppLauncherColor         = 'Yellow'
        [System.String]$TerminalLauncherColor    = 'Gold'
        [System.String]$RegistryLauncherColor    = 'Cyan'
        [System.String]$UserFolderLauncherColor  = 'Lime'
        [System.String]$SystemFolderLauncherColor = 'White'

        # EXECUTION - FEATURES
        # Import the Features
        $AppLauncherGroupBox            = Import-FeatureAppLauncher             -InputObject $InputObject -ParentTabPage $ParentTabPage -Color $AppLauncherColor
        $TerminalLauncherGroupBox       = Import-FeatureTerminalLauncher        -InputObject $InputObject -ParentTabPage $ParentTabPage -GroupBoxAbove $AppLauncherGroupBox -Color $TerminalLauncherColor
        $RegistryLauncherGroupBox       = Import-FeatureRegistryLauncher        -InputObject $InputObject -ParentTabPage $ParentTabPage -GroupBoxAbove $TerminalLauncherGroupBox -Color $RegistryLauncherColor
        $UserFolderLauncherGroupBox     = Import-FeatureUserFolderLauncher      -InputObject $InputObject -ParentTabPage $ParentTabPage -GroupBoxAbove $RegistryLauncherGroupBox -Color $UserFolderLauncherColor
        $null                           = Import-FeatureSystemFolderLauncher    -InputObject $InputObject -ParentTabPage $ParentTabPage -GroupBoxAbove $UserFolderLauncherGroupBox -Color $SystemFolderLauncherColor
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}

### END OF FUNCTION
####################################################################################################
