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
        # Get the full path to the settings file
        [System.String]$FolderToSearch = $InputObject.RootFolder
        [System.IO.FileInfo]$SettingsFileObject = Get-ChildItem -Path $FolderToSearch -File -Filter $SettingsFileName -Recurse

        # Check if the settings file was found
        if ($SettingsFileObject.Count -ne 1) {
            throw "The settings file ($SettingsFileName) was not found in folder ($FolderToSearch) or its subfolders. (Found $($SettingsFileObject.Count) files.)"
        }

        # Import the settings from the data file
        Write-Line "Importing application settings from ($SettingsFileName)..."
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
        [PSCustomObject]$InputObject
    )

    try {
        # PREPARATION
        # Set the Registry path for the User Settings
        [System.String]$UserSettingsRegistryPath = $InputObject.ApplicationSettings.UserSettingsRegistryPath

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


####################################################################################################
<#
.SYNOPSIS
    Sets a specific User Setting value in the registry.
.DESCRIPTION
    This function writes a single User Setting value to the configured User Settings registry path.
.EXAMPLE
    Set-UserSetting -InputObject $ApplicationObject -PropertyName 'Theme' -PropertyValue 'Light'
.INPUTS
    [PSCustomObject]
    [System.String]
    [System.String]
.OUTPUTS
    [System.String] The value that was written for the requested User Setting.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. All rights reserved.
    Version         : 6.0.0.0
    Author          : Imraan Iotana
    Creation Date   : May 2026
    Last Update     : May 2026
#>
####################################################################################################
function Set-UserSetting {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The ApplicationObject containing the settings.')]
        [PSCustomObject]$InputObject,

        [Parameter(Mandatory=$true,HelpMessage='The name of the User Setting to set.')]
        [System.String]$PropertyName,

        [Parameter(Mandatory=$false,HelpMessage='The value of the User Setting to set.')]
        [System.String]$PropertyValue
    )

    try {
        # PREPARATION
        # Set the Registry path for the User Settings
        [System.String]$UserSettingsRegistryPath = $InputObject.ApplicationSettings.UserSettingsRegistryPath

        # VALIDATION
        # Ensure the registry path exists before attempting to get the value
        if (-not (Test-Path -Path $UserSettingsRegistryPath)) {
            throw "The User Settings registry path ($UserSettingsRegistryPath) does not exist."
        }

        # EXECUTION
        # Set the value of the requested User Setting in the registry
        Set-ItemProperty -Path $UserSettingsRegistryPath -Name $PropertyName -Value $PropertyValue -Force -ErrorAction Stop
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
    Gets a specific User Setting value from the registry.
.DESCRIPTION
    This function reads a single User Setting value from the configured User Settings registry path.
.EXAMPLE
    Get-UserSetting -InputObject $ApplicationObject -PropertyName 'Theme'
.INPUTS
    [PSCustomObject]
    [System.String]
.OUTPUTS
    [System.String] The value of the requested User Setting.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. All rights reserved.
    Version         : 6.0.0.0
    Author          : Imraan Iotana
    Creation Date   : May 2026
    Last Update     : May 2026
#>
####################################################################################################
function Get-UserSetting {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The ApplicationObject containing the settings.')]
        [PSCustomObject]$InputObject,

        [Parameter(Mandatory=$true,HelpMessage='The name of the User Setting to retrieve.')]
        [System.String]$PropertyName
    )

    try {
        # PREPARATION
        # Set the Registry path for the User Settings
        [System.String]$UserSettingsRegistryPath = $InputObject.ApplicationSettings.UserSettingsRegistryPath

        # VALIDATION
        # Ensure the registry path exists before attempting to get the value
        if (-not (Test-Path -Path $UserSettingsRegistryPath)) {
            throw "The User Settings registry path ($UserSettingsRegistryPath) does not exist."
        }

        # EXECUTION
        try {
            # Get the value of the requested User Setting from the registry
            [System.String]$UserSettingValue = Get-ItemPropertyValue -Path $UserSettingsRegistryPath -Name $PropertyName -ErrorAction SilentlyContinue
        }
        catch [System.Management.Automation.PSArgumentException] {
            # The property does not exist in the registry
            [System.String]$UserSettingValue = $null
        }
        # Return the value of the requested User Setting
        $UserSettingValue
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}

# END OF FUNCTION
####################################################################################################

