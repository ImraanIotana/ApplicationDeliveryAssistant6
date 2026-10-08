####################################################################################################
<#
.SYNOPSIS
    Imports the Shortcut Export feature into the Other sub-tab.
.DESCRIPTION
    This function imports the Shortcut Export feature into the Other sub-tab by creating a new GroupBox and adding it to the specified parent TabPage.
    The ComboBox setup follows the 6.0.0.3 graphics pattern where New-ComboBox handles
    PropertyName generation and flattened graphics registration directly.
.EXAMPLE
    Import-FeatureShortcutExport -InputObject $MyApplicationObject -ParentTabPage $MyTabPage
.INPUTS
    [PSCustomObject]
    [System.Windows.Forms.TabPage]
    [System.Windows.Forms.GroupBox]
    [System.String]
.OUTPUTS
    [System.Windows.Forms.GroupBox]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.3.3
    Author          : Imraan Iotana
    Creation Date   : June 2026
    Last Update     : July 2026
#>
####################################################################################################
function Import-FeatureShortcutExport {
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
            Title           = 'SHORTCUT EXPORT'
            Color           = $Color
            NumberOfRows    = 2
            GroupBoxAbove   = $GroupBoxAbove
        }

        # EXECUTION - GROUPBOX
        # Create the GroupBox
        [System.Windows.Forms.GroupBox]$FeatureGroupBox = New-GroupBox @GroupBoxProperties

        # PREPARATION - COMBOBOX PROPERTIES
        # Set the ComboBox properties
        [System.Collections.Hashtable]$ApplicationShortcutsComboBoxProperties = @{
            RowNumber                   = 1
            Label                       = 'Select Shortcut / Folder'
            ToolTip                     = 'The shortcut or shortcut folder to export.'
            SizeType                    = 'Medium'
            Shortcuts                   = Get-Shortcuts -IncludeInternetShortcuts
        }

        # EXECUTION - COMBOBOX
        # Create the ComboBox
        [System.Windows.Forms.ComboBox]$ExportShortcutComboBox = New-ComboBox @ApplicationShortcutsComboBoxProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ReturnComboBox

        # EXECUTION - BUTTONS
        # Set the Small Buttons properties
        [System.Collections.Hashtable[]]$SmallButtonsPropertiesArray = @(
            @{
                ColumnNumber    = 5
                Text            = 'Details'
                PNGFileName     = 'information'
                SizeType        = 'Small'
                ToolTip         = 'View details of the selected shortcut or folder.'
                Function        = { Write-ShortcutInformationToHost -Path $ExportShortcutComboBox.SelectedItem.FullPath }.GetNewClosure()
            }
            @{
                ColumnNumber    = 6
                Text            = 'Open Folder'
                PNGFileName     = 'folder_go'
                SizeType        = 'Small'
                ToolTip         = 'Open the folder containing the selected shortcut.'
                Function        = { Open-Folder -Path $ExportShortcutComboBox.SelectedItem.FullPath }.GetNewClosure()
            }
            @{
                ColumnNumber    = 7
                Text            = 'Refresh'
                PNGFileName     = 'arrow_refresh'
                SizeType        = 'Small'
                ToolTip         = 'Refresh the list of shortcuts.'
                Function        = { Update-ComboBox -ComboBox $ExportShortcutComboBox -Shortcuts (Get-Shortcuts -IncludeInternetShortcuts) }.GetNewClosure()
            }
        )
        # Set the Action Buttons properties
        [System.Collections.Hashtable[]]$ActionButtonsPropertiesArray = @(
            @{
                ColumnNumber    = 1
                Text            = 'Export'
                PNGFileName     = 'table_export'
                SizeType        = 'Medium'
                ToolTip         = 'Export the selected shortcut to a text file.'
                Function        = { Export-ShortcutInformation -ShortcutItem $ExportShortcutComboBox.SelectedItem -OpenOutputFolder }.GetNewClosure()
            }
        )
        # Create the Buttons
        New-ButtonLine -InputObject $InputObject -ButtonPropertiesArray $SmallButtonsPropertiesArray -ParentGroupBox $FeatureGroupBox -RowNumber 1
        New-ButtonLine -InputObject $InputObject -ButtonPropertiesArray $ActionButtonsPropertiesArray -ParentGroupBox $FeatureGroupBox -RowNumber 2

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