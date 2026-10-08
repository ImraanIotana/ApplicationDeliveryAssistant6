####################################################################################################
<#
.SYNOPSIS
	Creates a new graphical ComboBox and adds it to the specified parent GroupBox.
.DESCRIPTION
	This function is a standalone ComboBox creator intended for graphical/owner-draw scenarios.
	It is kept separate from the existing New-ComboBox function so both implementations can coexist.
.EXAMPLE
	New-GraphicComboBox -InputObject $MyApplicationObject -ParentGroupBox $MyGroupBox -Label 'Color'
.INPUTS
	[PSCustomObject]
	[System.Windows.Forms.GroupBox]
	[System.Int32]
	[System.String]
	[System.String[]]
.OUTPUTS
	[System.Windows.Forms.ComboBox]
.NOTES
	This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
	Version         : 6.0.0.2
	Author          : Imraan Iotana
	Creation Date   : July 2026
	Last Update     : July 2026
#>
####################################################################################################
function New-GraphicComboBox {
	[CmdletBinding()]
	[OutputType([System.Windows.Forms.ComboBox])]
	param (
		[Parameter(Mandatory=$true,HelpMessage='The ApplicationObject containing the settings.')]
		[PSCustomObject]$InputObject,

		[Parameter(Mandatory=$true,HelpMessage='The Parent GroupBox to which this ComboBox will be added.')]
		[System.Windows.Forms.GroupBox]$ParentGroupBox,

		[Parameter(Mandatory=$false,HelpMessage='The RowNumber where the ComboBox will be placed.')]
		[System.Int32]$RowNumber = 1,

		[Parameter(Mandatory=$false,HelpMessage='The SizeType of the ComboBox. This influences only width.')]
		[ValidateSet('Small','Medium','Large')]
		[System.String]$SizeType = 'Large',

		[Parameter(Mandatory=$false,HelpMessage='The type of ComboBox. Input allows typing; Output is selection-only.')]
		[ValidateSet('Input','Output')]
		[System.String]$Type = 'Output',

		[Parameter(Mandatory=$false,HelpMessage='Optional label text shown to the left of the ComboBox.')]
		[System.String]$Label,

		[Parameter(Mandatory=$false,HelpMessage='Optional text color name.')]
		[System.String]$TextColor,

		[Parameter(Mandatory=$false,HelpMessage='The PropertyName that will be added to the object, to interact with the registry.')]
		[System.String]$PropertyName,

		[Parameter(Mandatory=$false,HelpMessage='Optional ToolTip text for the ComboBox.')]
		[System.String]$ToolTip,

		[Parameter(Mandatory=$false,HelpMessage='Optional string array content for the ComboBox.')]
		[System.String[]]$ContentStringArray,

		[Parameter(Mandatory=$false,HelpMessage='The DefaultValue that will be added to the object.')]
		[Alias('Default')]
		[System.String]$DefaultValue,

		[Parameter(Mandatory=$false,HelpMessage='The DefaultButtonsArray that will be added to the object.')]
		[System.Object[][]]$Buttons,

		[Parameter(Mandatory=$false,HelpMessage='The small buttons array that will be added to the object.')]
		[System.Object[][]]$SmallButtons,

		[Parameter(Mandatory=$false,HelpMessage='Renders a color swatch next to each item when the item text is a color name.')]
		[System.Management.Automation.SwitchParameter]$ShowColorSwatches,

		[Parameter(Mandatory=$false,HelpMessage='Switch for returning the created ComboBox object.')]
		[System.Management.Automation.SwitchParameter]$ReturnComboBox
	)

	try {
		# VALIDATION - LABEL VALIDATION
		# Every ComboBox must have a non-empty label so registration failures point to the offending call site
		if (Test-String -IsEmpty $Label) {
			throw 'New-GraphicComboBox requires a non-empty -Label.'
		}

		# EXECUTION - CREATE CONTROL
		[System.Windows.Forms.ComboBox]$NewComboBox = New-Object System.Windows.Forms.ComboBox

		# Apply shared ComboBox layout and style properties
		Set-ComboBoxCoreProperties -InputObject $InputObject -ParentGroupBox $ParentGroupBox -ComboBox $NewComboBox -RowNumber $RowNumber -SizeType $SizeType -Type $Type -TextColor $TextColor

		# Seed metadata, register this ComboBox, and create its label
		Initialize-ComboBoxTagRegistrationAndLabel -InputObject $InputObject -ParentGroupBox $ParentGroupBox -ComboBox $NewComboBox -Label $Label -PropertyName $PropertyName -RowNumber $RowNumber

		# CONTENT
		if ($ContentStringArray.Count -gt 0) {
			[System.Void]$NewComboBox.Items.AddRange([System.String[]]$ContentStringArray)
		}

		# Bind settings event handlers and resolve the stored value
		[System.String]$StoredPropertyValue = Set-ComboBoxUserSettingBinding -ComboBox $NewComboBox -Type $Type
		# Apply the stored value after content has been loaded
		Set-ComboBoxValueFromStoredSetting -ComboBox $NewComboBox -StoredPropertyValue $StoredPropertyValue -Type $Type

		# DEFAULTVALUE
		# Add and apply the DefaultValue
		Set-ComboBoxDefaultValue -ComboBox $NewComboBox -DefaultValue $DefaultValue

		# ADD TO PARENT
		# Add the ComboBox before button creation so same-row small buttons stay visible on top
		if (-not $ParentGroupBox.Controls.Contains($NewComboBox)) {
			$ParentGroupBox.Controls.Add($NewComboBox)
		}

		# BUTTONS
		# Add regular and small button lines to the ComboBox
		Add-ButtonsToComboBox -InputObject $InputObject -ParentGroupBox $ParentGroupBox -ComboBox $NewComboBox -RowNumber $RowNumber -Buttons $Buttons -SmallButtons $SmallButtons

		# STYLE - OPTIONAL OWNER DRAW FOR COLOR SWATCHES
		# Draw a color preview square for each entry when enabled
		if ($ShowColorSwatches.IsPresent) {
			$NewComboBox.DrawMode = [System.Windows.Forms.DrawMode]::OwnerDrawFixed
			$NewComboBox.ItemHeight = [System.Math]::Max(($NewComboBox.Font.Height + 4), 18)

			$NewComboBox.Add_DrawItem({
				param($DrawSender, $DrawEventArgs)

				$DrawEventArgs.DrawBackground()
				if ($DrawEventArgs.Index -lt 0 -or $DrawEventArgs.Index -ge $DrawSender.Items.Count) {
					return
				}

				[System.String]$ItemText = [System.String]$DrawSender.Items[$DrawEventArgs.Index]
				[System.Drawing.Color]$ItemColor = [System.Drawing.Color]::FromName($ItemText)
				[System.Boolean]$IsValidColor = ($ItemColor.IsKnownColor -or $ItemColor.IsNamedColor)

				[System.Int32]$SwatchSize = [System.Math]::Max(($DrawEventArgs.Bounds.Height - 6), 12)
				[System.Drawing.Rectangle]$SwatchRectangle = New-Object System.Drawing.Rectangle(($DrawEventArgs.Bounds.X + 3), ($DrawEventArgs.Bounds.Y + (($DrawEventArgs.Bounds.Height - $SwatchSize) / 2)), $SwatchSize, $SwatchSize)
				[System.Drawing.Rectangle]$TextRectangle = New-Object System.Drawing.Rectangle(($SwatchRectangle.Right + 6), $DrawEventArgs.Bounds.Y, [System.Math]::Max(($DrawEventArgs.Bounds.Width - $SwatchSize - 12), 10), $DrawEventArgs.Bounds.Height)

				[System.Drawing.Brush]$SwatchBrush = if ($IsValidColor) {
					New-Object System.Drawing.SolidBrush($ItemColor)
				}
				else {
					New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
				}

				[System.Drawing.Color]$TextColor = if (($DrawEventArgs.State -band [System.Windows.Forms.DrawItemState]::Selected) -eq [System.Windows.Forms.DrawItemState]::Selected) {
					[System.Drawing.SystemColors]::HighlightText
				}
				else {
					$DrawSender.ForeColor
				}
				[System.Windows.Forms.TextFormatFlags]$TextFlags = [System.Windows.Forms.TextFormatFlags]::VerticalCenter -bor [System.Windows.Forms.TextFormatFlags]::Left -bor [System.Windows.Forms.TextFormatFlags]::EndEllipsis -bor [System.Windows.Forms.TextFormatFlags]::SingleLine

				try {
					$DrawEventArgs.Graphics.FillRectangle($SwatchBrush, $SwatchRectangle)
					$DrawEventArgs.Graphics.DrawRectangle([System.Drawing.Pens]::DimGray, $SwatchRectangle)
					[System.Windows.Forms.TextRenderer]::DrawText($DrawEventArgs.Graphics, $ItemText, $DrawSender.Font, $TextRectangle, $TextColor, $TextFlags)
					$DrawEventArgs.DrawFocusRectangle()
				}
				finally {
					$SwatchBrush.Dispose()
				}
			})
		}

		# TOOLTIP
		if (Test-String -IsPopulated $ToolTip) {
			[System.Windows.Forms.ToolTip]$ComboBoxToolTip = New-Object System.Windows.Forms.ToolTip
			$ComboBoxToolTip.SetToolTip($NewComboBox, $ToolTip)
		}

		# ADD TO PARENT
		if (-not $ParentGroupBox.Controls.Contains($NewComboBox)) {
			$ParentGroupBox.Controls.Add($NewComboBox)
		}

		# POST-EXECUTION
		if ($ReturnComboBox.IsPresent) { $NewComboBox }
	}
	catch {
		Write-ErrorReport -ErrorRecord $_
	}
}

### END OF FUNCTION
####################################################################################################
