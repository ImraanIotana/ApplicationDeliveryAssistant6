####################################################################################################
<#
.SYNOPSIS
    Provides helper functions for the DSL Management Search feature.
.DESCRIPTION
    This module contains the search, archive, restore, and ListView helper functions used by the DSL Search feature UI.
.INPUTS
    None.
.OUTPUTS
    Helper functions are exported by module import.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.9.0
    Author          : Imraan Iotana
    Creation Date   : August 2026
    Last Update     : October 2026
#>
####################################################################################################

# Set to $false to use the preserved Compress-Archive/Expand-Archive implementation.
[System.Boolean]$script:UseNativeDSLCompression = $true

####################################################################################################
<#
.SYNOPSIS
    Executes Archive or Restore operations for the DSL search view.
.DESCRIPTION
    Parent helper that orchestrates archive operations, then refreshes both listviews when the
    operation succeeds.
.EXAMPLE
    Invoke-DSLArchiveOperation -Action Archive -SearchResultsListView $Top -ArchiveResultsListView $Bottom
.INPUTS
    [System.String]
    [System.Windows.Forms.ListView]
.OUTPUTS
    No objects are returned to the pipeline.
#>
####################################################################################################
function Invoke-DSLArchiveOperation {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The archive operation to execute.')]
        [ValidateSet('Archive','Restore','Remove')]
        [System.String]$Action,

        [Parameter(Mandatory=$true,HelpMessage='The top DSL results ListView.')]
        [System.Windows.Forms.ListView]$SearchResultsListView,

        [Parameter(Mandatory=$true,HelpMessage='The bottom archive results ListView.')]
        [System.Windows.Forms.ListView]$ArchiveResultsListView,

        [Parameter(Mandatory=$false,HelpMessage='Optional search term used when refreshing both lists.')]
        [AllowEmptyString()]
        [System.String]$SearchTerm
    )

    try {
        [System.Boolean]$Succeeded = $false
        switch ($Action) {
            'Archive' {
                $Succeeded = Start-DSLArchiveSelectedFolder -SearchResultsListView $SearchResultsListView
            }
            'Restore' {
                $Succeeded = Start-DSLRestoreSelectedArchiveZip -ArchiveResultsListView $ArchiveResultsListView
            }
            'Remove' {
                $Succeeded = Remove-DSLSelectedArchiveZip -ArchiveResultsListView $ArchiveResultsListView
            }
        }

        if ($Succeeded) {
            Invoke-DSLSearchResultsRefresh -SearchResultsListView $SearchResultsListView -ArchiveResultsListView $ArchiveResultsListView -SearchTerm $SearchTerm
        }
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
    Removes the selected DSL archive zip after user confirmation.
.EXAMPLE
    Remove-DSLSelectedArchiveZip -ArchiveResultsListView $Bottom
.INPUTS
    [System.Windows.Forms.ListView]
.OUTPUTS
    [System.Boolean]
#>
####################################################################################################
function Remove-DSLSelectedArchiveZip {
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The archive results ListView containing zip files.')]
        [System.Windows.Forms.ListView]$ArchiveResultsListView
    )

    try {
        # VALIDATION - LISTVIEW SELECTION
        if (($null -eq $ArchiveResultsListView.SelectedItems) -or ($ArchiveResultsListView.SelectedItems.Count -lt 1)) {
            Write-Line 'No archive result is selected.'
            return $false
        }

        [System.Windows.Forms.ListViewItem]$SelectedItem = $ArchiveResultsListView.SelectedItems[0]
        [System.String]$SelectedZipPath = [System.String]$SelectedItem.Tag.Path
        if ((Test-String -IsEmpty $SelectedZipPath) -or (-not (Test-Path -LiteralPath $SelectedZipPath -PathType Leaf))) {
            Write-Line "The selected archive zip is invalid or missing. ($SelectedZipPath)" -Type Warning
            return $false
        }

        # CONFIRMATION
        [System.String]$SelectedZipLeaf = Split-Path -Path $SelectedZipPath -Leaf
        [System.String]$ConfirmationBody = "This will permanently remove the selected archive zip:`n`n$SelectedZipLeaf`n`nThis cannot be undone. Do you want to continue?"
        if (-not (Get-UserConfirmation -Title 'CONFIRM REMOVE ARCHIVE' -Body $ConfirmationBody -Type Warning)) {
            Write-Line 'Archive removal cancelled by user.'
            return $false
        }

        # EXECUTION
        Remove-Item -LiteralPath $SelectedZipPath -Force -ErrorAction Stop
        if (Test-Path -LiteralPath $SelectedZipPath -PathType Leaf) {
            throw "The archive zip could not be removed. ($SelectedZipPath)"
        }

        Write-Line "Archive zip removed: $SelectedZipPath" -Type Success
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
    Compresses the selected DSL folder into a zip in the configured archive folder.
.DESCRIPTION
    Uses a temporary staging folder for zip creation, validates output existence, and then moves
    the zip to the archive destination.
.EXAMPLE
    Start-DSLArchiveSelectedFolder -SearchResultsListView $Top
.INPUTS
    [System.Windows.Forms.ListView]
.OUTPUTS
    [System.Boolean]
#>
####################################################################################################
function Start-DSLArchiveSelectedFolder {
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The DSL results ListView containing source folders.')]
        [System.Windows.Forms.ListView]$SearchResultsListView
    )

    [System.String]$TempRootFolder = ''
    [System.String]$ArchiveZipPath = ''
    [System.Boolean]$ArchivePublished = $false
    [PSCustomObject]$ProgressDialog = $null
    try {
        # VALIDATION - LISTVIEW SELECTION
        if (($null -eq $SearchResultsListView.SelectedItems) -or ($SearchResultsListView.SelectedItems.Count -lt 1)) {
            Write-Line 'No DSL result is selected.'
            return $false
        }

        # PREPARATION - PATHS
        [System.Windows.Forms.ListViewItem]$SelectedItem = $SearchResultsListView.SelectedItems[0]
        [System.String]$SourceFolderPath = [System.String]$SelectedItem.Tag.Path
        [System.String]$ArchiveFolderPath = [System.String](Get-Folder -SoftwareLibraryArchive)

        # VALIDATION - SOURCE/DESTINATION
        if ((Test-String -IsEmpty $SourceFolderPath) -or (-not (Test-Path -LiteralPath $SourceFolderPath -PathType Container))) {
            Write-Line "The selected DSL folder is invalid or missing. ($SourceFolderPath)" -Type Warning
            return $false
        }
        if (Test-String -IsEmpty $ArchiveFolderPath) {
            Write-Line 'The Software Library Archive folder path is empty.' -Type Warning
            return $false
        }
        if (-not (Test-Path -LiteralPath $ArchiveFolderPath -PathType Container)) {
            New-Item -Path $ArchiveFolderPath -ItemType Directory -Force | Out-Null
        }

        [System.String]$SourceFolderName = Split-Path -Path $SourceFolderPath -Leaf
        [System.String]$ZipFileName = "$SourceFolderName.zip"
        $ArchiveZipPath = Join-Path -Path $ArchiveFolderPath -ChildPath $ZipFileName
        if (Test-Path -LiteralPath $ArchiveZipPath -PathType Leaf) {
            [System.String]$TimeStamp = Get-TimeStamp -ForFileName
            $ZipFileName = "$SourceFolderName`_$TimeStamp.zip"
            $ArchiveZipPath = Join-Path -Path $ArchiveFolderPath -ChildPath $ZipFileName
        }

        # CONFIRMATION
        # Confirm archive operation before creating and moving the zip.
        [System.String]$ArchiveSourceLeaf = Split-Path -Path $SourceFolderPath -Leaf
        [System.String]$ArchiveZipLeaf = Split-Path -Path $ArchiveZipPath -Leaf
        [System.String]$ArchiveConfirmationTitle = 'CONFIRM ARCHIVE'
        [System.String]$ArchiveConfirmationBody = "This will ARCHIVE the selected folder:`n`n$ArchiveSourceLeaf`n`ninto:`n`n$ArchiveZipLeaf`n`nThe source folder will be removed after success.`n`nDo you want to continue?"
        if (-not (Get-UserConfirmation -Title $ArchiveConfirmationTitle -Body $ArchiveConfirmationBody)) {
            Write-Line 'Archive operation cancelled by user.'
            return $false
        }

        # EXECUTION - TEMP STAGING
        [System.String]$TempRootFolder = Join-Path -Path $ENV:TEMP -ChildPath ([System.IO.Path]::GetRandomFileName())
        New-Item -Path $TempRootFolder -ItemType Directory -Force | Out-Null
        [System.String]$TempZipPath = Join-Path -Path $TempRootFolder -ChildPath $ZipFileName

        Write-Line "Creating archive zip from folder: $SourceFolderPath" -Type Busy
        if ($script:UseNativeDSLCompression) {
            $ProgressDialog = New-CompressionProgressDialog -Owner $Global:MainForm -Title 'Archiving DSL folder'
            $null = New-ZipArchiveFromDirectory -SourceDirectory $SourceFolderPath -DestinationPath $TempZipPath -IncludeBaseDirectory -ProgressAction $ProgressDialog.Update
        }
        else {
            Compress-Archive -LiteralPath $SourceFolderPath -DestinationPath $TempZipPath -Force
        }

        # Fallback for empty folder archives where Compress-Archive may not emit a zip file.
        if (-not (Test-Path -LiteralPath $TempZipPath -PathType Leaf)) {
            [System.IO.FileInfo]$FirstSourceFile = Get-ChildItem -LiteralPath $SourceFolderPath -File -Recurse -Force -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($null -eq $FirstSourceFile) {
                Add-Type -AssemblyName System.IO.Compression
                Add-Type -AssemblyName System.IO.Compression.FileSystem
                [System.IO.Compression.ZipArchive]$ZipArchive = [System.IO.Compression.ZipFile]::Open($TempZipPath, [System.IO.Compression.ZipArchiveMode]::Create)
                try {
                    # Preserve the selected folder name in the archive for predictable restore behavior.
                    $null = $ZipArchive.CreateEntry((Split-Path -Path $SourceFolderPath -Leaf) + '/')
                }
                finally {
                    $ZipArchive.Dispose()
                }
            }
        }

        if (-not (Test-Path -LiteralPath $TempZipPath -PathType Leaf)) {
            Write-Line 'The archive zip was not created successfully.' -Type Fail
            return $false
        }

        Move-Item -LiteralPath $TempZipPath -Destination $ArchiveZipPath -Force
        if (-not (Test-Path -LiteralPath $ArchiveZipPath -PathType Leaf)) {
            throw "The archive zip was not published successfully. ($ArchiveZipPath)"
        }
        $ArchivePublished = $true

        # EXECUTION - LIFECYCLE LOG
        # Write to a temporary copy, then replace the archived log entry before deleting the source.
        [PSCustomObject]$ApplicationLogContext = Get-ApplicationLogContext -ApplicationFolderPath $SourceFolderPath -CreateIfMissing
        if ($null -eq $ApplicationLogContext) {
            throw "The application log context could not be resolved. ($SourceFolderPath)"
        }
        [System.String]$StagedLogFilePath = Join-Path -Path $TempRootFolder -ChildPath ([System.IO.Path]::GetFileName($ApplicationLogContext.LogFilePath))
        if (Test-Path -LiteralPath $ApplicationLogContext.LogFilePath -PathType Leaf) {
            Copy-Item -LiteralPath $ApplicationLogContext.LogFilePath -Destination $StagedLogFilePath -Force
        }
        [System.String]$OperationID = [System.Guid]::NewGuid().ToString()
        Write-ApplicationLogEntry -LogFilePath $StagedLogFilePath -ApplicationID $ApplicationLogContext.ApplicationID -Status Success -Action ApplicationFolderArchived -Details "Archived application folder to: $ZipFileName" -OperationID $OperationID
        Confirm-DSLApplicationLogEvent -LogFilePath $StagedLogFilePath -Action ApplicationFolderArchived -OperationID $OperationID
        if ($script:UseNativeDSLCompression) {
            [System.String]$RelativeLogPath = $ApplicationLogContext.LogFilePath.Substring($SourceFolderPath.TrimEnd('\').Length).TrimStart('\')
            [System.String]$ArchiveEntryPath = (Split-Path -Path $SourceFolderPath -Leaf) + '/' + $RelativeLogPath.Replace('\', '/')
            $null = Set-ZipArchiveEntryFromFile -ArchivePath $ArchiveZipPath -EntryName $ArchiveEntryPath -SourceFilePath $StagedLogFilePath -ProgressAction $ProgressDialog.Update
        }
        else {
            Set-DSLArchiveLogFile -ArchiveZipPath $ArchiveZipPath -ApplicationFolderPath $SourceFolderPath -SourceLogFilePath $ApplicationLogContext.LogFilePath -StagedLogFilePath $StagedLogFilePath
        }

        Write-Line "Archive created: $ArchiveZipPath" -Type Success

        # POST-EXECUTION - SOURCE CLEANUP
        # Remove the original source folder now that the archive has been created.
        if (Test-Path -LiteralPath $SourceFolderPath -PathType Container) {
            Remove-Item -LiteralPath $SourceFolderPath -Recurse -Force -ErrorAction SilentlyContinue
            if (Test-Path -LiteralPath $SourceFolderPath -PathType Container) {
                Write-Line "Archive created, but source folder could not be removed. ($SourceFolderPath)" -Type Warning
            }
            else {
                Write-Line "Source folder removed after archive. ($SourceFolderPath)" -Type Success
            }
        }

        return $true
    }
    catch {
        if ($ArchivePublished -and (Test-Path -LiteralPath $SourceFolderPath -PathType Container) -and (Test-Path -LiteralPath $ArchiveZipPath -PathType Leaf)) {
            Remove-Item -LiteralPath $ArchiveZipPath -Force -ErrorAction SilentlyContinue
        }
        Write-ErrorReport -ErrorRecord $_
        return $false
    }
    finally {
        if ($null -ne $ProgressDialog) {
            $null = $ProgressDialog.Close.Invoke()
        }
        if ((Test-String -IsPopulated $TempRootFolder) -and (Test-Path -LiteralPath $TempRootFolder -PathType Container)) {
            Remove-Item -LiteralPath $TempRootFolder -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Restores the selected archive zip into the configured Software Library folder.
.DESCRIPTION
    Extracts the selected archive zip to a temporary folder first, then moves content into a
    destination folder in the Software Library.
.EXAMPLE
    Start-DSLRestoreSelectedArchiveZip -ArchiveResultsListView $Bottom
.INPUTS
    [System.Windows.Forms.ListView]
.OUTPUTS
    [System.Boolean]
#>
####################################################################################################
function Start-DSLRestoreSelectedArchiveZip {
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The archive results ListView containing zip files.')]
        [System.Windows.Forms.ListView]$ArchiveResultsListView
    )

    [System.String]$TempRootFolder = ''
    [System.String]$DestinationFolderPath = ''
    [System.Boolean]$RestorePublished = $false
    [PSCustomObject]$ProgressDialog = $null
    try {
        # VALIDATION - LISTVIEW SELECTION
        if (($null -eq $ArchiveResultsListView.SelectedItems) -or ($ArchiveResultsListView.SelectedItems.Count -lt 1)) {
            Write-Line 'No archive result is selected.'
            return $false
        }

        # PREPARATION - PATHS
        [System.Windows.Forms.ListViewItem]$SelectedItem = $ArchiveResultsListView.SelectedItems[0]
        [System.String]$SelectedZipPath = [System.String]$SelectedItem.Tag.Path
        [System.String]$SoftwareLibraryFolder = [System.String](Get-Folder -SoftwareLibrary)

        # VALIDATION - SOURCE/DESTINATION
        if ((Test-String -IsEmpty $SelectedZipPath) -or (-not (Test-Path -LiteralPath $SelectedZipPath -PathType Leaf))) {
            Write-Line "The selected archive zip is invalid or missing. ($SelectedZipPath)" -Type Warning
            return $false
        }
        if ((Test-String -IsEmpty $SoftwareLibraryFolder) -or (-not (Test-Path -LiteralPath $SoftwareLibraryFolder -PathType Container))) {
            Write-Line "The Software Library folder path is invalid. ($SoftwareLibraryFolder)" -Type Warning
            return $false
        }

        # PREPARATION - DESTINATION
        [System.String]$ZipBaseName = [System.IO.Path]::GetFileNameWithoutExtension($SelectedZipPath)
        [System.String]$RestoreFolderName = $ZipBaseName
        $DestinationFolderPath = Join-Path -Path $SoftwareLibraryFolder -ChildPath $RestoreFolderName
        if (Test-Path -LiteralPath $DestinationFolderPath -PathType Container) {
            [System.String]$TimeStamp = Get-TimeStamp -ForFileName
            $DestinationFolderPath = Join-Path -Path $SoftwareLibraryFolder -ChildPath ("$RestoreFolderName`_$TimeStamp")
        }

        # CONFIRMATION
        # Confirm restore operation before extracting and moving content.
        [System.String]$RestoreZipLeaf = Split-Path -Path $SelectedZipPath -Leaf
        [System.String]$RestoreDestinationLeaf = Split-Path -Path $DestinationFolderPath -Leaf
        [System.String]$RestoreConfirmationTitle = 'CONFIRM RESTORE'
        [System.String]$RestoreConfirmationBody = "This will RESTORE the selected archive:`n`n$RestoreZipLeaf`n`ninto:`n`n$RestoreDestinationLeaf`n`nThe source zip will be removed after success.`n`nDo you want to continue?"
        if (-not (Get-UserConfirmation -Title $RestoreConfirmationTitle -Body $RestoreConfirmationBody)) {
            Write-Line 'Restore operation cancelled by user.'
            return $false
        }

        # EXECUTION - TEMP EXTRACT
        if ($script:UseNativeDSLCompression) {
            $ProgressDialog = New-CompressionProgressDialog -Owner $Global:MainForm -Title 'Restoring DSL archive'
        }
        [System.String]$TempRootFolder = Join-Path -Path $ENV:TEMP -ChildPath ([System.IO.Path]::GetRandomFileName())
        New-Item -Path $TempRootFolder -ItemType Directory -Force | Out-Null
        if ($script:UseNativeDSLCompression) {
            $null = Expand-ZipArchive -ArchivePath $SelectedZipPath -DestinationPath $TempRootFolder -ProgressAction $ProgressDialog.Update
        }
        else {
            Expand-Archive -LiteralPath $SelectedZipPath -DestinationPath $TempRootFolder -Force
        }

        [System.IO.DirectoryInfo[]]$ExtractedDirectories = @(Get-ChildItem -LiteralPath $TempRootFolder -Directory -Force -ErrorAction SilentlyContinue)
        [System.IO.FileInfo[]]$ExtractedFiles = @(Get-ChildItem -LiteralPath $TempRootFolder -File -Force -ErrorAction SilentlyContinue)

        # EXECUTION - RESTORE
        if (($ExtractedDirectories.Count -eq 1) -and ($ExtractedFiles.Count -eq 0)) {
            Move-Item -LiteralPath $ExtractedDirectories[0].FullName -Destination $DestinationFolderPath -Force
        }
        else {
            New-Item -Path $DestinationFolderPath -ItemType Directory -Force | Out-Null
            Get-ChildItem -LiteralPath $TempRootFolder -Force | ForEach-Object {
                Move-Item -LiteralPath $_.FullName -Destination $DestinationFolderPath -Force
            }
        }
        if (-not (Test-Path -LiteralPath $DestinationFolderPath -PathType Container)) {
            throw "The application folder was not restored successfully. ($DestinationFolderPath)"
        }
        $RestorePublished = $true

        Write-Line "Archive restored to folder: $DestinationFolderPath" -Type Success

        # EXECUTION - LIFECYCLE LOG
        [PSCustomObject]$ApplicationLogContext = Get-ApplicationLogContext -ApplicationFolderPath $DestinationFolderPath -CreateIfMissing
        if ($null -eq $ApplicationLogContext) {
            throw "The application log context could not be resolved. ($DestinationFolderPath)"
        }
        [System.String]$OperationID = [System.Guid]::NewGuid().ToString()
        Write-ApplicationLogEntry -LogFilePath $ApplicationLogContext.LogFilePath -ApplicationID $ApplicationLogContext.ApplicationID -Status Success -Action ApplicationFolderRestored -Details "Restored application folder from: $RestoreZipLeaf" -OperationID $OperationID
        Confirm-DSLApplicationLogEvent -LogFilePath $ApplicationLogContext.LogFilePath -Action ApplicationFolderRestored -OperationID $OperationID

        # POST-EXECUTION - SOURCE CLEANUP
        # Remove the original archive zip now that restore has succeeded.
        if (Test-Path -LiteralPath $SelectedZipPath -PathType Leaf) {
            Remove-Item -LiteralPath $SelectedZipPath -Force -ErrorAction SilentlyContinue
            if (Test-Path -LiteralPath $SelectedZipPath -PathType Leaf) {
                Write-Line "Archive restored, but source zip could not be removed. ($SelectedZipPath)" -Type Warning
            }
            else {
                Write-Line "Source zip removed after restore. ($SelectedZipPath)" -Type Success
            }
        }

        return $true
    }
    catch {
        if ($RestorePublished -and (Test-Path -LiteralPath $SelectedZipPath -PathType Leaf) -and (Test-Path -LiteralPath $DestinationFolderPath -PathType Container)) {
            Remove-Item -LiteralPath $DestinationFolderPath -Recurse -Force -ErrorAction SilentlyContinue
        }
        Write-ErrorReport -ErrorRecord $_
        return $false
    }
    finally {
        if ($null -ne $ProgressDialog) {
            $null = $ProgressDialog.Close.Invoke()
        }
        if ((Test-String -IsPopulated $TempRootFolder) -and (Test-Path -LiteralPath $TempRootFolder -PathType Container)) {
            Remove-Item -LiteralPath $TempRootFolder -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Confirms that a DSL lifecycle event was appended to an application log.
.OUTPUTS
    No objects are returned to the pipeline.
#>
####################################################################################################
function Confirm-DSLApplicationLogEvent {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [System.String]$LogFilePath,

        [Parameter(Mandatory=$true)]
        [System.String]$Action,

        [Parameter(Mandatory=$true)]
        [System.String]$OperationID
    )

    [PSCustomObject]$WrittenEntry = Import-Csv -LiteralPath $LogFilePath | Select-Object -Last 1
    if (($null -eq $WrittenEntry) -or ($WrittenEntry.Action -ne $Action) -or ($WrittenEntry.OperationID -ne $OperationID)) {
        throw "The application lifecycle event was not written. ($Action)"
    }
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Replaces an application log entry inside a DSL archive with a staged log file.
.OUTPUTS
    No objects are returned to the pipeline.
#>
####################################################################################################
function Set-DSLArchiveLogFile {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [System.String]$ArchiveZipPath,

        [Parameter(Mandatory=$true)]
        [System.String]$ApplicationFolderPath,

        [Parameter(Mandatory=$true)]
        [System.String]$SourceLogFilePath,

        [Parameter(Mandatory=$true)]
        [System.String]$StagedLogFilePath
    )

    Add-Type -AssemblyName System.IO.Compression
    Add-Type -AssemblyName System.IO.Compression.FileSystem

    [System.String]$ApplicationFolderName = Split-Path -Path $ApplicationFolderPath -Leaf
    [System.String]$RelativeLogPath = $SourceLogFilePath.Substring($ApplicationFolderPath.TrimEnd('\').Length).TrimStart('\')
    [System.String]$ArchiveEntryPath = Join-Path -Path $ApplicationFolderName -ChildPath $RelativeLogPath
    [System.IO.Compression.ZipArchive]$ZipArchive = [System.IO.Compression.ZipFile]::Open($ArchiveZipPath, [System.IO.Compression.ZipArchiveMode]::Update)
    try {
        [System.IO.Compression.ZipArchiveEntry]$ExistingEntry = $ZipArchive.GetEntry($ArchiveEntryPath)
        if ($null -ne $ExistingEntry) {
            $ExistingEntry.Delete()
        }
        $null = [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($ZipArchive, $StagedLogFilePath, $ArchiveEntryPath, [System.IO.Compression.CompressionLevel]::Optimal)
    }
    finally {
        $ZipArchive.Dispose()
    }
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Refreshes both DSL search result listviews using one optional search term.
.DESCRIPTION
    This helper updates the top DSL folder results and bottom archive zip results together so
    Enter/Search/Show All can share one execution path.
.EXAMPLE
    Invoke-DSLSearchResultsRefresh -SearchResultsListView $Top -ArchiveResultsListView $Bottom -SearchTerm 'web'
.INPUTS
    [System.Windows.Forms.ListView]
    [System.String]
.OUTPUTS
    No objects are returned to the pipeline.
#>
####################################################################################################
function Invoke-DSLSearchResultsRefresh {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The top DSL results ListView.')]
        [System.Windows.Forms.ListView]$SearchResultsListView,

        [Parameter(Mandatory=$true,HelpMessage='The bottom archive results ListView.')]
        [System.Windows.Forms.ListView]$ArchiveResultsListView,

        [Parameter(Mandatory=$false,HelpMessage='Optional search term used for both result lists.')]
        [AllowEmptyString()]
        [System.String]$SearchTerm
    )

    try {
        Show-DSLFoldersInListView -ListView $SearchResultsListView -SearchTerm $SearchTerm
        Show-DSLArchiveZipFilesInListView -ListView $ArchiveResultsListView -SearchTerm $SearchTerm
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
    Clears both DSL search result listviews and reapplies column autosize.
.DESCRIPTION
    This helper centralizes clear/reset behavior for both listviews to keep the button handlers
    concise and consistent.
.EXAMPLE
    Clear-DSLSearchResultListViews -SearchResultsListView $Top -ArchiveResultsListView $Bottom
.INPUTS
    [System.Windows.Forms.ListView]
.OUTPUTS
    No objects are returned to the pipeline.
#>
####################################################################################################
function Clear-DSLSearchResultListViews {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The top DSL results ListView to clear.')]
        [System.Windows.Forms.ListView]$SearchResultsListView,

        [Parameter(Mandatory=$true,HelpMessage='The bottom archive results ListView to clear.')]
        [System.Windows.Forms.ListView]$ArchiveResultsListView
    )

    try {
        $SearchResultsListView.Items.Clear()
        $ArchiveResultsListView.Items.Clear()
        Set-ListViewColumnAutoSize -ListView $SearchResultsListView -Mode Widest
        Set-ListViewColumnAutoSize -ListView $ArchiveResultsListView -Mode Widest
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
    Executes a shared context-aware action for DSL Search and Archive result listviews.
.DESCRIPTION
    This helper resolves the effective target list based on the last active listview and current
    selection state, then dispatches to Start-SelectedApplicationAction with the mapped action.
.EXAMPLE
    Invoke-DSLSearchContextAction -Action 'Open' -SearchResultsListView $Top -ArchiveResultsListView $Bottom -SelectionContext $Context
.INPUTS
    [System.String]
    [System.Windows.Forms.ListView]
    [System.Collections.Hashtable]
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.5.3
    Author          : Imraan Iotana
    Creation Date   : August 2026
    Last Update     : August 2026
#>
####################################################################################################
function Invoke-DSLSearchContextAction {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The logical action requested by the shared button row.')]
        [ValidateSet('Open','CopyPath','ShowInfo','OpenDocumentation','OpenOrGenerateDocumentation','ShowLog')]
        [System.String]$Action,

        [Parameter(Mandatory=$true,HelpMessage='The top DSL results ListView.')]
        [System.Windows.Forms.ListView]$SearchResultsListView,

        [Parameter(Mandatory=$true,HelpMessage='The bottom archive results ListView.')]
        [System.Windows.Forms.ListView]$ArchiveResultsListView,

        [Parameter(Mandatory=$true,HelpMessage='Selection context hashtable that stores the active ListView.')]
        [System.Collections.Hashtable]$SelectionContext
    )

    try {
        [System.String]$ArchiveAction = if ($Action -eq 'Open') { 'OpenAndHighlight' } else { $Action }
        [System.String]$SearchAction = $Action

        if (($SelectionContext.ActiveListView -eq $ArchiveResultsListView) -and ($ArchiveResultsListView.SelectedItems.Count -gt 0)) {
            Start-SelectedApplicationAction -Action $ArchiveAction -ListView $ArchiveResultsListView
            return
        }

        if (($SelectionContext.ActiveListView -eq $SearchResultsListView) -and ($SearchResultsListView.SelectedItems.Count -gt 0)) {
            Start-SelectedApplicationAction -Action $SearchAction -ListView $SearchResultsListView
            return
        }

        if (($ArchiveResultsListView.SelectedItems.Count -gt 0) -and ($SearchResultsListView.SelectedItems.Count -eq 0)) {
            Start-SelectedApplicationAction -Action $ArchiveAction -ListView $ArchiveResultsListView
            return
        }

        if ($SearchResultsListView.SelectedItems.Count -gt 0) {
            Start-SelectedApplicationAction -Action $SearchAction -ListView $SearchResultsListView
            return
        }

        Write-Line 'No DSL or archive result is selected.'
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
    Fills a ListView with zip files from the configured Software Library Archive folder.
.DESCRIPTION
    This function retrieves zip files from the archive folder and lists them in the provided
    ListView. The ListView is cleared before filling and the columns are auto-sized after update.
.EXAMPLE
    Show-DSLArchiveZipFilesInListView -ListView $MyListView
.INPUTS
    [System.Windows.Forms.ListView]
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.5.3
    Author          : Imraan Iotana
    Creation Date   : August 2026
    Last Update     : August 2026
#>
####################################################################################################
function Show-DSLArchiveZipFilesInListView {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The ListView that will be filled with archive zip file results.')]
        [System.Windows.Forms.ListView]$ListView,

        [Parameter(Mandatory=$false,HelpMessage='Optional search term used to filter archive zip file names.')]
        [AllowEmptyString()]
        [System.String]$SearchTerm
    )

    try {
        # PREPARATION
        # Resolve zip file objects from the configured archive folder.
        [System.String]$ArchiveFolder = Get-Folder -SoftwareLibraryArchive
        [System.String]$NormalizedFilter = $SearchTerm.Trim()
        [System.String]$ExclusionPrefix = '_'
        [PSCustomObject]$ColorTheme = Get-ListViewColorTheme -ListView $ListView

        # VALIDATION
        # Validate the archive folder path before reading files.
        if ((Test-String -IsEmpty $ArchiveFolder) -or (-not (Test-Path -LiteralPath $ArchiveFolder -PathType Container))) {
            Write-Line "The Software Library Archive folder path is empty or invalid. The archive results could not be retrieved."
            Invoke-ListViewBatchUpdate -ListView $ListView -Action {
                $ListView.Items.Clear()
                Set-ListViewColumnAutoSize -ListView $ListView -Mode Widest
            }
            return
        }

        [System.IO.FileInfo[]]$ZipFileObjects = @(
            Get-ChildItem -LiteralPath $ArchiveFolder -File -Filter '*.zip' -ErrorAction SilentlyContinue |
            Where-Object { -not ($_.Name.StartsWith($ExclusionPrefix)) } |
            Sort-Object Name
        )

        # Apply a case-insensitive filter when requested.
        if (Test-String -IsPopulated $NormalizedFilter) {
            $ZipFileObjects = $ZipFileObjects | Where-Object { ($_.Name.IndexOf($NormalizedFilter,[System.StringComparison]::OrdinalIgnoreCase) -ge 0) }
        }

        # EXECUTION
        # Refresh the ListView in one paint cycle to avoid flicker.
        Invoke-ListViewBatchUpdate -ListView $ListView -Action {
            $ListView.Items.Clear()
            [System.Int32]$Index = 1

            foreach ($ZipFileObject in $ZipFileObjects) {
                [System.String]$ZipFileName = [System.String]$ZipFileObject.Name
                [System.String]$ZipFilePath = [System.String]$ZipFileObject.FullName

                [System.Windows.Forms.ListViewItem]$ResultItem = New-Object System.Windows.Forms.ListViewItem([System.String]$Index)
                $ResultItem.Tag = [PSCustomObject]@{
                    Name = $ZipFileName
                    Path = $ZipFilePath
                }
                $null = $ResultItem.SubItems.Add($ZipFileName)
                $null = $ResultItem.SubItems.Add($ZipFilePath)
                Set-ListViewItemReadOnlyStyle -ListViewItem $ResultItem -ColorTheme $ColorTheme
                $null = $ListView.Items.Add($ResultItem)
                $Index++
            }

            Write-Line "Found $($ZipFileObjects.Count) zip files in the DSL archive folder."
            Set-ListViewColumnAutoSize -ListView $ListView -Mode Widest
        }
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
    Fills a ListView with direct subfolders in the Software Library.
.DESCRIPTION
    This function retrieves direct DSL subfolder names with Get-DSLDirectSubFolderNames.
    When SearchTerm is provided, matching folders are returned; when empty, all folders are returned.
    The provided ListView is cleared and then filled with one row per folder.
.EXAMPLE
    Show-DSLFoldersInListView -ListView $MyListView
.EXAMPLE
    Show-DSLFoldersInListView -ListView $MyListView -SearchTerm 'Web'
.INPUTS
    [System.Windows.Forms.ListView]
    [System.String]
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.5.3
    Author          : Imraan Iotana
    Creation Date   : July 2026
    Last Update     : August 2026
#>
####################################################################################################
function Show-DSLFoldersInListView {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The ListView that will be filled with DSL folder results.')]
        [System.Windows.Forms.ListView]$ListView,

        [Parameter(Mandatory=$false,HelpMessage='Optional search term used to filter DSL subfolder names.')]
        [AllowEmptyString()]
        [System.String]$SearchTerm
    )

    try {
        # PREPARATION
        # Resolve direct child folder objects from the Software Library.
        [System.IO.DirectoryInfo[]]$DirectSubFolderObjects = @(Get-DSLDirectSubFolderNames -Filter $SearchTerm -As Object)
        [PSCustomObject]$ColorTheme = Get-ListViewColorTheme -ListView $ListView

        # EXECUTION
        # Refresh the ListView in one paint cycle to avoid flicker.
        Invoke-ListViewBatchUpdate -ListView $ListView -Action {
            # Clear the ListView before adding new items.
            $ListView.Items.Clear()
            # Set the initial index for the ListView rows.
            [System.Int32]$Index = 1
            # Loop through the direct subfolder objects and add them to the ListView.
            foreach ($DirectSubFolderObject in $DirectSubFolderObjects) {
                [System.String]$DirectSubFolderName = [System.String]$DirectSubFolderObject.Name
                [System.String]$FolderPath = [System.String]$DirectSubFolderObject.FullName
                # Create a new ListViewItem for each folder and add it to the ListView.
                [System.Windows.Forms.ListViewItem]$ResultItem = New-Object System.Windows.Forms.ListViewItem([System.String]$Index)
                $ResultItem.Tag = [PSCustomObject]@{
                    Name = $DirectSubFolderName
                    Path = $FolderPath
                }
                $null = $ResultItem.SubItems.Add($DirectSubFolderName)
                $null = $ResultItem.SubItems.Add($FolderPath)
                Set-ListViewItemReadOnlyStyle -ListViewItem $ResultItem -ColorTheme $ColorTheme
                $null = $ListView.Items.Add($ResultItem)
                # Increment the index for the next row.
                $Index++
            }
            # Write a message to the host indicating how many folders were found and displayed.
            Write-Line "Found $($DirectSubFolderObjects.Count) DSL folders."

            # Size columns to the headers when empty, or to the content when populated.
            Set-ListViewColumnAutoSize -ListView $ListView -Mode Widest
        }
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
    Performs an action on the selected DSL search result.
.DESCRIPTION
    This helper resolves the selected search result path through the shared ListView path resolver
    and performs the requested action.
    Supported actions are opening the folder and copying the folder path.
.EXAMPLE
    Start-SelectedApplicationAction -Action 'Open' -ListView $MyListView
.INPUTS
    [System.String]
    [System.Windows.Forms.ListView]
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.5.3
    Author          : Imraan Iotana
    Creation Date   : July 2026
    Last Update     : August 2026
#>
####################################################################################################
function Start-SelectedApplicationAction {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The action to perform on the selected DSL search result.')]
        [ValidateSet('Open','OpenAndHighlight','CopyPath','ShowInfo','OpenDocumentation','OpenOrGenerateDocumentation','ShowLog')]
        [System.String]$Action,

        [Parameter(Mandatory=$true,HelpMessage='The ListView containing DSL search results.')]
        [System.Windows.Forms.ListView]$ListView
    )

    try {
        # PREPARATION - SELECTED PATH
        # Resolve the Path property from the selected DSL result record
        [System.String]$SelectedPath = Get-SelectedListViewItemPath -ListView $ListView -PathPropertyName 'Path' -ItemName 'search result'
        if ([System.String]::IsNullOrWhiteSpace($SelectedPath)) { return }

        # EXECUTION - ACTION
        # Perform the requested action on the selected path.
        switch ($Action) {
            'Open' {
                Open-Folder -Path $SelectedPath
            }
            'OpenAndHighlight' {
                Open-Folder -HighlightItem $SelectedPath
            }
            'CopyPath' {
                Set-ClipBoard -Value $SelectedPath
                Write-Line "The selected folder path has been copied to the clipboard. ($SelectedPath)"
            }
            'ShowInfo' {
                if (Test-Path -LiteralPath $SelectedPath -PathType Container) {
                    Write-FolderPropertiesToHost -Path $SelectedPath
                }
                elseif (Test-Path -LiteralPath $SelectedPath -PathType Leaf) {
                    Write-FilePropertiesToHost -Path $SelectedPath
                }
                else {
                    Write-Line "The selected search result path could not be found. ($SelectedPath)"
                }
            }
            'ShowLog' {
                Show-DSLSelectedApplicationLog -Path $SelectedPath
            }
            'OpenDocumentation' {
                Open-DSLSelectedApplicationDocumentation -Path $SelectedPath
            }
            'OpenOrGenerateDocumentation' {
                Invoke-DSLSelectedApplicationDocumentation -Path $SelectedPath
            }
        }
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
    Opens existing documentation or creates missing Dossier and TAT documents.
.DESCRIPTION
    Opens existing documentation normally. When Dossier or TAT documents are missing, the function
    creates only the missing documents from package templates or, after confirmation, the selected
    customer template from the Intake Templates screen.
.EXAMPLE
    Invoke-DSLSelectedApplicationDocumentation -Path 'C:\Applications\Vendor_App_1.0'
.INPUTS
    [System.String]
.OUTPUTS
    None.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.7.1
    Author          : Imraan Iotana
    Creation Date   : August 2026
    Last Update     : September 2026
#>
####################################################################################################
function Invoke-DSLSelectedApplicationDocumentation {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The selected DSL application folder or archive zip path.')]
        [ValidateNotNullOrEmpty()]
        [System.String]$Path
    )

    try {
        if (Test-Path -LiteralPath $Path -PathType Leaf) {
            if ([System.IO.Path]::GetExtension($Path) -ieq '.zip') {
                Write-Line 'The selected application is archived. Restore it before generating documentation.' -Type Warning
            }
            else {
                Write-Line "The selected documentation path is not an application folder. ($Path)" -Type Warning
            }
            return
        }

        if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
            Write-Line "The selected application folder could not be found. ($Path)" -Type Warning
            return
        }

        [System.Boolean]$UseSelectedCustomerTemplateFallback = $false
        [System.IO.FileInfo[]]$TemplateFiles = @(
            '*.dotx','*.dotm' | ForEach-Object {
                Get-ChildItem -LiteralPath $Path -File -Filter $_ -Recurse -ErrorAction SilentlyContinue
            } | Sort-Object -Property FullName -Unique
        )
        [System.IO.FileInfo]$TemplateFile = $TemplateFiles | Select-Object -First 1
        [System.IO.FileInfo]$MetadataFile = Get-ChildItem -LiteralPath $Path -Recurse -File -Filter '*.json' -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -like 'Metadata_*.json' } | Select-Object -First 1

        if ($null -eq $TemplateFile) {
            [System.String]$ExistingDocumentPath = Resolve-DSLApplicationDocumentationFile -ApplicationFolderPath $Path
            if (-not [System.String]::IsNullOrWhiteSpace($ExistingDocumentPath)) {
                Open-DSLDocumentationFile -Path $ExistingDocumentPath
                return
            }

            [System.Windows.Forms.ComboBox]$DocumentTemplateComboBox = Get-ComboBoxObject -ComboBoxName 'DocumentCustomerTemplate'
            [System.Object]$SelectedCustomerTemplate = if ($null -ne $DocumentTemplateComboBox) { $DocumentTemplateComboBox.SelectedItem } else { $null }
            [System.String]$SelectedCustomerTemplateName = if ($null -ne $SelectedCustomerTemplate -and $null -ne $SelectedCustomerTemplate.PSObject.Properties['Identity']) { [System.String]$SelectedCustomerTemplate.Identity } else { '' }

            if ($null -eq $SelectedCustomerTemplate -or
                ($null -ne $SelectedCustomerTemplate.PSObject.Properties['IsCustomTemplate'] -and [System.Boolean]$SelectedCustomerTemplate.IsCustomTemplate)) {
                Write-Line "No Word document or copied Word template was found in the selected application folder, and no customer template selection is available. ($Path)" -Type Warning
                return
            }

            [System.String]$FallbackConfirmationBody = "No Word template was found in the selected application folder.`n`nDo you want to use the selected customer template '$SelectedCustomerTemplateName' from the Intake Templates screen?"
            if (-not (Get-UserConfirmation -Title 'USE CUSTOMER TEMPLATE' -Body $FallbackConfirmationBody -Type Warning)) {
                Write-Line 'Customer template fallback cancelled by user.'
                return
            }

            [System.String[]]$FallbackTemplateNames = @()
            if ($null -ne $SelectedCustomerTemplate.Content -and $SelectedCustomerTemplate.Content -is [System.Collections.IDictionary]) {
                if ($SelectedCustomerTemplate.Content.Contains('TemplateName') -and (Test-String -IsPopulated $SelectedCustomerTemplate.Content.TemplateName)) {
                    $FallbackTemplateNames += [System.String]$SelectedCustomerTemplate.Content.TemplateName
                }
                if ($SelectedCustomerTemplate.Content.Contains('TatTemplateName') -and (Test-String -IsPopulated $SelectedCustomerTemplate.Content.TatTemplateName)) {
                    $FallbackTemplateNames += [System.String]$SelectedCustomerTemplate.Content.TatTemplateName
                }
                elseif ($SelectedCustomerTemplate.Content.Contains('TATTemplateName') -and (Test-String -IsPopulated $SelectedCustomerTemplate.Content.TATTemplateName)) {
                    $FallbackTemplateNames += [System.String]$SelectedCustomerTemplate.Content.TATTemplateName
                }
            }

            [System.String]$SelectedCustomerTemplateDirectory = [System.String]$SelectedCustomerTemplate.Directory
            $UseSelectedCustomerTemplateFallback = $true
            [System.IO.FileInfo[]]$TemplateFiles = @(
                $FallbackTemplateNames | ForEach-Object {
                    if (Test-String -IsPopulated $SelectedCustomerTemplateDirectory) {
                        Get-ChildItem -LiteralPath $SelectedCustomerTemplateDirectory -File -Filter $_ -ErrorAction SilentlyContinue
                    }
                } | Sort-Object -Property FullName -Unique
            )
            [System.IO.FileInfo]$TemplateFile = $TemplateFiles | Select-Object -First 1

            if ($null -eq $TemplateFile) {
                Write-Line "The selected customer template does not contain any usable Word templates. ($SelectedCustomerTemplateName)" -Type Warning
                return
            }
        }

        [System.String]$ApplicationID = Resolve-DSLApplicationIDFromPackage -ApplicationFolderPath $Path
        if (Test-String -IsEmpty $ApplicationID) {
            $ApplicationID = 'ApplicationDossier'
        }
        [System.String]$DocumentationRelativePath = 'Documentation'
        if ($UseSelectedCustomerTemplateFallback -and $null -ne $SelectedCustomerTemplate.ApplicationFolderSubFolders) {
            if ($SelectedCustomerTemplate.ApplicationFolderSubFolders -is [System.Collections.IDictionary] -and
                $SelectedCustomerTemplate.ApplicationFolderSubFolders.Contains('Documentation') -and
                (Test-String -IsPopulated ([System.String]$SelectedCustomerTemplate.ApplicationFolderSubFolders.Documentation))) {
                $DocumentationRelativePath = [System.String]$SelectedCustomerTemplate.ApplicationFolderSubFolders.Documentation
            }
            elseif ($null -ne $SelectedCustomerTemplate.ApplicationFolderSubFolders.PSObject.Properties['Documentation'] -and
                (Test-String -IsPopulated ([System.String]$SelectedCustomerTemplate.ApplicationFolderSubFolders.Documentation))) {
                $DocumentationRelativePath = [System.String]$SelectedCustomerTemplate.ApplicationFolderSubFolders.Documentation
            }
        }
        [System.String]$DocumentationFolderPath = if ($UseSelectedCustomerTemplateFallback) {
            Join-Path -Path $Path -ChildPath $DocumentationRelativePath
        }
        else {
            Split-Path -Path $TemplateFile.FullName -Parent
        }
        if (-not (Test-Path -LiteralPath $DocumentationFolderPath -PathType Container)) {
            New-Item -Path $DocumentationFolderPath -ItemType Directory -Force | Out-Null
        }
        [System.IO.FileInfo[]]$PendingTemplateFiles = @(
            $TemplateFiles | Where-Object {
                [System.String]$ExpectedDocumentName = Get-IntakeOutputDocumentFileName -TemplateFileName $_.Name -ApplicationID $ApplicationID
                -not (Test-Path -LiteralPath (Join-Path -Path $DocumentationFolderPath -ChildPath $ExpectedDocumentName) -PathType Leaf)
            }
        )

        if ($PendingTemplateFiles.Count -eq 0) {
            [System.String]$DocumentPath = Resolve-DSLApplicationDocumentationFile -ApplicationFolderPath $Path
            if (Test-String -IsPopulated $DocumentPath) {
                Open-DSLDocumentationFile -Path $DocumentPath
            }
            else {
                Write-Line "The selected application has no dossier documentation file to open. ($Path)" -Type Warning
            }
            return
        }

        [System.String]$PendingDocumentNames = ($PendingTemplateFiles | ForEach-Object {
            Get-IntakeOutputDocumentFileName -TemplateFileName $_.Name -ApplicationID $ApplicationID
        }) -join ', '
        [System.String]$ConfirmationBody = "The following documentation file(s) are missing:`n`n$PendingDocumentNames`n`nApplicationID: $ApplicationID`n`nDo you want to create them now?"
        if (-not (Get-UserConfirmation -Title 'CREATE DOCUMENTATION' -Body $ConfirmationBody -Type Warning)) {
            Write-Line 'Documentation creation cancelled by user.'
            return
        }

        [System.Boolean]$AnyDocumentCreated = $false
        foreach ($PendingTemplateFile in $PendingTemplateFiles) {
            [System.Boolean]$CurrentDocumentCreated = Invoke-DocumentGeneration -WordTemplatePath $PendingTemplateFile.FullName -MetaDataJsonPath $MetadataFile.FullName -OutputFolder $DocumentationFolderPath
            $AnyDocumentCreated = $AnyDocumentCreated -or $CurrentDocumentCreated
        }
        if ($AnyDocumentCreated -or (Test-String -IsPopulated (Resolve-DSLApplicationDocumentationFile -ApplicationFolderPath $Path))) {
            Open-DSLSelectedApplicationDocumentation -Path $Path
        }
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
    Shows the application log for a selected DSL folder or archive zip file.
.DESCRIPTION
    Uses the existing application log context resolver for application folders and falls back to
    searching a selected archive zip for a unique *_Log.csv entry.
.EXAMPLE
    Show-DSLSelectedApplicationLog -Path 'C:\Temp\Vendor_App_1.0'
.INPUTS
    [System.String]
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.5.3
    Author          : Imraan Iotana
    Creation Date   : August 2026
    Last Update     : August 2026
#>
####################################################################################################
function Show-DSLSelectedApplicationLog {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The selected DSL folder or archive zip path.')]
        [System.String]$Path
    )

    try {
        if (Test-Path -LiteralPath $Path -PathType Container) {
            [PSCustomObject]$ApplicationLogContext = Get-ApplicationLogContext -ApplicationFolderPath $Path
            if (($null -eq $ApplicationLogContext) -or (Test-String -IsEmpty ([System.String]$ApplicationLogContext.LogFilePath))) {
                Write-Line "No application log file was found in the selected DSL folder. ($Path)" -Type Warning
                return
            }

            Show-LogFileInGridView -Path $ApplicationLogContext.LogFilePath
            return
        }

        if ((Test-Path -LiteralPath $Path -PathType Leaf) -and ([System.IO.Path]::GetExtension($Path) -ieq '.zip')) {
            [PSCustomObject]$ArchiveFile = Resolve-DSLArchivePackageFile -ArchiveZipPath $Path -FileNamePatterns @('*_Log.csv') -PreferredFolderNamePart 'Logs' -ArtifactName 'application log'
            if ($null -eq $ArchiveFile) { return }

            try {
                Show-LogFileInGridView -Path $ArchiveFile.FilePath
            }
            finally {
                if (($ArchiveFile.IsTemporary) -and (Test-String -IsPopulated ([System.String]$ArchiveFile.TempRootFolder)) -and (Test-Path -LiteralPath $ArchiveFile.TempRootFolder -PathType Container)) {
                    Remove-Item -LiteralPath $ArchiveFile.TempRootFolder -Recurse -Force -ErrorAction SilentlyContinue
                }
            }
            return
        }

        Write-Line "The selected path is not a DSL folder or archive zip file. ($Path)" -Type Warning
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
    Resolves and extracts one file from a DSL archive zip file.
.DESCRIPTION
    Opens the archive, finds a unique matching entry with preference for entries under a matching
    folder name, extracts it to a temporary file, and returns the extracted file context.
.EXAMPLE
    Resolve-DSLArchivePackageFile -ArchiveZipPath 'C:\Archive\Vendor_App_1.0.zip' -FileNamePatterns @('*.docx') -PreferredFolderNamePart 'Documentation' -ArtifactName 'Word document'
.INPUTS
    [System.String]
.OUTPUTS
    [PSCustomObject]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.5.3
    Author          : Imraan Iotana
    Creation Date   : August 2026
    Last Update     : August 2026
#>
####################################################################################################
function Resolve-DSLArchivePackageFile {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The selected DSL archive zip path.')]
        [System.String]$ArchiveZipPath,

        [Parameter(Mandatory=$true,HelpMessage='File name patterns used to find the archive entry.')]
        [System.String[]]$FileNamePatterns,

        [Parameter(Mandatory=$false,HelpMessage='Preferred folder name fragment for selecting an entry.')]
        [System.String]$PreferredFolderNamePart,

        [Parameter(Mandatory=$true,HelpMessage='Friendly artifact name used in messages.')]
        [System.String]$ArtifactName

    )

    [System.String]$TempRootFolder = ''
    [System.IO.Compression.ZipArchive]$ZipArchive = $null
    try {
        if ((Test-String -IsEmpty $ArchiveZipPath) -or (-not (Test-Path -LiteralPath $ArchiveZipPath -PathType Leaf))) {
            Write-Line "The selected archive zip is invalid or missing. ($ArchiveZipPath)" -Type Warning
            return
        }

        Add-Type -AssemblyName System.IO.Compression
        Add-Type -AssemblyName System.IO.Compression.FileSystem

        $ZipArchive = [System.IO.Compression.ZipFile]::OpenRead($ArchiveZipPath)
        [System.IO.Compression.ZipArchiveEntry[]]$MatchingEntries = @(
            $ZipArchive.Entries | Where-Object {
                [System.String]$EntryName = [System.String]$_.Name
                (Test-String -IsPopulated $EntryName) -and (@($FileNamePatterns | Where-Object { $EntryName -like $_ }).Count -gt 0)
            } | Sort-Object -Property FullName -Unique
        )
        if ($MatchingEntries.Count -eq 0) {
            Write-Line "No $ArtifactName file was found in the selected archive zip. ($ArchiveZipPath)" -Type Warning
            return
        }

        [System.IO.Compression.ZipArchiveEntry[]]$PreferredFolderEntries = @()
        if (Test-String -IsPopulated $PreferredFolderNamePart) {
            [System.String]$EscapedFolderNamePart = [System.Text.RegularExpressions.Regex]::Escape($PreferredFolderNamePart)
            $PreferredFolderEntries = @($MatchingEntries | Where-Object { ($_.FullName -replace '\\','/') -match "(^|/)[^/]*$EscapedFolderNamePart[^/]*/[^/]+$" })
        }

        [System.IO.Compression.ZipArchiveEntry]$SelectedEntry = if ($PreferredFolderEntries.Count -eq 1) {
            $PreferredFolderEntries[0]
        }
        elseif ($PreferredFolderEntries.Count -gt 1) {
            throw "Multiple $ArtifactName files were found in matching folders inside the selected archive zip. ($ArchiveZipPath)"
        }
        elseif ($MatchingEntries.Count -eq 1) {
            $MatchingEntries[0]
        }
        else {
            throw "Multiple $ArtifactName files were found inside the selected archive zip. ($ArchiveZipPath)"
        }

        $TempRootFolder = Join-Path -Path $ENV:TEMP -ChildPath ([System.IO.Path]::GetRandomFileName())
        New-Item -Path $TempRootFolder -ItemType Directory -Force | Out-Null
        [System.String]$TempFilePath = Join-Path -Path $TempRootFolder -ChildPath $SelectedEntry.Name
        [System.IO.Compression.ZipFileExtensions]::ExtractToFile($SelectedEntry, $TempFilePath)

        return [PSCustomObject]@{
            FilePath       = [System.String]$TempFilePath
            IsTemporary    = $true
            TempRootFolder = [System.String]$TempRootFolder
            ArchiveEntry   = [System.String]$SelectedEntry.FullName
        }
    }
    catch {
        if ((Test-String -IsPopulated $TempRootFolder) -and (Test-Path -LiteralPath $TempRootFolder -PathType Container)) {
            Remove-Item -LiteralPath $TempRootFolder -Recurse -Force -ErrorAction SilentlyContinue
        }
        Write-ErrorReport -ErrorRecord $_
    }
    finally {
        if ($null -ne $ZipArchive) {
            $ZipArchive.Dispose()
        }
    }
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Opens the Word documentation for a selected DSL folder or archive zip file.
.DESCRIPTION
    Resolves a unique Word document from the selected application folder or extracts a unique Word
    document from the selected archive zip, preferring files under a Documentation folder.
.EXAMPLE
    Open-DSLSelectedApplicationDocumentation -Path 'C:\Temp\Vendor_App_1.0'
.INPUTS
    [System.String]
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.5.3
    Author          : Imraan Iotana
    Creation Date   : August 2026
    Last Update     : August 2026
#>
####################################################################################################
function Open-DSLSelectedApplicationDocumentation {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The selected DSL folder or archive zip path.')]
        [System.String]$Path
    )

    try {
        if (Test-Path -LiteralPath $Path -PathType Container) {
            [System.String]$DocumentPath = Resolve-DSLApplicationDocumentationFile -ApplicationFolderPath $Path
            if (Test-String -IsEmpty $DocumentPath) { return }

            Open-DSLDocumentationFile -Path $DocumentPath
            return
        }

        if ((Test-Path -LiteralPath $Path -PathType Leaf) -and ([System.IO.Path]::GetExtension($Path) -ieq '.zip')) {
            [PSCustomObject]$ArchiveFile = Resolve-DSLArchivePackageFile -ArchiveZipPath $Path -FileNamePatterns @('*.docx','*.docm','*.doc') -PreferredFolderNamePart 'Documentation' -ArtifactName 'Word document'
            if ($null -eq $ArchiveFile) { return }

            Write-Line "Extracted archive documentation for opening: $($ArchiveFile.FilePath)"
            Open-DSLDocumentationFile -Path $ArchiveFile.FilePath
            return
        }

        Write-Line "The selected path is not a DSL folder or archive zip file. ($Path)" -Type Warning
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
    Resolves the Word documentation file from an application folder.
.DESCRIPTION
    Searches the application folder for Word documents, preferring files under a Documentation
    folder and then files whose name includes the application folder name.
.EXAMPLE
    Resolve-DSLApplicationDocumentationFile -ApplicationFolderPath 'C:\Temp\Vendor_App_1.0'
.INPUTS
    [System.String]
.OUTPUTS
    [System.String]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.9.0
    Author          : Imraan Iotana
    Creation Date   : August 2026
    Last Update     : October 2026
#>
####################################################################################################
function Resolve-DSLApplicationDocumentationFile {
    [CmdletBinding()]
    [OutputType([System.String])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The root folder of the application package.')]
        [System.String]$ApplicationFolderPath
    )

    try {
        if (-not (Test-Path -LiteralPath $ApplicationFolderPath -PathType Container)) {
            Write-Line "The selected DSL folder is invalid or missing. ($ApplicationFolderPath)" -Type Warning
            return
        }

        [System.IO.FileInfo[]]$WordDocuments = @(
            '*.docx','*.docm','*.doc' | ForEach-Object {
                Get-ChildItem -LiteralPath $ApplicationFolderPath -File -Filter $_ -Recurse -ErrorAction SilentlyContinue
            } | Sort-Object -Property FullName -Unique
        )
        if ($WordDocuments.Count -eq 0) {
            Write-Line "No Word documentation file was found in the selected DSL folder. ($ApplicationFolderPath)" -Type Warning
            return
        }

        [System.IO.FileInfo[]]$DocumentationFolderDocuments = @($WordDocuments | Where-Object { ($_.FullName -replace '\\','/') -match '(^|/)[^/]*Documentation[^/]*/[^/]+$' })
        [System.IO.FileInfo[]]$CandidateDocuments = if ($DocumentationFolderDocuments.Count -gt 0) { $DocumentationFolderDocuments } else { $WordDocuments }

        # Step 1: prefer the document that starts with the dossier prefix and contains the package ApplicationID.
        [System.String]$ApplicationID = Resolve-DSLApplicationIDFromPackage -ApplicationFolderPath $ApplicationFolderPath
        if (Test-String -IsPopulated $ApplicationID) {
            [System.String]$EscapedApplicationID = [System.Text.RegularExpressions.Regex]::Escape($ApplicationID)
            [System.IO.FileInfo[]]$ApplicationDossierDocuments = @(
                $CandidateDocuments | Where-Object {
                    ($_.BaseName -match '(?i)\bDossier\b') -and
                    ($_.BaseName -match "(?<![A-Za-z0-9])$EscapedApplicationID(?![A-Za-z0-9])")
                }
            )
            if ($ApplicationDossierDocuments.Count -eq 1) {
                return [System.String]$ApplicationDossierDocuments[0].FullName
            }
        }

        Write-Line "Dossier document is not found for ApplicationID '$ApplicationID'." -Type Warning
        return
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
    Resolves the ApplicationID for a selected application package.
.DESCRIPTION
    Prefers the ApplicationID stored in the package metadata JSON file. When metadata is missing or
    ambiguous, the canonical application log context is used as the fallback source.
.EXAMPLE
    Resolve-DSLApplicationIDFromPackage -ApplicationFolderPath 'C:\Temp\Vendor_App_1.0'
.INPUTS
    [System.String]
.OUTPUTS
    [System.String]
#>
####################################################################################################
function Resolve-DSLApplicationIDFromPackage {
    [CmdletBinding()]
    [OutputType([System.String])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The root folder of the application package.')]
        [ValidateNotNullOrEmpty()]
        [System.String]$ApplicationFolderPath
    )

    try {
        [System.IO.FileInfo[]]$MetadataFiles = @(
            Get-ChildItem -LiteralPath $ApplicationFolderPath -File -Filter 'Metadata_*.json' -Recurse -ErrorAction SilentlyContinue |
                Sort-Object -Property LastWriteTime -Descending
        )

        foreach ($MetadataFile in $MetadataFiles) {
            try {
                [PSCustomObject]$Metadata = Get-Content -LiteralPath $MetadataFile.FullName -Raw | ConvertFrom-Json
                if (($null -ne $Metadata) -and (Test-String -IsPopulated ([System.String]$Metadata.ApplicationID))) {
                    return [System.String]$Metadata.ApplicationID
                }
            }
            catch {
                Write-Line "The metadata file could not be read and was skipped. ($($MetadataFile.FullName))" -Type Warning
            }
        }

        [PSCustomObject]$ApplicationLogContext = Get-ApplicationLogContext -ApplicationFolderPath $ApplicationFolderPath
        if (($null -ne $ApplicationLogContext) -and (Test-String -IsPopulated ([System.String]$ApplicationLogContext.ApplicationID))) {
            return [System.String]$ApplicationLogContext.ApplicationID
        }

        return $null
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
    Opens a resolved Word documentation file.
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.5.3
    Author          : Imraan Iotana
    Creation Date   : August 2026
    Last Update     : August 2026
#>
####################################################################################################
function Open-DSLDocumentationFile {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The Word documentation file path to open.')]
        [System.String]$Path
    )

    try {
        if ((Test-String -IsEmpty $Path) -or (-not (Test-Path -LiteralPath $Path -PathType Leaf))) {
            Write-Line "The documentation file could not be found. ($Path)" -Type Warning
            return
        }

        if ([System.IO.Path]::GetExtension($Path) -notin @('.docx','.docm','.doc')) {
            Write-Line "The selected documentation file is not a supported Word document. ($Path)" -Type Warning
            return
        }

        Write-Line "Opening documentation: $Path"
        Start-Process -FilePath $Path -ErrorAction Stop | Out-Null
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}

### END OF FUNCTION
####################################################################################################
