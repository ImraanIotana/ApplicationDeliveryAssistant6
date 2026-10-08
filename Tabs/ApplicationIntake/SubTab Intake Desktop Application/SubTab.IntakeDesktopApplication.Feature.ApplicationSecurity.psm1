####################################################################################################
<#
.SYNOPSIS
    Imports the Application Security feature into the Desktop Application sub-tab.
.DESCRIPTION
    This function imports the Application Security feature into the Desktop Application sub-tab by creating a new GroupBox and adding it to the specified parent TabPage.
.EXAMPLE
    Import-FeatureApplicationSecurity -InputObject $MyApplicationObject -ParentTabPage $MyTabPage
.INPUTS
    [PSCustomObject]
    [System.Windows.Forms.TabPage]
    [System.Windows.Forms.GroupBox]
    [System.String]
.OUTPUTS
    [System.Windows.Forms.GroupBox]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.5.0
    Author          : Imraan Iotana
    Creation Date   : May 2026
    Last Update     : August 2026
#>
####################################################################################################
function Import-FeatureApplicationSecurity {
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
            Title           = 'APPLICATION SECURITY AND DETECTION'
            Color           = $Color
            NumberOfRows    = 3
            GroupBoxAbove   = $GroupBoxAbove
        }

        # EXECUTION - GROUPBOX
        # Create the GroupBox
        [System.Windows.Forms.GroupBox]$FeatureGroupBox = New-GroupBox @GroupBoxProperties

        # PREPARATION - TEXTBOX PROPERTIES
        # Set the InstallationFolderTextBox properties
        [System.Collections.Hashtable]$InstallationFolderTextBoxProperties = @{
            RowNumber       = 1
            Label           = 'Installation Folder'
            ToolTip         = 'The installation folder of the application'
            SizeType        = 'Medium'
            SmallButtons    = @(@(6,'Paste'),@(7,'Open'))
        }
        # Set the DetectionFileTextBox properties
        [System.Collections.Hashtable]$DetectionFileTextBoxProperties = @{
            RowNumber       = 2
            Label           = 'Detection file / MSI'
            ToolTip         = 'The detection file or MSI of the application. This will be used to acquire the detection information for the distribution system.'
            SizeType        = 'Medium'
            SmallButtons    = @(@(6,'Paste'),@(7,'Open'))
        }
        # Set the CreateAppLockerFilesComboBox properties
        [System.Collections.Hashtable]$CreateAppLockerFilesComboBoxProperties = @{
            RowNumber          = 3
            Label              = 'Create AppLocker files'
            ToolTip            = 'Choose whether AppLocker policy files are required for this application.'
            DefaultValue       = 'No'
            SizeType           = 'Medium'
            ContentStringArray = @('No','Yes')
        }

        # EXECUTION - TEXTBOXES
        # Create the TextBoxes
        [System.Windows.Forms.TextBox]$InstallationFolderTextBox = New-TextBox @InstallationFolderTextBoxProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ReturnTextBox
        [System.Windows.Forms.TextBox]$DetectionFileTextBox      = New-TextBox @DetectionFileTextBoxProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ReturnTextBox
        $null = New-ComboBox @CreateAppLockerFilesComboBoxProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ReturnComboBox

        # EXECUTION - BUTTONS
        # Set the Button properties
        [System.Collections.Hashtable]$InstallFolderButton = @{
            ColumnNumber    = 5
            Text            = 'Browse Folder'
            PNGFileName     = 'folders_explorer'
            SizeType        = 'Small'
            ToolTip         = 'The installation folder of the application. This will be used to create security files like AppLocker policies.'
            Function        = { Select-Folder -TextBox $InstallationFolderTextBox }.GetNewClosure()
        }
        [System.Collections.Hashtable]$BrowseDetectionFileButton = @{
            ColumnNumber    = 5
            Text            = 'Browse File'
            PNGFileName     = 'magnifier'
            SizeType        = 'Small'
            ToolTip         = 'Browse for the detection file or MSI of the application.'
            Function        = { Select-File -InitialDirectory $InstallationFolderTextBox.Text -TextBox $DetectionFileTextBox -Type Executable }.GetNewClosure()
        }
        [System.Collections.Hashtable]$AppLockerDetailsButton = @{
            ColumnNumber    = 5
            Text            = 'Customize'
            PNGFileName     = 'textfield_add'
            SizeType        = 'Medium'
            ToolTip         = 'Configure the Active Directory group for AppLocker policy files.'
            Function        = { Show-ApplicationIntakeAppLockerDetails -Owner $FeatureGroupBox.FindForm() }.GetNewClosure()
        }
        # Create the Buttons
        New-Button @InstallFolderButton -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -RowNumber 1
        New-Button @BrowseDetectionFileButton -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -RowNumber 2
        New-Button @AppLockerDetailsButton -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -RowNumber 3
        
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
    Configures the Active Directory group for AppLocker policy files during application intake.
#>
####################################################################################################
function Show-ApplicationIntakeAppLockerDetails {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false)]
        [AllowNull()]
        [System.Windows.Forms.IWin32Window]$Owner
    )

    [PSCustomObject]$AppLockerConfiguration = Get-ApplicationIntakeAppLockerConfiguration
    [System.Windows.Forms.Form]$Dialog = New-ModalDialog -Title 'AppLocker Files' -ClientWidth 470 -ClientHeight 225 -Owner $Owner
    try {
        [PSCustomObject]$DialogActions = New-ModalDialogActionBar -Dialog $Dialog -PrimaryText 'Save' -PrimaryDialogResult ([System.Windows.Forms.DialogResult]::OK) -ButtonWidth 75 -ButtonHeight 28
        [System.Windows.Forms.Label]$DetailsLabel = New-Object System.Windows.Forms.Label
        [System.Windows.Forms.Label]$ADGroupNameLabel = New-Object System.Windows.Forms.Label
        [System.Windows.Forms.Label]$ADGroupSIDLabel = New-Object System.Windows.Forms.Label
        [System.Windows.Forms.TextBox]$ADGroupNameTextBox = New-Object System.Windows.Forms.TextBox
        [System.Windows.Forms.TextBox]$ADGroupSIDTextBox = New-Object System.Windows.Forms.TextBox
        [System.Windows.Forms.Button]$ResetDefaultsButton = New-Object System.Windows.Forms.Button

        $DetailsLabel.Text = 'Choose Yes when this application requires AppLocker policy XML files.'
        $DetailsLabel.Location = New-Object System.Drawing.Point(15,15)
        $DetailsLabel.Size = New-Object System.Drawing.Size(440,25)

        $ADGroupNameLabel.Text = 'AD Group Name'
        $ADGroupNameLabel.Location = New-Object System.Drawing.Point(15,55)
        $ADGroupNameLabel.Size = New-Object System.Drawing.Size(145,24)
        $ADGroupNameTextBox.Text = $AppLockerConfiguration.ADGroupName
        $ADGroupNameTextBox.Location = New-Object System.Drawing.Point(165,52)
        $ADGroupNameTextBox.Size = New-Object System.Drawing.Size(290,24)

        $ADGroupSIDLabel.Text = 'AD Group SID'
        $ADGroupSIDLabel.Location = New-Object System.Drawing.Point(15,92)
        $ADGroupSIDLabel.Size = New-Object System.Drawing.Size(145,24)
        $ADGroupSIDTextBox.Text = $AppLockerConfiguration.ADGroupSID
        $ADGroupSIDTextBox.Location = New-Object System.Drawing.Point(165,89)
        $ADGroupSIDTextBox.Size = New-Object System.Drawing.Size(290,24)

        $ResetDefaultsButton.Text = 'Reset Defaults'
        $ResetDefaultsButton.Size = New-Object System.Drawing.Size(115,28)
        $ResetDefaultsButton.Location = New-Object System.Drawing.Point(12,12)
        $ResetDefaultsButton.Add_Click({
            $ADGroupNameTextBox.Text = 'Everyone'
            $ADGroupSIDTextBox.Text = 'S-1-1-0'
        }.GetNewClosure())

        $Dialog.Controls.AddRange(@($DetailsLabel,$ADGroupNameLabel,$ADGroupNameTextBox,$ADGroupSIDLabel,$ADGroupSIDTextBox))
        $DialogActions.Panel.Controls.Add($ResetDefaultsButton)
        if ((Show-ModalDialog -Dialog $Dialog -Owner $Owner) -eq [System.Windows.Forms.DialogResult]::OK) {
            Set-UserSetting -PropertyName 'TextBoxes.applicationintake.desktopapplication.applicationsecurityanddetection.ADGroupName' -PropertyValue $ADGroupNameTextBox.Text.Trim()
            Set-UserSetting -PropertyName 'TextBoxes.applicationintake.desktopapplication.applicationsecurityanddetection.ADGroupSID' -PropertyValue $ADGroupSIDTextBox.Text.Trim()
        }
    }
    finally {
        $Dialog.Dispose()
    }
}

### END OF FUNCTION
################################################################################################


################################################################################################
<#
.SYNOPSIS
    Gets the current AppLocker selection and saved Active Directory group values.
#>
################################################################################################
function Get-ApplicationIntakeAppLockerConfiguration {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param ()

    [System.Windows.Forms.ComboBox]$CreateAppLockerFilesComboBox = Get-ComboBoxObject -ComboBoxName 'CreateAppLockerFiles'
    [System.String]$ADGroupName = Get-UserSetting -PropertyName 'TextBoxes.applicationintake.desktopapplication.applicationsecurityanddetection.ADGroupName'
    [System.String]$ADGroupSID = Get-UserSetting -PropertyName 'TextBoxes.applicationintake.desktopapplication.applicationsecurityanddetection.ADGroupSID'

    return [PSCustomObject]@{
        CreateFiles = ($null -ne $CreateAppLockerFilesComboBox) -and [System.String]::Equals($CreateAppLockerFilesComboBox.Text, 'Yes', [System.StringComparison]::OrdinalIgnoreCase)
        ADGroupName = if (Test-String -IsPopulated $ADGroupName) { $ADGroupName } else { 'Everyone' }
        ADGroupSID  = if (Test-String -IsPopulated $ADGroupSID) { $ADGroupSID } else { 'S-1-1-0' }
    }
}

### END OF FUNCTION
################################################################################################
