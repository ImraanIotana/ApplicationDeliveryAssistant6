#
# Module 'Graphics.Button.psm1'
# Last Update: May 2026
#

####################################################################################################
<#
.SYNOPSIS
    Adds graphical dimensions to the Button settings based on the MainForm dimensions and the Button margins.
.DESCRIPTION
    This function adds graphical dimensions to the Button settings based on the MainForm dimensions and the Button margins.
     It calculates the width and height of the Button based on the MainForm dimensions and the Button margins, and adds these dimensions to the Button settings in the GraphicalSettings hashtable of the main object.
.EXAMPLE
    Add-ButtonDimensions -InputObject $Global:ApplicationObject
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
        # Get the MainForm settings
        [System.Collections.Hashtable]$Settings = $InputObject.GraphicalSettings

        # EXECUTION - ADD BUTTON WIDTH
        # Add the width of the Large Button
        [System.Int32]$ButtonLargeWidth     = $Settings.TextBox.LargeWidth / 5
        $Settings.Button.LargeWidth         = $ButtonLargeWidth
        # Add the width of the Medium Button (same as Large)
        $Settings.Button.MediumWidth        = $ButtonLargeWidth
        # Add the width of the Small Button
        $Settings.Button.SmallWidth         = ($ButtonLargeWidth / 3)

        # EXECUTION - ADD BUTTON HEIGHT
        # Add the height of the Large Button
        [System.Int32]$TextBoxHeight        = $Settings.TextBox.Height
        [System.Int32]$ButtonLargeHeight    = $TextBoxHeight * 2
        $Settings.Button.LargeHeight        = $ButtonLargeHeight
        # Add the height of the Medium Button
        [System.Int32]$ButtonMediumHeight   = $TextBoxHeight - 3
        $Settings.Button.MediumHeight       = $ButtonMediumHeight
        # Add the height of the Small Button (same as Medium)
        $Settings.Button.SmallHeight        = $ButtonMediumHeight
        
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
        [void]$ColumnNumbersLocationXArray.Add($ColumnNumbersLocationXArray[5] + ($ButtonMediumWidth * 1/3 )) # Column and Index 6
        [void]$ColumnNumbersLocationXArray.Add($ColumnNumbersLocationXArray[6] + ($ButtonMediumWidth * 1/3 )) # Column and Index 7
        [void]$ColumnNumbersLocationXArray.Add($ColumnNumbersLocationXArray[7] + ($ButtonMediumWidth * 1/3 )) # Column and Index 8
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
    This function creates a new TabPage based on the provided parameters, and adds it to the specified parent TabControl.
.EXAMPLE
    New-TabPage -ParentTabControl $MyTabControl -Title 'Administration' -BackGroundColor 'Green'
.INPUTS
    [System.Windows.Forms.TabControl]
    [System.String]
.OUTPUTS
    [System.Windows.Forms.TabPage]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. All rights reserved.
    Version         : 6.0.0.0
    Author          : Imraan Iotana
    Creation Date   : May 2026
    Last Update     : May 2026
#>
####################################################################################################
function Invoke-Button {
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

    begin {
        ####################################################################################################
        ### MAIN PROPERTIES ###

        # Input
        [System.Collections.Hashtable]$Settings = $InputObject.GraphicalSettings

        # Create a New Button
        [System.Windows.Forms.Button]$NewButton = New-Object System.Windows.Forms.Button

        ####################################################################################################
    }
    
    process {
        try {
            # COORDINATES
            # Set the Location
            [System.Int32]$ButtonTopLeftX   = $Settings.ColumnNumber.($ColumnNumber)
            [System.Int32]$ButtonTopLeftY   = $Settings.TextBox.TopMargin + (($RowNumber - 1) * $Settings.TextBox.Height)
            $NewButton.Location             = New-Object System.Drawing.Point($ButtonTopLeftX, $ButtonTopLeftY)
            
            # SIZE
            # Set the Size
            [System.Int32[]]$ButtonSize = switch ($SizeType) {
                'Large'     { @($Settings.Button.LargeWidth,    $Settings.Button.LargeHeight) }
                'Medium'    { @($Settings.Button.MediumWidth,   $Settings.Button.MediumHeight) }
                'Small'     { @($Settings.Button.SmallWidth,    $Settings.Button.SmallHeight) }
            }
            $NewButton.Size = New-Object System.Drawing.Point($ButtonSize)
    
            # TOOLTIP
            # Check if the button has a default Text/Tooltip
            [System.Collections.Hashtable]$DefaultToolTips = @{
                'Copy'      = 'Copy the content of the box to your clipboard'
                'Paste'     = 'Paste the content of your clipboard to the box'
                'Clear'     = 'Clear the content of the box'
                'Default'   = 'Reset the box to the default value'
            }
            if (-not $ToolTip -and $DefaultToolTips.ContainsKey($Text)) { $ToolTip = $DefaultToolTips[$Text] }
    
            # Add the ToolTip
            if ($ToolTip) {
                [System.Windows.Forms.ToolTip]$NewToolTipObject = New-Object System.Windows.Forms.ToolTip
                $NewToolTipObject.SetToolTip($NewButton,$ToolTip)
                # Add the ToolTip object to the Mouse Over action
                $NewButton.Add_MouseEnter({ $NewToolTipObject })
            }

            
            # IMAGE
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
            $NewButton | Out-Host
        }
        catch {
            Write-ErrorReport -ErrorRecord $_
        }
    }

    end {
    }
}

### END OF FUNCTION
####################################################################################################
