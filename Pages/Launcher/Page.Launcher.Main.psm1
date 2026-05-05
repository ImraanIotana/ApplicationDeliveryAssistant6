#
# Module 'Page.Launcher.Main.psm1'
# Last Update: May 2026
#

####################################################################################################
<#
.SYNOPSIS
    Adds graphical dimensions to the MainTabControl settings based on the MainForm dimensions and the MainTabControl margins.
.DESCRIPTION
    This function adds graphical dimensions to the MainTabControl settings based on the MainForm dimensions and the MainTabControl margins.
     It calculates the width and height of the MainTabControl based on the MainForm dimensions and the MainTabControl margins, and adds these dimensions to the MainTabControl settings in the GraphicalSettings hashtable of the main object.
.EXAMPLE
    Add-MainTabControlDimensions -InputObject $Global:ApplicationObject
.INPUTS
    [PSCustomObject]
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
function Import-ModuleLauncher {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false,HelpMessage='The Parent TabControl to which this new TabPage will be added.')]
        [System.Windows.Forms.TabControl]$ParentTabControl = $Global:MainTabControl
    )

    # Module properties
    [System.Collections.Hashtable]$ModuleProperties = @{
        ParentTabControl    = $ParentTabControl
        Title               = 'LAUNCHER'
        Version             = '5.7.2'
        BackGroundColor     = 'ForestGreen'
    }

    try {
        # Create the Module TabPage
        Write-Line "Importing Module: Launcher" -Type Special
        #[System.Windows.Forms.TabPage]$ParentTabPage = New-TabPage @ModuleProperties

        # Import the Features
        #[System.Windows.Forms.GroupBox]$SystemFolderGroupBox = Import-FeatureSystemFolderLauncher -ParentTabPage $ParentTabPage -ReturnGroupBox
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}

### END OF FUNCTION
####################################################################################################
