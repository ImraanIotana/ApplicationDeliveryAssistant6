####################################################################################################
<#
.SYNOPSIS
    Provides the Customer Template editor user interface.
.DESCRIPTION
    Builds the four-tab Schema 2 editor and connects its controls to the editable model and
    transactional save workflow.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.9.0
    Author          : Imraan Iotana
    Creation Date   : August 2026
    Last Update     : October 2026
#>
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Creates a sortable ListView for the Customer Template editor.
.DESCRIPTION
    Configures a fill-docked details ListView with stable selection, grid lines, tooltips, and
    text sorting for the supplied column names.
.EXAMPLE
    New-CustomerTemplateEditorListView -Columns @('Property','Value')
.INPUTS
    [System.String[]]
.OUTPUTS
    [System.Windows.Forms.ListView]
#>
####################################################################################################
function New-CustomerTemplateEditorListView {
    [CmdletBinding()]
    [OutputType([System.Windows.Forms.ListView])]
    param ([Parameter(Mandatory=$false)][System.String[]]$Columns = @('Property','Value'))

    # PREPARATION - LISTVIEW
    [System.Windows.Forms.ListView]$ListView = New-Object System.Windows.Forms.ListView
    $ListView.Dock = [System.Windows.Forms.DockStyle]::Fill
    $ListView.View = [System.Windows.Forms.View]::Details
    $ListView.FullRowSelect = $true
    $ListView.GridLines = $true
    $ListView.HideSelection = $false
    $ListView.ShowItemToolTips = $true

    # EXECUTION - COLUMNS AND SORTING
    foreach ($Column in $Columns) { [void]$ListView.Columns.Add($Column) }
    Enable-ListViewColumnSorting -ListView $ListView -ColumnTypes @($Columns | ForEach-Object { 'Text' }) -MetadataPrefix 'CustomerTemplateEditor'

    # OUTPUT
    return $ListView
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Refreshes an editor ListView from dictionary data.
.DESCRIPTION
    Rebuilds property/value rows in preferred key order, restores an optional selection, reapplies
    editable styling and active sorting, and sizes columns to their widest content.
.EXAMPLE
    Update-CustomerTemplateEditorDictionaryListView -ListView $ListView -Data $Settings
.INPUTS
    [System.Windows.Forms.ListView]
    [System.Collections.IDictionary]
.OUTPUTS
    No objects are returned to the pipeline.
#>
####################################################################################################
function Update-CustomerTemplateEditorDictionaryListView {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)][System.Windows.Forms.ListView]$ListView,
        [Parameter(Mandatory=$true)][System.Collections.IDictionary]$Data,
        [Parameter(Mandatory=$false)][System.String[]]$PreferredKeyOrder,
        [Parameter(Mandatory=$false)][System.String]$KeyToSelect
    )

    # PREPARATION - KEY ORDER
    [System.Collections.Generic.List[System.String]]$Keys = New-Object 'System.Collections.Generic.List[System.String]'
    foreach ($PreferredKey in @($PreferredKeyOrder)) {
        if ($Data.Contains($PreferredKey) -and (-not $Keys.Contains($PreferredKey))) { $Keys.Add($PreferredKey) | Out-Null }
    }
    foreach ($Key in $Data.Keys) {
        if (-not $Keys.Contains([System.String]$Key)) { $Keys.Add([System.String]$Key) | Out-Null }
    }

    # EXECUTION - ROW REFRESH
    [PSCustomObject]$ColorTheme = Get-ListViewColorTheme -ListView $ListView
    Invoke-ListViewBatchUpdate -ListView $ListView -Action {
        $ListView.Items.Clear()
        foreach ($Key in $Keys) {
            [System.Windows.Forms.ListViewItem]$Item = New-Object System.Windows.Forms.ListViewItem($Key)
            [void]$Item.SubItems.Add([System.String]$Data[$Key])
            $Item.Tag = $Key
            Set-ListViewKeyValueItemStyle -ListViewItem $Item -ColorTheme $ColorTheme -ValueSubItemIndex 1 -ValueIsEditable $true
            [void]$ListView.Items.Add($Item)
            if ([System.String]::Equals($Key,$KeyToSelect,[System.StringComparison]::Ordinal)) {
                $Item.Selected = $true
                $Item.Focused = $true
            }
        }
        if (($null -ne $ListView.Tag.PSObject.Properties['CustomerTemplateEditorSortColumn']) -and ([System.Int32]$ListView.Tag.CustomerTemplateEditorSortColumn -ge 0)) {
            $ListView.Sort()
        }
        Set-ListViewColumnAutoSize -ListView $ListView -Mode Widest
    }
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Starts inline editing for a clicked dictionary value.
.DESCRIPTION
    Resolves the value cell under a mouse event, opens the shared inline editor, applies the new
    value to the backing dictionary, and refreshes the row while preserving selection.
.EXAMPLE
    Start-CustomerTemplateDictionaryInlineEdit -ListView $ListView -Data $Settings -MouseEventArgs $EventArgs
.INPUTS
    [System.Windows.Forms.ListView]
    [System.Collections.IDictionary]
    [System.Windows.Forms.MouseEventArgs]
.OUTPUTS
    No objects are returned to the pipeline.
#>
####################################################################################################
function Start-CustomerTemplateDictionaryInlineEdit {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)][System.Windows.Forms.ListView]$ListView,
        [Parameter(Mandatory=$true)][System.Collections.IDictionary]$Data,
        [Parameter(Mandatory=$true)][System.Windows.Forms.MouseEventArgs]$MouseEventArgs
    )

    # PREPARATION - VALUE CELL
    [void](Complete-ListViewInlineEditors -ListView $ListView -InlineEditorMarker 'CustomerTemplateValueEditor')
    [System.Windows.Forms.ListViewHitTestInfo]$HitTest = Get-ListViewValueCellHitTest -ListView $ListView -MouseEventArgs $MouseEventArgs -ValueColumnIndex 1
    if (($null -eq $HitTest) -or ($null -eq $HitTest.Item.Tag)) { return }

    [System.String]$Key = [System.String]$HitTest.Item.Tag
    [System.Object]$CurrentValue = $Data[$Key]
    # EXECUTION - INLINE EDITOR
    Start-ListViewInlineValueEdit -ListView $ListView -HitTestInfo $HitTest -InlineEditorMarker 'CustomerTemplateValueEditor' -PropertyName $Key -CurrentValueObject $CurrentValue -CurrentValueText ([System.String]$CurrentValue) -StartMessageContext 'customer template property' -ApplyValueAction {
        param([System.String]$NewValue)
        $Data[$Key] = $NewValue
        Update-CustomerTemplateEditorDictionaryListView -ListView $ListView -Data $Data -KeyToSelect $Key
    }.GetNewClosure() -CompleteInlineEditorsAction {
        [void](Complete-ListViewInlineEditors -ListView $ListView -InlineEditorMarker 'CustomerTemplateValueEditor')
    }.GetNewClosure()
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Starts inline editing for the selected dictionary row.
.DESCRIPTION
    Validates a single selected property row, constructs a value-cell hit-test target, and opens
    the same shared inline editor used by double-click editing.
.EXAMPLE
    Start-CustomerTemplateSelectedDictionaryEdit -ListView $ListView -Data $Settings
.INPUTS
    [System.Windows.Forms.ListView]
    [System.Collections.IDictionary]
.OUTPUTS
    No objects are returned to the pipeline.
#>
####################################################################################################
function Start-CustomerTemplateSelectedDictionaryEdit {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)][System.Windows.Forms.ListView]$ListView,
        [Parameter(Mandatory=$true)][System.Collections.IDictionary]$Data
    )

    # VALIDATION - SELECTION
    if (($ListView.SelectedItems.Count -ne 1) -or ($null -eq $ListView.SelectedItems[0].Tag) -or ($ListView.SelectedItems[0].SubItems.Count -lt 2)) {
        Write-Line 'Select one entry to edit.' -Type Warning
        return
    }

    # PREPARATION - VALUE CELL
    [System.Windows.Forms.ListViewItem]$SelectedItem = $ListView.SelectedItems[0]
    [System.Windows.Forms.ListViewHitTestInfo]$HitTest = New-Object System.Windows.Forms.ListViewHitTestInfo($SelectedItem,$SelectedItem.SubItems[1],[System.Windows.Forms.ListViewHitTestLocations]::Label)
    [System.String]$Key = [System.String]$SelectedItem.Tag
    [System.Object]$CurrentValue = $Data[$Key]

    # EXECUTION - INLINE EDITOR
    [void](Complete-ListViewInlineEditors -ListView $ListView -InlineEditorMarker 'CustomerTemplateValueEditor')
    Start-ListViewInlineValueEdit -ListView $ListView -HitTestInfo $HitTest -InlineEditorMarker 'CustomerTemplateValueEditor' -PropertyName $Key -CurrentValueObject $CurrentValue -CurrentValueText ([System.String]$CurrentValue) -StartMessageContext 'customer template property' -ApplyValueAction {
        param([System.String]$NewValue)
        $Data[$Key] = $NewValue
        Update-CustomerTemplateEditorDictionaryListView -ListView $ListView -Data $Data -KeyToSelect $Key
    }.GetNewClosure() -CompleteInlineEditorsAction {
        [void](Complete-ListViewInlineEditors -ListView $ListView -InlineEditorMarker 'CustomerTemplateValueEditor')
    }.GetNewClosure()
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Prompts for a customer template dictionary entry.
.DESCRIPTION
    Displays a modal key/value dialog and returns the trimmed key and entered value when the user
    confirms a non-empty key.
.EXAMPLE
    Read-CustomerTemplateKeyValue -Title 'Add Setting' -KeyLabel 'Name' -ValueLabel 'Value'
.INPUTS
    [System.String]
    [System.Windows.Forms.IWin32Window]
.OUTPUTS
    [PSCustomObject]
#>
####################################################################################################
function Read-CustomerTemplateKeyValue {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory=$true)][System.String]$Title,
        [Parameter(Mandatory=$false)][System.String]$KeyLabel = 'Name',
        [Parameter(Mandatory=$false)][System.String]$ValueLabel = 'Value',
        [Parameter(Mandatory=$false)][AllowNull()][System.Windows.Forms.IWin32Window]$Owner
    )

    # PREPARATION - DIALOG
    [System.Windows.Forms.Form]$Dialog = New-ModalDialog -Title $Title -ClientWidth 500 -ClientHeight 190 -Owner $Owner
    try {
        # EXECUTION - CONTROLS
        [PSCustomObject]$DialogActions = New-ModalDialogActionBar -Dialog $Dialog -PrimaryText 'Add' -PrimaryDialogResult ([System.Windows.Forms.DialogResult]::OK) -ButtonWidth 75 -ButtonHeight 28
        [System.Windows.Forms.Label]$KeyPrompt = New-Object System.Windows.Forms.Label
        $KeyPrompt.Text = $KeyLabel; $KeyPrompt.SetBounds(15,15,470,20)
        [System.Windows.Forms.TextBox]$KeyTextBox = New-Object System.Windows.Forms.TextBox
        $KeyTextBox.SetBounds(15,36,470,24)
        [System.Windows.Forms.Label]$ValuePrompt = New-Object System.Windows.Forms.Label
        $ValuePrompt.Text = $ValueLabel; $ValuePrompt.SetBounds(15,70,470,20)
        [System.Windows.Forms.TextBox]$ValueTextBox = New-Object System.Windows.Forms.TextBox
        $ValueTextBox.SetBounds(15,91,470,24)
        $Dialog.Controls.AddRange(@($KeyPrompt,$KeyTextBox,$ValuePrompt,$ValueTextBox))
        $Dialog.Add_Shown({$KeyTextBox.Focus()}.GetNewClosure())
        # OUTPUT
        if ((Show-ModalDialog -Dialog $Dialog -Owner $Owner) -ne [System.Windows.Forms.DialogResult]::OK) { return }
        [System.String]$Key = $KeyTextBox.Text.Trim()
        if ([System.String]::IsNullOrWhiteSpace($Key)) { return }
        return [PSCustomObject]@{ Key = $Key; Value = [System.String]$ValueTextBox.Text }
    }
    finally {
        # POST-EXECUTION - DIALOG CLEANUP
        $Dialog.Dispose()
    }
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Adds an entry to an editable customer template dictionary.
.DESCRIPTION
    Prompts for a key and value, rejects duplicate keys, updates the backing dictionary, and
    refreshes the ListView with the new entry selected.
.EXAMPLE
    Add-CustomerTemplateDictionaryEntry -ListView $ListView -Data $Settings -Title 'Add Setting'
.INPUTS
    [System.Windows.Forms.ListView]
    [System.Collections.IDictionary]
.OUTPUTS
    No objects are returned to the pipeline.
#>
####################################################################################################
function Add-CustomerTemplateDictionaryEntry {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)][System.Windows.Forms.ListView]$ListView,
        [Parameter(Mandatory=$true)][System.Collections.IDictionary]$Data,
        [Parameter(Mandatory=$true)][System.String]$Title,
        [Parameter(Mandatory=$false)][System.String]$KeyLabel = 'Name',
        [Parameter(Mandatory=$false)][System.String]$ValueLabel = 'Value'
    )

    # PREPARATION - NEW ENTRY
    [PSCustomObject]$Entry = Read-CustomerTemplateKeyValue -Title $Title -KeyLabel $KeyLabel -ValueLabel $ValueLabel -Owner $ListView.FindForm()
    if ($null -eq $Entry) { return }
    if ($Data.Contains($Entry.Key)) { Write-Line "An entry named '$($Entry.Key)' already exists." -Type Warning; return }
    # EXECUTION - DICTIONARY UPDATE
    $Data[$Entry.Key] = $Entry.Value
    Update-CustomerTemplateEditorDictionaryListView -ListView $ListView -Data $Data -KeyToSelect $Entry.Key
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Removes the selected customer template dictionary entry.
.DESCRIPTION
    Validates that one row is selected, removes its tagged key from the backing dictionary, and
    refreshes the editor ListView.
.EXAMPLE
    Remove-CustomerTemplateDictionaryEntry -ListView $ListView -Data $Settings
.INPUTS
    [System.Windows.Forms.ListView]
    [System.Collections.IDictionary]
.OUTPUTS
    No objects are returned to the pipeline.
#>
####################################################################################################
function Remove-CustomerTemplateDictionaryEntry {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)][System.Windows.Forms.ListView]$ListView,
        [Parameter(Mandatory=$true)][System.Collections.IDictionary]$Data
    )

    # VALIDATION - SELECTION
    if (($ListView.SelectedItems.Count -ne 1) -or ($null -eq $ListView.SelectedItems[0].Tag)) { Write-Line 'Select one entry to delete.' -Type Warning; return }

    # EXECUTION - DICTIONARY UPDATE
    [System.String]$Key = [System.String]$ListView.SelectedItems[0].Tag
    $Data.Remove($Key)
    Update-CustomerTemplateEditorDictionaryListView -ListView $ListView -Data $Data
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Refreshes the editable mail-template ListView.
.DESCRIPTION
    Rebuilds mail name and subject rows from the backing dictionary, restores an optional
    selection, reapplies active sorting, and sizes columns to their widest content.
.EXAMPLE
    Update-CustomerTemplateMailListView -ListView $ListView -MailTemplates $MailTemplates
.INPUTS
    [System.Windows.Forms.ListView]
    [System.Collections.IDictionary]
.OUTPUTS
    No objects are returned to the pipeline.
#>
####################################################################################################
function Update-CustomerTemplateMailListView {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)][System.Windows.Forms.ListView]$ListView,
        [Parameter(Mandatory=$true)][System.Collections.IDictionary]$MailTemplates,
        [Parameter(Mandatory=$false)][System.String]$NameToSelect
    )

    # EXECUTION - ROW REFRESH
    Invoke-ListViewBatchUpdate -ListView $ListView -Action {
        $ListView.Items.Clear()
        foreach ($Name in $MailTemplates.Keys) {
            [System.Collections.IDictionary]$Mail = $MailTemplates[$Name]
            [System.Windows.Forms.ListViewItem]$Item = New-Object System.Windows.Forms.ListViewItem([System.String]$Name)
            [void]$Item.SubItems.Add([System.String]$Mail.Subject)
            $Item.Tag = [System.String]$Name
            [void]$ListView.Items.Add($Item)
            if ([System.String]::Equals([System.String]$Name,$NameToSelect,[System.StringComparison]::Ordinal)) { $Item.Selected = $true; $Item.Focused = $true }
        }
        if (($null -ne $ListView.Tag.PSObject.Properties['CustomerTemplateEditorSortColumn']) -and ([System.Int32]$ListView.Tag.CustomerTemplateEditorSortColumn -ge 0)) {
            $ListView.Sort()
        }
        Set-ListViewColumnAutoSize -ListView $ListView -Mode Widest
    }
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Shows the Customer Template editor dialog.
.DESCRIPTION
    Loads an editable Schema 2 model, builds General, Application Folders, AppLocker, and Mail
    Templates tabs, binds controls to the mutable model, and saves through transactional bundle
    validation before refreshing the inventory selection.
.EXAMPLE
    Show-CustomerTemplateEditorDialog -CustomerTemplate $Template -InventoryListView $Inventory
.INPUTS
    [System.Object]
    [System.Windows.Forms.ListView]
.OUTPUTS
    [System.Boolean]
#>
####################################################################################################
function Show-CustomerTemplateEditorDialog {
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param (
        [Parameter(Mandatory=$true)][System.Object]$CustomerTemplate,
        [Parameter(Mandatory=$true)][System.Windows.Forms.ListView]$InventoryListView
    )

    # PREPARATION - EDITOR MODEL
    try { [PSCustomObject]$Model = Get-CustomerTemplateEditorModel -CustomerTemplate $CustomerTemplate }
    catch { Write-Line $_.Exception.Message -Type Warning; return $false }

    # PREPARATION - DIALOG SHELL
    [System.Windows.Forms.Form]$Dialog = New-ModalDialog -Title "Edit Customer Template - $($CustomerTemplate.Identity)" -ClientWidth 980 -ClientHeight 680 -Owner $InventoryListView.FindForm() -Resizable -MinimumWidth 800 -MinimumHeight 600
    Set-FormIconFromButtonIcon -Form $Dialog -IconName 'report_word'

    [System.Windows.Forms.TabControl]$Tabs = New-Object System.Windows.Forms.TabControl
    $Tabs.Dock = [System.Windows.Forms.DockStyle]::Fill
    $Tabs.Padding = New-Object System.Drawing.Point(14,5)
    $Dialog.Controls.Add($Tabs)
    [PSCustomObject]$DialogActions = New-ModalDialogActionBar -Dialog $Dialog -PrimaryText 'Save'
    [System.Windows.Forms.Button]$SaveButton = $DialogActions.PrimaryButton
    [System.Windows.Forms.Button]$CancelButton = $DialogActions.CancelButton

    # EXECUTION - GENERAL TAB
    # Expose editable manifest values without allowing schema, template ID, or component metadata changes.
    [System.Windows.Forms.ListView]$GeneralList = New-CustomerTemplateEditorListView
    [System.Collections.Hashtable]$GeneralData = @{
        Identity        = [System.String]$Model.Manifest.Identity
        TemplateName    = [System.String]$Model.Manifest.TemplateName
        TatTemplateName = if ($Model.Manifest.ContainsKey('TatTemplateName')) { [System.String]$Model.Manifest.TatTemplateName } else { '' }
        UDFName         = [System.String]$Model.Manifest.UDFName
    }
    [System.Windows.Forms.TabPage]$GeneralTab = New-Object System.Windows.Forms.TabPage('General')
    [System.Windows.Forms.FlowLayoutPanel]$GeneralActions = New-Object System.Windows.Forms.FlowLayoutPanel
    $GeneralActions.Dock = 'Bottom'; $GeneralActions.Height = 42
    [System.Windows.Forms.Button]$EditGeneralButton = New-Object System.Windows.Forms.Button
    $EditGeneralButton.Text = 'Edit'; $EditGeneralButton.Size = New-Object System.Drawing.Size(80,28)
    $GeneralActions.Controls.Add($EditGeneralButton); $GeneralTab.Controls.AddRange(@($GeneralList,$GeneralActions))
    Update-CustomerTemplateEditorDictionaryListView -ListView $GeneralList -Data $GeneralData -PreferredKeyOrder @('Identity','TemplateName','TatTemplateName','UDFName')
    $GeneralList.Add_MouseDoubleClick({param($EventSender,$EventArguments) Start-CustomerTemplateDictionaryInlineEdit -ListView $GeneralList -Data $GeneralData -MouseEventArgs $EventArguments}.GetNewClosure())
    $EditGeneralButton.Add_Click({Start-CustomerTemplateSelectedDictionaryEdit -ListView $GeneralList -Data $GeneralData}.GetNewClosure())

    # EXECUTION - APPLICATION FOLDERS TAB
    [System.Windows.Forms.ListView]$FoldersList = New-CustomerTemplateEditorListView -Columns @('Folder Key','Relative Path')
    [System.Windows.Forms.TabPage]$FoldersTab = New-Object System.Windows.Forms.TabPage('Application Folders')
    [System.Windows.Forms.FlowLayoutPanel]$FoldersActions = New-Object System.Windows.Forms.FlowLayoutPanel
    $FoldersActions.Dock = 'Bottom'; $FoldersActions.Height = 42; $FoldersActions.FlowDirection = 'LeftToRight'
    [System.Windows.Forms.Button]$AddFolderButton = New-Object System.Windows.Forms.Button
    $AddFolderButton.Text = 'Add'; $AddFolderButton.Size = New-Object System.Drawing.Size(80,28)
    [System.Windows.Forms.Button]$EditFolderButton = New-Object System.Windows.Forms.Button
    $EditFolderButton.Text = 'Edit'; $EditFolderButton.Size = New-Object System.Drawing.Size(80,28)
    [System.Windows.Forms.Button]$DeleteFolderButton = New-Object System.Windows.Forms.Button
    $DeleteFolderButton.Text = 'Delete'; $DeleteFolderButton.Size = New-Object System.Drawing.Size(80,28)
    $FoldersActions.Controls.AddRange(@($AddFolderButton,$EditFolderButton,$DeleteFolderButton)); $FoldersTab.Controls.AddRange(@($FoldersList,$FoldersActions))
    Update-CustomerTemplateEditorDictionaryListView -ListView $FoldersList -Data $Model.ApplicationFolderSubFolders
    $FoldersList.Add_MouseDoubleClick({param($EventSender,$EventArguments) Start-CustomerTemplateDictionaryInlineEdit -ListView $FoldersList -Data $Model.ApplicationFolderSubFolders -MouseEventArgs $EventArguments}.GetNewClosure())
    $AddFolderButton.Add_Click({Add-CustomerTemplateDictionaryEntry -ListView $FoldersList -Data $Model.ApplicationFolderSubFolders -Title 'Add Application Folder' -KeyLabel 'Folder key' -ValueLabel 'Relative path'}.GetNewClosure())
    $EditFolderButton.Add_Click({Start-CustomerTemplateSelectedDictionaryEdit -ListView $FoldersList -Data $Model.ApplicationFolderSubFolders}.GetNewClosure())
    $DeleteFolderButton.Add_Click({Remove-CustomerTemplateDictionaryEntry -ListView $FoldersList -Data $Model.ApplicationFolderSubFolders}.GetNewClosure())

    # EXECUTION - APPLOCKER TAB
    [System.Windows.Forms.ListView]$AppLockerList = New-CustomerTemplateEditorListView -Columns @('Setting','Value')
    [System.Windows.Forms.TabPage]$AppLockerTab = New-Object System.Windows.Forms.TabPage('AppLocker')
    [System.Windows.Forms.FlowLayoutPanel]$AppLockerActions = New-Object System.Windows.Forms.FlowLayoutPanel
    $AppLockerActions.Dock = 'Bottom'; $AppLockerActions.Height = 42
    [System.Windows.Forms.Button]$AddAppLockerButton = New-Object System.Windows.Forms.Button
    $AddAppLockerButton.Text = 'Add'; $AddAppLockerButton.Size = New-Object System.Drawing.Size(80,28)
    [System.Windows.Forms.Button]$EditAppLockerButton = New-Object System.Windows.Forms.Button
    $EditAppLockerButton.Text = 'Edit'; $EditAppLockerButton.Size = New-Object System.Drawing.Size(80,28)
    [System.Windows.Forms.Button]$DeleteAppLockerButton = New-Object System.Windows.Forms.Button
    $DeleteAppLockerButton.Text = 'Delete'; $DeleteAppLockerButton.Size = New-Object System.Drawing.Size(80,28)
    $AppLockerActions.Controls.AddRange(@($AddAppLockerButton,$EditAppLockerButton,$DeleteAppLockerButton)); $AppLockerTab.Controls.AddRange(@($AppLockerList,$AppLockerActions))
    Update-CustomerTemplateEditorDictionaryListView -ListView $AppLockerList -Data $Model.AppLockerDefaultSettings
    $AppLockerList.Add_MouseDoubleClick({param($EventSender,$EventArguments) Start-CustomerTemplateDictionaryInlineEdit -ListView $AppLockerList -Data $Model.AppLockerDefaultSettings -MouseEventArgs $EventArguments}.GetNewClosure())
    $AddAppLockerButton.Add_Click({Add-CustomerTemplateDictionaryEntry -ListView $AppLockerList -Data $Model.AppLockerDefaultSettings -Title 'Add AppLocker Setting' -KeyLabel 'Setting name' -ValueLabel 'Value'}.GetNewClosure())
    $EditAppLockerButton.Add_Click({Start-CustomerTemplateSelectedDictionaryEdit -ListView $AppLockerList -Data $Model.AppLockerDefaultSettings}.GetNewClosure())
    $DeleteAppLockerButton.Add_Click({Remove-CustomerTemplateDictionaryEntry -ListView $AppLockerList -Data $Model.AppLockerDefaultSettings}.GetNewClosure())

    # EXECUTION - MAIL TEMPLATES TAB
    # Keep subject and multiline body fields synchronized with the selected mail dictionary entry.
    [System.Windows.Forms.TabPage]$MailTab = New-Object System.Windows.Forms.TabPage('Mail Templates')
    [System.Windows.Forms.SplitContainer]$MailSplit = New-Object System.Windows.Forms.SplitContainer
    $MailSplit.Dock = 'Fill'; $MailSplit.SplitterDistance = 400
    [System.Windows.Forms.ListView]$MailList = New-CustomerTemplateEditorListView -Columns @('Template','Subject')
    [System.Windows.Forms.FlowLayoutPanel]$MailActions = New-Object System.Windows.Forms.FlowLayoutPanel
    $MailActions.Dock = 'Bottom'; $MailActions.Height = 42
    [System.Windows.Forms.Button]$AddMailButton = New-Object System.Windows.Forms.Button
    $AddMailButton.Text = 'Add'; $AddMailButton.Size = New-Object System.Drawing.Size(80,28)
    [System.Windows.Forms.Button]$DeleteMailButton = New-Object System.Windows.Forms.Button
    $DeleteMailButton.Text = 'Delete'; $DeleteMailButton.Size = New-Object System.Drawing.Size(80,28)
    $MailActions.Controls.AddRange(@($AddMailButton,$DeleteMailButton)); $MailSplit.Panel1.Controls.AddRange(@($MailList,$MailActions))
    [System.Windows.Forms.TableLayoutPanel]$MailFields = New-Object System.Windows.Forms.TableLayoutPanel
    $MailFields.Dock = 'Fill'; $MailFields.Padding = New-Object System.Windows.Forms.Padding(8); $MailFields.ColumnCount = 1; $MailFields.RowCount = 6
    [void]$MailFields.RowStyles.Add((New-Object System.Windows.Forms.RowStyle('Absolute',22))); [void]$MailFields.RowStyles.Add((New-Object System.Windows.Forms.RowStyle('Absolute',28))); [void]$MailFields.RowStyles.Add((New-Object System.Windows.Forms.RowStyle('Absolute',22))); [void]$MailFields.RowStyles.Add((New-Object System.Windows.Forms.RowStyle('Absolute',28))); [void]$MailFields.RowStyles.Add((New-Object System.Windows.Forms.RowStyle('Absolute',22))); [void]$MailFields.RowStyles.Add((New-Object System.Windows.Forms.RowStyle('Percent',100)))
    [System.Windows.Forms.Label]$MailNameLabel = New-Object System.Windows.Forms.Label; $MailNameLabel.Text = 'Template'; $MailNameLabel.Dock = 'Fill'
    [System.Windows.Forms.TextBox]$MailNameTextBox = New-Object System.Windows.Forms.TextBox; $MailNameTextBox.Dock = 'Fill'; $MailNameTextBox.ReadOnly = $true
    [System.Windows.Forms.Label]$MailSubjectLabel = New-Object System.Windows.Forms.Label; $MailSubjectLabel.Text = 'Subject'; $MailSubjectLabel.Dock = 'Fill'
    [System.Windows.Forms.TextBox]$MailSubjectTextBox = New-Object System.Windows.Forms.TextBox; $MailSubjectTextBox.Dock = 'Fill'
    [System.Windows.Forms.Label]$MailBodyLabel = New-Object System.Windows.Forms.Label; $MailBodyLabel.Text = 'Body'; $MailBodyLabel.Dock = 'Fill'
    [System.Windows.Forms.TextBox]$MailBodyTextBox = New-Object System.Windows.Forms.TextBox; $MailBodyTextBox.Dock = 'Fill'; $MailBodyTextBox.Multiline = $true; $MailBodyTextBox.ScrollBars = 'Vertical'; $MailBodyTextBox.AcceptsReturn = $true
    $MailFields.Controls.Add($MailNameLabel,0,0); $MailFields.Controls.Add($MailNameTextBox,0,1); $MailFields.Controls.Add($MailSubjectLabel,0,2); $MailFields.Controls.Add($MailSubjectTextBox,0,3); $MailFields.Controls.Add($MailBodyLabel,0,4); $MailFields.Controls.Add($MailBodyTextBox,0,5)
    $MailSplit.Panel2.Controls.Add($MailFields); $MailTab.Controls.Add($MailSplit)
    Update-CustomerTemplateMailListView -ListView $MailList -MailTemplates $Model.MailTemplates
    $MailList.Add_SelectedIndexChanged({
        if ($MailList.SelectedItems.Count -ne 1) { return }
        [System.String]$Name = [System.String]$MailList.SelectedItems[0].Tag
        [System.Collections.IDictionary]$Mail = $Model.MailTemplates[$Name]
        $MailNameTextBox.Text = $Name; $MailSubjectTextBox.Text = [System.String]$Mail.Subject; $MailBodyTextBox.Text = [System.String]$Mail.Body
    }.GetNewClosure())
    $MailSubjectTextBox.Add_TextChanged({if(-not [System.String]::IsNullOrWhiteSpace($MailNameTextBox.Text)){$Model.MailTemplates[$MailNameTextBox.Text]['Subject']=$MailSubjectTextBox.Text}}.GetNewClosure())
    $MailBodyTextBox.Add_TextChanged({if(-not [System.String]::IsNullOrWhiteSpace($MailNameTextBox.Text)){$Model.MailTemplates[$MailNameTextBox.Text]['Body']=$MailBodyTextBox.Text}}.GetNewClosure())
    $AddMailButton.Add_Click({
        [PSCustomObject]$Entry = Read-CustomerTemplateKeyValue -Title 'Add Mail Template' -KeyLabel 'Template name' -ValueLabel 'Subject' -Owner $Dialog
        if($null -eq $Entry){return}; if($Model.MailTemplates.Contains($Entry.Key)){Write-Line "A mail template named '$($Entry.Key)' already exists." -Type Warning;return}
        $Model.MailTemplates[$Entry.Key]=@{Subject=$Entry.Value;Body=''}; Update-CustomerTemplateMailListView -ListView $MailList -MailTemplates $Model.MailTemplates -NameToSelect $Entry.Key
    }.GetNewClosure())
    $DeleteMailButton.Add_Click({
        if($MailList.SelectedItems.Count-ne 1){Write-Line 'Select one mail template to delete.' -Type Warning;return};$Name=[System.String]$MailList.SelectedItems[0].Tag;$Model.MailTemplates.Remove($Name);$MailNameTextBox.Clear();$MailSubjectTextBox.Clear();$MailBodyTextBox.Clear();Update-CustomerTemplateMailListView -ListView $MailList -MailTemplates $Model.MailTemplates
    }.GetNewClosure())

    # EXECUTION - DIALOG ACTIONS
    $Tabs.TabPages.AddRange(@($GeneralTab,$FoldersTab,$AppLockerTab,$MailTab))
    $CancelButton.Add_Click({$Dialog.DialogResult=[System.Windows.Forms.DialogResult]::Cancel;$Dialog.Close()}.GetNewClosure())
    $SaveButton.Add_Click({
        try {
            # VALIDATION - PENDING EDITS
            # Commit active inline editors and require a usable identity before transactional saving.
            foreach($List in @($GeneralList,$FoldersList,$AppLockerList)){[void](Complete-ListViewInlineEditors -ListView $List -InlineEditorMarker 'CustomerTemplateValueEditor')}
            foreach($Key in @('Identity','TemplateName','TatTemplateName','UDFName')){
                if ($GeneralData.ContainsKey($Key) -and (Test-String -IsPopulated $GeneralData[$Key])) {
                    $Model.Manifest[$Key] = $GeneralData[$Key]
                }
                elseif ($Key -eq 'TatTemplateName' -and $Model.Manifest.ContainsKey('TatTemplateName') -and (Test-String -IsEmpty $GeneralData[$Key])) {
                    $Model.Manifest.Remove('TatTemplateName')
                }
                elseif ($Key -ne 'TatTemplateName') {
                    $Model.Manifest[$Key] = $GeneralData[$Key]
                }
            }
            if([System.String]::IsNullOrWhiteSpace([System.String]$Model.Manifest.Identity)){Write-Line 'Customer template Identity cannot be empty.' -Type Warning;return}
            if(Save-CustomerTemplateEditorModel -EditorModel $Model){Update-CustomerTemplateListView -ListView $InventoryListView -TemplatePathToSelect ([System.String]$CustomerTemplate.TemplatePath);Write-Line "Saved customer template: $($Model.Manifest.Identity)" -Type Success;$Dialog.DialogResult=[System.Windows.Forms.DialogResult]::OK;$Dialog.Close()}
        }
        catch { Write-ErrorReport -ErrorRecord $_ }
    }.GetNewClosure())

    # OUTPUT
    try { return ((Show-ModalDialog -Dialog $Dialog -Owner $InventoryListView.FindForm()) -eq [System.Windows.Forms.DialogResult]::OK) }
    finally {
        # POST-EXECUTION - DIALOG CLEANUP
        $Dialog.Dispose()
    }
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Edits the selected customer template.
.DESCRIPTION
    Requires one inventory row containing a discovered customer template and opens the Customer
    Template editor for that selection.
.EXAMPLE
    Edit-SelectedCustomerTemplate -ListView $CustomerTemplateListView
.INPUTS
    [System.Windows.Forms.ListView]
.OUTPUTS
    No objects are returned to the pipeline.
#>
####################################################################################################
function Edit-SelectedCustomerTemplate {
    [CmdletBinding()]
    param ([Parameter(Mandatory=$true)][System.Windows.Forms.ListView]$ListView)

    # VALIDATION - INVENTORY SELECTION
    if (($ListView.SelectedItems.Count -ne 1) -or ($null -eq $ListView.SelectedItems[0].Tag)) { Write-Line 'Select one customer template to edit.' -Type Warning; return }

    # EXECUTION - EDITOR DIALOG
    [void](Show-CustomerTemplateEditorDialog -CustomerTemplate $ListView.SelectedItems[0].Tag -InventoryListView $ListView)
}

### END OF FUNCTION
####################################################################################################
