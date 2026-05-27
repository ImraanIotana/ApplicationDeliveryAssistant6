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
        # Tab properties
        [System.Collections.Hashtable]$TabProperties = @{
            ParentTabControl    = $ParentTabControl
            Title               = 'INTAKE'
            Version             = '6.0.0.0'
            BackGroundColor     = 'RoyalBlue'
        }

        # Create the TabPage
        [System.Windows.Forms.TabPage]$ParentTabPage = New-TabPage @TabProperties

        # Import the Features
        $IntakeApplicationSelectionGroupBox     = Import-FeatureIntakeApplicationSelection  -InputObject $InputObject -ParentTabPage $ParentTabPage
        $FormalApplicationPropertiesGroupBox    = Import-FeatureFormalApplicationProperties -InputObject $InputObject -ParentTabPage $ParentTabPage -GroupBoxAbove $IntakeApplicationSelectionGroupBox
        $CustomApplicationPropertiesGroupBox    = Import-FeatureCustomApplicationProperties -InputObject $InputObject -ParentTabPage $ParentTabPage -GroupBoxAbove $FormalApplicationPropertiesGroupBox
        $ApplicationSecurityGroupBox            = Import-FeatureApplicationSecurity         -InputObject $InputObject -ParentTabPage $ParentTabPage -GroupBoxAbove $CustomApplicationPropertiesGroupBox
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}

### END OF FUNCTION
####################################################################################################
