####################################################################################################
<#
.SYNOPSIS
    Imports the Convert Image to ICO feature into the Files sub-tab.
.DESCRIPTION
    This function imports the Convert Image to ICO feature into the Files sub-tab by creating a new GroupBox and adding it to the specified parent TabPage.
.EXAMPLE
    Import-FeatureConvertImageToIcon -InputObject $MyApplicationObject -ParentTabPage $MyTabPage
.INPUTS
    [PSCustomObject]
    [System.Windows.Forms.TabPage]
.OUTPUTS
    [System.Windows.Forms.GroupBox]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.9.3
    Author          : Imraan Iotana
    Creation Date   : October 2026
    Last Update     : October 2026
#>
####################################################################################################
function Import-FeatureConvertImageToIcon {
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
            Title           = 'CONVERT IMAGE TO ICO'
            Color           = $Color
            NumberOfRows    = 3
            GroupBoxAbove   = $GroupBoxAbove
        }

        # EXECUTION - GROUPBOX
        # Create the GroupBox
        [System.Windows.Forms.GroupBox]$FeatureGroupBox = New-GroupBox @GroupBoxProperties

        # PREPARATION - TEXTBOX PROPERTIES
        # Set the TextBox properties
        [System.Collections.Hashtable]$ImageTextBoxProperties = @{
            RowNumber       = 1
            Label           = 'Source Image'
            ToolTip         = 'PNG, JPG, BMP, GIF, or TIFF image to convert to a Windows icon'
            SizeType        = 'Medium'
            IsPath          = $true
            SmallButtons    = @(@(5,'Browse File','Image'),@(6,'Paste'),@(7,'Open'))
        }
        [System.Windows.Forms.TextBox]$ImagePathTextBox = New-TextBox @ImageTextBoxProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ReturnTextBox

        [System.Collections.Hashtable]$DestinationTextBoxProperties = @{
            RowNumber       = 2
            Label           = 'Destination'
            ToolTip         = 'Optional. Leave empty to write the .ico file next to the source image, or choose a folder or an .ico path.'
            SizeType        = 'Medium'
            IsPath          = $true
            SmallButtons    = @(@(5,'Browse Folder'),@(6,'Paste'),@(7,'Open'))
        }
        [System.Windows.Forms.TextBox]$DestinationTextBox = New-TextBox @DestinationTextBoxProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ReturnTextBox

        # EXECUTION - BUTTONS
        # Set the Button properties
        [System.Collections.Hashtable[]]$ActionButtons = @(
            @{
                ColumnNumber    = 1
                Text            = 'Convert'
                PNGFileName     = 'magic_wand_2'
                SizeType        = 'Medium'
                ToolTip         = 'Create a multi-size Windows icon from the selected image.'
                Function        = { Convert-SelectedImageToIcon -ImagePath $ImagePathTextBox.Text -Destination $DestinationTextBox.Text }.GetNewClosure()
            }
            @{
                ColumnNumber    = 7
                Text            = 'Clear Fields'
                PNGFileName     = 'textfield_delete'
                SizeType        = 'Small'
                ToolTip         = 'Clear these fields.'
                Function        = { Clear-TextBox -TextBox $ImagePathTextBox; Clear-TextBox -TextBox $DestinationTextBox }.GetNewClosure()
            }
        )
        # Create the Buttons
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


####################################################################################################
<#
.SYNOPSIS
    Converts the image selected in the Files sub-tab to an .ico file.
.DESCRIPTION
    Confirms overwrite when the destination already exists, then writes a multi-size Windows icon.
.EXAMPLE
    Convert-SelectedImageToIcon -ImagePath 'C:\Images\Logo.png'
.INPUTS
    [System.String]
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.9.3
    Author          : Imraan Iotana
    Creation Date   : October 2026
    Last Update     : October 2026
#>
####################################################################################################
function Convert-SelectedImageToIcon {
    [CmdletBinding()]
    [OutputType([System.Void])]
    param (
        [Parameter(Mandatory=$false,HelpMessage='The source image path from the form.')]
        [AllowNull()][AllowEmptyString()]
        [System.String]$ImagePath,

        [Parameter(Mandatory=$false,HelpMessage='Optional destination folder or .ico path from the form.')]
        [AllowNull()][AllowEmptyString()]
        [System.String]$Destination
    )

    try {
        # VALIDATION - SOURCE
        $ImagePath = ConvertFrom-ExplorerFilePath -Path $ImagePath
        $Destination = ConvertFrom-ExplorerFilePath -Path $Destination
        if (-not (Confirm-FilePath -Path $ImagePath -Name 'Source Image')) {
            return
        }

        # VALIDATION - OVERWRITE
        [System.String]$IconPath = Resolve-IconFileDestination -Path $ImagePath -Destination $Destination
        if (Test-Path -LiteralPath $IconPath -PathType Leaf) {
            [System.Boolean]$UserHasConfirmed = Get-UserConfirmation -Title 'Convert Image to ICO' -Body "The destination already exists. Overwrite it?`r`n`r`n$IconPath" -Type Question
            if (-not $UserHasConfirmed) {
                return
            }
        }

        # EXECUTION - CONVERT
        Write-Line "Converting the image to an icon. ($ImagePath)" -Type Busy
        [PSCustomObject]$IconFile = ConvertTo-IconFile -Path $ImagePath -Destination $IconPath -Force
        if ($null -eq $IconFile) {
            return
        }

        # OUTPUT
        Write-Line "The icon was created. ($($IconFile.Path))" -Type Success
        Write-Line "Icon sizes: $($IconFile.Sizes)" -Type Info
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}

### END OF FUNCTION
####################################################################################################
