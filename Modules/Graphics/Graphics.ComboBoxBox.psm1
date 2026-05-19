####################################################################################################
<#
.SYNOPSIS
    Adds graphical dimensions to the ComboBox settings based on the GroupBox dimensions and the ComboBox margins.
.DESCRIPTION
    This function adds graphical dimensions to the ComboBox settings based on the GroupBox dimensions and the ComboBox margins.
     It calculates the width of the ComboBox based on the GroupBox dimensions and the ComboBox margins, and adds these dimensions to the ComboBox settings in the GraphicalSettings hashtable of the main object.
.EXAMPLE
    Add-ComboBoxDimensions -InputObject $MyApplicationObject
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
function Add-ComboBoxDimensions {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The ApplicationObject containing the settings.')]
        [PSCustomObject]$InputObject
    )

    try {
        # PREPARATION - GET SETTINGS
        # Get the GraphicalSettings settings
        [System.Collections.Hashtable]$Settings = $InputObject.GraphicalSettings

        # EXECUTION
        # The ComboBox dimensions are exactly the same as the TextBox dimensions, so we can copy the TextBox dimensions to the ComboBox dimensions
        $Settings.ComboBox = $Settings.TextBox
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}

### END OF FUNCTION
####################################################################################################

