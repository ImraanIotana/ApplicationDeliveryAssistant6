####################################################################################################
<#
.SYNOPSIS
    Imports the Settings sub-tab into the AppLocker section.
.DESCRIPTION
    This function imports the Settings sub-tab into the AppLocker section by creating a new TabPage and adding it to the specified parent TabControl.
    It follows the newer 6.0.0.3 pattern where textbox registration is handled directly by New-TextBox.
.EXAMPLE
    Import-SubTabAppLockerSettings -InputObject $MyApplicationObject -ParentTabControl $MySubTabControl
.INPUTS
    [PSCustomObject]
    [System.Windows.Forms.TabControl]
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.3.3
    Author          : Imraan Iotana
    Creation Date   : August 2025
    Last Update     : July 2026
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
        # PREPARATION - TAB PROPERTIES
        # Tab properties
        [System.Collections.Hashtable]$TabProperties = @{
            ParentTabControl    = $ParentTabControl
            Title               = 'APPLOCKER SETTINGS'
            Version             = '6.3.3'
            BackGroundColor     = 'SteelBlue'
        }
        # Set the main color for the GroupBoxes in this sub-tab
        [System.String]$MainColor = 'Cyan'

        # EXECUTION - TAB
        # Create the TabPage
        [System.Windows.Forms.TabPage]$ParentTabPage = New-TabPage @TabProperties

        # EXECUTION - FEATURES
        # Import the Feature
        $null = Import-FeatureAppLockerSettings -InputObject $InputObject -ParentTabPage $ParentTabPage -Color $MainColor
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
    [System.Windows.Forms.GroupBox]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.3.3
    Author          : Imraan Iotana
    Creation Date   : May 2026
    Last Update     : July 2026
#>
####################################################################################################
function Import-FeatureAppLockerSettings {
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
            Title           = 'APPLOCKER LDAP SETTINGS'
            Color           = $Color
            NumberOfRows    = 9
            GroupBoxAbove   = $GroupBoxAbove
        }

        # EXECUTION - GROUPBOX
        # Create the GroupBox
        [System.Windows.Forms.GroupBox]$FeatureGroupBox = New-GroupBox @GroupBoxProperties

        # PREPARATION - TEXTBOX PROPERTIES
        # Set the AppLockerDEVURL properties
        [System.Collections.Hashtable]$AppLockerDEVURLTextBoxProperties = @{
            RowNumber       = 1
            Label           = 'AppLocker LDAP DEV'
            ToolTip         = 'Enter the LDAP path for AppLocker policies in the DEVELOPMENT environment'
            DefaultValue    = 'LDAP://servername.domain.nl/CN={DEVELOPM-75F6-4AA2-89D0-034917004AA3},CN=Policies,CN=System,DC=domain,DC=nl'
            SizeType        = 'Large'
            Buttons         = @(@(1,'Copy'),@(2,'Paste'),@(5,'Default'))
        }
        # Set the AppLockerTSTURL properties
        [System.Collections.Hashtable]$AppLockerTSTURLTextBoxProperties = @{
            RowNumber       = 4
            Label           = 'AppLocker LDAP TEST'
            ToolTip         = 'Enter the LDAP path for AppLocker policies in the TEST environment'
            DefaultValue    = 'LDAP://servername.domain.nl/CN={TEST1234-ABCD-4AA2-89D0-034917004AA3},CN=Policies,CN=System,DC=domain,DC=nl'
            SizeType        = 'Large'
            Buttons         = @(@(1,'Copy'),@(2,'Paste'),@(5,'Default'))
        }
        # Set the AppLockerACCURL properties
        [System.Collections.Hashtable]$AppLockerACCURLTextBoxProperties = @{
            RowNumber       = 7
            Label           = 'AppLocker LDAP ACC'
            ToolTip         = 'Enter the LDAP path for AppLocker policies in the ACCEPTANCE environment'
            DefaultValue    = 'LDAP://servername.domain.nl/CN={ACCEPTAN-1234-4AA2-89D0-034917004AA3},CN=Policies,CN=System,DC=domain,DC=nl'
            SizeType        = 'Large'
            Buttons         = @(@(1,'Copy'),@(2,'Paste'),@(5,'Default'))
        }
        # Set the AppLockerPRDURL properties
        [System.Collections.Hashtable]$AppLockerPRDURLTextBoxProperties = @{
            RowNumber       = 10
            Label           = 'AppLocker LDAP PRD'
            ToolTip         = 'Enter the LDAP path for AppLocker policies in the PRODUCTION environment'
            DefaultValue    = 'LDAP://servername.domain.nl/CN={PRODUCTI-6098-4CBA-9233-E1512BF88ABA},CN=Policies,CN=System,DC=domain,DC=nl'
            SizeType        = 'Large'
            Buttons         = @(@(1,'Copy'),@(2,'Paste'),@(5,'Default'))
        }

        # EXECUTION - TEXTBOXES
        # Create the TextBoxes
        [System.Windows.Forms.TextBox]$AppLockerDEVURLTextBox = New-TextBox @AppLockerDEVURLTextBoxProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ReturnTextBox
        [System.Windows.Forms.TextBox]$AppLockerTSTURLTextBox = New-TextBox @AppLockerTSTURLTextBoxProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ReturnTextBox
        [System.Windows.Forms.TextBox]$AppLockerACCURLTextBox = New-TextBox @AppLockerACCURLTextBoxProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ReturnTextBox
        [System.Windows.Forms.TextBox]$AppLockerPRDURLTextBox = New-TextBox @AppLockerPRDURLTextBoxProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ReturnTextBox
        
        # PREPARATION - BUTTON PROPERTIES
        # Set the Custom Buttons properties
        [System.Collections.Hashtable[]]$CustomButtonsPropertiesArray = @(
            @{
                RowNumber   = 2
                Text        = 'Customer'
                PNGFileName = 'database_blue'
                SizeType    = 'Medium'
                ToolTip     = 'Enter the Customers LDAP setting from the selected Customer Template.'
                Function    = { Set-AppLockerLDAPFromSelectedTemplate -TargetTextBox $AppLockerDEVURLTextBox -Environment 'Development' }.GetNewClosure()
            }
            @{
                RowNumber   = 5
                Text        = 'Customer'
                PNGFileName = 'database_blue'
                SizeType    = 'Medium'
                ToolTip     = 'Enter the Customers LDAP setting from the selected Customer Template.'
                Function    = { Set-AppLockerLDAPFromSelectedTemplate -TargetTextBox $AppLockerTSTURLTextBox -Environment 'Test' }.GetNewClosure()
            }
            @{
                RowNumber   = 8
                Text        = 'Customer'
                PNGFileName = 'database_blue'
                SizeType    = 'Medium'
                ToolTip     = 'Enter the Customers LDAP setting from the selected Customer Template.'
                Function    = { Set-AppLockerLDAPFromSelectedTemplate -TargetTextBox $AppLockerACCURLTextBox -Environment 'Acceptance' }.GetNewClosure()
            }
            @{
                RowNumber   = 11
                Text        = 'Customer'
                PNGFileName = 'database_blue'
                SizeType    = 'Medium'
                ToolTip     = 'Enter the Customers LDAP setting from the selected Customer Template.'
                Function    = { Set-AppLockerLDAPFromSelectedTemplate -TargetTextBox $AppLockerPRDURLTextBox -Environment 'Production' }.GetNewClosure()
            }
        )

        # EXECUTION - BUTTONS
        # Create the Buttons
        New-ButtonLine -InputObject $InputObject -ButtonPropertiesArray $CustomButtonsPropertiesArray -ParentGroupBox $FeatureGroupBox -ColumnNumber 4


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
    Applies an AppLocker LDAP value from the selected customer template to a target TextBox.
.DESCRIPTION
    This helper resolves the TemplateSelection ComboBox from the General Settings feature,
    reads AppLockerDefaultSettings from the selected template, and writes the requested
    environment URL to the provided TextBox.
.EXAMPLE
    Set-AppLockerLDAPFromSelectedTemplate -TargetTextBox $MyTextBox -Environment 'Development'
.EXAMPLE
    Set-AppLockerLDAPFromSelectedTemplate -TargetTextBox $MyTextBox -Environment 'Production' -Force
.PARAMETER TargetTextBox
    The target TextBox that will receive the resolved LDAP value.
.PARAMETER Environment
    The AppLocker environment key to resolve from the selected customer template.
.PARAMETER Force
    Skip the confirmation prompt and apply the template value immediately.
.INPUTS
    [System.Windows.Forms.TextBox]
    [System.String]
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.3.3
    Author          : Imraan Iotana
    Creation Date   : July 2026
    Last Update     : July 2026
#>
####################################################################################################
function Set-AppLockerLDAPFromSelectedTemplate {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The target TextBox that will receive the LDAP value.')]
        [System.Windows.Forms.TextBox]$TargetTextBox,

        [Parameter(Mandatory=$true,HelpMessage='The AppLocker environment to read from the selected template.')]
        [ValidateSet('Development','Test','Acceptance','Production')]
        [System.String]$Environment,

        [Parameter(Mandatory=$false,HelpMessage='Skip the confirmation prompt and apply the value immediately.')]
        [System.Management.Automation.SwitchParameter]$Force
    )

    try {
        # VALIDATION
        # Ensure the target TextBox is available
        if ($null -eq $TargetTextBox -or $TargetTextBox.IsDisposed) {
            Write-Line 'The target AppLocker TextBox is not available.' -Type Warning
            return
        }

        # PREPARATION
        # Resolve the active customer template
        [System.Object]$SelectedTemplate = Get-ActiveCustomerTemplate
        if ($null -eq $SelectedTemplate) {
            Write-Line 'No active customer template is selected.' -Type Warning
            return
        }

        # PREPARATION
        # Resolve AppLocker default settings from the selected template object
        [System.Object]$AppLockerDefaultSettings = $null
        if (($SelectedTemplate -is [System.Collections.IDictionary]) -and $SelectedTemplate.Contains('AppLockerDefaultSettings')) {
            $AppLockerDefaultSettings = $SelectedTemplate['AppLockerDefaultSettings']
        }
        elseif ($null -ne $SelectedTemplate.PSObject.Properties['AppLockerDefaultSettings']) {
            $AppLockerDefaultSettings = $SelectedTemplate.AppLockerDefaultSettings
        }
        elseif (($SelectedTemplate -is [System.Collections.IDictionary]) -and $SelectedTemplate.Contains('Content') -and ($null -ne $SelectedTemplate['Content'])) {
            [System.Object]$TemplateContent = $SelectedTemplate['Content']
            if (($TemplateContent -is [System.Collections.IDictionary]) -and $TemplateContent.Contains('AppLockerDefaultSettings')) {
                $AppLockerDefaultSettings = $TemplateContent['AppLockerDefaultSettings']
            }
            elseif ($null -ne $TemplateContent.PSObject.Properties['AppLockerDefaultSettings']) {
                $AppLockerDefaultSettings = $TemplateContent.AppLockerDefaultSettings
            }
        }
        elseif (($null -ne $SelectedTemplate.PSObject.Properties['Content']) -and ($null -ne $SelectedTemplate.Content)) {
            [System.Object]$TemplateContent = $SelectedTemplate.Content
            if (($TemplateContent -is [System.Collections.IDictionary]) -and $TemplateContent.Contains('AppLockerDefaultSettings')) {
                $AppLockerDefaultSettings = $TemplateContent['AppLockerDefaultSettings']
            }
            elseif ($null -ne $TemplateContent.PSObject.Properties['AppLockerDefaultSettings']) {
                $AppLockerDefaultSettings = $TemplateContent.AppLockerDefaultSettings
            }
        }

        if ($null -eq $AppLockerDefaultSettings) {
            Write-Line "The selected customer template does not contain AppLocker default settings. ($($SelectedTemplate.Identity))" -Type Warning
            return
        }

        # EXECUTION
        # Map the requested environment to the expected key in AppLockerDefaultSettings
        [System.String]$SettingKey = switch ($Environment) {
            'Development' { 'DevelopmentURL' }
            'Test'        { 'TestURL' }
            'Acceptance'  { 'AcceptanceURL' }
            'Production'  { 'ProductionURL' }
        }

        # Read the LDAP value from either dictionary keys or object properties
        [System.String]$LDAPValue = ''
        if ($AppLockerDefaultSettings -is [System.Collections.IDictionary]) {
            $LDAPValue = [System.String]$AppLockerDefaultSettings[$SettingKey]
        }
        elseif ($null -ne $AppLockerDefaultSettings.PSObject.Properties[$SettingKey]) {
            $LDAPValue = [System.String]$AppLockerDefaultSettings.$SettingKey
        }

        if (Test-String -IsEmpty $LDAPValue) {
            Write-Line "No LDAP setting was found for $Environment in the selected customer template. ($($SelectedTemplate.Identity))" -Type Warning
            return
        }

        # VALIDATION
        # Ask for confirmation only when the TextBox already contains a value and -Force is not specified
        if ((Test-String -IsPopulated $TargetTextBox.Text) -and -not $Force) {
            [System.String]$Title = 'Confirm Apply Customer LDAP Value'
            [System.String]$Body = "This will overwrite the current value:`n`n$($TargetTextBox.Text)`n`nwith the customer template value:`n`n$LDAPValue`n`nDo you want to continue?"
            [System.Boolean]$UserHasConfirmed = Get-UserConfirmation -Title $Title -Body $Body
            if (-not $UserHasConfirmed) { return }
        }

        # EXECUTION
        # Apply the resolved LDAP value to the target TextBox and report the result
        $TargetTextBox.Text = $LDAPValue
        Write-Line "The AppLocker $Environment LDAP value has been applied from customer template ($($SelectedTemplate.Identity))."
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}

### END OF FUNCTION
####################################################################################################

