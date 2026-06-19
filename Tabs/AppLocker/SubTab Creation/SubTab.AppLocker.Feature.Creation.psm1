####################################################################################################
<#
.SYNOPSIS
    Imports the Application Security feature into the Intake tab.
.DESCRIPTION
    This function imports the Application Security feature into the Intake tab by creating a new GroupBox and adding it to the specified parent TabPage.
.EXAMPLE
    Import-FeatureApplicationSecurity -InputObject $MyApplicationObject -ParentTabPage $MyTabPage
.INPUTS
    [PSCustomObject]
    [System.Windows.Forms.TabPage]
    [System.Windows.Forms.GroupBox]
.OUTPUTS
    No objects are returned to the pipeline. All output is written to the host.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. All rights reserved.
    Version         : 6.0.0.0
    Author          : Imraan Iotana
    Creation Date   : May 2026
    Last Update     : June 2026
#>
####################################################################################################
function Import-FeatureAppLockerCreation {
    [CmdletBinding()]
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
            Title           = 'APPLICATION SECURITY'
            Color           = $Color
            NumberOfRows    = 5
            GroupBoxAbove   = $GroupBoxAbove
        }
        # Create the GroupBox
        [System.Windows.Forms.GroupBox]$FeatureGroupBox = New-GroupBox @FeatureProperties -OnSubTab

        # EXECUTION - TEXTBOXES
        # Set the InstallationFolderTextBox properties
        [System.Collections.Hashtable]$InstallationFolderTextBoxProperties = @{
            RowNumber       = 1
            Label           = 'Select Folder'
            PropertyName    = 'TextBoxes.AppLocker.Creation.FolderPath'
            ToolTip         = 'The folder to create AppLocker policies for.'
            SizeType        = 'Medium'
            SmallButtons    = @(@(5,'Browse Folder'),@(6,'Paste'),@(7,'Open'))
        }
        # Set the ADGroupNameTextBox properties
        [System.Collections.Hashtable]$ADGroupNameTextBoxProperties = @{
            RowNumber       = 2
            Label           = 'AD Group Name'
            PropertyName    = 'TextBoxes.AppLocker.Creation.ADGroupName'
            ToolTip         = 'The Active Directory group name that will be associated with the AppLocker policies'
            DefaultValue    = 'Everyone'
            SizeType        = 'Medium'
            SmallButtons    = @(@(5,'Copy'),@(6,'Paste'))
        }
        # Set the ADGroupSIDTextBox properties
        [System.Collections.Hashtable]$ADGroupSIDTextBoxProperties = @{
            RowNumber       = 3
            Label           = 'AD Group SID'
            PropertyName    = 'TextBoxes.AppLocker.Creation.ADGroupSID'
            ToolTip         = 'The Security Identifier (SID) of the Active Directory group associated with the AppLocker policies'
            DefaultValue    = 'S-1-1-0'
            SizeType        = 'Medium'
            SmallButtons    = @(@(5,'Copy'),@(6,'Paste'))
        }
        # Create the TextBoxes
        $Global:Graphics.TextBoxes.AppLocker.Creation.InstallationFolder   = New-TextBox @InstallationFolderTextBoxProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ReturnTextBox
        $Global:Graphics.TextBoxes.AppLocker.Creation.ADGroupName          = New-TextBox @ADGroupNameTextBoxProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ReturnTextBox
        $Global:Graphics.TextBoxes.AppLocker.Creation.ADGroupSID           = New-TextBox @ADGroupSIDTextBoxProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ReturnTextBox

        # EXECUTION - BUTTONS
        # Set the Default Button properties
        [System.Collections.Hashtable]$ADGroupDefaultButton = @{
            ColumnNumber    = 7
            Text            = 'Default'
            PNGFileName     = 'arrow_undo'
            SizeType        = 'Small'
            ToolTip         = 'Set the Active Directory group and SID to their default values.'
            Function        = {
                # This button is not a true "default" button as the default values are not hardcoded but rather set in the TextBox properties.
                Reset-TextBox -TextBox $Global:Graphics.TextBoxes.AppLocker.Creation.ADGroupName
                Reset-TextBox -TextBox $Global:Graphics.TextBoxes.AppLocker.Creation.ADGroupSID -Force
            }.GetNewClosure()
        }
        # Set the Action Button
        [System.Collections.Hashtable]$CreateButton = @{
            ColumnNumber    = 1
            Text            = 'Create AppLocker Files'
            PNGFileName     = 'shield'
            SizeType        = 'Large'
            ToolTip         = 'Create the AppLocker files for the selected folder.'
            Function        = { Write-Line "This function is still under development." }.GetNewClosure()
        }
        # Create the Buttons
        New-Button @ADGroupDefaultButton -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -RowNumber 3
        New-Button @CreateButton -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -RowNumber 4
        
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
    Creates the AppLocker policy files for a selected folder.
.DESCRIPTION
    This function creates AppLocker policy XML files for a selected folder and writes a short report with the scanned executables and DLLs.
.EXAMPLE
    New-AppLockerFile -Path 'C:\Demo\MyFolder'
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
function New-AppLockerFile {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The path folder to get all executables and dlls from.')]
        [AllowNull()]
        [System.String]
        $Path,

        [Parameter(Mandatory=$false,HelpMessage='The SID of the AD group that will be added to the policy file.')]
        [AllowEmptyString()]
        [System.String]
        $ADGroupSID,

        [Parameter(Mandatory=$false,HelpMessage='The parent folder where the output will be placed.')]
        [System.String]
        $OutputFolder = (Get-OutputFolder),

        [Parameter(Mandatory=$false,HelpMessage='The Application ID.')]
        [System.String]
        $ApplicationID,

        [Parameter(Mandatory=$false,HelpMessage='Switch for skipping user confirmation.')]
        [Alias('SkipConfrmation')]
        [System.Management.Automation.SwitchParameter]
        $SkipConfirmation
    )

    try {
        ####################################################################################################
        ### PREPARATION ###

        [System.String]$ParentOutputFolder = $OutputFolder
        if (Test-String -IsEmpty $ParentOutputFolder) { $ParentOutputFolder = Get-OutputFolder }
        if (-not (Test-Path -Path $ParentOutputFolder -PathType Container)) { New-Item -Path $ParentOutputFolder -ItemType Directory -Force | Out-Null }

        [System.String]$FolderToScan = $Path
        if (Test-String -IsEmpty $FolderToScan) { Write-Warning 'The Installation Folder field is empty. No AppLocker file will be created.' ; return }

        if (-not $SkipConfirmation) {
            [System.Boolean]$UserHasConfirmed = Get-UserConfirmation -Title 'Create AppLocker Policy' -Body 'Would you like to create the AppLocker Policy files?'
            if (-not $UserHasConfirmed) { return }
        }

        if (Test-String -IsEmpty $ADGroupSID) { Write-Warning 'The AD Group SID is empty. The group EVERYONE will be used instead.' ; $ADGroupSID = 'S-1-1-0' }
        if (Test-String -IsEmpty $ApplicationID) { $ApplicationID = Split-Path -Path $FolderToScan -Leaf }

        [System.String]$AppLockerFolderName = [System.String](Get-ApplicationSubfolders).AppLockerFolder
        [System.String]$NewApplicationFolder = Join-Path -Path $ParentOutputFolder -ChildPath $ApplicationID
        [System.String]$OutputFolder = Join-Path -Path $NewApplicationFolder -ChildPath $AppLockerFolderName

        if (-not (Test-Path -Path $OutputFolder -PathType Container)) { New-Item -Path $OutputFolder -ItemType Directory -Force | Out-Null }

        [System.String]$ReportFilePath = Join-Path -Path $OutputFolder -ChildPath ('AppLockerReport_{0}.txt' -f $ApplicationID)
        [System.String]$AppLockerPolicyHashFilePath = Join-Path -Path $OutputFolder -ChildPath ('AppLockerPolicyHash_{0}.xml' -f $ApplicationID)
        [System.String]$AppLockerPolicyPathFilePath = Join-Path -Path $OutputFolder -ChildPath ('AppLockerPolicyPath_{0}.xml' -f $ApplicationID)
        [System.String]$AppLockerPolicyPublisherFilePath = Join-Path -Path $OutputFolder -ChildPath ('AppLockerPolicyPublisher_{0}.xml' -f $ApplicationID)
        [System.String]$TimeStamp = [System.String](Get-TimeStamp -ForLogging)
        [System.String]$IntroductoryLine = ('AppLocker Information for the application: {0}' -f $ApplicationID)
        [System.String]$TimeStampLine = ('Generated on: {0}' -f $TimeStamp)
        [System.String]$SeperationLine = [System.String]'========================='

        ####################################################################################################
        ### EXECUTION ###

        Write-Host 'Creating the AppLocker Policy Report...' -ForegroundColor DarkGray
        Add-Content -Path $ReportFilePath -Value $IntroductoryLine
        Add-Content -Path $ReportFilePath -Value $TimeStampLine
        Add-Content -Path $ReportFilePath -Value ''
        Add-Content -Path $ReportFilePath -Value $SeperationLine
        Add-Content -Path $ReportFilePath -Value ''
        Add-Content -Path $ReportFilePath -Value 'AppLocker Policy XML files have been created for the following files:'
        Add-Content -Path $ReportFilePath -Value ''

        [System.IO.FileSystemInfo[]]$ExecutableFiles = Get-ChildItem -Path $FolderToScan -File -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.Extension -eq '.exe' }
        Add-Content -Path $ReportFilePath -Value $SeperationLine
        Add-Content -Path $ReportFilePath -Value ('Number of Exe-files: {0}' -f $ExecutableFiles.Count)
        Add-Content -Path $ReportFilePath -Value $SeperationLine
        foreach ($ExecutableFile in $ExecutableFiles) { Add-Content -Path $ReportFilePath -Value $ExecutableFile.FullName }

        Add-Content -Path $ReportFilePath -Value ''

        [System.IO.FileSystemInfo[]]$DllFiles = Get-ChildItem -Path $FolderToScan -File -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.Extension -eq '.dll' }
        Add-Content -Path $ReportFilePath -Value $SeperationLine
        Add-Content -Path $ReportFilePath -Value ('Number of DLL-files: {0}' -f $DllFiles.Count)
        Add-Content -Path $ReportFilePath -Value $SeperationLine
        foreach ($DllFile in $DllFiles) { Add-Content -Path $ReportFilePath -Value $DllFile.FullName }

        Write-Host 'Creating the AppLocker Policy files. One moment please...' -ForegroundColor DarkGray
        Get-AppLockerFileInformation -Directory $FolderToScan -Recurse | New-AppLockerPolicy -RuleType Hash -User $ADGroupSID -RuleNamePrefix $ApplicationID -Optimize -XML > $AppLockerPolicyHashFilePath -IgnoreMissingFileInformation -InformationAction SilentlyContinue
        Get-AppLockerFileInformation -Directory $FolderToScan -Recurse | New-AppLockerPolicy -RuleType Path -User $ADGroupSID -RuleNamePrefix $ApplicationID -Optimize -XML > $AppLockerPolicyPathFilePath -IgnoreMissingFileInformation -InformationAction SilentlyContinue
        Get-AppLockerFileInformation -Directory $FolderToScan -Recurse | New-AppLockerPolicy -RuleType Publisher -User $ADGroupSID -RuleNamePrefix $ApplicationID -Optimize -XML > $AppLockerPolicyPublisherFilePath -IgnoreMissingFileInformation -InformationAction SilentlyContinue

        Write-Line "The AppLocker policy files have been created for folder: ($FolderToScan)" -Type Success
        Open-Folder -Path $ParentOutputFolder
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}

### END OF FUNCTION
####################################################################################################


