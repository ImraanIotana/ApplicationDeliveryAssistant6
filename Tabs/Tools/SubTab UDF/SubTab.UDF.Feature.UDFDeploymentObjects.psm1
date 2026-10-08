####################################################################################################
<#
.SYNOPSIS
    Imports the Deployment Objects list feature into the UDF tab.
.DESCRIPTION
    This function creates a dedicated GroupBox that hosts the Deployment Objects ListView.
.EXAMPLE
    Import-FeatureUDFDeploymentObjects -InputObject $MyApplicationObject -ParentTabPage $MyTabPage
.INPUTS
    [PSCustomObject]
    [System.Windows.Forms.TabPage]
    [System.Windows.Forms.GroupBox]
    [System.String]
.OUTPUTS
    [PSCustomObject]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.4
    Author          : Imraan Iotana
    Creation Date   : August 2026
    Last Update     : August 2026
#>
####################################################################################################
function Import-FeatureUDFDeploymentObjects {
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
        # Create a dedicated group for deployment objects.
        [System.Collections.Hashtable]$GroupBoxProperties = @{
            InputObject     = $InputObject
            ParentTabPage   = $ParentTabPage
            Title           = 'DEPLOYMENT OBJECTS'
            Color           = $Color
            NumberOfRows    = 4.5
            GroupBoxAbove   = $GroupBoxAbove
        }

        # EXECUTION - GROUPBOX
        # Create the GroupBox.
        [System.Windows.Forms.GroupBox]$FeatureGroupBox = New-GroupBox @GroupBoxProperties

        # PREPARATION - UDF LISTVIEW COLOR THEME
        # Resolve shared ListView theme overrides from application settings.
        [System.Collections.Hashtable]$ThemeOverrides = Get-ListViewThemeOverridesFromInputObject -InputObject $InputObject
        [System.String]$ReadOnlyBackColor = [System.String]$ThemeOverrides.ReadOnlyBackColor
        [System.String]$ReadOnlyTextColor = [System.String]$ThemeOverrides.ReadOnlyTextColor

        # PREPARATION - LISTVIEW PROPERTIES
        # Create the list that will show DeploymentObjects after load.
        [System.Collections.Hashtable]$DeploymentObjectsListViewProperties = @{
            RowNumber           = 1
            Label               = 'Deployment Objects'
            SizeType            = 'Large'
            View                = 'Details'
            Columns             = @('#','Type','Summary')
            ColumnAutoSizeMode  = 'Widest'
            ToolTip             = 'Shows the deployment object blocks from DeploymentData.psd1.'
            GridLines           = $true
            FullRowSelect       = $true
            BackColor           = $ReadOnlyBackColor
            TextColor           = $ReadOnlyTextColor
            ThemeOverrides      = $ThemeOverrides
        }

        # EXECUTION - LISTVIEW
        # Add the objects list to the GroupBox.
        [System.Windows.Forms.ListView]$DeploymentObjectsListView = New-ListView @DeploymentObjectsListViewProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ReturnListView

        # EXECUTION - BUTTONS
        # Add deployment object list actions.
        [System.Collections.Hashtable[]]$DeploymentObjectButtons = @(
            @{
                ColumnNumber    = 1
                Text            = 'Add'
                PNGFileName     = 'package_add'
                SizeType        = 'Medium'
                ToolTip         = 'Add a new deployment object from the loaded _Catalog metadata. (Test flow)'
                Function        = {
                    [void](Add-UDFDeploymentObjectFromCatalog -SourceListView $DeploymentObjectsListView)
                }.GetNewClosure()
            }
            @{
                ColumnNumber    = 2
                Text            = 'Move Up'
                PNGFileName     = 'arrow_up'
                SizeType        = 'Medium'
                ToolTip         = 'Move the selected deployment object up one row.'
                Function        = {
                    [void](Move-UDFSelectedDeploymentObjectByOffset -SourceListView $DeploymentObjectsListView -Offset -1)
                }.GetNewClosure()
            }
            @{
                ColumnNumber    = 3
                Text            = 'Move Down'
                PNGFileName     = 'arrow_down'
                SizeType        = 'Medium'
                ToolTip         = 'Move the selected deployment object down one row.'
                Function        = {
                    [void](Move-UDFSelectedDeploymentObjectByOffset -SourceListView $DeploymentObjectsListView -Offset 1)
                }.GetNewClosure()
            }
            @{
                ColumnNumber    = 5
                Text            = 'Delete'
                PNGFileName     = 'package_delete'
                SizeType        = 'Medium'
                ToolTip         = 'Delete the selected deployment object.'
                Function        = {
                    [void](Remove-UDFSelectedDeploymentObject -SourceListView $DeploymentObjectsListView)
                }.GetNewClosure()
            }
        )
        New-ButtonLine -InputObject $InputObject -ButtonPropertiesArray $DeploymentObjectButtons -ParentGroupBox $FeatureGroupBox -RowNumber 5

        $FeatureGroupBox | Add-Member -NotePropertyName 'SourceListView' -NotePropertyValue $DeploymentObjectsListView -Force

        $FeatureGroupBox
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}

### END OF FUNCTION
####################################################################################################
