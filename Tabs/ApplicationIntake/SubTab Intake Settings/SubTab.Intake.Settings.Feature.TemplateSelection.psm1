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
function Import-FeatureIntakeTemplateSelection {
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
            Title           = 'TEMPLATE SELECTION'
            Color           = $Color
            NumberOfRows    = 1
            GroupBoxAbove   = $GroupBoxAbove
        }
        # Create the GroupBox
        [System.Windows.Forms.GroupBox]$FeatureGroupBox = New-GroupBox @FeatureProperties -OnSubTab

        # EXECUTION - COMBOBOXES
        # Set the ComboBox properties
        [System.Collections.Hashtable]$SelectedApplicationComboBoxProperties = @{
            RowNumber           = 1
            Label               = 'Select Customer Template'
            PropertyName        = 'ComboBoxes.ApplicationIntake.TemplateSelection'
            ToolTip             = 'The list of customer templates to select from.'
            SizeType            = 'Medium'
            CustomerTemplates   = Get-CustomerTemplates
            DefaultValue        = 'Default'
        }
        # Create the ComboBox
        $Global:Graphics.ComboBoxes.ApplicationIntake.TemplateSelection = New-ComboBox @SelectedApplicationComboBoxProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ReturnComboBox

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
                    Write-Line "Template Identity: $($Global:Graphics.ComboBoxes.ApplicationIntake.TemplateSelection.SelectedItem.Identity)" -Type Special
                    Write-Line "Template Path: $($Global:Graphics.ComboBoxes.ApplicationIntake.TemplateSelection.SelectedItem.TemplatePath)" -Type Info
                    Write-Line "Template Application SubFolders:" -Type Info
                    $Global:Graphics.ComboBoxes.ApplicationIntake.TemplateSelection.SelectedItem.ApplicationFolderSubFolders.GetEnumerator() | Sort-Object -Property Value | Format-Table -Property Name, Value -AutoSize | Out-String | Write-Host
                }.GetNewClosure()
            }
            @{
                ColumnNumber    = 6
                Text            = 'Open Folder'
                PNGFileName     = 'folder_go'
                SizeType        = 'Small'
                ToolTip         = 'Open the folder containing the templates.'
                Function        = { Open-Folder -Path $Global:Graphics.ComboBoxes.ApplicationIntake.TemplateSelection.SelectedItem.TemplatePath }.GetNewClosure()
            }
            @{
                ColumnNumber    = 7
                Text            = 'Refresh'
                PNGFileName     = 'arrow_refresh'
                SizeType        = 'Small'
                ToolTip         = 'Refresh the list of customer templates.'
                Function        = { Update-ComboBox -ComboBox $Global:Graphics.ComboBoxes.ApplicationIntake.TemplateSelection -CustomerTemplates (Get-CustomerTemplates) }.GetNewClosure()
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



