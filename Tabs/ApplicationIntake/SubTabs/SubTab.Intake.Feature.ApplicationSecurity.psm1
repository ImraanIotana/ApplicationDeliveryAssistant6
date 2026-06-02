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
    No objects are returned to the pipeline. All output is written to the host.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. All rights reserved.
    Version         : 6.0.0.0
    Author          : Imraan Iotana
    Creation Date   : May 2026
    Last Update     : May 2026
#>
####################################################################################################
function Import-FeatureApplicationSecurity {
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
        # Feature properties
        [System.Collections.Hashtable]$FeatureProperties = @{
            InputObject     = $InputObject
            ParentTabPage   = $ParentTabPage
            Title           = 'APPLICATION SECURITY'
            Color           = 'Yellow'
            NumberOfRows    = 3
        }
        # If the GroupBoxAbove parameter is provided, set the GroupBoxAbove property
        if ($PSBoundParameters.ContainsKey('GroupBoxAbove')) { $FeatureProperties.GroupBoxAbove = $GroupBoxAbove }

        # Create the GroupBox
        [System.Windows.Forms.GroupBox]$FeatureGroupBox = New-GroupBox @FeatureProperties -OnSubTab

        # TEXTBOXES
        # Set the InstallationFolderTextBox properties
        [System.Collections.Hashtable]$InstallationFolderTextBoxProperties = @{
            RowNumber       = 1
            Label           = 'Installation Folder'
            PropertyName    = 'TextBoxes.ApplicationIntake.Security.InstallationFolder'
            ToolTip         = 'The installation folder of the application'
            SizeType        = 'Medium'
            SmallButtons    = @(@(5,'Browse Folder'),@(6,'Paste'),@(7,'Open'))
        }
        # Set the ADGroupNameTextBox properties
        [System.Collections.Hashtable]$ADGroupNameTextBoxProperties = @{
            RowNumber       = 2
            Label           = 'AD Group Name'
            PropertyName    = 'TextBoxes.ApplicationIntake.Security.ADGroupName'
            ToolTip         = 'The Active Directory group name associated with the application'
            SizeType        = 'Medium'
            SmallButtons    = @(@(5,'Copy'),@(6,'Paste'))
        }
        # Set the ADGroupSIDTextBox properties
        [System.Collections.Hashtable]$ADGroupSIDTextBoxProperties = @{
            RowNumber       = 3
            Label           = 'AD Group SID'
            PropertyName    = 'TextBoxes.ApplicationIntake.Security.ADGroupSID'
            ToolTip         = 'The Security Identifier (SID) of the Active Directory group associated with the application'
            SizeType        = 'Medium'
            SmallButtons    = @(@(5,'Copy'),@(6,'Paste'))
        }
        # Create the hashtables for the TextBoxes in the Global Graphics object if they do not already exist
        if (-not $Global:Graphics.TextBoxes.ContainsKey('ApplicationIntake')) { $Global:Graphics.TextBoxes.ApplicationIntake = @{} }
        if (-not $Global:Graphics.TextBoxes.ApplicationIntake.ContainsKey('Security')) { $Global:Graphics.TextBoxes.ApplicationIntake.Security = @{} }
        # Create the TextBoxes
        $Global:Graphics.TextBoxes.ApplicationIntake.Security.InstallationFolder   = New-TextBox @InstallationFolderTextBoxProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ReturnTextBox
        $Global:Graphics.TextBoxes.ApplicationIntake.Security.ADGroupName          = New-TextBox @ADGroupNameTextBoxProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ReturnTextBox
        $Global:Graphics.TextBoxes.ApplicationIntake.Security.ADGroupSID           = New-TextBox @ADGroupSIDTextBoxProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ReturnTextBox

        # Return the GroupBox object
        $FeatureGroupBox
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}

### END OF FUNCTION
####################################################################################################
