####################################################################################################
<#
.SYNOPSIS
    Imports the Application Custom Properties feature into the Intake tab.
.DESCRIPTION
    This function imports the Application Custom Properties feature into the Intake tab by creating a new GroupBox and adding it to the specified parent TabPage.
.EXAMPLE
    Import-FeatureApplicationCustomProperties -InputObject $MyApplicationObject -ParentTabPage $MyTabPage
.INPUTS
    [PSCustomObject]
    [System.Windows.Forms.TabPage]
    [System.Windows.Forms.GroupBox]
.OUTPUTS
    [System.Windows.Forms.GroupBox]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. All rights reserved.
    Version         : 6.0.0.0
    Author          : Imraan Iotana
    Creation Date   : May 2026
    Last Update     : June 2026
#>
####################################################################################################
function Import-FeatureApplicationCustomProperties {
    [CmdletBinding()]
    [OutputType([System.Windows.Forms.GroupBox])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The ApplicationObject containing the Settings.')]
        [PSCustomObject]$InputObject,

        [Parameter(Mandatory=$true,HelpMessage='The Parent TabPage to which this Feature will be added.')]
        [System.Windows.Forms.TabPage]$ParentTabPage,

        [Parameter(Mandatory=$false,HelpMessage='The GroupBox above which this Feature will be added.')]
        [System.Windows.Forms.GroupBox]$GroupBoxAbove,

        [Parameter(Mandatory=$false,HelpMessage='The color of the GroupBox.')]
        [System.String]$Color
    )

    try {
        # EXECUTION - GROUPBOX
        # Feature properties
        [System.Collections.Hashtable]$FeatureProperties = @{
            InputObject     = $InputObject
            ParentTabPage   = $ParentTabPage
            Title           = 'CUSTOM APPLICATION PROPERTIES'
            Color           = $Color
            NumberOfRows    = 3
            GroupBoxAbove   = $GroupBoxAbove
        }
        # Create the GroupBox
        [System.Windows.Forms.GroupBox]$FeatureGroupBox = New-GroupBox @FeatureProperties -OnSubTab

        # TEXTBOXES
        # Set the VendorNameTextBox properties
        [System.Collections.Hashtable]$VendorNameTextBoxProperties = @{
            RowNumber       = 1
            Label           = 'Custom Vendor Name'
            PropertyName    = 'TextBoxes.ApplicationIntake.CustomProperties.VendorName'
            ToolTip         = 'The custom name of the vendor of the application'
            SizeType        = 'Medium'
            SmallButtons    = @(@(5,'Copy'),(6,'Paste'))
        }
        # Set the ApplicationNameTextBox properties
        [System.Collections.Hashtable]$ApplicationNameTextBoxProperties = @{
            RowNumber       = 2
            Label           = 'Custom Application Name'
            PropertyName    = 'TextBoxes.ApplicationIntake.CustomProperties.ApplicationName'
            ToolTip         = 'The custom name of the application'
            SizeType        = 'Medium'
            SmallButtons    = @(@(5,'Copy'),(6,'Paste'))

        }
        # Set the ApplicationVersionTextBox properties
        [System.Collections.Hashtable]$ApplicationVersionTextBoxProperties = @{
            RowNumber       = 3
            Label           = 'Custom Application Version'
            PropertyName    = 'TextBoxes.ApplicationIntake.CustomProperties.ApplicationVersion'
            ToolTip         = 'The custom version of the application'
            SizeType        = 'Medium'
            SmallButtons    = @(@(5,'Copy'),(6,'Paste'))
        }
        # Create the hashtables for the TextBoxes in the Global Graphics object if they do not already exist
        if (-not $Global:Graphics.TextBoxes.ApplicationIntake.ContainsKey('CustomProperties')) { $Global:Graphics.TextBoxes.ApplicationIntake.CustomProperties = @{} }
        # Create the TextBoxes
        $Global:Graphics.TextBoxes.ApplicationIntake.CustomProperties.VendorName          = New-TextBox @VendorNameTextBoxProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ReturnTextBox
        $Global:Graphics.TextBoxes.ApplicationIntake.CustomProperties.ApplicationName     = New-TextBox @ApplicationNameTextBoxProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ReturnTextBox
        $Global:Graphics.TextBoxes.ApplicationIntake.CustomProperties.ApplicationVersion  = New-TextBox @ApplicationVersionTextBoxProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ReturnTextBox

        # Return the GroupBox object
        $FeatureGroupBox
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}

### END OF FUNCTION
####################################################################################################
