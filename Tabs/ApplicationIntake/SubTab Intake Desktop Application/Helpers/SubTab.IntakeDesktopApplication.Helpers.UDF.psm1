####################################################################################################
<#
.SYNOPSIS
    Copies and extracts the configured UDF zip into the Work subfolder.
.DESCRIPTION
    Resolves UDFName from the selected customer template, locates the zip file below the configured
    customer folder, and extracts it into the Work subfolder of the supplied application folder.
.OUTPUTS
    [System.String] when PassThru is specified and the UDF is extracted; otherwise no objects are returned.
#>
####################################################################################################
function Copy-UDF {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The root folder of the created application package.')]
        [System.String]$ApplicationFolderPath,

        [Parameter(Mandatory=$true,HelpMessage='The selected customer template object.')]
        [System.Object]$SelectedTemplate,

        [Parameter(Mandatory=$false,HelpMessage='The folder where UDF zip files are searched.')]
        [System.String]$FolderToSearch = $Global:ApplicationObject.RootFolder,

        [Parameter(Mandatory=$false,HelpMessage='Skip the confirmation prompt and extract immediately.')]
        [System.Management.Automation.SwitchParameter]$SkipConfirmation,

        [Parameter(Mandatory=$false,HelpMessage='Return the extracted UDF folder path.')]
        [System.Management.Automation.SwitchParameter]$PassThru
    )

    try {
        if (Test-String -IsEmpty $ApplicationFolderPath) { throw 'The ApplicationFolderPath parameter is empty.' }
        if (-not (Test-Path -LiteralPath $ApplicationFolderPath -PathType Container)) { throw "The application folder does not exist. ($ApplicationFolderPath)" }
        if ($null -eq $SelectedTemplate) {
            Write-Line 'No customer template is selected. Skipping UDF copy.' -Type Warning
            return
        }

        [System.String]$UDFName = $SelectedTemplate.Content.UDFName
        if (Test-String -IsEmpty $UDFName) {
            Write-Line 'The selected customer template does not define Content.UDFName. Skipping UDF copy.' -Type Warning
            return
        }

        if (-not $SkipConfirmation) {
            [System.String]$Title = 'Copy UDF Archive'
            [System.String]$Body = 'Would you like to add the UNIVERSAL DEPLOYMENT FRAMEWORK (UDF) into the application Work folder?'
            if (-not (Get-UserConfirmation -Title $Title -Body $Body)) { return }
        }

        if (Test-String -IsEmpty $FolderToSearch) { throw 'The FolderToSearch parameter is empty.' }
        if (-not (Test-Path -LiteralPath $FolderToSearch -PathType Container)) { throw "UDF search folder not found. ($FolderToSearch)" }

        [System.IO.FileInfo]$UDFFile = Get-ChildItem -LiteralPath $FolderToSearch -Recurse -File -Filter $UDFName -ErrorAction SilentlyContinue | Select-Object -First 1
        [System.String]$ResolvedUDFPath = if ($null -ne $UDFFile) { $UDFFile.FullName } else { $null }
        if (Test-String -IsEmpty $ResolvedUDFPath) {
            Write-Line "The selected UDF zip could not be found in the search folder. ($UDFName)" -Type Warning
            return
        }

        [System.String]$WorkRelativePath = $SelectedTemplate.ApplicationFolderSubFolders.Work
        if (Test-String -IsEmpty $WorkRelativePath) { $WorkRelativePath = '8. Work' }

        [System.String]$WorkFolderPath = Join-Path -Path $ApplicationFolderPath -ChildPath $WorkRelativePath
        if (-not (Test-Path -LiteralPath $WorkFolderPath -PathType Container)) {
            New-Item -Path $WorkFolderPath -ItemType Directory -Force | Out-Null
        }

        [System.Windows.Forms.TextBox]$ApplicationIDTextBox = Get-IntakeApplicationIDTextBox
        [System.String]$ApplicationID = if ($null -ne $ApplicationIDTextBox) { $ApplicationIDTextBox.Text } else { $null }
        if (Test-String -IsEmpty $ApplicationID) { $ApplicationID = 'ApplicationDossier' }

        [System.String]$NewUDFFolderPath = Join-Path -Path $WorkFolderPath -ChildPath $ApplicationID
        if (Test-Path -LiteralPath $NewUDFFolderPath -PathType Container) {
            Remove-Item -LiteralPath $NewUDFFolderPath -Recurse -Force
        }
        New-Item -Path $NewUDFFolderPath -ItemType Directory -Force | Out-Null

        Write-Line "Extracting UDF archive to folder: $NewUDFFolderPath"
        Expand-Archive -LiteralPath $ResolvedUDFPath -DestinationPath $NewUDFFolderPath -Force

        [System.String]$ArchiveFolderName = [System.IO.Path]::GetFileNameWithoutExtension($UDFName)
        [System.String]$NestedArchiveFolderPath = Join-Path -Path $NewUDFFolderPath -ChildPath $ArchiveFolderName
        if (Test-Path -LiteralPath $NestedArchiveFolderPath -PathType Container) {
            Get-ChildItem -LiteralPath $NestedArchiveFolderPath -Force | ForEach-Object {
                Move-Item -LiteralPath $_.FullName -Destination $NewUDFFolderPath -Force
            }
            Remove-Item -LiteralPath $NestedArchiveFolderPath -Recurse -Force -ErrorAction SilentlyContinue
        }

        Write-Line "Added the Universal Deployment Framework: $ResolvedUDFPath" -Type Success
        if ($PassThru -and (Test-Path -LiteralPath $NewUDFFolderPath -PathType Container)) {
            return $NewUDFFolderPath
        }
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}

### END OF FUNCTION
####################################################################################################
