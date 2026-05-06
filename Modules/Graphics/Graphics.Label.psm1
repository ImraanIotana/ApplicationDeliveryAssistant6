#
# Module 'Graphics.Label.psm1'
# Last Update: May 2026
#

####################################################################################################
<#
.SYNOPSIS
    This function creates a new Label.
.DESCRIPTION
    This function is part of the Application Delivery Assistant. It creates a new label and adds it to the specified parent group box.
.EXAMPLE
    New-Label -ParentGroupBox $GroupBox -Text "Sample Label" -TextColor "Black" -RowNumber 1
.INPUTS
    [PSCustomObject]
    [System.Windows.Forms.GroupBox]
    [System.String]
    [System.Int32]
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
function New-Label {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The ApplicationObject containing the settings.')]
        [PSCustomObject]$InputObject,

        [Parameter(Mandatory=$true,HelpMessage='The Parent GroupBox to which this label will be added.')]
        [System.Windows.Forms.GroupBox]$ParentGroupBox,

        [Parameter(Mandatory=$true,HelpMessage='The text to be displayed on the label.')]
        [System.String]$Text,

        [Parameter(Mandatory=$true,HelpMessage='The row number for positioning the label.')]
        [System.Int32]$RowNumber,

        [Parameter(Mandatory=$false,HelpMessage='The color of the text.')]
        [System.String]$TextColor
    )

    try {
        # PREPARATION - GET SETTINGS
        # Get the GraphicalSettings settings
        [System.Collections.Hashtable]$Settings = $InputObject.GraphicalSettings

        # Create the label object
        [System.Windows.Forms.Label]$NewLabel = New-Object System.Windows.Forms.Label


        # Set the location of the label
        [System.Int32]$LabelX = $ParentGroupBox.Location.X + $Settings.Label.LeftMargin
        [System.Int32]$LabelY = ($Settings.TextBox.TopMargin + 2) + (($RowNumber - 1) * $Settings.TextBox.Height)
        $NewLabel.Location = New-Object System.Drawing.Point($LabelX, $LabelY)

        # Set the Text of the label
        $NewLabel.Text = $Text

        # Set the Font of the label
        $NewLabel.Font = $Settings.MainFont

        # Set the Text Color of the label
        if ($TextColor) { $NewLabel.ForeColor = [System.Drawing.Color]::FromName($TextColor) }

        # Set the AutoSize property of the label
        $NewLabel.AutoSize = $true

        # Add the label to the Parent GroupBox
        $ParentGroupBox.Controls.Add($NewLabel)
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}

### END OF SCRIPT
####################################################################################################
