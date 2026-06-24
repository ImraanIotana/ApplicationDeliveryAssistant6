####################################################################################################
<#
.SYNOPSIS
    Imports the Intake Extras sub-tab into the Tools tab.
.DESCRIPTION
    This function imports the Intake Extras sub-tab into the Tools tab by creating a new TabPage and adding it to the specified parent TabControl.
.EXAMPLE
    Import-SubTabIntakeExtras -ParentTabControl $MySubTabControl
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
function Import-SubTabIntakeExtras {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The ApplicationObject containing the Settings.')]
        [PSCustomObject]$InputObject,

        [Parameter(Mandatory=$true,HelpMessage='The Parent TabControl to which this TabPage will be added.')]
        [System.Windows.Forms.TabControl]$ParentTabControl
    )

    try {
        # PREPARATION - TABPAGE
        # Tab properties
        [System.Collections.Hashtable]$TabProperties = @{
            ParentTabControl    = $ParentTabControl
            Title               = 'INTAKE EXTRAS'
            Version             = '6.0.0.0'
            BackGroundColor     = 'RoyalBlue'
        }

        # PREPARATION - COLORS
        # Define the colors for the features in this sub-tab
        [System.String]$MainColor = 'Gold'

        # EXECUTION
        # Create the hashtables for the TextBoxes in the Global Graphics object if they do not already exist
        if (-not $Global:Graphics.TextBoxes.IntakeExtras.ContainsKey('ExtraDocumentInformation')) { $Global:Graphics.TextBoxes.IntakeExtras.ExtraDocumentInformation = @{} }

        # EXECUTION - TABPAGE
        # Create the TabPage
        [System.Windows.Forms.TabPage]$ParentTabPage = New-TabPage @TabProperties

        # EXECUTION - FEATURES
        # Import the Features and store the returned GroupBoxes in variables to be used as the GroupBoxAbove parameter for the next Feature
        $TemplateSelectionGroupBox          = Import-FeatureIntakeCustomerTemplateSelection -InputObject $InputObject -Color $MainColor -ParentTabPage $ParentTabPage
        $ExtraDocumentInformationGroupBox   = Import-FeatureExtraDocumentInformation        -InputObject $InputObject -Color $MainColor -ParentTabPage $ParentTabPage -GroupBoxAbove $TemplateSelectionGroupBox
        $null                               = Import-FeatureIntakeMailTemplateSelection     -InputObject $InputObject -Color $MainColor -ParentTabPage $ParentTabPage -GroupBoxAbove $ExtraDocumentInformationGroupBox
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}

### END OF FUNCTION
####################################################################################################
