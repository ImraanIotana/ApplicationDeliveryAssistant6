#
# Module 'Tab.Launcher.UserFolders.psm1'
# Last Update: May 2026
#

####################################################################################################
<#
.SYNOPSIS
    Imports the User Folder feature into the Launcher tab.
.DESCRIPTION
    This function imports the User Folder feature into the Launcher tab by creating a new GroupBox and adding it to the specified parent TabPage.
.EXAMPLE
    Import-FeatureUserFolderLauncher -InputObject $Global:ApplicationObject -ParentTabPage $MyTabPage
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
function Import-FeatureRegistryLauncher {
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
            Title           = 'REGISTRY'
            Color           = 'Cyan'
            NumberOfRows    = 2
        }
        # If the GroupBoxAbove parameter is provided, set the GroupBoxAbove property
        if ($PSBoundParameters.ContainsKey('GroupBoxAbove')) { $FeatureProperties.GroupBoxAbove = $GroupBoxAbove }

        # Create the Feature GroupBox
        [System.Windows.Forms.GroupBox]$FeatureGroupBox = New-GroupBox @FeatureProperties

        # Set the Button properties
        [System.Collections.Hashtable[]]$ButtonPropertiesArray1 = @(
            @{
                ColumnNumber    = 1
                Text            = 'Program Files (64bit)'
                PNGFileName     = '64_bit.png'
                SizeType        = 'Large'
                Function        = { Open-Folder -Path 'C:\Program Files' }
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

        # Add the Buttons
        New-ButtonLine -InputObject $InputObject -ButtonPropertiesArray $ButtonPropertiesArray1 -ParentGroupBox $FeatureGroupBox -RowNumber 1

        # Return the GroupBox object
        $FeatureGroupBox
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}

### END OF FUNCTION
####################################################################################################
