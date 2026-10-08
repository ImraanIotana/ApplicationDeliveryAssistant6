####################################################################################################
<#
.SYNOPSIS
    Imports the available customer templates feature into the Intake Templates sub-tab.
.DESCRIPTION
    Creates a read-only ListView containing the discovered customer template identity, source,
    schema version, and folder path, with actions to refresh or copy the inventory.
.EXAMPLE
    Import-FeatureCustomerTemplateList -InputObject $MyApplicationObject -ParentTabPage $MyTabPage
.INPUTS
    [PSCustomObject]
    [System.Windows.Forms.TabPage]
.OUTPUTS
    [System.Windows.Forms.GroupBox]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.9.0
    Author          : Imraan Iotana
    Creation Date   : August 2026
    Last Update     : October 2026
#>
####################################################################################################
function Import-FeatureCustomerTemplateList {
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
        [System.Collections.Hashtable]$GroupBoxProperties = @{
            InputObject   = $InputObject
            ParentTabPage = $ParentTabPage
            Title         = 'AVAILABLE CUSTOMER TEMPLATES'
            Color         = $Color
            NumberOfRows  = 6
            GroupBoxAbove = $GroupBoxAbove
        }

        # EXECUTION - GROUPBOX
        [System.Windows.Forms.GroupBox]$FeatureGroupBox = New-GroupBox @GroupBoxProperties

        # PREPARATION - LISTVIEW PROPERTIES
        [System.Collections.Hashtable]$TemplateListViewProperties = @{
            RowNumber          = 1
            SizeType           = 'Large'
            VisibleRowCount    = 4
            View               = 'Details'
            Columns            = @('Active','Template','Source','Folder','Schema')
            ColumnAutoSizeMode = 'Widest'
            ToolTip            = 'Available built-in and user customer templates. Double-click a row to open its folder.'
            GridLines          = $true
            FullRowSelect      = $true
        }

        # EXECUTION - LISTVIEW
        [System.Windows.Forms.ListView]$TemplateListView = New-ListView @TemplateListViewProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ReturnListView
        Enable-ListViewColumnSorting -ListView $TemplateListView -ColumnTypes @('Text','Text','Text','Text','Text') -MetadataPrefix 'CustomerTemplate'
        # Open the selected customer template folder when the user double-clicks a row
        $TemplateListView.Add_DoubleClick({
            Open-SelectedCustomerTemplateFolder -ListView $TemplateListView
        }.GetNewClosure())
        Update-CustomerTemplateListView -ListView $TemplateListView

        # PREPARATION - BUTTONS
        [System.Collections.Hashtable[]]$Action1Buttons = @(
            @{
                ColumnNumber = 1
                Text         = 'Activate selected Template'
                PNGFileName  = 'report_word'
                SizeType     = 'Large'
                ToolTip      = 'Use the selected customer template for intake, mail, and AppLocker workflows.'
                Function     = {
                    Select-ActiveCustomerTemplate -ListView $TemplateListView
                }.GetNewClosure()
            },
            @{
                ColumnNumber = 4
                Text         = 'Export Template to ZIP'
                PNGFileName  = 'report_word'
                SizeType     = 'Large'
                ToolTip      = 'Export the selected customer template as a versioned Customer Extension ZIP file.'
                Function     = {
                    Export-SelectedCustomerTemplateExtension -ListView $TemplateListView
                }.GetNewClosure()
            },
            @{
                ColumnNumber = 5
                Text         = 'Import Template from ZIP'
                PNGFileName  = 'report_word'
                SizeType     = 'Large'
                ToolTip      = 'Import a Customer Extension ZIP file into your roaming Customer Templates folder.'
                Function     = {
                    Import-CustomerTemplateExtensionFromFile -ListView $TemplateListView
                }.GetNewClosure()
            }
        )
        [System.Collections.Hashtable[]]$Action2Buttons = @(
            @{
                ColumnNumber = 1
                Text         = 'Show Info'
                PNGFileName  = 'information'
                SizeType     = 'Medium'
                ToolTip      = 'Show information about the selected customer template.'
                Function     = {
                    Write-SelectedCustomerTemplateInformation -ListView $TemplateListView
                }.GetNewClosure()
            },
            @{
                ColumnNumber = 2
                Text         = 'Refresh'
                PNGFileName  = 'arrow_refresh'
                SizeType     = 'Medium'
                ToolTip      = 'Refresh the available customer template inventory.'
                Function     = {
                    Update-CustomerTemplateListView -ListView $TemplateListView
                }.GetNewClosure()
            },
            @{
                ColumnNumber = 3
                Text         = 'Edit'
                PNGFileName  = 'cog'
                SizeType     = 'Medium'
                ToolTip      = 'Edit the selected user-owned Schema 2 customer template.'
                Function     = {
                    Edit-SelectedCustomerTemplate -ListView $TemplateListView
                }.GetNewClosure()
            },
            @{
                ColumnNumber = 4
                Text         = 'Make Copy'
                PNGFileName  = 'page_copy'
                SizeType     = 'Medium'
                ToolTip      = 'Copy the selected customer template into your roaming Customer Templates folder.'
                Function     = {
                    Copy-SelectedCustomerTemplate -ListView $TemplateListView
                }.GetNewClosure()
            },
            @{
                ColumnNumber = 5
                Text         = 'Delete'
                PNGFileName  = 'package_delete'
                SizeType     = 'Medium'
                ToolTip      = 'Move the selected user customer template folder to the Recycle Bin.'
                Function     = {
                    Remove-SelectedCustomerTemplate -ListView $TemplateListView
                }.GetNewClosure()
            }
        )

        # EXECUTION - BUTTONS
        # Large buttons are two rows high, so the second button line starts two rows lower
        New-ButtonLine -InputObject $InputObject -ButtonPropertiesArray $Action1Buttons -ParentGroupBox $FeatureGroupBox -RowNumber 5
        New-ButtonLine -InputObject $InputObject -ButtonPropertiesArray $Action2Buttons -ParentGroupBox $FeatureGroupBox -RowNumber 7

        # POST-EXECUTION
        return $FeatureGroupBox
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}

### END OF FUNCTION
####################################################################################################