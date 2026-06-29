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
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. All rights reserved.
    Version         : 6.0.0.0
    Author          : Imraan Iotana
    Creation Date   : December 2025
    Last Update     : June 2026
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
            if (-Not(Test-Path -LiteralPath $FolderToOpen)) { Write-Line "The folder does not exist, or could not be reached. ($FolderToOpen)" -Type Fail ; Return }
        }
        'HighlightTheItem' {
            # Validate the string
            if (Test-String -IsEmpty $ItemToHighlight) { Write-Line "The HighlightItem string is empty." -Type Fail ; Return }
            # Validate the path
            if (-Not(Test-Path -LiteralPath $ItemToHighlight)) {
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
                $SelectedItem = Get-Item -Force -LiteralPath $FolderToOpen -ErrorAction Stop
                if ($SelectedItem.PSIsContainer) {
                    Write-Line "Opening folder... ($FolderToOpen)"
                    Invoke-Item -LiteralPath $FolderToOpen
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
    No objects are returned to the pipeline.
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
            # If the textbox already contains an existing folder, reuse that as the initial directory.
            [System.String]$TextBoxFolderPath = $null
            if ($null -ne $TextBox) {
                $TextBoxFolderPath = [System.String]$TextBox.Text
            }
            if ((Test-String -IsPopulated $TextBoxFolderPath) -and (Test-Path -Path $TextBoxFolderPath -PathType Container)) {
                $InitialDirectory = $TextBoxFolderPath
            }
            else {
                # Default back to the root of the current drive
                $InitialDirectory = $ENV:SystemDrive
            }
        }
        elseif (-not (Test-Path -Path $InitialDirectory -PathType Container)) {
            # If the path is invalid, default back to the root of the current drive
            $InitialDirectory = $ENV:SystemDrive
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


####################################################################################################
<#
.SYNOPSIS
    Gets first-level subfolder names from the configured Software Library (DSL) folder.
.DESCRIPTION
    This function reads the Software Library folder path from user settings and
    returns the names of the direct child folders.

    Folders that start with an underscore are treated as internal/system folders
    and are excluded from the result.

    The returned names are sorted and de-duplicated so they can be used directly
    to populate writable ComboBoxes (for example the AppLocker Application ID
    selector) without additional processing.
.EXAMPLE
    Get-DSLDirectSubFolderNames
    Returns all first-level subfolder names from the configured DSL folder.
.OUTPUTS
    [System.String[]]
.NOTES
    Returns an empty array when the DSL folder is not configured, invalid,
    unreachable, or when an exception occurs.
#>
####################################################################################################
function Get-DSLDirectSubFolderNames {
    [CmdletBinding()]
    [OutputType([System.String[]])]
    param ()

    try {
        # Resolve the base Software Library path from user settings.
        [System.String]$SoftwareLibraryFolder = Get-SoftwareLibraryFolder

        # Guard clause: no usable folder means there is nothing to return.
        if ((Test-String -IsEmpty $SoftwareLibraryFolder) -or (-not (Test-Path -LiteralPath $SoftwareLibraryFolder -PathType Container))) {
            return @()
        }

        # Read direct child directories, excluding internal folders (prefixed with underscore).
        [System.String[]]$DirectSubFolderNames = @(
            Get-ChildItem -LiteralPath $SoftwareLibraryFolder -Directory -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -notlike '_*' } |
            Select-Object -ExpandProperty Name
        )

        # Normalize result for UI consumers.
        $DirectSubFolderNames | Sort-Object -Unique
    }
    catch {
        # Keep callers resilient: log and return an empty result.
        Write-ErrorReport -ErrorRecord $_
        @()
    }
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Gets the configured software library folder path from User Settings.
.DESCRIPTION
    This function retrieves the saved software library folder path from the configured User Settings registry path.
.EXAMPLE
    Get-SoftwareLibraryFolder
.INPUTS
    [PSCustomObject]
.OUTPUTS
    [System.String] The configured software library folder path.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. All rights reserved.
    Version         : 6.0.0.0
    Author          : Imraan Iotana
    Creation Date   : May 2026
    Last Update     : May 2026
#>
####################################################################################################
function Get-SoftwareLibraryFolder {
    [CmdletBinding()]
    [OutputType([System.String])]
    param (
        [Parameter(Mandatory=$false,HelpMessage='The ApplicationObject containing the settings.')]
        [PSCustomObject]$InputObject = $Global:ApplicationObject,

        [Parameter(Mandatory=$false,HelpMessage='The name of the User Setting to retrieve.')]
        [System.String]$PropertyName = 'TextBoxes.ApplicationSettings.FolderSettings.SoftwareLibrary'
    )

    try {
        # EXECUTION
        # Get the software library folder path from User Settings.
        [System.String]$SofwareLibraryFolder = Get-UserSetting -PropertyName $PropertyName

        # Return the software library folder value.
        $SofwareLibraryFolder
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}

# END OF FUNCTION
####################################################################################################
