####################################################################################################
<#
.SYNOPSIS
    Creates a new ComboBox and adds it to the specified parent GroupBox.
.DESCRIPTION
    This function creates a new ComboBox and adds it to the specified parent GroupBox.
    The ComboBox properties such as location, size, font, colors, and custom properties are set based on the input parameters and the GraphicalSettings in the main object.
.EXAMPLE
    New-ComboBox -ParentGroupBox $MyGroupBox -RowNumber 2 -SizeType 'Medium' -Type 'Input' -Label 'Select Name:' -TextColor 'Blue' -PropertyName 'UserName'
.INPUTS
    [PSCustomObject]
    [System.Windows.Forms.GroupBox]
    [System.Int32]
    [System.String]
    [System.Object[][]]
.OUTPUTS
    [System.Windows.Forms.ComboBox]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.2
    Author          : Imraan Iotana
    Creation Date   : May 2026
    Last Update     : July 2026
#>
####################################################################################################
function New-ComboBox {
    [CmdletBinding()]
    [OutputType([System.Windows.Forms.ComboBox])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The ApplicationObject containing the settings.')]
        [PSCustomObject]$InputObject,

        [Parameter(Mandatory=$true,HelpMessage='The Parent GroupBox to which this ComboBox will be added.')]
        [System.Windows.Forms.GroupBox]$ParentGroupBox,

        [Parameter(Mandatory=$false,HelpMessage='The RowNumber where the ComboBox will be placed.')]
        [System.Int32]$RowNumber = 1,

        [Parameter(Mandatory=$false,HelpMessage='The SizeType of the ComboBox. This will influence only the width, not the height.')]
        [ValidateSet('Small','Medium','Large')]
        [System.String]$SizeType = 'Large',

        [Parameter(Mandatory=$false,HelpMessage='The Type of ComboBox. This will influence the ComboBox background color, and whether users can type into it.')]
        [ValidateSet('Input','Output')]
        [System.String]$Type = 'Output',

        [Parameter(Mandatory=$false,HelpMessage='The Label that will be placed on the left of the ComboBox.')]
        [System.String]$Label,

        [Parameter(Mandatory=$false,HelpMessage='The color of the text.')]
        [System.String]$TextColor,

        [Parameter(Mandatory=$false,HelpMessage='The PropertyName that will be added to the object, to interact with the registry.')]
        [System.String]$PropertyName,

        [Parameter(Mandatory=$false,HelpMessage='The DefaultValue that will be added to the object.')]
        [Alias('Default')]
        [System.String]$DefaultValue,

        [Parameter(Mandatory=$false,HelpMessage='The DefaultButtonsArray that will be added to the object.')]
        [System.Object[][]]$Buttons,

        [Parameter(Mandatory=$false,HelpMessage='The small buttons array that will be added to the object.')]
        [System.Object[][]]$SmallButtons,

        [Parameter(Mandatory=$false,HelpMessage='The ToolTip text to display when hovering over the ComboBox.')]
        [System.String]$ToolTip,

        [Parameter(Mandatory=$false,HelpMessage='The array of strings that will be displayed in the ComboBox.')]
        [System.String[]]$ContentStringArray,

        [Parameter(Mandatory=$false,HelpMessage='The array of objects that will be displayed in the ComboBox.')]
        [System.Object[]]$ApplicationsFromRegistry,

        [Parameter(Mandatory=$false,HelpMessage='The array of objects that will be displayed in the ComboBox.')]
        [System.Object[]]$Shortcuts,

        [Parameter(Mandatory=$false,HelpMessage='The array of objects that will be displayed in the ComboBox.')]
        [System.Object[]]$CustomerTemplates,

        [Parameter(Mandatory=$false,HelpMessage='The array of objects that will be displayed in the ComboBox.')]
        [System.Object[]]$MailTemplates,

        [Parameter(Mandatory=$false,HelpMessage='Switch for returning the ComboBox object after it is created and added to the parent.')]
        [System.Management.Automation.SwitchParameter]$ReturnComboBox
    )

    try {
        # VALIDATION - LABEL VALIDATION
        # Every ComboBox must have a non-empty label so registration failures point to the offending call site
        if (Test-String -IsEmpty $Label) {
            throw 'New-ComboBox requires a non-empty -Label.'
        }

        [System.Collections.Hashtable]$ContentSourceParameters = @{
            ContentStringArray       = $ContentStringArray
            ApplicationsFromRegistry = $ApplicationsFromRegistry
            Shortcuts                = $Shortcuts
            CustomerTemplates        = $CustomerTemplates
            MailTemplates            = $MailTemplates
        }
        [System.Collections.Hashtable]$ContentSource = Get-ComboBoxContentSource @ContentSourceParameters

        # PREPARATION
        # Create a new ComboBox as the Output
        [System.Windows.Forms.ComboBox]$NewComboBox = New-Object System.Windows.Forms.ComboBox

        # EXECUTION - SET PROPERTIES
        # Apply shared ComboBox layout and style properties
        Set-ComboBoxCoreProperties -InputObject $InputObject -ParentGroupBox $ParentGroupBox -ComboBox $NewComboBox -RowNumber $RowNumber -SizeType $SizeType -Type $Type -TextColor $TextColor

        # CONTENT
        Set-ComboBoxContent -ComboBox $NewComboBox -ContentSource $ContentSource

        # EXECUTION - CUSTOM PROPERTIES '(TAG)'
        # Seed metadata, register this ComboBox, and create its label
        Initialize-ComboBoxTagRegistrationAndLabel -InputObject $InputObject -ParentGroupBox $ParentGroupBox -ComboBox $NewComboBox -Label $Label -PropertyName $PropertyName -RowNumber $RowNumber

        # PROPERTYNAME - INTERACTION WITH REGISTRY
        # Bind settings event handlers and resolve the stored value
        [System.String]$StoredPropertyValue = Set-ComboBoxUserSettingBinding -ComboBox $NewComboBox -Type $Type
        # Apply the stored value after content has been loaded
        Set-ComboBoxValueFromStoredSetting -ComboBox $NewComboBox -StoredPropertyValue $StoredPropertyValue -Type $Type

        # DEFAULTVALUE
        # Add and apply the DefaultValue
        Set-ComboBoxDefaultValue -ComboBox $NewComboBox -DefaultValue $DefaultValue

        # BUTTONS
        # Add regular and small button lines to the ComboBox
        Add-ButtonsToComboBox -InputObject $InputObject -ParentGroupBox $ParentGroupBox -ComboBox $NewComboBox -RowNumber $RowNumber -Buttons $Buttons -SmallButtons $SmallButtons

        # TOOLTIP
        # Add the ToolTip
        if (Test-String -IsPopulated $ToolTip) {
            [System.Windows.Forms.ToolTip]$ComboBoxToolTip = New-Object System.Windows.Forms.ToolTip
            $ComboBoxToolTip.SetToolTip($NewComboBox, $ToolTip)
        }

        # ADD TO PARENT
        # Add the new combobox to the parent
        $ParentGroupBox.Controls.Add($NewComboBox)

        # POST-EXECUTION
        # If the ReturnComboBox switch is set, return the ComboBox object
        if ($ReturnComboBox.IsPresent) { $NewComboBox }
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}

### END OF FUNCTION
####################################################################################################

