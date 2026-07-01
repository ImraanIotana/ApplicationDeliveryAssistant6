####################################################################################################
<#
.SYNOPSIS
    Imports the Settings sub-tab into the AppLocker tab.
.DESCRIPTION
    This function imports the Settings sub-tab into the AppLocker tab by creating a new TabPage and adding it to the specified parent TabControl.
.EXAMPLE
    Import-SubTabAppLockerSettings -InputObject $InputObject -ParentTabControl $MySubTabControl
.INPUTS
    [PSCustomObject]
    [System.Windows.Forms.TabControl]
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. All rights reserved.
    Version         : 6.0.0.0
    Author          : Imraan Iotana
    Creation Date   : August 2025
    Last Update     : June 2026
#>
####################################################################################################
function Import-SubTabAppLockerSettings {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The ApplicationObject containing the Settings.')]
        [PSCustomObject]$InputObject,

        [Parameter(Mandatory=$true,HelpMessage='The Parent TabControl to which this TabPage will be added.')]
        [System.Windows.Forms.TabControl]$ParentTabControl
    )

    try {
        # PREPARATION
        # Tab properties
        [System.Collections.Hashtable]$TabProperties = @{
            ParentTabControl    = $ParentTabControl
            Title               = 'APPLOCKER SETTINGS'
            Version             = '6.0.0.0'
            BackGroundColor     = 'Blue'
        }

        # EXECUTION
        # Create the TabPage
        [System.Windows.Forms.TabPage]$ParentTabPage = New-TabPage @TabProperties

        # Import the Features
        $null = Import-FeatureAppLockerSettings -InputObject $InputObject -ParentTabPage $ParentTabPage -Color 'GreenYellow'
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
            NumberOfRows    = 9
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
            Label           = 'AppLocker DEV LDAP Path'
            PropertyName    = "TextBoxes.$SubKeyForBoxes.AppLockerDEVURL"
            ToolTip         = 'Enter the LDAP path for AppLocker policies in the DEVELOPMENT environment'
            DefaultValue    = 'LDAP://servername.domain.nl/CN={DEVELOPM-75F6-4AA2-89D0-034917004AA3},CN=Policies,CN=System,DC=domain,DC=nl'
            SizeType        = 'Large'
            Buttons         = @(@(1,'Copy'),@(2,'Paste'),@(5,'Default'))
        }
        # Set the AppLockerTSTURL properties
        [System.Collections.Hashtable]$AppLockerTSTURL = @{
            RowNumber       = 4
            Label           = 'AppLocker TEST LDAP Path'
            PropertyName    = "TextBoxes.$SubKeyForBoxes.AppLockerTSTURL"
            ToolTip         = 'Enter the LDAP path for AppLocker policies in the TEST environment'
            DefaultValue    = 'LDAP://servername.domain.nl/CN={TEST1234-ABCD-4AA2-89D0-034917004AA3},CN=Policies,CN=System,DC=domain,DC=nl'
            SizeType        = 'Large'
            Buttons         = @(@(1,'Copy'),@(2,'Paste'),@(5,'Default'))
        }
        # Set the AppLockerACCURL properties
        [System.Collections.Hashtable]$AppLockerACCURL = @{
            RowNumber       = 7
            Label           = 'AppLocker ACC LDAP Path'
            PropertyName    = "TextBoxes.$SubKeyForBoxes.AppLockerACCURL"
            ToolTip         = 'Enter the LDAP path for AppLocker policies in the ACCEPTANCE environment'
            DefaultValue    = 'LDAP://servername.domain.nl/CN={ACCEPTAN-1234-4AA2-89D0-034917004AA3},CN=Policies,CN=System,DC=domain,DC=nl'
            SizeType        = 'Large'
            Buttons         = @(@(1,'Copy'),@(2,'Paste'),@(5,'Default'))
        }
        # Set the AppLockerPRDURL properties
        [System.Collections.Hashtable]$AppLockerPRDURL = @{
            RowNumber       = 10
            Label           = 'AppLocker PRD LDAP Path'
            PropertyName    = "TextBoxes.$SubKeyForBoxes.AppLockerPRDURL"
            ToolTip         = 'Enter the LDAP path for AppLocker policies in the PRODUCTION environment'
            DefaultValue    = 'LDAP://servername.domain.nl/CN={PRODUCTI-6098-4CBA-9233-E1512BF88ABA},CN=Policies,CN=System,DC=domain,DC=nl'
            SizeType        = 'Large'
            Buttons         = @(@(1,'Copy'),@(2,'Paste'),@(5,'Default'))
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

