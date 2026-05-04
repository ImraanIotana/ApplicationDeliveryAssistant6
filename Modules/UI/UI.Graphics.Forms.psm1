#
# Module 'UI.Graphics.Forms.psm1'
# Last Update: April 2026
#

####################################################################################################
<#
.SYNOPSIS
    This function creates the main form of the application.
.DESCRIPTION
    This function creates the main form of the application. It sets the properties of the form, including size, position, and window buttons.
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
    Last Update     : May 2026
#>
####################################################################################################
function Initialize-MainForm {
    [CmdletBinding()]
    [OutputType([System.Void])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The main object of the application, which contains all the properties and settings.')]
        [PSCustomObject]$InputObject
    )

    try {
        # PREPARATION
        # Get the graphical settings from the main object
        [System.Collections.Hashtable]$Settings = $InputObject.GraphicalSettings
        # Set the form properties
        [System.String]$FormTitle           = "$($InputObject.Name) - Version $($InputObject.Version)"
        [System.Drawing.Size]$FormSize      = New-Object System.Drawing.Size($Settings.MainForm.Width, $Settings.MainForm.Height)
        # Create a new Form Object
        [System.Windows.Forms.Form]$NewForm = New-Object System.Windows.Forms.Form
        # Set the properties of the new Form
        [System.Collections.Hashtable]$FormProperties = @{
            Text            = $FormTitle
            Size            = $FormSize
            StartPosition   = 'CenterScreen'
            MinimizeBox     = $true
            MaximizeBox     = $false
            FormBorderStyle = 'FixedSingle'
            Icon            = $Settings.MainIcon
        }

        # EXECUTION - APPLY THE PROPERTIES TO THE NEW FORM OBJECT
        # Apply the properties to the new Form Object
        $FormProperties.GetEnumerator() | ForEach-Object { $NewForm.$($_.Key) = $_.Value }
        # Create the Global Main Form variable and assign the new Form to it
        [System.Windows.Forms.Form]$Global:MainForm = $NewForm
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
    Last Update     : May 2026
#>
####################################################################################################
function Show-MainForm {
    [CmdletBinding()]
    [OutputType([System.Void])]
    param (
        [Parameter(Mandatory=$false,HelpMessage='The main form of the application.')]
        [System.Windows.Forms.Form]$FormToShow = $Global:MainForm
    )

    try {
        # PREPARATION
        # Stop the load timer and report elapsed time
        Stop-LoadTimer
        # Write the welcome message
        Write-WelcomeMessage

        # EXECUTION - SHOW THE MAIN FORM
        # Show the main form
        $null = $FormToShow.ShowDialog()
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}

### END OF FUNCTION
####################################################################################################
