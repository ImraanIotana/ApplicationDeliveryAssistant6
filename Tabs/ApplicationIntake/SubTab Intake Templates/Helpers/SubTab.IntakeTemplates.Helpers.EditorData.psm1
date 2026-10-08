####################################################################################################
<#
.SYNOPSIS
    Provides editable Customer Template models and transactional persistence.
.DESCRIPTION
    Loads user-owned Schema 2 manifests and components into mutable dictionaries, serializes PSD1
    content, and publishes complete validated template bundles.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.6.0
    Author          : Imraan Iotana
    Creation Date   : August 2026
    Last Update     : September 2026
#>
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Creates an editable model for a user-owned customer template.
.DESCRIPTION
    Validates a discovered Schema 2 template, imports its manifest and required components, and
    returns mutable dictionaries used by the Customer Template editor.
.EXAMPLE
    Get-CustomerTemplateEditorModel -CustomerTemplate $CustomerTemplate
.INPUTS
    [System.Object]
.OUTPUTS
    [PSCustomObject]
#>
####################################################################################################
function Get-CustomerTemplateEditorModel {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory=$true)]
        [System.Object]$CustomerTemplate
    )

    # VALIDATION - TEMPLATE OWNERSHIP
    # Only roaming user templates may be changed by the editor.
    if (($CustomerTemplate.Source -ne 'User') -or [System.Boolean]$CustomerTemplate.IsReadOnly) {
        throw 'Built-in customer templates are read-only. Make a copy before editing.'
    }
    if (-not (Test-Path -LiteralPath ([System.String]$CustomerTemplate.TemplatePath) -PathType Leaf)) {
        throw "The customer template manifest could not be found: $($CustomerTemplate.TemplatePath)"
    }

    # VALIDATION - SCHEMA 2 MANIFEST
    # Require an editable component manifest rather than a pre-6.2 flat template.
    [System.Collections.Hashtable]$Manifest = Import-PowerShellDataFile -LiteralPath ([System.String]$CustomerTemplate.TemplatePath)
    if ((-not $Manifest.ContainsKey('SchemaVersion')) -or ([System.Int32]$Manifest.SchemaVersion -ne 2) -or (-not $Manifest.ContainsKey('Components')) -or ($Manifest.Components -isnot [System.Collections.IDictionary])) {
        throw 'Only user-owned Schema 2 customer templates can be edited.'
    }

    # PREPARATION - COMPONENT DATA
    # Import every required component while enforcing the template directory boundary.
    [System.String]$TemplateDirectory = [System.IO.Path]::GetFullPath([System.String]$CustomerTemplate.Directory)
    [System.Collections.Hashtable]$ComponentData = @{}
    foreach ($ComponentName in @('ApplicationFolderSubFolders','AppLockerDefaultSettings','MailTemplates')) {
        if (-not $Manifest.Components.Contains($ComponentName)) {
            throw "The Schema 2 manifest does not define the $ComponentName component."
        }

        [System.String]$RelativePath = [System.String]$Manifest.Components[$ComponentName]
        [System.String]$ComponentPath = [System.IO.Path]::GetFullPath((Join-Path -Path $TemplateDirectory -ChildPath $RelativePath))
        [System.String]$DirectoryPrefix = $TemplateDirectory.TrimEnd([System.IO.Path]::DirectorySeparatorChar) + [System.IO.Path]::DirectorySeparatorChar
        if (-not $ComponentPath.StartsWith($DirectoryPrefix,[System.StringComparison]::OrdinalIgnoreCase)) {
            throw "The component path leaves the customer template directory: $RelativePath"
        }
        $ComponentData[$ComponentName] = Import-PowerShellDataFile -LiteralPath $ComponentPath
    }

    # OUTPUT
    # Return one mutable model shared by all editor tabs and the transactional save operation.
    return [PSCustomObject]@{
        CustomerTemplate             = $CustomerTemplate
        TemplateDirectory            = $TemplateDirectory
        ManifestRelativePath         = [System.IO.Path]::GetFileName([System.String]$CustomerTemplate.TemplatePath)
        Manifest                     = $Manifest
        ApplicationFolderSubFolders  = [System.Collections.Hashtable]$ComponentData.ApplicationFolderSubFolders
        AppLockerDefaultSettings     = [System.Collections.Hashtable]$ComponentData.AppLockerDefaultSettings
        MailTemplates                = [System.Collections.Hashtable]$ComponentData.MailTemplates
    }
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Converts a dictionary key to valid PSD1 key text.
.DESCRIPTION
    Leaves identifier-safe keys unquoted and single-quotes all other keys with embedded quotes
    escaped for PowerShell data-file syntax.
.EXAMPLE
    ConvertTo-CustomerTemplatePsd1KeyText -Key 'Mail Template 1'
.INPUTS
    [System.String]
.OUTPUTS
    [System.String]
#>
####################################################################################################
function ConvertTo-CustomerTemplatePsd1KeyText {
    [CmdletBinding()]
    [OutputType([System.String])]
    param ([Parameter(Mandatory=$true)][System.String]$Key)

    # OUTPUT
    # Quote only keys that cannot be represented as bare PowerShell identifiers.
    if ($Key -match '^[A-Za-z_][A-Za-z0-9_]*$') { return $Key }
    return "'$($Key.Replace("'", "''"))'"
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Serializes a value into formatted PSD1 lines.
.DESCRIPTION
    Recursively converts nulls, booleans, numbers, dictionaries, collections, and strings into
    deterministic PowerShell data-file syntax with optional preferred dictionary key ordering.
.EXAMPLE
    ConvertTo-CustomerTemplatePsd1ValueLines -Value $TemplateData -PreferredKeyOrder @('Identity')
.INPUTS
    [System.Object]
.OUTPUTS
    [System.String[]]
#>
####################################################################################################
function ConvertTo-CustomerTemplatePsd1ValueLines {
    [CmdletBinding()]
    [OutputType([System.String[]])]
    param (
        [Parameter(Mandatory=$false)][AllowNull()][System.Object]$Value,
        [Parameter(Mandatory=$false)][System.Int32]$IndentLevel = 0,
        [Parameter(Mandatory=$false)][System.String[]]$PreferredKeyOrder
    )

    # PREPARATION - VALUE TYPE
    # Resolve indentation once before dispatching to the appropriate PSD1 representation.
    [System.String]$Indent = ' ' * ($IndentLevel * 4)
    if ($null -eq $Value) { return @("${Indent}`$null") }
    if ($Value -is [System.Boolean]) { return @("${Indent}`$$($Value.ToString().ToLowerInvariant())") }
    if (($Value -is [System.Byte]) -or ($Value -is [System.Int16]) -or ($Value -is [System.Int32]) -or ($Value -is [System.Int64]) -or ($Value -is [System.Decimal]) -or ($Value -is [System.Double])) {
        return @("$Indent$Value")
    }
    # EXECUTION - DICTIONARY
    # Preserve preferred keys first and recursively serialize nested values.
    if ($Value -is [System.Collections.IDictionary]) {
        [System.Collections.Generic.List[System.String]]$Lines = New-Object 'System.Collections.Generic.List[System.String]'
        $Lines.Add("${Indent}@{") | Out-Null
        [System.Collections.Generic.List[System.String]]$Keys = New-Object 'System.Collections.Generic.List[System.String]'
        foreach ($PreferredKey in @($PreferredKeyOrder)) {
            if ($Value.Contains($PreferredKey) -and (-not $Keys.Contains([System.String]$PreferredKey))) { $Keys.Add([System.String]$PreferredKey) | Out-Null }
        }
        foreach ($Key in $Value.Keys) {
            if (-not $Keys.Contains([System.String]$Key)) { $Keys.Add([System.String]$Key) | Out-Null }
        }
        foreach ($Key in $Keys) {
            [System.String]$KeyText = ConvertTo-CustomerTemplatePsd1KeyText -Key $Key
            [System.String[]]$ValueLines = @(ConvertTo-CustomerTemplatePsd1ValueLines -Value $Value[$Key] -IndentLevel ($IndentLevel + 1))
            [System.String]$EntryIndent = ' ' * (($IndentLevel + 1) * 4)
            if ($ValueLines.Count -eq 1) {
                $Lines.Add("$EntryIndent$KeyText = $($ValueLines[0].TrimStart())") | Out-Null
            }
            else {
                $Lines.Add("$EntryIndent$KeyText = $($ValueLines[0].TrimStart())") | Out-Null
                for ($LineIndex = 1; $LineIndex -lt $ValueLines.Count; $LineIndex++) { $Lines.Add($ValueLines[$LineIndex]) | Out-Null }
            }
        }
        $Lines.Add("${Indent}}") | Out-Null
        return $Lines.ToArray()
    }
    # EXECUTION - COLLECTION
    # Serialize non-string enumerables as PowerShell array literals.
    if (($Value -is [System.Collections.IEnumerable]) -and ($Value -isnot [System.String])) {
        [System.String[]]$Items = @($Value | ForEach-Object { (ConvertTo-CustomerTemplatePsd1ValueLines -Value $_ -IndentLevel 0)[0].Trim() })
        return @("${Indent}@($($Items -join ', '))")
    }

    # OUTPUT - STRING
    # Use a single-quoted literal and escape embedded single quotes.
    [System.String]$StringValue = [System.String]$Value
    return @("$Indent'$($StringValue.Replace("'", "''"))'")
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Writes a dictionary to a PowerShell data file.
.DESCRIPTION
    Serializes customer template data with deterministic formatting and writes UTF-8 without a
    byte-order mark so edited manifests remain compatible with Windows PowerShell 5.1.
.EXAMPLE
    Write-CustomerTemplatePsd1File -Path $Path -Data $TemplateData
.INPUTS
    [System.String]
    [System.Collections.IDictionary]
.OUTPUTS
    No objects are returned to the pipeline.
#>
####################################################################################################
function Write-CustomerTemplatePsd1File {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)][System.String]$Path,
        [Parameter(Mandatory=$true)][System.Collections.IDictionary]$Data,
        [Parameter(Mandatory=$false)][System.String[]]$PreferredKeyOrder
    )

    # PREPARATION - SERIALIZED CONTENT
    # Produce stable line endings and a trailing newline for the complete PSD1 document.
    [System.String[]]$Lines = @(ConvertTo-CustomerTemplatePsd1ValueLines -Value $Data -PreferredKeyOrder $PreferredKeyOrder)
    [System.String]$Text = ($Lines -join [System.Environment]::NewLine) + [System.Environment]::NewLine
    [System.Text.UTF8Encoding]$Utf8WithoutBom = New-Object System.Text.UTF8Encoding($false)
    # EXECUTION - FILE WRITE
    [System.IO.File]::WriteAllText($Path,$Text,$Utf8WithoutBom)
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Saves an edited customer template transactionally.
.DESCRIPTION
    Writes the manifest and all three components into a staged directory, validates the normalized
    Schema 2 bundle, and publishes it through the shared validated directory update helper.
.EXAMPLE
    Save-CustomerTemplateEditorModel -EditorModel $EditorModel
.INPUTS
    [PSCustomObject]
.OUTPUTS
    [System.Boolean]
#>
####################################################################################################
function Save-CustomerTemplateEditorModel {
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param (
        [Parameter(Mandatory=$true)][PSCustomObject]$EditorModel
    )

    # PREPARATION - TARGET PATHS
    [System.String]$TemplateDirectory = [System.String]$EditorModel.TemplateDirectory
    [System.String]$ManifestRelativePath = [System.String]$EditorModel.ManifestRelativePath

    # EXECUTION - TRANSACTIONAL UPDATE
    # Write all bundle files to staging before any live template content is replaced.
    return (Invoke-ValidatedDirectoryUpdate -DirectoryPath $TemplateDirectory -UpdateAction {
        param([System.String]$StagingDirectory)

        [System.String]$ManifestPath = Join-Path -Path $StagingDirectory -ChildPath $ManifestRelativePath
        Write-CustomerTemplatePsd1File -Path $ManifestPath -Data $EditorModel.Manifest -PreferredKeyOrder @('SchemaVersion','TemplateId','Identity','TemplateName','TatTemplateName','UDFName','Components')
        Write-CustomerTemplatePsd1File -Path (Join-Path $StagingDirectory ([System.String]$EditorModel.Manifest.Components.ApplicationFolderSubFolders)) -Data $EditorModel.ApplicationFolderSubFolders
        Write-CustomerTemplatePsd1File -Path (Join-Path $StagingDirectory ([System.String]$EditorModel.Manifest.Components.AppLockerDefaultSettings)) -Data $EditorModel.AppLockerDefaultSettings
        Write-CustomerTemplatePsd1File -Path (Join-Path $StagingDirectory ([System.String]$EditorModel.Manifest.Components.MailTemplates)) -Data $EditorModel.MailTemplates
    }.GetNewClosure() -ValidationAction {
        param([System.String]$StagingDirectory)

        # VALIDATION - STAGED BUNDLE
        # Re-import the staged manifest through the production normalizer before publication.
        [System.String]$StagedManifestPath = Join-Path -Path $StagingDirectory -ChildPath $ManifestRelativePath
        [System.Collections.Hashtable]$ValidatedData = Import-CustomerTemplateData -SettingsFilePath $StagedManifestPath
        if (([System.Int32]$ValidatedData.SchemaVersion -ne 2) -or ([System.String]::IsNullOrWhiteSpace([System.String]$ValidatedData.Identity))) {
            throw 'The staged customer template failed Schema 2 validation.'
        }
    }.GetNewClosure())
}

### END OF FUNCTION
####################################################################################################
