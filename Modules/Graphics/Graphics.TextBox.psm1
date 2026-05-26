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
    No objects are returned to the pipeline. All output is written to the host.
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
    Last Update     : May 2026
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
        [System.String]$TextColor = 'Black',

        [Parameter(Mandatory=$false,HelpMessage='The PropertyName that will be added to the object, to interact with the registry.')]
        [System.String]$PropertyName,

        [Parameter(Mandatory=$false,HelpMessage='The DefaultValue that will be added to the object.')]
        [System.String]$DefaultValue,

        [Parameter(Mandatory=$false,HelpMessage='The DefaultButtonsArray that will be added to the object.')]
        [System.Object[][]]$Buttons,

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
    $NewTextBox.ForeColor = $TextColor

    # READONLY
    # Set the ReadOnly property
    $NewTextBox.ReadOnly = switch ($Type) {
        'Input'     { $false }
        'Output'    { $true }
    }

    # EXECUTION - CUSTOM PROPERTIES '(TAG)'

    # TAG
    # Create the Tag property
    $NewTextBox.Tag = [PSCustomObject]@{}

    # LABEL
    # Create the label and add it to the Tag property
    if ($Label) {
        New-Label -InputObject $InputObject -ParentGroupBox $ParentGroupBox -Text $Label -RowNumber $RowNumber
        $NewTextBox.Tag | Add-Member -MemberType NoteProperty -Name Label -Value $Label
    }

    # PROPERTYNAME
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
    # Add the ButtonPropertiesArray
    if ($Buttons.Count -gt 0) {
        try {
            # Initialize the ButtonPropertiesArray in the Tag property
            $NewTextBox.Tag | Add-Member -MemberType NoteProperty -Name ButtonPropertiesArray -Value @()
            # Add each button to the ButtonPropertiesArray
            foreach ($Button in $Buttons) {
                # Set the button properties
                [System.Int32]$ColumnNumber = $Button[0]
                [System.String]$ButtonText  = $Button[1]
                # Create the hashtable
                [System.Collections.Hashtable]$ButtonHashtable = @{
                    ColumnNumber    = $ColumnNumber
                    Text            = $ButtonText
                    Function        = switch ($ButtonText) {
                        'Browse'    { { Invoke-TextBoxAction -TextBox $NewTextBox -Action 'Browse' }.GetNewClosure() }
                        'Open'      { { Invoke-TextBoxAction -TextBox $NewTextBox -Action 'Open' }.GetNewClosure() }
                        'Copy'      { { Invoke-TextBoxAction -TextBox $NewTextBox -Action 'Copy' }.GetNewClosure() }
                        'Paste'     { { Invoke-TextBoxAction -TextBox $NewTextBox -Action 'Paste' }.GetNewClosure() }
                        'Default'   { { Invoke-TextBoxAction -TextBox $NewTextBox -Action 'Default' }.GetNewClosure() }
                        'Clear'     { { Invoke-TextBoxAction -TextBox $NewTextBox -Action 'Clear' }.GetNewClosure() }
                    }
                }
                # Add the hashtable to the ButtonPropertiesArray
                $NewTextBox.Tag.ButtonPropertiesArray += $ButtonHashtable
            }
            # Create the buttons
            New-ButtonLine -InputObject $InputObject -ButtonPropertiesArray $NewTextBox.Tag.ButtonPropertiesArray -ParentGroupBox $ParentGroupBox -RowNumber ($RowNumber + 1)
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
    Invoke-TextBoxAction -TextBox $MyTextBox -Action 'Browse'
.INPUTS
    [System.Windows.Forms.TextBox]
    [System.String]
.OUTPUTS
    No objects are returned to the pipeline. All output is written to the host.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. All rights reserved.
    Version         : 6.0.0.0
    Author          : Imraan Iotana
    Creation Date   : May 2026
    Last Update     : May 2026
#>
####################################################################################################
function Invoke-TextBoxAction {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The TextBox on which the action will be performed.')]
        [System.Windows.Forms.TextBox]$TextBox,

        [Parameter(Mandatory=$true,HelpMessage='The action to be performed on the TextBox.')]
        [ValidateSet('Browse','Open','Copy','Paste','Default','Clear')]
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
        'Browse'    { [System.String]$FolderName = Select-Item -Folder ; if ($FolderName) { $TextBox.Text = $FolderName } }
        'Open'      { Open-Folder -Path $TextBox.Text }
        'Copy'      { Set-ClipBoard -Value  $TextBoxContent ; Write-Line "The content of the TextBox has been copied to the clipboard. ($TextBoxContent)" }
        'Paste'     { $TextBox.Text = Get-ClipBoard ; Write-Line "The content of the clipboard has been pasted into the TextBox. ($($TextBox.Text))" }
        'Default'   { $TextBox.Text = $TextBox.Tag.DefaultValue ; Write-Line "The TextBox has been reset to the default value: ($($TextBox.Text))" }
        'Clear'     { $TextBox.Clear() ; Write-Line "The TextBox has been cleared." }
    }
}

### END OF FUNCTION
####################################################################################################

