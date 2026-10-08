####################################################################################################
<#
.SYNOPSIS
    Imports the Document Generation feature into the Intake Templates sub-tab.
.DESCRIPTION
    This function imports the Document Generation feature into the Intake Templates sub-tab by creating a new GroupBox and adding it to the specified parent TabPage.
    It provides a customer template ComboBox and file-path textboxes for the Word template,
    metadata JSON, and icon folder, plus document-generation actions that validate and generate
    the output document.
    New-TextBox handles graphics registration directly.
.EXAMPLE
    Import-FeatureDocumentGeneration -InputObject $MyApplicationObject -ParentTabPage $MyTabPage
.INPUTS
    [PSCustomObject]
    [System.Windows.Forms.TabPage]
    [System.Windows.Forms.GroupBox]
    [System.String]
.OUTPUTS
    [System.Windows.Forms.GroupBox]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.5.3
    Author          : Imraan Iotana
    Creation Date   : July 2026
    Last Update     : September 2026
#>
####################################################################################################
function Import-FeatureDocumentGeneration {
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
            Title           = 'DOCUMENT GENERATION'
            Color           = $Color
            NumberOfRows    = 4.2
            GroupBoxAbove   = $GroupBoxAbove
        }

        # EXECUTION - GROUPBOX
        # Create the GroupBox
        [System.Windows.Forms.GroupBox]$FeatureGroupBox = New-GroupBox @GroupBoxProperties

        # PREPARATION - COMBOBOX PROPERTIES
        # Set the customer template ComboBox properties
        [System.Collections.Hashtable]$CustomerTemplateComboBoxProperties = @{
            RowNumber           = 1
            Label               = 'Document Customer Template'
            ToolTip             = 'Select a customer template, or choose Use My Template to use the custom Word template textbox.'
            SizeType            = 'Medium'
            CustomerTemplates   = Get-DocumentGenerationTemplateOptions
        }

        # PREPARATION - TEXTBOX PROPERTIES
        # Set the Word template TextBox properties
        [System.Collections.Hashtable]$WordTemplateTextBoxProperties = @{
            RowNumber       = 2
            Label           = 'My Template'
            ToolTip         = 'Select the Word template file that will be filled with metadata values.'
            SizeType        = 'Medium'
            SmallButtons    = @(@(6,'Paste'),@(7,'Open'))
        }
        # Set the Metadata JSON TextBox properties
        [System.Collections.Hashtable]$MetadataJsonTextBoxProperties = @{
            RowNumber       = 3
            Label           = 'Metadata JSON'
            ToolTip         = 'Select the metadata JSON file that contains the values for the Word template.'
            SizeType        = 'Medium'
            SmallButtons    = @(@(6,'Paste'),@(7,'Open'))
        }
        # Set the Icon Folder TextBox properties
        [System.Collections.Hashtable]$IconFolderTextBoxProperties = @{
            RowNumber       = 4
            Label           = 'Icon Folder'
            ToolTip         = 'Select the folder containing the icons/png files.'
            SizeType        = 'Medium'
            SmallButtons    = @(@(6,'Paste'),@(7,'Open'))
        }

        # EXECUTION - COMBOBOX
        # Create the customer template ComboBox
        [System.Windows.Forms.ComboBox]$CustomerTemplateComboBox = New-ComboBox @CustomerTemplateComboBoxProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ReturnComboBox

        # EXECUTION - TEXTBOXES
        # Create the TextBoxes
        [System.Windows.Forms.TextBox]$WordTemplateTextBox  = New-TextBox @WordTemplateTextBoxProperties    -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ReturnTextBox
        [System.Windows.Forms.TextBox]$MetadataJsonTextBox  = New-TextBox @MetadataJsonTextBoxProperties    -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ReturnTextBox
        [System.Windows.Forms.TextBox]$IconFolderTextBox    = New-TextBox @IconFolderTextBoxProperties      -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ReturnTextBox

        # PREPARATION - BUTTONS
        # Set the small browse buttons
        [System.Collections.Hashtable[]]$SmallBrowseButtons = @(
            @{
                RowNumber   = 1
                Text        = 'Refresh Templates'
                PNGFileName = 'arrow_refresh'
                SizeType    = 'Small'
                ToolTip     = 'Refresh the list of customer templates.'
                Function    = { Update-ComboBox -ComboBox $CustomerTemplateComboBox -CustomerTemplates (Get-DocumentGenerationTemplateOptions) }.GetNewClosure()
            }
            @{
                RowNumber   = 2
                Text        = 'Browse Word'
                PNGFileName = 'magnifier'
                SizeType    = 'Small'
                ToolTip     = 'Select the Word template file that will be filled with metadata values.'
                Function    = { Select-File -TextBox $WordTemplateTextBox -Type Word }.GetNewClosure()
            }
            @{
                RowNumber   = 3
                Text        = 'Browse JSON'
                PNGFileName = 'magnifier'
                SizeType    = 'Small'
                ToolTip     = 'Select the metadata JSON file that contains the values for the Word template.'
                Function    = { Select-File -TextBox $MetadataJsonTextBox -Type Json }.GetNewClosure()
            }
            @{
                RowNumber   = 4
                Text        = 'Browse Icons'
                PNGFileName = 'folders_explorer'
                SizeType    = 'Small'
                ToolTip     = 'Select the folder containing the icons/png files.'
                Function    = { Select-Folder -TextBox $IconFolderTextBox }.GetNewClosure()
            }
        )

        # PREPARATION - BUTTONS
        # Set action buttons
        [System.Collections.Hashtable[]]$ActionButtons = @(
            @{
                ColumnNumber    = 1
                Text            = 'Generate'
                PNGFileName     = 'report_word'
                SizeType        = 'Medium'
                ToolTip         = 'Generate a Word document using the selected customer template, or custom textbox path when Use My Template is selected.'
                Function        = {
                    [System.String]$ResolvedWordTemplatePath = Resolve-DocumentGenerationTemplatePath -WordTemplatePath $WordTemplateTextBox.Text -SelectedCustomerTemplate $CustomerTemplateComboBox.SelectedItem -SelectedCustomerTemplateText $CustomerTemplateComboBox.Text
                    Invoke-DocumentGeneration -WordTemplatePath $ResolvedWordTemplatePath -MetaDataJsonPath $MetadataJsonTextBox.Text -IconFolderPath $IconFolderTextBox.Text -OpenOutputFolder
                }.GetNewClosure()
            }
            @{
                ColumnNumber    = 5
                Text            = 'Validate Input'
                PNGFileName     = 'html_valid'
                SizeType        = 'Medium'
                ToolTip         = 'Validate selected template input, metadata JSON, and icon folder.'
                Function        = {
                    [System.String]$ResolvedWordTemplatePath = Resolve-DocumentGenerationTemplatePath -WordTemplatePath $WordTemplateTextBox.Text -SelectedCustomerTemplate $CustomerTemplateComboBox.SelectedItem -SelectedCustomerTemplateText $CustomerTemplateComboBox.Text
                    Confirm-DocumentGenerationInput -WordTemplatePath $ResolvedWordTemplatePath -MetaDataJsonPath $MetadataJsonTextBox.Text -IconFolderPath $IconFolderTextBox.Text
                }.GetNewClosure()
            }
        )

        # EXECUTION - BUTTONS
        # Create the small browse buttons
        New-ButtonLine -InputObject $InputObject -ButtonPropertiesArray $SmallBrowseButtons -ParentGroupBox $FeatureGroupBox -ColumnNumber 5
        # Create the action buttons
        New-ButtonLine -InputObject $InputObject -ButtonPropertiesArray $ActionButtons -ParentGroupBox $FeatureGroupBox -RowNumber 5

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
    Gets template options for Document Generation including a custom-template mode.
.DESCRIPTION
    Returns customer templates plus a first option named Use My Template.
.EXAMPLE
    Get-DocumentGenerationTemplateOptions
.INPUTS
    None.
.OUTPUTS
    [PSCustomObject]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.3.3
    Author          : Imraan Iotana
    Creation Date   : July 2026
    Last Update     : August 2026
#>
####################################################################################################
function Get-DocumentGenerationTemplateOptions {
    [CmdletBinding()]
    param ()

    [System.Collections.Generic.List[System.Object]]$Options = New-Object 'System.Collections.Generic.List[System.Object]'

    # Add explicit custom option so textbox mode is intentional and visible.
    [void]$Options.Add([PSCustomObject]@{
        ComboBoxName = 'Use My Template'
        TemplatePath = ''
        TemplateName = ''
        Content      = $null
        Identity     = 'Custom Template'
        Directory    = ''
        IsCustomTemplate = $true
    })

    [System.Object[]]$CustomerTemplates = @(Get-CustomerTemplates)
    foreach ($CustomerTemplate in $CustomerTemplates) {
        [void]$Options.Add($CustomerTemplate)
    }

    return @($Options)
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Resolves the Word template path for Document Generation.
.DESCRIPTION
    This helper resolves from the selected customer template by default.
    When the selected option is Use My Template, it uses the manually supplied Word template path.
.EXAMPLE
    Resolve-DocumentGenerationTemplatePath -WordTemplatePath $WordTemplateTextBox.Text -SelectedCustomerTemplate $CustomerTemplateComboBox.SelectedItem
.INPUTS
    [System.String]
    [System.Object]
.OUTPUTS
    [System.String]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.3.3
    Author          : Imraan Iotana
    Creation Date   : July 2026
    Last Update     : August 2026
#>
####################################################################################################
function Resolve-DocumentGenerationTemplatePath {
    [CmdletBinding()]
    [OutputType([System.String])]
    param (
        [Parameter(Mandatory=$false,HelpMessage='Optional direct Word template path from the Word Template textbox.')]
        [AllowNull()][AllowEmptyString()]
        [System.String]$WordTemplatePath,

        [Parameter(Mandatory=$false,HelpMessage='Optional selected customer template item from the ComboBox.')]
        [System.Object]$SelectedCustomerTemplate,

        [Parameter(Mandatory=$false,HelpMessage='Optional visible text from the customer template ComboBox.')]
        [AllowNull()][AllowEmptyString()]
        [System.String]$SelectedCustomerTemplateText
    )

    # Some UI states can hold a visible ComboBox text while SelectedItem is temporarily null.
    # Resolve by text when needed so validation/generation does not fail incorrectly.
    if (($null -eq $SelectedCustomerTemplate) -and (Test-String -IsPopulated $SelectedCustomerTemplateText)) {
        [System.Object[]]$TemplateOptions = @(Get-DocumentGenerationTemplateOptions)
        [System.Object]$ResolvedOption = $TemplateOptions |
            Where-Object {
                ($null -ne $_.PSObject.Properties['ComboBoxName']) -and
                ([System.String]$_.ComboBoxName -eq [System.String]$SelectedCustomerTemplateText)
            } |
            Select-Object -First 1
        if ($null -ne $ResolvedOption) {
            $SelectedCustomerTemplate = $ResolvedOption
        }
    }

    if ($null -eq $SelectedCustomerTemplate) {
        if (Test-String -IsPopulated $WordTemplatePath) {
            return [System.String]$WordTemplatePath
        }

        Write-Line 'No customer template is selected and no custom Word template path was supplied.' -Type Warning
        return ''
    }

    [System.Boolean]$IsCustomTemplateSelection = $false
    if ($null -ne $SelectedCustomerTemplate.PSObject.Properties['IsCustomTemplate']) {
        $IsCustomTemplateSelection = [System.Boolean]$SelectedCustomerTemplate.IsCustomTemplate
    }
    elseif ($null -ne $SelectedCustomerTemplate.PSObject.Properties['ComboBoxName']) {
        $IsCustomTemplateSelection = ([System.String]$SelectedCustomerTemplate.ComboBoxName).Equals('Use My Template',[System.StringComparison]::OrdinalIgnoreCase)
    }

    if ($IsCustomTemplateSelection) {
        if (Test-String -IsPopulated $WordTemplatePath) {
            return [System.String]$WordTemplatePath
        }

        Write-Line 'Use My Template is selected, but the custom Word template path is empty.' -Type Warning
        return ''
    }

    [System.String]$TemplateName = ''
    if ($null -ne $SelectedCustomerTemplate.PSObject.Properties['Content'] -and
        $null -ne $SelectedCustomerTemplate.Content -and
        $null -ne $SelectedCustomerTemplate.Content.PSObject.Properties['TemplateName']) {
        $TemplateName = [System.String]$SelectedCustomerTemplate.Content.TemplateName
    }

    # Fallback: import the settings file when Content is not available on the selected item.
    if ((Test-String -IsEmpty $TemplateName) -and ($null -ne $SelectedCustomerTemplate.PSObject.Properties['TemplatePath'])) {
        [System.String]$SettingsPath = [System.String]$SelectedCustomerTemplate.TemplatePath
        if (Test-Path -LiteralPath $SettingsPath -PathType Leaf) {
            try {
                [System.Collections.Hashtable]$TemplateSettings = Import-PowerShellDataFile -Path $SettingsPath
                if ($null -ne $TemplateSettings -and $TemplateSettings.ContainsKey('TemplateName')) {
                    $TemplateName = [System.String]$TemplateSettings.TemplateName
                }
            }
            catch {
                # Continue with existing warnings below.
            }
        }
    }

    if (Test-String -IsEmpty $TemplateName) {
        Write-Line 'The selected customer template does not define Content.TemplateName.' -Type Warning
        return ''
    }
    if ([System.IO.Path]::IsPathRooted($TemplateName) -or
        [System.IO.Path]::GetFileName($TemplateName) -ne $TemplateName -or
        $TemplateName.IndexOfAny([System.IO.Path]::GetInvalidFileNameChars()) -ge 0) {
        Write-Line "The selected customer template defines an unsafe Word template filename. ($TemplateName)" -Type Warning
        return ''
    }

    [System.String]$TemplateDirectory = ''
    if ($null -ne $SelectedCustomerTemplate.PSObject.Properties['Directory']) {
        $TemplateDirectory = [System.String]$SelectedCustomerTemplate.Directory
    }

    if (Test-String -IsPopulated $TemplateDirectory) {
        [System.String]$CandidateTemplatePath = Join-Path -Path $TemplateDirectory -ChildPath $TemplateName
        if (Test-Path -LiteralPath $CandidateTemplatePath -PathType Leaf) {
            return $CandidateTemplatePath
        }
        Write-Line "The selected Word template could not be found for the selected customer template. ($TemplateName)" -Type Warning
        return ''
    }

    [System.String]$CustomerFolder = Join-Path -Path $Global:ApplicationObject.RootFolder -ChildPath 'Customer'
    [System.IO.FileInfo]$ResolvedTemplateFile = Get-ChildItem -LiteralPath $CustomerFolder -Recurse -File -Filter $TemplateName -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($null -ne $ResolvedTemplateFile) {
        return [System.String]$ResolvedTemplateFile.FullName
    }

    Write-Line "The selected Word template could not be found in the customer folder. ($TemplateName)" -Type Warning
    return ''
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Confirms the document-generation input file paths.
.DESCRIPTION
    This function confirms the selected Word template and metadata JSON paths using shared
    utility validation so the checks can be reused consistently across features.
.EXAMPLE
    Confirm-DocumentGenerationInput -WordTemplatePath 'C:\Temp\Template.dotx' -MetaDataJsonPath 'C:\Temp\Metadata.json'
.INPUTS
    [System.String]
.OUTPUTS
    [System.Boolean]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.3.3
    Author          : Imraan Iotana
    Creation Date   : July 2026
    Last Update     : August 2026
#>
####################################################################################################
function Confirm-DocumentGenerationInput {
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The selected Word template path.')]
        [AllowNull()][AllowEmptyString()]
        [System.String]$WordTemplatePath,

        [Parameter(Mandatory=$true,HelpMessage='The selected metadata JSON path.')]
        [AllowNull()][AllowEmptyString()]
        [System.String]$MetaDataJsonPath,

        [Parameter(Mandatory=$false,HelpMessage='Optional folder containing shortcut icon PNG files.')]
        [AllowNull()][AllowEmptyString()]
        [System.String]$IconFolderPath
    )

    # STATUS - START
    # Inform the user that validation has started
    Write-Line 'Starting Document Generation input validation...'

    # VALIDATION - WORD TEMPLATE
    # Validate that the selected template file exists and has a supported Word extension
    Write-Line 'Confirming Word Template path and extension...'
    [System.Boolean]$WordTemplateIsValid = Confirm-FileExtension -Path $WordTemplatePath -Name 'Word Template' -AllowedExtensions @('.dotx','.dotm','.docx','.doc')
    if (-not $WordTemplateIsValid) {
        return $false
    }
    Write-Line 'Word Template is valid.' -Type Success

    # VALIDATION - METADATA JSON
    # Validate that the selected metadata file exists and has a JSON extension
    Write-Line 'Confirming Metadata JSON path and extension...'
    [System.Boolean]$MetaDataJsonIsValid = Confirm-FileExtension -Path $MetaDataJsonPath -Name 'Metadata JSON' -AllowedExtensions @('.json')
    if (-not $MetaDataJsonIsValid) {
        return $false
    }
    Write-Line 'Metadata JSON is valid.' -Type Success

    # VALIDATION - METADATA JSON CONTENT
    # Validate that the selected metadata file contains parseable JSON
    Write-Line 'Confirming Metadata JSON content...'
    [System.Boolean]$MetaDataJsonContentIsValid = Confirm-JsonFileContent -Path $MetaDataJsonPath -Name 'Metadata JSON'
    if (-not $MetaDataJsonContentIsValid) {
        return $false
    }
    Write-Line 'Metadata JSON content is valid.' -Type Success

    # VALIDATION - ICON FOLDER
    # Validate the optional icon folder and ensure the metadata shortcuts have matching icon files.
    if (Test-String -IsEmpty $IconFolderPath) {
        Write-Line 'No icon folder was supplied. Shortcut icon validation was skipped.' -Type Info
        Write-Line 'Document Generation input validation succeeded.' -Type Success
        return $true
    }

    # Confirm the icon folder exists and contains at least one supported image file.
    Write-Line 'Confirming icon folder path...'
    if (-not (Test-Path -LiteralPath $IconFolderPath -PathType Container)) {
        Write-Line "Icon folder path does not exist or is not a folder: $IconFolderPath" -Type Warning
        return $false
    }

    [System.String[]]$ImageFiles = @(Get-ChildItem -LiteralPath $IconFolderPath -File | Where-Object { $_.Extension -in @('.png','.jpg','.jpeg','.bmp','.gif') } | Select-Object -ExpandProperty FullName)
    if ($ImageFiles.Count -eq 0) {
        Write-Line "No image files were found in icon folder: $IconFolderPath" -Type Warning
        return $false
    }
    Write-Line "Found $($ImageFiles.Count) icon image file(s) in the supplied folder." -Type Success

    # Build a case-insensitive lookup once to avoid repeated nested file scans.
    [System.Collections.Generic.HashSet[System.String]]$IconNameLookup = New-Object 'System.Collections.Generic.HashSet[System.String]' ([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($ImageFile in $ImageFiles) {
        [System.String]$IconFileNameStem = [System.IO.Path]::GetFileNameWithoutExtension([System.String]$ImageFile)
        [void]$IconNameLookup.Add($IconFileNameStem)
    }

    # Check whether the shortcut entries in the metadata have matching icon files by name.
    try {
        [System.String]$MetaDataJsonContent = Get-Content -LiteralPath $MetaDataJsonPath -Raw
        [PSCustomObject]$MetaDataObject = $MetaDataJsonContent | ConvertFrom-Json
        [PSCustomObject[]]$ShortcutEntries = @()
        if ($null -ne $MetaDataObject -and $null -ne $MetaDataObject.Shortcuts) {
            $ShortcutEntries = @($MetaDataObject.Shortcuts)
        }

        if ($ShortcutEntries.Count -eq 0) {
            Write-Line 'No shortcut entries were found in metadata. Icon name validation was skipped.' -Type Warning
            Write-Line 'Document Generation input validation succeeded.' -Type Success
            return $true
        }

        [System.Collections.Generic.List[System.String]]$UnmatchedShortcutNames = New-Object 'System.Collections.Generic.List[System.String]'
        foreach ($Shortcut in $ShortcutEntries) {
            [System.String]$ShortcutName = [System.String]$Shortcut.BaseName
            if (Test-String -IsEmpty $ShortcutName) {
                $ShortcutName = [System.String]$Shortcut.Name
            }
            if (Test-String -IsEmpty $ShortcutName) { continue }

            if (-not $IconNameLookup.Contains($ShortcutName)) {
                [void]$UnmatchedShortcutNames.Add($ShortcutName)
            }
        }

        if ($UnmatchedShortcutNames.Count -gt 0) {
            Write-Line "Some shortcuts do not have a matching icon file in the supplied folder: $($UnmatchedShortcutNames -join ', ')" -Type Warning
        }
        else {
            Write-Line 'All shortcuts have matching icon files in the supplied folder.' -Type Success
        }
    }
    catch {
        Write-Line "Icon folder validation could not be completed: $($_.Exception.Message)" -Type Warning
    }

    # OUTPUT
    Write-Line 'Document Generation input validation succeeded.' -Type Success
    return $true
}

### END OF FUNCTION
####################################################################################################

