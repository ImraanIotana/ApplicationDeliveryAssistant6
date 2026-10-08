####################################################################################################
<#
.SYNOPSIS
    Returns the nesting depth of a TabPage within TabControl containers.
.DESCRIPTION
    This function walks up the Parent chain and counts how many parent TabPage layers
    exist above the provided TabPage.
    Depth meanings:
    - 0: TabPage belongs to the main/root TabControl
    - 1: First-level sub-tab
    - 2: Second-level sub-tab
.EXAMPLE
    Get-TabPageDepth -TabPage $ParentTabPage
.INPUTS
    [System.Windows.Forms.TabPage]
.OUTPUTS
    [System.Int32]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.1
    Author          : Imraan Iotana
    Creation Date   : July 2026
    Last Update     : July 2026
#>
####################################################################################################
function Get-TabPageDepth {
    [CmdletBinding()]
    [OutputType([System.Int32])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The TabPage to inspect for nesting depth.')]
        [System.Windows.Forms.TabPage]$TabPage
    )

    try {
        # PREPARATION
        # Initialize depth tracking from the current TabPage
        [System.Int32]$Depth = 0
        [System.Windows.Forms.TabPage]$CurrentTabPage = $TabPage

        # EXECUTION
        # Walk upward through parent controls while the chain remains TabPage -> TabControl -> TabPage
        while ($true) {
            if ($null -eq $CurrentTabPage.Parent -or $CurrentTabPage.Parent -isnot [System.Windows.Forms.TabControl]) {
                break
            }

            [System.Windows.Forms.Control]$OwnerControl = $CurrentTabPage.Parent.Parent
            if ($OwnerControl -is [System.Windows.Forms.TabPage]) {
                $Depth++
                $CurrentTabPage = [System.Windows.Forms.TabPage]$OwnerControl
                continue
            }

            break
        }

        # RETURN
        # Return the resolved nesting depth
        $Depth
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
    Ensures a TabControl has highlight color state initialized.
.DESCRIPTION
    This function creates the Tag object when needed and guarantees that the
    SelectedTabHighlightColor note property exists with a valid fallback value.
.EXAMPLE
    Initialize-TabControlHighlightState -TabControl $Global:MainTabControl
.INPUTS
    [System.Windows.Forms.TabControl]
    [System.String]
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.1
    Author          : Imraan Iotana
    Creation Date   : July 2026
    Last Update     : July 2026
#>
####################################################################################################
function Initialize-TabControlHighlightState {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The TabControl to initialize.')]
        [System.Windows.Forms.TabControl]$TabControl,

        [Parameter(Mandatory=$false,HelpMessage='Fallback selected-tab highlight color name.')]
        [System.String]$DefaultColorName = 'Moccasin',

        [Parameter(Mandatory=$false,HelpMessage='Fallback selected-tab font color name.')]
        [System.String]$DefaultFontColorName = 'Navy'
    )

    try {
        # PREPARATION
        # Ensure the Tag container exists
        if ($null -eq $TabControl.Tag) {
            $TabControl.Tag = [PSCustomObject]@{}
        }

        # EXECUTION
        # Add the SelectedTabHighlightColor property when it is missing
        if (-not ($TabControl.Tag.PSObject.Properties.Name -contains 'SelectedTabHighlightColor')) {
            $TabControl.Tag | Add-Member -MemberType NoteProperty -Name SelectedTabHighlightColor -Value $DefaultColorName
        }

        # Add the SelectedTabFontColor property when it is missing
        if (-not ($TabControl.Tag.PSObject.Properties.Name -contains 'SelectedTabFontColor')) {
            $TabControl.Tag | Add-Member -MemberType NoteProperty -Name SelectedTabFontColor -Value $DefaultFontColorName
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
    Resolves the selected-tab highlight color for a TabControl.
.DESCRIPTION
    This function reads the configured highlight color name from TabControl Tag state
    and returns a valid Color object. If the configured color is 'Match Active Tab Background' and
    a TabPage is provided, returns that TabPage's BackColor. Falls back to Moccasin when the stored
    value is missing or invalid.
.EXAMPLE
    Get-TabControlHighlightColor -TabControl $Global:MainTabControl
    Get-TabControlHighlightColor -TabControl $Global:MainTabControl -TabPage $CurrentTab
.INPUTS
    [System.Windows.Forms.TabControl]
    [System.Windows.Forms.TabPage]
    [System.String]
.OUTPUTS
    [System.Drawing.Color]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.1
    Author          : Imraan Iotana
    Creation Date   : July 2026
    Last Update     : July 2026
#>
####################################################################################################
function Get-TabControlHighlightColor {
    [CmdletBinding()]
    [OutputType([System.Drawing.Color])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The TabControl to inspect.')]
        [System.Windows.Forms.TabControl]$TabControl,

        [Parameter(Mandatory=$false,HelpMessage='The TabPage for dynamic color matching.')]
        [System.Windows.Forms.TabPage]$TabPage,

        [Parameter(Mandatory=$false,HelpMessage='Fallback selected-tab highlight color name.')]
        [System.String]$DefaultColorName = 'Moccasin'
    )

    try {
        # PREPARATION
        # Ensure highlight state has been initialized before resolving the configured color
        Initialize-TabControlHighlightState -TabControl $TabControl -DefaultColorName $DefaultColorName

        # EXECUTION
        # Convert the stored color name into a Color object
        [System.String]$SelectedTabHighlightColorName = [System.String]$TabControl.Tag.SelectedTabHighlightColor

        # Check for automatic matching mode
        if ($SelectedTabHighlightColorName -eq 'Automatic' -and $null -ne $TabPage) {
            return $TabPage.BackColor
        }

        [System.Drawing.Color]$SelectedTabHighlightColor = [System.Drawing.Color]::FromName($SelectedTabHighlightColorName)

        # RETURN
        # Fallback to the default configured color when the selected value is unknown
        if (-not ($SelectedTabHighlightColor.IsKnownColor -or $SelectedTabHighlightColor.IsNamedColor)) {
            return [System.Drawing.Color]::FromName($DefaultColorName)
        }

        $SelectedTabHighlightColor
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
    Resolves the selected-tab font color for a TabControl.
.DESCRIPTION
    This function reads the configured font color name from TabControl Tag state and returns a valid
    Color object. If the configured color is 'Match Active Tab Font Color' and a TabPage is provided,
    attempts to derive a readable font color from that TabPage's BackColor. Falls back to Navy when
    the stored value is missing or invalid.
.EXAMPLE
    Get-TabControlFontColor -TabControl $Global:MainTabControl
    Get-TabControlFontColor -TabControl $Global:MainTabControl -TabPage $CurrentTab
.INPUTS
    [System.Windows.Forms.TabControl]
    [System.Windows.Forms.TabPage]
    [System.String]
.OUTPUTS
    [System.Drawing.Color]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.1
    Author          : Imraan Iotana
    Creation Date   : July 2026
    Last Update     : July 2026
#>
####################################################################################################
function Get-TabControlFontColor {
    [CmdletBinding()]
    [OutputType([System.Drawing.Color])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The TabControl to inspect.')]
        [System.Windows.Forms.TabControl]$TabControl,

        [Parameter(Mandatory=$false,HelpMessage='The TabPage for dynamic color matching.')]
        [System.Windows.Forms.TabPage]$TabPage,

        [Parameter(Mandatory=$false,HelpMessage='Fallback selected-tab font color name.')]
        [System.String]$DefaultColorName = 'Navy'
    )

    try {
        # PREPARATION
        # Ensure highlight state has been initialized before resolving the configured font color
        Initialize-TabControlHighlightState -TabControl $TabControl -DefaultFontColorName $DefaultColorName

        # EXECUTION
        # Convert the stored font color name into a Color object
        [System.String]$SelectedTabFontColorName = [System.String]$TabControl.Tag.SelectedTabFontColor

        # Check for automatic matching mode
        if ($SelectedTabFontColorName -eq 'Automatic' -and $null -ne $TabPage) {
            # Derive a readable font color using perceived luminance for better contrast
            [System.Drawing.Color]$TabBackColor = $TabPage.BackColor
            [System.Double]$Luminance =
                (0.299 * [System.Double]$TabBackColor.R) +
                (0.587 * [System.Double]$TabBackColor.G) +
                (0.114 * [System.Double]$TabBackColor.B)
            # Use light text on darker backgrounds, dark text on lighter backgrounds
            if ($Luminance -lt 150.0) {
                return [System.Drawing.Color]::White
            }
            else {
                return [System.Drawing.Color]::Black
            }
        }

        [System.Drawing.Color]$SelectedTabFontColor = [System.Drawing.Color]::FromName($SelectedTabFontColorName)

        # RETURN
        # Fallback to the default configured font color when the selected value is unknown
        if (-not ($SelectedTabFontColor.IsKnownColor -or $SelectedTabFontColor.IsNamedColor)) {
            return [System.Drawing.Color]::FromName($DefaultColorName)
        }

        $SelectedTabFontColor
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
    Repaints a TabControl after highlight color changes.
.DESCRIPTION
    This function invalidates individual tab header rectangles and then refreshes the
    entire TabControl so the selected highlight color is rendered immediately.
.EXAMPLE
    Update-TabControlHighlightRendering -TabControl $Global:MainTabControl
.INPUTS
    [System.Windows.Forms.TabControl]
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.1
    Author          : Imraan Iotana
    Creation Date   : July 2026
    Last Update     : July 2026
#>
####################################################################################################
function Update-TabControlHighlightRendering {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The TabControl to repaint.')]
        [System.Windows.Forms.TabControl]$TabControl
    )

    try {
        # PREPARATION
        # No preparation required beyond parameter validation
        # EXECUTION - INVALIDATE TAB RECTS
        # Invalidate each tab header rectangle to repaint selected and unselected tab visuals
        if ($TabControl.TabPages.Count -gt 0) {
            foreach ($TabIndex in 0..($TabControl.TabPages.Count - 1)) {
                [System.Drawing.Rectangle]$TabBounds = $TabControl.GetTabRect($TabIndex)
                if ($TabBounds.Width -gt 0 -and $TabBounds.Height -gt 0) {
                    $TabControl.Invalidate($TabBounds)
                }
            }
        }

        # EXECUTION - REFRESH CONTROL
        # Force a complete repaint cycle
        $TabControl.Invalidate()
        $TabControl.Update()
        $TabControl.Refresh()
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
    Returns descendant TabControls under a root control.
.DESCRIPTION
    This function walks the Controls tree recursively and returns all child TabControl
    instances under the provided root control. The root control itself is not included.
.EXAMPLE
    Get-DescendantTabControls -RootControl $Global:MainTabControl
.INPUTS
    [System.Windows.Forms.Control]
.OUTPUTS
    [System.Windows.Forms.TabControl[]]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.1
    Author          : Imraan Iotana
    Creation Date   : July 2026
    Last Update     : July 2026
#>
####################################################################################################
function Get-DescendantTabControls {
    [CmdletBinding()]
    [OutputType([System.Windows.Forms.TabControl[]])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The root control to inspect.')]
        [System.Windows.Forms.Control]$RootControl
    )

    try {
        # PREPARATION
        # Create a strongly typed list to collect discovered descendant tab controls
        [System.Collections.Generic.List[System.Windows.Forms.TabControl]]$TabControls = New-Object 'System.Collections.Generic.List[System.Windows.Forms.TabControl]'

        # EXECUTION
        # Traverse all child controls recursively
        foreach ($ChildControl in $RootControl.Controls) {
            if ($ChildControl -is [System.Windows.Forms.TabControl]) {
                [void]$TabControls.Add([System.Windows.Forms.TabControl]$ChildControl)
            }

            if ($ChildControl.Controls.Count -gt 0) {
                foreach ($NestedTabControl in @(Get-DescendantTabControls -RootControl $ChildControl)) {
                    [void]$TabControls.Add($NestedTabControl)
                }
            }
        }

        # RETURN
        # Return discovered descendant tab controls as an array
        $TabControls.ToArray()
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
    Resolves all related TabControls for a root TabControl.
.DESCRIPTION
    This function returns the main/root TabControl plus all descendant TabControls beneath it.
.EXAMPLE
    Get-RelatedTabControls -MainTabControl $Global:MainTabControl
.INPUTS
    [System.Windows.Forms.TabControl]
.OUTPUTS
    [System.Windows.Forms.TabControl[]]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.1
    Author          : Imraan Iotana
    Creation Date   : July 2026
    Last Update     : July 2026
#>
####################################################################################################
function Get-RelatedTabControls {
    [CmdletBinding()]
    [OutputType([System.Windows.Forms.TabControl[]])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The main/root TabControl to inspect.')]
        [System.Windows.Forms.TabControl]$MainTabControl
    )

    try {
        # PREPARATION
        # Create a strongly typed list that includes the root control first
        [System.Collections.Generic.List[System.Windows.Forms.TabControl]]$TargetTabControls = New-Object 'System.Collections.Generic.List[System.Windows.Forms.TabControl]'
        [void]$TargetTabControls.Add($MainTabControl)

        # EXECUTION
        # Add all descendant TabControls while avoiding duplicate root insertion
        foreach ($TabControl in @(Get-DescendantTabControls -RootControl $MainTabControl)) {
            if ($TabControl -eq $MainTabControl) {
                continue
            }
            [void]$TargetTabControls.Add($TabControl)
        }

        # RETURN
        # Return all related tab controls as an array
        $TargetTabControls.ToArray()
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}

### END OF FUNCTION
####################################################################################################
