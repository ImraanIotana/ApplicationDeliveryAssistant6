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
.OUTPUTS
    No objects are returned to the pipeline. All output is written to the host.
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
            Color           = 'Beige'
            NumberOfRows    = 2
        }
        # If the GroupBoxAbove parameter is provided, set the GroupBoxAbove property
        if ($PSBoundParameters.ContainsKey('GroupBoxAbove')) { $FeatureProperties.GroupBoxAbove = $GroupBoxAbove }

        # Create the GroupBox
        [System.Windows.Forms.GroupBox]$FeatureGroupBox = New-GroupBox @FeatureProperties

        # TEXTBOXES
        # Set the TextBox properties
        [System.Collections.Hashtable]$VendorNameTextBoxProperties = @{
            RowNumber       = 1
            Label           = 'Vendor Name:'
            PropertyName    = 'SubTab.Intake.FormalApplicationProperties.VendorName'
            ToolTip         = 'The formal name of the vendor of the application'
            SizeType        = 'Medium'
            Type            = 'Output'
        }
        # Create the TextBoxes
        $Global:SubTabIntakeFormalApplicationPropertiesVendorName = New-TextBox @VendorNameTextBoxProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ReturnTextBox

        # Return the GroupBox object
        $FeatureGroupBox
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}

### END OF FUNCTION
####################################################################################################
