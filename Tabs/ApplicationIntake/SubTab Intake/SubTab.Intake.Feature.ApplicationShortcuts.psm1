####################################################################################################
<#
.SYNOPSIS
    Imports the Application Shortcuts feature into the Intake sub-tab.
.DESCRIPTION
    This function imports the Application Shortcuts feature into the Intake sub-tab by creating a new GroupBox and adding it to the specified parent TabPage.
    It stores the shortcuts combobox in the flattened graphics key structure resolved by New-SubKeyForBoxes.
.EXAMPLE
    Import-FeatureIntakeApplicationShortcuts -InputObject $MyApplicationObject -ParentTabPage $MyTabPage
.INPUTS
    [PSCustomObject]
    [System.Windows.Forms.TabPage]
    [System.Windows.Forms.GroupBox]
    [System.String]
.OUTPUTS
    [System.Windows.Forms.GroupBox]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. All rights reserved.
    Version         : 6.0.0.0
    Author          : Imraan Iotana
    Creation Date   : May 2026
    Last Update     : June 2026
#>
####################################################################################################
function Import-FeatureIntakeApplicationShortcuts {
    [CmdletBinding()]
    [OutputType([System.Windows.Forms.GroupBox])]
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
            Title           = 'APPLICATION SHORTCUTS'
            Color           = $Color
            NumberOfRows    = 1
            GroupBoxAbove   = $GroupBoxAbove
        }
        # Create the GroupBox
        [System.Windows.Forms.GroupBox]$FeatureGroupBox = New-GroupBox @FeatureProperties -OnSubTab

        # PREPARATION - COMBOBOXES
        # Derive the subkeys for the TextBoxes and ComboBoxes from the current tab
        [System.String]$SubKeyForBoxes = New-SubKeyForBoxes -ParentTabPage $ParentTabPage -PassThru

        # Build the ComboBox property path used by New-ComboBox
        [System.String]$ApplicationShortcutsPropertyName = "ComboBoxes.$SubKeyForBoxes.ApplicationShortcuts"

        # EXECUTION - COMBOBOXES
        # Set the ComboBox properties
        [System.Collections.Hashtable]$ApplicationShortcutsComboBoxProperties = @{
            RowNumber                   = 1
            Label                       = 'Select Shortcut / Folder'
            PropertyName                = $ApplicationShortcutsPropertyName
            ToolTip                     = 'The shortcut or shortcut folder of the application.'
            SizeType                    = 'Medium'
            Shortcuts                   = Get-Shortcuts -IncludeInternetShortcuts
        }
        # Create the ComboBox
        [System.Windows.Forms.ComboBox]$ApplicationShortcutsComboBox = New-ComboBox @ApplicationShortcutsComboBoxProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ReturnComboBox
        $Global:Graphics.ComboBoxes[$SubKeyForBoxes].ApplicationShortcuts = $ApplicationShortcutsComboBox

        # EXECUTION - BUTTONS
        # Set the Small Buttons properties
        [System.Collections.Hashtable[]]$SmallButtonsPropertiesArray = @(
            @{
                ColumnNumber    = 5
                Text            = 'Details'
                PNGFileName     = 'information'
                SizeType        = 'Small'
                ToolTip         = 'View details of the selected shortcut or folder.'
                Function        = { Write-ShortcutInformationToHost -Path $ApplicationShortcutsComboBox.SelectedItem.FullPath }.GetNewClosure()
            }
            @{
                ColumnNumber    = 6
                Text            = 'Open Folder'
                PNGFileName     = 'folder_go'
                SizeType        = 'Small'
                ToolTip         = 'Open the folder containing the selected shortcut.'
                Function        = { Open-Folder -Path $ApplicationShortcutsComboBox.SelectedItem.FullPath }.GetNewClosure()
            }
            @{
                ColumnNumber    = 7
                Text            = 'Export'
                PNGFileName     = 'table_export'
                SizeType        = 'Small'
                ToolTip         = 'Export the selected shortcut to a text file.'
                Function        = { Export-ShortcutInformation -ShortcutItem $ApplicationShortcutsComboBox.SelectedItem -OpenOutputFolder }.GetNewClosure()
            }
        )
        # Add the Buttons
        New-ButtonLine -InputObject $InputObject -ButtonPropertiesArray $SmallButtonsPropertiesArray -ParentGroupBox $FeatureGroupBox -RowNumber 1

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

