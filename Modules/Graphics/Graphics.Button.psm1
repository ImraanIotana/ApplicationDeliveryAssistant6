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
        [System.Collections.Hashtable]$Settings = $InputObject.GraphicalSettings.MainForm

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

        # test
        $Settings.Button | Out-Host
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}

### END OF FUNCTION
####################################################################################################
