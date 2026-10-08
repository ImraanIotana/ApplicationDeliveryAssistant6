####################################################################################################
<#
.SYNOPSIS
    Imports the Deployment Data feature into the UDF tab.
.DESCRIPTION
    This function creates the first UDF feature GroupBox with a TextBox for selecting the DeploymentData.psd1 file.
.EXAMPLE
    Import-FeatureUDFImport -InputObject $MyApplicationObject -ParentTabPage $MyTabPage
.INPUTS
    [PSCustomObject]
    [System.Windows.Forms.TabPage]
    [System.Windows.Forms.GroupBox]
    [System.String]
.OUTPUTS
    [System.Windows.Forms.GroupBox]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.4
    Author          : Imraan Iotana
    Creation Date   : August 2026
    Last Update     : August 2026
#>
####################################################################################################
function Import-FeatureUDFImport {
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
            Title           = 'DEPLOYMENT DATA'
            Color           = $Color
            NumberOfRows    = 5
            GroupBoxAbove   = $GroupBoxAbove
        }

        # EXECUTION - GROUPBOX
        # Create the GroupBox
        [System.Windows.Forms.GroupBox]$FeatureGroupBox = New-GroupBox @GroupBoxProperties

        # PREPARATION - TEXTBOX PROPERTIES
        # Set the TextBox properties for the Deployment Data File selection.
        [System.Collections.Hashtable]$DeploymentDataTextBoxProperties = @{
            RowNumber       = 1
            Label           = 'Deployment Data File'
            PropertyName    = 'UDFDeploymentDataFilePath'
            ToolTip         = 'Select the DeploymentData.psd1 file used by UDF.'
            SizeType        = 'Medium'
            SmallButtons    = @(@(5,'Browse File'),@(6,'Paste'),@(7,'Open'))
        }

        # EXECUTION - TEXTBOX
        # Create the Deployment Data File TextBox with browse/open helpers.
        [System.Windows.Forms.TextBox]$DeploymentDataTextBox = New-TextBox @DeploymentDataTextBoxProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ReturnTextBox

        # PREPARATION - UDF LISTVIEW COLOR THEME
        # Resolve shared ListView theme overrides from application settings.
        [System.Collections.Hashtable]$ThemeOverrides = Get-ListViewThemeOverridesFromInputObject -InputObject $InputObject
        [System.String]$ReadOnlyBackColor = [System.String]$ThemeOverrides.ReadOnlyBackColor
        [System.String]$ReadOnlyTextColor = [System.String]$ThemeOverrides.ReadOnlyTextColor

        # PREPARATION - MAIN SETTINGS LISTVIEW PROPERTIES
        # Create the list for file-level settings.
        [System.Collections.Hashtable]$MainPropertiesListViewProperties = @{
            RowNumber       = 3
            Label           = 'Main Properties'
            SizeType        = 'Large'
            VisibleRowCount = 3
            View            = 'Details'
            Columns         = @('Property','Value')
            ColumnAutoSizeMode = 'Widest'
            ToolTip         = 'Shows file-level settings. Double-click the Value cell to edit.'
            GridLines       = $true
            FullRowSelect   = $true
            BackColor       = $ReadOnlyBackColor
            TextColor       = $ReadOnlyTextColor
            ThemeOverrides  = $ThemeOverrides
        }

        # EXECUTION - LISTVIEW
        # Add the main settings list to the UDF GroupBox.
        [System.Windows.Forms.ListView]$MainPropertiesListView = New-ListView @MainPropertiesListViewProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ReturnListView

        $FeatureGroupBox | Add-Member -NotePropertyName 'DeploymentDataTextBox' -NotePropertyValue $DeploymentDataTextBox -Force
        $FeatureGroupBox | Add-Member -NotePropertyName 'MainPropertiesListView' -NotePropertyValue $MainPropertiesListView -Force

        $FeatureGroupBox
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}

### END OF FUNCTION
####################################################################################################


