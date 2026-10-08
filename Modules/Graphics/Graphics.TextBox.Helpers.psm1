####################################################################################################
<#
.SYNOPSIS
    Removes enclosing double quotes from an explicitly marked path textbox.
.DESCRIPTION
    Updates only editable path fields, leaving ordinary text and password fields unchanged.
    Existing TextChanged handlers persist the cleaned value when the text changes.
.EXAMPLE
    Update-PathTextBox -TextBox $PathTextBox
.INPUTS
    [System.Windows.Forms.TextBox]
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant.
    Version         : 6.7.0
    Author          : Imraan Iotana
    Creation Date   : September 2026
    Last Update     : September 2026
#>
####################################################################################################
function Update-PathTextBox {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [System.Windows.Forms.TextBox]$TextBox
    )

    if ($null -eq $TextBox.Tag -or -not $TextBox.Tag.IsPath -or $TextBox.ReadOnly -or $TextBox.UseSystemPasswordChar -or $TextBox.PasswordChar -ne [char]0) { return }
    [System.String]$NormalizedPath = ConvertFrom-ExplorerFilePath -Path $TextBox.Text
    if ($TextBox.Text -cne $NormalizedPath) { $TextBox.Text = $NormalizedPath }
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Adds derived TextBox widths to GraphicalSettings.
.DESCRIPTION
    This helper calculates width variants for TextBox controls (Large, Medium, Small, Compact, Tiny)
    from the GroupBox width and TextBox margins, then stores them in GraphicalSettings.TextBox.
.EXAMPLE
    Add-TextBoxDimensions -InputObject $MyApplicationObject
.INPUTS
    [PSCustomObject]
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.6
    Author          : Imraan Iotana
    Creation Date   : May 2026
    Last Update     : August 2026
#>
####################################################################################################
function Add-TextBoxDimensions {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The ApplicationObject containing the settings.')]
        [PSCustomObject]$InputObject
    )

    try {
        # PREPARATION - GET SETTINGS
        # Get the GraphicalSettings settings
        [System.Collections.Hashtable]$Settings = $InputObject.GraphicalSettings

        # PREPARATION
        # Set size ratios mapped to 5, 4, 3, 2 and 1 button widths
        [System.Double]$MediumRatio  = 0.8
        [System.Double]$SmallRatio   = 0.6
        [System.Double]$CompactRatio = 0.4
        [System.Double]$TinyRatio    = 0.2

        # TEXTBOX WIDTH
        # Add the width of the Large textbox
        [System.Int32]$TextBoxLargeWidth = $Settings.GroupBox.Width - $Settings.TextBox.LeftMargin - $Settings.TextBox.RightMargin
        $Settings.TextBox.LargeWidth = $TextBoxLargeWidth
        # Add the width of the Medium textbox
        $Settings.TextBox.MediumWidth = (($TextBoxLargeWidth * $MediumRatio) - 3)
        # Add the width of the Small textbox
        $Settings.TextBox.SmallWidth = (($TextBoxLargeWidth * $SmallRatio) - 3)
        # Add the width of the Compact textbox
        $Settings.TextBox.CompactWidth = (($TextBoxLargeWidth * $CompactRatio) - 3)
        # Add the width of the Tiny textbox
        $Settings.TextBox.TinyWidth = (($TextBoxLargeWidth * $TinyRatio) - 3)
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
    Registers a TextBox in the flattened Graphics.TextBoxes store.
.DESCRIPTION
    This helper derives TextBox storage metadata from the control Tag,
    ensures the flattened store keys are populated, and returns the final
    PropertyName used for user settings interaction.
.EXAMPLE
    Register-GraphicsTextBox -TextBox $MyTextBox -FlatKeyName 'tools.applocker.applockercreation'
.INPUTS
    [System.Windows.Forms.TextBox]
    [System.String]
.OUTPUTS
    [System.String]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.6
    Author          : Imraan Iotana
    Creation Date   : July 2026
    Last Update     : August 2026
#>
####################################################################################################
function Register-GraphicsTextBox {
    [CmdletBinding()]
    [OutputType([System.String])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The TextBox to register in Graphics.TextBoxes.')]
        [System.Windows.Forms.TextBox]$TextBox,

        [Parameter(Mandatory=$true,HelpMessage='The flattened root key name for this control.')]
        [System.String]$FlatKeyName
    )

    # PREPARATION - CONTROL TAG
    # Ensure the TextBox has a Tag object for metadata operations.
    if ($null -eq $TextBox.Tag) {
        $TextBox.Tag = [PSCustomObject]@{}
    }

    # PREPARATION - LABEL
    # Resolve and validate the required label metadata.
    [System.String]$TextBoxLabel = $null
    if (($null -ne $TextBox.Tag.PSObject.Properties['Label']) -and (-not [System.String]::IsNullOrWhiteSpace([System.String]$TextBox.Tag.Label))) {
        $TextBoxLabel = [System.String]$TextBox.Tag.Label
    }

    if ([System.String]::IsNullOrWhiteSpace($TextBoxLabel)) {
        throw 'Unable to register the TextBox. New-TextBox requires a non-empty Label.'
    }

    # PREPARATION - LEAF KEY
    # Use explicit StorageKeyName when available, otherwise derive from Label.
    [System.String]$LeafKeyName = $null
    if (($null -ne $TextBox.Tag) -and ($null -ne $TextBox.Tag.PSObject.Properties['StorageKeyName']) -and (-not [System.String]::IsNullOrWhiteSpace([System.String]$TextBox.Tag.StorageKeyName))) {
        $LeafKeyName = [System.String]$TextBox.Tag.StorageKeyName
    }
    else {
        $LeafKeyName = ($TextBoxLabel -replace '[^A-Za-z0-9]+', '').Trim()
    }

    if ([System.String]::IsNullOrWhiteSpace($LeafKeyName)) {
        throw "Unable to derive a TextBox leaf key from Label '$TextBoxLabel'."
    }

    # EXECUTION - TAG METADATA
    # Normalize and persist metadata on the control.
    $TextBox.Tag | Add-Member -MemberType NoteProperty -Name Label -Value $TextBoxLabel -Force
    $TextBox.Tag | Add-Member -MemberType NoteProperty -Name StorageKeyName -Value $LeafKeyName -Force
    $TextBox.Tag | Add-Member -MemberType NoteProperty -Name RootKeyName -Value $FlatKeyName -Force

    if (($null -eq $TextBox.Tag.PSObject.Properties['PropertyName']) -or [System.String]::IsNullOrWhiteSpace([System.String]$TextBox.Tag.PropertyName)) {
        $TextBox.Tag | Add-Member -MemberType NoteProperty -Name PropertyName -Value "TextBoxes.$FlatKeyName.$LeafKeyName" -Force
    }

    # EXECUTION - GLOBAL REGISTRATION
    # Register the control under the flattened root and leaf keys.
    $Global:Graphics.TextBoxes[$FlatKeyName][$LeafKeyName] = $TextBox

    # POST-EXECUTION
    # Return the resolved PropertyName for caller convenience.
    return [System.String]$TextBox.Tag.PropertyName
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    This function performs the specified action on the given TextBox, such as opening a folder, copying text, pasting text, resetting to default value, etc.        
.DESCRIPTION
    This function performs the specified action on the given TextBox, such as opening a folder, copying text, pasting text, resetting to default value, etc.        
    The function takes a TextBox and an Action as input parameters, validates the input, and executes the corresponding action based on the Action parameter.
.EXAMPLE
    Invoke-TextBoxAction -TextBox $MyTextBox -Action 'Open'
.INPUTS
    [System.Windows.Forms.TextBox]
    [System.String]
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.0
    Author          : Imraan Iotana
    Creation Date   : May 2026
    Last Update     : June 2026
#>
####################################################################################################
function Invoke-TextBoxAction {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The TextBox on which the action will be performed.')]
        [System.Windows.Forms.TextBox]$TextBox,

        [Parameter(Mandatory=$true,HelpMessage='The action to be performed on the TextBox.')]
        [ValidateSet('Open','Copy')]
        [System.String]$Action
    )
    
    # PREPARATION
    # Get the text from the TextBox
    [System.String]$TextBoxContent = $TextBox.Text

    # VALIDATION
    # Test if the TextBox is empty, when the action is Copy or Open
    if ((Test-String -IsEmpty $TextBoxContent) -and ($Action -in @('Copy','Open'))) {
        Write-Line "The TextBox is empty. The $Action-action cannot be performed."
        return
    }

    # EXECUTION
    # Switch on the action
    switch ($Action) {
        # The Browse actions are still in development, but the structure is in place to easily implement them once the file and folder selection functions are ready
        'Open'          { Open-Folder -Path $TextBoxContent }
        'Copy'          { Set-ClipBoard -Value  $TextBoxContent ; Write-Line "The content of the TextBox has been copied to the clipboard. ($TextBoxContent)" }
    }
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Adds regular and small buttons to a TextBox.
.DESCRIPTION
    This helper builds button definitions for a TextBox and creates button lines.
    It mirrors the same button behavior used by New-TextBox.
.EXAMPLE
    Add-ButtonsToTextBox -InputObject $MyApplicationObject -ParentGroupBox $MyGroupBox -TextBox $MyTextBox -RowNumber 1 -SmallButtons @(@(5,'Default'))
.INPUTS
    [PSCustomObject]
    [System.Windows.Forms.GroupBox]
    [System.Windows.Forms.TextBox]
    [System.Int32]
    [System.Object[][]]
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.2.0
    Author          : Imraan Iotana
    Creation Date   : July 2026
    Last Update     : August 2026
#>
####################################################################################################
function Add-ButtonsToTextBox {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The ApplicationObject containing the settings.')]
        [PSCustomObject]$InputObject,

        [Parameter(Mandatory=$true,HelpMessage='The Parent GroupBox to which button lines will be added.')]
        [System.Windows.Forms.GroupBox]$ParentGroupBox,

        [Parameter(Mandatory=$true,HelpMessage='The TextBox that owns these buttons.')]
        [System.Windows.Forms.TextBox]$TextBox,

        [Parameter(Mandatory=$false,HelpMessage='The TextBox row number used for placement.')]
        [System.Int32]$RowNumber = 1,

        [Parameter(Mandatory=$false,HelpMessage='The regular buttons array to add below the TextBox.')]
        [System.Object[][]]$Buttons,

        [Parameter(Mandatory=$false,HelpMessage='The small buttons array to add on the TextBox row.')]
        [System.Object[][]]$SmallButtons
    )

    # Build regular and small button lines through one shared code path
    [System.Object[]]$ButtonGroups = @(
        # Standard buttons render on the row below the TextBox
        @{ Buttons = $Buttons       ; Row = ($RowNumber + 1) ; SizeType = $null   }
        # Small buttons render on the same row as the TextBox
        @{ Buttons = $SmallButtons  ; Row = $RowNumber       ; SizeType = 'Small' }
    )
    foreach ($ButtonGroup in $ButtonGroups) {
        # If there are no buttons defined for this group, skip to the next one
        if ($ButtonGroup.Buttons.Count -le 0) { continue }

        try {
            # Create a list of hashtables with button properties, to be used as input for the New-ButtonLine function
            [System.Collections.Generic.List[System.Collections.Hashtable]]$ButtonPropertiesList = New-Object 'System.Collections.Generic.List[System.Collections.Hashtable]'
            # Iterate over the button definitions in the current group
            foreach ($Button in $ButtonGroup.Buttons) {
                # Extract the column number and button text from the button definition
                [System.Int32]$ColumnNumber = $Button[0]
                [System.String]$ButtonText  = $Button[1]
                [System.String]$BrowseFileType = if ($Button.Count -gt 2) { [System.String]$Button[2] } else { 'Other' }
                # Resolve each button label to its click handler script block
                [System.Management.Automation.ScriptBlock]$ActionScript = switch ($ButtonText) {
                    'Browse File'   { { Select-File -TextBox $TextBox -Type $BrowseFileType }.GetNewClosure() }
                    'Browse Word'   { { Select-File -TextBox $TextBox -Type Word }.GetNewClosure() }
                    'Browse JSON'   { { Select-File -TextBox $TextBox -Type Json }.GetNewClosure() }
                    'Browse Folder' { { Select-Folder -TextBox $TextBox }.GetNewClosure() }
                    'Open'          { { Invoke-TextBoxAction -TextBox $TextBox -Action 'Open' }.GetNewClosure() }
                    'Copy'          { { Invoke-TextBoxAction -TextBox $TextBox -Action 'Copy' }.GetNewClosure() }
                    'Paste'         { { Write-ClipBoardToTextBox -TextBox $TextBox }.GetNewClosure() }
                    'Default'       { { Reset-TextBox -TextBox $TextBox }.GetNewClosure() }
                    'Clear'         { { Clear-TextBox -TextBox $TextBox }.GetNewClosure() }
                    'Show'          { { Switch-PasswordVisibility -TextBox $TextBox }.GetNewClosure() }
                }
                # Create a hashtable for each button with its properties, to be used as input for the New-ButtonLine function
                [System.Collections.Hashtable]$ButtonHashtable = @{
                    ColumnNumber    = $ColumnNumber
                    Text            = $ButtonText
                    Function        = $ActionScript
                }
                # Only small button groups include the SizeType entry
                if ($ButtonGroup.SizeType) { $ButtonHashtable.SizeType = $ButtonGroup.SizeType }

                [void]$ButtonPropertiesList.Add($ButtonHashtable)
            }

            # Convert the List to an Array, as the New-ButtonLine function expects an array as input
            [System.Collections.Hashtable[]]$ButtonPropertiesArray = $ButtonPropertiesList.ToArray()
            # Create the buttons for this TextBox
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
    Resets the specified TextBox to its configured default value.
.DESCRIPTION
    This function assigns the TextBox default value from the Tag metadata back to the Text property.
    It also writes a status message to the host with the value that was applied.
.EXAMPLE
    Reset-TextBox -TextBox $MyTextBox
.INPUTS
    [System.Windows.Forms.TextBox]
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
function Reset-TextBox {
    param (
        [Parameter(Mandatory=$true,HelpMessage='The TextBox to reset.')]
        [System.Windows.Forms.TextBox]$TextBox,

        [Parameter(Mandatory=$false,HelpMessage='Skip the confirmation prompt and reset the TextBox immediately.')]
        [System.Management.Automation.SwitchParameter]$Force
    )

    # VALIDATION
    # Ask for confirmation only when the TextBox currently contains a value and -Force is not specified
    if ((Test-String -IsPopulated $TextBox.Text) -and -not $Force) {
        [System.String]$Title   = 'Confirm Reset TextBox'
        [System.String]$Body    = "This will reset the current value:`n`n$($TextBox.Text)`n`nto the default value:`n`n$($TextBox.Tag.DefaultValue)`n`nDo you want to continue?"
        [System.Boolean]$UserHasConfirmed = Get-UserConfirmation -Title $Title -Body $Body
        if (-not $UserHasConfirmed) { return }
    }

    # EXECUTION
    # Reset the TextBox to its default value and write a status message
    $TextBox.Text = $TextBox.Tag.DefaultValue
    Write-Line "The TextBox ($($TextBox.Tag.Label)) has been reset to the default value: ($($TextBox.Text))"
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Clears the content of the specified TextBox.
.DESCRIPTION
    This function clears the text in the provided TextBox control.
    It also writes a status message to the host after the TextBox is cleared.
.EXAMPLE
    Clear-TextBox -TextBox $MyTextBox
.INPUTS
    [System.Windows.Forms.TextBox]
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
function Clear-TextBox {
    param (
        [Parameter(Mandatory=$true,HelpMessage='The TextBox to clear.')]
        [System.Windows.Forms.TextBox]$TextBox,

        [Parameter(Mandatory=$false,HelpMessage='Skip the confirmation prompt and clear the TextBox immediately.')]
        [System.Management.Automation.SwitchParameter]$Force
    )

    # VALIDATION
    # Ask for confirmation only when the TextBox currently contains a value and -Force is not specified
    if ((Test-String -IsPopulated $TextBox.Text) -and -not $Force) {
        [System.String]$Title   = 'Confirm Clear TextBox'
        [System.String]$Body    = "This will clear the current value:`n`n$($TextBox.Text)`n`nDo you want to continue?"
        [System.Boolean]$UserHasConfirmed = Get-UserConfirmation -Title $Title -Body $Body
        if (-not $UserHasConfirmed) { return }
    }

    # EXECUTION
    # Clear the TextBox content and write a status message
    $TextBox.Clear()
    Write-Line "The TextBox ($($TextBox.Tag.Label)) has been cleared."
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Writes the current clipboard content to the specified TextBox.
.DESCRIPTION
    This function retrieves the current clipboard content and assigns it to the provided TextBox control.
    It also writes a status message to the host showing the value that was written.
.EXAMPLE
    Write-ClipBoardToTextBox -TextBox $MyTextBox
.INPUTS
    [System.Windows.Forms.TextBox]
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
function Write-ClipBoardToTextBox {
    param (
        [Parameter(Mandatory=$true,HelpMessage='The TextBox where the clipboard content will be written.')]
        [System.Windows.Forms.TextBox]$TextBox,

        [Parameter(Mandatory=$false,HelpMessage='Skip the confirmation prompt and write to the TextBox immediately.')]
        [System.Management.Automation.SwitchParameter]$Force
    )

    # VALIDATION
    # Ensure the clipboard currently contains text that can be written to a TextBox
    if (-not [System.Windows.Forms.Clipboard]::ContainsText()) {
        Write-Line "The clipboard does not contain text that can be pasted into the TextBox."
        return
    }

    # PREPARATION
    # Get the content from the clipboard
    [System.Object]$ClipboardContent = Get-ClipBoard
    # Convert the clipboard content to a single string value for the TextBox
    [System.String]$ClipboardText = switch ($ClipboardContent) {
        { $null -eq $_ } { '' }
        { $_ -is [System.Array] } { [System.String]::Join([System.Environment]::NewLine, $_) }
        default { [System.String]$_ }
    }

    # VALIDATION
    # Ask for confirmation only when the TextBox already contains a value that would be overwritten
    if ((Test-String -IsPopulated $TextBox.Text) -and -not $Force) {
        [System.String]$Title   = 'Confirm Paste Clipboard Content'
        [System.String]$Body    = "This will overwrite the current value with the following value:`n`n$ClipboardText`n`nDo you want to continue?"
        [System.Boolean]$UserHasConfirmed = Get-UserConfirmation -Title $Title -Body $Body
        # If the user did not confirm, exit the function without making any changes to the TextBox
        if (-not $UserHasConfirmed) { return }
    }

    # EXECUTION
    # Write the clipboard content to the TextBox
    $TextBox.Text = $ClipboardText
    Write-Line "The content of the clipboard has been pasted into the TextBox ($($TextBox.Tag.Label)). ($($TextBox.Text))"
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Toggles the visibility of password characters in a TextBox.
.DESCRIPTION
    This function toggles the UseSystemPasswordChar property of a TextBox to show or hide password characters.
    It also writes a status message to the host showing the current visibility state.
.EXAMPLE
    Switch-PasswordVisibility -TextBox $MyPasswordTextBox
.INPUTS
    [System.Windows.Forms.TextBox]
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
function Switch-PasswordVisibility {
    param (
        [Parameter(Mandatory=$true,HelpMessage='The password TextBox to toggle.')]
        [System.Windows.Forms.TextBox]$TextBox
    )

    # EXECUTION
    # Toggle the UseSystemPasswordChar property
    $TextBox.UseSystemPasswordChar = -not $TextBox.UseSystemPasswordChar
    
    # Determine the current visibility state
    [System.String]$VisibilityState = if ($TextBox.UseSystemPasswordChar) { 'masked' } else { 'visible' }
    
    # Write a status message
    Write-Line "The password in TextBox ($($TextBox.Tag.Label)) is now $VisibilityState."
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Resolves a TextBox from Graphics.TextBoxes by logical name.
.DESCRIPTION
    This function resolves a TextBox object from the global Graphics.TextBoxes structure.
    It supports flattened sections, optional named child sections, and preferred root keys.

    When multiple matches exist, the best match is selected deterministically using:
    preferred root, populated PropertyName metadata, and populated Text value.

    For SoftwareLibrary, when no TextBox has been created yet, a temporary TextBox
    is created from User Settings so early startup callers can still resolve a value.
.EXAMPLE
    Get-TextBoxObject -TextBoxName 'ApplicationID'
.EXAMPLE
    Get-TextBoxObject -TextBoxName 'FormalVendorName' -PreferredRootKeys @('applicationintake.applicationintake')
.INPUTS
    [System.String]
    [System.String[]]
.OUTPUTS
    [System.Windows.Forms.TextBox] when found; otherwise $null.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.1
    Author          : Imraan Iotana
    Creation Date   : July 2026
    Last Update     : July 2026
#>
####################################################################################################
function Get-TextBoxObject {
    [CmdletBinding()]
    [OutputType([System.Windows.Forms.TextBox])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The TextBox key name to resolve from Graphics.TextBoxes.')]
        [System.String]$TextBoxName,

        [Parameter(Mandatory=$false,HelpMessage='Optional preferred root keys to search first in Graphics.TextBoxes.')]
        [System.String[]]$PreferredRootKeys = @(),

        [Parameter(Mandatory=$false,HelpMessage='Optional named child section keys to search under each root.')]
        [System.String[]]$SectionKeys = @()
    )

    [System.Collections.Generic.List[PSCustomObject]]$ResolvedMatches = [System.Collections.Generic.List[PSCustomObject]]::new()

    if ($Global:Graphics.TextBoxes -is [System.Collections.IDictionary]) {
        [System.Collections.Generic.List[System.String]]$SearchRoots = @()
        foreach ($RootKey in ($PreferredRootKeys + @($Global:Graphics.TextBoxes.Keys))) {
            [System.String]$RootKeyString = [System.String]$RootKey
            if (-not [System.String]::IsNullOrWhiteSpace($RootKeyString) -and -not $SearchRoots.Contains($RootKeyString)) {
                $SearchRoots.Add($RootKeyString)
            }
        }

        foreach ($ParentKey in $SearchRoots) {
            [System.Object]$ParentNode = $Global:Graphics.TextBoxes[$ParentKey]
            if ($ParentNode -isnot [System.Collections.IDictionary]) { continue }

            # Flattened layout: TextBox stored directly in the section hashtable
            if ($ParentNode.ContainsKey($TextBoxName) -and $ParentNode[$TextBoxName] -is [System.Windows.Forms.TextBox]) {
                [System.Windows.Forms.TextBox]$CandidateTextBox = $ParentNode[$TextBoxName]
                [System.Boolean]$HasPopulatedPropertyName = ($null -ne $CandidateTextBox.Tag) -and ($null -ne $CandidateTextBox.Tag.PSObject.Properties['PropertyName']) -and (-not [System.String]::IsNullOrWhiteSpace([System.String]$CandidateTextBox.Tag.PropertyName))
                [void]$ResolvedMatches.Add([PSCustomObject]@{
                    TextBox = $CandidateTextBox
                    IsPreferredRoot = $PreferredRootKeys -contains $ParentKey
                    HasPropertyName = $HasPopulatedPropertyName
                    HasText = -not [System.String]::IsNullOrWhiteSpace([System.String]$CandidateTextBox.Text)
                })
            }

            # Optional named section lookup: root -> section -> TextBox
            foreach ($SectionKey in $SectionKeys) {
                if ($ParentNode.ContainsKey($SectionKey) -and
                    $ParentNode[$SectionKey] -is [System.Collections.IDictionary] -and
                    $ParentNode[$SectionKey].ContainsKey($TextBoxName) -and
                    $ParentNode[$SectionKey][$TextBoxName] -is [System.Windows.Forms.TextBox]) {
                    [System.Windows.Forms.TextBox]$CandidateTextBox = $ParentNode[$SectionKey][$TextBoxName]
                    [System.Boolean]$HasPopulatedPropertyName = ($null -ne $CandidateTextBox.Tag) -and ($null -ne $CandidateTextBox.Tag.PSObject.Properties['PropertyName']) -and (-not [System.String]::IsNullOrWhiteSpace([System.String]$CandidateTextBox.Tag.PropertyName))
                    [void]$ResolvedMatches.Add([PSCustomObject]@{
                        TextBox = $CandidateTextBox
                        IsPreferredRoot = $PreferredRootKeys -contains $ParentKey
                        HasPropertyName = $HasPopulatedPropertyName
                        HasText = -not [System.String]::IsNullOrWhiteSpace([System.String]$CandidateTextBox.Text)
                    })
                }
            }
        }
    }

    if ($ResolvedMatches.Count -gt 0) {
        [PSCustomObject]$BestMatch = $ResolvedMatches |
            Sort-Object -Property @{ Expression = { if ($_.IsPreferredRoot) { 0 } else { 1 } } },
                                 @{ Expression = { if ($_.HasPropertyName) { 0 } else { 1 } } },
                                 @{ Expression = { if ($_.HasText) { 0 } else { 1 } } } |
            Select-Object -First 1

        return $BestMatch.TextBox
    }

    # SoftwareLibrary can be requested before the Settings tab is loaded
    # In that case, return a temporary textbox hydrated from User Settings
    if ($TextBoxName -ieq 'SoftwareLibrary') {
        [System.String]$UserSettingsRegistryPath = $null
        if (($null -ne $Global:ApplicationObject) -and ($null -ne $Global:ApplicationObject.ApplicationSettings)) {
            $UserSettingsRegistryPath = [System.String]$Global:ApplicationObject.ApplicationSettings.UserSettingsRegistryPath
        }

        if (-not [System.String]::IsNullOrWhiteSpace($UserSettingsRegistryPath) -and (Test-Path -Path $UserSettingsRegistryPath)) {
            [System.String[]]$PropertyCandidates = @(
                Get-ItemProperty -Path $UserSettingsRegistryPath -ErrorAction SilentlyContinue |
                Get-Member -MemberType NoteProperty |
                Select-Object -ExpandProperty Name |
                Where-Object { $_ -like "TextBoxes.*.$TextBoxName" }
            )

            [System.String]$ResolvedPropertyName = ($PropertyCandidates | Sort-Object | Select-Object -First 1)
            if (-not [System.String]::IsNullOrWhiteSpace($ResolvedPropertyName)) {
                # Resolve values through the shared user-settings reader.
                [System.String]$ResolvedText = [System.String](Get-UserSetting -InputObject $Global:ApplicationObject -PropertyName $ResolvedPropertyName)

                [System.Windows.Forms.TextBox]$VirtualTextBox = [System.Windows.Forms.TextBox]::new()
                $VirtualTextBox.Text = $ResolvedText
                $VirtualTextBox.Tag = [PSCustomObject]@{
                    PropertyName = $ResolvedPropertyName
                    Name = $TextBoxName
                    IsVirtual = $true
                }

                return $VirtualTextBox
            }
        }
    }

    return $null
}
### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Resolves a textbox value as text with a safe empty-string fallback.
.DESCRIPTION
    Looks up a textbox and returns its text value, or an empty string when the control is missing.
.EXAMPLE
    Get-ResolvedTextBoxText -TextBoxName 'FormalVendorName'
.INPUTS
    [System.String]
    [System.String[]]
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
function Get-ResolvedTextBoxText {
    [CmdletBinding()]
    [OutputType([System.String])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='Textbox name to resolve from Graphics.TextBoxes.')]
        [ValidateNotNullOrEmpty()]
        [System.String]$TextBoxName,

        [Parameter(Mandatory=$false,HelpMessage='Preferred root keys used by Get-TextBoxObject.')]
        [System.String[]]$PreferredRootKeys,

        [Parameter(Mandatory=$false,HelpMessage='Section keys used by Get-TextBoxObject.')]
        [System.String[]]$SectionKeys
    )

    try {
        [System.Collections.Hashtable]$ResolverParameters = @{ TextBoxName = $TextBoxName }
        if ($null -ne $PreferredRootKeys -and $PreferredRootKeys.Count -gt 0) { $ResolverParameters.PreferredRootKeys = $PreferredRootKeys }
        if ($null -ne $SectionKeys -and $SectionKeys.Count -gt 0) { $ResolverParameters.SectionKeys = $SectionKeys }

        [System.Windows.Forms.TextBox]$ResolvedTextBox = Get-TextBoxObject @ResolverParameters
        if ($null -ne $ResolvedTextBox) { return [System.String]$ResolvedTextBox.Text }
        return ''
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
        return ''
    }
}

### END OF FUNCTION
####################################################################################################
