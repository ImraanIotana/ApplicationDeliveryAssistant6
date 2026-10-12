####################################################################################################
<#
.SYNOPSIS
    Imports the Service Management feature into the Services sub-tab.
.DESCRIPTION
    This function creates the Service Management GroupBox and adds it to the specified Services TabPage.
    The search, filter, result and service action controls are functional.
.EXAMPLE
    Import-FeatureServiceManagement -InputObject $MyApplicationObject -ParentTabPage $MyTabPage
.INPUTS
    [PSCustomObject]
    [System.Windows.Forms.TabPage]
.OUTPUTS
    [System.Windows.Forms.GroupBox]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.10.0
    Author          : Imraan Iotana
    Creation Date   : October 2026
    Last Update     : October 2026
#>
####################################################################################################
function Import-FeatureServiceManagement {
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
            Title           = 'SERVICE MANAGEMENT'
            Color           = $Color
            NumberOfRows    = 12.5
            GroupBoxAbove   = $GroupBoxAbove
        }

        # EXECUTION - GROUPBOX
        # Create the GroupBox
        [System.Windows.Forms.GroupBox]$FeatureGroupBox = New-GroupBox @GroupBoxProperties

        # EXECUTION - COMBOBOXES
        # Create the filter ComboBoxes. They have no PropertyName, so their values are not stored. The first item is selected as the default.
        [System.Windows.Forms.ComboBox]$StatusComboBox = New-ComboBox -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -RowNumber 3 -SizeType 'Medium' -Label 'Filter Status' -ToolTip 'Show only the services with this status.' -ContentStringArray @('All','Running','Stopped','Paused') -ReturnComboBox
        [System.Windows.Forms.ComboBox]$StartupTypeComboBox = New-ComboBox -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -RowNumber 4 -SizeType 'Medium' -Label 'Filter Startup Type' -ToolTip 'Show only the services with this startup type.' -ContentStringArray @('All','Automatic','Automatic (Delayed Start)','Manual','Disabled') -ReturnComboBox
        [System.Windows.Forms.ComboBox]$OriginComboBox = New-ComboBox -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -RowNumber 5 -SizeType 'Medium' -Label 'Filter Origin' -ToolTip 'Show all services, or only the services of Microsoft or of other companies. The company name of the service executable determines the origin.' -ContentStringArray @('All services','Non-Microsoft only','Microsoft only') -ReturnComboBox
        $StatusComboBox.SelectedIndex = 0
        $StartupTypeComboBox.SelectedIndex = 0
        $OriginComboBox.SelectedIndex = 0

        # EXECUTION - LISTVIEW
        # Create the service results ListView
        [PSCustomObject[]]$ServiceListViewColumnSchema = @(Get-ServiceListViewColumnSchema)
        [System.Collections.Hashtable]$ServiceResultsListViewProperties = @{
            RowNumber          = 6
            Label              = 'Service Results'
            SizeType           = 'Large'
            VisibleRowCount    = 10
            View               = 'Details'
            Columns            = @($ServiceListViewColumnSchema.Label)
            ColumnAutoSizeMode = 'Widest'
            ToolTip            = 'Service results will be listed here.'
            GridLines          = $true
            FullRowSelect      = $true
        }
        [System.Windows.Forms.ListView]$ServiceResultsListView = New-ListView @ServiceResultsListViewProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ReturnListView
        Enable-ServiceListViewSorting -ListView $ServiceResultsListView

        # EXECUTION - TEXTBOX
        # Wire Enter to the shared search path after the results ListView and the filters exist, then create the TextBox.
        [System.Collections.Hashtable]$FilterState = @{ IsResetting = $false }
        [System.Collections.Hashtable]$SearchTermTextBoxProperties = @{
            RowNumber       = 1
            Label           = 'Search Services'
            PropertyName    = 'ServiceSearchFilter'
            ToolTip         = 'Enter text to search the services by name, display name, description, account or path.'
            SizeType        = 'Medium'
            SmallButtons    = @(@(5,'Copy'),@(6,'Paste'),@(7,'Clear'))
            EnterAction     = ({
                param($TextBox)
                Invoke-ServiceSearchResultsRefresh -ListView $ServiceResultsListView -SearchTerm $TextBox.Text -Status $StatusComboBox.Text -StartupType $StartupTypeComboBox.Text -Origin $OriginComboBox.Text
            }.GetNewClosure())
        }
        [System.Windows.Forms.TextBox]$SearchTermTextBox = New-TextBox @SearchTermTextBoxProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ReturnTextBox

        # EXECUTION - FILTER EVENTS
        # Refresh the results when a filter changes, unless the filters are being reset by a button
        [System.EventHandler]$FilterChangedHandler = {
            if (-not $FilterState.IsResetting) {
                Invoke-ServiceSearchResultsRefresh -ListView $ServiceResultsListView -SearchTerm $SearchTermTextBox.Text -Status $StatusComboBox.Text -StartupType $StartupTypeComboBox.Text -Origin $OriginComboBox.Text
            }
        }.GetNewClosure()
        $StatusComboBox.Add_SelectedIndexChanged($FilterChangedHandler)
        $StartupTypeComboBox.Add_SelectedIndexChanged($FilterChangedHandler)
        $OriginComboBox.Add_SelectedIndexChanged($FilterChangedHandler)
        # The function that resets the three filters to their default values without refreshing the results
        [System.Management.Automation.ScriptBlock]$ResetFilters = {
            $FilterState.IsResetting = $true
            try {
                $StatusComboBox.SelectedIndex = 0
                $StartupTypeComboBox.SelectedIndex = 0
                $OriginComboBox.SelectedIndex = 0
            }
            finally {
                $FilterState.IsResetting = $false
            }
        }.GetNewClosure()

        # PREPARATION - BUTTON PROPERTIES
        # Set the search button properties
        [System.Collections.Hashtable[]]$SearchButtons = @(
            @{
                ColumnNumber    = 1
                Text            = 'Search'
                PNGFileName     = 'find'
                SizeType        = 'Medium'
                ToolTip         = 'Search the services with the search term and the selected filters.'
                Function        = {
                    Invoke-ServiceSearchResultsRefresh -ListView $ServiceResultsListView -SearchTerm $SearchTermTextBox.Text -Status $StatusComboBox.Text -StartupType $StartupTypeComboBox.Text -Origin $OriginComboBox.Text
                }.GetNewClosure()
            },
            @{
                ColumnNumber    = 3
                Text            = 'Show Recent'
                PNGFileName     = 'clock_go'
                SizeType        = 'Medium'
                ToolTip         = 'Show the services whose executable was created during the last seven days. The selected filters are applied, the search term is ignored.'
                Function        = {
                    Invoke-ServiceSearchResultsRefresh -ListView $ServiceResultsListView -Status $StatusComboBox.Text -StartupType $StartupTypeComboBox.Text -Origin $OriginComboBox.Text -Recent
                }.GetNewClosure()
            },
            @{
                ColumnNumber    = 4
                Text            = 'Show All'
                PNGFileName     = 'folders'
                SizeType        = 'Medium'
                ToolTip         = 'Clear the search term, reset the filters and show all services.'
                Function        = {
                    Clear-TextBox -TextBox $SearchTermTextBox -Force
                    & $ResetFilters
                    Invoke-ServiceSearchResultsRefresh -ListView $ServiceResultsListView -RefreshCache
                }.GetNewClosure()
            },
            @{
                ColumnNumber    = 5
                Text            = 'Clear All'
                PNGFileName     = 'textfield_delete'
                SizeType        = 'Medium'
                ToolTip         = 'Clear the service search term and results, and reset the filters.'
                Function        = {
                    Clear-TextBox -TextBox $SearchTermTextBox -Force
                    & $ResetFilters
                    Invoke-ListViewBatchUpdate -ListView $ServiceResultsListView -Action {
                        $ServiceResultsListView.Items.Clear()
                    }
                }.GetNewClosure()
            }
        )
        # Set the service action button properties
        [System.Collections.Hashtable[]]$ServiceActionButtons = @(
            @{
                ColumnNumber    = 1
                Text            = 'Show Details'
                PNGFileName     = 'information'
                SizeType        = 'Large'
                ToolTip         = 'Show the details of the selected service.'
                Function        = {
                    Write-SelectedServiceDetailsToHost -ListView $ServiceResultsListView
                }.GetNewClosure()
            },
            @{
                ColumnNumber    = 2
                Text            = 'Start Service'
                PNGFileName     = 'cog_go'
                SizeType        = 'Large'
                ToolTip         = 'Start the selected service. Windows will request administrator approval.'
                Function        = {
                    Invoke-SelectedServiceAction -ListView $ServiceResultsListView -Action Start
                }.GetNewClosure()
            },
            @{
                ColumnNumber    = 3
                Text            = 'Stop Service'
                PNGFileName     = 'shield_delete'
                SizeType        = 'Large'
                ToolTip         = 'Stop the selected service. Windows will request administrator approval.'
                Function        = {
                    Invoke-SelectedServiceAction -ListView $ServiceResultsListView -Action Stop
                }.GetNewClosure()
            },
            @{
                ColumnNumber    = 4
                Text            = 'Restart Service'
                PNGFileName     = 'arrow_refresh'
                SizeType        = 'Large'
                ToolTip         = 'Restart the selected service. Windows will request administrator approval.'
                Function        = {
                    Invoke-SelectedServiceAction -ListView $ServiceResultsListView -Action Restart
                }.GetNewClosure()
            },
            @{
                ColumnNumber    = 5
                Text            = 'Set Startup Type'
                PNGFileName     = 'cog'
                SizeType        = 'Large'
                ToolTip         = 'Change the startup type of the selected service. Windows will request administrator approval.'
                Function        = {
                    Invoke-SelectedServiceAction -ListView $ServiceResultsListView -Action SetStartupType
                }.GetNewClosure()
            }
        )

        # EXECUTION - BUTTONS
        # Create the search and service action button rows
        New-ButtonLine -InputObject $InputObject -ButtonPropertiesArray $SearchButtons -ParentGroupBox $FeatureGroupBox -RowNumber 2
        New-ButtonLine -InputObject $InputObject -ButtonPropertiesArray $ServiceActionButtons -ParentGroupBox $FeatureGroupBox -RowNumber 15

        # POST-EXECUTION
        # Expose the controls for later wiring, then return the GroupBox
        $FeatureGroupBox | Add-Member -NotePropertyName 'SearchTermTextBox' -NotePropertyValue $SearchTermTextBox -Force
        $FeatureGroupBox | Add-Member -NotePropertyName 'StatusComboBox' -NotePropertyValue $StatusComboBox -Force
        $FeatureGroupBox | Add-Member -NotePropertyName 'StartupTypeComboBox' -NotePropertyValue $StartupTypeComboBox -Force
        $FeatureGroupBox | Add-Member -NotePropertyName 'OriginComboBox' -NotePropertyValue $OriginComboBox -Force
        $FeatureGroupBox | Add-Member -NotePropertyName 'ServiceResultsListView' -NotePropertyValue $ServiceResultsListView -Force
        $FeatureGroupBox
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}

### END OF FUNCTION
####################################################################################################
