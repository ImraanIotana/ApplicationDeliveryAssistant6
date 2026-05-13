#
# Module 'Tab.Launcher.Apps.psm1'
# Last Update: May 2026
#

####################################################################################################
<#
.SYNOPSIS
    Imports the Application Launcher feature into the Launcher tab.
.DESCRIPTION
    This function imports the Application Launcher feature into the Launcher tab by creating a new GroupBox and adding it to the specified parent TabPage.
.EXAMPLE
    Import-FeatureAppLauncher -InputObject $Global:ApplicationObject -ParentTabPage $MyTabPage
.INPUTS
    [PSCustomObject]
    [System.Windows.Forms.TabPage]
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
function Import-FeatureAppLauncher {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The ApplicationObject containing the Settings.')]
        [PSCustomObject]$InputObject,

        [Parameter(Mandatory=$true,HelpMessage='The Parent TabPage to which this Feature will be added.')]
        [System.Windows.Forms.TabPage]$ParentTabPage
    )

    try {
        # Feature properties
        [System.Collections.Hashtable]$FeatureProperties = @{
            InputObject     = $InputObject
            ParentTabPage   = $ParentTabPage
            Title           = 'APPLICATION LAUNCHER'
            Color           = 'Yellow'
            NumberOfRows    = 4
        }

        # Create the GroupBox
        [System.Windows.Forms.GroupBox]$Global:AppLauncherGroupBox = New-GroupBox @FeatureProperties

        # Set the Button properties
        [System.Collections.Hashtable[]]$ButtonPropertiesArray1 = @(
            @{
                ColumnNumber    = 1
                Text            = 'Add/Remove Programs'
                PNGFileName     = 'application_view_list.png'
                SizeType        = 'Large'
                Function        = { Start-Process control.exe appwiz.cpl }
            },
            @{
                ColumnNumber    = 2
                Text            = 'Services'
                PNGFileName     = 'cog.png'
                SizeType        = 'Large'
                Function        = { Start-Process mmc.exe services.msc }
            },
            @{
                ColumnNumber    = 3
                Text            = 'Cmd'
                PNGFileName     = 'application_xp_terminal.png'
                SizeType        = 'Large'
                Function        = { Start-Process cmd.exe }
            },
            @{
                ColumnNumber    = 4
                Text            = 'PowerShell'
                PNGFileName     = 'PowerShell.png'
                SizeType        = 'Large'
                Function        = { Start-Process powershell.exe }
            },
            @{
                ColumnNumber    = 5
                Text            = 'PowerShell ISE'
                PNGFileName     = 'PowerShell.png'
                SizeType        = 'Large'
                Function        = { Start-Process powershell_ise.exe }
            }
        )

        # Set the Button properties
        [System.Collections.Hashtable[]]$ButtonPropertiesArray2 = @(
            @{
                ColumnNumber    = 1
                Text            = 'Task Manager'
                PNGFileName     = 'system_monitor.png'
                SizeType        = 'Large'
                Function        = { Start-Process taskmgr.exe }
            },
            @{
                ColumnNumber    = 2
                Text            = 'Event Viewer'
                PNGFileName     = 'book.png'
                SizeType        = 'Large'
                Function        = { Start-Process mmc.exe eventvwr.msc }
            },
            @{
                ColumnNumber    = 3
                Text            = 'Cmd (Admin)'
                PNGFileName     = 'application_xp_terminal.png'
                SizeType        = 'Large'
                Function        = { Start-Process cmd.exe -Verb RunAs }
            },
            @{
                ColumnNumber    = 4
                Text            = 'PowerShell (Admin)'
                PNGFileName     = 'PowerShell.png'
                SizeType        = 'Large'
                Function        = { Start-Process powershell.exe -Verb RunAs }
            },
            @{
                ColumnNumber    = 5
                Text            = 'PowerShell ISE (Admin)'
                PNGFileName     = 'PowerShell.png'
                SizeType        = 'Large'
                Function        = { Start-Process powershell_ise.exe -Verb RunAs }
            }
        )

        # Add the Buttons
        New-ButtonLine -InputObject $InputObject -ButtonPropertiesArray $ButtonPropertiesArray1 -ParentGroupBox $Global:AppLauncherGroupBox -RowNumber 1
        New-ButtonLine -InputObject $InputObject -ButtonPropertiesArray $ButtonPropertiesArray2 -ParentGroupBox $Global:AppLauncherGroupBox -RowNumber 3
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}

### END OF FUNCTION
####################################################################################################
