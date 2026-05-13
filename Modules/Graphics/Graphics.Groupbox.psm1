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
function Add-GroupBoxDimensions {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The ApplicationObject containing the settings.')]
        [PSCustomObject]$InputObject
    )

    try {
        # PREPARATION - GET SETTINGS
        # Get the GraphicalSettings settings
        [System.Collections.Hashtable]$Settings = $InputObject.GraphicalSettings

        # GROUPBOX WIDTH
        # Add the Width of the GroupBox
        $Settings.GroupBox.Width = ($Settings.MainTabControl.Width - $Settings.GroupBox.RightMargin)

        # GROUPBOX HEIGHT
        # Create the GroupboxHeightTable
        [System.Collections.Hashtable]$GroupboxHeightTable =@{}
        # Add the Heights of the GroupBox to the GroupboxHeightTable
        [System.Int32[]]$NumberOfRowsArray = @(1..20)
        foreach ($NumberOfRows in $NumberOfRowsArray) {
            [System.Int32]$GroupboxHeight = if ($NumberOfRows -eq 1) {
                ($NumberOfRows * $Settings.GroupBox.RowHeight) + $Settings.GroupBox.OneRowMargin
            } else {
                $NumberOfRows * $Settings.GroupBox.RowHeight
            }
            $GroupboxHeightTable.Add($NumberOfRows,$GroupboxHeight)
        }
        # Add the GroupboxHeightTable
        $Settings.GroupBox.HeightTable = $GroupboxHeightTable
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
    This function creates a new GroupBox on a specified ParentTabPage with specified properties.
.DESCRIPTION
    This function creates a new GroupBox on a specified ParentTabPage with specified properties such as Title, NumberOfRows, Color, and optionally places it above another GroupBox or on a SubTab.
    The dimensions of the GroupBox are calculated based on the NumberOfRows and the settings defined in the ApplicationObject.
.EXAMPLE
    New-GroupBox -ParentTabPage $MyTabPage -Title 'Application Input'
.EXAMPLE
    New-GroupBox -ParentTabPage $MyTabPage -Title 'MECM Input' -NumberOfRows 8 -Color 'Green' -GroupBoxAbove $MyOtherGroupbox
.INPUTS
    [PSCustomObject]
    [System.Windows.Forms.TabPage]
    [System.String]
    [System.Int32]
    [System.Windows.Forms.GroupBox]
    [System.Management.Automation.SwitchParameter]
.OUTPUTS
    [System.Windows.Forms.GroupBox]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. All rights reserved.
    Version         : 6.0.0.0
    Author          : Imraan Iotana
    Creation Date   : May 2026
    Last Update     : May 2026
#>
####################################################################################################
function New-GroupBox {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The ApplicationObject containing the Settings.')]
        [PSCustomObject]$InputObject,

        [Parameter(Mandatory=$true,HelpMessage='The Parent TabPage to which this groupbox will be added.')]
        [System.Windows.Forms.TabPage]$ParentTabPage,

        [Parameter(Mandatory=$true,HelpMessage='The title of the Groupbox.')]
        [System.String]$Title,

        [Parameter(Mandatory=$false,HelpMessage='The height of the groupbox expressed in rownumbers.')]
        [System.Int32]$NumberOfRows = 1,

        [Parameter(Mandatory=$false,HelpMessage='The color of the text and border.')]
        [System.String]$Color = 'Black',

        [Parameter(Mandatory=$false,HelpMessage='The groupbox underneath which this new Groupbox will be placed.')]
        [System.Windows.Forms.GroupBox]$GroupBoxAbove,

        [Parameter(Mandatory=$false,HelpMessage='Switch for when the GroupBox is on a SubTab.')]
        [System.Management.Automation.SwitchParameter]$OnSubTab
    )

    try {
        # PREPARATION - GET SETTINGS
        # Get the MainTabControl settings
        [System.Collections.Hashtable]$Settings = $InputObject.GraphicalSettings


        # EXECUTION - CREATE THE GROUPBOX
        # Create the GroupBox
        [System.Windows.Forms.GroupBox]$NewGroupBox = New-Object System.Windows.Forms.GroupBox

        # LOCATION
        # Set the Location of the GroupBox
        [System.Int32]$GroupboxTopLeftX = $Settings.MainTabControl.TopLeftX
        [System.Int32]$GroupboxTopLeftY = if ($GroupBoxAbove) {
            $GroupBoxAbove.Location.Y + $GroupBoxAbove.Height + $Settings.GroupBox.BetweenMargin
        } else {
            $Settings.MainTabControl.TopLeftY
        }
        [System.Int32[]]$Location = @($GroupboxTopLeftX, $GroupboxTopLeftY)

        # SIZE
        # Set the Size of the GroupBox
        [System.Int32]$Width    = if ($OnSubTab.IsPresent) {
            $Settings.GroupBox.SubTabGroupboxWidth
        } else {
            $Settings.GroupBox.Width
        }
        [System.Int32]$Height   = $Settings.GroupBox.HeightTable.($NumberOfRows)
        [System.Int32[]]$Size   = @($Width, $Height)

        # ADD PROPERTIES
        # Add the properties to the GroupBox
        $NewGroupBox.Text       = $Title
        $NewGroupBox.ForeColor  = $Color
        $NewGroupBox.Location   = New-Object System.Drawing.Point($Location)
        $NewGroupBox.Size       = New-Object System.Drawing.Size($Size)

        # ADD TO PARENT
        # Add the Groupbox to the ParentTabPage
        $ParentTabPage.Controls.Add($NewGroupBox)
        # Return the output
        $NewGroupBox
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}

### END OF FUNCTION
####################################################################################################

