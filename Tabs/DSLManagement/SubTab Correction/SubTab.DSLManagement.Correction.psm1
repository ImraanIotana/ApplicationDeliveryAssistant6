####################################################################################################
<#
.SYNOPSIS
    Imports the Correction sub-tab into the DSL Management tab.
.DESCRIPTION
    This function imports the Correction sub-tab into the DSL Management tab by creating a new TabPage and adding it to the specified parent TabControl.
.EXAMPLE
    Import-SubTabDSLManagementCorrection -InputObject $MyApplicationObject -ParentTabControl $MySubTabControl
.INPUTS
    [PSCustomObject]
    [System.Windows.Forms.TabControl]
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.11.0
    Author          : Imraan Iotana
    Creation Date   : October 2026
    Last Update     : October 2026
#>
####################################################################################################
function Import-SubTabDSLManagementCorrection {
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
            Title               = 'DSL CORRECTION'
            Version             = '6.11.0'
            BackGroundColor     = 'SteelBlue'
        }
        # Set the main color for the GroupBoxes in this sub-tab
        [System.String]$MainColor = 'Cyan'

        # EXECUTION - TAB
        # Create the TabPage
        [System.Windows.Forms.TabPage]$ParentTabPage = New-TabPage @TabProperties

        # EXECUTION - FEATURES
        # Import the Correction feature
        $null = Import-FeatureDSLManagementCorrection  -InputObject $InputObject -ParentTabPage $ParentTabPage -Color $MainColor
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
    Imports the Correction feature into the DSL Correction sub-tab.
.DESCRIPTION
    This function creates a GroupBox with a ComboBox that lists all application folders in the Software Library (DSL),
    and GroupBoxes, grouped by theme, that show the metadata values of the selected application folder.
    The Folder Name group also allows renaming the folder through its prefix, postfix and separator.
    The Formal Properties group allows changing the formal vendor, name and version in the metadata and in the Word documents.
    The Custom Properties group allows changing the custom vendor, name and version, which changes the Application ID.
    The details are loaded with the Load button; changing the selection clears them.
.EXAMPLE
    Import-FeatureDSLManagementCorrection -InputObject $MyApplicationObject -ParentTabPage $MyTabPage
.INPUTS
    [PSCustomObject]
    [System.Windows.Forms.TabPage]
    [System.Windows.Forms.GroupBox]
    [System.String]
.OUTPUTS
    [System.Windows.Forms.GroupBox]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.11.0
    Author          : Imraan Iotana
    Creation Date   : October 2026
    Last Update     : October 2026
#>
####################################################################################################
function Import-FeatureDSLManagementCorrection {
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
            Title           = 'CORRECT APPLICATION FOLDER'
            Color           = $Color
            NumberOfRows    = 2
            GroupBoxAbove   = $GroupBoxAbove
        }

        # EXECUTION - GROUPBOX
        # Create the GroupBox
        [System.Windows.Forms.GroupBox]$FeatureGroupBox = New-GroupBox @GroupBoxProperties

        # PREPARATION - COMBOBOX PROPERTIES
        # Set the DSL Application Folder ComboBox properties
        [System.Collections.Hashtable]$ApplicationFolderComboBoxProperties = @{
            RowNumber          = 1
            Label              = 'DSL Application Folder'
            ToolTip            = 'Select the application folder in the Software Library (DSL) that you want to correct.'
            SizeType           = 'Medium'
            Type               = 'Output'
            ContentStringArray = @(Get-DSLDirectSubFolderNames)
            SmallButtons       = @(,(@(5,'Copy')))
        }

        # EXECUTION - INPUT CONTROLS
        # Create the DSL Application Folder ComboBox
        [System.Windows.Forms.ComboBox]$ApplicationFolderComboBox = New-ComboBox @ApplicationFolderComboBoxProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ReturnComboBox

        # PREPARATION - LOAD STATE
        # Remembers which application folder the details boxes were loaded for, so the Rename action can never use the details of another folder
        [System.Collections.Hashtable]$LoadState = @{ FolderName = '' }

        # PREPARATION - DETAILS GROUPS
        # The labels carry a prefix ('Metadata', 'Rename' or 'New') so their settings keys can never match the leaf names of the Intake fields (e.g. CustomVendorName).
        # Each item has the metadata property name, a label and a tooltip. Items are read-only unless the Type is 'Input'.
        [System.Collections.Hashtable[]]$DetailGroups = @(
            @{
                Title = 'METADATA FILE'
                Items = @(
                    @{ Name = 'MetadataFile';               Label = 'Metadata File';             ToolTip = 'The metadata file that was found in the selected application folder.' }
                    @{ Name = 'CreatedOn';                  Label = 'Metadata Created On';       ToolTip = 'The moment the application folder was created.' }
                )
            }
            @{
                Title = 'FOLDER NAME'
                SizeType = 'Medium'
                Items = @(
                    @{ Name = 'ApplicationID';              Label = 'Metadata Application ID';   ToolTip = 'The Application ID stored in the metadata. It is not changed by renaming the folder.' }
                    @{ Name = 'ApplicationFolderName';      Label = 'Metadata Folder Name';      ToolTip = 'The Application Folder Name stored in the metadata.' }
                    @{ Name = 'ApplicationFolderPrefix';    Label = 'Rename Prefix';             ToolTip = 'The prefix for the folder name. Starts with the value stored in the metadata.'; Type = 'Input' }
                    @{ Name = 'ApplicationFolderPostfix';   Label = 'Rename Postfix';            ToolTip = 'The postfix for the folder name. Starts with the value stored in the metadata.'; Type = 'Input' }
                    @{ Name = 'ApplicationFolderSeparator'; Label = 'Rename Separator';          ToolTip = 'The separator between prefix, Application ID and postfix. Starts with the value stored in the metadata; an empty value is shown as _ (the Intake default).'; Type = 'Input' }
                    @{ Name = 'NewFolderName';              Label = 'New Folder Name';           ToolTip = 'The folder name that will be used after renaming. It is built from the prefix, the Application ID and the postfix.' }
                )
            }
            @{
                Title = 'FORMAL PROPERTIES'
                SizeType = 'Medium'
                Items = @(
                    @{ Name = 'FormalVendorName';           Label = 'New Formal Vendor';         ToolTip = 'The formal vendor name. Starts with the value stored in the metadata.'; Type = 'Input' }
                    @{ Name = 'FormalApplicationName';      Label = 'New Formal Name';           ToolTip = 'The formal application name. Starts with the value stored in the metadata.'; Type = 'Input' }
                    @{ Name = 'FormalApplicationVersion';   Label = 'New Formal Version';        ToolTip = 'The formal application version. Starts with the value stored in the metadata.'; Type = 'Input' }
                )
            }
            @{
                Title = 'CUSTOM PROPERTIES'
                SizeType = 'Medium'
                Items = @(
                    @{ Name = 'CustomVendorName';           Label = 'New Custom Vendor';         ToolTip = 'The custom vendor name. Part of the Application ID. Starts with the value stored in the metadata.'; Type = 'Input' }
                    @{ Name = 'CustomApplicationName';      Label = 'New Custom Name';           ToolTip = 'The custom application name. Part of the Application ID. Starts with the value stored in the metadata.'; Type = 'Input' }
                    @{ Name = 'CustomApplicationVersion';   Label = 'New Custom Version';        ToolTip = 'The custom application version. Part of the Application ID. Starts with the value stored in the metadata.'; Type = 'Input' }
                )
            }
        )

        # EXECUTION - DETAILS GROUPBOXES AND TEXTBOXES
        # Create one GroupBox per group, stacked under the selection GroupBox, with one TextBox per metadata value.
        # The TextBoxes are keyed by the metadata property name.
        [System.Collections.Hashtable]$DetailTextBoxes = @{}
        [System.Collections.Hashtable]$DetailGroupBoxes = @{}
        [System.Windows.Forms.GroupBox]$DetailsGroupBox = $FeatureGroupBox
        foreach ($DetailGroup in $DetailGroups) {
            [System.Collections.Hashtable]$DetailsGroupBoxProperties = @{
                InputObject     = $InputObject
                ParentTabPage   = $ParentTabPage
                Title           = $DetailGroup.Title
                Color           = $Color
                # A TextBox row is 30 pixels high and a GroupBox row 40, plus 20 pixels for the top and bottom margins: (30 * rows + 20) / 40
                NumberOfRows    = (0.75 * $DetailGroup.Items.Count) + 0.5
                GroupBoxAbove   = $DetailsGroupBox
            }
            $DetailsGroupBox = New-GroupBox @DetailsGroupBoxProperties
            $DetailGroupBoxes[$DetailGroup.Title] = $DetailsGroupBox

            [System.Int32]$RowNumber = 1
            foreach ($DetailItem in $DetailGroup.Items) {
                [System.Collections.Hashtable]$DetailTextBoxProperties = @{
                    RowNumber = $RowNumber
                    Label     = $DetailItem.Label
                    ToolTip   = $DetailItem.ToolTip
                    SizeType  = if ($DetailGroup.SizeType) { $DetailGroup.SizeType } else { 'Large' }
                    Type      = if ($DetailItem.Type) { $DetailItem.Type } else { 'Output' }
                }
                $DetailTextBoxes[$DetailItem.Name] = New-TextBox @DetailTextBoxProperties -InputObject $InputObject -ParentGroupBox $DetailsGroupBox -ReturnTextBox
                $RowNumber++
            }
        }

        # EXECUTION - RENAME BUTTON
        # Place the Large button (two rows high) next to the last two rows of the Folder Name group, which ends with the New Folder Name TextBox
        [System.Collections.Hashtable]$RenameButtonProperties = @{
            RowNumber       = @($DetailGroups | Where-Object { $_.Title -eq 'FOLDER NAME' })[0].Items.Count - 1
            ColumnNumber    = 5
            Text            = 'Rename Folder'
            PNGFileName     = 'folder_edit'
            SizeType        = 'Large'
            ToolTip         = 'Rename the selected application folder to the New Folder Name, and update its metadata and log. The folder must be loaded first.'
            Function        = { Invoke-DSLApplicationFolderRename -ApplicationFolderComboBox $ApplicationFolderComboBox -DetailTextBoxes $DetailTextBoxes -LoadState $LoadState }.GetNewClosure()
        }
        New-Button @RenameButtonProperties -InputObject $InputObject -ParentGroupBox $DetailGroupBoxes['FOLDER NAME']

        # EXECUTION - APPLY CHANGES BUTTON
        # Place the Large button (two rows high) next to the last two rows of the Formal Properties group
        [System.Collections.Hashtable]$ApplyButtonProperties = @{
            RowNumber       = @($DetailGroups | Where-Object { $_.Title -eq 'FORMAL PROPERTIES' })[0].Items.Count - 1
            ColumnNumber    = 5
            Text            = 'Apply Changes'
            PNGFileName     = 'disk'
            SizeType        = 'Large'
            ToolTip         = 'Apply the formal vendor, name and version to the metadata and to the Word documents in the documentation folder, after a backup of each. Documents without content controls (older documents) are not changed. The folder must be loaded first.'
            Function        = { Invoke-DSLApplicationFormalApply -ApplicationFolderComboBox $ApplicationFolderComboBox -DetailTextBoxes $DetailTextBoxes -LoadState $LoadState }.GetNewClosure()
        }
        New-Button @ApplyButtonProperties -InputObject $InputObject -ParentGroupBox $DetailGroupBoxes['FORMAL PROPERTIES']

        # EXECUTION - CHANGE APPLICATION ID BUTTON
        # Place the Large button (two rows high) next to the last two rows of the Custom Properties group
        [System.Collections.Hashtable]$ChangeIDButtonProperties = @{
            RowNumber       = @($DetailGroups | Where-Object { $_.Title -eq 'CUSTOM PROPERTIES' })[0].Items.Count - 1
            ColumnNumber    = 5
            Text            = 'Change Application ID'
            PNGFileName     = 'magic_wand_2'
            SizeType        = 'Large'
            ToolTip         = 'Apply the custom vendor, name and version. This changes the Application ID, and with it the folder name, the metadata, log and Word document names and the Word documents, after a backup. The folder must be loaded first.'
            Function        = { Invoke-DSLApplicationCustomApply -ApplicationFolderComboBox $ApplicationFolderComboBox -DetailTextBoxes $DetailTextBoxes -LoadState $LoadState }.GetNewClosure()
        }
        New-Button @ChangeIDButtonProperties -InputObject $InputObject -ParentGroupBox $DetailGroupBoxes['CUSTOM PROPERTIES']

        # EXECUTION - SELECTION BUTTONS
        # Set the properties of the buttons in the selection GroupBox. The small Refresh and Open Folder buttons are next to the Copy button of the ComboBox.
        [System.Collections.Hashtable[]]$RefreshButtons = @(
            @{
                ColumnNumber    = 6
                Text            = 'Refresh'
                PNGFileName     = 'arrow_refresh'
                SizeType        = 'Small'
                ToolTip         = 'Reload the list of application folders from the Software Library (DSL). A folder that was loaded stays loaded.'
                Function        = {
                    [System.String]$LoadedFolderName = $LoadState.FolderName
                    Update-ComboBox -ComboBox $ApplicationFolderComboBox -ContentStringArray @(Get-DSLDirectSubFolderNames) -PreservePreviousSelection
                    # The refresh clears the details; load them again when the same folder is still selected
                    if ((Test-String -IsPopulated $LoadedFolderName) -and ($ApplicationFolderComboBox.Text -ceq $LoadedFolderName)) {
                        Invoke-DSLApplicationMetaDataLoad -ApplicationFolderComboBox $ApplicationFolderComboBox -DetailTextBoxes $DetailTextBoxes -LoadState $LoadState
                    }
                }.GetNewClosure()
            }
            @{
                ColumnNumber    = 7
                Text            = 'Open Folder'
                PNGFileName     = 'folder_go'
                SizeType        = 'Small'
                ToolTip         = 'Open the selected application folder in File Explorer.'
                Function        = {
                    [System.String]$SelectedFolderName = $ApplicationFolderComboBox.Text
                    if (Test-String -IsEmpty $SelectedFolderName) { Write-Line 'Select an application folder first.' -Type Fail ; return }
                    Open-Folder -Path (Join-Path -Path (Get-Folder -SoftwareLibrary) -ChildPath $SelectedFolderName)
                }.GetNewClosure()
            }
        )
        [System.Collections.Hashtable[]]$LoadButtons = @(
            @{
                ColumnNumber    = 1
                Text            = 'Load'
                PNGFileName     = 'download'
                SizeType        = 'Medium'
                ToolTip         = 'Load the metadata of the selected application folder.'
                Function        = { Invoke-DSLApplicationMetaDataLoad -ApplicationFolderComboBox $ApplicationFolderComboBox -DetailTextBoxes $DetailTextBoxes -LoadState $LoadState }.GetNewClosure()
            }
        )
        New-ButtonLine -InputObject $InputObject -ButtonPropertiesArray $RefreshButtons -ParentGroupBox $FeatureGroupBox -RowNumber 1
        New-ButtonLine -InputObject $InputObject -ButtonPropertiesArray $LoadButtons -ParentGroupBox $FeatureGroupBox -RowNumber 2

        # EXECUTION - EVENTS
        # Changing the selection clears the details, so the details on screen always belong to the folder that was loaded
        $ApplicationFolderComboBox.Add_SelectedIndexChanged({
            $LoadState.FolderName = ''
            Clear-DSLApplicationMetaDataTextBoxes -DetailTextBoxes $DetailTextBoxes
        }.GetNewClosure())
        # Update the New Folder Name preview while the user types
        foreach ($PreviewKey in @('ApplicationFolderPrefix','ApplicationFolderPostfix','ApplicationFolderSeparator')) {
            $DetailTextBoxes[$PreviewKey].Add_TextChanged({
                Update-DSLApplicationFolderNamePreview -DetailTextBoxes $DetailTextBoxes
            }.GetNewClosure())
        }

        # POST-EXECUTION
        # Discard values that were restored from the User Settings. The details are loaded with the Load button.
        Clear-DSLApplicationMetaDataTextBoxes -DetailTextBoxes $DetailTextBoxes

        # Return the GroupBox at the bottom of the stack
        $DetailsGroupBox
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
    Reads the metadata of an application folder in the Software Library (DSL).
.DESCRIPTION
    This function searches the application folder recursively for a Metadata_*.json file and parses it.
    When more than one metadata file exists, the most recently written file is used and a warning is written.
.EXAMPLE
    Get-DSLApplicationMetaData -ApplicationFolderPath 'C:\DSL\Vendor_App_1.0'
.INPUTS
    [System.String]
.OUTPUTS
    [PSCustomObject] with the properties FilePath and Data; otherwise $null.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.11.0
    Author          : Imraan Iotana
    Creation Date   : October 2026
    Last Update     : October 2026
#>
####################################################################################################
function Get-DSLApplicationMetaData {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The full path of the application folder in the Software Library (DSL).')]
        [AllowEmptyString()]
        [System.String]$ApplicationFolderPath
    )

    try {
        # VALIDATION
        # Validate the application folder path
        if ((Test-String -IsEmpty $ApplicationFolderPath) -or -not (Test-Path -LiteralPath $ApplicationFolderPath -PathType Container)) {
            Write-Line "The application folder does not exist. ($ApplicationFolderPath)" -Type Warning
            return $null
        }

        # EXECUTION
        # Find the metadata files, newest first
        [System.IO.FileInfo[]]$MetaDataFiles = @(
            Get-ChildItem -LiteralPath $ApplicationFolderPath -File -Filter 'Metadata_*.json' -Recurse -ErrorAction SilentlyContinue |
            Sort-Object -Property LastWriteTime -Descending
        )
        if ($MetaDataFiles.Count -eq 0) {
            Write-Line "No metadata file (Metadata_*.json) was found in the application folder. ($ApplicationFolderPath)" -Type Warning
            return $null
        }
        if ($MetaDataFiles.Count -gt 1) {
            Write-Line "Multiple metadata files were found. The most recent file is used. ($($MetaDataFiles[0].Name))" -Type Warning
        }

        # Parse the metadata file
        [System.IO.FileInfo]$MetaDataFile = $MetaDataFiles[0]
        [PSCustomObject]$MetaData = Get-Content -LiteralPath $MetaDataFile.FullName -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop
        if ($null -eq $MetaData) {
            Write-Line "The metadata file is empty. ($($MetaDataFile.FullName))" -Type Warning
            return $null
        }

        # POST-EXECUTION
        # Return the file path and the parsed data
        [PSCustomObject]@{
            FilePath = $MetaDataFile.FullName
            Data     = $MetaData
        }
    }
    catch {
        Write-Line "The metadata file could not be read. ($($_.Exception.Message))" -Type Warning
        return $null
    }
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Clears all metadata detail TextBoxes in the DSL Correction sub-tab.
.EXAMPLE
    Clear-DSLApplicationMetaDataTextBoxes -DetailTextBoxes $DetailTextBoxes
.INPUTS
    [System.Collections.Hashtable]
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.11.0
    Author          : Imraan Iotana
    Creation Date   : October 2026
    Last Update     : October 2026
#>
####################################################################################################
function Clear-DSLApplicationMetaDataTextBoxes {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The TextBoxes keyed by metadata property name.')]
        [System.Collections.Hashtable]$DetailTextBoxes
    )

    foreach ($DetailTextBox in $DetailTextBoxes.Values) {
        $DetailTextBox.Text = ''
    }

    # Clearing the prefix, postfix or separator recalculates the preview, which can happen before the Application ID is cleared. Empty the preview last.
    if ($DetailTextBoxes.ContainsKey('NewFolderName')) {
        $DetailTextBoxes['NewFolderName'].Text = ''
    }
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Shows the metadata of the selected application folder in the DSL Correction sub-tab.
.DESCRIPTION
    This function reads the metadata of the application folder with Get-DSLApplicationMetaData and fills the read-only TextBoxes.
    The TextBoxes are cleared when no folder is selected or no metadata can be read.
.EXAMPLE
    Show-DSLApplicationMetaData -ApplicationFolderName 'Vendor_App_1.0' -DetailTextBoxes $DetailTextBoxes
.INPUTS
    [System.String]
    [System.Collections.Hashtable]
.OUTPUTS
    [System.Boolean] True when the metadata was loaded into the TextBoxes; otherwise False.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.11.0
    Author          : Imraan Iotana
    Creation Date   : October 2026
    Last Update     : October 2026
#>
####################################################################################################
function Show-DSLApplicationMetaData {
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param (
        [Parameter(Mandatory=$false,HelpMessage='The name of the application folder in the Software Library (DSL).')]
        [AllowEmptyString()]
        [System.String]$ApplicationFolderName,

        [Parameter(Mandatory=$true,HelpMessage='The TextBoxes keyed by metadata property name. The key MetadataFile receives the relative file path.')]
        [System.Collections.Hashtable]$DetailTextBoxes
    )

    try {
        # PREPARATION
        # Start with empty boxes, so nothing from a previous selection remains visible
        Clear-DSLApplicationMetaDataTextBoxes -DetailTextBoxes $DetailTextBoxes
        if (Test-String -IsEmpty $ApplicationFolderName) { return $false }

        # EXECUTION
        # Read the metadata of the selected application folder
        [System.String]$ApplicationFolderPath = Join-Path -Path (Get-Folder -SoftwareLibrary) -ChildPath $ApplicationFolderName
        [PSCustomObject]$MetaDataResult = Get-DSLApplicationMetaData -ApplicationFolderPath $ApplicationFolderPath
        if ($null -eq $MetaDataResult) { return $false }

        # Fill the boxes. Properties that are missing in the metadata file stay empty.
        foreach ($DetailName in $DetailTextBoxes.Keys) {
            if ($DetailName -eq 'MetadataFile') {
                $DetailTextBoxes[$DetailName].Text = $MetaDataResult.FilePath.Substring($ApplicationFolderPath.TrimEnd('\').Length).TrimStart('\')
                continue
            }
            [System.Management.Automation.PSPropertyInfo]$MetaDataProperty = $MetaDataResult.Data.PSObject.Properties[$DetailName]
            if ($null -ne $MetaDataProperty) { $DetailTextBoxes[$DetailName].Text = [System.String]$MetaDataProperty.Value }
        }

        # Folders without any prefix, postfix or separator in the metadata start with the Intake default separator, so a newly typed prefix or postfix is joined sensibly
        if ($DetailTextBoxes.ContainsKey('ApplicationFolderSeparator') -and
            (Test-String -IsEmpty $DetailTextBoxes['ApplicationFolderPrefix'].Text) -and
            (Test-String -IsEmpty $DetailTextBoxes['ApplicationFolderPostfix'].Text) -and
            [System.String]::IsNullOrEmpty($DetailTextBoxes['ApplicationFolderSeparator'].Text)) {
            $DetailTextBoxes['ApplicationFolderSeparator'].Text = '_'
        }
        Update-DSLApplicationFolderNamePreview -DetailTextBoxes $DetailTextBoxes
        Write-Line "Loaded the metadata of the application folder. ($ApplicationFolderName)"
        return $true
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
        return $false
    }
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Loads the metadata of the application folder that is selected in the DSL Correction sub-tab.
.DESCRIPTION
    This function shows the metadata of the selected folder with Show-DSLApplicationMetaData and records in the LoadState which folder the details belong to.
    The LoadState is what allows the Rename action to run; it is cleared whenever the selection changes.
.EXAMPLE
    Invoke-DSLApplicationMetaDataLoad -ApplicationFolderComboBox $MyComboBox -DetailTextBoxes $DetailTextBoxes -LoadState $LoadState
.INPUTS
    [System.Windows.Forms.ComboBox]
    [System.Collections.Hashtable]
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.11.0
    Author          : Imraan Iotana
    Creation Date   : October 2026
    Last Update     : October 2026
#>
####################################################################################################
function Invoke-DSLApplicationMetaDataLoad {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The ComboBox with the application folders of the Software Library (DSL).')]
        [System.Windows.Forms.ComboBox]$ApplicationFolderComboBox,

        [Parameter(Mandatory=$true,HelpMessage='The TextBoxes keyed by metadata property name.')]
        [System.Collections.Hashtable]$DetailTextBoxes,

        [Parameter(Mandatory=$true,HelpMessage='The state that records which application folder is loaded. Its FolderName key is updated.')]
        [System.Collections.Hashtable]$LoadState
    )

    try {
        [System.String]$SelectedFolderName = $ApplicationFolderComboBox.Text
        $LoadState.FolderName = ''
        if (Test-String -IsEmpty $SelectedFolderName) {
            Write-Line 'No application folder is selected. Select a folder first. No action has been taken.' -Type Warning
            return
        }
        if (Show-DSLApplicationMetaData -ApplicationFolderName $SelectedFolderName -DetailTextBoxes $DetailTextBoxes) {
            $LoadState.FolderName = $SelectedFolderName
        }
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}

### END OF FUNCTION
####################################################################################################
