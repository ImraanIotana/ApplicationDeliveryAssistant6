####################################################################################################
<#
.SYNOPSIS
    Imports the Application Selection feature into the Desktop Application sub-tab.
.DESCRIPTION
    This function creates the Application Selection GroupBox, populates the installed-application ComboBox from the registry, and adds the import, refresh, clear, details, registry, and export actions.
.EXAMPLE
    Import-FeatureIntakeApplicationSelection -InputObject $MyApplicationObject -ParentTabPage $MyTabPage
.INPUTS
    [PSCustomObject]
    [System.Windows.Forms.TabPage]
    [System.Windows.Forms.GroupBox]
    [System.String]
.OUTPUTS
    [System.Windows.Forms.GroupBox]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.3.0
    Author          : Imraan Iotana
    Creation Date   : May 2026
    Last Update     : August 2026
#>
####################################################################################################
function Import-FeatureIntakeApplicationSelection {
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
        # Set the GroupBox properties.
        [System.Collections.Hashtable]$GroupBoxProperties = @{
            InputObject   = $InputObject
            ParentTabPage = $ParentTabPage
            Title         = 'APPLICATION SELECTION'
            Color         = $Color
            NumberOfRows  = 2
            GroupBoxAbove = $GroupBoxAbove
        }

        # EXECUTION - GROUPBOX
        # Create the GroupBox that contains the application-selection controls.
        [System.Windows.Forms.GroupBox]$FeatureGroupBox = New-GroupBox @GroupBoxProperties

        # PREPARATION - COMBOBOX PROPERTIES
        # Set the installed-application ComboBox properties.
        [System.Collections.Hashtable]$InstalledApplicationsComboBoxProperties = @{
            RowNumber                = 1
            Label                    = 'Import from Registry'
            ToolTip                  = 'The list of installed applications to select from and import into the intake form.'
            SizeType                 = 'Medium'
            ApplicationsFromRegistry = Get-InstalledApplicationsFromRegistry
        }

        # EXECUTION - COMBOBOX
        # Create and retain the ComboBox for use by the feature actions.
        [System.Windows.Forms.ComboBox]$InstalledApplicationsComboBox = New-ComboBox @InstalledApplicationsComboBoxProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ReturnComboBox

        # PREPARATION - BUTTON PROPERTIES
        # Set the import, refresh, and clear button properties.
        [System.Collections.Hashtable[]]$ImportButtonPropertiesArray = @(
            @{
                ColumnNumber = 1
                Text         = 'Import'
                PNGFileName  = 'download_for_windows'
                SizeType     = 'Medium'
                ToolTip      = 'Import the selected application from the registry.'
                Function     = { Import-SelectedApplicationToIntakeTextBoxes -SelectedApplication $InstalledApplicationsComboBox.SelectedItem }.GetNewClosure()
            }
            @{
                ColumnNumber = 5
                Text         = 'Refresh'
                PNGFileName  = 'arrow_refresh'
                SizeType     = 'Small'
                ToolTip      = 'Refresh the list of applications from the registry.'
                Function     = {
                    Update-ComboBox -ComboBox $InstalledApplicationsComboBox -ApplicationsFromRegistry (Get-InstalledApplicationsFromRegistry)
                    [System.Windows.Forms.ComboBox]$ShortcutsComboBox = Get-ComboBoxObject -ComboBoxName 'SelectShortcutFolder'
                    if ($null -ne $ShortcutsComboBox) {
                        Update-ComboBox -ComboBox $ShortcutsComboBox -Shortcuts (Get-Shortcuts -IncludeInternetShortcuts)
                    }
                }.GetNewClosure()
            }
            @{
                ColumnNumber = 7
                Text         = 'Clear All Fields'
                PNGFileName  = 'textfield_delete'
                SizeType     = 'Small'
                ToolTip      = 'Clear all fields.'
                Function     = {
                    if (-not (Get-UserConfirmation -Title 'Clear All Fields' -Body "This will CLEAR ALL fields in the intake form.`n`nAre you sure you want to continue?")) { return }
                    Clear-IntakeFormFields
                }.GetNewClosure()
            }
        )

        # Set the details, registry, and export button properties.
        [System.Collections.Hashtable[]]$SmallButtonsPropertiesArray = @(
            @{
                ColumnNumber = 5
                Text         = 'Details'
                PNGFileName  = 'information'
                SizeType     = 'Small'
                ToolTip      = 'View details of the selected application.'
                Function     = { $InstalledApplicationsComboBox.SelectedItem | Format-List | Out-String | Write-Host }.GetNewClosure()
            }
            @{
                ColumnNumber = 6
                Text         = 'Show'
                PNGFileName  = 'regedit'
                SizeType     = 'Small'
                ToolTip      = 'Open the registry editor at the selected application registry path.'
                Function     = { Start-RegistryEditor -Key $InstalledApplicationsComboBox.SelectedItem.RegistryPath }.GetNewClosure()
            }
            @{
                ColumnNumber = 7
                Text         = 'Export'
                PNGFileName  = 'table_export'
                SizeType     = 'Small'
                ToolTip      = 'Export the selected application to a text file.'
                Function     = { Export-RegistryKey -RegistryKeyPath $InstalledApplicationsComboBox.SelectedItem.RegistryPath -OpenOutputFolder }.GetNewClosure()
            }
        )

        # EXECUTION - BUTTONS
        # Create both button rows in the Application Selection GroupBox.
        New-ButtonLine -InputObject $InputObject -ButtonPropertiesArray $SmallButtonsPropertiesArray -ParentGroupBox $FeatureGroupBox -RowNumber 1
        New-ButtonLine -InputObject $InputObject -ButtonPropertiesArray $ImportButtonPropertiesArray -ParentGroupBox $FeatureGroupBox -RowNumber 2

        # POST-EXECUTION
        # Return the GroupBox so the next feature can be positioned underneath it.
        return $FeatureGroupBox
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}

### END OF FUNCTION
####################################################################################################
