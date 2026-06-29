####################################################################################################
<#
.SYNOPSIS
    Imports the Import sub-tab into the AppLocker tab.
.DESCRIPTION
    This function imports the Import sub-tab into the AppLocker tab by creating a new TabPage and adding it to the specified parent TabControl.
.EXAMPLE
    Import-SubTabAppLockerImport -InputObject $InputObject -ParentTabControl $MySubTabControl
.INPUTS
    [PSCustomObject]
    [System.Windows.Forms.TabControl]
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. All rights reserved.
    Version         : 6.0.0.0
    Author          : Imraan Iotana
    Creation Date   : August 2025
    Last Update     : June 2026
#>
####################################################################################################
function Import-SubTabAppLockerImport {
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
            Title               = 'APPLOCKER IMPORT'
            Version             = '6.0.0.0'
            BackGroundColor     = 'Blue'
        }

        # EXECUTION
        # Create the TabPage
        [System.Windows.Forms.TabPage]$ParentTabPage = New-TabPage @TabProperties

        # Import the Features
        if (Get-Command -Name 'Import-FeatureAppLockerImport' -ErrorAction SilentlyContinue) {
            $null = Import-FeatureAppLockerImport -InputObject $InputObject -ParentTabPage $ParentTabPage -Color 'GreenYellow'
        }
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}

### END OF FUNCTION
####################################################################################################
