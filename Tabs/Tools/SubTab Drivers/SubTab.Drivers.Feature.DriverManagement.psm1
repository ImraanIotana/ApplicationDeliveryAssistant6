####################################################################################################
<#
.SYNOPSIS
    Imports the Driver Management feature into the Drivers tab.
.DESCRIPTION
    This function creates the Driver Management GroupBox and adds it to the specified Drivers TabPage.
.EXAMPLE
    Import-FeatureDriverManagement -InputObject $MyApplicationObject -ParentTabPage $MyTabPage
.INPUTS
    [PSCustomObject]
    [System.Windows.Forms.TabPage]
.OUTPUTS
    [System.Windows.Forms.GroupBox]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.3.4
    Author          : Imraan Iotana
    Creation Date   : August 2026
    Last Update     : August 2026
#>
####################################################################################################
function Import-FeatureDriverManagement {
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
            Title           = 'DRIVER MANAGEMENT'
            Color           = $Color
            NumberOfRows    = 12.5
            GroupBoxAbove   = $GroupBoxAbove
        }

        # EXECUTION - GROUPBOX
        # Create the GroupBox
        [System.Windows.Forms.GroupBox]$FeatureGroupBox = New-GroupBox @GroupBoxProperties

        # PREPARATION - TEXTBOX PROPERTIES
        # Set the driver search TextBox properties
        [System.Collections.Hashtable]$SearchTermTextBoxProperties = @{
            RowNumber       = 1
            Label           = 'Search Drivers'
            PropertyName    = 'DriverSearchFilter'
            ToolTip         = 'Enter text to search the driver inventory.'
            SizeType        = 'Medium'
            SmallButtons    = @(@(5,'Copy'),@(6,'Paste'),@(7,'Clear'))
        }

        # PREPARATION - LISTVIEW PROPERTIES
        # Set the driver results ListView properties
        [PSCustomObject[]]$DriverListViewColumnSchema = @(Get-DriverListViewColumnSchema)
        [System.Collections.Hashtable]$DriverResultsListViewProperties = @{
            RowNumber          = 4
            Label              = 'Driver Results'
            SizeType           = 'Large'
            VisibleRowCount    = 13
            View               = 'Details'
            Columns            = @($DriverListViewColumnSchema.Label)
            ColumnAutoSizeMode = 'Widest'
            ToolTip            = 'Driver inventory results will be listed here.'
            GridLines          = $true
            FullRowSelect      = $true
        }

        # EXECUTION - LISTVIEW
        # Create the driver results ListView
        [System.Windows.Forms.ListView]$DriverResultsListView = New-ListView @DriverResultsListViewProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ReturnListView
        Enable-DriverListViewSorting -ListView $DriverResultsListView

        # EXECUTION - TEXTBOX
        # Wire Enter to the shared search path after the results ListView exists, then create the TextBox.
        $SearchTermTextBoxProperties.EnterAction = ({
            param($TextBox)
            Invoke-DriverSearchResultsRefresh -ListView $DriverResultsListView -SearchTerm $TextBox.Text
        }.GetNewClosure())
        [System.Windows.Forms.TextBox]$SearchTermTextBox = New-TextBox @SearchTermTextBoxProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ReturnTextBox

        # PREPARATION - BUTTON PROPERTIES
        # Set the currently available action button properties
        [System.Collections.Hashtable[]]$ActionButtons = @(
            @{
                ColumnNumber    = 1
                Text            = 'Search'
                PNGFileName     = 'find'
                SizeType        = 'Medium'
                ToolTip         = 'Search the driver inventory with the search term.'
                Function        = {
                    Invoke-DriverSearchResultsRefresh -ListView $DriverResultsListView -SearchTerm $SearchTermTextBox.Text
                }.GetNewClosure()
            },
            @{
                ColumnNumber    = 3
                Text            = 'Show Recent'
                PNGFileName     = 'clock_go'
                SizeType        = 'Medium'
                ToolTip         = 'Show drivers whose Driver Store folders were created during the last seven days.'
                Function        = {
                    Invoke-DriverSearchResultsRefresh -ListView $DriverResultsListView -Recent
                }.GetNewClosure()
            },
            @{
                ColumnNumber    = 4
                Text            = 'Show All'
                PNGFileName     = 'folders'
                SizeType        = 'Medium'
                ToolTip         = 'Show all drivers in the inventory.'
                Function        = {
                    Clear-TextBox -TextBox $SearchTermTextBox -Force
                    Invoke-DriverSearchResultsRefresh -ListView $DriverResultsListView -RefreshCache
                }.GetNewClosure()
            },
            @{
                ColumnNumber    = 5
                Text            = 'Clear All'
                PNGFileName     = 'textfield_delete'
                SizeType        = 'Medium'
                ToolTip         = 'Clear the driver search term and results.'
                Function        = {
                    Clear-TextBox -TextBox $SearchTermTextBox -Force
                    Invoke-ListViewBatchUpdate -ListView $DriverResultsListView -Action {
                        $DriverResultsListView.Items.Clear()
                    }
                }.GetNewClosure()
            }
        )
        # Set the driver action button properties
        [System.Collections.Hashtable[]]$DriverActionButtons = @(
            @{
                ColumnNumber    = 1
                Text            = 'Show Details (Quick)'
                PNGFileName     = 'information'
                SizeType        = 'Large'
                ToolTip         = 'Show cached package information for the selected driver without querying hardware devices.'
                Function        = {
                    Write-SelectedDriverDetailsToHost -ListView $DriverResultsListView -Quick
                }.GetNewClosure()
            },
            @{
                ColumnNumber    = 2
                Text            = 'Show Details (Full)'
                PNGFileName     = 'information'
                SizeType        = 'Large'
                ToolTip         = 'Show detailed information for the selected driver.'
                Function        = {
                    Write-SelectedDriverDetailsToHost -ListView $DriverResultsListView
                }.GetNewClosure()
            },
            @{
                ColumnNumber    = 3
                Text            = 'Open Driver Folder'
                PNGFileName     = 'folder_go'
                SizeType        = 'Large'
                ToolTip         = 'Open the folder for the selected driver.'
                Function        = {
                    Open-SelectedDriverStoreFolder -ListView $DriverResultsListView
                }.GetNewClosure()
            },
            @{
                ColumnNumber    = 4
                Text            = 'Export Driver Package'
                PNGFileName     = 'table_export'
                SizeType        = 'Large'
                ToolTip         = 'Export the selected driver files and administrative information to the configured output folder.'
                Function        = {
                    Export-SelectedDriverPackage -ListView $DriverResultsListView -OpenOutputFolder
                }.GetNewClosure()
            },
            @{
                ColumnNumber    = 5
                Text            = 'Remove Driver'
                PNGFileName     = 'package_delete'
                SizeType        = 'Large'
                ToolTip         = 'Remove the selected driver package from the Windows Driver Store and matching devices.'
                Function        = {
                    Remove-SelectedDriverPackage -ListView $DriverResultsListView -SearchTerm $SearchTermTextBox.Text
                }.GetNewClosure()
            }
        )

        # EXECUTION - BUTTONS
        # Create the search and driver action button rows
        New-ButtonLine -InputObject $InputObject -ButtonPropertiesArray $ActionButtons -ParentGroupBox $FeatureGroupBox -RowNumber 2
        New-ButtonLine -InputObject $InputObject -ButtonPropertiesArray $DriverActionButtons -ParentGroupBox $FeatureGroupBox -RowNumber 15

        # POST-EXECUTION
        # Expose the controls for later inventory and filter wiring, then return the GroupBox
        $FeatureGroupBox | Add-Member -NotePropertyName 'SearchTermTextBox' -NotePropertyValue $SearchTermTextBox -Force
        $FeatureGroupBox | Add-Member -NotePropertyName 'DriverResultsListView' -NotePropertyValue $DriverResultsListView -Force
        $FeatureGroupBox
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}

### END OF FUNCTION
####################################################################################################