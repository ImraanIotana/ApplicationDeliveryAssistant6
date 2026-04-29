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
    Initialize-MainForm
    Creates the main form of the application and sets its properties, but does not show it.
.INPUTS
    [PSCustomObject]
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

function Initialize-MainForm {
    [CmdletBinding()]
    [OutputType([System.Void])]
    param (
        [Parameter(Mandatory=$false,HelpMessage='The main object of the application, which contains all the properties and settings.')]
        [PSCustomObject]$InputObject = $Global:ApplicationObject
    )

    # Get the graphical settings from the main object
    [System.Collections.Hashtable]$Settings = $InputObject.GraphicalSettings

    # Create a new Form
    [System.Windows.Forms.Form]$NewForm = New-Object System.Windows.Forms.Form

    # Set the properties of the Main Form
    $NewForm.Text               = "$($InputObject.Name) - Version $($InputObject.Version)"
    $NewForm.StartPosition      = 'CenterScreen'
    $NewForm.Size               = New-Object System.Drawing.Size($Settings.MainForm.Width,$Settings.MainForm.Height)

    # Set the Window Buttons
    $NewForm.MinimizeBox        = $true
    $NewForm.MaximizeBox        = $false

    # Set the Form Border Style
    $NewForm.FormBorderStyle    = 'FixedSingle'

    # Set the Main Icon
    $NewForm.Icon               = $Settings.MainIcon

    # Create the Global Main Form variable
    [System.Windows.Forms.Form]$Global:MainForm = $NewForm
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    This function shows the main form of the application.
.DESCRIPTION
    This function shows the main form of the application. It displays the form that was created and configured by the Initialize-MainForm function.
.EXAMPLE
    Show-MainForm
    Displays the main form of the application.
.INPUTS
    None.
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

function Show-MainForm {
    [CmdletBinding()]
    [OutputType([System.Void])]
    param (
        [Parameter(Mandatory=$false,HelpMessage='The main form of the application.')]
        [System.Windows.Forms.Form]$FormToShow = $Global:MainForm
    )
    # Show the main form
    $null = $FormToShow.ShowDialog()
}

### END OF FUNCTION
####################################################################################################
