#
# Module 'UI.Graphics.Forms.psm1'
# Last Update: April 2026
#

####################################################################################################
<#
.SYNOPSIS
    This function creates and manages the main form of the application.
.DESCRIPTION
    This function creates and manages the main form of the application. It sets the properties of the form, including size, position, and window buttons.
.EXAMPLE
    Invoke-MainForm
    Creates the main form of the application and sets its properties, but does not show it.
.EXAMPLE
    Invoke-MainForm -Show
    Displays the main form of the application.
.INPUTS
    [PSCustomObject]
    [System.Management.Automation.SwitchParameter]
.OUTPUTS
    No objects are returned to the pipeline. All output is written to the host.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. All rights reserved.
    Version         : 6.0.0.0
    Author          : Imraan Iotana
    Creation Date   : April 2026
    Last Update     : April 2026
#>
####################################################################################################

function Invoke-MainForm {
    [CmdletBinding()]
    [OutputType([System.Void])]
    param (
        [Parameter(Mandatory=$false,HelpMessage='The main object of the application, which contains all the properties and settings.')]
        [PSCustomObject]$InputObject = $Global:ApplicationObject,

        [Parameter(Mandatory=$false,HelpMessage='Switch for showing the main form.')]
        [System.Management.Automation.SwitchParameter]$Show
    )

    # If the Show switch is present, then show the main form, otherwise create the main form and set its properties
    if ($Show.IsPresent) {

        # Show the main form
        $null = $Global:MainForm.ShowDialog()

    } else {

        # Get the graphical settings from the main object
        [System.Collections.Hashtable]$Settings = $InputObject.GraphicalSettings

        # Create the Global Main Form
        [System.Windows.Forms.Form]$Global:MainForm = $GMF = New-Object System.Windows.Forms.Form

        # Set the properties of the Main Form
        $GMF.Text               = "$($InputObject.Name) - Version $($InputObject.Version)"
        $GMF.StartPosition      = 'CenterScreen'
        $GMF.Size               = New-Object System.Drawing.Size($Settings.MainForm.Width,$Settings.MainForm.Height)

        # Set the Window Buttons
        $GMF.MinimizeBox        = $true
        $GMF.MaximizeBox        = $false

        # Set the Form Border Style
        $GMF.FormBorderStyle    = 'FixedSingle'

    }
}

### END OF FUNCTION
####################################################################################################
