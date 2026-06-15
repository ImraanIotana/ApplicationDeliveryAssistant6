####################################################################################################
<#
.SYNOPSIS
    Imports the System Folder feature into the Launcher tab.
.DESCRIPTION
    This function imports the System Folder feature into the Launcher tab by creating a new GroupBox and adding it to the specified parent TabPage.
.EXAMPLE
    Import-FeatureSystemFolderLauncher -InputObject $MyApplicationObject -ParentTabPage $MyTabPage
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
        [System.Windows.Forms.TabPage]$ParentTabPage,

        [Parameter(Mandatory=$false,HelpMessage='The GroupBox above which this Feature will be added.')]
        [System.Windows.Forms.GroupBox]$GroupBoxAbove
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
        # If the GroupBoxAbove parameter is provided, set the GroupBoxAbove property
        if ($PSBoundParameters.ContainsKey('GroupBoxAbove')) { $FeatureProperties.GroupBoxAbove = $GroupBoxAbove }

        # Create the GroupBox
        [System.Windows.Forms.GroupBox]$FeatureGroupBox = New-GroupBox @FeatureProperties

        # Set the Button properties
        [System.Collections.Hashtable[]]$ButtonPropertiesArray1 = @(
            @{
                ColumnNumber    = 1
                Text            = 'Program Files (64bit)'
                PNGFileName     = '64_bit'
                SizeType        = 'Large'
                Function        = { Open-Folder -Path $ENV:ProgramW6432 }
            },
            @{
                ColumnNumber    = 2
                Text            = 'Program Files (32bit)'
                PNGFileName     = '32_bit'
                SizeType        = 'Large'
                Function        = { Open-Folder -Path ${ENV:ProgramFiles(x86)} }
            },
            @{
                ColumnNumber    = 3
                Text            = 'ProgramData'
                PNGFileName     = 'folder_page'
                SizeType        = 'Large'
                Function        = { Open-Folder -Path $ENV:PROGRAMDATA }
            },
            @{
                ColumnNumber    = 4
                Text            = 'Windows'
                PNGFileName     = 'folder_table'
                SizeType        = 'Large'
                Function        = { Open-Folder -Path $ENV:WINDIR }
            },
            @{
                ColumnNumber    = 5
                Text            = 'Windows Temp'
                PNGFileName     = 'folder_torn'
                SizeType        = 'Large'
                Function        = { Open-Folder -Path "$ENV:WINDIR\Temp" }
            }
        )

        # Set the Button properties
        [System.Collections.Hashtable[]]$ButtonPropertiesArray2 = @(
            @{
                ColumnNumber    = 1
                Text            = 'Fonts'
                PNGFileName     = 'font'
                SizeType        = 'Large'
                Function        = { Open-Folder -Path "$ENV:WINDIR\Fonts" }
            },
            @{
                ColumnNumber    = 2
                Text            = 'Drivers'
                PNGFileName     = 'printer'
                SizeType        = 'Large'
                Function        = { Open-Folder -Path "$ENV:WINDIR\System32\DriverStore\FileRepository" }
            },
            @{
                ColumnNumber    = 3
                Text            = 'Output Folder'
                PNGFileName     = 'folder_table'
                SizeType        = 'Large'
                Function        = { Open-Folder -Path (Get-OutputFolder) }
            },
            @{
                ColumnNumber    = 4
                Text            = 'Software Library'
                PNGFileName     = 'cd'
                SizeType        = 'Large'
                Function        = { Open-Folder -Path (Get-SoftwareLibraryFolder) }
            },
            @{
                ColumnNumber    = 5
                Text            = 'SCCM Cache'
                PNGFileName     = 'folder_brick'
                SizeType        = 'Large'
                Function        = { Open-Folder -Path "$ENV:WINDIR\ccmcache" }
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
