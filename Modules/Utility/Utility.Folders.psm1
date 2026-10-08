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
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
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
    Removes a file or folder while showing the Windows progress bar.
.DESCRIPTION
    This function removes a specified file or folder through the Windows Shell,
    which shows the standard deletion progress dialog.
    By default, a confirmation prompt is shown before deletion.
.EXAMPLE
    Remove-WithGUI -Path 'C:\Demo\Folder'
.EXAMPLE
    Remove-WithGUI -Path 'C:\Demo\Folder' -OutHost
.EXAMPLE
    Remove-WithGUI -Path 'C:\Demo\Folder' -OutHost -Force
.INPUTS
    [System.String]
    [System.Management.Automation.SwitchParameter]
.OUTPUTS
    This function returns no stream output.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.1
    Author          : Imraan Iotana
    Creation Date   : December 2025
    Last Update     : July 2026
#>
####################################################################################################
function Remove-WithGUI {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false,HelpMessage='The path of the item that will be removed.')]
        [AllowNull()][AllowEmptyString()]
        [System.String]$Path,

        [Parameter(Mandatory=$false,HelpMessage='Switch for writing to the host.')]
        [System.Management.Automation.SwitchParameter]$OutHost,

        [Parameter(Mandatory=$false,HelpMessage='Switch for skipping the confirmation.')]
        [System.Management.Automation.SwitchParameter]$Force
    )

    # PREPARATION
    # Input
    [System.String]$ItemToDelete = $Path

    # VALIDATION
    # Validate that the input string is populated
    if (Test-String -IsEmpty $ItemToDelete) {
        Write-Line 'The Path string is empty.' -Type Fail
        return
    }
    # Validate that the item exists
    if (-not (Test-Path -LiteralPath $ItemToDelete)) {
        Write-Line "The item can not be found. ($ItemToDelete)" -Type Fail
        return
    }

    # PREPARATION
    # Handlers
    [System.Int32]$DeleteFlagMoveToRecycleBin   = 8
    [System.Int32]$DeleteFlagNoConfirmation     = 10
    [System.Int32]$DeleteFlagShowProgressBar    = 16
    # Confirmation handlers
    [System.String]$ConfirmationTitle = 'CONFIRM DELETION'
    [System.String]$ConfirmationBody = "This will DELETE the file/folder:`n`n$ItemToDelete`n`nAre you sure?"

    # CONFIRMATION
    # If the Force parameter is not present, ask for confirmation
    if (-not $Force.IsPresent) {
        if (-not (Get-UserConfirmation -Title $ConfirmationTitle -Body $ConfirmationBody)) {
            return
        }
    }

    # PREPARATION - COM OBJECTS
    # Create COM objects for the Shell, Parent Folder, and Leaf Item
    [System.__ComObject]$ShellObject = $null
    [System.__ComObject]$ParentFolderObject = $null
    [System.__ComObject]$LeafObject = $null

    try {
        # PREPARATION - OBJECTS
        # Create the Shell object and resolve the parent/leaf shell items
        $ShellObject = New-Object -ComObject Shell.Application
        [System.String]$ItemToDeleteParentFolder = Split-Path -Path $ItemToDelete -Parent
        [System.String]$ItemToDeleteLeafName = Split-Path -Path $ItemToDelete -Leaf

        # Guard against root deletion inputs (for example C:\) that do not provide a leaf item
        if (Test-String -IsEmpty $ItemToDeleteLeafName) {
            Write-Line "The item could not be resolved for deletion. ($ItemToDelete)" -Type Fail
            return
        }

        # Resolve the parent folder and leaf item using the Shell object
        $ParentFolderObject = $ShellObject.Namespace($ItemToDeleteParentFolder)
        $LeafObject = $ParentFolderObject.ParseName($ItemToDeleteLeafName)

        # VALIDATION - COM OBJECTS
        # Validate that the parent folder and leaf item were successfully resolved
        if (($null -eq $ParentFolderObject) -or ($null -eq $LeafObject)) {
            Write-Line "The item could not be resolved for deletion. ($ItemToDelete)" -Type Fail
            return
        }

        # PREPARATION - FLAGS
        # Set the delete flag
        [System.Int32]$DeleteFlag = $DeleteFlagMoveToRecycleBin + $DeleteFlagNoConfirmation + $DeleteFlagShowProgressBar

        # EXECUTION
        # Remove the item
        if ($OutHost.IsPresent) { Write-Line "Removing the item ($ItemToDelete)..." -Type Busy }
        $LeafObject.InvokeVerbEx('Delete', $DeleteFlag)
        if ($OutHost.IsPresent) { Write-Line "The item has been removed. ($ItemToDelete)" -Type Success }
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
    finally {
        # CLEANUP
        # Release COM objects in reverse order
        if ($null -ne $LeafObject) {
            [void][System.Runtime.InteropServices.Marshal]::ReleaseComObject($LeafObject)
        }
        if ($null -ne $ParentFolderObject) {
            [void][System.Runtime.InteropServices.Marshal]::ReleaseComObject($ParentFolderObject)
        }
        if ($null -ne $ShellObject) {
            [void][System.Runtime.InteropServices.Marshal]::ReleaseComObject($ShellObject)
        }
    }

}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Copies or moves files and folders while showing the Windows progress bar.
.DESCRIPTION
    This function uses the Windows Shell to copy or move a selected source item
    into a destination folder and shows the standard progress dialog.
    When the destination already contains the same item name, overwrite can be
    confirmed interactively or forced with -Overwrite.
.EXAMPLE
    Copy-WithGUI -ThisFolder 'C:\Demo\CopyThisFolder' -IntoThisFolder 'D:\Archives'
.EXAMPLE
    Copy-WithGUI -ThisFolder 'C:\Demo\CopyThisFolder' -IntoThisFolder 'D:\Archives' -OpenFolder
.EXAMPLE
    Copy-WithGUI -ThisFolder 'C:\Demo\CopyThisFolder' -IntoThisFolder 'D:\Archives' -Overwrite -OpenFolder
.INPUTS
    [System.String]
    [System.Management.Automation.SwitchParameter]
.OUTPUTS
    This function returns no stream output.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.1
    Author          : Imraan Iotana
    Creation Date   : December 2025
    Last Update     : July 2026
#>
####################################################################################################
function Copy-WithGUI {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false,HelpMessage='The source item path that will be copied or moved.')]
        [AllowNull()][AllowEmptyString()]
        [System.String]$ThisFolder,

        [Parameter(Mandatory=$false,HelpMessage='The destination folder into which the source item will be copied or moved.')]
        [AllowNull()][AllowEmptyString()]
        [System.String]$IntoThisFolder,

        [Parameter(Mandatory=$false,HelpMessage='Switch for overwriting an existing item at the destination.')]
        [System.Management.Automation.SwitchParameter]$Overwrite,

        [Parameter(Mandatory=$false,HelpMessage='Switch for moving instead of copying.')]
        [System.Management.Automation.SwitchParameter]$Move,

        [Parameter(Mandatory=$false,HelpMessage='Switch for opening the destination folder.')]
        [System.Management.Automation.SwitchParameter]$OpenFolder
    )

    # PREPARATION
    # Input
    [System.String]$ItemToTransfer = $ThisFolder
    [System.String]$DestinationFolder = $IntoThisFolder
    [System.String]$ItemLeafName = $null
    [System.String]$UltimateItemPath = $null
    # Handlers
    [System.Int32]$ShellFlagShowProgressBar = 16

    # VALIDATION
    # Validate source string and path
    if (Test-String -IsEmpty $ItemToTransfer) {
        Write-Line 'The Source folder field is empty.' -Type Fail
        return
    }
    if (-not (Test-Path -LiteralPath $ItemToTransfer)) {
        Write-Line "The Source folder can not be found. ($ItemToTransfer)" -Type Fail
        return
    }

    # Validate destination string and path
    if (Test-String -IsEmpty $DestinationFolder) {
        Write-Line 'The Destination folder field is empty.' -Type Fail
        return
    }
    if (-not (Test-Path -LiteralPath $DestinationFolder -PathType Container)) {
        Write-Line "The Destination folder can not be found. ($DestinationFolder)" -Type Fail
        return
    }

    # Build source/destination item paths only after validation to avoid null-path binding errors
    $ItemLeafName = Split-Path -Path $ItemToTransfer -Leaf
    $UltimateItemPath = Join-Path -Path $DestinationFolder -ChildPath $ItemLeafName

    # Guard against source root-like input (for example C:\) that does not provide a leaf item
    if (Test-String -IsEmpty $ItemLeafName) {
        Write-Line "The source item could not be resolved. ($ItemToTransfer)" -Type Fail
        return
    }

    # GENERAL CONFIRMATION
    # Set the operation verb and ask for confirmation
    [System.String]$Verb = if ($Move.IsPresent) { 'MOVE' } else { 'COPY' }
    if ($Overwrite.IsPresent) { $Verb += ' (AND OVERWRITE)' }
    if (-not (Get-UserConfirmation -Title "CONFIRM $Verb" -Body "This will $Verb the item:`n`n$ItemToTransfer`n`ninto the folder:`n`n$DestinationFolder`n`nAre you sure?")) {
        return
    }

    # OVERWRITE CONFIRMATION
    # If destination exists, verify overwrite behavior
    if (Test-Path -LiteralPath $UltimateItemPath) {
        Write-Line "The destination already exists. ($UltimateItemPath)" -Type Busy

        [System.Boolean]$ShouldOverwrite = if ($Overwrite.IsPresent) {
            $true
        }
        else {
            Get-UserConfirmation -Title 'CONFIRM OVERWRITE' -Body "This will OVERWRITE the existing item:`n`n$UltimateItemPath`n`nAre you sure?"
        }

        if (-not $ShouldOverwrite) {
            Write-Line "The destination was not overwritten. ($UltimateItemPath)" -Type Success
            return
        }

        Remove-WithGUI -Path $UltimateItemPath -OutHost -Force
        if (Test-Path -LiteralPath $UltimateItemPath) {
            Write-Line "The destination could not be removed. ($UltimateItemPath)" -Type Fail
            return
        }
        Write-Line "The existing destination has been removed. ($UltimateItemPath)" -Type Success
    }

    # PREPARATION - COM OBJECTS
    # Create COM objects for Shell, Source Parent/Leaf, and Destination
    [System.__ComObject]$ShellObject = $null
    [System.__ComObject]$SourceParentFolderObject = $null
    [System.__ComObject]$SourceLeafObject = $null
    [System.__ComObject]$DestinationObject = $null

    try {
        # PREPARATION - OBJECTS
        # Resolve source and destination shell objects
        $ShellObject = New-Object -ComObject Shell.Application
        [System.String]$SourceParentFolder = Split-Path -Path $ItemToTransfer -Parent
        $SourceParentFolderObject = $ShellObject.Namespace($SourceParentFolder)
        $SourceLeafObject = $SourceParentFolderObject.ParseName($ItemLeafName)
        $DestinationObject = $ShellObject.Namespace($DestinationFolder)

        # VALIDATION - COM OBJECTS
        # Validate that source and destination shell objects were resolved
        if (($null -eq $SourceParentFolderObject) -or ($null -eq $SourceLeafObject)) {
            Write-Line "The source item could not be resolved for transfer. ($ItemToTransfer)" -Type Fail
            return
        }
        if ($null -eq $DestinationObject) {
            Write-Line "The destination folder could not be accessed. ($DestinationFolder)" -Type Fail
            return
        }

        # EXECUTION
        # Perform copy or move through the shell to show the GUI progress bar
        [System.String]$ActionVerb = if ($Move.IsPresent) { 'Moving' } else { 'Copying' }
        [System.String]$CompletionVerb = if ($Move.IsPresent) { 'moved' } else { 'copied' }

        Write-Line "$ActionVerb the item ($ItemToTransfer) into the folder ($DestinationFolder)..." -Type Busy
        if ($Move.IsPresent) {
            $DestinationObject.MoveHere($SourceLeafObject, $ShellFlagShowProgressBar)
        }
        else {
            $DestinationObject.CopyHere($SourceLeafObject, $ShellFlagShowProgressBar)
        }
        Write-Line "The item has been $CompletionVerb. ($UltimateItemPath)" -Type Success

        if ($OpenFolder.IsPresent) {
            Open-Folder -HighlightItem $UltimateItemPath
        }
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
    finally {
        # CLEANUP
        # Release COM objects in reverse order
        if ($null -ne $DestinationObject) {
            [void][System.Runtime.InteropServices.Marshal]::ReleaseComObject($DestinationObject)
        }
        if ($null -ne $SourceLeafObject) {
            [void][System.Runtime.InteropServices.Marshal]::ReleaseComObject($SourceLeafObject)
        }
        if ($null -ne $SourceParentFolderObject) {
            [void][System.Runtime.InteropServices.Marshal]::ReleaseComObject($SourceParentFolderObject)
        }
        if ($null -ne $ShellObject) {
            [void][System.Runtime.InteropServices.Marshal]::ReleaseComObject($ShellObject)
        }
    }

}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Writes the main folder properties of a path to the host.
.DESCRIPTION
    This function accepts a folder path string, validates that the folder exists,
    and writes a readable set of folder properties to the host.
.EXAMPLE
    Write-FolderPropertiesToHost -Path 'C:\Demo\Folder'
.INPUTS
    [System.String]
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.4.1
    Author          : Imraan Iotana
    Creation Date   : July 2026
    Last Update     : August 2026
#>
####################################################################################################
function Write-FolderPropertiesToHost {
    [CmdletBinding()]
    [OutputType([System.Void])]
    param (
        [Parameter(Mandatory=$true,Position=0,HelpMessage='The full path to a folder to inspect.')]
        [AllowEmptyString()]
        [System.String]$Path
    )

    try {
        # VALIDATION
        # Validate that the supplied path points to an existing folder
        if (Test-String -IsEmpty $Path) {
            Write-Line 'The Path string is empty.' -Type Warning
            return
        }
        if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
            Write-Line "The folder does not exist, or could not be reached. ($Path)" -Type Warning
            return
        }

        # PREPARATION
        # Read the folder item once so the host output can reuse the same object
        [System.IO.DirectoryInfo]$FolderItem = Get-Item -LiteralPath $Path -Force -ErrorAction Stop
        [System.IO.FileSystemInfo[]]$ChildItems = @(Get-ChildItem -LiteralPath $Path -Force -ErrorAction SilentlyContinue)
        [System.IO.DirectoryInfo[]]$AllFoldersInFolder = @(Get-ChildItem -LiteralPath $Path -Directory -Recurse -Force -ErrorAction SilentlyContinue)
        [System.IO.FileInfo[]]$AllFilesInFolder = @(Get-ChildItem -LiteralPath $Path -File -Recurse -Force -ErrorAction SilentlyContinue)
        [System.Int32]$ChildFolderCount = @($ChildItems | Where-Object { $_.PSIsContainer }).Count
        [System.Int32]$ChildFileCount = @($ChildItems | Where-Object { -not $_.PSIsContainer }).Count
        [System.Int32]$TotalSubFolderCount = $AllFoldersInFolder.Count
        [System.Int32]$TotalFileCount = $AllFilesInFolder.Count
        [System.Int64]$FolderSizeBytes = [System.Int64](@($AllFilesInFolder | Measure-Object -Property Length -Sum).Sum)
        [System.Double]$FolderSizeMB = [System.Math]::Round(($FolderSizeBytes / 1MB), 3)
        [System.Double]$FolderSizeGB = [System.Math]::Round(($FolderSizeBytes / 1GB), 3)

        # OUTPUT
        # Write the folder properties in a readable host-friendly format
        Write-Line ''
        Write-Line ("{0,-20}: {1}" -f 'Folder Path', $FolderItem.FullName) -Type Special
        Write-Line ("{0,-20}: {1}" -f 'Folder Name', $FolderItem.Name)
        Write-Line ("{0,-20}: {1}" -f 'Parent Folder', $FolderItem.Parent.FullName)
        Write-Line ("{0,-20}: {1}" -f 'Created', $FolderItem.CreationTime)
        Write-Line ("{0,-20}: {1}" -f 'Last Write Time', $FolderItem.LastWriteTime)
        Write-Line ("{0,-20}: {1}" -f 'Last Access Time', $FolderItem.LastAccessTime)
        Write-Line ("{0,-20}: {1}" -f 'Attributes', $FolderItem.Attributes)
        Write-Line ("{0,-20}: {1} bytes ({2} MB / {3} GB)" -f 'Folder Size', $FolderSizeBytes, $FolderSizeMB, $FolderSizeGB)
        Write-Line ("{0,-20}: {1}" -f 'Child Folders', $ChildFolderCount)
        Write-Line ("{0,-20}: {1}" -f 'Child Files', $ChildFileCount)
        Write-Line ("{0,-20}: {1}" -f 'Total Subfolders', $TotalSubFolderCount)
        Write-Line ("{0,-20}: {1}" -f 'Total Files', $TotalFileCount)
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
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
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
            # If the textbox already contains an existing folder, reuse that as the initial directory
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
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
    finally {
        # CLEANUP
        # Dispose of the folder dialog object
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
    This function reads the Software Library folder path and returns the names of the direct child folders.
    Folders that start with an underscore are treated as internal/system folders and are excluded from the result.
    When a filter is supplied, only folders with names containing that text are returned.
.EXAMPLE
    Get-DSLDirectSubFolderNames
.EXAMPLE
    Get-DSLDirectSubFolderNames -Filter 'Java'
.INPUTS
    [System.String]
.OUTPUTS
    [System.String[]]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.3
    Author          : Imraan Iotana
    Creation Date   : July 2026
    Last Update     : July 2026
#>
####################################################################################################
function Get-DSLDirectSubFolderNames {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false,HelpMessage='Optional filter used to match direct subfolder names.')]
        [AllowEmptyString()]
        [System.String]$Filter,

        [Parameter(Mandatory=$false,HelpMessage='Optional output format for the subfolders.')]
        [ValidateSet('String', 'Object')]
        [System.String]$As = 'String'
    )

    try {
        # PREPARATION
        # Set the properties
        [System.String]$SoftwareLibraryFolder   = Get-Folder -SoftwareLibrary
        [System.String]$NormalizedFilter        = $Filter.Trim()
        [System.String]$ExclusionPrefix         = '_' 

        # VALIDATION
        # Validate the target application folder path
        if ((Test-String -IsEmpty $SoftwareLibraryFolder) -or (-not (Test-Path -LiteralPath $SoftwareLibraryFolder -PathType Container))) {
            Write-Line "The Software Library folder path is empty or invalid. The subfolders could not be retrieved."
            Return
        }

        # EXECUTION
        # Read direct child directories first, excluding internal folders (prefixed with underscore)
        [System.IO.DirectoryInfo[]]$SortedSubFolderObjects = @(
            Get-ChildItem -LiteralPath $SoftwareLibraryFolder -Directory -ErrorAction SilentlyContinue |
            Where-Object { -not ($_.Name.StartsWith($ExclusionPrefix)) } |
            Sort-Object Name
        )

        # Apply a case-insensitive filter when requested.
        if (Test-String -IsPopulated $NormalizedFilter) {
                $SortedSubFolderObjects = $SortedSubFolderObjects | Where-Object { ($_.Name.IndexOf($NormalizedFilter,[System.StringComparison]::OrdinalIgnoreCase) -ge 0) }
        }

        # Return the requested output format
        if ($As -eq 'String') {
            [System.String[]]$SortedSubFolderNames = @(
                $SortedSubFolderObjects | Select-Object -ExpandProperty Name
            )
            $SortedSubFolderNames
        }
        else {
            $SortedSubFolderObjects
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
    Gets a configured folder path from User Settings.
.DESCRIPTION
    This function retrieves a configured folder path based on the supplied switch parameter.
.EXAMPLE
    Get-Folder -SoftwareLibrary
.EXAMPLE
    Get-Folder -OutputFolder
.INPUTS
    [System.Management.Automation.SwitchParameter]
.OUTPUTS
    [System.String] The configured folder path.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.3.0
    Author          : Imraan Iotana
    Creation Date   : May 2026
    Last Update     : August 2026
#>
####################################################################################################
function Get-Folder {
    [CmdletBinding()]
    [OutputType([System.String])]
    param (
        [Parameter(Mandatory=$true,ParameterSetName='SoftwareLibrary',HelpMessage='Gets the configured Software Library folder path.')]
        [System.Management.Automation.SwitchParameter]$SoftwareLibrary,

        [Parameter(Mandatory=$true,ParameterSetName='SoftwareLibraryArchive',HelpMessage='Gets the configured Software Library Archive folder path.')]
        [System.Management.Automation.SwitchParameter]$SoftwareLibraryArchive,

        [Parameter(Mandatory=$true,ParameterSetName='OutputFolder',HelpMessage='Gets the configured output folder path.')]
        [System.Management.Automation.SwitchParameter]$OutputFolder
    )

    try {
        # PREPARATION
        # Get the parameter set name
        [System.String]$ParameterSetName = [System.String]$PSCmdlet.ParameterSetName

        # EXECUTION
        # Switch on the parameter set name to determine which folder path to retrieve
        [System.String]$Folder = switch ($ParameterSetName) {
            'SoftwareLibrary'        { Get-UserSetting -PropertyLeaf 'SoftwareLibraryDSL' }
            'SoftwareLibraryArchive' {
                [System.String]$ArchiveFolder = Get-UserSetting -PropertyLeaf 'SoftwareLibraryArchive'
                if (Test-String -IsEmpty $ArchiveFolder) {
                    $ArchiveFolder = Get-UserSetting -PropertyLeaf 'SoftwareLibraryArchiveDSL'
                }
                $ArchiveFolder
            }
            'OutputFolder'           { Get-UserSetting -PropertyLeaf 'MyOutputFolder' }
        }

        # OUTPUT
        # Return the folder
        $Folder
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}

### END OF FUNCTION
####################################################################################################
