function Test-UDFDeploymentObjectOrderMatchesSourceBlocks {
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The ListView containing current deployment object rows.')]
        [System.Windows.Forms.ListView]$SourceListView
    )

    try {
        [System.Int32]$PreviousStartLine = -1

        foreach ($SourceItem in $SourceListView.Items) {
            [PSCustomObject]$ItemEntry = Get-UDFDeploymentObjectItemEntry -SourceItem $SourceItem
            [PSCustomObject]$SourceBlock = [PSCustomObject]$ItemEntry.SourceBlock

            # Without source metadata we cannot validate ordering; allow patch mode.
            if (($null -eq $SourceBlock) -or ($null -eq $SourceBlock.PSObject.Properties['StartLine'])) {
                continue
            }

            [System.Int32]$CurrentStartLine = [System.Int32]$SourceBlock.StartLine
            if (($PreviousStartLine -ge 0) -and ($CurrentStartLine -lt $PreviousStartLine)) {
                return $false
            }

            $PreviousStartLine = $CurrentStartLine
        }

        return $true
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
        return $true
    }
}

### END OF FUNCTION
####################################################################################################


function Get-UDFPatchedDeploymentObjectBlockData {
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSCustomObject])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The deployment object ListView item to patch.')]
        [System.Windows.Forms.ListViewItem]$SourceItem,

        [Parameter(Mandatory=$true,HelpMessage='The full template file lines.')]
        [AllowEmptyString()]
        [System.String[]]$TemplateLines
    )

    [PSCustomObject]$ItemEntry = Get-UDFDeploymentObjectItemEntry -SourceItem $SourceItem
    [System.Collections.Hashtable]$DeploymentObject = [System.Collections.Hashtable]$ItemEntry.DeploymentObject
    [PSCustomObject]$SourceBlock = [PSCustomObject]$ItemEntry.SourceBlock

    # VALIDATION - SOURCE BLOCK
    # Stop patch-mode when required source metadata is missing.
    if (($null -eq $DeploymentObject) -or ($null -eq $SourceBlock) -or ($SourceBlock.StartLine -lt 1) -or ($SourceBlock.EndLine -lt $SourceBlock.StartLine)) {
        return $null
    }

    # PREPARATION - BLOCK RANGE
    # Convert 1-based source line numbers to zero-based array indexes.
    [System.Int32]$StartIndex = ($SourceBlock.StartLine - 1)
    [System.Int32]$EndIndex = ($SourceBlock.EndLine - 1)
    if (($StartIndex -lt 0) -or ($EndIndex -ge $TemplateLines.Count)) {
        return $null
    }

    # PREPARATION - COMMENT ALIGNMENT
    # Detect widest inline-comment column to preserve visual alignment.
    [System.String[]]$BlockLines = @($TemplateLines[$StartIndex..$EndIndex])
    [System.Collections.Generic.List[System.String]]$PatchedBlockLines = New-Object 'System.Collections.Generic.List[System.String]'
    [System.Int32]$TargetCommentColumn = -1

    foreach ($BlockLine in $BlockLines) {
        [System.Int32]$CommentIndex = $BlockLine.IndexOf('#')
        if ($CommentIndex -ge 0) {
            if ($CommentIndex -gt $TargetCommentColumn) {
                $TargetCommentColumn = $CommentIndex
            }
        }
    }

    # EXECUTION - PATCH BLOCK LINES
    # Rewrite only recognized key/value lines that still exist on the object.
    foreach ($BlockLine in $BlockLines) {
        if ($BlockLine -match '^(?<indent>\s*)(?<key>[A-Za-z_][A-Za-z0-9_]*)(?<beforeEq>\s*=\s*)(?<value>.*?)(?<suffix>\s*(#.*)?)$') {
            [System.String]$KeyName = [System.String]$Matches['key']
            if ($DeploymentObject.ContainsKey($KeyName)) {
                [System.String]$NewValueText = Convert-UDFDeploymentObjectValueToPsd1InlineText -Value $DeploymentObject[$KeyName]
                [System.String]$PrefixText = "$($Matches['indent'])$KeyName$($Matches['beforeEq'])$NewValueText"
                [System.String]$SuffixText = [System.String]$Matches['suffix']

                if (($TargetCommentColumn -ge 0) -and ($SuffixText -match '(?<leading>\s*)(?<comment>#.*)$')) {
                    [System.String]$CommentText = [System.String]$Matches['comment']
                    [System.Int32]$PaddingLength = [System.Math]::Max(1, ($TargetCommentColumn - $PrefixText.Length))
                    $PatchedBlockLines.Add($PrefixText + (' ' * $PaddingLength) + $CommentText) | Out-Null
                }
                else {
                    $PatchedBlockLines.Add($PrefixText + $SuffixText) | Out-Null
                }

                continue
            }
        }

        $PatchedBlockLines.Add($BlockLine) | Out-Null
    }

    if ($PatchedBlockLines.Count -ne $BlockLines.Count) {
        return $null
    }

    return [PSCustomObject]@{
        StartIndex        = $StartIndex
        EndIndex          = $EndIndex
        PatchedBlockLines = $PatchedBlockLines.ToArray()
    }
}

### END OF FUNCTION
####################################################################################################


function Get-UDFPatchedTemplateLines {
    [CmdletBinding()]
    [OutputType([System.String[]])]
    param (
        [Parameter(Mandatory=$false,HelpMessage='The original DeploymentData.psd1 file used as a patch template.')]
        [AllowEmptyString()]
        [System.String]$TemplateFilePath,

        [Parameter(Mandatory=$true,HelpMessage='The ListView containing current deployment objects.')]
        [System.Windows.Forms.ListView]$SourceListView,

        [Parameter(Mandatory=$false,HelpMessage='Main property values to apply.')]
        [System.Collections.Hashtable]$MainPropertiesToSave
    )

    # VALIDATION - TEMPLATE PATH
    # Patching requires a readable template file path.
    if ((Test-String -IsEmpty $TemplateFilePath) -or (-not (Test-Path -Path $TemplateFilePath -PathType Leaf))) {
        return $null
    }

    # PREPARATION - TEMPLATE CONTENT
    # Load full file content once for in-memory patching.
    [System.String[]]$TemplateLines = Get-Content -LiteralPath $TemplateFilePath -ErrorAction Stop
    if ($TemplateLines.Count -lt 1) {
        return $null
    }

    # PREPARATION - OUTPUT BUFFER
    # Start from original lines and overwrite only object-block ranges.
    [System.Collections.Generic.List[System.String]]$OutputLines = New-Object 'System.Collections.Generic.List[System.String]'
    $OutputLines.AddRange($TemplateLines)

    # EXECUTION - PATCH OBJECT BLOCKS
    # Apply current in-memory object values onto each parsed source block.
    foreach ($SourceItem in $SourceListView.Items) {
        [PSCustomObject]$PatchedBlockData = Get-UDFPatchedDeploymentObjectBlockData -SourceItem $SourceItem -TemplateLines $TemplateLines
        if ($null -eq $PatchedBlockData) {
            return $null
        }

        for ($LineIndex = 0; $LineIndex -lt $PatchedBlockData.PatchedBlockLines.Count; $LineIndex++) {
            $OutputLines[$PatchedBlockData.StartIndex + $LineIndex] = $PatchedBlockData.PatchedBlockLines[$LineIndex]
        }
    }

    # OUTPUT - PATCHED LINES
    # Return final lines with object patches and main-property updates applied.
    return (Update-UDFMainPropertiesInPsd1Lines -InputLines $OutputLines.ToArray() -MainProperties $MainPropertiesToSave)
}

### END OF FUNCTION
####################################################################################################


function Get-UDFReorderedPatchedTemplateLines {
    [CmdletBinding()]
    [OutputType([System.String[]])]
    param (
        [Parameter(Mandatory=$false,HelpMessage='The original DeploymentData.psd1 file used as a patch template.')]
        [AllowEmptyString()]
        [System.String]$TemplateFilePath,

        [Parameter(Mandatory=$true,HelpMessage='The ListView containing current deployment objects.')]
        [System.Windows.Forms.ListView]$SourceListView,

        [Parameter(Mandatory=$false,HelpMessage='Main property values to apply.')]
        [System.Collections.Hashtable]$MainPropertiesToSave
    )

    # VALIDATION - TEMPLATE PATH
    # Reordered patching requires a readable template file path.
    if ((Test-String -IsEmpty $TemplateFilePath) -or (-not (Test-Path -Path $TemplateFilePath -PathType Leaf))) {
        return $null
    }

    # PREPARATION - TEMPLATE CONTENT
    # Load source lines once for block reuse and replacement.
    [System.String[]]$TemplateLines = Get-Content -LiteralPath $TemplateFilePath -ErrorAction Stop
    if ($TemplateLines.Count -lt 1) {
        return $null
    }

    # PREPARATION - DEPLOYMENT OBJECTS RANGE
    # Resolve start and end line indexes of DeploymentObjects = @( ... ).
    [System.Int32]$DeploymentObjectsStartIndex = -1
    [System.Int32]$DeploymentObjectsEndIndex = -1
    [System.String]$DeploymentObjectsIndent = ''

    for ($LineIndex = 0; $LineIndex -lt $TemplateLines.Count; $LineIndex++) {
        if ($TemplateLines[$LineIndex] -match '^(\s*)DeploymentObjects\s*=\s*@\(') {
            $DeploymentObjectsStartIndex = $LineIndex
            $DeploymentObjectsIndent = [System.String]$Matches[1]
            break
        }
    }

    if ($DeploymentObjectsStartIndex -lt 0) {
        return $null
    }

    for ($LineIndex = ($DeploymentObjectsStartIndex + 1); $LineIndex -lt $TemplateLines.Count; $LineIndex++) {
        if (($TemplateLines[$LineIndex].Trim() -eq ')') -and ($TemplateLines[$LineIndex] -match "^$([regex]::Escape($DeploymentObjectsIndent))\)\s*$")) {
            $DeploymentObjectsEndIndex = $LineIndex
            break
        }
    }

    if ($DeploymentObjectsEndIndex -le $DeploymentObjectsStartIndex) {
        return $null
    }

    # EXECUTION - BUILD OUTPUT
    # Keep template pre/post content, but rebuild DeploymentObjects body in current ListView order.
    [System.Collections.Generic.List[System.String]]$OutputLines = New-Object 'System.Collections.Generic.List[System.String]'

    for ($LineIndex = 0; $LineIndex -le $DeploymentObjectsStartIndex; $LineIndex++) {
        $OutputLines.Add($TemplateLines[$LineIndex]) | Out-Null
    }

    foreach ($SourceItem in $SourceListView.Items) {
        [PSCustomObject]$PatchedBlockData = Get-UDFPatchedDeploymentObjectBlockData -SourceItem $SourceItem -TemplateLines $TemplateLines
        if ($null -eq $PatchedBlockData) {
            return $null
        }

        foreach ($PatchedBlockLine in $PatchedBlockData.PatchedBlockLines) {
            $OutputLines.Add([System.String]$PatchedBlockLine) | Out-Null
        }
    }

    $OutputLines.Add($TemplateLines[$DeploymentObjectsEndIndex]) | Out-Null

    for ($LineIndex = ($DeploymentObjectsEndIndex + 1); $LineIndex -lt $TemplateLines.Count; $LineIndex++) {
        $OutputLines.Add($TemplateLines[$LineIndex]) | Out-Null
    }

    # OUTPUT - PATCHED + REORDERED LINES
    # Return final lines with reordered blocks and main-property updates applied.
    return (Update-UDFMainPropertiesInPsd1Lines -InputLines $OutputLines.ToArray() -MainProperties $MainPropertiesToSave)
}

### END OF FUNCTION
####################################################################################################


function Get-UDFSerializedDeploymentDataLines {
    [CmdletBinding()]
    [OutputType([System.String[]])]
    param (
        [Parameter(Mandatory=$false,HelpMessage='The original DeploymentData.psd1 file used as a serialization template when possible.')]
        [AllowEmptyString()]
        [System.String]$TemplateFilePath,

        [Parameter(Mandatory=$true,HelpMessage='The ListView containing current deployment objects.')]
        [System.Windows.Forms.ListView]$SourceListView,

        [Parameter(Mandatory=$false,HelpMessage='Main property values to apply.')]
        [System.Collections.Hashtable]$MainPropertiesToSave
    )

    # PREPARATION - SERIALIZATION STATE
    # Initialize working buffers and indentation defaults.
    [System.Collections.Generic.List[System.String]]$Lines = New-Object 'System.Collections.Generic.List[System.String]'
    [System.String[]]$TemplateLines = @()
    [System.Int32]$DeploymentObjectsStartIndex = -1
    [System.Int32]$DeploymentObjectsEndIndex = -1
    [System.String]$DeploymentObjectsIndent = '    '
    [System.String]$ObjectIndent = '        '
    [System.String]$PropertyIndent = '            '
    [System.Boolean]$UsingTemplate = $false

    # EXECUTION - TEMPLATE DISCOVERY
    # Reuse existing file preamble and indentation when template parsing succeeds.
    if ((Test-String -IsPopulated $TemplateFilePath) -and (Test-Path -Path $TemplateFilePath -PathType Leaf)) {
        $TemplateLines = Get-Content -LiteralPath $TemplateFilePath -ErrorAction Stop
        for ($LineIndex = 0; $LineIndex -lt $TemplateLines.Count; $LineIndex++) {
            if ($TemplateLines[$LineIndex] -match '^(\s*)DeploymentObjects\s*=\s*@\(') {
                $DeploymentObjectsStartIndex = $LineIndex
                $DeploymentObjectsIndent = [System.String]$Matches[1]
                $ObjectIndent = "$DeploymentObjectsIndent    "
                $PropertyIndent = "$ObjectIndent    "
                break
            }
        }

        if ($DeploymentObjectsStartIndex -ge 0) {
            for ($LineIndex = ($DeploymentObjectsStartIndex + 1); $LineIndex -lt $TemplateLines.Count; $LineIndex++) {
                if (($TemplateLines[$LineIndex].Trim() -eq ')') -and ($TemplateLines[$LineIndex] -match "^$([regex]::Escape($DeploymentObjectsIndent))\)\s*$")) {
                    $DeploymentObjectsEndIndex = $LineIndex
                    break
                }
            }
        }

        if (($DeploymentObjectsStartIndex -ge 0) -and ($DeploymentObjectsEndIndex -gt $DeploymentObjectsStartIndex)) {
            $UsingTemplate = $true
            for ($LineIndex = 0; $LineIndex -le $DeploymentObjectsStartIndex; $LineIndex++) {
                $Lines.Add($TemplateLines[$LineIndex]) | Out-Null
            }
        }
    }

    # EXECUTION - OPEN ROOT BLOCK
    # Add a minimal root hashtable when no reusable template structure is available.
    if (-not $UsingTemplate) {
        $Lines.Add('@{') | Out-Null
        $Lines.Add('    DeploymentObjects = @(') | Out-Null
    }

    # EXECUTION - SERIALIZE OBJECTS
    # Serialize each in-memory deployment object in current list order.
    foreach ($SourceItem in $SourceListView.Items) {
        [PSCustomObject]$ItemEntry = Get-UDFDeploymentObjectItemEntry -SourceItem $SourceItem
        [System.Collections.Hashtable]$DeploymentObject = [System.Collections.Hashtable]$ItemEntry.DeploymentObject
        [System.String[]]$PreferredPropertyOrder = [System.String[]]$ItemEntry.PreferredPropertyOrder

        if ($null -eq $DeploymentObject) {
            continue
        }

        [System.String[]]$DisplayKeyOrder = Get-UDFDeploymentObjectDisplayKeyOrder -DeploymentObject $DeploymentObject -PreferredOrder $PreferredPropertyOrder
        $Lines.Add("$ObjectIndent@{") | Out-Null

        foreach ($KeyName in $DisplayKeyOrder) {
            [System.Object]$PropertyValueObject = $DeploymentObject[$KeyName]
            [System.String]$PropertyValueText = Convert-UDFDeploymentObjectValueToPsd1Text -Value $PropertyValueObject -IndentLevel 3

            if ($PropertyValueText.Contains([System.Environment]::NewLine)) {
                [System.String[]]$ValueLines = $PropertyValueText -split [System.Environment]::NewLine
                $Lines.Add("$PropertyIndent$KeyName = $($ValueLines[0])") | Out-Null
                foreach ($ValueLine in $ValueLines[1..($ValueLines.Count - 1)]) {
                    $Lines.Add($ValueLine) | Out-Null
                }
            }
            else {
                $Lines.Add("$PropertyIndent$KeyName = $PropertyValueText") | Out-Null
            }
        }

        $Lines.Add("$ObjectIndent}") | Out-Null
    }

    # EXECUTION - CLOSE ROOT BLOCK
    # Finish DeploymentObjects section and append any preserved trailing template lines.
    $Lines.Add("$DeploymentObjectsIndent)") | Out-Null

    if ($UsingTemplate) {
        for ($LineIndex = ($DeploymentObjectsEndIndex + 1); $LineIndex -lt $TemplateLines.Count; $LineIndex++) {
            $Lines.Add($TemplateLines[$LineIndex]) | Out-Null
        }
    }
    else {
        $Lines.Add('}') | Out-Null
    }

    # OUTPUT - SERIALIZED LINES
    # Return fully serialized lines with main-property updates applied.
    return (Update-UDFMainPropertiesInPsd1Lines -InputLines $Lines.ToArray() -MainProperties $MainPropertiesToSave)
}

### END OF FUNCTION
####################################################################################################


function Convert-UDFDeploymentObjectValueToPsd1Text {
    [CmdletBinding()]
    [OutputType([System.String])]
    param (
        [Parameter(Mandatory=$false,HelpMessage='The value to convert to PowerShell data file text.')]
        [AllowNull()]
        [System.Object]$Value,

        [Parameter(Mandatory=$false,HelpMessage='The current indentation level for nested values.')]
        [System.Int32]$IndentLevel = 0
    )

    # PREPARATION - INDENTATION
    # Build indentation tokens reused by nested value serializers.
    [System.String]$Indent = (' ' * ($IndentLevel * 4))
    [System.String]$NestedIndent = (' ' * (($IndentLevel + 1) * 4))

    # VALIDATION - NULL VALUE
    # Return explicit PowerShell null literal for null values.
    if ($null -eq $Value) {
        return '$null'
    }

    # EXECUTION - SCALAR CONVERSIONS
    # Convert primitive scalar types to PSD1-compatible text forms.
    if ($Value -is [System.Boolean]) {
        return $(if ($Value) { '$true' } else { '$false' })
    }

    if (($Value -is [System.Int32]) -or ($Value -is [System.Int64]) -or ($Value -is [System.Decimal]) -or ($Value -is [System.Double])) {
        return [System.String]$Value
    }

    if ($Value -is [System.DateTime]) {
        return "[datetime]'$([System.String]$Value.ToString('o'))'"
    }

    if ($Value -is [System.String]) {
        return "'$([System.String]$Value.Replace("'", "''"))'"
    }

    # EXECUTION - HASHTABLE SERIALIZATION
    # Serialize hashtable values as nested PSD1 hashtable syntax.
    if ($Value -is [System.Collections.Hashtable]) {
        if ($Value.Count -lt 1) {
            return '@{}'
        }

        [System.Collections.Generic.List[System.String]]$Lines = New-Object 'System.Collections.Generic.List[System.String]'
        $Lines.Add('@{') | Out-Null

        foreach ($KeyName in $Value.Keys) {
            [System.String]$KeyText = [System.String]$KeyName
            [System.Object]$KeyValue = $Value[$KeyName]
            [System.String]$ValueText = Convert-UDFDeploymentObjectValueToPsd1Text -Value $KeyValue -IndentLevel ($IndentLevel + 1)

            if ($ValueText.Contains([System.Environment]::NewLine)) {
                [System.String[]]$ValueLines = $ValueText -split [System.Environment]::NewLine
                $Lines.Add("$NestedIndent$KeyText = $($ValueLines[0])") | Out-Null
                foreach ($ValueLine in $ValueLines[1..($ValueLines.Count - 1)]) {
                    $Lines.Add($ValueLine) | Out-Null
                }
            }
            else {
                $Lines.Add("$NestedIndent$KeyText = $ValueText") | Out-Null
            }
        }

        $Lines.Add("$Indent}") | Out-Null
        return ($Lines -join [System.Environment]::NewLine)
    }

    # EXECUTION - ARRAY SERIALIZATION
    # Serialize arrays inline when short, otherwise multiline for readability.
    if ($Value -is [System.Array]) {
        if ($Value.Count -lt 1) {
            return '@()'
        }

        [System.Collections.Generic.List[System.String]]$ItemTexts = New-Object 'System.Collections.Generic.List[System.String]'
        foreach ($Item in $Value) {
            $ItemTexts.Add((Convert-UDFDeploymentObjectValueToPsd1Text -Value $Item -IndentLevel ($IndentLevel + 1))) | Out-Null
        }

        [System.String]$InlineArray = '@(' + ($ItemTexts -join ', ') + ')'
        if ($InlineArray.Length -le 120) {
            return $InlineArray
        }

        [System.Collections.Generic.List[System.String]]$ArrayLines = New-Object 'System.Collections.Generic.List[System.String]'
        $ArrayLines.Add('@(') | Out-Null
        foreach ($ItemText in $ItemTexts) {
            $ArrayLines.Add("$NestedIndent$ItemText") | Out-Null
        }
        $ArrayLines.Add("$Indent)") | Out-Null
        return ($ArrayLines -join [System.Environment]::NewLine)
    }

    # OUTPUT - FALLBACK STRING
    # Fallback to default string conversion for unsupported value types.
    return [System.String]$Value
}

### END OF FUNCTION
####################################################################################################


function Convert-UDFDeploymentObjectValueToPsd1InlineText {
    [CmdletBinding()]
    [OutputType([System.String])]
    param (
        [Parameter(Mandatory=$false,HelpMessage='The value to convert to single-line PowerShell data text.')]
        [AllowNull()]
        [System.Object]$Value
    )

    # PREPARATION - MULTILINE SOURCE
    # Reuse main serializer before flattening to single-line output.
    [System.String]$ValueText = Convert-UDFDeploymentObjectValueToPsd1Text -Value $Value

    # OUTPUT - INLINE TEXT
    # Replace line breaks with spaces to keep one-line assignment formatting.
    return (($ValueText -split '\r?\n') -join ' ')
}

### END OF FUNCTION
####################################################################################################


function Update-UDFMainPropertiesInPsd1Lines {
    [CmdletBinding()]
    [OutputType([System.String[]])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The full psd1 content as string array lines.')]
        [AllowEmptyCollection()]
        [AllowEmptyString()]
        [System.String[]]$InputLines,

        [Parameter(Mandatory=$false,HelpMessage='Main property values to apply.')]
        [System.Collections.Hashtable]$MainProperties
    )

    # VALIDATION - MAIN PROPERTIES
    # Return input unchanged when there are no updates to apply.
    if (($null -eq $MainProperties) -or ($MainProperties.Count -lt 1)) {
        return $InputLines
    }

    # PREPARATION - WORKING STATE
    # Initialize output lines and top-level keys used in patch operations.
    [System.String[]]$OutputLines = @($InputLines)
    [System.String[]]$MainKeys = @('ApplicationID','BuildNumber','SourceFilesFolder')

    # PREPARATION - DEPLOYMENTOBJECTS BOUNDARY
    # Locate DeploymentObjects start so main-property search stays above that section.
    [System.Int32]$DeploymentObjectsLineIndex = -1
    for ($LineIndex = 0; $LineIndex -lt $OutputLines.Count; $LineIndex++) {
        if ($OutputLines[$LineIndex] -match '^\s*DeploymentObjects\s*=\s*@\(') {
            $DeploymentObjectsLineIndex = $LineIndex
            break
        }
    }

    # VALIDATION - SEARCH RANGE
    # Stop early when no searchable lines exist above DeploymentObjects.
    [System.Int32]$SearchEndIndex = $(if ($DeploymentObjectsLineIndex -ge 0) { $DeploymentObjectsLineIndex - 1 } else { $OutputLines.Count - 1 })
    if ($SearchEndIndex -lt 0) {
        return $OutputLines
    }

    # PREPARATION - COMMENT ALIGNMENT COLUMN
    # Detect a shared inline comment column so replacements preserve visual alignment.
    [System.Int32]$TargetCommentColumn = -1
    foreach ($KeyName in $MainKeys) {
        if (-not $MainProperties.ContainsKey($KeyName)) { continue }
        [System.String]$Pattern = '^(?<indent>\s*)' + [regex]::Escape($KeyName) + '(?<beforeEq>\s*=\s*)(?<value>.*?)(?<suffix>\s*(#.*)?)$'
        for ($LineIndex = 0; $LineIndex -le $SearchEndIndex; $LineIndex++) {
            if ($OutputLines[$LineIndex] -match $Pattern) {
                [System.Int32]$CommentIndex = $OutputLines[$LineIndex].IndexOf('#')
                if ($CommentIndex -ge 0 -and $CommentIndex -gt $TargetCommentColumn) {
                    $TargetCommentColumn = $CommentIndex
                }
                break
            }
        }
    }

    # EXECUTION - APPLY MAIN PROPERTY PATCHES
    # Replace key assignment values while preserving suffix comments and spacing.
    foreach ($KeyName in $MainKeys) {
        if (-not $MainProperties.ContainsKey($KeyName)) { continue }
        [System.String]$Pattern = '^(?<indent>\s*)' + [regex]::Escape($KeyName) + '(?<beforeEq>\s*=\s*)(?<value>.*?)(?<suffix>\s*(#.*)?)$'

        for ($LineIndex = 0; $LineIndex -le $SearchEndIndex; $LineIndex++) {
            if ($OutputLines[$LineIndex] -match $Pattern) {
                [System.String]$NewValueText = Convert-UDFDeploymentObjectValueToPsd1InlineText -Value ([System.String]$MainProperties[$KeyName])
                [System.String]$PrefixText = "$($Matches['indent'])$KeyName$($Matches['beforeEq'])$NewValueText"
                [System.String]$SuffixText = [System.String]$Matches['suffix']

                if (($TargetCommentColumn -ge 0) -and ($SuffixText -match '(?<leading>\s*)(?<comment>#.*)$')) {
                    [System.String]$CommentText = [System.String]$Matches['comment']
                    [System.Int32]$PaddingLength = [System.Math]::Max(1, ($TargetCommentColumn - $PrefixText.Length))
                    $OutputLines[$LineIndex] = $PrefixText + (' ' * $PaddingLength) + $CommentText
                }
                else {
                    $OutputLines[$LineIndex] = $PrefixText + $SuffixText
                }

                break
            }
        }
    }

    # OUTPUT - PATCHED LINES
    # Return updated psd1 lines with patched main-property values.
    return $OutputLines
}

### END OF FUNCTION
####################################################################################################


function Save-UDFDeploymentDataToFile {
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param (
        [Parameter(Mandatory=$false,HelpMessage='The original DeploymentData.psd1 file used as a template when preserving extra content.')]
        [AllowEmptyString()]
        [System.String]$TemplateFilePath,

        [Parameter(Mandatory=$true,HelpMessage='The full path to the DeploymentData.psd1 file that will be written.')]
        [AllowEmptyString()]
        [System.String]$DataFilePath,

        [Parameter(Mandatory=$true,HelpMessage='The ListView containing the current deployment objects.')]
        [System.Windows.Forms.ListView]$SourceListView
    )

    try {
        # VALIDATION - OUTPUT PATH
        # Require a populated destination file path.
        if (Test-String -IsEmpty $DataFilePath) {
            Write-Line 'Choose a file path before saving.' -Type Warning
            return $false
        }

        # VALIDATION - SOURCE LISTVIEW
        # Require at least one deployment object to serialize.
        if (($null -eq $SourceListView) -or ($SourceListView.Items.Count -lt 1)) {
            Write-Line 'Nothing to save: no deployment objects loaded.' -Type Warning
            return $false
        }

        [System.Collections.Generic.List[System.String]]$TypesToSave = New-Object 'System.Collections.Generic.List[System.String]'
        foreach ($SourceItem in $SourceListView.Items) {
            [PSCustomObject]$ItemEntry = Get-UDFDeploymentObjectItemEntry -SourceItem $SourceItem
            [System.Collections.Hashtable]$DeploymentObject = [System.Collections.Hashtable]$ItemEntry.DeploymentObject
            if (($null -ne $DeploymentObject) -and $DeploymentObject.ContainsKey('Type') -and (Test-String -IsPopulated ([System.String]$DeploymentObject['Type']))) {
                $TypesToSave.Add([System.String]$DeploymentObject['Type']) | Out-Null
            }
            else {
                $TypesToSave.Add('UNKNOWN') | Out-Null
            }
        }
        Write-Line "Saving deployment object order: $([System.String]::Join(' -> ', $TypesToSave.ToArray()))"

        [System.Collections.Hashtable]$MainPropertiesToSave = Get-UDFDeploymentDataMainPropertiesFromListView -SourceListView $SourceListView

        # PREPARATION - SOURCE-PRESERVING PATCH
        # Try patching original source blocks first; fallback to full serialization when needed.
        [System.Boolean]$CanUsePatchMode = Test-UDFDeploymentObjectOrderMatchesSourceBlocks -SourceListView $SourceListView
        [System.Int32]$TemplateObjectCount = Get-UDFDeploymentObjectCountFromTemplate -TemplateFilePath $TemplateFilePath
        if (($TemplateObjectCount -ge 0) -and ($SourceListView.Items.Count -lt $TemplateObjectCount)) {
            # Deletion changes object cardinality, so simple patch mode can preserve removed blocks.
            $CanUsePatchMode = $false
            Write-Line 'Detected deleted deployment objects; saving in current list order to remove deleted blocks.'
        }
        [System.String[]]$FinalLines = $null

        if ($CanUsePatchMode) {
            $FinalLines = Get-UDFPatchedTemplateLines -TemplateFilePath $TemplateFilePath -SourceListView $SourceListView -MainPropertiesToSave $MainPropertiesToSave
        }

        if (-not $CanUsePatchMode) {
            Write-Line 'Detected reordered deployment objects; keeping comments and saving in current list order.'
            $FinalLines = Get-UDFReorderedPatchedTemplateLines -TemplateFilePath $TemplateFilePath -SourceListView $SourceListView -MainPropertiesToSave $MainPropertiesToSave
            if ($null -eq $FinalLines) {
                Write-Line 'Could not preserve all original object comments for this save; using normalized format.' -Type Warning
                $FinalLines = Get-UDFSerializedDeploymentDataLines -TemplateFilePath $TemplateFilePath -SourceListView $SourceListView -MainPropertiesToSave $MainPropertiesToSave
            }
        }
        elseif ($null -eq $FinalLines) {
            $FinalLines = Get-UDFSerializedDeploymentDataLines -TemplateFilePath $TemplateFilePath -SourceListView $SourceListView -MainPropertiesToSave $MainPropertiesToSave
        }

        # EXECUTION - WRITE FILE
        # Persist the final psd1 content to disk.
        [System.String]$OutputText = ($FinalLines -join [System.Environment]::NewLine)
        [System.Text.UTF8Encoding]$Utf8WithoutBom = New-Object System.Text.UTF8Encoding($false)
        [System.IO.File]::WriteAllText($DataFilePath, $OutputText, $Utf8WithoutBom)
        Write-Line "Saved: $DataFilePath" -Type Success
        Open-Folder -Path $DataFilePath
        return $true
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
        return $false
    }
}

### END OF FUNCTION
####################################################################################################


function Get-UDFDeploymentObjectCountFromTemplate {
    [CmdletBinding()]
    [OutputType([System.Int32])]
    param (
        [Parameter(Mandatory=$false,HelpMessage='The DeploymentData.psd1 template path used to estimate source object count.')]
        [AllowEmptyString()]
        [System.String]$TemplateFilePath
    )

    try {
        # VALIDATION - TEMPLATE PATH
        # Return -1 when source counting cannot be performed.
        if ((Test-String -IsEmpty $TemplateFilePath) -or (-not (Test-Path -Path $TemplateFilePath -PathType Leaf))) {
            return -1
        }

        # PREPARATION - IMPORT DATA
        # Read DeploymentData and resolve the DeploymentObjects array size.
        [System.Collections.Hashtable]$TemplateData = Import-PowerShellDataFile -Path $TemplateFilePath
        if (($null -eq $TemplateData) -or (-not $TemplateData.ContainsKey('DeploymentObjects'))) {
            return -1
        }

        # OUTPUT - OBJECT COUNT
        # Return source DeploymentObjects count with array shape normalization.
        return @($TemplateData.DeploymentObjects).Count
    }
    catch {
        # ERROR HANDLING - SAFE FALLBACK
        # Counting is advisory only; keep save flow resilient on read/import errors.
        return -1
    }
}

### END OF FUNCTION
####################################################################################################


