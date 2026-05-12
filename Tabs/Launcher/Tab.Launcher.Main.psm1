#
# Module 'Tab.Launcher.Main.psm1'
# Last Update: May 2026
#

####################################################################################################
<#
.SYNOPSIS
    Imports the Launcher tab into the main application.
.DESCRIPTION
    This function imports the Launcher tab into the main application by creating a new TabPage and adding it to the specified parent TabControl.
.EXAMPLE
    Import-TabLauncher -ParentTabControl $Global:MainTabControl
.INPUTS
    [System.Windows.Forms.TabControl]
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
function Import-TabLauncher {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The ApplicationObject containing the Settings.')]
        [PSCustomObject]$InputObject,

        [Parameter(Mandatory=$true,HelpMessage='The Parent TabControl to which this TabPage will be added.')]
        [System.Windows.Forms.TabControl]$ParentTabControl
    )


    try {
        # Tab properties
        [System.Collections.Hashtable]$TabProperties = @{
            ParentTabControl    = $ParentTabControl
            Title               = 'LAUNCHER'
            Version             = '6.0.0.0'
            BackGroundColor     = 'ForestGreen'
        }

        # Create the TabPage
        [System.Windows.Forms.TabPage]$ParentTabPage = New-TabPage @TabProperties

        # Import the Features
        Import-FeatureSystemFolderLauncher -InputObject $InputObject -ParentTabPage $ParentTabPage
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
    Imports the System Folder feature into the Launcher tab.
.DESCRIPTION
    This function imports the System Folder feature into the Launcher tab by creating a new GroupBox and adding it to the specified parent TabPage.
.EXAMPLE
    Import-FeatureSystemFolderLauncher -InputObject $Global:ApplicationObject -ParentTabPage $MyTabPage
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
function Import-FeatureSystemFolderLauncher {
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
            Title           = 'SYSTEM FOLDERS'
            Color           = 'White'
            NumberOfRows    = 4
        }

        # Create the GroupBox
        [System.Windows.Forms.GroupBox]$SystemFolderGroupBox = New-GroupBox @FeatureProperties

        # Set the Button properties
        [System.Collections.Hashtable[]]$ButtonProperties = @(
            @{
                ParentGroupBox  = $SystemFolderGroupBox
                SizeType        = 'Large'
                Text            = 'Program Files (64bit)'
                PNGFileName     = '64_bit.png'
                ColumnNumber    = 1
                Function        = { Open-Folder -Path 'C:\Program Files' }
            },
            @{
                ParentGroupBox  = $SystemFolderGroupBox
                SizeType        = 'Large'
                Text            = 'Program Files (32bit)'
                PNGFileName     = '32_bit.png'
                ColumnNumber    = 2
                Function        = { Open-Folder -Path 'C:\Program Files (x86)' }
            },
            @{
                ParentGroupBox  = $SystemFolderGroupBox
                SizeType        = 'Large'
                Text            = 'ProgramData'
                PNGFileName     = 'folder_page.png'
                ColumnNumber    = 3
                Function        = { Open-Folder -Path 'C:\ProgramData' }
            },
            @{
                ParentGroupBox  = $SystemFolderGroupBox
                SizeType        = 'Large'
                Text            = 'Windows'
                PNGFileName     = 'folder_wrench.png'
                ColumnNumber    = 4
                Function        = { Open-Folder -Path 'C:\Windows' }
            }
        )

        # Add the Buttons
        foreach ($Button in $ButtonProperties) {
            Invoke-Button -InputObject $InputObject @Button
        }
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}

### END OF FUNCTION
####################################################################################################
