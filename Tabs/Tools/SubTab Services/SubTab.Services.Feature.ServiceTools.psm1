####################################################################################################
<#
.SYNOPSIS
    Imports the Service Tools feature into the Services sub-tab.
.DESCRIPTION
    This function creates the Service Tools GroupBox and adds it to the specified Services TabPage.
    The buttons work on the service that is selected in the Service Results list of Service Management.
.EXAMPLE
    Import-FeatureServiceTools -InputObject $MyApplicationObject -ParentTabPage $MyTabPage -ServiceResultsListView $MyListView
.INPUTS
    [PSCustomObject]
    [System.Windows.Forms.TabPage]
    [System.Windows.Forms.ListView]
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
function Import-FeatureServiceTools {
    [CmdletBinding()]
    [OutputType([System.Windows.Forms.GroupBox])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The ApplicationObject containing the Settings.')]
        [PSCustomObject]$InputObject,

        [Parameter(Mandatory=$true,HelpMessage='The Parent TabPage to which this Feature will be added.')]
        [System.Windows.Forms.TabPage]$ParentTabPage,

        [Parameter(Mandatory=$true,HelpMessage='The Service Results ListView that contains the selected service.')]
        [System.Windows.Forms.ListView]$ServiceResultsListView,

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
            Title           = 'SERVICE TOOLS'
            Color           = $Color
            NumberOfRows    = 2
            GroupBoxAbove   = $GroupBoxAbove
        }

        # EXECUTION - GROUPBOX
        # Create the GroupBox
        [System.Windows.Forms.GroupBox]$FeatureGroupBox = New-GroupBox @GroupBoxProperties

        # PREPARATION - BUTTON PROPERTIES
        # Set the action button properties
        [System.Collections.Hashtable[]]$ActionButtons = @(
            @{
                ColumnNumber    = 1
                Text            = 'Open Folder'
                PNGFileName     = 'folder_go'
                SizeType        = 'Large'
                ToolTip         = 'Open the folder with the executable of the selected service.'
                Function        = {
                    Open-SelectedServiceFolder -ListView $ServiceResultsListView
                }.GetNewClosure()
            },
            @{
                ColumnNumber    = 2
                Text            = 'Open in Registry'
                PNGFileName     = 'regedit'
                SizeType        = 'Large'
                ToolTip         = 'Open the Registry Editor at the key of the selected service. When the Registry Editor is already open, it is not moved to the key.'
                Function        = {
                    Open-SelectedServiceRegistryKey -ListView $ServiceResultsListView
                }.GetNewClosure()
            },
            @{
                ColumnNumber    = 3
                Text            = 'Copy Info'
                PNGFileName     = 'page_copy'
                SizeType        = 'Large'
                ToolTip         = 'Copy the service name, display name, executable path or a summary of the selected service to the clipboard.'
                Function        = {
                    Copy-SelectedServiceInformation -ListView $ServiceResultsListView
                }.GetNewClosure()
            },
            @{
                ColumnNumber    = 4
                Text            = 'Export Service'
                PNGFileName     = 'table_export'
                SizeType        = 'Large'
                ToolTip         = 'Export a report, the registry key and the commands to recreate the selected service to the configured output folder.'
                Function        = {
                    Export-SelectedService -ListView $ServiceResultsListView -OpenOutputFolder
                }.GetNewClosure()
            },
            @{
                ColumnNumber    = 5
                Text            = 'Remove Service'
                PNGFileName     = 'package_delete'
                SizeType        = 'Large'
                ToolTip         = 'Remove the selected service. The service must be stopped. Windows will request administrator approval.'
                Function        = {
                    Remove-SelectedService -ListView $ServiceResultsListView
                }.GetNewClosure()
            }
        )

        # EXECUTION - BUTTONS
        # Create the action button row
        New-ButtonLine -InputObject $InputObject -ButtonPropertiesArray $ActionButtons -ParentGroupBox $FeatureGroupBox -RowNumber 1

        # POST-EXECUTION
        # Return the GroupBox
        $FeatureGroupBox
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}

### END OF FUNCTION
####################################################################################################
