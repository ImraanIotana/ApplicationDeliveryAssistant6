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
    No objects are returned to the pipeline. All output is written to the host.
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
    No objects are returned to the pipeline. All output is written to the host.
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
        [System.Object[]]$ApplicationsFromRegistry
    )

    # VALIDATION
    # If both ContentStringArray and ApplicationsFromRegistry are provided, throw an error
    if ($ContentStringArray.Count -gt 0 -and $ApplicationsFromRegistry.Count -gt 0) {
        throw "Both ContentStringArray and ApplicationsFromRegistry parameters cannot be used at the same time. Please provide only one of them."
    }
    # If ApplicationsFromRegistry is provided but is not an array of objects, throw an error
    if ($ApplicationsFromRegistry.Count -gt 0 -and -not ($ApplicationsFromRegistry -is [System.Object[]])) {
        throw "The ApplicationsFromRegistry parameter must be an array of objects. Please provide an array of application objects retrieved from the registry."
    }

    # If ContentStringArray is provided but is not an array of strings, throw an error
    if ($ContentStringArray.Count -gt 0 -and -not ($ContentStringArray -is [System.String[]])) {
        throw "The ContentStringArray parameter must be an array of strings. Please provide an array of strings to display in the ComboBox."
    }

    try {
        # Clear existing items first
        $ComboBox.Items.Clear()

        # Fill the ComboBox items from the ContentStringArray parameter
        if ($ContentStringArray.Count -gt 0) {
            $ComboBox.DisplayMember = ''
            $ComboBox.ValueMember = ''
            [System.Void]$ComboBox.Items.AddRange($ContentStringArray)
        }

        # Fill the ComboBox items from the ApplicationsFromRegistry parameter
        if ($ApplicationsFromRegistry.Count -gt 0) {
            # Set the DisplayMember to the property of the application objects that contains the name to display in the ComboBox
            $ComboBox.DisplayMember = 'ComboBoxName'
            # Set the ValueMember to the property of the application objects that contains the value to use when an item is selected in the ComboBox (in this case, the RegistryPath)
            $ComboBox.ValueMember = 'RegistryPath'
            [System.Void]$ComboBox.Items.AddRange([System.Object[]]$ApplicationsFromRegistry)
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
    Last Update     : May 2026
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
        [System.String]$TextColor = 'Black',

        [Parameter(Mandatory=$false,HelpMessage='The PropertyName that will be added to the object, to interact with the registry.')]
        [System.String]$PropertyName,

        [Parameter(Mandatory=$false,HelpMessage='The DefaultValue that will be added to the object.')]
        [System.String]$DefaultValue,

        [Parameter(Mandatory=$false,HelpMessage='The DefaultButtonsArray that will be added to the object.')]
        [System.Object[][]]$Buttons,

        [Parameter(Mandatory=$false,HelpMessage='The ToolTip text to display when hovering over the ComboBox.')]
        [System.String]$ToolTip,

        [Parameter(Mandatory=$false,HelpMessage='The array of strings that will be displayed in the ComboBox.')]
        [System.String[]]$ContentStringArray,

        [Parameter(Mandatory=$false,HelpMessage='The array of strings that will be displayed in the ComboBox.')]
        [System.Object[]]$ApplicationsFromRegistry,

        [Parameter(Mandatory=$false,HelpMessage='Switch for returning the ComboBox object after it is created and added to the parent.')]
        [System.Management.Automation.SwitchParameter]$ReturnComboBox
    )

    # VALIDATION
    # If both ContentStringArray and ApplicationsFromRegistry are provided, throw an error
    if ($ContentStringArray.Count -gt 0 -and $ApplicationsFromRegistry.Count -gt 0) {
        throw "Both ContentStringArray and ApplicationsFromRegistry parameters cannot be used at the same time. Please provide only one of them."
    }
    # If ApplicationsFromRegistry is provided but is not an array of objects, throw an error
    if ($ApplicationsFromRegistry.Count -gt 0 -and -not ($ApplicationsFromRegistry -is [System.Object[]])) {
    throw "The ApplicationsFromRegistry parameter must be an array of objects. Please provide an array of application objects retrieved from the registry."
}

    # If ContentStringArray is provided but is not an array of strings, throw an error
    if ($ContentStringArray.Count -gt 0 -and -not ($ContentStringArray -is [System.String[]])) {
    throw "The ContentStringArray parameter must be an array of strings. Please provide an array of strings to display in the ComboBox."
    }

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
    $NewComboBox.ForeColor = $TextColor

    # EDIT STYLE
    # Input combo boxes are editable, output combo boxes are selection-only
    $NewComboBox.DropDownStyle = switch ($Type) {
        'Input'     { [System.Windows.Forms.ComboBoxStyle]::DropDown }
        'Output'    { [System.Windows.Forms.ComboBoxStyle]::DropDownList }
    }

    # CONTENT
    # Fill the ComboBox items from the ContentStringArray parameter
    if ($ContentStringArray.Count -gt 0) {
        [System.Void]$NewComboBox.Items.AddRange($ContentStringArray)
    }
    # Fill the ComboBox items from the ApplicationsFromRegistry parameter
    if ($ApplicationsFromRegistry.Count -gt 0) {       
        # Set the DisplayMember to the property of the application objects that contains the name to display in the ComboBox
        $NewComboBox.DisplayMember = 'ComboBoxName'
        # Set the ValueMember to the property of the application objects that contains the value to use when an item is selected in the ComboBox (in this case, the RegistryPath)
        $NewComboBox.ValueMember = 'RegistryPath'
        # Clear any existing items and add the applications from the registry to the ComboBox items
        $NewComboBox.Items.Clear()
        [void]$NewComboBox.Items.AddRange([object[]]$ApplicationsFromRegistry)
    }

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
    }

    # DEFAULTVALUE
    # Add the DefaultValue
    if ($DefaultValue) {
        # Add the DefaultValue to the Tag property
        $NewComboBox.Tag | Add-Member -MemberType NoteProperty -Name DefaultValue -Value $DefaultValue
        # If the box is empty then fill it with the DefaultValue
        if (Test-String -IsEmpty $NewComboBox.Text) {
            Write-Line ("The box labeled ($($NewComboBox.Tag.Label)) is empty. It will be filled with the default value: ($DefaultValue)")
            $NewComboBox.Text = $NewComboBox.Tag.DefaultValue
        }
    }

    # BUTTONS
    # Add the ButtonPropertiesArray
    if ($Buttons.Count -gt 0) {
        try {
            # Initialize the ButtonPropertiesArray in the Tag property
            $NewComboBox.Tag | Add-Member -MemberType NoteProperty -Name ButtonPropertiesArray -Value @()
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
                        'Browse'    { { [System.String]$FolderName = Select-Item -Folder ; if ($FolderName) { $NewComboBox.Text = $FolderName } }.GetNewClosure() }
                        'Open'      { { if (Test-String -IsEmpty $NewComboBox.Text) { Write-Line 'The ComboBox is empty. The Open-action cannot be performed.' } else { Open-Folder -Path $NewComboBox.Text } }.GetNewClosure() }
                        'Copy'      { { if (Test-String -IsEmpty $NewComboBox.Text) { Write-Line 'The ComboBox is empty. The Copy-action cannot be performed.' } else { Set-ClipBoard -Value $NewComboBox.Text ; Write-Line "The content of the ComboBox has been copied to the clipboard. ($($NewComboBox.Text))" } }.GetNewClosure() }
                        'Paste'     { { $NewComboBox.Text = Get-ClipBoard ; Write-Line "The content of the clipboard has been pasted into the ComboBox. ($($NewComboBox.Text))" }.GetNewClosure() }
                        'Default'   { { $NewComboBox.Text = $NewComboBox.Tag.DefaultValue ; Write-Line "The ComboBox has been reset to the default value: ($($NewComboBox.Text))" }.GetNewClosure() }
                        'Clear'     { { $NewComboBox.Text = '' ; Write-Line 'The ComboBox has been cleared.' }.GetNewClosure() }
                    }
                }
                # Add the hashtable to the ButtonPropertiesArray
                $NewComboBox.Tag.ButtonPropertiesArray += $ButtonHashtable
            }
            # Create the buttons
            New-ButtonLine -InputObject $InputObject -ButtonPropertiesArray $NewComboBox.Tag.ButtonPropertiesArray -ParentGroupBox $ParentGroupBox -RowNumber ($RowNumber + 1)
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


