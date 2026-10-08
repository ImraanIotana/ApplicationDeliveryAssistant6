####################################################################################################
<#
.SYNOPSIS
    Imports the Application Identity feature into the Custom Application sub-tab.
.DESCRIPTION
    This function creates the Application Identity GroupBox and adds persisted inputs for the vendor or publisher, application name, and application version.
.EXAMPLE
    Import-FeatureCustomApplicationIdentity -InputObject $MyApplicationObject -ParentTabPage $MyTabPage
.INPUTS
    [PSCustomObject]
    [System.Windows.Forms.TabPage]
    [System.Windows.Forms.GroupBox]
    [System.String]
.OUTPUTS
    [System.Windows.Forms.GroupBox]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.3.4
    Author          : Imraan Iotana
    Creation Date   : August 2026
    Last Update     : August 2026
#>
####################################################################################################
function Import-FeatureCustomApplicationIdentity {
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
        # Set the Application Identity GroupBox properties.
        [System.Collections.Hashtable]$GroupBoxProperties = @{
            InputObject   = $InputObject
            ParentTabPage = $ParentTabPage
            Title         = 'APPLICATION IDENTITY'
            Color         = $Color
            NumberOfRows  = 3
            GroupBoxAbove = $GroupBoxAbove
        }

        # EXECUTION - GROUPBOX
        # Create the GroupBox that contains the application identity fields.
        [System.Windows.Forms.GroupBox]$FeatureGroupBox = New-GroupBox @GroupBoxProperties

        # PREPARATION - TEXTBOX PROPERTIES
        # Set the vendor or publisher and application name TextBox properties.
        [System.Collections.Hashtable]$VendorPublisherTextBoxProperties = @{
            RowNumber    = 1
            Label        = 'Vendor / Publisher'
            ToolTip      = 'The vendor, publisher, organization, or internal team responsible for the application.'
            SizeType     = 'Medium'
            SmallButtons = @(@(5,'Copy'),@(6,'Paste'))
        }
        [System.Collections.Hashtable]$ApplicationNameTextBoxProperties = @{
            RowNumber    = 2
            Label        = 'Application Name'
            ToolTip      = 'The name of the custom application.'
            SizeType     = 'Medium'
            SmallButtons = @(@(5,'Copy'),@(6,'Paste'))
        }

        # PREPARATION - COMBOBOX PROPERTIES
        # Allow a specific version to be entered or explicitly select no version.
        [System.Collections.Hashtable]$ApplicationVersionComboBoxProperties = @{
            RowNumber          = 3
            Label              = 'Application Version'
            ToolTip            = 'Enter the application version, or select (No Version) when the application has no version value.'
            SizeType           = 'Medium'
            Type               = 'Input'
            ContentStringArray = @('(No Version)')
            SmallButtons       = @(@(5,'Copy'),@(6,'Paste'))
        }

        # EXECUTION - INPUT CONTROLS
        # Create the identity inputs; the graphics helpers register and persist them automatically.
        $null = New-TextBox @VendorPublisherTextBoxProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox
        $null = New-TextBox @ApplicationNameTextBoxProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox
        [System.Windows.Forms.ComboBox]$ApplicationVersionComboBox = New-ComboBox @ApplicationVersionComboBoxProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ReturnComboBox
        if ($ApplicationVersionComboBox.Text -eq 'Provider managed') {
            $ApplicationVersionComboBox.Text = '(No Version)'
        }

        # POST-EXECUTION
        # Return the GroupBox so later features can be positioned underneath it.
        return $FeatureGroupBox
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}

### END OF FUNCTION
####################################################################################################