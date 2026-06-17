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
function Import-FeatureExtraDocumentInformation {
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
            Title           = 'EXTRA DOCUMENT INFORMATION'
            Color           = $Color
            NumberOfRows    = 2
            GroupBoxAbove   = $GroupBoxAbove
        }
        # Create the GroupBox
        [System.Windows.Forms.GroupBox]$FeatureGroupBox = New-GroupBox @FeatureProperties -OnSubTab

        # TEXTBOXES
        # Set the VendorNameTextBox properties
        [System.Collections.Hashtable]$VendorNameTextBoxProperties = @{
            RowNumber       = 1
            Label           = 'My Full Name'
            PropertyName    = 'TextBoxes.IntakeSettings.ExtraDocumentInformation.UserFullName'
            ToolTip         = 'The full name of the user that will be used in the document properties.'
            SizeType        = 'Medium'
            SmallButtons    = @(@(5,'Copy'),(6,'Paste'))
        }
        # Set the ApplicationNameTextBox properties
        [System.Collections.Hashtable]$ApplicationNameTextBoxProperties = @{
            RowNumber       = 2
            Label           = 'My Email Address'
            PropertyName    = 'TextBoxes.IntakeSettings.ExtraDocumentInformation.UserEmailAddress'
            ToolTip         = 'The email address of the user that will be used in the document properties.'
            SizeType        = 'Medium'
            SmallButtons    = @(@(5,'Copy'),(6,'Paste'))

        }
        # Create the TextBoxes
        $Global:Graphics.TextBoxes.IntakeSettings.ExtraDocumentInformation.UserFullName      = New-TextBox @VendorNameTextBoxProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ReturnTextBox
        $Global:Graphics.TextBoxes.IntakeSettings.ExtraDocumentInformation.UserEmailAddress  = New-TextBox @ApplicationNameTextBoxProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ReturnTextBox

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
            ComboBoxName = $TemplateName
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
