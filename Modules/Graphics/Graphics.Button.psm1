#
# Module 'Graphics.Button.psm1'
# Last Update: May 2026
#

####################################################################################################
<#
.SYNOPSIS
    Adds graphical dimensions to the Button settings based on the MainForm dimensions and the Button margins.
.DESCRIPTION
    This function adds graphical dimensions to the Button settings based on the MainForm dimensions and the Button margins.
     It calculates the width and height of the Button based on the MainForm dimensions and the Button margins, and adds these dimensions to the Button settings in the GraphicalSettings hashtable of the main object.
.EXAMPLE
    Add-ButtonDimensions -InputObject $Global:ApplicationObject
.INPUTS
    [PSCustomObject]
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
function Add-ButtonDimensions {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false,HelpMessage='The ApplicationObject containing the settings.')]
        [PSCustomObject]$InputObject
    )

    try {
        # PREPARATION - GET SETTINGS
        # Get the MainForm settings
        [System.Collections.Hashtable]$Settings = $InputObject.GraphicalSettings

        # EXECUTION - ADD BUTTON WIDTH
        # Add the width of the Large Button
        [System.Int32]$ButtonLargeWidth     = $Settings.TextBox.LargeWidth / 5
        $Settings.Button.LargeWidth         = $ButtonLargeWidth
        # Add the width of the Medium Button (same as Large)
        $Settings.Button.MediumWidth        = $ButtonLargeWidth
        # Add the width of the Small Button
        $Settings.Button.SmallWidth         = ($ButtonLargeWidth / 3)

        # EXECUTION - ADD BUTTON HEIGHT
        # Add the height of the Large Button
        [System.Int32]$TextBoxHeight        = $Settings.TextBox.Height
        [System.Int32]$ButtonLargeHeight    = $TextBoxHeight * 2
        $Settings.Button.LargeHeight        = $ButtonLargeHeight
        # Add the height of the Medium Button
        [System.Int32]$ButtonMediumHeight   = $TextBoxHeight - 3
        $Settings.Button.MediumHeight       = $ButtonMediumHeight
        # Add the height of the Small Button (same as Medium)
        $Settings.Button.SmallHeight        = $ButtonMediumHeight
        
        # Get the values
        [System.Int32]$MainTabControlLocationX  = $Settings.MainTabControl.Location.X
        [System.Int32]$LabelLeftMargin          = $Settings.Label.LeftMargin
        [System.Int32]$TextBoxLeftMargin        = $Settings.TextBox.LeftMargin
        [System.Int32]$ButtonMediumWidth        = $Settings.Button.MediumWidth
        # Set the Array
        [System.Collections.ArrayList]$ColumnNumbersLocationXArray = New-Object System.Collections.ArrayList
        # Set the ColumnNumbers and their X location
        # Column 0 is the location underneath the Label
        [void]$ColumnNumbersLocationXArray.Add($LabelLeftMargin) # Column and Index 0
        # Column 1 is the first location underneath the TextBox
        [void]$ColumnNumbersLocationXArray.Add(($MainTabControlLocationX + $LabelLeftMargin + $TextBoxLeftMargin)) # Column and Index 1
        # Columns 2-5 are the following locations underneath the TextBox
        @(1..4) | ForEach-Object { [void]$ColumnNumbersLocationXArray.Add($ColumnNumbersLocationXArray[$_] + $ButtonMediumWidth) } # Column and Index 2-5
        # Column 6 is only used for the small buttons
        [void]$ColumnNumbersLocationXArray.Add($ColumnNumbersLocationXArray[5] + ($ButtonMediumWidth * 1/3 )) # Column and Index 6
        [void]$ColumnNumbersLocationXArray.Add($ColumnNumbersLocationXArray[6] + ($ButtonMediumWidth * 1/3 )) # Column and Index 7
        [void]$ColumnNumbersLocationXArray.Add($ColumnNumbersLocationXArray[7] + ($ButtonMediumWidth * 1/3 )) # Column and Index 8
        # Add the results to the Global Settings
        @(0..7) | ForEach-Object { $Settings.ColumnNumber.Add( $_ , $ColumnNumbersLocationXArray[$_]) }

        # test
        $Settings.ColumnNumber | Out-Host
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}

### END OF FUNCTION
####################################################################################################
