####################################################################################################
<#
.SYNOPSIS
    Imports the Extra Document Information feature into the General Settings sub-tab.
.DESCRIPTION
    This function imports the Extra Document Information feature into the General Settings sub-tab by creating a new GroupBox and adding it to the specified parent TabPage.
.EXAMPLE
    Import-FeatureExtraDocumentInformation -InputObject $MyApplicationObject -ParentTabPage $MyTabPage
.INPUTS
    [PSCustomObject]
    [System.Windows.Forms.TabPage]
    [System.Windows.Forms.GroupBox]
    [System.String]
.OUTPUTS
    [System.Windows.Forms.GroupBox]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. All rights reserved.
    Version         : 6.0.0.1
    Author          : Imraan Iotana
    Creation Date   : May 2026
    Last Update     : July 2026
#>
####################################################################################################
function Import-FeatureExtraDocumentInformation {
    [CmdletBinding()]
    [OutputType([System.Windows.Forms.GroupBox])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The ApplicationObject containing the Settings.')]
        [PSCustomObject]$InputObject,

        [Parameter(Mandatory=$true,HelpMessage='The Parent TabPage to which this Feature will be added.')]
        [System.Windows.Forms.TabPage]$ParentTabPage,

        [Parameter(Mandatory=$false,HelpMessage='The GroupBox underneath which this Feature will be added.')]
        [System.Windows.Forms.GroupBox]$GroupBoxAbove,

        [Parameter(Mandatory=$false,HelpMessage='The color of the GroupBox.')]
        [System.String]$Color
    )

    try {
        # PREPARATION - GROUPBOX PROPERTIES
        # Set the GroupBox properties
        [System.Collections.Hashtable]$GroupBoxProperties = @{
            InputObject     = $InputObject
            ParentTabPage   = $ParentTabPage
            Title           = 'EXTRA DOCUMENT INFORMATION'
            Color           = $Color
            NumberOfRows    = 2
            GroupBoxAbove   = $GroupBoxAbove
        }

        # EXECUTION - GROUPBOX
        # Create the GroupBox
        [System.Windows.Forms.GroupBox]$FeatureGroupBox = New-GroupBox @GroupBoxProperties -OnSubTab

        # EXECUTION - SUBKEY
        # Create a unique SubKey for the TextBoxes and ComboBoxes
        [System.String]$SubKeyForBoxes = New-SubKeyForBoxes -ParentTabPage $ParentTabPage -PassThru

        # PREPARATION - TEXTBOX PROPERTY PATHS
        # Build textbox property paths.
        [System.String]$UserFullNamePropertyName = "TextBoxes.$SubKeyForBoxes.UserFullName"
        [System.String]$UserEmailAddressPropertyName = "TextBoxes.$SubKeyForBoxes.UserEmailAddress"

        # PREPARATION - TEXTBOX PROPERTIES
        # Set the VendorNameTextBox properties
        [System.Collections.Hashtable]$VendorNameTextBoxProperties = @{
            RowNumber       = 1
            Label           = 'My Full Name'
            PropertyName    = $UserFullNamePropertyName
            ToolTip         = 'The full name of the user that will be used in the document properties.'
            SizeType        = 'Medium'
            SmallButtons    = @(@(5,'Copy'),(6,'Paste'))
        }
        # Set the ApplicationNameTextBox properties
        [System.Collections.Hashtable]$ApplicationNameTextBoxProperties = @{
            RowNumber       = 2
            Label           = 'My Email Address'
            PropertyName    = $UserEmailAddressPropertyName
            ToolTip         = 'The email address of the user that will be used in the document properties.'
            SizeType        = 'Medium'
            SmallButtons    = @(@(5,'Copy'),(6,'Paste'))

        }

        # EXECUTION - TEXTBOXES
        # Create the TextBoxes
        $Global:Graphics.TextBoxes.$SubKeyForBoxes.UserFullName     = New-TextBox @VendorNameTextBoxProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ReturnTextBox
        $Global:Graphics.TextBoxes.$SubKeyForBoxes.UserEmailAddress = New-TextBox @ApplicationNameTextBoxProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ReturnTextBox

        # POST-EXECUTION
        # Return the GroupBox object
        $FeatureGroupBox
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}

### END OF FUNCTION
####################################################################################################

