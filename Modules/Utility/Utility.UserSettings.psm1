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
    No objects are returned to the pipeline.
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
    Determines whether a User Setting property should be stored as protected data.
.DESCRIPTION
    This function returns true for setting names that represent secrets, such as passwords.
.EXAMPLE
    Test-UserSettingIsSensitive -PropertyName 'TextBoxes.FTP.Credentials.Password'
.INPUTS
    [System.String]
.OUTPUTS
    [System.Boolean]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. All rights reserved.
    Version         : 6.0.0.0
    Author          : Imraan Iotana
    Creation Date   : June 2026
    Last Update     : June 2026
#>
####################################################################################################
function Test-UserSettingIsSensitive {
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The User Setting property name.')]
        [System.String]$PropertyName
    )

    # Consider any setting containing "Password" as sensitive.
    $PropertyName -match '(?i)password'
}

# END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Encrypts plain text using DPAPI for the current user.
.DESCRIPTION
    This function protects text with CurrentUser scope and returns a string prefixed with DPAPI:
    so callers can detect whether a setting is already protected.
.EXAMPLE
    Protect-UserSettingValue -PlainText 'secret'
.INPUTS
    [System.String]
.OUTPUTS
    [System.String]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. All rights reserved.
    Version         : 6.0.0.0
    Author          : Imraan Iotana
    Creation Date   : June 2026
    Last Update     : June 2026
#>
####################################################################################################
function Protect-UserSettingValue {
    [CmdletBinding()]
    [OutputType([System.String])]
    param (
        [Parameter(Mandatory=$false,HelpMessage='The plain text value to protect.')]
        [AllowNull()]
        [System.String]$PlainText
    )

    # Keep null values null so callers can clear settings without side effects.
    if ($null -eq $PlainText) { return $null }

    # Do not double-encrypt values that are already marked as protected.
    if ($PlainText.StartsWith('DPAPI:')) { return $PlainText }

    [System.Byte[]]$PlainBytes = [System.Text.Encoding]::UTF8.GetBytes($PlainText)
    [System.Byte[]]$ProtectedBytes = [System.Security.Cryptography.ProtectedData]::Protect($PlainBytes,$null,[System.Security.Cryptography.DataProtectionScope]::CurrentUser)
    'DPAPI:{0}' -f [System.Convert]::ToBase64String($ProtectedBytes)
}

# END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Decrypts a DPAPI-protected User Setting value.
.DESCRIPTION
    This function returns the decrypted plain text when the input starts with DPAPI:.
    If the value is not prefixed, it is treated as legacy plain text and returned unchanged.
.EXAMPLE
    Unprotect-UserSettingValue -StoredValue $ValueFromRegistry
.INPUTS
    [System.String]
.OUTPUTS
    [System.String]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. All rights reserved.
    Version         : 6.0.0.0
    Author          : Imraan Iotana
    Creation Date   : June 2026
    Last Update     : June 2026
#>
####################################################################################################
function Unprotect-UserSettingValue {
    [CmdletBinding()]
    [OutputType([System.String])]
    param (
        [Parameter(Mandatory=$false,HelpMessage='The value read from the registry.')]
        [AllowNull()]
        [System.String]$StoredValue
    )

    if ($null -eq $StoredValue) { return $null }
    if (-not $StoredValue.StartsWith('DPAPI:')) { return $StoredValue }

    [System.String]$CipherText = $StoredValue.Substring(6)
    [System.Byte[]]$ProtectedBytes = [System.Convert]::FromBase64String($CipherText)
    [System.Byte[]]$PlainBytes = [System.Security.Cryptography.ProtectedData]::Unprotect($ProtectedBytes,$null,[System.Security.Cryptography.DataProtectionScope]::CurrentUser)
    [System.Text.Encoding]::UTF8.GetString($PlainBytes)
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
        [Parameter(Mandatory=$false,HelpMessage='The ApplicationObject containing the settings.')]
        [PSCustomObject]$InputObject = $Global:ApplicationObject,

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
        # Protect sensitive values before writing to the registry.
        [System.String]$ValueToStore = if (Test-UserSettingIsSensitive -PropertyName $PropertyName) {
            Protect-UserSettingValue -PlainText $PropertyValue
        } else {
            $PropertyValue
        }
        # Set the value of the requested User Setting in the registry
        Set-ItemProperty -Path $UserSettingsRegistryPath -Name $PropertyName -Value $ValueToStore -Force -ErrorAction Stop
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
        [Parameter(Mandatory=$false,HelpMessage='The ApplicationObject containing the settings.')]
        [PSCustomObject]$InputObject = $Global:ApplicationObject,

        [Parameter(Mandatory=$false,HelpMessage='The name of the User Setting to retrieve.')]
        [System.String]$PropertyName
    )

    try {
        # VALIDATION
        # Ensure the PropertyName parameter is provided
        if (-not $PSBoundParameters.ContainsKey('PropertyName') -or (Test-String -IsEmpty $PropertyName)) {
            Write-Line "The Field / PropertyName is empty."
            return
        }
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
        # Decrypt sensitive values. Legacy plain text values are returned unchanged.
        if (Test-UserSettingIsSensitive -PropertyName $PropertyName) {
            [System.String]$UnprotectedValue = Unprotect-UserSettingValue -StoredValue $UserSettingValue

            # If a legacy plain text value is detected, rewrite it as protected data.
            if ((Test-String -IsPopulated $UserSettingValue) -and -not $UserSettingValue.StartsWith('DPAPI:')) {
                Set-UserSetting -InputObject $InputObject -PropertyName $PropertyName -PropertyValue $UnprotectedValue
            }

            return $UnprotectedValue
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


####################################################################################################
<#
.SYNOPSIS
    Gets the configured output folder path from User Settings.
.DESCRIPTION
    This function retrieves the saved output folder path from the configured User Settings registry path.
.EXAMPLE
    Get-OutputFolder
.INPUTS
    [PSCustomObject]
.OUTPUTS
    [System.String] The configured output folder path.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. All rights reserved.
    Version         : 6.0.0.0
    Author          : Imraan Iotana
    Creation Date   : May 2026
    Last Update     : May 2026
#>
####################################################################################################
function Get-OutputFolder {
    [CmdletBinding()]
    [OutputType([System.String])]
    param (
        [Parameter(Mandatory=$false,HelpMessage='The ApplicationObject containing the settings.')]
        [PSCustomObject]$InputObject = $Global:ApplicationObject,

        [Parameter(Mandatory=$false,HelpMessage='The name of the User Setting to retrieve.')]
        [System.String]$PropertyName = 'TextBoxes.ApplicationSettings.FolderSettings.UserOutputFolder'
    )

    try {
        # EXECUTION
        # Get the output folder path from User Settings.
        [System.String]$OutputFolder = Get-UserSetting -PropertyName $PropertyName

        # Return the output folder value.
        $OutputFolder
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
    Gets the configured software library folder path from User Settings.
.DESCRIPTION
    This function retrieves the saved software library folder path from the configured User Settings registry path.
.EXAMPLE
    Get-SoftwareLibraryFolder
.INPUTS
    [PSCustomObject]
.OUTPUTS
    [System.String] The configured software library folder path.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. All rights reserved.
    Version         : 6.0.0.0
    Author          : Imraan Iotana
    Creation Date   : May 2026
    Last Update     : May 2026
#>
####################################################################################################
function Get-SoftwareLibraryFolder {
    [CmdletBinding()]
    [OutputType([System.String])]
    param (
        [Parameter(Mandatory=$false,HelpMessage='The ApplicationObject containing the settings.')]
        [PSCustomObject]$InputObject = $Global:ApplicationObject,

        [Parameter(Mandatory=$false,HelpMessage='The name of the User Setting to retrieve.')]
        [System.String]$PropertyName = 'TextBoxes.ApplicationSettings.FolderSettings.SoftwareLibrary'
    )

    try {
        # EXECUTION
        # Get the software library folder path from User Settings.
        [System.String]$SofwareLibraryFolder = Get-UserSetting -PropertyName $PropertyName

        # Return the software library folder value.
        $SofwareLibraryFolder
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}

# END OF FUNCTION
####################################################################################################
