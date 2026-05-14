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
    param ()

    try {
        # PREPARATION
        # Set the Registry path for the User Settings
        [System.String]$UserSettingsRegistryPath = 'HKCU:\Software\Iotana Application Delivery Assistant\UserSettings'

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
