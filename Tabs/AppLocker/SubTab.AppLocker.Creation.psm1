####################################################################################################
<#
.SYNOPSIS
    Imports the Creation sub-tab into the AppLocker section.
.DESCRIPTION
    This function imports the Creation sub-tab into the AppLocker section by creating a new TabPage and adding it to the specified parent TabControl.
.EXAMPLE
    Import-SubTabAppLockerCreation -InputObject $MyApplicationObject -ParentTabControl $MySubTabControl
.INPUTS
    [PSCustomObject]
    [System.Windows.Forms.TabControl]
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.3.3
    Author          : Imraan Iotana
    Creation Date   : June 2026
    Last Update     : July 2026
#>
####################################################################################################
function Import-SubTabAppLockerCreation {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The ApplicationObject containing the Settings.')]
        [PSCustomObject]$InputObject,

        [Parameter(Mandatory=$true,HelpMessage='The Parent TabControl to which this TabPage will be added.')]
        [System.Windows.Forms.TabControl]$ParentTabControl
    )

    try {
        # PREPARATION - TAB PROPERTIES
        # Tab properties
        [System.Collections.Hashtable]$TabProperties = @{
            ParentTabControl    = $ParentTabControl
            Title               = 'APPLOCKER CREATION'
            Version             = '6.3.3'
            BackGroundColor     = 'SteelBlue'
        }
        # Set the main color for the GroupBoxes in this sub-tab
        [System.String]$MainColor = 'Cyan'

        # EXECUTION - TAB
        # Create the TabPage
        [System.Windows.Forms.TabPage]$ParentTabPage = New-TabPage @TabProperties

        # EXECUTION - FEATURES
        # Import the Feature
        $null = Import-FeatureAppLockerCreation -InputObject $InputObject -ParentTabPage $ParentTabPage -Color $MainColor
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
    Imports the AppLocker Creation feature into the AppLocker section.
.DESCRIPTION
    This function imports the AppLocker Creation feature into the AppLocker section by creating a new GroupBox and adding it to the specified parent TabPage.
.EXAMPLE
    Import-FeatureAppLockerCreation -InputObject $MyApplicationObject -ParentTabPage $MyTabPage
.INPUTS
    [PSCustomObject]
    [System.Windows.Forms.TabPage]
    [System.Windows.Forms.GroupBox]
.OUTPUTS
    [System.Windows.Forms.GroupBox]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.3.3
    Author          : Imraan Iotana
    Creation Date   : May 2026
    Last Update     : July 2026
#>
####################################################################################################
function Import-FeatureAppLockerCreation {
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
            Title           = 'APPLOCKER CREATION'
            Color           = $Color
            NumberOfRows    = 5
            GroupBoxAbove   = $GroupBoxAbove
        }

        # EXECUTION - GROUPBOX
        # Create the GroupBox
        [System.Windows.Forms.GroupBox]$FeatureGroupBox = New-GroupBox @GroupBoxProperties

        # PREPARATION - TEXTBOX PROPERTIES
        # Set the InstallationFolderTextBox properties
        [System.Collections.Hashtable]$InstallationFolderTextBoxProperties = @{
            RowNumber       = 1
            Label           = 'Select Folder'
            ToolTip         = 'The folder to create AppLocker policies for.'
            SizeType        = 'Medium'
            SmallButtons    = @(@(5,'Browse Folder'),@(6,'Paste'),@(7,'Open'))
        }
        # Set the ADGroupNameTextBox properties
        [System.Collections.Hashtable]$ADGroupNameTextBoxProperties = @{
            RowNumber       = 2
            Label           = 'AD Group Name'
            ToolTip         = 'The Active Directory group name that will be associated with the AppLocker policies'
            DefaultValue    = 'Everyone'
            SizeType        = 'Medium'
            SmallButtons    = @(@(5,'Copy'),@(6,'Paste'))
        }
        # Set the ADGroupSIDTextBox properties
        [System.Collections.Hashtable]$ADGroupSIDTextBoxProperties = @{
            RowNumber       = 3
            Label           = 'AD Group SID'
            ToolTip         = 'The Security Identifier (SID) of the Active Directory group associated with the AppLocker policies'
            DefaultValue    = 'S-1-1-0'
            SizeType        = 'Medium'
            SmallButtons    = @(@(5,'Copy'),@(6,'Paste'))
        }
        # Set the Application ID ComboBox properties
        [System.Collections.Hashtable]$ApplicationIDComboBoxProperties = @{
            RowNumber       = 4
            Label           = 'Application ID (Optional)'
            ToolTip         = 'The unique identifier for the application associated with the AppLocker policies'
            SizeType        = 'Medium'
            Type            = 'Input'
            ContentStringArray = Get-DSLDirectSubFolderNames
            SmallButtons    = @(@(5,'Copy'),@(6,'Paste'),@(7,'Clear'))
        }

        # EXECUTION - INPUT CONTROLS
        # Create the input controls
        [System.Windows.Forms.TextBox]$InstallationFolderTextBox    = New-TextBox @InstallationFolderTextBoxProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ReturnTextBox
        [System.Windows.Forms.TextBox]$ADGroupNameTextBox           = New-TextBox @ADGroupNameTextBoxProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ReturnTextBox
        [System.Windows.Forms.TextBox]$ADGroupSIDTextBox            = New-TextBox @ADGroupSIDTextBoxProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ReturnTextBox
        [System.Windows.Forms.ComboBox]$ApplicationIDComboBox       = New-ComboBox @ApplicationIDComboBoxProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ReturnComboBox

        # EXECUTION - BUTTONS
        # Set the Default Button properties
        [System.Collections.Hashtable]$ADGroupDefaultButton = @{
            ColumnNumber    = 7
            Text            = 'Default'
            PNGFileName     = 'arrow_undo'
            SizeType        = 'Small'
            ToolTip         = 'Set the Active Directory group and SID to their default values.'
            Function        = {
                Reset-TextBox -TextBox $ADGroupNameTextBox
                Reset-TextBox -TextBox $ADGroupSIDTextBox -Force
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
                [System.Object]$SelectedTemplate = Get-ActiveCustomerTemplate
                New-AppLockerFile -FolderToScan $InstallationFolderTextBox.Text -ADGroupSID $ADGroupSIDTextBox.Text -ApplicationID $ApplicationIDComboBox.Text -SelectedTemplate $SelectedTemplate -OpenOutputFolder
            }.GetNewClosure()
        }
        # Create the Buttons
        New-Button @ADGroupDefaultButton -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -RowNumber 3
        New-Button @CreateButton -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -RowNumber 5
        
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

