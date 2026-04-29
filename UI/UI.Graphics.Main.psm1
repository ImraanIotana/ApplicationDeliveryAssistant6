#
# Module 'UI.Graphics.Main.psm1'
# Last Update: April 2026
#

####################################################################################################
<#
.SYNOPSIS
    Initializes the graphical settings for the application by importing settings from a specified file and loading necessary assemblies.
.DESCRIPTION
    This function initializes the graphical settings for the application by importing settings from a specified file and loading necessary assemblies.
    It sets the properties of the main form, including size, position, and window buttons.
.EXAMPLE
    Initialize-Graphics
    Initializes the graphical settings for the application.
.INPUTS
    [System.String]
.OUTPUTS
    No objects are returned to the pipeline. All output is written to the host.
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
        [System.String]$GraphicalSettingsFileName = 'UI.Graphics.Settings.psd1',

        [Parameter(Mandatory=$false,HelpMessage='The folder to search for the graphical settings file.')]
        [System.String]$FolderToSearch = $Global:ApplicationObject.RootFolder
    )

    # PREPARATION
    # Get the full path to the graphical settings file
    [System.IO.FileInfo]$GraphicalSettingsFileObject = Get-ChildItem -Path $FolderToSearch -File -Filter $GraphicalSettingsFileName -Recurse

    # Check if the graphical settings file was found
    if ($GraphicalSettingsFileObject.Count -ne 1) {
        [System.String]$ErrorMessage = "The graphical settings file ($GraphicalSettingsFileName) was not found in folder ($FolderToSearch) or its subfolders. (Found $($GraphicalSettingsFileObject.Count) files.)"
        Write-Line $ErrorMessage -Type Error
        throw $ErrorMessage
    }

    # EXECUTION - IMPORT THE GRAPHICAL SETTINGS
    # Import the graphical settings from the Graphics Settings file
    Write-Line 'Importing graphical settings...'
    [System.Collections.Hashtable]$GraphicalSettings = Import-PowerShellDataFile -Path $GraphicalSettingsFileObject.FullName
    
    # EXECUTION - LOAD ASSEMBLIES
    # Load the assemblies
    Write-Line 'Loading assemblies...'
    $GraphicalSettings.Assemblies | ForEach-Object { Add-Type -AssemblyName $_ }

    # EXECUTION - ADD FONT
    # Set the font
    Write-Line 'Adding font...'
    [System.Drawing.Font]$MainFont = New-Object System.Drawing.Font($GraphicalSettings.MainFont.Name,$GraphicalSettings.MainFont.Size,[System.Drawing.FontStyle]::Bold)
    # Replace the MainFont in the GraphicalSettings hashtable with the actual Font object
    $GraphicalSettings.MainFont = $MainFont

    # EXECUTION - MAIN ICON
    # Get the full path to the main icon file
    [System.String]$MainIconFileName = $GraphicalSettings.MainForm.IconFileName
    [System.IO.FileInfo]$MainIconFileObject = Get-ChildItem -Path $FolderToSearch -File -Filter $MainIconFileName -Recurse
    # Check if the main icon file was found
    if ($MainIconFileObject.Count -ne 1) {
        [System.String]$ErrorMessage = "The main icon file ($MainIconFileName) was not found in folder ($FolderToSearch) or its subfolders. (Found $($MainIconFileObject.Count) files.)"
        Write-Line $ErrorMessage -Type Error
        throw $ErrorMessage
    }
    # Replace the MainIcon in the GraphicalSettings hashtable with the actual Icon object
    Write-Line 'Setting main icon...'
    [System.Drawing.Icon]$MainIcon = New-Object System.Drawing.Icon($MainIconFileObject.FullName)
    $GraphicalSettings.MainIcon = $MainIcon

    # EXECUTION - SET MAIN FORM PROPERTIES
    # Add the GraphicalSettings hashtable to the main object
    $Global:ApplicationObject | Add-Member -NotePropertyName GraphicalSettings -NotePropertyValue $GraphicalSettings

}

### END OF FUNCTION
####################################################################################################
