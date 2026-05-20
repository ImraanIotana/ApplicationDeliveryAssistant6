function Get-InstalledApplicationsFromRegistry {
    [CmdletBinding()]
    param (
        # Toon ook entries zonder UninstallString (optioneel)
        [switch]$IncludeIncomplete,

        # Toon ook SystemComponent entries (meestal Windows-onderdelen)
        [switch]$IncludeSystemComponents
    )

    # Alle relevante uninstall-locaties
    $registryPaths = @(
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
            Architecture = 'CurrentUser'
            Scope        = 'User'
        }
    )

    $results = foreach ($reg in $registryPaths) {

        Get-ItemProperty -Path $reg.Path -ErrorAction SilentlyContinue |
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
        } |
        ForEach-Object {

            # Build a rich object (data model)
            [PSCustomObject]@{
                DisplayName       = $_.DisplayName
                DisplayVersion    = $_.DisplayVersion
                Publisher         = $_.Publisher
                InstallLocation   = $_.InstallLocation
                InstallDate       = $_.InstallDate
                UninstallString   = $_.UninstallString
                QuietUninstall    = $_.QuietUninstallString
                EstimatedSizeKB   = $_.EstimatedSize
                Architecture      = $reg.Architecture
                Scope             = $reg.Scope
                RegistryPath      = $_.PSPath          # Unique identifier
                RegistryKeyName   = $_.PSChildName     # Often a GUID for MSI
                SystemComponent   = $_.SystemComponent
                WindowsInstaller  = $_.WindowsInstaller
            }
        }
    }

    # Sort neatly for UI usage
    $results | Sort-Object DisplayName
}