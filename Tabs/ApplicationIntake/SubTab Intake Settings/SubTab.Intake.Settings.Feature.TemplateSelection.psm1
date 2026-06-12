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
            NumberOfRows    = 2
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
            TextColor           = $Color
            CustomerTemplates   = Get-CustomerTemplates
            DefaultValue        = 'Default'
        }
        # Create the ComboBoxes
        $Global:Graphics.ComboBoxes.ApplicationIntake.TemplateSelection = New-ComboBox @SelectedApplicationComboBoxProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ReturnComboBox

        # EXECUTION - BUTTONS
        # Set the Import Button properties
        [System.Collections.Hashtable[]]$ImportButtonPropertiesArray = @(
            @{
                ColumnNumber    = 1
                Text            = 'Select'
                PNGFileName     = 'page_white_word'
                SizeType        = 'Medium'
                ToolTip         = 'Select the template.'
                Function        = { Write-Line 'This functon is not implemented yet.' }.GetNewClosure()
            }
        )
        # Set the Small Buttons properties
        [System.Collections.Hashtable[]]$SmallButtonsPropertiesArray = @(
            @{ # Testing duplicate buttons with the same function to ensure they work as expected
                ColumnNumber    = 5
                Text            = 'Details'
                PNGFileName     = 'information'
                SizeType        = 'Small'
                ToolTip         = 'View details of the selected template.'
                Function        = {
                    # Write the details of the selected file
                    $Global:Graphics.ComboBoxes.ApplicationIntake.TemplateSelection.SelectedItem | Format-List | Out-String | Write-Host
                    # Import and display the content of the selected template file
                    Import-PowerShellDataFile -Path $Global:Graphics.ComboBoxes.ApplicationIntake.TemplateSelection.SelectedItem.TemplatePath | Format-List | Out-String | Write-Host
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
        New-ButtonLine -InputObject $InputObject -ButtonPropertiesArray $ImportButtonPropertiesArray -ParentGroupBox $FeatureGroupBox -RowNumber 2

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


function Get-CustomerTemplates {
    param (
        $FolderToSearch = (Join-Path -Path $Global:ApplicationObject.RootFolder -ChildPath 'Settings')
    )
    
    # VALIDATION
    if (-Not (Test-Path -Path $FolderToSearch -PathType Container)) {
        Write-Warning "The specified folder '$FolderToSearch' does not exist. Returning an empty list."
        return @()
    }

    # EXECUTION
    [System.IO.FileInfo[]]$TemplateFiles = Get-ChildItem -Path $FolderToSearch -Filter '*.psd1' -File |
        Where-Object { $_.BaseName.StartsWith('Settings.Customer.') } |
        Sort-Object -Property Name

    if ($TemplateFiles.Count -eq 0) {
        return @()
    }

    foreach ($TemplateFile in $TemplateFiles) {
        $TemplateName = $TemplateFile.BaseName -replace '^Settings\.Customer\.', ''

        [PSCustomObject]@{
            ComboBoxName = $TemplateName
            TemplatePath = $TemplateFile.FullName
            TemplateName = $TemplateName
            FileName     = $TemplateFile.Name
            FullName     = $TemplateFile.FullName
            Directory    = $TemplateFile.DirectoryName
        }
    }
}

### END OF FUNCTION
####################################################################################################
