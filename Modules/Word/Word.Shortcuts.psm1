####################################################################################################
<#
.SYNOPSIS
    Word shortcut chapter helpers for Application Delivery Assistant.
.DESCRIPTION
    Contains metadata shortcut discovery, table lookup, icon resolution, cloning, cleanup, and chapter update logic.
.EXAMPLE
    Import-Module .\Modules\Word\Word.Shortcuts.psm1
.INPUTS
    None. You cannot pipe objects to this script file.
.OUTPUTS
    None. This script file only declares functions.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.2
    Author          : Imraan Iotana
    Creation Date   : July 2026
    Last Update     : July 2026
#>
####################################################################################################
<#
.SYNOPSIS
    Resolves shortcut metadata entries from either a file path or a metadata object.
.DESCRIPTION
    Returns the Shortcuts collection from metadata as an array of shortcut entries.
.EXAMPLE
    Get-ShortcutEntriesFromMetaData -MetaDataFilePath 'C:\Temp\Metadata_App.json'
.INPUTS
    [System.String]
    [System.Object]
.OUTPUTS
    [PSCustomObject[]]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.2
    Author          : Imraan Iotana
    Creation Date   : July 2026
    Last Update     : July 2026
#>
####################################################################################################
function Get-ShortcutEntriesFromMetaData {
    [CmdletBinding(DefaultParameterSetName='ByPath')]
    [OutputType([PSCustomObject[]])]
    param (
        [Parameter(Mandatory=$true,ParameterSetName='ByPath',HelpMessage='Path to the metadata JSON file containing a Shortcuts array.')]
        [ValidateNotNullOrEmpty()]
        [System.String]$MetaDataFilePath,

        [Parameter(Mandatory=$true,ParameterSetName='ByObject',HelpMessage='Metadata object that contains a Shortcuts array.')]
        [ValidateNotNull()]
        [System.Object]$MetaDataObject
    )

    try {
        # VALIDATION
        # Confirm the metadata source is available and resolve the correct parameter set input.
        [System.Object]$MetaData = $MetaDataObject
        if ($PSCmdlet.ParameterSetName -eq 'ByPath') {
            if (-not (Test-Path -LiteralPath $MetaDataFilePath -PathType Leaf)) {
                throw "The metadata file path does not exist. ($MetaDataFilePath)"
            }
            [System.String]$MetaDataJson = Get-Content -LiteralPath $MetaDataFilePath -Raw
            $MetaData = $MetaDataJson | ConvertFrom-Json
        }

        # PREPARATION
        # Normalize the metadata into a collection of shortcut entries.
        [PSCustomObject[]]$ShortcutEntries = @()
        if ($null -ne $MetaData -and $null -ne $MetaData.Shortcuts) {
            $ShortcutEntries = @($MetaData.Shortcuts)
        }

        # EXECUTION
        # Return the resolved shortcut entries to the caller.
        return $ShortcutEntries
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
    Gets shortcut tables from a Word document.
.DESCRIPTION
    Finds Word tables that belong to the shortcut chapter by matching the expected first-column label.
.EXAMPLE
    Get-WordShortcutTables -Document $Document
.INPUTS
    [System.Object]
.OUTPUTS
    [System.Collections.ArrayList]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.2
    Author          : Imraan Iotana
    Creation Date   : July 2026
    Last Update     : July 2026
#>
####################################################################################################
function Get-WordShortcutTables {
    [CmdletBinding()]
    [OutputType([System.Collections.ArrayList])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The Word document object to inspect.')]
        [ValidateNotNull()]
        [System.Object]$Document
    )

    [System.Collections.ArrayList]$ShortcutTables = New-Object System.Collections.ArrayList

    try {
        # VALIDATION
        # Confirm the Word document object is present before scanning its tables.
        if ($null -eq $Document) { throw 'The Word document object is null.' }

        # PREPARATION
        # Prepare the collection that stores the matching shortcut tables.
        for ([System.Int32]$TableIndex = 1; $TableIndex -le $Document.Tables.Count; $TableIndex++) {
            [System.Object]$Table = $Document.Tables.Item($TableIndex)
            if ($Table.Rows.Count -lt 6 -or $Table.Columns.Count -lt 2) { continue }

            [System.String]$Cell11 = (($Table.Cell(1,1).Range.Text -replace "[\r\a]",'').Trim())
            if ($Cell11 -eq 'Naam Snelkoppeling') {
                [void]$ShortcutTables.Add($Table)
            }
        }

        # EXECUTION
        # Return the discovered shortcut tables to the caller.
        Write-Output -NoEnumerate $ShortcutTables
        return
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
        [System.Collections.ArrayList]$EmptyShortcutTables = New-Object System.Collections.ArrayList
        Write-Output -NoEnumerate $EmptyShortcutTables
        return
    }
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Finds the heading paragraph directly before a shortcut table.
.DESCRIPTION
    Returns the latest paragraph matching "Snelkoppeling <number>" before the supplied table.
.EXAMPLE
    Get-WordShortcutHeadingBeforeTable -Document $Document -Table $Table
.INPUTS
    [System.Object]
.OUTPUTS
    [System.Object]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.2
    Author          : Imraan Iotana
    Creation Date   : July 2026
    Last Update     : July 2026
#>
####################################################################################################
function Get-WordShortcutHeadingBeforeTable {
    [CmdletBinding()]
    [OutputType([System.Object])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The Word document object to inspect.')]
        [ValidateNotNull()]
        [System.Object]$Document,

        [Parameter(Mandatory=$true,HelpMessage='The shortcut table object used as anchor.')]
        [ValidateNotNull()]
        [System.Object]$Table
    )

    try {
        # VALIDATION
        # Confirm the document and table anchors are present before searching for the current heading.
        if ($null -eq $Document) { throw 'The Word document object is null.' }
        if ($null -eq $Table) { throw 'The shortcut table object is null.' }

        # PREPARATION
        # Scan backward from the table position to find the most recent matching shortcut heading.
        [System.Object]$Candidate = $null
        [System.Int32]$TableStart = $Table.Range.Start

        for ([System.Int32]$ParagraphIndex = 1; $ParagraphIndex -le $Document.Paragraphs.Count; $ParagraphIndex++) {
            [System.Object]$Paragraph = $Document.Paragraphs.Item($ParagraphIndex)
            [System.Object]$ParagraphRange = $Paragraph.Range
            if ($ParagraphRange.End -ge $TableStart) { break }

            [System.String]$ParagraphText = (($ParagraphRange.Text -replace "[\r\a]",'').Trim())
            if ($ParagraphText -match '^Snelkoppeling\s+\d+$') {
                $Candidate = $Paragraph
            }
        }

        # EXECUTION
        # Return the best-matching heading paragraph.
        return $Candidate
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
        return $null
    }
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Resolves the canonical shortcut export folder from a shortcuts root folder.
.DESCRIPTION
    Prefers a "Shortcuts - *" folder that contains the shortcut report file,
    and otherwise falls back to the single matching shortcut folder when exactly one exists.
.EXAMPLE
    Get-WordShortcutCanonicalExportFolderPath -ShortcutsRootPath 'C:\Temp\9. Archive\Shortcuts'
.INPUTS
    [System.String]
.OUTPUTS
    [System.String]
#>
####################################################################################################
function Get-WordShortcutCanonicalExportFolderPath {
    [CmdletBinding()]
    [OutputType([System.String])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The root shortcuts archive folder path.')]
        [ValidateNotNullOrEmpty()]
        [System.String]$ShortcutsRootPath
    )

    try {
        if (-not (Test-Path -LiteralPath $ShortcutsRootPath -PathType Container)) { return '' }

        [System.IO.DirectoryInfo[]]$ShortcutFolders = @(Get-ChildItem -LiteralPath $ShortcutsRootPath -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -like 'Shortcuts - *' } | Sort-Object LastWriteTime -Descending)
        foreach ($Folder in $ShortcutFolders) {
            [System.IO.FileInfo[]]$ReportFiles = @(Get-ChildItem -LiteralPath $Folder.FullName -File -Filter '_Shortcut Properties - *.txt' -ErrorAction SilentlyContinue)
            if ($ReportFiles.Count -gt 0) { return $Folder.FullName }
        }

        if ($ShortcutFolders.Count -eq 1) { return $ShortcutFolders[0].FullName }
        return ''
    }
    catch {
        return ''
    }
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Resolves a best-effort icon image file path for a shortcut entry.
.DESCRIPTION
    Tries direct image fields first, then derives likely PNG candidates from IconFilePath, and finally checks the shortcut archive folder.
.EXAMPLE
    Resolve-WordShortcutIconImagePath -Shortcut $Shortcut -MetaDataFilePath $MetaDataFilePath -MetaDataObject $MetaDataObject
.INPUTS
    [System.Object]
    [System.String]
.OUTPUTS
    [System.String]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.2
    Author          : Imraan Iotana
    Creation Date   : July 2026
    Last Update     : July 2026
#>
####################################################################################################
function Resolve-WordShortcutIconImagePath {
    [CmdletBinding()]
    [OutputType([System.String])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='Shortcut metadata entry that may contain icon-related properties.')]
        [ValidateNotNull()]
        [System.Object]$Shortcut,

        [Parameter(Mandatory=$false,HelpMessage='Optional metadata JSON file path for application-folder-relative icon discovery.')]
        [System.String]$MetaDataFilePath,

        [Parameter(Mandatory=$false,HelpMessage='Optional metadata object used to resolve template shortcut subfolder settings.')]
        [System.Object]$MetaDataObject,

        [Parameter(Mandatory=$false,HelpMessage='Optional folder containing shortcut PNG files keyed by shortcut name.')]
        [System.String]$IconFolderPath,

        [Parameter(Mandatory=$false,HelpMessage='When set, create a PNG in the shortcut export folder if no image exists yet.')]
        [System.Management.Automation.SwitchParameter]$CreateImageIfMissing
    )

    try {
        # VALIDATION
        # Confirm the shortcut metadata object exists before resolving icon candidates.
        if ($null -eq $Shortcut) { throw 'The shortcut metadata object is null.' }

        # PREPARATION
        # Build the candidate icon paths from direct properties and related metadata paths.
        [System.Collections.ArrayList]$Candidates = New-Object System.Collections.ArrayList
        [System.String]$BaseName = [System.String]$Shortcut.BaseName
        [System.String]$ShortcutExportFolderPath = ''
        [System.String[]]$DirectPropertyNames = @('IconImagePath','PngFilePath','ImageFilePath','IconPngPath','IconPath')

        # Direct property values are checked first, then derived PNG candidates are added from IconFilePath and the shortcut export folder.
        foreach ($PropertyName in $DirectPropertyNames) {
            [System.Object]$Property = $Shortcut.PSObject.Properties[$PropertyName]
            if ($null -eq $Property) { continue }
            [System.String]$Value = [System.String]$Property.Value
            if (Test-String -IsEmpty $Value) { continue }
            [void]$Candidates.Add((Resolve-PrivacySafePath -Path $Value))
        }

        # If no direct property values were found, derive likely PNG candidates from the IconFilePath and the shortcut export folder.
        [System.String]$IconFilePath = Resolve-PrivacySafePath -Path ([System.String]$Shortcut.IconFilePath)
        [System.String]$TargetPath = Resolve-PrivacySafePath -Path ([System.String]$Shortcut.TargetPath)
        if (Test-String -IsPopulated $IconFilePath) {
            [void]$Candidates.Add($IconFilePath)
            [System.String]$IconFileDirectoryPath = [System.IO.Path]::GetDirectoryName($IconFilePath)
            if ((Test-String -IsPopulated $IconFileDirectoryPath) -and (Test-Path -LiteralPath $IconFileDirectoryPath -PathType Container)) {
                if (Test-String -IsPopulated $BaseName) { [void]$Candidates.Add((Join-Path -Path $IconFileDirectoryPath -ChildPath ($BaseName + '.png'))) }
                [System.String]$IconStem = [System.IO.Path]::GetFileNameWithoutExtension($IconFilePath)
                if (Test-String -IsPopulated $IconStem) { [void]$Candidates.Add((Join-Path -Path $IconFileDirectoryPath -ChildPath ($IconStem + '.png'))) }
            }
        }

        # If an explicit icon folder is supplied, add PNG candidates from that folder using the shortcut base name.
        if (Test-String -IsPopulated $IconFolderPath) {
            if (Test-Path -LiteralPath $IconFolderPath -PathType Container) {
                if (Test-String -IsPopulated $BaseName) {
                    [void]$Candidates.Add((Join-Path -Path $IconFolderPath -ChildPath ($BaseName + '.png')))
                }
                [System.String]$IconFolderStem = [System.IO.Path]::GetFileNameWithoutExtension($IconFolderPath)
                if (Test-String -IsPopulated $IconFolderStem) {
                    [void]$Candidates.Add((Join-Path -Path $IconFolderPath -ChildPath ($IconFolderStem + '.png')))
                }
            }
        }

        # If a metadata file path is supplied, derive the shortcut export folder and add a likely PNG candidate from that location.
        if (Test-String -IsPopulated $MetaDataFilePath) {
            [System.String]$MetaDataFolderPath = [System.IO.Path]::GetDirectoryName([System.IO.Path]::GetFullPath($MetaDataFilePath))
            [System.String]$MetaDataRelativePath = if ($null -ne $MetaDataObject -and $null -ne $MetaDataObject.SelectedTemplate) { [System.String]$MetaDataObject.SelectedTemplate.ApplicationFolderSubFolders.Metadata } else { '' }
            if (Test-String -IsEmpty $MetaDataRelativePath) { $MetaDataRelativePath = '9. Archive\Metadata' }
            [System.String]$NormalizedMetaFolder = $MetaDataFolderPath.TrimEnd('\')
            [System.String]$NormalizedMetaRelativePath = ($MetaDataRelativePath -replace '/','\').Trim('\')
            [System.String]$ExpectedMetaTail = ('\' + $NormalizedMetaRelativePath).ToLowerInvariant()
            [System.String]$ApplicationFolderPath = Split-Path -Path $MetaDataFolderPath -Parent
            if ($NormalizedMetaFolder.ToLowerInvariant().EndsWith($ExpectedMetaTail)) {
                [System.Int32]$TrimLength = $NormalizedMetaFolder.Length - $ExpectedMetaTail.Length
                if ($TrimLength -gt 0) { $ApplicationFolderPath = $NormalizedMetaFolder.Substring(0,$TrimLength) }
            }

            # If the application folder path is resolved, derive the shortcut export folder and add a likely PNG candidate from that location.
            [System.String]$ShortcutsRelativePath = if ($null -ne $MetaDataObject -and $null -ne $MetaDataObject.SelectedTemplate) { [System.String]$MetaDataObject.SelectedTemplate.ApplicationFolderSubFolders.Shortcuts } else { '' }
            if (Test-String -IsEmpty $ShortcutsRelativePath) { $ShortcutsRelativePath = '9. Archive\Shortcuts' }
            if ((Test-String -IsPopulated $ApplicationFolderPath) -and (Test-String -IsPopulated $BaseName)) {
                [System.String]$ShortcutsRootPath = Join-Path -Path $ApplicationFolderPath -ChildPath $ShortcutsRelativePath
                [System.String]$LegacyShortcutExportFolderPath = Join-Path -Path $ShortcutsRootPath -ChildPath ("Shortcuts - $BaseName")
                [System.String]$CanonicalShortcutExportFolderPath = Get-WordShortcutCanonicalExportFolderPath -ShortcutsRootPath $ShortcutsRootPath

                if (Test-String -IsPopulated $CanonicalShortcutExportFolderPath) {
                    $ShortcutExportFolderPath = $CanonicalShortcutExportFolderPath
                    [void]$Candidates.Add((Join-Path -Path $CanonicalShortcutExportFolderPath -ChildPath ($BaseName + '.png')))
                    if ($CanonicalShortcutExportFolderPath -ne $LegacyShortcutExportFolderPath) {
                        [void]$Candidates.Add((Join-Path -Path $LegacyShortcutExportFolderPath -ChildPath ($BaseName + '.png')))
                    }
                }
                else {
                    $ShortcutExportFolderPath = $LegacyShortcutExportFolderPath
                    [void]$Candidates.Add((Join-Path -Path $LegacyShortcutExportFolderPath -ChildPath ($BaseName + '.png')))
                }
            }
        }

        # EXECUTION
        # Check the candidates in priority order and return the first matching icon file.
        [System.String[]]$PreferredExtensions = @('.png','.jpg','.jpeg','.bmp','.gif')
        foreach ($Extension in $PreferredExtensions) {
            foreach ($Candidate in $Candidates) {
                [System.String]$CandidatePath = [System.String]$Candidate
                if (Test-String -IsEmpty $CandidatePath) { continue }
                if (-not $CandidatePath.ToLowerInvariant().EndsWith($Extension)) { continue }
                if (Test-Path -LiteralPath $CandidatePath -PathType Leaf) { return $CandidatePath }
            }
        }

        # If no existing icon file was found, optionally create a PNG in the shortcut export folder if the base name and icon file path are available.
        if ($CreateImageIfMissing -and (Test-String -IsPopulated $ShortcutExportFolderPath) -and (Test-String -IsPopulated $BaseName)) {
            try {
                if (-not (Test-Path -LiteralPath $ShortcutExportFolderPath -PathType Container)) {
                    New-Item -Path $ShortcutExportFolderPath -ItemType Directory -Force | Out-Null
                }
                [PSCustomObject]$ShortcutImageProperties = [PSCustomObject]@{ BaseName = $BaseName; IconFilePath = $IconFilePath; TargetPath = $TargetPath }
                Export-ShortcutImage -InputObject $ShortcutImageProperties -OutputFolder $ShortcutExportFolderPath -PNG
                [System.String]$GeneratedPngPath = Join-Path -Path $ShortcutExportFolderPath -ChildPath ($BaseName + '.png')
                if (Test-Path -LiteralPath $GeneratedPngPath -PathType Leaf) { return $GeneratedPngPath }
            }
            catch { }
        }

        return ''
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
        return ''
    }
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Inserts a shortcut icon image into a Word table cell.
.DESCRIPTION
    Clears the destination cell text, inserts an inline image, and constrains the image size.
.EXAMPLE
    Set-WordShortcutIconCellImage -Table $Table -ImagePath 'C:\Temp\Icon.png'
.INPUTS
    [System.Object]
    [System.String]
.OUTPUTS
    [System.Boolean]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.2
    Author          : Imraan Iotana
    Creation Date   : July 2026
    Last Update     : July 2026
#>
####################################################################################################
function Set-WordShortcutIconCellImage {
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='Shortcut table object containing the icon cell.')]
        [ValidateNotNull()]
        [System.Object]$Table,

        [Parameter(Mandatory=$true,HelpMessage='Absolute path to the icon image to insert.')]
        [ValidateNotNullOrEmpty()]
        [System.String]$ImagePath,

        [Parameter(Mandatory=$false,HelpMessage='Keep existing cell text and append the image below it instead of replacing content.')]
        [System.Management.Automation.SwitchParameter]$PreserveExistingContent,

        [Parameter(Mandatory=$false,HelpMessage='Maximum icon width in points.')]
        [System.Double]$MaxWidthPoints = 52,

        [Parameter(Mandatory=$false,HelpMessage='Maximum icon height in points.')]
        [System.Double]$MaxHeightPoints = 52
    )

    try {
        # VALIDATION
        # Confirm that the icon image exists and the target table cell is usable.
        if (-not (Test-Path -LiteralPath $ImagePath -PathType Leaf)) { return $false }
        if ($null -eq $Table) { throw 'The shortcut table object is null.' }

        # PREPARATION
        # Prepare the destination cell range for image insertion.
        [System.Object]$IconCellRange = $Table.Cell(6,2).Range
        [System.Object]$IconCellWriteRange = $IconCellRange.Duplicate
        $IconCellWriteRange.End = $IconCellWriteRange.End - 1

        if ($PreserveExistingContent) {
            [System.String]$ExistingCellText = (($IconCellWriteRange.Text -replace "[\r\a]",'').Trim())
            if (Test-String -IsPopulated $ExistingCellText) {
                [void]$IconCellWriteRange.Collapse(0)
                [void]$IconCellWriteRange.InsertAfter("`r")
                [void]$IconCellWriteRange.Collapse(0)
            }
            else {
                $IconCellWriteRange.Text = ''
                [void]$IconCellWriteRange.Collapse(1)
            }
        }
        else {
            $IconCellWriteRange.Text = ''
            [void]$IconCellWriteRange.Collapse(1)
        }

        # EXECUTION
        # Insert the image into the shortcut icon cell and constrain its size.
        [System.Object]$InlineShape = $IconCellWriteRange.InlineShapes.AddPicture($ImagePath,$false,$true)
        $InlineShape.LockAspectRatio = $true
        if ($InlineShape.Width -gt $MaxWidthPoints) { $InlineShape.Width = $MaxWidthPoints }
        if ($InlineShape.Height -gt $MaxHeightPoints) { $InlineShape.Height = $MaxHeightPoints }
        return $true
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
        return $false
    }
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Removes helper hint paragraphs from the shortcut chapter.
.DESCRIPTION
    Deletes any paragraph whose normalized text matches the supplied hint text.
.EXAMPLE
    Remove-WordParagraphByExactText -Document $Document -Text 'Kopieer tekst/tabel indien er meer dan twee snelkoppelingen zijn.'
.INPUTS
    [System.Object]
    [System.String]
.OUTPUTS
    [System.Int32]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.2
    Author          : Imraan Iotana
    Creation Date   : July 2026
    Last Update     : July 2026
#>
####################################################################################################
function Remove-WordParagraphByExactText {
    [CmdletBinding()]
    [OutputType([System.Int32])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The Word document object to inspect.')]
        [ValidateNotNull()]
        [System.Object]$Document,

        [Parameter(Mandatory=$true,HelpMessage='Exact paragraph text to delete after normalization.')]
        [ValidateNotNullOrEmpty()]
        [System.String]$Text
    )

    try {
        # VALIDATION
        # Confirm the document object and target paragraph text are available.
        if ($null -eq $Document) { throw 'The Word document object is null.' }
        if (Test-String -IsEmpty $Text) { throw 'The paragraph text to remove is empty.' }

        # PREPARATION
        # Normalize the expected text so matching is consistent across paragraph formatting.
        [System.Int32]$RemovedCount = 0
        [System.String]$Expected = $Text.Trim()
        [System.String]$NormalizedExpected = (($Expected -replace '\s+',' ').Trim().TrimEnd('.'))
        for ([System.Int32]$ParagraphIndex = $Document.Paragraphs.Count; $ParagraphIndex -ge 1; $ParagraphIndex--) {
            [System.Object]$Paragraph = $Document.Paragraphs.Item($ParagraphIndex)
            [System.String]$ParagraphText = (($Paragraph.Range.Text -replace "[\r\a]",'').Trim())
            [System.String]$NormalizedParagraphText = (($ParagraphText -replace '\s+',' ').Trim().TrimEnd('.'))
            if ($NormalizedParagraphText -eq $NormalizedExpected) {
                [void]$Paragraph.Range.Delete()
                $RemovedCount++
            }
        }

        # EXECUTION
        # Return the number of matching paragraphs removed from the document.
        return $RemovedCount
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
        return 0
    }
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Removes the second shortcut heading and table block.
.DESCRIPTION
    Deletes the visual block anchored by the second detected shortcut table, including its heading.
.EXAMPLE
    Remove-WordSecondShortcutBlock -Document $Document
.INPUTS
    [System.Object]
.OUTPUTS
    [System.Boolean]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.2
    Author          : Imraan Iotana
    Creation Date   : July 2026
    Last Update     : July 2026
#>
####################################################################################################
function Remove-WordSecondShortcutBlock {
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The Word document object to update.')]
        [ValidateNotNull()]
        [System.Object]$Document
    )

    try {
        # VALIDATION
        # Confirm the Word document object is present before locating the second shortcut block.
        if ($null -eq $Document) { throw 'The Word document object is null.' }

        # PREPARATION
        # Find the heading and table that represent the second shortcut block.
        [System.Object]$SecondHeading = $null
        for ([System.Int32]$ParagraphIndex = 1; $ParagraphIndex -le $Document.Paragraphs.Count; $ParagraphIndex++) {
            [System.Object]$Paragraph = $Document.Paragraphs.Item($ParagraphIndex)
            [System.String]$ParagraphText = (([System.String]$Paragraph.Range.Text -replace "[\r\a]",'').Trim())
            if ($ParagraphText -match '^Snelkoppeling\s+2\s*$') { $SecondHeading = $Paragraph; break }
        }

        [System.Object]$SecondTable = $null
        if ($null -ne $SecondHeading) {
            [System.Int32]$HeadingEnd = $SecondHeading.Range.End
            [System.Int32]$ClosestTableStart = [System.Int32]::MaxValue
            for ([System.Int32]$TableIndex = 1; $TableIndex -le $Document.Tables.Count; $TableIndex++) {
                [System.Object]$CandidateTable = $Document.Tables.Item($TableIndex)
                [System.Int32]$CandidateStart = $CandidateTable.Range.Start
                if (($CandidateStart -gt $HeadingEnd) -and ($CandidateStart -lt $ClosestTableStart)) {
                    $ClosestTableStart = $CandidateStart
                    $SecondTable = $CandidateTable
                }
            }
        }

        if ($null -eq $SecondTable) {
            [System.Collections.ArrayList]$ShortcutTables = Get-WordShortcutTables -Document $Document
            if ($ShortcutTables.Count -ge 2) { $SecondTable = $ShortcutTables[1] }
        }

        # EXECUTION
        # Remove the second shortcut heading and table block from the document.
        [System.Boolean]$RemovedAnything = $false
        if ($null -ne $SecondHeading) { [void]$SecondHeading.Range.Delete(); $RemovedAnything = $true }
        if ($null -ne $SecondTable) { [void]$SecondTable.Delete(); $RemovedAnything = $true }
        return $RemovedAnything
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
        return $false
    }
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Clones shortcut blocks until the document has enough shortcut tables.
.DESCRIPTION
    Uses the prototype heading and table style and inserts each cloned block before the configured bookmark.
.EXAMPLE
    Add-WordShortcutTableClones -Document $Document -RequiredShortcutCount 5 -PrototypeContext $PrototypeContext -InsertBeforeBookmarkName 'ADA_Shortcuts_InsertBefore'
.INPUTS
    [System.Object]
    [System.Int32]
    [System.Collections.Hashtable]
    [System.String]
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.2
    Author          : Imraan Iotana
    Creation Date   : July 2026
    Last Update     : July 2026
#>
####################################################################################################
function Add-WordShortcutTableClones {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The Word document object to update.')]
        [ValidateNotNull()]
        [System.Object]$Document,

        [Parameter(Mandatory=$true,HelpMessage='The required number of shortcut tables based on metadata entries.')]
        [ValidateRange(1,[System.Int32]::MaxValue)]
        [System.Int32]$RequiredShortcutCount,

        [Parameter(Mandatory=$true,HelpMessage='Prototype context hashtable containing table and heading style values.')]
        [ValidateNotNull()]
        [System.Collections.Hashtable]$PrototypeContext,

        [Parameter(Mandatory=$true,HelpMessage='Bookmark name used as insertion anchor before chapter 6.')]
        [ValidateNotNullOrEmpty()]
        [System.String]$InsertBeforeBookmarkName
    )

    # VALIDATION
    # Confirm the document, bookmark, and prototype context are available before cloning blocks.
    [System.Int32]$CurrentTableCount = (Get-WordShortcutTables -Document $Document).Count
    if ($CurrentTableCount -ge $RequiredShortcutCount) { Write-Line "Shortcut cloning not required. Tables available: $CurrentTableCount."; return }
    if (-not $Document.Bookmarks.Exists($InsertBeforeBookmarkName)) { throw "The required insertion bookmark was not found. ($InsertBeforeBookmarkName)" }
    if (-not $PrototypeContext.ContainsKey('PrototypeTable') -or $null -eq $PrototypeContext.PrototypeTable) { throw 'Prototype context is missing the PrototypeTable reference.' }

    # PREPARATION
    # Prepare the insertion loop and cloning context for the required shortcut blocks.
    Write-Line "Shortcut cloning started. Required tables: $RequiredShortcutCount, current tables: $CurrentTableCount."
    [System.Int32]$InsertionCursorPosition = 0
    while (($RequiredShortcutCount -gt 1) -and ((Get-WordShortcutTables -Document $Document).Count -lt $RequiredShortcutCount)) {
        [System.Collections.ArrayList]$CurrentTables = Get-WordShortcutTables -Document $Document
        if ($null -eq $CurrentTables -or $CurrentTables.Count -eq 0) { throw 'No shortcut tables were found in the document while cloning was required.' }
        [System.Object]$PrototypeTable = $PrototypeContext.PrototypeTable
        if ($null -eq $PrototypeTable) { throw 'Prototype shortcut table is not available while cloning was required.' }

        [System.Int32]$CurrentCount = $CurrentTables.Count
        [System.Int32]$NextShortcutNumber = $CurrentCount + 1
        Write-Line "Creating shortcut block $NextShortcutNumber of $RequiredShortcutCount."

        [System.Object]$Selection = $Document.Application.Selection
        [System.Int32]$InsertPosition = 0
        [System.Object]$InsertBeforeBookmark = $Document.Bookmarks.Item($InsertBeforeBookmarkName)
        if ($InsertionCursorPosition -gt 0) { $InsertPosition = $InsertionCursorPosition } else { $InsertPosition = [System.Int32]$InsertBeforeBookmark.Range.Start }
        [void]$Selection.SetRange($InsertPosition,$InsertPosition)
        try { $Selection.Style = $PrototypeContext.HeadingStyle } catch { }
        $Selection.Font.Name = $PrototypeContext.HeadingFontName
        $Selection.Font.Size = $PrototypeContext.HeadingFontSize
        $Selection.Font.Bold = $PrototypeContext.HeadingBold
        $Selection.Font.Underline = $PrototypeContext.HeadingUnderline
        $Selection.Font.Color = $PrototypeContext.HeadingColor
        $Selection.ParagraphFormat.Alignment = $PrototypeContext.HeadingAlignment
        $Selection.ParagraphFormat.SpaceBefore = $PrototypeContext.HeadingSpaceBefore
        $Selection.ParagraphFormat.SpaceAfter = $PrototypeContext.HeadingSpaceAfter
        $Selection.ParagraphFormat.LineSpacingRule = $PrototypeContext.HeadingLineSpacingRule
        [void]$Selection.TypeText("Snelkoppeling $NextShortcutNumber")
        [void]$Selection.TypeParagraph()
        [void]$PrototypeTable.Range.Copy()
        [void]$Selection.Paste()
        [void]$Selection.TypeParagraph()
        $InsertionCursorPosition = [System.Int32]$Selection.Range.End
        # EXECUTION
        # Clone the prototype shortcut block and insert it before the configured bookmark until enough tables exist.
        [System.Int32]$AfterCount = (Get-WordShortcutTables -Document $Document).Count
        if ($AfterCount -le $CurrentCount) { Write-Line 'Cloning shortcut table failed. Table count did not increase. Continuing with available tables.' -Type Warning; break }
    }
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Writes metadata values into shortcut tables and optionally inserts icon images.
.DESCRIPTION
    Updates each shortcut table row from metadata shortcut entries and optionally fills the icon cell with an image.
.EXAMPLE
    Set-WordShortcutTableValuesFromEntries -FinalShortcutTables $Tables -ShortcutEntries $Entries -InsertShortcutIconImage
.INPUTS
    [System.Collections.ArrayList]
    [PSCustomObject[]]
    [System.Management.Automation.SwitchParameter]
    [System.String]
    [System.Object]
    [System.Double]
    [System.Double]
.OUTPUTS
    [System.Int32]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.2
    Author          : Imraan Iotana
    Creation Date   : July 2026
    Last Update     : July 2026
#>
####################################################################################################
function Set-WordShortcutTableValuesFromEntries {
    [CmdletBinding()]
    [OutputType([System.Int32])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='Final shortcut table collection in document order.')]
        [ValidateNotNull()]
        [System.Collections.ArrayList]$FinalShortcutTables,

        [Parameter(Mandatory=$true,HelpMessage='Shortcut entries resolved from metadata.')]
        [ValidateNotNull()]
        [PSCustomObject[]]$ShortcutEntries,

        [Parameter(Mandatory=$false,HelpMessage='Insert shortcut icon images when available.')]
        [System.Management.Automation.SwitchParameter]$InsertShortcutIconImage,

        [Parameter(Mandatory=$false,HelpMessage='Optional metadata JSON path for icon resolution context.')]
        [System.String]$MetaDataFilePath,

        [Parameter(Mandatory=$false,HelpMessage='Optional metadata object for icon resolution context.')]
        [System.Object]$MetaDataObject,

        [Parameter(Mandatory=$false,HelpMessage='Optional folder containing shortcut PNG files keyed by shortcut name.')]
        [System.String]$IconFolderPath,

        [Parameter(Mandatory=$false,HelpMessage='Maximum icon width in points.')]
        [System.Double]$ShortcutIconMaxWidthPoints = 52,

        [Parameter(Mandatory=$false,HelpMessage='Maximum icon height in points.')]
        [System.Double]$ShortcutIconMaxHeightPoints = 52
    )

    # VALIDATION
    # Confirm the shortcut tables and entry collection are aligned before writing values.
    if ($FinalShortcutTables.Count -lt $ShortcutEntries.Count) { throw "Not enough shortcut tables are available to write all shortcut entries. Tables: $($FinalShortcutTables.Count), entries: $($ShortcutEntries.Count)." }

    # PREPARATION
    # Initialize the icon insertion counter and start the update loop.
    Write-Line "Updating shortcut table values for $($ShortcutEntries.Count) shortcuts."
    [System.Int32]$InsertedIconCount = 0
    for ([System.Int32]$Index = 0; $Index -lt $ShortcutEntries.Count; $Index++) {
        Write-Line "Writing shortcut $($Index + 1) of $($ShortcutEntries.Count)."
        [System.Object]$Table = $FinalShortcutTables[$Index]
        [System.Object]$Shortcut = $ShortcutEntries[$Index]
        $Table.Cell(1,2).Range.Text = [System.String]$Shortcut.BaseName
        $Table.Cell(2,2).Range.Text = [System.String]$Shortcut.TargetPath
        $Table.Cell(3,2).Range.Text = [System.String]$Shortcut.WorkingDirectory
        $Table.Cell(4,2).Range.Text = [System.String]$Shortcut.Arguments
        $Table.Cell(5,2).Range.Text = [System.String]$Shortcut.StartMenuLocation
        # EXECUTION
        # Populate each shortcut table row and optionally insert the corresponding icon image.
        [System.String]$ResolvedIconFilePath = [System.String]$Shortcut.IconFilePath
        $Table.Cell(6,2).Range.Text = $ResolvedIconFilePath
        if ($InsertShortcutIconImage) {
            [System.String]$ResolvedIconImagePath = Resolve-WordShortcutIconImagePath -Shortcut $Shortcut -MetaDataFilePath $MetaDataFilePath -MetaDataObject $MetaDataObject -IconFolderPath $IconFolderPath -CreateImageIfMissing
            if (Test-String -IsPopulated $ResolvedIconImagePath) {
                if (Set-WordShortcutIconCellImage -Table $Table -ImagePath $ResolvedIconImagePath -PreserveExistingContent -MaxWidthPoints $ShortcutIconMaxWidthPoints -MaxHeightPoints $ShortcutIconMaxHeightPoints) { $InsertedIconCount++ }
            }
        }
    }
    return $InsertedIconCount
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Normalizes selected shortcut heading numbers to match the heading-2 visual style.
.DESCRIPTION
    Uses shortcut heading number 2 as style reference and applies it to selected heading numbers when present.
.EXAMPLE
    Update-WordShortcutHeadingStyles -Document $Document -NormalizeHeadingNumbers @(3,4)
.INPUTS
    [System.Object]
    [System.Int32[]]
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.2
    Author          : Imraan Iotana
    Creation Date   : July 2026
    Last Update     : July 2026
#>
####################################################################################################
function Update-WordShortcutHeadingStyles {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The Word document object to update.')]
        [ValidateNotNull()]
        [System.Object]$Document,

        [Parameter(Mandatory=$false,HelpMessage='Shortcut heading numbers to normalize.')]
        [System.Int32[]]$NormalizeHeadingNumbers = @(3,4)
    )

    # VALIDATION
    # Confirm the heading numbers to normalize were provided before styling the document.
    if ($null -eq $NormalizeHeadingNumbers -or $NormalizeHeadingNumbers.Count -eq 0) { Write-Verbose 'No shortcut heading numbers were provided for style normalization.'; return }

    # PREPARATION
    # Build a heading map from the document paragraphs so each target heading can be styled consistently.
    Write-Verbose "Normalizing shortcut heading styles for numbers: $($NormalizeHeadingNumbers -join ', ')."
    [System.Collections.Hashtable]$HeadingMap = @{}
    for ([System.Int32]$ParagraphIndex = 1; $ParagraphIndex -le $Document.Paragraphs.Count; $ParagraphIndex++) {
        [System.Object]$Paragraph = $Document.Paragraphs.Item($ParagraphIndex)
        [System.String]$ParagraphText = (($Paragraph.Range.Text -replace "[\r\a]",'').Trim())
        if ($ParagraphText -match '^Snelkoppeling\s+(\d+)$') {
            [System.Int32]$Number = 0
            if (-not [System.Int32]::TryParse([System.String]$Matches[1],[ref]$Number)) { continue }
            if (-not $HeadingMap.ContainsKey($Number)) { $HeadingMap[$Number] = $Paragraph }
        }
    }

    # EXECUTION
    # Apply the heading-2 visual style to the target shortcut headings when present.
    if ($HeadingMap.ContainsKey(2)) {
        [System.Object]$ReferenceHeading = $HeadingMap[2].Range
        [System.Collections.Generic.List[System.Int32]]$SkippedHeadingNumbers = New-Object 'System.Collections.Generic.List[System.Int32]'
        foreach ($HeadingNumber in $NormalizeHeadingNumbers) {
            if (-not $HeadingMap.ContainsKey($HeadingNumber)) { continue }
            [System.Object]$TargetHeadingRange = $HeadingMap[$HeadingNumber].Range
            [System.Boolean]$AppliedSomething = $false
            try { $TargetHeadingRange.Style = $ReferenceHeading.Style; $AppliedSomething = $true } catch {}
            try { $TargetHeadingRange.Font.Name = $ReferenceHeading.Font.Name; $AppliedSomething = $true } catch {}
            try { $TargetHeadingRange.Font.Size = $ReferenceHeading.Font.Size; $AppliedSomething = $true } catch {}
            try { $TargetHeadingRange.Font.Bold = $ReferenceHeading.Font.Bold; $AppliedSomething = $true } catch {}
            try { $TargetHeadingRange.Font.Underline = $ReferenceHeading.Font.Underline; $AppliedSomething = $true } catch {}
            try { $TargetHeadingRange.Font.Color = $ReferenceHeading.Font.Color; $AppliedSomething = $true } catch {}
            try { $TargetHeadingRange.ParagraphFormat.Alignment = $ReferenceHeading.ParagraphFormat.Alignment; $AppliedSomething = $true } catch {}
            try { $TargetHeadingRange.ParagraphFormat.SpaceBefore = $ReferenceHeading.ParagraphFormat.SpaceBefore; $AppliedSomething = $true } catch {}
            try { $TargetHeadingRange.ParagraphFormat.SpaceAfter = $ReferenceHeading.ParagraphFormat.SpaceAfter; $AppliedSomething = $true } catch {}
            try { $TargetHeadingRange.ParagraphFormat.LineSpacingRule = $ReferenceHeading.ParagraphFormat.LineSpacingRule; $AppliedSomething = $true } catch {}
            if (-not $AppliedSomething) { [void]$SkippedHeadingNumbers.Add($HeadingNumber) }
        }
        if ($SkippedHeadingNumbers.Count -gt 0) {
            [System.String]$SkippedList = ($SkippedHeadingNumbers | Sort-Object -Unique) -join ', '
            Write-Verbose "Shortcut heading style normalization was skipped for: $SkippedList (Word formatting conversion limitation)."
        }
    }
    else {
        Write-Verbose 'Shortcut heading style normalization skipped because reference heading Snelkoppeling 2 was not found.'
    }
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Populates the shortcut chapter in a Word document using metadata shortcuts.
.DESCRIPTION
    Uses a clone-based workflow to preserve table styling and can optionally insert shortcut icon images.
.EXAMPLE
    Update-WordShortcutChapterFromMetaData -Document $Document -MetaDataFilePath 'C:\Temp\Metadata_App.json'
.EXAMPLE
    Update-WordShortcutChapterFromMetaData -Document $Document -MetaDataObject $MetaData
.INPUTS
    [System.Object]
    [System.String]
    [System.Object]
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.2
    Author          : Imraan Iotana
    Creation Date   : July 2026
    Last Update     : July 2026
#>
####################################################################################################
function Update-WordShortcutChapterFromMetaData {
    [CmdletBinding(DefaultParameterSetName='ByPath')]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The Word document object to update.')]
        [ValidateNotNull()]
        [System.Object]$Document,

        [Parameter(Mandatory=$true,ParameterSetName='ByPath',HelpMessage='Path to the metadata JSON file containing a Shortcuts array.')]
        [ValidateNotNullOrEmpty()]
        [System.String]$MetaDataFilePath,

        [Parameter(Mandatory=$true,ParameterSetName='ByObject',HelpMessage='Metadata object that contains a Shortcuts array.')]
        [ValidateNotNull()]
        [System.Object]$MetaDataObject,

        [Parameter(Mandatory=$false,HelpMessage='Shortcut heading numbers to normalize using heading 2 style. Default: 3 and 4.')]
        [System.Int32[]]$NormalizeHeadingNumbers = @(3,4),

        [Parameter(Mandatory=$false,HelpMessage='Insert shortcut icon images into row 6, column 2 when a matching PNG/image file is found.')]
        [System.Management.Automation.SwitchParameter]$InsertShortcutIconImage,

        [Parameter(Mandatory=$false,HelpMessage='Optional folder containing shortcut PNG files keyed by shortcut name.')]
        [System.String]$IconFolderPath,

        [Parameter(Mandatory=$false,HelpMessage='Maximum icon width in points when inserting icon images.')]
        [System.Double]$ShortcutIconMaxWidthPoints = 52,

        [Parameter(Mandatory=$false,HelpMessage='Maximum icon height in points when inserting icon images.')]
        [System.Double]$ShortcutIconMaxHeightPoints = 52
    )

    try {

        # VALIDATION
        # Load metadata and confirm the document still has usable shortcut anchors.
        Write-Line 'Shortcut chapter update started.' -Type Busy
        [System.String]$ShortcutInsertBeforeBookmarkName = 'ADA_Shortcuts_InsertBefore'
        [System.Int32]$RemovedHintLines = Remove-WordParagraphByExactText -Document $Document -Text 'Kopieer tekst/tabel indien er meer dan twee snelkoppelingen zijn.'
        Write-Line "Shortcut hint cleanup completed. Removed lines: $RemovedHintLines."

        # PREPARATION
        # Resolve metadata entries and capture the current shortcut tables.
        [System.Object]$MetaDataForContext = $MetaDataObject
        [PSCustomObject[]]$ShortcutEntries = if ($PSCmdlet.ParameterSetName -eq 'ByPath') {
            [System.String]$MetaDataJson = Get-Content -LiteralPath $MetaDataFilePath -Raw
            $MetaDataForContext = $MetaDataJson | ConvertFrom-Json
            Get-ShortcutEntriesFromMetaData -MetaDataFilePath $MetaDataFilePath
        }
        else {
            Get-ShortcutEntriesFromMetaData -MetaDataObject $MetaDataObject
        }

        if ($ShortcutEntries.Count -eq 0) {
            Write-Line 'No shortcuts were found in metadata. Skipping shortcut chapter update.' -Type Warning
            return
        }
        Write-Line "Shortcut metadata loaded. Entries found: $($ShortcutEntries.Count)."

        [System.Collections.ArrayList]$ShortcutTables = Get-WordShortcutTables -Document $Document
        Write-Line "Shortcut tables detected in document: $($ShortcutTables.Count)."

        if (($ShortcutEntries.Count -eq 1) -and ($ShortcutTables.Count -ge 2)) { Write-Line 'Single shortcut detected. Keeping the second shortcut table available for manual customization.' }
        if ($ShortcutTables.Count -lt 2) {
            if ($ShortcutEntries.Count -eq 1) { Write-Line 'Single shortcut detected. Continuing with one shortcut table after template cleanup.' }
            else { Write-Line 'At least 2 source shortcut tables are required in the template. Skipping shortcut chapter update.' -Type Warning; return }
        }

        [System.Collections.Hashtable]$PrototypeContext = @{}
        if ($ShortcutTables.Count -ge 2) {
            [System.Object]$PrototypeTable = $ShortcutTables[1]
            [System.Object]$PrototypeHeading = Get-WordShortcutHeadingBeforeTable -Document $Document -Table $PrototypeTable
            if ($null -eq $PrototypeHeading) { Write-Line 'A heading before the prototype shortcut table could not be found. Skipping shortcut chapter update.' -Type Warning; return }

            $PrototypeContext = @{
                PrototypeTable          = $PrototypeTable
                HeadingStyle            = $PrototypeHeading.Range.Style
                HeadingFontName         = [System.String]$PrototypeHeading.Range.Font.Name
                HeadingFontSize         = [System.Double]$PrototypeHeading.Range.Font.Size
                HeadingBold             = [System.Int32]$PrototypeHeading.Range.Font.Bold
                HeadingUnderline        = [System.Int32]$PrototypeHeading.Range.Font.Underline
                HeadingColor            = [System.Int32]$PrototypeHeading.Range.Font.Color
                HeadingAlignment        = [System.Int32]$PrototypeHeading.Range.ParagraphFormat.Alignment
                HeadingSpaceBefore      = [System.Double]$PrototypeHeading.Range.ParagraphFormat.SpaceBefore
                HeadingSpaceAfter       = [System.Double]$PrototypeHeading.Range.ParagraphFormat.SpaceAfter
                HeadingLineSpacingRule  = [System.Int32]$PrototypeHeading.Range.ParagraphFormat.LineSpacingRule
            }
        }

        if (-not $Document.Bookmarks.Exists($ShortcutInsertBeforeBookmarkName)) { Write-Line "Required bookmark '$ShortcutInsertBeforeBookmarkName' was not found. Skipping shortcut chapter update." -Type Warning; return }

        # EXECUTION
        # Clone and fill shortcut blocks, then normalize the heading styles.
        Write-Line 'Ensuring enough shortcut blocks exist in the document.'
        Add-WordShortcutTableClones -Document $Document -RequiredShortcutCount $ShortcutEntries.Count -PrototypeContext $PrototypeContext -InsertBeforeBookmarkName $ShortcutInsertBeforeBookmarkName

        [System.Collections.ArrayList]$FinalShortcutTables = Get-WordShortcutTables -Document $Document
        if ($null -eq $FinalShortcutTables) { $FinalShortcutTables = New-Object System.Collections.ArrayList }
        Write-Line "Final shortcut tables available for fill: $($FinalShortcutTables.Count)."
        if ($FinalShortcutTables.Count -lt $ShortcutEntries.Count) {
            if (($ShortcutEntries.Count -eq 1) -and ($null -ne $ShortcutTables) -and ($ShortcutTables.Count -ge 1)) { $FinalShortcutTables = $ShortcutTables }
        }
        if ($FinalShortcutTables.Count -lt $ShortcutEntries.Count) { Write-Line "Found $($FinalShortcutTables.Count) shortcut table(s), but $($ShortcutEntries.Count) shortcut value set(s) are required. Skipping shortcut chapter update." -Type Warning; return }

        Write-Line 'Applying shortcut values to document tables.'
        [System.Int32]$InsertedIconCount = Set-WordShortcutTableValuesFromEntries -FinalShortcutTables $FinalShortcutTables -ShortcutEntries $ShortcutEntries -InsertShortcutIconImage:$InsertShortcutIconImage -MetaDataFilePath $MetaDataFilePath -MetaDataObject $MetaDataForContext -IconFolderPath $IconFolderPath -ShortcutIconMaxWidthPoints $ShortcutIconMaxWidthPoints -ShortcutIconMaxHeightPoints $ShortcutIconMaxHeightPoints
        Update-WordShortcutHeadingStyles -Document $Document -NormalizeHeadingNumbers $NormalizeHeadingNumbers

        if ($InsertShortcutIconImage) { Write-Line "Updated Word shortcut chapter with $($ShortcutEntries.Count) shortcuts. Inserted icon images: $InsertedIconCount." -Type Success }
        else { Write-Line "Updated Word shortcut chapter with $($ShortcutEntries.Count) shortcuts." -Type Success }
        if ($RemovedHintLines -gt 0) { Write-Line "Removed shortcut helper hint line(s): $RemovedHintLines." }
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}

### END OF FUNCTION
####################################################################################################
