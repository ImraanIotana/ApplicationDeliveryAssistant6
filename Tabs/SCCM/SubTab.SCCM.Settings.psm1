####################################################################################################
<#
.SYNOPSIS
    Imports the SCCM Settings sub-tab into the SCCM section.
.DESCRIPTION
    This function imports the SCCM Settings sub-tab into the SCCM section by creating a new TabPage and adding it to the specified parent TabControl.
.EXAMPLE
    Import-SubTabSCCMSettings -InputObject $MyApplicationObject -ParentTabControl $MySubTabControl
.INPUTS
    [PSCustomObject]
    [System.Windows.Forms.TabControl]
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.1
    Author          : Imraan Iotana
    Creation Date   : July 2026
    Last Update     : July 2026
#>
####################################################################################################
function Import-SubTabSCCMSettings {
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
            Title               = 'SCCM SETTINGS'
            Version             = '6.0.0.1'
            BackGroundColor     = 'ForestGreen'
        }
        # Set the main color for the GroupBoxes in this sub-tab
        [System.String]$MainColor = 'Yellow'

        # EXECUTION - TAB
        # Create the TabPage
        [System.Windows.Forms.TabPage]$ParentTabPage = New-TabPage @TabProperties

        # EXECUTION - FEATURES
        # Import the Features
        $SCCMSettingsConnectionGroupBox = Import-FeatureSCCMSettingsConnection -InputObject $InputObject -ParentTabPage $ParentTabPage -Color $MainColor
        $null = Import-FeatureSCCMRepository -InputObject $InputObject -ParentTabPage $ParentTabPage -Color $MainColor -GroupBoxAbove $SCCMSettingsConnectionGroupBox
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
    Imports the SCCM Repository feature into the SCCM Settings sub-tab.
.DESCRIPTION
    This function imports the SCCM Repository feature by creating a GroupBox with a repository folder input.
.EXAMPLE
    Import-FeatureSCCMRepository -InputObject $MyApplicationObject -ParentTabPage $MyTabPage
.INPUTS
    [PSCustomObject]
    [System.Windows.Forms.TabPage]
    [System.Windows.Forms.GroupBox]
    [System.String]
.OUTPUTS
    [System.Windows.Forms.GroupBox]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.1
    Author          : Imraan Iotana
    Creation Date   : July 2026
    Last Update     : July 2026
#>
####################################################################################################
function Import-FeatureSCCMRepository {
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
            Title           = 'SCCM REPOSITORY'
            Color           = $Color
            NumberOfRows    = 2
            GroupBoxAbove   = $GroupBoxAbove
        }

        # EXECUTION - GROUPBOX
        # Create the GroupBox
        [System.Windows.Forms.GroupBox]$FeatureGroupBox = New-GroupBox @GroupBoxProperties

        # PREPARATION - TEXTBOX PROPERTIES
        # Set the RepositoryFolderTextBox properties
        [System.Collections.Hashtable]$RepositoryFolderTextBoxProperties = @{
            RowNumber       = 1
            Label           = 'Repository Folder'
            ToolTip         = 'The root folder used as SCCM repository.'
            SizeType        = 'Large'
            Buttons         = @(@(1,'Browse Folder'),@(2,'Open'),@(3,'Copy'),@(4,'Paste'),@(5,'Clear'))
        }

        # EXECUTION - INPUT CONTROLS
        # Create the repository folder input control
        [void](New-TextBox @RepositoryFolderTextBoxProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox)

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


####################################################################################################
<#
.SYNOPSIS
    Imports the SCCM connection settings feature into the SCCM Settings sub-tab.
.DESCRIPTION
    This function imports the SCCM connection settings feature by creating a GroupBox with inputs for Site Server, Site Code, and Provider Namespace, plus a button to test connectivity.
.EXAMPLE
    Import-FeatureSCCMSettingsConnection -InputObject $MyApplicationObject -ParentTabPage $MyTabPage
.INPUTS
    [PSCustomObject]
    [System.Windows.Forms.TabPage]
    [System.Windows.Forms.GroupBox]
    [System.String]
.OUTPUTS
    [System.Windows.Forms.GroupBox]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.1
    Author          : Imraan Iotana
    Creation Date   : July 2026
    Last Update     : July 2026
#>
####################################################################################################
function Import-FeatureSCCMSettingsConnection {
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
            Title           = 'SCCM CONNECTION SETTINGS'
            Color           = $Color
            NumberOfRows    = 5
            GroupBoxAbove   = $GroupBoxAbove
        }

        # EXECUTION - GROUPBOX
        # Create the GroupBox
        [System.Windows.Forms.GroupBox]$FeatureGroupBox = New-GroupBox @GroupBoxProperties

        # PREPARATION - TEXTBOX PROPERTIES
        # Set the SiteServerTextBox properties
        [System.Collections.Hashtable]$SiteServerTextBoxProperties = @{
            RowNumber       = 1
            Label           = 'Site Server'
            ToolTip         = 'The SCCM primary site server FQDN or hostname.'
            SizeType        = 'Medium'
            SmallButtons    = @(@(5,'Copy'),@(6,'Paste'),@(7,'Clear'))
        }
        # Set the SiteCodeTextBox properties
        [System.Collections.Hashtable]$SiteCodeTextBoxProperties = @{
            RowNumber       = 2
            Label           = 'Site Code'
            ToolTip         = 'The 3-character SCCM site code (for example: PR1).'
            SizeType        = 'Medium'
            SmallButtons    = @(@(5,'Copy'),@(6,'Paste'),@(7,'Clear'))
        }
        # Set the ProviderNamespaceTextBox properties
        [System.Collections.Hashtable]$ProviderNamespaceTextBoxProperties = @{
            RowNumber       = 3
            Label           = 'Provider Namespace'
            ToolTip         = 'The WMI namespace to query for provider location. Usually root\\sms.'
            DefaultValue    = 'root\\sms'
            SizeType        = 'Medium'
            SmallButtons    = @(@(5,'Copy'),@(6,'Paste'),@(7,'Default'))
        }

        # EXECUTION - INPUT CONTROLS
        # Create the input controls
        [System.Windows.Forms.TextBox]$SiteServerTextBox = New-TextBox @SiteServerTextBoxProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ReturnTextBox
        [System.Windows.Forms.TextBox]$SiteCodeTextBox = New-TextBox @SiteCodeTextBoxProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ReturnTextBox
        [System.Windows.Forms.TextBox]$ProviderNamespaceTextBox = New-TextBox @ProviderNamespaceTextBoxProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ReturnTextBox

        # PREPARATION - BUTTON PROPERTIES
        # Set the Test Connection button properties
        [System.Collections.Hashtable]$TestConnectionButton = @{
            ColumnNumber    = 1
            Text            = 'Test SCCM Connection'
            PNGFileName     = 'database_green'
            SizeType        = 'Large'
            ToolTip         = 'Tests WMI/CIM connectivity to SCCM provider and site namespace.'
            Function        = {
                Write-SCCMConnectionTestToHost -SiteServer $SiteServerTextBox.Text -SiteCode $SiteCodeTextBox.Text -ProviderNamespace $ProviderNamespaceTextBox.Text
            }.GetNewClosure()
        }

        # EXECUTION - BUTTONS
        # Create the Button
        New-Button @TestConnectionButton -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -RowNumber 4

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


####################################################################################################
<#
.SYNOPSIS
    Tests SCCM provider and site namespace connectivity and writes the result to the host.
.DESCRIPTION
    This helper validates user input, queries SMS_ProviderLocation from the configured provider namespace,
    then verifies access to the site namespace (root\sms\site_<SiteCode>) and writes a concise status summary.
.EXAMPLE
    Write-SCCMConnectionTestToHost -SiteServer 'sccm01.domain.local' -SiteCode 'PR1' -ProviderNamespace 'root\sms'
.INPUTS
    [System.String]
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.1
    Author          : Imraan Iotana
    Creation Date   : July 2026
    Last Update     : July 2026
#>
####################################################################################################
function Write-SCCMConnectionTestToHost {
    [CmdletBinding()]
    [OutputType([System.Void])]
    param (
        [Parameter(Mandatory=$false,HelpMessage='SCCM site server FQDN or hostname.')]
        [AllowNull()][AllowEmptyString()]
        [System.String]$SiteServer,

        [Parameter(Mandatory=$false,HelpMessage='SCCM site code.')]
        [AllowNull()][AllowEmptyString()]
        [System.String]$SiteCode,

        [Parameter(Mandatory=$false,HelpMessage='SCCM provider namespace. Default: root\\sms.')]
        [AllowNull()][AllowEmptyString()]
        [System.String]$ProviderNamespace = 'root\\sms'
    )

    [System.Management.Automation.Job]$Job = $null
    try {
        # VALIDATION
        # Validate the required values before testing
        if (-not (Test-String -IsPopulated $SiteServer)) {
            Write-Line 'Site Server is empty. Please provide a valid SCCM site server.' -Type Warning
            return
        }
        if (-not (Test-String -IsPopulated $SiteCode)) {
            Write-Line 'Site Code is empty. Please provide a valid SCCM site code.' -Type Warning
            return
        }

        [System.String]$NormalizedSiteServer = $SiteServer.Trim()
        [System.String]$NormalizedSiteCode = $SiteCode.Trim().ToUpperInvariant()
        [System.String]$NormalizedProviderNamespace = if (Test-String -IsPopulated $ProviderNamespace) { $ProviderNamespace.Trim() } else { 'root\\sms' }

        # EXECUTION
        # Run the SCCM connectivity test in a background job to keep the UI responsive
        Write-Line "Testing SCCM connectivity for SiteServer=[$NormalizedSiteServer], SiteCode=[$NormalizedSiteCode], Namespace=[$NormalizedProviderNamespace]..." -Type Busy

        $Job = Start-Job -ArgumentList $NormalizedSiteServer,$NormalizedSiteCode,$NormalizedProviderNamespace -ScriptBlock {
            param(
                [System.String]$TargetSiteServer,
                [System.String]$TargetSiteCode,
                [System.String]$TargetProviderNamespace
            )

            $ProgressPreference = 'SilentlyContinue'
            $InformationPreference = 'SilentlyContinue'
            $VerbosePreference = 'SilentlyContinue'
            $WarningPreference = 'SilentlyContinue'

            [System.Object]$ProviderLocation = Get-CimInstance -ComputerName $TargetSiteServer -Namespace $TargetProviderNamespace -ClassName 'SMS_ProviderLocation' -Filter "SiteCode='$TargetSiteCode'" -ErrorAction Stop | Select-Object -First 1

            if ($null -eq $ProviderLocation) {
                return [PSCustomObject]@{
                    Connected               = $false
                    Reason                  = 'NoProviderLocation'
                    SiteServer              = $TargetSiteServer
                    SiteCode                = $TargetSiteCode
                    ProviderNamespace       = $TargetProviderNamespace
                    ProviderMachine         = $null
                    ProviderNamespacePath   = $null
                    SiteNamespace           = $null
                    SiteName                = $null
                }
            }

            [System.String]$SiteNamespace = "root\\sms\\site_$TargetSiteCode"
            [System.Object]$SiteObject = Get-CimInstance -ComputerName $ProviderLocation.Machine -Namespace $SiteNamespace -ClassName 'SMS_Site' -ErrorAction Stop | Select-Object -First 1

            [PSCustomObject]@{
                Connected               = $true
                Reason                  = ''
                SiteServer              = $TargetSiteServer
                SiteCode                = $TargetSiteCode
                ProviderNamespace       = $TargetProviderNamespace
                ProviderMachine         = [System.String]$ProviderLocation.Machine
                ProviderNamespacePath   = [System.String]$ProviderLocation.NamespacePath
                SiteNamespace           = $SiteNamespace
                SiteName                = [System.String]$SiteObject.SiteName
            }
        }

        if (-not (Wait-Job -Job $Job -Timeout 12)) {
            Stop-Job -Job $Job -Force -ErrorAction SilentlyContinue
            Write-Line 'The SCCM connection test timed out after [12] second(s).' -Type Error
            return
        }

        [System.Object]$Result = Receive-Job -Job $Job -ErrorAction Stop

        # POST-EXECUTION
        # Write a compact status summary
        if ($Result.Connected) {
            Write-Line 'SCCM connection test succeeded.' -Type Success
            @(
                "Site Server             : $($Result.SiteServer)"
                "Site Code               : $($Result.SiteCode)"
                "Provider Namespace      : $($Result.ProviderNamespace)"
                "Provider Machine        : $($Result.ProviderMachine)"
                "Provider NamespacePath  : $($Result.ProviderNamespacePath)"
                "Site Namespace          : $($Result.SiteNamespace)"
                "Site Name               : $($Result.SiteName)"
            ) -join [System.Environment]::NewLine | Out-Host
        }
        else {
            Write-Line "SCCM connection test failed. No SMS_ProviderLocation was returned for SiteCode=[$($Result.SiteCode)] from [$($Result.SiteServer)] in namespace [$($Result.ProviderNamespace)]." -Type Error
        }
    }
    catch {
        Write-Line "The SCCM connection test failed for SiteServer=[$SiteServer] and SiteCode=[$SiteCode]." -Type Error
        Write-ErrorReport -ErrorRecord $_
    }
    finally {
        if ($null -ne $Job) {
            Remove-Job -Job $Job -Force -ErrorAction SilentlyContinue
        }
    }
}

### END OF FUNCTION
####################################################################################################
