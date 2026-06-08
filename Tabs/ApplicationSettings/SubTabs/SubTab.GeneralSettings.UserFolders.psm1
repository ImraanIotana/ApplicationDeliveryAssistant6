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
.OUTPUTS
    No objects are returned to the pipeline. All output is written to the host.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. All rights reserved.
    Version         : 6.0.0.0
    Author          : Imraan Iotana
    Creation Date   : May 2026
    Last Update     : June 2026
#>
####################################################################################################
function Import-FeatureUserFolders {
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
        # PREPARATION - FEATURE PROPERTIES
        # Feature properties
        [System.Collections.Hashtable]$FeatureProperties = @{
            InputObject     = $InputObject
            ParentTabPage   = $ParentTabPage
            Title           = 'FOLDER SETTINGS'
            Color           = 'Brown'
            NumberOfRows    = 4
        }
        # If the GroupBoxAbove parameter is provided, set the GroupBoxAbove property
        if ($PSBoundParameters.ContainsKey('GroupBoxAbove')) { $FeatureProperties.GroupBoxAbove = $GroupBoxAbove }

        # PREPARATION - TEXTBOXES
        # Set the TextBox properties
        [System.Collections.Hashtable]$OutputFolderTextBoxProperties = @{
            RowNumber       = 1
            Label           = 'My Output Folder'
            PropertyName    = 'TextBoxes.ApplicationSettings.FolderSettings.UserOutputFolder'
            ToolTip         = 'The path to the my Output Folder'
            Buttons         = [System.Object[][]]@(@(1, 'Browse Folder'), @(2, 'Open'), @(3, 'Copy'), @(4, 'Paste'), @(5, 'Default'))
            DefaultValue    = "$ENV:USERPROFILE\Downloads"
        }
        [System.Collections.Hashtable]$SoftwareLibraryTextBoxProperties = @{
            RowNumber       = 3
            Label           = 'Software Library'
            PropertyName    = 'TextBoxes.ApplicationSettings.FolderSettings.SoftwareLibrary'
            ToolTip         = 'The path to the Software Library'
            Buttons         = [System.Object[][]]@(@(1, 'Browse Folder'), @(2, 'Open'), @(3, 'Copy'), @(4, 'Paste'), @(5, 'Clear'))
        }

        # EXECUTION
        # Create the GroupBox
        [System.Windows.Forms.GroupBox]$FeatureGroupBox = New-GroupBox @FeatureProperties
        # Create the hashtables for the TextBoxes in the Global Graphics object if they do not already exist
        if (-not $Global:Graphics.TextBoxes.ContainsKey('ApplicationSettings')) { $Global:Graphics.TextBoxes.ApplicationSettings = @{} }
        if (-not $Global:Graphics.TextBoxes.ApplicationSettings.ContainsKey('FolderSettings')) { $Global:Graphics.TextBoxes.ApplicationSettings.FolderSettings = @{} }
        # Create the TextBoxes
        $Global:Graphics.TextBoxes.ApplicationSettings.FolderSettings.UserOutputFolder  = New-TextBox @OutputFolderTextBoxProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ReturnTextBox
        $Global:Graphics.TextBoxes.ApplicationSettings.FolderSettings.SoftwareLibrary   = New-TextBox @SoftwareLibraryTextBoxProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ReturnTextBox
        # Return the GroupBox object
        $FeatureGroupBox
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}

### END OF FUNCTION
####################################################################################################
