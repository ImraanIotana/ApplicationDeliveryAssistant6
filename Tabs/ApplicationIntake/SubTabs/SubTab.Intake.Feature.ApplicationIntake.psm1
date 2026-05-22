####################################################################################################
<#
.SYNOPSIS
    Imports the Ping Computer feature into the Connections sub-tab.
.DESCRIPTION
    This function imports the Ping Computer feature into the Connections sub-tab by creating a new GroupBox and adding it to the specified parent TabPage.
.EXAMPLE
    Import-FeaturePingComputer -InputObject $MyApplicationObject -ParentTabPage $MyTabPage
.INPUTS
    [PSCustomObject]
    [System.Windows.Forms.TabPage]
.OUTPUTS
    No objects are returned to the pipeline. All output is written to the host.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. All rights reserved.
    Version         : 6.0.0.0
    Author          : Imraan Iotana
    Creation Date   : May 2026
    Last Update     : May 2026
#>
####################################################################################################
function Import-FeatureApplicationIntake {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The ApplicationObject containing the Settings.')]
        [PSCustomObject]$InputObject,

        [Parameter(Mandatory=$true,HelpMessage='The Parent TabPage to which this Feature will be added.')]
        [System.Windows.Forms.TabPage]$ParentTabPage,

        [Parameter(Mandatory=$false,HelpMessage='The GroupBox above which this Feature will be added.')]
        [System.Windows.Forms.GroupBox]$GroupBoxAbove
    )

    try {
        # EXECUTION - GROUPBOX
        # Feature properties
        [System.Collections.Hashtable]$FeatureProperties = @{
            InputObject     = $InputObject
            ParentTabPage   = $ParentTabPage
            Title           = 'Application Intake'
            Color           = 'White'
            NumberOfRows    = 8
        }
        # If the GroupBoxAbove parameter is provided, set the GroupBoxAbove property
        if ($PSBoundParameters.ContainsKey('GroupBoxAbove')) { $FeatureProperties.GroupBoxAbove = $GroupBoxAbove }
        # Create the GroupBox
        [System.Windows.Forms.GroupBox]$FeatureGroupBox = New-GroupBox @FeatureProperties

        # EXECUTION - COMBOBOXES
        # Set the ComboBox properties
        [System.Collections.Hashtable]$SelectedApplicationComboBoxProperties = @{
            RowNumber                   = 1
            Label                       = 'Import from Registry:'
            PropertyName                = 'SubTab.Intake.SelectedApplicationFromRegistry'
            ToolTip                     = 'The name of the application to intake'
            SizeType                    = 'Medium'
            ApplicationsFromRegistry    = Get-InstalledApplicationsFromRegistry
        }
        # Create the ComboBoxes
        $SelectedApplicationComboBox = New-ComboBox @SelectedApplicationComboBoxProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ReturnComboBox

        # EXECUTION - BUTTONS
        # Set the Button properties
        [System.Collections.Hashtable[]]$ButtonPropertiesArray1 = @(
            @{
                ColumnNumber    = 1
                Text            = 'Import'
                PNGFileName     = 'download_for_windows'
                SizeType        = 'Medium'
                ToolTip         = 'Import the selected application from the registry.'
                Function        = {
                    Write-Line "This function is still in development."
                }
            }
            @{
                ColumnNumber    = 3
                Text            = 'Details'
                PNGFileName     = 'information'
                SizeType        = 'Medium'
                ToolTip         = 'View details of the selected application.'
                Function        = { $SelectedApplicationComboBox.SelectedItem | Format-List | Out-String | Write-Host }.GetNewClosure()
            }
        )
        # Add the Buttons
        New-ButtonLine -InputObject $InputObject -ButtonPropertiesArray $ButtonPropertiesArray1 -ParentGroupBox $FeatureGroupBox -RowNumber 2

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

