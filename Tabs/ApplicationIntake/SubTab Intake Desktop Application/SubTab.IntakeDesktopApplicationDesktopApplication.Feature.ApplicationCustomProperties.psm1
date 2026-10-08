####################################################################################################
<#
.SYNOPSIS
    Imports the Application Custom Properties feature into the Desktop Application sub-tab.
.DESCRIPTION
    This function imports the Application Custom Properties feature into the Desktop Application sub-tab by creating a new GroupBox and adding it to the specified parent TabPage.
.EXAMPLE
    Import-FeatureApplicationCustomProperties -InputObject $MyApplicationObject -ParentTabPage $MyTabPage
.INPUTS
    [PSCustomObject]
    [System.Windows.Forms.TabPage]
    [System.Windows.Forms.GroupBox]
.OUTPUTS
    [System.Windows.Forms.GroupBox]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.2.2
    Author          : Imraan Iotana
    Creation Date   : May 2026
    Last Update     : August 2026
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
            Title           = 'CUSTOM APPLICATION PROPERTIES'
            Color           = $Color
            NumberOfRows    = 3
            GroupBoxAbove   = $GroupBoxAbove
        }

        # EXECUTION - GROUPBOX
        # Create the GroupBox
        [System.Windows.Forms.GroupBox]$FeatureGroupBox = New-GroupBox @GroupBoxProperties

        # PREPARATION - TEXTBOX PROPERTIES
        # Set the VendorNameTextBox properties
        [System.Collections.Hashtable]$VendorNameTextBoxProperties = @{
            RowNumber       = 1
            Label           = 'Custom Vendor Name'
            ToolTip         = 'The custom name of the vendor of the application'
            SizeType        = 'Medium'
            SmallButtons    = @(@(5,'Copy'),@(6,'Paste'))
        }
        # Set the ApplicationNameTextBox properties
        [System.Collections.Hashtable]$ApplicationNameTextBoxProperties = @{
            RowNumber       = 2
            Label           = 'Custom Application Name'
            ToolTip         = 'The custom name of the application'
            SizeType        = 'Medium'
            SmallButtons    = @(@(5,'Copy'),@(6,'Paste'))

        }
        # Set the ApplicationVersionTextBox properties
        [System.Collections.Hashtable]$ApplicationVersionTextBoxProperties = @{
            RowNumber       = 3
            Label           = 'Custom Application Version'
            ToolTip         = 'The custom version of the application'
            SizeType        = 'Medium'
            SmallButtons    = @(@(5,'Copy'),@(6,'Paste'))
        }

        # EXECUTION - TEXTBOXES
        # Create the TextBoxes
        [void](New-TextBox @VendorNameTextBoxProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox)
        [void](New-TextBox @ApplicationNameTextBoxProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox)
        [void](New-TextBox @ApplicationVersionTextBoxProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox)

        # Return the GroupBox object
        $FeatureGroupBox
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}

### END OF FUNCTION
####################################################################################################
