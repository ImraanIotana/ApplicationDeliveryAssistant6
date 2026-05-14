####################################################################################################
<#
.SYNOPSIS
    Starts the Application Delivery Assistant.
.DESCRIPTION
    This function starts the Application Delivery Assistant by initializing the necessary components and displaying the main form.
.EXAMPLE
    Start-Application
.INPUTS
    None.
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
function Start-Application {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false,HelpMessage='The ApplicationObject containing the settings.')]
        [PSCustomObject]$InputObject = $Global:ApplicationObject
    )

    try {
        # Initialize the User Settings
        Initialize-UserSettings -InputObject $InputObject
        # Initialize the graphics
        Initialize-Graphics
        # Show the Main Form
        Show-MainForm       
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}

# END OF FUNCTION
####################################################################################################
