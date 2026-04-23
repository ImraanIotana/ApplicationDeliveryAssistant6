#
# Module 'Forms.psm1'
# Last Update: April 2026
#

####################################################################################################
<#
.SYNOPSIS
    Copies a file or folder to a specified destination folder, with the option to force overwrite.
.DESCRIPTION
    This function copies a file or folder to a specified destination folder. It supports both files and folders, and can force overwrite existing items.
    It also provides options to return the output and write the output to the host.
.EXAMPLE
    Copy-ItemUDF -ThisFile "C:\Source\File.txt" -IntoThisFolder "C:\Destination" -OutHost
    Copies the specified file to the destination folder and writes the output to the host.
.INPUTS
    [System.String]
    [System.Management.Automation.SwitchParameter]
.OUTPUTS
    [System.Boolean]
    A boolean value indicating whether the copy operation was successful, returned when using -PassThru
.NOTES
    This script is part of the Universal Deployment Framework. Copyright (C) Iotana. All rights reserved.
    Version         : 6.0.0.0
    Author          : Imraan Iotana
    Creation Date   : April 2026
    Last Update     : April 2026
#>
####################################################################################################

function Invoke-MainForm {
    [CmdletBinding()]
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
        #$GMF.MinimizeBox        = $true
        #$GMF.MaximizeBox        = $false

        # Set the Form Border Style
        #$GMF.FormBorderStyle    = 'FixedSingle'

    }
}