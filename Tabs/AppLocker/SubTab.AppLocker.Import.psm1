####################################################################################################
<#
.SYNOPSIS
    Imports the Import sub-tab into the AppLocker section.
.DESCRIPTION
    This function imports the Import sub-tab into the AppLocker section by creating a new TabPage and adding it to the specified parent TabControl.
.EXAMPLE
    Import-SubTabAppLockerImport -InputObject $InputObject -ParentTabControl $MySubTabControl
.INPUTS
    [PSCustomObject]
    [System.Windows.Forms.TabControl]
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.2
    Author          : Imraan Iotana
    Creation Date   : August 2025
    Last Update     : July 2026
#>
####################################################################################################
function Import-SubTabAppLockerImport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The ApplicationObject containing the Settings.')]
        [PSCustomObject]$InputObject,

        [Parameter(Mandatory=$true,HelpMessage='The Parent TabControl to which this TabPage will be added.')]
        [System.Windows.Forms.TabControl]$ParentTabControl
    )

    try {
        # PREPARATION
        # Tab properties
        [System.Collections.Hashtable]$TabProperties = @{
            ParentTabControl    = $ParentTabControl
            Title               = 'APPLOCKER IMPORT'
            Version             = '6.0.0.2'
            BackGroundColor     = 'SteelBlue'
        }
        # Set the main color for the GroupBoxes in this sub-tab
        [System.String]$MainColor = 'Cyan'

        # EXECUTION
        # Create the TabPage
        [System.Windows.Forms.TabPage]$ParentTabPage = New-TabPage @TabProperties

        # Import the Feature
        $null = Import-FeatureAppLockerImport -InputObject $InputObject -ParentTabPage $ParentTabPage -Color $MainColor

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
    Imports the AppLocker Import feature into the AppLocker section.
.DESCRIPTION
    This function imports the AppLocker Import feature into the AppLocker section by creating a new GroupBox and adding it to the specified parent TabPage.
.EXAMPLE
    Import-FeatureAppLockerImport -InputObject $MyApplicationObject -ParentTabPage $MyTabPage
.INPUTS
    [PSCustomObject]
    [System.Windows.Forms.TabPage]
    [System.Windows.Forms.GroupBox]
    [System.String]
.OUTPUTS
    [System.Windows.Forms.GroupBox]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.2
    Author          : Imraan Iotana
    Creation Date   : May 2026
    Last Update     : July 2026
#>
####################################################################################################
function Import-FeatureAppLockerImport {
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
        # EXECUTION - GROUPBOX
        # Feature properties
        [System.Collections.Hashtable]$GroupBoxProperties = @{
            InputObject     = $InputObject
            ParentTabPage   = $ParentTabPage
            Title           = 'APPLICATION IMPORT'
            Color           = $Color
            NumberOfRows    = 6
            GroupBoxAbove   = $GroupBoxAbove
        }
        # Create the GroupBox
        [System.Windows.Forms.GroupBox]$FeatureGroupBox = New-GroupBox @GroupBoxProperties

        # EXECUTION - TEXTBOXES
        # Set the AppLockerFile TextBox properties
        [System.Collections.Hashtable]$AppLockerFileTextBoxProperties = @{
            RowNumber       = 2
            Label           = '...select File'
            ToolTip         = 'The AppLocker file to import.'
            SizeType        = 'Medium'
            SmallButtons    = @(@(6,'Paste'),@(7,'Open'))
        }
        # Create the TextBoxes
        [System.Windows.Forms.TextBox]$AppLockerFileTextBox = New-TextBox @AppLockerFileTextBoxProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ReturnTextBox

        # EXECUTION - COMBOBOXES
        # Set the ApplicationIDComboBox properties
        [System.Collections.Hashtable]$ApplicationIDComboBoxProperties = @{
            RowNumber           = 1
            Label               = 'Select Application ID or...'
            ToolTip             = 'The Application ID for the AppLocker policies.'
            SizeType            = 'Medium'
            ContentStringArray  = Get-DSLDirectSubFolderNames
            SmallButtons        = @(@(5,'Copy'),@(6,'Paste'),@(7,'Clear'))
        }
        # Keep this list aligned with Import-FeatureAppLockerSettings and AppLockerDefaultSettings
        [System.String[]]$AppLockerEnvironments = @('Development','Test','Acceptance','Production')
        # Set the ApplockerEnvironmentComboBox properties
        [System.Collections.Hashtable]$ApplockerEnvironmentComboBoxProperties = @{
            RowNumber           = 3
            Label               = 'Environment'
            ToolTip             = 'The environment for the AppLocker policies.'
            DefaultValue        = 'Development'
            SizeType            = 'Medium'
            ContentStringArray  = $AppLockerEnvironments
        }
        # Create the ComboBoxes
        $null = New-ComboBox @ApplicationIDComboBoxProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ReturnComboBox
        [System.Windows.Forms.ComboBox]$ApplockerEnvironmentComboBox = New-ComboBox @ApplockerEnvironmentComboBoxProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ReturnComboBox

        # Link the environment selector to the AppLocker Settings textboxes so the host can show the active target
        if ($ApplockerEnvironmentComboBox) {
            [System.Collections.Hashtable]$AppLockerEnvironmentToTextBoxName = @{
                Development = 'AppLockerDEVURL'
                Test        = 'AppLockerTSTURL'
                Acceptance  = 'AppLockerACCURL'
                Production  = 'AppLockerPRDURL'
            }
            $ApplockerEnvironmentComboBox.Tag | Add-Member -MemberType NoteProperty -Name LinkedTextBoxNameMap -Value $AppLockerEnvironmentToTextBoxName -Force
            $ApplockerEnvironmentComboBox.Add_SelectedIndexChanged({
                param($ChangedControl, $ChangedEvent)
                Write-SelectedAppLockerEnvironmentToHost -EnvironmentComboBox $ChangedControl
            }.GetNewClosure())
        }

        # EXECUTION - BUTTONS
        # Set the AppLockerFileTextBox Browse button properties
        [System.Collections.Hashtable]$AppLockerFileTextBoxButtonProperties = @{
            ColumnNumber    = 5
            Text            = 'Browse File'
            PNGFileName     = 'magnifier'
            SizeType        = 'Small'
            ToolTip         = 'Browse for an AppLocker file to import.'
            Function        = { Select-File -TextBox $AppLockerFileTextBox -Type 'AppLocker' }.GetNewClosure()
        }
        # Set the EnvironmentComboBox Details button properties
        [System.Collections.Hashtable]$EnvironmentComboBoxButtonProperties = @{
            ColumnNumber    = 5
            Text            = 'Details'
            PNGFileName     = 'information'
            SizeType        = 'Small'
            ToolTip         = 'Show details for the selected AppLocker environment and LDAP value.'
            Function        = { Write-SelectedAppLockerEnvironmentToHost -EnvironmentComboBox $ApplockerEnvironmentComboBox }.GetNewClosure()
        }
        # Set the Action Buttons
        [System.Collections.Hashtable[]]$ActionButtonsPropertiesArray = @(
            @{
                ColumnNumber    = 1
                Text            = 'Check AppLocker'
                PNGFileName     = 'shield'
                SizeType        = 'Large'
                ToolTip         = 'Check if the AppLocker Policies are implemented.'
                Function        = {
                    # Placeholder
                    Write-Line "[INFO] Check AppLocker button clicked. Functionality not yet implemented."
                }.GetNewClosure()
            }
            @{
                ColumnNumber    = 3
                Text            = 'Import AppLocker Files'
                PNGFileName     = 'shield_add'
                SizeType        = 'Large'
                ToolTip         = 'Import the AppLocker Policies from the selected file into the selected environment.'
                Function        = {
                    # Placeholder
                    Write-Line "[INFO] Import AppLocker Files button clicked. Functionality not yet implemented."
                }.GetNewClosure()
            }
            @{
                ColumnNumber    = 5
                Text            = 'Delete AppLocker Files'
                PNGFileName     = 'shield_delete'
                SizeType        = 'Large'
                ToolTip         = 'Delete the AppLocker Policies from the selected environment.'
                Function        = {
                    # Placeholder
                    Write-Line "[INFO] Delete AppLocker Files button clicked. Functionality not yet implemented."
                }.GetNewClosure()
            }
        )
        # Create the Buttons
        New-Button @EnvironmentComboBoxButtonProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -RowNumber 1
        New-Button @AppLockerFileTextBoxButtonProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -RowNumber 2
        New-ButtonLine -InputObject $InputObject -ButtonPropertiesArray $ActionButtonsPropertiesArray -ParentGroupBox $FeatureGroupBox -RowNumber 5
        
        # OUTPUT
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
    Writes the selected AppLocker environment and its linked Settings textbox to the host.
.DESCRIPTION
    This helper resolves the matching AppLocker Settings textbox for the selected Import environment
    combobox value and writes the link plus current textbox value to the host.
.EXAMPLE
    Write-SelectedAppLockerEnvironmentToHost -EnvironmentComboBox $MyComboBox
.INPUTS
    [System.Windows.Forms.ComboBox]
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.2
    Author          : Imraan Iotana
    Creation Date   : July 2026
    Last Update     : July 2026
#>
####################################################################################################
function Write-SelectedAppLockerEnvironmentToHost {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The AppLocker environment ComboBox to inspect.')]
        [System.Windows.Forms.ComboBox]$EnvironmentComboBox
    )

    try {
        # VALIDATION - INPUT CONTROL
        # Ensure the supplied ComboBox exists and is not disposed.
        if ($null -eq $EnvironmentComboBox -or $EnvironmentComboBox.IsDisposed) { return }

        # PREPARATION - SELECTED ENVIRONMENT
        # Read the selected AppLocker environment from the ComboBox.
        [System.String]$Environment = [System.String]$EnvironmentComboBox.Text
        if (Test-String -IsEmpty $Environment) { return }

        # PREPARATION - LINK RESOLUTION
        # Resolve the linked Settings TextBox name from the ComboBox Tag map.
        [System.String]$LinkedTextBoxName = $null
        if (($null -ne $EnvironmentComboBox.Tag) -and ($EnvironmentComboBox.Tag.PSObject.Properties['LinkedTextBoxNameMap'])) {
            $LinkedTextBoxName = [System.String]$EnvironmentComboBox.Tag.LinkedTextBoxNameMap[$Environment]
        }

        # VALIDATION - LINKED TARGET NAME
        # Stop when no linked TextBox name is available for the selected environment.
        if (Test-String -IsEmpty $LinkedTextBoxName) {
            Write-Line "AppLocker environment selected: [$Environment]. No linked textbox could be resolved." -Type Warning
            return
        }

        # EXECUTION - LINKED CONTROL LOOKUP
        # Resolve the linked TextBox control by name.
        [System.Windows.Forms.TextBox]$LinkedTextBox = Get-TextBoxObject -TextBoxName $LinkedTextBoxName

        # VALIDATION - LINKED CONTROL
        # Stop when the linked TextBox cannot be found or is disposed.
        if ($null -eq $LinkedTextBox -or $LinkedTextBox.IsDisposed) {
            Write-Line "AppLocker environment selected: [$Environment], but the linked textbox ($LinkedTextBoxName) was not found." -Type Warning
            return
        }

        # EXECUTION - HOST OUTPUT
        # Write the selected environment and linked LDAP value (or empty-state message) to the host.
        [System.String]$LinkedValue = $LinkedTextBox.Text
        if (Test-String -IsPopulated $LinkedValue) {
            Write-Line "AppLocker environment selected: [$Environment].`nLDAP: [$LinkedValue]" -Type Info
        }
        else {
            Write-Line "AppLocker environment selected: [$Environment]. Linked textbox ($LinkedTextBoxName) is currently empty." -Type Info
        }
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}

### END OF FUNCTION
####################################################################################################

