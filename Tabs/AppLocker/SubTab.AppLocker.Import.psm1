####################################################################################################
<#
.SYNOPSIS
    Imports the Import sub-tab into the AppLocker tab.
.DESCRIPTION
    This function imports the Import sub-tab into the AppLocker tab by creating a new TabPage and adding it to the specified parent TabControl.
.EXAMPLE
    Import-SubTabAppLockerImport -InputObject $InputObject -ParentTabControl $MySubTabControl
.INPUTS
    [PSCustomObject]
    [System.Windows.Forms.TabControl]
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. All rights reserved.
    Version         : 6.0.0.0
    Author          : Imraan Iotana
    Creation Date   : August 2025
    Last Update     : June 2026
#>
####################################################################################################
function Import-SubTabAppLockerImport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The ApplicationObject containing the Settings.')]
        [PSCustomObject]$InputObject,

        [Parameter(Mandatory=$true,HelpMessage='The Parent TabControl to which this TabPage will be added.')]
        [System.Windows.Forms.TabControl]$ParentTabControl
    )

    try {
        # PREPARATION
        # Tab properties
        [System.Collections.Hashtable]$TabProperties = @{
            ParentTabControl    = $ParentTabControl
            Title               = 'APPLOCKER IMPORT'
            Version             = '6.0.0.0'
            BackGroundColor     = 'Blue'
        }

        # EXECUTION
        # Create the TabPage
        [System.Windows.Forms.TabPage]$ParentTabPage = New-TabPage @TabProperties

        # Import the Features
        $null = Import-FeatureAppLockerImport -InputObject $InputObject -ParentTabPage $ParentTabPage -Color 'GreenYellow'

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
    Imports the AppLocker Import feature into the AppLocker tab.
.DESCRIPTION
    This function imports the AppLocker Import feature into the AppLocker tab by creating a new GroupBox and adding it to the specified parent TabPage.
.EXAMPLE
    Import-FeatureAppLockerImport -InputObject $MyApplicationObject -ParentTabPage $MyTabPage
.INPUTS
    [PSCustomObject]
    [System.Windows.Forms.TabPage]
    [System.Windows.Forms.GroupBox]
    [System.String]
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
function Import-FeatureAppLockerImport {
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
            Title           = 'APPLICATION IMPORT'
            Color           = $Color
            NumberOfRows    = 6
            GroupBoxAbove   = $GroupBoxAbove
        }
        # Create the GroupBox
        [System.Windows.Forms.GroupBox]$FeatureGroupBox = New-GroupBox @FeatureProperties -OnSubTab

        # EXECUTION - SUBKEY
        # Create a unique SubKey for the TextBoxes and ComboBoxes
        [System.String]$SubKeyForBoxes = New-SubKeyForBoxes -ParentTabPage $ParentTabPage -PassThru

        # EXECUTION - TEXTBOXES
        # Set the InstallationFolderTextBox properties
        [System.Collections.Hashtable]$InstallationFolderTextBoxProperties = @{
            RowNumber       = 1
            Label           = 'Select File'
            PropertyName    = "TextBoxes.$SubKeyForBoxes.FilePath"
            ToolTip         = 'The file to create AppLocker policies for.'
            SizeType        = 'Medium'
            SmallButtons    = @(@(5,'Browse File'),@(6,'Paste'),@(7,'Open'))
        }
        # Set the ApplicationIDComboBox properties
        [System.Collections.Hashtable]$ApplicationIDComboBoxProperties = @{
            RowNumber           = 2
            Label               = 'Application ID'
            PropertyName        = "ComboBoxes.$SubKeyForBoxes.ApplicationID"
            ToolTip             = 'The Application ID for the AppLocker policies.'
            SizeType            = 'Medium'
            ContentStringArray  = Get-DSLDirectSubFolderNames
            SmallButtons        = @(@(5,'Copy'),@(6,'Paste'),@(7,'Clear'))
        }
        # Keep this list aligned with Import-FeatureAppLockerSettings and AppLockerDefaultSettings.
        [System.String[]]$AppLockerEnvironments = @('Development','Test','Acceptance','Production')
        # Set the ApplockerEnvironmentComboBox properties
        [System.Collections.Hashtable]$ApplockerEnvironmentComboBoxProperties = @{
            RowNumber       = 3
            Label           = 'Environment'
            PropertyName    = "ComboBoxes.$SubKeyForBoxes.ApplockerEnvironment"
            ToolTip         = 'The environment for the AppLocker policies.'
            DefaultValue    = 'Development'
            SizeType        = 'Medium'
            ContentStringArray = $AppLockerEnvironments
            SmallButtons    = @(@(5,'Copy'),@(6,'Paste'))
        }
        # Create the ComboBoxes
        $Global:Graphics.ComboBoxes[$SubKeyForBoxes].ApplicationID  = New-ComboBox @ApplicationIDComboBoxProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ReturnComboBox
        $Global:Graphics.ComboBoxes[$SubKeyForBoxes].ApplockerEnvironment = New-ComboBox @ApplockerEnvironmentComboBoxProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ReturnComboBox
        # Create the TextBoxes
        $Global:Graphics.TextBoxes[$SubKeyForBoxes].FilePath        = New-TextBox @InstallationFolderTextBoxProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ReturnTextBox


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
                # Plaeceholder
                Write-Line "[INFO] Create AppLocker Files button clicked. Functionality not yet implemented."
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

