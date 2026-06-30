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
    [System.String]
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

        # PREPARATION - TEXTBOXES
        # Derive the subkey for the TextBoxes from the current tab
        [System.String]$SubKeyForBoxes = New-SubKeyForBoxes -ParentTabPage $ParentTabPage -PassThru

        # EXECUTION - TEXTBOX
        # Set the TextBox properties
        [System.Collections.Hashtable]$ApplicationIDTextBoxProperties = @{
            RowNumber       = 2
            Label           = 'Application ID'
            PropertyName    = "TextBoxes.$SubKeyForBoxes.ApplicationID"
            ToolTip         = 'The ID of the application to intake'
            SizeType        = 'Medium'
            Type            = 'Output'
        }

        # Create the TextBox
        [System.Windows.Forms.TextBox]$ApplicationIDTextBox = New-TextBox @ApplicationIDTextBoxProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ReturnTextBox
        $Global:Graphics.TextBoxes[$SubKeyForBoxes].ApplicationID = $ApplicationIDTextBox

        # EXECUTION - BUTTONS
        # Set the Buttons properties
        [System.Collections.Hashtable]$ApplicationIDButtonProperties = @{
            ColumnNumber    = 1
            RowNumber       = 1
            Text            = 'Application ID'
            PNGFileName     = 'download_for_windows'
            SizeType        = 'Medium'
            ToolTip         = 'Browse for a detection file or MSI.'
            Function        = { New-ApplicationIDFromTextBoxes -OutputTextBox $ApplicationIDTextBox }.GetNewClosure()
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
    Resolves the Intake Application ID textbox from Graphics.TextBoxes.
.DESCRIPTION
    This function resolves the Application ID textbox from the flattened graphics key model first,
    then falls back to the legacy ApplicationIntake key path.
.EXAMPLE
    Get-IntakeApplicationIDTextBox
.INPUTS
    No input objects are accepted.
.OUTPUTS
    [System.Windows.Forms.TextBox] when found; otherwise $null.
#>
####################################################################################################
function Get-IntakeApplicationIDTextBox {
    [CmdletBinding()]
    [OutputType([System.Windows.Forms.TextBox])]
    param ()

    if ($Global:Graphics.TextBoxes -is [System.Collections.IDictionary]) {
        foreach ($Key in $Global:Graphics.TextBoxes.Keys) {
            [System.Object]$Section = $Global:Graphics.TextBoxes[$Key]
            if ($Section -is [System.Collections.IDictionary] -and $Section.ContainsKey('ApplicationID')) {
                if ($Section.ApplicationID -is [System.Windows.Forms.TextBox]) {
                    return $Section.ApplicationID
                }
            }
        }
    }

    if ($Global:Graphics.TextBoxes.ApplicationIntake -is [System.Collections.IDictionary] -and $Global:Graphics.TextBoxes.ApplicationIntake.ContainsKey('ApplicationID')) {
        if ($Global:Graphics.TextBoxes.ApplicationIntake.ApplicationID -is [System.Windows.Forms.TextBox]) {
            return $Global:Graphics.TextBoxes.ApplicationIntake.ApplicationID
        }
    }

    return $null
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
    No objects are returned to the pipeline.
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
        # Resolve the custom properties section from flattened keys first, then fallback to legacy nested path.
        [System.Object]$CustomSection = $null
        foreach ($Key in $Global:Graphics.TextBoxes.Keys) {
            [System.Object]$Section = $Global:Graphics.TextBoxes[$Key]
            if ($Section -is [System.Collections.IDictionary] -and $Section.ContainsKey('CustomProperties')) {
                $CustomSection = $Section.CustomProperties
                break
            }
        }
        if ($null -eq $CustomSection -and $Global:Graphics.TextBoxes.ApplicationIntake -is [System.Collections.IDictionary] -and $Global:Graphics.TextBoxes.ApplicationIntake.ContainsKey('CustomProperties')) {
            $CustomSection = $Global:Graphics.TextBoxes.ApplicationIntake.CustomProperties
        }
        if ($null -eq $CustomSection) {
            throw 'Unable to resolve Intake CustomProperties textboxes from Graphics.TextBoxes.'
        }

        # Create a hashtable to store the trimmed values of the TextBoxes
        [System.Collections.Hashtable]$TrimmedValues = @{}
        # Loop through the TextBoxes, get the text, trim it and store it in the hashtable
        foreach ($TextBoxName in $TextBoxesToGetTextFrom) {
            $TrimmedValues[$TextBoxName] = ($CustomSection.$TextBoxName.Text -replace '\s+', '')
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
    Resolves a ComboBox from Graphics.ComboBoxes by logical name.
.DESCRIPTION
    Searches flattened ComboBox sections first, then legacy nested sections,
    and finally the legacy ApplicationIntake fallback node.
.EXAMPLE
    Get-GraphicsComboBoxByName -ComboBoxName 'TemplateSelection'
.INPUTS
    [System.String]
.OUTPUTS
    [System.Windows.Forms.ComboBox] when found; otherwise $null.
#>
####################################################################################################
function Get-GraphicsComboBoxByName {
    [CmdletBinding()]
    [OutputType([System.Windows.Forms.ComboBox])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The ComboBox key name to resolve from Graphics.ComboBoxes.')]
        [System.String]$ComboBoxName
    )

    if ($Global:Graphics.ComboBoxes -is [System.Collections.IDictionary]) {
        foreach ($ParentKey in $Global:Graphics.ComboBoxes.Keys) {
            [System.Object]$ParentNode = $Global:Graphics.ComboBoxes.$ParentKey
            if ($ParentNode -isnot [System.Collections.IDictionary]) { continue }

            # Flattened layout: ComboBox stored directly in the section hashtable.
            if ($ParentNode.ContainsKey($ComboBoxName) -and $ParentNode.$ComboBoxName -is [System.Windows.Forms.ComboBox]) {
                return $ParentNode.$ComboBoxName
            }

            # Legacy nested layout: one additional level (tab -> subtab -> ComboBox).
            foreach ($SubTabKey in $ParentNode.Keys) {
                [System.Object]$SubTabNode = $ParentNode.$SubTabKey
                if (($SubTabNode -is [System.Collections.IDictionary]) -and $SubTabNode.ContainsKey($ComboBoxName) -and $SubTabNode.$ComboBoxName -is [System.Windows.Forms.ComboBox]) {
                    return $SubTabNode.$ComboBoxName
                }
            }
        }
    }

    if (($Global:Graphics.ComboBoxes.ApplicationIntake -is [System.Collections.IDictionary]) -and $Global:Graphics.ComboBoxes.ApplicationIntake.ContainsKey($ComboBoxName)) {
        if ($Global:Graphics.ComboBoxes.ApplicationIntake.$ComboBoxName -is [System.Windows.Forms.ComboBox]) {
            return $Global:Graphics.ComboBoxes.ApplicationIntake.$ComboBoxName
        }
    }

    return $null
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Resolves the Intake Security section from Graphics.TextBoxes.
.DESCRIPTION
    Searches flattened Intake sections first, then falls back to the legacy
    ApplicationIntake.Security node.
.EXAMPLE
    Get-IntakeSecuritySection
.INPUTS
    No input objects are accepted.
.OUTPUTS
    [System.Object] hashtable-like section when found; otherwise $null.
#>
####################################################################################################
function Get-IntakeSecuritySection {
    [CmdletBinding()]
    param ()

    foreach ($Key in $Global:Graphics.TextBoxes.Keys) {
        [System.Object]$Section = $Global:Graphics.TextBoxes[$Key]
        if (($Section -is [System.Collections.IDictionary]) -and $Section.ContainsKey('Security')) {
            return $Section.Security
        }
    }

    if (($Global:Graphics.TextBoxes.ApplicationIntake -is [System.Collections.IDictionary]) -and $Global:Graphics.TextBoxes.ApplicationIntake.ContainsKey('Security')) {
        return $Global:Graphics.TextBoxes.ApplicationIntake.Security
    }

    return $null
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
    creates the folder and its configured subfolders, generates initial artifacts, and opens the output folder afterwards.
.EXAMPLE
    New-ApplicationFolder
.INPUTS
    [System.String]
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
function New-ApplicationFolder {
    param (
        [Parameter(Mandatory=$false,HelpMessage='Destination folder where the export text file will be created.')]
        [System.String]$OutputFolder = (Get-OutputFolder)
    )
    
    try {
        # 1) Validate output location and resolve the current Application ID.
        # VALIDATION
        # Ensure the output folder is usable.
        if (Test-String -IsEmpty $OutputFolder) { throw "The OutputFolder parameter is empty." }
        if (-not (Test-Path -Path $OutputFolder -PathType Container)) { New-Item -Path $OutputFolder -ItemType Directory -Force | Out-Null }

        # PREPARATION
        # Resolve and refresh the Application ID.
        [System.Windows.Forms.TextBox]$ApplicationIDTextBox = Get-IntakeApplicationIDTextBox
        New-ApplicationIDFromTextBoxes -OutputTextBox $ApplicationIDTextBox
        [System.String]$ApplicationID = if ($null -ne $ApplicationIDTextBox) { $ApplicationIDTextBox.Text } else { $null }
        if (Test-String -IsEmpty $ApplicationID) {
            Write-Line "The Application ID is empty. Please generate an Application ID before creating the application folder. No action has been taken."
            return
        }

        # 2) Resolve template selection and target folder structure.
        # PREPARATION
        # Resolve the selected customer template.
        [System.Object]$TemplateSelectionComboBox = Get-GraphicsComboBoxByName -ComboBoxName 'TemplateSelection'
        [System.Object]$SelectedTemplate = if ($null -ne $TemplateSelectionComboBox) { $TemplateSelectionComboBox.SelectedItem } else { $null }
        if ($null -eq $SelectedTemplate) {
            Write-Line 'No customer template selected. Please select a template first. No action has been taken.'
            return
        }

        # Resolve subfolders from the selected template
        [System.Object]$ApplicationFolderSubFolders = $SelectedTemplate.ApplicationFolderSubFolders
        if ($null -eq $ApplicationFolderSubFolders) {
            Write-Line 'The selected template has no ApplicationFolderSubFolders configuration. No action has been taken.'
            return
        }

        # Set the path for the new folder
        [System.String]$NewFolderPath = Join-Path -Path $OutputFolder -ChildPath $ApplicationID

        # CONFIRMATION
        if (Test-Path -Path $NewFolderPath -PathType Container) {
            [System.String]$Title   = "Confirm Overwrite Application Folder"
            [System.String]$Body    = "This will OVERWRITE the EXISTING APPLICATION FOLDER with the following name:`n`n$ApplicationID`n`nDo you want to continue?"
        }
        else {
            [System.String]$Title   = "Create Application Folder"
            [System.String]$Body    = "This will create a NEW APPLICATION FOLDER with the following name:`n`n$ApplicationID`n`nDo you want to continue?"
        }
        if (Get-UserConfirmation -Title $Title -Body $Body) {
            Write-Line "Creating application folder: $NewFolderPath. One moment please..."
        } else {
            return
        }

        # 3) Create folder tree and base artifacts.
        # EXECUTION
        # Recreate the root application folder.
        if (Test-Path -Path $NewFolderPath -PathType Container) { Remove-Item -Path $NewFolderPath -Recurse -Force }
        New-Item -Path $NewFolderPath -ItemType Directory -Force | Out-Null

        # Create configured application subfolders.
        [System.Collections.Generic.List[System.String]]$SubFolders = @($ApplicationFolderSubFolders.GetEnumerator() | ForEach-Object { $_.Value })
        if ($SubFolders.Count -eq 0) {
            Write-Line 'The selected template defines no application subfolders. No action has been taken.'
            return
        }
        foreach ($SubFolder in $SubFolders) {
            [System.String]$SubFolderPath = Join-Path -Path $NewFolderPath -ChildPath $SubFolder
            New-Item -Path $SubFolderPath -ItemType Directory -Force | Out-Null
        }

        # Create initial artifacts in the folder.
        New-MetaDataFile -ApplicationFolderPath $NewFolderPath -SelectedTemplate $SelectedTemplate
        New-ApplicationIntakeDocument -ApplicationFolderPath $NewFolderPath -SelectedTemplate $SelectedTemplate -FolderToSearch (Join-Path -Path $Global:ApplicationObject.RootFolder -ChildPath 'Customer')

        # 4) Add optional exports and generated files that depend on UI selections.
        # Export selected application registry details to the template-defined Archive\Other folder.
        [System.Object]$InstalledApplicationsComboBox = Get-GraphicsComboBoxByName -ComboBoxName 'InstalledApplications'
        [System.Object]$SelectedInstalledApplication = if ($null -ne $InstalledApplicationsComboBox) { $InstalledApplicationsComboBox.SelectedItem } else { $null }
        [System.String]$SelectedRegistryPath = if ($null -ne $SelectedInstalledApplication) { $SelectedInstalledApplication.RegistryPath } else { $null }
        [System.String]$OtherRelativePath = [System.String]$ApplicationFolderSubFolders.Other
        if (Test-String -IsEmpty $OtherRelativePath) {
            Write-Line 'The selected customer template does not define ApplicationFolderSubFolders.Other. Skipping registry export.' -Type Warning
        }
        elseif (Test-String -IsPopulated $SelectedRegistryPath) {
            [System.String]$RegistryExportOutputFolder = Join-Path -Path $NewFolderPath -ChildPath $OtherRelativePath
            Export-RegistryKey -RegistryKeyPath $SelectedRegistryPath -OutputFolder $RegistryExportOutputFolder
        }
        else {
            Write-Line 'No installed application selected. Skipping registry export.' -Type Warning
        }

        [System.Object]$ApplicationShortcutsComboBox = Get-GraphicsComboBoxByName -ComboBoxName 'ApplicationShortcuts'
        Export-ShortcutInformation -ApplicationFolderPath $NewFolderPath -ShortcutComboBox $ApplicationShortcutsComboBox

        [System.Object]$SecuritySection = Get-IntakeSecuritySection
        [System.String]$SecurityInstallationFolder = if ($null -ne $SecuritySection -and $null -ne $SecuritySection.InstallationFolder) { $SecuritySection.InstallationFolder.Text } else { $null }
        [System.String]$SecurityADGroupSID = if ($null -ne $SecuritySection -and $null -ne $SecuritySection.ADGroupSID) { $SecuritySection.ADGroupSID.Text } else { $null }
        New-AppLockerFile -Path $SecurityInstallationFolder -ADGroupSID $SecurityADGroupSID -ApplicationID $ApplicationID -SelectedTemplate $SelectedTemplate

        Copy-UDF -ApplicationFolderPath $NewFolderPath -SelectedTemplate $SelectedTemplate

        # 5) Report completion and open destination.
        # Report completion and open destination.
        Write-Line "The new application folder has been created. ($ApplicationID)"
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
    No objects are returned to the pipeline.
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
        [System.String]$FolderToSearch = $Global:ApplicationObject.RootFolder,

        [Parameter(Mandatory=$false,HelpMessage='Skip the confirmation prompt and extract immediately.')]
        [System.Management.Automation.SwitchParameter]$SkipConfirmation
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

        # CONFIRMATION
        # Ask for confirmation only when -SkipConfirmation is not specified.
        if (-not $SkipConfirmation) {
            [System.String]$Title   = 'Copy UDF Archive'
            [System.String]$Body    = "Would you like to add the UNIVERSAL DEPLOYMENT FRAMEWORK (UDF) into the application Work folder?"
            if (-not (Get-UserConfirmation -Title $Title -Body $Body)) { return }
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
        [System.Windows.Forms.TextBox]$ApplicationIDTextBox = Get-IntakeApplicationIDTextBox
        [System.String]$ApplicationID = if ($null -ne $ApplicationIDTextBox) { $ApplicationIDTextBox.Text } else { $null }
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
        Write-Line "Added the Universal Deployment Framework: $ResolvedUDFPath" -Type Success
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
    No objects are returned to the pipeline.
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
        # Build metadata output path from the selected template (with safe default fallback).
        [System.String]$MetadataRelativePath = [System.String]$SelectedTemplate.ApplicationFolderSubFolders.Metadata
        if (Test-String -IsEmpty $MetadataRelativePath) {
            [System.String]$MetadataRelativePath = Join-Path -Path '9. Archive' -ChildPath 'Metadata'
            Write-Line 'The selected customer template does not define ApplicationFolderSubFolders.Metadata. Using default path: (9. Archive\Metadata)' -Type Warning
        }
        [System.String]$MetadataFolderPath = Join-Path -Path $ApplicationFolderPath -ChildPath $MetadataRelativePath
        if (-not (Test-Path -LiteralPath $MetadataFolderPath -PathType Container)) {
            New-Item -Path $MetadataFolderPath -ItemType Directory -Force | Out-Null
        }

        # PREPARATION
        # Build a safe file name based on the generated Application ID.
        [System.Windows.Forms.TextBox]$ApplicationIDTextBox = Get-IntakeApplicationIDTextBox
        [System.String]$ApplicationID = if ($null -ne $ApplicationIDTextBox) { $ApplicationIDTextBox.Text } else { $null }
        if (Test-String -IsEmpty $ApplicationID) {
            [System.String]$ApplicationID = 'ApplicationDossier'
        }
        [System.String]$SafeApplicationID = ($ApplicationID -replace '[\\/:*?""<>|]', '_')
        [System.String]$MetadataFilePath = Join-Path -Path $MetadataFolderPath -ChildPath ("Metadata_$SafeApplicationID.json")

        # PREPARATION
        # Convert UI controls to serializable values.
        # This keeps JSON creation resilient by stripping WinForms objects down to plain values.
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
        # Remove redundant path aliases from SelectedTemplate in metadata output.
        # These values duplicate information already present in FileName/Identity and folder sub-objects.
        if ($null -ne $SelectedTemplateForMetaData -and $SelectedTemplateForMetaData.PSObject.Properties['TemplatePath']) {
            [void]$SelectedTemplateForMetaData.PSObject.Properties.Remove('TemplatePath')
        }
        if ($null -ne $SelectedTemplateForMetaData -and $SelectedTemplateForMetaData.PSObject.Properties['FullName']) {
            [void]$SelectedTemplateForMetaData.PSObject.Properties.Remove('FullName')
        }
        if ($null -ne $SelectedTemplateForMetaData -and $SelectedTemplateForMetaData.PSObject.Properties['Directory']) {
            [void]$SelectedTemplateForMetaData.PSObject.Properties.Remove('Directory')
        }

        # PREPARATION
        # Local resolver helpers keep Graphics.TextBoxes lookups centralized and compact.
        [ScriptBlock]$GetTextBoxSection = {
            param (
                [Parameter(Mandatory=$true)]
                [System.String[]]$SectionKeys,

                [Parameter(Mandatory=$false)]
                [System.String[]]$PreferredRootKeys = @()
            )

            if ($Global:Graphics.TextBoxes -isnot [System.Collections.IDictionary]) { return $null }

            # Build a deterministic root list: preferred keys first, then discovered keys without duplicates.
            [System.Collections.Generic.List[System.String]]$SearchRoots = @()
            foreach ($RootKey in ($PreferredRootKeys + @($Global:Graphics.TextBoxes.Keys))) {
                [System.String]$RootKeyString = [System.String]$RootKey
                if (-not [System.String]::IsNullOrWhiteSpace($RootKeyString) -and -not $SearchRoots.Contains($RootKeyString)) {
                    $SearchRoots.Add($RootKeyString)
                }
            }

            foreach ($RootKey in $SearchRoots) {
                [System.Object]$RootNode = $Global:Graphics.TextBoxes[$RootKey]
                if ($RootNode -isnot [System.Collections.IDictionary]) { continue }

                foreach ($SectionKey in $SectionKeys) {
                    if ($RootNode.ContainsKey($SectionKey)) {
                        return $RootNode[$SectionKey]
                    }
                }
            }

            return $null
        }

        [ScriptBlock]$GetDetectionTextBox = {
            param (
                [Parameter(Mandatory=$false)]
                [System.String[]]$PreferredRootKeys = @('ApplicationIntake')
            )

            if ($Global:Graphics.TextBoxes -isnot [System.Collections.IDictionary]) { return $null }

            [System.Collections.Generic.List[System.String]]$SearchRoots = @()
            foreach ($RootKey in ($PreferredRootKeys + @($Global:Graphics.TextBoxes.Keys))) {
                [System.String]$RootKeyString = [System.String]$RootKey
                if (-not [System.String]::IsNullOrWhiteSpace($RootKeyString) -and -not $SearchRoots.Contains($RootKeyString)) {
                    $SearchRoots.Add($RootKeyString)
                }
            }

            foreach ($RootKey in $SearchRoots) {
                [System.Object]$RootNode = $Global:Graphics.TextBoxes[$RootKey]
                if ($RootNode -isnot [System.Collections.IDictionary]) { continue }

                if ($RootNode.ContainsKey('DetectionFile') -and $RootNode.DetectionFile -is [System.Windows.Forms.TextBox]) {
                    return $RootNode.DetectionFile
                }

                # Legacy layouts may nest DetectionFile under a Detection node.
                if ($RootNode.ContainsKey('Detection') -and
                    $RootNode.Detection -is [System.Collections.IDictionary] -and
                    $RootNode.Detection.ContainsKey('DetectionFile') -and
                    $RootNode.Detection.DetectionFile -is [System.Windows.Forms.TextBox]) {
                    return $RootNode.Detection.DetectionFile
                }
            }

            return $null
        }

        # Resolve Intake sections and detection textbox.
        [System.Object]$FormalSection = (& $GetTextBoxSection -SectionKeys @('FormalProperties', 'FormalApplicationProperties') -PreferredRootKeys @('ApplicationIntake'))
        [System.Object]$CustomSection = (& $GetTextBoxSection -SectionKeys @('CustomProperties') -PreferredRootKeys @('ApplicationIntake'))
        [System.Object]$SecuritySection = (& $GetTextBoxSection -SectionKeys @('Security') -PreferredRootKeys @('ApplicationIntake'))
        [System.Windows.Forms.TextBox]$DetectionTextBox = (& $GetDetectionTextBox)

        if ($null -eq $FormalSection -or $null -eq $CustomSection -or $null -eq $SecuritySection -or $null -eq $DetectionTextBox) {
            throw 'Unable to resolve Intake textbox sections (Formal, Custom, Security) and DetectionFile from Graphics.TextBoxes.'
        }

        # PREPARATION
        # Resolve extra document information section from Intake Extras (with legacy fallback).
        [System.Object]$ExtraDocumentSection = (& $GetTextBoxSection -SectionKeys @('ExtraDocumentInformation') -PreferredRootKeys @('IntakeExtras', 'IntakeSettings'))
        [System.Windows.Forms.TextBox]$UserFullNameTextBox = if ($ExtraDocumentSection -is [System.Collections.IDictionary] -and $ExtraDocumentSection.ContainsKey('UserFullName')) { $ExtraDocumentSection.UserFullName } else { $null }
        [System.Windows.Forms.TextBox]$UserEmailAddressTextBox = if ($ExtraDocumentSection -is [System.Collections.IDictionary] -and $ExtraDocumentSection.ContainsKey('UserEmailAddress')) { $ExtraDocumentSection.UserEmailAddress } else { $null }

        # EXECUTION
        # Build the metadata payload from the current Intake state.
        [PSCustomObject]$MetaDataObject = [PSCustomObject][ordered]@{
            # General properties
            CreatedOn                   = Get-TimeStamp -ForHost
            ApplicationID               = $ApplicationID
            # Formal properties
            FormalVendorName            = $FormalSection.VendorName.Text
            FormalApplicationName       = $FormalSection.ApplicationName.Text
            FormalApplicationVersion    = $FormalSection.ApplicationVersion.Text
            # Custom properties
            CustomVendorName            = $CustomSection.VendorName.Text
            CustomApplicationName       = $CustomSection.ApplicationName.Text
            CustomApplicationVersion    = $CustomSection.ApplicationVersion.Text
            # Security properties
            InstallationFolder          = $SecuritySection.InstallationFolder.Text
            ADGroupName                 = $SecuritySection.ADGroupName.Text
            ADGroupSID                  = $SecuritySection.ADGroupSID.Text
            # Other properties
            DetectionFile               = $DetectionTextBox.Text
            DetectionFileVersion        = Get-Item -LiteralPath $DetectionTextBox.Text -ErrorAction SilentlyContinue | Select-Object -ExpandProperty VersionInfo -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FileVersion -ErrorAction SilentlyContinue
            Bitness                     = Get-FileBitness -Path $DetectionTextBox.Text
            # Extra document information
            UserFullName                = if ($null -ne $UserFullNameTextBox) { $UserFullNameTextBox.Text } else { $null }
            UserEmailAddress            = if ($null -ne $UserEmailAddressTextBox) { $UserEmailAddressTextBox.Text } else { $null }
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

