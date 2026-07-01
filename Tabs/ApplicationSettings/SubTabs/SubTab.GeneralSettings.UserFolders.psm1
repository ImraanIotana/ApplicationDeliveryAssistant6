####################################################################################################
<#
.SYNOPSIS
    Imports the User Folders feature into the Folder Settings sub-tab.
.DESCRIPTION
    This function imports the User Folders feature into the Folder Settings sub-tab by creating a new GroupBox and adding it to the specified parent TabPage.
.EXAMPLE
    Import-FeatureUserFolders -InputObject $MyApplicationObject -ParentTabPage $MyTabPage
.INPUTS
    [PSCustomObject]
    [System.Windows.Forms.TabPage]
    [System.Windows.Forms.GroupBox]
    [System.String]
.OUTPUTS
    [System.Windows.Forms.GroupBox]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. All rights reserved.
    Version         : 6.0.0.1
    Author          : Imraan Iotana
    Creation Date   : May 2026
    Last Update     : July 2026
#>
####################################################################################################
function Import-FeatureUserFolders {
    [CmdletBinding()]
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
            Title           = 'FOLDER SETTINGS'
            Color           = $Color
            NumberOfRows    = 4
            GroupBoxAbove   = $GroupBoxAbove
        }
        # EXECUTION - GROUPBOX
        # Create the GroupBox
        [System.Windows.Forms.GroupBox]$FeatureGroupBox = New-GroupBox @GroupBoxProperties

        # EXECUTION - SUBKEY
        # Create a unique SubKey for the TextBoxes and ComboBoxes
        [System.String]$SubKeyForBoxes = New-SubKeyForBoxes -ParentTabPage $ParentTabPage -PassThru

        # PREPARATION - TEXTBOXES
        # Set the TextBox properties
        [System.Collections.Hashtable]$OutputFolderTextBoxProperties = @{
            RowNumber       = 1
            Label           = 'My Output Folder'
            PropertyName    = "TextBoxes.$SubKeyForBoxes.UserOutputFolder"
            ToolTip         = 'The path to the my Output Folder'
            Buttons         = [System.Object[][]]@(@(1, 'Browse Folder'), @(2, 'Open'), @(3, 'Copy'), @(4, 'Paste'), @(5, 'Default'))
            DefaultValue    = "$ENV:USERPROFILE\Downloads"
        }
        [System.Collections.Hashtable]$SoftwareLibraryTextBoxProperties = @{
            RowNumber       = 3
            Label           = 'Software Library'
            PropertyName    = "TextBoxes.$SubKeyForBoxes.SoftwareLibrary"
            ToolTip         = 'The path to the Software Library'
            Buttons         = [System.Object[][]]@(@(1, 'Browse Folder'), @(2, 'Open'), @(3, 'Copy'), @(4, 'Paste'), @(5, 'Clear'))
        }

        # EXECUTION - TEXTBOXES
        # Create the TextBoxes
        $Global:Graphics.TextBoxes[$SubKeyForBoxes].UserOutputFolder    = New-TextBox @OutputFolderTextBoxProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ReturnTextBox
        $Global:Graphics.TextBoxes[$SubKeyForBoxes].SoftwareLibrary     = New-TextBox @SoftwareLibraryTextBoxProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ReturnTextBox

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
