####################################################################################################
<#
.SYNOPSIS
    Imports the Search feature into the DSL Management tab.
.DESCRIPTION
    This function imports the Search feature into the DSL Management tab by creating a new GroupBox and adding a search TextBox.
.EXAMPLE
    Import-FeatureDSLManagementSearch -InputObject $MyApplicationObject -ParentTabPage $MyTabPage
.INPUTS
    [PSCustomObject]
    [System.Windows.Forms.TabPage]
    [System.Windows.Forms.GroupBox]
    [System.String]
.OUTPUTS
    [System.Windows.Forms.GroupBox]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.5.3
    Author          : Imraan Iotana
    Creation Date   : July 2026
    Last Update     : September 2026
#>
####################################################################################################
function Import-FeatureDSLManagementSearch {
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
            Title           = 'DSL SEARCH'
            Color           = $Color
            NumberOfRows    = 9
            GroupBoxAbove   = $GroupBoxAbove
        }

        # EXECUTION - GROUPBOX
        # Create the GroupBox
        [System.Windows.Forms.GroupBox]$FeatureGroupBox = New-GroupBox @GroupBoxProperties

        # PREPARATION - ARCHIVE GROUPBOX PROPERTIES
        # Set the Archive GroupBox properties
        [System.Collections.Hashtable]$ArchiveGroupBoxProperties = @{
            InputObject     = $InputObject
            ParentTabPage   = $ParentTabPage
            Title           = 'DSL ARCHIVE'
            Color           = $Color
            NumberOfRows    = 8
            GroupBoxAbove   = $FeatureGroupBox
        }

        # EXECUTION - ARCHIVE GROUPBOX
        # Create the Archive GroupBox
        [System.Windows.Forms.GroupBox]$ArchiveGroupBox = New-GroupBox @ArchiveGroupBoxProperties

        # PREPARATION - LISTVIEW PROPERTIES
        # Set the Search Results ListView properties
        [System.Collections.Hashtable]$SearchResultsListViewProperties = @{
            RowNumber       = 4
            Label           = 'DSL Results'
            SizeType        = 'Large'
            View            = 'Details'
            Columns         = @('#','Name','Path')
            ColumnAutoSizeMode = 'Widest'
            ToolTip         = 'Search results will be listed here.'
            GridLines       = $true
            FullRowSelect   = $true
            VisibleRowCount = 6
        }
        # Set the Archive Results ListView properties
        [System.Collections.Hashtable]$ArchiveResultsListViewProperties = @{
            RowNumber       = 2
            Label           = 'DSL Archive Results'
            SizeType        = 'Large'
            View            = 'Details'
            Columns         = @('#','Name','Path')
            ColumnAutoSizeMode = 'Widest'
            ToolTip         = 'Archive results will be listed here.'
            GridLines       = $true
            FullRowSelect   = $true
            VisibleRowCount = 6
        }

        # EXECUTION - LISTVIEW
        # Create the Search Results ListView
        [System.Windows.Forms.ListView]$SearchResultsListView = New-ListView @SearchResultsListViewProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ReturnListView
        # Create the Archive Results ListView
        [System.Windows.Forms.ListView]$ArchiveResultsListView = New-ListView @ArchiveResultsListViewProperties -InputObject $InputObject -ParentGroupBox $ArchiveGroupBox -ReturnListView

        # PREPARATION - ACTIVE LISTVIEW CONTEXT
        # Keep track of the last interacted listview so shared buttons target the intended list.
        [System.Collections.Hashtable]$SelectionContext = @{ ActiveListView = $SearchResultsListView }

        # EXECUTION - LISTVIEW EVENTS
        # Open the selected result when the user double-clicks a row.
        $SearchResultsListView.Add_DoubleClick({
            Start-SelectedApplicationAction -Action 'Open' -ListView $SearchResultsListView
        }.GetNewClosure())
        # Update active list context when the user interacts with the DSL results list.
        $SearchResultsListView.Add_MouseDown({ $SelectionContext.ActiveListView = $SearchResultsListView }.GetNewClosure())
        $SearchResultsListView.Add_Enter({ $SelectionContext.ActiveListView = $SearchResultsListView }.GetNewClosure())
        # Highlight the selected archive item when the user double-clicks a row.
        $ArchiveResultsListView.Add_DoubleClick({
            Start-SelectedApplicationAction -Action 'OpenAndHighlight' -ListView $ArchiveResultsListView
        }.GetNewClosure())
        # Update active list context when the user interacts with the archive results list.
        $ArchiveResultsListView.Add_MouseDown({ $SelectionContext.ActiveListView = $ArchiveResultsListView }.GetNewClosure())
        $ArchiveResultsListView.Add_Enter({ $SelectionContext.ActiveListView = $ArchiveResultsListView }.GetNewClosure())


        # PREPARATION - TEXTBOX PROPERTIES
        # Set the Search TextBox properties
        [System.Collections.Hashtable]$SearchTermTextBoxProperties = @{
            RowNumber       = 1
            Label           = 'Enter Searchterm'
            PropertyName    = 'DSLSearchFilter'
            ToolTip         = 'Enter text to search in DSL data.'
            SizeType        = 'Medium'
            SmallButtons    = @(@(5,'Copy'),@(6,'Paste'),@(7,'Clear'))
            EnterAction     = ({
                param($TextBox)
                Invoke-DSLSearchResultsRefresh -SearchResultsListView $SearchResultsListView -ArchiveResultsListView $ArchiveResultsListView -SearchTerm $TextBox.Text
            }.GetNewClosure())
        }

        # EXECUTION - TEXTBOX
        # Create the SearchTerm TextBox
        [System.Windows.Forms.TextBox]$SearchTermTextBox = New-TextBox @SearchTermTextBoxProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ReturnTextBox


        # PREPARATION - BUTTON PROPERTIES
        # Set the Action Buttons 1 properties
        [System.Collections.Hashtable[]]$ActionButtons1PropertiesArray = @(
            @{
                ColumnNumber    = 1
                Text            = 'Search'
                PNGFileName     = 'find'
                SizeType        = 'Medium'
                ToolTip         = 'Search the DSL folders with the searchterm.'
                Function        = {
                    Invoke-DSLSearchResultsRefresh -SearchResultsListView $SearchResultsListView -ArchiveResultsListView $ArchiveResultsListView -SearchTerm $SearchTermTextBox.Text
                }.GetNewClosure()
            }
            @{
                ColumnNumber    = 4
                Text            = 'Show All'
                PNGFileName     = 'folders'
                SizeType        = 'Medium'
                ToolTip         = 'Show all DSL folders and archive zip files.'
                Function        = {
                    Invoke-DSLSearchResultsRefresh -SearchResultsListView $SearchResultsListView -ArchiveResultsListView $ArchiveResultsListView
                }.GetNewClosure()
            }
            @{
                ColumnNumber    = 5
                Text            = 'Clear All'
                PNGFileName     = 'textfield_delete'
                SizeType        = 'Medium'
                ToolTip         = 'Clear the search term and search results.'
                Function        = {
                    Clear-TextBox -TextBox $SearchTermTextBox -Force
                    Clear-DSLSearchResultListViews -SearchResultsListView $SearchResultsListView -ArchiveResultsListView $ArchiveResultsListView
                    Write-Line 'Search term and results have been cleared.'
                }.GetNewClosure()
            }
        )
        # Set the Transfer Buttons properties
        [System.Collections.Hashtable[]]$TransferButtonsPropertiesArray = @(
            @{
                ColumnNumber    = 1
                Text            = 'Open Folder'
                PNGFileName     = 'folder_go'
                SizeType        = 'Large'
                ToolTip         = 'Open the selected DSL folder, or highlight the selected archive item in File Explorer.'
                Function        = {
                    Invoke-DSLSearchContextAction -Action 'Open' -SearchResultsListView $SearchResultsListView -ArchiveResultsListView $ArchiveResultsListView -SelectionContext $SelectionContext
                }.GetNewClosure()
            }
            @{
                ColumnNumber    = 2
                Text            = 'Show Info'
                PNGFileName     = 'information'
                SizeType        = 'Large'
                ToolTip         = 'Show information about the selected DSL folder.'
                Function        = {
                    Invoke-DSLSearchContextAction -Action 'ShowInfo' -SearchResultsListView $SearchResultsListView -ArchiveResultsListView $ArchiveResultsListView -SelectionContext $SelectionContext
                }.GetNewClosure()
            }
            @{
                ColumnNumber    = 3
                Text            = 'Documentation'
                PNGFileName     = 'page_word'
                SizeType        = 'Large'
                ToolTip         = 'Open existing documentation, or prepare document generation for the selected DSL folder.'
                Function        = {
                    Invoke-DSLSearchContextAction -Action 'OpenOrGenerateDocumentation' -SearchResultsListView $SearchResultsListView -ArchiveResultsListView $ArchiveResultsListView -SelectionContext $SelectionContext
                }.GetNewClosure()
            }
            @{
                ColumnNumber    = 4
                Text            = 'Open Log'
                PNGFileName     = 'file_extension_log'
                SizeType        = 'Large'
                ToolTip         = 'Show the application log for the selected DSL folder.'
                Function        = {
                    Invoke-DSLSearchContextAction -Action 'ShowLog' -SearchResultsListView $SearchResultsListView -ArchiveResultsListView $ArchiveResultsListView -SelectionContext $SelectionContext
                }.GetNewClosure()
            }
            @{
                ColumnNumber    = 5
                Text            = 'Archive'
                PNGFileName     = 'arrow_down'
                SizeType        = 'Large'
                ToolTip         = 'Compress the selected DSL folder to the archive location.'
                Function        = {
                    Invoke-DSLArchiveOperation -Action 'Archive' -SearchResultsListView $SearchResultsListView -ArchiveResultsListView $ArchiveResultsListView -SearchTerm $SearchTermTextBox.Text
                }.GetNewClosure()
            }
        )
        # Set the Archive Buttons properties
        [System.Collections.Hashtable[]]$ArchiveButtonsPropertiesArray = @(
            @{
                ColumnNumber    = 5
                Text            = 'Restore'
                PNGFileName     = 'arrow_up'
                SizeType        = 'Medium'
                ToolTip         = 'Restore the selected archive zip to the DSL location.'
                Function        = {
                    Invoke-DSLArchiveOperation -Action 'Restore' -SearchResultsListView $SearchResultsListView -ArchiveResultsListView $ArchiveResultsListView -SearchTerm $SearchTermTextBox.Text
                }.GetNewClosure()
            }
            @{
                ColumnNumber    = 5
                Text            = 'Remove'
                PNGFileName     = 'package_delete'
                SizeType        = 'Medium'
                ToolTip         = 'Permanently remove the selected archive zip.'
                Function        = {
                    Invoke-DSLArchiveOperation -Action 'Remove' -SearchResultsListView $SearchResultsListView -ArchiveResultsListView $ArchiveResultsListView -SearchTerm $SearchTermTextBox.Text
                }.GetNewClosure()
            }
        )

        # EXECUTION - BUTTONS
        # Create the Buttons
        New-ButtonLine -InputObject $InputObject -ButtonPropertiesArray $ActionButtons1PropertiesArray -ParentGroupBox $FeatureGroupBox -RowNumber 2
        New-ButtonLine -InputObject $InputObject -ButtonPropertiesArray $TransferButtonsPropertiesArray -ParentGroupBox $FeatureGroupBox -RowNumber 10
        New-ButtonLine -InputObject $InputObject -ButtonPropertiesArray $ArchiveButtonsPropertiesArray[0] -ParentGroupBox $ArchiveGroupBox -RowNumber 1
        New-ButtonLine -InputObject $InputObject -ButtonPropertiesArray $ArchiveButtonsPropertiesArray[1] -ParentGroupBox $ArchiveGroupBox -RowNumber 8

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
