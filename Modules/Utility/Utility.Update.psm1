####################################################################################################
<#
.SYNOPSIS
    Checks for a newer version of the Application Delivery Assistant on GitHub and installs it.
.DESCRIPTION
    The version check reads the Version of StartAssistant.ps1 on GitHub. The update downloads and validates the
    new version in a temporary folder, and then hands over to a small helper script. The helper waits until the
    application has closed, replaces the application folder with the staged copy (the previous version is kept as
    '<Folder>.previous') and starts the application again.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.9.1
    Author          : Imraan Iotana
    Creation Date   : October 2026
    Last Update     : October 2026
#>
####################################################################################################


# The pattern that finds the application version in StartAssistant.ps1
[System.String]$Script:UpdateVersionPattern = "Version\s*=\s*\[System\.Version\]\s*'(\d+(?:\.\d+){1,3})'"

# The maximum size of the update download
[System.Int64]$Script:UpdateMaximumZipBytes = 100MB

# The prefix of the temporary update folders
[System.String]$Script:UpdateWorkFolderPrefix = 'ADA-Update-'

# The script that runs after the application has closed. It only uses the installation module of the new version.
[System.String]$Script:UpdateHelperScript = @'
param (
    [Parameter(Mandatory=$true)][System.Int32]$ProcessId,
    [Parameter(Mandatory=$true)][System.Int32]$ParentProcessId,
    [Parameter(Mandatory=$true)][System.String]$StagingFolder,
    [Parameter(Mandatory=$true)][System.String]$StagedRoot,
    [Parameter(Mandatory=$true)][System.String]$InstallFolder,
    [Parameter(Mandatory=$true)][System.String]$NewVersion
)
$ErrorActionPreference = 'Stop'
$Host.UI.RawUI.WindowTitle = 'Application Delivery Assistant - Update'
try {
    Write-Host 'Waiting for the Application Delivery Assistant to close...'
    foreach ($Id in @($ProcessId,$ParentProcessId)) {
        if ($Id -gt 0) {
            $Process = Get-Process -Id $Id -ErrorAction SilentlyContinue
            if (($null -ne $Process) -and (-not $Process.WaitForExit(60000))) {
                throw 'The application did not close within 60 seconds. The update was cancelled.'
            }
        }
    }
    Write-Host "Installing version $NewVersion..."
    Import-Module -Name (Join-Path -Path $StagedRoot -ChildPath 'Modules\Utility\Utility.Installation.psm1') -Force
    $Result = Install-ApplicationFiles -SourceFolder $StagedRoot -DestinationFolder $InstallFolder -ApplicationVersion $NewVersion
    Write-Host "The application was updated to version $NewVersion ($($Result.FileCount) files)." -ForegroundColor Green
    if (-not [System.String]::IsNullOrWhiteSpace($Result.BackupPath)) {
        Write-Host "The previous version was kept in: $($Result.BackupPath)"
    }
}
catch {
    Write-Host "The update failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host 'The previous version is unchanged or has been restored.'
    Read-Host 'Press Enter to start the application'
}
finally {
    Remove-Item -LiteralPath $StagingFolder -Recurse -Force -ErrorAction SilentlyContinue
}
$Launcher = Join-Path -Path $InstallFolder -ChildPath 'Start Application Delivery Assistant.cmd'
if (Test-Path -LiteralPath $Launcher -PathType Leaf) {
    Start-Process -FilePath $Launcher -WorkingDirectory $InstallFolder
}
else {
    Start-Process -FilePath 'powershell.exe' -ArgumentList @('-ExecutionPolicy','Bypass','-File',('"' + (Join-Path -Path $InstallFolder -ChildPath 'StartAssistant.ps1') + '"')) -WorkingDirectory $InstallFolder
}
'@


####################################################################################################
<#
.SYNOPSIS
    Reads the application version from the text of StartAssistant.ps1.
.DESCRIPTION
    Finds the line "Version = [System.Version]'x.y.z'" and returns it as a version object.
.EXAMPLE
    Get-ApplicationVersionFromText -Text (Get-Content -Raw .\StartAssistant.ps1)
.INPUTS
    [System.String]
.OUTPUTS
    [System.Version]
.NOTES
    Version         : 6.9.1
#>
####################################################################################################
function Get-ApplicationVersionFromText {
    [CmdletBinding()]
    [OutputType([System.Version])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The text of StartAssistant.ps1.')]
        [AllowEmptyString()]
        [System.String]$Text
    )

    [System.Text.RegularExpressions.Match]$Match = [System.Text.RegularExpressions.Regex]::Match($Text,$Script:UpdateVersionPattern)
    if (-not $Match.Success) {
        throw 'The application version could not be found in StartAssistant.ps1.'
    }
    return [System.Version]$Match.Groups[1].Value
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Gets the latest application version from GitHub.
.DESCRIPTION
    Downloads StartAssistant.ps1 from the VersionFileOnGithub setting and reads its version. Nothing is saved.
.EXAMPLE
    Get-LatestApplicationVersion -InputObject $Global:ApplicationObject
.INPUTS
    [PSCustomObject]
.OUTPUTS
    [System.Version]
.NOTES
    Version         : 6.9.1
#>
####################################################################################################
function Get-LatestApplicationVersion {
    [CmdletBinding()]
    [OutputType([System.Version])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The ApplicationObject containing the ApplicationSettings.')]
        [PSCustomObject]$InputObject
    )

    [System.String]$VersionUrl = [System.String]$InputObject.ApplicationSettings.VersionFileOnGithub
    if (-not $VersionUrl.StartsWith('https://',[System.StringComparison]::OrdinalIgnoreCase)) {
        throw "The update address is not a secure (https) address. ($VersionUrl)"
    }

    # Windows PowerShell 5.1 does not use TLS 1.2 by default
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
    [System.String]$PreviousProgress = $ProgressPreference
    $ProgressPreference = 'SilentlyContinue'
    try {
        $Response = Invoke-WebRequest -Uri $VersionUrl -UseBasicParsing -TimeoutSec 20 -ErrorAction Stop
    }
    finally {
        $ProgressPreference = $PreviousProgress
    }
    return (Get-ApplicationVersionFromText -Text ([System.String]$Response.Content))
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Compares the running application version with the latest version on GitHub.
.DESCRIPTION
    Returns an object with the current version, the latest version and whether an update is available.
.EXAMPLE
    Test-ApplicationUpdateAvailable -InputObject $Global:ApplicationObject
.INPUTS
    [PSCustomObject]
.OUTPUTS
    [PSCustomObject] with CurrentVersion, LatestVersion and UpdateAvailable.
.NOTES
    Version         : 6.9.1
#>
####################################################################################################
function Test-ApplicationUpdateAvailable {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The ApplicationObject containing the Version and ApplicationSettings.')]
        [PSCustomObject]$InputObject
    )

    [System.Version]$CurrentVersion = [System.Version]$InputObject.Version
    [System.Version]$LatestVersion = Get-LatestApplicationVersion -InputObject $InputObject
    return [PSCustomObject]@{
        CurrentVersion  = $CurrentVersion
        LatestVersion   = $LatestVersion
        UpdateAvailable = ($LatestVersion -gt $CurrentVersion)
    }
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Checks for a newer application version and offers to install it.
.DESCRIPTION
    Shows whether the application is up to date. When a newer version exists, the user is asked whether to update now.
.EXAMPLE
    Invoke-ApplicationUpdateCheck -InputObject $Global:ApplicationObject
.INPUTS
    [PSCustomObject]
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.9.1
    Author          : Imraan Iotana
    Creation Date   : October 2026
    Last Update     : October 2026
#>
####################################################################################################
function Invoke-ApplicationUpdateCheck {
    [CmdletBinding()]
    [OutputType([System.Void])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The ApplicationObject containing the Version and ApplicationSettings.')]
        [PSCustomObject]$InputObject
    )

    try {
        # EXECUTION - CHECK
        Write-Line 'Checking for updates...' -Type Info
        [PSCustomObject]$Result = $null
        try {
            $Result = Test-ApplicationUpdateAvailable -InputObject $InputObject
        }
        catch {
            Write-Line "The update check failed. Check the internet connection and try again. ($($_.Exception.Message))" -Type Warning
            return
        }

        # POST-EXECUTION - UP TO DATE
        if (-not $Result.UpdateAvailable) {
            Write-Line "The application is up to date. (Version $($Result.CurrentVersion))" -Type Success
            [void](Get-UserConfirmation -Title 'Check for Updates' -Body "The $($InputObject.Name) is up to date.`n`nVersion $($Result.CurrentVersion)" -Type Information)
            return
        }

        # POST-EXECUTION - UPDATE AVAILABLE
        Write-Line "Version $($Result.LatestVersion) is available. (Current version $($Result.CurrentVersion))" -Type Info
        [System.String]$Body = "Version $($Result.LatestVersion) of the $($InputObject.Name) is available. You are using version $($Result.CurrentVersion).`n`nWould you like to UPDATE now?"
        if (Get-UserConfirmation -Title 'Update Available' -Body $Body) {
            Install-ApplicationUpdate -InputObject $InputObject
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
    Downloads and validates the latest application version, and installs it after the application has closed.
.DESCRIPTION
    Refuses development copies (a folder with a .git folder) and folders that cannot be written to. Downloads the
    ZIP file to a temporary folder, extracts it, checks that it is a newer, complete application with scripts that
    parse without errors, and starts a helper script. After confirmation the application closes, the helper
    replaces the application folder (keeping '<Folder>.previous') and starts the application again.
.EXAMPLE
    Install-ApplicationUpdate -InputObject $Global:ApplicationObject
.INPUTS
    [PSCustomObject]
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.9.1
    Author          : Imraan Iotana
    Creation Date   : October 2026
    Last Update     : October 2026
#>
####################################################################################################
function Install-ApplicationUpdate {
    [CmdletBinding()]
    [OutputType([System.Void])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The ApplicationObject containing the Name, Version, RootFolder and ApplicationSettings.')]
        [PSCustomObject]$InputObject
    )

    [System.String]$WorkFolder = ''
    [System.Boolean]$HandedOver = $false
    try {
        # VALIDATION - THE INSTALLATION FOLDER
        [System.String]$InstallFolder = ([System.String]$InputObject.RootFolder).TrimEnd('\')
        if (Test-Path -LiteralPath (Join-Path -Path $InstallFolder -ChildPath '.git')) {
            Write-Line "This is a development copy (it contains a .git folder), so it is not updated by the application. Use git to update it. ($InstallFolder)" -Type Warning
            return
        }
        [System.String]$ParentFolder = [System.IO.Path]::GetDirectoryName($InstallFolder)
        if ([System.String]::IsNullOrWhiteSpace($ParentFolder)) {
            Write-Line "The application cannot be updated from the root of a drive. ($InstallFolder)" -Type Warning
            return
        }
        try {
            [System.String]$WriteTestPath = Join-Path -Path $ParentFolder -ChildPath ('.ada-write-test-' + [System.Guid]::NewGuid().ToString('N').Substring(0,8))
            New-Item -Path $WriteTestPath -ItemType Directory -ErrorAction Stop | Out-Null
            Remove-Item -LiteralPath $WriteTestPath -Force -ErrorAction SilentlyContinue
        }
        catch {
            Write-Line "There is no write access to the parent folder of the application, which is needed to replace it. Install the application in a folder you can write to. ($ParentFolder)" -Type Warning
            return
        }
        [System.String]$ZipUrl = [System.String]$InputObject.ApplicationSettings.ZipFileOnGithub
        if (-not $ZipUrl.StartsWith('https://',[System.StringComparison]::OrdinalIgnoreCase)) {
            throw "The update address is not a secure (https) address. ($ZipUrl)"
        }

        # PREPARATION - TEMPORARY FOLDER
        Get-ChildItem -LiteralPath $env:TEMP -Directory -Filter ($Script:UpdateWorkFolderPrefix + '*') -ErrorAction SilentlyContinue |
            Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-1) } |
            ForEach-Object { Remove-Item -LiteralPath $_.FullName -Recurse -Force -ErrorAction SilentlyContinue }
        $WorkFolder = Join-Path -Path $env:TEMP -ChildPath ($Script:UpdateWorkFolderPrefix + [System.Guid]::NewGuid().ToString('N').Substring(0,8))
        [System.String]$StagingFolder = Join-Path -Path $WorkFolder -ChildPath 'Staged'
        [System.String]$ZipPath = Join-Path -Path $WorkFolder -ChildPath 'Update.zip'
        New-Item -Path $StagingFolder -ItemType Directory -Force -ErrorAction Stop | Out-Null

        # EXECUTION - DOWNLOAD
        Write-Line 'Downloading the update...' -Type Info
        [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
        [System.String]$PreviousProgress = $ProgressPreference
        $ProgressPreference = 'SilentlyContinue'
        try {
            Invoke-WebRequest -Uri $ZipUrl -OutFile $ZipPath -UseBasicParsing -TimeoutSec 120 -ErrorAction Stop
        }
        catch {
            Write-Line "The update could not be downloaded. Check the internet connection and try again. ($($_.Exception.Message))" -Type Warning
            return
        }
        finally {
            $ProgressPreference = $PreviousProgress
        }
        if ((Get-Item -LiteralPath $ZipPath).Length -gt $Script:UpdateMaximumZipBytes) {
            throw 'The downloaded update is larger than expected, so it was not used.'
        }

        # EXECUTION - EXTRACT
        Write-Line 'Extracting and checking the update...' -Type Info
        [void](Expand-ZipArchive -ArchivePath $ZipPath -DestinationPath $StagingFolder -Force)
        # A GitHub ZIP contains one top-level folder; the application can also be at the root
        [System.String]$StagedRoot = $StagingFolder
        if (-not (Test-Path -LiteralPath (Join-Path -Path $StagedRoot -ChildPath 'StartAssistant.ps1') -PathType Leaf)) {
            [System.IO.DirectoryInfo[]]$TopFolders = @(Get-ChildItem -LiteralPath $StagingFolder -Directory -Force)
            if ($TopFolders.Count -eq 1) { $StagedRoot = $TopFolders[0].FullName }
        }

        # VALIDATION - THE STAGED APPLICATION
        if ((-not (Test-Path -LiteralPath (Join-Path -Path $StagedRoot -ChildPath 'StartAssistant.ps1') -PathType Leaf)) -or
            (-not (Test-Path -LiteralPath (Join-Path -Path $StagedRoot -ChildPath 'Modules\Utility\Utility.Installation.psm1') -PathType Leaf))) {
            throw 'The downloaded update does not contain a complete application, so it was not installed.'
        }
        [System.Version]$NewVersion = Get-ApplicationVersionFromText -Text ([System.IO.File]::ReadAllText((Join-Path -Path $StagedRoot -ChildPath 'StartAssistant.ps1')))
        if ($NewVersion -le [System.Version]$InputObject.Version) {
            Write-Line "The downloaded version ($NewVersion) is not newer than the current version ($($InputObject.Version)), so it was not installed." -Type Warning
            return
        }
        foreach ($ScriptFile in (Get-ChildItem -LiteralPath $StagedRoot -Recurse -File -Force | Where-Object { $_.Extension -in '.ps1','.psm1' })) {
            [System.Management.Automation.Language.ParseError[]]$ParseErrors = $null
            [void][System.Management.Automation.Language.Parser]::ParseFile($ScriptFile.FullName,[ref]$null,[ref]$ParseErrors)
            if ($ParseErrors.Count -gt 0) {
                throw "The downloaded update contains a script with errors, so it was not installed. ($($ScriptFile.Name))"
            }
        }

        # CONFIRMATION
        [System.String]$Body = "Version $NewVersion is ready to install.`n`nThe application closes now, is replaced in:`n$InstallFolder`n`nand starts again. The current version is kept in '$([System.IO.Path]::GetFileName($InstallFolder)).previous'. Settings and Customer Templates are not affected.`n`nWould you like to UPDATE now?"
        if (-not (Get-UserConfirmation -Title 'Install Update' -Body $Body)) {
            Write-Line 'The update was cancelled.' -Type Info
            return
        }

        # EXECUTION - HAND OVER TO THE HELPER SCRIPT
        [System.String]$HelperPath = Join-Path -Path $WorkFolder -ChildPath 'Apply-Update.ps1'
        [System.IO.File]::WriteAllText($HelperPath,$Script:UpdateHelperScript,[System.Text.Encoding]::ASCII)
        # The launcher (cmd.exe) that started the application keeps the folder in use until it ends, so the helper waits for it as well
        [System.Int32]$ParentProcessId = 0
        $ParentProcess = Get-CimInstance -ClassName Win32_Process -Filter "ProcessId=$PID" -ErrorAction SilentlyContinue
        if ($null -ne $ParentProcess) {
            $ParentInfo = Get-Process -Id $ParentProcess.ParentProcessId -ErrorAction SilentlyContinue
            if (($null -ne $ParentInfo) -and ($ParentInfo.ProcessName -eq 'cmd')) { $ParentProcessId = [System.Int32]$ParentInfo.Id }
        }
        [System.String[]]$ArgumentList = @(
            '-NoProfile','-ExecutionPolicy','Bypass','-File',('"' + $HelperPath + '"'),
            '-ProcessId',[System.String]$PID,
            '-ParentProcessId',[System.String]$ParentProcessId,
            '-StagingFolder',('"' + $StagingFolder + '"'),
            '-StagedRoot',('"' + $StagedRoot + '"'),
            '-InstallFolder',('"' + $InstallFolder + '"'),
            '-NewVersion',[System.String]$NewVersion
        )
        Start-Process -FilePath (Join-Path -Path $env:WINDIR -ChildPath 'System32\WindowsPowerShell\v1.0\powershell.exe') -ArgumentList $ArgumentList -WorkingDirectory $env:TEMP -ErrorAction Stop | Out-Null
        $HandedOver = $true
        Write-Line "The update to version $NewVersion has started. The application closes now and starts again when the update is finished." -Type Success

        # POST-EXECUTION - CLOSE THE APPLICATION
        if (($null -ne $Global:MainForm) -and (-not $Global:MainForm.IsDisposed)) {
            $Global:MainForm.Close()
        }
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
    finally {
        if ((-not $HandedOver) -and (-not [System.String]::IsNullOrWhiteSpace($WorkFolder)) -and (Test-Path -LiteralPath $WorkFolder)) {
            Remove-Item -LiteralPath $WorkFolder -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

### END OF FUNCTION
####################################################################################################
