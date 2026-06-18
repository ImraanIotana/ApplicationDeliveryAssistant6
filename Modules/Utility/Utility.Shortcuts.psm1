####################################################################################################
<#
.SYNOPSIS
    Retrieves shortcuts from system and user locations.
.DESCRIPTION
    This function scans common Start Menu and Desktop locations for shortcuts.
    It returns rich objects that include a ComboBoxName property so the result can be used directly in ComboBoxes.
    Returned items are prefixed with [SYSTEM] or [USER] based on their source location.
.EXAMPLE
    Get-Shortcuts
.INPUTS
    None.
.OUTPUTS
    [PSCustomObject[]]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. All rights reserved.
    Version         : 6.0.0.0
    Author          : Imraan Iotana
    Creation Date   : May 2026
    Last Update     : June 2026
#>
####################################################################################################
function Get-Shortcuts {
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param (
        [Parameter(Mandatory=$false,HelpMessage='Include internet shortcuts (*.url) in addition to shell shortcuts (*.lnk).')]
        [System.Management.Automation.SwitchParameter]$IncludeInternetShortcuts
    )

    # PREPARATION
    # Define known shortcut roots and their labels
    [PSCustomObject[]]$ShortcutRoots = @(
        @{
            Path     = Join-Path -Path $env:ProgramData -ChildPath 'Microsoft\Windows\Start Menu\Programs'
            Prefix   = 'SYSTEM'
            Location = 'StartMenu'
        }
        @{
            Path     = Join-Path -Path $env:Public -ChildPath 'Desktop'
            Prefix   = 'SYSTEM'
            Location = 'Desktop'
        }
        @{
            Path     = Join-Path -Path $env:APPDATA -ChildPath 'Microsoft\Windows\Start Menu\Programs'
            Prefix   = 'USER'
            Location = 'StartMenu'
        }
        @{
            Path     = Join-Path -Path $env:USERPROFILE -ChildPath 'Desktop'
            Prefix   = 'USER'
            Location = 'Desktop'
        }
    )

    [System.String[]]$AllowedExtensions = @('.lnk')
    if ($IncludeInternetShortcuts) { $AllowedExtensions += '.url' }

    # EXECUTION
    # Enumerate shortcuts from all available roots
    [PSCustomObject[]]$Shortcuts = foreach ($ShortcutRoot in $ShortcutRoots) {
        if (-not (Test-Path -Path $ShortcutRoot.Path)) { continue }

        # Subfolders (top-level only) that contain at least one shortcut anywhere inside
        Get-ChildItem -Path $ShortcutRoot.Path -Directory -ErrorAction SilentlyContinue |
        Where-Object {
            $null -ne (Get-ChildItem -Path $_.FullName -Recurse -File -ErrorAction SilentlyContinue |
                Where-Object { $AllowedExtensions -contains $_.Extension.ToLowerInvariant() } |
                Select-Object -First 1)
        } |
        ForEach-Object {
            [PSCustomObject]@{
                Name            = $_.Name
                Extension       = ''
                FullPath        = $_.FullName
                FolderPath      = $_.Parent.FullName
                Prefix          = $ShortcutRoot.Prefix
                SourceLocation  = $ShortcutRoot.Location
                RegistryPath    = $_.FullName
                Type            = 'Folder'
                ComboBoxName    = "[$($ShortcutRoot.Prefix)] $($_.Name)"
            }
        }

        # Shortcut files in the root only (not recursive)
        Get-ChildItem -Path $ShortcutRoot.Path -File -ErrorAction SilentlyContinue |
        Where-Object { $AllowedExtensions -contains $_.Extension.ToLowerInvariant() } |
        ForEach-Object {
            [PSCustomObject]@{
                Name            = $_.BaseName
                Extension       = $_.Extension
                FullPath        = $_.FullName
                FolderPath      = $_.DirectoryName
                Prefix          = $ShortcutRoot.Prefix
                SourceLocation  = $ShortcutRoot.Location
                RegistryPath    = $_.FullName
                Type            = 'Shortcut'
                ComboBoxName    = "[$($ShortcutRoot.Prefix)] $($_.Name)"
            }
        }
    }

    # OUTPUT
    # Return unique items — folders first, then shortcuts — sorted alphabetically within each group
    $Shortcuts |
    Sort-Object FullPath -Unique | Sort-Object Prefix, Type, ComboBoxName
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Exports the icon image for a shortcut properties object.
.DESCRIPTION
    This function extracts an icon from a shortcut properties object and saves it as a PNG or ICO file.
    It first tries IconFilePath and falls back to TargetPath when needed.
.EXAMPLE
    Export-ShortcutImage -InputObject $ShortcutPropertiesObject -OutputFolder 'C:\Demo' -PNG
.EXAMPLE
    Export-ShortcutImage -InputObject $ShortcutPropertiesObject -OutputFolder 'C:\Demo' -ICO -OpenOutputFolder
.INPUTS
    [System.Object]
    [System.String]
    [System.Management.Automation.SwitchParameter]
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
function Export-ShortcutImage {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The object containing the shortcut properties.')]
        [System.Object]$InputObject,

        [Parameter(Mandatory=$true,HelpMessage='The folder where the output file will be created.')]
        [System.String]$OutputFolder,

        [Parameter(Mandatory=$false,HelpMessage='Create a PNG file.')]
        [System.Management.Automation.SwitchParameter]$PNG,

        [Parameter(Mandatory=$false,HelpMessage='Create an ICO file.')]
        [System.Management.Automation.SwitchParameter]$ICO,

        [Parameter(Mandatory=$false,HelpMessage='Open the output folder after export.')]
        [System.Management.Automation.SwitchParameter]$OpenOutputFolder
    )

    try {
        # VALIDATION
        # Validate output folder and output type switches.
        if (Test-String -IsEmpty $OutputFolder) { throw 'The OutputFolder parameter is empty.' }
        if ($PNG -and $ICO) {
            Write-Line 'Please select only one output format switch: -PNG or -ICO.' -Type Fail
            return
        }

        # PREPARATION
        # Ensure output folder exists and determine file extension.
        if (-not (Test-Path -LiteralPath $OutputFolder -PathType Container)) {
            New-Item -Path $OutputFolder -ItemType Directory -Force | Out-Null
        }
        [System.String]$Extension = if ($ICO) { 'ico' } else { 'png' }

        # PREPARATION
        # Read properties from the provided shortcut object.
        [System.String]$BaseName = [System.String]$InputObject.BaseName
        [System.String]$IconFilePath = [System.String]$InputObject.IconFilePath
        [System.String]$TargetPath = [System.String]$InputObject.TargetPath
        if (Test-String -IsEmpty $BaseName) { $BaseName = 'ShortcutIcon' }

        [System.String]$OutputFileName = ('{0}.{1}' -f $BaseName,$Extension)
        [System.String]$OutputFilePath = Join-Path -Path $OutputFolder -ChildPath $OutputFileName

        # EXECUTION
        # Try IconFilePath first, then fall back to TargetPath.
        [System.Boolean]$Saved = $false
        if ((Test-String -IsPopulated $IconFilePath) -and (Test-Path -LiteralPath $IconFilePath -PathType Leaf)) {
            try {
                [System.Drawing.Icon]::ExtractAssociatedIcon($IconFilePath).ToBitmap().Save($OutputFilePath)
                $Saved = $true
            }
            catch {
                # Keep trying with TargetPath when icon extraction from IconFilePath fails.
                $Saved = $false
            }
        }
        # Fallback: try extracting the icon from the shortcut target file.
        if (-not $Saved -and (Test-String -IsPopulated $TargetPath) -and (Test-Path -LiteralPath $TargetPath -PathType Leaf)) {
            try {
                [System.Drawing.Icon]::ExtractAssociatedIcon($TargetPath).ToBitmap().Save($OutputFilePath)
                $Saved = $true
            }
            catch {
                # Leave Saved as false so a warning is emitted below.
                $Saved = $false
            }
        }
        # Report a warning when both extraction attempts fail.
        if (-not $Saved) {
            Write-Line "The $Extension file could not be extracted from IconFilePath or TargetPath." -Type Warning
            return
        }

        # POST-EXECUTION
        # Report success and optionally open the output folder.
        Write-Line "Shortcut image exported to the following file: $OutputFilePath"
        if ($OpenOutputFolder) {
            Open-Folder -Path $OutputFolder
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
    Writes shortcut information for a shortcut file or folder to the host.
.DESCRIPTION
    This function reads shortcut information from a supplied path.
    If the path is a shortcut file, that item is processed.
    If the path is a folder, all shortcut files (*.lnk and *.url) in that folder (recursive) are processed.
    All output is written to the host.
.EXAMPLE
    Write-ShortcutInformation -Path 'C:\Users\Public\Desktop\MyApp.lnk'
.EXAMPLE
    Write-ShortcutInformation -Path 'C:\Users\Public\Desktop'
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
function Write-ShortcutInformation {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The shortcut file or folder path to inspect.')]
        [AllowEmptyString()]
        [System.String]$Path
    )

    # PREPARATION
    # Define a variable for the WScript.Shell COM object, which will be created only if at least one .lnk file needs to be processed
    [System.Object]$WScriptShell = $null

    try {
        # PREPARATION
        # Input
        [System.String]$InputPath = $Path

        # VALIDATION
        # Validate the input string
        if (Test-String -IsEmpty $InputPath) { Write-Line 'The Path string is empty.' -Type Fail ; return }
        # Validate the path
        if (-not (Test-Path -LiteralPath $InputPath)) { Write-Line "The supplied path could not be reached. ($InputPath)" -Type Fail ; return }

        # PREPARATION
        # Resolve the path and collect shortcut files
        [System.IO.FileSystemInfo]$SelectedItem = Get-Item -LiteralPath $InputPath -ErrorAction Stop
        [System.IO.FileInfo[]]$ShortcutFiles = @()

        if ($SelectedItem.PSIsContainer) {
            Write-Line "Reading shortcut information from folder... ($($SelectedItem.FullName))"
            $ShortcutFiles = Get-ChildItem -LiteralPath $SelectedItem.FullName -Recurse -File -ErrorAction SilentlyContinue |
            Where-Object { @('.lnk','.url') -contains $_.Extension.ToLowerInvariant() }
        }
        else {
            if (@('.lnk','.url') -notcontains $SelectedItem.Extension.ToLowerInvariant()) {
                Write-Line "The selected file is not a supported shortcut type (*.lnk or *.url). ($($SelectedItem.FullName))" -Type Fail
                return
            }
            $ShortcutFiles = @($SelectedItem)
        }

        if ($ShortcutFiles.Count -eq 0) {
            Write-Line "No shortcut files were found in the supplied path. ($InputPath)" -Type Warning
            return
        }

        # PREPARATION
        # Create the COM object only when at least one .lnk needs to be processed
        if (($ShortcutFiles | Where-Object { $_.Extension.ToLowerInvariant() -eq '.lnk' }).Count -gt 0) {
            $WScriptShell = New-Object -ComObject WScript.Shell
        }

        # EXECUTION
        # Write information for each shortcut
        foreach ($ShortcutFile in $ShortcutFiles | Sort-Object FullName) {
            Write-Line ''
            Write-Line "Shortcut Path       : $($ShortcutFile.FullName)" -Type Special
            Write-Line "Shortcut Name       : $($ShortcutFile.BaseName)"
            Write-Line "Shortcut Extension  : $($ShortcutFile.Extension)"
            Write-Line "Last Write Time     : $($ShortcutFile.LastWriteTime)"

            switch ($ShortcutFile.Extension.ToLowerInvariant()) {
                '.lnk' {
                    [System.Object]$ShellShortcut = $WScriptShell.CreateShortcut($ShortcutFile.FullName)
                    Write-Line 'Shortcut Type       : Shell Shortcut (*.lnk)'
                    Write-Line "Target Path         : $($ShellShortcut.TargetPath)"
                    Write-Line "Arguments           : $($ShellShortcut.Arguments)"
                    Write-Line "Working Directory   : $($ShellShortcut.WorkingDirectory)"
                    Write-Line "Description         : $($ShellShortcut.Description)"
                    Write-Line "HotKey              : $($ShellShortcut.Hotkey)"
                    Write-Line "Icon Location       : $($ShellShortcut.IconLocation)"
                    Write-Line "Window Style        : $($ShellShortcut.WindowStyle)"
                }
                '.url' {
                    Write-Line 'Shortcut Type       : Internet Shortcut (*.url)'
                    [System.String[]]$ShortcutContent = Get-Content -LiteralPath $ShortcutFile.FullName -ErrorAction SilentlyContinue
                    [System.Collections.Hashtable]$InternetShortcutInformation = @{}

                    foreach ($ContentLine in $ShortcutContent) {
                        if ($ContentLine -match '^\s*([^=]+)=(.*)$') {
                            $InternetShortcutInformation[$Matches[1].Trim()] = $Matches[2].Trim()
                        }
                    }

                    if ($InternetShortcutInformation.Count -eq 0) {
                        Write-Line 'No key/value information was found in this internet shortcut.' -Type Warning
                    }
                    else {
                        foreach ($Key in $InternetShortcutInformation.Keys | Sort-Object) {
                            Write-Line ("{0,-20}: {1}" -f $Key, $InternetShortcutInformation[$Key])
                        }
                    }
                }
            }
        }
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
    finally {
        if ($null -ne $WScriptShell -and [System.Runtime.InteropServices.Marshal]::IsComObject($WScriptShell)) {
            [void][System.Runtime.InteropServices.Marshal]::ReleaseComObject($WScriptShell)
        }
    }
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Exports shortcut details from a shortcut file or folder to a text report.
.DESCRIPTION
    This function reads shortcut information from a supplied path.
    If the path is a shortcut file, only that item is exported.
    If the path is a folder, all shortcut files (*.lnk and *.url) in that folder (recursive) are exported.
    The output is written to a text file inside a dedicated export folder.
    It also exports shortcut icons to PNG files in the same folder.
.EXAMPLE
    Export-ShortcutInformation -Path 'C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Acrobat Reader.lnk'
.EXAMPLE
    Export-ShortcutInformation -Path 'C:\Users\MyName\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Accessories' -OpenOutputFolder
.INPUTS
    [System.String]
.OUTPUTS
    No objects are returned to the pipeline. All output is written to the host.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. All rights reserved.
    Version         : 6.0.0.0
    Author          : Imraan Iotana
    Creation Date   : August 2025
    Last Update     : June 2026
#>
####################################################################################################
function Export-ShortcutInformation {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The shortcut file or folder path to export.')]
        [AllowEmptyString()]
        [System.String]$Path,

        [Parameter(Mandatory=$false,HelpMessage='Destination folder where the export output will be created.')]
        [Alias('OutputFolder')]
        [System.String]$ParentOutputFolder = (Get-OutputFolder),

        [Parameter(Mandatory=$false,HelpMessage='Open the output folder after export.')]
        [System.Management.Automation.SwitchParameter]$OpenOutputFolder
    )

    [System.Object]$WScriptShell = $null

    try {
        # PREPARATION
        # Input
        [System.String]$InputPath = $Path
        [System.String]$OutputRootFolder = $ParentOutputFolder
        [System.String]$SystemStartMenuFolder = Join-Path -Path $env:ProgramData -ChildPath 'Microsoft\Windows\Start Menu\Programs'
        [System.String]$UserStartMenuFolder = Join-Path -Path $env:APPDATA -ChildPath 'Microsoft\Windows\Start Menu\Programs'

        # VALIDATION
        # Validate input strings and paths
        if (Test-String -IsEmpty $InputPath) { Write-Line 'The Path string is empty.' -Type Fail ; return }
        if (-not (Test-Path -LiteralPath $InputPath)) { Write-Line "The supplied path could not be reached. ($InputPath)" -Type Fail ; return }
        if (Test-String -IsEmpty $OutputRootFolder) { throw 'The output folder is empty.' }
        if (-not (Test-Path -Path $OutputRootFolder)) { New-Item -Path $OutputRootFolder -ItemType Directory -Force | Out-Null }

        # PREPARATION
        # Resolve input path and output file paths
        [System.IO.FileSystemInfo]$SelectedItem = Get-Item -LiteralPath $InputPath -ErrorAction Stop
        [System.String]$ItemBaseName = if ($SelectedItem.PSIsContainer) { $SelectedItem.Name } else { $SelectedItem.BaseName }
        [System.String]$ActualOutputFolder = Join-Path -Path $OutputRootFolder -ChildPath ("Shortcuts - $ItemBaseName")
        if (-not (Test-Path -Path $ActualOutputFolder)) { New-Item -Path $ActualOutputFolder -ItemType Directory -Force | Out-Null }

        [System.String]$OutputFilePath = Join-Path -Path $ActualOutputFolder -ChildPath ("_Shortcut Properties - $ItemBaseName.txt")
        if (Test-Path -LiteralPath $OutputFilePath) { Remove-Item -LiteralPath $OutputFilePath -Force }

        # Collect shortcut files
        [System.IO.FileInfo[]]$ShortcutFiles = @()
        if ($SelectedItem.PSIsContainer) {
            $ShortcutFiles = Get-ChildItem -LiteralPath $SelectedItem.FullName -Recurse -File -ErrorAction SilentlyContinue |
            Where-Object { @('.lnk','.url') -contains $_.Extension.ToLowerInvariant() }
        }
        else {
            if (@('.lnk','.url') -notcontains $SelectedItem.Extension.ToLowerInvariant()) {
                Write-Line "The selected file is not a supported shortcut type (*.lnk or *.url). ($($SelectedItem.FullName))" -Type Fail
                return
            }
            $ShortcutFiles = @($SelectedItem)
        }

        if ($ShortcutFiles.Count -eq 0) {
            Write-Line "No shortcut files were found in the supplied path. ($InputPath)" -Type Warning
            return
        }

        # Create a COM object only when .lnk files are present
        if (($ShortcutFiles | Where-Object { $_.Extension.ToLowerInvariant() -eq '.lnk' }).Count -gt 0) {
            $WScriptShell = New-Object -ComObject WScript.Shell
        }

        # EXECUTION - HEADER
        # Write header
        [System.String[]]$HeaderLines = @(
            '******************************',
            '*',
            "* Shortcut Properties - $ItemBaseName",
            '*',
            "* Generated on: [$(Get-TimeStamp -ForHost)]",
            "* Generated by: $env:UserName",
            '*',
            '******************************',
            '',
            '******************************',
            '* The Shortcuts are formatted in the following way, to make it easier to copy/paste the information into a table.',
            '******************************',
            'BaseName',
            'TargetPath',
            'WorkingDirectory',
            'Arguments',
            'StartMenuLocation',
            'IconFilePath',
            '',
            ''
        )
        Set-Content -Path $OutputFilePath -Value $HeaderLines -Encoding UTF8

        # EXECUTION - BODY (SHORTCUTS)
        # Write one section per shortcut
        [System.Int32]$ShortcutIndex = 0
        foreach ($ShortcutFile in $ShortcutFiles | Sort-Object FullName) {
            $ShortcutIndex++
            [System.String]$ShortcutPath = $ShortcutFile.FullName

            # Build a compact Start Menu-relative location string for table export.
            [System.String]$StartMenuLocationShort = ''
            if ($ShortcutPath.StartsWith($SystemStartMenuFolder,[System.StringComparison]::OrdinalIgnoreCase)) {
                $StartMenuLocationShort = "[SYSTEM]$($ShortcutPath.Substring($SystemStartMenuFolder.Length))"
            }
            elseif ($ShortcutPath.StartsWith($UserStartMenuFolder,[System.StringComparison]::OrdinalIgnoreCase)) {
                $StartMenuLocationShort = "[USER]$($ShortcutPath.Substring($UserStartMenuFolder.Length))"
            }

            # Normalize all Start Menu roots to [ROOT] for consistent export output.
            if (Test-String -IsPopulated $StartMenuLocationShort) {
                $StartMenuLocationShort = $StartMenuLocationShort -replace '^\[(SYSTEM|USER)\]', '[STARMENUROOT]'
            }

            [System.String]$TargetPath = ''
            [System.String]$WorkingDirectory = ''
            [System.String]$Arguments = ''
            [System.String]$IconFilePath = ''

            # Resolve shortcut details depending on shortcut file type.
            if ($ShortcutFile.Extension.ToLowerInvariant() -eq '.lnk') {
                [System.Object]$ShellShortcut = $WScriptShell.CreateShortcut($ShortcutPath)
                $TargetPath = [System.String]$ShellShortcut.TargetPath
                $WorkingDirectory = [System.String]$ShellShortcut.WorkingDirectory
                $Arguments = [System.String]$ShellShortcut.Arguments

                [System.String]$IconLocation = [System.String]$ShellShortcut.IconLocation
                if (Test-String -IsPopulated $IconLocation) {
                    $IconFilePath = ($IconLocation -split ',')[0].Trim('"')
                }
            }
            else {
                [System.String[]]$ShortcutContent = Get-Content -LiteralPath $ShortcutPath -ErrorAction SilentlyContinue
                [System.Collections.Hashtable]$InternetShortcutInformation = @{}

                foreach ($ContentLine in $ShortcutContent) {
                    if ($ContentLine -match '^\s*([^=]+)=(.*)$') {
                        $InternetShortcutInformation[$Matches[1].Trim()] = $Matches[2].Trim()
                    }
                }

                if ($InternetShortcutInformation.ContainsKey('URL')) { $TargetPath = [System.String]$InternetShortcutInformation.URL }
                if ($InternetShortcutInformation.ContainsKey('IconFile')) { $IconFilePath = [System.String]$InternetShortcutInformation.IconFile }
            }

            # Keep body rows value-only to make copy/paste into tables easy.
            [System.String[]]$ShortcutLines = @(
                '******************************',
                "* Shortcut $ShortcutIndex of $($ShortcutFiles.Count)",
                '******************************',
                "$($ShortcutFile.BaseName)",
                "$TargetPath",
                "$WorkingDirectory",
                "$Arguments",
                "$StartMenuLocationShort",
                "$IconFilePath",
                '******************************',
                ''
            )
            Add-Content -Path $OutputFilePath -Value $ShortcutLines -Encoding UTF8

            # Export icon image to the same output folder as the text report.
            [PSCustomObject]$ShortcutImageProperties = [PSCustomObject]@{
                BaseName     = $ShortcutFile.BaseName
                IconFilePath = $IconFilePath
                TargetPath   = $TargetPath
            }
            Export-ShortcutImage -InputObject $ShortcutImageProperties -OutputFolder $ActualOutputFolder -PNG
            Export-ShortcutImage -InputObject $ShortcutImageProperties -OutputFolder $ActualOutputFolder -ICO
        }

        # EXECUTION - FOOTER
        # Write footer
        [System.String[]]$FooterLines = @(
            '******************************',
            '*',
            '* End of file',
            '*',
            '******************************'
        )
        Add-Content -Path $OutputFilePath -Value $FooterLines -Encoding UTF8

        # Write a final message to the host indicating where the output was saved
        Write-Line "Shortcut information exported to the following file: $OutputFilePath"

        # POST-EXECUTION
        if ($OpenOutputFolder) {
            Open-Folder -Path $ActualOutputFolder
        }
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
    finally {
        if ($null -ne $WScriptShell -and [System.Runtime.InteropServices.Marshal]::IsComObject($WScriptShell)) {
            [void][System.Runtime.InteropServices.Marshal]::ReleaseComObject($WScriptShell)
        }
    }
}

### END OF FUNCTION
####################################################################################################


