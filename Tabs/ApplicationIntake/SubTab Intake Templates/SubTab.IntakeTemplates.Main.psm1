####################################################################################################
<#
.SYNOPSIS
    Imports the Intake Templates sub-tab into the Application Intake tab.
.DESCRIPTION
    This function imports the Intake Templates sub-tab into the Application Intake tab by creating a new TabPage and adding it to the specified parent TabControl.
.EXAMPLE
    Import-SubTabIntakeTemplates -InputObject $MyApplicationObject -ParentTabControl $MySubTabControl
.INPUTS
    [PSCustomObject]
    [System.Windows.Forms.TabControl]
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.9.0
    Author          : Imraan Iotana
    Creation Date   : July 2026
    Last Update     : October 2026
#>
####################################################################################################
function Import-SubTabIntakeTemplates {
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
            Title               = 'INTAKE TEMPLATES'
            Version             = '6.9.0'
            BackGroundColor     = 'RoyalBlue'
        }

        # EXECUTION - TAB
        # Create the TabPage
        [System.Windows.Forms.TabPage]$ParentTabPage = New-TabPage @TabProperties

        # Set the main color for the GroupBoxes in this sub-tab
        [System.String]$MainColor = 'Cyan'

        # EXECUTION - FEATURES
        # Import the features
        $CustomerTemplateListGroupBox       = Import-FeatureCustomerTemplateList -InputObject $InputObject -Color $MainColor -ParentTabPage $ParentTabPage
        $ExtraDocumentInformationGroupBox   = Import-FeatureExtraDocumentInformation -InputObject $InputObject -Color $MainColor -ParentTabPage $ParentTabPage -GroupBoxAbove $CustomerTemplateListGroupBox
        $MailTemplateGroupBox               = Import-FeatureIntakeMailTemplateSelection -InputObject $InputObject -Color $MainColor -ParentTabPage $ParentTabPage -GroupBoxAbove $ExtraDocumentInformationGroupBox
        $null                               = Import-FeatureDocumentGeneration -InputObject $InputObject -Color $MainColor -ParentTabPage $ParentTabPage -GroupBoxAbove $MailTemplateGroupBox
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}

### END OF FUNCTION
####################################################################################################
