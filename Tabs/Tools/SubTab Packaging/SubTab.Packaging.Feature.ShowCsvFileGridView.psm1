####################################################################################################
<#
.SYNOPSIS
    Imports the CSV file GridView feature into the General sub-tab.
.DESCRIPTION
    Creates a GroupBox for selecting any CSV file and displaying its content in a sortable grid window.
.EXAMPLE
    Import-FeatureShowCsvFileGridView -InputObject $MyApplicationObject -ParentTabPage $MyTabPage
.INPUTS
    [PSCustomObject]
    [System.Windows.Forms.TabPage]
    [System.Windows.Forms.GroupBox]
.OUTPUTS
    [System.Windows.Forms.GroupBox]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.10.3
    Author          : Imraan Iotana
    Creation Date   : August 2026
    Last Update     : October 2026
#>
####################################################################################################
function Import-FeatureShowCsvFileGridView {
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
        [System.Collections.Hashtable]$GroupBoxProperties = @{
            InputObject     = $InputObject
            ParentTabPage   = $ParentTabPage
            Title           = 'SHOW CSV FILE'
            Color           = $Color
            NumberOfRows    = 2
            GroupBoxAbove   = $GroupBoxAbove
        }

        # EXECUTION - GROUPBOX
        [System.Windows.Forms.GroupBox]$FeatureGroupBox = New-GroupBox @GroupBoxProperties

        # PREPARATION - TEXTBOX PROPERTIES
        [System.Collections.Hashtable]$CsvFileTextBoxProperties = @{
            RowNumber       = 1
            Label           = 'Select CSV File'
            ToolTip         = 'Select the CSV file to display. The delimiter (comma, semicolon, tab or pipe) is detected automatically.'
            SizeType        = 'Medium'
            SmallButtons    = @(@(5,'Browse File','Csv'),@(6,'Paste'),@(7,'Open'))
            IsPath          = $true
            # Keeps the path stored by earlier versions, when this feature was named SHOW LOG FILE
            PropertyName    = 'TextBoxes.tools.other.showlogfile.SelectCSVLogFile'
        }

        # EXECUTION - TEXTBOX
        [System.Windows.Forms.TextBox]$CsvFileTextBox = New-TextBox @CsvFileTextBoxProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ReturnTextBox

        # PREPARATION - BUTTON PROPERTIES
        [System.Collections.Hashtable[]]$ActionButtons = @(
            @{
                ColumnNumber    = 1
                Text            = 'Show CSV File'
                PNGFileName     = 'file_extension_log'
                SizeType        = 'Medium'
                ToolTip         = 'Show the selected CSV file in a sortable grid window.'
                Function        = { Show-CsvFileInGridView -Path $CsvFileTextBox.Text }.GetNewClosure()
            }
            @{
                ColumnNumber    = 7
                Text            = 'Clear Field'
                PNGFileName     = 'textfield_delete'
                SizeType        = 'Small'
                ToolTip         = 'Clear the selected CSV file path.'
                Function        = { Clear-TextBox -TextBox $CsvFileTextBox }.GetNewClosure()
            }
        )

        # EXECUTION - BUTTONS
        New-ButtonLine -InputObject $InputObject -ButtonPropertiesArray $ActionButtons -ParentGroupBox $FeatureGroupBox -RowNumber 2

        # POST-EXECUTION
        return $FeatureGroupBox
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}

### END OF FUNCTION
####################################################################################################