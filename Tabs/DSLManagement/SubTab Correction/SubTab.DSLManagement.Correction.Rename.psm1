####################################################################################################
<#
.SYNOPSIS
    Builds an application folder name from its parts.
.DESCRIPTION
    This function combines the prefix, the Application ID and the postfix into a folder name, using the same rules as the Application Intake:
    empty parts are skipped and the remaining parts are joined with the separator.
.EXAMPLE
    Get-DSLApplicationFolderNameFromParts -ApplicationID 'Vendor_App_1.0' -ApplicationFolderPrefix 'TST' -ApplicationFolderPostfix 'x64' -ApplicationFolderSeparator '_'
.INPUTS
    [System.String]
.OUTPUTS
    [System.String] The folder name; empty when the Application ID is empty.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.11.0
    Author          : Imraan Iotana
    Creation Date   : October 2026
    Last Update     : October 2026
#>
####################################################################################################
function Get-DSLApplicationFolderNameFromParts {
    [CmdletBinding()]
    [OutputType([System.String])]
    param (
        [Parameter(Mandatory=$false,HelpMessage='The Application ID.')]
        [AllowEmptyString()][AllowNull()]
        [System.String]$ApplicationID,

        [Parameter(Mandatory=$false,HelpMessage='The optional prefix.')]
        [AllowEmptyString()][AllowNull()]
        [System.String]$ApplicationFolderPrefix,

        [Parameter(Mandatory=$false,HelpMessage='The optional postfix.')]
        [AllowEmptyString()][AllowNull()]
        [System.String]$ApplicationFolderPostfix,

        [Parameter(Mandatory=$false,HelpMessage='The separator placed between the parts.')]
        [AllowEmptyString()][AllowNull()]
        [System.String]$ApplicationFolderSeparator
    )

    if (Test-String -IsEmpty $ApplicationID) { return '' }

    [System.String[]]$FolderNameComponents = @(([System.String]$ApplicationFolderPrefix).Trim(), $ApplicationID.Trim(), ([System.String]$ApplicationFolderPostfix).Trim()) | Where-Object { Test-String -IsPopulated $_ }
    return ($FolderNameComponents -join [System.String]$ApplicationFolderSeparator)
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Updates the New Folder Name preview in the DSL Correction sub-tab.
.DESCRIPTION
    This function builds the folder name from the Application ID and the prefix, postfix and separator TextBoxes, and writes it into the New Folder Name TextBox.
.EXAMPLE
    Update-DSLApplicationFolderNamePreview -DetailTextBoxes $DetailTextBoxes
.INPUTS
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
function Update-DSLApplicationFolderNamePreview {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The TextBoxes keyed by metadata property name. The key NewFolderName receives the preview.')]
        [System.Collections.Hashtable]$DetailTextBoxes
    )

    foreach ($RequiredKey in @('ApplicationID','ApplicationFolderPrefix','ApplicationFolderPostfix','ApplicationFolderSeparator','NewFolderName')) {
        if (-not $DetailTextBoxes.ContainsKey($RequiredKey)) { return }
    }

    $DetailTextBoxes['NewFolderName'].Text = Get-DSLApplicationFolderNameFromParts `
        -ApplicationID $DetailTextBoxes['ApplicationID'].Text `
        -ApplicationFolderPrefix $DetailTextBoxes['ApplicationFolderPrefix'].Text `
        -ApplicationFolderPostfix $DetailTextBoxes['ApplicationFolderPostfix'].Text `
        -ApplicationFolderSeparator $DetailTextBoxes['ApplicationFolderSeparator'].Text
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Checks whether a new application folder name can be used.
.DESCRIPTION
    This function checks the rules for the name of an application folder: no invalid characters, no name that starts with '_' or '.',
    no name that ends with a dot or a space, and no existing folder or file with that name (a change of only upper/lower case is allowed).
.EXAMPLE
    Get-DSLApplicationFolderNameProblem -NewFolderName 'Vendor_App_2.0' -CurrentFolderName 'Vendor_App_1.0' -SoftwareLibraryFolder 'C:\DSL'
.INPUTS
    [System.String]
.OUTPUTS
    [System.String] The problem as a sentence; an empty string when the name can be used.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.11.0
    Author          : Imraan Iotana
    Creation Date   : October 2026
    Last Update     : October 2026
#>
####################################################################################################
function Get-DSLApplicationFolderNameProblem {
    [CmdletBinding()]
    [OutputType([System.String])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The new folder name.')]
        [AllowEmptyString()]
        [System.String]$NewFolderName,

        [Parameter(Mandatory=$true,HelpMessage='The current folder name.')]
        [System.String]$CurrentFolderName,

        [Parameter(Mandatory=$true,HelpMessage='The Software Library (DSL) folder.')]
        [System.String]$SoftwareLibraryFolder
    )

    if (Test-String -IsEmpty $NewFolderName) { return 'The new folder name is empty.' }
    if ($NewFolderName.IndexOfAny([System.IO.Path]::GetInvalidFileNameChars()) -ge 0) { return "The new folder name contains characters that are not allowed in a folder name. ($NewFolderName)" }
    if ($NewFolderName.StartsWith('_') -or $NewFolderName.StartsWith('.')) { return "A folder name that starts with '_' or '.' is treated as an internal folder and would disappear from the DSL list. ($NewFolderName)" }
    if ($NewFolderName.EndsWith('.') -or $NewFolderName.EndsWith(' ')) { return "A folder name cannot end with a dot or a space. ($NewFolderName)" }
    [System.Boolean]$IsCaseOnlyChange = [System.String]::Equals($NewFolderName, $CurrentFolderName, [System.StringComparison]::OrdinalIgnoreCase)
    if ((-not $IsCaseOnlyChange) -and (Test-Path -LiteralPath (Join-Path -Path $SoftwareLibraryFolder -ChildPath $NewFolderName))) { return "A folder or file with the new name already exists. ($NewFolderName)" }
    return ''
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Writes values into top-level properties of a metadata JSON file, without changing anything else in the file.
.DESCRIPTION
    This function replaces the value of each requested string property in the JSON text itself, so the layout and all other content of the file stay exactly as they were.
    It throws when a requested property is not present in the file, before anything is written.
.EXAMPLE
    Set-DSLApplicationMetaDataValue -MetaDataFilePath 'C:\DSL\App\9. Archive\Metadata\Metadata_App.json' -Value @{ ApplicationFolderName = 'TST_App' }
.INPUTS
    [System.String]
    [System.Collections.Specialized.OrderedDictionary]
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
function Set-DSLApplicationMetaDataValue {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The full path of the metadata JSON file.')]
        [System.String]$MetaDataFilePath,

        [Parameter(Mandatory=$true,HelpMessage='The property names and their new string values.')]
        [System.Collections.IDictionary]$Value
    )

    [System.String]$JsonText = [System.IO.File]::ReadAllText($MetaDataFilePath)
    foreach ($PropertyName in $Value.Keys) {
        [System.Text.RegularExpressions.Regex]$PropertyRegex = [System.Text.RegularExpressions.Regex]::new('("' + [System.Text.RegularExpressions.Regex]::Escape([System.String]$PropertyName) + '"\s*:\s*)"(?:[^"\\]|\\.)*"')
        if (-not $PropertyRegex.IsMatch($JsonText)) {
            throw "The property ($PropertyName) was not found in the metadata file."
        }
        [System.String]$NewJsonValue = ConvertTo-Json -InputObject ([System.String]$Value[$PropertyName]) -Compress
        # Only the first match is replaced: the application properties are at the top level, before any nested content
        $JsonText = $PropertyRegex.Replace($JsonText, [System.Text.RegularExpressions.MatchEvaluator]{ param($Match) $Match.Groups[1].Value + $NewJsonValue }, 1)
    }

    # Write with a BOM, as the Intake does
    [System.IO.File]::WriteAllText($MetaDataFilePath, $JsonText, [System.Text.UTF8Encoding]::new($true))
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Renames an application folder in the Software Library (DSL) and updates its metadata and log.
.DESCRIPTION
    This function builds the new folder name from the Application ID in the metadata plus the supplied prefix, postfix and separator.
    After validation and confirmation it renames the folder, updates the folder name properties in the metadata file, and adds an entry to the application log.
    The Application ID and all other content of the folder stay unchanged.
    When the metadata cannot be updated, the rename is reverted.
.EXAMPLE
    Rename-DSLApplicationFolder -ApplicationFolderName 'Vendor_App_1.0' -ApplicationFolderPrefix 'TST' -ApplicationFolderPostfix '' -ApplicationFolderSeparator '_'
.INPUTS
    [System.String]
.OUTPUTS
    [System.String] The new folder name; nothing when no rename was done.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.11.0
    Author          : Imraan Iotana
    Creation Date   : October 2026
    Last Update     : October 2026
#>
####################################################################################################
function Rename-DSLApplicationFolder {
    [CmdletBinding()]
    [OutputType([System.String])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The current name of the application folder in the Software Library (DSL).')]
        [System.String]$ApplicationFolderName,

        [Parameter(Mandatory=$false,HelpMessage='The new prefix.')]
        [AllowEmptyString()][AllowNull()]
        [System.String]$ApplicationFolderPrefix,

        [Parameter(Mandatory=$false,HelpMessage='The new postfix.')]
        [AllowEmptyString()][AllowNull()]
        [System.String]$ApplicationFolderPostfix,

        [Parameter(Mandatory=$false,HelpMessage='The new separator.')]
        [AllowEmptyString()][AllowNull()]
        [System.String]$ApplicationFolderSeparator
    )

    try {
        # PREPARATION - CURRENT FOLDER
        [System.String]$ApplicationFolderPrefix = ([System.String]$ApplicationFolderPrefix).Trim()
        [System.String]$ApplicationFolderPostfix = ([System.String]$ApplicationFolderPostfix).Trim()
        [System.String]$ApplicationFolderSeparator = [System.String]$ApplicationFolderSeparator
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

        # PREPARATION - APPLICATION ID FROM THE METADATA
        [PSCustomObject]$MetaDataResult = Get-DSLApplicationMetaData -ApplicationFolderPath $CurrentFolderPath
        if ($null -eq $MetaDataResult) {
            Write-Line 'The folder cannot be renamed without a readable metadata file. No action has been taken.' -Type Warning
            return
        }
        [System.String]$ApplicationID = [System.String]$MetaDataResult.Data.ApplicationID
        if (Test-String -IsEmpty $ApplicationID) {
            Write-Line 'The metadata file contains no Application ID. No action has been taken.' -Type Warning
            return
        }

        # VALIDATION - NEW FOLDER NAME
        [System.String]$NewFolderName = Get-DSLApplicationFolderNameFromParts -ApplicationID $ApplicationID -ApplicationFolderPrefix $ApplicationFolderPrefix -ApplicationFolderPostfix $ApplicationFolderPostfix -ApplicationFolderSeparator $ApplicationFolderSeparator
        if ([System.String]::Equals($NewFolderName, $ApplicationFolderName, [System.StringComparison]::Ordinal)) {
            Write-Line 'The new folder name is the same as the current folder name. No action has been taken.'
            return
        }
        [System.String]$FolderNameProblem = Get-DSLApplicationFolderNameProblem -NewFolderName $NewFolderName -CurrentFolderName $ApplicationFolderName -SoftwareLibraryFolder $SoftwareLibraryFolder
        if (Test-String -IsPopulated $FolderNameProblem) {
            Write-Line "$FolderNameProblem No action has been taken." -Type Warning
            return
        }
        [System.String]$NewFolderPath = Join-Path -Path $SoftwareLibraryFolder -ChildPath $NewFolderName

        # CONFIRMATION
        [System.String]$ConfirmationBody = "This will RENAME the application folder:`n`nFrom: $ApplicationFolderName`nTo:      $NewFolderName`n`nThe metadata file will be updated and an entry will be added to the application log.`nThe Application ID ($ApplicationID) and all other content stay unchanged.`n`nDo you want to continue?"
        if (-not (Get-UserConfirmation -Title 'Rename Application Folder' -Body $ConfirmationBody)) {
            Write-Line 'Renaming the application folder was cancelled by the user. No action has been taken.' -Type Warning
            return
        }

        # EXECUTION - RENAME THE FOLDER
        try {
            Rename-Item -LiteralPath $CurrentFolderPath -NewName $NewFolderName -ErrorAction Stop
        }
        catch {
            Write-Line "The application folder could not be renamed. Is it open in another program? No action has been taken. ($($_.Exception.Message))" -Type Warning
            return
        }

        # EXECUTION - UPDATE THE METADATA, OR REVERT THE RENAME
        [System.String]$RelativeMetaDataPath = $MetaDataResult.FilePath.Substring($CurrentFolderPath.TrimEnd('\').Length).TrimStart('\')
        [System.String]$NewMetaDataFilePath = Join-Path -Path $NewFolderPath -ChildPath $RelativeMetaDataPath
        try {
            Set-DSLApplicationMetaDataValue -MetaDataFilePath $NewMetaDataFilePath -Value ([ordered]@{
                ApplicationFolderName      = $NewFolderName
                ApplicationFolderPrefix    = $ApplicationFolderPrefix
                ApplicationFolderPostfix   = $ApplicationFolderPostfix
                ApplicationFolderSeparator = $ApplicationFolderSeparator
            })
        }
        catch {
            [System.String]$FailureMessage = $_.Exception.Message
            try {
                Rename-Item -LiteralPath $NewFolderPath -NewName $ApplicationFolderName -ErrorAction Stop
                Write-Line "The metadata file could not be updated, so the rename has been reverted. ($FailureMessage)" -Type Warning
            }
            catch {
                Write-Line "The metadata file could not be updated AND the rename could not be reverted. The folder is now named ($NewFolderName). ($FailureMessage)" -Type Error
            }
            return
        }

        # EXECUTION - LOG THE RENAME
        # A missing or unwritable log must not undo a completed rename
        try {
            [PSCustomObject]$LogContext = Get-ApplicationLogContext -ApplicationFolderPath $NewFolderPath
            if ($null -ne $LogContext) {
                Write-ApplicationLogEntry -LogFilePath $LogContext.LogFilePath -ApplicationID $ApplicationID -Status Success -Action ApplicationFolderRenamed -Details "Renamed application folder from ($ApplicationFolderName) to ($NewFolderName). Prefix: ($ApplicationFolderPrefix) Postfix: ($ApplicationFolderPostfix) Separator: ($ApplicationFolderSeparator)"
            }
            else {
                Write-Line 'No application log was found, so the rename was not logged.' -Type Warning
            }
        }
        catch {
            Write-Line "The rename could not be logged. ($($_.Exception.Message))" -Type Warning
        }

        # POST-EXECUTION
        Write-Line "The application folder has been renamed. ($ApplicationFolderName > $NewFolderName)" -Type Success
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
    Renames the application folder that is selected in the DSL Correction sub-tab.
.DESCRIPTION
    This function reads the prefix, postfix and separator from the TextBoxes, renames the selected folder with Rename-DSLApplicationFolder,
    and when the rename succeeded, reloads the folder list and loads the renamed folder.
    It only runs when the details on screen were loaded for the selected folder (see LoadState), so the values of another folder can never be applied.
.EXAMPLE
    Invoke-DSLApplicationFolderRename -ApplicationFolderComboBox $MyComboBox -DetailTextBoxes $DetailTextBoxes -LoadState $LoadState
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
function Invoke-DSLApplicationFolderRename {
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

        [System.String]$NewFolderName = Rename-DSLApplicationFolder `
            -ApplicationFolderName $SelectedFolderName `
            -ApplicationFolderPrefix $DetailTextBoxes['ApplicationFolderPrefix'].Text `
            -ApplicationFolderPostfix $DetailTextBoxes['ApplicationFolderPostfix'].Text `
            -ApplicationFolderSeparator $DetailTextBoxes['ApplicationFolderSeparator'].Text
        if (Test-String -IsEmpty $NewFolderName) { return }

        # Reload the list, select the renamed folder and load its details
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
