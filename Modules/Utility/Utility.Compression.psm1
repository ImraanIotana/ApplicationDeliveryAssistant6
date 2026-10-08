####################################################################################################
<#
.SYNOPSIS
    Provides reusable ZIP archive creation, extraction, verification, and entry replacement helpers.
.DESCRIPTION
    Uses System.IO.Compression streams directly so large ZIP64 entries can be processed without
    loading complete files or archives into memory.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.8.0
    Author          : Imraan Iotana
    Creation Date   : September 2026
    Last Update     : September 2026
#>
####################################################################################################

function Initialize-CompressionRuntime {
    Add-Type -AssemblyName System.IO.Compression -ErrorAction Stop | Out-Null
    Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction Stop | Out-Null
}

function ConvertTo-CompressionSizeText {
    [CmdletBinding()]
    [OutputType([System.String])]
    param (
        [Parameter(Mandatory=$true)]
        [System.Int64]$ByteCount
    )

    [double]$Size = $ByteCount
    [System.String[]]$Units = @('B','KB','MB','GB','TB')
    [int]$UnitIndex = 0
    while (($Size -ge 1024) -and ($UnitIndex -lt ($Units.Count - 1))) {
        $Size /= 1024
        $UnitIndex++
    }

    if ($UnitIndex -eq 0) { return "$([System.Int64]$Size) $($Units[$UnitIndex])" }
    return ('{0:N1} {1}' -f $Size, $Units[$UnitIndex])
}

function New-CompressionProgressDialog {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory=$true)]
        [System.Object]$Owner,

        [Parameter(Mandatory=$true)]
        [System.String]$Title
    )

    Add-Type -AssemblyName System.Drawing -ErrorAction Stop
    Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
    if ($Owner -isnot [System.Windows.Forms.Form]) {
        throw 'The progress dialog owner must be a Windows Forms Form.'
    }

    [System.Windows.Forms.Form]$Dialog = New-Object System.Windows.Forms.Form
    $Dialog.Text = $Title
    $Dialog.ClientSize = New-Object System.Drawing.Size(460, 112)
    $Dialog.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterParent
    $Dialog.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $Dialog.MinimizeBox = $false
    $Dialog.MaximizeBox = $false
    $Dialog.ControlBox = $false
    $Dialog.ShowInTaskbar = $false
    $Dialog.ShowIcon = $false

    [System.Windows.Forms.Label]$StatusLabel = New-Object System.Windows.Forms.Label
    $StatusLabel.Location = New-Object System.Drawing.Point(16, 18)
    $StatusLabel.Size = New-Object System.Drawing.Size(428, 24)
    $StatusLabel.AutoEllipsis = $true
    $StatusLabel.Text = 'Preparing...'

    [System.Windows.Forms.ProgressBar]$ProgressBar = New-Object System.Windows.Forms.ProgressBar
    $ProgressBar.Location = New-Object System.Drawing.Point(16, 56)
    $ProgressBar.Size = New-Object System.Drawing.Size(428, 24)
    $ProgressBar.Minimum = 0
    $ProgressBar.Maximum = 100
    $ProgressBar.Style = [System.Windows.Forms.ProgressBarStyle]::Continuous

    $Dialog.Controls.AddRange(@($StatusLabel, $ProgressBar))
    $Owner.Enabled = $false
    try {
        $Dialog.Show($Owner)
        [System.Windows.Forms.Application]::DoEvents()
    }
    catch {
        $Owner.Enabled = $true
        $Dialog.Dispose()
        throw
    }

    [ScriptBlock]$UpdateAction = {
        param ([PSCustomObject]$ProgressInfo)
        if ($Dialog.IsDisposed -or $Dialog.Disposing) { return }
        $StatusLabel.Text = $ProgressInfo.Status
        if ($ProgressInfo.TotalBytes -gt 0) {
            $ProgressBar.Style = [System.Windows.Forms.ProgressBarStyle]::Continuous
            $ProgressBar.Value = [System.Math]::Max(0, [System.Math]::Min(100, $ProgressInfo.PercentComplete))
        }
        else {
            $ProgressBar.Style = [System.Windows.Forms.ProgressBarStyle]::Marquee
        }
        $Dialog.Refresh()
        [System.Windows.Forms.Application]::DoEvents()
    }.GetNewClosure()

    [ScriptBlock]$CloseAction = {
        if (-not $Dialog.IsDisposed) {
            $Dialog.Close()
            $Dialog.Dispose()
        }
        if (-not $Owner.IsDisposed) {
            $Owner.Enabled = $true
            $Owner.Activate()
        }
    }.GetNewClosure()

    return [PSCustomObject]@{
        Update = $UpdateAction
        Close  = $CloseAction
    }
}

function Write-CompressionProgress {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [ScriptBlock]$ProgressAction,

        [Parameter(Mandatory=$true)]
        [System.String]$Phase,

        [Parameter(Mandatory=$true)]
        [System.Int64]$CompletedBytes,

        [Parameter(Mandatory=$true)]
        [System.Int64]$TotalBytes,

        [Parameter(Mandatory=$false)]
        [AllowEmptyString()]
        [System.String]$CurrentItem = ''
    )

    [int]$PercentComplete = if ($TotalBytes -gt 0) {
        [System.Math]::Min(100, [System.Math]::Floor(($CompletedBytes * 100.0) / $TotalBytes))
    }
    else {
        100
    }
    [System.String]$Status = "$Phase - $PercentComplete% ($((ConvertTo-CompressionSizeText -ByteCount $CompletedBytes)) of $((ConvertTo-CompressionSizeText -ByteCount $TotalBytes)))"
    if (-not [System.String]::IsNullOrWhiteSpace($CurrentItem)) {
        $Status += " - $CurrentItem"
    }
    [PSCustomObject]$ProgressInfo = @{
        Phase           = $Phase
        PercentComplete = $PercentComplete
        CompletedBytes  = $CompletedBytes
        TotalBytes      = $TotalBytes
        CurrentItem     = $CurrentItem
        Status          = $Status
    }
    $null = $ProgressAction.Invoke($ProgressInfo)
}

function Copy-CompressionStream {
    [CmdletBinding()]
    [OutputType([System.Int64])]
    param (
        [Parameter(Mandatory=$true)]
        [System.IO.Stream]$SourceStream,

        [Parameter(Mandatory=$true)]
        [System.IO.Stream]$DestinationStream,

        [Parameter(Mandatory=$false)]
        [AllowNull()]
        [ScriptBlock]$ProgressAction,

        [Parameter(Mandatory=$false)]
        [System.String]$Phase = 'Processing',

        [Parameter(Mandatory=$false)]
        [System.Int64]$CompletedBytesBefore = 0,

        [Parameter(Mandatory=$false)]
        [System.Int64]$TotalBytes = 0,

        [Parameter(Mandatory=$false)]
        [AllowEmptyString()]
        [System.String]$CurrentItem = ''
    )

    [byte[]]$Buffer = New-Object byte[] 1048576
    [long]$CopiedBytes = 0
    [int]$BytesRead = 0
    [long]$LastReportedBytes = 0
    [System.Diagnostics.Stopwatch]$ProgressTimer = [System.Diagnostics.Stopwatch]::StartNew()
    while (($BytesRead = $SourceStream.Read($Buffer, 0, $Buffer.Length)) -gt 0) {
        $DestinationStream.Write($Buffer, 0, $BytesRead)
        $CopiedBytes += $BytesRead
        if (($null -ne $ProgressAction) -and (($CopiedBytes - $LastReportedBytes -ge 33554432) -or ($ProgressTimer.ElapsedMilliseconds -ge 250))) {
            Write-CompressionProgress -ProgressAction $ProgressAction -Phase $Phase -CompletedBytes ($CompletedBytesBefore + $CopiedBytes) -TotalBytes $TotalBytes -CurrentItem $CurrentItem
            $LastReportedBytes = $CopiedBytes
            $ProgressTimer.Restart()
        }
    }

    if ($null -ne $ProgressAction) {
        Write-CompressionProgress -ProgressAction $ProgressAction -Phase $Phase -CompletedBytes ($CompletedBytesBefore + $CopiedBytes) -TotalBytes $TotalBytes -CurrentItem $CurrentItem
    }
    return $CopiedBytes
}

function ConvertTo-CompressionEntryName {
    [CmdletBinding()]
    [OutputType([System.String])]
    param (
        [Parameter(Mandatory=$true)]
        [AllowEmptyString()]
        [System.String]$EntryName
    )

    [System.String]$NormalizedName = $EntryName.Replace('\', '/')
    if ([System.String]::IsNullOrWhiteSpace($NormalizedName) -or $NormalizedName.StartsWith('/') -or $NormalizedName -match '^[A-Za-z]:') {
        throw "The ZIP entry path is empty or rooted. ($EntryName)"
    }
    if ($NormalizedName.Contains(':') -or (@($NormalizedName.Split('/')) -contains '..')) {
        throw "The ZIP entry path contains an unsafe segment. ($EntryName)"
    }

    return $NormalizedName
}

function Set-CompressionEntryTimestamp {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [System.IO.Compression.ZipArchiveEntry]$Entry,

        [Parameter(Mandatory=$true)]
        [System.DateTime]$LastWriteTime
    )

    if ($LastWriteTime.Year -lt 1980) {
        $Entry.LastWriteTime = [System.DateTimeOffset]::new(1980, 1, 1, 0, 0, 0, [System.TimeSpan]::Zero)
    }
    elseif ($LastWriteTime.Year -gt 2107) {
        $Entry.LastWriteTime = [System.DateTimeOffset]::new(2107, 12, 31, 23, 59, 58, [System.TimeSpan]::Zero)
    }
    else {
        $Entry.LastWriteTime = [System.DateTimeOffset]$LastWriteTime
    }
}

function Publish-CompressionFile {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [System.String]$StagedPath,

        [Parameter(Mandatory=$true)]
        [System.String]$DestinationPath,

        [Parameter(Mandatory=$false)]
        [System.Management.Automation.SwitchParameter]$Force
    )

    if (-not (Test-Path -LiteralPath $DestinationPath)) {
        [System.IO.File]::Move($StagedPath, $DestinationPath)
        return
    }
    if (-not $Force) {
        throw "The destination already exists. ($DestinationPath)"
    }
    if (-not (Test-Path -LiteralPath $DestinationPath -PathType Leaf)) {
        throw "The destination is not a file. ($DestinationPath)"
    }

    [System.String]$BackupPath = "$DestinationPath.backup-$([System.Guid]::NewGuid().ToString('N'))"
    [System.IO.File]::Move($DestinationPath, $BackupPath)
    try {
        [System.IO.File]::Move($StagedPath, $DestinationPath)
    }
    catch {
        if ((Test-Path -LiteralPath $BackupPath -PathType Leaf) -and (-not (Test-Path -LiteralPath $DestinationPath))) {
            [System.IO.File]::Move($BackupPath, $DestinationPath)
        }
        throw
    }

    try {
        [System.IO.File]::Delete($BackupPath)
    }
    catch {
        Write-Warning "The new archive was published, but its backup could not be removed. ($BackupPath)"
    }
}

function Get-CompressionExtractionPath {
    [CmdletBinding()]
    [OutputType([System.String])]
    param (
        [Parameter(Mandatory=$true)]
        [System.String]$DestinationRoot,

        [Parameter(Mandatory=$true)]
        [System.String]$EntryName
    )

    [System.String]$NormalizedName = ConvertTo-CompressionEntryName -EntryName $EntryName
    [System.String]$RootPath = [System.IO.Path]::GetFullPath($DestinationRoot).TrimEnd([char[]]@('\', '/'))
    [System.String]$RootPrefix = $RootPath + [System.IO.Path]::DirectorySeparatorChar
    [System.String]$TargetPath = [System.IO.Path]::GetFullPath((Join-Path -Path $RootPath -ChildPath $NormalizedName.Replace('/', [System.IO.Path]::DirectorySeparatorChar)))
    if (-not $TargetPath.StartsWith($RootPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "The ZIP entry resolves outside the extraction folder. ($EntryName)"
    }

    return $TargetPath
}

function New-ZipArchiveFromDirectory {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory=$true)]
        [System.String]$SourceDirectory,

        [Parameter(Mandatory=$true)]
        [System.String]$DestinationPath,

        [Parameter(Mandatory=$false)]
        [System.Management.Automation.SwitchParameter]$IncludeBaseDirectory,

        [Parameter(Mandatory=$false)]
        [ValidateSet('Optimal','Fastest','NoCompression')]
        [System.String]$CompressionLevel = 'Optimal',

        [Parameter(Mandatory=$false)]
        [System.Management.Automation.SwitchParameter]$Force,

        [Parameter(Mandatory=$false)]
        [AllowNull()]
        [ScriptBlock]$ProgressAction
    )

    Initialize-CompressionRuntime
    if (-not (Test-Path -LiteralPath $SourceDirectory -PathType Container)) {
        throw "The source directory does not exist. ($SourceDirectory)"
    }

    [System.String]$SourceRoot = [System.IO.Path]::GetFullPath($SourceDirectory).TrimEnd([char[]]@('\', '/'))
    [System.String]$ArchivePath = [System.IO.Path]::GetFullPath($DestinationPath)
    if (Test-Path -LiteralPath $ArchivePath -PathType Container) {
        throw "The destination path is a directory. ($ArchivePath)"
    }
    if ((Test-Path -LiteralPath $ArchivePath) -and (-not $Force)) {
        throw "The destination already exists. ($ArchivePath)"
    }
    if ($ArchivePath.StartsWith(($SourceRoot + [System.IO.Path]::DirectorySeparatorChar), [System.StringComparison]::OrdinalIgnoreCase)) {
        throw 'The destination archive cannot be inside the source directory.'
    }

    [System.String]$DestinationParent = [System.IO.Path]::GetDirectoryName($ArchivePath)
    if ([System.String]::IsNullOrWhiteSpace($DestinationParent)) {
        throw "The destination folder is invalid. ($ArchivePath)"
    }
    [System.IO.Directory]::CreateDirectory($DestinationParent) | Out-Null

    [System.IO.DirectoryInfo[]]$SourceDirectories = @(Get-ChildItem -LiteralPath $SourceRoot -Directory -Recurse -Force -ErrorAction Stop)
    [System.IO.FileInfo[]]$SourceFiles = @(Get-ChildItem -LiteralPath $SourceRoot -File -Recurse -Force -ErrorAction Stop)
    [System.String]$SourceLeaf = [System.IO.Path]::GetFileName($SourceRoot)
    [System.String]$StagedPath = Join-Path -Path $DestinationParent -ChildPath ('.' + [System.IO.Path]::GetFileName($ArchivePath) + '.partial-' + [System.Guid]::NewGuid().ToString('N'))
    [System.IO.Compression.CompressionLevel]$Level = [System.IO.Compression.CompressionLevel]::$CompressionLevel
    [System.IO.FileStream]$ArchiveStream = $null
    [System.IO.Compression.ZipArchive]$Archive = $null
    [System.Boolean]$GenerationCompleted = $false
    [long]$TotalBytes = 0
    foreach ($File in $SourceFiles) {
        $TotalBytes += $File.Length
    }
    [long]$CompletedBytes = 0

    try {
        $ArchiveStream = [System.IO.File]::Open($StagedPath, [System.IO.FileMode]::CreateNew, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None)
        $Archive = [System.IO.Compression.ZipArchive]::new($ArchiveStream, [System.IO.Compression.ZipArchiveMode]::Create, $false)

        if ($IncludeBaseDirectory) {
            [System.IO.Compression.ZipArchiveEntry]$RootEntry = $Archive.CreateEntry(($SourceLeaf + '/'), $Level)
            Set-CompressionEntryTimestamp -Entry $RootEntry -LastWriteTime (Get-Item -LiteralPath $SourceRoot -Force).LastWriteTime
        }

        foreach ($Directory in $SourceDirectories) {
            [System.String]$RelativePath = $Directory.FullName.Substring($SourceRoot.Length).TrimStart([char[]]@('\', '/')).Replace('\', '/')
            if ($IncludeBaseDirectory) { $RelativePath = $SourceLeaf + '/' + $RelativePath }
            [System.IO.Compression.ZipArchiveEntry]$DirectoryEntry = $Archive.CreateEntry(($RelativePath.TrimEnd('/') + '/'), $Level)
            Set-CompressionEntryTimestamp -Entry $DirectoryEntry -LastWriteTime $Directory.LastWriteTime
        }

        foreach ($File in $SourceFiles) {
            [System.String]$RelativePath = $File.FullName.Substring($SourceRoot.Length).TrimStart([char[]]@('\', '/')).Replace('\', '/')
            if ($IncludeBaseDirectory) { $RelativePath = $SourceLeaf + '/' + $RelativePath }
            [System.IO.Compression.ZipArchiveEntry]$FileEntry = $Archive.CreateEntry($RelativePath, $Level)
            Set-CompressionEntryTimestamp -Entry $FileEntry -LastWriteTime $File.LastWriteTime
            [System.IO.Stream]$InputStream = $null
            [System.IO.Stream]$EntryStream = $null
            try {
                $InputStream = [System.IO.File]::Open($File.FullName, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::Read)
                $EntryStream = $FileEntry.Open()
                $null = Copy-CompressionStream -SourceStream $InputStream -DestinationStream $EntryStream -ProgressAction $ProgressAction -Phase 'Creating archive' -CompletedBytesBefore $CompletedBytes -TotalBytes $TotalBytes -CurrentItem $File.Name
            }
            finally {
                if ($null -ne $EntryStream) { $EntryStream.Dispose() }
                if ($null -ne $InputStream) { $InputStream.Dispose() }
            }
            $CompletedBytes += $File.Length
        }
        $GenerationCompleted = $true
    }
    finally {
        try {
            if ($null -ne $Archive) { $Archive.Dispose() }
            elseif ($null -ne $ArchiveStream) { $ArchiveStream.Dispose() }
        }
        catch {
            $GenerationCompleted = $false
            throw
        }
        finally {
            if ((-not $GenerationCompleted) -and (Test-Path -LiteralPath $StagedPath -PathType Leaf)) {
                [System.IO.File]::Delete($StagedPath)
            }
        }
    }

    try {
        if ($null -ne $ProgressAction) {
            [PSCustomObject]$ArchiveTest = Test-ZipArchive -ArchivePath $StagedPath -ProgressAction $ProgressAction -Phase 'Verifying archive'
        }
        else {
            [PSCustomObject]$ArchiveTest = Test-ZipArchive -ArchivePath $StagedPath
        }
        Publish-CompressionFile -StagedPath $StagedPath -DestinationPath $ArchivePath -Force:$Force
        return [PSCustomObject]@{
            ArchivePath       = $ArchivePath
            SourceDirectory   = $SourceRoot
            EntryCount        = $ArchiveTest.EntryCount
            UncompressedBytes = $ArchiveTest.UncompressedBytes
            CompressedBytes   = $ArchiveTest.CompressedBytes
            IsValid           = $ArchiveTest.IsValid
        }
    }
    finally {
        if (Test-Path -LiteralPath $StagedPath -PathType Leaf) {
            [System.IO.File]::Delete($StagedPath)
        }
    }
}

function Test-ZipArchive {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory=$true)]
        [System.String]$ArchivePath

        ,
        [Parameter(Mandatory=$false)]
        [AllowNull()]
        [ScriptBlock]$ProgressAction,

        [Parameter(Mandatory=$false)]
        [System.String]$Phase = 'Verifying archive'
    )

    Initialize-CompressionRuntime
    if (-not (Test-Path -LiteralPath $ArchivePath -PathType Leaf)) {
        throw "The archive file does not exist. ($ArchivePath)"
    }

    [System.IO.Compression.ZipArchive]$Archive = [System.IO.Compression.ZipFile]::OpenRead($ArchivePath)
    [long]$UncompressedBytes = 0
    [long]$CompressedBytes = 0
    [long]$TotalBytes = 0
    [int]$EntryCount = 0
    foreach ($Entry in $Archive.Entries) {
        $TotalBytes += $Entry.Length
    }
    [long]$CompletedBytes = 0
    try {
        foreach ($Entry in $Archive.Entries) {
            [System.IO.Stream]$EntryStream = $null
            try {
                $EntryStream = $Entry.Open()
                [long]$EntryBytes = Copy-CompressionStream -SourceStream $EntryStream -DestinationStream ([System.IO.Stream]::Null) -ProgressAction $ProgressAction -Phase $Phase -CompletedBytesBefore $CompletedBytes -TotalBytes $TotalBytes -CurrentItem ([System.IO.Path]::GetFileName($Entry.FullName))
                if ($EntryBytes -ne $Entry.Length) {
                    throw "The ZIP entry length does not match its directory record. ($($Entry.FullName))"
                }
                $UncompressedBytes += $EntryBytes
                $CompressedBytes += $Entry.CompressedLength
                $CompletedBytes += $EntryBytes
                $EntryCount++
            }
            finally {
                if ($null -ne $EntryStream) { $EntryStream.Dispose() }
            }
        }
    }
    finally {
        $Archive.Dispose()
    }

    return [PSCustomObject]@{
        ArchivePath       = [System.IO.Path]::GetFullPath($ArchivePath)
        IsValid           = $true
        EntryCount        = $EntryCount
        UncompressedBytes = $UncompressedBytes
        CompressedBytes   = $CompressedBytes
    }
}

function Expand-ZipArchive {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory=$true)]
        [System.String]$ArchivePath,

        [Parameter(Mandatory=$true)]
        [System.String]$DestinationPath,

        [Parameter(Mandatory=$false)]
        [System.Management.Automation.SwitchParameter]$Force

        ,
        [Parameter(Mandatory=$false)]
        [AllowNull()]
        [ScriptBlock]$ProgressAction
    )

    Initialize-CompressionRuntime
    if (-not (Test-Path -LiteralPath $ArchivePath -PathType Leaf)) {
        throw "The archive file does not exist. ($ArchivePath)"
    }

    [System.String]$DestinationRoot = [System.IO.Path]::GetFullPath($DestinationPath)
    [void][System.IO.Directory]::CreateDirectory($DestinationRoot)
    [System.IO.Compression.ZipArchive]$Archive = [System.IO.Compression.ZipFile]::OpenRead($ArchivePath)
    [System.Collections.Generic.List[object]]$ExtractionEntries = New-Object 'System.Collections.Generic.List[object]'
    [System.Collections.Hashtable]$SeenPaths = @{}
    [int]$FileCount = 0
    [int]$DirectoryCount = 0
    [long]$TotalBytes = 0
    foreach ($Entry in $Archive.Entries) {
        if (-not ($Entry.FullName.EndsWith('/') -or $Entry.FullName.EndsWith('\'))) {
            $TotalBytes += $Entry.Length
        }
    }
    [long]$CompletedBytes = 0

    try {
        foreach ($Entry in $Archive.Entries) {
            [System.String]$TargetPath = Get-CompressionExtractionPath -DestinationRoot $DestinationRoot -EntryName $Entry.FullName
            [System.Boolean]$IsDirectory = $Entry.FullName.EndsWith('/') -or $Entry.FullName.EndsWith('\')
            [System.String]$PathKey = $TargetPath.TrimEnd([char[]]@('\', '/'))
            if ($SeenPaths.ContainsKey($PathKey)) {
                throw "The archive contains duplicate paths. ($($Entry.FullName))"
            }
            $SeenPaths[$PathKey] = $true
            $ExtractionEntries.Add([PSCustomObject]@{ Entry = $Entry; TargetPath = $TargetPath; IsDirectory = $IsDirectory })
        }

        foreach ($ExtractionEntry in $ExtractionEntries) {
            if ($ExtractionEntry.IsDirectory) {
                [void][System.IO.Directory]::CreateDirectory($ExtractionEntry.TargetPath)
                $DirectoryCount++
                continue
            }

            [System.String]$ParentPath = [System.IO.Path]::GetDirectoryName($ExtractionEntry.TargetPath)
            if (-not [System.String]::IsNullOrEmpty($ParentPath)) {
                [void][System.IO.Directory]::CreateDirectory($ParentPath)
            }
            if ((Test-Path -LiteralPath $ExtractionEntry.TargetPath) -and (-not $Force)) {
                throw "The extracted file already exists. ($($ExtractionEntry.TargetPath))"
            }

            [System.IO.FileMode]$FileMode = if ($Force) { [System.IO.FileMode]::Create } else { [System.IO.FileMode]::CreateNew }
            [System.IO.Stream]$EntryStream = $null
            [System.IO.FileStream]$OutputStream = $null
            try {
                $EntryStream = $ExtractionEntry.Entry.Open()
                $OutputStream = [System.IO.File]::Open($ExtractionEntry.TargetPath, $FileMode, [System.IO.FileAccess]::Write, [System.IO.FileShare]::None)
                [long]$ExtractedBytes = Copy-CompressionStream -SourceStream $EntryStream -DestinationStream $OutputStream -ProgressAction $ProgressAction -Phase 'Restoring archive' -CompletedBytesBefore $CompletedBytes -TotalBytes $TotalBytes -CurrentItem ([System.IO.Path]::GetFileName($ExtractionEntry.Entry.FullName))
                if ($ExtractedBytes -ne $ExtractionEntry.Entry.Length) {
                    throw "The extracted ZIP entry length does not match its directory record. ($($ExtractionEntry.Entry.FullName))"
                }
            }
            finally {
                if ($null -ne $OutputStream) { $OutputStream.Dispose() }
                if ($null -ne $EntryStream) { $EntryStream.Dispose() }
            }
            $CompletedBytes += $ExtractedBytes
            $FileCount++
        }
    }
    finally {
        $Archive.Dispose()
    }

    return [PSCustomObject]@{
        ArchivePath       = [System.IO.Path]::GetFullPath($ArchivePath)
        DestinationPath   = $DestinationRoot
        ExtractedFileCount = $FileCount
        CreatedDirectories = $DirectoryCount
    }
}

function Set-ZipArchiveEntryFromFile {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory=$true)]
        [System.String]$ArchivePath,

        [Parameter(Mandatory=$true)]
        [System.String]$EntryName,

        [Parameter(Mandatory=$true)]
        [System.String]$SourceFilePath,

        [Parameter(Mandatory=$false)]
        [ValidateSet('Optimal','Fastest','NoCompression')]
        [System.String]$CompressionLevel = 'Optimal',

        [Parameter(Mandatory=$false)]
        [AllowNull()]
        [ScriptBlock]$ProgressAction
    )

    Initialize-CompressionRuntime
    if (-not (Test-Path -LiteralPath $ArchivePath -PathType Leaf)) {
        throw "The archive file does not exist. ($ArchivePath)"
    }
    if (-not (Test-Path -LiteralPath $SourceFilePath -PathType Leaf)) {
        throw "The replacement source file does not exist. ($SourceFilePath)"
    }

    [System.String]$NormalizedEntryName = ConvertTo-CompressionEntryName -EntryName $EntryName
    if ($NormalizedEntryName.EndsWith('/')) {
        throw 'A replacement ZIP entry must name a file, not a directory.'
    }
    [System.String]$FullArchivePath = [System.IO.Path]::GetFullPath($ArchivePath)
    [System.String]$ArchiveParent = [System.IO.Path]::GetDirectoryName($FullArchivePath)
    [System.String]$StagedPath = Join-Path -Path $ArchiveParent -ChildPath ('.' + [System.IO.Path]::GetFileName($FullArchivePath) + '.partial-' + [System.Guid]::NewGuid().ToString('N'))
    [System.IO.Compression.CompressionLevel]$Level = [System.IO.Compression.CompressionLevel]::$CompressionLevel
    [System.IO.Compression.ZipArchive]$SourceArchive = $null
    [System.IO.Compression.ZipArchive]$DestinationArchive = $null
    [System.IO.FileStream]$DestinationStream = $null
    [System.Boolean]$EntryReplaced = $false
    [System.Boolean]$GenerationCompleted = $false
    [System.IO.FileInfo]$ReplacementFile = Get-Item -LiteralPath $SourceFilePath -Force
    [long]$TotalBytes = $ReplacementFile.Length
    [long]$CompletedBytes = 0

    try {
        $SourceArchive = [System.IO.Compression.ZipFile]::OpenRead($FullArchivePath)
        foreach ($SourceEntry in $SourceArchive.Entries) {
            if (-not [System.String]::Equals($SourceEntry.FullName.Replace('\', '/'), $NormalizedEntryName, [System.StringComparison]::OrdinalIgnoreCase)) {
                $TotalBytes += $SourceEntry.Length
            }
        }
        $DestinationStream = [System.IO.File]::Open($StagedPath, [System.IO.FileMode]::CreateNew, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None)
        $DestinationArchive = [System.IO.Compression.ZipArchive]::new($DestinationStream, [System.IO.Compression.ZipArchiveMode]::Create, $false)

        foreach ($SourceEntry in $SourceArchive.Entries) {
            [System.String]$SourceEntryName = $SourceEntry.FullName.Replace('\', '/')
            if ([System.String]::Equals($SourceEntryName, $NormalizedEntryName, [System.StringComparison]::OrdinalIgnoreCase)) {
                if ($EntryReplaced) { continue }
                [System.IO.Compression.ZipArchiveEntry]$ReplacementEntry = $DestinationArchive.CreateEntry($NormalizedEntryName, $Level)
                Set-CompressionEntryTimestamp -Entry $ReplacementEntry -LastWriteTime ([System.IO.File]::GetLastWriteTime($SourceFilePath))
                [System.IO.Stream]$ReplacementStream = $null
                [System.IO.Stream]$ReplacementSource = $null
                try {
                    $ReplacementStream = $ReplacementEntry.Open()
                    $ReplacementSource = [System.IO.File]::OpenRead($SourceFilePath)
                    $null = Copy-CompressionStream -SourceStream $ReplacementSource -DestinationStream $ReplacementStream -ProgressAction $ProgressAction -Phase 'Updating archive log' -CompletedBytesBefore $CompletedBytes -TotalBytes $TotalBytes -CurrentItem ([System.IO.Path]::GetFileName($SourceFilePath))
                }
                finally {
                    if ($null -ne $ReplacementStream) { $ReplacementStream.Dispose() }
                    if ($null -ne $ReplacementSource) { $ReplacementSource.Dispose() }
                }
                $CompletedBytes += $ReplacementFile.Length
                $EntryReplaced = $true
                continue
            }

            [System.IO.Compression.ZipArchiveEntry]$CopiedEntry = $DestinationArchive.CreateEntry($SourceEntry.FullName, $Level)
            $CopiedEntry.LastWriteTime = $SourceEntry.LastWriteTime
            $CopiedEntry.ExternalAttributes = $SourceEntry.ExternalAttributes
            [System.IO.Stream]$SourceEntryStream = $null
            [System.IO.Stream]$CopiedEntryStream = $null
            try {
                $SourceEntryStream = $SourceEntry.Open()
                $CopiedEntryStream = $CopiedEntry.Open()
                $null = Copy-CompressionStream -SourceStream $SourceEntryStream -DestinationStream $CopiedEntryStream -ProgressAction $ProgressAction -Phase 'Updating archive log' -CompletedBytesBefore $CompletedBytes -TotalBytes $TotalBytes -CurrentItem ([System.IO.Path]::GetFileName($SourceEntry.FullName))
            }
            finally {
                if ($null -ne $CopiedEntryStream) { $CopiedEntryStream.Dispose() }
                if ($null -ne $SourceEntryStream) { $SourceEntryStream.Dispose() }
            }
            $CompletedBytes += $SourceEntry.Length
        }

        if (-not $EntryReplaced) {
            [System.IO.Compression.ZipArchiveEntry]$NewEntry = $DestinationArchive.CreateEntry($NormalizedEntryName, $Level)
            Set-CompressionEntryTimestamp -Entry $NewEntry -LastWriteTime ([System.IO.File]::GetLastWriteTime($SourceFilePath))
            [System.IO.Stream]$NewEntryStream = $null
            [System.IO.Stream]$NewEntrySource = $null
            try {
                $NewEntryStream = $NewEntry.Open()
                $NewEntrySource = [System.IO.File]::OpenRead($SourceFilePath)
                $null = Copy-CompressionStream -SourceStream $NewEntrySource -DestinationStream $NewEntryStream -ProgressAction $ProgressAction -Phase 'Updating archive log' -CompletedBytesBefore $CompletedBytes -TotalBytes $TotalBytes -CurrentItem ([System.IO.Path]::GetFileName($SourceFilePath))
            }
            finally {
                if ($null -ne $NewEntryStream) { $NewEntryStream.Dispose() }
                if ($null -ne $NewEntrySource) { $NewEntrySource.Dispose() }
            }
            $CompletedBytes += $ReplacementFile.Length
        }
        $GenerationCompleted = $true
    }
    finally {
        try {
            try {
                if ($null -ne $DestinationArchive) { $DestinationArchive.Dispose() }
                elseif ($null -ne $DestinationStream) { $DestinationStream.Dispose() }
            }
            finally {
                if ($null -ne $SourceArchive) { $SourceArchive.Dispose() }
            }
        }
        catch {
            $GenerationCompleted = $false
            throw
        }
        finally {
            if ((-not $GenerationCompleted) -and (Test-Path -LiteralPath $StagedPath -PathType Leaf)) {
                [System.IO.File]::Delete($StagedPath)
            }
        }
    }

    try {
        if ($null -ne $ProgressAction) {
            [PSCustomObject]$ArchiveTest = Test-ZipArchive -ArchivePath $StagedPath -ProgressAction $ProgressAction -Phase 'Verifying updated archive'
        }
        else {
            [PSCustomObject]$ArchiveTest = Test-ZipArchive -ArchivePath $StagedPath
        }
        Publish-CompressionFile -StagedPath $StagedPath -DestinationPath $FullArchivePath -Force
        return [PSCustomObject]@{
            ArchivePath       = $FullArchivePath
            EntryName         = $NormalizedEntryName
            EntryReplaced     = $EntryReplaced
            EntryCount        = $ArchiveTest.EntryCount
            UncompressedBytes = $ArchiveTest.UncompressedBytes
            IsValid           = $ArchiveTest.IsValid
        }
    }
    finally {
        if (Test-Path -LiteralPath $StagedPath -PathType Leaf) {
            [System.IO.File]::Delete($StagedPath)
        }
    }
}

Export-ModuleMember -Function New-ZipArchiveFromDirectory, Expand-ZipArchive, Test-ZipArchive, Set-ZipArchiveEntryFromFile, New-CompressionProgressDialog