####################################################################################################
<#
.SYNOPSIS
    Gets installed web browser executable paths from Windows registrations and known locations.
.DESCRIPTION
    This function queries StartMenuInternet registrations and common vendor installation paths without recursively scanning the file system.
.EXAMPLE
    Get-InstalledWebBrowserExecutablePaths
.OUTPUTS
    [System.String[]]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.3.1
    Author          : Imraan Iotana
    Creation Date   : August 2026
    Last Update     : August 2026
#>
####################################################################################################
function Get-InstalledWebBrowserExecutablePaths {
    [CmdletBinding()]
    [OutputType([System.String[]])]
    param ()

    try {
        # PREPARATION - REGISTERED AND KNOWN BROWSER LOCATIONS
        [System.Collections.Generic.List[System.String]]$CandidatePaths = New-Object 'System.Collections.Generic.List[System.String]'
        [System.String[]]$BrowserRegistrationRoots = @(
            'HKLM:\SOFTWARE\Clients\StartMenuInternet'
            'HKLM:\SOFTWARE\WOW6432Node\Clients\StartMenuInternet'
            'HKCU:\SOFTWARE\Clients\StartMenuInternet'
        )

        # EXECUTION - REGISTERED BROWSER DISCOVERY
        foreach ($RegistrationRoot in $BrowserRegistrationRoots) {
            if (-not (Test-Path -LiteralPath $RegistrationRoot -PathType Container)) { continue }

            foreach ($BrowserRegistration in (Get-ChildItem -LiteralPath $RegistrationRoot -ErrorAction SilentlyContinue)) {
                [System.String]$OpenCommandKey = Join-Path -Path $BrowserRegistration.PSPath -ChildPath 'shell\open\command'
                if (-not (Test-Path -LiteralPath $OpenCommandKey -PathType Container)) { continue }

                [System.String]$OpenCommand = [System.String](Get-ItemPropertyValue -LiteralPath $OpenCommandKey -Name '(default)' -ErrorAction SilentlyContinue)
                [System.String]$ExecutablePath = Resolve-ExecutablePathFromCommand -Command $OpenCommand
                if (Test-String -IsPopulated $ExecutablePath) { [void]$CandidatePaths.Add($ExecutablePath) }
            }
        }

        [System.String[]]$KnownBrowserRelativePaths = @(
            'Microsoft\Edge\Application\msedge.exe'
            'Google\Chrome\Application\chrome.exe'
            'Mozilla Firefox\firefox.exe'
            'BraveSoftware\Brave-Browser\Application\brave.exe'
            'Opera\launcher.exe'
            'Opera GX\launcher.exe'
        )
        [System.String[]]$KnownBrowserRoots = @(
            [System.Environment]::GetEnvironmentVariable('ProgramW6432')
            [System.Environment]::GetEnvironmentVariable('ProgramFiles')
            [System.Environment]::GetEnvironmentVariable('ProgramFiles(x86)')
            [System.Environment]::GetEnvironmentVariable('LOCALAPPDATA')
        ) | Where-Object { Test-String -IsPopulated $_ }

        # EXECUTION - KNOWN LOCATION DISCOVERY
        foreach ($BrowserRoot in $KnownBrowserRoots) {
            foreach ($RelativePath in $KnownBrowserRelativePaths) {
                [System.String]$CandidatePath = Join-Path -Path $BrowserRoot -ChildPath $RelativePath
                if (Test-Path -LiteralPath $CandidatePath -PathType Leaf) { [void]$CandidatePaths.Add($CandidatePath) }
            }
        }

        # OUTPUT - VERIFIED UNIQUE EXECUTABLES
        return @($CandidatePaths |
            Where-Object { (Test-String -IsPopulated $_) -and (Test-Path -LiteralPath $_ -PathType Leaf) } |
            Sort-Object -Unique)
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
        return @()
    }
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Resolves an executable path from a registered application command.
.OUTPUTS
    [System.String]
#>
####################################################################################################
function Resolve-ExecutablePathFromCommand {
    [CmdletBinding()]
    [OutputType([System.String])]
    param (
        [Parameter(Mandatory=$false)]
        [AllowEmptyString()]
        [System.String]$Command
    )

    # VALIDATION - REGISTERED COMMAND
    if (Test-String -IsEmpty $Command) { return $null }

    # PREPARATION - NORMALIZED EXECUTABLE PATH
    [System.String]$ExpandedCommand = [System.Environment]::ExpandEnvironmentVariables($Command).Trim()
    [System.String]$ExecutablePath = $null
    if ($ExpandedCommand -match '^"([^\"]+\.exe)"') {
        $ExecutablePath = $Matches[1]
    }
    elseif ($ExpandedCommand -match '^(.+?\.exe)(?:\s|$)') {
        $ExecutablePath = $Matches[1].Trim('"')
    }

    # OUTPUT - VERIFIED EXECUTABLE
    if ((Test-String -IsPopulated $ExecutablePath) -and (Test-Path -LiteralPath $ExecutablePath -PathType Leaf)) {
        return $ExecutablePath
    }
    return $null
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Gets installed executable paths for supported Microsoft Office applications.
.DESCRIPTION
    Resolves all supported Office executables through Windows App Paths registrations and known Microsoft Office installation folders.
.OUTPUTS
    [System.String[]]
#>
####################################################################################################
function Get-InstalledOfficeApplicationExecutablePaths {
    [CmdletBinding()]
    [OutputType([System.String[]])]
    param ()

    # PREPARATION - SUPPORTED OFFICE EXECUTABLES
    [System.Collections.Hashtable]$ExecutableNames = @{
        'Microsoft Access'     = 'MSACCESS.EXE'
        'Microsoft Excel'      = 'EXCEL.EXE'
        'Microsoft OneNote'    = 'ONENOTE.EXE'
        'Microsoft Outlook'    = 'OUTLOOK.EXE'
        'Microsoft PowerPoint' = 'POWERPNT.EXE'
        'Microsoft Project'    = 'WINPROJ.EXE'
        'Microsoft Publisher'  = 'MSPUB.EXE'
        'Microsoft Visio'      = 'VISIO.EXE'
        'Microsoft Word'       = 'WINWORD.EXE'
    }
    [System.Collections.Generic.List[System.String]]$CandidatePaths = New-Object 'System.Collections.Generic.List[System.String]'

    # EXECUTION - APP PATHS DISCOVERY
    [System.String[]]$AppPathRoots = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths'
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\App Paths'
        'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths'
    )
    foreach ($ExecutableName in $ExecutableNames.Values) {
        foreach ($AppPathRoot in $AppPathRoots) {
            [System.String]$RegistrationPath = Join-Path -Path $AppPathRoot -ChildPath $ExecutableName
            [System.String]$RegisteredExecutable = [System.String](Get-ItemPropertyValue -LiteralPath $RegistrationPath -Name '(default)' -ErrorAction SilentlyContinue)
            if (Test-String -IsPopulated $RegisteredExecutable) {
                $RegisteredExecutable = [System.Environment]::ExpandEnvironmentVariables($RegisteredExecutable).Trim('"')
                if (Test-Path -LiteralPath $RegisteredExecutable -PathType Leaf) { [void]$CandidatePaths.Add($RegisteredExecutable) }
            }
        }
    }

    # EXECUTION - KNOWN OFFICE LOCATION DISCOVERY
    [System.String[]]$OfficeRoots = @(
        [System.Environment]::GetEnvironmentVariable('ProgramW6432')
        [System.Environment]::GetEnvironmentVariable('ProgramFiles')
        [System.Environment]::GetEnvironmentVariable('ProgramFiles(x86)')
    ) | Where-Object { Test-String -IsPopulated $_ } | Sort-Object -Unique
    [System.String[]]$OfficeRelativeFolders = @(
        'Microsoft Office\root\Office16'
        'Microsoft Office\Office16'
        'Microsoft Office\Office15'
        'Microsoft Office\Office14'
    )
    foreach ($ExecutableName in $ExecutableNames.Values) {
        foreach ($OfficeRoot in $OfficeRoots) {
            foreach ($OfficeRelativeFolder in $OfficeRelativeFolders) {
                [System.String]$CandidatePath = Join-Path -Path (Join-Path -Path $OfficeRoot -ChildPath $OfficeRelativeFolder) -ChildPath $ExecutableName
                if (Test-Path -LiteralPath $CandidatePath -PathType Leaf) { [void]$CandidatePaths.Add($CandidatePath) }
            }
        }
    }

    # OUTPUT - UNIQUE OFFICE EXECUTABLES
    return @($CandidatePaths | Sort-Object -Unique)
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Updates the executable selector with applications appropriate for the selected application type.
.OUTPUTS
    No objects are returned to the pipeline.
#>
####################################################################################################
function Update-CustomApplicationExecutableCandidates {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [System.Windows.Forms.ComboBox]$ApplicationTypeComboBox,

        [Parameter(Mandatory=$true)]
        [System.Windows.Forms.ComboBox]$ApplicationExecutableComboBox
    )

    try {
        # VALIDATION - SELECTED APPLICATION TYPE
        [System.String]$ApplicationType = [System.String]$ApplicationTypeComboBox.Text
        if (Test-String -IsEmpty $ApplicationType) {
            Write-Line 'Select an Application Type before finding applications.' -Type Warning
            return
        }

        if ($ApplicationType -eq 'Custom Application') {
            Write-Line 'Use Browse File to select the executable for a Custom Application.' -Type Info
            return
        }

        # EXECUTION - TYPE-SPECIFIC DISCOVERY
        [System.String[]]$ExecutablePaths = switch ($ApplicationType) {
            'Web Application'   { @(Get-InstalledWebBrowserExecutablePaths); break }
            'Office Application' { @(Get-InstalledOfficeApplicationExecutablePaths); break }
            default {
                Write-Line "Application discovery is not available for type: ($ApplicationType)" -Type Warning
                return
            }
        }

        if ($ExecutablePaths.Count -eq 0) {
            Write-Line "No installed applications were found for type: ($ApplicationType)" -Type Warning
            return
        }

        # POST-EXECUTION - REFRESH SELECTOR
        Update-ComboBox -ComboBox $ApplicationExecutableComboBox -ContentStringArray $ExecutablePaths -PreservePreviousSelection
        Write-Line "Found $($ExecutablePaths.Count) application executable(s) for type: ($ApplicationType)" -Type Success
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}

### END OF FUNCTION
####################################################################################################