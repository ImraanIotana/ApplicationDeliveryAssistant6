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
        # Import and attach application settings to the ApplicationObject
        Import-ApplicationSettings -InputObject $InputObject
        # Initialize the User Settings
        Initialize-UserSettings -InputObject $InputObject
        # Initialize the graphics
        Initialize-Graphics -InputObject $InputObject
        # Show the Main Form
        Show-MainForm -InputObject $InputObject       
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}

# END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Imports an application settings data file and attaches it to the ApplicationObject.
.DESCRIPTION
    This function locates a PowerShell data file, imports it, and adds it to the provided
    ApplicationObject as a NoteProperty.
.EXAMPLE
    Import-ApplicationSettings -InputObject $ApplicationObject -SettingsFileName 'Settings.UserSettings.psd1' -OutputPropertyName 'UserSettings'
.INPUTS
    [PSCustomObject]
    [System.String]
    [System.String]
.OUTPUTS
    [System.Collections.Hashtable] The imported settings hashtable.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. All rights reserved.
    Version         : 6.0.0.0
    Author          : Imraan Iotana
    Creation Date   : May 2026
    Last Update     : May 2026
#>
####################################################################################################
function Import-ApplicationSettings {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The ApplicationObject containing the settings.')]
        [PSCustomObject]$InputObject,

        [Parameter(Mandatory=$false,HelpMessage='The name of the settings file to import.')]
        [System.String]$SettingsFileName = 'Settings.ApplicationSettings.psd1'
    )

    try {
        # PREPARATION
        # Get the full path to the settings file
        [System.String]$FolderToSearch = $InputObject.RootFolder
        [System.IO.FileInfo]$SettingsFileObject = Get-ChildItem -Path $FolderToSearch -File -Filter $SettingsFileName -Recurse

        # VALIDATION
        # Check if the settings file was found
        if ($SettingsFileObject.Count -ne 1) {
            throw "The settings file ($SettingsFileName) was not found in folder ($FolderToSearch) or its subfolders. (Found $($SettingsFileObject.Count) files.)"
        }

        # EXECUTION
        # Import the settings from the data file
        [System.Collections.Hashtable]$ApplicationSettings = Import-PowerShellDataFile -Path $SettingsFileObject.FullName
        # Add the settings hashtable to the main object
        $InputObject | Add-Member -NotePropertyName ApplicationSettings -NotePropertyValue $ApplicationSettings -Force
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}

# END OF FUNCTION
####################################################################################################
