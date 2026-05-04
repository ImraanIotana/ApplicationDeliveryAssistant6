#
# Module 'UI.Graphics.Tab.psm1'
# Last Update: April 2026
#

####################################################################################################
<#
.SYNOPSIS
    This function creates the MainTabControl.
.DESCRIPTION
    This function is part of the Packaging Assistant. It contains functions and variables that are in other files.
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

    ####################################################################################################
    ### MAIN PROPERTIES ###

    # Input
    [System.Collections.Hashtable]$Settings = $InputObject.Settings

    # Create the MainTabControl
    [System.Windows.Forms.TabControl]$Global:MainTabControl = $NewTabControl = New-Object System.Windows.Forms.TabControl


    ####################################################################################################

    try {
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
