####################################################################################################
<#
.SYNOPSIS
    Imports the Mail Template Selection feature into the Intake Mail sub-tab.
.DESCRIPTION
    This function imports the Mail Template Selection feature into the Intake Mail sub-tab by creating a new GroupBox and adding it to the specified parent TabPage.
    The ComboBox setup uses the shared graphics pattern where New-ComboBox handles
    PropertyName generation and flattened graphics registration directly.
.EXAMPLE
    Import-FeatureIntakeMailTemplateSelection -InputObject $MyApplicationObject -ParentTabPage $MyTabPage
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
    Last Update     : August 2026
#>
####################################################################################################
function Import-FeatureIntakeMailTemplateSelection {
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
            Title           = 'MAIL TEMPLATE SELECTION'
            Color           = $Color
            NumberOfRows    = 2
            GroupBoxAbove   = $GroupBoxAbove
        }

        # EXECUTION - GROUPBOX
        # Create the GroupBox
        [System.Windows.Forms.GroupBox]$FeatureGroupBox = New-GroupBox @GroupBoxProperties

        # PREPARATION - COMBOBOX PROPERTIES
        # Set the ComboBox properties
        [System.Collections.Hashtable]$SelectedApplicationComboBoxProperties = @{
            RowNumber       = 1
            Label           = 'Select Mail Template'
            ToolTip         = 'The list of mail templates to select from.'
            SizeType        = 'Medium'
            MailTemplates   = Get-MailTemplates
        }

        # EXECUTION - COMBOBOX
        # Create the ComboBox
        [System.Windows.Forms.ComboBox]$MailTemplateSelectionComboBox = New-ComboBox @SelectedApplicationComboBoxProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ReturnComboBox

        # EXECUTION - BUTTONS
        # Set the Small Buttons properties
        [System.Collections.Hashtable[]]$SmallButtonsPropertiesArray = @(
            @{
                ColumnNumber    = 5
                Text            = 'Details'
                PNGFileName     = 'information'
                SizeType        = 'Small'
                ToolTip         = 'View details of the selected template.'
                Function        = { Write-MailTemplateToHost -ComboBox $MailTemplateSelectionComboBox }.GetNewClosure()
            }
            @{
                ColumnNumber    = 6
                Text            = 'Refresh'
                PNGFileName     = 'arrow_refresh'
                SizeType        = 'Small'
                ToolTip         = 'Refresh the list of mail templates from the selected customer settings file.'
                Function        = {
                    [System.Object]$ActiveCustomerTemplate = Get-ActiveCustomerTemplate
                    [System.String]$SettingsFilePath = if ($null -ne $ActiveCustomerTemplate) { [System.String]$ActiveCustomerTemplate.TemplatePath } else { '' }

                    Update-ComboBox -ComboBox $MailTemplateSelectionComboBox -MailTemplates (Get-MailTemplates -SettingsFilePath $SettingsFilePath)
                }.GetNewClosure()
            }
        )
        # Set the action button properties
        [System.Collections.Hashtable]$ActionButtonProperties = @{
            ColumnNumber    = 1
            Text            = 'Create Mail'
            PNGFileName     = 'mail_yellow'
            SizeType        = 'Medium'
            ToolTip         = 'Create a new mail based on the selected template.'
            Function        = { New-MailFromTemplate -ComboBox $MailTemplateSelectionComboBox }.GetNewClosure()
        }
        # Create the Buttons
        New-ButtonLine -InputObject $InputObject -ButtonPropertiesArray $SmallButtonsPropertiesArray -ParentGroupBox $FeatureGroupBox -RowNumber 1
        New-Button @ActionButtonProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -RowNumber 2

        # POST-EXECUTION
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
    Writes details of the selected mail template to the host.
.DESCRIPTION
    This function reads the selected item from the Mail Template Selection ComboBox and writes key template
    details (mail template name, subject, and body) to the host.
.EXAMPLE
    Write-MailTemplateToHost -ComboBox (Get-ComboBoxObject -ComboBoxName 'MailTemplateSelection')
.PARAMETER ComboBox
    Required ComboBox containing mail template items.
.INPUTS
    [System.Windows.Forms.ComboBox]
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.3.3
    Author          : Imraan Iotana
    Creation Date   : June 2026
    Last Update     : August 2026
#>
####################################################################################################
function Write-MailTemplateToHost {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The mail template ComboBox.')]
        [System.Windows.Forms.ComboBox]$ComboBox
    )

    # Guard against calls before the UI control exists
    if ($null -eq $ComboBox -or $ComboBox.IsDisposed) {
        Write-Line 'The mail template ComboBox is not available.' -Type Warning
        return
    }

    # A template must be selected before we can show details
    if ($null -eq $ComboBox.SelectedItem) {
        Write-Line 'No mail template is selected.' -Type Warning
        return
    }

    # Read the selected template once and write the key mail fields
    [System.Object]$SelectedTemplate = $ComboBox.SelectedItem
    Write-Line "Mail Template: $($SelectedTemplate.TemplateName)" -Type Special
    Write-Line "Mail Subject: $($SelectedTemplate.Subject)" -Type Info
    Write-Line "Mail Body: $($SelectedTemplate.Body)" -Type Info
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Creates a new mail draft from the selected mail template.
.DESCRIPTION
    This function reads the currently selected template from the Mail Template Selection ComboBox,
    creates a mailto URL with escaped subject/body content, and opens the default mail client.
.EXAMPLE
    New-MailFromTemplate -ComboBox (Get-ComboBoxObject -ComboBoxName 'MailTemplateSelection')
.PARAMETER ComboBox
    Required ComboBox containing mail template items.
.INPUTS
    [System.Windows.Forms.ComboBox]
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.3.3
    Author          : Imraan Iotana
    Creation Date   : June 2026
    Last Update     : August 2026
#>
####################################################################################################
function New-MailFromTemplate {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The mail template ComboBox.')]
        [System.Windows.Forms.ComboBox]$ComboBox
    )

    # Guard against calls before the UI control exists
    if ($null -eq $ComboBox -or $ComboBox.IsDisposed) {
        Write-Line 'The mail template ComboBox is not available.' -Type Warning
        return
    }

    # A template must be selected before creating a draft mail
    if ($null -eq $ComboBox.SelectedItem) {
        Write-Line 'No mail template is selected.' -Type Warning
        return
    }

    [System.Object]$SelectedTemplate = $ComboBox.SelectedItem

    # Keep To optional and support common field names if present in customer template content
    [System.String]$To = ''
    if ($SelectedTemplate.PSObject.Properties.Name -contains 'To' -and -not (Test-String -IsEmpty $SelectedTemplate.To)) {
        $To = [System.String]$SelectedTemplate.To
    }
    elseif ($SelectedTemplate.PSObject.Properties.Name -contains 'Recipient' -and -not (Test-String -IsEmpty $SelectedTemplate.Recipient)) {
        $To = [System.String]$SelectedTemplate.Recipient
    }

    [System.String]$Subject = [System.String]$SelectedTemplate.Subject
    [System.String]$Body = [System.String]$SelectedTemplate.Body

    try {
        [System.String]$MailtoUrl = "mailto:$To`?subject=$([uri]::EscapeDataString($Subject))&body=$([uri]::EscapeDataString($Body))"
        Start-Process $MailtoUrl
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
    Gets mail templates from customer settings data.
.DESCRIPTION
    This function resolves a customer settings file, reads the MailTemplates section,
    and returns template objects to populate the Mail Template Selection ComboBox.
    When no settings file is available yet, the function returns an empty array instead of
    falling back to a default customer file.
.EXAMPLE
    Get-MailTemplates
.INPUTS
    [System.String]
.OUTPUTS
    [PSCustomObject]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.3.3
    Author          : Imraan Iotana
    Creation Date   : June 2026
    Last Update     : August 2026
#>
####################################################################################################
function Get-MailTemplates {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false,HelpMessage='Optional explicit path to a Settings.Customer.*.psd1 file.')]
        [System.String]$SettingsFilePath
    )

    # PREPARATION - RESOLVE SETTINGS FILE
    # Prefer the active customer template selected in the inventory
    if (Test-String -IsEmpty $SettingsFilePath) {
        [System.Object]$ActiveCustomerTemplate = Get-ActiveCustomerTemplate
        if ($null -ne $ActiveCustomerTemplate) {
            $SettingsFilePath = [System.String]$ActiveCustomerTemplate.TemplatePath
        }
    }

    # VALIDATION
    # Stop early when the settings file path is still unresolved or no longer exists
    if (Test-String -IsEmpty $SettingsFilePath) {
        return @()
    }
    if (-not (Test-Path -Path $SettingsFilePath -PathType Leaf)) {
        Write-Line "The selected customer settings file cannot be found: $SettingsFilePath" -Type Warning
        return @()
    }

    # EXECUTION - IMPORT SETTINGS DATA
    # Read the customer data file as a hashtable so we can inspect MailTemplates safely
    try {
        [System.Collections.Hashtable]$TemplateContent = Import-CustomerTemplateData -SettingsFilePath $SettingsFilePath
    }
    catch {
        Write-Line "The settings file could not be parsed: $SettingsFilePath" -Type Warning
        Write-ErrorReport -ErrorRecord $_
        return @()
    }

    [System.Object]$MailTemplates = $null
    if ($TemplateContent.ContainsKey('MailTemplates')) {
        $MailTemplates = $TemplateContent.MailTemplates
    }

    if ($null -eq $MailTemplates -or -not ($MailTemplates -is [System.Collections.IDictionary])) {
        return @()
    }

    # POST-EXECUTION - RETURN COMBOBOX OBJECTS
    # Normalize each template entry into the structure expected by New-ComboBox/Update-ComboBox
    foreach ($TemplateName in ($MailTemplates.Keys | Sort-Object)) {
        [System.Object]$MailTemplateContent = $MailTemplates[$TemplateName]

        [PSCustomObject]@{
            ComboBoxName         = [System.String]$TemplateName
            TemplateName         = [System.String]$TemplateName
            TemplateKey          = [System.String]$TemplateName
            Subject              = $MailTemplateContent.Subject
            Body                 = $MailTemplateContent.Body
            Content              = $MailTemplateContent
            TemplateSettingsPath = $SettingsFilePath
            CustomerIdentity     = $TemplateContent.Identity
        }
    }
}

### END OF FUNCTION
####################################################################################################
