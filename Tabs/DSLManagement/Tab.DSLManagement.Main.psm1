####################################################################################################
<#
.SYNOPSIS
    Imports the DSL Management tab into the main application.
.DESCRIPTION
    This function imports the DSL Management tab into the main application by creating a new TabPage and adding it to the specified parent TabControl.
.EXAMPLE
    Import-TabDSLManagement -InputObject $MyApplicationObject -ParentTabControl $Global:MainTabControl
.INPUTS
    [PSCustomObject]
    [System.Windows.Forms.TabControl]
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.4.1
    Author          : Imraan Iotana
    Creation Date   : July 2026
    Last Update     : August 2026
#>
####################################################################################################
function Import-TabDSLManagement {
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
            Title               = 'DSL MANAGEMENT'
            Version             = '6.4.1'
            BackGroundColor     = 'SteelBlue'
        }

        # EXECUTION - TAB
        # Create the TabPage
        [System.Windows.Forms.TabPage]$ParentTabPage = New-TabPage @TabProperties

        # EXECUTION - SUBTABS
        # Create the SubTabControl and add it to the TabPage
        [System.Windows.Forms.TabControl]$SubTabControl = New-SubTabControl -InputObject $InputObject -ParentTabPage $ParentTabPage

        # Import the SubTabs
        Import-SubTabDSLManagementSearch -InputObject $InputObject -ParentTabControl $SubTabControl
        Import-SubTabDSLManagementSettings -InputObject $InputObject -ParentTabControl $SubTabControl

    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}

### END OF FUNCTION
####################################################################################################
