####################################################################################################
<#
.SYNOPSIS
    Imports the Customer Template Selection feature into the General Settings sub-tab.
.DESCRIPTION
    This function imports the Customer Template Selection feature into the General Settings sub-tab by creating a new GroupBox and adding it to the specified parent TabPage.
.EXAMPLE
    Import-FeatureCustomerTemplateSelection -InputObject $MyApplicationObject -ParentTabPage $MyTabPage
.INPUTS
    [PSCustomObject]
    [System.Windows.Forms.TabPage]
    [System.Windows.Forms.GroupBox]
    [System.String]
.OUTPUTS
    [System.Windows.Forms.GroupBox]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. All rights reserved.
    Version         : 6.0.0.1
    Author          : Imraan Iotana
    Creation Date   : May 2026
    Last Update     : July 2026
#>
####################################################################################################
function Import-FeatureCustomerTemplateSelection {
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
            Title           = 'CUSTOMER TEMPLATE SELECTION'
            Color           = $Color
            NumberOfRows    = 1
            GroupBoxAbove   = $GroupBoxAbove
        }
        # EXECUTION - GROUPBOX
        # Create the GroupBox
        [System.Windows.Forms.GroupBox]$FeatureGroupBox = New-GroupBox @GroupBoxProperties -OnSubTab

        # EXECUTION - SUBKEY
        # Create a unique SubKey for the TextBoxes and ComboBoxes
        [System.String]$SubKeyForBoxes = New-SubKeyForBoxes -ParentTabPage $ParentTabPage -PassThru

        # EXECUTION - COMBOBOXES
        # Set the ComboBox properties
        [System.Collections.Hashtable]$SelectedApplicationComboBoxProperties = @{
            RowNumber           = 1
            Label               = 'Select Customer Template'
            PropertyName        = "ComboBoxes.$SubKeyForBoxes.TemplateSelection"
            ToolTip             = 'The list of customer templates to select from.'
            SizeType            = 'Medium'
            CustomerTemplates   = Get-CustomerTemplates
            DefaultValue        = 'Default'
        }
        # Create the ComboBox
        [System.Windows.Forms.ComboBox]$TemplateSelectionComboBox = New-ComboBox @SelectedApplicationComboBoxProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ReturnComboBox
        $Global:Graphics.ComboBoxes[$SubKeyForBoxes].TemplateSelection = $TemplateSelectionComboBox

        # When the selected customer template changes, refresh the mail template list as well.
        $TemplateSelectionComboBox.Add_SelectedIndexChanged([System.EventHandler]{
            param($ChangedControl, $ChangedEvent)

            [System.Windows.Forms.ComboBox]$MailTemplateSelection = Get-ComboBoxObject -ComboBoxName 'MailTemplateSelection'
            [System.String]$SettingsFilePath = $null

            if ($null -ne $ChangedControl -and $null -ne $ChangedControl.SelectedItem -and $null -ne $ChangedControl.SelectedItem.PSObject.Properties['TemplatePath']) {
                $SettingsFilePath = [System.String]$ChangedControl.SelectedItem.TemplatePath
            }

            if ($null -eq $MailTemplateSelection -or $MailTemplateSelection.IsDisposed) {
                return
            }

            Update-ComboBox -ComboBox $MailTemplateSelection -MailTemplates (Get-MailTemplates -SettingsFilePath $SettingsFilePath)
        }.GetNewClosure())

        # EXECUTION - BUTTONS
        # Set the Small Buttons properties
        [System.Collections.Hashtable[]]$SmallButtonsPropertiesArray = @(
            @{
                ColumnNumber    = 5
                Text            = 'Details'
                PNGFileName     = 'information'
                SizeType        = 'Small'
                ToolTip         = 'View details of the selected template.'
                Function        = { Write-CustomerTemplateToHost -ComboBox $TemplateSelectionComboBox }.GetNewClosure()
            }
            @{
                ColumnNumber    = 6
                Text            = 'Open Folder'
                PNGFileName     = 'folder_go'
                SizeType        = 'Small'
                ToolTip         = 'Open the folder containing the templates.'
                Function        = { Open-Folder -Path $TemplateSelectionComboBox.SelectedItem.TemplatePath }.GetNewClosure()
            }
            @{
                ColumnNumber    = 7
                Text            = 'Refresh'
                PNGFileName     = 'arrow_refresh'
                SizeType        = 'Small'
                ToolTip         = 'Refresh the list of customer templates.'
                Function        = { Update-ComboBox -ComboBox $TemplateSelectionComboBox -CustomerTemplates (Get-CustomerTemplates) }.GetNewClosure()
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
    Writes details of the selected customer template to the host.
.DESCRIPTION
    This function reads the selected item from the Customer Template Selection ComboBox and writes
    key template details (identity, path, and configured application subfolders) to the host.
.EXAMPLE
    Write-CustomerTemplateToHost -ComboBox $Global:Graphics.ComboBoxes.ApplicationSettings.TemplateSelection
.PARAMETER ComboBox
    Required ComboBox containing customer template items.
.INPUTS
    [System.Windows.Forms.ComboBox]
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. All rights reserved.
    Version         : 6.0.0.1
    Author          : Imraan Iotana
    Creation Date   : July 2026
    Last Update     : July 2026
#>
####################################################################################################
function Write-CustomerTemplateToHost {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The customer template ComboBox.')]
        [System.Windows.Forms.ComboBox]$ComboBox
    )

    # VALIDATION
    # If the ComboBox is null or disposed, write a warning and return.
    if ($null -eq $ComboBox -or $ComboBox.IsDisposed) {
        Write-Line 'The customer template ComboBox is not available.' -Type Warning
        return
    }

    # VALIDATION
    # If no item is selected in the ComboBox, write a warning and return.
    if ($null -eq $ComboBox.SelectedItem) {
        Write-Line 'No customer template is selected.' -Type Warning
        return
    }

    # PREPARATION
    # Read the selected template once and write the key template fields.
    [System.Object]$SelectedTemplate = $ComboBox.SelectedItem

    # EXECUTION
    # Write key details for the selected customer template.
    Write-Line "Template Identity: $($SelectedTemplate.Identity)" -Type Special
    Write-Line "Template Path: $($SelectedTemplate.TemplatePath)" -Type Info
    Write-Line 'Template Application SubFolders:' -Type Info

    # EXECUTION
    # Write configured subfolder mappings when available.
    if ($null -ne $SelectedTemplate.ApplicationFolderSubFolders -and $SelectedTemplate.ApplicationFolderSubFolders -is [System.Collections.IDictionary]) {
        $SelectedTemplate.ApplicationFolderSubFolders.GetEnumerator() | Sort-Object -Property Value | Format-Table -Property Name, Value -AutoSize | Out-String | Write-Host
    }
    else {
        Write-Line 'No ApplicationFolderSubFolders are defined on the selected template.' -Type Warning
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
function Get-CustomerTemplates {
    param (
        $FolderToSearch = (Join-Path -Path $Global:ApplicationObject.RootFolder -ChildPath 'Customer')
    )
    
    # VALIDATION
    # Check if the specified folder exists
    if (-Not (Test-Path -Path $FolderToSearch -PathType Container)) {
        Write-Warning "The specified folder '$FolderToSearch' does not exist. Returning an empty list."
        return @()
    }

    # EXECUTION
    # Get all .psd1 files in the specified folder and subfolders that start with 'Settings.Customer.'
    [System.IO.FileInfo[]]$TemplateFiles = Get-ChildItem -Path $FolderToSearch -Filter '*.psd1' -File -Recurse |
        Where-Object { $_.BaseName.StartsWith('Settings.Customer.') } |
        Sort-Object -Property Name
    # Return an empty array if no template files are found
    if ($TemplateFiles.Count -eq 0) {
        return @()
    }

    foreach ($TemplateFile in $TemplateFiles) {
        # Get the content of the template file
        $TemplateContent = Import-PowerShellDataFile -Path $TemplateFile.FullName

        # Extract the template name by removing the 'Settings.Customer.' prefix from the base name
        $TemplateName = $TemplateFile.BaseName -replace '^Settings\.Customer\.', ''

        # Create a custom object for each template file
        [PSCustomObject]@{
            ComboBoxName = $TemplateContent.Identity
            TemplatePath = $TemplateFile.FullName
            TemplateName = $TemplateName
            FileName     = $TemplateFile.Name
            FullName     = $TemplateFile.FullName
            Directory    = $TemplateFile.DirectoryName
            Content      = $TemplateContent
            Identity     = $TemplateContent.Identity
            ApplicationFolderSubFolders = $TemplateContent.ApplicationFolderSubFolders
        }
    }
}

### END OF FUNCTION
####################################################################################################



