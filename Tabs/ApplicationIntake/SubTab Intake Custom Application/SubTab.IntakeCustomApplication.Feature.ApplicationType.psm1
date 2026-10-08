####################################################################################################
<#
.SYNOPSIS
    Imports the Application Type feature into the Custom Application sub-tab.
.DESCRIPTION
    This function creates the Application Type GroupBox, adds a persisted selection-only ComboBox containing Web Application, Office Application, and Custom Application options, and provides the scoped Clear All Fields action.
.EXAMPLE
    Import-FeatureCustomApplicationType -InputObject $MyApplicationObject -ParentTabPage $MyTabPage
.INPUTS
    [PSCustomObject]
    [System.Windows.Forms.TabPage]
    [System.Windows.Forms.GroupBox]
    [System.String]
.OUTPUTS
    [System.Windows.Forms.GroupBox]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.3.1
    Author          : Imraan Iotana
    Creation Date   : August 2026
    Last Update     : August 2026
#>
####################################################################################################
function Import-FeatureCustomApplicationType {
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
        # Set the Application Type GroupBox properties.
        [System.Collections.Hashtable]$GroupBoxProperties = @{
            InputObject   = $InputObject
            ParentTabPage = $ParentTabPage
            Title         = 'APPLICATION TYPE'
            Color         = $Color
            NumberOfRows  = 1
            GroupBoxAbove = $GroupBoxAbove
        }

        # EXECUTION - GROUPBOX
        # Create the GroupBox that contains the application type selector.
        [System.Windows.Forms.GroupBox]$FeatureGroupBox = New-GroupBox @GroupBoxProperties

        # PREPARATION - COMBOBOX PROPERTIES
        # Offer grouped Web, Office, and manual Custom Application options.
        [System.String[]]$ApplicationTypes = @(
            'Web Application'
            'Office Application'
            'Custom Application'
        )
        [System.Collections.Hashtable]$ApplicationTypeComboBoxProperties = @{
            RowNumber         = 1
            Label             = 'Application Type'
            ToolTip           = 'Select Web Application, Office Application, or Custom Application.'
            SizeType          = 'Medium'
            ContentStringArray = $ApplicationTypes
        }

        # EXECUTION - COMBOBOX
        # Create the selection-only ComboBox; New-ComboBox registers and persists it automatically.
        $null = New-ComboBox @ApplicationTypeComboBoxProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox

        # PREPARATION - BUTTON PROPERTIES
        # Configure the action that clears only Custom Application controls.
        [System.Collections.Hashtable]$ClearAllFieldsButtonProperties = @{
            ColumnNumber = 5
            RowNumber    = 1
            Text         = 'Clear All Fields'
            PNGFileName  = 'textfield_delete'
            SizeType     = 'Medium'
            ToolTip      = 'Clear all fields in the Custom Application form.'
            Function     = {
                if (-not (Get-UserConfirmation -Title 'Clear All Fields' -Body "This will CLEAR ALL fields in the Custom Application form.`n`nAre you sure you want to continue?")) { return }
                Clear-CustomApplicationFormFields
            }.GetNewClosure()
        }

        # EXECUTION - BUTTON
        # Create the scoped clear button.
        New-Button @ClearAllFieldsButtonProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox

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