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
            Color           = 'White'
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
                Text            = 'Program Files (32bit)'
                PNGFileName     = '32_bit.png'
                SizeType        = 'Large'
                Function        = { Open-Folder -Path 'C:\Program Files (x86)' }
            },
            @{
                ColumnNumber    = 3
                Text            = 'ProgramData'
                PNGFileName     = 'folder_page.png'
                SizeType        = 'Large'
                Function        = { Open-Folder -Path 'C:\ProgramData' }
            },
            @{
                ColumnNumber    = 4
                Text            = 'Windows'
                PNGFileName     = 'folder_wrench.png'
                SizeType        = 'Large'
                Function        = { Open-Folder -Path 'C:\Windows' }
            },
            @{
                ColumnNumber    = 5
                Text            = 'SCCM Cache'
                PNGFileName     = 'package_link.png'
                SizeType        = 'Large'
                Function        = { Open-Folder -Path 'C:\Windows\ccmcache' }
            }
        )

        # Set the Button properties
        [System.Collections.Hashtable[]]$ButtonPropertiesArray2 = @(
            @{
                ColumnNumber    = 4
                Text            = 'Fonts'
                PNGFileName     = 'font.png'
                SizeType        = 'Large'
                Function        = { Open-Folder -Path 'C:\Windows\Fonts' }
            },
            @{
                ColumnNumber    = 5
                Text            = 'Drivers'
                PNGFileName     = 'printer.png'
                SizeType        = 'Large'
                Function        = { Open-Folder -Path 'C:\Windows\System32\DriverStore\FileRepository' }
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
