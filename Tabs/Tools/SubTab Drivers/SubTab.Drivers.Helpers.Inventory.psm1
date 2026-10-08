####################################################################################################
<#
.SYNOPSIS
    Provides Windows driver inventory and package inspection helpers.
.DESCRIPTION
    Retrieves and normalizes driver package, Driver Store, signing, filtering, and associated-device data.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.2.0
    Author          : Imraan Iotana
    Creation Date   : August 2026
    Last Update     : August 2026
#>
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Returns devices associated with a published driver package.
.DESCRIPTION
    Matches signed-device records by published INF name and correlates their device IDs with the
    current PnP inventory to include presence, status, and problem information.
.EXAMPLE
    Get-DriverAssociatedDeviceInventory -PublishedInfName 'oem42.inf'
.INPUTS
    [System.String]
.OUTPUTS
    [PSCustomObject[]]
#>
####################################################################################################
function Get-DriverAssociatedDeviceInventory {
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The published INF name used to identify associated devices.')]
        [ValidateNotNullOrEmpty()]
        [System.String]$PublishedInfName
    )

    try {
        # EXECUTION - SIGNED DRIVER RECORDS
        # Match installed device records to the selected package using its unique published INF name.
        [System.String]$EscapedInfName = $PublishedInfName.Replace("'", "''")
        [System.Object[]]$SignedDriverRecords = @(
            Get-CimInstance -ClassName Win32_PnPSignedDriver -Filter "InfName = '$EscapedInfName'" -ErrorAction Stop
        )
        if ($SignedDriverRecords.Count -eq 0) {
            return @()
        }

        # PREPARATION - PNP LOOKUP
        # Query PnP state once and index it by device ID for fast correlation with signed records.
        [System.Collections.Hashtable]$PnpDeviceLookup = @{}
        [System.Management.Automation.CommandInfo]$GetPnpDeviceCommand = Get-Command -Name 'Get-PnpDevice' -ErrorAction SilentlyContinue
        if ($null -ne $GetPnpDeviceCommand) {
            try {
                foreach ($PnpDevice in @(Get-PnpDevice -ErrorAction Stop)) {
                    [System.String]$InstanceId = [System.String]$PnpDevice.InstanceId
                    if (-not [System.String]::IsNullOrWhiteSpace($InstanceId)) {
                        $PnpDeviceLookup[$InstanceId] = $PnpDevice
                    }
                }
            }
            catch {
                Write-Line 'Live PnP device state is unavailable. Using signed-driver information only.' -Type Warning
            }
        }

        # OUTPUT
        # Combine stable signed-driver identity with live PnP state for each associated device.
        [PSCustomObject[]]$AssociatedDevices = @(
            foreach ($SignedDriverRecord in $SignedDriverRecords) {
                [System.String]$DeviceId = [System.String]$SignedDriverRecord.DeviceID
                [System.Object]$PnpDevice = if ($PnpDeviceLookup.ContainsKey($DeviceId)) { $PnpDeviceLookup[$DeviceId] } else { $null }
                [System.String[]]$HardwareIds = if ($null -ne $PnpDevice) { @($PnpDevice.HardwareID) } else { @($SignedDriverRecord.HardWareID) }
                [System.String]$Service = if (($null -ne $PnpDevice) -and (-not [System.String]::IsNullOrWhiteSpace([System.String]$PnpDevice.Service))) { [System.String]$PnpDevice.Service } else { [System.String]$SignedDriverRecord.DriverName }

                [PSCustomObject]@{
                    Name         = $(if (-not [System.String]::IsNullOrWhiteSpace([System.String]$SignedDriverRecord.DeviceName)) { [System.String]$SignedDriverRecord.DeviceName } else { [System.String]$SignedDriverRecord.FriendlyName })
                    Manufacturer = [System.String]$SignedDriverRecord.Manufacturer
                    Class        = $(if ($null -ne $PnpDevice) { [System.String]$PnpDevice.Class } else { [System.String]$SignedDriverRecord.DeviceClass })
                    InstanceId   = $DeviceId
                    Present      = $(if ($null -ne $PnpDevice) { [System.Boolean]$PnpDevice.Present } else { $null })
                    Started      = $(if ($null -ne $SignedDriverRecord.Started) { [System.Boolean]$SignedDriverRecord.Started } else { $null })
                    Status       = $(if ($null -ne $PnpDevice) { [System.String]$PnpDevice.Status } else { [System.String]$SignedDriverRecord.Status })
                    Problem      = $(if ($null -ne $PnpDevice) { [System.String]$PnpDevice.Problem } else { '' })
                    ConfigurationCode = $(if ($null -ne $PnpDevice) { [System.String]$PnpDevice.ConfigManagerErrorCode } else { '' })
                    Location     = [System.String]$SignedDriverRecord.Location
                    Service      = $Service
                    HardwareIds  = @($HardwareIds | Where-Object { -not [System.String]::IsNullOrWhiteSpace([System.String]$_) }) -join '; '
                    InstalledVersion = [System.String]$SignedDriverRecord.DriverVersion
                }
            }
        )

        @($AssociatedDevices | Sort-Object @{ Expression = { if ($_.Present -eq $true) { 0 } else { 1 } } }, Name, InstanceId)
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
        @()
    }
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Returns the canonical associated-device property order.
.DESCRIPTION
    Provides one schema for associated-device objects and CSV export.
.EXAMPLE
    Get-DriverAssociatedDevicePropertyNames
.OUTPUTS
    [System.String[]]
#>
####################################################################################################
function Get-DriverAssociatedDevicePropertyNames {
    [CmdletBinding()]
    [OutputType([System.String[]])]
    param ()

    @(
        'Name','Manufacturer','Class','InstanceId','Present','Started','Status','Problem',
        'ConfigurationCode','Location','Service','HardwareIds','InstalledVersion'
    )
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Summarizes associated devices using one shared set of state rules.
.DESCRIPTION
    Categorizes present, started, working, problem, and matching-version devices for host details
    and administrative export reports.
.EXAMPLE
    Get-DriverAssociatedDeviceSummary -AssociatedDevices $Devices -PackageVersion '1.2.3.4'
.INPUTS
    [PSCustomObject[]]
.OUTPUTS
    [PSCustomObject]
#>
####################################################################################################
function Get-DriverAssociatedDeviceSummary {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory=$false,HelpMessage='The devices associated with the selected driver package.')]
        [AllowNull()]
        [PSCustomObject[]]$AssociatedDevices,

        [Parameter(Mandatory=$false,HelpMessage='The selected driver package version.')]
        [AllowNull()][AllowEmptyString()]
        [System.String]$PackageVersion
    )

    [PSCustomObject[]]$Devices = @($AssociatedDevices)
    [PSCustomObject[]]$PresentDevices = @($Devices | Where-Object { $_.Present -eq $true })
    [PSCustomObject[]]$StartedDevices = @($Devices | Where-Object { $_.Started -eq $true })
    [PSCustomObject[]]$WorkingDevices = @($PresentDevices | Where-Object {
        ([System.String]$_.Status -eq 'OK') -and
        (([System.String]$_.Problem -eq 'CM_PROB_NONE') -or [System.String]::IsNullOrWhiteSpace([System.String]$_.Problem))
    })
    [PSCustomObject[]]$ProblemDevices = @($PresentDevices | Where-Object {
        ([System.String]$_.Status -ne 'OK') -or
        ((-not [System.String]::IsNullOrWhiteSpace([System.String]$_.Problem)) -and ([System.String]$_.Problem -ne 'CM_PROB_NONE'))
    })
    [PSCustomObject[]]$MatchingVersionDevices = @($Devices | Where-Object {
        (-not [System.String]::IsNullOrWhiteSpace([System.String]$_.InstalledVersion)) -and
        ([System.String]$_.InstalledVersion -eq $PackageVersion)
    })

    [PSCustomObject]@{
        AssociatedCount       = $Devices.Count
        PresentCount          = $PresentDevices.Count
        StartedCount          = $StartedDevices.Count
        WorkingCount          = $WorkingDevices.Count
        ProblemCount          = $ProblemDevices.Count
        NotPresentCount       = ($Devices.Count - $PresentDevices.Count)
        MatchingVersionCount  = $MatchingVersionDevices.Count
        PresentDevices        = $PresentDevices
        StartedDevices        = $StartedDevices
        WorkingDevices        = $WorkingDevices
        ProblemDevices        = $ProblemDevices
        MatchingVersionDevices= $MatchingVersionDevices
    }
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Returns quick content and signing details for a Driver Store package folder.
.DESCRIPTION
    Reads one selected package folder to summarize its size, files, architecture, catalogs, and
    catalog signature state without querying associated hardware devices.
.EXAMPLE
    Get-DriverPackageQuickDetails -StorePath 'C:\Windows\System32\DriverStore\FileRepository\example.inf_amd64_1234'
.INPUTS
    [System.String]
.OUTPUTS
    [PSCustomObject]
#>
####################################################################################################
function Get-DriverPackageQuickDetails {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory=$false,HelpMessage='The Driver Store package folder to inspect.')]
        [AllowNull()][AllowEmptyString()]
        [System.String]$StorePath
    )

    [PSCustomObject]$Details = [PSCustomObject]@{
        PackageSizeText = 'Unknown'
        FileCount       = 0
        InfFiles        = 'None'
        CatalogFiles    = 'None'
        Architecture    = 'Unknown'
        Signed          = 'Unknown'
        SignatureStatus = 'Unknown'
    }

    if ([System.String]::IsNullOrWhiteSpace($StorePath) -or (-not (Test-Path -LiteralPath $StorePath -PathType Container))) {
        return $Details
    }

    try {
        [System.IO.FileInfo[]]$PackageFiles = @(Get-ChildItem -LiteralPath $StorePath -File -Recurse -ErrorAction Stop)
        [System.Int64]$PackageSizeBytes = [System.Int64](($PackageFiles | Measure-Object -Property Length -Sum).Sum)
        [System.String]$PackageSizeText = if ($PackageSizeBytes -ge 1GB) {
            '{0:N2} GB' -f ($PackageSizeBytes / 1GB)
        }
        elseif ($PackageSizeBytes -ge 1MB) {
            '{0:N2} MB' -f ($PackageSizeBytes / 1MB)
        }
        elseif ($PackageSizeBytes -ge 1KB) {
            '{0:N2} KB' -f ($PackageSizeBytes / 1KB)
        }
        else {
            "${PackageSizeBytes} bytes"
        }

        [System.IO.FileInfo[]]$InfFiles = @($PackageFiles | Where-Object { $_.Extension -ieq '.inf' })
        [System.IO.FileInfo[]]$CatalogFiles = @($PackageFiles | Where-Object { $_.Extension -ieq '.cat' })
        [System.String]$Architecture = switch -Regex ([System.IO.Path]::GetFileName($StorePath)) {
            '_amd64_' { 'x64'; break }
            '_arm64_' { 'ARM64'; break }
            '_arm_'   { 'ARM'; break }
            '_x86_'   { 'x86'; break }
            default   { 'Unknown' }
        }

        [System.String]$Signed = if ($CatalogFiles.Count -eq 0) { 'Unknown' } else { 'No' }
        [System.String]$SignatureStatus = if ($CatalogFiles.Count -eq 0) { 'No catalog file' } else { 'Unknown' }
        if ($CatalogFiles.Count -gt 0) {
            [System.Object[]]$CatalogSignatures = @($CatalogFiles | Get-AuthenticodeSignature)
            if (@($CatalogSignatures | Where-Object { $null -ne $_.SignerCertificate }).Count -gt 0) {
                $Signed = 'Yes'
            }
            [System.String[]]$SignatureStatuses = @($CatalogSignatures | ForEach-Object { [System.String]$_.Status } | Sort-Object -Unique)
            if ($SignatureStatuses.Count -gt 0) {
                $SignatureStatus = $SignatureStatuses -join ', '
            }
        }

        [PSCustomObject]@{
            PackageSizeText = $PackageSizeText
            FileCount       = $PackageFiles.Count
            InfFiles        = $(if ($InfFiles.Count -gt 0) { @($InfFiles.Name | Sort-Object -Unique) -join ', ' } else { 'None' })
            CatalogFiles    = $(if ($CatalogFiles.Count -gt 0) { @($CatalogFiles.Name | Sort-Object -Unique) -join ', ' } else { 'None' })
            Architecture    = $Architecture
            Signed          = $Signed
            SignatureStatus = $SignatureStatus
        }
    }
    catch {
        $Details
    }
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Maps INF content hashes to their Driver Store package folders.
.DESCRIPTION
    Hashes INF files in the Driver Store so each published OEM INF can be matched to its exact
    package folder without confusing different versions that share an original INF name.
.EXAMPLE
    Get-DriverStoreFolderLookup
.INPUTS
    None.
.OUTPUTS
    [System.Collections.Hashtable]
#>
####################################################################################################
function Get-DriverStoreFolderLookup {
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param ()

    try {
        [System.String]$DriverStorePath = Join-Path -Path $env:WINDIR -ChildPath 'System32\DriverStore\FileRepository'
        if (-not (Test-Path -LiteralPath $DriverStorePath -PathType Container)) {
            throw "The Windows Driver Store folder could not be found. ($DriverStorePath)"
        }

        [System.Collections.Hashtable]$FolderLookup = @{}
        [System.IO.FileInfo[]]$InfFiles = @(
            Get-ChildItem -LiteralPath $DriverStorePath -Filter '*.inf' -File -Recurse -ErrorAction Stop
        )

        foreach ($InfFile in $InfFiles) {
            [System.String]$ContentHash = [System.String](Get-FileHash -LiteralPath $InfFile.FullName -Algorithm SHA256 -ErrorAction Stop).Hash
            if (-not $FolderLookup.ContainsKey($ContentHash)) {
                $FolderLookup[$ContentHash] = New-Object System.Collections.ArrayList
            }
            $null = $FolderLookup[$ContentHash].Add([PSCustomObject]@{
                OriginalName = [System.String]$InfFile.Name
                Path         = [System.String]$InfFile.Directory.FullName
                CreationTime = [System.DateTime]$InfFile.Directory.CreationTime
            })
        }

        $FolderLookup
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
        @{}
    }
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Retrieves third-party driver packages from PnPUtil.
.DESCRIPTION
    Uses PnPUtil CSV output and returns normalized objects suitable for filtering and display.
.EXAMPLE
    Get-DriverInventory
.INPUTS
    None.
.OUTPUTS
    [PSCustomObject[]]
#>
####################################################################################################
function Get-DriverInventory {
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param ()

    try {
        # PREPARATION
        # Resolve the supported Windows driver utility before starting enumeration.
        [System.Management.Automation.ApplicationInfo]$PnPUtilCommand = Get-Command -Name 'pnputil.exe' -CommandType Application -ErrorAction Stop

        # EXECUTION
        # Request structured output so driver package metadata does not need text parsing.
        [System.String[]]$PnPUtilOutput = @(& $PnPUtilCommand.Source '/enum-drivers' '/format' 'csv')
        if ($LASTEXITCODE -ne 0) {
            throw "PnPUtil driver enumeration failed with exit code $LASTEXITCODE."
        }

        [PSCustomObject[]]$DriverRows = @($PnPUtilOutput | ConvertFrom-Csv)
        if (($DriverRows.Count -gt 0) -and ($null -eq $DriverRows[0].PSObject.Properties['DriverName'])) {
            throw 'PnPUtil returned an unsupported CSV format without a DriverName column.'
        }
        [System.Collections.Hashtable]$DriverStoreFolderLookup = Get-DriverStoreFolderLookup
        [System.String]$PublishedInfRoot = Join-Path -Path $env:WINDIR -ChildPath 'INF'

        # OUTPUT
        # Normalize the combined driver date/version field and retain stable display properties.
        [PSCustomObject[]]$DriverInventory = @(
            foreach ($DriverRow in $DriverRows) {
                [System.String]$DriverDateText = ''
                [System.String]$DriverVersionText = [System.String]$DriverRow.DriverVersion
                if ($DriverVersionText -match '^\s*(?<DriverDate>\d{1,2}/\d{1,2}/\d{4})\s+(?<Version>.+?)\s*$') {
                    [System.DateTime]$DriverDate = [System.DateTime]::MinValue
                    if ([System.DateTime]::TryParseExact([System.String]$Matches.DriverDate, 'M/d/yyyy', [System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::None, [ref]$DriverDate)) {
                        $DriverDateText = $DriverDate.ToString('yyyy-MM-dd', [System.Globalization.CultureInfo]::InvariantCulture)
                    }
                    else {
                        $DriverDateText = [System.String]$Matches.DriverDate
                    }
                    $DriverVersionText = [System.String]$Matches.Version
                }
                [PSCustomObject]$DriverStoreFolder = $null
                [System.String]$StoreMatchStatus = 'PublishedInfMissing'
                [System.String]$PublishedInfPath = Join-Path -Path $PublishedInfRoot -ChildPath ([System.String]$DriverRow.DriverName)
                if (Test-Path -LiteralPath $PublishedInfPath -PathType Leaf) {
                    [System.String]$PublishedInfHash = [System.String](Get-FileHash -LiteralPath $PublishedInfPath -Algorithm SHA256 -ErrorAction Stop).Hash
                    [PSCustomObject[]]$HashCandidates = if ($DriverStoreFolderLookup.ContainsKey($PublishedInfHash)) {
                        @($DriverStoreFolderLookup[$PublishedInfHash] | Where-Object { $_.OriginalName -ieq [System.String]$DriverRow.OriginalName })
                    }
                    else {
                        @()
                    }

                    if ($HashCandidates.Count -eq 1) {
                        $DriverStoreFolder = $HashCandidates[0]
                        $StoreMatchStatus = 'ContentHash'
                    }
                    elseif ($HashCandidates.Count -gt 1) {
                        $StoreMatchStatus = 'AmbiguousContentHash'
                    }
                    else {
                        $StoreMatchStatus = 'ContentHashNotFound'
                    }
                }

                [PSCustomObject]@{
                    ProviderName  = [System.String]$DriverRow.ProviderName
                    ClassName     = [System.String]$DriverRow.ClassName
                    OriginalName  = [System.String]$DriverRow.OriginalName
                    DriverName    = [System.String]$DriverRow.DriverName
                    Version       = $DriverVersionText
                    InstallationDate     = $(if ($null -ne $DriverStoreFolder) { [System.DateTime]$DriverStoreFolder.CreationTime } else { $null })
                    InstallationDateText = $(if ($null -ne $DriverStoreFolder) { ([System.DateTime]$DriverStoreFolder.CreationTime).ToString('yyyy-MM-dd HH:mm', [System.Globalization.CultureInfo]::InvariantCulture) } else { '' })
                    StorePath     = $(if ($null -ne $DriverStoreFolder) { [System.String]$DriverStoreFolder.Path } else { '' })
                    DriverDate    = $DriverDateText
                    SignerName    = [System.String]$DriverRow.SignerName
                    ClassGuid     = [System.String]$DriverRow.ClassGuid
                    StoreMatchStatus = $StoreMatchStatus
                }
            }
        )

        @($DriverInventory | Sort-Object ProviderName, ClassName, OriginalName)
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
        @()
    }
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Filters a normalized driver inventory using one optional search term.
.DESCRIPTION
    Searches all fields displayed in Driver Management. An empty search term returns all drivers.
.EXAMPLE
    Find-DriverInventory -DriverInventory $Drivers -SearchTerm 'Intel'
.INPUTS
    [PSCustomObject[]]
    [System.String]
.OUTPUTS
    [PSCustomObject[]]
#>
####################################################################################################
function Find-DriverInventory {
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param (
        [Parameter(Mandatory=$false,HelpMessage='The normalized driver inventory to filter.')]
        [AllowNull()]
        [PSCustomObject[]]$DriverInventory,

        [Parameter(Mandatory=$false,HelpMessage='Optional text matched against all displayed driver fields.')]
        [AllowNull()][AllowEmptyString()]
        [System.String]$SearchTerm
    )

    [System.String]$NormalizedSearchTerm = [System.String]$SearchTerm
    if ($null -ne $NormalizedSearchTerm) { $NormalizedSearchTerm = $NormalizedSearchTerm.Trim() }
    if ([System.String]::IsNullOrWhiteSpace($NormalizedSearchTerm)) {
        return @($DriverInventory)
    }

    @(
        $DriverInventory | Where-Object {
            [System.String[]]$SearchValues = @(
                [System.String]$_.ProviderName,
                [System.String]$_.ClassName,
                [System.String]$_.OriginalName,
                [System.String]$_.DriverName,
                [System.String]$_.Version,
                [System.String]$_.InstallationDateText,
                [System.String]$_.DriverDate,
                [System.String]$_.SignerName
            )

            [System.Boolean]$MatchesSearchTerm = $false
            foreach ($SearchValue in $SearchValues) {
                if ($SearchValue.IndexOf($NormalizedSearchTerm, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
                    $MatchesSearchTerm = $true
                    break
                }
            }
            $MatchesSearchTerm
        }
    )
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Returns driver packages whose Driver Store folders were created recently.
.DESCRIPTION
    Filters by the approximate Driver Store folder creation timestamp from now back through the
    requested number of days. Packages without a matched folder timestamp are excluded.
.EXAMPLE
    Find-RecentDriverInventory -DriverInventory $Drivers -Days 7
.INPUTS
    [PSCustomObject[]]
    [System.Int32]
.OUTPUTS
    [PSCustomObject[]]
#>
####################################################################################################
function Find-RecentDriverInventory {
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param (
        [Parameter(Mandatory=$false,HelpMessage='The normalized driver inventory to filter.')]
        [AllowNull()]
        [PSCustomObject[]]$DriverInventory,

        [Parameter(Mandatory=$false,HelpMessage='The number of days included in the recent period.')]
        [ValidateRange(1,365)]
        [System.Int32]$Days = 7,

        [Parameter(Mandatory=$false,HelpMessage='The end of the recent period.')]
        [System.DateTime]$Now = (Get-Date)
    )

    [System.DateTime]$StartDate = $Now.AddDays(-$Days)
    @(
        $DriverInventory | Where-Object {
            ($null -ne $_.InstallationDate) -and ([System.DateTime]$_.InstallationDate -ge $StartDate) -and ([System.DateTime]$_.InstallationDate -le $Now)
        }
    )
}

### END OF FUNCTION
####################################################################################################
