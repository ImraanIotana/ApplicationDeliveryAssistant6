####################################################################################################
<#
.SYNOPSIS
    Imports the AppLocker Settings feature into the AppLocker Settings tab.
.DESCRIPTION
    This function imports the AppLocker Settings feature into the AppLocker Settings tab by creating a new GroupBox and adding it to the specified parent TabPage.
.EXAMPLE
    Import-FeatureAppLockerSettings -InputObject $MyApplicationObject -ParentTabPage $MyTabPage
.INPUTS
    [PSCustomObject]
    [System.Windows.Forms.TabPage]
    [System.Windows.Forms.GroupBox]
    [System.String]
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. All rights reserved.
    Version         : 6.0.0.0
    Author          : Imraan Iotana
    Creation Date   : May 2026
    Last Update     : June 2026
#>
####################################################################################################
function Import-FeatureAppLockerSettings {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The ApplicationObject containing the Settings.')]
        [PSCustomObject]$InputObject,

        [Parameter(Mandatory=$true,HelpMessage='The Parent TabPage to which this Feature will be added.')]
        [System.Windows.Forms.TabPage]$ParentTabPage,

        [Parameter(Mandatory=$false,HelpMessage='The GroupBox above which this Feature will be added.')]
        [System.Windows.Forms.GroupBox]$GroupBoxAbove,

        [Parameter(Mandatory=$false,HelpMessage='The color of the GroupBox.')]
        [System.String]$Color
    )

    try {
        # EXECUTION - GROUPBOX
        # Feature properties
        [System.Collections.Hashtable]$FeatureProperties = @{
            InputObject     = $InputObject
            ParentTabPage   = $ParentTabPage
            Title           = 'APPLOCKER SETTINGS'
            Color           = $Color
            NumberOfRows    = 5
            GroupBoxAbove   = $GroupBoxAbove
        }
        # Create the GroupBox
        [System.Windows.Forms.GroupBox]$FeatureGroupBox = New-GroupBox @FeatureProperties -OnSubTab

        # Ensure the flat storage key exists for this tab-feature pair and capture it.
        [System.String]$SubKeyForBoxes = New-SubKeyForBoxes -ParentTabPage $ParentTabPage -PassThru

        # EXECUTION - TEXTBOXES
        # Set the AppLockerDEVURL properties
        [System.Collections.Hashtable]$AppLockerDEVURL = @{
            RowNumber       = 1
            Label           = 'Select Folder'
            PropertyName    = "TextBoxes.$SubKeyForBoxes.AppLockerDEVURL"
            ToolTip         = 'Enter the LDAP path for AppLocker policies in the DEVELOPMENT environment'
            SizeType        = 'Medium'
            SmallButtons    = @(@(5,'Browse Folder'),@(6,'Paste'),@(7,'Open'))
        }
        # Set the AppLockerTSTURL properties
        [System.Collections.Hashtable]$AppLockerTSTURL = @{
            RowNumber       = 2
            Label           = 'Select Folder'
            PropertyName    = "TextBoxes.$SubKeyForBoxes.AppLockerTSTURL"
            ToolTip         = 'Enter the LDAP path for AppLocker policies in the TEST environment'
            DefaultValue    = 'Everyone'
            SizeType        = 'Medium'
            SmallButtons    = @(@(5,'Copy'),@(6,'Paste'))
        }
        # Set the AppLockerACCURL properties
        [System.Collections.Hashtable]$AppLockerACCURL = @{
            RowNumber       = 3
            Label           = 'Select Folder'
            PropertyName    = "TextBoxes.$SubKeyForBoxes.AppLockerACCURL"
            ToolTip         = 'Enter the LDAP path for AppLocker policies in the ACCEPTANCE environment'
            DefaultValue    = 'S-1-1-0'
            SizeType        = 'Medium'
            SmallButtons    = @(@(5,'Copy'),@(6,'Paste'))
        }
        # Set the AppLockerPRDURL properties
        [System.Collections.Hashtable]$AppLockerPRDURL = @{
            RowNumber       = 4
            Label           = 'Select Folder'
            PropertyName    = "TextBoxes.$SubKeyForBoxes.AppLockerPRDURL"
            ToolTip         = 'Enter the LDAP path for AppLocker policies in the PRODUCTION environment'
            DefaultValue    = 'S-1-1-0'
            SizeType        = 'Medium'
            SmallButtons    = @(@(5,'Copy'),@(6,'Paste'))
        }
        # Create the TextBoxes
        $Global:Graphics.TextBoxes[$SubKeyForBoxes].AppLockerDEVURL = New-TextBox @AppLockerDEVURL -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ReturnTextBox
        $Global:Graphics.TextBoxes[$SubKeyForBoxes].AppLockerTSTURL = New-TextBox @AppLockerTSTURL -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ReturnTextBox
        $Global:Graphics.TextBoxes[$SubKeyForBoxes].AppLockerACCURL = New-TextBox @AppLockerACCURL -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ReturnTextBox
        $Global:Graphics.TextBoxes[$SubKeyForBoxes].AppLockerPRDURL = New-TextBox @AppLockerPRDURL -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ReturnTextBox
        
        # OUTPUT
        # Return the GroupBox object
        $FeatureGroupBox
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}

### END OF FUNCTION
####################################################################################################

