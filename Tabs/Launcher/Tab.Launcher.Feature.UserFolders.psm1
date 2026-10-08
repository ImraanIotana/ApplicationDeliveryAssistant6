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
function Import-FeatureUserFolderLauncher {
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
            Title           = 'USER FOLDERS'
            Color           = $Color
            NumberOfRows    = 2
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
                Text            = 'User Roaming Profile'
                PNGFileName     = 'folder_user'
                SizeType        = 'Large'
                Function        = { Open-Folder -Path $ENV:APPDATA }
            },
            @{
                ColumnNumber    = 2
                Text            = 'User Local Profile'
                PNGFileName     = 'folder_table'
                SizeType        = 'Large'
                Function        = { Open-Folder -Path $ENV:LOCALAPPDATA }
            },
            @{
                ColumnNumber    = 3
                Text            = 'Output Folder'
                PNGFileName     = 'folder_go'
                SizeType        = 'Large'
                Function        = { Open-Folder -Path (Get-Folder -OutputFolder) }
            },
            @{
                ColumnNumber    = 4
                Text            = 'Start Menu'
                PNGFileName     = 'application_side_tree'
                SizeType        = 'Large'
                Function        = { Open-Folder -Path ([System.Environment]::GetFolderPath('Programs')) }
            },
            @{
                ColumnNumber    = 5
                Text            = 'User Temp'
                PNGFileName     = 'folder_torn'
                SizeType        = 'Large'
                Function        = { Open-Folder -Path $ENV:TEMP }
            }
        )

        # EXECUTION - BUTTONS
        # Create the Buttons
        New-ButtonLine -InputObject $InputObject -ButtonPropertiesArray $ButtonPropertiesArray1 -ParentGroupBox $FeatureGroupBox -RowNumber 1

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
