####################################################################################################
<#
.SYNOPSIS
    Imports the Custom Application sub-tab into the Application Intake tab.
.DESCRIPTION
    This function imports the Custom Application sub-tab and its intake features into the Application Intake tab.
.EXAMPLE
    Import-SubTabCustomApplication -InputObject $MyApplicationObject -ParentTabControl $MySubTabControl
.INPUTS
    [PSCustomObject]
    [System.Windows.Forms.TabControl]
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.3.2
    Author          : Imraan Iotana
    Creation Date   : August 2026
    Last Update     : August 2026
#>
####################################################################################################
function Import-SubTabCustomApplication {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The ApplicationObject containing the Settings.')]
        [PSCustomObject]$InputObject,

        [Parameter(Mandatory=$true,HelpMessage='The Parent TabControl to which this TabPage will be added.')]
        [System.Windows.Forms.TabControl]$ParentTabControl
    )

    try {
        [System.Collections.Hashtable]$TabProperties = @{
            ParentTabControl = $ParentTabControl
            Title            = 'CUSTOM APPLICATION'
            Version          = '6.3.2'
            BackGroundColor  = 'RoyalBlue'
        }
        [System.Windows.Forms.TabPage]$ParentTabPage = New-TabPage @TabProperties

        # PREPARATION - COLORS
        # Set the colors for the Custom Application features.
        [System.String]$TopColor    = 'GreenYellow'
        [System.String]$MiddleColor = 'Gold'
        [System.String]$BottomColor = 'GreenYellow'

        # EXECUTION - FEATURES
        # Import each feature and position it underneath the preceding GroupBox.
        [System.Windows.Forms.GroupBox]$ApplicationTypeGroupBox     = Import-FeatureCustomApplicationType       -InputObject $InputObject -ParentTabPage $ParentTabPage -Color $TopColor
        [System.Windows.Forms.GroupBox]$ApplicationIdentityGroupBox = Import-FeatureCustomApplicationIdentity   -InputObject $InputObject -ParentTabPage $ParentTabPage -Color $MiddleColor -GroupBoxAbove $ApplicationTypeGroupBox
        [System.Windows.Forms.GroupBox]$ApplicationExecutableGroupBox = Import-FeatureCustomApplicationExecutable -InputObject $InputObject -ParentTabPage $ParentTabPage -Color $MiddleColor -GroupBoxAbove $ApplicationIdentityGroupBox
        $null                                                         = Import-FeatureCustomApplicationID         -InputObject $InputObject -ParentTabPage $ParentTabPage -Color $BottomColor -GroupBoxAbove $ApplicationExecutableGroupBox
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}

### END OF FUNCTION
####################################################################################################