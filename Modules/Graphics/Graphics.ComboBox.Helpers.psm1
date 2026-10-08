####################################################################################################
<#
.SYNOPSIS
    Registers a ComboBox in the flattened Graphics.ComboBoxes store.
.DESCRIPTION
    This helper derives ComboBox storage metadata from control Tag values,
    ensures flattened registration keys are populated, and returns the
    resolved PropertyName used for user settings interaction.
.EXAMPLE
    Register-GraphicsComboBox -ComboBox $MyComboBox -FlatKeyName 'tools.applocker.applockerimport'
.INPUTS
    [System.Windows.Forms.ComboBox]
    [System.String]
.OUTPUTS
    [System.String]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.3.1
    Author          : Imraan Iotana
    Creation Date   : July 2026
    Last Update     : July 2026
#>
####################################################################################################
function Register-GraphicsComboBox {
    [CmdletBinding()]
    [OutputType([System.String])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The ComboBox to register in Graphics.ComboBoxes.')]
        [System.Windows.Forms.ComboBox]$ComboBox,

        [Parameter(Mandatory=$true,HelpMessage='The flattened root key name for this control.')]
        [System.String]$FlatKeyName
    )

    # PREPARATION - CONTROL TAG
    # Ensure the ComboBox has a Tag object for metadata operations.
    if ($null -eq $ComboBox.Tag) {
        $ComboBox.Tag = [PSCustomObject]@{}
    }

    # PREPARATION - LABEL
    # Resolve and validate the required label metadata.
    [System.String]$ComboBoxLabel = $null
    if (($null -ne $ComboBox.Tag.PSObject.Properties['Label']) -and (Test-String -IsPopulated ([System.String]$ComboBox.Tag.Label))) {
        $ComboBoxLabel = [System.String]$ComboBox.Tag.Label
    }

    if (Test-String -IsEmpty $ComboBoxLabel) {
        throw 'Unable to register the ComboBox. New-ComboBox requires a non-empty Label.'
    }

    # PREPARATION - LEAF KEY
    # Use explicit StorageKeyName when available, otherwise derive from Label.
    [System.String]$LeafKeyName = $null

    if (($null -ne $ComboBox.Tag) -and ($null -ne $ComboBox.Tag.PSObject.Properties['StorageKeyName']) -and (Test-String -IsPopulated ([System.String]$ComboBox.Tag.StorageKeyName))) {
        $LeafKeyName = [System.String]$ComboBox.Tag.StorageKeyName
    }
    else {
        $LeafKeyName = ($ComboBoxLabel -replace '[^A-Za-z0-9]+', '').Trim()
    }

    if (Test-String -IsEmpty $LeafKeyName) {
        throw "Unable to derive a ComboBox leaf key from Label '$ComboBoxLabel'."
    }

    # EXECUTION - TAG METADATA
    # Normalize and persist metadata on the control.
    $ComboBox.Tag | Add-Member -MemberType NoteProperty -Name Label -Value $ComboBoxLabel -Force
    $ComboBox.Tag | Add-Member -MemberType NoteProperty -Name StorageKeyName -Value $LeafKeyName -Force
    $ComboBox.Tag | Add-Member -MemberType NoteProperty -Name RootKeyName -Value $FlatKeyName -Force

    if (($null -eq $ComboBox.Tag.PSObject.Properties['PropertyName']) -or (Test-String -IsEmpty ([System.String]$ComboBox.Tag.PropertyName))) {
        $ComboBox.Tag | Add-Member -MemberType NoteProperty -Name PropertyName -Value "ComboBoxes.$FlatKeyName.$LeafKeyName" -Force
    }

    # EXECUTION - GLOBAL REGISTRATION
    # Register the control under the flattened root and leaf keys.
    $Global:Graphics.ComboBoxes[$FlatKeyName][$LeafKeyName] = $ComboBox

    # POST-EXECUTION
    # Return the resolved PropertyName for caller convenience.
    return [System.String]$ComboBox.Tag.PropertyName
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Adds regular and small buttons to a ComboBox.
.DESCRIPTION
    This helper builds button definitions for a ComboBox and creates button lines.
    It mirrors the same button behavior used by New-ComboBox.
.EXAMPLE
    Add-ButtonsToComboBox -InputObject $MyApplicationObject -ParentGroupBox $MyGroupBox -ComboBox $MyComboBox -RowNumber 1 -SmallButtons @(@(5,'Default'))
.INPUTS
    [PSCustomObject]
    [System.Windows.Forms.GroupBox]
    [System.Windows.Forms.ComboBox]
    [System.Int32]
    [System.Object[][]]
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.2
    Author          : Imraan Iotana
    Creation Date   : July 2026
    Last Update     : July 2026
#>
####################################################################################################
function Add-ButtonsToComboBox {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The ApplicationObject containing the settings.')]
        [PSCustomObject]$InputObject,

        [Parameter(Mandatory=$true,HelpMessage='The Parent GroupBox to which button lines will be added.')]
        [System.Windows.Forms.GroupBox]$ParentGroupBox,

        [Parameter(Mandatory=$true,HelpMessage='The ComboBox that owns these buttons.')]
        [System.Windows.Forms.ComboBox]$ComboBox,

        [Parameter(Mandatory=$false,HelpMessage='The ComboBox row number used for placement.')]
        [System.Int32]$RowNumber = 1,

        [Parameter(Mandatory=$false,HelpMessage='The regular buttons array to add below the ComboBox.')]
        [System.Object[][]]$Buttons,

        [Parameter(Mandatory=$false,HelpMessage='The small buttons array to add on the ComboBox row.')]
        [System.Object[][]]$SmallButtons
    )

    # Build regular and small button lines through one shared code path
    [System.Object[]]$ButtonGroups = @(
        # Standard buttons render on the row below the ComboBox
        @{ Buttons = $Buttons      ; Row = ($RowNumber + 1) ; SizeType = $null   ; TagProperty = 'ButtonPropertiesArray' }
        # Small buttons render on the same row as the ComboBox
        @{ Buttons = $SmallButtons ; Row = $RowNumber       ; SizeType = 'Small' ; TagProperty = 'SmallButtonPropertiesArray' }
    )
    foreach ($ButtonGroup in $ButtonGroups) {
        # If there are no buttons defined for this group, skip to the next one
        if ($ButtonGroup.Buttons.Count -le 0) { continue }

        try {
            # Create a list of hashtables with button properties, to be used as input for the New-ButtonLine function
            [System.Collections.Generic.List[System.Collections.Hashtable]]$ButtonPropertiesList = New-Object 'System.Collections.Generic.List[System.Collections.Hashtable]'
            foreach ($Button in $ButtonGroup.Buttons) {
                # Set the button properties
                [System.Int32]$ColumnNumber = $Button[0]
                [System.String]$ButtonText  = $Button[1]
                [System.String]$BrowseFileType = if ($Button.Count -gt 2) { [System.String]$Button[2] } else { 'Other' }
                [System.Collections.Hashtable]$ButtonHashtable = @{
                    ColumnNumber    = $ColumnNumber
                    Text            = $ButtonText
                    Function        = switch ($ButtonText) {
                        'Browse File' { { Select-File -ComboBox $ComboBox -Type $BrowseFileType }.GetNewClosure() }
                        'Browse'    { { [System.String]$FolderName = Select-Item -Folder ; if ($FolderName) { $ComboBox.Text = $FolderName } }.GetNewClosure() }
                        'Open'      { { Invoke-ComboBoxAction -ComboBox $ComboBox -Action 'Open' }.GetNewClosure() }
                        'Copy'      { { Invoke-ComboBoxAction -ComboBox $ComboBox -Action 'Copy' }.GetNewClosure() }
                        'Paste'     { { Write-ClipBoardToComboBox -ComboBox $ComboBox }.GetNewClosure() }
                        'Default'   { { Reset-ComboBox -ComboBox $ComboBox }.GetNewClosure() }
                        'Clear'     { { Clear-ComboBox -ComboBox $ComboBox }.GetNewClosure() }
                    }
                }

                # Only small button groups include the SizeType entry
                if ($ButtonGroup.SizeType) { $ButtonHashtable.SizeType = $ButtonGroup.SizeType }

                [void]$ButtonPropertiesList.Add($ButtonHashtable)
            }

            # Convert the list to an array, as New-ButtonLine expects an array input
            [System.Collections.Hashtable[]]$ButtonPropertiesArray = $ButtonPropertiesList.ToArray()

            # Store the generated button definitions on the ComboBox Tag for downstream use
            if (-not ($ComboBox.Tag.PSObject.Properties.Name -contains $ButtonGroup.TagProperty)) {
                $ComboBox.Tag | Add-Member -MemberType NoteProperty -Name $ButtonGroup.TagProperty -Value @()
            }
            $ComboBox.Tag.($ButtonGroup.TagProperty) = $ButtonPropertiesArray

            # Create the buttons for this group
            New-ButtonLine -InputObject $InputObject -ButtonPropertiesArray $ButtonPropertiesArray -ParentGroupBox $ParentGroupBox -RowNumber $ButtonGroup.Row
        }
        catch {
            Write-ErrorReport -ErrorRecord $_
        }
    }
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Finds a ComboBox item that matches the provided text.
.DESCRIPTION
    This helper searches ComboBox items and resolves a match against
    string values, ComboBoxName, or TemplateName.
.EXAMPLE
    Find-ComboBoxItemByText -ComboBox $MyComboBox -Text 'MyValue'
.INPUTS
    [System.Windows.Forms.ComboBox]
    [System.String]
.OUTPUTS
    [System.Object]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.2
    Author          : Imraan Iotana
    Creation Date   : July 2026
    Last Update     : July 2026
#>
####################################################################################################
function Find-ComboBoxItemByText {
    [CmdletBinding()]
    [OutputType([System.Object])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The ComboBox whose items should be searched.')]
        [System.Windows.Forms.ComboBox]$ComboBox,

        [Parameter(Mandatory=$true,HelpMessage='The text value to match against ComboBox items.')]
        [System.String]$Text
    )

    try {
        # EXECUTION
        # Iterate through all ComboBox items and return the first supported match.
        foreach ($Item in $ComboBox.Items) {
            if ($null -eq $Item) { continue }

            if ($Item -is [string] -and $Item -eq $Text) {
                return $Item
            }

            if (($null -ne $Item.PSObject.Properties['ComboBoxName']) -and ($Item.ComboBoxName -eq $Text)) {
                return $Item
            }

            if (($null -ne $Item.PSObject.Properties['TemplateName']) -and ($Item.TemplateName -eq $Text)) {
                return $Item
            }
        }

        # POST-EXECUTION
        # Return null when no matching item could be resolved.
        return $null
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
        return $null
    }
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Applies shared layout and style properties to a ComboBox.
.DESCRIPTION
    This helper centralizes ComboBox location, size, font, colors, and
    DropDownStyle setup used by both standard and graphic constructors.
.EXAMPLE
    Set-ComboBoxCoreProperties -InputObject $MyApplicationObject -ParentGroupBox $MyGroupBox -ComboBox $MyComboBox -RowNumber 1 -SizeType 'Medium' -Type 'Input'
.INPUTS
    [PSCustomObject]
    [System.Windows.Forms.GroupBox]
    [System.Windows.Forms.ComboBox]
    [System.Int32]
    [System.String]
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.2
    Author          : Imraan Iotana
    Creation Date   : July 2026
    Last Update     : July 2026
#>
####################################################################################################
function Set-ComboBoxCoreProperties {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The ApplicationObject containing the settings.')]
        [PSCustomObject]$InputObject,

        [Parameter(Mandatory=$true,HelpMessage='The Parent GroupBox to which this ComboBox is attached.')]
        [System.Windows.Forms.GroupBox]$ParentGroupBox,

        [Parameter(Mandatory=$true,HelpMessage='The ComboBox to configure.')]
        [System.Windows.Forms.ComboBox]$ComboBox,

        [Parameter(Mandatory=$false,HelpMessage='The row number where the ComboBox will be placed.')]
        [System.Int32]$RowNumber = 1,

        [Parameter(Mandatory=$false,HelpMessage='The width size type of the ComboBox.')]
        [ValidateSet('Small','Medium','Large')]
        [System.String]$SizeType = 'Large',

        [Parameter(Mandatory=$false,HelpMessage='The type of ComboBox. Input allows typing; Output is selection-only.')]
        [ValidateSet('Input','Output')]
        [System.String]$Type = 'Output',

        [Parameter(Mandatory=$false,HelpMessage='Optional text color override.')]
        [System.String]$TextColor
    )

    try {
        # PREPARATION - SETTINGS
        # Resolve graphical settings once to keep all look-and-feel values consistent.
        [System.Collections.Hashtable]$Settings = $InputObject.GraphicalSettings

        # EXECUTION - LOCATION
        # Position the ComboBox on the configured row.
        [System.Int32]$ComboBoxTopLeftX = $ParentGroupBox.Location.X + $Settings.ComboBox.LeftMargin
        [System.Int32]$ComboBoxTopLeftY = $Settings.ComboBox.TopMargin + (($RowNumber - 1) * $Settings.ComboBox.Height)
        $ComboBox.Location = New-Object System.Drawing.Point($ComboBoxTopLeftX, $ComboBoxTopLeftY)

        # EXECUTION - SIZE
        # Apply width by size profile and fixed configured height.
        [System.Int32]$ComboBoxWidth = switch ($SizeType) {
            'Large'     { $Settings.ComboBox.LargeWidth }
            'Medium'    { $Settings.ComboBox.MediumWidth }
            'Small'     { $Settings.ComboBox.SmallWidth }
        }
        [System.Int32]$ComboBoxHeight = $Settings.ComboBox.Height
        $ComboBox.Size = New-Object System.Drawing.Size($ComboBoxWidth, $ComboBoxHeight)

        # EXECUTION - FONT AND COLORS
        # Apply standard font and type-aware background/foreground colors.
        $ComboBox.Font = $Settings.MainFont
        $ComboBox.BackColor = switch ($Type) {
            'Input'     { 'White' }
            'Output'    { 'Beige' }
        }
        $ComboBox.ForeColor = if (Test-String -IsPopulated $TextColor) {
            $TextColor
        }
        else {
            switch ($Type) {
                'Input'     { 'Black' }
                'Output'    { 'Blue' }
            }
        }

        # EXECUTION - EDIT STYLE
        # Input boxes allow typing; output boxes are list-only.
        $ComboBox.DropDownStyle = switch ($Type) {
            'Input'     { [System.Windows.Forms.ComboBoxStyle]::DropDown }
            'Output'    { [System.Windows.Forms.ComboBoxStyle]::DropDownList }
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
    Initializes ComboBox tag metadata, registration, and linked label.
.DESCRIPTION
    This helper seeds Label/PropertyName metadata, registers the ComboBox
    in the flattened Graphics store, and creates the visible label.
.EXAMPLE
    Initialize-ComboBoxTagRegistrationAndLabel -InputObject $MyApplicationObject -ParentGroupBox $MyGroupBox -ComboBox $MyComboBox -Label 'Application ID' -RowNumber 1
.INPUTS
    [PSCustomObject]
    [System.Windows.Forms.GroupBox]
    [System.Windows.Forms.ComboBox]
    [System.String]
    [System.Int32]
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.2
    Author          : Imraan Iotana
    Creation Date   : July 2026
    Last Update     : July 2026
#>
####################################################################################################
function Initialize-ComboBoxTagRegistrationAndLabel {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The ApplicationObject containing the settings.')]
        [PSCustomObject]$InputObject,

        [Parameter(Mandatory=$true,HelpMessage='The Parent GroupBox to which this ComboBox belongs.')]
        [System.Windows.Forms.GroupBox]$ParentGroupBox,

        [Parameter(Mandatory=$true,HelpMessage='The ComboBox to initialize.')]
        [System.Windows.Forms.ComboBox]$ComboBox,

        [Parameter(Mandatory=$true,HelpMessage='The label text for this ComboBox.')]
        [System.String]$Label,

        [Parameter(Mandatory=$false,HelpMessage='Optional PropertyName override for user settings binding.')]
        [System.String]$PropertyName,

        [Parameter(Mandatory=$false,HelpMessage='The row number used by the companion label.')]
        [System.Int32]$RowNumber = 1
    )

    try {
        # PREPARATION - CONTROL TAG
        # Ensure the ComboBox has a tag object before assigning metadata.
        if ($null -eq $ComboBox.Tag) {
            $ComboBox.Tag = [PSCustomObject]@{}
        }

        # EXECUTION - METADATA
        # Persist label and optional settings-property override on the control.
        $ComboBox.Tag | Add-Member -MemberType NoteProperty -Name Label -Value $Label -Force
        if (Test-String -IsPopulated $PropertyName) {
            $ComboBox.Tag | Add-Member -MemberType NoteProperty -Name PropertyName -Value $PropertyName -Force
        }

        # EXECUTION - REGISTRATION
        # Register this ComboBox in the flattened Graphics store.
        New-SubKeyForBoxes -GroupBox $ParentGroupBox -ComboBox $ComboBox | Out-Null

        # EXECUTION - LABEL
        # Create the visual label paired with this ComboBox row.
        New-Label -InputObject $InputObject -ParentGroupBox $ParentGroupBox -Text $Label -RowNumber $RowNumber
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
    Binds a ComboBox to user settings and returns the stored value.
.DESCRIPTION
    This helper wires event handlers for settings persistence and resolves
    the current stored value when PropertyName metadata is available.
.EXAMPLE
    $StoredValue = Set-ComboBoxUserSettingBinding -ComboBox $MyComboBox -Type 'Input'
.INPUTS
    [System.Windows.Forms.ComboBox]
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
function Set-ComboBoxUserSettingBinding {
    [CmdletBinding()]
    [OutputType([System.String])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The ComboBox to bind to user settings.')]
        [System.Windows.Forms.ComboBox]$ComboBox,

        [Parameter(Mandatory=$false,HelpMessage='The ComboBox type. Input allows typed values.')]
        [ValidateSet('Input','Output')]
        [System.String]$Type = 'Output'
    )

    [System.String]$StoredPropertyValue = $null

    try {
        # VALIDATION
        # Continue only when a valid PropertyName metadata value is available.
        if (($null -ne $ComboBox.Tag.PSObject.Properties['PropertyName']) -and (Test-String -IsPopulated ([System.String]$ComboBox.Tag.PropertyName))) {
            # PREPARATION
            # Read the currently stored setting value.
            $StoredPropertyValue = Get-UserSetting -PropertyName $ComboBox.Tag.PropertyName

            # EXECUTION - SELECTION BINDING
            # Persist setting value whenever selection changes.
            $ComboBox.Add_SelectedIndexChanged([System.EventHandler]{
                param($ChangedControl, $ChangedEvent)
                Set-UserSetting -PropertyName $ChangedControl.Tag.PropertyName -PropertyValue $ChangedControl.Text
            }.GetNewClosure())

            # EXECUTION - TEXT BINDING
            # For editable ComboBoxes, persist also when free text is typed.
            if ($Type -eq 'Input') {
                $ComboBox.Add_TextChanged([System.EventHandler]{
                    param($ChangedControl, $ChangedEvent)
                    Set-UserSetting -PropertyName $ChangedControl.Tag.PropertyName -PropertyValue $ChangedControl.Text
                }.GetNewClosure())
            }
        }
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }

    # POST-EXECUTION
    # Return the stored value so callers can apply it after content loading.
    return $StoredPropertyValue
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Applies a previously stored value to a ComboBox after content load.
.DESCRIPTION
    This helper attempts to select a matching ComboBox item first, and when
    no match exists falls back to direct text assignment for input ComboBoxes.
.EXAMPLE
    Set-ComboBoxValueFromStoredSetting -ComboBox $MyComboBox -StoredPropertyValue $StoredValue -Type 'Input'
.INPUTS
    [System.Windows.Forms.ComboBox]
    [System.String]
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.2
    Author          : Imraan Iotana
    Creation Date   : July 2026
    Last Update     : July 2026
#>
####################################################################################################
function Set-ComboBoxValueFromStoredSetting {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The ComboBox that should receive the stored value.')]
        [System.Windows.Forms.ComboBox]$ComboBox,

        [Parameter(Mandatory=$false,HelpMessage='The stored setting value resolved from user settings.')]
        [System.String]$StoredPropertyValue,

        [Parameter(Mandatory=$false,HelpMessage='The ComboBox type. Input allows typed values.')]
        [ValidateSet('Input','Output')]
        [System.String]$Type = 'Output'
    )

    try {
        # VALIDATION
        # No setting value means there is nothing to apply.
        if (Test-String -IsEmpty $StoredPropertyValue) { return }

        # EXECUTION
        # Prefer a real item selection for list/object-backed ComboBoxes.
        [System.Object]$MatchingItem = Find-ComboBoxItemByText -ComboBox $ComboBox -Text $StoredPropertyValue
        if ($null -ne $MatchingItem) {
            $ComboBox.SelectedItem = $MatchingItem
        }
        elseif ($Type -eq 'Input') {
            # Editable ComboBoxes can safely fall back to free-text values.
            $ComboBox.Text = $StoredPropertyValue
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
    Applies and resolves the default value for a ComboBox.
.DESCRIPTION
    This helper stores DefaultValue metadata and applies it when the current
    ComboBox text is empty, preferring item selection over plain text.
.EXAMPLE
    Set-ComboBoxDefaultValue -ComboBox $MyComboBox -DefaultValue 'Development'
.INPUTS
    [System.Windows.Forms.ComboBox]
    [System.String]
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.2
    Author          : Imraan Iotana
    Creation Date   : July 2026
    Last Update     : July 2026
#>
####################################################################################################
function Set-ComboBoxDefaultValue {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The ComboBox that should receive the default value.')]
        [System.Windows.Forms.ComboBox]$ComboBox,

        [Parameter(Mandatory=$false,HelpMessage='The default value to apply when the ComboBox is empty.')]
        [System.String]$DefaultValue
    )

    try {
        # VALIDATION
        # No configured default means there is nothing to apply.
        if (Test-String -IsEmpty $DefaultValue) { return }

        # EXECUTION - METADATA
        # Persist the default value on the ComboBox tag.
        $ComboBox.Tag | Add-Member -MemberType NoteProperty -Name DefaultValue -Value $DefaultValue -Force

        # EXECUTION - APPLY DEFAULT
        # Only apply when the ComboBox currently has no value.
        if (Test-String -IsEmpty $ComboBox.Text) {
            Write-Line ("The ComboBox labeled ($($ComboBox.Tag.Label)) is empty. It will be filled with the default value: ($DefaultValue)")

            [System.Object]$MatchingDefaultItem = Find-ComboBoxItemByText -ComboBox $ComboBox -Text $ComboBox.Tag.DefaultValue
            if ($null -ne $MatchingDefaultItem) {
                $ComboBox.SelectedItem = $MatchingDefaultItem
            }
            else {
                $ComboBox.Text = $ComboBox.Tag.DefaultValue
            }
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
    Resets the specified ComboBox to its configured default value.
.DESCRIPTION
    This function assigns the ComboBox default value from the Tag metadata back to the selection/text.
    It also writes a status message to the host with the value that was applied.
.EXAMPLE
    Reset-ComboBox -ComboBox $MyComboBox
.INPUTS
    [System.Windows.Forms.ComboBox]
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.0
    Author          : Imraan Iotana
    Creation Date   : June 2026
    Last Update     : June 2026
#>
####################################################################################################
function Reset-ComboBox {
    param (
        [Parameter(Mandatory=$true,HelpMessage='The ComboBox to reset.')]
        [System.Windows.Forms.ComboBox]$ComboBox,

        [Parameter(Mandatory=$false,HelpMessage='Skip the confirmation prompt and reset the ComboBox immediately.')]
        [System.Management.Automation.SwitchParameter]$Force
    )

    # PREPARATION
    [System.String]$DefaultValue = [System.String]$ComboBox.Tag.DefaultValue

    # VALIDATION
    # Ensure there is a default value configured before resetting
    if (Test-String -IsEmpty $DefaultValue) {
        Write-Line "The ComboBox ($($ComboBox.Tag.Label)) has no default value configured."
        return
    }

    # Ask for confirmation only when the ComboBox currently contains a value and -Force is not specified
    if ((Test-String -IsPopulated $ComboBox.Text) -and -not $Force) {
        [System.String]$Title   = 'Confirm Reset ComboBox'
        [System.String]$Body    = "This will reset the current value:`n`n$($ComboBox.Text)`n`nto the default value:`n`n$DefaultValue`n`nDo you want to continue?"
        [System.Boolean]$UserHasConfirmed = Get-UserConfirmation -Title $Title -Body $Body
        if (-not $UserHasConfirmed) { return }
    }

    # EXECUTION
    # Prefer selecting an existing item that matches the default value
    [System.Object]$MatchingDefaultItem = Find-ComboBoxItemByText -ComboBox $ComboBox -Text $DefaultValue

    if ($null -ne $MatchingDefaultItem) {
        $ComboBox.SelectedItem = $MatchingDefaultItem
    }
    else {
        if ($ComboBox.DropDownStyle -eq [System.Windows.Forms.ComboBoxStyle]::DropDownList) {
            Write-Line "The default value is not available in this ComboBox list. ($DefaultValue)"
            return
        }
        $ComboBox.Text = $DefaultValue
    }

    Write-Line "The ComboBox ($($ComboBox.Tag.Label)) has been reset to the default value: ($($ComboBox.Text))"
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Clears the content of the specified ComboBox.
.DESCRIPTION
    This function clears the selected value and text in the provided ComboBox control.
    It also writes a status message to the host after the ComboBox is cleared.
.EXAMPLE
    Clear-ComboBox -ComboBox $MyComboBox
.INPUTS
    [System.Windows.Forms.ComboBox]
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.0
    Author          : Imraan Iotana
    Creation Date   : June 2026
    Last Update     : June 2026
#>
####################################################################################################
function Clear-ComboBox {
    param (
        [Parameter(Mandatory=$true,HelpMessage='The ComboBox to clear.')]
        [System.Windows.Forms.ComboBox]$ComboBox,

        [Parameter(Mandatory=$false,HelpMessage='Skip the confirmation prompt and clear the ComboBox immediately.')]
        [System.Management.Automation.SwitchParameter]$Force
    )

    # VALIDATION
    # Ask for confirmation only when the ComboBox currently contains a value and -Force is not specified
    if ((Test-String -IsPopulated $ComboBox.Text) -and -not $Force) {
        [System.String]$Title   = 'Confirm Clear ComboBox'
        [System.String]$Body    = "This will clear the current value:`n`n$($ComboBox.Text)`n`nDo you want to continue?"
        [System.Boolean]$UserHasConfirmed = Get-UserConfirmation -Title $Title -Body $Body
        if (-not $UserHasConfirmed) { return }
    }

    # EXECUTION
    # Clear the ComboBox selection and text and write a status message
    $ComboBox.SelectedIndex = -1
    $ComboBox.Text = ''
    Write-Line "The ComboBox ($($ComboBox.Tag.Label)) has been cleared."
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Writes the current clipboard content to the specified ComboBox.
.DESCRIPTION
    This function retrieves the current clipboard content and applies it to the provided ComboBox control.
    It also writes a status message to the host showing the value that was written.
.EXAMPLE
    Write-ClipBoardToComboBox -ComboBox $MyComboBox
.INPUTS
    [System.Windows.Forms.ComboBox]
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.0
    Author          : Imraan Iotana
    Creation Date   : June 2026
    Last Update     : June 2026
#>
####################################################################################################
function Write-ClipBoardToComboBox {
    param (
        [Parameter(Mandatory=$true,HelpMessage='The ComboBox where the clipboard content will be written.')]
        [System.Windows.Forms.ComboBox]$ComboBox,

        [Parameter(Mandatory=$false,HelpMessage='Skip the confirmation prompt and write to the ComboBox immediately.')]
        [System.Management.Automation.SwitchParameter]$Force
    )

    # VALIDATION
    # Ensure the clipboard currently contains text that can be written to a ComboBox
    if (-not [System.Windows.Forms.Clipboard]::ContainsText()) {
        Write-Line "The clipboard does not contain text that can be pasted into the ComboBox."
        return
    }

    # PREPARATION
    # Get and normalize clipboard content to a single string value
    [System.Object]$ClipboardContent = Get-ClipBoard
    [System.String]$ClipboardText = switch ($ClipboardContent) {
        { $null -eq $_ } { '' }
        { $_ -is [System.Array] } { [System.String]::Join([System.Environment]::NewLine, $_) }
        default { [System.String]$_ }
    }

    # VALIDATION
    # Ask for confirmation only when the ComboBox already contains a value that would be overwritten
    if ((Test-String -IsPopulated $ComboBox.Text) -and -not $Force) {
        [System.String]$Title   = 'Confirm Paste Clipboard Content'
        [System.String]$Body    = "This will overwrite the current value with the following value:`n`n$ClipboardText`n`nDo you want to continue?"
        [System.Boolean]$UserHasConfirmed = Get-UserConfirmation -Title $Title -Body $Body
        if (-not $UserHasConfirmed) { return }
    }

    # EXECUTION
    # Prefer selecting an existing item that matches the clipboard text
    [System.Object]$MatchingItem = Find-ComboBoxItemByText -ComboBox $ComboBox -Text $ClipboardText

    if ($null -ne $MatchingItem) {
        $ComboBox.SelectedItem = $MatchingItem
    }
    else {
        if ($ComboBox.DropDownStyle -eq [System.Windows.Forms.ComboBoxStyle]::DropDownList) {
            Write-Line "The clipboard value is not available in this ComboBox list. ($ClipboardText)"
            return
        }
        $ComboBox.Text = $ClipboardText
    }

    Write-Line "The content of the clipboard has been pasted into the ComboBox ($($ComboBox.Tag.Label)). ($($ComboBox.Text))"
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Performs the specified action on the given ComboBox, such as opening a folder or copying text.
.DESCRIPTION
    This function performs simple actions against a ComboBox value.
    It validates the ComboBox content and executes the requested action.
.EXAMPLE
    Invoke-ComboBoxAction -ComboBox $MyComboBox -Action 'Open'
.INPUTS
    [System.Windows.Forms.ComboBox]
    [System.String]
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.0
    Author          : Imraan Iotana
    Creation Date   : June 2026
    Last Update     : June 2026
#>
####################################################################################################
function Invoke-ComboBoxAction {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The ComboBox on which the action will be performed.')]
        [System.Windows.Forms.ComboBox]$ComboBox,

        [Parameter(Mandatory=$true,HelpMessage='The action to be performed on the ComboBox.')]
        [ValidateSet('Open','Copy')]
        [System.String]$Action
    )

    # PREPARATION
    # Get the text from the ComboBox
    [System.String]$ComboBoxContent = $ComboBox.Text

    # VALIDATION
    # Test if the ComboBox is empty when the action is Copy or Open
    if ((Test-String -IsEmpty $ComboBoxContent) -and ($Action -in @('Copy','Open'))) {
        Write-Line "The ComboBox is empty. The $Action-action cannot be performed."
        return
    }

    # EXECUTION
    # Switch on the action
    switch ($Action) {
        'Open'  { Open-Folder -Path $ComboBoxContent }
        'Copy'  { Set-ClipBoard -Value $ComboBoxContent ; Write-Line "The content of the ComboBox has been copied to the clipboard. ($ComboBoxContent)" }
    }
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Adds graphical dimensions to the ComboBox settings based on the GroupBox dimensions and the ComboBox margins.
.DESCRIPTION
    This function adds graphical dimensions to the ComboBox settings based on the GroupBox dimensions and the ComboBox margins.
     It calculates the width of the ComboBox based on the GroupBox dimensions and the ComboBox margins, and adds these dimensions to the ComboBox settings in the GraphicalSettings hashtable of the main object.
.EXAMPLE
    Add-ComboBoxDimensions -InputObject $MyApplicationObject
.INPUTS
    [PSCustomObject]
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.0
    Author          : Imraan Iotana
    Creation Date   : May 2026
    Last Update     : May 2026
#>
####################################################################################################
function Add-ComboBoxDimensions {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The ApplicationObject containing the settings.')]
        [PSCustomObject]$InputObject
    )

    try {
        # PREPARATION - GET SETTINGS
        # Get the GraphicalSettings settings
        [System.Collections.Hashtable]$Settings = $InputObject.GraphicalSettings

        # EXECUTION
        # The ComboBox dimensions are exactly the same as the TextBox dimensions, so we can copy the TextBox dimensions to the ComboBox dimensions
        $Settings.ComboBox = $Settings.TextBox
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
    Updates the content of an existing ComboBox.
.DESCRIPTION
    This function clears and repopulates an existing ComboBox.
    You can provide either an array of strings or an array of application objects from the registry.
    By default, the current selection is cleared after refresh so users must actively confirm a choice.
    Use -PreservePreviousSelection to restore the prior selected value when available.
    Use -Silent to skip the host status message after refresh.
.EXAMPLE
    Update-ComboBox -ComboBox $MyComboBox -ContentStringArray @('Item1','Item2')
.EXAMPLE
    Update-ComboBox -ComboBox $MyComboBox -ApplicationsFromRegistry $ApplicationsFromRegistry
.EXAMPLE
    Update-ComboBox -ComboBox $MyComboBox -MailTemplates $Templates -Silent
.EXAMPLE
    Update-ComboBox -ComboBox $MyComboBox -MailTemplates $Templates -PreservePreviousSelection
.INPUTS
    [System.Windows.Forms.ComboBox]
    [System.String[]]
    [System.Object[]]
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.1
    Author          : Imraan Iotana
    Creation Date   : May 2026
    Last Update     : July 2026
#>
####################################################################################################
function Update-ComboBox {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The ComboBox to update.')]
        [System.Windows.Forms.ComboBox]$ComboBox,

        [Parameter(Mandatory=$false,HelpMessage='The array of strings that will be displayed in the ComboBox.')]
        [System.String[]]$ContentStringArray,

        [Parameter(Mandatory=$false,HelpMessage='The array of application objects that will be displayed in the ComboBox.')]
        [System.Object[]]$ApplicationsFromRegistry,

        [Parameter(Mandatory=$false,HelpMessage='The array of shortcut objects that will be displayed in the ComboBox.')]
        [System.Object[]]$Shortcuts,

        [Parameter(Mandatory=$false,HelpMessage='The array of customer template objects that will be displayed in the ComboBox.')]
        [System.Object[]]$CustomerTemplates,

        [Parameter(Mandatory=$false,HelpMessage='The array of mail template objects that will be displayed in the ComboBox.')]
        [System.Object[]]$MailTemplates,

        [Parameter(Mandatory=$false,HelpMessage='When supplied, attempts to restore the previously selected text if it still exists in the refreshed list.')]
        [System.Management.Automation.SwitchParameter]$PreservePreviousSelection,

        [Parameter(Mandatory=$false,HelpMessage='When supplied, suppresses the host status message after the ComboBox is refreshed.')]
        [System.Management.Automation.SwitchParameter]$Silent
    )

    [System.Collections.Hashtable]$ContentSourceParameters = @{
        ContentStringArray       = $ContentStringArray
        ApplicationsFromRegistry = $ApplicationsFromRegistry
        Shortcuts                = $Shortcuts
        CustomerTemplates        = $CustomerTemplates
        MailTemplates            = $MailTemplates
    }
    [System.Collections.Hashtable]$ContentSource = Get-ComboBoxContentSource @ContentSourceParameters

    try {
        [System.String]$PreviouslySelectedText = $ComboBox.Text

        Set-ComboBoxContent -ComboBox $ComboBox -ContentSource $ContentSource

        # By default the refresh requires explicit re-selection from the user
        $ComboBox.SelectedIndex = -1
        $ComboBox.Text = ''

        # Optionally preserve the previous text/selection during refresh
        if ($PreservePreviousSelection.IsPresent -and -not (Test-String -IsEmpty $PreviouslySelectedText)) {
            foreach ($Item in $ComboBox.Items) {
                if ($null -eq $Item) { continue }

                if ($Item -is [string] -and $Item -eq $PreviouslySelectedText) {
                    $ComboBox.SelectedItem = $Item
                    break
                }

                if ($null -ne $Item.PSObject.Properties['ComboBoxName'] -and $Item.ComboBoxName -eq $PreviouslySelectedText) {
                    $ComboBox.SelectedItem = $Item
                    break
                }
            }
        }

        # Write a message to the host indicating that the ComboBox has been updated
        if (-not $Silent.IsPresent) {
            Write-Line "The ComboBox ($($ComboBox.Tag.Label)) has been updated."
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
    Resolves the single active ComboBox content source and metadata.
.DESCRIPTION
    This internal helper validates that only one content source parameter is populated and returns a hashtable
    with source name, items, display member, and value member for downstream binding.
#>
####################################################################################################
function Get-ComboBoxContentSource {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false)]
        [System.String[]]$ContentStringArray,

        [Parameter(Mandatory=$false)]
        [System.Object[]]$ApplicationsFromRegistry,

        [Parameter(Mandatory=$false)]
        [System.Object[]]$Shortcuts,

        [Parameter(Mandatory=$false)]
        [System.Object[]]$CustomerTemplates,

        [Parameter(Mandatory=$false)]
        [System.Object[]]$MailTemplates
    )

    [System.Collections.Hashtable[]]$ContentSources = @(
        @{ Name = 'ContentStringArray';       Items = [System.Object[]]$ContentStringArray;       DisplayMember = '';              ValueMember = '' }
        @{ Name = 'ApplicationsFromRegistry'; Items = [System.Object[]]$ApplicationsFromRegistry; DisplayMember = 'ComboBoxName'; ValueMember = 'RegistryPath' }
        @{ Name = 'Shortcuts';                Items = [System.Object[]]$Shortcuts;                DisplayMember = 'ComboBoxName'; ValueMember = 'FullPath' }
        @{ Name = 'CustomerTemplates';        Items = [System.Object[]]$CustomerTemplates;        DisplayMember = 'ComboBoxName'; ValueMember = 'TemplatePath' }
        @{ Name = 'MailTemplates';            Items = [System.Object[]]$MailTemplates;            DisplayMember = 'ComboBoxName'; ValueMember = 'TemplateKey' }
    )

    [System.Collections.Hashtable[]]$ProvidedSources = @($ContentSources | Where-Object { $_.Items.Count -gt 0 })
    if ($ProvidedSources.Count -gt 1) {
        [System.String]$SourceList = ($ProvidedSources.Name -join ', ')
        throw "Only one content source parameter can be used at a time. Provided: $SourceList"
    }

    if ($ProvidedSources.Count -eq 0) { return $null }
    return $ProvidedSources[0]
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Applies a resolved content source to a ComboBox.
.DESCRIPTION
    This internal helper clears existing items and binds items plus display/value members from a source descriptor.
#>
####################################################################################################
function Set-ComboBoxContent {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [System.Windows.Forms.ComboBox]$ComboBox,

        [Parameter(Mandatory=$false)]
        [System.Collections.Hashtable]$ContentSource
    )

    $ComboBox.Items.Clear()

    if ($null -eq $ContentSource) {
        return
    }

    $ComboBox.DisplayMember = $ContentSource.DisplayMember
    $ComboBox.ValueMember = $ContentSource.ValueMember
    [System.Void]$ComboBox.Items.AddRange([System.Object[]]$ContentSource.Items)
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Resolves a ComboBox from Graphics.ComboBoxes by logical name.
.DESCRIPTION
    Searches flattened ComboBox sections,
    and returns null when no matching control is found.
.EXAMPLE
    Get-ComboBoxObject -ComboBoxName 'TemplateSelection'
.INPUTS
    [System.String]
.OUTPUTS
    [System.Windows.Forms.ComboBox] when found; otherwise $null.
#>
####################################################################################################
function Get-ComboBoxObject {
    [CmdletBinding()]
    [OutputType([System.Windows.Forms.ComboBox])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The ComboBox key name to resolve from Graphics.ComboBoxes.')]
        [System.String]$ComboBoxName
    )

    [System.Collections.Generic.List[PSCustomObject]]$ResolvedMatches = [System.Collections.Generic.List[PSCustomObject]]::new()

    if ($Global:Graphics.ComboBoxes -is [System.Collections.IDictionary]) {
        foreach ($ParentKey in $Global:Graphics.ComboBoxes.Keys) {
            [System.Object]$ParentNode = $Global:Graphics.ComboBoxes.$ParentKey
            if ($ParentNode -isnot [System.Collections.IDictionary]) { continue }

            # Flattened layout: ComboBox stored directly in the section hashtable
            if ($ParentNode.ContainsKey($ComboBoxName) -and $ParentNode.$ComboBoxName -is [System.Windows.Forms.ComboBox]) {
                [System.Windows.Forms.ComboBox]$CandidateComboBox = $ParentNode.$ComboBoxName
                [void]$ResolvedMatches.Add([PSCustomObject]@{
                    ComboBox = $CandidateComboBox
                    IsVisible = $CandidateComboBox.Visible
                    HasSelectedItem = $null -ne $CandidateComboBox.SelectedItem
                    HasText = -not [System.String]::IsNullOrWhiteSpace([System.String]$CandidateComboBox.Text)
                })
            }
        }
    }

    if ($ResolvedMatches.Count -gt 0) {
        [PSCustomObject]$BestMatch = $ResolvedMatches |
            Sort-Object -Property @{ Expression = { if ($_.IsVisible) { 0 } else { 1 } } },
                                 @{ Expression = { if ($_.HasSelectedItem) { 0 } else { 1 } } },
                                 @{ Expression = { if ($_.HasText) { 0 } else { 1 } } } |
            Select-Object -First 1

        return $BestMatch.ComboBox
    }

    return $null
}
### END OF FUNCTION
####################################################################################################
