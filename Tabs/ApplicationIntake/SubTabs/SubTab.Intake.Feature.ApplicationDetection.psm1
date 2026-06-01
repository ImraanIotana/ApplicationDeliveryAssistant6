####################################################################################################
<#
.SYNOPSIS
    Imports the Application Detection feature into the Intake sub-tab.
.DESCRIPTION
    This function imports the Application Detection feature into the Intake sub-tab by creating a new GroupBox and adding it to the specified parent TabPage.
.EXAMPLE
    Import-FeatureIntakeApplicationDetection -InputObject $MyApplicationObject -ParentTabPage $MyTabPage
.INPUTS
    [PSCustomObject]
    [System.Windows.Forms.TabPage]
    [System.Windows.Forms.GroupBox]
.OUTPUTS
    [System.Windows.Forms.GroupBox]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. All rights reserved.
    Version         : 6.0.0.0
    Author          : Imraan Iotana
    Creation Date   : May 2026
    Last Update     : June 2026
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

        [Parameter(Mandatory=$false,HelpMessage='The GroupBox above which this Feature will be added.')]
        [System.Windows.Forms.GroupBox]$GroupBoxAbove
    )

    try {
        # EXECUTION - GROUPBOX
        # Feature properties
        [System.Collections.Hashtable]$FeatureProperties = @{
            InputObject     = $InputObject
            ParentTabPage   = $ParentTabPage
            Title           = 'APPLICATION DETECTION'
            Color           = 'Yellow'
            NumberOfRows    = 1
        }
        # If the GroupBoxAbove parameter is provided, set the GroupBoxAbove property
        if ($PSBoundParameters.ContainsKey('GroupBoxAbove')) { $FeatureProperties.GroupBoxAbove = $GroupBoxAbove }
        # Create the GroupBox
        [System.Windows.Forms.GroupBox]$FeatureGroupBox = New-GroupBox @FeatureProperties -OnSubTab

        # EXECUTION - TEXTBOX
        # Set the ComboBox properties
        [System.Collections.Hashtable]$SelectedApplicationComboBoxProperties = @{
            RowNumber                   = 1
            Label                       = 'Detection file / MSI'
            PropertyName                = 'TextBoxes.IntakeApplication.Detection.SelectedApplication'
            ToolTip                     = 'The name of the application to intake'
            SizeType                    = 'Medium'
            SmallButtons                = @(@(6,'Paste'),@(7,'Open'))
        }
        # Create the hashtables for the TextBoxes in the Global Graphics object if they do not already exist
        if (-not $Global:Graphics.TextBoxes.ContainsKey('IntakeApplication')) { $Global:Graphics.TextBoxes.IntakeApplication = @{} }
        if (-not $Global:Graphics.TextBoxes.IntakeApplication.ContainsKey('Detection')) { $Global:Graphics.TextBoxes.IntakeApplication.Detection = @{} }
        # Create the TextBox
        $Global:Graphics.TextBoxes.IntakeApplication.Detection.SelectedApplication = New-TextBox @SelectedApplicationComboBoxProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ReturnTextBox

        # EXECUTION - BUTTONS
        # Set the Small Buttons properties
        [System.Collections.Hashtable[]]$SmallButtonsPropertiesArray = @(
            @{ # Testing duplicate buttons with the same function to ensure they work as expected
                ColumnNumber    = 5
                Text            = 'Browse'
                PNGFileName     = 'magnifier'
                SizeType        = 'Small'
                ToolTip         = 'Browse for a detection file or MSI.'
                Function        = { $Global:Graphics.TextBoxes.IntakeApplication.Detection.SelectedApplication.Text | Format-List | Out-String | Write-Host }.GetNewClosure()
            }
        )
        # Add the Buttons
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

