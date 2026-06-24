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
            NumberOfRows    = 1
            GroupBoxAbove   = $GroupBoxAbove
        }
        # Create the GroupBox
        [System.Windows.Forms.GroupBox]$FeatureGroupBox = New-GroupBox @FeatureProperties -OnSubTab

        # PREPARATION - MAIL TEMPLATES
        [System.Object[]]$MailTemplates = Get-MailTemplates

        # EXECUTION - COMBOBOXES
        # Set the ComboBox properties
        [System.Collections.Hashtable]$SelectedApplicationComboBoxProperties = @{
            RowNumber           = 1
            Label               = 'Select Mail Template'
            PropertyName        = 'ComboBoxes.ApplicationIntake.MailTemplateSelection'
            ToolTip             = 'The list of mail templates to select from.'
            SizeType            = 'Medium'
            MailTemplates       = $MailTemplates
        }
        # Create the ComboBox
        $Global:Graphics.ComboBoxes.ApplicationIntake.MailTemplateSelection = New-ComboBox @SelectedApplicationComboBoxProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ReturnComboBox

        # EXECUTION - BUTTONS
        # Set the Small Buttons properties
        [System.Collections.Hashtable[]]$SmallButtonsPropertiesArray = @(
            @{ # Testing duplicate buttons with the same function to ensure they work as expected
                ColumnNumber    = 5
                Text            = 'Details'
                PNGFileName     = 'information'
                SizeType        = 'Small'
                ToolTip         = 'View details of the selected template.'
                Function        = {
                    [System.Windows.Forms.ComboBox]$ComboBox = $Global:Graphics.ComboBoxes.ApplicationIntake.MailTemplateSelection
                    if ($null -eq $ComboBox.SelectedItem) {
                        Write-Line 'No mail template is selected.' -Type Warning
                        return
                    }
                    [System.Object]$SelectedTemplate = $ComboBox.SelectedItem
                    Write-Line "Mail Template: $($SelectedTemplate.TemplateName)" -Type Special
                    Write-Line "Subject: $($SelectedTemplate.Subject)" -Type Info
                    Write-Line "Settings File: $($SelectedTemplate.TemplateSettingsPath)" -Type Info
                }.GetNewClosure()
            }
            @{
                ColumnNumber    = 6
                Text            = 'Refresh'
                PNGFileName     = 'arrow_refresh'
                SizeType        = 'Small'
                ToolTip         = 'Refresh the list of mail templates from the selected customer settings file.'
                Function        = { Update-ComboBox -ComboBox $Global:Graphics.ComboBoxes.ApplicationIntake.MailTemplateSelection -MailTemplates (Get-MailTemplates) }.GetNewClosure()
            }
        )
        # Add the Buttons
        New-ButtonLine -InputObject $InputObject -ButtonPropertiesArray $SmallButtonsPropertiesArray -ParentGroupBox $FeatureGroupBox -RowNumber 1

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
    if (Test-String -IsEmpty $SettingsFilePath) {
        # First preference: currently selected customer template in the Template Selection combo box.
        $SettingsFilePath = $Global:Graphics.ComboBoxes.ApplicationIntake.TemplateSelection.SelectedItem.TemplatePath
    }

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
    if (Test-String -IsEmpty $SettingsFilePath) {
        Write-Line 'No customer settings file is available to read mail templates from.' -Type Warning
        return @()
    }
    if (-not (Test-Path -Path $SettingsFilePath -PathType Leaf)) {
        Write-Line "The selected customer settings file cannot be found: $SettingsFilePath" -Type Warning
        return @()
    }

    # EXECUTION - IMPORT SETTINGS DATA
    try {
        [System.Collections.Hashtable]$TemplateContent = Import-PowerShellDataFile -Path $SettingsFilePath
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
    elseif ($TemplateContent.ContainsKey('$MailTemplates')) {
        # Backward-compatible fallback for accidentally prefixed keys.
        $MailTemplates = $TemplateContent.'$MailTemplates'
    }

    if ($null -eq $MailTemplates -or -not ($MailTemplates -is [System.Collections.IDictionary])) {
        return @()
    }

    # POST-EXECUTION - RETURN COMBOBOX OBJECTS
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



