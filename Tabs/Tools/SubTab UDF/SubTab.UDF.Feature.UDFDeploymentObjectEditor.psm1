####################################################################################################
<#
.SYNOPSIS
    Imports the Deployment Object Properties editor feature into the UDF tab.
.DESCRIPTION
    This function creates a dedicated GroupBox for the selected DeploymentObject properties,
    property value editing, and save actions.
.EXAMPLE
    Import-FeatureUDFDeploymentObjectEditor -InputObject $MyApplicationObject -ParentTabPage $MyTabPage -SourceListView $MyListView -DeploymentDataTextBox $MyTextBox
.INPUTS
    [PSCustomObject]
    [System.Windows.Forms.TabPage]
    [System.Windows.Forms.GroupBox]
    [System.String]
    [System.Windows.Forms.ListView]
    [System.Windows.Forms.TextBox]
.OUTPUTS
    [PSCustomObject]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.4
    Author          : Imraan Iotana
    Creation Date   : August 2026
    Last Update     : August 2026
#>
####################################################################################################
function Import-FeatureUDFDeploymentObjectEditor {
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
        [System.String]$Color,

        [Parameter(Mandatory=$true,HelpMessage='The Deployment Objects ListView that drives the selected object context.')]
        [System.Windows.Forms.ListView]$SourceListView,

        [Parameter(Mandatory=$false,HelpMessage='The Main Properties ListView used to snapshot pending main-property edits before save.')]
        [System.Windows.Forms.ListView]$MainPropertiesListView,

        [Parameter(Mandatory=$true,HelpMessage='The Deployment Data file TextBox used for Save As operations.')]
        [System.Windows.Forms.TextBox]$DeploymentDataTextBox
    )

    try {
        # PREPARATION - GROUPBOX PROPERTIES
        # Create a dedicated editor group for selected object properties.
        [System.Collections.Hashtable]$GroupBoxProperties = @{
            InputObject     = $InputObject
            ParentTabPage   = $ParentTabPage
            Title           = 'DEPLOYMENT OBJECT PROPERTIES'
            Color           = $Color
            NumberOfRows    = 6
            GroupBoxAbove   = $GroupBoxAbove
        }

        # EXECUTION - GROUPBOX
        # Create the GroupBox.
        [System.Windows.Forms.GroupBox]$FeatureGroupBox = New-GroupBox @GroupBoxProperties

        # PREPARATION - UDF LISTVIEW COLOR THEME
        # Resolve shared ListView theme overrides from application settings.
        [System.Collections.Hashtable]$ThemeOverrides = Get-ListViewThemeOverridesFromInputObject -InputObject $InputObject
        [System.String]$ReadOnlyBackColor = [System.String]$ThemeOverrides.ReadOnlyBackColor
        [System.String]$ReadOnlyTextColor = [System.String]$ThemeOverrides.ReadOnlyTextColor

        # PREPARATION - LISTVIEW PROPERTIES
        # Create the properties list for the currently selected deployment object.
        [System.Collections.Hashtable]$DeploymentObjectPropertiesListViewProperties = @{
            RowNumber           = 1
            VisibleRowCount     = 6
            Label               = 'Properties'
            SizeType            = 'Large'
            View                = 'Details'
            Columns             = @('Property','Value','Info')
            ColumnAutoSizeMode  = 'Widest'
            ToolTip             = 'Shows properties of the selected deployment object. Double-click the Value cell to edit; the Info column is driven by _Catalog metadata when available.'
            GridLines           = $true
            FullRowSelect       = $true
            BackColor           = $ReadOnlyBackColor
            TextColor           = $ReadOnlyTextColor
            ThemeOverrides      = $ThemeOverrides
        }

        # EXECUTION - LISTVIEW
        # Add the properties list view to the editor GroupBox.
        [System.Windows.Forms.ListView]$DeploymentObjectPropertiesListView = New-ListView @DeploymentObjectPropertiesListViewProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ReturnListView

        # EXECUTION - LISTVIEW EVENTS
        # Keep the properties panel synchronized with object selection.
        $SourceListView.Add_SelectedIndexChanged({
            Show-UDFDeploymentObjectPropertiesInListView -SourceListView $SourceListView -PropertiesListView $DeploymentObjectPropertiesListView
        }.GetNewClosure())

        # Open inline editor directly when double-clicking the Value cell.
        $DeploymentObjectPropertiesListView.Add_MouseDoubleClick({
            param($DoubleClickTarget, $DoubleClickEventData)
            Start-UDFDeploymentObjectInlineEditFromListView -SourceListView $SourceListView -PropertiesListView $DeploymentObjectPropertiesListView -MouseEventArgs $DoubleClickEventData
        }.GetNewClosure())

        # EXECUTION - BUTTONS
        # Add undo and save actions in this dedicated editor feature.
        [System.Collections.Hashtable[]]$PropertyValueButtons = @(
            @{
                ColumnNumber    = 1
                Text            = 'Undo All'
                PNGFileName     = 'arrow_undo'
                SizeType        = 'Medium'
                ToolTip         = 'Reload the current DeploymentData.psd1 file and discard pending editor changes.'
                Function        = {
                    [void](Undo-UDFDeploymentObjectChanges -SourceListView $SourceListView -PropertiesListView $DeploymentObjectPropertiesListView -MainPropertiesListView $MainPropertiesListView -DeploymentDataTextBox $DeploymentDataTextBox)
                }.GetNewClosure()
            }
            @{
                ColumnNumber    = 5
                Text            = 'Save to File'
                PNGFileName     = 'disk'
                SizeType        = 'Medium'
                ToolTip         = 'Choose a destination path for DeploymentData.psd1.'
                Function        = {
                    [void](Complete-UDFDeploymentObjectInlineEditors -PropertiesListView $DeploymentObjectPropertiesListView)
                    [void](Complete-UDFMainPropertyInlineEditors -MainPropertiesListView $MainPropertiesListView)

                    [System.String]$TemplateFilePath = $DeploymentDataTextBox.Text
                    if ($null -eq $DeploymentDataTextBox.Tag) {
                        $DeploymentDataTextBox.Tag = [PSCustomObject]@{}
                    }
                    $DeploymentDataTextBox.Tag | Add-Member -MemberType NoteProperty -Name SkipAutoLoadOnce -Value $true -Force
                    [System.String]$SavePath = Save-File -TextBox $DeploymentDataTextBox -Type PowerShellData -DefaultFileName 'DeploymentData.psd1'
                    if (Test-String -IsPopulated $SavePath) {
                        [void](Save-UDFDeploymentDataToFile -TemplateFilePath $TemplateFilePath -DataFilePath $SavePath -SourceListView $SourceListView)
                    }
                }.GetNewClosure()
            }
        )
        New-ButtonLine -InputObject $InputObject -ButtonPropertiesArray $PropertyValueButtons -ParentGroupBox $FeatureGroupBox -RowNumber 7

        # POST-EXECUTION
        # Initialize editor state and return created UI controls.
        Show-UDFDeploymentObjectPropertiesInListView -SourceListView $SourceListView -PropertiesListView $DeploymentObjectPropertiesListView

        $FeatureGroupBox | Add-Member -NotePropertyName 'PropertiesListView' -NotePropertyValue $DeploymentObjectPropertiesListView -Force

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
    Reloads the current deployment data file to undo pending editor changes.
.DESCRIPTION
    This helper re-imports the file referenced by the deployment data textbox so the lists are reset
    from disk instead of trying to reverse the edits in memory.
.EXAMPLE
    Undo-UDFDeploymentObjectChanges -SourceListView $MySourceListView -PropertiesListView $MyPropertiesListView -MainPropertiesListView $MyMainPropertiesListView -DeploymentDataTextBox $MyTextBox
.INPUTS
    [System.Windows.Forms.ListView]
    [System.Windows.Forms.ListView]
    [System.Windows.Forms.ListView]
    [System.Windows.Forms.TextBox]
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.4
    Author          : Imraan Iotana
    Creation Date   : August 2026
    Last Update     : August 2026
#>
####################################################################################################
function Undo-UDFDeploymentObjectChanges {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The Deployment Objects ListView that drives the selected object context.')]
        [System.Windows.Forms.ListView]$SourceListView,

        [Parameter(Mandatory=$true,HelpMessage='The Deployment Object Properties ListView used by inline editors.')]
        [System.Windows.Forms.ListView]$PropertiesListView,

        [Parameter(Mandatory=$false,HelpMessage='The Main Properties ListView used to snapshot pending main-property edits before save.')]
        [System.Windows.Forms.ListView]$MainPropertiesListView,

        [Parameter(Mandatory=$true,HelpMessage='The Deployment Data file TextBox used for reload operations.')]
        [System.Windows.Forms.TextBox]$DeploymentDataTextBox
    )

    try {
        # PREPARATION - RELOAD FILE
        # Re-import the selected psd1 file and let the loader refresh the UI.
        [System.String]$CurrentDataFilePath = [System.String]$DeploymentDataTextBox.Text
        if (Test-String -IsEmpty $CurrentDataFilePath) {
            Write-Line 'Choose a DeploymentData.psd1 file before undoing changes.' -Type Warning
            return
        }

        Import-UDFDeploymentDataToListView -DataFilePath $CurrentDataFilePath -ListView $SourceListView -PropertiesListView $PropertiesListView -MainPropertiesListView $MainPropertiesListView
        Write-Line 'All changes have been undone.'
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}

### END OF FUNCTION
####################################################################################################
