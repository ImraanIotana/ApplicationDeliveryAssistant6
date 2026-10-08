####################################################################################################
<#
.SYNOPSIS
    Creates a Custom Application folder and its initial artifacts.
.DESCRIPTION
    Validates the scoped Custom Application form, initializes the shared folder context, and creates portable icons, a launch shortcut, privacy-safe metadata, and a Word document.
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.3.1
    Author          : Imraan Iotana
    Creation Date   : August 2026
    Last Update     : August 2026
#>
####################################################################################################
function New-CustomApplicationFolder {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false,HelpMessage='Parent folder where the Custom Application folder will be created.')]
        [System.String]$OutputFolder = (Get-Folder -OutputFolder)
    )

    [PSCustomObject]$Context = $null
    try {
        # VALIDATION - OUTPUT AND FORM VALUES
        if (Test-String -IsEmpty $OutputFolder) { throw 'The OutputFolder parameter is empty.' }

        [PSCustomObject]$FormData = Get-CustomApplicationFormData
        [System.String]$ApplicationID = New-CustomApplicationID `
            -VendorPublisher $FormData.VendorPublisher `
            -ApplicationName $FormData.ApplicationName `
            -ApplicationVersion $FormData.ApplicationVersion `
            -OutputTextBox $FormData.ApplicationIDTextBox
        if (Test-String -IsEmpty $ApplicationID) { return }

        if (Test-String -IsEmpty $FormData.ApplicationType) {
            Write-Line 'Application Type is empty. The Custom Application folder cannot be created.' -Type Warning
            return
        }
        if ((Test-String -IsEmpty $FormData.ApplicationExecutable) -or
            (-not (Test-Path -LiteralPath $FormData.ApplicationExecutable -PathType Leaf))) {
            Write-Line "The Application Executable does not exist. ($($FormData.ApplicationExecutable))" -Type Warning
            return
        }
        if ((Test-String -IsPopulated $FormData.ApplicationIcon) -and
            (-not (Test-Path -LiteralPath $FormData.ApplicationIcon -PathType Leaf))) {
            Write-Line "The optional Application Icon does not exist. ($($FormData.ApplicationIcon))" -Type Warning
            return
        }

        # PREPARATION - TRANSACTIONAL APPLICATION FOLDER
        # Shared preparation performs the only overwrite confirmation before recreating the package folder.
        $Context = New-ApplicationFolderContext -ApplicationID $ApplicationID -OutputFolder $OutputFolder
        if ($null -eq $Context) { return }

        # EXECUTION - REQUIRED APPLICATION ARTIFACTS
        [System.String]$ShortcutFolderPath = Get-ApplicationArtifactFolderPath `
            -ApplicationFolderPath $Context.ApplicationFolderPath `
            -SelectedTemplate $Context.SelectedTemplate `
            -FolderName Shortcuts `
            -DefaultRelativePath '9. Archive\Shortcuts'
        [System.String]$IconSourcePath = Resolve-CustomApplicationIconSourcePath `
            -ApplicationIconPath $FormData.ApplicationIcon `
            -ApplicationExecutablePath $FormData.ApplicationExecutable
        [PSCustomObject]$IconArtifacts = Export-CustomApplicationIconFiles `
            -SourcePath $IconSourcePath `
            -OutputFolder $ShortcutFolderPath `
            -BaseName $FormData.ApplicationName

        [System.Collections.Hashtable]$ApplicationLog = $Context.ApplicationLog
        Write-ApplicationFileLogEntry @ApplicationLog -FilePath $IconArtifacts.PngPath -Action CustomApplicationIconImageCreated -DetailsPrefix 'Created documentation icon image'
        Write-ApplicationFileLogEntry @ApplicationLog -FilePath $IconArtifacts.IcoPath -Action CustomApplicationIconCreated -DetailsPrefix 'Created shortcut icon'

        [PSCustomObject]$ShortcutArtifact = New-CustomApplicationShortcutArtifact -FormData $FormData -Context $Context -IconArtifacts $IconArtifacts
        [PSCustomObject]$ShortcutInformationArtifact = Export-CustomApplicationShortcutInformationArtifact `
            -ShortcutArtifact $ShortcutArtifact `
            -Context $Context
        [System.String]$MetadataFilePath = New-CustomApplicationMetadataArtifact `
            -FormData $FormData `
            -Context $Context `
            -ShortcutMetadata $ShortcutArtifact.Metadata `
            -IconArtifacts $IconArtifacts
        $null = New-CustomApplicationDocumentArtifact `
            -Context $Context `
            -MetadataFilePath $MetadataFilePath `
            -IconFolderPath $ShortcutFolderPath

        # VALIDATION - REQUIRED ARTIFACT CONTRACT
        [System.String[]]$RequiredFilePaths = @(
            $IconArtifacts.PngPath
            $IconArtifacts.IcoPath
            $ShortcutArtifact.FilePath
            $ShortcutInformationArtifact.ReportFilePath
            $ShortcutInformationArtifact.PngFilePath
            $ShortcutInformationArtifact.IcoFilePath
            $MetadataFilePath
        )
        # POST-EXECUTION - TRANSACTIONAL PUBLICATION
        Complete-ApplicationFolderContext -Context $Context -Details 'Completed initial Custom Application intake processing.' -RequiredFilePaths $RequiredFilePaths
    }
    catch {
        Remove-ApplicationFolderContextStaging -Context $Context
        Write-ErrorReport -ErrorRecord $_
    }
}

### END OF FUNCTION
####################################################################################################