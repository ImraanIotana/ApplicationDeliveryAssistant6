####################################################################################################
<#
.SYNOPSIS
    Imports the General Settings sub-tab into the Application Settings tab.
.DESCRIPTION
    This function imports the General Settings sub-tab into the Application Settings tab by creating a new TabPage and adding it to the specified parent TabControl.
.EXAMPLE
    Import-SubTabGeneralSettings -ParentTabControl $MySubTabControl
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
function Import-SubTabGeneralSettings {
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
            Title               = 'GENERAL SETTINGS'
            Version             = '6.0.0.0'
            BackGroundColor     = 'Cornsilk'
        }

        # EXECUTION - TAB
        # Create the TabPage
        [System.Windows.Forms.TabPage]$ParentTabPage = New-TabPage @TabProperties

        # EXECUTION - FEATURES
        # Import the Features
        $TemplateSelectionGroupBox          = Import-FeatureIntakeCustomerTemplateSelection -InputObject $InputObject -Color $MainColor -ParentTabPage $ParentTabPage
        $ExtraDocumentInformationGroupBox   = Import-FeatureExtraDocumentInformation        -InputObject $InputObject -Color $MainColor -ParentTabPage $ParentTabPage -GroupBoxAbove $TemplateSelectionGroupBox
        $null                               = Import-FeatureUserFolders                     -InputObject $InputObject -ParentTabPage $ParentTabPage -GroupBoxAbove $ExtraDocumentInformationGroupBox
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}

### END OF FUNCTION
####################################################################################################
