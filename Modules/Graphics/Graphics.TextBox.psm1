####################################################################################################
<#
.SYNOPSIS
    Creates a new TextBox and adds it to the specified parent GroupBox.
.DESCRIPTION
    This function creates a new TextBox and adds it to the specified parent GroupBox.
    The TextBox properties such as location, size, font, colors, and custom properties are set based on the input parameters and the GraphicalSettings in the main object.
    The Label is required.
    IsPath removes enclosing double quotes on leaving the field or pressing Enter, without changing text while typing or pasting.
.EXAMPLE
    New-TextBox -ParentGroupBox $MyGroupBox -RowNumber 2 -SizeType 'Medium' -Type 'Input' -Label 'Enter Name:' -TextColor 'Blue' -PropertyName 'UserName'
.EXAMPLE
    New-TextBox -ParentGroupBox $MyGroupBox -RowNumber 1 -Label 'Repository Folder'
.INPUTS
    [PSCustomObject]
    [System.Windows.Forms.GroupBox]
    [System.Int32]
    [System.String]
    [System.Object[][]]
.OUTPUTS
    [System.Windows.Forms.TextBox]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.7.0
    Author          : Imraan Iotana
    Creation Date   : May 2026
    Last Update     : September 2026
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
        [ValidateSet('Tiny','Compact','Small','Medium','Large')]
        [System.String]$SizeType = 'Large',

        [Parameter(Mandatory=$false,HelpMessage='The Type of TextBox. This will influence the TextBox background color, and the readonly property.')]
        [ValidateSet('Input','Output')]
        [System.String]$Type = 'Input',

        [Parameter(Mandatory=$false,HelpMessage='The Label that will be placed on the left of the TextBox.')]
        [System.String]$Label,

        [Parameter(Mandatory=$false,HelpMessage='The color of the text.')]
        [System.String]$TextColor,

        [Parameter(Mandatory=$false,HelpMessage='Optional explicit PropertyName override for registry interaction.')]
        [System.String]$PropertyName,

        [Parameter(Mandatory=$false,HelpMessage='The DefaultValue that will be added to the object.')]
        [System.String]$DefaultValue,

        [Parameter(Mandatory=$false,HelpMessage='The DefaultButtonsArray that will be added to the object.')]
        [System.Object[][]]$Buttons,

        [Parameter(Mandatory=$false,HelpMessage='The small buttons array that will be added to the object.')]
        [System.Object[][]]$SmallButtons,

        [Parameter(Mandatory=$false,HelpMessage='Display password characters as asterisks in the TextBox.')]
        [System.Management.Automation.SwitchParameter]$UsePasswordChar,

        [Parameter(Mandatory=$false,HelpMessage='Treat the value as a file or folder path and remove enclosing double quotes when editing finishes.')]
        [switch]$IsPath,

        [Parameter(Mandatory=$false,HelpMessage='The ToolTip text to display when hovering over the TextBox.')]
        [System.String]$ToolTip,

        [Parameter(Mandatory=$false,HelpMessage='Optional action to run when the Enter key is pressed in the TextBox.')]
        [System.Management.Automation.ScriptBlock]$EnterAction,

        [Parameter(Mandatory=$false,HelpMessage='Switch for returning the TextBox object after it is created and added to the parent.')]
        [System.Management.Automation.SwitchParameter]$ReturnTextBox
    )

    try {
        # VALIDATION - LABEL VALIDATION
        # Every TextBox must have a non-empty label so registration failures point to the offending call site
        if (Test-String -IsEmpty $Label) {
            throw 'New-TextBox requires a non-empty -Label.'
        }

        # PREPARATION
        # Input
        [System.Collections.Hashtable]$Settings     = $InputObject.GraphicalSettings
        # Create a new TextBox as the Output
        [System.Windows.Forms.TextBox]$NewTextBox   = New-Object System.Windows.Forms.TextBox
        # Create the Tag property
        $NewTextBox.Tag = [PSCustomObject]@{}

        # PREPARATION - TEXTBOX METADATA
        # Seed metadata so New-SubKeyForBoxes can derive storage information and register the TextBox
        $NewTextBox.Tag | Add-Member -MemberType NoteProperty -Name Label -Value $Label -Force
        $NewTextBox.Tag | Add-Member -MemberType NoteProperty -Name IsPath -Value ([bool]$IsPath) -Force
        if (Test-String -IsPopulated $PropertyName) {
            $NewTextBox.Tag | Add-Member -MemberType NoteProperty -Name PropertyName -Value $PropertyName -Force
        }

        # EXECUTION - REGISTRATION
        # Create a new subkey for the TextBox in the flattened Graphics.TextBoxes store, and register it with the parent GroupBox
        New-SubKeyForBoxes -GroupBox $ParentGroupBox -TextBox $NewTextBox | Out-Null

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
            'Compact'   { $Settings.TextBox.CompactWidth }
            'Tiny'      { $Settings.TextBox.TinyWidth }
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
        $NewTextBox.ForeColor = if (Test-String -IsPopulated $TextColor) {
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
        # Create the label that corresponds to this TextBox
        New-Label -InputObject $InputObject -ParentGroupBox $ParentGroupBox -Text $Label -RowNumber $RowNumber

        # PROPERTYNAME - INTERACTION WITH REGISTRY
        # Bind the TextBox to its resolved user-settings property
        if (($null -ne $NewTextBox.Tag.PSObject.Properties['PropertyName']) -and (Test-String -IsPopulated ([System.String]$NewTextBox.Tag.PropertyName))) {
            # Set the initial value of the TextBox based on the user setting
            $NewTextBox.Text = Get-UserSetting -PropertyName $NewTextBox.Tag.PropertyName
            # Add an event handler to update the user setting when the TextBox value changes
            $NewTextBox.Add_TextChanged([System.EventHandler]{
                Set-UserSetting -PropertyName $this.Tag.PropertyName -PropertyValue $this.Text
            }.GetNewClosure())
        }

        # DEFAULTVALUE
        # Add the DefaultValue
        if (Test-String -IsPopulated $DefaultValue) {
            # Add the DefaultValue to the Tag property
            $NewTextBox.Tag | Add-Member -MemberType NoteProperty -Name DefaultValue -Value $DefaultValue
            # If the box is empty then fill it with the DefaultValue
            if (Test-String -IsEmpty $NewTextBox.Text) {
                Write-Line ("The box labeled ($($NewTextBox.Tag.Label)) is empty. It will be filled with the default value: ($DefaultValue)")
                $NewTextBox.Text = $NewTextBox.Tag.DefaultValue
            }
        }

        # BUTTONS
        # Add regular and small button lines to the TextBox
        Add-ButtonsToTextBox -InputObject $InputObject -ParentGroupBox $ParentGroupBox -TextBox $NewTextBox -RowNumber $RowNumber -Buttons $Buttons -SmallButtons $SmallButtons

        # TOOLTIP
        # Add the ToolTip
        if (Test-String -IsPopulated $ToolTip) {
            [System.Windows.Forms.ToolTip]$TextBoxToolTip = New-Object System.Windows.Forms.ToolTip
            $TextBoxToolTip.SetToolTip($NewTextBox, $ToolTip)
        }

        if ($IsPath) {
            $NewTextBox.Add_Leave([System.EventHandler]{ Update-PathTextBox -TextBox $this })
            $NewTextBox.Add_KeyDown([System.Windows.Forms.KeyEventHandler]{
                if ($_.KeyCode -eq [System.Windows.Forms.Keys]::Enter) {
                    Update-PathTextBox -TextBox $this
                }
            })
        }

        # ENTER KEY ACTION
        # Allow feature callers to reuse the same textbox for Enter-to-submit behavior.
        if ($null -ne $EnterAction) {
            $NewTextBox.Add_KeyDown({
                if ($_.KeyCode -eq [System.Windows.Forms.Keys]::Enter) {
                    $_.Handled = $true
                    $_.SuppressKeyPress = $true
                    & $EnterAction $this
                }
            }.GetNewClosure())
        }

        # ADD TO PARENT
        # Add the new textbox to the parent
        $ParentGroupBox.Controls.Add($NewTextBox)

        # POST-EXECUTION
        # Return the TextBox if the switch is set
        if ($ReturnTextBox) { $NewTextBox }
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}

### END OF FUNCTION
####################################################################################################
