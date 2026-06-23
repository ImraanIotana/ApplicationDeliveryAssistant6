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
        # Capture the current timestamp and build the fixed report lines.
        [System.String]$TimeStamp           = [System.String](Get-TimeStamp -ForHost)
        [System.String]$IntroductoryLine    = ('AppLocker Information for the application: {0}' -f $ApplicationID)
        [System.String]$TimeStampLine       = ('Generated on: {0}' -f $TimeStamp)
        [System.String]$EmptyLine           = [System.String]''
        [System.String]$SeperationLine      = [System.String]'========================='

        # Write the report header.
        Write-Line 'Creating the AppLocker Policy Report...'
        Add-Content -Path $ReportFilePath -Value $IntroductoryLine
        Add-Content -Path $ReportFilePath -Value $TimeStampLine
        Add-Content -Path $ReportFilePath -Value $EmptyLine
        Add-Content -Path $ReportFilePath -Value $SeperationLine
        Add-Content -Path $ReportFilePath -Value $EmptyLine
        Add-Content -Path $ReportFilePath -Value 'AppLocker Policy XML files have been created for the following files:'
        Add-Content -Path $ReportFilePath -Value $EmptyLine

        # Scan and list executable files.
        [System.IO.FileSystemInfo[]]$ExecutableFiles = Get-ChildItem -Path $FolderToScan -File -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.Extension -eq '.exe' }
        Add-Content -Path $ReportFilePath -Value $SeperationLine
        Add-Content -Path $ReportFilePath -Value ('Number of Exe-files: {0}' -f $ExecutableFiles.Count)
        Add-Content -Path $ReportFilePath -Value $SeperationLine
        foreach ($ExecutableFile in $ExecutableFiles) { Add-Content -Path $ReportFilePath -Value $ExecutableFile.FullName }

        Add-Content -Path $ReportFilePath -Value $EmptyLine

        # Scan and list DLL files.
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
