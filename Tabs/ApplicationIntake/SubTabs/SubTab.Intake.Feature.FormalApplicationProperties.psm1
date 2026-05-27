####################################################################################################
<#
.SYNOPSIS
    Imports the Formal Application Properties feature into the Intake tab.
.DESCRIPTION
    This function imports the Formal Application Properties feature into the Intake tab by creating a new GroupBox and adding it to the specified parent TabPage.
.EXAMPLE
    Import-FeatureFormalApplicationProperties -InputObject $MyApplicationObject -ParentTabPage $MyTabPage
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
    Last Update     : May 2026
#>
####################################################################################################
function Import-FeatureFormalApplicationProperties {
    [CmdletBinding()]
    [OutputType([System.Windows.Forms.GroupBox])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The ApplicationObject containing the Settings.')]
        [PSCustomObject]$InputObject,

        [Parameter(Mandatory=$true,HelpMessage='The Parent TabPage to which this Feature will be added.')]
        [System.Windows.Forms.TabPage]$ParentTabPage,

        [Parameter(Mandatory=$false,HelpMessage='The GroupBox above which this Feature will be added.')]
        [System.Windows.Forms.GroupBox]$GroupBoxAbove
    )

    try {
        # Feature properties
        [System.Collections.Hashtable]$FeatureProperties = @{
            InputObject     = $InputObject
            ParentTabPage   = $ParentTabPage
            Title           = 'FORMAL APPLICATION PROPERTIES'
            Color           = 'Yellow'
            NumberOfRows    = 3
        }
        # If the GroupBoxAbove parameter is provided, set the GroupBoxAbove property
        if ($PSBoundParameters.ContainsKey('GroupBoxAbove')) { $FeatureProperties.GroupBoxAbove = $GroupBoxAbove }

        # Create the GroupBox
        [System.Windows.Forms.GroupBox]$FeatureGroupBox = New-GroupBox @FeatureProperties -OnSubTab

        # TEXTBOXES
        # Set the VendorNameTextBox properties
        [System.Collections.Hashtable]$VendorNameTextBoxProperties = @{
            RowNumber       = 1
            Label           = 'Vendor Name:'
            PropertyName    = 'SubTab.Intake.FormalApplicationProperties.VendorName'
            ToolTip         = 'The formal name of the vendor of the application'
            SizeType        = 'Medium'
            Type            = 'Output'
            SmallButtons    = @(,@(5,'Copy'))
                
        }
        # Set the ApplicationNameTextBox properties
        [System.Collections.Hashtable]$ApplicationNameTextBoxProperties = @{
            RowNumber       = 2
            Label           = 'Application Name:'
            PropertyName    = 'SubTab.Intake.FormalApplicationProperties.ApplicationName'
            ToolTip         = 'The formal name of the application'
            SizeType        = 'Medium'
            Type            = 'Output'
            SmallButtons    = @(,@(5,'Copy'))
                
        }
        # Set the ApplicationVersionTextBox properties
        [System.Collections.Hashtable]$ApplicationVersionTextBoxProperties = @{
            RowNumber       = 3
            Label           = 'Application Version:'
            PropertyName    = 'SubTab.Intake.FormalApplicationProperties.ApplicationVersion'
            ToolTip         = 'The version of the application'
            SizeType        = 'Medium'
            Type            = 'Output'
            SmallButtons    = @(,@(5,'Copy'))
        }
        # Create the TextBoxes
        $Global:SubTabIntakeFormalApplicationPropertiesVendorName = New-TextBox @VendorNameTextBoxProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ReturnTextBox
        $Global:SubTabIntakeFormalApplicationPropertiesApplicationName = New-TextBox @ApplicationNameTextBoxProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ReturnTextBox
        $Global:SubTabIntakeFormalApplicationPropertiesApplicationVersion = New-TextBox @ApplicationVersionTextBoxProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ReturnTextBox

        # Return the GroupBox object
        $FeatureGroupBox
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}

### END OF FUNCTION
####################################################################################################
