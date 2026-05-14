####################################################################################################
<#
.SYNOPSIS
    Imports the Application Settings tab into the main application.
.DESCRIPTION
    This function imports the Application Settings tab into the main application by creating a new TabPage and adding it to the specified parent TabControl.
.EXAMPLE
    Import-TabApplicationSettings -ParentTabControl $Global:MainTabControl
.INPUTS
    [PSCustomObject]
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
function Import-TabApplicationSettings {
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
            Title               = 'SETTINGS'
            Version             = '6.0.0.0'
            BackGroundColor     = 'Cornsilk'
        }

        # Create the TabPage
        [System.Windows.Forms.TabPage]$ParentTabPage = New-TabPage @TabProperties

        # Create the SubTabControl and add it to the TabPage
        [System.Windows.Forms.TabControl]$SubTabControl = New-SubTabControl -InputObject $InputObject -ParentTabPage $ParentTabPage

        # Import the SubTabs
        Import-SubTabGeneralSettings -InputObject $InputObject -ParentTabControl $SubTabControl
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}

### END OF FUNCTION
####################################################################################################
