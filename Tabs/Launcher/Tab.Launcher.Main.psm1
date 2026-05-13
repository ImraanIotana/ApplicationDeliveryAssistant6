#
# Module 'Tab.Launcher.Main.psm1'
# Last Update: May 2026
#

####################################################################################################
<#
.SYNOPSIS
    Imports the Launcher tab into the main application.
.DESCRIPTION
    This function imports the Launcher tab into the main application by creating a new TabPage and adding it to the specified parent TabControl.
.EXAMPLE
    Import-TabLauncher -ParentTabControl $Global:MainTabControl
.INPUTS
    [System.Windows.Forms.TabControl]
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
function Import-TabLauncher {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The ApplicationObject containing the Settings.')]
        [PSCustomObject]$InputObject,

        [Parameter(Mandatory=$true,HelpMessage='The Parent TabControl to which this TabPage will be added.')]
        [System.Windows.Forms.TabControl]$ParentTabControl
    )


    try {
        # Tab properties
        [System.Collections.Hashtable]$TabProperties = @{
            ParentTabControl    = $ParentTabControl
            Title               = 'LAUNCHER'
            Version             = '6.0.0.0'
            BackGroundColor     = 'ForestGreen'
        }

        # Create the TabPage
        [System.Windows.Forms.TabPage]$ParentTabPage = New-TabPage @TabProperties

        # Import the Features
        $AppLauncherGroupBox        = Import-FeatureAppLauncher         -InputObject $InputObject -ParentTabPage $ParentTabPage
        $RegistryLauncherGroupBox   = Import-FeatureRegistryLauncher    -InputObject $InputObject -ParentTabPage $ParentTabPage -GroupBoxAbove $AppLauncherGroupBox
        #Import-FeatureUserFolderLauncher -InputObject $InputObject -ParentTabPage $ParentTabPage
        #Import-FeatureSystemFolderLauncher -InputObject $InputObject -ParentTabPage $ParentTabPage
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}

### END OF FUNCTION
####################################################################################################
