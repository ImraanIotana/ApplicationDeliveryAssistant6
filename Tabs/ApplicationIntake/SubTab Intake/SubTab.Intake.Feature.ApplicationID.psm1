####################################################################################################
<#
.SYNOPSIS
    Imports the Application ID feature into the Intake sub-tab.
.DESCRIPTION
    This function imports the Application ID feature into the Intake sub-tab by creating a new GroupBox and adding it to the specified parent TabPage.
.EXAMPLE
    Import-FeatureIntakeApplicationID -InputObject $MyApplicationObject -ParentTabPage $MyTabPage
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
function Import-FeatureIntakeApplicationID {
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
            Title           = 'APPLICATION ID'
            Color           = $Color
            NumberOfRows    = 2
            GroupBoxAbove   = $GroupBoxAbove
        }
        # Create the GroupBox
        [System.Windows.Forms.GroupBox]$FeatureGroupBox = New-GroupBox @FeatureProperties -OnSubTab

        # EXECUTION - TEXTBOX
        # Set the TextBox properties
        [System.Collections.Hashtable]$ApplicationIDTextBoxProperties = @{
            RowNumber       = 2
            Label           = 'Application ID'
            PropertyName    = 'TextBoxes.ApplicationIntake.ApplicationID'
            ToolTip         = 'The ID of the application to intake'
            SizeType        = 'Medium'
            Type            = 'Output'
        }
        # Create the hashtables for the TextBoxes in the Global Graphics object if they do not already exist
        if (-not $Global:Graphics.TextBoxes.ContainsKey('ApplicationIntake')) { $Global:Graphics.TextBoxes.ApplicationIntake = @{} }
        # Create the TextBox
        $Global:Graphics.TextBoxes.ApplicationIntake.ApplicationID = New-TextBox @ApplicationIDTextBoxProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ReturnTextBox

        # EXECUTION - BUTTONS
        # Set the Buttons properties
        [System.Collections.Hashtable]$ApplicationIDButtonProperties = @{
            ColumnNumber    = 1
            RowNumber       = 1
            Text            = 'Application ID'
            PNGFileName     = 'download_for_windows'
            SizeType        = 'Medium'
            ToolTip         = 'Browse for a detection file or MSI.'
            Function        = { New-ApplicationIDFromTextBoxes -OutputTextBox $Global:Graphics.TextBoxes.ApplicationIntake.ApplicationID }.GetNewClosure()
        }
        [System.Collections.Hashtable]$CreateFolderButtonProperties = @{
            ColumnNumber    = 5
            RowNumber       = 2
            Text            = 'Create Folder'
            PNGFileName     = 'folder_add'
            SizeType        = 'Medium'
            ToolTip         = 'Browse for a detection file or MSI.'
            Function        = { New-ApplicationFolder }.GetNewClosure()
        }
        # Add the Buttons
        New-Button @ApplicationIDButtonProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox
        New-Button @CreateFolderButtonProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox

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
    Creates the application folder structure for the generated Application ID.
.DESCRIPTION
    This function creates the application folder for the current Application ID in the configured output folder.
    It validates the output folder and Application ID, asks for confirmation before overwriting an existing folder,
    creates the folder and its configured subfolders, and opens the output folder afterwards.
.EXAMPLE
    New-ApplicationFolder
.INPUTS
    [System.String]
.OUTPUTS
    No objects are returned to the pipeline. All output is written to the host.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. All rights reserved.
    Version         : 6.0.0.0
    Author          : Imraan Iotana
    Creation Date   : June 2026
    Last Update     : June 2026
#>
####################################################################################################
function New-ApplicationIDFromTextBoxes {
    param (
        [Parameter(Mandatory=$false,HelpMessage='The TextBox to write the Application ID into.')]
        [System.Windows.Forms.TextBox]$OutputTextBox
    )
    
    try {
        # VALIDATION
        # Define the TextBoxes to get the text from
        [System.String[]]$TextBoxesToGetTextFrom = @(
            'VendorName'
            'ApplicationName'
            'ApplicationVersion'
        )
        # Create a hashtable to store the trimmed values of the TextBoxes
        [System.Collections.Hashtable]$TrimmedValues = @{}
        # Loop through the TextBoxes, get the text, trim it and store it in the hashtable
        foreach ($TextBoxName in $TextBoxesToGetTextFrom) {
            $TrimmedValues[$TextBoxName] = ($Global:Graphics.TextBoxes.ApplicationIntake.CustomProperties.$TextBoxName.Text -replace '\s+', '')
        }
        # Validate that none of the trimmed values are empty
        foreach ($Key in $TrimmedValues.Keys) {
            if (Test-String -IsEmpty $TrimmedValues[$Key]) {
                Write-Line "$Key is empty. The Application ID cannot be generated."
                if ($OutputTextBox) { Clear-TextBox -TextBox $OutputTextBox -Force }
                return
            }
        }
        # Reuse the already validated and normalized values
        [System.String]$VendorName          = $TrimmedValues.VendorName
        [System.String]$ApplicationName     = $TrimmedValues.ApplicationName
        [System.String]$ApplicationVersion  = $TrimmedValues.ApplicationVersion


        # VALIDATION
        # If the Application Name contains the Application Version, write a warning
        if ($ApplicationName.Contains($ApplicationVersion)) {
            Write-Line "Warning: The Custom Application Name contains the Application Version. This will cause the Application Version to be duplicated in the Application ID." -Type Warning
        }
        # If the Application Name contains the Vendor Name, write a warning
        if ($ApplicationName.Contains($VendorName)) {
            Write-Line "Warning: The Custom Application Name contains the Vendor Name. This will cause the Vendor Name to be duplicated in the Application ID." -Type Warning
        }

        # EXECUTION
        # Generate the Application ID in the format VendorName_ApplicationName_ApplicationVersion, without any whitespace
        [System.String]$ApplicationID = "$($VendorName)_$($ApplicationName)_$($ApplicationVersion)"
        Write-Line "Generated Application ID: $ApplicationID"

        # EXECUTION
        # Set the text to the textbox
        if ($OutputTextBox) { $OutputTextBox.Text = $ApplicationID }
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
    Generates an Application ID from Intake Custom Properties textboxes.
.DESCRIPTION
    This function reads Vendor Name, Application Name, and Application Version from the Intake Custom Properties textboxes.
    It removes all whitespace from each value, validates that all values are populated, and generates an Application ID string.
    The generated ID is written to the supplied output textbox when one is provided.
.EXAMPLE
    New-ApplicationIDFromTextBoxes -OutputTextBox $Global:Graphics.TextBoxes.ApplicationIntake.ApplicationID
.INPUTS
    [System.Windows.Forms.TextBox]
.OUTPUTS
    No objects are returned to the pipeline. The result is written to the provided textbox.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. All rights reserved.
    Version         : 6.0.0.0
    Author          : Imraan Iotana
    Creation Date   : June 2026
    Last Update     : June 2026
#>
####################################################################################################
function New-ApplicationFolder {
    param (
        [Parameter(Mandatory=$false,HelpMessage='Destination folder where the export text file will be created.')]
        [System.String]$OutputFolder = (Get-OutputFolder)
    )
    
    try {
        # VALIDATION
        # If OutputFolder is not provided, throw an error
        if (Test-String -IsEmpty $OutputFolder) { throw "The OutputFolder parameter is empty." }
        # If the output folder does not exist, create it
        if (-not (Test-Path -Path $OutputFolder -PathType Container)) { New-Item -Path $OutputFolder -ItemType Directory -Force | Out-Null }

        # PREPARATION
        # Set the ApplicationID
        New-ApplicationIDFromTextBoxes -OutputTextBox $Global:Graphics.TextBoxes.ApplicationIntake.ApplicationID
        # Get the Application ID from the ApplicationID TextBox
        [System.String]$ApplicationID = $Global:Graphics.TextBoxes.ApplicationIntake.ApplicationID.Text
        # If the Application ID is empty, throw an error
        if (Test-String -IsEmpty $ApplicationID) {
            Write-Line "The Application ID is empty. Please generate an Application ID before creating the application folder. No action has been taken."
            return
        }
        # Set the path for the new folder
        [System.String]$NewFolderPath = Join-Path -Path $OutputFolder -ChildPath $ApplicationID

        # CONFIRMATION
        # Set the Title and Body for the confirmation message box
        if (Test-Path -Path $NewFolderPath -PathType Container) {
            [System.String]$Title   = "Confirm Overwrite Application Folder"
            [System.String]$Body    = "This will OVERWRITE the EXISTING Application Folder with the following name:`n`n$ApplicationID`n`nDo you want to continue?"
        }
        else {
            [System.String]$Title   = "Create Application Folder"
            [System.String]$Body    = "This will create a NEW Application Folder with the following name:`n`n$ApplicationID`n`nDo you want to continue?"
        }
        # If the user did not confirm, return
        if (Get-UserConfirmation -Title $Title -Body $Body) {
            Write-Line "Creating application folder: $NewFolderPath. One moment please..."
        } else {
            return
        }

        # EXECUTION
        # Remove the existing folder if it exists
        if (Test-Path -Path $NewFolderPath -PathType Container) { Remove-Item -Path $NewFolderPath -Recurse -Force }
        # Create the new folder
        New-Item -Path $NewFolderPath -ItemType Directory -Force | Out-Null
        # Get the subfolders from the Application Folder Template
        [System.Collections.Generic.List[System.String]]$SubFolders = $Global:Graphics.ComboBoxes.ApplicationIntake.TemplateSelection.SelectedItem.ApplicationFolderSubFolders.GetEnumerator() | ForEach-Object { $_.Value }
        # Create the subfolders in the new folder
        foreach ($SubFolder in $SubFolders) {
            [System.String]$SubFolderPath = Join-Path -Path $NewFolderPath -ChildPath $SubFolder
            New-Item -Path $SubFolderPath -ItemType Directory -Force | Out-Null
        }

        # Create the initial Word document in the Documentation subfolder from the selected template.
        [System.Object]$SelectedTemplate = $Global:Graphics.ComboBoxes.ApplicationIntake.TemplateSelection.SelectedItem
        Copy-UDF -ApplicationFolderPath $NewFolderPath -SelectedTemplate $SelectedTemplate
        New-ApplicationIntakeDocument -ApplicationFolderPath $NewFolderPath -SelectedTemplate $SelectedTemplate
        New-MetaDataFile -ApplicationFolderPath $NewFolderPath -SelectedTemplate $SelectedTemplate
        New-ApplicationShortcutInformation -ApplicationFolderPath $NewFolderPath -SkipConfirmation

        # Write a message to the host indicating that the new application folder has been created
        Write-Line "The new application folder has been created. ($ApplicationID)"

        # POST-EXECUTION
        # Open the OutputFolder
        Open-Folder -Path $OutputFolder
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
    Copies and extracts the configured UDF zip into the Work subfolder.
.DESCRIPTION
    Resolves UDFName from the selected customer template, locates the zip file below the configured
    customer folder, and extracts it into the Work subfolder (8. Work) of the supplied application folder.
.EXAMPLE
    Copy-UDF -ApplicationFolderPath 'C:\Temp\Vendor_App_1.0' -SelectedTemplate $Template
.INPUTS
    [System.String]
    [System.Object]
.OUTPUTS
    No objects are returned to the pipeline. All output is written to the host.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. All rights reserved.
    Version         : 6.0.0.0
    Author          : Imraan Iotana
    Creation Date   : June 2026
    Last Update     : June 2026
#>
####################################################################################################
function Copy-UDF {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The root folder of the created application package.')]
        [System.String]$ApplicationFolderPath,

        [Parameter(Mandatory=$true,HelpMessage='The selected customer template object from the Template Selection ComboBox.')]
        [System.Object]$SelectedTemplate,

        [Parameter(Mandatory=$false,HelpMessage='The folder where UDF zip files are searched.')]
        [System.String]$FolderToSearch = $Global:ApplicationObject.RootFolder
    )

    try {
        # VALIDATION
        # Validate the target application folder path
        if (Test-String -IsEmpty $ApplicationFolderPath) { throw 'The ApplicationFolderPath parameter is empty.' }
        if (-not (Test-Path -LiteralPath $ApplicationFolderPath -PathType Container)) { throw "The application folder does not exist. ($ApplicationFolderPath)" }

        # VALIDATION
        # Ensure a template object is provided
        if ($null -eq $SelectedTemplate) {
            Write-Line 'No customer template is selected. Skipping UDF copy.' -Type Warning
            return
        }

        # PREPARATION
        # Read the configured UDF zip file name from the selected customer template.
        [System.String]$UDFName = $SelectedTemplate.Content.UDFName
        if (Test-String -IsEmpty $UDFName) {
            Write-Line 'The selected customer template does not define Content.UDFName. Skipping UDF copy.' -Type Warning
            return
        }

        # VALIDATION
        # Ensure the UDF search folder is available.
        if (Test-String -IsEmpty $FolderToSearch) { throw 'The FolderToSearch parameter is empty.' }
        if (-not (Test-Path -LiteralPath $FolderToSearch -PathType Container)) { throw "UDF search folder not found. ($FolderToSearch)" }

        # PREPARATION
        # Find the configured UDF zip file in the customer folder tree.
        [System.String]$ResolvedUDFPath = $null
        [System.IO.FileInfo]$UDFFile = Get-ChildItem -LiteralPath $FolderToSearch -Recurse -File -Filter $UDFName -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($null -ne $UDFFile) { $ResolvedUDFPath = $UDFFile.FullName }

        if (Test-String -IsEmpty $ResolvedUDFPath) {
            Write-Line "The selected UDF zip could not be found in the search folder. ($UDFName)" -Type Warning
            return
        }

        # PREPARATION
        # Resolve the Work subfolder from template, defaulting to 8. Work.
        [System.String]$WorkRelativePath = $SelectedTemplate.ApplicationFolderSubFolders.Work
        if (Test-String -IsEmpty $WorkRelativePath) {
            [System.String]$WorkRelativePath = '8. Work'
        }

        # EXECUTION
        # Ensure the target Work subfolder exists.
        [System.String]$WorkFolderPath = Join-Path -Path $ApplicationFolderPath -ChildPath $WorkRelativePath
        if (-not (Test-Path -LiteralPath $WorkFolderPath -PathType Container)) {
            New-Item -Path $WorkFolderPath -ItemType Directory -Force | Out-Null
        }

        # EXECUTION
        # Extract the UDF archive contents directly into the ApplicationID folder.
        [System.String]$ApplicationID = $Global:Graphics.TextBoxes.ApplicationIntake.ApplicationID.Text
        if (Test-String -IsEmpty $ApplicationID) {
            [System.String]$ApplicationID = 'ApplicationDossier'
        }
        [System.String]$NewUDFFolderPath = Join-Path -Path $WorkFolderPath -ChildPath $ApplicationID
        if (Test-Path -LiteralPath $NewUDFFolderPath -PathType Container) {
            Remove-Item -Path $NewUDFFolderPath -Recurse -Force
        }
        New-Item -Path $NewUDFFolderPath -ItemType Directory -Force | Out-Null

        Write-Line "Extracting UDF archive to folder: $NewUDFFolderPath"
        Expand-Archive -LiteralPath $ResolvedUDFPath -DestinationPath $NewUDFFolderPath -Force

        # Normalize one nested top-level folder if archive was packaged with a root directory.
        [System.String]$ArchiveFolderName = [System.IO.Path]::GetFileNameWithoutExtension($UDFName)
        [System.String]$NestedArchiveFolderPath = Join-Path -Path $NewUDFFolderPath -ChildPath $ArchiveFolderName
        if (Test-Path -LiteralPath $NestedArchiveFolderPath -PathType Container) {
            Get-ChildItem -LiteralPath $NestedArchiveFolderPath -Force | ForEach-Object {
                Move-Item -LiteralPath $_.FullName -Destination $NewUDFFolderPath -Force
            }
            Remove-Item -LiteralPath $NestedArchiveFolderPath -Recurse -Force -ErrorAction SilentlyContinue
        }

        # POST-EXECUTION
        # Report the resolved UDF source and target path.
        Write-Line "Extracted UDF archive: $ResolvedUDFPath"
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
    Exports shortcut information for the selected Intake shortcut to the application archive.
.DESCRIPTION
    This function reads the selected shortcut or shortcut folder from the Intake Application Shortcuts combobox
    and exports its details to a text file under 9. Archive\Shortcuts in the supplied application folder.
.EXAMPLE
    New-ApplicationShortcutInformation -ApplicationFolderPath 'C:\Temp\Vendor_App_1.0'
.INPUTS
    [System.String]
.OUTPUTS
    No objects are returned to the pipeline. All output is written to the host.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. All rights reserved.
    Version         : 6.0.0.0
    Author          : Imraan Iotana
    Creation Date   : June 2026
    Last Update     : June 2026
#>
####################################################################################################
function New-ApplicationShortcutInformation {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The root folder of the created application package.')]
        [System.String]$ApplicationFolderPath,

        [Parameter(Mandatory=$false,HelpMessage='If set, confirmation prompts will be skipped.')]
        [System.Management.Automation.SwitchParameter]$SkipConfirmation
    )

    try {
        # VALIDATION
        # Validate the target application folder path
        if (Test-String -IsEmpty $ApplicationFolderPath) { throw 'The ApplicationFolderPath parameter is empty.' }
        if (-not (Test-Path -LiteralPath $ApplicationFolderPath -PathType Container)) { throw "The application folder does not exist. ($ApplicationFolderPath)" }

        # PREPARATION
        # Resolve the selected shortcut/folder path from the Intake shortcut combobox.
        [System.Object]$SelectedShortcut = $Global:Graphics.ComboBoxes.ApplicationIntake.ApplicationShortcuts.SelectedItem
        if ($null -eq $SelectedShortcut) {
            Write-Line 'No shortcut is selected. Skipping shortcut information export.' -Type Warning
            return
        }

        [System.String]$ShortcutPath = [System.String]$SelectedShortcut.FullPath
        if (Test-String -IsEmpty $ShortcutPath) {
            Write-Line 'The selected shortcut does not contain a valid path. Skipping shortcut information export.' -Type Warning
            return
        }

        # CONFIRMATION
        # Ask the user to confirm exporting the shortcut information.
        [System.String]$Title = 'Confirm Export Shortcut Information'
        [System.String]$Body = "Do you want to export the shortcut information?"
        if (-not $SkipConfirmation -and -not (Get-UserConfirmation -Title $Title -Body $Body)) { return }

        # PREPARATION
        # Build output folder path in 9. Archive\Shortcuts.
        [System.String]$ShortcutsRelativePath = Join-Path -Path '9. Archive' -ChildPath 'Shortcuts'
        [System.String]$ShortcutsFolderPath = Join-Path -Path $ApplicationFolderPath -ChildPath $ShortcutsRelativePath
        if (-not (Test-Path -LiteralPath $ShortcutsFolderPath -PathType Container)) {
            New-Item -Path $ShortcutsFolderPath -ItemType Directory -Force | Out-Null
        }

        # EXECUTION
        # Export shortcut information to the archive shortcuts folder.
        Export-ShortcutInformation -Path $ShortcutPath -ParentOutputFolder $ShortcutsFolderPath
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
    Creates a metadata JSON file with all current Intake values.
.DESCRIPTION
    Collects the current Application Intake information from the UI controls, converts it to a
    JSON payload, and saves it to the Metadata subfolder under 9. Archive in the supplied
    application folder.
.EXAMPLE
    New-MetaDataFile -ApplicationFolderPath 'C:\Temp\Vendor_App_1.0' -SelectedTemplate $Template
.INPUTS
    [System.String]
    [System.Object]
.OUTPUTS
    No objects are returned to the pipeline. All output is written to the host.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. All rights reserved.
    Version         : 6.0.0.0
    Author          : Imraan Iotana
    Creation Date   : June 2026
    Last Update     : June 2026
#>
####################################################################################################
function New-MetaDataFile {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The root folder of the created application package.')]
        [System.String]$ApplicationFolderPath,

        [Parameter(Mandatory=$true,HelpMessage='The selected customer template object from the Template Selection ComboBox.')]
        [System.Object]$SelectedTemplate
    )

    try {
        # VALIDATION
        # Validate the target application folder path
        if (Test-String -IsEmpty $ApplicationFolderPath) { throw 'The ApplicationFolderPath parameter is empty.' }
        if (-not (Test-Path -LiteralPath $ApplicationFolderPath -PathType Container)) { throw "The application folder does not exist. ($ApplicationFolderPath)" }

        # VALIDATION
        # Ensure a template object is provided
        if ($null -eq $SelectedTemplate) {
            Write-Line 'No customer template is selected. Skipping metadata file creation.' -Type Warning
            return
        }

        # PREPARATION
        # Build metadata output path in 9. Archive\Metadata.
        [System.String]$MetadataRelativePath = Join-Path -Path '9. Archive' -ChildPath 'Metadata'
        [System.String]$MetadataFolderPath = Join-Path -Path $ApplicationFolderPath -ChildPath $MetadataRelativePath
        if (-not (Test-Path -LiteralPath $MetadataFolderPath -PathType Container)) {
            New-Item -Path $MetadataFolderPath -ItemType Directory -Force | Out-Null
        }

        # PREPARATION
        # Build a safe file name based on the generated Application ID.
        [System.String]$ApplicationID = $Global:Graphics.TextBoxes.ApplicationIntake.ApplicationID.Text
        if (Test-String -IsEmpty $ApplicationID) {
            [System.String]$ApplicationID = 'ApplicationDossier'
        }
        [System.String]$SafeApplicationID = ($ApplicationID -replace '[\\/:*?""<>|]', '_')
        [System.String]$MetadataFilePath = Join-Path -Path $MetadataFolderPath -ChildPath ("Metadata_$SafeApplicationID.json")

        # PREPARATION
        # Convert UI controls to serializable values.
        [ScriptBlock]$ConvertControlValue = {
            param (
                [Parameter(Mandatory=$false)]
                [System.Object]$Value
            )

            # Preserve nulls and primitive values as-is.
            if ($null -eq $Value) { return $null }
            if ($Value -is [System.String] -or $Value -is [System.ValueType]) { return $Value }

            # Reduce TextBox controls to the user-entered text value.
            if ($Value -is [System.Windows.Forms.TextBox]) {
                return $Value.Text
            }

            # Keep key ComboBox selection details in a compact object.
            if ($Value -is [System.Windows.Forms.ComboBox]) {
                return [PSCustomObject]@{
                    Text         = $Value.Text
                    SelectedItem = $Value.SelectedItem
                    SelectedValue= $Value.SelectedValue
                }
            }

            # Convert hashtables/dictionaries recursively with stable key ordering.
            if ($Value -is [System.Collections.IDictionary]) {
                [System.Collections.Specialized.OrderedDictionary]$Result = [ordered]@{}
                foreach ($Key in ($Value.Keys | Sort-Object)) {
                    $Result[$Key] = & $ConvertControlValue -Value $Value[$Key]
                }
                return [PSCustomObject]$Result
            }

            # Convert arrays and other enumerables recursively.
            if ($Value -is [System.Collections.IEnumerable] -and -not ($Value -is [System.String])) {
                [System.Collections.Generic.List[System.Object]]$Items = @()
                foreach ($Item in $Value) {
                    $Items.Add((& $ConvertControlValue -Value $Item))
                }
                return $Items
            }

            # Convert arbitrary objects by walking gettable properties only.
            if ($Value.PSObject -and $Value.PSObject.Properties.Count -gt 0) {
                [System.Collections.Specialized.OrderedDictionary]$Result = [ordered]@{}
                foreach ($Property in $Value.PSObject.Properties) {
                    if ($Property.IsGettable) {
                        $Result[$Property.Name] = & $ConvertControlValue -Value $Property.Value
                    }
                }
                return [PSCustomObject]$Result
            }

            return $Value.ToString()
        }

        # EXECUTION
        # Build a compact template object without the duplicated Content property.
        Write-Line "Creating metadata JSON file: $MetadataFilePath"
        [System.Object]$SelectedTemplateForMetaData = (& $ConvertControlValue -Value $SelectedTemplate)
        # Drop the heavy Content node to keep metadata focused and small.
        if ($null -ne $SelectedTemplateForMetaData -and $SelectedTemplateForMetaData.PSObject.Properties['Content']) {
            [void]$SelectedTemplateForMetaData.PSObject.Properties.Remove('Content')
        }

        # EXECUTION
        # Build the metadata payload from the current Intake state.
        [PSCustomObject]$MetaDataObject = [PSCustomObject][ordered]@{
            # General properties
            CreatedOn                   = Get-TimeStamp -ForHost
            ApplicationID               = $ApplicationID
            # Formal properties
            FormalVendorName            = $Global:Graphics.TextBoxes.ApplicationIntake.FormalProperties.VendorName.Text
            FormalApplicationName       = $Global:Graphics.TextBoxes.ApplicationIntake.FormalProperties.ApplicationName.Text
            FormalApplicationVersion    = $Global:Graphics.TextBoxes.ApplicationIntake.FormalProperties.ApplicationVersion.Text
            # Custom properties
            CustomVendorName            = $Global:Graphics.TextBoxes.ApplicationIntake.CustomProperties.VendorName.Text
            CustomApplicationName       = $Global:Graphics.TextBoxes.ApplicationIntake.CustomProperties.ApplicationName.Text
            CustomApplicationVersion    = $Global:Graphics.TextBoxes.ApplicationIntake.CustomProperties.ApplicationVersion.Text
            # Security properties
            InstallationFolder          = $Global:Graphics.TextBoxes.ApplicationIntake.Security.InstallationFolder.Text
            ADGroupName                 = $Global:Graphics.TextBoxes.ApplicationIntake.Security.ADGroupName.Text
            ADGroupSID                  = $Global:Graphics.TextBoxes.ApplicationIntake.Security.ADGroupSID.Text
            # Other properties
            DetectionFile               = $Global:Graphics.TextBoxes.ApplicationIntake.Detection.DetectionFile.Text
            DetectionFileVersion        = Get-Item -LiteralPath $Global:Graphics.TextBoxes.ApplicationIntake.Detection.DetectionFile.Text -ErrorAction SilentlyContinue | Select-Object -ExpandProperty VersionInfo -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FileVersion -ErrorAction SilentlyContinue
            Bitness                     = Get-FileBitness -Path $Global:Graphics.TextBoxes.ApplicationIntake.Detection.DetectionFile.Text
            # Extra document information
            UserFullName                = $Global:Graphics.TextBoxes.IntakeSettings.ExtraDocumentInformation.UserFullName.Text
            UserEmailAddress            = $Global:Graphics.TextBoxes.IntakeSettings.ExtraDocumentInformation.UserEmailAddress.Text
            SelectedTemplate            = $SelectedTemplateForMetaData
        }

        # EXECUTION
        # Serialize metadata and write it to disk.
        [System.String]$MetaDataJson = $MetaDataObject | ConvertTo-Json -Depth 20
        Set-Content -Path $MetadataFilePath -Value $MetaDataJson -Encoding UTF8

        # POST-EXECUTION
        # Report the created metadata file path.
        Write-Line "Created metadata JSON file: $MetadataFilePath"
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
    Creates a Word document from the selected customer template in the Documentation subfolder.
.DESCRIPTION
    Resolves the selected customer template from the Template Selection combobox, finds the configured Word template
    below the application root folder, opens it in Word, and saves it as a .docx file in the Documentation subfolder
    of the supplied application folder.
.EXAMPLE
    New-ApplicationIntakeDocument -ApplicationFolderPath 'C:\Temp\Vendor_App_1.0'
.INPUTS
    [System.String]
.OUTPUTS
    No objects are returned to the pipeline. All output is written to the host.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. All rights reserved.
    Version         : 6.0.0.0
    Author          : Imraan Iotana
    Creation Date   : June 2026
    Last Update     : June 2026
#>
####################################################################################################
function New-ApplicationIntakeDocument {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The root folder of the created application package.')]
        [System.String]$ApplicationFolderPath,

        [Parameter(Mandatory=$true,HelpMessage='The selected customer template object from the Template Selection ComboBox.')]
        [System.Object]$SelectedTemplate,

        [Parameter(Mandatory=$false,HelpMessage='The folder where Word templates are searched.')]
        [System.String]$FolderToSearch = (Join-Path -Path $Global:ApplicationObject.RootFolder -ChildPath 'Customer')
    )

    try {
        # VALIDATION
        # Validate the target application folder path
        if (Test-String -IsEmpty $ApplicationFolderPath) { throw 'The ApplicationFolderPath parameter is empty.' }
        if (-not (Test-Path -LiteralPath $ApplicationFolderPath -PathType Container)) { throw "The application folder does not exist. ($ApplicationFolderPath)" }

        # VALIDATION
        # Ensure a template object is provided
        if ($null -eq $SelectedTemplate) {
            Write-Line 'No customer template is selected. Skipping document creation.' -Type Warning
            return
        }

        # PREPARATION
        # Read the configured Word template name from the selected customer template
        [System.String]$WordTemplateName = $SelectedTemplate.Content.TemplateName
        if (Test-String -IsEmpty $WordTemplateName) {
            Write-Line 'The selected customer template does not define Content.TemplateName. Skipping document creation.' -Type Warning
            return
        }

        # VALIDATION
        # Ensure the template search folder is available.
        if (Test-String -IsEmpty $FolderToSearch) { throw 'The FolderToSearch parameter is empty.' }
        if (-not (Test-Path -LiteralPath $FolderToSearch -PathType Container)) { throw "Template search folder not found. ($FolderToSearch)" }

        # PREPARATION
        # Search the template file from the configured template search folder.
        [System.String]$ResolvedTemplatePath = $null
        [System.IO.FileInfo]$TemplateFile = Get-ChildItem -LiteralPath $FolderToSearch -Recurse -File -Filter $WordTemplateName -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($null -ne $TemplateFile) { $ResolvedTemplatePath = $TemplateFile.FullName }

        if (Test-String -IsEmpty $ResolvedTemplatePath) {
            Write-Line "The selected Word template could not be found in the template search folder. ($WordTemplateName)" -Type Fail
            return
        }

        # PREPARATION
        # Resolve the Documentation subfolder configured by the selected customer template
        [System.String]$DocumentationRelativePath = $SelectedTemplate.ApplicationFolderSubFolders.Documentation
        if (Test-String -IsEmpty $DocumentationRelativePath) {
            Write-Line 'The selected customer template does not define ApplicationFolderSubFolders.Documentation. Skipping document creation.' -Type Warning
            return
        }

        # EXECUTION
        # Ensure the target Documentation subfolder exists
        [System.String]$DocumentationFolderPath = Join-Path -Path $ApplicationFolderPath -ChildPath $DocumentationRelativePath
        if (-not (Test-Path -LiteralPath $DocumentationFolderPath -PathType Container)) {
            New-Item -Path $DocumentationFolderPath -ItemType Directory -Force | Out-Null
        }

        # PREPARATION
        # Build the output document name using the generated Application ID
        [System.String]$ApplicationID = $Global:Graphics.TextBoxes.ApplicationIntake.ApplicationID.Text
        if (Test-String -IsEmpty $ApplicationID) {
            [System.String]$ApplicationID = 'ApplicationDossier'
        }

        [System.String]$OutputDocumentPath = Join-Path -Path $DocumentationFolderPath -ChildPath ('KPN Dossier ' + $ApplicationID + '.docx')

        # EXECUTION
        # Create the intake document from template and fill the fields
        New-AppDocumentation -TemplatePath $ResolvedTemplatePath -OutputPath $OutputDocumentPath

        # POST-EXECUTION
        # Report the created document path.
        Write-Line "Created Word document from template: $OutputDocumentPath"
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
    Creates an application documentation Word file from a template and replaces placeholder text.
.DESCRIPTION
    Opens a Word template as a new document, replaces known placeholder text values, and saves the result
    to the supplied output path as a .docx document.
.EXAMPLE
    New-AppDocumentation -TemplatePath 'C:\Templates\Dossier.dotx' -OutputPath 'C:\Out\Dossier.docx'
.INPUTS
    [System.String]
.OUTPUTS
    No objects are returned to the pipeline. All output is written to the host.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. All rights reserved.
    Version         : 6.0.0.0
    Author          : Imraan Iotana
    Creation Date   : June 2026
    Last Update     : June 2026
#>
####################################################################################################
function New-AppDocumentation {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [System.String]$TemplatePath,

        [Parameter(Mandatory=$true)]
        [System.String]$OutputPath
    )

    [System.Object]$Word = $null
    [System.Object]$Document = $null

    try {
        # VALIDATION
        if (Test-String -IsEmpty $TemplatePath) { throw 'The TemplatePath parameter is empty.' }
        if (Test-String -IsEmpty $OutputPath) { throw 'The OutputPath parameter is empty.' }
        if (-not (Test-Path -LiteralPath $TemplatePath -PathType Leaf)) { throw "Template not found. ($TemplatePath)" }

        # CONFIRMATION
        # Ask the user to confirm creating the Word document.
        [System.String]$Title = 'Confirm Word Document'
        [System.String]$Body = "Do you want to create the Word document?"
        if (-not (Get-UserConfirmation -Title $Title -Body $Body)) { return }
        
        # PREPARATION
        # Start Word in the background and create a new document from the template.
        Write-Line "Creating Word document, one moment please..."
        $Word = New-Object -ComObject Word.Application
        $Word.Visible = $false
        $Document = $Word.Documents.Add($TemplatePath)

        # PREPARATION
        # Map placeholder text to replacement values.
        [System.Collections.Hashtable]$ReplaceMap = Get-DocumentReplacementMap

        # EXECUTION
        # Replace placeholder text in the whole document body.
        foreach ($Key in $ReplaceMap.Keys) {
            [System.Object]$Find = $Document.Content.Find
            [void]$Find.ClearFormatting()
            [void]$Find.Replacement.ClearFormatting()
            [void]$Find.Execute(
                [ref]$Key,
                [ref]$false,
                [ref]$false,
                [ref]$false,
                [ref]$false,
                [ref]$false,
                [ref]$true,
                [ref]1,
                [ref]$false,
                [ref]$ReplaceMap[$Key],
                [ref]2
            )
        }

        # EXECUTION
        # Save the generated document.
        [System.String]$ResolvedOutputPath = [System.IO.Path]::GetFullPath($OutputPath)
        [System.String]$OutputDirectory = [System.IO.Path]::GetDirectoryName($ResolvedOutputPath)
        if (-not (Test-Path -LiteralPath $OutputDirectory -PathType Container)) {
            New-Item -Path $OutputDirectory -ItemType Directory -Force | Out-Null
        }

        $Document.SaveAs2($ResolvedOutputPath)
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
    finally {
        # POST-EXECUTION
        # Ensure COM objects are closed and released.
        if ($Document) {
            $Document.Close($false)
            [void][System.Runtime.InteropServices.Marshal]::ReleaseComObject($Document)
        }
        if ($Word) {
            $Word.Quit()
            [void][System.Runtime.InteropServices.Marshal]::ReleaseComObject($Word)
        }
        # Clean up variables to avoid accidental reuse and reduce memory footprint.
        Remove-Variable Document -ErrorAction SilentlyContinue
        Remove-Variable Word -ErrorAction SilentlyContinue
    }
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Builds the placeholder-to-value map for Word document replacement.
.DESCRIPTION
    Returns a hashtable that maps the supported document placeholder tokens to their current values
    from the Intake textboxes. This map is used by New-AppDocumentation to perform Find/Replace updates
    in the generated Word document.
.EXAMPLE
    Get-DocumentReplacementMap
.INPUTS
    None.
.OUTPUTS
    [System.Collections.Hashtable]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. All rights reserved.
    Version         : 6.0.0.0
    Author          : Imraan Iotana
    Creation Date   : June 2026
    Last Update     : June 2026
#>
####################################################################################################
function Get-DocumentReplacementMap {
    # EXECUTION
    # Build a static replacement map from the corresponding textbox values.
    return @{
        # Formal Application Properties
        '[FORMALVENDORNAME]'         = $Global:Graphics.TextBoxes.ApplicationIntake.FormalProperties.VendorName.Text
        '[FORMALAPPLICATIONNAME]'    = $Global:Graphics.TextBoxes.ApplicationIntake.FormalProperties.ApplicationName.Text
        '[FORMALAPPLICATIONVERSION]' = $Global:Graphics.TextBoxes.ApplicationIntake.FormalProperties.ApplicationVersion.Text
        # Custom Application Properties
        '[CUSTOMVENDORNAME]'         = $Global:Graphics.TextBoxes.ApplicationIntake.CustomProperties.VendorName.Text
        '[CUSTOMAPPLICATIONNAME]'    = $Global:Graphics.TextBoxes.ApplicationIntake.CustomProperties.ApplicationName.Text
        '[CUSTOMAPPLICATIONVERSION]' = $Global:Graphics.TextBoxes.ApplicationIntake.CustomProperties.ApplicationVersion.Text
        # Other Intake Properties
        '[INSTALLATIONFOLDER]'       = $Global:Graphics.TextBoxes.ApplicationIntake.Security.InstallationFolder.Text
        '[BITNESS]'                  = (Get-FileBitness -Path $Global:Graphics.TextBoxes.ApplicationIntake.Detection.DetectionFile.Text -ForDocument)
        # User properties
        '[USERFULLNAME]'             = $Global:Graphics.TextBoxes.IntakeSettings.ExtraDocumentInformation.UserFullName.Text
        '[USEREMAILADDRESS]'         = $Global:Graphics.TextBoxes.IntakeSettings.ExtraDocumentInformation.UserEmailAddress.Text
    }
}

### END OF FUNCTION
####################################################################################################

