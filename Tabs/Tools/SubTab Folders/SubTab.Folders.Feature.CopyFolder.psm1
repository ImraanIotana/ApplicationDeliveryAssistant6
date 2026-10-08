####################################################################################################
<#
.SYNOPSIS
	Imports the Folder Copy feature into the Folders sub-tab.
.DESCRIPTION
	This function imports the Folder Copy feature into the Folders sub-tab by creating a new GroupBox and adding it to the specified parent TabPage.
.EXAMPLE
	Import-FeatureFolderCopy -InputObject $MyApplicationObject -ParentTabPage $MyTabPage
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
	Creation Date   : February 2026
	Last Update     : July 2026
#>
####################################################################################################
function Import-FeatureFolderCopy {
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
			Title           = 'FOLDER COPY AND MOVE'
			Color           = $Color
			NumberOfRows    = 3
			GroupBoxAbove   = $GroupBoxAbove
		}

		# EXECUTION - GROUPBOX
		# Create the GroupBox
		[System.Windows.Forms.GroupBox]$FeatureGroupBox = New-GroupBox @GroupBoxProperties

		# PREPARATION - TEXTBOX PROPERTIES
		# Set the source and destination TextBox properties
		[System.Collections.Hashtable]$SourceFolderTextBoxProperties = @{
			RowNumber       = 1
			Label           = 'Folder to Copy / Move'
			ToolTip         = 'The folder that will be copied or moved.'
			SizeType        = 'Medium'
			SmallButtons    = @(@(5,'Browse Folder'),@(6,'Paste'),@(7,'Open'))
		}
		[System.Collections.Hashtable]$DestinationFolderTextBoxProperties = @{
			RowNumber       = 2
			Label           = 'Copy / Move Into Folder'
			ToolTip         = 'The destination folder into which the source folder will be copied or moved.'
			SizeType        = 'Medium'
			SmallButtons    = @(@(5,'Browse Folder'),@(6,'Paste'),@(7,'Open'))
		}

		# EXECUTION - TEXTBOXES
		# Create the TextBoxes
		[System.Windows.Forms.TextBox]$SourceFolderTextBox = New-TextBox @SourceFolderTextBoxProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ReturnTextBox
		[System.Windows.Forms.TextBox]$DestinationFolderTextBox = New-TextBox @DestinationFolderTextBoxProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ReturnTextBox

		# PREPARATION - BUTTON PROPERTIES
		# Set the action button properties
		[System.Collections.Hashtable[]]$ActionButtons = @(
			@{
				ColumnNumber    = 1
				Text            = 'Copy Folder'
				PNGFileName     = 'page_copy'
				SizeType        = 'Medium'
				ToolTip         = 'Copy the selected source folder into the destination folder.'
				Function        = { Copy-WithGUI -ThisFolder $SourceFolderTextBox.Text -IntoThisFolder $DestinationFolderTextBox.Text }.GetNewClosure()
			}
			@{
				ColumnNumber    = 2
				Text            = 'Move Folder'
				PNGFileName     = 'folder_go'
				SizeType        = 'Medium'
				ToolTip         = 'Move the selected source folder into the destination folder.'
				Function        = { Copy-WithGUI -ThisFolder $SourceFolderTextBox.Text -IntoThisFolder $DestinationFolderTextBox.Text -Move }.GetNewClosure()
			}
			@{
				ColumnNumber    = 3
				Text            = 'Switch Folders'
				PNGFileName     = 'arrow_refresh'
				SizeType        = 'Medium'
				ToolTip         = 'Swap the source and destination folder paths.'
				Function        = {
					[System.String]$TempFolderPath = $SourceFolderTextBox.Text
					$SourceFolderTextBox.Text = $DestinationFolderTextBox.Text
					$DestinationFolderTextBox.Text = $TempFolderPath
				}.GetNewClosure()
			}
			@{
				ColumnNumber    = 7
				Text            = 'Clear Fields'
				PNGFileName     = 'textfield_delete'
				SizeType        = 'Small'
				ToolTip         = 'Clear both folder path fields.'
				Function        = {
					if (-not (Get-UserConfirmation -Title 'Clear Fields' -Body "This will CLEAR both folder path fields.`n`nDo you want to continue?")) { return }
					Clear-TextBox -TextBox $SourceFolderTextBox -Force
					Clear-TextBox -TextBox $DestinationFolderTextBox -Force
				}.GetNewClosure()
			}
		)

		# EXECUTION - BUTTONS
		# Create the Action Buttons
		New-ButtonLine -InputObject $InputObject -ButtonPropertiesArray $ActionButtons -ParentGroupBox $FeatureGroupBox -RowNumber 3

		# POST-EXECUTION
		# Return the GroupBox object
		$FeatureGroupBox
	}
	catch {
		Write-ErrorReport -ErrorRecord $_
	}
}

### END OF FUNCTION
####################################################################################################
