####################################################################################################
<#
.SYNOPSIS
    Provides the Service Management inventory and filter helpers.
.DESCRIPTION
    Enumerates the Windows services into normalized objects and filters them by search term, status,
    startup type, origin and recent installation.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.10.0
    Author          : Imraan Iotana
    Creation Date   : October 2026
    Last Update     : October 2026
#>
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Returns the executable path from the PathName of a service.
.DESCRIPTION
    Removes the quotes and the command line arguments from the PathName of a service, and expands
    environment variables. An empty string is returned when no path can be determined.
.EXAMPLE
    Get-ServiceExecutablePath -PathName '"C:\Windows\System32\svchost.exe" -k netsvcs -p'
.INPUTS
    [System.String]
.OUTPUTS
    [System.String]
#>
####################################################################################################
function Get-ServiceExecutablePath {
    [CmdletBinding()]
    [OutputType([System.String])]
    param (
        [Parameter(Mandatory=$false,HelpMessage='The PathName of the service, including quotes and arguments.')]
        [AllowNull()][AllowEmptyString()]
        [System.String]$PathName
    )

    if ([System.String]::IsNullOrWhiteSpace($PathName)) { return '' }

    [System.String]$ExecutablePath = $PathName.Trim()
    if ($ExecutablePath.StartsWith('"')) {
        [System.Int32]$ClosingQuoteIndex = $ExecutablePath.IndexOf('"', 1)
        $ExecutablePath = if ($ClosingQuoteIndex -gt 0) { $ExecutablePath.Substring(1, ($ClosingQuoteIndex - 1)) } else { $ExecutablePath.Substring(1) }
    }
    elseif ($ExecutablePath -match '^(?<Path>.+?\.(exe|dll|sys))(\s|$)') {
        $ExecutablePath = $Matches.Path
    }

    [System.Environment]::ExpandEnvironmentVariables($ExecutablePath.Trim())
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Returns the startup type text of a service.
.DESCRIPTION
    Converts the StartMode and the DelayedAutoStart values of a Win32_Service object into the text
    that is shown in Service Management.
.EXAMPLE
    Get-ServiceStartupTypeText -StartMode 'Auto' -DelayedAutoStart $true
.INPUTS
    [System.String]
    [System.Boolean]
.OUTPUTS
    [System.String]
#>
####################################################################################################
function Get-ServiceStartupTypeText {
    [CmdletBinding()]
    [OutputType([System.String])]
    param (
        [Parameter(Mandatory=$false,HelpMessage='The StartMode of the service.')]
        [AllowNull()][AllowEmptyString()]
        [System.String]$StartMode,

        [Parameter(Mandatory=$false,HelpMessage='Indicates whether the automatic service starts delayed.')]
        [AllowNull()]
        [System.Boolean]$DelayedAutoStart
    )

    switch ($StartMode) {
        'Auto'      { if ($DelayedAutoStart) { 'Automatic (Delayed Start)' } else { 'Automatic' } }
        'Manual'    { 'Manual' }
        'Disabled'  { 'Disabled' }
        'Boot'      { 'Boot' }
        'System'    { 'System' }
        default     { 'Unknown' }
    }
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Returns the inventory of the Windows services.
.DESCRIPTION
    Enumerates the Windows services and returns one normalized object per service. The origin of a
    service is Microsoft when the company name of its executable starts with Microsoft, otherwise
    Non-Microsoft. The install date is the creation date of the executable.
.EXAMPLE
    Get-ServiceInventory
.OUTPUTS
    [PSCustomObject[]]
#>
####################################################################################################
function Get-ServiceInventory {
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param ()

    try {
        # PREPARATION
        # Cache the file information per executable, because many services share one executable
        [System.Collections.Hashtable]$FileInformationCache = @{}
        [System.Globalization.CultureInfo]$InvariantCulture = [System.Globalization.CultureInfo]::InvariantCulture

        # EXECUTION - INVENTORY
        [PSCustomObject[]]$Inventory = foreach ($Service in @(Get-CimInstance -ClassName Win32_Service -ErrorAction Stop)) {
            [System.String]$ExecutablePath = Get-ServiceExecutablePath -PathName $Service.PathName

            if (-not $FileInformationCache.ContainsKey($ExecutablePath)) {
                [System.String]$Company = ''
                [System.Nullable[System.DateTime]]$InstallDate = $null
                if ((-not [System.String]::IsNullOrWhiteSpace($ExecutablePath)) -and [System.IO.File]::Exists($ExecutablePath)) {
                    try {
                        $Company = [System.String][System.Diagnostics.FileVersionInfo]::GetVersionInfo($ExecutablePath).CompanyName
                        $InstallDate = [System.IO.File]::GetCreationTime($ExecutablePath)
                    }
                    catch {
                        $Company = ''
                    }
                }
                $FileInformationCache[$ExecutablePath] = [PSCustomObject]@{ Company = $Company; InstallDate = $InstallDate }
            }
            [PSCustomObject]$FileInformation = $FileInformationCache[$ExecutablePath]

            [PSCustomObject]@{
                DisplayName     = [System.String]$Service.DisplayName
                ServiceName     = [System.String]$Service.Name
                Status          = [System.String]$Service.State
                StartupType     = Get-ServiceStartupTypeText -StartMode $Service.StartMode -DelayedAutoStart ([System.Boolean]$Service.DelayedAutoStart)
                LogOnAs         = [System.String]$Service.StartName
                InstallDate     = $FileInformation.InstallDate
                InstallDateText = $(if ($null -ne $FileInformation.InstallDate) { ([System.DateTime]$FileInformation.InstallDate).ToString('yyyy-MM-dd HH:mm', $InvariantCulture) } else { '' })
                PathName        = [System.String]$Service.PathName
                Description     = ([System.String]$Service.Description -replace '\s+', ' ').Trim()
                ExecutablePath  = $ExecutablePath
                Company         = $FileInformation.Company
                Origin          = $(if ($FileInformation.Company -like 'Microsoft*') { 'Microsoft' } else { 'Non-Microsoft' })
                ProcessId       = [System.Int32]$Service.ProcessId
            }
        }

        @($Inventory | Sort-Object -Property DisplayName)
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
    Filters a normalized service inventory.
.DESCRIPTION
    Applies the optional search term, status, startup type, origin and recent filters. The search
    term is matched against the display name, service name, description, account and path. An empty
    filter, or the value All, does not filter. The Recent switch keeps only the services whose
    executable was created during the last number of days, and ignores the search term.
.EXAMPLE
    Find-ServiceInventory -ServiceInventory $Services -SearchTerm 'Intel' -Status 'Running' -Origin 'Non-Microsoft only'
.INPUTS
    [PSCustomObject[]]
    [System.String]
.OUTPUTS
    [PSCustomObject[]]
#>
####################################################################################################
function Find-ServiceInventory {
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param (
        [Parameter(Mandatory=$false,HelpMessage='The normalized service inventory to filter.')]
        [AllowNull()]
        [PSCustomObject[]]$ServiceInventory,

        [Parameter(Mandatory=$false,HelpMessage='Optional text matched against the displayed service fields.')]
        [AllowNull()][AllowEmptyString()]
        [System.String]$SearchTerm,

        [Parameter(Mandatory=$false,HelpMessage='The status to show: All, Running, Stopped or Paused.')]
        [AllowNull()][AllowEmptyString()]
        [System.String]$Status = 'All',

        [Parameter(Mandatory=$false,HelpMessage='The startup type to show: All, Automatic, Automatic (Delayed Start), Manual or Disabled.')]
        [AllowNull()][AllowEmptyString()]
        [System.String]$StartupType = 'All',

        [Parameter(Mandatory=$false,HelpMessage='The origin to show: All services, Non-Microsoft only or Microsoft only.')]
        [AllowNull()][AllowEmptyString()]
        [System.String]$Origin = 'All services',

        [Parameter(Mandatory=$false,HelpMessage='Shows only the services whose executable was created recently, and ignores the search term.')]
        [System.Management.Automation.SwitchParameter]$Recent,

        [Parameter(Mandatory=$false,HelpMessage='The number of days included in the recent period.')]
        [ValidateRange(1,365)]
        [System.Int32]$Days = 7
    )

    [System.String]$NormalizedSearchTerm = ([System.String]$SearchTerm).Trim()
    [System.DateTime]$Now = Get-Date
    [System.DateTime]$StartDate = $Now.AddDays(-$Days)

    @(
        $ServiceInventory | Where-Object {
            if ((-not [System.String]::IsNullOrWhiteSpace($Status)) -and ($Status -ne 'All') -and ($_.Status -ne $Status)) { return $false }
            if ((-not [System.String]::IsNullOrWhiteSpace($StartupType)) -and ($StartupType -ne 'All') -and ($_.StartupType -ne $StartupType)) { return $false }
            if ($Origin -eq 'Non-Microsoft only') { if ($_.Origin -ne 'Non-Microsoft') { return $false } }
            elseif ($Origin -eq 'Microsoft only') { if ($_.Origin -ne 'Microsoft') { return $false } }

            if ($Recent.IsPresent) {
                return (($null -ne $_.InstallDate) -and ([System.DateTime]$_.InstallDate -ge $StartDate) -and ([System.DateTime]$_.InstallDate -le $Now))
            }
            if ([System.String]::IsNullOrWhiteSpace($NormalizedSearchTerm)) { return $true }

            foreach ($SearchValue in @([System.String]$_.DisplayName, [System.String]$_.ServiceName, [System.String]$_.Description, [System.String]$_.LogOnAs, [System.String]$_.PathName)) {
                if ($SearchValue.IndexOf($NormalizedSearchTerm, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) { return $true }
            }
            $false
        }
    )
}

### END OF FUNCTION
####################################################################################################
