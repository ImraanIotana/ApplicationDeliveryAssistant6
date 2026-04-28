#
# Module 'Graphics.Main.psm1'
# Last Update: April 2026
#

####################################################################################################
<#
.SYNOPSIS
    This function creates and manages the main form of the application.
.DESCRIPTION
    This function creates and manages the main form of the application. It sets the properties of the form, including size, position, and window buttons.
.EXAMPLE
    Invoke-MainForm
    Creates the main form of the application and sets its properties, but does not show it.
.EXAMPLE
    Invoke-MainForm -Show
    Displays the main form of the application.
.INPUTS
    [PSCustomObject]
    [System.Management.Automation.SwitchParameter]
.OUTPUTS
    This function returns no stream output.
.NOTES
    This script is part of the Universal Deployment Framework. Copyright (C) Iotana. All rights reserved.
    Version         : 6.0.0.0
    Author          : Imraan Iotana
    Creation Date   : April 2026
    Last Update     : April 2026
#>
####################################################################################################

function Initialize-Graphics {
    param (
        [Parameter(Mandatory=$false,HelpMessage='The name of the graphical settings file.')]
        [System.String]$GraphicalSettingsFileName = 'Graphics.Settings.psd1'
    )

    # Get the full path to the graphical settings file
    [System.String]$GraphicalSettingsFilePath = (Get-ChildItem -Path $Global:ApplicationObject.RootFolder -File -Filter $GraphicalSettingsFileName -Recurse).FullName

    # Import the graphical settings from the Graphics Settings file
    Write-Host 'Importing graphical settings...' -ForegroundColor DarkGray
    [System.Collections.Hashtable]$GraphicalSettings = Import-PowerShellDataFile -Path $GraphicalSettingsFilePath
    
    # Load the assemblies
    $GraphicalSettings.Assemblies | ForEach-Object { Write-Host "Loading Assembly $_..." -ForegroundColor DarkGray ; Add-Type -AssemblyName $_ }

    # Add the GraphicalSettings hashtable to the main object
    $Global:ApplicationObject | Add-Member -NotePropertyName GraphicalSettings -NotePropertyValue $GraphicalSettings
}

### END OF FUNCTION
####################################################################################################
