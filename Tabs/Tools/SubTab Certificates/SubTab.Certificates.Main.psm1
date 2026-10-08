####################################################################################################
<#
.SYNOPSIS
    Imports the Certificates subtab into the Tools tab.
.DESCRIPTION
    Creates the Certificates TabPage in the Tools subtab control and imports its certificate
    management features.
.EXAMPLE
    Import-SubTabCertificates -InputObject $MyApplicationObject -ParentTabControl $ToolsSubTabControl
.INPUTS
    [PSCustomObject]
    [System.Windows.Forms.TabControl]
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.1.0
    Author          : Imraan Iotana
    Creation Date   : August 2026
    Last Update     : August 2026
#>
####################################################################################################
function Import-SubTabCertificates {
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
            Title            = 'CERTIFICATES'
            Version          = '6.1.0'
            BackGroundColor  = '#2F6F6D'
        }
        [System.String]$MainColor = '#E6F4F1'

        # EXECUTION - TAB
        [System.Windows.Forms.TabPage]$ParentTabPage = New-TabPage @TabProperties

        # EXECUTION - FEATURES
        [System.Windows.Forms.GroupBox]$CertificateManagementGroupBox = Import-FeatureCertificateManagement -InputObject $InputObject -ParentTabPage $ParentTabPage -Color $MainColor
        $null = Import-FeatureCertificateImport -InputObject $InputObject -ParentTabPage $ParentTabPage -Color $MainColor -GroupBoxAbove $CertificateManagementGroupBox
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}

### END OF FUNCTION
####################################################################################################