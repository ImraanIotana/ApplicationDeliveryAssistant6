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
function Import-FeatureIntakeCustomerTemplateSelection {
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
            Title           = 'CUSTOMER TEMPLATE SELECTION'
            Color           = $Color
            NumberOfRows    = 1
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
        [System.String]$TemplateSelectionPropertyName = "ComboBoxes.$GraphicsParentKey.$GraphicsSubTabKey.TemplateSelection"

        # Create Graphics hashtable entries for this tab path when they do not already exist
        if ($GraphicsParentKey) {
            if (-not $Global:Graphics.ComboBoxes.ContainsKey($GraphicsParentKey) -or $Global:Graphics.ComboBoxes.$GraphicsParentKey -isnot [System.Collections.IDictionary]) {
                $Global:Graphics.ComboBoxes.$GraphicsParentKey = @{}
            }
            if (-not $Global:Graphics.ComboBoxes.$GraphicsParentKey.ContainsKey($GraphicsSubTabKey)) {
                $Global:Graphics.ComboBoxes.$GraphicsParentKey.$GraphicsSubTabKey = @{}
            }
        }

        # EXECUTION - COMBOBOXES
        # Set the ComboBox properties
        [System.Collections.Hashtable]$SelectedApplicationComboBoxProperties = @{
            RowNumber           = 1
            Label               = 'Select Customer Template'
            PropertyName        = $TemplateSelectionPropertyName
            ToolTip             = 'The list of customer templates to select from.'
            SizeType            = 'Medium'
            CustomerTemplates   = Get-CustomerTemplates
            DefaultValue        = 'Default'
        }
        # Create the ComboBox
        [System.Windows.Forms.ComboBox]$TemplateSelectionComboBox = New-ComboBox @SelectedApplicationComboBoxProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ReturnComboBox
        $Global:Graphics.ComboBoxes.$GraphicsParentKey.$GraphicsSubTabKey.TemplateSelection = $TemplateSelectionComboBox

        # When the selected customer template changes, refresh the mail template list as well.
        $TemplateSelectionComboBox.Add_SelectedIndexChanged([System.EventHandler]{
            param($ChangedControl, $ChangedEvent)

            [System.Windows.Forms.ComboBox]$MailTemplateSelection = $Global:Graphics.ComboBoxes.$GraphicsParentKey.$GraphicsSubTabKey.MailTemplateSelection
            if ($null -eq $MailTemplateSelection -or $MailTemplateSelection.IsDisposed) {
                return
            }

            Update-ComboBox -ComboBox $MailTemplateSelection -MailTemplates (Get-MailTemplates)
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
                Function        = {
                    Write-Line "Template Identity: $($TemplateSelectionComboBox.SelectedItem.Identity)" -Type Special
                    Write-Line "Template Path: $($TemplateSelectionComboBox.SelectedItem.TemplatePath)" -Type Info
                    Write-Line "Template Application SubFolders:" -Type Info
                    $TemplateSelectionComboBox.SelectedItem.ApplicationFolderSubFolders.GetEnumerator() | Sort-Object -Property Value | Format-Table -Property Name, Value -AutoSize | Out-String | Write-Host
                }.GetNewClosure()
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



