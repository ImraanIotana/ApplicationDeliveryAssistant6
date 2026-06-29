####################################################################################################
<#
.SYNOPSIS
    Imports the Application Security feature into the Intake tab.
.DESCRIPTION
    This function imports the Application Security feature into the Intake tab by creating a new GroupBox and adding it to the specified parent TabPage.
.EXAMPLE
    Import-FeatureApplicationSecurity -InputObject $MyApplicationObject -ParentTabPage $MyTabPage
.INPUTS
    [PSCustomObject]
    [System.Windows.Forms.TabPage]
    [System.Windows.Forms.GroupBox]
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. All rights reserved.
    Version         : 6.0.0.0
    Author          : Imraan Iotana
    Creation Date   : May 2026
    Last Update     : June 2026
#>
####################################################################################################
function Import-FeatureAppLockerCreation {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The ApplicationObject containing the Settings.')]
        [PSCustomObject]$InputObject,

        [Parameter(Mandatory=$true,HelpMessage='The Parent TabPage to which this Feature will be added.')]
        [System.Windows.Forms.TabPage]$ParentTabPage,

        [Parameter(Mandatory=$false,HelpMessage='The GroupBox above which this Feature will be added.')]
        [System.Windows.Forms.GroupBox]$GroupBoxAbove,

        [Parameter(Mandatory=$false,HelpMessage='The color of the GroupBox.')]
        [System.String]$Color
    )

    try {
        # EXECUTION - GROUPBOX
        # Feature properties
        [System.Collections.Hashtable]$FeatureProperties = @{
            InputObject     = $InputObject
            ParentTabPage   = $ParentTabPage
            Title           = 'APPLICATION SECURITY'
            Color           = $Color
            NumberOfRows    = 5
            GroupBoxAbove   = $GroupBoxAbove
        }
        # Create the GroupBox
        [System.Windows.Forms.GroupBox]$FeatureGroupBox = New-GroupBox @FeatureProperties -OnSubTab

        # Ensure the flat storage key exists for this tab-feature pair and capture it.
        [System.String]$SubKeyForBoxes = New-SubKeyForBoxes -ParentTabPage $ParentTabPage -PassThru

        # EXECUTION - TEXTBOXES
        # Set the InstallationFolderTextBox properties
        [System.Collections.Hashtable]$InstallationFolderTextBoxProperties = @{
            RowNumber       = 1
            Label           = 'Select Folder'
            PropertyName    = "TextBoxes.$SubKeyForBoxes.FolderPath"
            ToolTip         = 'The folder to create AppLocker policies for.'
            SizeType        = 'Medium'
            SmallButtons    = @(@(5,'Browse Folder'),@(6,'Paste'),@(7,'Open'))
        }
        # Set the ADGroupNameTextBox properties
        [System.Collections.Hashtable]$ADGroupNameTextBoxProperties = @{
            RowNumber       = 2
            Label           = 'AD Group Name'
            PropertyName    = "TextBoxes.$SubKeyForBoxes.ADGroupName"
            ToolTip         = 'The Active Directory group name that will be associated with the AppLocker policies'
            DefaultValue    = 'Everyone'
            SizeType        = 'Medium'
            SmallButtons    = @(@(5,'Copy'),@(6,'Paste'))
        }
        # Set the ADGroupSIDTextBox properties
        [System.Collections.Hashtable]$ADGroupSIDTextBoxProperties = @{
            RowNumber       = 3
            Label           = 'AD Group SID'
            PropertyName    = "TextBoxes.$SubKeyForBoxes.ADGroupSID"
            ToolTip         = 'The Security Identifier (SID) of the Active Directory group associated with the AppLocker policies'
            DefaultValue    = 'S-1-1-0'
            SizeType        = 'Medium'
            SmallButtons    = @(@(5,'Copy'),@(6,'Paste'))
        }
        # Create the TextBoxes
        $Global:Graphics.TextBoxes[$SubKeyForBoxes].FolderPath    = New-TextBox @InstallationFolderTextBoxProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ReturnTextBox
        $Global:Graphics.TextBoxes[$SubKeyForBoxes].ADGroupName   = New-TextBox @ADGroupNameTextBoxProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ReturnTextBox
        $Global:Graphics.TextBoxes[$SubKeyForBoxes].ADGroupSID    = New-TextBox @ADGroupSIDTextBoxProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ReturnTextBox

        # EXECUTION - BUTTONS
        # Set the Default Button properties
        [System.Collections.Hashtable]$ADGroupDefaultButton = @{
            ColumnNumber    = 7
            Text            = 'Default'
            PNGFileName     = 'arrow_undo'
            SizeType        = 'Small'
            ToolTip         = 'Set the Active Directory group and SID to their default values.'
            Function        = {
                # This button is not a true "default" button as the default values are not hardcoded but rather set in the TextBox properties.
                Reset-TextBox -TextBox $Global:Graphics.TextBoxes[$SubKeyForBoxes].ADGroupName
                Reset-TextBox -TextBox $Global:Graphics.TextBoxes[$SubKeyForBoxes].ADGroupSID -Force
            }.GetNewClosure()
        }
        # Set the Action Button
        [System.Collections.Hashtable]$CreateButton = @{
            ColumnNumber    = 1
            Text            = 'Create AppLocker Files'
            PNGFileName     = 'shield'
            SizeType        = 'Large'
            ToolTip         = 'Create the AppLocker files for the selected folder.'
            Function        = {
                [System.String]$FolderToScan        = $Global:Graphics.TextBoxes[$SubKeyForBoxes].FolderPath.Text
                [System.String]$ADGroupSID          = $Global:Graphics.TextBoxes[$SubKeyForBoxes].ADGroupSID.Text
                [System.Object]$SelectedTemplate    = $Global:Graphics.ComboBoxes.ApplicationIntake.TemplateSelection.SelectedItem
                New-AppLockerFile -FolderToScan $FolderToScan -ADGroupSID $ADGroupSID -SelectedTemplate $SelectedTemplate -OpenOutputFolder
            }.GetNewClosure()
        }
        # Create the Buttons
        New-Button @ADGroupDefaultButton -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -RowNumber 3
        New-Button @CreateButton -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -RowNumber 4
        
        # OUTPUT
        # Return the GroupBox object
        $FeatureGroupBox
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}

### END OF FUNCTION
####################################################################################################

