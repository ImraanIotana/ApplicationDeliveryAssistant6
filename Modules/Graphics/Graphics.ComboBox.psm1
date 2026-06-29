####################################################################################################
<#
.SYNOPSIS
    Creates a new ComboBox and adds it to the specified parent GroupBox.
.DESCRIPTION
    This function creates a new ComboBox and adds it to the specified parent GroupBox.
    The ComboBox properties such as location, size, font, colors, and custom properties are set based on the input parameters and the GraphicalSettings in the main object.
.EXAMPLE
    New-ComboBox -ParentGroupBox $MyGroupBox -RowNumber 2 -SizeType 'Medium' -Type 'Input' -Label 'Select Name:' -TextColor 'Blue' -PropertyName 'UserName'
.INPUTS
    [PSCustomObject]
    [System.Windows.Forms.GroupBox]
    [System.Int32]
    [System.String]
    [System.Object[][]]
.OUTPUTS
    [System.Windows.Forms.ComboBox]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. All rights reserved.
    Version         : 6.0.0.0
    Author          : Imraan Iotana
    Creation Date   : May 2026
    Last Update     : June 2026
#>
####################################################################################################
function New-ComboBox {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The ApplicationObject containing the settings.')]
        [PSCustomObject]$InputObject,

        [Parameter(Mandatory=$true,HelpMessage='The Parent GroupBox to which this ComboBox will be added.')]
        [System.Windows.Forms.GroupBox]$ParentGroupBox,

        [Parameter(Mandatory=$false,HelpMessage='The RowNumber where the ComboBox will be placed.')]
        [System.Int32]$RowNumber = 1,

        [Parameter(Mandatory=$false,HelpMessage='The SizeType of the ComboBox. This will influence only the width, not the height.')]
        [ValidateSet('Small','Medium','Large')]
        [System.String]$SizeType = 'Large',

        [Parameter(Mandatory=$false,HelpMessage='The Type of ComboBox. This will influence the ComboBox background color, and whether users can type into it.')]
        [ValidateSet('Input','Output')]
        [System.String]$Type = 'Output',

        [Parameter(Mandatory=$false,HelpMessage='The Label that will be placed on the left of the ComboBox.')]
        [System.String]$Label,

        [Parameter(Mandatory=$false,HelpMessage='The color of the text.')]
        [System.String]$TextColor,

        [Parameter(Mandatory=$false,HelpMessage='The PropertyName that will be added to the object, to interact with the registry.')]
        [System.String]$PropertyName,

        [Parameter(Mandatory=$false,HelpMessage='The DefaultValue that will be added to the object.')]
        [Alias('Default')]
        [System.String]$DefaultValue,

        [Parameter(Mandatory=$false,HelpMessage='The DefaultButtonsArray that will be added to the object.')]
        [System.Object[][]]$Buttons,

        [Parameter(Mandatory=$false,HelpMessage='The small buttons array that will be added to the object.')]
        [System.Object[][]]$SmallButtons,

        [Parameter(Mandatory=$false,HelpMessage='The ToolTip text to display when hovering over the ComboBox.')]
        [System.String]$ToolTip,

        [Parameter(Mandatory=$false,HelpMessage='The array of strings that will be displayed in the ComboBox.')]
        [System.String[]]$ContentStringArray,

        [Parameter(Mandatory=$false,HelpMessage='The array of objects that will be displayed in the ComboBox.')]
        [System.Object[]]$ApplicationsFromRegistry,

        [Parameter(Mandatory=$false,HelpMessage='The array of objects that will be displayed in the ComboBox.')]
        [System.Object[]]$Shortcuts,

        [Parameter(Mandatory=$false,HelpMessage='The array of objects that will be displayed in the ComboBox.')]
        [System.Object[]]$CustomerTemplates,

        [Parameter(Mandatory=$false,HelpMessage='The array of objects that will be displayed in the ComboBox.')]
        [System.Object[]]$MailTemplates,

        [Parameter(Mandatory=$false,HelpMessage='Switch for returning the ComboBox object after it is created and added to the parent.')]
        [System.Management.Automation.SwitchParameter]$ReturnComboBox
    )

    [System.Collections.Hashtable]$ContentSourceParameters = @{
        ContentStringArray       = $ContentStringArray
        ApplicationsFromRegistry = $ApplicationsFromRegistry
        Shortcuts                = $Shortcuts
        CustomerTemplates        = $CustomerTemplates
        MailTemplates            = $MailTemplates
    }
    [System.Collections.Hashtable]$ContentSource = Get-ComboBoxContentSource @ContentSourceParameters

     # PREPARATION
    # Input
    [System.Collections.Hashtable]$Settings     = $InputObject.GraphicalSettings

    # Create a new ComboBox as the Output
    [System.Windows.Forms.ComboBox]$NewComboBox = New-Object System.Windows.Forms.ComboBox

    # EXECUTION - SET PROPERTIES

    # LOCATION
    # Set the location
    [System.Int32]$ComboBoxTopLeftX = $ParentGroupBox.Location.X + $Settings.ComboBox.LeftMargin
    [System.Int32]$ComboBoxTopLeftY = $Settings.ComboBox.TopMargin + (($RowNumber - 1) * $Settings.ComboBox.Height)
    $NewComboBox.Location           = New-Object System.Drawing.Point($ComboBoxTopLeftX, $ComboBoxTopLeftY)

    # SIZE
    # Set the size
    [System.Int32]$ComboBoxWidth = switch ($SizeType) {
        'Large'     { $Settings.ComboBox.LargeWidth }
        'Medium'    { $Settings.ComboBox.MediumWidth }
        'Small'     { $Settings.ComboBox.SmallWidth }
    }
    [System.Int32]$ComboBoxHeight = $ComboBoxTopLeftY + $Settings.ComboBox.Height
    $NewComboBox.Size = New-Object System.Drawing.Size($ComboBoxWidth, $ComboBoxHeight)

    # FONT
    # Set the font
    $NewComboBox.Font = $Settings.MainFont

    # COLORS
    # Set the BackColor
    $NewComboBox.BackColor = switch ($Type) {
        'Input'     { 'White' }
        'Output'    { 'Beige' }
    }
    # Set the ForeColor
    $NewComboBox.ForeColor = if ($TextColor) {
        $TextColor
    } else {
        switch ($Type) {
            'Input'     { 'Black' }
            'Output'    { 'Blue' }
        }
    }

    # EDIT STYLE
    # Input combo boxes are editable, output combo boxes are selection-only
    $NewComboBox.DropDownStyle = switch ($Type) {
        'Input'     { [System.Windows.Forms.ComboBoxStyle]::DropDown }
        'Output'    { [System.Windows.Forms.ComboBoxStyle]::DropDownList }
    }

    # CONTENT
    Set-ComboBoxContent -ComboBox $NewComboBox -ContentSource $ContentSource

    # EXECUTION - CUSTOM PROPERTIES '(TAG)'

    # TAG
    # Create the Tag property
    $NewComboBox.Tag = [PSCustomObject]@{}

    # LABEL
    # Create the label and add it to the Tag property
    if ($Label) {
        New-Label -InputObject $InputObject -ParentGroupBox $ParentGroupBox -Text $Label -RowNumber $RowNumber
        $NewComboBox.Tag | Add-Member -MemberType NoteProperty -Name Label -Value $Label
    }

    # PROPERTYNAME
    # Add the PropertyName
    if ($PropertyName) {
        $NewComboBox.Tag | Add-Member -MemberType NoteProperty -Name PropertyName -Value $PropertyName
        # Set the initial value of the ComboBox based on the user setting
        $NewComboBox.Text = Get-UserSetting -PropertyName $NewComboBox.Tag.PropertyName
        # Add an event handler to update the user setting when the ComboBox value changes
        $NewComboBox.Add_SelectedIndexChanged([System.EventHandler]{
            param($ChangedControl, $ChangedEvent)
            Set-UserSetting -PropertyName $ChangedControl.Tag.PropertyName -PropertyValue $ChangedControl.Text
        }.GetNewClosure())
        # Keep editable ComboBox text in sync with user settings even when the user types a custom value.
        if ($Type -eq 'Input') {
            $NewComboBox.Add_TextChanged([System.EventHandler]{
                param($ChangedControl, $ChangedEvent)
                Set-UserSetting -PropertyName $ChangedControl.Tag.PropertyName -PropertyValue $ChangedControl.Text
            }.GetNewClosure())
        }
    }

    # DEFAULTVALUE
    # Add the DefaultValue
    if ($DefaultValue) {
        # Add the DefaultValue to the Tag property
        $NewComboBox.Tag | Add-Member -MemberType NoteProperty -Name DefaultValue -Value $DefaultValue
        # If the box is empty then select/apply the DefaultValue.
        if (Test-String -IsEmpty $NewComboBox.Text) {
            Write-Line ("The ComboBox labeled ($($NewComboBox.Tag.Label)) is empty. It will be filled with the default value: ($DefaultValue)")

            # Prefer selecting an existing item (for object-backed combo boxes), then fall back to text assignment.
            [System.Object]$MatchingDefaultItem = $null
            foreach ($Item in $NewComboBox.Items) {
                if ($null -eq $Item) { continue }

                if ($Item -is [string] -and $Item -eq $NewComboBox.Tag.DefaultValue) {
                    $MatchingDefaultItem = $Item
                    break
                }

                if ($null -ne $Item.PSObject.Properties['ComboBoxName'] -and $Item.ComboBoxName -eq $NewComboBox.Tag.DefaultValue) {
                    $MatchingDefaultItem = $Item
                    break
                }

                if ($null -ne $Item.PSObject.Properties['TemplateName'] -and $Item.TemplateName -eq $NewComboBox.Tag.DefaultValue) {
                    $MatchingDefaultItem = $Item
                    break
                }
            }

            if ($null -ne $MatchingDefaultItem) {
                $NewComboBox.SelectedItem = $MatchingDefaultItem
            }
            else {
                $NewComboBox.Text = $NewComboBox.Tag.DefaultValue
            }
        }
    }

    # BUTTONS
    # Build regular and small button lines through one shared code path.
    [System.Object[]]$ButtonGroups = @(
        # Standard buttons render on the row below the ComboBox.
        @{ Buttons = $Buttons      ; Row = ($RowNumber + 1) ; SizeType = $null   ; TagProperty = 'ButtonPropertiesArray' }
        # Small buttons render on the same row as the ComboBox.
        @{ Buttons = $SmallButtons ; Row = $RowNumber       ; SizeType = 'Small' ; TagProperty = 'SmallButtonPropertiesArray' }
    )
    foreach ($ButtonGroup in $ButtonGroups) {
        # If there are no buttons defined for this group, skip to the next one.
        if ($ButtonGroup.Buttons.Count -le 0) { continue }

        try {
            # Create a list of hashtables with button properties, to be used as input for the New-ButtonLine function.
            [System.Collections.Generic.List[System.Collections.Hashtable]]$ButtonPropertiesList = New-Object 'System.Collections.Generic.List[System.Collections.Hashtable]'
            foreach ($Button in $ButtonGroup.Buttons) {
                # Set the button properties.
                [System.Int32]$ColumnNumber = $Button[0]
                [System.String]$ButtonText  = $Button[1]
                [System.Collections.Hashtable]$ButtonHashtable = @{
                    ColumnNumber    = $ColumnNumber
                    Text            = $ButtonText
                    Function        = switch ($ButtonText) {
                        'Browse'    { { [System.String]$FolderName = Select-Item -Folder ; if ($FolderName) { $NewComboBox.Text = $FolderName } }.GetNewClosure() }
                        'Open'      { { Invoke-ComboBoxAction -ComboBox $NewComboBox -Action 'Open' }.GetNewClosure() }
                        'Copy'      { { Invoke-ComboBoxAction -ComboBox $NewComboBox -Action 'Copy' }.GetNewClosure() }
                        'Paste'     { { Write-ClipBoardToComboBox -ComboBox $NewComboBox }.GetNewClosure() }
                        'Default'   { { Reset-ComboBox -ComboBox $NewComboBox }.GetNewClosure() }
                        'Clear'     { { Clear-ComboBox -ComboBox $NewComboBox }.GetNewClosure() }
                    }
                }

                # Only small button groups include the SizeType entry.
                if ($ButtonGroup.SizeType) { $ButtonHashtable.SizeType = $ButtonGroup.SizeType }

                [void]$ButtonPropertiesList.Add($ButtonHashtable)
            }

            # Convert the list to an array, as New-ButtonLine expects an array input.
            [System.Collections.Hashtable[]]$ButtonPropertiesArray = $ButtonPropertiesList.ToArray()

            # Store the generated button definitions on the ComboBox Tag for downstream use.
            if (-not ($NewComboBox.Tag.PSObject.Properties.Name -contains $ButtonGroup.TagProperty)) {
                $NewComboBox.Tag | Add-Member -MemberType NoteProperty -Name $ButtonGroup.TagProperty -Value @()
            }
            $NewComboBox.Tag.($ButtonGroup.TagProperty) = $ButtonPropertiesArray

            # Create the buttons for this group.
            New-ButtonLine -InputObject $InputObject -ButtonPropertiesArray $ButtonPropertiesArray -ParentGroupBox $ParentGroupBox -RowNumber $ButtonGroup.Row
        }
        catch {
            Write-ErrorReport -ErrorRecord $_
        }
    }

    # TOOLTIP
    # Add the ToolTip
    if ($ToolTip) {
        [System.Windows.Forms.ToolTip]$ComboBoxToolTip = New-Object System.Windows.Forms.ToolTip
        $ComboBoxToolTip.SetToolTip($NewComboBox, $ToolTip)
    }

    # ADD TO PARENT
    # Add the new combobox to the parent
    $ParentGroupBox.Controls.Add($NewComboBox)

    # POST-EXECUTION
    # If the ReturnComboBox switch is set, return the ComboBox object
    if ($ReturnComboBox.IsPresent) { $NewComboBox }
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
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. All rights reserved.
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
    # Ensure there is a default value configured before resetting.
    if (Test-String -IsEmpty $DefaultValue) {
        Write-Line "The ComboBox ($($ComboBox.Tag.Label)) has no default value configured."
        return
    }

    # Ask for confirmation only when the ComboBox currently contains a value and -Force is not specified.
    if ((Test-String -IsPopulated $ComboBox.Text) -and -not $Force) {
        [System.String]$Title   = 'Confirm Reset ComboBox'
        [System.String]$Body    = "This will reset the current value:`n`n$($ComboBox.Text)`n`nto the default value:`n`n$DefaultValue`n`nDo you want to continue?"
        [System.Boolean]$UserHasConfirmed = Get-UserConfirmation -Title $Title -Body $Body
        if (-not $UserHasConfirmed) { return }
    }

    # EXECUTION
    # Prefer selecting an existing item that matches the default value.
    [System.Object]$MatchingDefaultItem = $null
    foreach ($Item in $ComboBox.Items) {
        if ($null -eq $Item) { continue }

        if ($Item -is [string] -and $Item -eq $DefaultValue) {
            $MatchingDefaultItem = $Item
            break
        }

        if ($null -ne $Item.PSObject.Properties['ComboBoxName'] -and $Item.ComboBoxName -eq $DefaultValue) {
            $MatchingDefaultItem = $Item
            break
        }

        if ($null -ne $Item.PSObject.Properties['TemplateName'] -and $Item.TemplateName -eq $DefaultValue) {
            $MatchingDefaultItem = $Item
            break
        }
    }

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
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. All rights reserved.
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
    # Ask for confirmation only when the ComboBox currently contains a value and -Force is not specified.
    if ((Test-String -IsPopulated $ComboBox.Text) -and -not $Force) {
        [System.String]$Title   = 'Confirm Clear ComboBox'
        [System.String]$Body    = "This will clear the current value:`n`n$($ComboBox.Text)`n`nDo you want to continue?"
        [System.Boolean]$UserHasConfirmed = Get-UserConfirmation -Title $Title -Body $Body
        if (-not $UserHasConfirmed) { return }
    }

    # EXECUTION
    # Clear the ComboBox selection and text and write a status message.
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
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. All rights reserved.
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
    # Ensure the clipboard currently contains text that can be written to a ComboBox.
    if (-not [System.Windows.Forms.Clipboard]::ContainsText()) {
        Write-Line "The clipboard does not contain text that can be pasted into the ComboBox."
        return
    }

    # PREPARATION
    # Get and normalize clipboard content to a single string value.
    [System.Object]$ClipboardContent = Get-ClipBoard
    [System.String]$ClipboardText = switch ($ClipboardContent) {
        { $null -eq $_ } { '' }
        { $_ -is [System.Array] } { [System.String]::Join([System.Environment]::NewLine, $_) }
        default { [System.String]$_ }
    }

    # VALIDATION
    # Ask for confirmation only when the ComboBox already contains a value that would be overwritten.
    if ((Test-String -IsPopulated $ComboBox.Text) -and -not $Force) {
        [System.String]$Title   = 'Confirm Paste Clipboard Content'
        [System.String]$Body    = "This will overwrite the current value with the following value:`n`n$ClipboardText`n`nDo you want to continue?"
        [System.Boolean]$UserHasConfirmed = Get-UserConfirmation -Title $Title -Body $Body
        if (-not $UserHasConfirmed) { return }
    }

    # EXECUTION
    # Prefer selecting an existing item that matches the clipboard text.
    [System.Object]$MatchingItem = $null
    foreach ($Item in $ComboBox.Items) {
        if ($null -eq $Item) { continue }

        if ($Item -is [string] -and $Item -eq $ClipboardText) {
            $MatchingItem = $Item
            break
        }

        if ($null -ne $Item.PSObject.Properties['ComboBoxName'] -and $Item.ComboBoxName -eq $ClipboardText) {
            $MatchingItem = $Item
            break
        }

        if ($null -ne $Item.PSObject.Properties['TemplateName'] -and $Item.TemplateName -eq $ClipboardText) {
            $MatchingItem = $Item
            break
        }
    }

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
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. All rights reserved.
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
    # Get the text from the ComboBox.
    [System.String]$ComboBoxContent = $ComboBox.Text

    # VALIDATION
    # Test if the ComboBox is empty when the action is Copy or Open.
    if ((Test-String -IsEmpty $ComboBoxContent) -and ($Action -in @('Copy','Open'))) {
        Write-Line "The ComboBox is empty. The $Action-action cannot be performed."
        return
    }

    # EXECUTION
    # Switch on the action.
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
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. All rights reserved.
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
.EXAMPLE
    Update-ComboBox -ComboBox $MyComboBox -ContentStringArray @('Item1','Item2')
.EXAMPLE
    Update-ComboBox -ComboBox $MyComboBox -ApplicationsFromRegistry $ApplicationsFromRegistry
.INPUTS
    [System.Windows.Forms.ComboBox]
    [System.String[]]
    [System.Object[]]
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. All rights reserved.
    Version         : 6.0.0.0
    Author          : Imraan Iotana
    Creation Date   : May 2026
    Last Update     : May 2026
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
        [System.Object[]]$MailTemplates
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

        # Try to preserve the previous text/selection during refresh.
        if (-not (Test-String -IsEmpty $PreviouslySelectedText)) {
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
        Write-Line "The ComboBox ($($ComboBox.Tag.Label)) has been updated."
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


