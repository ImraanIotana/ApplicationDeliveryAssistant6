####################################################################################################
<#
.SYNOPSIS
    Escapes one value using the Windows command-line argument rules.
.OUTPUTS
    [System.String]
#>
####################################################################################################
function ConvertTo-CustomApplicationCommandLineArgument {
    [CmdletBinding()]
    [OutputType([System.String])]
    param (
        [Parameter(Mandatory=$true)]
        [AllowEmptyString()]
        [System.String]$Value
    )

    # OUTPUT - UNQUOTED SIMPLE VALUE
    if ((Test-String -IsPopulated $Value) -and $Value -notmatch '[\s"]') {
        return $Value
    }

    # EXECUTION - WINDOWS ARGUMENT ESCAPING
    [System.Text.StringBuilder]$EscapedValue = New-Object System.Text.StringBuilder
    [void]$EscapedValue.Append('"')
    [System.Int32]$BackslashCount = 0
    foreach ($Character in $Value.ToCharArray()) {
        if ($Character -eq [System.Char]'\') {
            $BackslashCount++
            continue
        }

        if ($Character -eq [System.Char]'"') {
            # Backslashes before a literal quote are doubled, plus one slash escapes the quote itself.
            [void]$EscapedValue.Append(('\' * (($BackslashCount * 2) + 1)))
            [void]$EscapedValue.Append('"')
        }
        else {
            [void]$EscapedValue.Append(('\' * $BackslashCount))
            [void]$EscapedValue.Append($Character)
        }
        $BackslashCount = 0
    }

    # A quoted argument doubles trailing backslashes so they do not escape the closing quote.
    [void]$EscapedValue.Append(('\' * ($BackslashCount * 2)))
    [void]$EscapedValue.Append('"')
    return $EscapedValue.ToString()
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Builds the command-line arguments for a Custom Application shortcut.
.OUTPUTS
    [System.String]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.6.0
    Author          : Imraan Iotana
    Creation Date   : August 2026
    Last Update     : September 2026
#>
####################################################################################################
function Join-CustomApplicationShortcutArguments {
    [CmdletBinding()]
    [OutputType([System.String])]
    param (
        [Parameter(Mandatory=$false)]
        [AllowNull()][AllowEmptyString()]
        [System.String]$ApplicationParameter,

        [Parameter(Mandatory=$false)]
        [AllowNull()][AllowEmptyString()]
        [System.String]$AdditionalArguments
    )

    # PREPARATION - ORDERED ARGUMENT PARTS
    [System.Collections.Generic.List[System.String]]$ArgumentParts = New-Object 'System.Collections.Generic.List[System.String]'
    if (Test-String -IsPopulated $ApplicationParameter) {
        [System.String]$NormalizedParameter = $ApplicationParameter.Trim()
        [void]$ArgumentParts.Add((ConvertTo-CustomApplicationCommandLineArgument -Value $NormalizedParameter))
    }
    if (Test-String -IsPopulated $AdditionalArguments) {
        [void]$ArgumentParts.Add($AdditionalArguments.Trim())
    }

    # OUTPUT - COMBINED COMMAND LINE
    return ($ArgumentParts -join ' ')
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Creates and logs the Custom Application shortcut artifact.
.OUTPUTS
    [PSCustomObject] containing the shortcut file path and metadata entry.
#>
####################################################################################################
function New-CustomApplicationShortcutArtifact {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$FormData,

        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Context,

        [Parameter(Mandatory=$true)]
        [PSCustomObject]$IconArtifacts
    )

    [System.Object]$WScriptShell = $null
    [System.Object]$Shortcut = $null
    try {
        # PREPARATION - SHORTCUT PATHS AND PROPERTIES
        [System.String]$ShortcutFolderPath = Get-ApplicationArtifactFolderPath -ApplicationFolderPath $Context.ApplicationFolderPath -SelectedTemplate $Context.SelectedTemplate -FolderName Shortcuts -DefaultRelativePath '9. Archive\Shortcuts'
        [System.String]$SafeShortcutName = ($FormData.ApplicationName -replace '[\\/:*?""<>|]', '_').Trim()
        [System.String]$ShortcutFilePath = Join-Path -Path $ShortcutFolderPath -ChildPath ($SafeShortcutName + '.lnk')
        [System.String]$WorkingDirectory = [System.IO.Path]::GetDirectoryName($FormData.ApplicationExecutable)
        [System.String]$Arguments = Join-CustomApplicationShortcutArguments -ApplicationParameter $FormData.ApplicationParameter -AdditionalArguments $FormData.AdditionalArguments
        [System.String]$PublishedIcoPath = Get-PublishedApplicationArtifactPath -Context $Context -StagedPath $IconArtifacts.IcoPath
        [System.String]$PublishedPngPath = Get-PublishedApplicationArtifactPath -Context $Context -StagedPath $IconArtifacts.PngPath
        # The dossier shows the executable icon source, or only the filename of an explicitly supplied icon.
        [System.String]$DocumentIconFile = if (Test-String -IsPopulated $FormData.ApplicationIcon) {
            [System.IO.Path]::GetFileName($FormData.ApplicationIcon)
        }
        else {
            $FormData.ApplicationExecutable
        }

        # EXECUTION - CREATE WINDOWS SHORTCUT
        $WScriptShell = New-Object -ComObject WScript.Shell
        $Shortcut = $WScriptShell.CreateShortcut($ShortcutFilePath)
        $Shortcut.TargetPath = $FormData.ApplicationExecutable
        $Shortcut.WorkingDirectory = $WorkingDirectory
        $Shortcut.Arguments = $Arguments
        $Shortcut.Description = "Start $($FormData.ApplicationName)"
        $Shortcut.IconLocation = "$PublishedIcoPath,0"
        $Shortcut.WindowStyle = 1
        $Shortcut.Save()

        # VALIDATION - WRITTEN SHORTCUT
        if (-not (Test-Path -LiteralPath $ShortcutFilePath -PathType Leaf)) {
            throw "The Custom Application shortcut was not created. ($ShortcutFilePath)"
        }

        [System.Collections.Hashtable]$ApplicationLog = $Context.ApplicationLog
        Write-ApplicationFileLogEntry @ApplicationLog -FilePath $ShortcutFilePath -Action CustomApplicationShortcutCreated -DetailsPrefix 'Created Custom Application shortcut'

        # OUTPUT - SHORTCUT ARTIFACT AND DOCUMENT METADATA
        [PSCustomObject]$ShortcutMetadata = [PSCustomObject][ordered]@{
            Name             = $SafeShortcutName
            BaseName         = $SafeShortcutName
            Extension        = '.lnk'
            Type             = 'Shell Shortcut (*.lnk)'
            TargetPath       = $FormData.ApplicationExecutable
            WorkingDirectory = $WorkingDirectory
            Arguments        = $Arguments
            Description      = "Start $($FormData.ApplicationName)"
            Hotkey           = ''
            IconLocation     = "$PublishedIcoPath,0"
            WindowStyle      = 1
            IconFilePath     = $DocumentIconFile
            IconImagePath    = $PublishedPngPath
        }

        return [PSCustomObject]@{
            FilePath = $ShortcutFilePath
            Metadata = $ShortcutMetadata
        }
    }
    finally {
        if ($null -ne $Shortcut -and [System.Runtime.InteropServices.Marshal]::IsComObject($Shortcut)) {
            [void][System.Runtime.InteropServices.Marshal]::ReleaseComObject($Shortcut)
        }
        if ($null -ne $WScriptShell -and [System.Runtime.InteropServices.Marshal]::IsComObject($WScriptShell)) {
            [void][System.Runtime.InteropServices.Marshal]::ReleaseComObject($WScriptShell)
        }
    }
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Exports and logs the standard shortcut properties report and companion images.
.OUTPUTS
    [PSCustomObject] containing the report, PNG, and ICO file paths.
#>
####################################################################################################
function Export-CustomApplicationShortcutInformationArtifact {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$ShortcutArtifact,

        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Context
    )

    # PREPARATION - STANDARD SHORTCUT EXPORT LOCATION
    [System.String]$ShortcutFolderPath = Get-ApplicationArtifactFolderPath `
        -ApplicationFolderPath $Context.ApplicationFolderPath `
        -SelectedTemplate $Context.SelectedTemplate `
        -FolderName Shortcuts `
        -DefaultRelativePath '9. Archive\Shortcuts'
    # EXECUTION - DESKTOP-EQUIVALENT SHORTCUT EXPORT
    [System.String]$ReportFilePath = Export-ShortcutInformation `
        -Path $ShortcutArtifact.FilePath `
        -ParentOutputFolder $ShortcutFolderPath `
        -SkipConfirmation `
        -PassThru
    # VALIDATION - REPORT AND COMPANION IMAGES
    if ((Test-String -IsEmpty $ReportFilePath) -or
        (-not (Test-Path -LiteralPath $ReportFilePath -PathType Leaf))) {
        throw 'The Custom Application shortcut properties report was not created.'
    }

    [System.String]$PngFilePath = Join-Path `
        -Path ([System.IO.Path]::GetDirectoryName($ReportFilePath)) `
        -ChildPath ($ShortcutArtifact.Metadata.BaseName + '.png')
    [System.String]$IcoFilePath = Join-Path `
        -Path ([System.IO.Path]::GetDirectoryName($ReportFilePath)) `
        -ChildPath ($ShortcutArtifact.Metadata.BaseName + '.ico')
    if (-not (Test-Path -LiteralPath $PngFilePath -PathType Leaf)) {
        throw "The Custom Application shortcut PNG image was not created. ($PngFilePath)"
    }
    if (-not (Test-Path -LiteralPath $IcoFilePath -PathType Leaf)) {
        throw "The Custom Application shortcut ICO image was not created. ($IcoFilePath)"
    }

    # POST-EXECUTION - LOG VERIFIED ARTIFACTS
    [System.Collections.Hashtable]$ApplicationLog = $Context.ApplicationLog
    Write-ApplicationFileLogEntry @ApplicationLog -FilePath $ReportFilePath -Action ShortcutInformationExported -DetailsPrefix 'Exported Custom Application shortcut information'
    Write-ApplicationFileLogEntry @ApplicationLog -FilePath $PngFilePath -Action ShortcutImageExported -DetailsPrefix 'Exported Custom Application shortcut PNG image'
    Write-ApplicationFileLogEntry @ApplicationLog -FilePath $IcoFilePath -Action ShortcutIconExported -DetailsPrefix 'Exported Custom Application shortcut ICO image'

    return [PSCustomObject]@{
        ReportFilePath = $ReportFilePath
        PngFilePath    = $PngFilePath
        IcoFilePath    = $IcoFilePath
    }
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Creates and logs privacy-safe Custom Application metadata.
.OUTPUTS
    [System.String] containing the metadata JSON path.
#>
####################################################################################################
function New-CustomApplicationMetadataArtifact {
    [CmdletBinding()]
    [OutputType([System.String])]
    param (
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$FormData,

        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Context,

        [Parameter(Mandatory=$true)]
        [PSCustomObject]$ShortcutMetadata,

        [Parameter(Mandatory=$true)]
        [PSCustomObject]$IconArtifacts
    )

    # PREPARATION - METADATA PATH AND VALUES
    [System.String]$MetadataFolderPath = Get-ApplicationArtifactFolderPath -ApplicationFolderPath $Context.ApplicationFolderPath -SelectedTemplate $Context.SelectedTemplate -FolderName Metadata -DefaultRelativePath '9. Archive\Metadata'
    [System.String]$SafeApplicationID = ($Context.ApplicationID -replace '[\\/:*?""<>|]', '_')
    [System.String]$MetadataFilePath = Join-Path -Path $MetadataFolderPath -ChildPath ("Metadata_$SafeApplicationID.json")
    [System.String]$ExecutableBitness = ''
    try { $ExecutableBitness = Get-FileBitness -Path $FormData.ApplicationExecutable } catch { $ExecutableBitness = '' }

    # Include established document fields alongside Custom-specific launch data for template compatibility.
    [PSCustomObject]$MetadataObject = [PSCustomObject][ordered]@{
        CreatedOn                = Get-TimeStamp -ForHost
        IntakeType               = 'Custom Application'
        ApplicationID            = $Context.ApplicationID
        ApplicationType          = $FormData.ApplicationType
        FormalVendorName         = $FormData.VendorPublisher
        FormalApplicationName    = $FormData.ApplicationName
        FormalApplicationVersion = $FormData.ApplicationVersion
        CustomVendorName         = $FormData.VendorPublisher
        CustomApplicationName    = $FormData.ApplicationName
        CustomApplicationVersion = $FormData.ApplicationVersion
        ApplicationExecutable    = $FormData.ApplicationExecutable
        ApplicationParameter     = $FormData.ApplicationParameter
        AdditionalArguments      = $FormData.AdditionalArguments
        ApplicationIcon          = $FormData.ApplicationIcon
        IconSourcePath           = $IconArtifacts.SourcePath
        IconImagePath            = Get-PublishedApplicationArtifactPath -Context $Context -StagedPath $IconArtifacts.PngPath
        DetectionFile            = ''
        Bitness                  = $ExecutableBitness
        UserFullName             = Get-UserSetting -PropertyLeaf 'MyFullName'
        UserEmailAddress         = Get-UserSetting -PropertyLeaf 'MyEmailAddress'
        Shortcuts                = @($ShortcutMetadata)
        SelectedTemplate         = $Context.SelectedTemplate
    }

    # EXECUTION - PRIVACY-SAFE JSON WRITE
    [System.Object]$ConvertedMetadata = Convert-MetaDataObject -MetaDataObject $MetadataObject
    [System.String]$MetadataJson = $ConvertedMetadata | ConvertTo-Json -Depth 20
    Set-Content -LiteralPath $MetadataFilePath -Value $MetadataJson -Encoding UTF8
    # VALIDATION - WRITTEN METADATA
    if (-not (Test-Path -LiteralPath $MetadataFilePath -PathType Leaf)) {
        throw "The Custom Application metadata file was not created. ($MetadataFilePath)"
    }

    [System.Collections.Hashtable]$ApplicationLog = $Context.ApplicationLog
    Write-ApplicationFileLogEntry @ApplicationLog -FilePath $MetadataFilePath -Action MetadataFileCreated -DetailsPrefix 'Created Custom Application metadata file'
    return $MetadataFilePath
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Creates and logs the Custom Application Word document.
.OUTPUTS
    [System.String] containing the created document path when available.
#>
####################################################################################################
function New-CustomApplicationDocumentArtifact {
    [CmdletBinding()]
    [OutputType([System.String])]
    param (
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Context,

        [Parameter(Mandatory=$true)]
        [System.String]$MetadataFilePath,

        [Parameter(Mandatory=$true)]
        [System.String]$IconFolderPath
    )

    # PREPARATION - SELECTED TEMPLATE ROOT
    [System.String]$CustomerFolderPath = Join-Path -Path $Global:ApplicationObject.RootFolder -ChildPath 'Customer'
    # EXECUTION - OPTIONAL WORD DOCUMENT
    [System.String[]]$DocumentFilePaths = @(New-ApplicationIntakeDocument `
        -ApplicationFolderPath $Context.ApplicationFolderPath `
        -SelectedTemplate $Context.SelectedTemplate `
        -FolderToSearch $CustomerFolderPath `
        -MetaDataFilePath $MetadataFilePath `
        -ApplicationID $Context.ApplicationID `
        -IconFolderPath $IconFolderPath `
        -PassThru)

    # POST-EXECUTION - LOG CREATED OR SKIPPED RESULT
    [System.Collections.Hashtable]$ApplicationLog = $Context.ApplicationLog
    [System.Int32]$CreatedCount = 0
    foreach ($DocumentFilePath in $DocumentFilePaths) {
        if ((Test-String -IsPopulated $DocumentFilePath) -and (Test-Path -LiteralPath $DocumentFilePath -PathType Leaf)) {
            Write-ApplicationFileLogEntry @ApplicationLog -FilePath $DocumentFilePath -Action WordDocumentCreated -DetailsPrefix 'Created Custom Application Word document'
            $CreatedCount++
        }
    }
    if ($CreatedCount -eq 0) {
        Write-ApplicationLogEntry @ApplicationLog -Status Warning -Action WordDocumentSkipped -Details 'No Custom Application Word document was created; document creation was declined or unavailable.'
    }
    return $DocumentFilePaths
}

### END OF FUNCTION
####################################################################################################