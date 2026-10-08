####################################################################################################
<#
.SYNOPSIS
    Imports a template feature into the parent sub-tab.
.DESCRIPTION
    This function provides a reusable template for Import-Feature* functions by creating a GroupBox and adding controls to the specified parent TabPage.
    The TextBox setup follows the 6.0.0.3 graphics pattern: New-TextBox handles
    PropertyName generation and auto-registration directly through its built-in metadata flow.
    Every TextBox must provide a non-empty Label.
.EXAMPLE
    Import-FeatureTemplate -InputObject $MyApplicationObject -ParentTabPage $MyTabPage
.EXAMPLE
    # Use this template as a starting point and replace the two example actions
    # with feature-specific logic.
    Import-FeatureTemplate -InputObject $MyApplicationObject -ParentTabPage $MyTabPage -Color 'Cyan'
.INPUTS
    [PSCustomObject]
    [System.Windows.Forms.TabPage]
    [System.Windows.Forms.GroupBox]
    [System.String]
.OUTPUTS
    [System.Windows.Forms.GroupBox]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.3
    Author          : Imraan Iotana
    Creation Date   : July 2026
    Last Update     : July 2026
#>
####################################################################################################
function Import-FeatureTemplate {
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
            Title           = 'TEMPLATE FEATURE'
            Color           = $Color
            NumberOfRows    = 2
            GroupBoxAbove   = $GroupBoxAbove
        }

        # EXECUTION - GROUPBOX
        # Create the GroupBox
        [System.Windows.Forms.GroupBox]$FeatureGroupBox = New-GroupBox @GroupBoxProperties

        # PREPARATION - TEXTBOXES
        # Set the template TextBox properties
        [System.Collections.Hashtable]$TemplateInputTextBoxProperties = @{
            RowNumber       = 1
            Label           = 'Template Input'
            ToolTip         = 'Example input field for feature template implementations.'
            SizeType        = 'Medium'
            SmallButtons    = @(@(5,'Copy'),@(6,'Paste'),@(7,'Clear'))
        }

        # EXECUTION - TEXTBOXES
        # Create the template TextBox
        [System.Windows.Forms.TextBox]$TemplateInputTextBox = New-TextBox @TemplateInputTextBoxProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ReturnTextBox

        # PREPARATION - BUTTONS
        # Set the example action buttons
        [System.Collections.Hashtable[]]$ActionButtons = @(
            @{
                ColumnNumber    = 1
                Text            = 'Example Action'
                PNGFileName     = 'plugin'
                SizeType        = 'Medium'
                ToolTip         = 'Example action button for this feature template.'
                Function        = { Write-Line "Template action executed for value: $($TemplateInputTextBox.Text)" }.GetNewClosure()
            }
            @{
                ColumnNumber    = 7
                Text            = 'Example Action 2'
                PNGFileName     = 'plugin'
                SizeType        = 'Small'
                ToolTip         = 'Second example action button for this feature template.'
                Function        = { Invoke-TemplateDummyAction2 -TextBox $TemplateInputTextBox }.GetNewClosure()
            }
        )

        # EXECUTION - BUTTONS
        # Create the Buttons
        New-ButtonLine -InputObject $InputObject -ButtonPropertiesArray $ActionButtons -ParentGroupBox $FeatureGroupBox -RowNumber 2

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


####################################################################################################
<#
.SYNOPSIS
    Executes a second dummy action for the template feature.
.DESCRIPTION
    This helper writes a simple status line that includes the current TextBox value.
    It is intended as an example action for new feature implementations.
.EXAMPLE
    Invoke-TemplateDummyAction2 -TextBox $MyTextBox
.INPUTS
    [System.Windows.Forms.TextBox]
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.3
    Author          : Imraan Iotana
    Creation Date   : July 2026
    Last Update     : July 2026
#>
####################################################################################################
function Invoke-TemplateDummyAction2 {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The TextBox used by the second template action.')]
        [System.Windows.Forms.TextBox]$TextBox
    )

    [System.String]$CurrentValue = [System.String]$TextBox.Text
    [System.Int32]$CurrentLength = $CurrentValue.Length
    Write-Line "Template action 2 executed. Current value length: $CurrentLength"
}

### END OF FUNCTION
####################################################################################################

