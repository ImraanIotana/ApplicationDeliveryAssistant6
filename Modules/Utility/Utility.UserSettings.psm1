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
        [System.String]$UserSettingsRegistryPath = $InputObject.UserSettings.RegistryPath

        # VALIDATION
        # Ensure the registry path exists before attempting to get the value
        if (-not (Test-Path -Path $UserSettingsRegistryPath)) {
            throw "The User Settings registry path ($UserSettingsRegistryPath) does not exist."
        }

        # EXECUTION
        # Set the value of the requested User Setting in the registry
        Set-ItemProperty -Path $UserSettingsRegistryPath -Name $PropertyName -Value $PropertyValue -Force -ErrorAction Stop

        # Return the value that was written
        #return (Get-ItemPropertyValue -Path $UserSettingsRegistryPath -Name $PropertyName -ErrorAction Stop)
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
        [System.String]$UserSettingsRegistryPath = $InputObject.UserSettings.RegistryPath

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

