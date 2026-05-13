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
        [System.Windows.Forms.TabPage]$ParentTabPage,

        [Parameter(Mandatory=$false,HelpMessage='The GroupBox above which this Feature will be added.')]
        [System.Windows.Forms.GroupBox]$GroupBoxAbove
    )

    try {
        # Feature properties
        [System.Collections.Hashtable]$FeatureProperties = @{
            InputObject     = $InputObject
            ParentTabPage   = $ParentTabPage
            Title           = 'APPS'
            Color           = 'Yellow'
            NumberOfRows    = 4
        }
        # If the GroupBoxAbove parameter is provided, set the GroupBoxAbove property
        if ($PSBoundParameters.ContainsKey('GroupBoxAbove')) { $FeatureProperties.GroupBoxAbove = $GroupBoxAbove }

        # Create the GroupBox
        [System.Windows.Forms.GroupBox]$FeatureGroupBox = New-GroupBox @FeatureProperties

        # Set the Button properties
        [System.Collections.Hashtable[]]$ButtonPropertiesArray1 = @(
            @{
                ColumnNumber    = 1
                Text            = 'Add/Remove Programs'
                PNGFileName     = 'application_view_icons.png'
                SizeType        = 'Large'
                ToolTip         = 'Open the Add/Remove Programs window to add or remove programs from your computer'
                Function        = { Start-Process control.exe appwiz.cpl }
            },
            @{
                ColumnNumber    = 2
                Text            = 'Task Manager'
                PNGFileName     = 'system_monitor'
                SizeType        = 'Large'
                ToolTip         = 'Open the Task Manager window'
                Function        = { Start-Process taskmgr.exe }
            },
            @{
                ColumnNumber    = 3
                Text            = 'Cmd'
                PNGFileName     = 'application_xp_terminal.png'
                SizeType        = 'Large'
                ToolTip         = 'Open the Command Prompt window'
                Function        = { Start-Process cmd.exe }
            },
            @{
                ColumnNumber    = 4
                Text            = 'PowerShell'
                PNGFileName     = 'powershell'
                SizeType        = 'Large'
                ToolTip         = 'Open the PowerShell window'
                Function        = { Start-Process powershell.exe }
            },
            @{
                ColumnNumber    = 5
                Text            = 'PowerShell ISE'
                PNGFileName     = 'powershell'
                SizeType        = 'Large'
                ToolTip         = 'Open the PowerShell ISE window'
                Function        = { Start-Process powershell_ise.exe }
            }
        )

        # Set the Button properties
        [System.Collections.Hashtable[]]$ButtonPropertiesArray2 = @(
            @{
                ColumnNumber    = 1
                Text            = 'Event Viewer'
                PNGFileName     = 'book'
                SizeType        = 'Large'
                ToolTip         = 'Open the Event Viewer window'
                Function        = { Start-Process mmc.exe eventvwr.msc }
            },
            @{
                ColumnNumber    = 2
                Text            = 'Services'
                PNGFileName     = 'cog.png'
                SizeType        = 'Large'
                ToolTip         = 'Open the Services window to manage system services'
                Function        = { Start-Process mmc.exe services.msc }
            },
            @{
                ColumnNumber    = 3
                Text            = 'Cmd (Admin)'
                PNGFileName     = 'application_xp_terminal'
                SizeType        = 'Large'
                ToolTip         = 'Open the Command Prompt window as Administrator'
                Function        = { Start-Process cmd.exe -Verb RunAs }
            },
            @{
                ColumnNumber    = 4
                Text            = 'PowerShell (Admin)'
                PNGFileName     = 'powershell'
                SizeType        = 'Large'
                ToolTip         = 'Open the PowerShell window as Administrator'
                Function        = { Start-Process powershell.exe -Verb RunAs }
            },
            @{
                ColumnNumber    = 5
                Text            = 'PowerShell ISE (Admin)'
                PNGFileName     = 'powershell'
                SizeType        = 'Large'
                ToolTip         = 'Open the PowerShell ISE window as Administrator'
                Function        = { Start-Process powershell_ise.exe -Verb RunAs }
            }
        )

        # Add the Buttons
        New-ButtonLine -InputObject $InputObject -ButtonPropertiesArray $ButtonPropertiesArray1 -ParentGroupBox $FeatureGroupBox -RowNumber 1
        New-ButtonLine -InputObject $InputObject -ButtonPropertiesArray $ButtonPropertiesArray2 -ParentGroupBox $FeatureGroupBox -RowNumber 3

        # Return the GroupBox object
        $FeatureGroupBox
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}

### END OF FUNCTION
####################################################################################################
