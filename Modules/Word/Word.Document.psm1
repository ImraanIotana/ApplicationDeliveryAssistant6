####################################################################################################
<#
.SYNOPSIS
    Creates the intake Word document(s) from the selected customer template.
.DESCRIPTION
    Resolves the selected template(s) (including Dossier and TAT templates), confirms the output
    location, and creates the Word document(s).
.EXAMPLE
    New-ApplicationIntakeDocument -ApplicationFolderPath 'C:\Temp\App' -SelectedTemplate $SelectedTemplate -FolderToSearch 'C:\Templates'
.INPUTS
    [System.String]
    [System.Object]
.OUTPUTS
    [System.String[]] when PassThru is specified and Word document(s) are created; otherwise no objects are returned.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.6.0
    Author          : Imraan Iotana
    Creation Date   : July 2026
    Last Update     : September 2026
#>
####################################################################################################
function New-ApplicationIntakeDocument {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The root folder of the created application package.')]
        [ValidateNotNullOrEmpty()]
        [System.String]$ApplicationFolderPath,

        [Parameter(Mandatory=$true,HelpMessage='The selected customer template object from the Template Selection ComboBox.')]
        [ValidateNotNullOrEmpty()]
        [System.Object]$SelectedTemplate,

        [Parameter(Mandatory=$true,HelpMessage='The folder where Word templates are searched.')]
        [ValidateNotNullOrEmpty()]
        [System.String]$FolderToSearch,

        [Parameter(Mandatory=$false,HelpMessage='Optional metadata JSON file path used to build Word placeholder replacements.')]
        [System.String]$MetaDataFilePath,

        [Parameter(Mandatory=$false,HelpMessage='Optional explicit Application ID used for output naming.')]
        [System.String]$ApplicationID,

        [Parameter(Mandatory=$false,HelpMessage='Optional folder containing shortcut icon images.')]
        [System.String]$IconFolderPath,

        [Parameter(Mandatory=$false,HelpMessage='Return the created Word document file path(s).')]
        [System.Management.Automation.SwitchParameter]$PassThru
    )

    try {
        # VALIDATION
        # Confirm the required folders exist before doing any document work.
        if (-not (Test-Path -LiteralPath $ApplicationFolderPath -PathType Container)) { throw "The application folder does not exist. ($ApplicationFolderPath)" }
        if (-not (Test-Path -LiteralPath $FolderToSearch -PathType Container)) { throw "Template search folder not found. ($FolderToSearch)" }

        # Resolve all configured template names (e.g. TemplateName and optional TatTemplateName)
        [System.Collections.Generic.List[System.String]]$ConfiguredTemplateNames = New-Object 'System.Collections.Generic.List[System.String]'
        if ($SelectedTemplate.Content -is [System.Collections.IDictionary]) {
            if ($SelectedTemplate.Content.Contains('TemplateName') -and (Test-String -IsPopulated $SelectedTemplate.Content.TemplateName)) {
                [void]$ConfiguredTemplateNames.Add([System.String]$SelectedTemplate.Content.TemplateName)
            }
            if ($SelectedTemplate.Content.Contains('TatTemplateName') -and (Test-String -IsPopulated $SelectedTemplate.Content.TatTemplateName)) {
                [void]$ConfiguredTemplateNames.Add([System.String]$SelectedTemplate.Content.TatTemplateName)
            }
            elseif ($SelectedTemplate.Content.Contains('TATTemplateName') -and (Test-String -IsPopulated $SelectedTemplate.Content.TATTemplateName)) {
                [void]$ConfiguredTemplateNames.Add([System.String]$SelectedTemplate.Content.TATTemplateName)
            }
        }
        elseif ($null -ne $SelectedTemplate.PSObject.Properties['Content']) {
            if ($null -ne $SelectedTemplate.Content.PSObject.Properties['TemplateName'] -and (Test-String -IsPopulated $SelectedTemplate.Content.TemplateName)) {
                [void]$ConfiguredTemplateNames.Add([System.String]$SelectedTemplate.Content.TemplateName)
            }
            if ($null -ne $SelectedTemplate.Content.PSObject.Properties['TatTemplateName'] -and (Test-String -IsPopulated $SelectedTemplate.Content.TatTemplateName)) {
                [void]$ConfiguredTemplateNames.Add([System.String]$SelectedTemplate.Content.TatTemplateName)
            }
            elseif ($null -ne $SelectedTemplate.Content.PSObject.Properties['TATTemplateName'] -and (Test-String -IsPopulated $SelectedTemplate.Content.TATTemplateName)) {
                [void]$ConfiguredTemplateNames.Add([System.String]$SelectedTemplate.Content.TATTemplateName)
            }
        }

        if ($ConfiguredTemplateNames.Count -eq 0) {
            Write-Line 'The selected customer template does not define any Word templates (TemplateName / TatTemplateName). Skipping document creation.' -Type Warning
            return
        }

        [System.String]$DocumentationRelativePath = $SelectedTemplate.ApplicationFolderSubFolders.Documentation
        if (Test-String -IsEmpty $DocumentationRelativePath) {
            Write-Line 'The selected customer template does not define ApplicationFolderSubFolders.Documentation. Skipping document creation.' -Type Warning
            return
        }

        # Prefer the directory belonging to the selected customer template to avoid same-name cross-customer matches.
        [System.String]$SelectedTemplateDirectory = if ($null -ne $SelectedTemplate.Directory) { [System.String]$SelectedTemplate.Directory } else { '' }
        [System.Collections.Generic.List[System.String]]$ResolvedTemplatePaths = New-Object 'System.Collections.Generic.List[System.String]'

        foreach ($WordTemplateName in $ConfiguredTemplateNames) {
            if ([System.IO.Path]::IsPathRooted($WordTemplateName) -or
                [System.IO.Path]::GetFileName($WordTemplateName) -ne $WordTemplateName -or
                $WordTemplateName.IndexOfAny([System.IO.Path]::GetInvalidFileNameChars()) -ge 0) {
                Write-Line "The selected customer template defines an unsafe Word template filename. ($WordTemplateName)" -Type Fail
                continue
            }

            [System.String]$ResolvedTemplatePath = ''
            if (Test-String -IsPopulated $SelectedTemplateDirectory) {
                [System.String]$PreferredTemplatePath = Join-Path -Path $SelectedTemplateDirectory -ChildPath $WordTemplateName
                if (Test-Path -LiteralPath $PreferredTemplatePath -PathType Leaf) {
                    $ResolvedTemplatePath = $PreferredTemplatePath
                }
            }
            if (Test-String -IsEmpty $ResolvedTemplatePath) {
                $ResolvedTemplatePath = (Get-ChildItem -LiteralPath $FolderToSearch -Recurse -File -Filter $WordTemplateName -ErrorAction SilentlyContinue | Select-Object -First 1).FullName
            }
            if (Test-String -IsEmpty $ResolvedTemplatePath) {
                Write-Line "The selected Word template could not be found for the selected customer template. ($WordTemplateName)" -Type Fail
                continue
            }
            [void]$ResolvedTemplatePaths.Add($ResolvedTemplatePath)
        }

        if ($ResolvedTemplatePaths.Count -eq 0) {
            Write-Line 'No valid Word templates could be resolved for the selected customer template.' -Type Fail
            return
        }

        # PREPARATION
        # Resolve the output paths and current Application ID.
        if (Test-String -IsEmpty $ApplicationID) {
            [System.Windows.Forms.TextBox]$ApplicationIDTextBox = Get-IntakeApplicationIDTextBox
            $ApplicationID = if ($null -ne $ApplicationIDTextBox) { $ApplicationIDTextBox.Text } else { $null }
        }
        if (Test-String -IsEmpty $ApplicationID) {
            $ApplicationID = 'ApplicationDossier'
        }
        [System.String]$DocumentationFolderPath = Join-Path -Path $ApplicationFolderPath -ChildPath $DocumentationRelativePath
        if (-not (Test-Path -LiteralPath $DocumentationFolderPath -PathType Container)) {
            New-Item -Path $DocumentationFolderPath -ItemType Directory -Force | Out-Null
        }

        # PREREQUISITE CHECK
        # If Microsoft Word is not installed, inform the user and copy the Word template(s) directly without prompting.
        if ($null -eq [System.Type]::GetTypeFromProgID('Word.Application')) {
            Write-Line 'Microsoft Word is not installed or not registered on this computer. Word document creation is skipped.' -Type Warning
            foreach ($TemplatePath in $ResolvedTemplatePaths) {
                [System.String]$FallbackCopyPath = Join-Path -Path $DocumentationFolderPath -ChildPath ([System.IO.Path]::GetFileName($TemplatePath))
                Copy-ApplicationIntakeTemplateFallback -SourceTemplatePath $TemplatePath -DestinationTemplatePath $FallbackCopyPath -PrefixMessage 'Microsoft Word is not installed.' -MessageType Warning
            }
            return
        }

        # CONFIRMATION
        # Ask before creating the Word document(s).
        [System.String]$DocWord = if ($ResolvedTemplatePaths.Count -gt 1) { 'WORD DOCUMENTS' } else { 'WORD DOCUMENT' }
        [System.String]$Title = "Confirm $DocWord"
        [System.String]$Body = "Do you want to create the $DocWord for the following application?`n`n$ApplicationID"
        if (-not (Get-UserConfirmation -Title $Title -Body $Body)) {
            foreach ($TemplatePath in $ResolvedTemplatePaths) {
                [System.String]$FallbackCopyPath = Join-Path -Path $DocumentationFolderPath -ChildPath ([System.IO.Path]::GetFileName($TemplatePath))
                Copy-ApplicationIntakeTemplateFallback -SourceTemplatePath $TemplatePath -DestinationTemplatePath $FallbackCopyPath -MessageType Info
            }
            return
        }

        # PREPARATION
        # Build the placeholder replacement map.
        [System.Collections.Hashtable]$ReplaceMap = $null
        if (Test-String -IsPopulated $MetaDataFilePath) {
            if (-not (Test-Path -LiteralPath $MetaDataFilePath -PathType Leaf)) {
                throw "The metadata file path does not exist. ($MetaDataFilePath)"
            }
            $ReplaceMap = Get-DocumentReplacementMapFromMetaData -MetaDataFilePath $MetaDataFilePath
        }
        else {
            Write-Line 'No metadata file path supplied. Falling back to UI-based document replacements.' -Type Warning
            $ReplaceMap = Get-DocumentReplacementMap
        }

        # EXECUTION
        # Generate each Word document using the resolved templates.
        [System.Collections.Generic.List[System.String]]$CreatedDocumentPaths = New-Object 'System.Collections.Generic.List[System.String]'
        foreach ($TemplatePath in $ResolvedTemplatePaths) {
            [System.String]$OutputDocName = Get-IntakeOutputDocumentFileName -TemplateFileName ([System.IO.Path]::GetFileName($TemplatePath)) -ApplicationID $ApplicationID
            [System.String]$OutputDocumentPath = Join-Path -Path $DocumentationFolderPath -ChildPath $OutputDocName
            [System.Boolean]$IsTATDoc = ([System.IO.Path]::GetFileNameWithoutExtension($TemplatePath) -match '(?i)\bTAT\b')

            [System.String]$CreatedDoc = New-WordDocumentFromTemplate -TemplatePath $TemplatePath -OutputPath $OutputDocumentPath -ReplaceMap $ReplaceMap -MetaDataFilePath $MetaDataFilePath -IconFolderPath $IconFolderPath -SkipShortcutChapter:$IsTATDoc -PassThru
            if ((Test-String -IsPopulated $CreatedDoc) -and (Test-Path -LiteralPath $CreatedDoc -PathType Leaf)) {
                Write-Line "Succesfully created the WORD DOCUMENT: $OutputDocName for application: $ApplicationID" -Type Success
                [void]$CreatedDocumentPaths.Add($CreatedDoc)
            }
        }

        if ($PassThru) {
            return $CreatedDocumentPaths.ToArray()
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
    Copies the Word template as a fallback working file.
.DESCRIPTION
    Writes a copy of the selected Word template to the documentation folder for later use.
.EXAMPLE
    Copy-ApplicationIntakeTemplateFallback -SourceTemplatePath $Template -DestinationTemplatePath $Target
.INPUTS
    [System.String]
.OUTPUTS
    [System.String] when PassThru is specified and the document is saved; otherwise no objects are returned.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.6.0
    Author          : Imraan Iotana
    Creation Date   : July 2026
    Last Update     : September 2026
#>
####################################################################################################
function Copy-ApplicationIntakeTemplateFallback {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='Resolved source Word template path.')]
        [ValidateNotNullOrEmpty()]
        [System.String]$SourceTemplatePath,

        [Parameter(Mandatory=$true,HelpMessage='Destination path where the template copy will be written.')]
        [ValidateNotNullOrEmpty()]
        [System.String]$DestinationTemplatePath,

        [Parameter(Mandatory=$false,HelpMessage='Optional prefix message before the standard copy status text.')]
        [System.String]$PrefixMessage,

        [Parameter(Mandatory=$false,HelpMessage='Write-Line message type for status output.')]
        [ValidateSet('Info','Warning','Success','Fail')]
        [System.String]$MessageType = 'Info'
    )

    try {
        # VALIDATION
        # Confirm the required paths are present before copying the template.
        if (-not (Test-Path -LiteralPath $SourceTemplatePath -PathType Leaf)) { throw "The source template file does not exist. ($SourceTemplatePath)" }
        if (Test-String -IsEmpty $DestinationTemplatePath) { throw 'The destination template path is empty.' }

        # PREPARATION
        # Ensure the destination folder exists before writing the template copy.
        [System.String]$DestinationDirectory = [System.IO.Path]::GetDirectoryName($DestinationTemplatePath)
        if (-not [System.String]::IsNullOrWhiteSpace($DestinationDirectory) -and -not (Test-Path -LiteralPath $DestinationDirectory -PathType Container)) {
            New-Item -Path $DestinationDirectory -ItemType Directory -Force | Out-Null
        }

        # EXECUTION
        # Copy the Word template for later use.
        Copy-Item -Path $SourceTemplatePath -Destination $DestinationTemplatePath -Force
        [System.String]$Message = "Copied the Word template for later use: $DestinationTemplatePath"
        if (Test-String -IsPopulated $PrefixMessage) {
            $Message = "$PrefixMessage $Message"
        }
        Write-Line $Message -Type $MessageType
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
    Creates a Word document from a template and replaces placeholder text.
.DESCRIPTION
    Opens a Word template as a new document, applies text replacements, and saves the generated output.
.EXAMPLE
    New-WordDocumentFromTemplate -TemplatePath 'C:\Templates\Dossier.dotx' -OutputPath 'C:\Out\Dossier.docx' -ReplaceMap $Map
.INPUTS
    [System.String]
    [System.Collections.Hashtable]
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.6.0
    Author          : Imraan Iotana
    Creation Date   : June 2026
    Last Update     : September 2026
#>
####################################################################################################
function New-WordDocumentFromTemplate {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='Path to the Word template file (.dotx) to use as the base for the new document.')]
        [ValidateNotNullOrEmpty()]
        [System.String]$TemplatePath,

        [Parameter(Mandatory=$true,HelpMessage='Path where the generated Word document (.docx) will be saved.')]
        [ValidateNotNullOrEmpty()]
        [System.String]$OutputPath,

        [Parameter(Mandatory=$true,HelpMessage='Hashtable mapping placeholder text tokens to replacement values.')]
        [ValidateNotNull()]
        [System.Collections.Hashtable]$ReplaceMap,

        [Parameter(Mandatory=$false,HelpMessage='Optional metadata JSON file path used to update the shortcut chapter tables.')]
        [System.String]$MetaDataFilePath,

        [Parameter(Mandatory=$false,HelpMessage='Optional folder containing shortcut PNG files keyed by shortcut name.')]
        [System.String]$IconFolderPath,

        [Parameter(Mandatory=$false,HelpMessage='Skip updating the shortcut chapter in the document.')]
        [System.Management.Automation.SwitchParameter]$SkipShortcutChapter,

        [Parameter(Mandatory=$false,HelpMessage='Return the saved Word document file path.')]
        [System.Management.Automation.SwitchParameter]$PassThru
    )

    [System.Object]$Word = $null
    [System.Object]$Document = $null

    try {
        # VALIDATION
        # Confirm the template exists before starting Word.
        if (-not (Test-Path -LiteralPath $TemplatePath -PathType Leaf)) { throw "Template not found. ($TemplatePath)" }

        # PREPARATION
        # Start Word and load the template into a new document.
        Write-Line "Creating Word document, one moment please..." -Type Busy
        $Word = New-Object -ComObject Word.Application
        $Word.Visible = $false
        $Document = $Word.Documents.Add($TemplatePath)

        # EXECUTION
        # Apply placeholder replacements and optional shortcut updates.
        Update-WordDocument -Document $Document -ReplaceMap $ReplaceMap
        [System.Boolean]$ShouldUpdateShortcuts = (-not $SkipShortcutChapter) -and
            ([System.IO.Path]::GetFileNameWithoutExtension($TemplatePath) -notmatch '(?i)\bTAT\b')
        if ($ShouldUpdateShortcuts -and (Test-String -IsPopulated $MetaDataFilePath) -and (Test-Path -LiteralPath $MetaDataFilePath -PathType Leaf)) {
            Update-WordShortcutChapterFromMetaData -Document $Document -MetaDataFilePath $MetaDataFilePath -InsertShortcutIconImage -IconFolderPath $IconFolderPath
        }

        # EXECUTION
        # Save the generated output document.
        [System.String]$ResolvedOutputPath = [System.IO.Path]::GetFullPath($OutputPath)
        [System.String]$OutputDirectory = [System.IO.Path]::GetDirectoryName($ResolvedOutputPath)
        if (-not (Test-Path -LiteralPath $OutputDirectory -PathType Container)) {
            New-Item -Path $OutputDirectory -ItemType Directory -Force | Out-Null
        }
        $Document.SaveAs2($ResolvedOutputPath)
        if (-not (Test-Path -LiteralPath $ResolvedOutputPath -PathType Leaf)) {
            throw "The Word document was not saved. ($ResolvedOutputPath)"
        }
        if ($PassThru) {
            return $ResolvedOutputPath
        }
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
    finally {
        # POST-EXECUTION
        # Close the document and quit Word, releasing COM objects.
        if ($Document) {
            $Document.Close($false)
            [void][System.Runtime.InteropServices.Marshal]::ReleaseComObject($Document)
        }
        if ($Word) {
            $Word.Quit()
            [void][System.Runtime.InteropServices.Marshal]::ReleaseComObject($Word)
        }
        Remove-Variable Document -ErrorAction SilentlyContinue
        Remove-Variable Word -ErrorAction SilentlyContinue
    }
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Determines the output Word document (.docx) file name from a template file name and Application ID.
.DESCRIPTION
    Replaces [APPLICATIONID] / APPLICATIONID tokens in the template file name with the sanitized
    Application ID, or derives standard output naming for templates named '<Prefix> Dossier'.
.EXAMPLE
    Get-IntakeOutputDocumentFileName -TemplateFileName 'Contoso TAT APPLICATIONID.dotx' -ApplicationID 'Contoso_App_1.0'
.INPUTS
    [System.String]
.OUTPUTS
    [System.String]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.9.0
    Author          : Imraan Iotana
    Creation Date   : September 2026
    Last Update     : October 2026
#>
####################################################################################################
function Get-IntakeOutputDocumentFileName {
    [CmdletBinding()]
    [OutputType([System.String])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The template file name.')]
        [ValidateNotNullOrEmpty()]
        [System.String]$TemplateFileName,

        [Parameter(Mandatory=$true,HelpMessage='The Application ID used for output document naming.')]
        [ValidateNotNullOrEmpty()]
        [System.String]$ApplicationID
    )

    [System.String]$SafeApplicationID = $ApplicationID
    foreach ($InvalidChar in [System.IO.Path]::GetInvalidFileNameChars()) {
        $SafeApplicationID = $SafeApplicationID.Replace($InvalidChar, '_')
    }

    [System.String]$BaseName = [System.IO.Path]::GetFileNameWithoutExtension($TemplateFileName)
    if ($BaseName -match '(?i)APPLICATIONID') {
        return ($BaseName -replace '(?i)APPLICATIONID', $SafeApplicationID) + '.docx'
    }
    if ($BaseName -match '^(?i)(?<Prefix>.+?) Dossier\b') {
        return $Matches['Prefix'] + ' Dossier ' + $SafeApplicationID + '.docx'
    }
    return $BaseName + ' ' + $SafeApplicationID + '.docx'
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Builds the placeholder-to-value map from a metadata JSON file.
.DESCRIPTION
    Reads metadata and maps supported Word placeholder tokens to metadata values.
.EXAMPLE
    Get-DocumentReplacementMapFromMetaData -MetaDataFilePath 'C:\Temp\Metadata_App.json'
.INPUTS
    [System.String]
.OUTPUTS
    [System.Collections.Hashtable]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.6.0
    Author          : Imraan Iotana
    Creation Date   : July 2026
    Last Update     : September 2026
#>
####################################################################################################
function Get-DocumentReplacementMapFromMetaData {
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='Path to the metadata JSON file produced by New-MetaDataFile.')]
        [ValidateNotNullOrEmpty()]
        [System.String]$MetaDataFilePath
    )

    try {
        # VALIDATION
        # Confirm the metadata file exists before attempting to read document values.
        if (-not (Test-Path -LiteralPath $MetaDataFilePath -PathType Leaf)) { throw "Metadata file not found. ($MetaDataFilePath)" }

        # PREPARATION
        # Load metadata and resolve the document bitness value.
        [System.String]$MetaDataJson = Get-Content -LiteralPath $MetaDataFilePath -Raw
        [PSCustomObject]$MetaData = $MetaDataJson | ConvertFrom-Json
        [System.String]$DetectionFilePath = if ($null -ne $MetaData.DetectionFile) { [System.String]$MetaData.DetectionFile } else { '' }
        [System.String]$ResolvedDetectionFilePath = Resolve-PrivacySafePath -Path $DetectionFilePath
        [System.String]$BitnessForDocument = ''
        if ((Test-String -IsPopulated $ResolvedDetectionFilePath) -and (Test-Path -LiteralPath $ResolvedDetectionFilePath -PathType Leaf)) {
            try {
                $BitnessForDocument = Get-FileBitness -Path $ResolvedDetectionFilePath -ForDocument
            }
            catch {
                $BitnessForDocument = ''
            }
        }
        if (Test-String -IsEmpty $BitnessForDocument) {
            [System.String]$StoredBitness = if ($null -ne $MetaData.Bitness) { [System.String]$MetaData.Bitness } else { '' }
            # Append the detection file sentence from the stored path even when that path cannot be reached from this computer (e.g. it is a target install path).
            if ((Test-String -IsPopulated $StoredBitness) -and (Test-String -IsPopulated $DetectionFilePath) -and $StoredBitness -notmatch '\(Based on detection file:') {
                $BitnessForDocument = "{0}{1}(Based on detection file: {2})" -f $StoredBitness, [char]11, $DetectionFilePath
            }
            else {
                $BitnessForDocument = $StoredBitness
            }
        }

        # EXECUTION
        # Build the replacement map for the supported Word placeholders.
        [System.String]$ApplicationID = if ($null -ne $MetaData.ApplicationID) { [System.String]$MetaData.ApplicationID } else { '' }

        return @{
            '[APPLICATIONID]'            = $ApplicationID
            '[FORMALVENDORNAME]'         = if ($null -ne $MetaData.FormalVendorName) { [System.String]$MetaData.FormalVendorName } else { '' }
            '[FORMALAPPLICATIONNAME]'    = if ($null -ne $MetaData.FormalApplicationName) { [System.String]$MetaData.FormalApplicationName } else { '' }
            '[FORMALAPPLICATIONVERSION]' = if ($null -ne $MetaData.FormalApplicationVersion) { [System.String]$MetaData.FormalApplicationVersion } else { '' }
            '[CUSTOMVENDORNAME]'         = if ($null -ne $MetaData.CustomVendorName) { [System.String]$MetaData.CustomVendorName } else { '' }
            '[CUSTOMAPPLICATIONNAME]'    = if ($null -ne $MetaData.CustomApplicationName) { [System.String]$MetaData.CustomApplicationName } else { '' }
            '[CUSTOMAPPLICATIONVERSION]' = if ($null -ne $MetaData.CustomApplicationVersion) { [System.String]$MetaData.CustomApplicationVersion } else { '' }
            '[INSTALLATIONFOLDER]'       = if ($null -ne $MetaData.InstallationFolder) { [System.String]$MetaData.InstallationFolder } else { '' }
            '[BITNESS]'                  = $BitnessForDocument
            '[USERFULLNAME]'             = if ($null -ne $MetaData.UserFullName) { [System.String]$MetaData.UserFullName } else { '' }
            '[USEREMAILADDRESS]'         = if ($null -ne $MetaData.UserEmailAddress) { [System.String]$MetaData.UserEmailAddress } else { '' }
        }
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
        return @{ }
    }
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Generates a Word document from an explicit template and metadata JSON file.
.DESCRIPTION
    Validates the supplied inputs, builds placeholder replacements from metadata, invokes Word
    automation, and verifies the generated output document.
.EXAMPLE
    Invoke-DocumentGeneration -WordTemplatePath 'C:\Temp\Template.dotx' -MetaDataJsonPath 'C:\Temp\Metadata.json'
.INPUTS
    [System.String]
.OUTPUTS
    [System.Boolean]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.6.0
    Author          : Imraan Iotana
    Creation Date   : September 2026
    Last Update     : September 2026
#>
####################################################################################################
function Invoke-DocumentGeneration {
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The selected Word template path.')]
        [AllowNull()][AllowEmptyString()]
        [System.String]$WordTemplatePath,

        [Parameter(Mandatory=$true,HelpMessage='The selected metadata JSON path.')]
        [AllowNull()][AllowEmptyString()]
        [System.String]$MetaDataJsonPath,

        [Parameter(Mandatory=$false,HelpMessage='Optional folder containing shortcut PNG files keyed by shortcut name.')]
        [System.String]$IconFolderPath,

        [Parameter(Mandatory=$false,HelpMessage='Optional folder where the generated document is written.')]
        [System.String]$OutputFolder,

        [Parameter(Mandatory=$false,HelpMessage='Open the output folder after export.')]
        [System.Management.Automation.SwitchParameter]$OpenOutputFolder
    )

    try {
        Write-Line 'Starting document generation...' -Type Info

        if (-not (Confirm-DocumentGenerationInput -WordTemplatePath $WordTemplatePath -MetaDataJsonPath $MetaDataJsonPath -IconFolderPath $IconFolderPath)) {
            Write-Line 'Document generation cancelled because input validation failed.' -Type Warning
            return $false
        }

        if ($null -eq [System.Type]::GetTypeFromProgID('Word.Application')) {
            Write-Line 'Microsoft Word is not installed or not registered on this computer.' -Type Warning
            return $false
        }

        Write-Line 'Building document replacement values from metadata JSON...' -Type Info
        [System.Collections.Hashtable]$ReplaceMap = Get-DocumentReplacementMapFromMetaData -MetaDataFilePath $MetaDataJsonPath
        if ($null -eq $ReplaceMap -or $ReplaceMap.Count -le 0) {
            Write-Line 'No replacement values were found in the metadata JSON file.' -Type Warning
            return $false
        }

        if (Test-String -IsEmpty $OutputFolder) {
            $OutputFolder = Get-Folder -OutputFolder
        }
        if ((Test-String -IsEmpty $OutputFolder) -or (-not (Test-Path -LiteralPath $OutputFolder -PathType Container))) {
            Write-Line "The document output folder does not exist. ($OutputFolder)" -Type Warning
            return $false
        }

        [System.String]$ApplicationID = ''
        try {
            [System.String]$MetaDataJson = Get-Content -LiteralPath $MetaDataJsonPath -Raw
            [PSCustomObject]$MetaDataObject = $MetaDataJson | ConvertFrom-Json
            if ($null -ne $MetaDataObject -and $null -ne $MetaDataObject.ApplicationID) {
                $ApplicationID = [System.String]$MetaDataObject.ApplicationID
            }
        }
        catch {
            $ApplicationID = ''
        }

        [System.String]$OutputDocumentName = ''
        if (Test-String -IsPopulated $ApplicationID) {
            $OutputDocumentName = Get-IntakeOutputDocumentFileName -TemplateFileName ([System.IO.Path]::GetFileName($WordTemplatePath)) -ApplicationID $ApplicationID
        }
        else {
            [System.String]$TemplateName = [System.IO.Path]::GetFileNameWithoutExtension($WordTemplatePath)
            $OutputDocumentName = $TemplateName + '_Generated.docx'
        }

        [System.String]$OutputDocumentPath = Join-Path -Path $OutputFolder -ChildPath $OutputDocumentName
        [System.Boolean]$IsTATDoc = ([System.IO.Path]::GetFileNameWithoutExtension($WordTemplatePath) -match '(?i)\bTAT\b')
        New-WordDocumentFromTemplate -TemplatePath $WordTemplatePath -OutputPath $OutputDocumentPath -ReplaceMap $ReplaceMap -MetaDataFilePath $MetaDataJsonPath -IconFolderPath $IconFolderPath -SkipShortcutChapter:$IsTATDoc

        if (Test-Path -LiteralPath $OutputDocumentPath -PathType Leaf) {
            Write-Line "Document generated successfully: $OutputDocumentPath" -Type Success
            if ($OpenOutputFolder) {
                Open-Folder -Path $OutputDocumentPath
            }
            return $true
        }

        Write-Line 'Document generation finished, but the output file could not be confirmed.' -Type Warning
        return $false
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
    Resolves privacy-safe metadata path tokens to real environment paths.
.DESCRIPTION
    Converts known metadata tokens such as [LOCALAPPDATA], [APPDATA], and [USERPROFILE] back into absolute paths.
.EXAMPLE
    Resolve-PrivacySafePath -Path '[LOCALAPPDATA]\Programs\Vendor\App.exe'
.INPUTS
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
function Resolve-PrivacySafePath {
    [CmdletBinding()]
    [OutputType([System.String])]
    param (
        [Parameter(Mandatory=$false,HelpMessage='Path value that may include metadata privacy tokens.')]
        [System.String]$Path
    )

    try {
        # PREPARATION
        # Return the original value if no path was supplied for resolution.
        if (Test-String -IsEmpty $Path) {
            return $Path
        }

        # PREPARATION
        # Normalize the input path and gather the environment roots.
        [System.String]$NormalizedPath = ([System.String]$Path).Trim().Trim('"','''') -replace '/','\\'
        [System.String]$LocalAppDataRoot = [System.String]$env:LOCALAPPDATA
        [System.String]$AppDataRoot = [System.String]$env:APPDATA
        [System.String]$UserProfileRoot = [System.String]$env:USERPROFILE

        if (Test-String -IsEmpty $LocalAppDataRoot) { $LocalAppDataRoot = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::LocalApplicationData) }
        if (Test-String -IsEmpty $AppDataRoot) { $AppDataRoot = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::ApplicationData) }
        if (Test-String -IsEmpty $UserProfileRoot) { $UserProfileRoot = [System.String][System.Environment]::GetEnvironmentVariable('USERPROFILE','Process') }
        if (Test-String -IsEmpty $UserProfileRoot) { $UserProfileRoot = [System.String][System.Environment]::GetEnvironmentVariable('USERPROFILE','User') }

        [System.Collections.Hashtable[]]$TokenMap = @(
            @{ Token = '[LOCALAPPDATA]'; Value = $LocalAppDataRoot }
            @{ Token = '[APPDATA]';      Value = $AppDataRoot }
            @{ Token = '[USERPROFILE]';  Value = $UserProfileRoot }
        )

        # EXECUTION
        # Replace known privacy-safe path tokens with their environment-backed values.
        foreach ($TokenEntry in $TokenMap) {
            [System.String]$Token = [System.String]$TokenEntry.Token
            [System.String]$Value = [System.String]$TokenEntry.Value
            if (Test-String -IsEmpty $Value) { continue }
            if ($NormalizedPath.Equals($Token,[System.StringComparison]::OrdinalIgnoreCase)) { return $Value }
            [System.String]$TokenPrefix = "$Token\\"
            if ($NormalizedPath.StartsWith($TokenPrefix,[System.StringComparison]::OrdinalIgnoreCase)) {
                [System.String]$RelativePath = $NormalizedPath.Substring($TokenPrefix.Length)
                return (Join-Path -Path $Value -ChildPath $RelativePath)
            }
        }

        return $Path
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
        return $Path
    }
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Builds the placeholder-to-value map for Word document replacement.
.DESCRIPTION
    Returns a hashtable that maps the supported document placeholder tokens to the current UI values.
.EXAMPLE
    Get-DocumentReplacementMap
.INPUTS
    None.
.OUTPUTS
    [System.Collections.Hashtable]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.6.0
    Author          : Imraan Iotana
    Creation Date   : June 2026
    Last Update     : September 2026
#>
####################################################################################################
function Get-DocumentReplacementMap {
    try {
        # PREPARATION
        # Gather the current textbox values that back the document placeholders.
        [System.String]$ApplicationID = Get-ResolvedTextBoxText -TextBoxName 'ApplicationID'
        if (Test-String -IsEmpty $ApplicationID) {
            [System.Windows.Forms.TextBox]$ApplicationIDTextBox = Get-IntakeApplicationIDTextBox
            if ($null -ne $ApplicationIDTextBox) {
                $ApplicationID = [System.String]$ApplicationIDTextBox.Text
            }
        }
        [System.String]$FormalVendorName = Get-ResolvedTextBoxText -TextBoxName 'FormalVendorName'
        [System.String]$FormalApplicationName = Get-ResolvedTextBoxText -TextBoxName 'FormalApplicationName'
        [System.String]$FormalApplicationVersion = Get-ResolvedTextBoxText -TextBoxName 'FormalApplicationVersion'
        [System.String]$CustomVendorName = Get-ResolvedTextBoxText -TextBoxName 'CustomVendorName'
        [System.String]$CustomApplicationName = Get-ResolvedTextBoxText -TextBoxName 'CustomApplicationName'
        [System.String]$CustomApplicationVersion = Get-ResolvedTextBoxText -TextBoxName 'CustomApplicationVersion'
        [System.String]$InstallationFolder = Get-ResolvedTextBoxText -TextBoxName 'InstallationFolder' -SectionKeys @('Security')
        [System.String]$DetectionPath = Get-ResolvedTextBoxText -TextBoxName 'DetectionfileMSI' -SectionKeys @('Detection')
        [System.String[]]$DocumentInfoRoots = @('applicationsettings.generalsettings')
        [System.String]$UserFullName = Get-ResolvedTextBoxText -TextBoxName 'UserFullName' -PreferredRootKeys $DocumentInfoRoots -SectionKeys @('ExtraDocumentInformation')
        [System.String]$UserEmailAddress = Get-ResolvedTextBoxText -TextBoxName 'UserEmailAddress' -PreferredRootKeys $DocumentInfoRoots -SectionKeys @('ExtraDocumentInformation')

        # PREPARATION
        # Resolve the current intake textbox values.
        [System.String]$Bitness = ''
        if (-not [System.String]::IsNullOrWhiteSpace($DetectionPath)) {
            try { $Bitness = Get-FileBitness -Path $DetectionPath -ForDocument }
            catch { $Bitness = '' }
        }

        # EXECUTION
        # Return the placeholder replacement map for Word document generation.
        return @{
            '[APPLICATIONID]'            = $ApplicationID
            '[FORMALVENDORNAME]'         = $FormalVendorName
            '[FORMALAPPLICATIONNAME]'    = $FormalApplicationName
            '[FORMALAPPLICATIONVERSION]' = $FormalApplicationVersion
            '[CUSTOMVENDORNAME]'         = $CustomVendorName
            '[CUSTOMAPPLICATIONNAME]'    = $CustomApplicationName
            '[CUSTOMAPPLICATIONVERSION]' = $CustomApplicationVersion
            '[INSTALLATIONFOLDER]'       = $InstallationFolder
            '[BITNESS]'                  = $Bitness
            '[USERFULLNAME]'             = $UserFullName
            '[USEREMAILADDRESS]'         = $UserEmailAddress
        }
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
        return @{ }
    }
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Updates a Word document by replacing placeholder text values.
.DESCRIPTION
    Uses a supplied replacement map to perform Find/Replace operations over the whole document body.
.EXAMPLE
    Update-WordDocument -Document $Document -ReplaceMap $ReplaceMap
.INPUTS
    [System.Object]
    [System.Collections.Hashtable]
.OUTPUTS
    No objects are returned to the pipeline. The Word document is modified in place.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.2
    Author          : Imraan Iotana
    Creation Date   : June 2026
    Last Update     : July 2026
#>
####################################################################################################
function Update-WordDocument {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The Word document object to update.')]
        [System.Object]$Document,

        [Parameter(Mandatory=$true,HelpMessage='Hashtable mapping placeholder text tokens to their replacement values.')]
        [System.Collections.Hashtable]$ReplaceMap
    )

    try {
        # VALIDATION
        # Confirm the Word document object and replacement map are available.
        if ($null -eq $Document) { throw 'The Word document object is null.' }
        if ($null -eq $ReplaceMap) { throw 'The replacement map is null.' }

        # PREPARATION
        # Prepare the Word find/replace settings for each placeholder token.
        foreach ($Key in $ReplaceMap.Keys) {
            [System.Object]$Find = $Document.Content.Find
            [void]$Find.ClearFormatting()
            [void]$Find.Replacement.ClearFormatting()

            # EXECUTION
            # Apply each placeholder replacement across the document.
            [void]$Find.Execute(
                [ref]$Key,
                [ref]$false,
                [ref]$false,
                [ref]$false,
                [ref]$false,
                [ref]$false,
                [ref]$true,
                [ref]1,
                [ref]$false,
                [ref]$ReplaceMap[$Key],
                [ref]2
            )
        }
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}

### END OF FUNCTION
####################################################################################################
