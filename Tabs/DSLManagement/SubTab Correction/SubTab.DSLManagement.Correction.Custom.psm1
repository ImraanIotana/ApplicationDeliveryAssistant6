####################################################################################################
<#
.SYNOPSIS
    Changes the custom vendor, name and version of an application folder, and with that its Application ID.
.DESCRIPTION
    The Application ID is built from the custom vendor, name and version. This function compares the supplied values with the metadata file.
    When they changed, it builds the new Application ID and, after confirmation:
    renames the application folder (with the prefix, postfix and separator that are stored in the metadata), makes a backup of the metadata file and the Word documents,
    updates the metadata file and renames it, updates the matching ADA content controls in the Word documents and renames the documents that have the old
    Application ID in their file name, renames the log file, and adds an entry to the application log. The old log entries stay as they are.
    When the metadata cannot be updated, the folder rename is reverted. A problem with a later step is reported, but does not undo the earlier steps.
    Items that cannot be changed from here (for example the SCCM application, archived ZIP files, AppLocker files and the UDF folder) are reported afterwards.
.EXAMPLE
    Update-DSLApplicationCustomProperties -ApplicationFolderName 'Vendor_App_1.0' -CustomVendorName 'Vendor' -CustomApplicationName 'App' -CustomApplicationVersion '1.1'
.INPUTS
    [System.String]
.OUTPUTS
    [System.String] The name of the application folder after the change; nothing when no change was made.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.11.0
    Author          : Imraan Iotana
    Creation Date   : October 2026
    Last Update     : October 2026
#>
####################################################################################################
function Update-DSLApplicationCustomProperties {
    [CmdletBinding()]
    [OutputType([System.String])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The name of the application folder in the Software Library (DSL).')]
        [System.String]$ApplicationFolderName,

        [Parameter(Mandatory=$true,HelpMessage='The custom vendor name.')]
        [AllowEmptyString()][AllowNull()]
        [System.String]$CustomVendorName,

        [Parameter(Mandatory=$true,HelpMessage='The custom application name.')]
        [AllowEmptyString()][AllowNull()]
        [System.String]$CustomApplicationName,

        [Parameter(Mandatory=$true,HelpMessage='The custom application version.')]
        [AllowEmptyString()][AllowNull()]
        [System.String]$CustomApplicationVersion
    )

    try {
        # PREPARATION - NEW VALUES
        [System.Collections.Specialized.OrderedDictionary]$NewValues = [ordered]@{
            CustomVendorName         = ([System.String]$CustomVendorName).Trim()
            CustomApplicationName    = ([System.String]$CustomApplicationName).Trim()
            CustomApplicationVersion = ([System.String]$CustomApplicationVersion).Trim()
        }
        [System.Collections.Hashtable]$Labels = @{ CustomVendorName = 'Custom Vendor'; CustomApplicationName = 'Custom Name'; CustomApplicationVersion = 'Custom Version' }

        # VALIDATION - NEW VALUES
        foreach ($PropertyName in $NewValues.Keys) {
            if (Test-String -IsEmpty $NewValues[$PropertyName]) {
                Write-Line "The $($Labels[$PropertyName]) cannot be empty. No action has been taken." -Type Warning
                return
            }
            if ($NewValues[$PropertyName] -match '[\r\n\v]') {
                Write-Line "The $($Labels[$PropertyName]) cannot contain a line break. No action has been taken." -Type Warning
                return
            }
        }

        # PREPARATION - CURRENT FOLDER AND METADATA
        [System.String]$SoftwareLibraryFolder = Get-Folder -SoftwareLibrary
        if ((Test-String -IsEmpty $SoftwareLibraryFolder) -or -not (Test-Path -LiteralPath $SoftwareLibraryFolder -PathType Container)) {
            Write-Line "The Software Library folder path is empty or invalid. No action has been taken. ($SoftwareLibraryFolder)" -Type Warning
            return
        }
        [System.String]$CurrentFolderPath = Join-Path -Path $SoftwareLibraryFolder -ChildPath $ApplicationFolderName
        if (-not (Test-Path -LiteralPath $CurrentFolderPath -PathType Container)) {
            Write-Line "The application folder does not exist. No action has been taken. ($CurrentFolderPath)" -Type Warning
            return
        }
        [PSCustomObject]$MetaDataResult = Get-DSLApplicationMetaData -ApplicationFolderPath $CurrentFolderPath
        if ($null -eq $MetaDataResult) {
            Write-Line 'The properties cannot be changed without a readable metadata file. No action has been taken.' -Type Warning
            return
        }
        foreach ($RequiredProperty in @('ApplicationID','ApplicationFolderName','ApplicationFolderPrefix','ApplicationFolderPostfix','ApplicationFolderSeparator') + @($NewValues.Keys)) {
            if ($null -eq $MetaDataResult.Data.PSObject.Properties[$RequiredProperty]) {
                Write-Line "The metadata file does not contain the property ($RequiredProperty). No action has been taken." -Type Warning
                return
            }
        }
        [System.String]$OldApplicationID = [System.String]$MetaDataResult.Data.ApplicationID
        if (Test-String -IsEmpty $OldApplicationID) {
            Write-Line 'The metadata file contains no Application ID. No action has been taken.' -Type Warning
            return
        }

        # The changes are the values that differ from the metadata file itself, not from what is on screen
        [System.Collections.Specialized.OrderedDictionary]$Changes = [ordered]@{}
        [System.Collections.Generic.List[System.String]]$ChangeLines = New-Object 'System.Collections.Generic.List[System.String]'
        foreach ($PropertyName in $NewValues.Keys) {
            [System.String]$OldValue = [System.String]$MetaDataResult.Data.PSObject.Properties[$PropertyName].Value
            if (-not [System.String]::Equals($OldValue, $NewValues[$PropertyName], [System.StringComparison]::Ordinal)) {
                $Changes[$PropertyName] = $NewValues[$PropertyName]
                [void]$ChangeLines.Add("$($Labels[$PropertyName]): $OldValue  >  $($NewValues[$PropertyName])")
            }
        }
        if ($Changes.Count -eq 0) {
            Write-Line 'The custom properties are the same as in the metadata file. No action has been taken.'
            return
        }

        # PREPARATION - NEW APPLICATION ID AND NAMES
        [System.String]$NewApplicationID = New-ApplicationIDValue -Vendor $NewValues.CustomVendorName -ApplicationName $NewValues.CustomApplicationName -ApplicationVersion $NewValues.CustomApplicationVersion
        if (Test-String -IsEmpty $NewApplicationID) {
            Write-Line 'The new Application ID cannot be generated from these values. No action has been taken.' -Type Warning
            return
        }
        [System.Boolean]$IDChanged = -not [System.String]::Equals($OldApplicationID, $NewApplicationID, [System.StringComparison]::Ordinal)
        [System.String]$NewFolderName = $ApplicationFolderName
        [System.String]$SafeNewApplicationID = $NewApplicationID -replace '[\\/:*?"<>|]', '_'
        [System.String]$NewMetaDataFileName = [System.IO.Path]::GetFileName($MetaDataResult.FilePath)
        [System.String]$NewLogFileName = ''
        [System.Collections.Hashtable]$DocumentRenames = @{}
        [System.String[]]$DocumentPaths = @(Get-DSLApplicationDocumentationDocuments -ApplicationFolderPath $CurrentFolderPath)
        [PSCustomObject]$CurrentLogContext = Get-ApplicationLogContext -ApplicationFolderPath $CurrentFolderPath
        [System.Collections.Generic.List[System.String]]$RenameLines = New-Object 'System.Collections.Generic.List[System.String]'
        if ($IDChanged) {
            $NewFolderName = Get-DSLApplicationFolderNameFromParts -ApplicationID $NewApplicationID `
                -ApplicationFolderPrefix ([System.String]$MetaDataResult.Data.ApplicationFolderPrefix) `
                -ApplicationFolderPostfix ([System.String]$MetaDataResult.Data.ApplicationFolderPostfix) `
                -ApplicationFolderSeparator ([System.String]$MetaDataResult.Data.ApplicationFolderSeparator)
            [System.String]$FolderProblem = Get-DSLApplicationFolderNameProblem -NewFolderName $NewFolderName -CurrentFolderName $ApplicationFolderName -SoftwareLibraryFolder $SoftwareLibraryFolder
            if (Test-String -IsPopulated $FolderProblem) {
                Write-Line "$FolderProblem No action has been taken." -Type Warning
                return
            }
            if (-not [System.String]::Equals($NewFolderName, $ApplicationFolderName, [System.StringComparison]::Ordinal)) {
                [void]$RenameLines.Add("Folder: $ApplicationFolderName  >  $NewFolderName")
            }

            # Metadata file
            $NewMetaDataFileName = "Metadata_$SafeNewApplicationID.json"
            if (-not [System.String]::Equals($NewMetaDataFileName, [System.IO.Path]::GetFileName($MetaDataResult.FilePath), [System.StringComparison]::Ordinal)) {
                [System.String]$NewMetaDataFilePathCheck = Join-Path -Path ([System.IO.Path]::GetDirectoryName($MetaDataResult.FilePath)) -ChildPath $NewMetaDataFileName
                if (Test-Path -LiteralPath $NewMetaDataFilePathCheck) {
                    Write-Line "A metadata file with the new name already exists. No action has been taken. ($NewMetaDataFileName)" -Type Warning
                    return
                }
                [void]$RenameLines.Add("Metadata file: $([System.IO.Path]::GetFileName($MetaDataResult.FilePath))  >  $NewMetaDataFileName")
            }
            else { $NewMetaDataFileName = '' }

            # Word documents that have the old Application ID in their file name
            [System.String]$OldIDPattern = [System.Text.RegularExpressions.Regex]::Escape($OldApplicationID)
            foreach ($DocumentPath in $DocumentPaths) {
                [System.String]$DocumentFileName = [System.IO.Path]::GetFileName($DocumentPath)
                if ($DocumentFileName -notmatch "(?i)$OldIDPattern") { continue }
                [System.String]$NewDocumentFileName = [System.Text.RegularExpressions.Regex]::Replace($DocumentFileName, $OldIDPattern, $NewApplicationID.Replace('$','$$'), [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
                if ([System.String]::Equals($NewDocumentFileName, $DocumentFileName, [System.StringComparison]::Ordinal)) { continue }
                if (Test-Path -LiteralPath (Join-Path -Path ([System.IO.Path]::GetDirectoryName($DocumentPath)) -ChildPath $NewDocumentFileName)) {
                    Write-Line "A document with the new name already exists. No action has been taken. ($NewDocumentFileName)" -Type Warning
                    return
                }
                $DocumentRenames[$DocumentPath] = $NewDocumentFileName
                [void]$RenameLines.Add("Document: $DocumentFileName  >  $NewDocumentFileName")
            }

            # Log file
            if ($null -ne $CurrentLogContext) {
                [System.String]$ProposedLogFileName = "${SafeNewApplicationID}_Log.csv"
                if (-not [System.String]::Equals($ProposedLogFileName, [System.IO.Path]::GetFileName($CurrentLogContext.LogFilePath), [System.StringComparison]::Ordinal)) {
                    if (Test-Path -LiteralPath (Join-Path -Path ([System.IO.Path]::GetDirectoryName($CurrentLogContext.LogFilePath)) -ChildPath $ProposedLogFileName)) {
                        Write-Line "A log file with the new name already exists. No action has been taken. ($ProposedLogFileName)" -Type Warning
                        return
                    }
                    $NewLogFileName = $ProposedLogFileName
                    [void]$RenameLines.Add("Log file: $([System.IO.Path]::GetFileName($CurrentLogContext.LogFilePath))  >  $NewLogFileName")
                }
            }
        }

        # CONFIRMATION
        [System.String]$IDLine = if ($IDChanged) { "Application ID: $OldApplicationID  >  $NewApplicationID" } else { "The Application ID stays $OldApplicationID." }
        [System.String]$ConfirmationBody = "This will CHANGE the custom properties of the application folder:`n$ApplicationFolderName`n`n$($ChangeLines -join "`n")`n`n$IDLine"
        if ($RenameLines.Count -gt 0) { $ConfirmationBody += "`n`nThese will be RENAMED:`n$($RenameLines -join "`n")" }
        $ConfirmationBody += "`n`nThe metadata file and the Word documents in the documentation folder(s) will be updated, after a backup of each (.bak, in the archive Other folder). Documents without content controls (older documents) keep their old text. An entry will be added to the application log; the old log entries stay as they are."
        if ($IDChanged) { $ConfirmationBody += "`n`nThe SCCM application, archived ZIP files, AppLocker files and the UDF folder are NOT changed. They are reported afterwards." }
        $ConfirmationBody += "`n`nDo you want to continue?"
        if (-not (Get-UserConfirmation -Title 'Change Custom Properties' -Body $ConfirmationBody)) {
            Write-Line 'Changing the custom properties was cancelled by the user. No action has been taken.' -Type Warning
            return
        }

        # EXECUTION - RENAME THE FOLDER
        [System.String]$NewFolderPath = Join-Path -Path $SoftwareLibraryFolder -ChildPath $NewFolderName
        [System.Boolean]$FolderRenamed = -not [System.String]::Equals($NewFolderName, $ApplicationFolderName, [System.StringComparison]::Ordinal)
        if ($FolderRenamed) {
            try {
                Rename-Item -LiteralPath $CurrentFolderPath -NewName $NewFolderName -ErrorAction Stop
            }
            catch {
                Write-Line "The application folder could not be renamed. Is it open in another program? No action has been taken. ($($_.Exception.Message))" -Type Warning
                return
            }
        }
        # From here on, every path in the old folder is looked up in the new folder
        [System.Int32]$OldFolderPathLength = $CurrentFolderPath.TrimEnd('\').Length
        $Remap = { param([System.String]$Path) Join-Path -Path $NewFolderPath -ChildPath $Path.Substring($OldFolderPathLength).TrimStart('\') }.GetNewClosure()

        # EXECUTION - BACKUP AND UPDATE THE METADATA, OR REVERT THE RENAME
        [System.String]$Stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
        [System.String]$MetaDataFilePath = & $Remap $MetaDataResult.FilePath
        [System.String]$BackupFolderPath = Get-DSLApplicationBackupFolderPath -ApplicationFolderPath $NewFolderPath -MetaData $MetaDataResult.Data
        [System.Collections.Specialized.OrderedDictionary]$MetaDataValues = [ordered]@{}
        foreach ($PropertyName in $Changes.Keys) { $MetaDataValues[$PropertyName] = $Changes[$PropertyName] }
        if ($IDChanged) {
            $MetaDataValues['ApplicationID'] = $NewApplicationID
            $MetaDataValues['ApplicationFolderName'] = $NewFolderName
        }
        try {
            if (-not (Test-Path -LiteralPath $BackupFolderPath -PathType Container)) {
                New-Item -Path $BackupFolderPath -ItemType Directory -Force -ErrorAction Stop | Out-Null
            }
            [void](Copy-DSLApplicationFileBackup -FilePath $MetaDataFilePath -BackupFolderPath $BackupFolderPath -Stamp $Stamp)
            # Nothing is written when a property is missing, so a failure leaves the metadata file as it was
            Set-DSLApplicationMetaDataValue -MetaDataFilePath $MetaDataFilePath -Value $MetaDataValues
        }
        catch {
            [System.String]$FailureMessage = $_.Exception.Message
            if ($FolderRenamed) {
                try {
                    Rename-Item -LiteralPath $NewFolderPath -NewName $ApplicationFolderName -ErrorAction Stop
                    Write-Line "The metadata file could not be updated, so the rename has been reverted. ($FailureMessage)" -Type Warning
                }
                catch {
                    Write-Line "The metadata file could not be updated AND the rename could not be reverted. The folder is now named ($NewFolderName). ($FailureMessage)" -Type Error
                }
            }
            else {
                Write-Line "The metadata file could not be updated. No other action has been taken. ($FailureMessage)" -Type Warning
            }
            return
        }
        Write-Line "The metadata file has been updated. ($($MetaDataValues.Count) value(s) changed)" -Type Success

        # EXECUTION - RENAME THE METADATA FILE
        if (Test-String -IsPopulated $NewMetaDataFileName) {
            try {
                Rename-Item -LiteralPath $MetaDataFilePath -NewName $NewMetaDataFileName -ErrorAction Stop
            }
            catch {
                Write-Line "The metadata file could not be renamed. ($($_.Exception.Message))" -Type Warning
            }
        }

        # EXECUTION - UPDATE AND RENAME THE WORD DOCUMENTS
        # A problem with a document is reported, but does not undo the metadata, which is the source of the values.
        [System.Int32]$UpdatedDocumentCount = 0
        [System.Int32]$UnchangedDocumentCount = 0
        if ($DocumentPaths.Count -eq 0) {
            Write-Line 'No Word documents were found in the documentation folder(s).' -Type Warning
        }
        else {
            [System.Collections.Hashtable]$ControlValues = @{}
            foreach ($PropertyName in $Changes.Keys) { $ControlValues["ADA_$PropertyName"] = $Changes[$PropertyName] }
            if ($IDChanged) { $ControlValues['ADA_ApplicationID'] = $NewApplicationID }
            [System.Collections.Hashtable]$BackupPaths = @{}
            foreach ($OldDocumentPath in $DocumentPaths) {
                [System.String]$DocumentPath = & $Remap $OldDocumentPath
                try {
                    $BackupPaths[$DocumentPath] = Copy-DSLApplicationFileBackup -FilePath $DocumentPath -BackupFolderPath $BackupFolderPath -Stamp $Stamp
                }
                catch {
                    Write-Line "The document was not backed up, so its text is not changed. ($DocumentPath) ($($_.Exception.Message))" -Type Warning
                }
            }
            if ($BackupPaths.Count -gt 0) {
                Write-Line 'Updating the Word documents, one moment please...' -Type Busy
                foreach ($DocumentResult in @(Update-WordDocumentFileControlValue -DocumentPath @($BackupPaths.Keys | Sort-Object) -Values $ControlValues)) {
                    [System.String]$DocumentName = [System.IO.Path]::GetFileName($DocumentResult.Path)
                    if ($DocumentResult.Status -eq 'Updated') {
                        $UpdatedDocumentCount++
                        Write-Line "Updated the document. ($DocumentName) ($($DocumentResult.Updated) value(s))" -Type Success
                    }
                    else {
                        $UnchangedDocumentCount++
                        Write-Line "The text of the document was not changed. ($DocumentName) $($DocumentResult.Message)" -Type Warning
                        # The text is unchanged, so the backup is not needed
                        Remove-Item -LiteralPath $BackupPaths[$DocumentResult.Path] -Force -ErrorAction SilentlyContinue
                    }
                }
            }
            # Rename the documents that have the old Application ID in their name, also when their text could not be changed
            foreach ($OldDocumentPath in $DocumentRenames.Keys) {
                [System.String]$DocumentPath = & $Remap $OldDocumentPath
                try {
                    Rename-Item -LiteralPath $DocumentPath -NewName $DocumentRenames[$OldDocumentPath] -ErrorAction Stop
                    Write-Line "Renamed the document. ($([System.IO.Path]::GetFileName($DocumentPath)) > $($DocumentRenames[$OldDocumentPath]))" -Type Success
                }
                catch {
                    Write-Line "The document could not be renamed. ($DocumentPath) ($($_.Exception.Message))" -Type Warning
                }
            }
        }

        # EXECUTION - RENAME THE LOG FILE AND LOG THE CHANGE
        # A missing or unwritable log must not undo the completed change
        try {
            [PSCustomObject]$LogContext = Get-ApplicationLogContext -ApplicationFolderPath $NewFolderPath
            if ($null -ne $LogContext) {
                [System.String]$LogFilePath = $LogContext.LogFilePath
                if (Test-String -IsPopulated $NewLogFileName) {
                    try {
                        Rename-Item -LiteralPath $LogFilePath -NewName $NewLogFileName -ErrorAction Stop
                        $LogFilePath = Join-Path -Path ([System.IO.Path]::GetDirectoryName($LogFilePath)) -ChildPath $NewLogFileName
                    }
                    catch {
                        Write-Line "The log file could not be renamed. ($($_.Exception.Message))" -Type Warning
                    }
                }
                Write-ApplicationLogEntry -LogFilePath $LogFilePath -ApplicationID $NewApplicationID -Status Success -Action ApplicationCustomPropertiesChanged -Details "Changed custom properties. $($ChangeLines -join ' | ') Application ID: ($OldApplicationID) to ($NewApplicationID). Folder: ($ApplicationFolderName) to ($NewFolderName). Documents updated: $UpdatedDocumentCount. Documents not changed: $UnchangedDocumentCount."
            }
            else {
                Write-Line 'No application log was found, so the change was not logged.' -Type Warning
            }
        }
        catch {
            Write-Line "The change could not be logged. ($($_.Exception.Message))" -Type Warning
        }

        # POST-EXECUTION - REPORT WHAT STILL HAS THE OLD APPLICATION ID
        if ($IDChanged) {
            [System.String[]]$LeftOverNames = @(
                Get-ChildItem -LiteralPath $NewFolderPath -Recurse -Force -ErrorAction SilentlyContinue |
                Where-Object { ($_.Extension -ine '.bak') -and ($_.Name.IndexOf($OldApplicationID, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) } |
                ForEach-Object { $_.FullName.Substring($NewFolderPath.TrimEnd('\').Length).TrimStart('\') }
            )
            if ($LeftOverNames.Count -gt 0) {
                Write-Line "These items in the folder still have the old Application ID in their name. ($($LeftOverNames.Count))" -Type Warning
                foreach ($LeftOverName in ($LeftOverNames | Select-Object -First 15)) { Write-Line "  $LeftOverName" -Type Warning }
            }
            Write-Line "Check the SCCM application and archived ZIP files of the old Application ID. ($OldApplicationID)" -Type Warning
        }
        Write-Line "The custom properties have been changed. ($NewFolderName)" -Type Success
        return $NewFolderName
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
    Applies the custom properties that are entered in the DSL Correction sub-tab.
.DESCRIPTION
    This function reads the custom vendor, name and version from the TextBoxes, applies them with Update-DSLApplicationCustomProperties,
    and when that succeeded, reloads the folder list, selects the (renamed) folder and loads its details.
    It only runs when the details on screen were loaded for the selected folder (see LoadState), so the values of another folder can never be applied.
.EXAMPLE
    Invoke-DSLApplicationCustomApply -ApplicationFolderComboBox $MyComboBox -DetailTextBoxes $DetailTextBoxes -LoadState $LoadState
.INPUTS
    [System.Windows.Forms.ComboBox]
    [System.Collections.Hashtable]
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.11.0
    Author          : Imraan Iotana
    Creation Date   : October 2026
    Last Update     : October 2026
#>
####################################################################################################
function Invoke-DSLApplicationCustomApply {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The ComboBox with the application folders of the Software Library (DSL).')]
        [System.Windows.Forms.ComboBox]$ApplicationFolderComboBox,

        [Parameter(Mandatory=$true,HelpMessage='The TextBoxes keyed by metadata property name.')]
        [System.Collections.Hashtable]$DetailTextBoxes,

        [Parameter(Mandatory=$true,HelpMessage='The state that records which application folder is loaded.')]
        [System.Collections.Hashtable]$LoadState
    )

    try {
        [System.String]$SelectedFolderName = $ApplicationFolderComboBox.Text
        if (Test-String -IsEmpty $SelectedFolderName) {
            Write-Line 'No application folder is selected. Select a folder first. No action has been taken.' -Type Warning
            return
        }
        if (-not [System.String]::Equals([System.String]$LoadState.FolderName, $SelectedFolderName, [System.StringComparison]::Ordinal)) {
            Write-Line 'The selected application folder is not loaded. Click Load first. No action has been taken.' -Type Warning
            return
        }

        [System.String]$NewFolderName = Update-DSLApplicationCustomProperties `
            -ApplicationFolderName $SelectedFolderName `
            -CustomVendorName $DetailTextBoxes['CustomVendorName'].Text `
            -CustomApplicationName $DetailTextBoxes['CustomApplicationName'].Text `
            -CustomApplicationVersion $DetailTextBoxes['CustomApplicationVersion'].Text
        if (Test-String -IsEmpty $NewFolderName) { return }

        # Reload the list, select the (renamed) folder and load its details
        Update-ComboBox -ComboBox $ApplicationFolderComboBox -ContentStringArray @(Get-DSLDirectSubFolderNames) -Silent
        $ApplicationFolderComboBox.SelectedItem = $NewFolderName
        Invoke-DSLApplicationMetaDataLoad -ApplicationFolderComboBox $ApplicationFolderComboBox -DetailTextBoxes $DetailTextBoxes -LoadState $LoadState
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}

### END OF FUNCTION
####################################################################################################
