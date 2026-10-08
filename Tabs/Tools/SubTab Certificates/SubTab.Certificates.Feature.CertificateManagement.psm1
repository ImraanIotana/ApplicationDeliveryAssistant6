####################################################################################################
<#
.SYNOPSIS
    Imports the Certificate Management feature into the Certificates tab.
.DESCRIPTION
    Creates the search, results, and selected-certificate action controls. Show All loads the
    read-only inventory, and Show Details displays the selected certificate properties.
.EXAMPLE
    Import-FeatureCertificateManagement -InputObject $MyApplicationObject -ParentTabPage $MyTabPage
.INPUTS
    [PSCustomObject]
    [System.Windows.Forms.TabPage]
.OUTPUTS
    [System.Windows.Forms.GroupBox]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.1.0
    Author          : Imraan Iotana
    Creation Date   : August 2026
    Last Update     : August 2026
#>
####################################################################################################
function Import-FeatureCertificateManagement {
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
            Title         = 'CERTIFICATE MANAGEMENT'
            Color         = $Color
            NumberOfRows  = 11
            GroupBoxAbove = $GroupBoxAbove
        }

        # EXECUTION - GROUPBOX
        [System.Windows.Forms.GroupBox]$FeatureGroupBox = New-GroupBox @GroupBoxProperties

        # PREPARATION - SEARCH TEXTBOX
        [System.Collections.Hashtable]$SearchTermTextBoxProperties = @{
            RowNumber    = 1
            Label        = 'Search Certificates'
            ToolTip      = 'Enter text to search certificate subjects, issuers, stores, and thumbprints.'
            SizeType     = 'Medium'
            SmallButtons = @(@(5,'Copy'),@(6,'Paste'),@(7,'Clear'))
        }

        # PREPARATION - RESULTS LISTVIEW
        [PSCustomObject[]]$CertificateListViewColumnSchema = @(Get-CertificateListViewColumnSchema)
        [System.Collections.Hashtable]$CertificateResultsListViewProperties = @{
            RowNumber          = 4
            Label              = 'Certificate Results'
            SizeType           = 'Large'
            VisibleRowCount    = 10
            View               = 'Details'
            Columns            = @($CertificateListViewColumnSchema.Label)
            ColumnAutoSizeMode = 'Widest'
            ToolTip            = 'Certificate inventory results will be listed here.'
            GridLines          = $true
            FullRowSelect      = $true
        }

        # EXECUTION - CONTROLS
        [System.Windows.Forms.ListView]$CertificateResultsListView = New-ListView @CertificateResultsListViewProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ReturnListView
        Enable-ListViewColumnSorting -ListView $CertificateResultsListView -ColumnTypes @($CertificateListViewColumnSchema.SortType) -MetadataPrefix 'Certificate'
        $SearchTermTextBoxProperties.EnterAction = ({
            param($TextBox)
            Invoke-CertificateSearchResultsRefresh -ListView $CertificateResultsListView -SearchTerm $TextBox.Text
        }.GetNewClosure())
        [System.Windows.Forms.TextBox]$SearchTermTextBox = New-TextBox @SearchTermTextBoxProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ReturnTextBox

        # PREPARATION - SEARCH BUTTONS
        [System.Collections.Hashtable[]]$SearchButtons = @(
            @{
                ColumnNumber = 1
                Text         = 'Search'
                PNGFileName  = 'find'
                SizeType     = 'Medium'
                ToolTip      = 'Search the certificate inventory with the search term.'
                Function     = {
                    Invoke-CertificateSearchResultsRefresh -ListView $CertificateResultsListView -SearchTerm $SearchTermTextBox.Text
                }.GetNewClosure()
            },
            @{
                ColumnNumber = 4
                Text         = 'Show All'
                PNGFileName  = 'ssl_certificates'
                SizeType     = 'Medium'
                ToolTip      = 'Show all certificates in the inventory.'
                Function     = {
                    Clear-TextBox -TextBox $SearchTermTextBox -Force
                    Show-AllCertificatesInListView -ListView $CertificateResultsListView
                }.GetNewClosure()
            },
            @{
                ColumnNumber = 5
                Text         = 'Clear All'
                PNGFileName  = 'textfield_delete'
                SizeType     = 'Medium'
                ToolTip      = 'Clear the certificate search term and results.'
                Function     = {
                    Clear-TextBox -TextBox $SearchTermTextBox -Force
                    Invoke-ListViewBatchUpdate -ListView $CertificateResultsListView -Action {
                        $CertificateResultsListView.Items.Clear()
                    }
                }.GetNewClosure()
            }
        )

        # PREPARATION - STATUS FILTER BUTTONS
        [System.Collections.Hashtable[]]$StatusFilterButtons = @(
            @{
                ColumnNumber = 1
                Text         = 'Valid'
                PNGFileName  = 'ssl_certificates'
                SizeType     = 'Medium'
                ToolTip      = 'Show certificates that are currently valid.'
                Function     = {
                    Clear-TextBox -TextBox $SearchTermTextBox -Force
                    Show-CertificatePresetInListView -ListView $CertificateResultsListView -PresetFilter Valid
                }.GetNewClosure()
            },
            @{
                ColumnNumber = 2
                Text         = 'Expiring'
                PNGFileName  = 'clock_go'
                SizeType     = 'Medium'
                ToolTip      = 'Show certificates that expire within 30 days.'
                Function     = {
                    Clear-TextBox -TextBox $SearchTermTextBox -Force
                    Show-CertificatePresetInListView -ListView $CertificateResultsListView -PresetFilter Expiring
                }.GetNewClosure()
            },
            @{
                ColumnNumber = 3
                Text         = 'Expired'
                PNGFileName  = 'clock_go'
                SizeType     = 'Medium'
                ToolTip      = 'Show certificates that have already expired.'
                Function     = {
                    Clear-TextBox -TextBox $SearchTermTextBox -Force
                    Show-CertificatePresetInListView -ListView $CertificateResultsListView -PresetFilter Expired
                }.GetNewClosure()
            },
            @{
                ColumnNumber = 4
                Text         = 'Private Key'
                PNGFileName  = 'shield'
                SizeType     = 'Medium'
                ToolTip      = 'Show certificates that have an associated private key.'
                Function     = {
                    Clear-TextBox -TextBox $SearchTermTextBox -Force
                    Show-CertificatePresetInListView -ListView $CertificateResultsListView -PresetFilter PrivateKey
                }.GetNewClosure()
            },
            @{
                ColumnNumber = 5
                Text         = 'Personal'
                PNGFileName  = 'folder_user'
                SizeType     = 'Medium'
                ToolTip      = 'Show certificates in the Personal (My) store.'
                Function     = {
                    Clear-TextBox -TextBox $SearchTermTextBox -Force
                    Show-CertificatePresetInListView -ListView $CertificateResultsListView -PresetFilter PersonalStore
                }.GetNewClosure()
            }
        )

        # PREPARATION - CERTIFICATE ACTION BUTTONS
        [System.Collections.Hashtable[]]$CertificateActionButtons = @(
            @{
                ColumnNumber = 1
                Text         = 'Show Details'
                PNGFileName  = 'information'
                SizeType     = 'Large'
                ToolTip      = 'Show detailed information for the selected certificate.'
                Function     = {
                    Show-SelectedCertificateDetails -ListView $CertificateResultsListView
                }.GetNewClosure()
            },
            @{
                ColumnNumber = 2
                Text         = 'Open Current User Certificates'
                PNGFileName  = 'ssl_certificates'
                SizeType     = 'Large'
                ToolTip      = 'Open Current User Certificate Manager without elevation.'
                Function     = { Open-CurrentUserCertificateManager }
            },
            @{
                ColumnNumber = 3
                Text         = 'Open Local Computer Certificates'
                PNGFileName  = 'ssl_certificates'
                SizeType     = 'Large'
                ToolTip      = 'Open Local Computer Certificate Manager with administrator access.'
                Function     = { Open-LocalComputerCertificateManagerAsAdministrator }
            },
            @{
                ColumnNumber = 4
                Text         = 'Export Certificate'
                PNGFileName  = 'table_export'
                SizeType     = 'Large'
                ToolTip      = 'Export the selected certificate, optionally including its private key when available.'
                Function     = {
                    Invoke-SelectedCertificateExport -ListView $CertificateResultsListView
                }.GetNewClosure()
            },
            @{
                ColumnNumber = 5
                Text         = 'Remove Certificate'
                PNGFileName  = 'shield_delete'
                SizeType     = 'Large'
                ToolTip      = 'Choose and remove exact store installations of the selected certificate.'
                Function     = {
                    Invoke-SelectedCertificateRemoval -ListView $CertificateResultsListView -SearchTextBox $SearchTermTextBox
                }.GetNewClosure()
            }
        )

        # EXECUTION - BUTTONS
        New-ButtonLine -InputObject $InputObject -ButtonPropertiesArray $SearchButtons -ParentGroupBox $FeatureGroupBox -RowNumber 2
        New-Label -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -Text 'Preset Filters' -RowNumber 3
        New-ButtonLine -InputObject $InputObject -ButtonPropertiesArray $StatusFilterButtons -ParentGroupBox $FeatureGroupBox -RowNumber 3
        New-ButtonLine -InputObject $InputObject -ButtonPropertiesArray $CertificateActionButtons -ParentGroupBox $FeatureGroupBox -RowNumber 13

        # POST-EXECUTION
        $FeatureGroupBox | Add-Member -NotePropertyName 'SearchTermTextBox' -NotePropertyValue $SearchTermTextBox -Force
        $FeatureGroupBox | Add-Member -NotePropertyName 'CertificateResultsListView' -NotePropertyValue $CertificateResultsListView -Force
        $FeatureGroupBox
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}

### END OF FUNCTION
####################################################################################################