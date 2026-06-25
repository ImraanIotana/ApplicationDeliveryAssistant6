####################################################################################################
<#
.SYNOPSIS
    Adds graphical dimensions to the MainTabControl settings based on the MainForm dimensions and the MainTabControl margins.
.DESCRIPTION
    This function adds graphical dimensions to the MainTabControl settings based on the MainForm dimensions and the MainTabControl margins.
     It calculates the width and height of the MainTabControl based on the MainForm dimensions and the MainTabControl margins, and adds these dimensions to the MainTabControl settings in the GraphicalSettings hashtable of the main object.
.EXAMPLE
    Add-MainTabControlDimensions -InputObject $MyApplicationObject
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
        # Set the ratios for the Medium and Small TextBox sizes based on the Large TextBox size
        [System.Double]$MediumRatio = 0.8
        [System.Double]$SmallRatio  = 0.6

        # TEXTBOX WIDTH
        # Add the width of the Large textbox
        [System.Int32]$TextBoxLargeWidth = $Settings.GroupBox.Width - $Settings.TextBox.LeftMargin - $Settings.TextBox.RightMargin
        $Settings.TextBox.LargeWidth = $TextBoxLargeWidth
        # Add the width of the Medium textbox
        $Settings.TextBox.MediumWidth = (($TextBoxLargeWidth * $MediumRatio) - 3)
        # Add the width of the Small textbox
        $Settings.TextBox.SmallWidth = (($TextBoxLargeWidth * $SmallRatio) - 3)
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
    Creates a new TextBox and adds it to the specified parent GroupBox.
.DESCRIPTION
    This function creates a new TextBox and adds it to the specified parent GroupBox.
    The TextBox properties such as location, size, font, colors, and custom properties are set based on the input parameters and the GraphicalSettings in the main object.
.EXAMPLE
    New-TextBox -ParentGroupBox $MyGroupBox -RowNumber 2 -SizeType 'Medium' -Type 'Input' -Label 'Enter Name:' -TextColor 'Blue' -PropertyName 'UserName'
.INPUTS
    [PSCustomObject]
    [System.Windows.Forms.GroupBox]
    [System.Int32]
    [System.String]
    [System.Object[][]]
.OUTPUTS
    [System.Windows.Forms.TextBox]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. All rights reserved.
    Version         : 6.0.0.0
    Author          : Imraan Iotana
    Creation Date   : May 2026
    Last Update     : June 2026
#>
####################################################################################################
function New-TextBox {
    [CmdletBinding()]
    [OutputType([System.Windows.Forms.TextBox])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The ApplicationObject containing the settings.')]
        [PSCustomObject]$InputObject,

        [Parameter(Mandatory=$true,HelpMessage='The Parent GroupBox to which this TextBox will be added.')]
        [System.Windows.Forms.GroupBox]$ParentGroupBox,

        [Parameter(Mandatory=$false,HelpMessage='The RowNumber where the TextBox will be placed.')]
        [System.Int32]$RowNumber = 1,

        [Parameter(Mandatory=$false,HelpMessage='The SizeType of the TextBox. This will influence only the width, not the height.')]
        [ValidateSet('Small','Medium','Large')]
        [System.String]$SizeType = 'Large',

        [Parameter(Mandatory=$false,HelpMessage='The Type of TextBox. This will influence the TextBox background color, and the readonly property.')]
        [ValidateSet('Input','Output')]
        [System.String]$Type = 'Input',

        [Parameter(Mandatory=$false,HelpMessage='The Label that will be placed on the left of the TextBox.')]
        [System.String]$Label,

        [Parameter(Mandatory=$false,HelpMessage='The color of the text.')]
        [System.String]$TextColor,

        [Parameter(Mandatory=$false,HelpMessage='The PropertyName that will be added to the object, to interact with the registry.')]
        [System.String]$PropertyName,

        [Parameter(Mandatory=$false,HelpMessage='The DefaultValue that will be added to the object.')]
        [System.String]$DefaultValue,

        [Parameter(Mandatory=$false,HelpMessage='The DefaultButtonsArray that will be added to the object.')]
        [System.Object[][]]$Buttons,

        [Parameter(Mandatory=$false,HelpMessage='The small buttons array that will be added to the object.')]
        [System.Object[][]]$SmallButtons,

        [Parameter(Mandatory=$false,HelpMessage='Display password characters as asterisks in the TextBox.')]
        [System.Management.Automation.SwitchParameter]$UsePasswordChar,

        [Parameter(Mandatory=$false,HelpMessage='The ToolTip text to display when hovering over the TextBox.')]
        [System.String]$ToolTip,

        [Parameter(Mandatory=$false,HelpMessage='Switch for returning the TextBox object after it is created and added to the parent.')]
        [System.Management.Automation.SwitchParameter]$ReturnTextBox
    )

    # PREPARATION
    # Input
    [System.Collections.Hashtable]$Settings     = $InputObject.GraphicalSettings
    # Create a new TextBox as the Output
    [System.Windows.Forms.TextBox]$NewTextBox   = New-Object System.Windows.Forms.TextBox
    # Create the Tag property
    $NewTextBox.Tag = [PSCustomObject]@{}

    
    # EXECUTION - SET PROPERTIES

    # LOCATION
    # Set the location
    [System.Int32]$TextBoxTopLeftX  = $ParentGroupBox.Location.X + $Settings.TextBox.LeftMargin
    [System.Int32]$TextBoxTopLeftY  = $Settings.TextBox.TopMargin + (($RowNumber - 1) * $Settings.TextBox.Height)
    $NewTextBox.Location            = New-Object System.Drawing.Point($TextBoxTopLeftX, $TextBoxTopLeftY)

    # SIZE
    # Set the size
    [System.Int32]$TextBoxWidth = switch ($SizeType) {
        'Large'     { $Settings.TextBox.LargeWidth }
        'Medium'    { $Settings.TextBox.MediumWidth }
        'Small'     { $Settings.TextBox.SmallWidth }
    }
    [System.Int32]$TextBoxHeight = $TextBoxTopLeftY + $Settings.TextBox.Height
    $NewTextBox.Size = New-Object System.Drawing.Size($TextBoxWidth, $TextBoxHeight)

    # FONT
    # Set the font
    $NewTextBox.Font = $Settings.MainFont

    # COLORS
    # Set the BackColor
    $NewTextBox.BackColor = switch ($Type) {
        'Input'     { 'White' }
        'Output'    { 'Beige' }
    }
    # Set the ForeColor
    $NewTextBox.ForeColor = if ($TextColor) {
        $TextColor
    } else {
        switch ($Type) {
            'Input'     { 'Black' }
            'Output'    { 'Blue' }
        }
    }

    # READONLY
    # Set the ReadOnly property
    $NewTextBox.ReadOnly = switch ($Type) {
        'Input'     { $false }
        'Output'    { $true }
    }

    # PASSWORD CHARACTER MASKING
    # Set the UseSystemPasswordChar property
    if ($UsePasswordChar) {
        $NewTextBox.UseSystemPasswordChar = $true
    }

    # LABEL
    # Create the label and add it to the Tag property
    if ($Label) {
        New-Label -InputObject $InputObject -ParentGroupBox $ParentGroupBox -Text $Label -RowNumber $RowNumber
        $NewTextBox.Tag | Add-Member -MemberType NoteProperty -Name Label -Value $Label
    }

    # PROPERTYNAME - INTERACTION WITH REGISTRY
    # Add the PropertyName
    if ($PropertyName) {
        $NewTextBox.Tag | Add-Member -MemberType NoteProperty -Name PropertyName -Value $PropertyName
        # Set the initial value of the TextBox based on the user setting
        $NewTextBox.Text = Get-UserSetting -PropertyName $NewTextBox.Tag.PropertyName
        # Add an event handler to update the user setting when the TextBox value changes
        $NewTextBox.Add_TextChanged([System.EventHandler]{
            param($Sender, $EventArgs)
            Set-UserSetting -PropertyName $Sender.Tag.PropertyName -PropertyValue $Sender.Text
        }.GetNewClosure())
    }

    # DEFAULTVALUE
    # Add the DefaultValue
    if ($DefaultValue) {
        # Add the DefaultValue to the Tag property
        $NewTextBox.Tag | Add-Member -MemberType NoteProperty -Name DefaultValue -Value $DefaultValue
        # If the box is empty then fill it with the DefaultValue
        if (Test-String -IsEmpty $NewTextBox.Text) {
            Write-Line ("The box labeled ($($NewTextBox.Tag.Label)) is empty. It will be filled with the default value: ($DefaultValue)")
            $NewTextBox.Text = $NewTextBox.Tag.DefaultValue
        }
    }

    # BUTTONS
    # Build regular and small button lines through one shared code path.
    [System.Object[]]$ButtonGroups = @(
        # Standard buttons render on the row below the TextBox.
        @{ Buttons = $Buttons       ; Row = ($RowNumber + 1)    ; SizeType = $null   }
        # Small buttons render on the same row as the TextBox.
        @{ Buttons = $SmallButtons  ; Row = $RowNumber          ; SizeType = 'Small' }
    )
    foreach ($ButtonGroup in $ButtonGroups) {
        # If there are no buttons defined for this group, skip to the next one.
        if ($ButtonGroup.Buttons.Count -le 0) { continue }

        try {
            # Create a list of hashtables with button properties, to be used as input for the New-ButtonLine function
            [System.Collections.Generic.List[System.Collections.Hashtable]]$ButtonPropertiesList = New-Object 'System.Collections.Generic.List[System.Collections.Hashtable]'
            # Iterate over the button definitions in the current group
            foreach ($Button in $ButtonGroup.Buttons) {
                # Extract the column number and button text from the button definition
                [System.Int32]$ColumnNumber = $Button[0]
                [System.String]$ButtonText  = $Button[1]
                # Resolve each button label to its click handler script block.
                [System.Management.Automation.ScriptBlock]$ActionScript = switch ($ButtonText) {
                    'Browse File'   { { Select-File -TextBox $NewTextBox }.GetNewClosure() }
                    'Browse Folder' { { Select-Folder -TextBox $NewTextBox }.GetNewClosure() }
                    'Open'          { { Invoke-TextBoxAction -TextBox $NewTextBox -Action 'Open' }.GetNewClosure() }
                    'Copy'          { { Invoke-TextBoxAction -TextBox $NewTextBox -Action 'Copy' }.GetNewClosure() }
                    'Paste'         { { Write-ClipBoardToTextBox -TextBox $NewTextBox }.GetNewClosure() }
                    'Default'       { { Reset-TextBox -TextBox $NewTextBox }.GetNewClosure() }
                    'Clear'         { { Clear-TextBox -TextBox $NewTextBox }.GetNewClosure() }
                    'Show'          { { Switch-PasswordVisibility -TextBox $NewTextBox }.GetNewClosure() }
                }
                # Create a hashtable for each button with its properties, to be used as input for the New-ButtonLine function.
                [System.Collections.Hashtable]$ButtonHashtable = @{
                    ColumnNumber    = $ColumnNumber
                    Text            = $ButtonText
                    Function        = $ActionScript
                }
                # Only small button groups include the SizeType entry.
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

    # TOOLTIP
    # Add the ToolTip
    if ($ToolTip) {
        [System.Windows.Forms.ToolTip]$TextBoxToolTip = New-Object System.Windows.Forms.ToolTip
        $TextBoxToolTip.SetToolTip($NewTextBox, $ToolTip)
    }

    # ADD TO PARENT
    # Add the new textbox to the parent
    $ParentGroupBox.Controls.Add($NewTextBox)

    # POST-EXECUTION
    # Return the TextBox if the switch is set
    if ($ReturnTextBox) { $NewTextBox }
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
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. All rights reserved.
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
        # The Browse actions are still in development, but the structure is in place to easily implement them once the file and folder selection functions are ready.
        'Open'          { Open-Folder -Path $TextBoxContent }
        'Copy'          { Set-ClipBoard -Value  $TextBoxContent ; Write-Line "The content of the TextBox has been copied to the clipboard. ($TextBoxContent)" }
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
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. All rights reserved.
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
    # Ask for confirmation only when the TextBox currently contains a value and -Force is not specified.
    if ((Test-String -IsPopulated $TextBox.Text) -and -not $Force) {
        [System.String]$Title   = 'Confirm Reset TextBox'
        [System.String]$Body    = "This will reset the current value:`n`n$($TextBox.Text)`n`nto the default value:`n`n$($TextBox.Tag.DefaultValue)`n`nDo you want to continue?"
        [System.Boolean]$UserHasConfirmed = Get-UserConfirmation -Title $Title -Body $Body
        if (-not $UserHasConfirmed) { return }
    }

    # EXECUTION
    # Reset the TextBox to its default value and write a status message.
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
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. All rights reserved.
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
    # Ask for confirmation only when the TextBox currently contains a value and -Force is not specified.
    if ((Test-String -IsPopulated $TextBox.Text) -and -not $Force) {
        [System.String]$Title   = 'Confirm Clear TextBox'
        [System.String]$Body    = "This will clear the current value:`n`n$($TextBox.Text)`n`nDo you want to continue?"
        [System.Boolean]$UserHasConfirmed = Get-UserConfirmation -Title $Title -Body $Body
        if (-not $UserHasConfirmed) { return }
    }

    # EXECUTION
    # Clear the TextBox content and write a status message.
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
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. All rights reserved.
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
    # Ensure the clipboard currently contains text that can be written to a TextBox.
    if (-not [System.Windows.Forms.Clipboard]::ContainsText()) {
        Write-Line "The clipboard does not contain text that can be pasted into the TextBox."
        return
    }

    # PREPARATION
    # Get the content from the clipboard
    [System.Object]$ClipboardContent = Get-ClipBoard
    # Convert the clipboard content to a single string value for the TextBox.
    [System.String]$ClipboardText = switch ($ClipboardContent) {
        { $null -eq $_ } { '' }
        { $_ -is [System.Array] } { [System.String]::Join([System.Environment]::NewLine, $_) }
        default { [System.String]$_ }
    }

    # VALIDATION
    # Ask for confirmation only when the TextBox already contains a value that would be overwritten.
    if ((Test-String -IsPopulated $TextBox.Text) -and -not $Force) {
        [System.String]$Title   = 'Confirm Paste Clipboard Content'
        [System.String]$Body    = "This will overwrite the current value with the following value:`n`n$ClipboardText`n`nDo you want to continue?"
        [System.Boolean]$UserHasConfirmed = Get-UserConfirmation -Title $Title -Body $Body
        # If the user did not confirm, exit the function without making any changes to the TextBox.
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
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. All rights reserved.
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
