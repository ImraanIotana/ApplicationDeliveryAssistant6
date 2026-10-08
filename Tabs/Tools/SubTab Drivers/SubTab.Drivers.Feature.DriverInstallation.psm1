####################################################################################################
<#
.SYNOPSIS
    Imports the Driver Installation feature into the Drivers tab.
.DESCRIPTION
    Creates a Driver Installation GroupBox with an INF file path field and package staging and
    installation actions.
.EXAMPLE
    Import-FeatureDriverInstallation -InputObject $MyApplicationObject -ParentTabPage $MyTabPage
.INPUTS
    [PSCustomObject]
    [System.Windows.Forms.TabPage]
.OUTPUTS
    [System.Windows.Forms.GroupBox]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.2.0
    Author          : Imraan Iotana
    Creation Date   : August 2026
    Last Update     : August 2026
#>
####################################################################################################
function Import-FeatureDriverInstallation {
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
            InputObject     = $InputObject
            ParentTabPage   = $ParentTabPage
            Title           = 'DRIVER INSTALLATION'
            Color           = $Color
            NumberOfRows    = 3
            GroupBoxAbove   = $GroupBoxAbove
        }

        # EXECUTION - GROUPBOX
        [System.Windows.Forms.GroupBox]$FeatureGroupBox = New-GroupBox @GroupBoxProperties

        # EXECUTION - DRIVER INF TEXTBOX
        [System.Collections.Hashtable]$DriverInfTextBoxProperties = @{
            RowNumber       = 1
            Label           = 'Driver INF File'
            ToolTip         = 'Select the driver INF file to add to the Windows Driver Store.'
            SizeType        = 'Medium'
            SmallButtons    = @(@(5,'Browse File','Inf'),@(6,'Paste'),@(7,'Clear'))
        }
        [System.Windows.Forms.TextBox]$DriverInfTextBox = New-TextBox @DriverInfTextBoxProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ReturnTextBox

        # PREPARATION - ACTION BUTTONS
        [System.Collections.Hashtable[]]$ActionButtons = @(
            @{
                ColumnNumber    = 1
                Text            = 'Add to Driver Store'
                PNGFileName     = 'package_add'
                SizeType        = 'Large'
                ToolTip         = 'Add the driver package to the Windows Driver Store for later use without updating connected devices now.'
                Function        = {
                    Add-DriverPackage -InfPath $DriverInfTextBox.Text
                }.GetNewClosure()
            },
            @{
                ColumnNumber    = 2
                Text            = 'Add and Install Driver'
                PNGFileName     = 'package_go'
                SizeType        = 'Large'
                ToolTip         = 'Add the driver package to the Windows Driver Store and immediately install it on compatible connected devices.'
                Function        = {
                    Add-DriverPackage -InfPath $DriverInfTextBox.Text -Install
                }.GetNewClosure()
            },
            @{
                ColumnNumber    = 5
                Text            = 'Check Driver Status'
                PNGFileName     = 'check_box'
                SizeType        = 'Large'
                ToolTip         = 'Check whether the exact driver package is already in the Windows Driver Store or assigned to devices.'
                Function        = {
                    Test-DriverPackageInstallation -InfPath $DriverInfTextBox.Text
                }.GetNewClosure()
            }
        )

        # EXECUTION - ACTION BUTTONS
        New-ButtonLine -InputObject $InputObject -ButtonPropertiesArray $ActionButtons -ParentGroupBox $FeatureGroupBox -RowNumber 2

        # POST-EXECUTION
        $FeatureGroupBox | Add-Member -NotePropertyName 'DriverInfTextBox' -NotePropertyValue $DriverInfTextBox -Force
        $FeatureGroupBox
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}

### END OF FUNCTION
####################################################################################################