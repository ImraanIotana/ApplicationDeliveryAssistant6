####################################################################################################
<#
.SYNOPSIS
    Imports deployment data into the UDF editor list view.
.DESCRIPTION
    Loads deployment data from a PowerShell data file, resolves catalog metadata, and populates the object and properties list views used by the UDF editor experience.
.EXAMPLE
    Import-UDFDeploymentDataToListView
.INPUTS
    The function parameters are described in the parameter block.
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.5
    Author          : Imraan Iotana
    Creation Date   : August 2026
    Last Update     : August 2026
#>
####################################################################################################
function Import-UDFDeploymentDataToListView {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false,HelpMessage='The full path to DeploymentData.psd1.')]
        [AllowNull()][AllowEmptyString()]
        [System.String]$DataFilePath,

        [Parameter(Mandatory=$true,HelpMessage='The ListView that will be filled with DeploymentObjects.')]
        [System.Windows.Forms.ListView]$ListView,

        [Parameter(Mandatory=$false,HelpMessage='Optional ListView that displays properties of the selected DeploymentObject.')]
        [System.Windows.Forms.ListView]$PropertiesListView,

        [Parameter(Mandatory=$false,HelpMessage='Optional ListView that displays main deployment settings.')]
        [System.Windows.Forms.ListView]$MainPropertiesListView
    )

    try {
        # VALIDATION - INPUTS
        # Validate the selected file path with the shared file-path validator.
        if (-not (Confirm-FilePath -Path $DataFilePath -Name 'Deployment Data File')) {
            $ListView.Tag = [PSCustomObject]@{
                MainProperties = @{}
                DataFilePath   = ''
                InternalCatalog = $null
            }
            if ($null -ne $PropertiesListView) {
                Show-UDFDeploymentObjectPropertiesInListView -SourceListView $ListView -PropertiesListView $PropertiesListView
            }
            if ($null -ne $MainPropertiesListView) {
                Show-UDFMainPropertiesInListView -SourceListView $ListView -MainPropertiesListView $MainPropertiesListView
            }
            return
        }

        # PREPARATION - IMPORT DATA
        # Import the selected psd1 as a hashtable.
        [System.Collections.Hashtable]$DeploymentData = Import-PowerShellDataFile -Path $DataFilePath
        if ($null -eq $DeploymentData) {
            Write-Line "Could not load file: $DataFilePath" -Type Warning
            return
        }
        if (-not $DeploymentData.ContainsKey('DeploymentObjects')) {
            Write-Line "File has no DeploymentObjects section: $DataFilePath" -Type Warning
            return
        }

        # PREPARATION - OBJECT ARRAY
        # Force array shape so single-object files are handled consistently.
        [System.Collections.Hashtable[]]$DeploymentObjects = @($DeploymentData.DeploymentObjects)
        [System.Collections.Hashtable]$MainProperties = @{
            ApplicationID       = [System.String]$(if ($DeploymentData.ContainsKey('ApplicationID')) { $DeploymentData.ApplicationID } else { '' })
            BuildNumber         = [System.String]$(if ($DeploymentData.ContainsKey('BuildNumber')) { $DeploymentData.BuildNumber } else { '' })
            SourceFilesFolder   = [System.String]$(if ($DeploymentData.ContainsKey('SourceFilesFolder')) { $DeploymentData.SourceFilesFolder } else { '' })
        }
        [System.Collections.Hashtable]$InternalCatalog = $null
        if ($DeploymentData.ContainsKey('_Catalog') -and ($DeploymentData._Catalog -is [System.Collections.Hashtable])) {
            $InternalCatalog = [System.Collections.Hashtable]$DeploymentData._Catalog
            [void](Test-UDFInternalCatalog -InternalCatalog $InternalCatalog)
        }
        elseif (Test-String -IsPopulated ([System.String]$DataFilePath)) {
            $InternalCatalog = Get-UDFExternalDeploymentObjectCatalog -DataFilePath $DataFilePath
        }
        $ListView.Tag = [PSCustomObject]@{
            MainProperties  = $MainProperties
            DataFilePath    = [System.String]$DataFilePath
            InternalCatalog = $InternalCatalog
        }

        # Read the property order and source blocks in one pass so the file is only parsed once.
        [PSCustomObject]$DeploymentObjectMetadata = Get-UDFDeploymentObjectMetadataFromFile -DataFilePath $DataFilePath
        [System.Collections.Hashtable]$PropertyOrderPerObject = [System.Collections.Hashtable]$DeploymentObjectMetadata.PropertyOrderPerObject
        [System.Collections.Hashtable]$SourceBlockPerObject = [System.Collections.Hashtable]$DeploymentObjectMetadata.SourceBlockPerObject

        # EXECUTION - FILL LISTVIEW
        # Refresh the ListView in one paint cycle to reduce flicker.
        Invoke-ListViewBatchUpdate -ListView $ListView -Action {
            $ListView.Items.Clear()

            [System.Int32]$Index = 1
            foreach ($DeploymentObject in $DeploymentObjects) {
                [System.Int32]$ObjectIndex = ($Index - 1)
                [System.String[]]$ObjectPropertyOrder = @()
                if (($null -ne $PropertyOrderPerObject) -and $PropertyOrderPerObject.ContainsKey($ObjectIndex)) {
                    $ObjectPropertyOrder = [System.String[]]$PropertyOrderPerObject[$ObjectIndex]
                }

                [System.String]$ObjectType = if (($null -ne $DeploymentObject) -and $DeploymentObject.ContainsKey('Type')) { [System.String]$DeploymentObject.Type } else { 'UNKNOWN' }
                [System.String]$Summary = Get-UDFDeploymentObjectSummaryText -DeploymentObject $DeploymentObject

                [System.Windows.Forms.ListViewItem]$ResultItem = New-Object System.Windows.Forms.ListViewItem([System.String]$Index)
                $ResultItem.Tag = [PSCustomObject]@{
                    DeploymentObject = $DeploymentObject
                    PropertyOrder    = $ObjectPropertyOrder
                    SourceBlock      = $(if (($null -ne $SourceBlockPerObject) -and $SourceBlockPerObject.ContainsKey($ObjectIndex)) { $SourceBlockPerObject[$ObjectIndex] } else { $null })
                }
                $null = $ResultItem.SubItems.Add($ObjectType)
                $null = $ResultItem.SubItems.Add($Summary)
                $null = $ListView.Items.Add($ResultItem)

                $Index++
            }

            Set-ListViewColumnAutoSize -ListView $ListView -Mode Widest

            # If a properties ListView is supplied, sync it with the current selection.
            if ($null -ne $PropertiesListView) {
                if ($ListView.Items.Count -gt 0) {
                    [void](Set-ListViewSelectionByIndex -ListView $ListView -Index 0 -ClearExisting -SetFocus)
                    Show-UDFDeploymentObjectPropertiesInListView -SourceListView $ListView -PropertiesListView $PropertiesListView
                }
                else {
                    Show-UDFDeploymentObjectPropertiesInListView -SourceListView $ListView -PropertiesListView $PropertiesListView
                }
            }

            # If a main-properties ListView is supplied, sync it with current source metadata.
            if ($null -ne $MainPropertiesListView) {
                Show-UDFMainPropertiesInListView -SourceListView $ListView -MainPropertiesListView $MainPropertiesListView
            }
        }

        # OUTPUT - STATUS MESSAGE
        # Write a simple status message with loaded object count.
        Write-Line "Loaded $($DeploymentObjects.Count) deployment object(s)." -Type Success
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
    Validates the structure of an internal deployment object catalog.
.DESCRIPTION
    Checks that the supplied catalog contains the expected ObjectTypes section and field metadata required by the add/edit dialogs.
.EXAMPLE
    Test-UDFInternalCatalog
.INPUTS
    The function parameters are described in the parameter block.
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.4
    Author          : Imraan Iotana
    Creation Date   : August 2026
    Last Update     : August 2026
#>
####################################################################################################
function Test-UDFInternalCatalog {
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The internal _Catalog hashtable loaded from DeploymentData.')]
        [System.Collections.Hashtable]$InternalCatalog
    )

    try {
        # VALIDATION - ROOT KEYS
        # Require the basic catalog sections used by the Add dialog and Info column.
        if (-not $InternalCatalog.ContainsKey('ObjectTypes')) {
            Write-Line 'The loaded _Catalog has no ObjectTypes section.' -Type Warning
            return $false
        }

        if ($null -eq $InternalCatalog.ObjectTypes) {
            Write-Line 'The loaded _Catalog.ObjectTypes section is empty.' -Type Warning
            return $false
        }

        # VALIDATION - OBJECT TYPES
        # Warn on missing display metadata, but keep the catalog usable with fallbacks.
        foreach ($ObjectTypeName in @($InternalCatalog.ObjectTypes.Keys)) {
            [System.Collections.Hashtable]$TypeDefinition = [System.Collections.Hashtable]$InternalCatalog.ObjectTypes[$ObjectTypeName]
            if ($null -eq $TypeDefinition) {
                Write-Line "The loaded _Catalog type '$ObjectTypeName' is empty." -Type Warning
                continue
            }

            if ((-not $TypeDefinition.ContainsKey('DisplayName')) -or (Test-String -IsEmpty ([System.String]$TypeDefinition.DisplayName))) {
                Write-Line "The loaded _Catalog type '$ObjectTypeName' has no DisplayName; the Add dialog will fall back to the raw type name." -Type Warning
            }
            if ((-not $TypeDefinition.ContainsKey('Description')) -or (Test-String -IsEmpty ([System.String]$TypeDefinition.Description))) {
                Write-Line "The loaded _Catalog type '$ObjectTypeName' has no Description; the Add dialog description area will be blank." -Type Warning
            }
            if ((-not $TypeDefinition.ContainsKey('Fields')) -or ($null -eq $TypeDefinition.Fields) -or (@($TypeDefinition.Fields).Count -lt 1)) {
                Write-Line "The loaded _Catalog type '$ObjectTypeName' has no Fields definitions." -Type Warning
            }
        }

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
    Resolves a deployment object catalog from the selected data file location.
.DESCRIPTION
    Scans folder-local and bundled catalog candidates and returns a validated catalog that can drive the UDF editor UI.
.EXAMPLE
    Get-UDFExternalDeploymentObjectCatalog
.INPUTS
    The function parameters are described in the parameter block.
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.4
    Author          : Imraan Iotana
    Creation Date   : August 2026
    Last Update     : August 2026
#>
####################################################################################################
function Get-UDFExternalDeploymentObjectCatalog {
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The full path to DeploymentData.psd1.')]
        [System.String]$DataFilePath
    )

    try {
        # PREPARATION - CATALOG PATHS
        # Resolve the deployment-data folder and candidate catalog locations.
        [System.String]$DataDirectory = Split-Path -Path $DataFilePath -Parent
        [System.String]$NormalizedDataDirectory = [System.IO.Path]::GetFullPath($DataDirectory)
        [System.String]$RepoRootPath = [System.IO.Path]::GetFullPath((Join-Path -Path $PSScriptRoot -ChildPath '..\..'))
        [System.Boolean]$IsRepoOwnedDataPath = $NormalizedDataDirectory.StartsWith($RepoRootPath, [System.StringComparison]::OrdinalIgnoreCase)

        [System.String]$BundledCatalogPath = [System.IO.Path]::GetFullPath((Join-Path -Path $PSScriptRoot -ChildPath '..\..\Assets\UDF\DeploymentObjectCatalog.psd1'))
        [System.Collections.Generic.List[System.String]]$CandidatePaths = New-Object 'System.Collections.Generic.List[System.String]'
        $CandidatePaths.Add((Join-Path -Path $DataDirectory -ChildPath 'Engines\DeploymentEngines\DeploymentDataEngines\DeploymentObjectCatalog.psd1')) | Out-Null
        $CandidatePaths.Add((Join-Path -Path $DataDirectory -ChildPath 'DeploymentObjectCatalog.psd1')) | Out-Null

        # PREPARATION - BUNDLED FALLBACK
        # Only use bundled fallbacks for repo-owned UDF paths to avoid leaking newer catalogs into external/older folders.
        if ($IsRepoOwnedDataPath) {
            $CandidatePaths.Add($BundledCatalogPath) | Out-Null
        }

        # EXECUTION - CHECK CANDIDATE PATHS
        # Scan the folder-local and bundled catalog candidates until a valid catalog is found.
        foreach ($CandidatePath in $CandidatePaths.ToArray()) {
            if (-not (Test-Path -LiteralPath $CandidatePath -PathType Leaf)) {
                continue
            }

            [System.Object]$ImportedCatalogData = Import-PowerShellDataFile -Path $CandidatePath
            if ($null -eq $ImportedCatalogData) {
                continue
            }

            [System.Collections.Hashtable]$Catalog = $null
            if (($ImportedCatalogData -is [System.Collections.Hashtable]) -and $ImportedCatalogData.ContainsKey('_Catalog') -and ($ImportedCatalogData._Catalog -is [System.Collections.Hashtable])) {
                $Catalog = [System.Collections.Hashtable]$ImportedCatalogData._Catalog
            }
            elseif (($ImportedCatalogData -is [System.Collections.Hashtable]) -and $ImportedCatalogData.ContainsKey('ObjectTypes')) {
                $Catalog = [System.Collections.Hashtable]$ImportedCatalogData
            }

            if ($null -eq $Catalog) {
                continue
            }

            if (Test-UDFInternalCatalog -InternalCatalog $Catalog) {
                Write-Line "Loaded deployment object catalog from '$CandidatePath'."
                return $Catalog
            }
        }

        # OUTPUT - FALLBACK RESULT
        # Warn when no local catalog is available for external folders; otherwise return null.
        if (-not $IsRepoOwnedDataPath) {
            Write-Line 'No folder-local deployment object catalog was found next to the selected DeploymentData.psd1; bundled fallback is intentionally skipped for external folders.' -Type Warning
        }

        return $null
    }
    catch {
        # ERROR HANDLING - SAFE FALLBACK
        # Return null when catalog discovery fails.
        Write-ErrorReport -ErrorRecord $_
        return $null
    }
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Resolves metadata from a source ListView item.
.DESCRIPTION
    Extracts the deployment object and associated property-order metadata stored on the ListView item tag.
.EXAMPLE
    Get-UDFDeploymentObjectItemEntry
.INPUTS
    The function parameters are described in the parameter block.
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.4
    Author          : Imraan Iotana
    Creation Date   : August 2026
    Last Update     : August 2026
#>
####################################################################################################
function Get-UDFDeploymentObjectItemEntry {
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSCustomObject])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The ListView item to resolve metadata from.')]
        [System.Windows.Forms.ListViewItem]$SourceItem
    )

    # PREPARATION - DEFAULT OUTPUT VALUES
    # Initialize fallback values used when row-tag metadata is absent.
    [System.Collections.Hashtable]$DeploymentObject = $null
    [System.String[]]$PreferredPropertyOrder = @()
    [PSCustomObject]$SourceBlock = $null

    # EXECUTION - RESOLVE TAG PAYLOAD
    # Support both legacy hashtable tags and structured PSCustomObject tags.
    if ($SourceItem.Tag -is [System.Collections.Hashtable]) {
        $DeploymentObject = [System.Collections.Hashtable]$SourceItem.Tag
    }
    elseif (($null -ne $SourceItem.Tag) -and ($null -ne $SourceItem.Tag.PSObject.Properties['DeploymentObject'])) {
        if ($SourceItem.Tag.DeploymentObject -is [System.Collections.Hashtable]) {
            $DeploymentObject = [System.Collections.Hashtable]$SourceItem.Tag.DeploymentObject
        }

        if (($null -ne $SourceItem.Tag.PSObject.Properties['PropertyOrder']) -and ($SourceItem.Tag.PropertyOrder -is [System.Array])) {
            $PreferredPropertyOrder = [System.String[]]$SourceItem.Tag.PropertyOrder
        }
    }

    if (($null -ne $SourceItem.Tag) -and ($null -ne $SourceItem.Tag.PSObject.Properties['SourceBlock'])) {
        $SourceBlock = [PSCustomObject]$SourceItem.Tag.SourceBlock
    }

    # OUTPUT - ENTRY OBJECT
    # Return one stable shape for all callers.
    return [PSCustomObject]@{
        DeploymentObject     = $DeploymentObject
        PreferredPropertyOrder = $PreferredPropertyOrder
        SourceBlock          = $SourceBlock
    }
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Retrieves main deployment properties from a ListView tag.
.DESCRIPTION
    Returns the main property hashtable stored on the source ListView so the editor can display the top-level deployment settings.
.EXAMPLE
    Get-UDFDeploymentDataMainPropertiesFromListView
.INPUTS
    The function parameters are described in the parameter block.
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.4
    Author          : Imraan Iotana
    Creation Date   : August 2026
    Last Update     : August 2026
#>
####################################################################################################
function Get-UDFDeploymentDataMainPropertiesFromListView {
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The ListView containing the deployment data tag.')]
        [System.Windows.Forms.ListView]$SourceListView
    )

    # PREPARATION - DEFAULT MAIN PROPERTIES
    # Use an empty hashtable when no source metadata exists yet.
    [System.Collections.Hashtable]$MainProperties = @{}

    # EXECUTION - RESOLVE TAG VALUE
    # Read main-property values from ListView tag when present.
    if (($null -ne $SourceListView.Tag) -and ($null -ne $SourceListView.Tag.PSObject.Properties['MainProperties']) -and ($SourceListView.Tag.MainProperties -is [System.Collections.Hashtable])) {
        $MainProperties = [System.Collections.Hashtable]$SourceListView.Tag.MainProperties
    }

    # OUTPUT - MAIN PROPERTIES
    # Return the resolved main-property map.
    return $MainProperties
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Parses deployment object metadata directly from the source file.
.DESCRIPTION
    Reads deployment data from disk and captures property-order and source-block metadata for each deployment object.
.EXAMPLE
    Get-UDFDeploymentObjectMetadataFromFile
.INPUTS
    The function parameters are described in the parameter block.
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.4
    Author          : Imraan Iotana
    Creation Date   : August 2026
    Last Update     : August 2026
#>
####################################################################################################
function Get-UDFDeploymentObjectMetadataFromFile {
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSCustomObject])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The full path to DeploymentData.psd1.')]
        [System.String]$DataFilePath
    )

    try {
        # PREPARATION - OUTPUT TABLES
        # Create per-object dictionaries for property order and source-block metadata.
        [System.Collections.Hashtable]$PropertyOrderPerObject = @{}
        [System.Collections.Hashtable]$SourceBlockPerObject = @{}

        # PREPARATION - FILE CONTENT
        # Read full source file once for one-pass metadata extraction.
        [System.String[]]$Lines = Get-Content -LiteralPath $DataFilePath -ErrorAction Stop

        # PREPARATION - PARSER STATE
        # Track parser position and object-level scope while scanning lines.
        [System.Boolean]$InsideDeploymentObjects = $false
        [System.Int32]$ObjectDepth = 0
        [System.Int32]$ObjectIndex = -1
        [System.Int32]$ObjectStartLine = -1
        [System.Collections.Generic.List[System.String]]$CurrentKeyOrder = $null

        # EXECUTION - PARSE METADATA
        # Capture object key order and source line ranges in a single file pass.
        for ($LineIndex = 0; $LineIndex -lt $Lines.Count; $LineIndex++) {
            [System.String]$Line = $Lines[$LineIndex]
            [System.String]$TrimmedLine = $Line.Trim()

            if (-not $InsideDeploymentObjects) {
                if ($TrimmedLine -match '^DeploymentObjects\s*=\s*@\(') {
                    $InsideDeploymentObjects = $true
                }
                continue
            }

            if (($ObjectDepth -eq 0) -and ($TrimmedLine -eq ')')) {
                break
            }

            [System.Boolean]$IsCommentOnlyLine = ($TrimmedLine.StartsWith('#')) -or ($TrimmedLine.StartsWith('<#')) -or ($TrimmedLine.StartsWith('#>'))
            if (-not $IsCommentOnlyLine) {
                if (($ObjectDepth -eq 1) -and ($TrimmedLine -match '^([A-Za-z_][A-Za-z0-9_]*)\s*=')) {
                    [System.String]$KeyName = [System.String]$Matches[1]
                    if (($null -ne $CurrentKeyOrder) -and -not $CurrentKeyOrder.Contains($KeyName)) {
                        $CurrentKeyOrder.Add($KeyName) | Out-Null
                    }
                }

                if (($ObjectDepth -eq 0) -and ($TrimmedLine -match '^@\{')) {
                    $ObjectIndex++
                    $CurrentKeyOrder = New-Object 'System.Collections.Generic.List[System.String]'
                    $ObjectStartLine = $LineIndex
                }
            }

            [System.Int32]$OpenBraceCount = ([regex]::Matches($Line, '\{')).Count
            [System.Int32]$CloseBraceCount = ([regex]::Matches($Line, '\}')).Count
            $ObjectDepth += $OpenBraceCount
            $ObjectDepth -= $CloseBraceCount

            if (($ObjectDepth -eq 0) -and ($null -ne $CurrentKeyOrder)) {
                $PropertyOrderPerObject[$ObjectIndex] = $CurrentKeyOrder.ToArray()

                if ($ObjectStartLine -ge 0) {
                    [System.String[]]$ObjectLines = $Lines[$ObjectStartLine..$LineIndex]
                    $SourceBlockPerObject[$ObjectIndex] = [PSCustomObject]@{
                        StartLine = ($ObjectStartLine + 1)
                        EndLine   = ($LineIndex + 1)
                        Text      = ($ObjectLines -join [System.Environment]::NewLine)
                    }
                }

                $CurrentKeyOrder = $null
                $ObjectStartLine = -1
            }
        }

        # OUTPUT - METADATA OBJECT
        # Return parsed metadata for all detected deployment objects.
        return [PSCustomObject]@{
            PropertyOrderPerObject = $PropertyOrderPerObject
            SourceBlockPerObject   = $SourceBlockPerObject
        }
    }
    catch {
        # ERROR HANDLING - SAFE FALLBACK
        # Return empty metadata maps when parsing fails.
        Write-ErrorReport -ErrorRecord $_
        return [PSCustomObject]@{
            PropertyOrderPerObject = @{}
            SourceBlockPerObject   = @{}
        }
    }
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Runs a ListView update action inside BeginUpdate/EndUpdate.
.DESCRIPTION
    Wraps ListView repaint suppression so callers can focus on row logic while avoiding flicker.
.EXAMPLE
    Invoke-UDFListViewBatchUpdate -ListView $MyListView -Action { $MyListView.Items.Clear() }
.INPUTS
    The function parameters are described in the parameter block.
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.5
    Author          : Imraan Iotana
    Creation Date   : August 2026
    Last Update     : August 2026
#>
####################################################################################################
function Invoke-UDFListViewBatchUpdate {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The ListView that will be updated in one paint cycle.')]
        [System.Windows.Forms.ListView]$ListView,

        [Parameter(Mandatory=$true,HelpMessage='The update action that mutates rows/columns.')]
        [System.Management.Automation.ScriptBlock]$Action
    )

    Invoke-ListViewBatchUpdate -ListView $ListView -Action $Action
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Selects a ListView row by matching text in a target subitem.
.DESCRIPTION
    Applies optional clear/focus/scroll behavior while preserving existing selection semantics.
.EXAMPLE
    Set-UDFListViewSelectionByText -ListView $ListView -MatchText 'BuildNumber' -ClearExisting -SetFocus -EnsureVisible
.INPUTS
    The function parameters are described in the parameter block.
.OUTPUTS
    [System.Boolean]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.5
    Author          : Imraan Iotana
    Creation Date   : August 2026
    Last Update     : August 2026
#>
####################################################################################################
function Set-UDFListViewSelectionByText {
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The ListView whose rows will be searched.')]
        [System.Windows.Forms.ListView]$ListView,

        [Parameter(Mandatory=$true,HelpMessage='The text to match in the selected subitem.')]
        [System.String]$MatchText,

        [Parameter(Mandatory=$false,HelpMessage='The subitem index whose text is matched.')]
        [System.Int32]$SubItemIndex = 0,

        [Parameter(Mandatory=$false,HelpMessage='Clears existing selection before selecting the match.')]
        [System.Management.Automation.SwitchParameter]$ClearExisting,

        [Parameter(Mandatory=$false,HelpMessage='Sets keyboard focus on the selected item.')]
        [System.Management.Automation.SwitchParameter]$SetFocus,

        [Parameter(Mandatory=$false,HelpMessage='Scrolls the selected item into view.')]
        [System.Management.Automation.SwitchParameter]$EnsureVisible
    )

    return (Set-ListViewSelectionByText -ListView $ListView -MatchText $MatchText -SubItemIndex $SubItemIndex -ClearExisting:$ClearExisting -SetFocus:$SetFocus -EnsureVisible:$EnsureVisible)
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Resolves a value-cell hit test in a ListView.
.DESCRIPTION
    Returns hit-test metadata only when the clicked cell is in the configured value column and selects the row.
.EXAMPLE
    Get-UDFListViewValueCellHitTest -ListView $ListView -MouseEventArgs $MouseData
.INPUTS
    The function parameters are described in the parameter block.
.OUTPUTS
    [System.Windows.Forms.ListViewHitTestInfo]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.5
    Author          : Imraan Iotana
    Creation Date   : August 2026
    Last Update     : August 2026
#>
####################################################################################################
function Get-UDFListViewValueCellHitTest {
    [CmdletBinding()]
    [OutputType([System.Windows.Forms.ListViewHitTestInfo])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The target ListView that receives the click.')]
        [System.Windows.Forms.ListView]$ListView,

        [Parameter(Mandatory=$true,HelpMessage='Mouse data from a ListView click event.')]
        [System.Windows.Forms.MouseEventArgs]$MouseEventArgs,

        [Parameter(Mandatory=$false,HelpMessage='The column index treated as editable value cell.')]
        [System.Int32]$ValueColumnIndex = 1
    )

    return (Get-ListViewValueCellHitTest -ListView $ListView -MouseEventArgs $MouseEventArgs -ValueColumnIndex $ValueColumnIndex)
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Starts a reusable inline value editor for a ListView value cell.
.DESCRIPTION
    Creates and manages temporary TextBox/ComboBox overlays with Enter/Escape/click-away behavior and shared cleanup.
.EXAMPLE
    Start-UDFListViewInlineValueEditCore -ListView $ListView -HitTestInfo $HitTestInfo -InlineEditorMarker 'UDFInlineEditor' -PropertyName 'BuildNumber' -CurrentValueObject '1' -CurrentValueText '1' -ApplyValueAction { param($Text) } -CompleteInlineEditorsAction { }
.INPUTS
    The function parameters are described in the parameter block.
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.5
    Author          : Imraan Iotana
    Creation Date   : August 2026
    Last Update     : August 2026
#>
####################################################################################################
function Start-UDFListViewInlineValueEditCore {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The ListView that hosts the temporary inline editor overlay.')]
        [System.Windows.Forms.ListView]$ListView,

        [Parameter(Mandatory=$true,HelpMessage='Resolved value-cell hit test metadata.')]
        [System.Windows.Forms.ListViewHitTestInfo]$HitTestInfo,

        [Parameter(Mandatory=$true,HelpMessage='Marker key used by Complete-UDFListViewInlineEditorsByMarker.')]
        [System.String]$InlineEditorMarker,

        [Parameter(Mandatory=$true,HelpMessage='The property label used in status messages.')]
        [System.String]$PropertyName,

        [Parameter(Mandatory=$true,HelpMessage='The current typed value object for editor type resolution.')]
        [AllowNull()]
        [System.Object]$CurrentValueObject,

        [Parameter(Mandatory=$false,HelpMessage='The current value text used to prefill the editor.')]
        [AllowNull()][AllowEmptyString()]
        [System.String]$CurrentValueText,

        [Parameter(Mandatory=$true,HelpMessage='Callback that applies the candidate value text to model/UI.')]
        [System.Management.Automation.ScriptBlock]$ApplyValueAction,

        [Parameter(Mandatory=$true,HelpMessage='Callback that completes all active editors for this ListView context.')]
        [System.Management.Automation.ScriptBlock]$CompleteInlineEditorsAction,

        [Parameter(Mandatory=$false,HelpMessage='Label used in the start edit message, for example "main property".')]
        [System.String]$StartMessageContext = 'property',

        [Parameter(Mandatory=$false,HelpMessage='Optional tag property used to track active inline edits on the ListView tag object.')]
        [System.String]$InlineEditActiveTagName,

        [Parameter(Mandatory=$false,HelpMessage='When set, Escape also cancels from PreviewKeyDown to survive dialog-key interception.')]
        [System.Management.Automation.SwitchParameter]$CancelEscapeInPreview
    )

    try {
        if ([System.String]::IsNullOrWhiteSpace([System.String]$PropertyName)) {
            return
        }

        Write-Line "Editing $StartMessageContext '$PropertyName'. Press Enter to save or Escape to cancel."

        if (Test-String -IsPopulated ([System.String]$InlineEditActiveTagName)) {
            if ($null -eq $ListView.Tag) {
                $ListView.Tag = [PSCustomObject]@{}
            }
            $ListView.Tag | Add-Member -MemberType NoteProperty -Name $InlineEditActiveTagName -Value $false -Force
        }

        [System.String]$LatestEditorText = [System.String]$CurrentValueText
        [System.Windows.Forms.Control]$EditorControl = $null
        [System.Collections.Hashtable]$EditorState = @{ IsCompleted = $false }

        [System.Management.Automation.ScriptBlock]$DisposeEditor = {
            if (Test-String -IsPopulated ([System.String]$InlineEditActiveTagName)) {
                if ($null -eq $ListView.Tag) {
                    $ListView.Tag = [PSCustomObject]@{}
                }
                $ListView.Tag | Add-Member -MemberType NoteProperty -Name $InlineEditActiveTagName -Value $false -Force
            }

            if (($null -ne $EditorControl) -and (-not $EditorControl.IsDisposed)) {
                $EditorControl.Visible = $false
                $ListView.Controls.Remove($EditorControl)
                $EditorControl.Dispose()
                $ListView.Invalidate()
                $ListView.Update()
            }
        }.GetNewClosure()

        [System.Management.Automation.ScriptBlock]$CancelEdit = {
            if ([System.Boolean]$EditorState.IsCompleted) { return }
            $EditorState.IsCompleted = $true

            if (($null -ne $EditorControl) -and ($null -ne $EditorControl.Tag)) {
                $EditorControl.Tag | Add-Member -MemberType NoteProperty -Name IsCanceled -Value $true -Force
            }

            & $DisposeEditor
            & $CompleteInlineEditorsAction

            $ListView.Focus() | Out-Null
            $ListView.Invalidate()
            $ListView.Update()
            Write-Line "Canceled edit for '$PropertyName'."
        }.GetNewClosure()

        [System.Management.Automation.ScriptBlock]$ApplyEdit = {
            param (
                [Parameter(Mandatory=$false)]
                [AllowNull()][AllowEmptyString()]
                [System.String]$CandidateText,

                [Parameter(Mandatory=$false)]
                [System.Boolean]$IsAutoCommit
            )

            if ([System.Boolean]$EditorState.IsCompleted) { return }
            $EditorState.IsCompleted = $true

            [System.String]$NewValueText = if ($null -ne $CandidateText) { [System.String]$CandidateText } else { [System.String]$LatestEditorText }
            if ([System.Boolean]$IsAutoCommit) {
                Write-Line "Focus changed. Auto-saving edit for '$PropertyName'."
            }

            & $DisposeEditor
            & $ApplyValueAction $NewValueText
            & $CompleteInlineEditorsAction

            $ListView.Focus() | Out-Null
            $ListView.Invalidate()
            $ListView.Update()
        }.GetNewClosure()

        if ($CurrentValueObject -is [System.Boolean]) {
            [System.Windows.Forms.ComboBox]$BooleanEditor = New-Object System.Windows.Forms.ComboBox
            $BooleanEditor.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
            [void]$BooleanEditor.Items.Add('True')
            [void]$BooleanEditor.Items.Add('False')
            $BooleanEditor.Text = [System.String]$CurrentValueText

            $BooleanEditor.Add_TextChanged({
                param($ControlSender, $ControlEventArgs)
                $LatestEditorText = [System.String]$ControlSender.Text
            }.GetNewClosure())

            $BooleanEditor.Add_SelectionChangeCommitted({
                param($ControlSender, $ControlEventArgs)
                & $ApplyEdit ([System.String]$ControlSender.Text)
            }.GetNewClosure())

            $BooleanEditor.Add_KeyDown({
                param($ControlSender, $ControlEventArgs)
                if ($ControlEventArgs.KeyCode -eq [System.Windows.Forms.Keys]::Enter) {
                    $ControlEventArgs.Handled = $true
                    $ControlEventArgs.SuppressKeyPress = $true
                    & $ApplyEdit ([System.String]$ControlSender.Text)
                }
                elseif ($ControlEventArgs.KeyCode -eq [System.Windows.Forms.Keys]::Escape) {
                    $ControlEventArgs.Handled = $true
                    $ControlEventArgs.SuppressKeyPress = $true
                    & $CancelEdit
                }
            }.GetNewClosure())

            $BooleanEditor.Add_LostFocus({
                param($ControlSender, $ControlEventArgs)

                if (($null -ne $ControlSender.Tag) -and ($null -ne $ControlSender.Tag.PSObject.Properties['IsCanceled']) -and ([System.Boolean]$ControlSender.Tag.IsCanceled)) {
                    return
                }

                & $ApplyEdit ([System.String]$ControlSender.Text) $true
            }.GetNewClosure())

            $EditorControl = [System.Windows.Forms.Control]$BooleanEditor
        }
        else {
            [System.Windows.Forms.TextBox]$TextEditor = New-Object System.Windows.Forms.TextBox
            $TextEditor.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
            $TextEditor.Text = [System.String]$CurrentValueText

            $TextEditor.Add_TextChanged({
                param($ControlSender, $ControlEventArgs)
                $LatestEditorText = [System.String]$ControlSender.Text
            }.GetNewClosure())

            $TextEditor.Add_PreviewKeyDown({
                param($ControlSender, $ControlEventArgs)
                if (($ControlEventArgs.KeyCode -eq [System.Windows.Forms.Keys]::Enter) -or ($ControlEventArgs.KeyCode -eq [System.Windows.Forms.Keys]::Escape)) {
                    $ControlEventArgs.IsInputKey = $true
                }

                if ($CancelEscapeInPreview -and ($ControlEventArgs.KeyCode -eq [System.Windows.Forms.Keys]::Escape)) {
                    & $CancelEdit
                }
            }.GetNewClosure())

            $TextEditor.Add_KeyDown({
                param($ControlSender, $ControlEventArgs)
                if ($ControlEventArgs.KeyCode -eq [System.Windows.Forms.Keys]::Enter) {
                    $ControlEventArgs.Handled = $true
                    $ControlEventArgs.SuppressKeyPress = $true
                    & $ApplyEdit ([System.String]$ControlSender.Text)
                }
                elseif ($ControlEventArgs.KeyCode -eq [System.Windows.Forms.Keys]::Escape) {
                    $ControlEventArgs.Handled = $true
                    $ControlEventArgs.SuppressKeyPress = $true
                    & $CancelEdit
                }
            }.GetNewClosure())

            $TextEditor.Add_KeyUp({
                param($ControlSender, $ControlEventArgs)
                if ($ControlEventArgs.KeyCode -eq [System.Windows.Forms.Keys]::Escape) {
                    & $CancelEdit
                }
            }.GetNewClosure())

            $TextEditor.Add_LostFocus({
                param($ControlSender, $ControlEventArgs)

                if (($null -ne $ControlSender.Tag) -and ($null -ne $ControlSender.Tag.PSObject.Properties['IsCanceled']) -and ([System.Boolean]$ControlSender.Tag.IsCanceled)) {
                    return
                }

                & $ApplyEdit ([System.String]$ControlSender.Text) $true
            }.GetNewClosure())

            $EditorControl = [System.Windows.Forms.Control]$TextEditor
        }

        $EditorControl.Tag = [PSCustomObject]@{
            InlineEditorMarker = $InlineEditorMarker
            CommitAction       = $ApplyEdit
            CancelAction       = $CancelEdit
        }

        [System.Drawing.Rectangle]$CellBounds = $HitTestInfo.SubItem.Bounds
        [System.Drawing.Rectangle]$EditorBounds = New-Object System.Drawing.Rectangle(($CellBounds.X + 1), ($CellBounds.Y + 1), ([System.Math]::Max(24, ($CellBounds.Width - 2))), ([System.Math]::Max(20, ($CellBounds.Height - 2))))
        $EditorControl.Bounds = $EditorBounds
        $ListView.Controls.Add($EditorControl)
        $EditorControl.BringToFront()
        $EditorControl.Focus() | Out-Null

        if (Test-String -IsPopulated ([System.String]$InlineEditActiveTagName)) {
            $ListView.Tag | Add-Member -MemberType NoteProperty -Name $InlineEditActiveTagName -Value $true -Force
        }

        if ($EditorControl -is [System.Windows.Forms.ComboBox]) {
            ([System.Windows.Forms.ComboBox]$EditorControl).DroppedDown = $true
        }
        elseif ($EditorControl -is [System.Windows.Forms.TextBox]) {
            ([System.Windows.Forms.TextBox]$EditorControl).SelectAll()
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
    Displays main deployment properties in a ListView.
.DESCRIPTION
    Refreshes the main-properties ListView with the current deployment metadata from the source ListView tag.
.EXAMPLE
    Show-UDFMainPropertiesInListView
.INPUTS
    The function parameters are described in the parameter block.
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.4
    Author          : Imraan Iotana
    Creation Date   : August 2026
    Last Update     : August 2026
#>
####################################################################################################
function Show-UDFMainPropertiesInListView {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The source ListView containing deployment-object context and main settings metadata.')]
        [System.Windows.Forms.ListView]$SourceListView,

        [Parameter(Mandatory=$true,HelpMessage='The ListView that will show main DeploymentData settings.')]
        [System.Windows.Forms.ListView]$MainPropertiesListView
    )

    try {
        # PREPARATION - MAIN PROPERTY SOURCE
        # Resolve the stored main-property map from the source list tag.
        [System.Collections.Hashtable]$MainProperties = @{}
        if (($null -ne $SourceListView.Tag) -and ($null -ne $SourceListView.Tag.PSObject.Properties['MainProperties']) -and ($SourceListView.Tag.MainProperties -is [System.Collections.Hashtable])) {
            $MainProperties = [System.Collections.Hashtable]$SourceListView.Tag.MainProperties
        }

        # PREPARATION - DISPLAY ORDER
        # Keep a stable top-level key order in the UI.
        [System.String[]]$DisplayKeys = @('ApplicationID','BuildNumber','SourceFilesFolder')
        [PSCustomObject]$ColorTheme = Get-ListViewColorTheme -ListView $MainPropertiesListView

        # EXECUTION - REFRESH LISTVIEW
        # Rebuild all rows in a single paint cycle.
        Invoke-ListViewBatchUpdate -ListView $MainPropertiesListView -Action {
            $MainPropertiesListView.Items.Clear()

            # EXECUTION - ADD PROPERTY ROWS
            # Add one row per known top-level property.
            foreach ($KeyName in $DisplayKeys) {
                [System.String]$ValueText = ''
                if ($MainProperties.ContainsKey($KeyName)) {
                    $ValueText = [System.String]$MainProperties[$KeyName]
                }

                [System.Windows.Forms.ListViewItem]$PropertyItem = New-Object System.Windows.Forms.ListViewItem($KeyName)
                $null = $PropertyItem.SubItems.Add($ValueText)

                # Style property/value columns for clearer visual separation.
                Set-ListViewKeyValueItemStyle -ListViewItem $PropertyItem -ColorTheme $ColorTheme -ValueSubItemIndex 1 -ValueIsEditable $true

                $null = $MainPropertiesListView.Items.Add($PropertyItem)
            }

            Set-ListViewColumnAutoSize -ListView $MainPropertiesListView -Mode Widest
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
    Synchronizes the selected main property into an editor textbox.
.DESCRIPTION
    Copies the selected main-property value into the supplied textbox so it can be edited inline.
.EXAMPLE
    Set-UDFMainPropertyValueTextBoxFromSelection
.INPUTS
    The function parameters are described in the parameter block.
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.4
    Author          : Imraan Iotana
    Creation Date   : August 2026
    Last Update     : August 2026
#>
####################################################################################################
function Set-UDFMainPropertyValueTextBoxFromSelection {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The ListView that contains main settings rows.')]
        [System.Windows.Forms.ListView]$MainPropertiesListView,

        [Parameter(Mandatory=$true,HelpMessage='The TextBox that displays and edits the selected main setting value.')]
        [System.Windows.Forms.TextBox]$ValueTextBox
    )

    try {
        # PREPARATION - RESET CONTROL STATE
        # Clear value editor when no valid main-property selection exists.
        $ValueTextBox.Text = ''
        $ValueTextBox.Enabled = $false

        # VALIDATION - SELECTED ROW
        # Continue only when a main-property row is selected.
        if ($MainPropertiesListView.SelectedItems.Count -lt 1) {
            return
        }

        [System.Windows.Forms.ListViewItem]$SelectedItem = $MainPropertiesListView.SelectedItems[0]
        if ($SelectedItem.SubItems.Count -lt 2) {
            return
        }

        # EXECUTION - SYNC VALUE
        # Copy selected property value into the editable textbox.
        $ValueTextBox.Text = [System.String]$SelectedItem.SubItems[1].Text
        $ValueTextBox.Enabled = $true
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
    Applies a new value to a selected main property.
.DESCRIPTION
    Updates the main-properties metadata store and refreshes the displayed value after the textbox changes.
.EXAMPLE
    Set-UDFSelectedMainPropertyValueFromTextBox
.INPUTS
    The function parameters are described in the parameter block.
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.4
    Author          : Imraan Iotana
    Creation Date   : August 2026
    Last Update     : August 2026
#>
####################################################################################################
function Set-UDFSelectedMainPropertyValueFromTextBox {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The source ListView that stores main settings metadata in its tag.')]
        [System.Windows.Forms.ListView]$SourceListView,

        [Parameter(Mandatory=$true,HelpMessage='The ListView that contains main settings rows.')]
        [System.Windows.Forms.ListView]$MainPropertiesListView,

        [Parameter(Mandatory=$true,HelpMessage='The TextBox that contains the new main setting value.')]
        [System.Windows.Forms.TextBox]$ValueTextBox
    )

    try {
        # VALIDATION - SELECTED ROW
        # Continue only when a main-property row is selected.
        if ($MainPropertiesListView.SelectedItems.Count -lt 1) {
            Write-Line 'Select a main property first.' -Type Warning
            return
        }

        # PREPARATION - SELECTED PROPERTY
        # Resolve target property name from selected list row.
        [System.Windows.Forms.ListViewItem]$SelectedItem = $MainPropertiesListView.SelectedItems[0]
        [System.String]$PropertyName = [System.String]$SelectedItem.Text
        if ([System.String]::IsNullOrWhiteSpace($PropertyName)) {
            return
        }

        # PREPARATION - NEW VALUE
        # Resolve requested value from the source textbox.
        [System.String]$NewValue = [System.String]$ValueTextBox.Text

        [void](Update-UDFMainPropertyAndUi -SourceListView $SourceListView -MainPropertiesListView $MainPropertiesListView -PropertyName $PropertyName -NewValue $NewValue)
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
    Applies a main-property value and refreshes the ListView UI.
.DESCRIPTION
    Writes the value into source metadata, rebuilds the main-properties ListView, and restores row selection so visual state is fully repainted.
.EXAMPLE
    Update-UDFMainPropertyAndUi -SourceListView $SourceListView -MainPropertiesListView $MainPropertiesListView -PropertyName 'BuildNumber' -NewValue '02'
.INPUTS
    The function parameters are described in the parameter block.
.OUTPUTS
    [System.Boolean]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.4
    Author          : Imraan Iotana
    Creation Date   : August 2026
    Last Update     : August 2026
#>
####################################################################################################
function Update-UDFMainPropertyAndUi {
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The source ListView that stores main settings metadata in its tag.')]
        [System.Windows.Forms.ListView]$SourceListView,

        [Parameter(Mandatory=$true,HelpMessage='The ListView that contains main settings rows.')]
        [System.Windows.Forms.ListView]$MainPropertiesListView,

        [Parameter(Mandatory=$true,HelpMessage='The target main-property key to update.')]
        [System.String]$PropertyName,

        [Parameter(Mandatory=$false,HelpMessage='The new value text to apply.')]
        [AllowNull()][AllowEmptyString()]
        [System.String]$NewValue
    )

    try {
        # VALIDATION - PROPERTY NAME
        # Continue only when the target key is populated.
        if ([System.String]::IsNullOrWhiteSpace([System.String]$PropertyName)) {
            return $false
        }

        # PREPARATION - METADATA STORE
        # Ensure source tag contains a mutable main-properties hashtable.
        if (($null -eq $SourceListView.Tag) -or ($null -eq $SourceListView.Tag.PSObject.Properties['MainProperties']) -or -not ($SourceListView.Tag.MainProperties -is [System.Collections.Hashtable])) {
            [System.String]$ExistingDataFilePath = ''
            [System.Collections.Hashtable]$ExistingInternalCatalog = $null
            if (($null -ne $SourceListView.Tag) -and ($null -ne $SourceListView.Tag.PSObject.Properties['DataFilePath'])) {
                $ExistingDataFilePath = [System.String]$SourceListView.Tag.DataFilePath
            }
            if (($null -ne $SourceListView.Tag) -and ($null -ne $SourceListView.Tag.PSObject.Properties['InternalCatalog']) -and ($SourceListView.Tag.InternalCatalog -is [System.Collections.Hashtable])) {
                $ExistingInternalCatalog = [System.Collections.Hashtable]$SourceListView.Tag.InternalCatalog
            }

            $SourceListView.Tag = [PSCustomObject]@{
                MainProperties  = @{}
                DataFilePath    = $ExistingDataFilePath
                InternalCatalog = $ExistingInternalCatalog
            }
        }

        # PREPARATION - CURRENT AND NEW VALUES
        # Resolve previous and requested values for no-op detection and status output.
        [System.Collections.Hashtable]$MainProperties = [System.Collections.Hashtable]$SourceListView.Tag.MainProperties
        [System.String]$OldValue = [System.String]$(if ($MainProperties.ContainsKey($PropertyName)) { $MainProperties[$PropertyName] } else { '' })
        [System.String]$NewValueText = if ($null -ne $NewValue) { [System.String]$NewValue } else { '' }

        # VALIDATION - NO-OP UPDATE
        # Avoid writing and reporting success when value is unchanged.
        if ([System.String]::Equals($OldValue, $NewValueText, [System.StringComparison]::Ordinal)) {
            Write-Line "No changes saved for '$PropertyName'."
            return $false
        }

        # EXECUTION - APPLY VALUE
        # Write value to metadata store.
        $MainProperties[$PropertyName] = $NewValueText

        # EXECUTION - REFRESH UI
        # Rebuild the list to guarantee clean redraw after inline editor disposal.
        Show-UDFMainPropertiesInListView -SourceListView $SourceListView -MainPropertiesListView $MainPropertiesListView

        [void](Set-ListViewSelectionByText -ListView $MainPropertiesListView -MatchText $PropertyName -SubItemIndex 0 -ClearExisting -SetFocus -EnsureVisible)

        Write-Line "Updated '$PropertyName': '$OldValue' -> '$NewValueText'." -Type Success
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
    Completes any active inline editors in the main-properties ListView.
.DESCRIPTION
    Commits pending inline edits and removes temporary editor controls from the ListView.
.EXAMPLE
    Complete-UDFMainPropertyInlineEditors
.INPUTS
    The function parameters are described in the parameter block.
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.4
    Author          : Imraan Iotana
    Creation Date   : August 2026
    Last Update     : August 2026
#>
####################################################################################################
function Complete-UDFMainPropertyInlineEditors {
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The main-properties ListView that may host active inline editors.')]
        [System.Windows.Forms.ListView]$MainPropertiesListView
    )

    try {
        return (Complete-ListViewInlineEditors -ListView $MainPropertiesListView -InlineEditorMarker 'UDFMainInlineEditor')
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
    Starts inline editing for a main property.
.DESCRIPTION
    Creates a temporary editor control over the selected main-property value cell so the user can edit it directly.
.EXAMPLE
    Start-UDFMainPropertyInlineEditFromListView
.INPUTS
    The function parameters are described in the parameter block.
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.4
    Author          : Imraan Iotana
    Creation Date   : August 2026
    Last Update     : August 2026
#>
####################################################################################################
function Start-UDFMainPropertyInlineEditFromListView {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The source ListView that stores main-properties metadata in its tag.')]
        [System.Windows.Forms.ListView]$SourceListView,

        [Parameter(Mandatory=$true,HelpMessage='The main-properties ListView that contains key/value rows.')]
        [System.Windows.Forms.ListView]$MainPropertiesListView,

        [Parameter(Mandatory=$true,HelpMessage='The mouse event args from the list double-click.')]
        [System.Windows.Forms.MouseEventArgs]$MouseEventArgs
    )

    try {
        [void](Complete-UDFMainPropertyInlineEditors -MainPropertiesListView $MainPropertiesListView)

        # PREPARATION - HIT TEST
        # Resolve clicked row/subitem and continue only for the Value column.
        [System.Windows.Forms.ListViewHitTestInfo]$HitTestInfo = Get-ListViewValueCellHitTest -ListView $MainPropertiesListView -MouseEventArgs $MouseEventArgs -ValueColumnIndex 1
        if ($null -eq $HitTestInfo) {
            return
        }

        # VALIDATION - SELECTED ROW
        # Continue only when a main-property row and key are available.
        if ($MainPropertiesListView.SelectedItems.Count -lt 1) {
            return
        }

        [System.Windows.Forms.ListViewItem]$SelectedItem = [System.Windows.Forms.ListViewItem]$MainPropertiesListView.SelectedItems[0]
        [System.String]$PropertyName = [System.String]$SelectedItem.Text
        if ([System.String]::IsNullOrWhiteSpace($PropertyName)) {
            return
        }

        # PREPARATION - CURRENT VALUE
        # Use the visible Value cell text as inline-editor seed value.
        [System.String]$OldValue = ''
        if ($SelectedItem.SubItems.Count -ge 2) {
            $OldValue = [System.String]$SelectedItem.SubItems[1].Text
        }

        Start-ListViewInlineValueEdit -ListView $MainPropertiesListView -HitTestInfo $HitTestInfo -InlineEditorMarker 'UDFMainInlineEditor' -PropertyName $PropertyName -CurrentValueObject ([System.String]$OldValue) -CurrentValueText $OldValue -StartMessageContext 'main property' -CancelEscapeInPreview -ApplyValueAction {
            param ([System.String]$NewValueText)
            [void](Update-UDFMainPropertyAndUi -SourceListView $SourceListView -MainPropertiesListView $MainPropertiesListView -PropertyName $PropertyName -NewValue $NewValueText)
        }.GetNewClosure() -CompleteInlineEditorsAction {
            [void](Complete-UDFMainPropertyInlineEditors -MainPropertiesListView $MainPropertiesListView)
        }.GetNewClosure()
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
    Builds a display order for deployment object properties.
.DESCRIPTION
    Returns a stable ordering for object properties using the preferred source order first and then the remaining keys.
.EXAMPLE
    Get-UDFDeploymentObjectDisplayKeyOrder
.INPUTS
    The function parameters are described in the parameter block.
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.4
    Author          : Imraan Iotana
    Creation Date   : August 2026
    Last Update     : August 2026
#>
####################################################################################################
function Get-UDFDeploymentObjectDisplayKeyOrder {
    [CmdletBinding()]
    [OutputType([System.String[]])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The selected deployment object.')]
        [System.Collections.Hashtable]$DeploymentObject,

        [Parameter(Mandatory=$false,HelpMessage='Optional preferred key order from source text parsing.')]
        [System.String[]]$PreferredOrder
    )

    # PREPARATION - OUTPUT LIST
    # Create the output list used to build the final display order.
    [System.Collections.Generic.List[System.String]]$DisplayKeyOrder = New-Object 'System.Collections.Generic.List[System.String]'

    # EXECUTION - PREFERRED ORDER
    # Add preferred keys first when they exist on the object.
    if ($PreferredOrder.Count -gt 0) {
        foreach ($KeyName in $PreferredOrder) {
            if ($DeploymentObject.ContainsKey($KeyName) -and -not $DisplayKeyOrder.Contains($KeyName)) {
                $DisplayKeyOrder.Add($KeyName) | Out-Null
            }
        }
    }

    # EXECUTION - REMAINING KEYS
    # Append any remaining keys that were not present in preferred order.
    foreach ($KeyName in $DeploymentObject.Keys) {
        [System.String]$KeyAsString = [System.String]$KeyName
        if (-not $DisplayKeyOrder.Contains($KeyAsString)) {
            $DisplayKeyOrder.Add($KeyAsString) | Out-Null
        }
    }

    # OUTPUT - ORDERED KEYS
    # Return the final ordered key list.
    return $DisplayKeyOrder.ToArray()
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Converts a deployment object property value to display text.
.DESCRIPTION
    Formats scalar and array values into the text shown in the properties ListView.
.EXAMPLE
    Convert-UDFDeploymentObjectPropertyValueToText
.INPUTS
    The function parameters are described in the parameter block.
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.4
    Author          : Imraan Iotana
    Creation Date   : August 2026
    Last Update     : August 2026
#>
####################################################################################################
function Convert-UDFDeploymentObjectPropertyValueToText {
    [CmdletBinding()]
    [OutputType([System.String])]
    param (
        [Parameter(Mandatory=$false,HelpMessage='The property value object to convert to display text.')]
        [AllowNull()]
        [System.Object]$PropertyValueObject
    )

    # EXECUTION - ARRAY TO STRING
    # Join array values using comma separators for display.
    if ($PropertyValueObject -is [System.Array]) {
        return (($PropertyValueObject | ForEach-Object { [System.String]$_ }) -join ', ')
    }

    # VALIDATION - NULL VALUE
    # Return an empty display value when source value is null.
    if ($null -eq $PropertyValueObject) {
        return ''
    }

    # OUTPUT - STRING VALUE
    # Convert remaining scalar values directly to string.
    return [System.String]$PropertyValueObject
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Creates a summary string for a deployment object.
.DESCRIPTION
    Returns a concise summary derived from the most meaningful deployment object properties.
.EXAMPLE
    Get-UDFDeploymentObjectSummaryText
.INPUTS
    The function parameters are described in the parameter block.
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.4
    Author          : Imraan Iotana
    Creation Date   : August 2026
    Last Update     : August 2026
#>
####################################################################################################
function Get-UDFDeploymentObjectSummaryText {
    [CmdletBinding()]
    [OutputType([System.String])]
    param (
        [Parameter(Mandatory=$false,HelpMessage='The deployment object used to generate summary text.')]
        [System.Collections.Hashtable]$DeploymentObject
    )

    # VALIDATION - INPUT OBJECT
    # Return a default placeholder when no object is provided.
    if ($null -eq $DeploymentObject) {
        return '(no details)'
    }

    # PREPARATION - PREFERRED SUMMARY KEYS
    # Check known summary keys first in stable order.
    [System.String[]]$SummaryKeys = @(
        'MSIFileName','ZipFileName','FolderToCopy','FileToCopy','DisplayName',
        'REGFileName','ShortcutFileName','Directory','DestinationFolder','SecondsToPause'
    )

    # EXECUTION - PREFERRED SUMMARY
    # Return the first populated preferred key/value pair.
    foreach ($KeyName in $SummaryKeys) {
        if ($DeploymentObject.ContainsKey($KeyName)) {
            [System.String]$ValueText = Convert-UDFDeploymentObjectPropertyValueToText -PropertyValueObject $DeploymentObject[$KeyName]
            if (Test-String -IsPopulated $ValueText) {
                return "$KeyName=$ValueText"
            }
        }
    }

    # EXECUTION - FALLBACK SUMMARY
    # Fallback to first populated non-Type key.
    foreach ($KeyName in $DeploymentObject.Keys) {
        if ([System.String]$KeyName -eq 'Type') { continue }
        [System.String]$ValueText = Convert-UDFDeploymentObjectPropertyValueToText -PropertyValueObject $DeploymentObject[$KeyName]
        if (Test-String -IsPopulated $ValueText) {
            return "$KeyName=$ValueText"
        }
    }

    # OUTPUT - SUMMARY TEXT
    # Return default placeholder when no summary value can be resolved.
    return '(no details)'
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Builds the current deployment-object selection context.
.DESCRIPTION
    Resolves the currently selected deployment object and property so callers can perform editing operations consistently.
.EXAMPLE
    Get-UDFDeploymentObjectSelectionContext
.INPUTS
    The function parameters are described in the parameter block.
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.4
    Author          : Imraan Iotana
    Creation Date   : August 2026
    Last Update     : August 2026
#>
####################################################################################################
function Get-UDFDeploymentObjectSelectionContext {
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSCustomObject])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The source ListView that contains deployment objects.')]
        [System.Windows.Forms.ListView]$SourceListView,

        [Parameter(Mandatory=$true,HelpMessage='The properties ListView that shows the selected object properties.')]
        [System.Windows.Forms.ListView]$PropertiesListView
    )

    try {
        # PREPARATION - DEFAULT RESULT
        # Build a stable, fully populated context object so callers can read one shape.
        [PSCustomObject]$SelectionContext = [PSCustomObject]@{
            HasSelection           = $false
            HasValidPropertyName   = $false
            PropertyName           = $null
            SelectedObjectItem     = $null
            SelectedPropertyItem   = $null
            DeploymentObject       = $null
        }

        # VALIDATION - SELECTION
        # Continue only when both list views have a selected row.
        if (($SourceListView.SelectedItems.Count -lt 1) -or ($PropertiesListView.SelectedItems.Count -lt 1)) {
            return $SelectionContext
        }

        # PREPARATION - CURRENT SELECTION
        # Resolve selected object row and selected property row.
        [System.Windows.Forms.ListViewItem]$SelectedObjectItem = $SourceListView.SelectedItems[0]
        [System.Windows.Forms.ListViewItem]$SelectedPropertyItem = $PropertiesListView.SelectedItems[0]
        [System.String]$PropertyName = [System.String]$SelectedPropertyItem.Text

        $SelectionContext.HasSelection = $true
        $SelectionContext.PropertyName = $PropertyName
        $SelectionContext.SelectedObjectItem = $SelectedObjectItem
        $SelectionContext.SelectedPropertyItem = $SelectedPropertyItem

        # VALIDATION - PROPERTY NAME
        # Stop when the selected property name is empty.
        if ([System.String]::IsNullOrWhiteSpace($PropertyName)) {
            return $SelectionContext
        }

        $SelectionContext.HasValidPropertyName = $true

        # PREPARATION - DEPLOYMENT OBJECT
        # Resolve the selected deployment object from the source row tag.
        [System.Collections.Hashtable]$DeploymentObject = [System.Collections.Hashtable](Get-UDFDeploymentObjectItemEntry -SourceItem $SelectedObjectItem).DeploymentObject

        # VALIDATION - RESOLVED PROPERTY
        # Stop when the selected deployment object does not expose this key.
        if (($null -eq $DeploymentObject) -or (-not $DeploymentObject.ContainsKey($PropertyName))) {
            return $SelectionContext
        }

        $SelectionContext.DeploymentObject = $DeploymentObject
        return $SelectionContext
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
        return [PSCustomObject]@{
            HasSelection           = $false
            HasValidPropertyName   = $false
            PropertyName           = $null
            SelectedObjectItem     = $null
            SelectedPropertyItem   = $null
            DeploymentObject       = $null
        }
    }
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Determines whether a deployment object property is editable.
.DESCRIPTION
    Returns false for immutable properties such as Type and true for values that can be edited in the UI.
.EXAMPLE
    Test-UDFDeploymentObjectPropertyCanBeEdited
.INPUTS
    The function parameters are described in the parameter block.
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.4
    Author          : Imraan Iotana
    Creation Date   : August 2026
    Last Update     : August 2026
#>
####################################################################################################
function Test-UDFDeploymentObjectPropertyCanBeEdited {
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The property name to test for editability.')]
        [AllowEmptyString()]
        [System.String]$PropertyName
    )

    # OUTPUT - EDITABILITY RESULT
    # Keep Type immutable and allow editing all other properties.
    return ($PropertyName -ne 'Type')
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Retrieves the internal catalog from the source ListView tag.
.DESCRIPTION
    Returns the catalog metadata stored on the source ListView when it is available.
.EXAMPLE
    Get-UDFDeploymentObjectInternalCatalogFromSourceListView
.INPUTS
    The function parameters are described in the parameter block.
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.4
    Author          : Imraan Iotana
    Creation Date   : August 2026
    Last Update     : August 2026
#>
####################################################################################################
function Get-UDFDeploymentObjectInternalCatalogFromSourceListView {
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The source ListView that may store internal catalog metadata in its tag.')]
        [System.Windows.Forms.ListView]$SourceListView
    )

    # OUTPUT - INTERNAL CATALOG
    # Return loaded _Catalog metadata when available.
    if (($null -ne $SourceListView.Tag) -and ($null -ne $SourceListView.Tag.PSObject.Properties['InternalCatalog']) -and ($SourceListView.Tag.InternalCatalog -is [System.Collections.Hashtable])) {
        return [System.Collections.Hashtable]$SourceListView.Tag.InternalCatalog
    }

    return $null
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Resolves display metadata for a deployment object field.
.DESCRIPTION
    Looks up field metadata from the internal catalog for the selected deployment object and property name.
.EXAMPLE
    Get-UDFDeploymentObjectFieldMetadata
.INPUTS
    The function parameters are described in the parameter block.
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.4
    Author          : Imraan Iotana
    Creation Date   : August 2026
    Last Update     : August 2026
#>
####################################################################################################
function Get-UDFDeploymentObjectFieldMetadata {
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSCustomObject])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The source ListView that may contain internal catalog metadata.')]
        [System.Windows.Forms.ListView]$SourceListView,

        [Parameter(Mandatory=$true,HelpMessage='The selected deployment object whose field metadata should be resolved.')]
        [System.Collections.Hashtable]$DeploymentObject,

        [Parameter(Mandatory=$true,HelpMessage='The property name whose metadata should be resolved.')]
        [System.String]$PropertyName
    )

    # PREPARATION - DEFAULT RESULT
    # Return one stable object shape even when no catalog metadata exists.
    [PSCustomObject]$DefaultMetadata = [PSCustomObject]@{
        DisplayType = ''
        Description = ''
    }

    # VALIDATION - PROPERTY INPUT
    # Stop when property name or deployment object is missing.
    if (($null -eq $DeploymentObject) -or ([System.String]::IsNullOrWhiteSpace($PropertyName))) {
        return $DefaultMetadata
    }

    [System.Collections.Hashtable]$InternalCatalog = Get-UDFDeploymentObjectInternalCatalogFromSourceListView -SourceListView $SourceListView
    if (($null -eq $InternalCatalog) -or (-not $InternalCatalog.ContainsKey('ObjectTypes')) -or ($null -eq $InternalCatalog.ObjectTypes)) {
        return $DefaultMetadata
    }

    [System.String]$ObjectTypeName = ''
    if ($DeploymentObject.ContainsKey('Type')) {
        $ObjectTypeName = [System.String]$DeploymentObject['Type']
    }

    # VALIDATION - TYPE DEFINITION
    # Stop when the selected object type is absent from the catalog.
    if ([System.String]::IsNullOrWhiteSpace($ObjectTypeName) -or (-not $InternalCatalog.ObjectTypes.ContainsKey($ObjectTypeName))) {
        return $DefaultMetadata
    }

    # EXECUTION - FIELD LOOKUP
    # Resolve display metadata from the matching field definition.
    [System.Collections.Hashtable]$TypeDefinition = [System.Collections.Hashtable]$InternalCatalog.ObjectTypes[$ObjectTypeName]
    foreach ($FieldDefinition in @($TypeDefinition.Fields)) {
        if (($null -eq $FieldDefinition) -or (-not $FieldDefinition.ContainsKey('Name'))) {
            continue
        }

        if (-not [System.String]::Equals([System.String]$FieldDefinition.Name, $PropertyName, [System.StringComparison]::Ordinal)) {
            continue
        }

        return [PSCustomObject]@{
            DisplayType = [System.String]$(if ($FieldDefinition.ContainsKey('DisplayType')) { $FieldDefinition.DisplayType } else { '' })
            Description = [System.String]$(if ($FieldDefinition.ContainsKey('Description')) { $FieldDefinition.Description } else { '' })
        }
    }

    return $DefaultMetadata
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Displays deployment object properties in a ListView.
.DESCRIPTION
    Refreshes the properties ListView with the selected deployment object and its field metadata.
.EXAMPLE
    Show-UDFDeploymentObjectPropertiesInListView
.INPUTS
    The function parameters are described in the parameter block.
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.4
    Author          : Imraan Iotana
    Creation Date   : August 2026
    Last Update     : August 2026
#>
####################################################################################################
function Show-UDFDeploymentObjectPropertiesInListView {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The ListView containing DeploymentObject rows.')]
        [System.Windows.Forms.ListView]$SourceListView,

        [Parameter(Mandatory=$true,HelpMessage='The ListView that will show key/value properties.')]
        [System.Windows.Forms.ListView]$PropertiesListView
    )

    try {
        # VALIDATION - INLINE EDIT STATE
        # Skip refresh while an inline editor is active to avoid overwriting in-flight edits.
        if (($null -ne $PropertiesListView.Tag) -and ($null -ne $PropertiesListView.Tag.PSObject.Properties['UDFInlineEditActive']) -and ([System.Boolean]$PropertiesListView.Tag.UDFInlineEditActive)) {
            return
        }

        # PREPARATION - SELECTED OBJECT
        # Resolve the selected deployment object and optional preferred key order from row tag.
        [System.Collections.Hashtable]$SelectedDeploymentObject = $null
        [System.String[]]$PreferredPropertyOrder = @()
        if (($null -ne $SourceListView.SelectedItems) -and ($SourceListView.SelectedItems.Count -gt 0)) {
            [PSCustomObject]$ItemEntry = Get-UDFDeploymentObjectItemEntry -SourceItem $SourceListView.SelectedItems[0]
            $SelectedDeploymentObject = [System.Collections.Hashtable]$ItemEntry.DeploymentObject
            $PreferredPropertyOrder = [System.String[]]$ItemEntry.PreferredPropertyOrder
        }
        [PSCustomObject]$ColorTheme = Get-ListViewColorTheme -ListView $PropertiesListView

        # EXECUTION - REFRESH LISTVIEW
        # Refresh the properties list in one paint cycle.
        Invoke-ListViewBatchUpdate -ListView $PropertiesListView -Action {
            $PropertiesListView.Items.Clear()

            # VALIDATION - SELECTED OBJECT
            # Stop when no object is selected and keep column sizing consistent.
            if ($null -eq $SelectedDeploymentObject) {
                Set-ListViewColumnAutoSize -ListView $PropertiesListView -Mode Widest
                return
            }

            # PREPARATION - DISPLAY ORDER
            # Resolve key order used for display.
            [System.String[]]$DisplayKeyOrder = Get-UDFDeploymentObjectDisplayKeyOrder -DeploymentObject $SelectedDeploymentObject -PreferredOrder $PreferredPropertyOrder

            # EXECUTION - ADD PROPERTY ROWS
            # Add one row per property key/value.
            foreach ($KeyName in $DisplayKeyOrder) {
                [System.Object]$PropertyValueObject = $SelectedDeploymentObject[$KeyName]
                [System.String]$PropertyValueText = Convert-UDFDeploymentObjectPropertyValueToText -PropertyValueObject $PropertyValueObject
                [PSCustomObject]$FieldMetadata = Get-UDFDeploymentObjectFieldMetadata -SourceListView $SourceListView -DeploymentObject $SelectedDeploymentObject -PropertyName ([System.String]$KeyName)
                [System.String]$InfoText = [System.String]$FieldMetadata.DisplayType

                [System.Windows.Forms.ListViewItem]$PropertyItem = New-Object System.Windows.Forms.ListViewItem([System.String]$KeyName)
                $null = $PropertyItem.SubItems.Add($PropertyValueText)
                $null = $PropertyItem.SubItems.Add($InfoText)
                if (Test-String -IsPopulated ([System.String]$FieldMetadata.Description)) {
                    $PropertyItem.ToolTipText = [System.String]$FieldMetadata.Description
                }

                # Style property/value columns for clearer visual separation.
                [System.Boolean]$ValueIsEditable = (Test-UDFDeploymentObjectPropertyCanBeEdited -PropertyName ([System.String]$KeyName))
                Set-ListViewKeyValueItemStyle -ListViewItem $PropertyItem -ColorTheme $ColorTheme -ValueSubItemIndex 1 -ValueIsEditable $ValueIsEditable
                if ($PropertyItem.SubItems.Count -gt 2) {
                    $PropertyItem.SubItems[2].BackColor = [System.Drawing.Color]$ColorTheme.ReadOnlyBackColor
                    $PropertyItem.SubItems[2].ForeColor = [System.Drawing.Color]$ColorTheme.ReadOnlyTextColor
                }

                $null = $PropertiesListView.Items.Add($PropertyItem)
            }

            # POST-EXECUTION - FINALIZE COLUMNS
            # Apply final column sizing after all rows are added.
            Set-ListViewColumnAutoSize -ListView $PropertiesListView -Mode Widest
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
    Updates a deployment object property and refreshes the editor UI.
.DESCRIPTION
    Writes a new value to the selected deployment object and refreshes the properties ListView and summary column.
.EXAMPLE
    Update-UDFDeploymentObjectPropertyAndUi
.INPUTS
    The function parameters are described in the parameter block.
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.4
    Author          : Imraan Iotana
    Creation Date   : August 2026
    Last Update     : August 2026
#>
####################################################################################################
function Update-UDFDeploymentObjectPropertyAndUi {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The source ListView that contains deployment objects.')]
        [System.Windows.Forms.ListView]$SourceListView,

        [Parameter(Mandatory=$true,HelpMessage='The properties ListView that will be refreshed after the update.')]
        [System.Windows.Forms.ListView]$PropertiesListView,

        [Parameter(Mandatory=$true,HelpMessage='The resolved selection context for the current object and property.')]
        [System.Object]$SelectionContext,

        [Parameter(Mandatory=$true,HelpMessage='The new value object to write into the selected property.')]
        [AllowNull()]
        [System.Object]$NewValueObject,

        [Parameter(Mandatory=$false,HelpMessage='The previous value text used for the status message.')]
        [AllowEmptyString()]
        [System.String]$OldValueText,

        [Parameter(Mandatory=$false,HelpMessage='The applied value text used for the status message.')]
        [AllowEmptyString()]
        [System.String]$AppliedNewValueText,

        [Parameter(Mandatory=$false,HelpMessage='Optional script block that runs after the UI refresh completes.')]
        [System.Management.Automation.ScriptBlock]$PostRefreshAction
    )

    try {
        # VALIDATION - SELECTION CONTEXT
        # Require a resolved deployment object and property name.
        if (($null -eq $SelectionContext) -or ($null -eq $SelectionContext.DeploymentObject) -or ([System.String]::IsNullOrWhiteSpace([System.String]$SelectionContext.PropertyName))) {
            return
        }

        if ([System.String]::Equals([System.String]$OldValueText, [System.String]$AppliedNewValueText, [System.StringComparison]::Ordinal)) {
            Write-Line "No changes saved for '$([System.String]$SelectionContext.PropertyName)'."
            return
        }

        # EXECUTION - APPLY VALUE
        # Write the converted value to the selected deployment object property.
        $SelectionContext.DeploymentObject[$SelectionContext.PropertyName] = $NewValueObject

        # EXECUTION - REFRESH UI
        # Refresh property rows, preserve selected property, and refresh object summary.
        [System.String]$SelectedPropertyName = [System.String]$SelectionContext.PropertyName
        Show-UDFDeploymentObjectPropertiesInListView -SourceListView $SourceListView -PropertiesListView $PropertiesListView

        [void](Set-ListViewSelectionByText -ListView $PropertiesListView -MatchText $SelectedPropertyName -SubItemIndex 0)

        if (($null -ne $SelectionContext.SelectedObjectItem) -and ($SelectionContext.SelectedObjectItem.SubItems.Count -ge 3)) {
            $SelectionContext.SelectedObjectItem.SubItems[2].Text = Get-UDFDeploymentObjectSummaryText -DeploymentObject $SelectionContext.DeploymentObject
        }

        # POST-EXECUTION - OPTIONAL REFRESH
        # Re-run any caller-specific refresh and report a detailed change message.
        if ($null -ne $PostRefreshAction) {
            & $PostRefreshAction
        }

        Set-ListViewColumnAutoSize -ListView $PropertiesListView -Mode Widest
        Write-Line "Updated '$([System.String]$SelectionContext.PropertyName)': '$OldValueText' -> '$AppliedNewValueText'." -Type Success
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
    Synchronizes the selected property into a ComboBox editor.
.DESCRIPTION
    Populates the value ComboBox with the selected deployment object property and configures editability rules.
.EXAMPLE
    Set-UDFPropertyValueComboFromSelection
.INPUTS
    The function parameters are described in the parameter block.
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.4
    Author          : Imraan Iotana
    Creation Date   : August 2026
    Last Update     : August 2026
#>
####################################################################################################
function Set-UDFPropertyValueComboFromSelection {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The source ListView that contains deployment objects.')]
        [System.Windows.Forms.ListView]$SourceListView,

        [Parameter(Mandatory=$true,HelpMessage='The properties ListView that contains the selected property row.')]
        [System.Windows.Forms.ListView]$PropertiesListView,

        [Parameter(Mandatory=$true,HelpMessage='The ComboBox that displays and edits the selected property value.')]
        [System.Windows.Forms.ComboBox]$ValueComboBox
    )

    try {
        # PREPARATION - RESET CONTROL STATE
        # Clear state when no valid selection is available.
        $ValueComboBox.Text = ''
        $ValueComboBox.Enabled = $false

        # Keep existing ComboBox tag metadata intact (it is used by generic settings binding).
        if ($null -eq $ValueComboBox.Tag) {
            $ValueComboBox.Tag = [PSCustomObject]@{}
        }
        $ValueComboBox.Tag | Add-Member -MemberType NoteProperty -Name SelectedUDFPropertyName -Value '' -Force

        # PREPARATION - SELECTION CONTEXT
        # Reuse the shared selection context helper to avoid duplicate object/property resolution.
        [PSCustomObject]$SelectionContext = Get-UDFDeploymentObjectSelectionContext -SourceListView $SourceListView -PropertiesListView $PropertiesListView

        # VALIDATION - SELECTION
        # Continue only when both list views have a valid resolved selection.
        if ((-not $SelectionContext.HasSelection) -or (-not $SelectionContext.HasValidPropertyName) -or ($null -eq $SelectionContext.DeploymentObject)) {
            return
        }

        Write-Line "Editing object property '$([System.String]$SelectionContext.PropertyName)'. Press Enter to save or Escape to cancel."

        # EXECUTION - ENFORCE EDITABLE ROW SELECTION
        # Keep read-only rows (for example Type) unselected by moving focus to the first editable row.
        if (-not (Test-UDFDeploymentObjectPropertyCanBeEdited -PropertyName $SelectionContext.PropertyName)) {
            [System.Windows.Forms.ListViewItem]$FirstEditableItem = $null
            foreach ($Item in $PropertiesListView.Items) {
                [System.String]$ItemPropertyName = [System.String]$Item.Text
                if (Test-UDFDeploymentObjectPropertyCanBeEdited -PropertyName $ItemPropertyName) {
                    $FirstEditableItem = [System.Windows.Forms.ListViewItem]$Item
                    break
                }
            }

            if (($null -ne $FirstEditableItem) -and ($FirstEditableItem -ne $SelectionContext.SelectedPropertyItem)) {
                $PropertiesListView.SelectedIndices.Clear()
                $FirstEditableItem.Selected = $true
                $FirstEditableItem.Focused = $true
                $FirstEditableItem.EnsureVisible()

                $SelectionContext = Get-UDFDeploymentObjectSelectionContext -SourceListView $SourceListView -PropertiesListView $PropertiesListView
                if ((-not $SelectionContext.HasSelection) -or (-not $SelectionContext.HasValidPropertyName) -or ($null -eq $SelectionContext.DeploymentObject)) {
                    return
                }
            }
        }

        # EXECUTION - SYNC VALUE
        # Write the current property value into the ComboBox and store selected metadata.
        [System.Object]$CurrentValueObject = $SelectionContext.DeploymentObject[$SelectionContext.PropertyName]
        [System.String]$CurrentValueText = Convert-UDFDeploymentObjectPropertyValueToText -PropertyValueObject $CurrentValueObject

        # EXECUTION - CONFIGURE BOOLEAN PICKLIST
        # Use strict True/False selection for boolean properties and free text for all others.
        $ValueComboBox.Items.Clear()
        if ($CurrentValueObject -is [System.Boolean]) {
            $ValueComboBox.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
            [void]$ValueComboBox.Items.Add('True')
            [void]$ValueComboBox.Items.Add('False')
            $ValueComboBox.AutoCompleteMode = [System.Windows.Forms.AutoCompleteMode]::None
            $ValueComboBox.AutoCompleteSource = [System.Windows.Forms.AutoCompleteSource]::None
        }
        else {
            $ValueComboBox.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDown
            $ValueComboBox.AutoCompleteMode = [System.Windows.Forms.AutoCompleteMode]::SuggestAppend
            $ValueComboBox.AutoCompleteSource = [System.Windows.Forms.AutoCompleteSource]::ListItems
        }

        $ValueComboBox.Tag | Add-Member -MemberType NoteProperty -Name SelectedUDFPropertyName -Value $SelectionContext.PropertyName -Force
        $ValueComboBox.Text = $CurrentValueText

        # EXECUTION - APPLY EDITABILITY RULES
        # Keep Type immutable; other properties remain editable.
        if (-not (Test-UDFDeploymentObjectPropertyCanBeEdited -PropertyName $SelectionContext.PropertyName)) {
            $ValueComboBox.Enabled = $false
        }
        else {
            $ValueComboBox.Enabled = $true
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
    Toggles a boolean deployment object property from the ListView UI.
.DESCRIPTION
    Switches the value of a boolean property between true and false in response to selection changes.
.EXAMPLE
    Switch-UDFSelectedBooleanPropertyValueFromListView
.INPUTS
    The function parameters are described in the parameter block.
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.4
    Author          : Imraan Iotana
    Creation Date   : August 2026
    Last Update     : August 2026
#>
####################################################################################################
function Switch-UDFSelectedBooleanPropertyValueFromListView {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The source ListView that contains deployment objects.')]
        [System.Windows.Forms.ListView]$SourceListView,

        [Parameter(Mandatory=$true,HelpMessage='The properties ListView that contains the selected property row.')]
        [System.Windows.Forms.ListView]$PropertiesListView,

        [Parameter(Mandatory=$true,HelpMessage='The ComboBox that reflects the selected property value.')]
        [System.Windows.Forms.ComboBox]$ValueComboBox
    )

    try {
        # PREPARATION - SELECTION CONTEXT
        # Resolve current object/property selection before applying a boolean toggle.
        [PSCustomObject]$SelectionContext = Get-UDFDeploymentObjectSelectionContext -SourceListView $SourceListView -PropertiesListView $PropertiesListView

        # VALIDATION - SELECTION
        # Continue only when both list views have a valid resolved selection.
        if ((-not $SelectionContext.HasSelection) -or (-not $SelectionContext.HasValidPropertyName) -or ($null -eq $SelectionContext.DeploymentObject)) {
            return
        }

        # VALIDATION - PROTECTED PROPERTY
        # Keep Type immutable in direct-list toggles as well.
        if (-not (Test-UDFDeploymentObjectPropertyCanBeEdited -PropertyName $SelectionContext.PropertyName)) {
            return
        }

        # VALIDATION - VALUE TYPE
        # Toggle only when the selected value is a boolean.
        [System.Object]$CurrentValueObject = $SelectionContext.DeploymentObject[$SelectionContext.PropertyName]
        if (-not ($CurrentValueObject -is [System.Boolean])) {
            return
        }

        # EXECUTION - TOGGLE BOOLEAN VALUE
        # Flip True/False and reuse the shared update/refresh helper.
        [System.String]$OldValueText = Convert-UDFDeploymentObjectPropertyValueToText -PropertyValueObject $CurrentValueObject
        [System.Object]$NewValueObject = -not [System.Boolean]$CurrentValueObject
        [System.String]$AppliedNewValueText = Convert-UDFDeploymentObjectPropertyValueToText -PropertyValueObject $NewValueObject

        Update-UDFDeploymentObjectPropertyAndUi -SourceListView $SourceListView -PropertiesListView $PropertiesListView -SelectionContext $SelectionContext -NewValueObject $NewValueObject -OldValueText $OldValueText -AppliedNewValueText $AppliedNewValueText -PostRefreshAction {
            Set-UDFPropertyValueComboFromSelection -SourceListView $SourceListView -PropertiesListView $PropertiesListView -ValueComboBox $ValueComboBox
        }.GetNewClosure()
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
    Completes any active inline editors in the properties ListView.
.DESCRIPTION
    Commits pending inline edits and removes temporary editor controls from the properties ListView.
.EXAMPLE
    Complete-UDFDeploymentObjectInlineEditors
.INPUTS
    The function parameters are described in the parameter block.
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.4
    Author          : Imraan Iotana
    Creation Date   : August 2026
    Last Update     : August 2026
#>
####################################################################################################
function Complete-UDFDeploymentObjectInlineEditors {
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The properties ListView that may host active inline editors.')]
        [System.Windows.Forms.ListView]$PropertiesListView
    )

    try {
        return (Complete-ListViewInlineEditors -ListView $PropertiesListView -InlineEditorMarker 'UDFInlineEditor')
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
    Starts inline editing for a deployment object property.
.DESCRIPTION
    Creates a temporary editor control over the selected property cell so the user can edit it directly.
.EXAMPLE
    Start-UDFDeploymentObjectInlineEditFromListView
.INPUTS
    The function parameters are described in the parameter block.
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.4
    Author          : Imraan Iotana
    Creation Date   : August 2026
    Last Update     : August 2026
#>
####################################################################################################
function Start-UDFDeploymentObjectInlineEditFromListView {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The source ListView that contains deployment objects.')]
        [System.Windows.Forms.ListView]$SourceListView,

        [Parameter(Mandatory=$true,HelpMessage='The properties ListView that contains key/value rows.')]
        [System.Windows.Forms.ListView]$PropertiesListView,

        [Parameter(Mandatory=$true,HelpMessage='The mouse event args from the list double-click.')]
        [System.Windows.Forms.MouseEventArgs]$MouseEventArgs
    )

    try {
        # PREPARATION - CLEANUP EXISTING INLINE EDITORS
        # Ensure any previous inline editor overlays are removed before starting a new edit.
        [void](Complete-UDFDeploymentObjectInlineEditors -PropertiesListView $PropertiesListView)

        # PREPARATION - HIT TEST
        # Resolve clicked row/subitem and continue only for the Value column.
        [System.Windows.Forms.ListViewHitTestInfo]$HitTestInfo = Get-ListViewValueCellHitTest -ListView $PropertiesListView -MouseEventArgs $MouseEventArgs -ValueColumnIndex 1
        if ($null -eq $HitTestInfo) {
            return
        }

        # PREPARATION - SELECTION CONTEXT
        # Resolve selected deployment object + property metadata.
        [PSCustomObject]$SelectionContext = Get-UDFDeploymentObjectSelectionContext -SourceListView $SourceListView -PropertiesListView $PropertiesListView
        if ((-not $SelectionContext.HasSelection) -or (-not $SelectionContext.HasValidPropertyName) -or ($null -eq $SelectionContext.DeploymentObject)) {
            return
        }

        [System.String]$PropertyName = [System.String]$SelectionContext.PropertyName
        if ([System.String]::IsNullOrWhiteSpace($PropertyName)) {
            return
        }

        # VALIDATION - PROTECTED PROPERTY
        # Keep Type immutable in inline edit mode.
        if (-not (Test-UDFDeploymentObjectPropertyCanBeEdited -PropertyName $PropertyName)) {
            return
        }

        # PREPARATION - CURRENT VALUE
        # Resolve the current value to prefill the inline editor.
        [System.Object]$CurrentValueObject = $SelectionContext.DeploymentObject[$PropertyName]
        [System.String]$CurrentValueText = Convert-UDFDeploymentObjectPropertyValueToText -PropertyValueObject $CurrentValueObject

        Start-ListViewInlineValueEdit -ListView $PropertiesListView -HitTestInfo $HitTestInfo -InlineEditorMarker 'UDFInlineEditor' -PropertyName $PropertyName -CurrentValueObject $CurrentValueObject -CurrentValueText $CurrentValueText -StartMessageContext 'object property' -InlineEditActiveTagName 'UDFInlineEditActive' -ApplyValueAction {
            param ([System.String]$NewValueText)
            [System.Object]$NewValueObject = Convert-UDFTextToDeploymentObjectPropertyValue -CurrentValueObject $CurrentValueObject -InputText $NewValueText
            [System.String]$OldValueText = Convert-UDFDeploymentObjectPropertyValueToText -PropertyValueObject $CurrentValueObject
            [System.String]$AppliedNewValueText = Convert-UDFDeploymentObjectPropertyValueToText -PropertyValueObject $NewValueObject

            Update-UDFDeploymentObjectPropertyAndUi -SourceListView $SourceListView -PropertiesListView $PropertiesListView -SelectionContext $SelectionContext -NewValueObject $NewValueObject -OldValueText $OldValueText -AppliedNewValueText $AppliedNewValueText
        }.GetNewClosure() -CompleteInlineEditorsAction {
            [void](Complete-UDFDeploymentObjectInlineEditors -PropertiesListView $PropertiesListView)
        }.GetNewClosure()
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
    Completes inline editors in a ListView for a specific marker.
.DESCRIPTION
    Commits pending inline edits and removes temporary editor controls that match the supplied marker.
.EXAMPLE
    Complete-UDFListViewInlineEditorsByMarker
.INPUTS
    The function parameters are described in the parameter block.
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.4
    Author          : Imraan Iotana
    Creation Date   : August 2026
    Last Update     : August 2026
#>
####################################################################################################
function Complete-UDFListViewInlineEditorsByMarker {
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The ListView that may host active inline editors.')]
        [System.Windows.Forms.ListView]$ListView,

        [Parameter(Mandatory=$true,HelpMessage='The inline editor marker used to match overlay controls.')]
        [System.String]$InlineEditorMarker
    )

    [System.Boolean]$Committed = $false

    [System.Collections.Generic.List[System.Windows.Forms.Control]]$InlineEditors = New-Object 'System.Collections.Generic.List[System.Windows.Forms.Control]'
    foreach ($Control in $ListView.Controls) {
        if (($null -eq $Control) -or ($null -eq $Control.Tag)) {
            continue
        }

        if (($null -ne $Control.Tag.PSObject.Properties['InlineEditorMarker']) -and ([System.String]::Equals([System.String]$Control.Tag.InlineEditorMarker, $InlineEditorMarker, [System.StringComparison]::Ordinal))) {
            $InlineEditors.Add([System.Windows.Forms.Control]$Control) | Out-Null
        }
    }

    foreach ($InlineEditor in $InlineEditors) {
        if (($null -ne $InlineEditor.Tag) -and ($null -ne $InlineEditor.Tag.PSObject.Properties['CommitAction']) -and ($InlineEditor.Tag.CommitAction -is [System.Management.Automation.ScriptBlock])) {
            try {
                & $InlineEditor.Tag.CommitAction
                $Committed = $true
            }
            finally {
                if (-not $InlineEditor.IsDisposed) {
                    $ListView.Controls.Remove($InlineEditor)
                    $InlineEditor.Dispose()
                }
            }
        }
        elseif (-not $InlineEditor.IsDisposed) {
            $ListView.Controls.Remove($InlineEditor)
            $InlineEditor.Dispose()
        }
    }

    $ListView.Invalidate()
    $ListView.Update()

    return $Committed
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Handles the Convert-UDFTextToDeploymentObjectPropertyValue helper.
.DESCRIPTION
    Provides the Convert-UDFTextToDeploymentObjectPropertyValue implementation used by the UDF editor.
.EXAMPLE
    Convert-UDFTextToDeploymentObjectPropertyValue
.INPUTS
    The function parameters are described in the parameter block.
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.4
    Author          : Imraan Iotana
    Creation Date   : August 2026
    Last Update     : August 2026
#>
####################################################################################################
function Convert-UDFTextToDeploymentObjectPropertyValue {
    [CmdletBinding()]
    [OutputType([System.Object])]
    param (
        [Parameter(Mandatory=$false,HelpMessage='The current property value used to infer the target type.')]
        [AllowNull()]
        [System.Object]$CurrentValueObject,

        [Parameter(Mandatory=$false,HelpMessage='The text entered in the editor.')]
        [AllowNull()][AllowEmptyString()]
        [System.String]$InputText
    )

    [System.String]$NormalizedInputText = [System.String]$(if ($null -eq $InputText) { '' } else { $InputText })

    # EXECUTION - BOOLEAN CONVERSION
    # Convert textual boolean values and numeric aliases to true/false.
    if ($CurrentValueObject -is [System.Boolean]) {
        [System.Boolean]$ParsedBoolean = $false
        if ([System.Boolean]::TryParse($NormalizedInputText, [ref]$ParsedBoolean)) {
            return $ParsedBoolean
        }

        switch ($NormalizedInputText.Trim().ToLowerInvariant()) {
            '1' { return $true }
            '0' { return $false }
            default { return $CurrentValueObject }
        }
    }

    # EXECUTION - INTEGER CONVERSION
    # Convert textual integer values while preserving previous value on parse failure.
    if ($CurrentValueObject -is [System.Int32]) {
        [System.Int32]$ParsedInt = 0
        if ([System.Int32]::TryParse($InputText, [ref]$ParsedInt)) {
            return $ParsedInt
        }
        return $CurrentValueObject
    }

    # EXECUTION - ARRAY CONVERSION
    # Convert comma-separated text to string[] or int[] based on current array element type.
    if ($CurrentValueObject -is [System.Array]) {
        [System.String[]]$Parts = @($NormalizedInputText -split ',') | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }

        if (($CurrentValueObject.Count -gt 0) -and ($CurrentValueObject[0] -is [System.Int32])) {
            [System.Collections.Generic.List[System.Int32]]$IntParts = New-Object 'System.Collections.Generic.List[System.Int32]'
            foreach ($Part in $Parts) {
                [System.Int32]$ParsedInt = 0
                if ([System.Int32]::TryParse($Part, [ref]$ParsedInt)) {
                    $IntParts.Add($ParsedInt) | Out-Null
                }
            }
            return $IntParts.ToArray()
        }

        return $Parts
    }

    # OUTPUT - TYPED VALUE
    # Default to string conversion for other scalar values.
    return [System.String]$NormalizedInputText
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Handles the Set-UDFSelectedDeploymentObjectPropertyValueFromCombo helper.
.DESCRIPTION
    Provides the Set-UDFSelectedDeploymentObjectPropertyValueFromCombo implementation used by the UDF editor.
.EXAMPLE
    Set-UDFSelectedDeploymentObjectPropertyValueFromCombo
.INPUTS
    The function parameters are described in the parameter block.
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.4
    Author          : Imraan Iotana
    Creation Date   : August 2026
    Last Update     : August 2026
#>
####################################################################################################
function Set-UDFSelectedDeploymentObjectPropertyValueFromCombo {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The source ListView that contains deployment objects.')]
        [System.Windows.Forms.ListView]$SourceListView,

        [Parameter(Mandatory=$true,HelpMessage='The properties ListView that contains the selected property row.')]
        [System.Windows.Forms.ListView]$PropertiesListView,

        [Parameter(Mandatory=$true,HelpMessage='The ComboBox that contains the new property value.')]
        [System.Windows.Forms.ComboBox]$ValueComboBox
    )

    try {
        # PREPARATION - SELECTION CONTEXT
        # Reuse the shared selection context helper to avoid duplicate object/property resolution.
        [PSCustomObject]$SelectionContext = Get-UDFDeploymentObjectSelectionContext -SourceListView $SourceListView -PropertiesListView $PropertiesListView

        # VALIDATION - SELECTION
        # Continue only when both list views have a valid resolved selection.
        if ((-not $SelectionContext.HasSelection) -or (-not $SelectionContext.HasValidPropertyName) -or ($null -eq $SelectionContext.DeploymentObject)) {
            Write-Line 'Select an object property first.' -Type Warning
            return
        }

        # VALIDATION - PROTECTED PROPERTY
        # Keep Type immutable in all update flows.
        if (-not (Test-UDFDeploymentObjectPropertyCanBeEdited -PropertyName $SelectionContext.PropertyName)) {
            Write-Line "'Type' is read-only." -Type Warning
            return
        }

        # PREPARATION - VALUE CONVERSION
        # Convert ComboBox text to the best matching target type.
        [System.Object]$CurrentValueObject = $SelectionContext.DeploymentObject[$SelectionContext.PropertyName]
        [System.String]$OldValueText = Convert-UDFDeploymentObjectPropertyValueToText -PropertyValueObject $CurrentValueObject
        [System.String]$NewValueText = [System.String]$ValueComboBox.Text
        [System.Object]$NewValueObject = Convert-UDFTextToDeploymentObjectPropertyValue -CurrentValueObject $CurrentValueObject -InputText $NewValueText
        [System.String]$AppliedNewValueText = Convert-UDFDeploymentObjectPropertyValueToText -PropertyValueObject $NewValueObject

        # EXECUTION - APPLY VALUE
        # Reuse the shared refresh/update helper.
        Update-UDFDeploymentObjectPropertyAndUi -SourceListView $SourceListView -PropertiesListView $PropertiesListView -SelectionContext $SelectionContext -NewValueObject $NewValueObject -OldValueText $OldValueText -AppliedNewValueText $AppliedNewValueText -PostRefreshAction {
            Set-UDFPropertyValueComboFromSelection -SourceListView $SourceListView -PropertiesListView $PropertiesListView -ValueComboBox $ValueComboBox
        }.GetNewClosure()
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}

### END OF FUNCTION
####################################################################################################


