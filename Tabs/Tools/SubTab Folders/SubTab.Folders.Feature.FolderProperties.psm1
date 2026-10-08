####################################################################################################
<#
.SYNOPSIS
    Imports the Folder Properties feature into the Folders sub-tab.
.DESCRIPTION
    This function imports the Folder Properties feature into the Folders sub-tab by creating a new GroupBox and adding it to the specified parent TabPage.
.EXAMPLE
    Import-FeatureFolderProperties -InputObject $MyApplicationObject -ParentTabPage $MyTabPage
.INPUTS
    [PSCustomObject]
    [System.Windows.Forms.TabPage]
    [System.Windows.Forms.GroupBox]
    [System.String]
.OUTPUTS
    [System.Windows.Forms.GroupBox]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.1
    Author          : Imraan Iotana
    Creation Date   : July 2026
    Last Update     : July 2026
#>
####################################################################################################
function Import-FeatureFolderProperties {
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
            Title           = 'FOLDER PROPERTIES'
            Color           = $Color
            NumberOfRows    = 2
            GroupBoxAbove   = $GroupBoxAbove
        }

        # EXECUTION - GROUPBOX
        # Create the GroupBox
        [System.Windows.Forms.GroupBox]$FeatureGroupBox = New-GroupBox @GroupBoxProperties

        # PREPARATION - TEXTBOX PROPERTIES
        # Set the TextBox properties
        [System.Collections.Hashtable]$FolderTextBoxProperties = @{
            RowNumber       = 1
            Label           = 'Select Folder'
            ToolTip         = 'The path of the folder to analyze.'
            SizeType        = 'Medium'
            SmallButtons    = @(@(5,'Browse Folder'),@(6,'Paste'),@(7,'Open'))
        }

        # EXECUTION - TEXTBOX
        # Create the TextBox
        [System.Windows.Forms.TextBox]$FolderPathTextBox = New-TextBox @FolderTextBoxProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ReturnTextBox

        # EXECUTION - BUTTONS
        # Set the button properties
        [System.Collections.Hashtable[]]$ActionButtons = @(
            @{
                ColumnNumber    = 1
                Text            = 'Properties'
                PNGFileName     = 'microscope'
                SizeType        = 'Medium'
                Function        = { Write-FolderPropertiesToHost -Path $FolderPathTextBox.Text }.GetNewClosure()
            }
            @{
                ColumnNumber    = 7
                Text            = 'Clear Fields'
                PNGFileName     = 'textfield_delete'
                SizeType        = 'Small'
                ToolTip         = 'Clear this field.'
                Function        = { Clear-TextBox -TextBox $FolderPathTextBox }.GetNewClosure()
            }
        )

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
