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
    [System.Windows.Forms.GroupBox]
    [System.String]
.OUTPUTS
    [System.Windows.Forms.GroupBox]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.8.0
    Author          : Imraan Iotana
    Creation Date   : May 2026
    Last Update     : September 2026
#>
####################################################################################################
function Import-FeatureSystemFolderLauncher {
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
            Title           = 'SYSTEM FOLDERS'
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
                Text            = 'Start Menu'
                PNGFileName     = 'application_side_tree'
                SizeType        = 'Large'
                Function        = { Open-Folder -Path ([System.Environment]::GetFolderPath('CommonPrograms')) }
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
                Text            = 'Software Library'
                PNGFileName     = 'cd'
                SizeType        = 'Large'
                Function        = { Open-Folder -Path (Get-Folder -SoftwareLibrary) }
            },
            @{
                ColumnNumber    = 4
                Text            = 'Package Cache'
                PNGFileName     = 'package_go'
                SizeType        = 'Large'
                Function        = { Open-Folder -Path (Join-Path $ENV:ProgramData -ChildPath 'Package Cache') }
            },
            @{
                ColumnNumber    = 5
                Text            = 'SCCM Cache'
                PNGFileName     = 'folder_brick'
                SizeType        = 'Large'
                Function        = { Open-Folder -Path "$ENV:WINDIR\ccmcache" }
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
