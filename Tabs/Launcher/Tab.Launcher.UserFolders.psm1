####################################################################################################
<#
.SYNOPSIS
    Imports the User Folder feature into the Launcher tab.
.DESCRIPTION
    This function imports the User Folder feature into the Launcher tab by creating a new GroupBox and adding it to the specified parent TabPage.
.EXAMPLE
    Import-FeatureUserFolderLauncher -InputObject $MyApplicationObject -ParentTabPage $MyTabPage
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
function Import-FeatureUserFolderLauncher {
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
            Title           = 'USER FOLDERS'
            Color           = 'Lime'
            NumberOfRows    = 2
        }
        # If the GroupBoxAbove parameter is provided, set the GroupBoxAbove property
        if ($PSBoundParameters.ContainsKey('GroupBoxAbove')) { $FeatureProperties.GroupBoxAbove = $GroupBoxAbove }

        # Create the GroupBox
        [System.Windows.Forms.GroupBox]$FeatureGroupBox = New-GroupBox @FeatureProperties

        # Set the Button properties
        [System.Collections.Hashtable[]]$ButtonPropertiesArray1 = @(
            @{
                ColumnNumber    = 1
                Text            = 'Roaming Profile'
                PNGFileName     = 'folder_user'
                SizeType        = 'Large'
                Function        = { Open-Folder -Path $ENV:APPDATA }
            },
            @{
                ColumnNumber    = 2
                Text            = 'Local Profile'
                PNGFileName     = 'folder_table'
                SizeType        = 'Large'
                Function        = { Open-Folder -Path $ENV:LOCALAPPDATA }
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
                Text            = 'Downloads'
                PNGFileName     = 'download'
                SizeType        = 'Large'
                Function        = { Open-Folder -Path "$ENV:USERPROFILE\Downloads" }
            },
            @{
                ColumnNumber    = 5
                Text            = 'Temp'
                PNGFileName     = 'folder_torn'
                SizeType        = 'Large'
                Function        = { Open-Folder -Path $ENV:TEMP }
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
