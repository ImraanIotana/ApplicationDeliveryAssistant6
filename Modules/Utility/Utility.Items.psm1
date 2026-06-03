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


