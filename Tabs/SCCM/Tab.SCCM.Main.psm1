####################################################################################################
<#
.SYNOPSIS
    Imports the SCCM tab into the main application.
.DESCRIPTION
    This function imports the SCCM tab into the main application by creating a new TabPage and adding it to the specified parent TabControl.
.EXAMPLE
    Import-TabSCCM -InputObject $MyApplicationObject -ParentTabControl $Global:MainTabControl
.INPUTS
    [PSCustomObject]
    [System.Windows.Forms.TabControl]
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.1
    Author          : Imraan Iotana
    Creation Date   : July 2026
    Last Update     : July 2026
#>
####################################################################################################
function Import-TabSCCM {
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
            Title               = 'SCCM'
            Version             = '6.0.0.1'
            BackGroundColor     = 'ForestGreen'
        }

        # EXECUTION - TAB
        # Create the TabPage
        [System.Windows.Forms.TabPage]$ParentTabPage = New-TabPage @TabProperties

        # EXECUTION - SUBTABS
        # Create the SubTabControl and add it to the TabPage
        [System.Windows.Forms.TabControl]$SubTabControl = New-SubTabControl -InputObject $InputObject -ParentTabPage $ParentTabPage

        # Import the SCCM SubTabs
        Import-SubTabSCCMApplication -InputObject $InputObject -ParentTabControl $SubTabControl
        Import-SubTabSCCMSettings -InputObject $InputObject -ParentTabControl $SubTabControl
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}

### END OF FUNCTION
####################################################################################################
