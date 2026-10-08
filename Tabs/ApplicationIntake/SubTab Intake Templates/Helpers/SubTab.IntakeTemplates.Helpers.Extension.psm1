####################################################################################################
<#
.SYNOPSIS
    Creates distributable Customer Extension ZIP files from customer template bundles.
.DESCRIPTION
    A Customer Extension is a ZIP file that contains one customer template bundle (manifest,
    component files and Word templates) plus an Extension.psd1 file describing the package.
    The package version is derived from the newest file in the bundle (Year.Month.Day.HHmm) and a
    SHA-256 content fingerprint identifies whether the bundle content changed.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.9.0
    Author          : Imraan Iotana
    Creation Date   : October 2026
    Last Update     : October 2026
#>
####################################################################################################


# The only file types a Customer Extension may contain
[System.String[]]$Script:CustomerExtensionAllowedExtensions = @('.psd1','.dotx')


####################################################################################################
<#
.SYNOPSIS
    Verifies that the folder values of a customer template stay inside the application folder.
.DESCRIPTION
    Throws when an application subfolder value is rooted, contains a drive or invalid characters, or
    uses a parent folder segment (..).
.EXAMPLE
    Assert-CustomerTemplateFolderPaths -Content $ManifestData
.INPUTS
    [System.Collections.IDictionary]
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    Version         : 6.9.0
#>
####################################################################################################
function Assert-CustomerTemplateFolderPaths {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The imported manifest data of the customer template.')]
        [System.Collections.IDictionary]$Content
    )

    if ((-not $Content.Contains('ApplicationFolderSubFolders')) -or ($Content.ApplicationFolderSubFolders -isnot [System.Collections.IDictionary])) {
        return
    }
    foreach ($Entry in $Content.ApplicationFolderSubFolders.GetEnumerator()) {
        # Only string values are folder paths; option lists such as the postfix options are skipped
        if ($Entry.Value -isnot [System.String]) { continue }
        [System.String]$FolderPath = [System.String]$Entry.Value
        [System.Boolean]$IsUnsafe = [System.String]::IsNullOrWhiteSpace($FolderPath) -or
            ($FolderPath -match '[:*?"<>|]') -or
            ($FolderPath.IndexOfAny([System.IO.Path]::GetInvalidPathChars()) -ge 0) -or
            [System.IO.Path]::IsPathRooted($FolderPath) -or
            (@($FolderPath.Split([char[]]@('\','/')) | Where-Object { $_ -eq '..' }).Count -gt 0)
        if ($IsUnsafe) {
            throw "The application folder '$($Entry.Key)' has an unsafe path. ($FolderPath)"
        }
    }
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Verifies that a customer template bundle folder only contains files allowed in an extension.
.DESCRIPTION
    Throws when the folder contains a file type outside the allowed list or a temporary Word lock file.
.EXAMPLE
    Assert-CustomerExtensionBundleFiles -BundleDirectory 'C:\ADA\Customer\Contoso'
.INPUTS
    [System.String]
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    Version         : 6.9.0
#>
####################################################################################################
function Assert-CustomerExtensionBundleFiles {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The customer template bundle folder.')]
        [System.String]$BundleDirectory
    )

    foreach ($File in (Get-ChildItem -LiteralPath $BundleDirectory -File -Recurse -Force -ErrorAction Stop)) {
        if ($File.Name -eq 'Extension.psd1') { continue }
        if ($File.Name.StartsWith('~$')) {
            throw "A temporary Word file is present. Close the template in Word and try again. ($($File.FullName))"
        }
        if ($Script:CustomerExtensionAllowedExtensions -notcontains $File.Extension.ToLowerInvariant()) {
            throw "The bundle contains a file type that is not allowed in a Customer Extension ($($Script:CustomerExtensionAllowedExtensions -join ', ') only). ($($File.Name))"
        }
    }
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Checks the structure and size of a Customer Extension ZIP file before it is extracted.
.DESCRIPTION
    Reads every entry with a hard byte limit instead of trusting the sizes declared in the ZIP file,
    and rejects too many entries, oversized content, unsafe entry names, files outside the descriptor
    and bundle folder, and file types that are not allowed.
.EXAMPLE
    Test-CustomerExtensionArchive -ArchivePath 'C:\Temp\ADA Customer Extension - Contoso.zip'
.INPUTS
    [System.String]
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    Version         : 6.9.0
#>
####################################################################################################
function Test-CustomerExtensionArchive {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The Customer Extension ZIP file.')]
        [System.String]$ArchivePath,

        [Parameter(Mandatory=$false,HelpMessage='The maximum number of entries.')]
        [System.Int32]$MaximumEntryCount = 200,

        [Parameter(Mandatory=$false,HelpMessage='The maximum size of one entry in bytes.')]
        [System.Int64]$MaximumEntryBytes = 50MB,

        [Parameter(Mandatory=$false,HelpMessage='The maximum total size of all entries in bytes.')]
        [System.Int64]$MaximumTotalBytes = 100MB
    )

    Add-Type -AssemblyName System.IO.Compression -ErrorAction Stop
    Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction Stop
    if (-not (Test-Path -LiteralPath $ArchivePath -PathType Leaf)) {
        throw "The ZIP file does not exist. ($ArchivePath)"
    }

    [System.IO.Compression.ZipArchive]$Archive = [System.IO.Compression.ZipFile]::OpenRead($ArchivePath)
    try {
        if ($Archive.Entries.Count -gt $MaximumEntryCount) {
            throw "The ZIP file contains too many entries. (maximum $MaximumEntryCount)"
        }

        [System.Int64]$TotalBytes = 0
        [System.Byte[]]$Buffer = New-Object System.Byte[] 65536
        foreach ($Entry in $Archive.Entries) {
            # VALIDATION - ENTRY NAME
            [System.String]$EntryName = $Entry.FullName.Replace('\','/')
            if ($EntryName.StartsWith('/') -or ($EntryName -match '^[A-Za-z]:') -or (@($EntryName.Split('/') | Where-Object { $_ -eq '..' }).Count -gt 0)) {
                throw "The ZIP file contains an unsafe entry name. ($($Entry.FullName))"
            }
            if ($EntryName.EndsWith('/')) { continue }

            # VALIDATION - ENTRY LOCATION AND TYPE
            [System.String]$FileName = [System.IO.Path]::GetFileName($EntryName)
            if (($EntryName.IndexOf('/') -lt 0) -and ($EntryName -ne 'Extension.psd1')) {
                throw "The ZIP file contains an unexpected file at its root. ($($Entry.FullName))"
            }
            if ($FileName.StartsWith('~$') -or ($Script:CustomerExtensionAllowedExtensions -notcontains [System.IO.Path]::GetExtension($FileName).ToLowerInvariant())) {
                throw "The ZIP file contains a file type that is not allowed ($($Script:CustomerExtensionAllowedExtensions -join ', ') only). ($($Entry.FullName))"
            }

            # VALIDATION - ENTRY SIZE
            # Count the real decompressed bytes and stop at the limit
            [System.Int64]$EntryBytes = 0
            [System.IO.Stream]$EntryStream = $Entry.Open()
            try {
                [System.Int32]$BytesRead = 0
                while (($BytesRead = $EntryStream.Read($Buffer,0,$Buffer.Length)) -gt 0) {
                    $EntryBytes += $BytesRead
                    $TotalBytes += $BytesRead
                    if ($EntryBytes -gt $MaximumEntryBytes) {
                        throw "A file in the ZIP file is too large. ($($Entry.FullName))"
                    }
                    if ($TotalBytes -gt $MaximumTotalBytes) {
                        throw 'The ZIP file is too large when extracted.'
                    }
                }
            }
            finally {
                $EntryStream.Dispose()
            }
            if ($EntryBytes -ne $Entry.Length) {
                throw "The ZIP entry length does not match its directory record. ($($Entry.FullName))"
            }
        }
    }
    finally {
        $Archive.Dispose()
    }
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Gets the content fingerprint and version of a customer template bundle.
.DESCRIPTION
    Hashes every file in the bundle (relative path plus SHA-256 of the content, in a fixed order,
    ignoring Extension.psd1) and derives the version from the newest file write time as
    Year.Month.Day.HHmm, for example 2026.10.5.1432.
.EXAMPLE
    Get-CustomerTemplateBundleFingerprint -BundleDirectory 'C:\ADA\Customer\Contoso'
.INPUTS
    [System.String]
.OUTPUTS
    [PSCustomObject] with ContentHash, ContentTimestamp, Version and FileCount.
.NOTES
    Version         : 6.9.0
#>
####################################################################################################
function Get-CustomerTemplateBundleFingerprint {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The customer template bundle folder.')]
        [System.String]$BundleDirectory
    )

    # VALIDATION - BUNDLE FOLDER
    [System.String]$BundleRoot = [System.IO.Path]::GetFullPath($BundleDirectory).TrimEnd([char[]]@('\','/'))
    if (-not (Test-Path -LiteralPath $BundleRoot -PathType Container)) {
        throw "The customer template folder does not exist. ($BundleRoot)"
    }

    # PREPARATION - FILES
    # Index the files by lowercase relative path so the hash order is identical on every computer
    [System.Collections.Hashtable]$FilesByPath = @{}
    foreach ($File in (Get-ChildItem -LiteralPath $BundleRoot -File -Recurse -Force -ErrorAction Stop)) {
        if ($File.Name -eq 'Extension.psd1') { continue }
        [System.String]$RelativePath = $File.FullName.Substring($BundleRoot.Length).TrimStart([char[]]@('\','/')).Replace('\','/').ToLowerInvariant()
        $FilesByPath[$RelativePath] = $File
    }
    if ($FilesByPath.Count -eq 0) {
        throw "The customer template folder does not contain any files. ($BundleRoot)"
    }
    [System.String[]]$SortedPaths = [System.String[]]@($FilesByPath.Keys)
    [System.Array]::Sort($SortedPaths,[System.StringComparer]::Ordinal)

    # EXECUTION - HASH THE CONTENT
    [System.Collections.Generic.List[System.String]]$HashLines = New-Object 'System.Collections.Generic.List[System.String]'
    [System.DateTime]$NewestWriteTime = [System.DateTime]::MinValue
    foreach ($RelativePath in $SortedPaths) {
        [System.IO.FileInfo]$File = $FilesByPath[$RelativePath]
        [void]$HashLines.Add($RelativePath + '|' + (Get-FileHash -LiteralPath $File.FullName -Algorithm SHA256 -ErrorAction Stop).Hash)
        if ($File.LastWriteTime -gt $NewestWriteTime) { $NewestWriteTime = $File.LastWriteTime }
    }
    [System.Security.Cryptography.SHA256]$Sha256 = [System.Security.Cryptography.SHA256]::Create()
    try {
        [System.Byte[]]$HashBytes = $Sha256.ComputeHash([System.Text.Encoding]::UTF8.GetBytes(($HashLines -join "`n")))
    }
    finally {
        $Sha256.Dispose()
    }

    # OUTPUT
    return [PSCustomObject]@{
        ContentHash      = ([System.BitConverter]::ToString($HashBytes)).Replace('-','')
        ContentTimestamp = $NewestWriteTime
        Version          = [System.Version]::new($NewestWriteTime.Year,$NewestWriteTime.Month,$NewestWriteTime.Day,(($NewestWriteTime.Hour * 100) + $NewestWriteTime.Minute))
        FileCount        = $FilesByPath.Count
    }
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Creates a Customer Extension ZIP file from a customer template bundle.
.DESCRIPTION
    Validates the bundle, derives its version and content fingerprint, copies it to a temporary
    staging folder together with a generated Extension.psd1, and creates a verified ZIP file in
    the destination folder.
.EXAMPLE
    New-CustomerExtensionPackage -CustomerTemplate $Template -ApplicationVersion '6.9.0' -DestinationFolder 'C:\Output'
.INPUTS
    [System.Object]
    [System.Version]
    [System.String]
.OUTPUTS
    [PSCustomObject] describing the created ZIP file.
.NOTES
    Version         : 6.9.0
#>
####################################################################################################
function New-CustomerExtensionPackage {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The discovered customer template object to package.')]
        [System.Object]$CustomerTemplate,

        [Parameter(Mandatory=$true,HelpMessage='The version of the application creating the package.')]
        [System.Version]$ApplicationVersion,

        [Parameter(Mandatory=$true,HelpMessage='The folder in which the ZIP file is created.')]
        [System.String]$DestinationFolder
    )

    [System.String]$StagingFolder = ''
    try {
        # VALIDATION - BUNDLE FOLDER
        [System.String]$TemplateDirectory = [System.IO.Path]::GetFullPath([System.String]$CustomerTemplate.Directory).TrimEnd([char[]]@('\','/'))
        if (-not (Test-Path -LiteralPath $TemplateDirectory -PathType Container)) {
            throw "The customer template folder does not exist. ($TemplateDirectory)"
        }
        Assert-CustomerExtensionBundleFiles -BundleDirectory $TemplateDirectory

        # VALIDATION - TEMPLATES
        # A bundle folder can hold several template variants; each must be a complete Schema 2 manifest
        [System.IO.FileInfo[]]$ManifestFiles = @(Get-ChildItem -LiteralPath $TemplateDirectory -Filter 'Settings.Customer.*.psd1' -File | Sort-Object -Property Name)
        if ($ManifestFiles.Count -eq 0) {
            throw "The customer template folder does not contain a manifest. ($TemplateDirectory)"
        }
        [System.Collections.Generic.List[System.String]]$TemplateEntryLines = New-Object 'System.Collections.Generic.List[System.String]'
        [System.Collections.Generic.List[System.String]]$Identities = New-Object 'System.Collections.Generic.List[System.String]'
        foreach ($ManifestFile in $ManifestFiles) {
            [System.Collections.Hashtable]$Content = Import-CustomerTemplateData -SettingsFilePath $ManifestFile.FullName
            if ((-not $Content.ContainsKey('TemplateId')) -or (-not $Content.ContainsKey('Identity'))) {
                throw "Only Schema 2 customer templates with an Identity and TemplateId can be packaged. ($($ManifestFile.Name))"
            }
            Assert-CustomerTemplateWordTemplates -BundleDirectory $TemplateDirectory -Content $Content
            Assert-CustomerTemplateFolderPaths -Content $Content
            [void]$Identities.Add([System.String]$Content.Identity)
            [void]$TemplateEntryLines.Add("        @{ Identity = '$(([System.String]$Content.Identity).Replace("'","''"))'; TemplateId = '$([System.String]$Content.TemplateId)'; ManifestFileName = '$($ManifestFile.Name.Replace("'","''"))' }")
        }

        # PREPARATION - VERSION AND NAMES
        [PSCustomObject]$Fingerprint = Get-CustomerTemplateBundleFingerprint -BundleDirectory $TemplateDirectory
        [System.String]$FolderName = [System.IO.Path]::GetFileName($TemplateDirectory)
        [System.String]$SafeFolderName = $FolderName
        foreach ($InvalidCharacter in [System.IO.Path]::GetInvalidFileNameChars()) {
            $SafeFolderName = $SafeFolderName.Replace($InvalidCharacter,'_')
        }
        [System.String]$VersionForFileName = $Fingerprint.ContentTimestamp.ToString('yyyy.MM.dd-HHmm')
        [System.String]$ArchivePath = Join-Path -Path $DestinationFolder -ChildPath "ADA Customer Extension - $SafeFolderName - $VersionForFileName.zip"

        # EXECUTION - STAGE THE BUNDLE
        $StagingFolder = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath ('ADA-CustomerExtension-' + [System.Guid]::NewGuid().ToString('N'))
        New-Item -Path $StagingFolder -ItemType Directory -ErrorAction Stop | Out-Null
        Copy-Item -LiteralPath $TemplateDirectory -Destination (Join-Path -Path $StagingFolder -ChildPath $FolderName) -Recurse -ErrorAction Stop
        # An installed bundle carries its own descriptor; the package gets a fresh one at the root
        Remove-Item -LiteralPath (Join-Path -Path (Join-Path -Path $StagingFolder -ChildPath $FolderName) -ChildPath 'Extension.psd1') -Force -ErrorAction SilentlyContinue

        # EXECUTION - WRITE THE EXTENSION DESCRIPTOR
        [System.String]$EscapedFolderName = $FolderName.Replace("'","''")
        [System.String[]]$DescriptorLines = @(
            '@{'
            '    ExtensionSchemaVersion    = 1'
            "    Name                      = '$EscapedFolderName'"
            "    FolderName                = '$EscapedFolderName'"
            "    Version                   = '$($Fingerprint.Version)'"
            "    ContentTimestamp          = '$($Fingerprint.ContentTimestamp.ToString('s'))'"
            "    ContentHash               = '$($Fingerprint.ContentHash)'"
            "    MinimumApplicationVersion = '$ApplicationVersion'"
            "    CreatedOn                 = '$((Get-Date).ToString('yyyy-MM-dd'))'"
            '    Templates                 = @('
        ) + $TemplateEntryLines + @(
            '    )'
            '}'
        )
        [System.IO.File]::WriteAllText((Join-Path -Path $StagingFolder -ChildPath 'Extension.psd1'),($DescriptorLines -join [System.Environment]::NewLine),(New-Object System.Text.UTF8Encoding($true)))

        # EXECUTION - CREATE THE ZIP FILE
        [PSCustomObject]$ArchiveResult = New-ZipArchiveFromDirectory -SourceDirectory $StagingFolder -DestinationPath $ArchivePath -Force
        if (-not $ArchiveResult.IsValid) {
            throw "The Customer Extension ZIP file failed verification. ($ArchivePath)"
        }

        # OUTPUT
        return [PSCustomObject]@{
            ArchivePath      = $ArchiveResult.ArchivePath
            Name             = $FolderName
            Identities       = [System.String[]]$Identities.ToArray()
            ExtensionVersion = $Fingerprint.Version
            ContentHash      = $Fingerprint.ContentHash
            EntryCount       = $ArchiveResult.EntryCount
        }
    }
    finally {
        # POST-EXECUTION - CLEANUP
        if ((-not [System.String]::IsNullOrWhiteSpace($StagingFolder)) -and (Test-Path -LiteralPath $StagingFolder)) {
            Remove-Item -LiteralPath $StagingFolder -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Verifies that the Word templates defined by a customer template exist in its bundle folder.
.DESCRIPTION
    Checks the TemplateName and TatTemplateName entries and throws when a name is unsafe or the file is missing.
.EXAMPLE
    Assert-CustomerTemplateWordTemplates -BundleDirectory 'C:\Bundle' -Content $ManifestData
.INPUTS
    [System.String]
    [System.Collections.IDictionary]
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    Version         : 6.9.0
#>
####################################################################################################
function Assert-CustomerTemplateWordTemplates {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The customer template bundle folder.')]
        [System.String]$BundleDirectory,

        [Parameter(Mandatory=$true,HelpMessage='The imported manifest data of the customer template.')]
        [System.Collections.IDictionary]$Content
    )

    foreach ($TemplateKey in @('TemplateName','TatTemplateName')) {
        if ($Content.Contains($TemplateKey) -and (-not [System.String]::IsNullOrWhiteSpace([System.String]$Content[$TemplateKey]))) {
            [System.String]$WordTemplateName = [System.String]$Content[$TemplateKey]
            if ($WordTemplateName -ne [System.IO.Path]::GetFileName($WordTemplateName)) {
                throw "The Word template defined by $TemplateKey is not a plain file name. ($WordTemplateName)"
            }
            [System.String]$WordTemplatePath = Join-Path -Path $BundleDirectory -ChildPath $WordTemplateName
            if (-not (Test-Path -LiteralPath $WordTemplatePath -PathType Leaf)) {
                throw "The Word template defined by $TemplateKey is missing from the bundle. ($WordTemplatePath)"
            }
        }
    }
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Validates an extracted Customer Extension and returns its content.
.DESCRIPTION
    Reads Extension.psd1, checks the schema, application version requirement, folder name, content
    fingerprint, and every template manifest of the extracted bundle. Throws when anything is invalid.
.EXAMPLE
    Get-CustomerExtensionContent -ExtractedFolder 'C:\Temp\Extension' -ApplicationVersion '6.9.0'
.INPUTS
    [System.String]
    [System.Version]
.OUTPUTS
    [PSCustomObject] with Name, FolderName, Version, ContentHash, BundleFolder and Templates.
.NOTES
    Version         : 6.9.0
#>
####################################################################################################
function Get-CustomerExtensionContent {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The folder into which the Customer Extension ZIP file was extracted.')]
        [System.String]$ExtractedFolder,

        [Parameter(Mandatory=$true,HelpMessage='The version of the running application.')]
        [System.Version]$ApplicationVersion
    )

    # VALIDATION - DESCRIPTOR
    [System.String]$DescriptorPath = Join-Path -Path $ExtractedFolder -ChildPath 'Extension.psd1'
    if (-not (Test-Path -LiteralPath $DescriptorPath -PathType Leaf)) {
        throw 'The ZIP file is not a Customer Extension, because Extension.psd1 is missing.'
    }
    [System.Collections.Hashtable]$Descriptor = Import-PowerShellDataFile -LiteralPath $DescriptorPath
    if ((-not $Descriptor.ContainsKey('ExtensionSchemaVersion')) -or ([System.Int32]$Descriptor.ExtensionSchemaVersion -ne 1)) {
        throw 'The Customer Extension uses an unsupported schema version.'
    }
    foreach ($RequiredKey in @('Name','FolderName','Version','ContentHash','MinimumApplicationVersion','Templates')) {
        if (-not $Descriptor.ContainsKey($RequiredKey)) {
            throw "The Customer Extension descriptor does not define $RequiredKey."
        }
    }

    # VALIDATION - VERSIONS
    [System.Version]$ExtensionVersion = $null
    if (-not [System.Version]::TryParse([System.String]$Descriptor.Version,[ref]$ExtensionVersion)) {
        throw "The Customer Extension version is not valid. ($($Descriptor.Version))"
    }
    [System.Version]$MinimumVersion = $null
    if (-not [System.Version]::TryParse([System.String]$Descriptor.MinimumApplicationVersion,[ref]$MinimumVersion)) {
        throw "The minimum application version of the Customer Extension is not valid. ($($Descriptor.MinimumApplicationVersion))"
    }
    if ($ApplicationVersion -lt $MinimumVersion) {
        throw "This Customer Extension requires application version $MinimumVersion or newer. This is version $ApplicationVersion."
    }

    # VALIDATION - BUNDLE FOLDER
    [System.String]$FolderName = [System.String]$Descriptor.FolderName
    if ([System.String]::IsNullOrWhiteSpace($FolderName) -or $FolderName.StartsWith('.') -or ($FolderName -ne $FolderName.Trim()) -or ($FolderName.IndexOfAny([System.IO.Path]::GetInvalidFileNameChars()) -ge 0)) {
        throw "The Customer Extension folder name is not valid. ($FolderName)"
    }
    [System.String]$BundleFolder = Join-Path -Path $ExtractedFolder -ChildPath $FolderName
    if (-not (Test-Path -LiteralPath $BundleFolder -PathType Container)) {
        throw "The Customer Extension does not contain its bundle folder. ($FolderName)"
    }
    [PSCustomObject]$Fingerprint = Get-CustomerTemplateBundleFingerprint -BundleDirectory $BundleFolder
    if (-not $Fingerprint.ContentHash.Equals([System.String]$Descriptor.ContentHash,[System.StringComparison]::OrdinalIgnoreCase)) {
        throw 'The content of the Customer Extension does not match its fingerprint. The ZIP file may be damaged or modified.'
    }

    # VALIDATION - TEMPLATES
    [System.Collections.Generic.List[PSCustomObject]]$Templates = New-Object 'System.Collections.Generic.List[PSCustomObject]'
    foreach ($Entry in @($Descriptor.Templates)) {
        [System.String]$Identity = [System.String]$Entry.Identity
        [System.String]$ManifestFileName = [System.String]$Entry.ManifestFileName
        [System.Guid]$TemplateId = [System.Guid]::Empty
        if ([System.String]::IsNullOrWhiteSpace($Identity) -or (-not [System.Guid]::TryParse([System.String]$Entry.TemplateId,[ref]$TemplateId))) {
            throw 'A template in the Customer Extension descriptor has no valid Identity or TemplateId.'
        }
        if (($ManifestFileName -ne [System.IO.Path]::GetFileName($ManifestFileName)) -or (-not ($ManifestFileName -like 'Settings.Customer.*.psd1'))) {
            throw "A template in the Customer Extension descriptor has an invalid manifest name. ($ManifestFileName)"
        }
        [System.String]$ManifestPath = Join-Path -Path $BundleFolder -ChildPath $ManifestFileName
        if (-not (Test-Path -LiteralPath $ManifestPath -PathType Leaf)) {
            throw "The manifest of '$Identity' is missing from the Customer Extension. ($ManifestFileName)"
        }
        [System.Collections.Hashtable]$ManifestData = Import-CustomerTemplateData -SettingsFilePath $ManifestPath
        if ((-not $ManifestData.ContainsKey('TemplateId')) -or ([System.Guid]$ManifestData.TemplateId -ne $TemplateId)) {
            throw "The manifest of '$Identity' does not match its TemplateId in the descriptor."
        }
        Assert-CustomerTemplateWordTemplates -BundleDirectory $BundleFolder -Content $ManifestData
        Assert-CustomerTemplateFolderPaths -Content $ManifestData
        [void]$Templates.Add([PSCustomObject]@{
            Identity         = $Identity
            TemplateId       = $TemplateId
            ManifestFileName = $ManifestFileName
        })
    }
    if ($Templates.Count -eq 0) {
        throw 'The Customer Extension does not contain any templates.'
    }

    # OUTPUT
    return [PSCustomObject]@{
        Name        = [System.String]$Descriptor.Name
        FolderName  = $FolderName
        Version     = $ExtensionVersion
        ContentHash = $Fingerprint.ContentHash
        BundleFolder = $BundleFolder
        Templates   = $Templates.ToArray()
    }
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Reads the state of an installed Customer Extension bundle folder.
.DESCRIPTION
    Recomputes the content fingerprint of the installed folder and compares it with the descriptor
    stored at installation, so local changes can be detected.
.EXAMPLE
    Get-InstalledCustomerExtensionState -InstalledFolder 'C:\Users\Me\AppData\Roaming\Application Delivery Assistant\Customer Templates\Contoso'
.INPUTS
    [System.String]
.OUTPUTS
    [PSCustomObject] with Exists, HasDescriptor, InstalledVersion, CurrentVersion, CurrentHash and LocallyModified.
.NOTES
    Version         : 6.9.0
#>
####################################################################################################
function Get-InstalledCustomerExtensionState {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The folder in which the extension bundle would be installed.')]
        [System.String]$InstalledFolder
    )

    if (-not (Test-Path -LiteralPath $InstalledFolder -PathType Container)) {
        return [PSCustomObject]@{ Exists = $false; HasDescriptor = $false; InstalledVersion = $null; CurrentVersion = $null; CurrentHash = ''; LocallyModified = $false }
    }

    [PSCustomObject]$Fingerprint = Get-CustomerTemplateBundleFingerprint -BundleDirectory $InstalledFolder
    [System.Version]$InstalledVersion = $Fingerprint.Version
    [System.String]$RecordedHash = ''
    [System.Boolean]$HasDescriptor = $false
    [System.String]$DescriptorPath = Join-Path -Path $InstalledFolder -ChildPath 'Extension.psd1'
    if (Test-Path -LiteralPath $DescriptorPath -PathType Leaf) {
        try {
            [System.Collections.Hashtable]$Recorded = Import-PowerShellDataFile -LiteralPath $DescriptorPath
            [System.Version]$RecordedVersion = $null
            if ($Recorded.ContainsKey('ContentHash') -and $Recorded.ContainsKey('Version') -and [System.Version]::TryParse([System.String]$Recorded.Version,[ref]$RecordedVersion)) {
                $RecordedHash = [System.String]$Recorded.ContentHash
                $InstalledVersion = $RecordedVersion
                $HasDescriptor = $true
            }
        }
        catch {
            # A damaged descriptor is treated like a missing one, so the folder counts as not installed from an extension
            $HasDescriptor = $false
        }
    }

    return [PSCustomObject]@{
        Exists           = $true
        HasDescriptor    = $HasDescriptor
        InstalledVersion = $InstalledVersion
        CurrentVersion   = $Fingerprint.Version
        CurrentHash      = $Fingerprint.ContentHash
        LocallyModified  = ((-not $HasDescriptor) -or (-not $Fingerprint.ContentHash.Equals($RecordedHash,[System.StringComparison]::OrdinalIgnoreCase)))
    }
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Moves a folder, retrying and falling back to copy and delete when a rename is denied.
.DESCRIPTION
    Renaming a freshly written folder can fail with an access denied error while antivirus software
    still scans its files. The move is retried; as a last resort the folder is copied and the source removed.
.EXAMPLE
    Move-CustomerExtensionFolder -SourcePath 'C:\Temp\.Contoso.partial' -DestinationPath 'C:\Templates\Contoso'
.INPUTS
    [System.String]
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    Version         : 6.9.0
#>
####################################################################################################
function Move-CustomerExtensionFolder {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The folder to move.')]
        [System.String]$SourcePath,

        [Parameter(Mandatory=$true,HelpMessage='The new location of the folder. It must not exist.')]
        [System.String]$DestinationPath
    )

    # EXECUTION - RENAME WITH RETRIES
    for ([System.Int32]$Attempt = 1; $Attempt -le 5; $Attempt++) {
        try {
            [System.IO.Directory]::Move($SourcePath,$DestinationPath)
            return
        }
        catch [System.UnauthorizedAccessException],[System.IO.IOException] {
            if (Test-Path -LiteralPath $DestinationPath) { throw }
            Start-Sleep -Milliseconds 300
        }
    }

    # EXECUTION - COPY FALLBACK
    try {
        Copy-Item -LiteralPath $SourcePath -Destination $DestinationPath -Recurse -ErrorAction Stop
    }
    catch {
        if (Test-Path -LiteralPath $DestinationPath) {
            Remove-Item -LiteralPath $DestinationPath -Recurse -Force -ErrorAction SilentlyContinue
        }
        throw
    }
    Remove-Item -LiteralPath $SourcePath -Recurse -Force -ErrorAction SilentlyContinue
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Removes old backups of a replaced Customer Extension bundle.
.DESCRIPTION
    Keeps the newest backups of one bundle folder and deletes the rest. Only direct child folders of
    the backup root named <FolderName>.<yyyyMMdd-HHmmssfff> are considered, and a failed deletion is
    reported as a warning.
.EXAMPLE
    Remove-OldCustomerExtensionBackups -BackupRoot $BackupRoot -FolderName 'Contoso' -KeepCount 3
.INPUTS
    [System.String]
    [System.Int32]
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    Version         : 6.9.0
#>
####################################################################################################
function Remove-OldCustomerExtensionBackups {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The folder that holds the backups.')]
        [System.String]$BackupRoot,

        [Parameter(Mandatory=$true,HelpMessage='The folder name of the bundle whose backups are cleaned.')]
        [System.String]$FolderName,

        [Parameter(Mandatory=$false,HelpMessage='The number of newest backups to keep.')]
        [ValidateRange(1,100)]
        [System.Int32]$KeepCount = 3
    )

    if (-not (Test-Path -LiteralPath $BackupRoot -PathType Container)) { return }

    # PREPARATION - MATCHING BACKUPS
    # The timestamp format sorts chronologically as text; the optional suffix separates identical timestamps
    [System.String]$BackupRootFullPath = [System.IO.Path]::GetFullPath($BackupRoot).TrimEnd([char[]]@('\','/'))
    [System.String]$Pattern = '^' + [System.Text.RegularExpressions.Regex]::Escape($FolderName) + '\.\d{8}-\d{9}(-\d+)?$'
    [System.Collections.Hashtable]$BackupsByName = @{}
    foreach ($Backup in (Get-ChildItem -LiteralPath $BackupRootFullPath -Directory -ErrorAction SilentlyContinue)) {
        if ($Backup.Name -match $Pattern) { $BackupsByName[$Backup.Name] = $Backup }
    }
    if ($BackupsByName.Count -le $KeepCount) { return }
    [System.String[]]$SortedNames = [System.String[]]@($BackupsByName.Keys)
    [System.Array]::Sort($SortedNames,[System.StringComparer]::Ordinal)

    # EXECUTION - REMOVE THE OLDEST
    foreach ($OldName in ($SortedNames | Select-Object -First ($SortedNames.Count - $KeepCount))) {
        [System.String]$OldPath = [System.IO.Path]::GetFullPath($BackupsByName[$OldName].FullName)
        if (-not [System.IO.Path]::GetDirectoryName($OldPath).Equals($BackupRootFullPath,[System.StringComparison]::OrdinalIgnoreCase)) { continue }
        try {
            Remove-Item -LiteralPath $OldPath -Recurse -Force -ErrorAction Stop
        }
        catch {
            Write-Warning "An old customer extension backup could not be removed. ($OldPath)"
        }
    }
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Installs a validated Customer Extension bundle into the roaming Customer Templates folder.
.DESCRIPTION
    Copies the bundle to a partial folder, writes the descriptor, validates the manifests, moves an
    existing bundle to the backup folder, and publishes the new bundle. The previous bundle is restored
    when publishing fails.
.EXAMPLE
    Install-CustomerExtensionBundle -Content $Content -ExtractedFolder $Folder -DestinationRoot $Root -BackupRoot $Backups
.INPUTS
    [PSCustomObject]
    [System.String]
.OUTPUTS
    [PSCustomObject] with Directory, ManifestPaths and BackupPath.
.NOTES
    Version         : 6.9.0
#>
####################################################################################################
function Install-CustomerExtensionBundle {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The validated extension content.')]
        [PSCustomObject]$Content,

        [Parameter(Mandatory=$true,HelpMessage='The folder into which the ZIP file was extracted.')]
        [System.String]$ExtractedFolder,

        [Parameter(Mandatory=$true,HelpMessage='The roaming Customer Templates folder.')]
        [System.String]$DestinationRoot,

        [Parameter(Mandatory=$true,HelpMessage='The folder that receives the previous version of a replaced bundle.')]
        [System.String]$BackupRoot
    )

    [System.String]$FinalFolder = Join-Path -Path $DestinationRoot -ChildPath $Content.FolderName
    [System.String]$PartialFolder = Join-Path -Path $DestinationRoot -ChildPath ('.' + $Content.FolderName + '.partial-' + [System.Guid]::NewGuid().ToString('N'))
    [System.String]$BackupPath = ''
    try {
        # EXECUTION - STAGE THE BUNDLE
        Copy-Item -LiteralPath $Content.BundleFolder -Destination $PartialFolder -Recurse -ErrorAction Stop
        Copy-Item -LiteralPath (Join-Path -Path $ExtractedFolder -ChildPath 'Extension.psd1') -Destination (Join-Path -Path $PartialFolder -ChildPath 'Extension.psd1') -Force -ErrorAction Stop

        # VALIDATION - STAGED MANIFESTS
        foreach ($Template in $Content.Templates) {
            [void](Import-CustomerTemplateData -SettingsFilePath (Join-Path -Path $PartialFolder -ChildPath $Template.ManifestFileName))
        }

        # EXECUTION - BACK UP THE PREVIOUS VERSION
        if (Test-Path -LiteralPath $FinalFolder) {
            [void][System.IO.Directory]::CreateDirectory($BackupRoot)
            $BackupPath = Join-Path -Path $BackupRoot -ChildPath ('{0}.{1}' -f $Content.FolderName,(Get-Date).ToString('yyyyMMdd-HHmmssfff'))
            # A second replacement within the same millisecond gets a numbered suffix instead of failing
            [System.String]$BackupBasePath = $BackupPath
            [System.Int32]$BackupSuffix = 0
            while (Test-Path -LiteralPath $BackupPath) {
                $BackupSuffix++
                $BackupPath = '{0}-{1}' -f $BackupBasePath,$BackupSuffix
            }
            Move-CustomerExtensionFolder -SourcePath $FinalFolder -DestinationPath $BackupPath
        }

        # EXECUTION - PUBLISH
        try {
            Move-CustomerExtensionFolder -SourcePath $PartialFolder -DestinationPath $FinalFolder
            $PartialFolder = ''
        }
        catch {
            if ((-not [System.String]::IsNullOrWhiteSpace($BackupPath)) -and (-not (Test-Path -LiteralPath $FinalFolder))) {
                Move-CustomerExtensionFolder -SourcePath $BackupPath -DestinationPath $FinalFolder
            }
            throw
        }

        # POST-EXECUTION - BACKUP RETENTION
        if (-not [System.String]::IsNullOrWhiteSpace($BackupPath)) {
            Remove-OldCustomerExtensionBackups -BackupRoot $BackupRoot -FolderName $Content.FolderName -KeepCount 3
        }

        # OUTPUT
        return [PSCustomObject]@{
            Directory     = $FinalFolder
            ManifestPaths = [System.String[]]@($Content.Templates | ForEach-Object { Join-Path -Path $FinalFolder -ChildPath $_.ManifestFileName })
            BackupPath    = $BackupPath
        }
    }
    finally {
        if ((-not [System.String]::IsNullOrWhiteSpace($PartialFolder)) -and (Test-Path -LiteralPath $PartialFolder)) {
            Remove-Item -LiteralPath $PartialFolder -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Imports a Customer Extension ZIP file chosen by the user.
.DESCRIPTION
    Lets the user pick a ZIP file, extracts and validates it in a temporary folder, compares it with
    an installed copy by content fingerprint and version, asks for confirmation, installs the bundle
    transactionally, and refreshes the inventory ListView.
.EXAMPLE
    Import-CustomerTemplateExtensionFromFile -ListView $CustomerTemplateListView
.INPUTS
    [System.Windows.Forms.ListView]
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    Version         : 6.9.0
#>
####################################################################################################
function Import-CustomerTemplateExtensionFromFile {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The customer template inventory ListView.')]
        [System.Windows.Forms.ListView]$ListView
    )

    [System.String]$StagingFolder = ''
    try {
        # PREPARATION - FILE SELECTION
        [System.Windows.Forms.Form]$Owner = $ListView.FindForm()
        [System.Windows.Forms.OpenFileDialog]$FileDialog = [System.Windows.Forms.OpenFileDialog]::new()
        try {
            $FileDialog.Filter = 'Customer Extension (*.zip)|*.zip|All Files (*.*)|*.*'
            $FileDialog.Title = 'Import Customer Extension'
            [System.String]$InitialDirectory = Get-Folder -OutputFolder
            if (Test-Path -LiteralPath $InitialDirectory -PathType Container) {
                $FileDialog.InitialDirectory = $InitialDirectory
            }
            if ($FileDialog.ShowDialog($Owner) -ne [System.Windows.Forms.DialogResult]::OK) {
                return
            }
            [System.String]$ZipPath = $FileDialog.FileName
        }
        finally {
            $FileDialog.Dispose()
        }

        # EXECUTION - EXTRACT AND VALIDATE
        # Everything is verified in a temporary folder before any installed template is touched
        $StagingFolder = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath ('ADA-CustomerExtensionImport-' + [System.Guid]::NewGuid().ToString('N'))
        Test-CustomerExtensionArchive -ArchivePath $ZipPath
        [void](Expand-ZipArchive -ArchivePath $ZipPath -DestinationPath $StagingFolder)
        [PSCustomObject]$Content = Get-CustomerExtensionContent -ExtractedFolder $StagingFolder -ApplicationVersion ([System.Version]$Global:ApplicationObject.Version)

        # VALIDATION - TEMPLATE ID CONFLICTS
        # Built-in templates and bundles in other folders must not be duplicated by an import
        [PSCustomObject]$StoragePaths = Get-CustomerTemplateStoragePaths -Create
        foreach ($ExistingTemplate in @(Get-CustomerTemplates)) {
            if ((-not $ExistingTemplate.Content.ContainsKey('TemplateId')) -or (@($Content.Templates | Where-Object { $_.TemplateId -eq [System.Guid]$ExistingTemplate.Content.TemplateId }).Count -eq 0)) { continue }
            if ($ExistingTemplate.Source -eq 'Built-in') {
                Write-Line "'$($ExistingTemplate.Identity)' is already part of the application. The extension was not imported." -Type Warning
                return
            }
            if (-not [System.IO.Path]::GetFileName($ExistingTemplate.Directory).Equals($Content.FolderName,[System.StringComparison]::OrdinalIgnoreCase)) {
                Write-Line "'$($ExistingTemplate.Identity)' is already installed from another folder. The extension was not imported. ($($ExistingTemplate.Directory))" -Type Warning
                return
            }
        }

        # PREPARATION - COMPARE WITH THE INSTALLED BUNDLE
        [System.String]$InstalledFolder = Join-Path -Path $StoragePaths.CustomerTemplatesRoot -ChildPath $Content.FolderName
        [PSCustomObject]$State = Get-InstalledCustomerExtensionState -InstalledFolder $InstalledFolder
        [System.String]$TemplateList = ($Content.Templates | ForEach-Object { '  - ' + $_.Identity }) -join [System.Environment]::NewLine
        [System.Windows.Forms.MessageBoxIcon]$Icon = [System.Windows.Forms.MessageBoxIcon]::Question
        [System.Windows.Forms.MessageBoxDefaultButton]$DefaultButton = [System.Windows.Forms.MessageBoxDefaultButton]::Button1

        if (-not $State.Exists) {
            [System.String]$Question = "Install customer extension '$($Content.Name)' version $($Content.Version)?`n`nIncluded templates:`n$TemplateList"
        }
        elseif ($State.CurrentHash.Equals($Content.ContentHash,[System.StringComparison]::OrdinalIgnoreCase)) {
            Write-Line "Customer extension '$($Content.Name)' is already up to date (version $($Content.Version))." -Type Info
            return
        }
        else {
            # A locally changed bundle is compared by its newest file date, not by the version it was imported as
            [System.Version]$ComparedVersion = if ($State.LocallyModified) { $State.CurrentVersion } else { $State.InstalledVersion }
            [System.String]$Comparison = if ($Content.Version -gt $ComparedVersion) { 'newer' } elseif ($Content.Version -lt $ComparedVersion) { 'OLDER' } else { 'different (same version)' }
            [System.String]$Question = "Customer extension '$($Content.Name)' is already installed (version $ComparedVersion).`n`nThe selected file contains version $($Content.Version), which is $Comparison.`n`nIncluded templates:`n$TemplateList`n`nThe installed version is kept as a backup."
            if ($State.LocallyModified) {
                $Question += "`n`nWARNING: the installed folder was changed after it was installed (imported as version $($State.InstalledVersion)), or was not installed from an extension. Those changes are replaced (the backup keeps them)."
                $Icon = [System.Windows.Forms.MessageBoxIcon]::Warning
                $DefaultButton = [System.Windows.Forms.MessageBoxDefaultButton]::Button2
            }
            if ($Content.Version -lt $ComparedVersion) {
                $Icon = [System.Windows.Forms.MessageBoxIcon]::Warning
                $DefaultButton = [System.Windows.Forms.MessageBoxDefaultButton]::Button2
            }
            $Question += "`n`nDo you want to replace it?"
        }

        # EXECUTION - CONFIRM
        if ([System.Windows.Forms.MessageBox]::Show($Owner,$Question,'Import Customer Extension',[System.Windows.Forms.MessageBoxButtons]::YesNo,$Icon,$DefaultButton) -ne [System.Windows.Forms.DialogResult]::Yes) {
            Write-Line 'The customer extension was not imported.' -Type Info
            return
        }

        # EXECUTION - INSTALL
        [System.String]$BackupRoot = Join-Path -Path $StoragePaths.ApplicationDataRoot -ChildPath 'Customer Template Backups'
        [PSCustomObject]$Installed = Install-CustomerExtensionBundle -Content $Content -ExtractedFolder $StagingFolder -DestinationRoot $StoragePaths.CustomerTemplatesRoot -BackupRoot $BackupRoot

        # POST-EXECUTION - REFRESH THE INVENTORY
        Update-CustomerTemplateListView -ListView $ListView -TemplatePathToSelect $Installed.ManifestPaths[0]
        Write-Line "Customer extension '$($Content.Name)' version $($Content.Version) imported to: ($($Installed.Directory))" -Type Success
        if (-not [System.String]::IsNullOrWhiteSpace($Installed.BackupPath)) {
            Write-Line "The previous version was kept in: ($($Installed.BackupPath))" -Type Info
        }
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
    finally {
        if ((-not [System.String]::IsNullOrWhiteSpace($StagingFolder)) -and (Test-Path -LiteralPath $StagingFolder)) {
            Remove-Item -LiteralPath $StagingFolder -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Scans a customer template bundle for personal or internal information.
.DESCRIPTION
    Read-only scan of the Word templates (author and company properties, custom properties, shared-with
    names, comment and tracked-change authors, email addresses, user or UNC paths, external links) and
    of the .psd1 files (email addresses, user or UNC paths). Nothing is changed.
.EXAMPLE
    Get-CustomerBundleHygieneFindings -BundleDirectory 'C:\ADA\Customer\Contoso'
.INPUTS
    [System.String]
.OUTPUTS
    [PSCustomObject[]] with File, Category and Detail.
.NOTES
    Version         : 6.9.0
#>
####################################################################################################
function Get-CustomerBundleHygieneFindings {
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The customer template bundle folder.')]
        [System.String]$BundleDirectory
    )

    Add-Type -AssemblyName System.IO.Compression -ErrorAction Stop
    Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction Stop

    [System.Collections.Generic.List[PSCustomObject]]$Findings = New-Object 'System.Collections.Generic.List[PSCustomObject]'
    [System.String]$EmailPattern = '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}'
    [System.String]$PathPattern = '[A-Za-z]:\\Users\\[^\\<"\s]+|\\\\[A-Za-z0-9._-]+\\[A-Za-z0-9$._-]+'

    # EXECUTION - WORD TEMPLATES
    foreach ($File in (Get-ChildItem -LiteralPath $BundleDirectory -File -Recurse -Force -Filter '*.dotx' -ErrorAction Stop)) {
        if ($File.Name.StartsWith('~$')) { continue }
        [System.Collections.Generic.HashSet[System.String]]$Authors = New-Object 'System.Collections.Generic.HashSet[System.String]'
        [System.Collections.Generic.HashSet[System.String]]$Emails = New-Object 'System.Collections.Generic.HashSet[System.String]'
        [System.Collections.Generic.HashSet[System.String]]$Paths = New-Object 'System.Collections.Generic.HashSet[System.String]'
        [System.Collections.Generic.HashSet[System.String]]$Links = New-Object 'System.Collections.Generic.HashSet[System.String]'
        [System.Collections.Generic.HashSet[System.String]]$SharedNames = New-Object 'System.Collections.Generic.HashSet[System.String]'
        [System.Collections.Generic.HashSet[System.String]]$CustomNames = New-Object 'System.Collections.Generic.HashSet[System.String]'
        try {
            [System.IO.Compression.ZipArchive]$Package = [System.IO.Compression.ZipFile]::OpenRead($File.FullName)
            try {
                foreach ($Entry in $Package.Entries) {
                    if ($Entry.Length -gt 20MB) { continue }
                    [System.String]$EntryName = $Entry.FullName
                    if ($EntryName -notmatch '^(docProps/(core|app|custom)\.xml|customXml/item\d+\.xml|word/(document|comments|footnotes|endnotes|header\d*|footer\d*)\.xml|word/_rels/[^/]+\.rels)$') { continue }
                    [System.IO.StreamReader]$Reader = New-Object System.IO.StreamReader($Entry.Open())
                    try { [System.String]$Text = $Reader.ReadToEnd() } finally { $Reader.Dispose() }

                    if ($EntryName -eq 'docProps/core.xml') {
                        foreach ($Pair in @(@('creator','Author (creator)'),@('lastModifiedBy','Author (last modified by)'))) {
                            [System.Text.RegularExpressions.Match]$Match = [System.Text.RegularExpressions.Regex]::Match($Text,"<[a-z]+:$($Pair[0])>([^<]+)</")
                            if ($Match.Success -and (-not [System.String]::IsNullOrWhiteSpace($Match.Groups[1].Value))) {
                                [void]$Findings.Add([PSCustomObject]@{ File = $File.Name; Category = $Pair[1]; Detail = $Match.Groups[1].Value.Trim() })
                            }
                        }
                    }
                    elseif ($EntryName -eq 'docProps/app.xml') {
                        foreach ($Tag in @('Company','Manager')) {
                            [System.Text.RegularExpressions.Match]$Match = [System.Text.RegularExpressions.Regex]::Match($Text,"<$Tag>([^<]+)</$Tag>")
                            if ($Match.Success -and (-not [System.String]::IsNullOrWhiteSpace($Match.Groups[1].Value))) {
                                [void]$Findings.Add([PSCustomObject]@{ File = $File.Name; Category = $Tag; Detail = $Match.Groups[1].Value.Trim() })
                            }
                        }
                    }
                    elseif ($EntryName -eq 'docProps/custom.xml') {
                        # Only the names are reported; the values can be tenant or label IDs
                        foreach ($Match in [System.Text.RegularExpressions.Regex]::Matches($Text,'name="([^"]+)"')) {
                            if ($Match.Groups[1].Value -match '^(Templafy|MSIP_Label_)|(?i)tenant|siteid') { [void]$CustomNames.Add($Match.Groups[1].Value) }
                        }
                    }
                    elseif ($EntryName -like 'customXml/*') {
                        foreach ($Match in [System.Text.RegularExpressions.Regex]::Matches($Text,'<DisplayName>([^<]+)</DisplayName>')) { [void]$SharedNames.Add($Match.Groups[1].Value.Trim()) }
                    }
                    elseif ($EntryName -like 'word/_rels/*') {
                        foreach ($Match in [System.Text.RegularExpressions.Regex]::Matches($Text,'Target="([^"]+)"[^>]*TargetMode="External"')) { [void]$Links.Add($Match.Groups[1].Value) }
                    }
                    else {
                        foreach ($Match in [System.Text.RegularExpressions.Regex]::Matches($Text,'w:author="([^"]+)"')) { [void]$Authors.Add($Match.Groups[1].Value) }
                        foreach ($Match in [System.Text.RegularExpressions.Regex]::Matches($Text,$EmailPattern)) { [void]$Emails.Add($Match.Value) }
                        foreach ($Match in [System.Text.RegularExpressions.Regex]::Matches($Text,$PathPattern)) { [void]$Paths.Add($Match.Value) }
                    }
                }
            }
            finally {
                $Package.Dispose()
            }
        }
        catch {
            [void]$Findings.Add([PSCustomObject]@{ File = $File.Name; Category = 'Could not be scanned'; Detail = $_.Exception.Message })
        }

        # Group the custom property names so the report stays short; the values themselves are never shown
        if ($CustomNames.Count -gt 0) {
            [System.Collections.Generic.List[System.String]]$CustomSummary = New-Object 'System.Collections.Generic.List[System.String]'
            [System.Int32]$TemplafyCount = @($CustomNames | Where-Object { $_ -like 'Templafy*' }).Count
            [System.Int32]$LabelCount = @($CustomNames | Where-Object { $_ -like 'MSIP_Label_*' }).Count
            if ($TemplafyCount -gt 0) { [void]$CustomSummary.Add("Templafy ($TemplafyCount)") }
            if ($LabelCount -gt 0) { [void]$CustomSummary.Add("sensitivity label MSIP ($LabelCount)") }
            foreach ($OtherName in @($CustomNames | Where-Object { ($_ -notlike 'Templafy*') -and ($_ -notlike 'MSIP_Label_*') } | Sort-Object)) { [void]$CustomSummary.Add($OtherName) }
            [void]$Findings.Add([PSCustomObject]@{ File = $File.Name; Category = 'Company or label properties'; Detail = ($CustomSummary -join '; ') })
        }
        foreach ($Set in @(
            @{ Items = $SharedNames; Category = 'Shared-with names' },
            @{ Items = $Authors; Category = 'Comment or tracked-change authors' },
            @{ Items = $Emails; Category = 'Email addresses' },
            @{ Items = $Paths; Category = 'User or network paths' },
            @{ Items = $Links; Category = 'External links' })) {
            if ($Set.Items.Count -gt 0) {
                [void]$Findings.Add([PSCustomObject]@{ File = $File.Name; Category = $Set.Category; Detail = (@($Set.Items | Sort-Object) -join '; ') })
            }
        }
    }

    # EXECUTION - DATA FILES
    foreach ($File in (Get-ChildItem -LiteralPath $BundleDirectory -File -Recurse -Force -Filter '*.psd1' -ErrorAction Stop)) {
        if ($File.Name -eq 'Extension.psd1') { continue }
        [System.String]$Text = [System.IO.File]::ReadAllText($File.FullName)
        [System.String[]]$FileEmails = @([System.Text.RegularExpressions.Regex]::Matches($Text,$EmailPattern) | ForEach-Object { $_.Value } | Sort-Object -Unique)
        [System.String[]]$FilePaths = @([System.Text.RegularExpressions.Regex]::Matches($Text,$PathPattern) | ForEach-Object { $_.Value } | Sort-Object -Unique)
        if ($FileEmails.Count -gt 0) { [void]$Findings.Add([PSCustomObject]@{ File = $File.Name; Category = 'Email addresses'; Detail = ($FileEmails -join '; ') }) }
        if ($FilePaths.Count -gt 0) { [void]$Findings.Add([PSCustomObject]@{ File = $File.Name; Category = 'User or network paths'; Detail = ($FilePaths -join '; ') }) }
    }

    # OUTPUT
    return $Findings.ToArray()
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Exports the selected customer template as a Customer Extension ZIP file.
.DESCRIPTION
    Resolves the selected inventory record, creates the ZIP file in the output folder with an
    automatically derived version, and opens the output location.
.EXAMPLE
    Export-SelectedCustomerTemplateExtension -ListView $CustomerTemplateListView
.INPUTS
    [System.Windows.Forms.ListView]
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    Version         : 6.9.0
#>
####################################################################################################
function Export-SelectedCustomerTemplateExtension {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The customer template inventory ListView.')]
        [System.Windows.Forms.ListView]$ListView
    )

    try {
        # VALIDATION - INVENTORY SELECTION
        if (($null -eq $ListView.SelectedItems) -or ($ListView.SelectedItems.Count -ne 1) -or ($null -eq $ListView.SelectedItems[0].Tag)) {
            Write-Line 'Select one customer template to export.' -Type Warning
            return
        }

        [System.Object]$SelectedTemplate = $ListView.SelectedItems[0].Tag

        # VALIDATION - HYGIENE CHECK
        # Warn about personal or internal information before the template is shared; nothing is changed
        [System.Object[]]$Findings = @(Get-CustomerBundleHygieneFindings -BundleDirectory ([System.String]$SelectedTemplate.Directory))
        if ($Findings.Count -gt 0) {
            [System.String[]]$FindingLines = @($Findings | ForEach-Object { '{0}: {1} - {2}' -f $_.File,$_.Category,$_.Detail })
            foreach ($FindingLine in $FindingLines) { Write-Line $FindingLine -Type Warning }
            [System.String]$Shown = ($FindingLines | Select-Object -First 12) -join "`n"
            if ($FindingLines.Count -gt 12) { $Shown += "`n... and $($FindingLines.Count - 12) more (see the console)" }
            [System.String]$Question = "The template contains information you may not want to share:`n`n$Shown`n`nExport anyway?"
            if ([System.Windows.Forms.MessageBox]::Show($ListView.FindForm(),$Question,'Export Customer Extension',[System.Windows.Forms.MessageBoxButtons]::YesNo,[System.Windows.Forms.MessageBoxIcon]::Warning,[System.Windows.Forms.MessageBoxDefaultButton]::Button2) -ne [System.Windows.Forms.DialogResult]::Yes) {
                Write-Line 'The export was cancelled.' -Type Info
                return
            }
        }

        # PREPARATION - OUTPUT LOCATION
        [System.String]$OutputFolder = Get-Folder -OutputFolder
        if (-not (Test-Path -Path $OutputFolder)) {
            New-Item -Path $OutputFolder -ItemType Directory -Force | Out-Null
        }

        # EXECUTION - CREATE THE ZIP FILE
        [PSCustomObject]$Package = New-CustomerExtensionPackage -CustomerTemplate $SelectedTemplate -ApplicationVersion ([System.Version]$Global:ApplicationObject.Version) -DestinationFolder $OutputFolder

        # POST-EXECUTION
        Write-Line "Customer Extension '$($Package.Name)' version $($Package.ExtensionVersion) created with: $($Package.Identities -join ', ') ($($Package.ArchivePath))" -Type Success
        Open-Folder -Path $Package.ArchivePath
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}

### END OF FUNCTION
####################################################################################################
