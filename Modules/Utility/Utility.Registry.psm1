####################################################################################################
<#
.SYNOPSIS
    Starts the Registry Editor with specific keys based on the provided parameters.
.DESCRIPTION
    This function starts the Registry Editor (regedit.exe) and can optionally set the last opened key to a specific location before launching.
    The key to open can be specified using the parameters, allowing for quick access to commonly used registry locations.
.EXAMPLE
    Start-RegistryEditor
.EXAMPLE
    Start-RegistryEditor -UninstallKey32bit
.EXAMPLE
    Start-RegistryEditor -UninstallKey64bit
.INPUTS
    [System.Management.Automation.SwitchParameter]
.OUTPUTS
    No objects are returned to the pipeline. All output is written to the host.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. All rights reserved.
    Version         : 6.0.0.0
    Author          : Imraan Iotana
    Creation Date   : February 2026
    Last Update     : May 2026
#>
####################################################################################################
function Start-RegistryEditor {
    [CmdletBinding(DefaultParameterSetName='None')]
    param (
        [Parameter(Mandatory=$false,ParameterSetName='ApplicationSettingsKey',HelpMessage='The ApplicationObject containing the Settings.')]
        [PSCustomObject]$InputObject,

        [Parameter(Mandatory=$false,ParameterSetName='UninstallKey64bit',HelpMessage='Open the 64-bit Uninstall key.')]
        [System.Management.Automation.SwitchParameter]$UninstallKey64bit,

        [Parameter(Mandatory=$false,ParameterSetName='UninstallKey32bit',HelpMessage='Open the 32-bit Uninstall key.')]
        [System.Management.Automation.SwitchParameter]$UninstallKey32bit,
        
        [Parameter(Mandatory=$false,ParameterSetName='PowerShellPolicyKey',HelpMessage='Open the PowerShell policy key.')]
        [System.Management.Automation.SwitchParameter]$PowerShellPolicyKey,

        [Parameter(Mandatory=$false,ParameterSetName='LastOpenedSettingKey',HelpMessage='Open the last-opened-setting key.')]
        [System.Management.Automation.SwitchParameter]$LastOpenedSettingKey,

        [Parameter(Mandatory=$false,ParameterSetName='ApplicationSettingsKey',HelpMessage='Open the 64-bit Uninstall key.')]
        [System.Management.Automation.SwitchParameter]$ApplicationSettingsKey,

        [Parameter(Mandatory=$false,ParameterSetName='CustomKey',HelpMessage='Open regedit at a specific key.')]
        [System.String]$Key
    )

    try {
        # PREPARATION - DEFINE VARIABLES
        # Define a hashtable to store the registry paths for different keys
        [System.Collections.Hashtable]$Context = @{
            UninstallKey64bit       = 'Computer\HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall'
            UninstallKey32bit       = 'Computer\HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall'
            PowerShellPolicyKey     = 'Computer\HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\PowerShell\1\ShellIds\Microsoft.PowerShell'
            LastOpenedSettingKey    = 'Computer\HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Applets\Regedit'
        }
        # Set the registry key that contains the last opened key value for regedit
        [System.String]$KeyContainingLastOpenedKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Applets\Regedit'

        # PREPARATION - MAKE KEY COMPATIBLE WITH REGEDIT
        # If the custom key parameter is used, convert it to the format used by regedit for the last opened key
        if ($PSCmdlet.ParameterSetName -eq 'CustomKey') {
            [system.string]$PrefixToReplace = 'Microsoft.PowerShell.Core\Registry::'
            if ($Key.StartsWith($PrefixToReplace)) {
                $Key = $Key.Replace($PrefixToReplace, 'Computer\')
            }
        }
        # Add the custom key to the context for easier access later
        $Context.CustomKey = $Key

        # PREPARATION - DETERMINE LAST OPENED KEY
        # Determine which key to open
        [System.String]$LastKeyValue = switch ($PSCmdlet.ParameterSetName) {
            'UninstallKey64bit'         { $Context.UninstallKey64bit }
            'UninstallKey32bit'         { $Context.UninstallKey32bit }
            'PowerShellPolicyKey'       { $Context.PowerShellPolicyKey }
            'LastOpenedSettingKey'      { $Context.LastOpenedSettingKey }
            'CustomKey'                 { $Context.CustomKey }
            'ApplicationSettingsKey'    {
                # Get the User Settings registry path from the Application Settings
                [System.String]$UserSettingsRegistryPath = $InputObject.ApplicationSettings.UserSettingsRegistryPath
                # Convert the User Settings registry path to the format used by regedit for the last opened key
                [System.String]$UserSettingsRegistryPathForRegedit = $UserSettingsRegistryPath.Replace('HKCU:\','Computer\HKEY_CURRENT_USER\')
                # Return the converted registry path
                $UserSettingsRegistryPathForRegedit
            }
            Default                     { [System.String]::Empty }
        }

        # PREPARATION - SET LAST OPENED KEY
        # If a specific key is requested, set it as the last opened key in regedit
        if (Test-String -IsPopulated $LastKeyValue) { Set-ItemProperty -Path $KeyContainingLastOpenedKey -Name 'LastKey' -Value $LastKeyValue -Force }

        # EXECUTION
        # Start the Registry Editor
        Write-Line "Starting the Registry Editor at the key: ($LastKeyValue)"
        Start-Process regedit.exe
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Converts a registry key path into a PowerShell registry provider path.
.DESCRIPTION
    This function normalizes registry key paths from multiple formats (provider-qualified, short hive,
    and long hive formats) into a provider-compatible path such as HKLM:\Software\....
.EXAMPLE
    Convert-RegistryKey -RegistryKeyPath 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\Software\MyCompany'
.INPUTS
    [System.String]
.OUTPUTS
    [System.String] The normalized registry provider path.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. All rights reserved.
    Version         : 6.0.0.0
    Author          : Imraan Iotana
    Creation Date   : May 2026
    Last Update     : May 2026
#>
####################################################################################################
function Convert-RegistryKey {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The registry key path to normalize.')]
        [System.String]$RegistryKeyPath
    )

    try {
        # PREPARATION - NORMALIZE INPUT TEXT
        [System.String]$NormalizedRegistryKeyPath = $RegistryKeyPath.Trim()

        # Handle provider-qualified paths (for example: Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\...).
        if ($NormalizedRegistryKeyPath -match '^Microsoft\.PowerShell\.Core\\Registry::') {
            $NormalizedRegistryKeyPath = $NormalizedRegistryKeyPath -replace '^Microsoft\.PowerShell\.Core\\Registry::',''
        }
        elseif ($NormalizedRegistryKeyPath -match '^Registry::') {
            $NormalizedRegistryKeyPath = $NormalizedRegistryKeyPath -replace '^Registry::',''
        }

        # EXECUTION - MAP TO PROVIDER-COMPATIBLE HIVE PREFIXES
        [System.String]$ProviderPath = switch -Regex ($NormalizedRegistryKeyPath) {
            '^HKLM:\\' { $NormalizedRegistryKeyPath }
            '^HKCU:\\' { $NormalizedRegistryKeyPath }
            '^HKCR:\\' { $NormalizedRegistryKeyPath }
            '^HKU:\\'  { $NormalizedRegistryKeyPath }
            '^HKCC:\\' { $NormalizedRegistryKeyPath }
            '^HKLM\\' { $NormalizedRegistryKeyPath -replace '^HKLM\\','HKLM:\\' }
            '^HKCU\\' { $NormalizedRegistryKeyPath -replace '^HKCU\\','HKCU:\\' }
            '^HKCR\\' { $NormalizedRegistryKeyPath -replace '^HKCR\\','HKCR:\\' }
            '^HKU\\'  { $NormalizedRegistryKeyPath -replace '^HKU\\','HKU:\\' }
            '^HKCC\\' { $NormalizedRegistryKeyPath -replace '^HKCC\\','HKCC:\\' }
            '^HKEY_LOCAL_MACHINE\\' { $NormalizedRegistryKeyPath -replace '^HKEY_LOCAL_MACHINE\\','HKLM:\\' }
            '^HKEY_CURRENT_USER\\' { $NormalizedRegistryKeyPath -replace '^HKEY_CURRENT_USER\\','HKCU:\\' }
            '^HKEY_CLASSES_ROOT\\' { $NormalizedRegistryKeyPath -replace '^HKEY_CLASSES_ROOT\\','HKCR:\\' }
            '^HKEY_USERS\\' { $NormalizedRegistryKeyPath -replace '^HKEY_USERS\\','HKU:\\' }
            '^HKEY_CURRENT_CONFIG\\' { $NormalizedRegistryKeyPath -replace '^HKEY_CURRENT_CONFIG\\','HKCC:\\' }
            default { throw "Unsupported registry path format: ($RegistryKeyPath)" }
        }

        $ProviderPath
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Retrieves a list of installed applications from the Windows registry.
.DESCRIPTION
    This function queries the Windows registry to gather information about installed applications.
    It can include incomplete entries and system components based on the provided parameters.
.EXAMPLE
    Get-InstalledApplicationsFromRegistry
.INPUTS
    [System.Management.Automation.SwitchParameter]
.OUTPUTS
    [PSCustomObject[]]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. All rights reserved.
    Version         : 6.0.0.0
    Author          : Imraan Iotana
    Creation Date   : May 2026
    Last Update     : May 2026
#>
####################################################################################################
function Get-InstalledApplicationsFromRegistry {
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param (
        [Parameter(Mandatory=$false,HelpMessage='Include entries without an UninstallString.')]
        [System.Management.Automation.SwitchParameter]$IncludeIncomplete,

        [Parameter(Mandatory=$false,HelpMessage='Include SystemComponent entries (usually Windows components).')]
        [System.Management.Automation.SwitchParameter]$IncludeSystemComponents
    )

    # PREPARATION
    # Set up registry paths to query for installed applications
    [PSCustomObject[]]$KeysContainingUninstallInformation = @(
        @{
            Path         = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*'
            Architecture = 'x64'
            Scope        = 'Machine'
        },
        @{
            Path         = 'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
            Architecture = 'x86'
            Scope        = 'Machine'
        },
        @{
            Path         = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*'
            Architecture = 'User'
            Scope        = 'User'
        }
    )

    # EXECUTION
    # Query the registry and build a list of application objects
    [PSCustomObject[]]$ApplicationObjectsFromRegistry = foreach ($KeyContainingUninstallInformation in $KeysContainingUninstallInformation) {

        # Get all registry entries under the specified path, and filter them based on the presence of DisplayName, UninstallString, and SystemComponent properties
        [PSCustomObject[]]$Apps = Get-ItemProperty -Path $KeyContainingUninstallInformation.Path -ErrorAction SilentlyContinue |
        Where-Object {
            $_.DisplayName -and
            (
                $IncludeIncomplete -or
                $_.UninstallString
            ) -and
            (
                $IncludeSystemComponents -or
                $_.SystemComponent -ne 1
            )
        }

        # For each application found, create a rich object with all the relevant information
        $Apps | ForEach-Object {

            # Build a rich object (data model)
            [PSCustomObject]@{
                DisplayName         = $_.DisplayName
                DisplayVersion      = $_.DisplayVersion
                Publisher           = $_.Publisher
                InstallLocation     = $_.InstallLocation
                InstallDate         = $_.InstallDate
                UninstallString     = $_.UninstallString
                QuietUninstall      = $_.QuietUninstallString
                EstimatedSizeKB     = $_.EstimatedSize
                Architecture        = $KeyContainingUninstallInformation.Architecture
                Scope               = $KeyContainingUninstallInformation.Scope
                RegistryPath        = $_.PSPath          # Unique identifier
                RegistryKeyName     = $_.PSChildName     # Often a GUID for MSI
                SystemComponent     = $_.SystemComponent
                WindowsInstaller    = $_.WindowsInstaller
                # Create a unique name to show in the ComboBox
                ComboBoxName        = "[$($KeyContainingUninstallInformation.Architecture)] $($_.DisplayName)"
            }

        }
    }

    # OUTPUT
    # Sort the applications by the ComboBoxName for better user experience in the ComboBox, and output the result to the pipeline
    $ApplicationObjectsFromRegistry | Sort-Object DisplayName
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Exports a registry key (including subkeys and values) to a text file.
.DESCRIPTION
    This function uses Get-ItemProperty with Format-List and Out-File to export the specified
    registry key and all subkeys to a .txt file.
.EXAMPLE
    Export-RegistryKey -RegistryKeyPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall' -OutputFolder 'C:\Temp'
.INPUTS
    [System.String]
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
function Export-RegistryKey {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The registry key path to export (for example: HKLM:\SOFTWARE\...).')]
        [System.String]$RegistryKeyPath,

        [Parameter(Mandatory=$false,HelpMessage='Destination folder where the export text file will be created.')]
        [System.String]$OutputFolder = (Get-OutputFolder),

        [Parameter(Mandatory=$false,HelpMessage='Open the output folder after export.')]
        [System.Management.Automation.SwitchParameter]$OpenOutputFolder
    )

    try {
        # PREPARATION - VALIDATE OUTPUT FOLDER
        if (-not (Test-String -IsPopulated $OutputFolder)) {
            throw 'The output folder must be provided.'
        }

        if (-not (Test-Path -LiteralPath $OutputFolder)) {
            New-Item -Path $OutputFolder -ItemType Directory -Force | Out-Null
        }

        # PREPARATION - NORMALIZE REGISTRY PATH FOR PROVIDER TESTS
        [System.String]$ProviderPath = Convert-RegistryKey -RegistryKeyPath $RegistryKeyPath

        if (-not (Test-Path -LiteralPath $ProviderPath)) {
            throw "The registry key path does not exist: ($RegistryKeyPath)"
        }

        # PREPARATION - BUILD OUTPUT FILE PATH FROM THE TARGET KEY NAME
        [System.String]$RootKeyName = Split-Path -Path ($ProviderPath.TrimEnd('\\')) -Leaf
        if (-not (Test-String -IsPopulated $RootKeyName)) {
            throw "Unable to derive a key name from the registry path: ($RegistryKeyPath)"
        }

        [System.String]$SanitizedRootKeyName = [System.String]::Join('_',($RootKeyName.Split([System.IO.Path]::GetInvalidFileNameChars(),[System.StringSplitOptions]::RemoveEmptyEntries)))
        if (-not (Test-String -IsPopulated $SanitizedRootKeyName)) {
            throw "Unable to build a valid file name from registry key name: ($RootKeyName)"
        }

        [System.String]$OutputFilePath = Join-Path -Path $OutputFolder -ChildPath "$SanitizedRootKeyName.txt"

        # EXECUTION
        if (Test-Path -LiteralPath $OutputFilePath) {
            Remove-Item -LiteralPath $OutputFilePath -Force
        }

        # Build a list containing the root key and all descendant keys.
        [System.String[]]$KeysToExport = @($ProviderPath)
        [System.String[]]$ChildKeys = @(Get-ChildItem -Path $ProviderPath -Recurse -ErrorAction SilentlyContinue | Select-Object -ExpandProperty PSPath)
        if ($ChildKeys.Count -gt 0) {
            $KeysToExport += $ChildKeys
        }

        foreach ($CurrentKeyPath in $KeysToExport) {
            "####################################################################################################" | Out-File -FilePath $OutputFilePath -Append -Encoding UTF8
            "RegistryKeyPath: $CurrentKeyPath" | Out-File -FilePath $OutputFilePath -Append -Encoding UTF8
            "" | Out-File -FilePath $OutputFilePath -Append -Encoding UTF8

            Get-ItemProperty -Path $CurrentKeyPath -ErrorAction SilentlyContinue |
            Format-List |
            Out-File -FilePath $OutputFilePath -Append -Encoding UTF8

            "" | Out-File -FilePath $OutputFilePath -Append -Encoding UTF8
        }

        Write-Line "Registry key exported to file: ($OutputFilePath)"

        # POST-EXECUTION - OPEN OUTPUT FOLDER
        if ($OpenOutputFolder) {
            Open-Folder -Path $OutputFolder
        }
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}

### END OF FUNCTION
####################################################################################################


