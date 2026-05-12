#
# Module 'Graphics.TextBox.psm1'
# Last Update: May 2026
#

####################################################################################################
<#
.SYNOPSIS
    Adds graphical dimensions to the MainTabControl settings based on the MainForm dimensions and the MainTabControl margins.
.DESCRIPTION
    This function adds graphical dimensions to the MainTabControl settings based on the MainForm dimensions and the MainTabControl margins.
     It calculates the width and height of the MainTabControl based on the MainForm dimensions and the MainTabControl margins, and adds these dimensions to the MainTabControl settings in the GraphicalSettings hashtable of the main object.
.EXAMPLE
    Add-MainTabControlDimensions -InputObject $Global:ApplicationObject
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

        # TEXTBOX WIDTH
        # Add the width of the Large textbox
        [System.Int32]$TextBoxLargeWidth = $Settings.GroupBox.Width - $Settings.TextBox.LeftMargin - $Settings.TextBox.RightMargin
        $Settings.TextBox.LargeWidth = $TextBoxLargeWidth
        # Add the width of the Medium textbox
        $Settings.TextBox.MediumWidth = (($TextBoxLargeWidth * 0.8) - 3)
        # Add the width of the Small textbox
        $Settings.TextBox.SmallWidth = (($TextBoxLargeWidth * 0.6) - 3)
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
    This function creates a new TextBox.
.DESCRIPTION
    This function is part of the Application Delivery Assistant. It creates a new TextBox and adds it to the specified parent GroupBox.
.EXAMPLE
    Invoke-TextBox -ParentGroupBox $MyGroupBox -RowNumber 2 -SizeType 'Medium' -Type 'Input' -Label 'Enter Name:' -TextColor 'Blue' -PropertyName 'UserName'
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
        [System.Object[][]]$ButtonPropertiesArray,

        [Parameter(Mandatory=$false,HelpMessage='The ToolTip text to display when hovering over the TextBox.')]
        [System.String]$ToolTip
    )

    begin {
        ####################################################################################################
        ### MAIN PROPERTIES ###

        # Input
        [System.Collections.Hashtable]$Settings     = $InputObject.GraphicalSettings

        # Create a new TextBox as the Output
        [System.Windows.Forms.TextBox]$NewTextBox   = New-Object System.Windows.Forms.TextBox

        ####################################################################################################
    }
    
    process {
        ####################################################################################################
        ### NATIVE PROPERTIES ###

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

        ####################################################################################################
        ### CUSTOM PROPERTIES ###

        <# TAG
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
            # Make it interact with the registry
            $NewTextBox.Text = Invoke-RegistrySettings -Read -PropertyName $NewTextBox.Tag.PropertyName
            $NewTextBox.Add_TextChanged([System.EventHandler]{ param($TextBoxInternal=$NewTextBox) Invoke-RegistrySettings -Write -PropertyName $TextBoxInternal.Tag.PropertyName -PropertyValue $TextBoxInternal.Text })
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
        if ($ButtonPropertiesArray.Count -gt 0) {
            try {
                # Initialize the ButtonPropertiesArray in the Tag property
                $NewTextBox.Tag | Add-Member -MemberType NoteProperty -Name ButtonPropertiesArray -Value @()
                # Add each button to the ButtonPropertiesArray
                foreach ($Button in $ButtonPropertiesArray) {
                    # Set the button properties
                    [System.Int32]$ColumnNumber = $Button[0]
                    [System.String]$ButtonText  = $Button[1]
                    # Create the hashtable
                    [System.Collections.Hashtable]$ButtonHashtable = @{
                        ColumnNumber    = $ColumnNumber
                        Text            = $ButtonText
                        Function        = switch ($ButtonText) {
                            'Copy'      { { Invoke-ClipBoard -CopyFromBox $NewTextBox }.GetNewClosure() }
                            'Paste'     { { Invoke-ClipBoard -PasteToBox $NewTextBox }.GetNewClosure() }
                            'Clear'     { { Clear-TextBox $NewTextBox }.GetNewClosure() }
                            'Default'   { { Reset-TextBoxToDefault $NewTextBox }.GetNewClosure() }
                            'Browse'    { { [System.String]$FolderName = Select-Item -Folder ; if ($FolderName) { $NewTextBox.Text = $FolderName } }.GetNewClosure() }
                            'Open'      { { Open-Folder -Path $NewTextBox.Text }.GetNewClosure() }
                        }
                    }
                    # Add the hashtable to the ButtonPropertiesArray
                    $NewTextBox.Tag.ButtonPropertiesArray += $ButtonHashtable
                }
                # Create the buttons
                Invoke-ButtonLine -InputObject $InputObject -ButtonPropertiesArray $NewTextBox.Tag.ButtonPropertiesArray -ParentGroupBox $ParentGroupBox -RowNumber ($RowNumber + 1)
            }
            catch {
                Write-FullError
            }
        }

        # TOOLTIP
        # Add the ToolTip
        if ($ToolTip) {
            [System.Windows.Forms.ToolTip]$TextBoxToolTip = New-Object System.Windows.Forms.ToolTip
            $TextBoxToolTip.SetToolTip($NewTextBox, $ToolTip)
        }#>

        # ADD TO PARENT
        # Add the new textbox to the parent
        $ParentGroupBox.Controls.Add($NewTextBox)
    }

    end {
        # Return the output
        $NewTextBox
    }
}

### END OF FUNCTION
####################################################################################################

