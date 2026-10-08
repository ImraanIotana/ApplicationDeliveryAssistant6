####################################################################################################
<#
.SYNOPSIS
    Installs the Application Delivery Assistant into a folder.
.DESCRIPTION
    Copies the application files to a chosen folder with a staged copy, so a failed installation never
    leaves a half-written folder behind. An existing installation in that folder is kept as a backup.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.9.1
    Author          : Imraan Iotana
    Creation Date   : October 2026
    Last Update     : October 2026
#>
####################################################################################################


# Folders that are never copied to an installation
[System.String[]]$Script:InstallationExcludedFolderNames = @('.git','.vs','.vscode')

# The file that marks a folder as an installed copy
[System.String]$Script:InstallationMarkerFileName = 'Installed.marker'


####################################################################################################
<#
.SYNOPSIS
    Copies the application files to a destination folder, keeping any existing installation as a backup.
.DESCRIPTION
    Validates both folders, copies the application files into a staging folder next to the destination,
    checks the staged copy, and then publishes it. An existing installation is renamed to '<Folder>.previous'
    (one backup is kept) and restored when publishing fails. A destination folder that is not empty and does
    not contain an application installation is refused.
.EXAMPLE
    Install-ApplicationFiles -SourceFolder 'C:\Downloads\ADA' -DestinationFolder 'C:\Users\Me\AppData\Local\Programs\Application Delivery Assistant'
.INPUTS
    [System.String]
.OUTPUTS
    [PSCustomObject] with Destination, BackupPath and FileCount.
.NOTES
    Version         : 6.9.1
#>
####################################################################################################
function Install-ApplicationFiles {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The folder that contains the application files.')]
        [System.String]$SourceFolder,

        [Parameter(Mandatory=$true,HelpMessage='The folder in which the application is installed.')]
        [System.String]$DestinationFolder,

        [Parameter(Mandatory=$false,HelpMessage='The application version that is written to the installation marker.')]
        [System.String]$ApplicationVersion = ''
    )

    [System.String]$StagePath = ''
    [System.String]$BackupPath = ''
    [System.Boolean]$OriginalMoved = $false
    [System.Int32]$FileCount = 0

    try {
        # VALIDATION - FOLDERS
        [System.String]$Source = ''
        [System.String]$Destination = ''
        try {
            $Source = [System.IO.Path]::GetFullPath($SourceFolder).TrimEnd('\')
            $Destination = [System.IO.Path]::GetFullPath($DestinationFolder).TrimEnd('\')
        }
        catch {
            throw "The folder path is not valid. ($DestinationFolder)"
        }
        if (-not (Test-Path -LiteralPath (Join-Path -Path $Source -ChildPath 'StartAssistant.ps1') -PathType Leaf)) {
            throw "The source folder does not contain the application. ($Source)"
        }
        if ([System.String]::IsNullOrWhiteSpace($Destination) -or $Destination.Equals([System.IO.Path]::GetPathRoot($Destination).TrimEnd('\'),[System.StringComparison]::OrdinalIgnoreCase)) {
            throw "The application cannot be installed in the root of a drive. ($DestinationFolder)"
        }
        if ($Destination.Equals($Source,[System.StringComparison]::OrdinalIgnoreCase)) {
            throw "The application already runs from this folder. ($Destination)"
        }
        if ($Destination.StartsWith($Source + '\',[System.StringComparison]::OrdinalIgnoreCase) -or $Source.StartsWith($Destination + '\',[System.StringComparison]::OrdinalIgnoreCase)) {
            throw "The installation folder and the folder the application runs from cannot be inside each other. ($Destination)"
        }

        # VALIDATION - EXISTING DESTINATION
        [System.Boolean]$DestinationExists = Test-Path -LiteralPath $Destination
        [System.Boolean]$DestinationIsEmpty = $true
        if ($DestinationExists) {
            if (-not (Test-Path -LiteralPath $Destination -PathType Container)) {
                throw "A file with the name of the installation folder already exists. ($Destination)"
            }
            $DestinationIsEmpty = (@(Get-ChildItem -LiteralPath $Destination -Force -ErrorAction Stop).Count -eq 0)
            [System.Boolean]$IsInstallation = (Test-Path -LiteralPath (Join-Path -Path $Destination -ChildPath $Script:InstallationMarkerFileName) -PathType Leaf) -or
                (Test-Path -LiteralPath (Join-Path -Path $Destination -ChildPath 'StartAssistant.ps1') -PathType Leaf)
            if ((-not $DestinationIsEmpty) -and (-not $IsInstallation)) {
                throw "The folder is not empty and does not contain an Application Delivery Assistant installation, so it was not replaced. ($Destination)"
            }
        }

        # PREPARATION - STAGING FOLDER
        [System.String]$ParentFolder = [System.IO.Path]::GetDirectoryName($Destination)
        [System.String]$LeafName = [System.IO.Path]::GetFileName($Destination)
        try {
            if (-not (Test-Path -LiteralPath $ParentFolder -PathType Container)) {
                New-Item -Path $ParentFolder -ItemType Directory -Force -ErrorAction Stop | Out-Null
            }
            $StagePath = Join-Path -Path $ParentFolder -ChildPath ('.' + $LeafName + '.partial-' + [System.Guid]::NewGuid().ToString('N').Substring(0,8))
            New-Item -Path $StagePath -ItemType Directory -ErrorAction Stop | Out-Null
        }
        catch [System.UnauthorizedAccessException] {
            throw "There is no write access to the folder. Choose another folder. ($ParentFolder)"
        }

        # EXECUTION - COPY THE FILES
        [System.Collections.Generic.Stack[System.String]]$PendingFolders = New-Object 'System.Collections.Generic.Stack[System.String]'
        $PendingFolders.Push($Source)
        while ($PendingFolders.Count -gt 0) {
            [System.String]$CurrentFolder = $PendingFolders.Pop()
            [System.String]$RelativeFolder = $CurrentFolder.Substring($Source.Length).TrimStart('\')
            [System.String]$StageFolder = if ($RelativeFolder.Length -eq 0) { $StagePath } else { Join-Path -Path $StagePath -ChildPath $RelativeFolder }
            if (-not (Test-Path -LiteralPath $StageFolder -PathType Container)) {
                New-Item -Path $StageFolder -ItemType Directory -ErrorAction Stop | Out-Null
            }
            foreach ($Child in (Get-ChildItem -LiteralPath $CurrentFolder -Force -ErrorAction Stop)) {
                if ($Child.PSIsContainer) {
                    if ($Script:InstallationExcludedFolderNames -notcontains $Child.Name) { $PendingFolders.Push($Child.FullName) }
                    continue
                }
                if (($RelativeFolder.Length -eq 0) -and $Child.Name.Equals($Script:InstallationMarkerFileName,[System.StringComparison]::OrdinalIgnoreCase)) { continue }
                Copy-Item -LiteralPath $Child.FullName -Destination (Join-Path -Path $StageFolder -ChildPath $Child.Name) -Force -ErrorAction Stop
                $FileCount++
            }
        }

        # VALIDATION - STAGED COPY
        if ((-not (Test-Path -LiteralPath (Join-Path -Path $StagePath -ChildPath 'StartAssistant.ps1') -PathType Leaf)) -or (-not (Test-Path -LiteralPath (Join-Path -Path $StagePath -ChildPath 'Modules') -PathType Container))) {
            throw 'The copied application is incomplete. The installation was cancelled.'
        }
        [System.String]$MarkerText = "Installed by the Application Delivery Assistant $ApplicationVersion on $((Get-Date).ToString('yyyy-MM-dd HH:mm')) from $Source"
        [System.IO.File]::WriteAllText((Join-Path -Path $StagePath -ChildPath $Script:InstallationMarkerFileName),$MarkerText,(New-Object System.Text.UTF8Encoding($false)))

        # EXECUTION - PUBLISH
        if ($DestinationExists) {
            if ($DestinationIsEmpty) {
                Remove-Item -LiteralPath $Destination -Force -ErrorAction Stop
            }
            else {
                $BackupPath = Join-Path -Path $ParentFolder -ChildPath ($LeafName + '.previous')
                if (Test-Path -LiteralPath $BackupPath) { Remove-Item -LiteralPath $BackupPath -Recurse -Force -ErrorAction Stop }
                for ([System.Int32]$Attempt = 1; $Attempt -le 5; $Attempt++) {
                    try { Move-Item -LiteralPath $Destination -Destination $BackupPath -ErrorAction Stop; $OriginalMoved = $true; break }
                    catch { if ($Attempt -eq 5) { throw "The existing installation could not be moved. Close the application that runs from that folder and try again. ($Destination)" }; Start-Sleep -Milliseconds 400 }
                }
            }
        }
        try {
            for ([System.Int32]$Attempt = 1; $Attempt -le 5; $Attempt++) {
                try { Move-Item -LiteralPath $StagePath -Destination $Destination -ErrorAction Stop; break }
                catch { if ($Attempt -eq 5) { throw }; Start-Sleep -Milliseconds 400 }
            }
        }
        catch {
            if ($OriginalMoved) { Move-Item -LiteralPath $BackupPath -Destination $Destination -ErrorAction SilentlyContinue }
            throw
        }

        # POST-EXECUTION
        return [PSCustomObject]@{
            Destination = $Destination
            BackupPath  = $BackupPath
            FileCount   = $FileCount
        }
    }
    finally {
        if ((-not [System.String]::IsNullOrWhiteSpace($StagePath)) -and (Test-Path -LiteralPath $StagePath)) {
            Remove-Item -LiteralPath $StagePath -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Installs the application into a folder chosen by the user.
.DESCRIPTION
    Asks for a folder, confirms the resulting installation folder, copies the application, and offers to
    create shortcuts and to start the installed copy. The application is placed in a subfolder named after
    the application, unless the chosen folder already contains an installation.
.EXAMPLE
    Install-ApplicationToFolder -InputObject $Global:ApplicationObject
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
function Install-ApplicationToFolder {
    [CmdletBinding()]
    [OutputType([System.Void])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The ApplicationObject containing the Name, Version and RootFolder.')]
        [PSCustomObject]$InputObject
    )

    [System.Windows.Forms.FolderBrowserDialog]$FolderDialog = $null
    try {
        # PREPARATION
        [System.String]$SourceFolder = ([System.String]$InputObject.RootFolder).TrimEnd('\')
        [System.String]$DefaultParent = Join-Path -Path $env:LOCALAPPDATA -ChildPath 'Programs'
        if (-not (Test-Path -LiteralPath $DefaultParent -PathType Container)) {
            New-Item -Path $DefaultParent -ItemType Directory -Force | Out-Null
        }

        # EXECUTION - CHOOSE THE FOLDER
        $FolderDialog = [System.Windows.Forms.FolderBrowserDialog]::new()
        $FolderDialog.Description = "Select the folder in which to install the $($InputObject.Name). A subfolder named '$($InputObject.Name)' is created in it."
        $FolderDialog.SelectedPath = $DefaultParent
        $FolderDialog.ShowNewFolderButton = $true
        if ($FolderDialog.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) {
            Write-Line 'The installation was cancelled.' -Type Info
            return
        }
        [System.String]$ChosenFolder = $FolderDialog.SelectedPath.TrimEnd('\')
        [System.String]$Destination = if (Test-Path -LiteralPath (Join-Path -Path $ChosenFolder -ChildPath 'StartAssistant.ps1') -PathType Leaf) { $ChosenFolder } else { Join-Path -Path $ChosenFolder -ChildPath ([System.String]$InputObject.Name) }
        if ($Destination.Equals($SourceFolder,[System.StringComparison]::OrdinalIgnoreCase)) {
            Write-Line "The application already runs from this folder. ($Destination)" -Type Warning
            return
        }

        # CONFIRMATION
        [System.String]$Body = "Would you like to INSTALL the $($InputObject.Name) $($InputObject.Version) in the following folder?`n`n$Destination"
        if (Test-Path -LiteralPath $Destination -PathType Container) {
            $Body += "`n`nAn existing installation in this folder is replaced. It is kept as a backup in '$([System.IO.Path]::GetFileName($Destination)).previous'."
        }
        if (-not (Get-UserConfirmation -Title 'Confirm Install Application' -Body $Body)) {
            Write-Line 'The installation was cancelled.' -Type Info
            return
        }

        # EXECUTION - INSTALL
        Write-Line "Installing the application to: ($Destination)" -Type Info
        [PSCustomObject]$Result = Install-ApplicationFiles -SourceFolder $SourceFolder -DestinationFolder $Destination -ApplicationVersion ([System.String]$InputObject.Version)
        Write-Line "The application was installed ($($Result.FileCount) files) to: ($($Result.Destination))" -Type Success
        if (-not [System.String]::IsNullOrWhiteSpace($Result.BackupPath)) {
            Write-Line "The previous installation was kept in: ($($Result.BackupPath))" -Type Info
        }

        # POST-EXECUTION - SHORTCUTS
        [PSCustomObject]$InstalledObject = [PSCustomObject]@{ RootFolder = $Result.Destination }
        foreach ($ShortcutType in 'Startmenu','Desktop') {
            if (Get-UserConfirmation -Title 'Create Shortcut' -Body "Would you like to create a $ShortcutType shortcut for the installed application?") {
                New-ApplicationShortcut -InputObject $InstalledObject -ShortcutType $ShortcutType -Force
            }
        }

        # POST-EXECUTION - START THE INSTALLED COPY
        if (Get-UserConfirmation -Title 'Start Application' -Body "Would you like to start the installed application now?`n`nThis window and the current application stay open. You can remove the folder you downloaded the application to.") {
            [System.String]$Launcher = Join-Path -Path $Result.Destination -ChildPath 'Start Application Delivery Assistant.cmd'
            if (Test-Path -LiteralPath $Launcher -PathType Leaf) {
                Start-Process -FilePath $Launcher -WorkingDirectory $Result.Destination
            }
            else {
                Start-Process -FilePath 'powershell.exe' -ArgumentList @('-ExecutionPolicy','Bypass','-File',('"' + (Join-Path -Path $Result.Destination -ChildPath 'StartAssistant.ps1') + '"')) -WorkingDirectory $Result.Destination
            }
        }
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
    finally {
        if ($null -ne $FolderDialog) { $FolderDialog.Dispose() }
    }
}

### END OF FUNCTION
####################################################################################################
