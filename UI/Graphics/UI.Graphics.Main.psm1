#
# Module 'UI.Graphics.Main.psm1'
# Last Update: April 2026
#

####################################################################################################
<#
.SYNOPSIS
    Initializes the graphical settings for the application by importing settings from a specified file and loading necessary assemblies.
.DESCRIPTION
    This function initializes the graphical settings for the application by importing settings from a specified file and loading necessary assemblies. It sets the properties of the main form, including size, position, and window buttons.
.EXAMPLE
    Initialize-Graphics
    Initializes the graphical settings for the application.
.INPUTS
    [System.String]
.OUTPUTS
    This function returns no stream output.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. All rights reserved.
    Version         : 6.0.0.0
    Author          : Imraan Iotana
    Creation Date   : April 2026
    Last Update     : April 2026
#>
####################################################################################################

function Initialize-Graphics {
    [CmdletBinding()]
    [OutputType([System.Void])]
    param (
        [Parameter(Mandatory=$false,HelpMessage='The name of the graphical settings file.')]
        [System.String]$GraphicalSettingsFileName = 'UI.Graphics.Settings.psd1'
    )

    # Get the full path to the graphical settings file
    [System.String]$GraphicalSettingsFilePath = (Get-ChildItem -Path $Global:ApplicationObject.RootFolder -File -Filter $GraphicalSettingsFileName -Recurse).FullName

    # Import the graphical settings from the Graphics Settings file
    Write-Line 'Importing graphical settings...' -Type Info
    [System.Collections.Hashtable]$GraphicalSettings = Import-PowerShellDataFile -Path $GraphicalSettingsFilePath
    
    # Load the assemblies
    $GraphicalSettings.Assemblies | ForEach-Object { Write-Line "Loading Assembly $_..." -Type Info ; Add-Type -AssemblyName $_ }

    # Add the GraphicalSettings hashtable to the main object
    $Global:ApplicationObject | Add-Member -NotePropertyName GraphicalSettings -NotePropertyValue $GraphicalSettings
}

### END OF FUNCTION
####################################################################################################
