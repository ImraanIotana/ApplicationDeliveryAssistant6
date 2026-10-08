####################################################################################################
<#
.SYNOPSIS
    Updates the deployment-object list row-number column based on current item order.
.DESCRIPTION
    This helper renumbers the first ListView column so it always matches the in-memory
    ordering of deployment objects after move or delete actions.
.EXAMPLE
    Update-UDFDeploymentObjectListViewRowNumbers -SourceListView $DeploymentObjectsListView
.INPUTS
    [System.Windows.Forms.ListView]
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.2.0
    Author          : Imraan Iotana
    Creation Date   : August 2026
    Last Update     : August 2026
#>
####################################################################################################
function Update-UDFDeploymentObjectListViewRowNumbers {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The deployment objects ListView to renumber.')]
        [System.Windows.Forms.ListView]$SourceListView
    )

    # EXECUTION - RENNUMBER DISPLAY ROWS
    # Keep the first column synchronized with the current in-memory item order.
    for ($ItemIndex = 0; $ItemIndex -lt $SourceListView.Items.Count; $ItemIndex++) {
        $SourceListView.Items[$ItemIndex].Text = [System.String]($ItemIndex + 1)
    }
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Runs deployment-object ListView mutations inside BeginUpdate/EndUpdate.
.DESCRIPTION
    Centralizes flicker-safe update wrapping for add/move/remove operations.
.EXAMPLE
    Invoke-UDFDeploymentObjectListViewBatchUpdate -SourceListView $ListView -Action { ... }
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
function Invoke-UDFDeploymentObjectListViewBatchUpdate {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The deployment objects ListView to update.')]
        [System.Windows.Forms.ListView]$SourceListView,

        [Parameter(Mandatory=$true,HelpMessage='The action that mutates rows in a single paint cycle.')]
        [System.Management.Automation.ScriptBlock]$Action
    )

    Invoke-ListViewBatchUpdate -ListView $SourceListView -Action $Action
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Sets deployment-object ListView selection by row index.
.DESCRIPTION
    Applies optional clear/focus/visibility behavior in one helper.
.EXAMPLE
    Set-UDFDeploymentObjectListViewSelectionByIndex -SourceListView $ListView -Index 2 -ClearExisting -SetFocus -EnsureVisible
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
function Set-UDFDeploymentObjectListViewSelectionByIndex {
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The deployment objects ListView that owns the row.')]
        [System.Windows.Forms.ListView]$SourceListView,

        [Parameter(Mandatory=$true,HelpMessage='The target row index to select.')]
        [System.Int32]$Index,

        [Parameter(Mandatory=$false,HelpMessage='Clears existing selection before selecting the row.')]
        [System.Management.Automation.SwitchParameter]$ClearExisting,

        [Parameter(Mandatory=$false,HelpMessage='Sets keyboard focus on the selected row.')]
        [System.Management.Automation.SwitchParameter]$SetFocus,

        [Parameter(Mandatory=$false,HelpMessage='Scrolls the selected row into view.')]
        [System.Management.Automation.SwitchParameter]$EnsureVisible
    )

    return (Set-ListViewSelectionByIndex -ListView $SourceListView -Index $Index -ClearExisting:$ClearExisting -SetFocus:$SetFocus -EnsureVisible:$EnsureVisible)
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Moves the selected deployment object one position up or down in the list.
.DESCRIPTION
    This helper validates single-row selection, applies an index offset, reorders the selected
    ListView row, updates row numbering, and restores selection/focus for smooth UI behavior.
.EXAMPLE
    Move-UDFSelectedDeploymentObjectByOffset -SourceListView $DeploymentObjectsListView -Offset -1
.INPUTS
    [System.Windows.Forms.ListView]
    [System.Int32]
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
function Move-UDFSelectedDeploymentObjectByOffset {
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The deployment objects ListView that contains the selected row.')]
        [System.Windows.Forms.ListView]$SourceListView,

        [Parameter(Mandatory=$true,HelpMessage='The move offset: -1 for up, +1 for down.')]
        [System.Int32]$Offset
    )

    try {
        # VALIDATION - SOURCE LISTVIEW
        # Ensure a target control exists before attempting reorder operations.
        if ($null -eq $SourceListView) {
            return $false
        }

        # VALIDATION - MINIMUM ROW COUNT
        # Reordering requires at least two deployment objects.
        if ($SourceListView.Items.Count -lt 2) {
            Write-Line 'At least two deployment objects are required to reorder.' -Type Warning
            return $false
        }

        # VALIDATION - SINGLE SELECTION
        # Exactly one row must be selected to move it predictably.
        if (($null -eq $SourceListView.SelectedItems) -or ($SourceListView.SelectedItems.Count -ne 1)) {
            Write-Line 'Select one deployment object before moving.' -Type Warning
            return $false
        }

        # PREPARATION - INDEX TARGETS
        # Resolve current and destination indexes for the selected row.
        [System.Windows.Forms.ListViewItem]$SelectedItem = $SourceListView.SelectedItems[0]
        [System.Int32]$CurrentIndex = $SelectedItem.Index
        [System.Int32]$TargetIndex = ($CurrentIndex + $Offset)
        [System.String]$ObjectType = if ($SelectedItem.SubItems.Count -gt 1) { [System.String]$SelectedItem.SubItems[1].Text } else { '' }
        if ([System.String]::IsNullOrWhiteSpace($ObjectType)) {
            $ObjectType = 'UnknownType'
        }

        # VALIDATION - BOUNDS CHECK
        # Skip move when target index falls outside current list boundaries.
        if (($TargetIndex -lt 0) -or ($TargetIndex -ge $SourceListView.Items.Count)) {
            return $false
        }

        # EXECUTION - REORDER ROW
        # Move selected row, refresh row numbers, and set dirty state.
        Invoke-UDFDeploymentObjectListViewBatchUpdate -SourceListView $SourceListView -Action {
            $SourceListView.Items.RemoveAt($CurrentIndex)
            $SourceListView.Items.Insert($TargetIndex, $SelectedItem)
            Update-UDFDeploymentObjectListViewRowNumbers -SourceListView $SourceListView

            # POST-EXECUTION - RESTORE SELECTION
            # Keep keyboard and visual focus on the moved row.
            [void](Set-UDFDeploymentObjectListViewSelectionByIndex -SourceListView $SourceListView -Index $TargetIndex -SetFocus -EnsureVisible)
        }

        # OUTPUT - USER FEEDBACK
        # Mirror inline edit confirmations by reporting the move in host output.
        Write-Line "Moved '$ObjectType': '$($CurrentIndex + 1)' -> '$($TargetIndex + 1)'." -Type Success

        # OUTPUT - OPERATION RESULT
        # Signal success to calling button handlers.
        return $true
    }
    catch {
        # ERROR HANDLING - SAFE FAILURE
        # Report exception details and return false for callers.
        Write-ErrorReport -ErrorRecord $_
        return $false
    }
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Deletes the selected deployment object from the list after user confirmation.
.DESCRIPTION
    This helper validates single-row selection, prompts the user for confirmation, removes the
    selected ListView row, renumbers remaining rows, and restores logical selection/focus.
.EXAMPLE
    Remove-UDFSelectedDeploymentObject -SourceListView $DeploymentObjectsListView
.INPUTS
    [System.Windows.Forms.ListView]
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
function Remove-UDFSelectedDeploymentObject {
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The deployment objects ListView that contains the selected row.')]
        [System.Windows.Forms.ListView]$SourceListView
    )

    try {
        # VALIDATION - SOURCE LISTVIEW
        # Ensure a target control exists before attempting delete operations.
        if ($null -eq $SourceListView) {
            return $false
        }

        # VALIDATION - SINGLE SELECTION
        # Exactly one row must be selected to delete it predictably.
        if (($null -eq $SourceListView.SelectedItems) -or ($SourceListView.SelectedItems.Count -ne 1)) {
            Write-Line 'Select one deployment object before deleting.' -Type Warning
            return $false
        }

        # PREPARATION - SELECTED ROW CONTEXT
        # Resolve selected row metadata for confirmation and feedback.
        [System.Windows.Forms.ListViewItem]$SelectedItem = [System.Windows.Forms.ListViewItem]$SourceListView.SelectedItems[0]
        [System.Int32]$CurrentIndex = [System.Int32]$SelectedItem.Index
        [System.String]$ObjectType = if ($SelectedItem.SubItems.Count -gt 1) { [System.String]$SelectedItem.SubItems[1].Text } else { '' }
        if ([System.String]::IsNullOrWhiteSpace($ObjectType)) {
            $ObjectType = 'UnknownType'
        }

        # VALIDATION - USER CONFIRMATION
        # Confirm with the user before removing the selected deployment object.
        [System.String]$Title = 'Confirm Delete Deployment Object'
        [System.String]$Body = "This will delete the selected deployment object:`n`nType: $ObjectType`nRow: $($CurrentIndex + 1)`n`nDo you want to continue?"
        if (-not (Get-UserConfirmation -Title $Title -Body $Body -Type Warning)) {
            return $false
        }

        # EXECUTION - REMOVE ROW
        # Remove selected row, renumber remaining rows, and restore logical selection.
        Invoke-UDFDeploymentObjectListViewBatchUpdate -SourceListView $SourceListView -Action {
            $SourceListView.Items.RemoveAt($CurrentIndex)
            Update-UDFDeploymentObjectListViewRowNumbers -SourceListView $SourceListView

            if ($SourceListView.Items.Count -gt 0) {
                [System.Int32]$NextIndex = [System.Math]::Min($CurrentIndex, ($SourceListView.Items.Count - 1))
                [void](Set-UDFDeploymentObjectListViewSelectionByIndex -SourceListView $SourceListView -Index $NextIndex -SetFocus -EnsureVisible)
            }
        }

        # OUTPUT - USER FEEDBACK
        # Mirror list action confirmations by reporting the deleted row details.
        Write-Line "Deleted '$ObjectType' at row '$($CurrentIndex + 1)'." -Type Success

        # OUTPUT - OPERATION RESULT
        # Signal success to calling button handlers.
        return $true
    }
    catch {
        # ERROR HANDLING - SAFE FAILURE
        # Report exception details and return false for callers.
        Write-ErrorReport -ErrorRecord $_
        return $false
    }
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Creates a new deployment object and preferred property order from catalog metadata.
.DESCRIPTION
    This helper reads one object type definition from the internal DeploymentData catalog and
    returns a new default deployment object plus the preferred field order used by the UI and
    serializer.
.EXAMPLE
    New-UDFDeploymentObjectFromCatalogType -InternalCatalog $Catalog -ObjectTypeName 'DEPLOYMSI'
.INPUTS
    [System.Collections.Hashtable]
    [System.String]
.OUTPUTS
    [System.Management.Automation.PSCustomObject]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.4
    Author          : Imraan Iotana
    Creation Date   : August 2026
    Last Update     : August 2026
#>
####################################################################################################
function New-UDFDeploymentObjectFromCatalogType {
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSCustomObject])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The internal catalog hashtable loaded from DeploymentData._Catalog.')]
        [System.Collections.Hashtable]$InternalCatalog,

        [Parameter(Mandatory=$true,HelpMessage='The deployment object type name to instantiate.')]
        [System.String]$ObjectTypeName
    )

    # VALIDATION - OBJECT TYPE DEFINITION
    # Return null when the requested type is not present in the catalog.
    if ((-not $InternalCatalog.ContainsKey('ObjectTypes')) -or ($null -eq $InternalCatalog.ObjectTypes) -or (-not $InternalCatalog.ObjectTypes.ContainsKey($ObjectTypeName))) {
        return $null
    }

    [System.Collections.Hashtable]$TypeDefinition = [System.Collections.Hashtable]$InternalCatalog.ObjectTypes[$ObjectTypeName]
    [System.Object[]]$FieldDefinitions = @()
    if ($TypeDefinition.ContainsKey('Fields')) {
        $FieldDefinitions = @($TypeDefinition.Fields)
    }

    # PREPARATION - DEFAULT OBJECT
    # Build a fresh object and stable property order from the catalog fields.
    [System.Collections.Hashtable]$DeploymentObject = @{}
    $DeploymentObject['Type'] = [System.String]$ObjectTypeName

    [System.Collections.Generic.List[System.String]]$PropertyOrder = New-Object 'System.Collections.Generic.List[System.String]'
    $PropertyOrder.Add('Type') | Out-Null

    foreach ($FieldDefinition in $FieldDefinitions) {
        if (($null -eq $FieldDefinition) -or (-not $FieldDefinition.ContainsKey('Name'))) {
            continue
        }

        [System.String]$FieldName = [System.String]$FieldDefinition.Name
        if ([System.String]::IsNullOrWhiteSpace($FieldName)) {
            continue
        }

        [System.Object]$DefaultValue = $null
        if ($FieldDefinition.ContainsKey('Default')) {
            $DefaultValue = $FieldDefinition.Default
        }

        # Clone array defaults so each new object gets an independent collection instance.
        if ($DefaultValue -is [System.Array]) {
            $DefaultValue = @($DefaultValue)
        }

        $DeploymentObject[$FieldName] = $DefaultValue
        $PropertyOrder.Add($FieldName) | Out-Null
    }

    return [PSCustomObject]@{
        DeploymentObject = $DeploymentObject
        PropertyOrder    = $PropertyOrder.ToArray()
    }
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Resolves ordered picker entries from the internal deployment object catalog.
.DESCRIPTION
    This helper converts `_Catalog.ObjectTypes` metadata into a stable ordered entry list used by
    both the richer Add dialog and the fallback ComboBox picker.
.EXAMPLE
    Get-UDFCatalogPickerEntries -InternalCatalog $Catalog
.INPUTS
    [System.Collections.Hashtable]
.OUTPUTS
    [System.Management.Automation.PSCustomObject[]]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.4
    Author          : Imraan Iotana
    Creation Date   : August 2026
    Last Update     : August 2026
#>
####################################################################################################
function Get-UDFCatalogPickerEntries {
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSCustomObject[]])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The internal catalog hashtable loaded from DeploymentData._Catalog.')]
        [System.Collections.Hashtable]$InternalCatalog
    )

    # VALIDATION - CATALOG CONTENT
    # Return an empty array when no object-type metadata exists.
    if ((-not $InternalCatalog.ContainsKey('ObjectTypes')) -or ($null -eq $InternalCatalog.ObjectTypes) -or ($InternalCatalog.ObjectTypes.Keys.Count -lt 1)) {
        return @()
    }

    [System.Collections.Generic.List[PSCustomObject]]$PickerEntries = New-Object 'System.Collections.Generic.List[PSCustomObject]'
    foreach ($ObjectTypeName in @($InternalCatalog.ObjectTypes.Keys)) {
        [System.Collections.Hashtable]$TypeDefinition = [System.Collections.Hashtable]$InternalCatalog.ObjectTypes[$ObjectTypeName]
        [System.String]$CategoryLabel = ''
        [System.String]$CategoryDisplayName = ''
        [System.String]$FriendlyDisplayName = [System.String]$ObjectTypeName
        [System.String]$Description = ''
        [System.Int32]$CategoryOrder = 9999
        [System.Int32]$PickerOrder = 9999

        if (($null -ne $TypeDefinition) -and $TypeDefinition.ContainsKey('Category') -and (Test-String -IsPopulated ([System.String]$TypeDefinition.Category))) {
            $CategoryLabel = [System.String]$TypeDefinition.Category
            if ($CategoryLabel -match '^(\d+)') {
                $CategoryOrder = [System.Int32]$Matches[1]
            }
            if ($CategoryLabel -match '^\d+\s*-\s*(.+)$') {
                $CategoryDisplayName = [System.String]$Matches[1]
            }
            else {
                $CategoryDisplayName = $CategoryLabel
            }
        }
        if (($null -ne $TypeDefinition) -and $TypeDefinition.ContainsKey('CategoryOrder')) {
            $CategoryOrder = [System.Int32]$TypeDefinition.CategoryOrder
        }
        if (($null -ne $TypeDefinition) -and $TypeDefinition.ContainsKey('PickerOrder')) {
            $PickerOrder = [System.Int32]$TypeDefinition.PickerOrder
        }
        if (($null -ne $TypeDefinition) -and $TypeDefinition.ContainsKey('CategoryDisplayName') -and (Test-String -IsPopulated ([System.String]$TypeDefinition.CategoryDisplayName))) {
            $CategoryDisplayName = [System.String]$TypeDefinition.CategoryDisplayName
        }
        if (($null -ne $TypeDefinition) -and $TypeDefinition.ContainsKey('DisplayName') -and (Test-String -IsPopulated ([System.String]$TypeDefinition.DisplayName))) {
            $FriendlyDisplayName = [System.String]$TypeDefinition.DisplayName
        }
        if (($null -ne $TypeDefinition) -and $TypeDefinition.ContainsKey('Description') -and (Test-String -IsPopulated ([System.String]$TypeDefinition.Description))) {
            $Description = [System.String]$TypeDefinition.Description
        }

        [System.String]$CategoryPrefix = if ($CategoryOrder -lt 9999) {
            ('{0:D2}' -f $CategoryOrder)
        }
        else {
            '--'
        }

        [System.String]$PickerDisplayName = if (Test-String -IsPopulated $CategoryDisplayName) {
            ('{0} | {1,-10} | {2}' -f $CategoryPrefix, $CategoryDisplayName, $FriendlyDisplayName)
        }
        else {
            $FriendlyDisplayName
        }

        $PickerEntries.Add([PSCustomObject]@{
            TypeName            = [System.String]$ObjectTypeName
            CategoryLabel       = $CategoryLabel
            CategoryDisplayName = $CategoryDisplayName
            CategoryOrder       = $CategoryOrder
            PickerOrder         = $PickerOrder
            FriendlyDisplayName = $FriendlyDisplayName
            PickerDisplayName   = $PickerDisplayName
            Description         = $Description
        }) | Out-Null
    }

    return @($PickerEntries.ToArray() | Sort-Object CategoryOrder, PickerOrder, FriendlyDisplayName, TypeName)
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Shows the richer categorized picker dialog for adding deployment objects.
.DESCRIPTION
    This dialog separates categories, object types, and descriptions so larger catalogs remain
    readable and intuitive while using the same ordered catalog metadata as the Add flow.
.EXAMPLE
    Select-UDFDeploymentObjectTypeFromCatalogDialog -PickerEntries $Entries
.INPUTS
    [System.Management.Automation.PSCustomObject[]]
.OUTPUTS
    [System.Management.Automation.PSCustomObject]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.4
    Author          : Imraan Iotana
    Creation Date   : August 2026
    Last Update     : August 2026
#>
####################################################################################################
function Select-UDFDeploymentObjectTypeFromCatalogDialog {
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSCustomObject])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The ordered picker entries resolved from the internal catalog.')]
        [System.Object[]]$PickerEntries
    )

    [System.String]$SelectedObjectTypeName = ''
    [System.Windows.Forms.IWin32Window]$Owner = if ($Global:MainForm -is [System.Windows.Forms.Form]) { $Global:MainForm } else { $null }
    [System.Windows.Forms.Form]$PickerForm = New-ModalDialog -Title 'Add Deployment Object' -ClientWidth 640 -ClientHeight 320 -Owner $Owner
    try {
        [System.Windows.Forms.Label]$CategoryLabel = New-Object System.Windows.Forms.Label
        $CategoryLabel.AutoSize = $true
        $CategoryLabel.Location = New-Object System.Drawing.Point(18, 14)
        $CategoryLabel.Text = 'Category'

        [System.Windows.Forms.ListBox]$CategoryListBox = New-Object System.Windows.Forms.ListBox
        $CategoryListBox.Location = New-Object System.Drawing.Point(18, 38)
        $CategoryListBox.Size = New-Object System.Drawing.Size(190, 180)

        [System.Windows.Forms.Label]$TypeLabel = New-Object System.Windows.Forms.Label
        $TypeLabel.AutoSize = $true
        $TypeLabel.Location = New-Object System.Drawing.Point(224, 14)
        $TypeLabel.Text = 'Deployment Object'

        [System.Windows.Forms.ListBox]$TypeListBox = New-Object System.Windows.Forms.ListBox
        $TypeListBox.Location = New-Object System.Drawing.Point(224, 38)
        $TypeListBox.Size = New-Object System.Drawing.Size(392, 180)

        [System.Windows.Forms.Label]$DescriptionLabel = New-Object System.Windows.Forms.Label
        $DescriptionLabel.AutoSize = $true
        $DescriptionLabel.Location = New-Object System.Drawing.Point(18, 228)
        $DescriptionLabel.Text = 'Description'

        [System.Windows.Forms.TextBox]$DescriptionTextBox = New-Object System.Windows.Forms.TextBox
        $DescriptionTextBox.Location = New-Object System.Drawing.Point(18, 250)
        $DescriptionTextBox.Size = New-Object System.Drawing.Size(598, 36)
        $DescriptionTextBox.Multiline = $true
        $DescriptionTextBox.ReadOnly = $true
        $DescriptionTextBox.ScrollBars = [System.Windows.Forms.ScrollBars]::Vertical
        $DescriptionTextBox.BackColor = [System.Drawing.Color]::White

        [System.Windows.Forms.Button]$OkButton = New-Object System.Windows.Forms.Button
        $OkButton.Text = 'Add'
        $OkButton.Location = New-Object System.Drawing.Point(460, 290)
        $OkButton.Size = New-Object System.Drawing.Size(75, 28)
        $OkButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
        $OkButton.Enabled = $false

        [System.Windows.Forms.Button]$CancelButton = New-Object System.Windows.Forms.Button
        $CancelButton.Text = 'Cancel'
        $CancelButton.Location = New-Object System.Drawing.Point(541, 290)
        $CancelButton.Size = New-Object System.Drawing.Size(75, 28)
        $CancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel

        [void]$PickerForm.Controls.Add($CategoryLabel)
        [void]$PickerForm.Controls.Add($CategoryListBox)
        [void]$PickerForm.Controls.Add($TypeLabel)
        [void]$PickerForm.Controls.Add($TypeListBox)
        [void]$PickerForm.Controls.Add($DescriptionLabel)
        [void]$PickerForm.Controls.Add($DescriptionTextBox)
        [void]$PickerForm.Controls.Add($OkButton)
        [void]$PickerForm.Controls.Add($CancelButton)
        $PickerForm.AcceptButton = $OkButton
        $PickerForm.CancelButton = $CancelButton

        [System.Collections.Hashtable]$CategoryEntriesMap = @{}
        [System.Collections.Generic.List[System.String]]$OrderedCategories = New-Object 'System.Collections.Generic.List[System.String]'
        foreach ($PickerEntry in $PickerEntries) {
            [System.String]$CategoryName = if (Test-String -IsPopulated ([System.String]$PickerEntry.CategoryDisplayName)) { [System.String]$PickerEntry.CategoryDisplayName } else { 'OTHER' }
            if (-not $CategoryEntriesMap.ContainsKey($CategoryName)) {
                $CategoryEntriesMap[$CategoryName] = New-Object System.Collections.ArrayList
                $OrderedCategories.Add($CategoryName) | Out-Null
            }

            [void]$CategoryEntriesMap[$CategoryName].Add([PSCustomObject]$PickerEntry)
        }

        [System.Collections.Hashtable]$TypeDisplayNameToEntryMap = @{}
        [System.Management.Automation.ScriptBlock]$PopulateTypeList = {
            param (
                [System.String]$CategoryName
            )

            $TypeListBox.Items.Clear()
            $DescriptionTextBox.Text = ''
            $OkButton.Enabled = $false
            $TypeDisplayNameToEntryMap.Clear()

            if ([System.String]::IsNullOrWhiteSpace($CategoryName) -or (-not $CategoryEntriesMap.ContainsKey($CategoryName))) {
                return
            }

            foreach ($PickerEntry in @($CategoryEntriesMap[$CategoryName])) {
                [System.String]$DisplayText = [System.String]$PickerEntry.FriendlyDisplayName
                if ($TypeDisplayNameToEntryMap.ContainsKey($DisplayText)) {
                    $DisplayText = "$DisplayText [$([System.String]$PickerEntry.TypeName)]"
                }

                $TypeDisplayNameToEntryMap[$DisplayText] = [PSCustomObject]$PickerEntry
                [void]$TypeListBox.Items.Add($DisplayText)
            }

            if ($TypeListBox.Items.Count -gt 0) {
                $TypeListBox.SelectedIndex = 0
            }
        }.GetNewClosure()

        $CategoryListBox.Add_SelectedIndexChanged({
            & $PopulateTypeList ([System.String]$this.SelectedItem)
        }.GetNewClosure())

        $TypeListBox.Add_SelectedIndexChanged({
            [System.String]$SelectedDisplayText = [System.String]$this.SelectedItem
            if ((Test-String -IsPopulated $SelectedDisplayText) -and $TypeDisplayNameToEntryMap.ContainsKey($SelectedDisplayText)) {
                [PSCustomObject]$SelectedEntry = [PSCustomObject]$TypeDisplayNameToEntryMap[$SelectedDisplayText]
                $DescriptionTextBox.Text = [System.String]$SelectedEntry.Description
                $OkButton.Enabled = $true
            }
            else {
                $DescriptionTextBox.Text = ''
                $OkButton.Enabled = $false
            }
        }.GetNewClosure())

        foreach ($CategoryName in $OrderedCategories.ToArray()) {
            [void]$CategoryListBox.Items.Add($CategoryName)
        }
        if ($CategoryListBox.Items.Count -gt 0) {
            $CategoryListBox.SelectedIndex = 0
        }

        [System.Windows.Forms.DialogResult]$PickerResult = Show-ModalDialog -Dialog $PickerForm -Owner $Owner

        if ($PickerResult -eq [System.Windows.Forms.DialogResult]::OK) {
            [System.String]$SelectedDisplayText = [System.String]$TypeListBox.SelectedItem
            if ((Test-String -IsPopulated $SelectedDisplayText) -and $TypeDisplayNameToEntryMap.ContainsKey($SelectedDisplayText)) {
                $SelectedObjectTypeName = [System.String]$TypeDisplayNameToEntryMap[$SelectedDisplayText].TypeName
            }
        }

        return [PSCustomObject]@{
            SelectedTypeName = $SelectedObjectTypeName
            WasCancelled     = ($PickerResult -ne [System.Windows.Forms.DialogResult]::OK)
            FailureMessage   = ''
        }
    }
    catch {
        return [PSCustomObject]@{
            SelectedTypeName = ''
            WasCancelled     = $false
            FailureMessage   = [System.String]$_.Exception.Message
        }
    }
    finally {
        if (-not $PickerForm.IsDisposed) {
            $PickerForm.Dispose()
        }
    }
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Adds a new deployment object to the list using the internal DeploymentData catalog.
.DESCRIPTION
    This helper is a test-first Add flow. It reads the loaded `_Catalog` metadata from the source
    ListView context, prompts the user to choose one available object type, creates a default
    object from schema defaults, appends it to the ListView, and selects the new row.
.EXAMPLE
    Add-UDFDeploymentObjectFromCatalog -SourceListView $DeploymentObjectsListView
.INPUTS
    [System.Windows.Forms.ListView]
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
function Add-UDFDeploymentObjectFromCatalog {
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The deployment objects ListView that receives the new row.')]
        [System.Windows.Forms.ListView]$SourceListView
    )

    try {
        # VALIDATION - SOURCE LISTVIEW
        # Ensure a target control exists before attempting add operations.
        if ($null -eq $SourceListView) {
            return $false
        }

        # PREPARATION - INTERNAL CATALOG
        # Read the currently loaded internal catalog from the ListView context.
        [System.Collections.Hashtable]$InternalCatalog = $null
        if (($null -ne $SourceListView.Tag) -and ($null -ne $SourceListView.Tag.PSObject.Properties['InternalCatalog']) -and ($SourceListView.Tag.InternalCatalog -is [System.Collections.Hashtable])) {
            $InternalCatalog = [System.Collections.Hashtable]$SourceListView.Tag.InternalCatalog
        }

        # VALIDATION - CATALOG PRESENCE
        # This test-first Add flow only works for DeploymentData files that expose _Catalog metadata.
        if (($null -eq $InternalCatalog) -or (-not $InternalCatalog.ContainsKey('ObjectTypes')) -or ($null -eq $InternalCatalog.ObjectTypes) -or ($InternalCatalog.ObjectTypes.Keys.Count -lt 1)) {
            Write-Line 'Add test is unavailable: the loaded DeploymentData.psd1 has no _Catalog.ObjectTypes metadata.' -Type Warning
            return $false
        }

        # PREPARATION - AVAILABLE TYPES
        # Build one ordered entry list for the richer Add dialog.
        [PSCustomObject[]]$PickerEntries = @(Get-UDFCatalogPickerEntries -InternalCatalog $InternalCatalog)
        if ($PickerEntries.Count -lt 1) {
            Write-Line 'Add test is unavailable: no valid _Catalog.ObjectTypes entries were found.' -Type Warning
            return $false
        }

        [PSCustomObject]$SelectionResult = Select-UDFDeploymentObjectTypeFromCatalogDialog -PickerEntries $PickerEntries
        if ((Test-String -IsEmpty ([System.String]$SelectionResult.SelectedTypeName)) -and (-not [System.Boolean]$SelectionResult.WasCancelled)) {
            if (Test-String -IsPopulated ([System.String]$SelectionResult.FailureMessage)) {
                Write-Line "Add dialog failed: $([System.String]$SelectionResult.FailureMessage)" -Type Warning
            }
            return $false
        }

        if ([System.Boolean]$SelectionResult.WasCancelled) {
            return $false
        }

        [System.String]$SelectedObjectTypeName = [System.String]$SelectionResult.SelectedTypeName

        if ([System.String]::IsNullOrWhiteSpace($SelectedObjectTypeName)) {
            return $false
        }

        # PREPARATION - DEFAULT OBJECT
        # Build the new object and stable display/save property order from catalog defaults.
        [PSCustomObject]$CatalogObjectData = New-UDFDeploymentObjectFromCatalogType -InternalCatalog $InternalCatalog -ObjectTypeName $SelectedObjectTypeName
        if (($null -eq $CatalogObjectData) -or ($null -eq $CatalogObjectData.DeploymentObject)) {
            Write-Line "Could not build a default object for type '$SelectedObjectTypeName'." -Type Warning
            return $false
        }

        [System.Collections.Hashtable]$DeploymentObject = [System.Collections.Hashtable]$CatalogObjectData.DeploymentObject
        [System.String[]]$PropertyOrder = [System.String[]]$CatalogObjectData.PropertyOrder
        [System.String]$Summary = Get-UDFDeploymentObjectSummaryText -DeploymentObject $DeploymentObject

        # EXECUTION - APPEND ROW
        # Add a new row to the ListView and select it so the properties editor refreshes.
        [System.Windows.Forms.ListViewItem]$NewItem = New-Object System.Windows.Forms.ListViewItem([System.String]($SourceListView.Items.Count + 1))
        $NewItem.Tag = [PSCustomObject]@{
            DeploymentObject = $DeploymentObject
            PropertyOrder    = $PropertyOrder
            SourceBlock      = $null
        }
        $null = $NewItem.SubItems.Add($SelectedObjectTypeName)
        $null = $NewItem.SubItems.Add($Summary)

        Invoke-UDFDeploymentObjectListViewBatchUpdate -SourceListView $SourceListView -Action {
            $null = $SourceListView.Items.Add($NewItem)
            Update-UDFDeploymentObjectListViewRowNumbers -SourceListView $SourceListView

            [void](Set-UDFDeploymentObjectListViewSelectionByIndex -SourceListView $SourceListView -Index ($SourceListView.Items.Count - 1) -ClearExisting -SetFocus -EnsureVisible)
            Set-ListViewColumnAutoSize -ListView $SourceListView -Mode Widest
        }

        # OUTPUT - USER FEEDBACK
        # Report the created row and selected type.
        Write-Line "Added '$SelectedObjectTypeName' at row '$($NewItem.Index + 1)'." -Type Success
        return $true
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
        return $false
    }
}

### END OF FUNCTION
####################################################################################################


