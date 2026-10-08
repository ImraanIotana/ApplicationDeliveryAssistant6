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
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.1
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
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.1
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
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.1
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
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.1
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
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.1
    Author          : Imraan Iotana
    Creation Date   : June 2026
    Last Update     : July 2026
#>
####################################################################################################
function Enable-TabControlHighlightStyle {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The TabControl to style.')]
        [System.Windows.Forms.TabControl]$TabControl
    )

    try {
        Initialize-TabControlHighlightState -TabControl $TabControl

        # Configure owner draw once to avoid duplicate DrawItem handlers
        if ($TabControl.DrawMode -ne [System.Windows.Forms.TabDrawMode]::OwnerDrawFixed) {
            $TabControl.DrawMode = [System.Windows.Forms.TabDrawMode]::OwnerDrawFixed
            $TabControl.Add_DrawItem({
                param ($DrawSender, $DrawEventArgs)

                # Resolve context for the tab being painted
                [System.Windows.Forms.TabPage]$CurrentTabPage = $DrawSender.TabPages[$DrawEventArgs.Index]
                [System.Drawing.Rectangle]$TabBounds = $DrawEventArgs.Bounds
                [System.Boolean]$IsSelected = ($DrawSender.SelectedIndex -eq $DrawEventArgs.Index)

                # Apply visual palette per selected/unselected state
                [System.Drawing.Color]$BackColor = if ($IsSelected) { Get-TabControlHighlightColor -TabControl $DrawSender -TabPage $CurrentTabPage } else { [System.Drawing.Color]::Gainsboro }
                [System.Drawing.Color]$TextColor = if ($IsSelected) { Get-TabControlFontColor -TabControl $DrawSender -TabPage $CurrentTabPage } else { [System.Drawing.Color]::Navy }

                [System.Drawing.SolidBrush]$BackgroundBrush = New-Object System.Drawing.SolidBrush($BackColor)
                [System.Windows.Forms.TextFormatFlags]$TextFlags = [System.Windows.Forms.TextFormatFlags]::HorizontalCenter -bor [System.Windows.Forms.TextFormatFlags]::VerticalCenter -bor [System.Windows.Forms.TextFormatFlags]::SingleLine -bor [System.Windows.Forms.TextFormatFlags]::EndEllipsis

                try {
                    # Paint tab background and centered caption text
                    $DrawEventArgs.Graphics.FillRectangle($BackgroundBrush, $TabBounds)
                    [System.Windows.Forms.TextRenderer]::DrawText($DrawEventArgs.Graphics, $CurrentTabPage.Text, $DrawSender.Font, $TabBounds, $TextColor, $TextFlags)

                    # Draw a stronger border for the active tab and subtle edge lines for inactive tabs
                    if ($IsSelected) {
                        $DrawEventArgs.Graphics.DrawRectangle([System.Drawing.Pens]::DarkGray, $TabBounds.X, $TabBounds.Y, $TabBounds.Width - 1, $TabBounds.Height - 1)
                    }
                    else {
                        # For unselected tabs, avoid a full rectangle to prevent harsh bottom seams
                        $DrawEventArgs.Graphics.DrawLine([System.Drawing.Pens]::Gray, $TabBounds.X, $TabBounds.Y, $TabBounds.Right - 1, $TabBounds.Y)
                        if ($DrawEventArgs.Index -eq 0) {
                            $DrawEventArgs.Graphics.DrawLine([System.Drawing.Pens]::Gray, $TabBounds.X, $TabBounds.Y, $TabBounds.X, $TabBounds.Bottom - 2)
                        }
                        if ($DrawEventArgs.Index -eq ($DrawSender.TabPages.Count - 1)) {
                            $DrawEventArgs.Graphics.DrawLine([System.Drawing.Pens]::Gray, $TabBounds.Right - 1, $TabBounds.Y, $TabBounds.Right - 1, $TabBounds.Bottom - 2)
                        }
                        $DrawEventArgs.Graphics.DrawLine([System.Drawing.Pens]::Gainsboro, $TabBounds.X, $TabBounds.Bottom - 1, $TabBounds.Right - 1, $TabBounds.Bottom - 1)
                    }

                    # Keep keyboard focus cues visible for accessibility
                    if ($IsSelected -and $DrawSender.Focused) { $DrawEventArgs.DrawFocusRectangle() }
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


####################################################################################################
<#
.SYNOPSIS
    Applies the selected-tab highlight color to a TabControl and refreshes it.
.DESCRIPTION
    This function ensures the highlight style is enabled, stores the selected highlight color on the
    TabControl Tag, and invalidates the control so the new color is repainted immediately.
.EXAMPLE
    Set-TabControlHighlightColor -TabControl $Global:MainTabControl -ColorName 'Moccasin'
.INPUTS
    [System.Windows.Forms.TabControl]
    [System.String]
.OUTPUTS
    No objects are returned to the pipeline.
#>
####################################################################################################
function Set-TabControlHighlightColor {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The TabControl to update.')]
        [System.Windows.Forms.TabControl]$TabControl,

        [Parameter(Mandatory=$false,HelpMessage='The selected-tab highlight color name.')]
        [System.String]$ColorName = 'Moccasin'
    )

    try {
        Enable-TabControlHighlightStyle -TabControl $TabControl
        Initialize-TabControlHighlightState -TabControl $TabControl -DefaultColorName $ColorName
        $TabControl.Tag.SelectedTabHighlightColor = $ColorName
        Update-TabControlHighlightRendering -TabControl $TabControl
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
    Applies the selected-tab font color to a TabControl and refreshes it.
.DESCRIPTION
    This function ensures the highlight style is enabled, stores the selected font color on the
    TabControl Tag, and invalidates the control so the new color is repainted immediately.
.EXAMPLE
    Set-TabControlFontColor -TabControl $Global:MainTabControl -ColorName 'Navy'
.INPUTS
    [System.Windows.Forms.TabControl]
    [System.String]
.OUTPUTS
    No objects are returned to the pipeline.
#>
####################################################################################################
function Set-TabControlFontColor {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The TabControl to update.')]
        [System.Windows.Forms.TabControl]$TabControl,

        [Parameter(Mandatory=$false,HelpMessage='The selected-tab font color name.')]
        [System.String]$ColorName = 'Navy'
    )

    try {
        Enable-TabControlHighlightStyle -TabControl $TabControl
        Initialize-TabControlHighlightState -TabControl $TabControl -DefaultFontColorName $ColorName
        $TabControl.Tag.SelectedTabFontColor = $ColorName
        Update-TabControlHighlightRendering -TabControl $TabControl
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
    Connects a ComboBox to the main and sub-tab highlight colors.
.DESCRIPTION
    This helper applies the current ComboBox value to the main/root TabControl and all descendant
    TabControls, and keeps them in sync whenever the ComboBox selection changes.
.EXAMPLE
    Register-TabHighlightColorComboBox -ComboBox $ThemeColorComboBox -MainTabControl $Global:MainTabControl
.INPUTS
    [System.Windows.Forms.ComboBox]
    [System.Windows.Forms.TabControl]
.OUTPUTS
    No objects are returned to the pipeline.
#>
####################################################################################################
function Register-TabHighlightColorComboBox {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The ComboBox that provides the highlight color.')]
        [System.Windows.Forms.ComboBox]$ComboBox,

        [Parameter(Mandatory=$true,HelpMessage='The main/root TabControl to update.')]
        [System.Windows.Forms.TabControl]$MainTabControl,

        [Parameter(Mandatory=$false,HelpMessage='Fallback color used when the ComboBox has no value.')]
        [System.String]$DefaultColorName = 'Moccasin'
    )

    try {
        [System.Windows.Forms.TabControl[]]$TargetTabControls = @(Get-RelatedTabControls -MainTabControl $MainTabControl)

        [System.String]$InitialTabHighlightColor = if (Test-String -IsPopulated $ComboBox.Text) { $ComboBox.Text } else { $DefaultColorName }
        foreach ($TabControl in $TargetTabControls) {
            Set-TabControlHighlightColor -TabControl $TabControl -ColorName $InitialTabHighlightColor
        }

        if ($null -eq $ComboBox.Tag) { $ComboBox.Tag = [PSCustomObject]@{} }
        if (-not ($ComboBox.Tag.PSObject.Properties.Name -contains 'TabHighlightColorComboBoxRegistered')) {
            $ComboBox.Tag | Add-Member -MemberType NoteProperty -Name TabHighlightColorComboBoxRegistered -Value $false
        }

        if ($ComboBox.Tag.TabHighlightColorComboBoxRegistered) {
            return
        }

        $ComboBox.Add_SelectedIndexChanged([System.EventHandler]{
            param($ChangedControl, $ChangedEvent)

            [System.String]$SelectedTabHighlightColor = if (Test-String -IsPopulated $ChangedControl.Text) {
                $ChangedControl.Text
            }
            else {
                $DefaultColorName
            }

            foreach ($TabControl in $TargetTabControls) {
                Set-TabControlHighlightColor -TabControl $TabControl -ColorName $SelectedTabHighlightColor
            }
        }.GetNewClosure())

        $ComboBox.Tag.TabHighlightColorComboBoxRegistered = $true
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
    Connects a ComboBox to the main and sub-tab selected font colors.
.DESCRIPTION
    This helper applies the current ComboBox value to the main/root TabControl and all descendant
    TabControls, and keeps them in sync whenever the ComboBox selection changes.
.EXAMPLE
    Register-TabFontColorComboBox -ComboBox $ThemeFontColorComboBox -MainTabControl $Global:MainTabControl
.INPUTS
    [System.Windows.Forms.ComboBox]
    [System.Windows.Forms.TabControl]
.OUTPUTS
    No objects are returned to the pipeline.
#>
####################################################################################################
function Register-TabFontColorComboBox {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The ComboBox that provides the selected-tab font color.')]
        [System.Windows.Forms.ComboBox]$ComboBox,

        [Parameter(Mandatory=$true,HelpMessage='The main/root TabControl to update.')]
        [System.Windows.Forms.TabControl]$MainTabControl,

        [Parameter(Mandatory=$false,HelpMessage='Fallback color used when the ComboBox has no value.')]
        [System.String]$DefaultColorName = 'Navy'
    )

    try {
        [System.Windows.Forms.TabControl[]]$TargetTabControls = @(Get-RelatedTabControls -MainTabControl $MainTabControl)

        [System.String]$InitialTabFontColor = if (Test-String -IsPopulated $ComboBox.Text) { $ComboBox.Text } else { $DefaultColorName }
        foreach ($TabControl in $TargetTabControls) {
            Set-TabControlFontColor -TabControl $TabControl -ColorName $InitialTabFontColor
        }

        if ($null -eq $ComboBox.Tag) { $ComboBox.Tag = [PSCustomObject]@{} }
        if (-not ($ComboBox.Tag.PSObject.Properties.Name -contains 'TabFontColorComboBoxRegistered')) {
            $ComboBox.Tag | Add-Member -MemberType NoteProperty -Name TabFontColorComboBoxRegistered -Value $false
        }

        if ($ComboBox.Tag.TabFontColorComboBoxRegistered) {
            return
        }

        $ComboBox.Add_SelectedIndexChanged([System.EventHandler]{
            param($ChangedControl, $ChangedEvent)

            [System.String]$SelectedTabFontColor = if (Test-String -IsPopulated $ChangedControl.Text) {
                $ChangedControl.Text
            }
            else {
                $DefaultColorName
            }

            foreach ($TabControl in $TargetTabControls) {
                Set-TabControlFontColor -TabControl $TabControl -ColorName $SelectedTabFontColor
            }
        }.GetNewClosure())

        $ComboBox.Tag.TabFontColorComboBoxRegistered = $true
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}

### END OF FUNCTION
####################################################################################################
