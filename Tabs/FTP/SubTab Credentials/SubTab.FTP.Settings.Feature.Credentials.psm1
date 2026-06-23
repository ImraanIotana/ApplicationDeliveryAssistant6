####################################################################################################
<#
.SYNOPSIS
    Imports the File Bitness feature into the Files sub-tab.
.DESCRIPTION
    This function imports the File Bitness feature into the Files sub-tab by creating a new GroupBox and adding it to the specified parent TabPage.
.EXAMPLE
    Import-FeatureFileBitness -InputObject $MyApplicationObject -ParentTabPage $MyTabPage
.INPUTS
    [PSCustomObject]
    [System.Windows.Forms.TabPage]
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. All rights reserved.
    Version         : 6.0.0.0
    Author          : Imraan Iotana
    Creation Date   : June 2026
    Last Update     : June 2026
#>
####################################################################################################
function Import-FeatureFTPCredentials {
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
        # PREPARATION - FEATURE PROPERTIES
        # Feature properties
        [System.Collections.Hashtable]$FeatureProperties = @{
            InputObject     = $InputObject
            ParentTabPage   = $ParentTabPage
            Title           = 'CREDENTIALS'
            Color           = 'Indigo'
            NumberOfRows    = 3
            GroupBoxAbove   = $GroupBoxAbove
        }

        # PREPARATION - TEXTBOXES
        # Set the FTP Server URL TextBox properties
        [System.Collections.Hashtable]$ServerURLTextBoxProperties = @{
            RowNumber       = 1
            Label           = 'FTP Server URL'
            PropertyName    = 'TextBoxes.FTP.Credentials.ServerURL'
            ToolTip         = 'The URL or IP address of the FTP server'
            SizeType        = 'Medium'
            SmallButtons    = @(@(5,'Copy'),@(6,'Paste'),@(7,'Clear'))
        }

        # Set the Username TextBox properties
        [System.Collections.Hashtable]$UsernameTextBoxProperties = @{
            RowNumber       = 2
            Label           = 'Username'
            PropertyName    = 'TextBoxes.FTP.Credentials.Username'
            ToolTip         = 'The username for FTP authentication'
            SizeType        = 'Medium'
            SmallButtons    = @(@(5,'Copy'),@(6,'Paste'),@(7,'Clear'))
        }

        # Set the Password TextBox properties
        [System.Collections.Hashtable]$PasswordTextBoxProperties = @{
            RowNumber       = 3
            Label           = 'Password'
            PropertyName    = 'TextBoxes.FTP.Credentials.Password'
            ToolTip         = 'The password for FTP authentication'
            SizeType        = 'Medium'
            UsePasswordChar = $true
            SmallButtons    = @(@(5,'Show'),@(6,'Paste'),@(7,'Clear'))
        }


        # EXECUTION
        # Create the GroupBox
        [System.Windows.Forms.GroupBox]$FeatureGroupBox = New-GroupBox @FeatureProperties -OnSubTab
        # Create the TextBoxes
        if (-not $Global:Graphics.TextBoxes.FTP.ContainsKey('Credentials')) { $Global:Graphics.TextBoxes.FTP.Credentials = @{} }
        $Global:Graphics.TextBoxes.FTP.Credentials.ServerURL = New-TextBox @ServerURLTextBoxProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ReturnTextBox
        $Global:Graphics.TextBoxes.FTP.Credentials.Username = New-TextBox @UsernameTextBoxProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ReturnTextBox
        $Global:Graphics.TextBoxes.FTP.Credentials.Password = New-TextBox @PasswordTextBoxProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ReturnTextBox
        # Return the GroupBox object
        $FeatureGroupBox
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}

### END OF FUNCTION
####################################################################################################
