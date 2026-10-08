####################################################################################################
<#
.SYNOPSIS
    Imports the Certificate Import feature into the Certificates tab.
.DESCRIPTION
    Creates certificate file, target scope, target store, import, and installation-status controls.
.EXAMPLE
    Import-FeatureCertificateImport -InputObject $MyApplicationObject -ParentTabPage $MyTabPage
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
function Import-FeatureCertificateImport {
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
            Title         = 'CERTIFICATE IMPORT'
            Color         = $Color
            NumberOfRows  = 4.4
            GroupBoxAbove = $GroupBoxAbove
        }

        # EXECUTION - GROUPBOX
        [System.Windows.Forms.GroupBox]$FeatureGroupBox = New-GroupBox @GroupBoxProperties

        # EXECUTION - CERTIFICATE FILE TEXTBOX
        [System.Collections.Hashtable]$CertificateFileTextBoxProperties = @{
            RowNumber    = 1
            Label        = 'Certificate File'
            PropertyName = 'CertificateFilePath'
            ToolTip      = 'Select a certificate file to import.'
            SizeType     = 'Medium'
            SmallButtons = @(@(5,'Browse File','Other'),@(6,'Paste'),@(7,'Clear'))
        }
        [System.Windows.Forms.TextBox]$CertificateFileTextBox = New-TextBox @CertificateFileTextBoxProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ReturnTextBox

        # PREPARATION - TARGET COMBOBOXES
        [System.Collections.Hashtable]$CertificateScopeComboBoxProperties = @{
            RowNumber          = 2
            Label              = 'Target Scope'
            PropertyName       = 'CertificateTargetScope'
            ToolTip            = 'Select CurrentUser for non-administrative import or LocalMachine for a machine-wide target.'
            SizeType           = 'Medium'
            Type               = 'Output'
            DefaultValue       = 'CurrentUser'
            ContentStringArray = @('CurrentUser','LocalMachine')
        }
        [System.Collections.Hashtable]$CertificateStoreComboBoxProperties = @{
            RowNumber          = 3
            Label              = 'Certificate Store'
            PropertyName       = 'CertificateTargetStore'
            ToolTip            = 'Select the destination certificate store.'
            SizeType           = 'Medium'
            Type               = 'Output'
            DefaultValue       = 'My'
            ContentStringArray = @('My','Root','CA','TrustedPublisher','TrustedPeople','AuthRoot')
        }
        [System.Windows.Forms.ComboBox]$CertificateScopeComboBox = New-ComboBox @CertificateScopeComboBoxProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ReturnComboBox
        [System.Windows.Forms.ComboBox]$CertificateStoreComboBox = New-ComboBox @CertificateStoreComboBoxProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ReturnComboBox

        # PREPARATION - CERTIFICATE MANAGEMENT CONTROLS
        # Resolve the search controls used to show certificate action results
        [System.Windows.Forms.ListView]$CertificateResultsListView = $GroupBoxAbove.CertificateResultsListView
        [System.Windows.Forms.TextBox]$CertificateSearchTermTextBox = $GroupBoxAbove.SearchTermTextBox

        # PREPARATION - ACTION BUTTONS
        [System.Collections.Hashtable[]]$ActionButtons = @(
            @{
                ColumnNumber = 1
                Text         = 'Import Certificate'
                PNGFileName  = 'shield_add'
                SizeType     = 'Large'
                ToolTip      = 'Import the selected certificate and show the imported certificate in Certificate Management.'
                Function     = {
                    [System.String]$SelectedCertificatePath = [System.String]$CertificateFileTextBox.Text
                    [System.String]$SelectedScope = [System.String]$CertificateScopeComboBox.Text
                    [System.String]$SelectedStore = [System.String]$CertificateStoreComboBox.Text
                    [System.Windows.Forms.Form]$Owner = $CertificateFileTextBox.FindForm()
                    $null = Import-CertificateFileToStore -CertificateFilePath $SelectedCertificatePath -Scope $SelectedScope -Store $SelectedStore -Owner $Owner -ListView $CertificateResultsListView -SearchTextBox $CertificateSearchTermTextBox
                }.GetNewClosure()
            },
            @{
                ColumnNumber = 5
                Text         = 'Check Certificate Status'
                PNGFileName  = 'check_box'
                SizeType     = 'Large'
                ToolTip      = 'Check every readable CurrentUser and LocalMachine store and show matching certificates in Certificate Management.'
                Function     = {
                    [System.String]$SelectedCertificatePath = [System.String]$CertificateFileTextBox.Text
                    [System.Windows.Forms.Form]$Owner = $CertificateFileTextBox.FindForm()
                    $null = Test-CertificateInstalledInStore -CertificateFilePath $SelectedCertificatePath -Owner $Owner -ListView $CertificateResultsListView -SearchTextBox $CertificateSearchTermTextBox
                }.GetNewClosure()
            }
        )

        # EXECUTION - BUTTONS
        New-ButtonLine -InputObject $InputObject -ButtonPropertiesArray $ActionButtons -ParentGroupBox $FeatureGroupBox -RowNumber 4

        # POST-EXECUTION
        $FeatureGroupBox | Add-Member -NotePropertyName 'CertificateFileTextBox' -NotePropertyValue $CertificateFileTextBox -Force
        $FeatureGroupBox | Add-Member -NotePropertyName 'CertificateScopeComboBox' -NotePropertyValue $CertificateScopeComboBox -Force
        $FeatureGroupBox | Add-Member -NotePropertyName 'CertificateStoreComboBox' -NotePropertyValue $CertificateStoreComboBox -Force
        $FeatureGroupBox
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}

### END OF FUNCTION
####################################################################################################