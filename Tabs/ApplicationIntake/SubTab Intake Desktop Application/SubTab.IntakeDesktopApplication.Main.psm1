####################################################################################################
<#
.SYNOPSIS
    Imports the Desktop Application sub-tab into the Application Intake tab.
.DESCRIPTION
    This function imports the Desktop Application sub-tab into the Application Intake tab by creating a new TabPage and adding it to the specified parent TabControl.
.EXAMPLE
    Import-SubTabIntake -InputObject $MyApplicationObject -ParentTabControl $MySubTabControl
.INPUTS
    [PSCustomObject]
    [System.Windows.Forms.TabControl]
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.5.2
    Author          : Imraan Iotana
    Creation Date   : July 2026
    Last Update     : August 2026
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
        # PREPARATION - TAB PROPERTIES
        # Tab properties
        [System.Collections.Hashtable]$TabProperties = @{
            ParentTabControl    = $ParentTabControl
            Title               = 'DESKTOP APPLICATION'
            Version             = '6.5.2'
            BackGroundColor     = 'RoyalBlue'
        }

        # EXECUTION - TAB
        # Create the TabPage
        [System.Windows.Forms.TabPage]$ParentTabPage = New-TabPage @TabProperties

        # PREPARATION - COLORS
        # Define the colors for the features in this sub-tab
        [System.String]$TopColor        = 'GreenYellow'
        [System.String]$MiddleColor1    = 'Orange'
        [System.String]$MiddleColor2    = 'Gold'
        [System.String]$BottomColor     = 'GreenYellow'

        # EXECUTION - FEATURES
        # Import the Features and store the returned GroupBoxes in variables to be used as the GroupBoxAbove parameter for the next Feature
        $IntakeApplicationSelectionGroupBox     = Import-FeatureIntakeApplicationSelection  -InputObject $InputObject -Color $TopColor      -ParentTabPage $ParentTabPage
        $ApplicationFormalPropertiesGroupBox    = Import-FeatureApplicationFormalProperties -InputObject $InputObject -Color $MiddleColor1   -ParentTabPage $ParentTabPage -GroupBoxAbove $IntakeApplicationSelectionGroupBox
        $ApplicationCustomPropertiesGroupBox    = Import-FeatureApplicationCustomProperties -InputObject $InputObject -Color $MiddleColor2   -ParentTabPage $ParentTabPage -GroupBoxAbove $ApplicationFormalPropertiesGroupBox
        $ApplicationShortcutsGroupBox           = Import-FeatureIntakeApplicationShortcuts  -InputObject $InputObject -Color $MiddleColor2   -ParentTabPage $ParentTabPage -GroupBoxAbove $ApplicationCustomPropertiesGroupBox
        $ApplicationSecurityGroupBox            = Import-FeatureApplicationSecurity         -InputObject $InputObject -Color $MiddleColor2   -ParentTabPage $ParentTabPage -GroupBoxAbove $ApplicationShortcutsGroupBox
        $null                                   = Import-FeatureIntakeApplicationID         -InputObject $InputObject -Color $BottomColor   -ParentTabPage $ParentTabPage -GroupBoxAbove $ApplicationSecurityGroupBox
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}

### END OF FUNCTION
####################################################################################################
