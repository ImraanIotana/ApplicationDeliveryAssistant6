####################################################################################################
<#
.SYNOPSIS
    Imports the File Compare feature into the Files sub-tab.
.DESCRIPTION
    This function imports the File Compare feature into the Files sub-tab by creating a new GroupBox and adding it to the specified parent TabPage.
.EXAMPLE
    Import-FeatureCompareFiles -InputObject $MyApplicationObject -ParentTabPage $MyTabPage
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
    Last Update     : June 2026
#>
####################################################################################################
function Import-FeatureCompareFiles {
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
        # PREPARATION - FEATURE PROPERTIES
        # Feature properties
        [System.Collections.Hashtable]$FeatureProperties = @{
            InputObject     = $InputObject
            ParentTabPage   = $ParentTabPage
            Title           = 'COMPARE FILES'
            Color           = 'Cyan'
            NumberOfRows    = 3
        }
        # If the GroupBoxAbove parameter is provided, set the GroupBoxAbove property
        if ($PSBoundParameters.ContainsKey('GroupBoxAbove')) { $FeatureProperties.GroupBoxAbove = $GroupBoxAbove }

        # PREPARATION - TEXTBOXES
        # Set the TextBox properties
        [System.Collections.Hashtable]$File1TextBoxProperties = @{
            RowNumber       = 1
            Label           = 'Select File 1'
            PropertyName    = 'TextBoxes.Files.FilePath1'
            ToolTip         = 'The path of the first file to compare'
            SizeType        = 'Medium'
            SmallButtons    = @(@(5,'Browse File'),@(6,'Paste'),@(7,'Open'))
        }
        # Set the TextBox properties
        [System.Collections.Hashtable]$File2TextBoxProperties = @{
            RowNumber       = 2
            Label           = 'Select File 2'
            PropertyName    = 'TextBoxes.Files.FilePath2'
            ToolTip         = 'The path of the second file to compare'
            SizeType        = 'Medium'
            SmallButtons    = @(@(5,'Browse File'),@(6,'Paste'),@(7,'Open'))
        }

        # PREPARATION - BUTTONS
        # Set the Button properties
        [System.Collections.Hashtable[]]$ButtonPropertiesArray1 = @(
            @{
                ColumnNumber    = 1
                Text            = 'Compare Files'
                PNGFileName     = 'price_comparison'
                SizeType        = 'Medium'
                Function        = {
                    # TEST
                    Write-Line "TEST: Comparing files: $($Global:Graphics.TextBoxes.CompareFiles.FilePath1.Text) and $($Global:Graphics.TextBoxes.CompareFiles.FilePath2.Text)..."
                }
            }
        )


        # EXECUTION
        # Create the GroupBox
        [System.Windows.Forms.GroupBox]$FeatureGroupBox = New-GroupBox @FeatureProperties -OnSubTab
        # Create the TextBoxes
        $Global:Graphics.TextBoxes.CompareFiles.FilePath1 = New-TextBox @File1TextBoxProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ReturnTextBox
        $Global:Graphics.TextBoxes.CompareFiles.FilePath2 = New-TextBox @File2TextBoxProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ReturnTextBox
        # Add the Buttons
        New-ButtonLine -InputObject $InputObject -ButtonPropertiesArray $ButtonPropertiesArray1 -ParentGroupBox $FeatureGroupBox -RowNumber 3
        # Return the GroupBox object
        $FeatureGroupBox
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}

### END OF FUNCTION
####################################################################################################

