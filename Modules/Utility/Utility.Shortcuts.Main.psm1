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
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.3
    Author          : Imraan Iotana
    Creation Date   : May 2026
    Last Update     : July 2026
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

    # PREPARATION
    # Define allowed shortcut file extensions based on the IncludeInternetShortcuts switch
    [System.String[]]$AllowedExtensions = @('.lnk')
    if ($IncludeInternetShortcuts) { $AllowedExtensions += '.url' }

    # EXECUTION
    # Enumerate shortcuts from all available roots
    [PSCustomObject[]]$Shortcuts = foreach ($ShortcutRoot in $ShortcutRoots) {
        if ([System.String]::IsNullOrWhiteSpace($ShortcutRoot.Path)) { continue }
        if (-not (Test-Path -LiteralPath $ShortcutRoot.Path -PathType Container)) { continue }

        # Enumerate supported shortcuts once per root, then derive folder and file entries from that set
        [System.IO.FileInfo[]]$AllShortcutFiles = Get-ChildItem -LiteralPath $ShortcutRoot.Path -Recurse -File -ErrorAction SilentlyContinue |
        Where-Object { $AllowedExtensions -contains $_.Extension.ToLowerInvariant() }

        # Top-level folders that contain at least one supported shortcut anywhere below them
        [System.Collections.Specialized.OrderedDictionary]$TopLevelFolders = [ordered]@{}
        foreach ($ShortcutFile in $AllShortcutFiles) {
            if ([System.String]::Equals($ShortcutFile.DirectoryName,$ShortcutRoot.Path,[System.StringComparison]::OrdinalIgnoreCase)) {
                continue
            }

            [System.String]$RelativePath = $ShortcutFile.FullName.Substring($ShortcutRoot.Path.Length).TrimStart('\\')
            if (Test-String -IsEmpty $RelativePath) { continue }

            [System.String]$TopLevelFolderName = ($RelativePath -split '\\')[0]
            if (Test-String -IsPopulated $TopLevelFolderName) {
                $TopLevelFolders[$TopLevelFolderName] = $true
            }
        }

        # Enumerate top-level folders that contain at least one supported shortcut anywhere below them
        foreach ($TopLevelFolderName in ($TopLevelFolders.Keys | Sort-Object)) {
            [System.String]$TopLevelFolderPath = Join-Path -Path $ShortcutRoot.Path -ChildPath $TopLevelFolderName
            if (-not (Test-Path -LiteralPath $TopLevelFolderPath -PathType Container)) { continue }

            [System.IO.DirectoryInfo]$TopLevelFolder = Get-Item -LiteralPath $TopLevelFolderPath -ErrorAction SilentlyContinue
            if ($null -eq $TopLevelFolder) { continue }

            [PSCustomObject]@{
                Name            = $TopLevelFolder.Name
                Extension       = ''
                FullPath        = $TopLevelFolder.FullName
                FolderPath      = $TopLevelFolder.Parent.FullName
                Prefix          = $ShortcutRoot.Prefix
                SourceLocation  = $ShortcutRoot.Location
                RegistryPath    = $TopLevelFolder.FullName
                Type            = 'Folder'
                ComboBoxName    = "[$($ShortcutRoot.Prefix)] $($TopLevelFolder.Name)"
            }
        }

        # Shortcut files in the root only (not recursive)
        $AllShortcutFiles |
        Where-Object { $_ -and [System.String]::Equals($_.DirectoryName,$ShortcutRoot.Path,[System.StringComparison]::OrdinalIgnoreCase) } |
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
    Resolves a shortcut input source into a concrete path.
.DESCRIPTION
    Accepts a direct path, a shortcut item, or a shortcut ComboBox and returns the resolved FullPath.
.EXAMPLE
    Resolve-ShortcutInputPath -ShortcutComboBox (Get-ComboBoxObject -ComboBoxName 'SelectShortcutFolder')
.INPUTS
    [System.String]
    [System.Object]
    [System.Windows.Forms.ComboBox]
.OUTPUTS
    [System.String]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.3
    Author          : Imraan Iotana
    Creation Date   : July 2026
    Last Update     : July 2026
#>
####################################################################################################
function Resolve-ShortcutInputPath {
    [CmdletBinding(DefaultParameterSetName='ByPath')]
    [OutputType([System.String])]
    param (
        [Parameter(Mandatory=$true,ParameterSetName='ByPath',HelpMessage='The shortcut file or folder path.')]
        [ValidateNotNullOrEmpty()]
        [System.String]$Path,

        [Parameter(Mandatory=$true,ParameterSetName='ByShortcutItem',HelpMessage='Shortcut item that contains the FullPath property.')]
        [System.Object]$ShortcutItem,

        [Parameter(Mandatory=$true,ParameterSetName='ByComboBox',HelpMessage='Shortcut ComboBox; the SelectedItem.FullPath value will be resolved.')]
        [System.Windows.Forms.ComboBox]$ShortcutComboBox,

        [Parameter(Mandatory=$false,HelpMessage='Write host messages when invalid input is encountered.')]
        [System.Management.Automation.SwitchParameter]$WriteMessages
    )

    # PREPARATION
    # Resolve the effective input path from the active parameter set.
    [System.String]$InputPath = $null
    switch ($PSCmdlet.ParameterSetName) {
        'ByPath' {
            $InputPath = [System.String]$Path
        }
        'ByShortcutItem' {
            if ($null -eq $ShortcutItem) {
                if ($WriteMessages) { Write-Line 'No shortcut is selected. Skipping shortcut operation.' -Type Warning }
                return $null
            }

            # Accept direct string inputs and object-based inputs.
            if ($ShortcutItem -is [System.String]) {
                $InputPath = [System.String]$ShortcutItem
            }
            elseif ($null -ne $ShortcutItem.PSObject.Properties['FullPath']) {
                $InputPath = [System.String]$ShortcutItem.FullPath
            }
            elseif ($null -ne $ShortcutItem.PSObject.Properties['RegistryPath']) {
                $InputPath = [System.String]$ShortcutItem.RegistryPath
            }
        }
        'ByComboBox' {
            if ($null -eq $ShortcutComboBox) {
                if ($WriteMessages) { Write-Line 'No shortcut is selected. Skipping shortcut operation.' -Type Warning }
                return $null
            }

            # Prefer SelectedItem metadata, then fall back to SelectedValue when available.
            if ($null -ne $ShortcutComboBox.SelectedItem) {
                if ($ShortcutComboBox.SelectedItem -is [System.String]) {
                    $InputPath = [System.String]$ShortcutComboBox.SelectedItem
                }
                elseif ($null -ne $ShortcutComboBox.SelectedItem.PSObject.Properties['FullPath']) {
                    $InputPath = [System.String]$ShortcutComboBox.SelectedItem.FullPath
                }
                elseif ($null -ne $ShortcutComboBox.SelectedItem.PSObject.Properties['RegistryPath']) {
                    $InputPath = [System.String]$ShortcutComboBox.SelectedItem.RegistryPath
                }
            }

            if ((Test-String -IsEmpty $InputPath) -and $null -ne $ShortcutComboBox.SelectedValue) {
                $InputPath = [System.String]$ShortcutComboBox.SelectedValue
            }
        }
    }

    # VALIDATION
    # Validate the resolved input path string
    if (Test-String -IsEmpty $InputPath) {
        if ($WriteMessages) { Write-Line 'The selected shortcut does not contain a valid path. Skipping shortcut operation.' -Type Warning }
        return $null
    }

    # POST-EXECUTION
    # Return the resolved input path
    return $InputPath
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Resolves supported shortcut files from a shortcut file or folder path.
.DESCRIPTION
    Returns all supported shortcut files (*.lnk, *.url) from the supplied path.
    For a folder path, files are collected recursively.
.EXAMPLE
    Resolve-ShortcutFilesFromPath -Path 'C:\Users\Public\Desktop'
.INPUTS
    [System.String]
.OUTPUTS
    [System.IO.FileInfo[]]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.3
    Author          : Imraan Iotana
    Creation Date   : July 2026
    Last Update     : July 2026
#>
####################################################################################################
function Resolve-ShortcutFilesFromPath {
    [CmdletBinding()]
    [OutputType([System.IO.FileInfo[]])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The shortcut file or folder path to inspect.')]
        [System.String]$Path,

        [Parameter(Mandatory=$false,HelpMessage='Supported file extensions to include.')]
        [System.String[]]$SupportedExtensions = @('.lnk','.url'),

        [Parameter(Mandatory=$false,HelpMessage='Write host messages when validation fails.')]
        [System.Management.Automation.SwitchParameter]$WriteMessages
    )

    try {
        # VALIDATION
        # Validate the supplied path string and existence
        if (Test-String -IsEmpty $Path) {
            if ($WriteMessages) { Write-Line 'The Path string is empty.' -Type Fail }
            return @()
        }

        if (-not (Test-Path -LiteralPath $Path)) {
            if ($WriteMessages) { Write-Line "The supplied path could not be reached. ($Path)" -Type Fail }
            return @()
        }

        # PREPARATION
        # Resolve the supplied path to a file system item
        [System.IO.FileSystemInfo]$SelectedItem = Get-Item -LiteralPath $Path -ErrorAction Stop

        # EXECUTION
        # Collect supported shortcut files recursively when a folder is supplied
        if ($SelectedItem.PSIsContainer) {
            return (Get-ChildItem -LiteralPath $SelectedItem.FullName -Recurse -File -ErrorAction SilentlyContinue |
                Where-Object { $SupportedExtensions -contains $_.Extension.ToLowerInvariant() })
        }

        # VALIDATION
        # Ensure a file input has a supported shortcut extension
        [System.String]$SelectedExtension = $SelectedItem.Extension.ToLowerInvariant()
        if ($SupportedExtensions -notcontains $SelectedExtension) {
            if ($WriteMessages) {
                Write-Line "The selected file is not a supported shortcut type (*.lnk or *.url). ($($SelectedItem.FullName))" -Type Fail
            }
            return @()
        }

        # POST-EXECUTION
        # Return the single supported shortcut file
        return @($SelectedItem)
    }
    catch {
        if ($WriteMessages) { Write-ErrorReport -ErrorRecord $_ }
        return @()
    }
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Retrieves properties of a shortcut file (.lnk or .url).
.DESCRIPTION
    This function reads properties from a shortcut file and returns a unified custom object.
    If the file is a shell shortcut (.lnk), it reads the target path, working directory,
    arguments, description, hotkey, icon location, window style, and extracts the icon file path.
    If the file is an internet shortcut (.url), it reads the URL and icon file.
.EXAMPLE
    Get-ShortcutProperties -ShortcutFile (Get-Item 'C:\Demo\Acrobat.lnk')
.INPUTS
    [System.IO.FileInfo]
.OUTPUTS
    [PSCustomObject]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.3
    Author          : Imraan Iotana
    Creation Date   : June 2026
    Last Update     : July 2026
#>
####################################################################################################
function Get-ShortcutProperties {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The shortcut file to inspect.')]
        [System.IO.FileInfo]$ShortcutFile,

        [Parameter(Mandatory=$false,HelpMessage='An optional WScript.Shell COM object to reuse.')]
        [System.Object]$WScriptShell
    )

    # PREPARATION
    # Set the shortcut file extension and initialize the COM object flag
    [System.String]$Extension = $ShortcutFile.Extension.ToLowerInvariant()
    [System.Object]$Shell = $WScriptShell
    [System.Boolean]$CreatedCom = $false

    try {
        # PREPARATION
        # Resolve shortcut details based on shortcut file extension type.
        if ($Extension -eq '.lnk') {
            if ($null -eq $Shell) {
                $Shell = New-Object -ComObject WScript.Shell
                $CreatedCom = $true
            }
            [System.Object]$ShellShortcut = $Shell.CreateShortcut($ShortcutFile.FullName)

            # PREPARATION
            # Read icon metadata and derive the icon file path when IconLocation is set.
            [System.String]$IconFilePath = ''
            [System.String]$IconLocation = [System.String]$ShellShortcut.IconLocation
            [System.String]$TargetPath = [System.String]$ShellShortcut.TargetPath

            # PREPARATION
            # Resolve the icon file path from the IconLocation property, falling back to the TargetPath when necessary.
            if (Test-String -IsPopulated $IconLocation) {
                # Extract icon file path, stripping away comma/index separator if present.
                $IconFilePath = ($IconLocation -split ',')[0].Trim('"')

                # FALLBACK
                # Keep IconFilePath populated for metadata when IconLocation resolves to an empty value.
                if ((Test-String -IsEmpty $IconFilePath) -and (Test-String -IsPopulated $TargetPath)) {
                    $IconFilePath = $TargetPath
                }
            }
            elseif (Test-String -IsPopulated $TargetPath) {
                # FALLBACK
                # Keep IconFilePath populated for metadata when IconLocation is empty.
                $IconFilePath = $TargetPath
            }

            # OUTPUT
            # Return normalized shell shortcut properties.
            return [PSCustomObject]@{
                Name             = $ShortcutFile.BaseName
                Extension        = '.lnk'
                Type             = 'Shell Shortcut (*.lnk)'
                TargetPath       = $TargetPath
                WorkingDirectory = [System.String]$ShellShortcut.WorkingDirectory
                Arguments        = [System.String]$ShellShortcut.Arguments
                Description      = [System.String]$ShellShortcut.Description
                Hotkey           = [System.String]$ShellShortcut.Hotkey
                IconLocation     = [System.String]$ShellShortcut.IconLocation
                WindowStyle      = [System.String]$ShellShortcut.WindowStyle
                IconFilePath     = $IconFilePath
            }
        }
        elseif ($Extension -eq '.url') {
            # PREPARATION
            # Parse internet shortcut key/value content from the .url file.
            [System.String[]]$ShortcutContent = Get-Content -LiteralPath $ShortcutFile.FullName -ErrorAction SilentlyContinue
            [System.Collections.Hashtable]$InternetShortcutInformation = @{}

            foreach ($ContentLine in $ShortcutContent) {
                if ($ContentLine -match '^\s*([^=]+)=(.*)$') {
                    $InternetShortcutInformation[$Matches[1].Trim()] = $Matches[2].Trim()
                }
            }

            [System.String]$TargetPath = ''
            [System.String]$IconFilePath = ''
            if ($InternetShortcutInformation.ContainsKey('URL')) { $TargetPath = [System.String]$InternetShortcutInformation.URL }
            if ($InternetShortcutInformation.ContainsKey('IconFile')) { $IconFilePath = [System.String]$InternetShortcutInformation.IconFile }

            # OUTPUT
            # Return normalized internet shortcut properties.
            return [PSCustomObject]@{
                Name             = $ShortcutFile.BaseName
                Extension        = '.url'
                Type             = 'Internet Shortcut (*.url)'
                TargetPath       = $TargetPath
                WorkingDirectory = ''
                Arguments        = ''
                Description      = ''
                Hotkey           = ''
                IconLocation     = ''
                WindowStyle      = ''
                IconFilePath     = $IconFilePath
                InternetShortcutInformation = $InternetShortcutInformation
            }
        }
    }
    finally {
        # POST-EXECUTION
        # Release COM object only when this function created it.
        if ($CreatedCom -and $null -ne $Shell -and [System.Runtime.InteropServices.Marshal]::IsComObject($Shell)) {
            [void][System.Runtime.InteropServices.Marshal]::ReleaseComObject($Shell)
        }
    }

    return $null
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Collects shortcut details as JSON-friendly objects for export and metadata workflows.
.DESCRIPTION
    Resolves a shortcut input (path, shortcut item, or shortcut ComboBox selection), scans supported
    shortcut files (*.lnk, *.url), and returns a normalized object array with key fields.
.EXAMPLE
    Get-ShortcutInformationCollection -Path 'C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Acrobat Reader.lnk'
.EXAMPLE
    Get-ShortcutInformationCollection -ShortcutComboBox (Get-ComboBoxObject -ComboBoxName 'SelectShortcutFolder')
.INPUTS
    [System.String]
    [System.Object]
    [System.Windows.Forms.ComboBox]
.OUTPUTS
    [PSCustomObject[]]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.3
    Author          : Imraan Iotana
    Creation Date   : July 2026
    Last Update     : July 2026
#>
####################################################################################################
function Get-ShortcutInformationCollection {
    [CmdletBinding(DefaultParameterSetName='ByPath')]
    [OutputType([PSCustomObject[]])]
    param (
        [Parameter(Mandatory=$true,ParameterSetName='ByPath',HelpMessage='The shortcut file or folder path to inspect.')]
        [ValidateNotNullOrEmpty()]
        [System.String]$Path,

        [Parameter(Mandatory=$true,ParameterSetName='ByShortcutItem',HelpMessage='Shortcut item that contains the FullPath property.')]
        [System.Object]$ShortcutItem,

        [Parameter(Mandatory=$true,ParameterSetName='ByComboBox',HelpMessage='Shortcut ComboBox; the SelectedItem.FullPath value will be inspected.')]
        [System.Windows.Forms.ComboBox]$ShortcutComboBox,

        [Parameter(Mandatory=$false,HelpMessage='Write host messages when validation fails.')]
        [System.Management.Automation.SwitchParameter]$WriteMessages
    )

    [System.Object]$WScriptShell = $null
    [System.String[]]$SupportedExtensions = @('.lnk','.url')
    [System.String]$SystemStartMenuFolder = Join-Path -Path $env:ProgramData -ChildPath 'Microsoft\Windows\Start Menu\Programs'
    [System.String]$UserStartMenuFolder = Join-Path -Path $env:APPDATA -ChildPath 'Microsoft\Windows\Start Menu\Programs'

    try {
        # PREPARATION
        # Resolve and validate the effective input path
        [System.String]$InputPath = Resolve-ShortcutInputPath @PSBoundParameters
        if (Test-String -IsEmpty $InputPath) { return @() }

        # PREPARATION
        # Resolve supported shortcut files from the input path
        [System.IO.FileInfo[]]$ShortcutFiles = Resolve-ShortcutFilesFromPath -Path $InputPath -SupportedExtensions $SupportedExtensions -WriteMessages:$WriteMessages

        if ($ShortcutFiles.Count -eq 0) {
            if ($WriteMessages) { Write-Line "No shortcut files were found in the supplied path. ($InputPath)" -Type Warning }
            return @()
        }

        # PREPARATION
        # Create a reusable COM object only when .lnk files are present
        if (($ShortcutFiles | Where-Object { $_.Extension.ToLowerInvariant() -eq '.lnk' }).Count -gt 0) {
            $WScriptShell = New-Object -ComObject WScript.Shell
        }

        # EXECUTION
        # Build normalized shortcut entries for metadata and export consumers
        [System.Collections.Generic.List[System.Object]]$ShortcutEntries = @()
        foreach ($ShortcutFile in ($ShortcutFiles | Sort-Object FullName)) {
            [PSCustomObject]$Props = Get-ShortcutProperties -ShortcutFile $ShortcutFile -WScriptShell $WScriptShell
            if ($null -eq $Props) { continue }

            [System.String]$StartMenuLocationShort = ''
            if ($ShortcutFile.FullName.StartsWith($SystemStartMenuFolder,[System.StringComparison]::OrdinalIgnoreCase)) {
                $StartMenuLocationShort = "[SYSTEM]$($ShortcutFile.FullName.Substring($SystemStartMenuFolder.Length))"
            }
            elseif ($ShortcutFile.FullName.StartsWith($UserStartMenuFolder,[System.StringComparison]::OrdinalIgnoreCase)) {
                $StartMenuLocationShort = "[USER]$($ShortcutFile.FullName.Substring($UserStartMenuFolder.Length))"
            }
            if (Test-String -IsPopulated $StartMenuLocationShort) {
                $StartMenuLocationShort = $StartMenuLocationShort -replace '^\[(SYSTEM|USER)\]', '[STARTMENUROOT]'
            }

            $ShortcutEntries.Add([PSCustomObject]@{
                BaseName          = $ShortcutFile.BaseName
                Extension         = $ShortcutFile.Extension
                FullPath          = $ShortcutFile.FullName
                ShortcutType      = $Props.Type
                TargetPath        = $Props.TargetPath
                WorkingDirectory  = $Props.WorkingDirectory
                Arguments         = $Props.Arguments
                StartMenuLocation = $StartMenuLocationShort
                IconFilePath      = $Props.IconFilePath
            })
        }

        # POST-EXECUTION
        # Return the collected shortcut entry objects
        return $ShortcutEntries
    }
    catch {
        if ($WriteMessages) { Write-ErrorReport -ErrorRecord $_ }
        return @()
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
    Writes shortcut information for a shortcut file or folder to the host.
.DESCRIPTION
    This function reads shortcut information from a supplied path.
    If the path is a shortcut file, that item is processed.
    If the path is a folder, all shortcut files (*.lnk and *.url) in that folder (recursive) are processed.
    All output is written to the host.
.EXAMPLE
    Write-ShortcutInformationToHost -Path 'C:\Users\Public\Desktop\MyApp.lnk'
.EXAMPLE
    Write-ShortcutInformationToHost -Path 'C:\Users\Public\Desktop'
.INPUTS
    [System.String]
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.3
    Author          : Imraan Iotana
    Creation Date   : June 2026
    Last Update     : July 2026
#>
####################################################################################################
function Write-ShortcutInformationToHost {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The shortcut file or folder path to inspect.')]
        [ValidateNotNullOrEmpty()]
        [System.String]$Path
    )

    [System.Object]$WScriptShell = $null

    try {
        if (Test-Path -LiteralPath $Path -PathType Container) {
            Write-Line "Reading shortcut information from folder... ($Path)"
        }

        [System.IO.FileInfo[]]$ShortcutFiles = Resolve-ShortcutFilesFromPath -Path $Path -WriteMessages
        if ($ShortcutFiles.Count -eq 0) {
            return
        }

        # PREPARATION
        # Create the COM object only when at least one .lnk needs to be processed
        if (($ShortcutFiles | Where-Object { $_.Extension.ToLowerInvariant() -eq '.lnk' }).Count -gt 0) {
            $WScriptShell = New-Object -ComObject WScript.Shell
        }

        # EXECUTION
        # Write information for each shortcut
        foreach ($ShortcutFile in ($ShortcutFiles | Sort-Object FullName)) {
            Write-Line ''
            Write-Line "Shortcut Path       : $($ShortcutFile.FullName)" -Type Special
            Write-Line "Shortcut Name       : $($ShortcutFile.BaseName)"
            Write-Line "Shortcut Extension  : $($ShortcutFile.Extension)"
            Write-Line "Last Write Time     : $($ShortcutFile.LastWriteTime)"

            [PSCustomObject]$Props = Get-ShortcutProperties -ShortcutFile $ShortcutFile -WScriptShell $WScriptShell
            if ($null -eq $Props) { continue }

            Write-Line "Shortcut Type       : $($Props.Type)"
            if ($ShortcutFile.Extension.ToLowerInvariant() -eq '.lnk') {
                Write-Line "Target Path         : $($Props.TargetPath)"
                Write-Line "Arguments           : $($Props.Arguments)"
                Write-Line "Working Directory   : $($Props.WorkingDirectory)"
                Write-Line "Description         : $($Props.Description)"
                Write-Line "HotKey              : $($Props.Hotkey)"
                Write-Line "Icon Location       : $($Props.IconLocation)"
                Write-Line "Window Style        : $($Props.WindowStyle)"
            }
            else {
                if ($null -eq $Props.InternetShortcutInformation -or $Props.InternetShortcutInformation.Count -eq 0) {
                    Write-Line 'No key/value information was found in this internet shortcut.' -Type Warning
                }
                else {
                    foreach ($Key in $Props.InternetShortcutInformation.Keys | Sort-Object) {
                        Write-Line ("{0,-20}: {1}" -f $Key, $Props.InternetShortcutInformation[$Key])
                    }
                }
            }
        }
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
    # POST-EXECUTION
    # Release COM object if created within this function
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
    Creates an application shortcut for the current user.
.DESCRIPTION
    This function creates a shortcut in one of three user locations:
    Start Menu or Desktop.
    It always creates a new launcher shortcut that starts StartAssistant.ps1.
.EXAMPLE
    New-ApplicationShortcut -InputObject $MyApplicationObject -ShortcutType 'Desktop'
.INPUTS
    [PSCustomObject]
    [System.String]
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.3
    Author          : Imraan Iotana
    Creation Date   : July 2026
    Last Update     : July 2026
#>
####################################################################################################
function New-ApplicationShortcut {
    [CmdletBinding()]
    [OutputType([System.Void])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The ApplicationObject containing settings such as RootFolder.')]
        [PSCustomObject]$InputObject,

        [Parameter(Mandatory=$true,HelpMessage='The type of shortcut to create.')]
        [ValidateSet('StartMenu','Startmenu','Desktop')]
        [System.String]$ShortcutType,

        [Parameter(Mandatory=$false,HelpMessage='The displayed name of the created shortcut.')]
        [System.String]$ShortcutName = 'Application Delivery Assistant',

        [Parameter(Mandatory=$false,HelpMessage='Overwrite an existing shortcut with the same name.')]
        [System.Management.Automation.SwitchParameter]$Force
    )

    [System.Object]$WScriptShell = $null
    [System.String]$DestinationShortcutPath = ''

    try {
        # VALIDATION
        # Resolve and validate the repository root
        [System.String]$RootFolder = [System.String]$InputObject.RootFolder
        if (Test-String -IsEmpty $RootFolder) {
            throw 'InputObject.RootFolder is empty. Unable to create the shortcut.'
        }
        if (-not (Test-Path -LiteralPath $RootFolder -PathType Container)) {
            throw "The root folder could not be found. ($RootFolder)"
        }

        # PREPARATION
        # Resolve Desktop path via Windows special folders (supports redirected desktops)
        [System.String]$DesktopFolder = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::Desktop)
        if (Test-String -IsEmpty $DesktopFolder) {
            $DesktopFolder = Join-Path -Path $env:USERPROFILE -ChildPath 'Desktop'
        }

        # PREPARATION
        # Resolve destination folder for the selected shortcut type and create it when missing
        [System.String]$NormalizedShortcutType = if ($ShortcutType -ieq 'Startmenu') { 'StartMenu' } else { $ShortcutType }
        [System.String]$DestinationFolder = switch ($NormalizedShortcutType) {
            'StartMenu' { Join-Path -Path $env:APPDATA -ChildPath 'Microsoft\Windows\Start Menu\Programs' }
            'Desktop' { $DesktopFolder }
        }
        if (-not (Test-Path -LiteralPath $DestinationFolder -PathType Container)) {
            New-Item -Path $DestinationFolder -ItemType Directory -Force | Out-Null
        }

        [System.String]$NormalizedShortcutName = $ShortcutName
        if (Test-String -IsEmpty $NormalizedShortcutName) {
            $NormalizedShortcutName = 'Application Delivery Assistant'
        }
        $NormalizedShortcutName = $NormalizedShortcutName.Trim()
        if (-not $NormalizedShortcutName.EndsWith('.lnk',[System.StringComparison]::OrdinalIgnoreCase)) {
            $NormalizedShortcutName = "$NormalizedShortcutName.lnk"
        }
        $DestinationShortcutPath = Join-Path -Path $DestinationFolder -ChildPath $NormalizedShortcutName

        # CONFIRMATION
        # Ask for creation confirmation when -Force is not specified
        if (-not $Force) {
            [System.String]$CreateTitle = 'Confirm Create Shortcut'
            [System.String]$CreateBody = "Would you like to CREATE the following shortcut?`n`n$DestinationShortcutPath"
            if (-not (Get-UserConfirmation -Title $CreateTitle -Body $CreateBody)) { return }
        }

        # CONFIRMATION
        # Ask for overwrite confirmation when the shortcut already exists and -Force is not specified
        if ((Test-Path -LiteralPath $DestinationShortcutPath -PathType Leaf) -and -not $Force) {
            [System.String]$OverwriteTitle = 'Confirm Overwrite Shortcut'
            [System.String]$OverwriteBody = "The shortcut already exists. Would you like to OVERWRITE it?`n`n$DestinationShortcutPath"
            if (-not (Get-UserConfirmation -Title $OverwriteTitle -Body $OverwriteBody)) { return }
        }

        # PREPARATION
        # Resolve the preferred custom icon
        [System.String]$PreferredIconPath = Join-Path -Path $RootFolder -ChildPath 'Assets\MainFormIcon.ico'
        if (-not (Test-Path -LiteralPath $PreferredIconPath -PathType Leaf)) {
            $PreferredIconPath = Join-Path -Path $RootFolder -ChildPath 'Assets\Other\MainFormIcon.ico'
        }
        [System.String]$ShortcutIconLocation = if (Test-Path -LiteralPath $PreferredIconPath -PathType Leaf) {
            "$PreferredIconPath,0"
        }
        else {
            "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe,0"
        }

        # EXECUTION
        # Create a new launcher shortcut
        [System.String]$StartAssistantPath = Join-Path -Path $RootFolder -ChildPath 'StartAssistant.ps1'
        if (-not (Test-Path -LiteralPath $StartAssistantPath -PathType Leaf)) {
            throw "The StartAssistant.ps1 script could not be found. ($StartAssistantPath)"
        }

        # Create a new shortcut that launches StartAssistant.ps1 with PowerShell
        if ($null -eq $WScriptShell) { $WScriptShell = New-Object -ComObject WScript.Shell }
        [System.Object]$ShellShortcut = $WScriptShell.CreateShortcut($DestinationShortcutPath)
        $ShellShortcut.TargetPath = (Get-Command powershell.exe -ErrorAction Stop).Source
        $ShellShortcut.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$StartAssistantPath`""
        $ShellShortcut.WorkingDirectory = $RootFolder
        $ShellShortcut.Description = 'Start Application Delivery Assistant'
        $ShellShortcut.IconLocation = $ShortcutIconLocation
        $ShellShortcut.Save()

        # POST-EXECUTION
        # Write a success message to the host
        Write-Line "Shortcut created. ($DestinationShortcutPath)" -Type Success
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

