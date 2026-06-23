####################################################################################################
<#
.SYNOPSIS
    Creates the AppLocker policy files for a selected folder.
.DESCRIPTION
    This function creates AppLocker policy XML files for a selected folder and writes a short report with the scanned executables and DLLs.
.EXAMPLE
    New-AppLockerFile -FolderToScan 'C:\Demo\MyFolder'
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
function New-AppLockerFile {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false,HelpMessage='The path folder to get all executables and dlls from.')]
        [Alias('Path')]
        [AllowNull()]
        [System.String]
        $FolderToScan,

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

        [Parameter(Mandatory=$false,HelpMessage='The selected template object.')]
        [PSCustomObject]
        $SelectedTemplate,

        [Parameter(Mandatory=$false,HelpMessage='Switch for skipping user confirmation.')]
        [Alias('SkipConfrmation')]
        [System.Management.Automation.SwitchParameter]
        $SkipConfirmation,

        [Parameter(Mandatory=$false,HelpMessage='Open the output folder after export.')]
        [System.Management.Automation.SwitchParameter]$OpenOutputFolder
    )

    try {
        # VALIDATION
        # Validate the source folder that will be scanned
        if ((Test-String -IsEmpty $FolderToScan) -or (-not (Test-Path -Path $FolderToScan -PathType Container))) {
            Write-Line "The Folder Path is invalid or empty. No AppLocker file will be created. ($FolderToScan)" -Type Warning
            return
        }

        # PREPARATION
        # Set the parent output folder and ensure it exists
        [System.String]$ParentOutputFolder = $OutputFolder
        if (Test-String -IsEmpty $ParentOutputFolder) { $ParentOutputFolder = Get-OutputFolder }
        if (-not (Test-Path -Path $ParentOutputFolder -PathType Container)) { New-Item -Path $ParentOutputFolder -ItemType Directory -Force | Out-Null }

        # CONFIRMATION
        # Ask for confirmation only when -SkipConfirmation is not specified
        if (-not $SkipConfirmation) {
            [System.String]$Title   = 'Create AppLocker Policy'
            [System.String]$Body    = "Would you like to create the APPLOCKER POLICY files for the folder:`n`n$FolderToScan"
            if (-not (Get-UserConfirmation -Title $Title -Body $Body)) { return }
        }

        # PREPARATION
        # Apply the fallback AD group before building any output paths
        if (Test-String -IsEmpty $ADGroupSID) { $ADGroupSID = 'S-1-1-0' ; Write-Line "The AD Group SID is empty. The group EVERYONE will be used instead. ($ADGroupSID)" -Type Warning }

        # Default to the standard AppLocker folder name unless the template overrides it
        [System.String]$AppLockerFolderName = 'AppLockerPolicies'

        # Use the template folder only when the caller supplied an explicit ApplicationID
        if (Test-String -IsEmpty $ApplicationID) {
            $ApplicationID = Split-Path -Path $FolderToScan -Leaf
        }
        else {
            # Else, if the ApplicationID is provided, attempt to resolve the AppLocker folder name from the selected template
            if ($null -eq $SelectedTemplate) {
                $SelectedTemplate = $Global:Graphics.ComboBoxes.ApplicationIntake.TemplateSelection.SelectedItem
            }
            [System.String]$ResolvedAppLockerFolderName = [System.String]$SelectedTemplate.ApplicationFolderSubFolders.AppLocker
            if (Test-String -IsPopulated $ResolvedAppLockerFolderName) {
                $AppLockerFolderName = $ResolvedAppLockerFolderName
            }
            else {
                # If the template does not provide a valid AppLocker folder name, log a warning and use the default
                Write-Line "Could not resolve ApplicationFolderSubFolders.AppLocker from the selected template. Using default path: ($AppLockerFolderName)" -Type Warning
            }
        }

        # Finalize the application-specific output root and AppLocker subfolder
        [System.String]$NewApplicationFolder = Join-Path -Path $ParentOutputFolder -ChildPath $ApplicationID
        [System.String]$OutputFolder = Join-Path -Path $NewApplicationFolder -ChildPath $AppLockerFolderName

        # Ensure the AppLocker output folder exists
        if (-not (Test-Path -Path $OutputFolder -PathType Container)) { New-Item -Path $OutputFolder -ItemType Directory -Force | Out-Null }

        # Precompute the report and policy output file paths
        [System.String]$ReportFilePath = Join-Path -Path $OutputFolder -ChildPath ('AppLockerReport_{0}.txt' -f $ApplicationID)
        [System.String]$AppLockerPolicyHashFilePath = Join-Path -Path $OutputFolder -ChildPath ('AppLockerPolicyHash_{0}.xml' -f $ApplicationID)
        [System.String]$AppLockerPolicyPathFilePath = Join-Path -Path $OutputFolder -ChildPath ('AppLockerPolicyPath_{0}.xml' -f $ApplicationID)
        [System.String]$AppLockerPolicyPublisherFilePath = Join-Path -Path $OutputFolder -ChildPath ('AppLockerPolicyPublisher_{0}.xml' -f $ApplicationID)

        # EXECUTION
        # Create the AppLocker policy files
        Write-Host 'Creating the AppLocker Policy files. One moment please...' -ForegroundColor DarkGray
        # Collect file information per file so invalid binaries are skipped instead of aborting the whole run
        [System.IO.FileInfo[]]$CandidatePolicyFiles = Get-ChildItem -Path $FolderToScan -File -Recurse -ErrorAction SilentlyContinue |
        Where-Object { $_.Extension -in @('.exe','.dll') }
        [System.Collections.Generic.List[System.Object]]$AppLockerFileInformation = [System.Collections.Generic.List[System.Object]]::new()
        foreach ($CandidatePolicyFile in $CandidatePolicyFiles) {
            try {
                [System.Object[]]$CurrentFileInformation = @(Get-AppLockerFileInformation -Path $CandidatePolicyFile.FullName -ErrorAction Stop)
                foreach ($FileInformationItem in $CurrentFileInformation) {
                    [void]$AppLockerFileInformation.Add($FileInformationItem)
                }
            }
            catch {
                Write-Line "Skipping file for AppLocker policy creation because it could not be processed as a valid Win32 binary: $($CandidatePolicyFile.FullName)" -Type Warning
            }
        }
        if ($AppLockerFileInformation.Count -eq 0) {
            Write-Line "No valid .exe or .dll files were found for AppLocker policy generation in folder: ($FolderToScan)" -Type Fail
            return
        }

        # Create the AppLocker policy files for Hash, Path, and Publisher rules
        $AppLockerFileInformation | New-AppLockerPolicy -RuleType Hash -User $ADGroupSID -RuleNamePrefix $ApplicationID -Optimize -XML > $AppLockerPolicyHashFilePath -IgnoreMissingFileInformation -InformationAction SilentlyContinue
        Write-Line "The AppLocker policy files by Hash have been created for folder: ($FolderToScan)" -Type Success
        $AppLockerFileInformation | New-AppLockerPolicy -RuleType Path -User $ADGroupSID -RuleNamePrefix $ApplicationID -Optimize -XML > $AppLockerPolicyPathFilePath -IgnoreMissingFileInformation -InformationAction SilentlyContinue
        Write-Line "The AppLocker policy files by Path have been created for folder: ($FolderToScan)" -Type Success
        $AppLockerFileInformation | New-AppLockerPolicy -RuleType Publisher -User $ADGroupSID -RuleNamePrefix $ApplicationID -Optimize -XML > $AppLockerPolicyPublisherFilePath -IgnoreMissingFileInformation -InformationAction SilentlyContinue
        Write-Line "The AppLocker policy files by Publisher have been created for folder: ($FolderToScan)" -Type Success

        # Create the AppLocker policy report
        New-AppLockerPolicyReport -FolderToScan $FolderToScan -ReportFilePath $ReportFilePath -ApplicationID $ApplicationID

        # Open the output folder if the switch is set
        if ($OpenOutputFolder) {
            Open-Folder -Path $ParentOutputFolder
        }
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
    Creates the AppLocker policy report for a selected folder.
.DESCRIPTION
    This function creates the AppLocker policy report and lists the executables and DLLs that were scanned.
.EXAMPLE
    New-AppLockerPolicyReport -FolderToScan 'C:\Demo\MyFolder' -ReportFilePath 'C:\Demo\AppLockerReport.txt' -ApplicationID 'MyFolder'
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
function New-AppLockerPolicyReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The folder to scan for executables and dlls.')]
        [System.String]
        $FolderToScan,

        [Parameter(Mandatory=$true,HelpMessage='The file path where the report will be written.')]
        [System.String]
        $ReportFilePath,

        [Parameter(Mandatory=$true,HelpMessage='The Application ID.')]
        [System.String]
        $ApplicationID
    )

    try {
        # Capture the current timestamp and build the fixed report lines
        [System.String]$TimeStamp           = [System.String](Get-TimeStamp -ForHost)
        [System.String]$IntroductoryLine    = ('AppLocker Information for the application: {0}' -f $ApplicationID)
        [System.String]$TimeStampLine       = ('Generated on: {0}' -f $TimeStamp)
        [System.String]$EmptyLine           = [System.String]''
        [System.String]$SeperationLine      = [System.String]'========================='

        # Write the report header
        Write-Line 'Creating the AppLocker Policy Report...'
        Add-Content -Path $ReportFilePath -Value $IntroductoryLine
        Add-Content -Path $ReportFilePath -Value $TimeStampLine
        Add-Content -Path $ReportFilePath -Value $EmptyLine
        Add-Content -Path $ReportFilePath -Value $SeperationLine
        Add-Content -Path $ReportFilePath -Value $EmptyLine
        Add-Content -Path $ReportFilePath -Value 'AppLocker Policy XML files have been created for the following files:'
        Add-Content -Path $ReportFilePath -Value $EmptyLine

        # Scan and list executable files
        [System.IO.FileSystemInfo[]]$ExecutableFiles = Get-ChildItem -Path $FolderToScan -File -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.Extension -eq '.exe' }
        Add-Content -Path $ReportFilePath -Value $SeperationLine
        Add-Content -Path $ReportFilePath -Value ('Number of Exe-files: {0}' -f $ExecutableFiles.Count)
        Add-Content -Path $ReportFilePath -Value $SeperationLine
        foreach ($ExecutableFile in $ExecutableFiles) { Add-Content -Path $ReportFilePath -Value $ExecutableFile.FullName }

        Add-Content -Path $ReportFilePath -Value $EmptyLine

        # Scan and list DLL files
        [System.IO.FileSystemInfo[]]$DllFiles = Get-ChildItem -Path $FolderToScan -File -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.Extension -eq '.dll' }
        Add-Content -Path $ReportFilePath -Value $SeperationLine
        Add-Content -Path $ReportFilePath -Value ('Number of DLL-files: {0}' -f $DllFiles.Count)
        Add-Content -Path $ReportFilePath -Value $SeperationLine
        foreach ($DllFile in $DllFiles) { Add-Content -Path $ReportFilePath -Value $DllFile.FullName }
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}

### END OF FUNCTION
####################################################################################################
