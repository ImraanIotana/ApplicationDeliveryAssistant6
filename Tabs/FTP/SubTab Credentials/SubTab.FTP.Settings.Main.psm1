####################################################################################################
<#
.SYNOPSIS
    Imports the Credentials sub-tab into the FTP tab.
.DESCRIPTION
    This function imports the Credentials sub-tab into the FTP tab by creating a new TabPage and adding it to the specified parent TabControl.
.EXAMPLE
    Import-SubTabCredentials -ParentTabControl $MySubTabControl
.INPUTS
    [PSCustomObject]
    [System.Windows.Forms.TabControl]
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. All rights reserved.
    Version         : 6.0.0.0
    Author          : Imraan Iotana
    Creation Date   : May 2026
    Last Update     : May 2026
#>
####################################################################################################
function Import-SubTabFTPSettings {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The ApplicationObject containing the Settings.')]
        [PSCustomObject]$InputObject,

        [Parameter(Mandatory=$true,HelpMessage='The Parent TabControl to which this TabPage will be added.')]
        [System.Windows.Forms.TabControl]$ParentTabControl
    )

    try {
        # PREPARATION
        # Tab properties
        [System.Collections.Hashtable]$TabProperties = @{
            ParentTabControl    = $ParentTabControl
            Title               = 'SETTINGS'
            Version             = '6.0.0.0'
            BackGroundColor     = 'LightSalmon'
        }

        # EXECUTION
        # Create the hashtables for the TextBoxes in the Global Graphics object if they do not already exist
        if (-not $Global:Graphics.TextBoxes.FTP.ContainsKey('Settings')) { $Global:Graphics.TextBoxes.FTP.Settings = @{} }
        if (-not $Global:Graphics.ComboBoxes.FTP.ContainsKey('Settings')) { $Global:Graphics.ComboBoxes.FTP.Settings = @{} }

        # Create the TabPage
        [System.Windows.Forms.TabPage]$ParentTabPage = New-TabPage @TabProperties

        # Import the Features
        $FTPCredentialsGroupBox = Import-FeatureFTPCredentials -InputObject $InputObject -ParentTabPage $ParentTabPage -GroupBoxAbove $CompareFilesGroupBox
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}

### END OF FUNCTION
####################################################################################################
