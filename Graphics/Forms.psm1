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
        [PSCustomObject]$Object = $Global:ApplicationObject,

        [Parameter(Mandatory=$false,HelpMessage='Switch for showing the main form.')]
        [System.Management.Automation.SwitchParameter]$Show
    )
    
    begin {
        
    }
    
    process {
        if ($Show.IsPresent) {
            # Show the main form
            $null = $Global:MainForm.ShowDialog()
        } else {
            # Create the Global Main Form
            [System.Windows.Forms.Form]$Global:MainForm = $NewForm = New-Object System.Windows.Forms.Form
            # Set the properties of the Main Form
            $NewForm.Text = ('{0} - Version {1}' -f $Object.Name,$Object.Version)
            $NewForm.StartPosition = 'CenterScreen'
            $NewForm.Size = New-Object System.Drawing.Size(1200,800)
            $NewForm.MinimumSize = New-Object System.Drawing.Size(1000,600)
        }
    }
    
    end {
        
    }
}