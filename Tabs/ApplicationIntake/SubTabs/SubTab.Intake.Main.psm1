####################################################################################################
<#
.SYNOPSIS
    Imports the Intake sub-tab into the Tools tab.
.DESCRIPTION
    This function imports the Intake sub-tab into the Tools tab by creating a new TabPage and adding it to the specified parent TabControl.
.EXAMPLE
    Import-SubTabIntake -ParentTabControl $MySubTabControl
.INPUTS
    [PSCustomObject]
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
function Import-SubTabIntake {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The ApplicationObject containing the Settings.')]
        [PSCustomObject]$InputObject,

        [Parameter(Mandatory=$true,HelpMessage='The Parent TabControl to which this TabPage will be added.')]
        [System.Windows.Forms.TabControl]$ParentTabControl
    )

    try {
        # PREPARATION - TABPAGE
        # Tab properties
        [System.Collections.Hashtable]$TabProperties = @{
            ParentTabControl    = $ParentTabControl
            Title               = 'INTAKE'
            Version             = '6.0.0.0'
            BackGroundColor     = 'RoyalBlue'
        }

        # PREPARATION - COLORS
        # Define the colors for the features in this sub-tab
        [System.String]$TopColor        = 'Cyan'
        [System.String]$MiddleColor1    = 'Gold'
        [System.String]$MiddleColor2    = 'Gold'
        [System.String]$MiddleColor3    = 'Gold'
        [System.String]$BottomColor     = 'Cyan'

        # EXECUTION - TABPAGE
        # Create the TabPage
        [System.Windows.Forms.TabPage]$ParentTabPage = New-TabPage @TabProperties

        # EXECUTION - FEATURES
        # Import the Features and store the returned GroupBoxes in variables to be used as the GroupBoxAbove parameter for the next Feature
        $IntakeApplicationSelectionGroupBox     = Import-FeatureIntakeApplicationSelection  -InputObject $InputObject -Color $TopColor      -ParentTabPage $ParentTabPage
        $ApplicationFormalPropertiesGroupBox    = Import-FeatureApplicationFormalProperties -InputObject $InputObject -Color $MiddleColor1   -ParentTabPage $ParentTabPage -GroupBoxAbove $IntakeApplicationSelectionGroupBox
        $ApplicationCustomPropertiesGroupBox    = Import-FeatureApplicationCustomProperties -InputObject $InputObject -Color $MiddleColor1   -ParentTabPage $ParentTabPage -GroupBoxAbove $ApplicationFormalPropertiesGroupBox
        $ApplicationShortcutsGroupBox           = Import-FeatureIntakeApplicationShortcuts  -InputObject $InputObject -Color $MiddleColor2   -ParentTabPage $ParentTabPage -GroupBoxAbove $ApplicationCustomPropertiesGroupBox
        $ApplicationSecurityGroupBox            = Import-FeatureApplicationSecurity         -InputObject $InputObject -Color $MiddleColor3    -ParentTabPage $ParentTabPage -GroupBoxAbove $ApplicationShortcutsGroupBox
        $ApplicationDetectionGroupBox           = Import-FeatureIntakeApplicationDetection  -InputObject $InputObject -Color $MiddleColor3    -ParentTabPage $ParentTabPage -GroupBoxAbove $ApplicationSecurityGroupBox
        $null                                   = Import-FeatureIntakeApplicationID         -InputObject $InputObject -Color $BottomColor   -ParentTabPage $ParentTabPage -GroupBoxAbove $ApplicationDetectionGroupBox
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}

### END OF FUNCTION
####################################################################################################
