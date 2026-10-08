####################################################################################################
<#
.SYNOPSIS
    Imports the UDF tab into the main application.
.DESCRIPTION
    This function imports the UDF tab into the main application by creating a new TabPage and adding it to the specified parent TabControl.
.EXAMPLE
    Import-TabUDF -InputObject $MyApplicationObject -ParentTabControl $Global:MainTabControl
.INPUTS
    [PSCustomObject]
    [System.Windows.Forms.TabControl]
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.4.0
    Author          : Imraan Iotana
    Creation Date   : August 2026
    Last Update     : August 2026
#>
####################################################################################################
function Import-TabUDF {
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
            Title               = 'UDF'
            Version             = '6.4.0'
            BackGroundColor     = '#2F6F6D'
        }
        # Set the main color for the GroupBoxes in this tab
        [System.String]$MainColor = '#E6F4F1'

        # EXECUTION - TAB
        # Create the TabPage
        [System.Windows.Forms.TabPage]$ParentTabPage = New-TabPage @TabProperties

        # EXECUTION - FEATURES
        # Import the UDF feature groupboxes in the same order as the other tab/sub-tab patterns.
        $UDFImportFeatureGroupBox         = Import-FeatureUDFImport -InputObject $InputObject -ParentTabPage $ParentTabPage -Color $MainColor
        $DeploymentObjectsFeatureGroupBox = Import-FeatureUDFDeploymentObjects -InputObject $InputObject -ParentTabPage $ParentTabPage -GroupBoxAbove $UDFImportFeatureGroupBox -Color $MainColor
        $PropertyEditorFeatureGroupBox    = Import-FeatureUDFDeploymentObjectEditor -InputObject $InputObject -ParentTabPage $ParentTabPage -GroupBoxAbove $DeploymentObjectsFeatureGroupBox -Color $MainColor -SourceListView $DeploymentObjectsFeatureGroupBox.SourceListView -MainPropertiesListView $UDFImportFeatureGroupBox.MainPropertiesListView -DeploymentDataTextBox $UDFImportFeatureGroupBox.DeploymentDataTextBox

        # POST-EXECUTION - FEATURE WIRING
        # Wire the features together after all of them have been created.
        Initialize-UDFTabFeatures -InputObject $InputObject -UDFImportFeatureGroupBox $UDFImportFeatureGroupBox -DeploymentObjectsFeatureGroupBox $DeploymentObjectsFeatureGroupBox -PropertyEditorFeatureGroupBox $PropertyEditorFeatureGroupBox
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
    Initializes the feature wiring for the UDF tab.
.DESCRIPTION
    This function wires the UDF import, deployment objects, and property editor groupboxes together after they have been created.
.EXAMPLE
    Initialize-UDFTabFeatures -InputObject $MyApplicationObject -UDFImportFeatureGroupBox $UDFImportFeatureGroupBox -DeploymentObjectsFeatureGroupBox $DeploymentObjectsFeatureGroupBox -PropertyEditorFeatureGroupBox $PropertyEditorFeatureGroupBox
.INPUTS
    [PSCustomObject]
    [System.Windows.Forms.GroupBox]
    [System.Windows.Forms.GroupBox]
    [System.Windows.Forms.GroupBox]
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.3.4
    Author          : Imraan Iotana
    Creation Date   : August 2026
    Last Update     : August 2026
#>
####################################################################################################
function Initialize-UDFTabFeatures {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The ApplicationObject containing the Settings.')]
        [PSCustomObject]$InputObject,

        [Parameter(Mandatory=$true,HelpMessage='The UDF import feature groupbox.')]
        [System.Windows.Forms.GroupBox]$UDFImportFeatureGroupBox,

        [Parameter(Mandatory=$true,HelpMessage='The UDF deployment objects feature groupbox.')]
        [System.Windows.Forms.GroupBox]$DeploymentObjectsFeatureGroupBox,

        [Parameter(Mandatory=$true,HelpMessage='The UDF property editor feature groupbox.')]
        [System.Windows.Forms.GroupBox]$PropertyEditorFeatureGroupBox
    )

    try {
        # PREPARATION - INLINE EDITOR SYNC
        # Keep the UDF inline editors in sync across the list views and feature panels.
        [System.Management.Automation.ScriptBlock]$CompleteMainInlineEditors = {
            [void](Complete-UDFMainPropertyInlineEditors -MainPropertiesListView $UDFImportFeatureGroupBox.MainPropertiesListView)
        }.GetNewClosure()
        [System.Management.Automation.ScriptBlock]$CompleteObjectInlineEditors = {
            [void](Complete-UDFDeploymentObjectInlineEditors -PropertiesListView $PropertyEditorFeatureGroupBox.PropertiesListView)
        }.GetNewClosure()

        # EXECUTION - EVENT HOOKS
        # Wire mouse interactions so pending inline edits are completed before focus changes.
        $UDFImportFeatureGroupBox.MainPropertiesListView.Add_MouseDown({
            param($MouseSource, $MouseData)
            & $CompleteMainInlineEditors
            & $CompleteObjectInlineEditors
        }.GetNewClosure())
        $DeploymentObjectsFeatureGroupBox.SourceListView.Add_MouseDown({
            param($MouseSource, $MouseData)
            & $CompleteMainInlineEditors
            & $CompleteObjectInlineEditors
        }.GetNewClosure())
        $PropertyEditorFeatureGroupBox.PropertiesListView.Add_MouseDown({
            param($MouseSource, $MouseData)
            & $CompleteMainInlineEditors
            & $CompleteObjectInlineEditors
        }.GetNewClosure())
        $UDFImportFeatureGroupBox.Add_MouseDown({
            param($MouseSource, $MouseData)
            & $CompleteMainInlineEditors
            & $CompleteObjectInlineEditors
        }.GetNewClosure())
        $DeploymentObjectsFeatureGroupBox.Add_MouseDown({
            param($MouseSource, $MouseData)
            & $CompleteMainInlineEditors
            & $CompleteObjectInlineEditors
        }.GetNewClosure())
        $PropertyEditorFeatureGroupBox.Add_MouseDown({
            param($MouseSource, $MouseData)
            & $CompleteMainInlineEditors
            & $CompleteObjectInlineEditors
        }.GetNewClosure())

        # Open the inline editor directly when double-clicking the Value cell.
        $UDFImportFeatureGroupBox.MainPropertiesListView.Add_MouseDoubleClick({
            param($DoubleClickSource, $DoubleClickData)
            Start-UDFMainPropertyInlineEditFromListView -SourceListView $DeploymentObjectsFeatureGroupBox.SourceListView -MainPropertiesListView $UDFImportFeatureGroupBox.MainPropertiesListView -MouseEventArgs $DoubleClickData
        }.GetNewClosure())

        # EXECUTION - AUTO-LOAD
        # Keep the deployment data textbox synchronized with the selected PSD1 file.
        [System.String]$LastAutoLoadedPath = ''
        [System.Management.Automation.ScriptBlock]$AutoLoadFromTextBox = {
            if (($null -ne $UDFImportFeatureGroupBox.DeploymentDataTextBox.Tag) -and ($null -ne $UDFImportFeatureGroupBox.DeploymentDataTextBox.Tag.PSObject.Properties['SkipAutoLoadOnce']) -and ([System.Boolean]$UDFImportFeatureGroupBox.DeploymentDataTextBox.Tag.SkipAutoLoadOnce)) {
                $UDFImportFeatureGroupBox.DeploymentDataTextBox.Tag | Add-Member -MemberType NoteProperty -Name SkipAutoLoadOnce -Value $false -Force
                return
            }

            [System.String]$SelectedPath = [System.String]$UDFImportFeatureGroupBox.DeploymentDataTextBox.Text
            if (Test-String -IsEmpty $SelectedPath) { return }
            if (-not $SelectedPath.EndsWith('.psd1', [System.StringComparison]::OrdinalIgnoreCase)) { return }
            if (-not (Test-Path -Path $SelectedPath -PathType Leaf)) { return }
            if ($SelectedPath -eq $LastAutoLoadedPath) { return }

            Import-UDFDeploymentDataToListView -DataFilePath $SelectedPath -ListView $DeploymentObjectsFeatureGroupBox.SourceListView -PropertiesListView $PropertyEditorFeatureGroupBox.PropertiesListView -MainPropertiesListView $UDFImportFeatureGroupBox.MainPropertiesListView
            $LastAutoLoadedPath = $SelectedPath
        }.GetNewClosure()
        $UDFImportFeatureGroupBox.DeploymentDataTextBox.Add_TextChanged($AutoLoadFromTextBox)

        # EXECUTION - ACTION BUTTONS
        # Build the helper buttons that load data or create a new UDF workspace.
        [System.Collections.Hashtable[]]$ActionButtons = @(
            @{
                ColumnNumber    = 1
                Text            = 'Load'
                PNGFileName     = 'download_for_windows'
                SizeType        = 'Medium'
                ToolTip         = 'Load DeploymentObjects from the selected DeploymentData.psd1 file.'
                Function        = {
                    Import-UDFDeploymentDataToListView -DataFilePath $UDFImportFeatureGroupBox.DeploymentDataTextBox.Text -ListView $DeploymentObjectsFeatureGroupBox.SourceListView -PropertiesListView $PropertyEditorFeatureGroupBox.PropertiesListView -MainPropertiesListView $UDFImportFeatureGroupBox.MainPropertiesListView
                }.GetNewClosure()
            },
            @{
                ColumnNumber    = 5
                Text            = 'New...'
                PNGFileName     = 'script_add'
                SizeType        = 'Medium'
                ToolTip         = 'Create a new UDF workspace from the bundled repo zip.'
                Function        = {
                    New-UDFWorkspaceFromBundledZip -DeploymentDataTextBox $UDFImportFeatureGroupBox.DeploymentDataTextBox -InitialDirectory (Get-Folder -OutputFolder)
                }.GetNewClosure()
            }
        )
        New-ButtonLine -InputObject $InputObject -ButtonPropertiesArray $ActionButtons -ParentGroupBox $UDFImportFeatureGroupBox -RowNumber 2

        # POST-EXECUTION - INITIAL VIEW
        # Populate the list view after the controls and handlers have been wired.
        Show-UDFMainPropertiesInListView -SourceListView $DeploymentObjectsFeatureGroupBox.SourceListView -MainPropertiesListView $UDFImportFeatureGroupBox.MainPropertiesListView
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
    Creates a new UDF workspace from the bundled zip.
.DESCRIPTION
    This helper prompts the user for a destination parent folder, extracts the
    bundled UDF zip into a new workspace subfolder, and updates the Deployment
    Data textbox to the extracted DeploymentData.psd1 file.
    The textbox update triggers the existing UDF auto-load behavior.
.EXAMPLE
    New-UDFWorkspaceFromBundledZip -DeploymentDataTextBox $MyTextBox
.INPUTS
    [System.Windows.Forms.TextBox]
    [System.String]
.OUTPUTS
    [System.Boolean]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.3.4
    Author          : Imraan Iotana
    Creation Date   : August 2026
    Last Update     : August 2026
#>
####################################################################################################
function New-UDFWorkspaceFromBundledZip {
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param (
        [Parameter(Mandatory=$false,HelpMessage='Optional textbox to receive the extracted DeploymentData.psd1 path.')]
        [System.Windows.Forms.TextBox]$DeploymentDataTextBox,

        [Parameter(Mandatory=$false,HelpMessage='Optional initial directory for the destination folder picker.')]
        [AllowEmptyString()]
        [System.String]$InitialDirectory
    )

    [System.Windows.Forms.FolderBrowserDialog]$FolderDialog = $null
    try {
        # PREPARATION - ZIP SOURCE PATH
        # Resolve the bundled UDF zip path from common roots.
        [System.String]$BundledZipPath = ''
        [System.String[]]$CandidateZipPaths = @(
            [System.String](Join-Path -Path $Global:ApplicationObject.RootFolder -ChildPath 'Assets\UDF\UniversalDeploymentFramework.zip'),
            [System.String]([System.IO.Path]::GetFullPath((Join-Path -Path $PSScriptRoot -ChildPath '..\..\Assets\UDF\UniversalDeploymentFramework.zip')))
        )

        foreach ($CandidatePath in $CandidateZipPaths) {
            if ((Test-String -IsPopulated $CandidatePath) -and (Test-Path -LiteralPath $CandidatePath -PathType Leaf)) {
                $BundledZipPath = $CandidatePath
                break
            }
        }

        # VALIDATION - ZIP SOURCE
        # Stop early when no bundled zip is available.
        if (Test-String -IsEmpty $BundledZipPath) {
            Write-Line 'Could not find the bundled UDF zip (Assets\UDF\UniversalDeploymentFramework.zip).' -Type Warning
            return $false
        }

        # PREPARATION - DESTINATION PICKER
        # Ask the user where the new UDF workspace should be created.
        [System.String]$ResolvedInitialDirectory = [System.String]$InitialDirectory
        if (Test-String -IsEmpty $ResolvedInitialDirectory) {
            $ResolvedInitialDirectory = [System.String](Get-Folder -OutputFolder)
        }
        if ((Test-String -IsEmpty $ResolvedInitialDirectory) -or (-not (Test-Path -LiteralPath $ResolvedInitialDirectory -PathType Container))) {
            $ResolvedInitialDirectory = $ENV:SystemDrive
        }

        $FolderDialog = [System.Windows.Forms.FolderBrowserDialog]::new()
        $FolderDialog.Description = 'Select the parent folder for the new UDF workspace'
        $FolderDialog.SelectedPath = $ResolvedInitialDirectory
        $FolderDialog.ShowNewFolderButton = $true

        if ($FolderDialog.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) {
            return $false
        }

        [System.String]$DestinationParentFolder = [System.String]$FolderDialog.SelectedPath
        if ((Test-String -IsEmpty $DestinationParentFolder) -or (-not (Test-Path -LiteralPath $DestinationParentFolder -PathType Container))) {
            Write-Line 'The selected destination folder is invalid.' -Type Warning
            return $false
        }

        # PREPARATION - TARGET FOLDER
        # Create one timestamped folder so separate workspaces remain isolated.
        [System.String]$WorkspaceFolderName = ('UniversalDeploymentFramework_Workspace_{0}' -f (Get-Date -Format 'yyyyMMdd_HHmmss'))
        [System.String]$DestinationFolder = Join-Path -Path $DestinationParentFolder -ChildPath $WorkspaceFolderName

        # EXECUTION - EXTRACT ZIP
        # Extract the bundled zip to the new workspace folder.
        New-Item -Path $DestinationFolder -ItemType Directory -Force | Out-Null
        Expand-Archive -LiteralPath $BundledZipPath -DestinationPath $DestinationFolder -Force

        # Normalize one nested top-level zip folder when present.
        [System.String]$ArchiveFolderName = [System.IO.Path]::GetFileNameWithoutExtension($BundledZipPath)
        [System.String]$NestedArchiveFolderPath = Join-Path -Path $DestinationFolder -ChildPath $ArchiveFolderName
        if (Test-Path -LiteralPath $NestedArchiveFolderPath -PathType Container) {
            Get-ChildItem -LiteralPath $NestedArchiveFolderPath -Force | ForEach-Object {
                Move-Item -LiteralPath $_.FullName -Destination $DestinationFolder -Force
            }
            Remove-Item -LiteralPath $NestedArchiveFolderPath -Recurse -Force -ErrorAction SilentlyContinue
        }

        # POST-EXECUTION - TEXTBOX SYNC
        # Point the UDF textbox to the extracted DeploymentData.psd1 when available.
        [System.String]$ExtractedDeploymentDataPath = Join-Path -Path $DestinationFolder -ChildPath 'DeploymentData.psd1'
        if (($null -ne $DeploymentDataTextBox) -and (Test-Path -LiteralPath $ExtractedDeploymentDataPath -PathType Leaf)) {
            $DeploymentDataTextBox.Text = $ExtractedDeploymentDataPath
        }

        # OUTPUT - USER FEEDBACK
        # Report source and target. The textbox sync above keeps the user in-tab and loads the file.
        Write-Line "Created new UDF workspace from zip: $BundledZipPath" -Type Success
        Write-Line "Workspace folder: $DestinationFolder" -Type Info
        Write-Line "Loaded DeploymentData file: $ExtractedDeploymentDataPath" -Type Info
        return $true
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
        return $false
    }
    finally {
        if ($null -ne $FolderDialog) {
            $FolderDialog.Dispose()
        }
    }
}

### END OF FUNCTION
####################################################################################################


