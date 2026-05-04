#
# Module 'UI.Graphics.Tab.psm1'
# Last Update: May 2026
#

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

        # Add the MainTabControl Width to the MainTabControl settings based on the MainForm dimensions and the MainTabControl margins
        $MainTabControl.Width   = $MainForm.Width - $MainTabControl.LeftMargin - $MainTabControl.RightMargin
        # Add the MainTabControl Height to the MainTabControl settings based on the MainForm dimensions and the MainTabControl margins
        $MainTabControl.Height  = $MainForm.Height - $MainTabControl.TopMargin - $MainTabControl.BottomMargin
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
    This function creates the MainTabControl.
.DESCRIPTION
    This function is part of the Application Delivery Assistant. It contains functions and variables that are in other files.
.EXAMPLE
    Invoke-MainTabControl -ParentForm $Global:MainForm -ApplicationObject $Global:ApplicationObject
.INPUTS
    [System.Windows.Forms.Form]
    [PSCustomObject]
.OUTPUTS
    This function returns no stream output.
.NOTES
    Version         : 6.0.0.0
    Author          : Imraan Iotana
    Creation Date   : May 2026
    Last Update     : May 2026
#>
####################################################################################################
function Invoke-MainTabControl {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The main object of the application, which contains all the properties and settings.')]
        [PSCustomObject]$InputObject,

        [Parameter(Mandatory=$true,HelpMessage='The Parent object to which this tabcontrol will be added.')]
        [System.Windows.Forms.Form]
        $ParentForm
    )

    try {
        # PREPARATION
        # Get the settings from the input object
        [System.Collections.Hashtable]$Settings = $InputObject.Settings

        # Create the Global MainTabControl
        [System.Windows.Forms.TabControl]$Global:MainTabControl = $NewTabControl = New-Object System.Windows.Forms.TabControl

        # Set the Location property
        [System.Int32[]]$Location   = @($Settings.MainTabControl.TopLeftX, $Settings.MainTabControl.TopLeftY)
        $NewTabControl.Location     = New-Object System.Drawing.Point($Location)

        # Set the Size property
        [System.Int32[]]$Size       = @($Settings.MainTabControl.Width, $Settings.MainTabControl.Height)
        $NewTabControl.Size         = New-Object System.Drawing.Size($Size)

        $NewTabControl.Dock         = 'Fill'

        # Add the TabControl to the ParentForm
        $ParentForm.Controls.Add($NewTabControl)
        if ($ParentForm.MainMenuStrip) {
            # Ensure dock order keeps the menubar above the tab headers
            $ParentForm.Controls.SetChildIndex($NewTabControl, 0)
        }
    }
    catch {
        Write-FullError -ErrorRecord $_
    }
}

### END OF SCRIPT
####################################################################################################
