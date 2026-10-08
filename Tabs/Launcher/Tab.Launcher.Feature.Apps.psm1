####################################################################################################
<#
.SYNOPSIS
    Imports the Application Launcher feature into the Launcher tab.
.DESCRIPTION
    This function imports the Application Launcher feature into the Launcher tab by creating a new GroupBox and adding it to the specified parent TabPage.
.EXAMPLE
    Import-FeatureAppLauncher -InputObject $MyApplicationObject -ParentTabPage $MyTabPage
.INPUTS
    [PSCustomObject]
    [System.Windows.Forms.TabPage]
    [System.Windows.Forms.GroupBox]
    [System.String]
.OUTPUTS
    [System.Windows.Forms.GroupBox]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.1.0
    Author          : Imraan Iotana
    Creation Date   : May 2026
    Last Update     : July 2026
#>
####################################################################################################
function Import-FeatureAppLauncher {
    [CmdletBinding()]
    [OutputType([System.Windows.Forms.GroupBox])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The ApplicationObject containing the Settings.')]
        [PSCustomObject]$InputObject,

        [Parameter(Mandatory=$true,HelpMessage='The Parent TabPage to which this Feature will be added.')]
        [System.Windows.Forms.TabPage]$ParentTabPage,

        [Parameter(Mandatory=$false,HelpMessage='The GroupBox underneath which this Feature will be added.')]
        [System.Windows.Forms.GroupBox]$GroupBoxAbove,

        [Parameter(Mandatory=$false,HelpMessage='The color of the GroupBox.')]
        [System.String]$Color
    )

    try {
        # PREPARATION - GROUPBOX PROPERTIES
        # Set the GroupBox properties
        [System.Collections.Hashtable]$GroupBoxProperties = @{
            InputObject     = $InputObject
            ParentTabPage   = $ParentTabPage
            Title           = 'APPS'
            Color           = $Color
            NumberOfRows    = 4
            GroupBoxAbove   = $GroupBoxAbove
        }

        # EXECUTION - GROUPBOX
        # Create the GroupBox
        [System.Windows.Forms.GroupBox]$FeatureGroupBox = New-GroupBox @GroupBoxProperties

        # PREPARATION - BUTTON PROPERTIES
        # Set the Button properties
        [System.Collections.Hashtable[]]$ButtonPropertiesArray1 = @(
            @{
                ColumnNumber    = 1
                Text            = 'Add/Remove Programs'
                PNGFileName     = 'application_view_icons'
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
                Text            = 'Event Viewer'
                PNGFileName     = 'book'
                SizeType        = 'Large'
                ToolTip         = 'Open the Event Viewer window'
                Function        = { Start-Process mmc.exe eventvwr.msc }
            },
            @{
                ColumnNumber    = 4
                Text            = 'Services'
                PNGFileName     = 'cog'
                SizeType        = 'Large'
                ToolTip         = 'Open the Services window to manage system services'
                Function        = { Start-Process mmc.exe services.msc }
            },
            @{
                ColumnNumber    = 5
                Text            = 'Certificates (Current User)'
                PNGFileName     = 'ssl_certificates'
                SizeType        = 'Large'
                ToolTip         = 'Open Current User Certificate Manager without elevation'
                Function        = { Open-CurrentUserCertificateManager }
            }
        )
        [System.Collections.Hashtable[]]$ButtonPropertiesArray2 = @(
            @{
                ColumnNumber    = 1
                Text            = 'Task Scheduler'
                PNGFileName     = 'clock_go'
                SizeType        = 'Large'
                ToolTip         = 'Open the Task Scheduler window to manage scheduled tasks'
                Function        = { Start-Process taskschd.msc }
            },
            @{
                ColumnNumber    = 2
                Text            = 'Snipping Tool'
                PNGFileName     = 'camera_add'
                SizeType        = 'Large'
                ToolTip         = 'Open the Snipping Tool to capture screenshots'
                Function        = { Start-Process snippingtool.exe }
            }
            @{
                ColumnNumber    = 3
                Text            = 'Computer Management'
                PNGFileName     = 'computer'
                SizeType        = 'Large'
                ToolTip         = 'Open the Computer Management window to manage system settings'
                Function        = { Start-Process compmgmt.msc }
            },
            @{
                ColumnNumber    = 4
                Text            = 'User Management'
                PNGFileName     = 'user'
                SizeType        = 'Large'
                ToolTip         = 'Open the User Management window to manage user accounts'
                Function        = { Start-Process lusrmgr.msc }
            },
            @{
                ColumnNumber    = 5
                Text            = 'Certificates (Local Computer)'
                PNGFileName     = 'ssl_certificates'
                SizeType        = 'Large'
                ToolTip         = 'Open Local Computer Certificate Manager with administrator access'
                Function        = { Open-LocalComputerCertificateManagerAsAdministrator }
            }
        )

        # EXECUTION - BUTTONS
        # Create the Buttons
        New-ButtonLine -InputObject $InputObject -ButtonPropertiesArray $ButtonPropertiesArray1 -ParentGroupBox $FeatureGroupBox -RowNumber 1
        New-ButtonLine -InputObject $InputObject -ButtonPropertiesArray $ButtonPropertiesArray2 -ParentGroupBox $FeatureGroupBox -RowNumber 3

        # POST-EXECUTION
        # Return the GroupBox object
        $FeatureGroupBox
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}

### END OF FUNCTION
####################################################################################################
