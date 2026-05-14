####################################################################################################
<#
.SYNOPSIS
    Initializes the User Settings for the Application Delivery Assistant.
.DESCRIPTION
    This function initializes the User Settings for the Application Delivery Assistant by creating the necessary registry keys if they do not already exist.
.EXAMPLE
    Initialize-UserSettings
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
function Initialize-UserSettings {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false,HelpMessage='The ApplicationObject containing the settings.')]
        [PSCustomObject]$InputObject,

        [Parameter(Mandatory=$false,HelpMessage='The name of the user settings file.')]
        [System.String]$UserSettingsFileName = 'Settings.UserSettings.psd1'
    )

    try {
        # PREPARATION
        # Get the full path to the user settings file
        [System.String]$FolderToSearch = $InputObject.RootFolder
        [System.IO.FileInfo]$UserSettingsFileObject = Get-ChildItem -Path $FolderToSearch -File -Filter $UserSettingsFileName -Recurse

        # Check if the user settings file was found
        if ($UserSettingsFileObject.Count -ne 1) {
            [System.String]$ErrorMessage = "The user settings file ($UserSettingsFileName) was not found in folder ($FolderToSearch) or its subfolders. (Found $($UserSettingsFileObject.Count) files.)"
            Write-Line $ErrorMessage -Type Error
            throw $ErrorMessage
        }

        # EXECUTION - IMPORT THE USER SETTINGS
        # Import the user settings from the User Settings file
        Write-Line 'Importing user settings...'
        [System.Collections.Hashtable]$UserSettings = Import-PowerShellDataFile -Path $UserSettingsFileObject.FullName
        # Add the UserSettings hashtable to the main object
        $InputObject | Add-Member -NotePropertyName UserSettings -NotePropertyValue $UserSettings

        # PREPARATION
        # Set the Registry path for the User Settings
        [System.String]$UserSettingsRegistryPath = $InputObject.UserSettings.RegistryPath

        # EXECUTION
        # Check if the User Settings registry key exists, and if not, create it
        Write-Line "Initializing User Settings..."
        if (-not (Test-Path -Path $UserSettingsRegistryPath)) {
            New-Item -Path $UserSettingsRegistryPath -Force | Out-Null
        }        
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}

# END OF FUNCTION
####################################################################################################
