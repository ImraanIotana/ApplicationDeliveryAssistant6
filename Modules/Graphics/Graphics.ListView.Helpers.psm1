####################################################################################################
<#
.SYNOPSIS
    Resolves ListView color themes and applies semantic key/value row styling.
.DESCRIPTION
    This module provides shared ListView helpers for color-theme resolution and row-level styling,
    so feature modules can consistently communicate editable versus read-only value cells.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.2.0
    Author          : Imraan Iotana
    Creation Date   : August 2026
    Last Update     : August 2026
#>
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Returns a path property from the selected ListView row.
.DESCRIPTION
    Resolves the tagged data object from the first selected ListViewItem and returns the explicitly
    named path property. Selection, tag, property, and empty-value validation are handled centrally.
.EXAMPLE
    Get-SelectedListViewItemPath -ListView $ResultsListView -PathPropertyName 'Path' -ItemName 'search result'
    Returns the Path property stored on the selected search result.
.EXAMPLE
    Get-SelectedListViewItemPath -ListView $TemplateListView -PathPropertyName 'Directory' -ItemName 'customer template'
    Returns the Directory property stored on the selected customer template.
.INPUTS
    [System.Windows.Forms.ListView]
    [System.String]
.OUTPUTS
    [System.String] when a populated path property is available; otherwise no object is returned.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.2.0
    Author          : Imraan Iotana
    Creation Date   : August 2026
    Last Update     : August 2026
#>
####################################################################################################
function Get-SelectedListViewItemPath {
    [CmdletBinding()]
    [OutputType([System.String])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The ListView containing the selected tagged row.')]
        [System.Windows.Forms.ListView]$ListView,

        [Parameter(Mandatory=$true,HelpMessage='The name of the path property stored on the selected row Tag.')]
        [ValidateNotNullOrEmpty()]
        [System.String]$PathPropertyName,

        [Parameter(Mandatory=$false,HelpMessage='User-facing name of one row item for validation messages.')]
        [ValidateNotNullOrEmpty()]
        [System.String]$ItemName = 'item'
    )

    # VALIDATION - LISTVIEW SELECTION
    # Require one selected row with a tagged data object
    if (($null -eq $ListView.SelectedItems) -or ($ListView.SelectedItems.Count -lt 1)) {
        Write-Line "No $ItemName is selected." -Type Warning
        return
    }

    [System.Object]$SelectedData = $ListView.SelectedItems[0].Tag
    if ($null -eq $SelectedData) {
        Write-Line "The selected $ItemName does not contain data." -Type Warning
        return
    }

    # PREPARATION - PATH PROPERTY
    # Resolve the explicitly named property from the selected row data
    [System.Management.Automation.PSPropertyInfo]$PathProperty = $SelectedData.PSObject.Properties[$PathPropertyName]

    # VALIDATION - PATH PROPERTY
    # Stop when the selected row does not provide a populated path value
    if (($null -eq $PathProperty) -or [System.String]::IsNullOrWhiteSpace([System.String]$PathProperty.Value)) {
        Write-Line "The selected $ItemName does not contain a valid $PathPropertyName path." -Type Warning
        return
    }

    # OUTPUT
    # Return the path value using a consistent string contract
    return [System.String]$PathProperty.Value
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Converts ListView theme settings to a hashtable.
.DESCRIPTION
    Normalizes hashtable or PSCustomObject theme payloads into a hashtable so callers can use one shape.
.EXAMPLE
    Convert-ListViewThemeSettingsToHashtable -ThemeSettings $ListView.Tag.ListViewTheme
.INPUTS
    [System.Object]
.OUTPUTS
    [System.Collections.Hashtable]
#>
####################################################################################################
function Convert-ListViewThemeSettingsToHashtable {
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param (
        [Parameter(Mandatory=$false,HelpMessage='Theme settings provided as hashtable or PSCustomObject.')]
        [System.Object]$ThemeSettings
    )

    if ($ThemeSettings -is [System.Collections.Hashtable]) {
        return [System.Collections.Hashtable]$ThemeSettings
    }

    if ($ThemeSettings -is [System.Management.Automation.PSCustomObject]) {
        [System.Collections.Hashtable]$NormalizedTheme = @{}
        foreach ($Property in $ThemeSettings.PSObject.Properties) {
            $NormalizedTheme[[System.String]$Property.Name] = $Property.Value
        }
        return $NormalizedTheme
    }

    return $null
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Resolves ListView theme overrides from application settings.
.DESCRIPTION
    Returns a stable hashtable with read-only and editable ListView color names,
    applying safe defaults and then overriding them from GraphicalSettings.ListView.
.EXAMPLE
    Get-ListViewThemeOverridesFromInputObject -InputObject $MyApplicationObject
.INPUTS
    [PSCustomObject]
.OUTPUTS
    [System.Collections.Hashtable]
#>
####################################################################################################
function Get-ListViewThemeOverridesFromInputObject {
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param (
        [Parameter(Mandatory=$false,HelpMessage='Optional application object containing GraphicalSettings.ListView.')]
        [PSCustomObject]$InputObject,

        [Parameter(Mandatory=$false,HelpMessage='Fallback color for read-only background.')]
        [System.String]$DefaultReadOnlyBackColor = 'Beige',

        [Parameter(Mandatory=$false,HelpMessage='Fallback color for read-only text.')]
        [System.String]$DefaultReadOnlyTextColor = 'Blue',

        [Parameter(Mandatory=$false,HelpMessage='Fallback color for editable background.')]
        [System.String]$DefaultEditableBackColor = 'White',

        [Parameter(Mandatory=$false,HelpMessage='Fallback color for editable text.')]
        [System.String]$DefaultEditableTextColor = 'Black'
    )

    [System.Collections.Hashtable]$ThemeOverrides = @{
        ReadOnlyBackColor = [System.String]$DefaultReadOnlyBackColor
        ReadOnlyTextColor = [System.String]$DefaultReadOnlyTextColor
        EditableBackColor = [System.String]$DefaultEditableBackColor
        EditableTextColor = [System.String]$DefaultEditableTextColor
    }

    if (($null -ne $InputObject) -and ($InputObject.GraphicalSettings.ListView -is [System.Collections.Hashtable])) {
        [System.Collections.Hashtable]$ListViewSettings = [System.Collections.Hashtable]$InputObject.GraphicalSettings.ListView
        if ($ListViewSettings.ContainsKey('ReadOnlyBackColor') -and (Test-String -IsPopulated ([System.String]$ListViewSettings.ReadOnlyBackColor))) { $ThemeOverrides.ReadOnlyBackColor = [System.String]$ListViewSettings.ReadOnlyBackColor }
        if ($ListViewSettings.ContainsKey('ReadOnlyTextColor') -and (Test-String -IsPopulated ([System.String]$ListViewSettings.ReadOnlyTextColor))) { $ThemeOverrides.ReadOnlyTextColor = [System.String]$ListViewSettings.ReadOnlyTextColor }
        if ($ListViewSettings.ContainsKey('EditableBackColor') -and (Test-String -IsPopulated ([System.String]$ListViewSettings.EditableBackColor))) { $ThemeOverrides.EditableBackColor = [System.String]$ListViewSettings.EditableBackColor }
        if ($ListViewSettings.ContainsKey('EditableTextColor') -and (Test-String -IsPopulated ([System.String]$ListViewSettings.EditableTextColor))) { $ThemeOverrides.EditableTextColor = [System.String]$ListViewSettings.EditableTextColor }
    }

    return $ThemeOverrides
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Stores neutral ListView theme metadata on a ListView control.
.DESCRIPTION
    Writes ListView theme settings to Tag.ListViewTheme.
.EXAMPLE
    Set-ListViewThemeMetadata -ListView $MyListView -ThemeSettings @{ ReadOnlyBackColor='Beige' }
.INPUTS
    [System.Windows.Forms.ListView]
    [System.Object]
.OUTPUTS
    No objects are returned to the pipeline.
#>
####################################################################################################
function Set-ListViewThemeMetadata {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The ListView that will store theme metadata.')]
        [System.Windows.Forms.ListView]$ListView,

        [Parameter(Mandatory=$false,HelpMessage='Theme settings provided as hashtable or PSCustomObject.')]
        [System.Object]$ThemeSettings,

        [Parameter(Mandatory=$false,HelpMessage='Optional application object to store as metadata fallback source.')]
        [PSCustomObject]$ApplicationObject
    )

    [System.Collections.Hashtable]$NormalizedTheme = Convert-ListViewThemeSettingsToHashtable -ThemeSettings $ThemeSettings

    if ($null -eq $ListView.Tag) {
        $ListView.Tag = [PSCustomObject]@{}
    }
    elseif (-not ($ListView.Tag -is [System.Management.Automation.PSCustomObject])) {
        $ListView.Tag = [PSCustomObject]@{
            LegacyTagValue = $ListView.Tag
        }
    }

    if ($null -ne $ApplicationObject) {
        $ListView.Tag | Add-Member -MemberType NoteProperty -Name ApplicationObject -Value $ApplicationObject -Force
    }

    if ($null -ne $NormalizedTheme) {
        $ListView.Tag | Add-Member -MemberType NoteProperty -Name ListViewTheme -Value $NormalizedTheme -Force
    }
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Runs a ListView update action inside BeginUpdate/EndUpdate.
.DESCRIPTION
    Wraps repaint suppression so callers can perform multiple row/column changes in one paint cycle.
.EXAMPLE
    Invoke-ListViewBatchUpdate -ListView $MyListView -Action { $MyListView.Items.Clear() }
.INPUTS
    [System.Windows.Forms.ListView]
    [System.Management.Automation.ScriptBlock]
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
function Invoke-ListViewBatchUpdate {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The ListView that will be updated in one paint cycle.')]
        [System.Windows.Forms.ListView]$ListView,

        [Parameter(Mandatory=$true,HelpMessage='The update action that mutates rows/columns.')]
        [System.Management.Automation.ScriptBlock]$Action
    )

    $ListView.BeginUpdate()
    try {
        & $Action
    }
    finally {
        $ListView.EndUpdate()
    }
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Enables typed column sorting for a Details ListView.
.DESCRIPTION
    Attaches one reusable ColumnClick handler that sorts text, integer, version, and date columns.
    Clicking the active column reverses its direction; clicking a different column starts ascending.
.EXAMPLE
    Enable-ListViewColumnSorting -ListView $MyListView -ColumnTypes @('Integer','Text','Date') -MetadataPrefix 'MyFeature'
.INPUTS
    [System.Windows.Forms.ListView]
    [System.String[]]
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.1.0
    Author          : Imraan Iotana
    Creation Date   : August 2026
    Last Update     : August 2026
#>
####################################################################################################
function Enable-ListViewColumnSorting {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The Details ListView that receives column sorting.')]
        [System.Windows.Forms.ListView]$ListView,

        [Parameter(Mandatory=$true,HelpMessage='The sort type for each ListView column in display order.')]
        [ValidateNotNullOrEmpty()]
        [System.String[]]$ColumnTypes,

        [Parameter(Mandatory=$false,HelpMessage='The feature-specific prefix used for sorting metadata on the ListView tag.')]
        [ValidatePattern('^[A-Za-z][A-Za-z0-9]*$')]
        [System.String]$MetadataPrefix = 'ListView'
    )

    try {
        # VALIDATION
        if ($ListView.View -ne [System.Windows.Forms.View]::Details) {
            throw 'Column sorting requires a ListView using Details view.'
        }
        if ($ColumnTypes.Count -ne $ListView.Columns.Count) {
            throw "Column sorting received $($ColumnTypes.Count) sort types for $($ListView.Columns.Count) columns."
        }
        foreach ($ColumnType in $ColumnTypes) {
            if ($ColumnType -notin @('Text','Integer','Version','Date')) {
                throw "Unsupported ListView column sort type: $ColumnType"
            }
        }

        # PREPARATION - SHARED COMPARER TYPE
        if ($null -eq ('ApplicationDeliveryAssistant.ListViewItemComparer' -as [System.Type])) {
            [System.String]$ComparerSource = @'
using System;
using System.Collections;
using System.Globalization;
using System.Windows.Forms;

namespace ApplicationDeliveryAssistant
{
    public sealed class ListViewItemComparer : IComparer
    {
        public int Column { get; set; }
        public bool Descending { get; set; }
        public string ValueType { get; set; }

        public int Compare(object leftObject, object rightObject)
        {
            ListViewItem leftItem = leftObject as ListViewItem;
            ListViewItem rightItem = rightObject as ListViewItem;
            string leftText = GetText(leftItem);
            string rightText = GetText(rightItem);
            int result;

            switch (ValueType)
            {
                case "Integer":
                    int leftInteger;
                    int rightInteger;
                    if (Int32.TryParse(leftText, out leftInteger) && Int32.TryParse(rightText, out rightInteger))
                        result = leftInteger.CompareTo(rightInteger);
                    else
                        result = CompareText(leftText, rightText);
                    break;
                case "Version":
                    Version leftVersion;
                    Version rightVersion;
                    if (Version.TryParse(leftText, out leftVersion) && Version.TryParse(rightText, out rightVersion))
                        result = leftVersion.CompareTo(rightVersion);
                    else
                        result = CompareText(leftText, rightText);
                    break;
                case "Date":
                    DateTime leftDate;
                    DateTime rightDate;
                    if (DateTime.TryParse(leftText, CultureInfo.InvariantCulture, DateTimeStyles.None, out leftDate) &&
                        DateTime.TryParse(rightText, CultureInfo.InvariantCulture, DateTimeStyles.None, out rightDate))
                        result = leftDate.CompareTo(rightDate);
                    else
                        result = CompareText(leftText, rightText);
                    break;
                default:
                    result = CompareText(leftText, rightText);
                    break;
            }

            return Descending ? -result : result;
        }

        private string GetText(ListViewItem item)
        {
            if (item == null || Column < 0 || Column >= item.SubItems.Count)
                return String.Empty;
            return item.SubItems[Column].Text ?? String.Empty;
        }

        private static int CompareText(string leftText, string rightText)
        {
            return StringComparer.OrdinalIgnoreCase.Compare(leftText, rightText);
        }
    }
}
'@
            Add-Type -TypeDefinition $ComparerSource -ReferencedAssemblies ([System.Windows.Forms.ListView].Assembly.Location)
        }

        # PREPARATION - FEATURE METADATA
        if ($null -eq $ListView.Tag) {
            $ListView.Tag = [PSCustomObject]@{}
        }
        elseif (-not ($ListView.Tag -is [System.Management.Automation.PSCustomObject])) {
            $ListView.Tag = [PSCustomObject]@{ LegacyTagValue = $ListView.Tag }
        }

        [System.String]$EnabledProperty = "${MetadataPrefix}SortingEnabled"
        [System.String]$ColumnProperty = "${MetadataPrefix}SortColumn"
        [System.String]$DescendingProperty = "${MetadataPrefix}SortDescending"
        [System.String]$ColumnTypesProperty = "${MetadataPrefix}SortColumnTypes"
        if (($null -ne $ListView.Tag.PSObject.Properties[$EnabledProperty]) -and ([System.Boolean]$ListView.Tag.PSObject.Properties[$EnabledProperty].Value)) {
            return
        }

        $ListView.Tag | Add-Member -MemberType NoteProperty -Name $EnabledProperty -Value $true -Force
        $ListView.Tag | Add-Member -MemberType NoteProperty -Name $ColumnProperty -Value -1 -Force
        $ListView.Tag | Add-Member -MemberType NoteProperty -Name $DescendingProperty -Value $false -Force
        $ListView.Tag | Add-Member -MemberType NoteProperty -Name $ColumnTypesProperty -Value @($ColumnTypes) -Force

        # EXECUTION - COLUMN CLICK
        $ListView.Add_ColumnClick({
            [System.Windows.Forms.ColumnClickEventArgs]$ColumnClickData = $args[1]
            [System.Int32]$ClickedColumn = [System.Int32]$ColumnClickData.Column
            [System.Int32]$CurrentColumn = [System.Int32]$ListView.Tag.PSObject.Properties[$ColumnProperty].Value
            [System.Boolean]$CurrentDescending = [System.Boolean]$ListView.Tag.PSObject.Properties[$DescendingProperty].Value
            [System.Boolean]$Descending = if ($CurrentColumn -eq $ClickedColumn) { -not $CurrentDescending } else { $false }

            $ListView.Tag.PSObject.Properties[$ColumnProperty].Value = $ClickedColumn
            $ListView.Tag.PSObject.Properties[$DescendingProperty].Value = $Descending
            [System.String]$ColumnType = [System.String]$ListView.Tag.PSObject.Properties[$ColumnTypesProperty].Value[$ClickedColumn]
            $ListView.ListViewItemSorter = New-Object ApplicationDeliveryAssistant.ListViewItemComparer -Property @{
                Column     = $ClickedColumn
                Descending = $Descending
                ValueType  = $ColumnType
            }
            $ListView.Sort()
        }.GetNewClosure())
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
    Selects a ListView row by matching text in a target subitem.
.DESCRIPTION
    Supports optional clear/focus/scroll behavior for reusable selection orchestration.
.EXAMPLE
    Set-ListViewSelectionByText -ListView $ListView -MatchText 'BuildNumber' -ClearExisting -SetFocus -EnsureVisible
.INPUTS
    [System.Windows.Forms.ListView]
    [System.String]
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
function Set-ListViewSelectionByText {
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

    if (($null -eq $ListView) -or [System.String]::IsNullOrWhiteSpace([System.String]$MatchText)) {
        return $false
    }

    foreach ($Item in $ListView.Items) {
        if (($null -eq $Item) -or ($Item.SubItems.Count -le $SubItemIndex)) {
            continue
        }

        if ([System.String]::Equals([System.String]$Item.SubItems[$SubItemIndex].Text, [System.String]$MatchText, [System.StringComparison]::Ordinal)) {
            if ($ClearExisting) {
                $ListView.SelectedIndices.Clear()
            }

            $Item.Selected = $true
            if ($SetFocus) {
                $Item.Focused = $true
            }
            if ($EnsureVisible) {
                $Item.EnsureVisible()
            }

            return $true
        }
    }

    return $false
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Selects a ListView row by index.
.DESCRIPTION
    Supports optional clear/focus/scroll behavior while validating index bounds.
.EXAMPLE
    Set-ListViewSelectionByIndex -ListView $ListView -Index 2 -ClearExisting -SetFocus -EnsureVisible
.INPUTS
    [System.Windows.Forms.ListView]
    [System.Int32]
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
function Set-ListViewSelectionByIndex {
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The ListView that owns the row.')]
        [System.Windows.Forms.ListView]$ListView,

        [Parameter(Mandatory=$true,HelpMessage='The target row index to select.')]
        [System.Int32]$Index,

        [Parameter(Mandatory=$false,HelpMessage='Clears existing selection before selecting the row.')]
        [System.Management.Automation.SwitchParameter]$ClearExisting,

        [Parameter(Mandatory=$false,HelpMessage='Sets keyboard focus on the selected row.')]
        [System.Management.Automation.SwitchParameter]$SetFocus,

        [Parameter(Mandatory=$false,HelpMessage='Scrolls the selected row into view.')]
        [System.Management.Automation.SwitchParameter]$EnsureVisible
    )

    if (($null -eq $ListView) -or ($Index -lt 0) -or ($Index -ge $ListView.Items.Count)) {
        return $false
    }

    if ($ClearExisting) {
        $ListView.SelectedIndices.Clear()
    }

    [System.Windows.Forms.ListViewItem]$SelectedItem = [System.Windows.Forms.ListViewItem]$ListView.Items[$Index]
    $SelectedItem.Selected = $true
    if ($SetFocus) {
        $SelectedItem.Focused = $true
    }
    if ($EnsureVisible) {
        $SelectedItem.EnsureVisible()
    }

    return $true
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Resolves a value-cell hit test in a ListView.
.DESCRIPTION
    Returns hit-test metadata only when the clicked cell matches the configured value column.
.EXAMPLE
    Get-ListViewValueCellHitTest -ListView $ListView -MouseEventArgs $MouseData -ValueColumnIndex 1
.INPUTS
    [System.Windows.Forms.ListView]
    [System.Windows.Forms.MouseEventArgs]
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
function Get-ListViewValueCellHitTest {
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

    [System.Windows.Forms.ListViewHitTestInfo]$HitTestInfo = $ListView.HitTest($MouseEventArgs.X, $MouseEventArgs.Y)
    if (($null -eq $HitTestInfo) -or ($null -eq $HitTestInfo.Item) -or ($null -eq $HitTestInfo.SubItem)) {
        return $null
    }

    [System.Int32]$SubItemIndex = $HitTestInfo.Item.SubItems.IndexOf($HitTestInfo.SubItem)
    if ($SubItemIndex -ne $ValueColumnIndex) {
        return $null
    }

    $HitTestInfo.Item.Selected = $true
    $HitTestInfo.Item.Focused = $true
    return $HitTestInfo
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Completes matching inline editors hosted by a ListView.
.DESCRIPTION
    Invokes each matching editor's commit action, removes the temporary controls, and redraws the ListView.
.EXAMPLE
    Complete-ListViewInlineEditors -ListView $ListView -InlineEditorMarker 'PropertyEditor'
.OUTPUTS
    [System.Boolean]
#>
####################################################################################################
function Complete-ListViewInlineEditors {
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The ListView that may host active inline editors.')]
        [System.Windows.Forms.ListView]$ListView,

        [Parameter(Mandatory=$true,HelpMessage='The marker used to identify matching inline editor controls.')]
        [System.String]$InlineEditorMarker
    )

    [System.Boolean]$Committed = $false
    [System.Collections.Generic.List[System.Windows.Forms.Control]]$InlineEditors = New-Object 'System.Collections.Generic.List[System.Windows.Forms.Control]'

    foreach ($Control in $ListView.Controls) {
        if (($null -eq $Control) -or ($null -eq $Control.Tag)) { continue }

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
    Starts an inline value editor over a ListView cell.
.DESCRIPTION
    Hosts a temporary TextBox or boolean ComboBox with Enter, Escape, and focus-change behavior.
.EXAMPLE
    Start-ListViewInlineValueEdit -ListView $ListView -HitTestInfo $HitTest -InlineEditorMarker 'PropertyEditor' -PropertyName 'Name' -CurrentValueObject 'Old' -ApplyValueAction { param($Value) } -CompleteInlineEditorsAction { }
.OUTPUTS
    No objects are returned to the pipeline.
#>
####################################################################################################
function Start-ListViewInlineValueEdit {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The ListView that hosts the temporary inline editor.')]
        [System.Windows.Forms.ListView]$ListView,

        [Parameter(Mandatory=$true,HelpMessage='Resolved hit-test information for the editable cell.')]
        [System.Windows.Forms.ListViewHitTestInfo]$HitTestInfo,

        [Parameter(Mandatory=$true,HelpMessage='Marker used to identify the inline editor control.')]
        [System.String]$InlineEditorMarker,

        [Parameter(Mandatory=$true,HelpMessage='Property label used in status messages.')]
        [System.String]$PropertyName,

        [Parameter(Mandatory=$true,HelpMessage='Current typed value used to select an editor control.')]
        [AllowNull()]
        [System.Object]$CurrentValueObject,

        [Parameter(Mandatory=$false,HelpMessage='Current text displayed by the editor.')]
        [AllowNull()][AllowEmptyString()]
        [System.String]$CurrentValueText,

        [Parameter(Mandatory=$true,HelpMessage='Callback that applies the candidate text value.')]
        [System.Management.Automation.ScriptBlock]$ApplyValueAction,

        [Parameter(Mandatory=$true,HelpMessage='Callback that completes active editors for this context.')]
        [System.Management.Automation.ScriptBlock]$CompleteInlineEditorsAction,

        [Parameter(Mandatory=$false,HelpMessage='Label used in the edit status message.')]
        [System.String]$StartMessageContext = 'property',

        [Parameter(Mandatory=$false,HelpMessage='Optional ListView Tag property used to track active editing.')]
        [System.String]$InlineEditActiveTagName,

        [Parameter(Mandatory=$false,HelpMessage='Also handle Escape during PreviewKeyDown.')]
        [System.Management.Automation.SwitchParameter]$CancelEscapeInPreview
    )

    try {
        if ([System.String]::IsNullOrWhiteSpace($PropertyName)) { return }

        Write-Line "Editing $StartMessageContext '$PropertyName'. Press Enter to save or Escape to cancel."

        if (Test-String -IsPopulated $InlineEditActiveTagName) {
            if ($null -eq $ListView.Tag) { $ListView.Tag = [PSCustomObject]@{} }
            $ListView.Tag | Add-Member -MemberType NoteProperty -Name $InlineEditActiveTagName -Value $false -Force
        }

        [System.Windows.Forms.Control]$EditorControl = $null
        [System.Collections.Hashtable]$EditorState = @{
            IsCompleted = $false
            LatestText  = [System.String]$CurrentValueText
        }

        [System.Management.Automation.ScriptBlock]$DisposeEditor = {
            if (Test-String -IsPopulated $InlineEditActiveTagName) {
                if ($null -eq $ListView.Tag) { $ListView.Tag = [PSCustomObject]@{} }
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

            [System.String]$NewValueText = if ($null -ne $CandidateText) { [System.String]$CandidateText } else { [System.String]$EditorState.LatestText }
            if ($IsAutoCommit) { Write-Line "Focus changed. Auto-saving edit for '$PropertyName'." }

            & $DisposeEditor
            & $ApplyValueAction $NewValueText
            & $CompleteInlineEditorsAction
            $ListView.Focus() | Out-Null
        }.GetNewClosure()

        if ($CurrentValueObject -is [System.Boolean]) {
            [System.Windows.Forms.ComboBox]$BooleanEditor = New-Object System.Windows.Forms.ComboBox
            $BooleanEditor.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
            [void]$BooleanEditor.Items.Add('True')
            [void]$BooleanEditor.Items.Add('False')
            $BooleanEditor.Text = [System.String]$CurrentValueText
            $BooleanEditor.Add_TextChanged({ param($Sender,$EventArgs) $EditorState.LatestText = [System.String]$Sender.Text }.GetNewClosure())
            $BooleanEditor.Add_SelectionChangeCommitted({ param($Sender,$EventArgs) & $ApplyEdit ([System.String]$Sender.Text) }.GetNewClosure())
            $BooleanEditor.Add_KeyDown({
                param($Sender,$EventArgs)
                if ($EventArgs.KeyCode -eq [System.Windows.Forms.Keys]::Enter) {
                    $EventArgs.Handled = $true; $EventArgs.SuppressKeyPress = $true; & $ApplyEdit ([System.String]$Sender.Text)
                }
                elseif ($EventArgs.KeyCode -eq [System.Windows.Forms.Keys]::Escape) {
                    $EventArgs.Handled = $true; $EventArgs.SuppressKeyPress = $true; & $CancelEdit
                }
            }.GetNewClosure())
            $BooleanEditor.Add_LostFocus({
                param($Sender,$EventArgs)
                if (($null -ne $Sender.Tag) -and ($null -ne $Sender.Tag.PSObject.Properties['IsCanceled']) -and [System.Boolean]$Sender.Tag.IsCanceled) { return }
                & $ApplyEdit ([System.String]$Sender.Text) $true
            }.GetNewClosure())
            $EditorControl = $BooleanEditor
        }
        else {
            [System.Windows.Forms.TextBox]$TextEditor = New-Object System.Windows.Forms.TextBox
            $TextEditor.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
            $TextEditor.Text = [System.String]$CurrentValueText
            $TextEditor.Add_TextChanged({ param($Sender,$EventArgs) $EditorState.LatestText = [System.String]$Sender.Text }.GetNewClosure())
            $TextEditor.Add_PreviewKeyDown({
                param($Sender,$EventArgs)
                if (($EventArgs.KeyCode -eq [System.Windows.Forms.Keys]::Enter) -or ($EventArgs.KeyCode -eq [System.Windows.Forms.Keys]::Escape)) { $EventArgs.IsInputKey = $true }
                if ($CancelEscapeInPreview -and ($EventArgs.KeyCode -eq [System.Windows.Forms.Keys]::Escape)) { & $CancelEdit }
            }.GetNewClosure())
            $TextEditor.Add_KeyDown({
                param($Sender,$EventArgs)
                if ($EventArgs.KeyCode -eq [System.Windows.Forms.Keys]::Enter) {
                    $EventArgs.Handled = $true; $EventArgs.SuppressKeyPress = $true; & $ApplyEdit ([System.String]$Sender.Text)
                }
                elseif ($EventArgs.KeyCode -eq [System.Windows.Forms.Keys]::Escape) {
                    $EventArgs.Handled = $true; $EventArgs.SuppressKeyPress = $true; & $CancelEdit
                }
            }.GetNewClosure())
            $TextEditor.Add_KeyUp({ param($Sender,$EventArgs) if ($EventArgs.KeyCode -eq [System.Windows.Forms.Keys]::Escape) { & $CancelEdit } }.GetNewClosure())
            $TextEditor.Add_LostFocus({
                param($Sender,$EventArgs)
                if (($null -ne $Sender.Tag) -and ($null -ne $Sender.Tag.PSObject.Properties['IsCanceled']) -and [System.Boolean]$Sender.Tag.IsCanceled) { return }
                & $ApplyEdit ([System.String]$Sender.Text) $true
            }.GetNewClosure())
            $EditorControl = $TextEditor
        }

        [System.Management.Automation.ScriptBlock]$CommitEditor = {
            & $ApplyEdit ([System.String]$EditorControl.Text)
        }.GetNewClosure()

        $EditorControl.Tag = [PSCustomObject]@{
            InlineEditorMarker = $InlineEditorMarker
            CommitAction       = $CommitEditor
            CancelAction       = $CancelEdit
        }
        [System.Drawing.Rectangle]$CellBounds = $HitTestInfo.SubItem.Bounds
        $EditorControl.Bounds = New-Object System.Drawing.Rectangle(($CellBounds.X + 1),($CellBounds.Y + 1),([System.Math]::Max(24,($CellBounds.Width - 2))),([System.Math]::Max(20,($CellBounds.Height - 2))))
        $ListView.Controls.Add($EditorControl)
        $EditorControl.BringToFront()
        $EditorControl.Focus() | Out-Null

        if (Test-String -IsPopulated $InlineEditActiveTagName) {
            $ListView.Tag | Add-Member -MemberType NoteProperty -Name $InlineEditActiveTagName -Value $true -Force
        }
        if ($EditorControl -is [System.Windows.Forms.ComboBox]) { ([System.Windows.Forms.ComboBox]$EditorControl).DroppedDown = $true }
        else { ([System.Windows.Forms.TextBox]$EditorControl).SelectAll() }
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
    Resolves ListView color theme values from global settings and optional ListView metadata.
.DESCRIPTION
    This helper returns read-only and editable colors used by key/value ListView renderers.
    It first reads global defaults from GraphicalSettings.ListView and then applies optional
    per-list overrides from ListView.Tag.ListViewTheme when present.
.EXAMPLE
    Get-ListViewColorTheme -InputObject $MyApplicationObject -ListView $MyListView
.INPUTS
    [PSCustomObject]
    [System.Windows.Forms.ListView]
.OUTPUTS
    [System.Management.Automation.PSCustomObject]
#>
####################################################################################################
function Get-ListViewColorTheme {
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSCustomObject])]
    param (
        [Parameter(Mandatory=$false,HelpMessage='Optional application object used to resolve global ListView color settings.')]
        [PSCustomObject]$InputObject,

        [Parameter(Mandatory=$false,HelpMessage='Optional ListView used to resolve per-control theme overrides from Tag metadata.')]
        [System.Windows.Forms.ListView]$ListView
    )

    # PREPARATION - DEFAULT COLORS
    # Use safe defaults when settings are missing.
    [System.Drawing.Color]$ReadOnlyBackColor = [System.Drawing.Color]::Beige
    [System.Drawing.Color]$ReadOnlyTextColor = [System.Drawing.Color]::Blue
    [System.Drawing.Color]$EditableBackColor = [System.Drawing.Color]::White
    [System.Drawing.Color]$EditableTextColor = [System.Drawing.Color]::Black

    # PREPARATION - GLOBAL SETTINGS SOURCE
    # Read global defaults from GraphicalSettings.ListView.
    [System.Collections.Hashtable]$GlobalListViewSettings = $null
    if (($null -ne $InputObject) -and ($null -ne $InputObject.PSObject.Properties['GraphicalSettings']) -and ($InputObject.GraphicalSettings.ListView -is [System.Collections.Hashtable])) {
        $GlobalListViewSettings = [System.Collections.Hashtable]$InputObject.GraphicalSettings.ListView
    }
    elseif (($null -ne $ListView) -and ($null -ne $ListView.Tag) -and ($null -ne $ListView.Tag.PSObject.Properties['ApplicationObject']) -and ($ListView.Tag.ApplicationObject -is [PSCustomObject]) -and ($ListView.Tag.ApplicationObject.GraphicalSettings.ListView -is [System.Collections.Hashtable])) {
        $GlobalListViewSettings = [System.Collections.Hashtable]$ListView.Tag.ApplicationObject.GraphicalSettings.ListView
    }

    if ($null -ne $GlobalListViewSettings) {
        if ($GlobalListViewSettings.ContainsKey('ReadOnlyBackColor') -and (Test-String -IsPopulated ([System.String]$GlobalListViewSettings.ReadOnlyBackColor))) {
            [System.Drawing.Color]$CandidateColor = [System.Drawing.Color]::FromName([System.String]$GlobalListViewSettings.ReadOnlyBackColor)
            if (-not $CandidateColor.IsEmpty) { $ReadOnlyBackColor = $CandidateColor }
        }

        if ($GlobalListViewSettings.ContainsKey('ReadOnlyTextColor') -and (Test-String -IsPopulated ([System.String]$GlobalListViewSettings.ReadOnlyTextColor))) {
            [System.Drawing.Color]$CandidateColor = [System.Drawing.Color]::FromName([System.String]$GlobalListViewSettings.ReadOnlyTextColor)
            if (-not $CandidateColor.IsEmpty) { $ReadOnlyTextColor = $CandidateColor }
        }

        if ($GlobalListViewSettings.ContainsKey('EditableBackColor') -and (Test-String -IsPopulated ([System.String]$GlobalListViewSettings.EditableBackColor))) {
            [System.Drawing.Color]$CandidateColor = [System.Drawing.Color]::FromName([System.String]$GlobalListViewSettings.EditableBackColor)
            if (-not $CandidateColor.IsEmpty) { $EditableBackColor = $CandidateColor }
        }

        if ($GlobalListViewSettings.ContainsKey('EditableTextColor') -and (Test-String -IsPopulated ([System.String]$GlobalListViewSettings.EditableTextColor))) {
            [System.Drawing.Color]$CandidateColor = [System.Drawing.Color]::FromName([System.String]$GlobalListViewSettings.EditableTextColor)
            if (-not $CandidateColor.IsEmpty) { $EditableTextColor = $CandidateColor }
        }
    }

    # PREPARATION - CONTROL OVERRIDES
    # Read per-control theme metadata from neutral Tag.ListViewTheme.
    [System.Collections.Hashtable]$ThemeSettings = $null
    if (($null -ne $ListView) -and ($null -ne $ListView.Tag)) {
        if ($null -ne $ListView.Tag.PSObject.Properties['ListViewTheme']) {
            $ThemeSettings = Convert-ListViewThemeSettingsToHashtable -ThemeSettings $ListView.Tag.ListViewTheme
        }
    }

    # EXECUTION - APPLY CONTROL OVERRIDES
    # Control metadata wins over global defaults when valid.
    if ($null -ne $ThemeSettings) {
        if ($ThemeSettings.ContainsKey('ReadOnlyBackColor') -and (Test-String -IsPopulated ([System.String]$ThemeSettings.ReadOnlyBackColor))) {
            [System.Drawing.Color]$CandidateColor = [System.Drawing.Color]::FromName([System.String]$ThemeSettings.ReadOnlyBackColor)
            if (-not $CandidateColor.IsEmpty) { $ReadOnlyBackColor = $CandidateColor }
        }

        if ($ThemeSettings.ContainsKey('ReadOnlyTextColor') -and (Test-String -IsPopulated ([System.String]$ThemeSettings.ReadOnlyTextColor))) {
            [System.Drawing.Color]$CandidateColor = [System.Drawing.Color]::FromName([System.String]$ThemeSettings.ReadOnlyTextColor)
            if (-not $CandidateColor.IsEmpty) { $ReadOnlyTextColor = $CandidateColor }
        }

        if ($ThemeSettings.ContainsKey('EditableBackColor') -and (Test-String -IsPopulated ([System.String]$ThemeSettings.EditableBackColor))) {
            [System.Drawing.Color]$CandidateColor = [System.Drawing.Color]::FromName([System.String]$ThemeSettings.EditableBackColor)
            if (-not $CandidateColor.IsEmpty) { $EditableBackColor = $CandidateColor }
        }

        if ($ThemeSettings.ContainsKey('EditableTextColor') -and (Test-String -IsPopulated ([System.String]$ThemeSettings.EditableTextColor))) {
            [System.Drawing.Color]$CandidateColor = [System.Drawing.Color]::FromName([System.String]$ThemeSettings.EditableTextColor)
            if (-not $CandidateColor.IsEmpty) { $EditableTextColor = $CandidateColor }
        }
    }

    # OUTPUT - RESOLVED THEME
    # Return one stable color object for callers.
    return [PSCustomObject]@{
        ReadOnlyBackColor = $ReadOnlyBackColor
        ReadOnlyTextColor = $ReadOnlyTextColor
        EditableBackColor = $EditableBackColor
        EditableTextColor = $EditableTextColor
    }
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Applies semantic key/value styling to a ListView item.
.DESCRIPTION
    This helper styles a key/value ListView row using read-only styling for the key column and
    either editable or read-only styling for the value subitem.
.EXAMPLE
    Set-ListViewKeyValueItemStyle -ListViewItem $Item -ColorTheme $Theme -ValueSubItemIndex 1 -ValueIsEditable $true
.INPUTS
    [System.Windows.Forms.ListViewItem]
    [System.Management.Automation.PSCustomObject]
.OUTPUTS
    No objects are returned to the pipeline.
#>
####################################################################################################
function Set-ListViewKeyValueItemStyle {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The ListView item to style as a key/value row.')]
        [System.Windows.Forms.ListViewItem]$ListViewItem,

        [Parameter(Mandatory=$true,HelpMessage='The color theme object returned by Get-ListViewColorTheme.')]
        [PSCustomObject]$ColorTheme,

        [Parameter(Mandatory=$false,HelpMessage='The subitem index that represents the value column.')]
        [System.Int32]$ValueSubItemIndex = 1,

        [Parameter(Mandatory=$false,HelpMessage='Whether the value subitem should be styled as editable.')]
        [System.Boolean]$ValueIsEditable = $true
    )

    # PREPARATION - BASE ROW STYLE
    # Keep key column/read-only row styling stable.
    $ListViewItem.UseItemStyleForSubItems = $false
    $ListViewItem.BackColor = [System.Drawing.Color]$ColorTheme.ReadOnlyBackColor
    $ListViewItem.ForeColor = [System.Drawing.Color]$ColorTheme.ReadOnlyTextColor

    # VALIDATION - VALUE SUBITEM
    # Skip value styling if requested subitem does not exist.
    if (($null -eq $ListViewItem.SubItems) -or ($ValueSubItemIndex -lt 0) -or ($ListViewItem.SubItems.Count -le $ValueSubItemIndex)) {
        return
    }

    # EXECUTION - VALUE STYLE
    # Apply editable/read-only semantic styling to the value cell.
    if ($ValueIsEditable) {
        $ListViewItem.SubItems[$ValueSubItemIndex].BackColor = [System.Drawing.Color]$ColorTheme.EditableBackColor
        $ListViewItem.SubItems[$ValueSubItemIndex].ForeColor = [System.Drawing.Color]$ColorTheme.EditableTextColor
    }
    else {
        $ListViewItem.SubItems[$ValueSubItemIndex].BackColor = [System.Drawing.Color]$ColorTheme.ReadOnlyBackColor
        $ListViewItem.SubItems[$ValueSubItemIndex].ForeColor = [System.Drawing.Color]$ColorTheme.ReadOnlyTextColor
    }
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Applies read-only styling to all cells of a ListView item.
.DESCRIPTION
    This helper enforces the read-only color theme across the key cell and all subitems so
    result-list rows can be rendered consistently as non-editable content.
.EXAMPLE
    Set-ListViewItemReadOnlyStyle -ListViewItem $Item -ColorTheme $Theme
.INPUTS
    [System.Windows.Forms.ListViewItem]
    [System.Management.Automation.PSCustomObject]
.OUTPUTS
    No objects are returned to the pipeline.
#>
####################################################################################################
function Set-ListViewItemReadOnlyStyle {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The ListView item to style as read-only.')]
        [System.Windows.Forms.ListViewItem]$ListViewItem,

        [Parameter(Mandatory=$true,HelpMessage='The color theme object returned by Get-ListViewColorTheme.')]
        [PSCustomObject]$ColorTheme
    )

    # PREPARATION - BASE ROW STYLE
    # Apply read-only style to the first column.
    $ListViewItem.UseItemStyleForSubItems = $false
    $ListViewItem.BackColor = [System.Drawing.Color]$ColorTheme.ReadOnlyBackColor
    $ListViewItem.ForeColor = [System.Drawing.Color]$ColorTheme.ReadOnlyTextColor

    # EXECUTION - SUBITEM STYLE
    # Apply read-only style to all subitems.
    if ($null -ne $ListViewItem.SubItems) {
        foreach ($SubItem in $ListViewItem.SubItems) {
            $SubItem.BackColor = [System.Drawing.Color]$ColorTheme.ReadOnlyBackColor
            $SubItem.ForeColor = [System.Drawing.Color]$ColorTheme.ReadOnlyTextColor
        }
    }
}

### END OF FUNCTION
####################################################################################################
