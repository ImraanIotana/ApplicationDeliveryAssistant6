####################################################################################################
<#
.SYNOPSIS
    This function opens a folder in File Explorer, optionally highlighting a specific item.
.DESCRIPTION
    The Open-Folder function opens a specified folder in File Explorer.
    You can also choose to highlight a specific item within that folder when it opens. This is useful for quickly navigating to a particular file or subfolder.
.EXAMPLE
    Open-Folder -Path C:\Demo
.EXAMPLE
    Open-Folder -HighlightItem C:\Demo\NewFolder
.INPUTS
    [System.String]
.OUTPUTS
    No objects are returned to the pipeline. All output is written to the host.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. All rights reserved.
    Version         : 6.0.0.0
    Author          : Imraan Iotana
    Creation Date   : December 2025
    Last Update     : May 2026
#>
####################################################################################################
function Open-Folder {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,ParameterSetName='OpenTheFolder',HelpMessage='The path of the folder that will be opened.')]
        [AllowEmptyString()]
        [System.String]$Path,

        [Parameter(Mandatory=$true,ParameterSetName='HighlightTheItem',HelpMessage='The item that will be highlighted when the folder is opened.')]
        [Alias('Highlight','Select','SelectItem')]
        [AllowEmptyString()]
        [System.String]$HighlightItem
    )

    # PREPARATION
    # Input
    [System.String]$ParameterSetName    = [System.String]$PSCmdlet.ParameterSetName
    [System.String]$FolderToOpen        = $Path
    [System.String]$ItemToHighlight     = $HighlightItem
    # Handlers
    [System.String]$HighlightPrefix     = '/select,"{0}"'


    # VALIDATION
    # Validate the input based on the parameter set
    switch ($ParameterSetName) {
        'OpenTheFolder'    {
            # Validate the string
            if (Test-String -IsEmpty $FolderToOpen) { Write-Line "The Path string is empty." -Type Fail ; Return }
            # Validate the path
            if (-Not(Test-Path -Path $FolderToOpen)) { Write-Line "The folder does not exist, or could not be reached. ($FolderToOpen)" -Type Fail ; Return }
        }
        'HighlightTheItem' {
            # Validate the string
            if (Test-String -IsEmpty $ItemToHighlight) { Write-Line "The HighlightItem string is empty." -Type Fail ; Return }
            # Validate the path
            if (-Not(Test-Path -Path $ItemToHighlight)) {
                Write-Line "The selected item could not be reached. ($ItemToHighlight)" -Type Fail
                Open-Folder -Path (Split-Path -Path $ItemToHighlight -Parent) ; Return
            }
        }
    }

    # EXECUTION
    switch ($ParameterSetName) {
        'OpenTheFolder'    {
            # Open the folder or highlight the file if a file path was supplied
            try {
                $SelectedItem = Get-Item -LiteralPath $FolderToOpen -ErrorAction Stop
                if ($SelectedItem.PSIsContainer) {
                    Write-Line "Opening folder... ($FolderToOpen)"
                    Invoke-Item -Path $FolderToOpen
                }
                else {
                    Write-Line "Opening folder and highlighting item... ($FolderToOpen)"
                    Start-Process explorer.exe -ArgumentList ($HighlightPrefix -f $FolderToOpen)
                }
            }
            catch {
                Write-ErrorReport -ErrorRecord $_
            }
        }
        'HighlightTheItem' {
            # Open the folder
            try {
                Write-Line "Opening folder and highlighting item... ($ItemToHighlight)"
                Start-Process explorer.exe -ArgumentList ($HighlightPrefix -f $ItemToHighlight)
            }
            catch {
                Write-ErrorReport -ErrorRecord $_
            }
        }
    }

}

### END OF FUNCTION
####################################################################################################


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
    Opens a standard file selection dialog and returns the selected file path.
.DESCRIPTION
    This function opens a Windows file picker so the user can select a file path.
    If an initial directory is supplied, the dialog opens there when the path is valid.
    When a TextBox is provided, the selected path is written back to the control.
.EXAMPLE
    Select-File
.EXAMPLE
    Select-File -InitialDirectory C:\Demo -TextBox $TextBox
.INPUTS
    [System.String]
    [System.Windows.Forms.TextBox]
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
function Select-File {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false,HelpMessage='The initial directory that the file dialog will open to.')]
        [AllowEmptyString()]
        [System.String]$InitialDirectory,

        [Parameter(Mandatory=$false,HelpMessage='The TextBox in which the selected file path will be displayed.')]
        [System.Windows.Forms.TextBox]$TextBox,

        [Parameter(Mandatory=$false,HelpMessage='The type of file being selected, used for logging purposes.')]
        [ValidateSet('Executable','Document','Image','Video','Audio','Other')]
        [System.String]$Type = 'Other'
    )

    try {
        # VALIDATION
        # Validate and normalize the initial directory
        if (Test-String -IsEmpty $InitialDirectory) {
            # Default back to the root of the current drive
            $InitialDirectory = $ENV:SystemDrive
            Write-Line "The provided InitialDirectory string is empty. It will be set to the root of the current drive. ($InitialDirectory)"
        }
        elseif (-not (Test-Path -Path $InitialDirectory -PathType Container)) {
            # If the path is invalid, default back to the root of the current drive
            $InitialDirectory = $ENV:SystemDrive
            Write-Line "The provided InitialDirectory could not be reached. It will be set to the root of the current drive. ($InitialDirectory)"
        }

        # PREPARATION
        # Define the file type filters for the OpenFileDialog based on the selected type
        [System.String]$FileTypeFilter = switch ($Type) {
            'Executable' { 'Executable Files (*.exe;*.msi;*.bat;*.cmd)|*.exe;*.msi;*.bat;*.cmd|All Files (*.*)|*.*' }
            'Document'   { 'Document Files (*.txt;*.pdf;*.doc;*.docx;*.xls;*.xlsx;*.ppt;*.pptx)|*.txt;*.pdf;*.doc;*.docx;*.xls;*.xlsx;*.ppt;*.pptx|All Files (*.*)|*.*' }
            'Image'      { 'Image Files (*.jpg;*.jpeg;*.png;*.bmp;*.gif;*.webp;*.ico)|*.jpg;*.jpeg;*.png;*.bmp;*.gif;*.webp;*.ico|All Files (*.*)|*.*' }
            'Video'      { 'Video Files (*.mp4;*.mkv;*.avi;*.mov;*.wmv;*.webm)|*.mp4;*.mkv;*.avi;*.mov;*.wmv;*.webm|All Files (*.*)|*.*' }
            'Audio'      { 'Audio Files (*.mp3;*.wav;*.flac;*.aac;*.ogg;*.wma)|*.mp3;*.wav;*.flac;*.aac;*.ogg;*.wma|All Files (*.*)|*.*' }
            'Other'      { 'All Files (*.*)|*.*' }
        }

        # EXECUTION - CREATE FILE DIALOG
        # Create an instance of the OpenFileDialog class
        [System.Windows.Forms.OpenFileDialog]$FileDialog = [System.Windows.Forms.OpenFileDialog]::new()
        # Apply the initial directory
        if (Test-String -IsPopulated $InitialDirectory) { $FileDialog.InitialDirectory = $InitialDirectory }
        # Apply the selected file type filter
        $FileDialog.Filter      = $FileTypeFilter
        $FileDialog.FilterIndex = 1

        # EXECUTION - SHOW DIALOG
        # Show the file dialog and capture the selected file path
        if ($FileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            [System.String]$SelectedFile = $FileDialog.FileName
            Write-Line "Selected file: $SelectedFile"
            # If a TextBox was provided, write the selected file path back to it
            if ($null -ne $TextBox) { $TextBox.Text = $SelectedFile }
        }
    }
    finally {
        $FileDialog.Dispose()
    }
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Opens a standard folder selection dialog and captures the selected folder path.
.DESCRIPTION
    This function opens a Windows folder picker so the user can select a folder path.
    If an initial directory is supplied, the dialog opens there when the path is valid.
    When a TextBox is provided, the selected path is written back to the control.
.EXAMPLE
    Select-Folder
.EXAMPLE
    Select-Folder -InitialDirectory C:\Demo -TextBox $TextBox
.INPUTS
    [System.String]
    [System.Windows.Forms.TextBox]
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
function Select-Folder {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false,HelpMessage='The initial directory that the folder dialog will open to.')]
        [AllowEmptyString()]
        [System.String]$InitialDirectory,

        [Parameter(Mandatory=$false,HelpMessage='The TextBox in which the selected folder path will be displayed.')]
        [System.Windows.Forms.TextBox]$TextBox
    )

    try {
        # VALIDATION
        # Validate and normalize the initial directory
        if (Test-String -IsEmpty $InitialDirectory) {
            # Default back to the root of the current drive
            $InitialDirectory = $ENV:SystemDrive
            Write-Line "The provided InitialDirectory string is empty. It will be set to the root of the current drive. ($InitialDirectory)"
        }
        elseif (-not (Test-Path -Path $InitialDirectory -PathType Container)) {
            # If the path is invalid, default back to the root of the current drive
            $InitialDirectory = $ENV:SystemDrive
            Write-Line "The provided InitialDirectory could not be reached. It will be set to the root of the current drive. ($InitialDirectory)"
        }

        # EXECUTION - CREATE FOLDER DIALOG
        # Create an instance of the FolderBrowserDialog class
        [System.Windows.Forms.FolderBrowserDialog]$FolderDialog = [System.Windows.Forms.FolderBrowserDialog]::new()
        # Apply the initial directory
        if (Test-String -IsPopulated $InitialDirectory) { $FolderDialog.SelectedPath = $InitialDirectory }
        $FolderDialog.ShowNewFolderButton = $true

        # EXECUTION - SHOW DIALOG
        # Show the folder dialog and capture the selected folder path
        if ($FolderDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            [System.String]$SelectedFolder = $FolderDialog.SelectedPath
            Write-Line "Selected folder: $SelectedFolder"
            # If a TextBox was provided, write the selected folder path back to it
            if ($null -ne $TextBox) { $TextBox.Text = $SelectedFolder }
        }
    }
    finally {
        $FolderDialog.Dispose()
    }
}

### END OF FUNCTION
####################################################################################################
