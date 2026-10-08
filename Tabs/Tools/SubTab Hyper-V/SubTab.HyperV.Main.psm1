####################################################################################################
<#
.SYNOPSIS
    Imports the Hyper-V subtab into the Tools tab.
.DESCRIPTION
    Creates the HYPER-V subtab in Tools and imports its virtual machine creation and selection feature.
.EXAMPLE
    Import-SubTabHyperV -InputObject $MyApplicationObject -ParentTabControl $ToolsSubTabControl
.INPUTS
    [PSCustomObject]
    [System.Windows.Forms.TabControl]
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.4.0
    Author          : Imraan Iotana
    Creation Date   : August 2026
    Last Update     : August 2026
#>
####################################################################################################
function Import-SubTabHyperV {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The ApplicationObject containing the Settings.')]
        [PSCustomObject]$InputObject,

        [Parameter(Mandatory=$true,HelpMessage='The Parent TabControl to which this TabPage will be added.')]
        [System.Windows.Forms.TabControl]$ParentTabControl
    )

    try {
        # PREPARATION - TAB PROPERTIES
        [System.Collections.Hashtable]$TabProperties = @{
            ParentTabControl = $ParentTabControl
            Title            = 'HYPER-V'
            Version          = '6.4.0'
            BackGroundColor  = 'DarkBlue'
        }

        # EXECUTION - TAB
        [System.Windows.Forms.TabPage]$ParentTabPage = New-TabPage @TabProperties
        [System.String]$MainColor = 'Cyan'

        # EXECUTION - FEATURES
        $null = Import-FeatureHyperVVirtualMachineConfiguration -InputObject $InputObject -ParentTabPage $ParentTabPage -Color $MainColor

        # OUTPUT
        # The HYPER-V subtab and its feature group boxes are added by the shared graphics helpers.
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}

### END OF FUNCTION
####################################################################################################