####################################################################################################
<#
.SYNOPSIS
    Creates a metadata JSON file with all current Intake values.
.OUTPUTS
    [System.String] Full path of the created metadata JSON file.
.NOTES
    Version         : 6.6.1
#>
####################################################################################################
function New-MetaDataFile {
    [CmdletBinding()]
    [OutputType([System.String])]
    param (
        [Parameter(Mandatory=$false)]
        [System.String]$ApplicationFolderPath,

        [Parameter(Mandatory=$false)]
        [System.Object]$SelectedTemplate
    )

    try {
        if (-not (Confirm-FolderPath -Path $ApplicationFolderPath -Name 'Application Folder')) {
            throw 'The ApplicationFolderPath parameter is invalid. Metadata file creation was cancelled.'
        }
        if ($null -eq $SelectedTemplate) {
            Write-Line 'No customer template is selected. Skipping metadata file creation.' -Type Warning
            return
        }

        [System.String]$MetadataFolderPath = Resolve-MetaDataPaths -ApplicationFolderPath $ApplicationFolderPath -SelectedTemplate $SelectedTemplate
        [System.Windows.Forms.TextBox]$ApplicationIDTextBox = Get-IntakeApplicationIDTextBox
        [System.String]$ApplicationID = if ($null -ne $ApplicationIDTextBox) { $ApplicationIDTextBox.Text } else { $null }
        if (Test-String -IsEmpty $ApplicationID) { throw 'ApplicationID is empty. Metadata file creation was cancelled.' }
        [System.Windows.Forms.TextBox]$ApplicationFolderNameTextBox = Get-TextBoxObject -TextBoxName 'ApplicationFolderName'
        [System.String]$ApplicationFolderName = if ($null -ne $ApplicationFolderNameTextBox) { $ApplicationFolderNameTextBox.Text.Trim() } else { $null }
        [System.String]$ApplicationFolderPrefix = Get-UserSetting -PropertyName 'TextBoxes.applicationintake.desktopapplication.applicationid.ApplicationFolderPrefix'
        [System.String]$ApplicationFolderPostfix = Get-UserSetting -PropertyName 'TextBoxes.applicationintake.desktopapplication.applicationid.ApplicationFolderPostfix'
        [System.String]$ApplicationFolderSeparator = Get-UserSetting -PropertyName 'TextBoxes.applicationintake.desktopapplication.applicationid.ApplicationFolderSeparator'

        [System.String]$SafeApplicationID = ($ApplicationID -replace '[\\/:*?""<>|]', '_')
        [System.String]$MetadataFilePath = Join-Path -Path $MetadataFolderPath -ChildPath ("Metadata_$SafeApplicationID.json")
        [PSCustomObject]$ResolvedMetaData = Get-MetaDataFromIntakeTextBoxes
        [System.String]$DetectionFilePath = [System.String]$ResolvedMetaData.DetectionFile
        # Detection File is optional; the user already confirmed proceeding without one, if it was empty, before folder creation started.
        if ((Test-String -IsPopulated $DetectionFilePath) -and -not (Confirm-FilePath -Path $DetectionFilePath -Name 'Detection File')) {
            throw 'The Detection file path is invalid. Metadata file creation was cancelled.'
        }

        [PSCustomObject[]]$ShortcutMetaData = @()
        [System.Windows.Forms.ComboBox]$ApplicationShortcutsComboBox = Get-ComboBoxObject -ComboBoxName 'SelectShortcutFolder'
        if ($null -ne $ApplicationShortcutsComboBox -and $null -ne $ApplicationShortcutsComboBox.SelectedItem) {
            $ShortcutMetaData = Get-ShortcutInformationCollection -ShortcutComboBox $ApplicationShortcutsComboBox
        }

        [PSCustomObject]$MetaDataObject = [PSCustomObject][ordered]@{
            CreatedOn                = Get-TimeStamp -ForHost
            ApplicationID            = $ApplicationID
            ApplicationFolderName    = $ApplicationFolderName
            ApplicationFolderPrefix  = $ApplicationFolderPrefix
            ApplicationFolderPostfix = $ApplicationFolderPostfix
            ApplicationFolderSeparator = $ApplicationFolderSeparator
            FormalVendorName         = [System.String]$ResolvedMetaData.FormalVendorName
            FormalApplicationName    = [System.String]$ResolvedMetaData.FormalApplicationName
            FormalApplicationVersion = [System.String]$ResolvedMetaData.FormalApplicationVersion
            CustomVendorName         = [System.String]$ResolvedMetaData.CustomVendorName
            CustomApplicationName    = [System.String]$ResolvedMetaData.CustomApplicationName
            CustomApplicationVersion = [System.String]$ResolvedMetaData.CustomApplicationVersion
            InstallationFolder       = [System.String]$ResolvedMetaData.InstallationFolder
            ADGroupName              = [System.String]$ResolvedMetaData.ADGroupName
            ADGroupSID               = [System.String]$ResolvedMetaData.ADGroupSID
            DetectionFile            = $DetectionFilePath
            DetectionFileVersion     = if (Test-String -IsPopulated $DetectionFilePath) { Get-FileVersion -Path $DetectionFilePath } else { '' }
            Bitness                  = if (Test-String -IsPopulated $DetectionFilePath) { Get-FileBitness -Path $DetectionFilePath -ForDocument } else { '' }
            UserFullName             = [System.String]$ResolvedMetaData.UserFullName
            UserEmailAddress         = [System.String]$ResolvedMetaData.UserEmailAddress
            Shortcuts                = $ShortcutMetaData
            SelectedTemplate         = $SelectedTemplate
        }

        Write-Line "Creating metadata JSON file: $MetadataFilePath"
        [System.Object]$ConvertedMetaData = Convert-MetaDataObject -MetaDataObject $MetaDataObject
        [System.String]$MetaDataJson = $ConvertedMetaData | ConvertTo-Json -Depth 20
        Set-Content -Path $MetadataFilePath -Value $MetaDataJson -Encoding UTF8
        Write-Line "Created metadata JSON file: $MetadataFilePath"
        return $MetadataFilePath
    }
    catch {
        # Re-throw so the caller's rollback/error-reporting logic handles this once, instead of continuing with a $null metadata path.
        throw
    }
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
function Resolve-MetaDataPaths {
    [CmdletBinding()]
    [OutputType([System.String])]
    param (
        [Parameter(Mandatory=$true)]
        [System.String]$ApplicationFolderPath,

        [Parameter(Mandatory=$true)]
        [System.Object]$SelectedTemplate
    )

    [System.String]$MetadataRelativePath = [System.String]$SelectedTemplate.ApplicationFolderSubFolders.Metadata
    if (Test-String -IsEmpty $MetadataRelativePath) {
        $MetadataRelativePath = Join-Path -Path '9. Archive' -ChildPath 'Metadata'
        Write-Line 'The selected customer template does not define ApplicationFolderSubFolders.Metadata. Using default path: (9. Archive\Metadata)' -Type Warning
    }

    [System.String]$MetadataFolderPath = Join-Path -Path $ApplicationFolderPath -ChildPath $MetadataRelativePath
    if (-not (Test-Path -LiteralPath $MetadataFolderPath -PathType Container)) {
        New-Item -Path $MetadataFolderPath -ItemType Directory -Force | Out-Null
    }
    return $MetadataFolderPath
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Resolves Intake metadata from user settings.
.NOTES
    Version         : 6.6.1
#>
function Get-MetaDataFromIntakeTextBoxes {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param ()

    try {
        [System.Collections.Specialized.OrderedDictionary]$MandatoryValuesMap = [ordered]@{
            FormalVendorName         = 'FormalVendorName'
            FormalApplicationName    = 'FormalApplicationName'
            FormalApplicationVersion = 'FormalApplicationVersion'
            CustomVendorName         = 'CustomVendorName'
            CustomApplicationName    = 'CustomApplicationName'
            CustomApplicationVersion = 'CustomApplicationVersion'
            InstallationFolder       = 'InstallationFolder'
        }

        [System.Collections.Specialized.OrderedDictionary]$ResolvedMetaData = [ordered]@{}
        foreach ($Entry in $MandatoryValuesMap.GetEnumerator()) {
            [System.String]$PropertyName = [System.String]$Entry.Key
            [System.String]$PropertyLeaf = [System.String]$Entry.Value
            [System.String]$Value = Get-UserSetting -PropertyLeaf $PropertyLeaf
            if (Test-String -IsEmpty $Value) {
                throw "Unable to resolve required Intake metadata value for '$PropertyName' from User Settings. The property leaf '$PropertyLeaf' is empty."
            }
            $ResolvedMetaData[$PropertyName] = $Value
        }

        # Detection File is optional at this point; emptiness is confirmed with the user upstream in New-ApplicationFolder.
        $ResolvedMetaData['DetectionFile'] = Get-UserSetting -PropertyLeaf 'DetectionfileMSI'

        [PSCustomObject]$AppLockerConfiguration = Get-ApplicationIntakeAppLockerConfiguration
        $ResolvedMetaData['ADGroupName'] = $AppLockerConfiguration.ADGroupName
        $ResolvedMetaData['ADGroupSID'] = $AppLockerConfiguration.ADGroupSID

        $ResolvedMetaData['UserFullName'] = Get-UserSetting -PropertyLeaf 'MyFullName'
        $ResolvedMetaData['UserEmailAddress'] = Get-UserSetting -PropertyLeaf 'MyEmailAddress'
        return [PSCustomObject]$ResolvedMetaData
    }
    catch {
        # Re-throw so New-MetaDataFile does not continue building a metadata object from a $null result.
        throw
    }
}

### END OF FUNCTION
####################################################################################################
