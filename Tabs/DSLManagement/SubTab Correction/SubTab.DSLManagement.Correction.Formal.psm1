####################################################################################################
<#
.SYNOPSIS
    Gets the Word documents in the documentation folders of an application folder.
.DESCRIPTION
    This function returns the .docx files that are in a folder with 'Documentation' in its name, anywhere in the application folder.
    Temporary Word lock files (~$...) are ignored.
.EXAMPLE
    Get-DSLApplicationDocumentationDocuments -ApplicationFolderPath 'C:\DSL\Vendor_App_1.0'
.INPUTS
    [System.String]
.OUTPUTS
    [System.String[]] The full paths of the documents.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.11.0
    Author          : Imraan Iotana
    Creation Date   : October 2026
    Last Update     : October 2026
#>
####################################################################################################
function Get-DSLApplicationDocumentationDocuments {
    [CmdletBinding()]
    [OutputType([System.String[]])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The full path of the application folder in the Software Library (DSL).')]
        [System.String]$ApplicationFolderPath
    )

    # The extension is checked in the Where-Object, because the -Filter '*.docx' of Get-ChildItem can also match other extensions
    [System.String[]]@(
        Get-ChildItem -LiteralPath $ApplicationFolderPath -File -Recurse -ErrorAction SilentlyContinue |
        Where-Object { ($_.Extension -ieq '.docx') -and (-not $_.Name.StartsWith('~$')) -and ($_.Directory.Name -match 'Documentation') } |
        Sort-Object -Property FullName |
        ForEach-Object { $_.FullName }
    )
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Gets the folder where the backups of an application folder are stored.
.DESCRIPTION
    This function returns the Other folder of the archive of the application folder. The relative path is read from the template that is stored in the metadata (ApplicationFolderSubFolders.Other); the default is '9. Archive\Other'.
    The folder is not created by this function.
.EXAMPLE
    Get-DSLApplicationBackupFolderPath -ApplicationFolderPath 'C:\DSL\Vendor_App_1.0' -MetaData $MetaData
.INPUTS
    [System.String]
    [PSCustomObject]
.OUTPUTS
    [System.String]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.11.0
    Author          : Imraan Iotana
    Creation Date   : October 2026
    Last Update     : October 2026
#>
####################################################################################################
function Get-DSLApplicationBackupFolderPath {
    [CmdletBinding()]
    [OutputType([System.String])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The full path of the application folder.')]
        [System.String]$ApplicationFolderPath,

        [Parameter(Mandatory=$false,HelpMessage='The parsed metadata of the application folder.')]
        [AllowNull()]
        [PSCustomObject]$MetaData
    )

    [System.String]$RelativePath = '9. Archive\Other'
    if (($null -ne $MetaData) -and ($null -ne $MetaData.PSObject.Properties['SelectedTemplate']) -and ($null -ne $MetaData.SelectedTemplate) -and
        ($null -ne $MetaData.SelectedTemplate.PSObject.Properties['ApplicationFolderSubFolders']) -and ($null -ne $MetaData.SelectedTemplate.ApplicationFolderSubFolders) -and
        ($null -ne $MetaData.SelectedTemplate.ApplicationFolderSubFolders.PSObject.Properties['Other']) -and
        (Test-String -IsPopulated ([System.String]$MetaData.SelectedTemplate.ApplicationFolderSubFolders.Other))) {
        $RelativePath = [System.String]$MetaData.SelectedTemplate.ApplicationFolderSubFolders.Other
    }
    Join-Path -Path $ApplicationFolderPath -ChildPath $RelativePath
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Copies a file to a backup folder, with a date and time in the backup name.
.DESCRIPTION
    This function copies the file to the backup folder as '<file name>.<stamp>.bak'. When that name already exists (for example two documents with the same name), a number is added.
.EXAMPLE
    Copy-DSLApplicationFileBackup -FilePath 'C:\DSL\App\1. Documentation\Dossier.docx' -BackupFolderPath 'C:\DSL\App\9. Archive\Other' -Stamp '20261016-090000'
.INPUTS
    [System.String]
.OUTPUTS
    [System.String] The full path of the backup file. The function throws when the copy fails.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.11.0
    Author          : Imraan Iotana
    Creation Date   : October 2026
    Last Update     : October 2026
#>
####################################################################################################
function Copy-DSLApplicationFileBackup {
    [CmdletBinding()]
    [OutputType([System.String])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The full path of the file to back up.')]
        [System.String]$FilePath,

        [Parameter(Mandatory=$true,HelpMessage='The folder that receives the backup.')]
        [System.String]$BackupFolderPath,

        [Parameter(Mandatory=$true,HelpMessage='The date and time text that is part of the backup name.')]
        [System.String]$Stamp
    )

    [System.String]$FileName = [System.IO.Path]::GetFileName($FilePath)
    [System.String]$BackupPath = Join-Path -Path $BackupFolderPath -ChildPath "$FileName.$Stamp.bak"
    [System.Int32]$Number = 1
    while (Test-Path -LiteralPath $BackupPath) {
        $Number++
        $BackupPath = Join-Path -Path $BackupFolderPath -ChildPath "$FileName.$Stamp ($Number).bak"
    }
    Copy-Item -LiteralPath $FilePath -Destination $BackupPath -ErrorAction Stop
    $BackupPath
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Changes the formal vendor, name and version of an application folder in the Software Library (DSL).
.DESCRIPTION
    This function compares the supplied values with the formal properties in the metadata file. For the values that changed it:
    asks for confirmation, makes a backup of the metadata file and of each Word document in the Other folder of the archive (9. Archive\Other), updates the metadata file,
    updates the matching ADA content controls in the Word documents in the documentation folders, and adds an entry to the application log.
    Documents without ADA content controls (older documents) are not changed, and this is reported.
    The folder name and the Application ID are not changed.
.EXAMPLE
    Update-DSLApplicationFormalProperties -ApplicationFolderName 'Vendor_App_1.0' -FormalVendorName 'Vendor' -FormalApplicationName 'App' -FormalApplicationVersion '1.1'
.INPUTS
    [System.String]
.OUTPUTS
    [System.Boolean] True when the metadata was updated; otherwise False.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.11.0
    Author          : Imraan Iotana
    Creation Date   : October 2026
    Last Update     : October 2026
#>
####################################################################################################
function Update-DSLApplicationFormalProperties {
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The name of the application folder in the Software Library (DSL).')]
        [System.String]$ApplicationFolderName,

        [Parameter(Mandatory=$true,HelpMessage='The formal vendor name.')]
        [AllowEmptyString()][AllowNull()]
        [System.String]$FormalVendorName,

        [Parameter(Mandatory=$true,HelpMessage='The formal application name.')]
        [AllowEmptyString()][AllowNull()]
        [System.String]$FormalApplicationName,

        [Parameter(Mandatory=$true,HelpMessage='The formal application version.')]
        [AllowEmptyString()][AllowNull()]
        [System.String]$FormalApplicationVersion
    )

    try {
        # PREPARATION - NEW VALUES
        [System.Collections.Specialized.OrderedDictionary]$NewValues = [ordered]@{
            FormalVendorName         = ([System.String]$FormalVendorName).Trim()
            FormalApplicationName    = ([System.String]$FormalApplicationName).Trim()
            FormalApplicationVersion = ([System.String]$FormalApplicationVersion).Trim()
        }
        [System.Collections.Hashtable]$Labels = @{ FormalVendorName = 'Formal Vendor'; FormalApplicationName = 'Formal Name'; FormalApplicationVersion = 'Formal Version' }

        # VALIDATION - NEW VALUES
        foreach ($PropertyName in $NewValues.Keys) {
            if (Test-String -IsEmpty $NewValues[$PropertyName]) {
                Write-Line "The $($Labels[$PropertyName]) cannot be empty. No action has been taken." -Type Warning
                return $false
            }
            if ($NewValues[$PropertyName] -match '[\r\n\v]') {
                Write-Line "The $($Labels[$PropertyName]) cannot contain a line break. No action has been taken." -Type Warning
                return $false
            }
        }

        # PREPARATION - CURRENT FOLDER AND METADATA
        [System.String]$SoftwareLibraryFolder = Get-Folder -SoftwareLibrary
        [System.String]$ApplicationFolderPath = Join-Path -Path $SoftwareLibraryFolder -ChildPath $ApplicationFolderName
        if ((Test-String -IsEmpty $SoftwareLibraryFolder) -or -not (Test-Path -LiteralPath $ApplicationFolderPath -PathType Container)) {
            Write-Line "The application folder does not exist. No action has been taken. ($ApplicationFolderPath)" -Type Warning
            return $false
        }
        [PSCustomObject]$MetaDataResult = Get-DSLApplicationMetaData -ApplicationFolderPath $ApplicationFolderPath
        if ($null -eq $MetaDataResult) {
            Write-Line 'The properties cannot be changed without a readable metadata file. No action has been taken.' -Type Warning
            return $false
        }
        [System.String]$ApplicationID = [System.String]$MetaDataResult.Data.ApplicationID

        # The changes are the values that differ from the metadata file itself, not from what is on screen
        [System.Collections.Specialized.OrderedDictionary]$Changes = [ordered]@{}
        [System.Collections.Generic.List[System.String]]$ChangeLines = New-Object 'System.Collections.Generic.List[System.String]'
        foreach ($PropertyName in $NewValues.Keys) {
            [System.Management.Automation.PSPropertyInfo]$MetaDataProperty = $MetaDataResult.Data.PSObject.Properties[$PropertyName]
            if ($null -eq $MetaDataProperty) {
                Write-Line "The metadata file does not contain the property ($PropertyName). No action has been taken." -Type Warning
                return $false
            }
            [System.String]$OldValue = [System.String]$MetaDataProperty.Value
            if (-not [System.String]::Equals($OldValue, $NewValues[$PropertyName], [System.StringComparison]::Ordinal)) {
                $Changes[$PropertyName] = $NewValues[$PropertyName]
                [void]$ChangeLines.Add("$($Labels[$PropertyName]): $OldValue  >  $($NewValues[$PropertyName])")
            }
        }
        if ($Changes.Count -eq 0) {
            Write-Line 'The formal properties are the same as in the metadata file. No action has been taken.'
            return $false
        }
        [System.String[]]$DocumentPaths = @(Get-DSLApplicationDocumentationDocuments -ApplicationFolderPath $ApplicationFolderPath)

        # CONFIRMATION
        [System.String]$ConfirmationBody = "This will CHANGE the formal properties of the application folder:`n$ApplicationFolderName`n`n$($ChangeLines -join "`n")`n`nThe metadata file and $($DocumentPaths.Count) Word document(s) in the documentation folder(s) will be updated, after a backup of each (.bak, in the archive Other folder). An entry will be added to the application log.`nDocuments without content controls (older documents) are not changed.`nThe folder name and the Application ID ($ApplicationID) stay unchanged.`n`nDo you want to continue?"
        if (-not (Get-UserConfirmation -Title 'Change Formal Properties' -Body $ConfirmationBody)) {
            Write-Line 'Changing the formal properties was cancelled by the user. No action has been taken.' -Type Warning
            return $false
        }

        # EXECUTION - BACKUP AND UPDATE THE METADATA
        # The backups go to the Other folder of the template (default 9. Archive\Other), to keep the other folders clean
        [System.String]$Stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
        [System.String]$BackupFolderPath = Get-DSLApplicationBackupFolderPath -ApplicationFolderPath $ApplicationFolderPath -MetaData $MetaDataResult.Data
        try {
            if (-not (Test-Path -LiteralPath $BackupFolderPath -PathType Container)) {
                New-Item -Path $BackupFolderPath -ItemType Directory -Force -ErrorAction Stop | Out-Null
            }
            [void](Copy-DSLApplicationFileBackup -FilePath $MetaDataResult.FilePath -BackupFolderPath $BackupFolderPath -Stamp $Stamp)
            # Nothing is written when a property is missing, so a failure leaves the metadata file as it was
            Set-DSLApplicationMetaDataValue -MetaDataFilePath $MetaDataResult.FilePath -Value $Changes
        }
        catch {
            Write-Line "The metadata file could not be updated. No other action has been taken. ($($_.Exception.Message))" -Type Warning
            return $false
        }
        Write-Line "The metadata file has been updated. ($($Changes.Count) value(s) changed)" -Type Success

        # EXECUTION - UPDATE THE WORD DOCUMENTS
        # A problem with a document is reported, but does not undo the metadata, which is the source of the values.
        [System.Int32]$UpdatedDocumentCount = 0
        [System.Int32]$UnchangedDocumentCount = 0
        if ($DocumentPaths.Count -eq 0) {
            Write-Line 'No Word documents were found in the documentation folder(s).' -Type Warning
        }
        else {
            [System.Collections.Hashtable]$ControlValues = @{}
            foreach ($PropertyName in $Changes.Keys) { $ControlValues["ADA_$PropertyName"] = $Changes[$PropertyName] }
            [System.Collections.Hashtable]$BackupPaths = @{}
            foreach ($DocumentPath in $DocumentPaths) {
                try {
                    $BackupPaths[$DocumentPath] = Copy-DSLApplicationFileBackup -FilePath $DocumentPath -BackupFolderPath $BackupFolderPath -Stamp $Stamp
                }
                catch {
                    Write-Line "The document was not backed up, so it is not changed. ($DocumentPath) ($($_.Exception.Message))" -Type Warning
                }
            }
            if ($BackupPaths.Count -gt 0) {
                Write-Line 'Updating the Word documents, one moment please...' -Type Busy
                foreach ($DocumentResult in @(Update-WordDocumentFileControlValue -DocumentPath @($BackupPaths.Keys | Sort-Object) -Values $ControlValues)) {
                    [System.String]$DocumentName = [System.IO.Path]::GetFileName($DocumentResult.Path)
                    switch ($DocumentResult.Status) {
                        'Updated' {
                            $UpdatedDocumentCount++
                            Write-Line "Updated the document. ($DocumentName) ($($DocumentResult.Updated) value(s))" -Type Success
                        }
                        default {
                            $UnchangedDocumentCount++
                            Write-Line "The document was not changed. ($DocumentName) $($DocumentResult.Message)" -Type Warning
                            # The document is unchanged, so its backup is not needed
                            Remove-Item -LiteralPath $BackupPaths[$DocumentResult.Path] -Force -ErrorAction SilentlyContinue
                        }
                    }
                }
            }
        }

        # EXECUTION - LOG THE CHANGE
        # A missing or unwritable log must not undo the completed change
        try {
            [PSCustomObject]$LogContext = Get-ApplicationLogContext -ApplicationFolderPath $ApplicationFolderPath
            if ($null -ne $LogContext) {
                Write-ApplicationLogEntry -LogFilePath $LogContext.LogFilePath -ApplicationID $ApplicationID -Status Success -Action ApplicationFormalPropertiesChanged -Details "Changed formal properties. $($ChangeLines -join ' | ') Documents updated: $UpdatedDocumentCount. Documents not changed: $UnchangedDocumentCount."
            }
            else {
                Write-Line 'No application log was found, so the change was not logged.' -Type Warning
            }
        }
        catch {
            Write-Line "The change could not be logged. ($($_.Exception.Message))" -Type Warning
        }

        # POST-EXECUTION
        Write-Line "The formal properties have been changed. ($ApplicationFolderName)" -Type Success
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
    Applies the formal properties that are entered in the DSL Correction sub-tab.
.DESCRIPTION
    This function reads the formal vendor, name and version from the TextBoxes, applies them with Update-DSLApplicationFormalProperties,
    and when that succeeded, loads the details of the folder again.
    It only runs when the details on screen were loaded for the selected folder (see LoadState), so the values of another folder can never be applied.
.EXAMPLE
    Invoke-DSLApplicationFormalApply -ApplicationFolderComboBox $MyComboBox -DetailTextBoxes $DetailTextBoxes -LoadState $LoadState
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
function Invoke-DSLApplicationFormalApply {
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

        [System.Boolean]$Changed = Update-DSLApplicationFormalProperties `
            -ApplicationFolderName $SelectedFolderName `
            -FormalVendorName $DetailTextBoxes['FormalVendorName'].Text `
            -FormalApplicationName $DetailTextBoxes['FormalApplicationName'].Text `
            -FormalApplicationVersion $DetailTextBoxes['FormalApplicationVersion'].Text
        if (-not $Changed) { return }

        # Load the details again, so the screen shows what is now in the metadata file
        Invoke-DSLApplicationMetaDataLoad -ApplicationFolderComboBox $ApplicationFolderComboBox -DetailTextBoxes $DetailTextBoxes -LoadState $LoadState
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}

### END OF FUNCTION
####################################################################################################
