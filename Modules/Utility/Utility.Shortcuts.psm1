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
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. All rights reserved.
    Version         : 6.0.0.0
    Author          : Imraan Iotana
    Creation Date   : June 2026
    Last Update     : June 2026
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

    [System.String]$Extension = $ShortcutFile.Extension.ToLowerInvariant()
    [System.Object]$Shell = $WScriptShell
    [System.Boolean]$CreatedCom = $false

    try {
        if ($Extension -eq '.lnk') {
            if ($null -eq $Shell) {
                $Shell = New-Object -ComObject WScript.Shell
                $CreatedCom = $true
            }
            [System.Object]$ShellShortcut = $Shell.CreateShortcut($ShortcutFile.FullName)

            [System.String]$IconFilePath = ''
            [System.String]$IconLocation = [System.String]$ShellShortcut.IconLocation
            if (Test-String -IsPopulated $IconLocation) {
                # Extract first path element prior to optional comma / icon index
                $IconFilePath = ($IconLocation -split ',')[0].Trim('"')
            }

            return [PSCustomObject]@{
                Name             = $ShortcutFile.BaseName
                Extension        = '.lnk'
                Type             = 'Shell Shortcut (*.lnk)'
                TargetPath       = [System.String]$ShellShortcut.TargetPath
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
    Write-ShortcutInformationToHost -Path 'C:\Users\Public\Desktop\MyApp.lnk'
.EXAMPLE
    Write-ShortcutInformationToHost -Path 'C:\Users\Public\Desktop'
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
function Write-ShortcutInformationToHost {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The shortcut file or folder path to inspect.')]
        [AllowEmptyString()]
        [System.String]$Path
    )

    # PREPARATION
    # Define a variable for the WScript.Shell COM object, which will be created only if at least one .lnk file needs to be processed
    [System.Object]$WScriptShell = $null
    [System.String[]]$SupportedExtensions = @('.lnk','.url')

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
        # Collect all supported shortcut files.
        if ($SelectedItem.PSIsContainer) {
            Write-Line "Reading shortcut information from folder... ($($SelectedItem.FullName))"
            $ShortcutFiles = Get-ChildItem -LiteralPath $SelectedItem.FullName -Recurse -File -ErrorAction SilentlyContinue |
            Where-Object { $SupportedExtensions -contains $_.Extension.ToLowerInvariant() }
        }
        else {
            [System.String]$SelectedExtension = $SelectedItem.Extension.ToLowerInvariant()
            if ($SupportedExtensions -notcontains $SelectedExtension) {
                Write-Line "The selected file is not a supported shortcut type (*.lnk or *.url). ($($SelectedItem.FullName))" -Type Fail
                return
            }
            $ShortcutFiles = @($SelectedItem)
        }
        # Report a warning and exit when no shortcut files are found at the supplied path.
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
    Universal shortcut export function for path-based and UI-based workflows.
.DESCRIPTION
    This function exports shortcut details from either:
    - A direct path (file or folder),
    - A selected shortcut object (with FullPath), or
    - A shortcut ComboBox (using SelectedItem.FullPath).

    It can export to a generic output folder or to an application archive location
    (9. Archive\Shortcuts) when ApplicationFolderPath is supplied.
.EXAMPLE
    Export-UniversalShortcutInformation -Path 'C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Acrobat Reader.lnk'
.EXAMPLE
    Export-UniversalShortcutInformation -ShortcutItem $Global:Graphics.ComboBoxes.ApplicationIntake.ApplicationShortcuts.SelectedItem -OpenOutputFolder
.EXAMPLE
    Export-UniversalShortcutInformation -ApplicationFolderPath 'C:\Temp\Vendor_App_1.0' -ShortcutComboBox $Global:Graphics.ComboBoxes.ApplicationIntake.ApplicationShortcuts -SkipConfirmation
.INPUTS
    [System.String]
    [System.Object]
    [System.Windows.Forms.ComboBox]
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
function Export-UniversalShortcutInformation {
    [CmdletBinding(DefaultParameterSetName='ByPath')]
    param (
        [Parameter(Mandatory=$true,ParameterSetName='ByPath',HelpMessage='The shortcut file or folder path to export.')]
        [AllowEmptyString()]
        [System.String]$Path,

        [Parameter(Mandatory=$true,ParameterSetName='ByShortcutItem',HelpMessage='Shortcut item that contains the FullPath property.')]
        [System.Object]$ShortcutItem,

        [Parameter(Mandatory=$true,ParameterSetName='ByComboBox',HelpMessage='Shortcut ComboBox; the SelectedItem.FullPath value will be exported.')]
        [System.Windows.Forms.ComboBox]$ShortcutComboBox,

        [Parameter(Mandatory=$false,HelpMessage='Destination folder where the export output will be created.')]
        [Alias('OutputFolder')]
        [System.String]$ParentOutputFolder = (Get-OutputFolder),

        [Parameter(Mandatory=$false,HelpMessage='The root folder of the created application package. When supplied, output is written to 9. Archive\\Shortcuts.')]
        [System.String]$ApplicationFolderPath,

        [Parameter(Mandatory=$false,HelpMessage='Open the output folder after export.')]
        [System.Management.Automation.SwitchParameter]$OpenOutputFolder,

        [Parameter(Mandatory=$false,HelpMessage='Skip the confirmation prompt and export immediately.')]
        [System.Management.Automation.SwitchParameter]$SkipConfirmation
    )

    [System.Object]$WScriptShell = $null

    try {
        # PREPARATION
        # Resolve input path from parameter set.
        [System.String]$InputPath = ''
        switch ($PSCmdlet.ParameterSetName) {
            'ByPath' {
                $InputPath = $Path
            }
            'ByShortcutItem' {
                if ($null -eq $ShortcutItem) {
                    Write-Line 'No shortcut is selected. Skipping shortcut information export.' -Type Warning
                    return
                }
                $InputPath = [System.String]$ShortcutItem.FullPath
            }
            'ByComboBox' {
                if ($null -eq $ShortcutComboBox -or $null -eq $ShortcutComboBox.SelectedItem) {
                    Write-Line 'No shortcut is selected. Skipping shortcut information export.' -Type Warning
                    return
                }
                $InputPath = [System.String]$ShortcutComboBox.SelectedItem.FullPath
            }
            default {
                throw "Unsupported parameter set: $($PSCmdlet.ParameterSetName)"
            }
        }

        # CONFIRMATION
        # Ask for confirmation only when -SkipConfirmation is not specified.
        if (-not $SkipConfirmation) {
            [System.String]$Title   = 'Confirm Export Shortcut Information'
            [System.String]$Body    = "Would you like to EXPORT the SHORTCUT information for the following path?:`n`n$InputPath"
            if (-not (Get-UserConfirmation -Title $Title -Body $Body)) { return }
        }

        [System.String]$OutputRootFolder = $ParentOutputFolder
        if (Test-String -IsPopulated $ApplicationFolderPath) {
            if (-not (Test-Path -LiteralPath $ApplicationFolderPath -PathType Container)) {
                throw "The application folder does not exist. ($ApplicationFolderPath)"
            }
            [System.String]$ShortcutsRelativePath = Join-Path -Path '9. Archive' -ChildPath 'Shortcuts'
            $OutputRootFolder = Join-Path -Path $ApplicationFolderPath -ChildPath $ShortcutsRelativePath
        }

        [System.String]$SystemStartMenuFolder = Join-Path -Path $env:ProgramData -ChildPath 'Microsoft\Windows\Start Menu\Programs'
        [System.String]$UserStartMenuFolder = Join-Path -Path $env:APPDATA -ChildPath 'Microsoft\Windows\Start Menu\Programs'

        # VALIDATION
        # Validate resolved input and output paths
        if (Test-String -IsEmpty $InputPath) {
            Write-Line 'The selected shortcut does not contain a valid path. Skipping shortcut information export.' -Type Warning
            return
        }
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
        [System.String[]]$SupportedExtensions = @('.lnk','.url')
        [System.IO.FileInfo[]]$ShortcutFiles = @()
        if ($SelectedItem.PSIsContainer) {
            $ShortcutFiles = Get-ChildItem -LiteralPath $SelectedItem.FullName -Recurse -File -ErrorAction SilentlyContinue |
            Where-Object { $SupportedExtensions -contains $_.Extension.ToLowerInvariant() }
        }
        else {
            if ($SupportedExtensions -notcontains $SelectedItem.Extension.ToLowerInvariant()) {
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
        Set-ShortcutReportHeader -OutputFilePath $OutputFilePath -ItemBaseName $ItemBaseName

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

            [PSCustomObject]$Props = Get-ShortcutProperties -ShortcutFile $ShortcutFile -WScriptShell $WScriptShell
            if ($null -eq $Props) { continue }

            # Keep body rows value-only to make copy/paste into tables easy.
            [System.String[]]$ShortcutLines = @(
                '******************************',
                "* Shortcut $ShortcutIndex of $($ShortcutFiles.Count)",
                '******************************',
                "$($ShortcutFile.BaseName)",
                "$($Props.TargetPath)",
                "$($Props.WorkingDirectory)",
                "$($Props.Arguments)",
                "$StartMenuLocationShort",
                "$($Props.IconFilePath)",
                '******************************',
                ''
            )
            Add-Content -Path $OutputFilePath -Value $ShortcutLines -Encoding UTF8

            # Export icon image to the same output folder as the text report.
            [PSCustomObject]$ShortcutImageProperties = [PSCustomObject]@{
                BaseName     = $ShortcutFile.BaseName
                IconFilePath = $Props.IconFilePath
                TargetPath   = $Props.TargetPath
            }
            Export-ShortcutImage -InputObject $ShortcutImageProperties -OutputFolder $ActualOutputFolder -PNG
            Export-ShortcutImage -InputObject $ShortcutImageProperties -OutputFolder $ActualOutputFolder -ICO
        }

        # EXECUTION - FOOTER
        # Write footer
        Set-ShortcutReportFooter -OutputFilePath $OutputFilePath

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


####################################################################################################
<#
.SYNOPSIS
    Writes the standard header for a shortcut export report file.
.DESCRIPTION
    This function composes and writes the common header lines used by shortcut export reports
    to the provided output file path.
.EXAMPLE
    Set-ShortcutReportHeader -OutputFilePath 'C:\Temp\_Shortcut Properties - Demo.txt' -ItemBaseName 'Demo'
.INPUTS
    [System.String]
.OUTPUTS
    No objects are returned to the pipeline. The report header is written to the output file.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. All rights reserved.
    Version         : 6.0.0.0
    Author          : Imraan Iotana
    Creation Date   : June 2026
    Last Update     : June 2026
#>
####################################################################################################
function Set-ShortcutReportHeader {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The output report file path where the header will be written.')]
        [ValidateNotNullOrEmpty()]
        [System.String]$OutputFilePath,

        [Parameter(Mandatory=$true,HelpMessage='The base name of the shortcut item used in the header title.')]
        [ValidateNotNullOrEmpty()]
        [System.String]$ItemBaseName
    )

    # EXECUTION
    # Write the report header in a fixed format for consistent exports.
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
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Appends the standard footer for a shortcut export report file.
.DESCRIPTION
    This function composes and appends the common footer lines used by shortcut export reports
    to the provided output file path.
.EXAMPLE
    Set-ShortcutReportFooter -OutputFilePath 'C:\Temp\_Shortcut Properties - Demo.txt'
.INPUTS
    [System.String]
.OUTPUTS
    No objects are returned to the pipeline. The report footer is appended to the output file.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. All rights reserved.
    Version         : 6.0.0.0
    Author          : Imraan Iotana
    Creation Date   : June 2026
    Last Update     : June 2026
#>
####################################################################################################
function Set-ShortcutReportFooter {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The output report file path where the footer will be appended.')]
        [ValidateNotNullOrEmpty()]
        [System.String]$OutputFilePath
    )

    # EXECUTION
    # Append the report footer in a fixed format for consistent exports.
    [System.String[]]$FooterLines = @(
        '******************************',
        '*',
        '* End of file',
        '*',
        '******************************'
    )

    Add-Content -Path $OutputFilePath -Value $FooterLines -Encoding UTF8
}

### END OF FUNCTION
####################################################################################################

