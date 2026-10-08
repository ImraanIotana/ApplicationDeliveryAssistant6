####################################################################################################
<#
.SYNOPSIS
    Provides driver package export and administrative reporting helpers.
.DESCRIPTION
    Exports selected driver package files and writes structured administrative information to the user output folder.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.2.0
    Author          : Imraan Iotana
    Creation Date   : August 2026
    Last Update     : August 2026
#>
####################################################################################################


####################################################################################################
function ConvertTo-DriverExportPathComponent {
    [CmdletBinding()]
    [OutputType([System.String])]
    param (
        [Parameter(Mandatory=$false)][AllowNull()][AllowEmptyString()][System.String]$Value,
        [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][System.String]$Fallback,
        [Parameter(Mandatory=$true)][ValidateRange(1,100)][System.Int32]$MaximumLength
    )

    [System.String]$SafeValue = ([System.String]$Value).Trim() -replace '[\/:*?""<>|]', '_'
    $SafeValue = $SafeValue.TrimEnd([System.Char[]]' .')
    if ([System.String]::IsNullOrWhiteSpace($SafeValue)) { $SafeValue = $Fallback }
    if ($SafeValue.Length -gt $MaximumLength) {
        $SafeValue = $SafeValue.Substring(0, $MaximumLength).TrimEnd([System.Char[]]' .')
    }
    $SafeValue
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
function Get-DriverExportFolderName {
    [CmdletBinding()]
    [OutputType([System.String])]
    param (
        [Parameter(Mandatory=$true)][PSCustomObject]$Driver
    )

    [System.String]$ProviderName = ConvertTo-DriverExportPathComponent -Value ([System.String]$Driver.ProviderName) -Fallback 'Unknown Vendor' -MaximumLength 40
    [System.String]$OriginalInf = ConvertTo-DriverExportPathComponent -Value ([System.String]$Driver.OriginalName) -Fallback ([System.String]$Driver.DriverName) -MaximumLength 60
    [System.String]$Version = ConvertTo-DriverExportPathComponent -Value ([System.String]$Driver.Version) -Fallback 'Unknown Version' -MaximumLength 30
    "Driver Export - $ProviderName - $OriginalInf - $Version"
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
function Get-DriverExportFileManifest {
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param (
        [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][System.String]$DriverFilesFolder
    )

    @(
        foreach ($DriverFile in @(Get-ChildItem -LiteralPath $DriverFilesFolder -File -Recurse -ErrorAction Stop)) {
            [System.String]$RelativePath = $DriverFile.FullName.Substring($DriverFilesFolder.Length).TrimStart([System.Char[]]'\')
            [PSCustomObject][ordered]@{
                RelativePath = $RelativePath
                SizeBytes    = [System.Int64]$DriverFile.Length
                LastWriteTime= $DriverFile.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss', [System.Globalization.CultureInfo]::InvariantCulture)
                SHA256       = [System.String](Get-FileHash -LiteralPath $DriverFile.FullName -Algorithm SHA256 -ErrorAction Stop).Hash
            }
        }
    )
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
function New-DriverAdministrativeReport {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory=$true)][PSCustomObject]$Driver,
        [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][System.String]$OutputFolder,
        [Parameter(Mandatory=$true)][System.Int32]$PnPUtilExitCode,
        [Parameter(Mandatory=$true)][PSCustomObject]$PackageDetails,
        [Parameter(Mandatory=$true)][PSCustomObject]$DeviceSummary,
        [Parameter(Mandatory=$false)][AllowNull()][PSCustomObject[]]$AssociatedDevices,
        [Parameter(Mandatory=$false)][AllowNull()][PSCustomObject[]]$FileManifest,
        [Parameter(Mandatory=$false)][AllowNull()][System.String[]]$PnPUtilOutput
    )

    [System.Object]$OperatingSystem = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction SilentlyContinue
    [PSCustomObject][ordered]@{
        Export = [PSCustomObject][ordered]@{
            ExportedAt        = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss', [System.Globalization.CultureInfo]::InvariantCulture)
            ExportedBy        = [System.String]$env:USERNAME
            ComputerName      = [System.String]$env:COMPUTERNAME
            OutputFolder      = $OutputFolder
            PnPUtilExitCode   = $PnPUtilExitCode
            ExportedFileCount = @($FileManifest).Count
        }
        OperatingSystem = [PSCustomObject][ordered]@{
            Caption      = [System.String]$OperatingSystem.Caption
            Version      = [System.String]$OperatingSystem.Version
            BuildNumber  = [System.String]$OperatingSystem.BuildNumber
            Architecture = [System.String]$OperatingSystem.OSArchitecture
        }
        DriverPackage = [PSCustomObject][ordered]@{
            ProviderName          = [System.String]$Driver.ProviderName
            OriginalInf           = [System.String]$Driver.OriginalName
            PublishedInf          = [System.String]$Driver.DriverName
            Version               = [System.String]$Driver.Version
            DriverDate            = [System.String]$Driver.DriverDate
            Class                 = [System.String]$Driver.ClassName
            ClassGuid             = [System.String]$Driver.ClassGuid
            Signer                = [System.String]$Driver.SignerName
            InstallationDate      = [System.String]$Driver.InstallationDateText
            SourceDriverStorePath = [System.String]$Driver.StorePath
            StoreMatchStatus      = [System.String]$Driver.StoreMatchStatus
        }
        PackageDetails = $PackageDetails
        DeviceSummary = [PSCustomObject][ordered]@{
            AssociatedCount      = $DeviceSummary.AssociatedCount
            PresentCount         = $DeviceSummary.PresentCount
            StartedCount         = $DeviceSummary.StartedCount
            WorkingCount         = $DeviceSummary.WorkingCount
            ProblemCount         = $DeviceSummary.ProblemCount
            NotPresentCount      = $DeviceSummary.NotPresentCount
            MatchingVersionCount = $DeviceSummary.MatchingVersionCount
        }
        AssociatedDevices = @($AssociatedDevices)
        FileManifest      = @($FileManifest)
        PnPUtilOutput     = @($PnPUtilOutput)
    }
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
function Write-DriverExportArtifacts {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][System.String]$ExportFolder,
        [Parameter(Mandatory=$true)][PSCustomObject]$AdministrativeReport
    )

    [System.String]$TextReportPath = Join-Path -Path $ExportFolder -ChildPath 'Driver Administrative Report.txt'
    [System.String]$JsonReportPath = Join-Path -Path $ExportFolder -ChildPath 'Driver Administrative Report.json'
    [System.String]$DevicesCsvPath = Join-Path -Path $ExportFolder -ChildPath 'Associated Devices.csv'
    [System.String]$ManifestCsvPath = Join-Path -Path $ExportFolder -ChildPath 'Driver File Manifest.csv'

    @($AdministrativeReport.FileManifest) | Export-Csv -LiteralPath $ManifestCsvPath -NoTypeInformation -Encoding UTF8
    [System.String[]]$DevicePropertyNames = @(Get-DriverAssociatedDevicePropertyNames)
    if (@($AdministrativeReport.AssociatedDevices).Count -gt 0) {
        $AdministrativeReport.AssociatedDevices | Select-Object -Property $DevicePropertyNames |
            Export-Csv -LiteralPath $DevicesCsvPath -NoTypeInformation -Encoding UTF8
    }
    else {
        [System.Collections.Specialized.OrderedDictionary]$EmptyDevice = [ordered]@{}
        foreach ($PropertyName in $DevicePropertyNames) { $EmptyDevice[$PropertyName] = '' }
        [System.String]$CsvHeader = @([PSCustomObject]$EmptyDevice | ConvertTo-Csv -NoTypeInformation)[0]
        $CsvHeader | Set-Content -LiteralPath $DevicesCsvPath -Encoding UTF8
    }
    $AdministrativeReport | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $JsonReportPath -Encoding UTF8

    [PSCustomObject]$Driver = $AdministrativeReport.DriverPackage
    [PSCustomObject]$Package = $AdministrativeReport.PackageDetails
    [PSCustomObject]$Summary = $AdministrativeReport.DeviceSummary
    [System.String[]]$TextReport = @(
        'DRIVER PACKAGE EXPORT','=====================',
        "Exported At          : $($AdministrativeReport.Export.ExportedAt)",
        "Exported By          : $($AdministrativeReport.Export.ExportedBy)",
        "Computer             : $($AdministrativeReport.Export.ComputerName)",
        "Operating System     : $($AdministrativeReport.OperatingSystem.Caption)",
        "OS Version           : $($AdministrativeReport.OperatingSystem.Version) (Build $($AdministrativeReport.OperatingSystem.BuildNumber))",
        "OS Architecture      : $($AdministrativeReport.OperatingSystem.Architecture)",'',
        'DRIVER PACKAGE','==============',
        "Provider             : $($Driver.ProviderName)","Original INF         : $($Driver.OriginalInf)",
        "Published INF        : $($Driver.PublishedInf)","Version              : $($Driver.Version)",
        "Driver Date          : $($Driver.DriverDate)","Class                : $($Driver.Class)",
        "Class GUID           : $($Driver.ClassGuid)","Signer               : $($Driver.Signer)",
        "Installation Date    : $($Driver.InstallationDate)","Driver Store Folder  : $($Driver.SourceDriverStorePath)",
        "Store Match          : $($Driver.StoreMatchStatus)",'',
        'PACKAGE CONTENT AND SIGNING','===========================',
        "Architecture          : $($Package.Architecture)","Package Size          : $($Package.PackageSizeText)",
        "Source File Count     : $($Package.FileCount)","Exported File Count   : $($AdministrativeReport.Export.ExportedFileCount)",
        "INF Files             : $($Package.InfFiles)","Catalog Files         : $($Package.CatalogFiles)",
        "Signed                : $($Package.Signed)","Signature Status      : $($Package.SignatureStatus)",'',
        'ASSOCIATED DEVICES','==================',
        "Associated Devices    : $($Summary.AssociatedCount)","Present Devices       : $($Summary.PresentCount)",
        "Started Devices       : $($Summary.StartedCount)","Working Devices       : $($Summary.WorkingCount)",
        "Devices With Problems : $($Summary.ProblemCount)","Not Present           : $($Summary.NotPresentCount)",
        "Using Package Version : $($Summary.MatchingVersionCount)",'',
        'FILES IN THIS EXPORT','====================',
        'Driver Files\         Reinstallable files exported by PnPUtil',
        'Administrative Files\  Reports, device data, file manifest, and PnPUtil output','',
        'REINSTALLATION','==============',
        'Use PnPUtil /add-driver with an exported INF file. Add /install only when matching devices should be updated.','',
        '-------------------- End of driver export information --------------------'
    )
    $TextReport | Set-Content -LiteralPath $TextReportPath -Encoding UTF8
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Exports the selected driver package and its administrative information.
.DESCRIPTION
    Uses PnPUtil to export the reinstallable driver files into one package-specific folder under
    the configured user output folder, with confirmation before replacing an existing export. The
    Administrative Files subfolder receives TXT/JSON reports, associated-device data, the raw
    PnPUtil log, and a SHA-256 file manifest.
.EXAMPLE
    Export-SelectedDriverPackage -ListView $DriverResultsListView -OpenOutputFolder
.INPUTS
    [System.Windows.Forms.ListView]
.OUTPUTS
    No objects are returned to the pipeline.
#>
####################################################################################################
function Export-SelectedDriverPackage {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The Driver Results ListView containing the selected package.')]
        [System.Windows.Forms.ListView]$ListView,

        [Parameter(Mandatory=$false,HelpMessage='The parent folder where the driver export folder will be created.')]
        [AllowNull()][AllowEmptyString()]
        [System.String]$OutputFolder = (Get-Folder -OutputFolder),

        [Parameter(Mandatory=$false,HelpMessage='Skips confirmation dialogs and permits replacement of an existing export folder.')]
        [System.Management.Automation.SwitchParameter]$SkipConfirmation,

        [Parameter(Mandatory=$false,HelpMessage='Opens the completed driver export folder.')]
        [System.Management.Automation.SwitchParameter]$OpenOutputFolder
    )

    [System.String]$ExportFolder = ''
    [System.String]$StagingFolder = ''
    [System.String]$BackupFolder = ''

    try {
        # VALIDATION - SELECTED DRIVER
        [PSCustomObject]$Driver = Get-SelectedDriverPackage -ListView $ListView
        if ($null -eq $Driver) { return }

        [System.String]$PublishedInfName = [System.String]$Driver.DriverName
        if ($PublishedInfName -notmatch '^oem\d+\.inf$') {
            Write-Line "The published INF name is not valid for driver export. ($PublishedInfName)" -Type Warning
            return
        }
        if ([System.String]::IsNullOrWhiteSpace($OutputFolder)) {
            Write-Line 'The configured user output folder is empty.' -Type Warning
            return
        }

        # PREPARATION - OUTPUT PATHS
        [System.String]$ExportFolderName = Get-DriverExportFolderName -Driver $Driver
        [System.String]$ExportFolder = Join-Path -Path $OutputFolder -ChildPath $ExportFolderName
        [System.String]$TransactionId = [System.Guid]::NewGuid().ToString('N')
        $StagingFolder = Join-Path -Path $OutputFolder -ChildPath ".$ExportFolderName.partial-$TransactionId"
        $BackupFolder = Join-Path -Path $OutputFolder -ChildPath ".$ExportFolderName.backup-$TransactionId"
        [System.String]$DriverFilesFolder = Join-Path -Path $StagingFolder -ChildPath 'Driver Files'
        [System.String]$AdministrativeFilesFolder = Join-Path -Path $StagingFolder -ChildPath 'Administrative Files'
        [System.String]$PnPUtilLogPath = Join-Path -Path $AdministrativeFilesFolder -ChildPath 'PnPUtil Export.log'

        # CONFIRMATION
        if (Test-Path -LiteralPath $ExportFolder) {
            if (-not (Test-Path -LiteralPath $ExportFolder -PathType Container)) {
                Write-Line "The export destination exists but is not a folder. ($ExportFolder)" -Type Warning
                return
            }
            if (-not $SkipConfirmation.IsPresent) {
                [System.String]$OverwriteBody = "The driver export folder already exists:`n`n$ExportFolder`n`nThe folder and all files inside it will be replaced.`n`nDo you want to overwrite it?"
                if (-not (Get-UserConfirmation -Title 'Overwrite Driver Export' -Body $OverwriteBody -Type Warning)) {
                    return
                }
            }
        }
        elseif (-not $SkipConfirmation.IsPresent) {
            [System.String]$ConfirmationBody = "This will export the driver package files and administrative information for:`n`n$PublishedInfName`n$([System.String]$Driver.ProviderName)`n$([System.String]$Driver.Version)`n`nDestination:`n$ExportFolder`n`nDo you want to continue?"
            if (-not (Get-UserConfirmation -Title 'Export Driver Package' -Body $ConfirmationBody)) {
                return
            }
        }

        if (-not (Test-Path -LiteralPath $OutputFolder -PathType Container)) {
            $null = New-Item -Path $OutputFolder -ItemType Directory -Force
        }
        $null = New-Item -Path $DriverFilesFolder -ItemType Directory -Force
        $null = New-Item -Path $AdministrativeFilesFolder -ItemType Directory -Force

        # EXECUTION - DRIVER FILE EXPORT
        [System.String]$ProviderDisplayName = ([System.String]$Driver.ProviderName).Trim()
        if ([System.String]::IsNullOrWhiteSpace($ProviderDisplayName)) { $ProviderDisplayName = 'Unknown vendor' }
        Write-Line "Exporting driver package $PublishedInfName from $ProviderDisplayName, one moment please..." -Type Busy
        [System.Management.Automation.ApplicationInfo]$PnPUtilCommand = Get-Command -Name 'pnputil.exe' -CommandType Application -ErrorAction Stop
        [System.String[]]$PnPUtilOutput = @(& $PnPUtilCommand.Source '/export-driver' $PublishedInfName $DriverFilesFolder 2>&1 | ForEach-Object { [System.String]$_ })
        [System.Int32]$PnPUtilExitCode = $LASTEXITCODE
        $PnPUtilOutput | Set-Content -LiteralPath $PnPUtilLogPath -Encoding UTF8
        if ($PnPUtilExitCode -ne 0) {
            throw "PnPUtil driver export failed with exit code $PnPUtilExitCode. Review the export log: $PnPUtilLogPath"
        }

        [System.IO.FileInfo[]]$ExportedDriverFiles = @(Get-ChildItem -LiteralPath $DriverFilesFolder -File -Recurse -ErrorAction Stop)
        if ($ExportedDriverFiles.Count -eq 0) {
            throw "PnPUtil completed without exporting driver files. Review the export log: $PnPUtilLogPath"
        }

        # EXECUTION - ADMINISTRATIVE INFORMATION
        [PSCustomObject]$PackageDetails = Get-DriverPackageQuickDetails -StorePath ([System.String]$Driver.StorePath)
        [PSCustomObject[]]$AssociatedDevices = @(Get-DriverAssociatedDeviceInventory -PublishedInfName $PublishedInfName)
        [PSCustomObject]$DeviceSummary = Get-DriverAssociatedDeviceSummary -AssociatedDevices $AssociatedDevices -PackageVersion ([System.String]$Driver.Version)
        [PSCustomObject[]]$FileManifest = @(Get-DriverExportFileManifest -DriverFilesFolder $DriverFilesFolder)
        [PSCustomObject]$AdministrativeReport = New-DriverAdministrativeReport -Driver $Driver -OutputFolder $ExportFolder `
            -PnPUtilExitCode $PnPUtilExitCode -PackageDetails $PackageDetails -DeviceSummary $DeviceSummary `
            -AssociatedDevices $AssociatedDevices -FileManifest $FileManifest -PnPUtilOutput $PnPUtilOutput
        Write-DriverExportArtifacts -ExportFolder $AdministrativeFilesFolder -AdministrativeReport $AdministrativeReport

        # POST-EXECUTION - TRANSACTIONAL REPLACEMENT
        if (Test-Path -LiteralPath $ExportFolder -PathType Container) {
            Move-Item -LiteralPath $ExportFolder -Destination $BackupFolder -ErrorAction Stop
        }
        try {
            Move-Item -LiteralPath $StagingFolder -Destination $ExportFolder -ErrorAction Stop
            $StagingFolder = ''
        }
        catch {
            if ((Test-Path -LiteralPath $BackupFolder -PathType Container) -and (-not (Test-Path -LiteralPath $ExportFolder))) {
                Move-Item -LiteralPath $BackupFolder -Destination $ExportFolder -ErrorAction SilentlyContinue
            }
            throw
        }
        if (Test-Path -LiteralPath $BackupFolder -PathType Container) {
            try {
                Remove-Item -LiteralPath $BackupFolder -Recurse -Force -ErrorAction Stop
            }
            catch {
                Write-Line "The previous driver export backup could not be removed. ($BackupFolder)" -Type Warning
            }
        }
        $BackupFolder = ''

        Write-Line "Driver package and administrative information exported successfully. ($ExportFolder)" -Type Success
        if ($OpenOutputFolder.IsPresent) {
            Open-Folder -Path $ExportFolder
        }
    }
    catch {
        if ((-not [System.String]::IsNullOrWhiteSpace($StagingFolder)) -and (Test-Path -LiteralPath $StagingFolder -PathType Container)) {
            Remove-Item -LiteralPath $StagingFolder -Recurse -Force -ErrorAction SilentlyContinue
        }
        if ((-not [System.String]::IsNullOrWhiteSpace($BackupFolder)) -and
            (Test-Path -LiteralPath $BackupFolder -PathType Container) -and
            (-not [System.String]::IsNullOrWhiteSpace($ExportFolder)) -and
            (-not (Test-Path -LiteralPath $ExportFolder))) {
            Move-Item -LiteralPath $BackupFolder -Destination $ExportFolder -ErrorAction SilentlyContinue
        }
        Write-ErrorReport -ErrorRecord $_
    }
}

### END OF FUNCTION
####################################################################################################
