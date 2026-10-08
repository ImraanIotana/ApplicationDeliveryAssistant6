####################################################################################################
<#
.SYNOPSIS
    Imports the Application Maintenance feature into the Maintenance sub-tab
.DESCRIPTION
    This function creates a placeholder GroupBox for the Application Maintenance feature
.EXAMPLE
    Import-FeatureApplicationMaintenance -InputObject $MyApplicationObject -ParentTabPage $MyTabPage
.INPUTS
    [PSCustomObject]
    [System.Windows.Forms.TabPage]
    [System.Windows.Forms.GroupBox]
    [System.String]
.OUTPUTS
    [System.Windows.Forms.GroupBox]
.NOTES
    This script is part of the Application Delivery Assistant Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.9.1
    Author          : Imraan Iotana
    Creation Date   : July 2026
    Last Update     : October 2026
#>
####################################################################################################
function Import-FeatureApplicationMaintenance {
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
            Title           = 'APPLICATION MAINTENANCE'
            Color           = $Color
            NumberOfRows    = 1
            GroupBoxAbove   = $GroupBoxAbove
        }

        # EXECUTION - GROUPBOX
        # Create the GroupBox
        [System.Windows.Forms.GroupBox]$FeatureGroupBox = New-GroupBox @GroupBoxProperties

        # PREPARATION - ACTION COMBOBOX
        # Set the DefaultValue for the action selector to the first item in the list
        [System.String]$DefaultAction = 'Select an action...'
        # Create a simple string list of available maintenance actions
        [System.String[]]$MaintenanceActions = @(
            $DefaultAction,
            'GENERAL: View Change Log',
            'GENERAL: Check for Updates',
            'GENERAL: Install Application to Folder',
            'GENERAL: Create Startmenu Shortcut',
            'GENERAL: Create Desktop Shortcut',
            'USER SETTINGS: Export User Settings (JSON)',
            'USER SETTINGS: Export User Settings (CLIXML)',
            'USER SETTINGS: Import User Settings (JSON/CLIXML)',
            'USER SETTINGS: Reset User Settings'
        )

        [System.Collections.Hashtable]$ActionComboBoxProperties = @{
            RowNumber           = 1
            Label               = 'Select Action'
            SizeType            = 'Medium'
            Type                = 'Output'
            ContentStringArray  = $MaintenanceActions
            DefaultValue        = $DefaultAction
            ShowColorSwatches   = $false
        }

        # Create the action selector
        [System.Windows.Forms.ComboBox]$ActionComboBox = New-GraphicComboBox @ActionComboBoxProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ReturnComboBox

        # EXECUTION - BUTTONS
        # Add one execute button that dispatches to the selected maintenance action
        [System.Collections.Hashtable[]]$ButtonPropertiesArray = @(
            @{
                ColumnNumber    = 5
                Text            = 'Execute'
                PNGFileName     = 'cog_go'
                SizeType        = 'Medium'
                ToolTip         = 'Execute the selected Application Maintenance action.'
                Function        = {
                    [System.String]$SelectedAction = [System.String]$ActionComboBox.Text
                    if (Test-String -IsEmpty $SelectedAction) {
                        Write-Line 'Please select an action first.' -Type Warning
                        return
                    }

                    switch ($SelectedAction) {
                        $DefaultAction {
                            Write-Line 'Please select a maintenance action first.' -Type Warning
                        }
                        'GENERAL: View Change Log' {
                            Show-ApplicationChangeLog -InputObject $InputObject
                        }
                        'GENERAL: Check for Updates' {
                            Write-Line 'Check for Updates is not implemented yet.' -Type Warning
                        }
                        'GENERAL: Install Application to Folder' {
                            Install-ApplicationToFolder -InputObject $InputObject
                        }
                        'GENERAL: Create Startmenu Shortcut' {
                            New-ApplicationShortcut -InputObject $InputObject -ShortcutType 'Startmenu'
                        }
                        'GENERAL: Create Desktop Shortcut' {
                            New-ApplicationShortcut -InputObject $InputObject -ShortcutType 'Desktop'
                        }
                        'USER SETTINGS: Export User Settings (JSON)' {
                            Export-ApplicationMaintenanceSettings -InputObject $InputObject -Format Json
                        }
                        'USER SETTINGS: Export User Settings (CLIXML)' {
                            Export-ApplicationMaintenanceSettings -InputObject $InputObject -Format CliXml
                        }
                        'USER SETTINGS: Import User Settings (JSON/CLIXML)' {
                            Import-ApplicationMaintenanceSettings -InputObject $InputObject
                        }
                        'USER SETTINGS: Reset User Settings' {
                            Invoke-ApplicationMaintenanceResetSettings -InputObject $InputObject
                        }
                        default {
                            Write-Line "Unknown maintenance action selected: ($SelectedAction)" -Type Warning
                        }
                    }
                }.GetNewClosure()
            }
        )
        New-ButtonLine -InputObject $InputObject -ButtonPropertiesArray $ButtonPropertiesArray -ParentGroupBox $FeatureGroupBox -RowNumber 1

        # POST-EXECUTION
        # Return the configured GroupBox
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
    Displays the application README changelog in a read-only window.
.DESCRIPTION
    Loads README.md from the application root and presents its contents in a resizable viewer.
.EXAMPLE
    Show-ApplicationChangeLog -InputObject $MyApplicationObject
.INPUTS
    [PSCustomObject]
.OUTPUTS
    None.
.NOTES
    This script is part of the Application Delivery Assistant Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.5.2
    Author          : Imraan Iotana
    Creation Date   : August 2026
    Last Update     : August 2026
#>
####################################################################################################
function Show-ApplicationChangeLog {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The ApplicationObject containing the application root folder.')]
        [PSCustomObject]$InputObject
    )

    try {
        [System.String]$RootFolder = [System.String]$InputObject.RootFolder
        if (Test-String -IsEmpty $RootFolder) {
            Write-Line 'The application root folder is empty; the change log cannot be displayed.' -Type Warning
            return
        }

        [System.String]$ChangeLogPath = Join-Path -Path $RootFolder -ChildPath 'README.md'
        if (-not (Test-Path -LiteralPath $ChangeLogPath -PathType Leaf)) {
            Write-Line "The change log could not be found: $ChangeLogPath" -Type Warning
            return
        }

        [System.String]$ChangeLogText = Get-Content -LiteralPath $ChangeLogPath -Raw -ErrorAction Stop
        [System.Windows.Forms.Form]$ChangeLogForm = New-Object System.Windows.Forms.Form
        $ChangeLogForm.Text = 'Application Delivery Assistant - Change Log'
        $ChangeLogForm.StartPosition = 'CenterParent'
        $ChangeLogForm.Size = New-Object System.Drawing.Size(950,700)
        $ChangeLogForm.MinimumSize = New-Object System.Drawing.Size(600,400)
        $ChangeLogForm.FormBorderStyle = 'Sizable'
        $ChangeLogForm.MinimizeBox = $false
        $ChangeLogForm.MaximizeBox = $true
        $ChangeLogForm.KeyPreview = $true
        if ($null -ne $Global:MainForm -and $null -ne $Global:MainForm.Icon) {
            $ChangeLogForm.Icon = $Global:MainForm.Icon
        }

        [System.Windows.Forms.RichTextBox]$ChangeLogTextBox = New-Object System.Windows.Forms.RichTextBox
        $ChangeLogTextBox.Dock = 'Fill'
        $ChangeLogTextBox.ReadOnly = $true
        $ChangeLogTextBox.WordWrap = $false
        $ChangeLogTextBox.ScrollBars = 'Both'
        $ChangeLogTextBox.DetectUrls = $false
        $ChangeLogTextBox.Font = New-Object System.Drawing.Font('Consolas',10)
        $ChangeLogTextBox.Text = $ChangeLogText
        $ChangeLogTextBox.SelectionStart = 0
        $ChangeLogTextBox.SelectionLength = 0

        [System.Windows.Forms.Panel]$ButtonPanel = New-Object System.Windows.Forms.Panel
        $ButtonPanel.Dock = 'Bottom'
        $ButtonPanel.Height = 42
        [System.Windows.Forms.Button]$CloseButton = New-Object System.Windows.Forms.Button
        $CloseButton.Text = 'Close'
        $CloseButton.Size = New-Object System.Drawing.Size(90,28)
        $CloseButton.Location = New-Object System.Drawing.Point(10,7)
        $CloseButton.Add_Click({ $this.FindForm().Close() })
        $ChangeLogForm.AcceptButton = $CloseButton
        $ChangeLogForm.CancelButton = $CloseButton
        [void]$ButtonPanel.Controls.Add($CloseButton)
        [void]$ChangeLogForm.Controls.Add($ChangeLogTextBox)
        [void]$ChangeLogForm.Controls.Add($ButtonPanel)
        $ChangeLogForm.Add_KeyDown({
            if ($_.KeyCode -eq [System.Windows.Forms.Keys]::Escape) {
                $this.Close()
            }
        })

        if ($null -ne $Global:MainForm) {
            [void]$ChangeLogForm.ShowDialog($Global:MainForm)
        }
        else {
            [void]$ChangeLogForm.ShowDialog()
        }
        $ChangeLogForm.Dispose()
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
    Resets all user settings by recreating the user settings registry key
.DESCRIPTION
    This function deletes the configured user settings registry key and initializes it again
.EXAMPLE
    Invoke-ApplicationMaintenanceResetSettings -InputObject $MyApplicationObject
.INPUTS
    [PSCustomObject]
.OUTPUTS
    No objects are returned to the pipeline
.NOTES
    This script is part of the Application Delivery Assistant Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.1
    Author          : Imraan Iotana
    Creation Date   : July 2026
    Last Update     : July 2026
#>
####################################################################################################
function Invoke-ApplicationMaintenanceResetSettings {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The ApplicationObject containing the Settings.')]
        [PSCustomObject]$InputObject
    )

    try {
        # PREPARATION - INPUT
        # Read the configured user settings registry path
        [System.String]$UserSettingsRegistryPath = [System.String]$InputObject.ApplicationSettings.UserSettingsRegistryPath

        # VALIDATION - REGISTRY PATH
        # Ensure a registry path is configured before attempting reset
        if (Test-String -IsEmpty $UserSettingsRegistryPath) {
            Write-Line 'The User Settings registry path is empty; reset cannot continue.' -Type Warning
            return
        }

        # EXECUTION - RESET SETTINGS KEY
        # Remove the current settings key if it exists so defaults can be recreated
        if (Test-Path -Path $UserSettingsRegistryPath) {
            Remove-Item -Path $UserSettingsRegistryPath -Recurse -Force -ErrorAction Stop
        }

        # POST-EXECUTION
        # Recreate the user settings key structure and report completion
        Initialize-UserSettings -InputObject $InputObject
        Write-Line 'All user settings have been reset to defaults.' -Type Success
        Write-Line 'Please restart the application to apply the updated settings.' -Type Warning

        # POST-EXECUTION
        # Offer restart so the updated settings become visible in the UI
        Restart-ApplicationDeliveryAssistant -InputObject $InputObject
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
    Exports current user settings to a JSON or CLIXML file
.DESCRIPTION
    This function reads all user settings values from the configured registry key and writes them to
    a timestamped backup file JSON is the default; use -Format CliXml for CLIXML export
.EXAMPLE
    Export-ApplicationMaintenanceSettings -InputObject $MyApplicationObject
.EXAMPLE
    Export-ApplicationMaintenanceSettings -InputObject $MyApplicationObject -Format CliXml
.INPUTS
    [PSCustomObject]
.OUTPUTS
    No objects are returned to the pipeline
.NOTES
    This script is part of the Application Delivery Assistant Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.1
    Author          : Imraan Iotana
    Creation Date   : July 2026
    Last Update     : July 2026
#>
####################################################################################################
function Export-ApplicationMaintenanceSettings {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The ApplicationObject containing the Settings.')]
        [PSCustomObject]$InputObject,

        [Parameter(Mandatory=$false,HelpMessage='The export format for the backup file.')]
        [ValidateSet('Json','CliXml')]
        [System.String]$Format = 'Json'
    )

    try {
        # PREPARATION - INPUT
        # Read the configured user settings registry path
        [System.String]$UserSettingsRegistryPath = [System.String]$InputObject.ApplicationSettings.UserSettingsRegistryPath

        # VALIDATION - REGISTRY PATH
        # Ensure the source path exists before exporting
        if (-not (Test-Path -Path $UserSettingsRegistryPath)) {
            Write-Line "User settings path does not exist: ($UserSettingsRegistryPath)" -Type Warning
            return
        }

        # PREPARATION - OUTPUT LOCATION
        # Resolve and create the output folder if needed
        [System.String]$OutputFolder = Get-Folder -OutputFolder
        if (-not (Test-Path -Path $OutputFolder)) {
            New-Item -Path $OutputFolder -ItemType Directory -Force | Out-Null
        }

        # PREPARATION - OUTPUT FILE
        # Build format-specific output metadata and destination file path
        [System.String]$TimeStamp = Get-TimeStamp -ForFileName
        [System.Boolean]$UseCliXml = ($Format -eq 'CliXml')
        [System.String]$ExportFormat = if ($UseCliXml) { 'CLIXML' } else { 'JSON' }
        [System.String]$OutputExtension = if ($UseCliXml) { 'clixml' } else { 'json' }
        [System.String]$OutputFilePath = Join-Path -Path $OutputFolder -ChildPath "ADA_UserSettings_Backup_$TimeStamp.$OutputExtension"

        # EXECUTION - READ SETTINGS
        # Collect note properties from registry into a serializable settings map
        [System.Object]$RegistryProperties = Get-ItemProperty -Path $UserSettingsRegistryPath -ErrorAction Stop
        [System.Collections.Hashtable]$SettingsValues = @{}

        foreach ($Property in $RegistryProperties.PSObject.Properties) {
            if ($Property.MemberType -ne 'NoteProperty') { continue }
            if ($Property.Name -match '^PS(.*)') { continue }
            $SettingsValues[$Property.Name] = [System.String]$Property.Value
        }

        # PREPARATION - EXPORT OBJECT
        # Build a consistent backup object used by both serializers
        [PSCustomObject]$ExportObject = [PSCustomObject]@{
            ExportedAt  = (Get-Date).ToString('s')
            SourcePath  = $UserSettingsRegistryPath
            Format      = $ExportFormat
            Settings    = $SettingsValues
        }

        # EXECUTION - SERIALIZE
        # Write the backup in the requested format
        if ($UseCliXml) {
            $ExportObject | Export-Clixml -Path $OutputFilePath -Encoding UTF8
        }
        else {
            $ExportObject | ConvertTo-Json -Depth 8 | Set-Content -Path $OutputFilePath -Encoding UTF8
        }

        # VALIDATION - EXPORTED FILE
        # Ensure the exported backup file exists and contains data
        [System.IO.FileInfo]$ExportedFile = Get-Item -Path $OutputFilePath -ErrorAction SilentlyContinue
        if ($null -eq $ExportedFile -or $ExportedFile.Length -le 0) {
            Write-Line "The backup export did not produce a valid file: ($OutputFilePath)" -Type Warning
            return
        }

        # VALIDATION - EXPORTED BACKUP CONTENT
        # Validate schema/content with the shared validator
        if (-not (Test-ApplicationMaintenanceBackupObject -SourceFilePath $OutputFilePath -Format $Format -Operation Export)) {
            return
        }

        # POST-EXECUTION
        # Report the generated backup file
        Write-Line "User settings exported to: ($OutputFilePath)" -Type Success

        # POST-EXECUTION - OPEN OUTPUT LOCATION
        # Open the folder location for the exported backup file
        Open-Folder -Path $OutputFilePath
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
    Imports user settings from a JSON or CLIXML backup file
.DESCRIPTION
    This function lets the user choose a backup file and applies each setting value through
    Set-UserSetting The format is automatically detected from the selected file extension
.EXAMPLE
    Import-ApplicationMaintenanceSettings -InputObject $MyApplicationObject
.INPUTS
    [PSCustomObject]
.OUTPUTS
    No objects are returned to the pipeline
.NOTES
    This script is part of the Application Delivery Assistant Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.1
    Author          : Imraan Iotana
    Creation Date   : July 2026
    Last Update     : July 2026
#>
####################################################################################################
function Import-ApplicationMaintenanceSettings {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The ApplicationObject containing the Settings.')]
        [PSCustomObject]$InputObject
    )

    try {
        # PREPARATION - DIALOG
        # Create and configure the file selection dialog for supported backup formats
        [System.Windows.Forms.OpenFileDialog]$FileDialog = [System.Windows.Forms.OpenFileDialog]::new()
        $FileDialog.Filter = 'Supported Backup Files (*.json;*.clixml;*.xml)|*.json;*.clixml;*.xml|JSON Files (*.json)|*.json|CLIXML Files (*.clixml)|*.clixml|XML Files (*.xml)|*.xml|All Files (*.*)|*.*'
        $FileDialog.FilterIndex = 1
        $FileDialog.Multiselect = $false

        # PREPARATION - INITIAL FOLDER
        # Point the dialog to the output folder when it exists
        [System.String]$InitialDirectory = Get-Folder -OutputFolder
        if (Test-Path -Path $InitialDirectory) {
            $FileDialog.InitialDirectory = $InitialDirectory
        }

        # EXECUTION - FILE SELECTION
        # Stop when the user cancels selection
        if ($FileDialog.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) {
            return
        }

        # VALIDATION - SELECTED FILE
        # Ensure the selected path exists before reading
        [System.String]$SelectedFilePath = [System.String]$FileDialog.FileName
        if (-not (Test-Path -Path $SelectedFilePath -PathType Leaf)) {
            Write-Line "Selected file does not exist: ($SelectedFilePath)" -Type Warning
            return
        }

        # PREPARATION - FORMAT
        # Detect backup format from the selected file extension
        [System.String]$SelectedExtension = [System.IO.Path]::GetExtension($SelectedFilePath).ToLowerInvariant()
        [System.String]$DetectedFormat = switch ($SelectedExtension) {
            '.json' { 'Json' }
            '.clixml' { 'CliXml' }
            '.xml' { 'CliXml' }
            default { $null }
        }

        if (Test-String -IsEmpty $DetectedFormat) {
            Write-Line "Unsupported import file extension: ($SelectedExtension)" -Type Warning
            return
        }

        # VALIDATION - BACKUP CONTENT
        # Validate selected backup before deserialization and confirmation
        if (-not (Test-ApplicationMaintenanceBackupObject -SourceFilePath $SelectedFilePath -Format $DetectedFormat -Operation Import)) {
            return
        }

        # EXECUTION - DESERIALIZE
        # Read the selected backup using the matching parser
        [System.Object]$ImportedObject = if ($DetectedFormat -eq 'CliXml') {
            Import-Clixml -Path $SelectedFilePath -ErrorAction Stop
        }
        else {
            [System.String]$RawJson = Get-Content -Path $SelectedFilePath -Raw -ErrorAction Stop
            $RawJson | ConvertFrom-Json -ErrorAction Stop
        }

        # PREPARATION - SETTINGS PAYLOAD
        # Prefer nested Settings payload and fall back to root object
        [System.Object]$SettingsToImport = if ($null -ne $ImportedObject.PSObject.Properties['Settings']) {
            $ImportedObject.Settings
        }
        else {
            $ImportedObject
        }


        # VALIDATION - USER CONFIRMATION
        # Confirm with the user before applying imported settings
        [System.String]$ConfirmationTitle = 'Confirm User Settings Import'
        [System.String]$ConfirmationBody = "Validation successful`n`nThis will overwrite your current user settings with values from:`n`n$SelectedFilePath`n`nDo you want to continue?"
        if (-not (Get-UserConfirmation -Title $ConfirmationTitle -Body $ConfirmationBody)) {
            return
        }

        # EXECUTION - APPLY SETTINGS
        # Apply imported settings through shared import helper
        Invoke-ApplicationMaintenanceImportSettings -InputObject $InputObject -SettingsToImport $SettingsToImport -SourceFilePath $SelectedFilePath
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
    finally {
        if ($null -ne $FileDialog) { $FileDialog.Dispose() }
    }
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Validates a user settings backup object before import
.DESCRIPTION
    This helper validates backup file metadata and settings payload structure so import can fail fast
    with clear diagnostics
.EXAMPLE
    Test-ApplicationMaintenanceBackupObject -SourceFilePath 'C:\Temp\Settings.json' -Format Json -Operation Import
.INPUTS
    [System.String]
    [System.String]
.OUTPUTS
    [System.Boolean]
.NOTES
    This script is part of the Application Delivery Assistant Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.1
    Author          : Imraan Iotana
    Creation Date   : July 2026
    Last Update     : July 2026
#>
####################################################################################################
function Test-ApplicationMaintenanceBackupObject {
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The full path to the selected backup file.')]
        [System.String]$SourceFilePath,

        [Parameter(Mandatory=$true,HelpMessage='Expected import format for validation.')]
        [ValidateSet('Json','CliXml')]
        [System.String]$Format,

        [Parameter(Mandatory=$false,HelpMessage='The operation context for user-facing validation messages.')]
        [ValidateSet('Import','Export')]
        [System.String]$Operation = 'Import'
    )

    try {
        # PREPARATION - RESULT OBJECT
        # Initialize validation result container
        [System.Collections.Generic.List[System.String]]$Errors = New-Object 'System.Collections.Generic.List[System.String]'
        [System.Collections.Generic.List[System.String]]$Warnings = New-Object 'System.Collections.Generic.List[System.String]'
        [System.Int32]$SettingsCount = 0
        [System.Object]$ImportedObject = $null
        [System.Object]$SettingsToImport = $null

        # VALIDATION - FILE
        # Validate file existence, extension, and size
        if (-not (Test-Path -Path $SourceFilePath -PathType Leaf)) {
            [void]$Errors.Add("The backup file does not exist: ($SourceFilePath)")
        }
        else {
            [System.String]$Extension = [System.IO.Path]::GetExtension($SourceFilePath)
            if ($Format -eq 'Json' -and $Extension -ne '.json') {
                [void]$Errors.Add("Expected a .json file for Json import but got: ($Extension)")
            }
            if ($Format -eq 'CliXml' -and @('.clixml','.xml') -notcontains $Extension) {
                [void]$Errors.Add("Expected a .clixml or .xml file for CliXml import but got: ($Extension)")
            }

            [System.IO.FileInfo]$FileInfo = Get-Item -Path $SourceFilePath -ErrorAction SilentlyContinue
            if ($null -eq $FileInfo -or $FileInfo.Length -le 0) {
                [void]$Errors.Add('The backup file is empty')
            }
        }

        # EXECUTION - DESERIALIZE
        # Parse the backup file using the selected format
        if ($Errors.Count -eq 0) {
            try {
                $ImportedObject = if ($Format -eq 'CliXml') {
                    Import-Clixml -Path $SourceFilePath -ErrorAction Stop
                }
                else {
                    [System.String]$RawContent = Get-Content -Path $SourceFilePath -Raw -ErrorAction Stop
                    $RawContent | ConvertFrom-Json -ErrorAction Stop
                }
            }
            catch {
                [void]$Errors.Add("The backup file could not be parsed as format ($Format)")
            }
        }

        # VALIDATION - OBJECTS
        # Ensure imported and settings objects are present
        if ($null -eq $ImportedObject) {
            [void]$Errors.Add('The backup object could not be parsed')
        }
        else {
            $SettingsToImport = if ($null -ne $ImportedObject.PSObject.Properties['Settings']) {
                $ImportedObject.Settings
            }
            else {
                $ImportedObject
            }

            if ($null -eq $SettingsToImport) {
                [void]$Errors.Add('The backup does not contain a settings payload')
            }
        }

        # VALIDATION - FORMAT METADATA
        # Warn if metadata format is present and differs from selected import format
        if ($null -ne $ImportedObject -and $null -ne $ImportedObject.PSObject.Properties['Format']) {
            [System.String]$MetadataFormat = [System.String]$ImportedObject.Format
            if (Test-String -IsPopulated $MetadataFormat) {
                [System.String]$ExpectedMetadataFormat = if ($Format -eq 'CliXml') { 'CLIXML' } else { 'JSON' }
                if ($MetadataFormat.ToUpperInvariant() -ne $ExpectedMetadataFormat) {
                    [void]$Warnings.Add("Backup metadata format is ($MetadataFormat) while selected import format is ($ExpectedMetadataFormat)")
                }
            }
        }

        # VALIDATION - SETTINGS ENTRIES
        # Validate key/value entry shape and count
        if ($null -ne $SettingsToImport) {
            if ($SettingsToImport -is [System.Collections.IDictionary]) {
                foreach ($Entry in $SettingsToImport.GetEnumerator()) {
                    $SettingsCount++
                    if (Test-String -IsEmpty ([System.String]$Entry.Key)) {
                        [void]$Errors.Add('The backup contains an empty setting key')
                    }
                    if ($null -eq $Entry.Value) {
                        [void]$Warnings.Add("The setting key ($([System.String]$Entry.Key)) has a null value")
                    }
                }
            }
            else {
                [System.Management.Automation.PSPropertyInfo[]]$SettingProperties = @(
                    $SettingsToImport.PSObject.Properties | Where-Object { $_.MemberType -eq 'NoteProperty' }
                )
                foreach ($Property in $SettingProperties) {
                    $SettingsCount++
                    if (Test-String -IsEmpty ([System.String]$Property.Name)) {
                        [void]$Errors.Add('The backup contains an empty setting key')
                    }
                    if ($null -eq $Property.Value) {
                        [void]$Warnings.Add("The setting key ($([System.String]$Property.Name)) has a null value")
                    }
                }
            }
        }

        if ($SettingsCount -le 0) {
            [void]$Errors.Add('The backup contains zero settings entries')
        }

        # OUTPUT
        # Write validation feedback and return boolean state
        if ($Errors.Count -gt 0) {
            Write-Line "The selected backup file is not valid for ($Operation)" -Type Warning
            foreach ($ValidationError in $Errors) {
                Write-Line $ValidationError -Type Warning
            }
            return $false
        }

        foreach ($ValidationWarning in $Warnings) {
            Write-Line $ValidationWarning -Type Warning
        }

        Write-Line "Backup validation successful. ($SettingsCount) setting(s) are ready for ($Operation)" -Type Success
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
    Applies imported user settings to the current user settings registry
.DESCRIPTION
    This helper accepts either a dictionary or a PSCustomObject and writes each property value using
    Set-UserSetting
.EXAMPLE
    Invoke-ApplicationMaintenanceImportSettings -InputObject $MyApplicationObject -SettingsToImport $SettingsObject -SourceFilePath 'C:\Temp\Settings.json'
.INPUTS
    [PSCustomObject]
    [System.Object]
    [System.String]
.OUTPUTS
    No objects are returned to the pipeline
.NOTES
    This script is part of the Application Delivery Assistant Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.1
    Author          : Imraan Iotana
    Creation Date   : July 2026
    Last Update     : July 2026
#>
####################################################################################################
function Invoke-ApplicationMaintenanceImportSettings {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The ApplicationObject containing the Settings.')]
        [PSCustomObject]$InputObject,

        [Parameter(Mandatory=$true,HelpMessage='The settings object to apply.')]
        [System.Object]$SettingsToImport,

        [Parameter(Mandatory=$false,HelpMessage='The source file path for logging.')]
        [System.String]$SourceFilePath
    )

    try {
        # VALIDATION - SETTINGS PAYLOAD
        # Stop when the import payload is empty
        if ($null -eq $SettingsToImport) {
            Write-Line 'The import payload is empty and cannot be applied.' -Type Warning
            return
        }

        # Track how many setting entries are written
        [System.Int32]$ImportedCount = 0

        # EXECUTION - APPLY SETTINGS
        # Support dictionary and object payload styles
        if ($SettingsToImport -is [System.Collections.IDictionary]) {
            foreach ($Entry in $SettingsToImport.GetEnumerator()) {
                Set-UserSetting -InputObject $InputObject -PropertyName ([System.String]$Entry.Key) -PropertyValue ([System.String]$Entry.Value)
                $ImportedCount++
            }
        }
        else {
            foreach ($Property in $SettingsToImport.PSObject.Properties) {
                Set-UserSetting -InputObject $InputObject -PropertyName $Property.Name -PropertyValue ([System.String]$Property.Value)
                $ImportedCount++
            }
        }

        # POST-EXECUTION
        # Report how many settings were imported and from which file
        if (Test-String -IsPopulated $SourceFilePath) {
            Write-Line "Imported ($ImportedCount) user setting(s) from: ($SourceFilePath)" -Type Success
        }
        else {
            Write-Line "Imported ($ImportedCount) user setting(s)." -Type Success
        }
        Write-Line 'Please restart the application to apply the updated settings.' -Type Warning

        # POST-EXECUTION
        # Offer restart so the imported settings become visible in the UI
        Restart-ApplicationDeliveryAssistant -InputObject $InputObject
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}

### END OF FUNCTION
####################################################################################################
