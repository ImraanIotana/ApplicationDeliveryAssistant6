
####################################################################################################
<#
.SYNOPSIS
    Imports the Tab color selection feature into the Maintenance Settings sub-tab.
.DESCRIPTION
    This function creates a GroupBox and adds a Graphic ComboBox filled with Windows Forms known color names.
.EXAMPLE
    Import-FeatureTabColorSelection -InputObject $MyApplicationObject -ParentTabPage $MyTabPage
.INPUTS
    [PSCustomObject]
    [System.Windows.Forms.TabPage]
    [System.Windows.Forms.GroupBox]
    [System.String]
.OUTPUTS
    [System.Windows.Forms.GroupBox]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.1
    Author          : Imraan Iotana
    Creation Date   : July 2026
    Last Update     : July 2026
#>
####################################################################################################
function Import-FeatureTabColorSelection {
    [CmdletBinding()]
    [OutputType([System.Windows.Forms.GroupBox])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The ApplicationObject containing the Settings.')]
        [PSCustomObject]$InputObject,

        [Parameter(Mandatory=$true,HelpMessage='The Parent TabPage to which this Feature will be added.')]
        [System.Windows.Forms.TabPage]$ParentTabPage,

        [Parameter(Mandatory=$false,HelpMessage='The GroupBox underneath which this Feature will be added.')]
        [System.Windows.Forms.GroupBox]$GroupBoxAbove,

        [Parameter(Mandatory=$false,HelpMessage='The color of the GroupBox.')]
        [System.String]$Color
    )

    try {
        # PREPARATION - GROUPBOX PROPERTIES
        # Set the GroupBox properties
        [System.Collections.Hashtable]$GroupBoxProperties = @{
            InputObject     = $InputObject
            ParentTabPage   = $ParentTabPage
            Title           = 'TAB COLOR SELECTION'
            Color           = $Color
            NumberOfRows    = 2
            GroupBoxAbove   = $GroupBoxAbove
        }

        # EXECUTION - GROUPBOX
        # Create the GroupBox
        [System.Windows.Forms.GroupBox]$FeatureGroupBox = New-GroupBox @GroupBoxProperties

        # PREPARATION - CONTENT
        [System.String]$DefaultValue = 'Automatic'
        # Build visually ordered lists from reusable graphics helpers
        [System.String[]]$ThemeColorNames = @($DefaultValue) + @(Get-KnownColorNamesByVisualOrder)
        [System.String[]]$ThemeFontColorNames = @($DefaultValue) + @(Get-KnownFontColorNamesByVisualOrder)

        # EXECUTION - GRAPHIC COMBOBOX
        # Set the Graphic ComboBox properties
        [System.Collections.Hashtable]$ThemeColorComboBoxProperties = @{
            RowNumber           = 1
            Label               = 'Selected Tab Color'
            SizeType            = 'Medium'
            Type                = 'Output'
            ContentStringArray  = $ThemeColorNames
            DefaultValue        = $DefaultValue
            SmallButtons        = @(,(@(5,'Default')))
            ShowColorSwatches   = $true
        }
        # Create the Theme color selector
        [System.Windows.Forms.ComboBox]$ThemeColorComboBox = New-GraphicComboBox @ThemeColorComboBoxProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ReturnComboBox

        # Set the Graphic ComboBox properties
        [System.Collections.Hashtable]$ThemeFontColorComboBoxProperties = @{
            RowNumber           = 2
            Label               = 'Selected Tab Font Color'
            SizeType            = 'Medium'
            Type                = 'Output'
            ContentStringArray  = $ThemeFontColorNames
            DefaultValue        = $DefaultValue
            SmallButtons        = @(,(@(5,'Default')))
            ShowColorSwatches   = $true
        }
        # Create the Theme font color selector
        [System.Windows.Forms.ComboBox]$ThemeFontColorComboBox = New-GraphicComboBox @ThemeFontColorComboBoxProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ReturnComboBox

        # WIRE HIGHLIGHT COLOR
        # Keep the main tab and current sub-tab highlight colors in sync with this Theme selector
        # Note: 'Automatic' is a special marker value that enables dynamic color matching
        Register-TabHighlightColorComboBox -ComboBox $ThemeColorComboBox -MainTabControl $Global:MainTabControl -DefaultColorName $DefaultValue

        # WIRE FONT COLOR
        # Keep the main tab and current sub-tab selected font colors in sync with this Theme selector
        # Note: 'Automatic' is a special marker value that enables dynamic font color based on tab background
        Register-TabFontColorComboBox -ComboBox $ThemeFontColorComboBox -MainTabControl $Global:MainTabControl -DefaultColorName $DefaultValue

        # POST-EXECUTION
        # Return the GroupBox object for feature chaining/layout
        $FeatureGroupBox
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
	Returns Windows known color names sorted for visual browsing.
.DESCRIPTION
	This function returns the full KnownColor name list and orders items by visual similarity:
	chromatic colors first (by hue), then low-saturation grayscale colors.
.EXAMPLE
	$Colors = Get-KnownColorNamesByVisualOrder
.INPUTS
	No pipeline input.
.OUTPUTS
	[System.String[]]
.NOTES
	This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
	Version         : 6.0.0.1
	Author          : Imraan Iotana
	Creation Date   : July 2026
	Last Update     : July 2026
#>
####################################################################################################
function Get-KnownColorNamesByVisualOrder {
	[CmdletBinding()]
	[OutputType([System.String[]])]
	param ()

	try {
		[System.String[]]$KnownColorNames = [System.Enum]::GetNames([System.Drawing.KnownColor]) | Sort-Object {
			[System.Drawing.Color]$ColorObject = [System.Drawing.Color]::FromName($_)
			if ($ColorObject.GetSaturation() -lt 0.05) { 1 } else { 0 }
		}, {
			([System.Drawing.Color]::FromName($_)).GetHue()
		}, {
			([System.Drawing.Color]::FromName($_)).GetSaturation()
		}, {
			([System.Drawing.Color]::FromName($_)).GetBrightness()
		}, {
			$_
		}

		$KnownColorNames
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
    Returns Windows known font color names sorted for visual browsing.
.DESCRIPTION
    This function returns the KnownColor name list filtered for readable tab-font usage on light tab
    backgrounds. Colors are ordered by visual similarity: chromatic colors first (by hue), then
    low-saturation grayscale colors.
.EXAMPLE
    $FontColors = Get-KnownFontColorNamesByVisualOrder
.INPUTS
    No pipeline input.
.OUTPUTS
    [System.String[]]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.1
    Author          : Imraan Iotana
    Creation Date   : July 2026
    Last Update     : July 2026
#>
####################################################################################################
function Get-KnownFontColorNamesByVisualOrder {
    [CmdletBinding()]
    [OutputType([System.String[]])]
    param ()

    try {
        [System.String[]]$KnownFontColorNames = [System.Enum]::GetNames([System.Drawing.KnownColor]) | Where-Object {
            [System.Drawing.Color]$ColorObject = [System.Drawing.Color]::FromName($_)
            $ColorObject.A -gt 0 -and ($ColorObject.GetBrightness() -le 0.70 -or $_ -eq 'White')
        } | Sort-Object {
            [System.Drawing.Color]$ColorObject = [System.Drawing.Color]::FromName($_)
            if ($ColorObject.GetSaturation() -lt 0.05) { 1 } else { 0 }
        }, {
            ([System.Drawing.Color]::FromName($_)).GetHue()
        }, {
            ([System.Drawing.Color]::FromName($_)).GetSaturation()
        }, {
            ([System.Drawing.Color]::FromName($_)).GetBrightness()
        }, {
            $_
        }

        $KnownFontColorNames
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}

### END OF FUNCTION
####################################################################################################
