####################################################################################################
<#
.SYNOPSIS
    Adds graphical dimensions to the Button settings based on the MainForm dimensions and the Button margins.
.DESCRIPTION
    This function adds graphical dimensions to the Button settings based on the MainForm dimensions and the Button margins.
     It calculates the width and height of the Button based on the MainForm dimensions and the Button margins, and adds these dimensions to the Button settings in the GraphicalSettings hashtable of the main object.
.EXAMPLE
    Add-ButtonDimensions -InputObject $MyApplicationObject
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
function Add-ButtonDimensions {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false,HelpMessage='The ApplicationObject containing the settings.')]
        [PSCustomObject]$InputObject
    )

    try {
        # PREPARATION - GET SETTINGS
        # Get the settings
        [System.Collections.Hashtable]$Settings = $InputObject.GraphicalSettings
        # Get the TextBox properties to use as a basis for the Button dimensions
        [System.Int32]$TextBoxHeight            = $Settings.TextBox.Height
        [System.Int32]$TextBoxLargeWidth        = $Settings.TextBox.LargeWidth

        # PREPARATION - RATIOS
        # Set the ratios and margins for the Buttons based on the TextBox size
        [System.Double]$LargeButtonWidthRatio   = 0.2
        [System.Double]$LargeButtonHeightRatio  = 2
        [System.Int32]$MediumButtonHeightMargin = 3
        [System.Double]$SmallButtonWidthRatio   = 3

        # EXECUTION - ADD THE LARGE BUTTON DIMENSIONS
        # Add the dimensions of the Large Button
        $Settings.Button.LargeWidth             = $TextBoxLargeWidth * $LargeButtonWidthRatio
        $Settings.Button.LargeHeight            = $TextBoxHeight * $LargeButtonHeightRatio

        # EXECUTION - ADD THE MEDIUM BUTTON DIMENSIONS
        # Add the dimensions of the Medium Button
        $Settings.Button.MediumWidth            = $Settings.Button.LargeWidth
        $Settings.Button.MediumHeight           = $TextBoxHeight - $MediumButtonHeightMargin

        # EXECUTION - ADD THE SMALL BUTTON DIMENSIONS
        # Add the dimensions of the Small Button
        $Settings.Button.SmallWidth             = $Settings.Button.MediumWidth / $SmallButtonWidthRatio
        $Settings.Button.SmallHeight            = $Settings.Button.MediumHeight
        
        # Get the values
        [System.Int32]$MainTabControlLocationX  = $Settings.MainTabControl.Location.X
        [System.Int32]$LabelLeftMargin          = $Settings.Label.LeftMargin
        [System.Int32]$TextBoxLeftMargin        = $Settings.TextBox.LeftMargin
        [System.Int32]$ButtonMediumWidth        = $Settings.Button.MediumWidth
        # Set the Array
        [System.Collections.ArrayList]$ColumnNumbersLocationXArray = New-Object System.Collections.ArrayList
        # Set the ColumnNumbers and their X location
        # Column 0 is the location underneath the Label
        [void]$ColumnNumbersLocationXArray.Add($LabelLeftMargin) # Column and Index 0
        # Column 1 is the first location underneath the TextBox
        [void]$ColumnNumbersLocationXArray.Add(($MainTabControlLocationX + $LabelLeftMargin + $TextBoxLeftMargin)) # Column and Index 1
        # Columns 2-5 are the following locations underneath the TextBox
        @(1..4) | ForEach-Object { [void]$ColumnNumbersLocationXArray.Add($ColumnNumbersLocationXArray[$_] + $ButtonMediumWidth) } # Column and Index 2-5
        # Column 6 is only used for the small buttons
        [void]$ColumnNumbersLocationXArray.Add($ColumnNumbersLocationXArray[5] + ($ButtonMediumWidth / $SmallButtonWidthRatio )) # Column and Index 6
        [void]$ColumnNumbersLocationXArray.Add($ColumnNumbersLocationXArray[6] + ($ButtonMediumWidth / $SmallButtonWidthRatio )) # Column and Index 7
        [void]$ColumnNumbersLocationXArray.Add($ColumnNumbersLocationXArray[7] + ($ButtonMediumWidth / $SmallButtonWidthRatio )) # Column and Index 8
        # Add the results to the Global Settings
        @(0..7) | ForEach-Object { $Settings.ColumnNumber.Add( $_ , $ColumnNumbersLocationXArray[$_]) }

        # test
        #$Settings.ColumnNumber | Out-Host
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
    This function creates a new Button.
.DESCRIPTION
    This function creates a new Button based on the provided properties and adds it to the specified Parent GroupBox.
.EXAMPLE
    New-Button -InputObject $MyAppObject -ParentGroupBox $MyGroupBox -Text 'Click Me' -RowNumber 1 -ColumnNumber 1 -SizeType 'Medium' -Function { Write-Host 'Button Clicked' }
.INPUTS
    [PSCustomObject]
    [System.Windows.Forms.GroupBox]
    [System.String]
    [System.EventHandler]
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
function New-Button {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The ApplicationObject containing the settings.')]
        [PSCustomObject]$InputObject,

        [Parameter(Mandatory=$true,HelpMessage='The Parent GroupBox to which this button will be added.')]
        [System.Windows.Forms.GroupBox]$ParentGroupBox,

        [Parameter(Mandatory=$false,HelpMessage='The text of the button.')]
        [System.String]$Text,

        [Parameter(Mandatory=$false,HelpMessage='The color of the text.')]
        [AllowEmptyString()]
        [System.String]$TextColor,

        [Parameter(Mandatory = $false,HelpMessage='The name of the image file in png format.')]
        [AllowEmptyString()]
        [System.String]$ImageKeyName,

        [Parameter(Mandatory = $false,HelpMessage='The name of the image file in png format.')]
        [AllowEmptyString()]
        [System.String]$PNGFileName,

        [Parameter(Mandatory = $false,HelpMessage='The path of the image file in png format.')]
        [AllowEmptyString()]
        [System.String]$PNGImagePath,

        [Parameter(Mandatory = $false,HelpMessage='The name of the Default Icon.')]
        [System.String]$DefaultIcon,

        [Parameter(Mandatory=$false,HelpMessage='The location of the button expressed in rownumber.')]
        [System.Int32]$RowNumber = 1,

        [Parameter(Mandatory=$false,HelpMessage='The location of the button expressed in columnnumber.')]
        [System.Int32]$ColumnNumber = 1,

        [Parameter(Mandatory=$false,HelpMessage='The size type of the button (Small, Medium or Large).')]
        [ValidateSet('Small','Medium','Large')]
        [System.String]$SizeType = 'Medium',

        [Parameter(Mandatory = $false,HelpMessage='The function to be invoked when the button is clicked.')]
        [System.EventHandler]$Function,

        [Parameter(Mandatory = $false,HelpMessage='The ToolTip of the button.')]
        [System.String]$ToolTip
    )

    # Input
    [System.Collections.Hashtable]$Settings = $InputObject.GraphicalSettings

    # Create a New Button
    [System.Windows.Forms.Button]$NewButton = New-Object System.Windows.Forms.Button


    try {
        # COORDINATES - PREPARATION
        # Set the Location
        [System.Int32]$ButtonTopLeftX   = $Settings.ColumnNumber.($ColumnNumber)
        [System.Int32]$ButtonTopLeftY   = $Settings.TextBox.TopMargin + (($RowNumber - 1) * $Settings.TextBox.Height)

        # COORDINATES - EXECUTION
        # Set the Location of the Button using the calculated coordinates
        $NewButton.Location             = New-Object System.Drawing.Point($ButtonTopLeftX, $ButtonTopLeftY)
        
        # SIZE - PREPARATION
        # Set the Size
        [System.Int32[]]$ButtonSize = switch ($SizeType) {
            'Large'     { @($Settings.Button.LargeWidth,    $Settings.Button.LargeHeight) }
            'Medium'    { @($Settings.Button.MediumWidth,   $Settings.Button.MediumHeight) }
            'Small'     { @($Settings.Button.SmallWidth,    $Settings.Button.SmallHeight) }
        }

        # SIZE - EXECUTION
        # Set the Size of the Button using the calculated size
        $NewButton.Size = New-Object System.Drawing.Point($ButtonSize)

        # TOOLTIP - PREPARATION
        # Set the default ToolTips based on the Text of the button, if no ToolTip is provided
        [System.Collections.Hashtable]$DefaultToolTips = @{
            'Copy'      = 'Copy the content of the box to your clipboard'
            'Paste'     = 'Paste the content of your clipboard to the box'
            'Clear'     = 'Clear the content of the box'
            'Default'   = 'Reset the box to the default value'
        }
        # If no ToolTip is provided, but the Text matches a default Text, then use the corresponding default ToolTip
        if (-not $ToolTip -and $DefaultToolTips.ContainsKey($Text)) { $ToolTip = $DefaultToolTips[$Text] }

        # TOOLTIP - EXECUTION
        # Add the ToolTip
        if ($ToolTip) {
            [System.Windows.Forms.ToolTip]$NewToolTipObject = New-Object System.Windows.Forms.ToolTip
            $NewToolTipObject.SetToolTip($NewButton,$ToolTip)
            # Add the ToolTip object to the Mouse Over action
            $NewButton.Add_MouseEnter({ $NewToolTipObject })
        }
        
        # IMAGE
        # If a PNG file name is provided, search for the file and add the image to the button
        if ($PNGFileName) {
            # If the PNG filename does not end with .png, then add the extension
            if (-not $PNGFileName.EndsWith('.png')) { $PNGFileName += '.png' }
            # Search for the PNG file
            $PNGImagePath = Get-ChildItem -Path $InputObject.RootFolder -Filter $PNGFileName -File -Recurse | Select-Object -First 1 -ExpandProperty FullName
            # Add the PNG Image
            if ($PNGImagePath) { $NewButton.Image = [System.Drawing.Image]::FromFile($PNGImagePath) }
        }
        
        <# If the DefaultIcon is not specified, then use the Text to determine the DefaultIcon
        if (-not $DefaultIcon) { $DefaultIcon = $Text }

        # If the DefaultIcon exists in the Settings Icons
        if ($Settings.Icons.ContainsKey($DefaultIcon)) {
            # Set the Image from the Settings
            $NewButton.Image = $Settings.Icons[$DefaultIcon]
        } else {
            # Add the PNG Image
            if ($PNGImagePath) {
                $NewButton.Image = [System.Drawing.Image]::FromFile($PNGImagePath)
            }
        }#>

        # IMAGE AND TEXT RELATION
        # Set TextImageRelation for all cases with images
        if ($NewButton.Image) {
            # Set the TextImageRelation
            $NewButton.TextImageRelation = 'ImageBeforeText'
            # If both an image and text are passed thru, add a space before the text for better spacing, except for Small buttons
            if (($Text) -and (-Not($SizeType -eq 'Small')))  { $Text = " $Text" }
        }

        # TEXT
        # If the Size is not Small, then add the Text
        if (($Text) -and (-Not($SizeType -eq 'Small'))) { $NewButton.Text = $Text }
        # Add the Text Color
        if ($TextColor) { $NewButton.ForeColor = $TextColor }

        # CURSOR
        # Add the Cursor
        $NewButton.Cursor = [System.Windows.Forms.Cursors]::Hand

        # FUNCTION
        # Add the Function
        if ($Function) { $NewButton.Add_Click($Function) }

        # ADD BUTTON TO PARENT
        $ParentGroupbox.Controls.Add($NewButton)

        # test
        #$NewButton | Out-Host
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
    This function creates a horizontal line of buttons.
.DESCRIPTION
    This function applies shared button-line properties and invokes Invoke-Button for each button definition.
.EXAMPLE
    New-ButtonLine -InputObject $MyApplicationObject -ButtonPropertiesArray $ButtonPropertiesArray -ParentGroupBox $GroupBox -RowNumber 2
.INPUTS
    [PSCustomObject]
    [System.Collections.Hashtable[]]
    [System.Windows.Forms.GroupBox]
    [System.Int32]
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
function New-ButtonLine {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The ApplicationObject containing the settings.')]
        [PSCustomObject]$InputObject,

        [Parameter(Mandatory=$true,HelpMessage='The array of button property hashtables.')]
        [System.Collections.Hashtable[]]$ButtonPropertiesArray,

        [Parameter(Mandatory=$true,HelpMessage='The Parent GroupBox to which these buttons will be added.')]
        [System.Windows.Forms.GroupBox]$ParentGroupBox,

        [Parameter(Mandatory=$false,ParameterSetName='RowNumber',HelpMessage='The row number to use for buttons that do not define one explicitly.')]
        [System.Int32]$RowNumber = 1,

        [Parameter(Mandatory=$false,ParameterSetName='ColumnNumber',HelpMessage='The column number to use for buttons that do not define one explicitly.')]
        [System.Int32]$ColumnNumber = 1
    )

    try {
        # EXECUTION - CREATE BUTTONS
        # Switch on the ParameterSetName
        switch ($PSCmdlet.ParameterSetName) {
            'RowNumber' {
                foreach ($ButtonPropertiesHashtable in $ButtonPropertiesArray) {
                    New-Button @ButtonPropertiesHashtable -InputObject $InputObject -ParentGroupBox $ParentGroupBox -RowNumber $RowNumber
                }
            }
            'ColumnNumber' {
                foreach ($ButtonPropertiesHashtable in $ButtonPropertiesArray) {
                    New-Button @ButtonPropertiesHashtable -InputObject $InputObject -ParentGroupBox $ParentGroupBox -ColumnNumber $ColumnNumber
                }
            }
        }
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}

### END OF FUNCTION
####################################################################################################
