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
    Last Update     : May 2026
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
            NumberOfRows    = 2
        }
        # If the GroupBoxAbove parameter is provided, set the GroupBoxAbove property
        if ($PSBoundParameters.ContainsKey('GroupBoxAbove')) { $FeatureProperties.GroupBoxAbove = $GroupBoxAbove }

        # PREPARATION - TEXTBOXES
        # Set the TextBox properties
        [System.Collections.Hashtable[]]$TextBoxPropertiesArray = @(
            @{
                RowNumber       = 1
                Label           = 'My Output Folder:'
                PropertyName    = 'SubTab.FolderSettings.UserFolders.MyOutputFolder'
                ToolTip         = 'The path to the My Output Folder'
                Buttons         = [System.Object[][]]@(@(1, 'Browse'), @(2, 'Open'), @(3, 'Copy'), @(4, 'Paste'), @(5, 'Default'))
                DefaultValue    = "$ENV:USERPROFILE\Downloads"
            }
        )

        # EXECUTION
        # Create the GroupBox
        [System.Windows.Forms.GroupBox]$FeatureGroupBox = New-GroupBox @FeatureProperties
        # Create the TextBoxes
        foreach ($TextBoxProperties in $TextBoxPropertiesArray) { New-TextBox @TextBoxProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox }

        # Return the GroupBox object
        $FeatureGroupBox
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}

### END OF FUNCTION
####################################################################################################
