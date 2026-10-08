####################################################################################################
<#
.SYNOPSIS
    Imports the Application Detection feature into the Desktop Application sub-tab.
.DESCRIPTION
    This function imports the Application Detection feature into the Desktop Application sub-tab by creating a new GroupBox and adding it to the specified parent TabPage.
.EXAMPLE
    Import-FeatureIntakeApplicationDetection -InputObject $MyApplicationObject -ParentTabPage $MyTabPage
.INPUTS
    [PSCustomObject]
    [System.Windows.Forms.TabPage]
    [System.Windows.Forms.GroupBox]
    [System.String]
.OUTPUTS
    [System.Windows.Forms.GroupBox]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.2.2
    Author          : Imraan Iotana
    Creation Date   : May 2026
    Last Update     : August 2026
#>
####################################################################################################
function Import-FeatureIntakeApplicationDetection {
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
        # EXECUTION - GROUPBOX
        # Feature properties
            [System.Collections.Hashtable]$GroupBoxProperties = @{
            InputObject     = $InputObject
            ParentTabPage   = $ParentTabPage
            Title           = 'APPLICATION DETECTION AND BITNESS'
            Color           = $Color
            NumberOfRows    = 1
            GroupBoxAbove   = $GroupBoxAbove
        }

        # EXECUTION - GROUPBOX
        # Create the GroupBox
        [System.Windows.Forms.GroupBox]$FeatureGroupBox = New-GroupBox @GroupBoxProperties

        # EXECUTION - TEXTBOX
        # Set the ComboBox properties
            [System.Collections.Hashtable]$DetectionFileTextBoxProperties = @{
            RowNumber                   = 1
            Label                       = 'Detection file / MSI'
            ToolTip                     = 'The detection file or MSI of the application. This will be used to acquire the detection information for the distribution system.'
            SizeType                    = 'Medium'
            SmallButtons                = @(@(6,'Paste'),@(7,'Open'))
        }

        # Create the TextBox
            [System.Windows.Forms.TextBox]$DetectionFileTextBox = New-TextBox @DetectionFileTextBoxProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ReturnTextBox

        # EXECUTION - BUTTONS
        # Set the Small Buttons properties
        [System.Collections.Hashtable[]]$SmallButtonsPropertiesArray = @(
            @{
                ColumnNumber    = 5
                Text            = 'Browse File'
                PNGFileName     = 'magnifier'
                SizeType        = 'Small'
                ToolTip         = 'Browse for the detection file or MSI of the application.'
                Function        = {
                    [System.Windows.Forms.TextBox]$InstallationFolderTextBox = Get-TextBoxObject -TextBoxName 'InstallationFolder'

                    [System.String]$InitialDirectory = if ($null -ne $InstallationFolderTextBox) { [System.String]$InstallationFolderTextBox.Text } else { $null }
                    Select-File -InitialDirectory $InitialDirectory -TextBox $DetectionFileTextBox -Type Executable
                }.GetNewClosure()
            }
        )
        # Create the Buttons
        New-ButtonLine -InputObject $InputObject -ButtonPropertiesArray $SmallButtonsPropertiesArray -ParentGroupBox $FeatureGroupBox -RowNumber 1

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

