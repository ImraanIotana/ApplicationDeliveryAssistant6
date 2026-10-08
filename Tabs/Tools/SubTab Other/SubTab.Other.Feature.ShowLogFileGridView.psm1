####################################################################################################
<#
.SYNOPSIS
    Imports the log file GridView feature into the Other sub-tab.
.DESCRIPTION
    Creates a GroupBox for selecting a CSV log file and displaying its entries in a WinForms viewer.
.EXAMPLE
    Import-FeatureShowLogFileGridView -InputObject $MyApplicationObject -ParentTabPage $MyTabPage
.INPUTS
    [PSCustomObject]
    [System.Windows.Forms.TabPage]
    [System.Windows.Forms.GroupBox]
.OUTPUTS
    [System.Windows.Forms.GroupBox]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.4.1
    Author          : Imraan Iotana
    Creation Date   : August 2026
    Last Update     : August 2026
#>
####################################################################################################
function Import-FeatureShowLogFileGridView {
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
            Title           = 'SHOW LOG FILE'
            Color           = $Color
            NumberOfRows    = 2
            GroupBoxAbove   = $GroupBoxAbove
        }

        # EXECUTION - GROUPBOX
        [System.Windows.Forms.GroupBox]$FeatureGroupBox = New-GroupBox @GroupBoxProperties

        # PREPARATION - TEXTBOX PROPERTIES
        [System.Collections.Hashtable]$LogFileTextBoxProperties = @{
            RowNumber       = 1
            Label           = 'Select CSV Log File'
            ToolTip         = 'Select the application CSV log file to display.'
            SizeType        = 'Medium'
            SmallButtons    = @(@(5,'Browse File','Csv'),@(6,'Paste'),@(7,'Open'))
        }

        # EXECUTION - TEXTBOX
        [System.Windows.Forms.TextBox]$LogFileTextBox = New-TextBox @LogFileTextBoxProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ReturnTextBox

        # PREPARATION - BUTTON PROPERTIES
        [System.Collections.Hashtable[]]$ActionButtons = @(
            @{
                ColumnNumber    = 1
                Text            = 'Show Log File'
                PNGFileName     = 'file_extension_log'
                SizeType        = 'Medium'
                ToolTip         = 'Show the selected CSV log file in the ADA log viewer.'
                Function        = { Show-LogFileInGridView -Path $LogFileTextBox.Text }.GetNewClosure()
            }
            @{
                ColumnNumber    = 7
                Text            = 'Clear Field'
                PNGFileName     = 'textfield_delete'
                SizeType        = 'Small'
                ToolTip         = 'Clear the selected log file path.'
                Function        = { Clear-TextBox -TextBox $LogFileTextBox }.GetNewClosure()
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