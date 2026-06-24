####################################################################################################
<#
.SYNOPSIS
    Imports the Application Selection feature into the Intake sub-tab.
.DESCRIPTION
    This function imports the Application Selection feature into the Intake sub-tab by creating a new GroupBox and adding it to the specified parent TabPage.
.EXAMPLE
    Import-FeatureIntakeApplicationSelection -InputObject $MyApplicationObject -ParentTabPage $MyTabPage
.INPUTS
    [PSCustomObject]
    [System.Windows.Forms.TabPage]
    [System.Windows.Forms.GroupBox]
.OUTPUTS
    [System.Windows.Forms.GroupBox]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. All rights reserved.
    Version         : 6.0.0.0
    Author          : Imraan Iotana
    Creation Date   : May 2026
    Last Update     : June 2026
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

        [Parameter(Mandatory=$false,HelpMessage='The GroupBox above which this Feature will be added.')]
        [System.Windows.Forms.GroupBox]$GroupBoxAbove,

        [Parameter(Mandatory=$false,HelpMessage='The color of the GroupBox.')]
        [System.String]$Color
    )

    try {
        # EXECUTION - GROUPBOX
        # Feature properties
        [System.Collections.Hashtable]$FeatureProperties = @{
            InputObject     = $InputObject
            ParentTabPage   = $ParentTabPage
            Title           = 'MAIL TEMPLATE SELECTION'
            Color           = $Color
            NumberOfRows    = 3
            GroupBoxAbove   = $GroupBoxAbove
        }
        # Create the GroupBox
        [System.Windows.Forms.GroupBox]$FeatureGroupBox = New-GroupBox @FeatureProperties -OnSubTab

        # Derive graphics keys from the current tab hierarchy
        [System.Windows.Forms.TabControl]$ParentTabControl = $ParentTabPage.Parent
        [System.Windows.Forms.Control]$ParentTab = if ($ParentTabControl -is [System.Windows.Forms.TabControl]) { $ParentTabControl.Parent } else { $null }
        [System.String]$GraphicsParentKey = if ($ParentTab -is [System.Windows.Forms.TabPage]) { $ParentTab.Text } else { $null }
        [System.String]$GraphicsSubTabKey = ([System.Globalization.CultureInfo]::CurrentCulture.TextInfo.ToTitleCase($ParentTabPage.Text.ToLower()) -replace '\s+', '')

        # Build the ComboBox property path used by New-ComboBox
        [System.String]$MailTemplateSelectionPropertyName = "ComboBoxes.$GraphicsParentKey.$GraphicsSubTabKey.MailTemplateSelection"

        # Create Graphics hashtable entries for this tab path when they do not already exist
        if ($GraphicsParentKey -and (-not $Global:Graphics.ComboBoxes.$GraphicsParentKey.ContainsKey($GraphicsSubTabKey))) { $Global:Graphics.ComboBoxes.$GraphicsParentKey.$GraphicsSubTabKey = @{} }

        # PREPARATION - MAIL TEMPLATES
        [System.Object[]]$MailTemplates = Get-MailTemplates

        # EXECUTION - COMBOBOXES
        # Set the ComboBox properties
        [System.Collections.Hashtable]$SelectedApplicationComboBoxProperties = @{
            RowNumber           = 1
            Label               = 'Select Mail Template'
            PropertyName        = $MailTemplateSelectionPropertyName
            ToolTip             = 'The list of mail templates to select from.'
            SizeType            = 'Medium'
            MailTemplates       = $MailTemplates
        }
        # Create the ComboBox
        [System.Windows.Forms.ComboBox]$MailTemplateSelectionComboBox = New-ComboBox @SelectedApplicationComboBoxProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ReturnComboBox
        $Global:Graphics.ComboBoxes.$GraphicsParentKey.$GraphicsSubTabKey.MailTemplateSelection = $MailTemplateSelectionComboBox

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
                Function        = { Update-ComboBox -ComboBox $MailTemplateSelectionComboBox -MailTemplates (Get-MailTemplates) }.GetNewClosure()
            }
        )
        # Set the action button properties
        [System.Collections.Hashtable]$ActionButtonProperties = @{
            ColumnNumber    = 1
            Text            = 'Create New Mail'
            PNGFileName     = 'mail_yellow'
            SizeType        = 'Large'
            ToolTip         = 'Create a new mail based on the selected template.'
            Function        = { New-MailFromTemplate -ComboBox $MailTemplateSelectionComboBox }.GetNewClosure()
        }
        # Add the Buttons
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
    Write-MailTemplateToHost -ComboBox $Global:Graphics.ComboBoxes.ApplicationIntake.MailTemplateSelection
.PARAMETER ComboBox
    Required ComboBox containing mail template items.
.INPUTS
    [System.Windows.Forms.ComboBox]
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
function Write-MailTemplateToHost {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The mail template ComboBox.')]
        [System.Windows.Forms.ComboBox]$ComboBox
    )

    # Guard against calls before the UI control exists.
    if ($null -eq $ComboBox -or $ComboBox.IsDisposed) {
        Write-Line 'The mail template ComboBox is not available.' -Type Warning
        return
    }

    # A template must be selected before we can show details.
    if ($null -eq $ComboBox.SelectedItem) {
        Write-Line 'No mail template is selected.' -Type Warning
        return
    }

    # Read the selected template once and write the key mail fields.
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
    New-MailFromTemplate -ComboBox $Global:Graphics.ComboBoxes.ApplicationIntake.MailTemplateSelection
.PARAMETER ComboBox
    Required ComboBox containing mail template items.
.INPUTS
    [System.Windows.Forms.ComboBox]
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
function New-MailFromTemplate {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The mail template ComboBox.')]
        [System.Windows.Forms.ComboBox]$ComboBox
    )

    # Guard against calls before the UI control exists.
    if ($null -eq $ComboBox -or $ComboBox.IsDisposed) {
        Write-Line 'The mail template ComboBox is not available.' -Type Warning
        return
    }

    # A template must be selected before creating a draft mail.
    if ($null -eq $ComboBox.SelectedItem) {
        Write-Line 'No mail template is selected.' -Type Warning
        return
    }

    [System.Object]$SelectedTemplate = $ComboBox.SelectedItem

    # Keep To optional and support common field names if present in customer template content.
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
    Gets customer templates from the Customer folder.
.DESCRIPTION
    This function retrieves customer template files from the Customer folder and its subfolders,
    imports their content, and returns a custom object for each template to populate the
    Template Selection ComboBox.
.EXAMPLE
    Get-CustomerTemplates
.INPUTS
    [System.String]
.OUTPUTS
    [PSCustomObject]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. All rights reserved.
    Version         : 6.0.0.0
    Author          : Imraan Iotana
    Creation Date   : June 2026
    Last Update     : June 2026
#>
####################################################################################################
function Get-MailTemplates {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false,HelpMessage='Optional explicit path to a Settings.Customer.*.psd1 file.')]
        [System.String]$SettingsFilePath
    )

    # PREPARATION - RESOLVE SETTINGS FILE
    # Prefer the customer template currently selected in Intake Settings.
    if (Test-String -IsEmpty $SettingsFilePath) {
        # First preference: currently selected customer template in the Template Selection combo box.
        [System.Object]$TemplateSelectionComboBox = $null
        if ($Global:Graphics.ComboBoxes -is [System.Collections.IDictionary]) {
            foreach ($ParentKey in $Global:Graphics.ComboBoxes.Keys) {
                [System.Object]$ParentNode = $Global:Graphics.ComboBoxes.$ParentKey
                if ($ParentNode -is [System.Collections.IDictionary]) {
                    foreach ($SubTabKey in $ParentNode.Keys) {
                        [System.Object]$SubTabNode = $ParentNode.$SubTabKey
                        if (($SubTabNode -is [System.Collections.IDictionary]) -and $SubTabNode.ContainsKey('TemplateSelection')) {
                            $TemplateSelectionComboBox = $SubTabNode.TemplateSelection
                            break
                        }
                    }
                }
                if ($null -ne $TemplateSelectionComboBox) { break }
            }
        }
        if ($null -eq $TemplateSelectionComboBox -and ($Global:Graphics.ComboBoxes.ApplicationIntake -is [System.Collections.IDictionary]) -and $Global:Graphics.ComboBoxes.ApplicationIntake.ContainsKey('TemplateSelection')) {
            $TemplateSelectionComboBox = $Global:Graphics.ComboBoxes.ApplicationIntake.TemplateSelection
        }
        if ($null -ne $TemplateSelectionComboBox -and $null -ne $TemplateSelectionComboBox.SelectedItem) {
            $SettingsFilePath = $TemplateSelectionComboBox.SelectedItem.TemplatePath
        }
    }

    # If no explicit/selected file is available, try the Default customer settings file.
    if (Test-String -IsEmpty $SettingsFilePath) {
        [System.String]$CustomerFolder = Join-Path -Path $Global:ApplicationObject.RootFolder -ChildPath 'Customer'
        if (-not (Test-Path -Path $CustomerFolder -PathType Container)) {
            Write-Line "The customer folder cannot be found: $CustomerFolder" -Type Warning
            return @()
        }

        # Fallback to the Default customer settings file when no customer template is selected yet.
        [System.String]$DefaultSettingsPath = Join-Path -Path $CustomerFolder -ChildPath 'Default\Settings.Customer.Default.psd1'
        if (Test-Path -Path $DefaultSettingsPath -PathType Leaf) {
            $SettingsFilePath = $DefaultSettingsPath
        }
    }

    # VALIDATION
    # Stop early when the settings file path is still unresolved or no longer exists.
    if (Test-String -IsEmpty $SettingsFilePath) {
        Write-Line 'No customer settings file is available to read mail templates from.' -Type Warning
        return @()
    }
    if (-not (Test-Path -Path $SettingsFilePath -PathType Leaf)) {
        Write-Line "The selected customer settings file cannot be found: $SettingsFilePath" -Type Warning
        return @()
    }

    # EXECUTION - IMPORT SETTINGS DATA
    # Read the customer data file as a hashtable so we can inspect MailTemplates safely.
    try {
        [System.Collections.Hashtable]$TemplateContent = Import-PowerShellDataFile -Path $SettingsFilePath
    }
    catch {
        Write-Line "The settings file could not be parsed: $SettingsFilePath" -Type Warning
        Write-ErrorReport -ErrorRecord $_
        return @()
    }

    [System.Object]$MailTemplates = $null
    # Primary key is MailTemplates; keep legacy support for accidental '$MailTemplates'.
    if ($TemplateContent.ContainsKey('MailTemplates')) {
        $MailTemplates = $TemplateContent.MailTemplates
    }
    elseif ($TemplateContent.ContainsKey('$MailTemplates')) {
        # Backward-compatible fallback for accidentally prefixed keys.
        $MailTemplates = $TemplateContent.'$MailTemplates'
    }

    if ($null -eq $MailTemplates -or -not ($MailTemplates -is [System.Collections.IDictionary])) {
        return @()
    }

    # POST-EXECUTION - RETURN COMBOBOX OBJECTS
    # Normalize each template entry into the structure expected by New-ComboBox/Update-ComboBox.
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

