####################################################################################################
<#
.SYNOPSIS
    Imports the Application Shortcuts feature into the Desktop Application sub-tab.
.DESCRIPTION
    This function imports the Application Shortcuts feature into the Desktop Application sub-tab by creating a new GroupBox and adding it to the specified parent TabPage.
    The shortcuts ComboBox is auto-registered and persisted through label-based metadata in New-ComboBox.
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
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.2.2
    Author          : Imraan Iotana
    Creation Date   : May 2026
    Last Update     : August 2026
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
            Title           = 'APPLICATION SHORTCUTS'
            Color           = $Color
            NumberOfRows    = 1
            GroupBoxAbove   = $GroupBoxAbove
        }

        # EXECUTION - GROUPBOX
        # Create the GroupBox
        [System.Windows.Forms.GroupBox]$FeatureGroupBox = New-GroupBox @GroupBoxProperties

        # EXECUTION - COMBOBOXES
        # Set the ComboBox properties
        [System.Collections.Hashtable]$ApplicationShortcutsComboBoxProperties = @{
            RowNumber                   = 1
            Label                       = 'Select Shortcut / Folder'
            ToolTip                     = 'The shortcut or shortcut folder of the application.'
            SizeType                    = 'Medium'
            Shortcuts                   = Get-Shortcuts -IncludeInternetShortcuts
        }
        # Create the ComboBox
        [System.Windows.Forms.ComboBox]$ApplicationShortcutsComboBox = New-ComboBox @ApplicationShortcutsComboBoxProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ReturnComboBox

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
        # Create the Buttons
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

