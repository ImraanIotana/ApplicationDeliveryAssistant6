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
function Add-MainTabControlDimensions {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false,HelpMessage='The ApplicationObject containing the settings.')]
        [PSCustomObject]$InputObject
    )

    try {
        # Get the MainForm settings
        [System.Collections.Hashtable]$MainForm         = $InputObject.GraphicalSettings.MainForm
        # Get the MainTabControl settings
        [System.Collections.Hashtable]$MainTabControl   = $InputObject.GraphicalSettings.MainTabControl

        # EXECUTION - ADD LOCATION
        # Add the MainTabControl Location
        $MainTabControl.TopLeftX    = $MainTabControl.LeftMargin
        $MainTabControl.TopLeftY    = $MainTabControl.TopMargin
        $MainTabControl.Location    = New-Object System.Drawing.Point($MainTabControl.TopLeftX, $MainTabControl.TopLeftY)

        # EXECUTION - ADD SIZE
        # Add the MainTabControl Size to the MainTabControl settings based on the MainForm dimensions and the MainTabControl margins
        $MainTabControl.Width       = $MainForm.Width - $MainTabControl.LeftMargin - $MainTabControl.RightMargin
        $MainTabControl.Height      = $MainForm.Height - $MainTabControl.TopMargin - $MainTabControl.BottomMargin
        $MainTabControl.Size        = New-Object System.Drawing.Size($MainTabControl.Width, $MainTabControl.Height)
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
    Creates the MainTabControl and adds it to the MainForm.
.DESCRIPTION
    This function creates the MainTabControl based on the settings in the GraphicalSettings hashtable of the main object, and adds it to the MainForm.
.EXAMPLE
    Add-MainTabControl -InputObject $MyApplicationObject -ParentForm $Global:MainForm
.INPUTS
    [PSCustomObject]
    [System.Windows.Forms.Form]
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
function Add-MainTabControl {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The ApplicationObject containing the Settings.')]
        [PSCustomObject]$InputObject,

        [Parameter(Mandatory=$true,HelpMessage='The Parent object to which this tabcontrol will be added.')]
        [System.Windows.Forms.Form]
        $ParentForm
    )

    try {
        # PREPARATION
        # Create a new TabControl
        [System.Windows.Forms.TabControl]$NewTabControl = New-Object System.Windows.Forms.TabControl
        # Get the graphical settings from the main object
        [System.Collections.Hashtable]$Settings         = $InputObject.GraphicalSettings
        # Set the TabControl Location
        $NewTabControl.Location                         = $Settings.MainTabControl.Location
        # Set the TabControl Size
        $NewTabControl.Size                             = $Settings.MainTabControl.Size

        # EXECUTION - CREATE THE GLOBAL MAIN TAB CONTROL VARIABLE
        # Add the TabControl to the ParentForm
        $ParentForm.Controls.Add($NewTabControl)
        # Create the Global MainTabControl variable and set it to the new TabControl
        [System.Windows.Forms.TabControl]$Global:MainTabControl = $NewTabControl
    }
    catch {
        Write-FullError -ErrorRecord $_
    }
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Creates a new SubTabControl and adds it to the specified ParentTabPage.
.DESCRIPTION
    This function creates a new SubTabControl based on the settings in the GraphicalSettings hashtable of the main object, and adds it to the specified ParentTabPage.
.EXAMPLE
    New-SubTabControl -ParentTabPage $Global:ParentTabPage
.INPUTS
    [System.Windows.Forms.TabPage]
    [PSCustomObject]
.OUTPUTS
    No objects are returned to the pipeline. All output is written to the host.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. All rights reserved.
    Version         : 6.0.0.0
    Author          : Imraan Iotana
    Creation Date   : October 2023
    Last Update     : May 2026
#>
####################################################################################################
function New-SubTabControl {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The ApplicationObject containing the Settings.')]
        [PSCustomObject]$InputObject,

        [Parameter(Mandatory=$true,HelpMessage='The Parent TabPage to which this tabcontrol will be added.')]
        [System.Windows.Forms.TabPage]$ParentTabPage
    )

    try {
        # PREPARATION
        # Create a new SubTabControl
        [System.Windows.Forms.TabControl]$NewSubTabControl = New-Object System.Windows.Forms.TabControl
        # Get the graphical settings from the main object
        [System.Collections.Hashtable]$Settings = $InputObject.GraphicalSettings

        # PREPARATION - SET LOCATION
        # Set the Location property
        [System.Int32[]]$Location   = @(0,0)
        $NewSubTabControl.Location  = New-Object System.Drawing.Point($Location)

        # PREPARATION - SET SIZE
        # Set the Size property
        [System.Int32]$Width        = $Settings.MainForm.Width - $Settings.MainTabControl.RightMargin
        [System.Int32]$Height       = $Settings.MainForm.Height - $Settings.MainTabControl.BottomMargin
        [System.Int32[]]$Size       = @($Width, $Height)
        $NewSubTabControl.Size      = New-Object System.Drawing.Size($Size)

        # EXECUTION - ADD THE SUBTABCONTROL TO THE PARENT TABPAGE
        # Add the TabControl to the ParentTabPage
        $ParentTabPage.Controls.Add($NewSubTabControl)
    }
    catch {
        Write-FullError
    }
    # Return the output
    $NewSubTabControl

}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    This function creates a new TabPage.
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
function New-TabPage {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The Parent TabControl to which this TabPage will be added.')]
        [System.Windows.Forms.TabControl]$ParentTabControl,

        [Parameter(Mandatory=$true,HelpMessage='The title of the TabPage.')]
        [System.String]$Title,

        [Parameter(Mandatory=$true,HelpMessage='The version of the TabPage.')]
        [System.String]$Version,

        [Parameter(Mandatory=$false,HelpMessage='The color of the TabPage.')]
        [System.String]$BackGroundColor
    )

    try {
        # PREPARATION
        # Write the message
        if ($Version) { Write-Line "Importing Tab $Title $Version" }

        # Ensure selected tabs are visually highlighted
        Enable-TabControlHighlightStyle -TabControl $ParentTabControl

        # EXECUTION - CREATE THE TABPAGE
        # Create a new TabPage
        [System.Windows.Forms.TabPage]$NewTabPage = New-Object System.Windows.Forms.TabPage

        # EXECUTION - SET PROPERTIES
        # Set the Title of the TabPage
        $NewTabPage.Text = $Title
        # Set the BackGroundColor if provided
        if ($BackGroundColor) { $NewTabPage.BackColor = $BackGroundColor }

        # EXECUTION - ADD THE TABPAGE TO THE PARENT TABCONTROL
        # Add the TabPage to the Parent TabControl
        $ParentTabControl.Controls.Add($NewTabPage)

        # EXECUTION - RETURN THE NEW TABPAGE
        # Return the output
        $NewTabPage
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
    Enables custom tab-header coloring for a TabControl.
.DESCRIPTION
    This function configures a TabControl for owner-draw and paints selected/unselected tabs using different colors.
.EXAMPLE
    Enable-TabControlHighlightStyle -TabControl $Global:MainTabControl
.INPUTS
    [System.Windows.Forms.TabControl]
.OUTPUTS
    No objects are returned to the pipeline. All output is written to the host.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. All rights reserved.
    Version         : 6.0.0.0
    Author          : Imraan Iotana
    Creation Date   : June 2026
    Last Update     : June 2026
#>
####################################################################################################
function Enable-TabControlHighlightStyle {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The TabControl to style.')]
        [System.Windows.Forms.TabControl]$TabControl
    )

    try {
        # Configure owner draw once to avoid duplicate DrawItem handlers
        if ($TabControl.DrawMode -ne [System.Windows.Forms.TabDrawMode]::OwnerDrawFixed) {
            $TabControl.DrawMode = [System.Windows.Forms.TabDrawMode]::OwnerDrawFixed
            $TabControl.Add_DrawItem({
                param ($Sender, $EventArgs)

                [System.Windows.Forms.TabPage]$CurrentTabPage = $Sender.TabPages[$EventArgs.Index]
                [System.Drawing.Rectangle]$TabBounds = $EventArgs.Bounds
                [System.Boolean]$IsSelected = ($Sender.SelectedIndex -eq $EventArgs.Index)

                [System.Drawing.Color]$BackColor = if ($IsSelected) { [System.Drawing.Color]::White } else { [System.Drawing.Color]::Gainsboro }
                [System.Drawing.Color]$TextColor = if ($IsSelected) { [System.Drawing.Color]::Black } else { [System.Drawing.Color]::DimGray }

                [System.Drawing.SolidBrush]$BackgroundBrush = New-Object System.Drawing.SolidBrush($BackColor)
                [System.Windows.Forms.TextFormatFlags]$TextFlags = [System.Windows.Forms.TextFormatFlags]::HorizontalCenter -bor [System.Windows.Forms.TextFormatFlags]::VerticalCenter -bor [System.Windows.Forms.TextFormatFlags]::SingleLine -bor [System.Windows.Forms.TextFormatFlags]::EndEllipsis

                try {
                    $EventArgs.Graphics.FillRectangle($BackgroundBrush, $TabBounds)
                    [System.Windows.Forms.TextRenderer]::DrawText($EventArgs.Graphics, $CurrentTabPage.Text, $Sender.Font, $TabBounds, $TextColor, $TextFlags)
                    if ($IsSelected) {
                        $EventArgs.Graphics.DrawRectangle([System.Drawing.Pens]::DarkGray, $TabBounds.X, $TabBounds.Y, $TabBounds.Width - 1, $TabBounds.Height - 1)
                    }
                    else {
                        # For unselected tabs, avoid a full rectangle to prevent harsh bottom seams.
                        $EventArgs.Graphics.DrawLine([System.Drawing.Pens]::Gray, $TabBounds.X, $TabBounds.Y, $TabBounds.Right - 1, $TabBounds.Y)
                        if ($EventArgs.Index -eq 0) {
                            $EventArgs.Graphics.DrawLine([System.Drawing.Pens]::Gray, $TabBounds.X, $TabBounds.Y, $TabBounds.X, $TabBounds.Bottom - 2)
                        }
                        if ($EventArgs.Index -eq ($Sender.TabPages.Count - 1)) {
                            $EventArgs.Graphics.DrawLine([System.Drawing.Pens]::Gray, $TabBounds.Right - 1, $TabBounds.Y, $TabBounds.Right - 1, $TabBounds.Bottom - 2)
                        }
                        $EventArgs.Graphics.DrawLine([System.Drawing.Pens]::Gainsboro, $TabBounds.X, $TabBounds.Bottom - 1, $TabBounds.Right - 1, $TabBounds.Bottom - 1)
                    }
                    if ($IsSelected -and $Sender.Focused) { $EventArgs.DrawFocusRectangle() }
                }
                finally {
                    $BackgroundBrush.Dispose()
                }
            })
        }
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}

### END OF FUNCTION
####################################################################################################
