####################################################################################################
<#
.SYNOPSIS
    Creates and logs the Intake metadata artifact.
.OUTPUTS
    [System.String] Full path of the created metadata file.
.NOTES
    Version         : 6.6.0
#>
####################################################################################################
function New-ApplicationMetadataArtifact {
    [CmdletBinding()]
    [OutputType([System.String])]
    param (
        [Parameter(Mandatory=$true)]
        [System.String]$ApplicationFolderPath,

        [Parameter(Mandatory=$true)]
        [System.Object]$SelectedTemplate,

        [Parameter(Mandatory=$true)]
        [System.Collections.Hashtable]$ApplicationLog
    )

    [System.String]$MetaDataFilePath = New-MetaDataFile -ApplicationFolderPath $ApplicationFolderPath -SelectedTemplate $SelectedTemplate
    Write-ApplicationFileLogEntry @ApplicationLog -FilePath $MetaDataFilePath -Action MetadataFileCreated -DetailsPrefix 'Created metadata file'
    return $MetaDataFilePath
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Exports and logs the selected shortcut information.
.OUTPUTS
    No objects are returned to the pipeline.
#>
####################################################################################################
function Export-ApplicationShortcutArtifact {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [System.String]$ApplicationFolderPath,

        [Parameter(Mandatory=$true)]
        [System.Collections.Hashtable]$ApplicationLog
    )

    [System.Object]$ApplicationShortcutsComboBox = Get-ComboBoxObject -ComboBoxName 'SelectShortcutFolder'
    [System.String]$ShortcutInformationFilePath = Export-ShortcutInformation -ApplicationFolderPath $ApplicationFolderPath -ShortcutComboBox $ApplicationShortcutsComboBox -SkipConfirmation -PassThru
    Write-ApplicationFileLogEntry @ApplicationLog -FilePath $ShortcutInformationFilePath -Action ShortcutInformationExported -DetailsPrefix 'Exported shortcut information'
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Creates and logs the Intake document from the selected template and metadata.
.OUTPUTS
    No objects are returned to the pipeline.
#>
####################################################################################################
function New-ApplicationDocumentArtifact {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [System.String]$ApplicationFolderPath,

        [Parameter(Mandatory=$true)]
        [System.Object]$SelectedTemplate,

        [Parameter(Mandatory=$true)]
        [System.String]$MetaDataFilePath,

        [Parameter(Mandatory=$true)]
        [System.Collections.Hashtable]$ApplicationLog
    )

    [System.String]$CustomerFolderPath = Join-Path -Path $Global:ApplicationObject.RootFolder -ChildPath 'Customer'
    [System.String[]]$DocumentFilePaths = @(New-ApplicationIntakeDocument -ApplicationFolderPath $ApplicationFolderPath -SelectedTemplate $SelectedTemplate -FolderToSearch $CustomerFolderPath -MetaDataFilePath $MetaDataFilePath -PassThru)
    foreach ($DocumentFilePath in $DocumentFilePaths) {
        if ((Test-String -IsPopulated $DocumentFilePath) -and (Test-Path -LiteralPath $DocumentFilePath -PathType Leaf)) {
            Write-ApplicationFileLogEntry @ApplicationLog -FilePath $DocumentFilePath -Action WordDocumentCreated -DetailsPrefix 'Created Word document'
        }
    }
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Exports and logs registry information selected in the Intake form.
.OUTPUTS
    No objects are returned to the pipeline.
#>
####################################################################################################
function Export-ApplicationRegistryArtifact {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [System.String]$ApplicationFolderPath,

        [Parameter(Mandatory=$true)]
        [System.Object]$SelectedTemplate,

        [Parameter(Mandatory=$true)]
        [System.Collections.Hashtable]$ApplicationLog
    )

    [System.Object]$InstalledApplicationsComboBox = Get-ComboBoxObject -ComboBoxName 'ImportfromRegistry'
    [System.Object]$SelectedInstalledApplication = if ($null -ne $InstalledApplicationsComboBox) { $InstalledApplicationsComboBox.SelectedItem } else { $null }
    [System.String]$SelectedRegistryPath = if ($null -ne $SelectedInstalledApplication) { $SelectedInstalledApplication.RegistryPath } else { $null }
    [System.String]$OtherRelativePath = [System.String]$SelectedTemplate.ApplicationFolderSubFolders.Other

    if (Test-String -IsEmpty $OtherRelativePath) {
        Write-Line 'The selected customer template does not define ApplicationFolderSubFolders.Other. Skipping registry export.' -Type Warning
        return
    }
    if (Test-String -IsEmpty $SelectedRegistryPath) {
        Write-Line 'No installed application selected. Skipping registry export.' -Type Warning
        return
    }

    [System.String]$RegistryExportOutputFolder = Join-Path -Path $ApplicationFolderPath -ChildPath $OtherRelativePath
    [System.String]$RegistryExportFilePath = Export-RegistryKey -RegistryKeyPath $SelectedRegistryPath -OutputFolder $RegistryExportOutputFolder -PassThru
    Write-ApplicationFileLogEntry @ApplicationLog -FilePath $RegistryExportFilePath -Action RegistryInformationExported -DetailsPrefix 'Exported registry information'
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Creates and logs AppLocker artifacts from the current Intake security values.
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    Version         : 6.6.0
#>
####################################################################################################
function New-ApplicationAppLockerArtifacts {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [System.String]$ApplicationID,

        [Parameter(Mandatory=$true)]
        [System.String]$ApplicationFolderPath,

        [Parameter(Mandatory=$true)]
        [System.Object]$SelectedTemplate,

        [Parameter(Mandatory=$true)]
        [System.Collections.Hashtable]$ApplicationLog
    )

    [PSCustomObject]$AppLockerConfiguration = Get-ApplicationIntakeAppLockerConfiguration
    if (-not $AppLockerConfiguration.CreateFiles) {
        Write-Line 'AppLocker policy creation is not selected. Skipping AppLocker artifacts.'
        return
    }

    [System.Windows.Forms.TextBox]$InstallationFolderTextBox = Get-TextBoxObject -TextBoxName 'InstallationFolder'
    [System.String]$InstallationFolder = if ($null -ne $InstallationFolderTextBox) { $InstallationFolderTextBox.Text } else { $null }

    [System.String]$AppLockerFolderPath = New-AppLockerFile -Path $InstallationFolder -ADGroupSID $AppLockerConfiguration.ADGroupSID -ApplicationID $ApplicationID -ApplicationFolderPath $ApplicationFolderPath -SelectedTemplate $SelectedTemplate -SkipConfirmation -PassThru
    Write-ApplicationFolderLogEntry @ApplicationLog -FolderPath $AppLockerFolderPath -Action AppLockerPoliciesCreated -DetailsPrefix 'Created AppLocker policies in folder'
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Extracts and logs the configured UDF artifact.
.OUTPUTS
    No objects are returned to the pipeline.
#>
####################################################################################################
function Copy-ApplicationUDFArtifact {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [System.String]$ApplicationFolderPath,

        [Parameter(Mandatory=$true)]
        [System.Object]$SelectedTemplate,

        [Parameter(Mandatory=$true)]
        [System.Collections.Hashtable]$ApplicationLog
    )

    [System.String]$UDFFolderPath = Copy-UDF -ApplicationFolderPath $ApplicationFolderPath -SelectedTemplate $SelectedTemplate -PassThru
    Write-ApplicationFolderLogEntry @ApplicationLog -FolderPath $UDFFolderPath -Action UDFExtracted -DetailsPrefix 'Extracted UDF to folder'
}

### END OF FUNCTION
####################################################################################################
