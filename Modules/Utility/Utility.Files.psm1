####################################################################################################
<#
.SYNOPSIS
    Removes enclosing double quotes from an Explorer-copied file or folder path.
.DESCRIPTION
    Removes one matching pair of enclosing double quotes and whitespace outside that pair.
    Unquoted paths, apostrophes, and whitespace inside the quotes are preserved.
.EXAMPLE
    ConvertFrom-ExplorerFilePath -Path '"C:\Setup Files\Setup.msi"'
.INPUTS
    [System.String]
.OUTPUTS
    [System.String]
.NOTES
    This script is part of the Application Delivery Assistant.
    Version         : 6.7.0
    Author          : Imraan Iotana
    Creation Date   : September 2026
    Last Update     : September 2026
#>
####################################################################################################
function ConvertFrom-ExplorerFilePath {
    [CmdletBinding()]
    [OutputType([System.String])]
    param (
        [Parameter(Mandatory=$false)]
        [AllowNull()][AllowEmptyString()]
        [System.String]$Path
    )

    if ([System.String]::IsNullOrEmpty($Path)) { return '' }
    [System.String]$TrimmedPath = $Path.Trim()
    if ($TrimmedPath.Length -ge 2 -and $TrimmedPath.StartsWith('"') -and $TrimmedPath.EndsWith('"')) {
        return $TrimmedPath.Substring(1, $TrimmedPath.Length - 2)
    }

    return $Path
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Returns the detected bitness of a file path.
.DESCRIPTION
    This function accepts a file path string and returns the bitness as text.
    For EXE files, it reads the PE header Machine field.
    For MSI files, bitness detection is currently in development.
    Use -ForDocument to include a second line with the source detection file path.
    Use -OutHost to write a sentence to the host and return nothing to the pipeline.
.EXAMPLE
    Get-FileBitness -Path 'C:\Program Files\Demo\demoapp.exe'
.EXAMPLE
    Get-FileBitness -Path 'C:\Program Files\Demo\demoapp.exe' -ForDocument
.EXAMPLE
    Get-FileBitness -Path 'C:\Program Files\Demo\demoapp.exe' -OutHost
.INPUTS
    [System.String]
.OUTPUTS
    [System.String]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.1
    Author          : Imraan Iotana
    Creation Date   : June 2026
    Last Update     : July 2026
#>
####################################################################################################
function Get-FileBitness {
    [CmdletBinding()]
    [OutputType([System.String])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The full path to an EXE or MSI file.')]
        [AllowEmptyString()]
        [System.String]$Path,

        [Parameter(Mandatory=$false,HelpMessage='When supplied, returns a document-friendly multi-line output that includes the detection file path.')]
        [System.Management.Automation.SwitchParameter]$ForDocument,

        [Parameter(Mandatory=$false,HelpMessage='When supplied, outputs a sentence to the host and returns nothing to the pipeline.')]
        [System.Management.Automation.SwitchParameter]$OutHost
    )

    # VALIDATION
    # Validate that the supplied path points to an existing file
    if (-not (Confirm-FilePath -Path $Path -Name 'File Bitness Detection')) {
        return $null
    }

    # PREPARATION
    # Read and normalize the file extension for branch selection
    [System.String]$Extension = [System.IO.Path]::GetExtension($Path).ToLowerInvariant()

    # EXECUTION
    [System.String]$BitnessText = switch ($Extension) {
        '.exe' {
            try {
                # Parse the PE header to determine the target machine architecture without loading the full file
                [System.IO.FileStream]$FileStream = $null
                [System.IO.BinaryReader]$BinaryReader = $null
                try {
                    $FileStream = [System.IO.File]::Open($Path,[System.IO.FileMode]::Open,[System.IO.FileAccess]::Read,[System.IO.FileShare]::ReadWrite)
                    $BinaryReader = New-Object -TypeName System.IO.BinaryReader -ArgumentList $FileStream

                    # Validate minimum header size and DOS signature (MZ)
                    if ($FileStream.Length -lt 64) {
                        'Unknown/other format'
                        break
                    }

                    $FileStream.Position = 0
                    [System.UInt16]$DosSignature = $BinaryReader.ReadUInt16()
                    if ($DosSignature -ne 0x5A4D) {
                        'Unknown/other format'
                        break
                    }

                    # Read PE header offset from DOS header and validate range
                    $FileStream.Position = 0x3C
                    [System.Int32]$PeHeaderOffset = $BinaryReader.ReadInt32()
                    if ($PeHeaderOffset -lt 0 -or ($PeHeaderOffset + 6) -gt $FileStream.Length) {
                        'Unknown/other format'
                        break
                    }

                    # Validate PE signature and read machine field
                    $FileStream.Position = $PeHeaderOffset
                    [System.UInt32]$PeSignature = $BinaryReader.ReadUInt32()
                    if ($PeSignature -ne 0x00004550) {
                        'Unknown/other format'
                        break
                    }

                    [System.UInt16]$Machine = $BinaryReader.ReadUInt16()

                    # Translate PE machine values to user-friendly bitness text
                    switch ($Machine) {
                        0x014c  { '32bit (x86)' ; break }
                        0x8664  { '64bit (x64)' ; break }
                        default { 'Unknown/other format' ; break }
                    }
                }
                finally {
                    if ($null -ne $BinaryReader) { $BinaryReader.Dispose() }
                    elseif ($null -ne $FileStream) { $FileStream.Dispose() }
                }
            }
            catch {
                # Return a readable status instead of throwing to the caller
                "Unable to read executable format. ($Path)"
            }
        }
        '.msi' {
            try {
                # Open the MSI database through Windows Installer COM
                [System.__ComObject]$Installer = New-Object -ComObject WindowsInstaller.Installer
                [System.Object]$Database = $Installer.GetType().InvokeMember('OpenDatabase', 'InvokeMethod', $null, $Installer, @($Path, 0))

                # Read the Summary Information template property (PID_TEMPLATE = 7)
                [System.Object]$Summary = $Database.SummaryInformation(0)
                [System.String]$Template = [System.String]$Summary.Property(7)

                # Translate template values to user-friendly bitness text
                switch -Regex ($Template.ToLowerInvariant()) {
                    'arm64'                         { '64bit (ARM64)' ; break }
                    '(^|;)\s*(x64|amd64)\s*(;|$)'   { '64bit (x64)' ; break }
                    '(^|;)\s*(intel|x86)\s*(;|$)'   { '32bit (x86)' ; break }
                    default                         { "Unknown/other format ($Template)" ; break }
                }
            }
            catch {
                # Return a readable status instead of throwing to the caller
                "Unable to read MSI format. ($Path)"
            }
            finally {
                # Release COM objects in reverse order to avoid lingering handles
                if ($null -ne $Summary)     { [void][System.Runtime.InteropServices.Marshal]::ReleaseComObject($Summary) }
                if ($null -ne $Database)    { [void][System.Runtime.InteropServices.Marshal]::ReleaseComObject($Database) }
                if ($null -ne $Installer)   { [void][System.Runtime.InteropServices.Marshal]::ReleaseComObject($Installer) }
            }
        }
        default {
            # Inform the caller when the extension is outside supported types
            "Unsupported file extension. ($Extension)"
        }
    }

    # POST-PROCESSING
    # If the -ForDocument switch is supplied, include a second line with the source detection file path for document output
    [System.String]$TextToOutput = switch ($ForDocument.IsPresent) {
        $true {
            "{0}{1}(Based on detection file: {2})" -f $BitnessText, [char]11, $Path
        }
        $false {
            $BitnessText
        }
    }

    # OUTPUT
    # When -OutHost is supplied, write a sentence to the host and return nothing to the pipeline
    if ($OutHost.IsPresent) {
        Write-Line "The bitness of the file ($Path) is: $BitnessText"
    } else {
        # Return the final output text to the pipeline
        $TextToOutput
    }

}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Returns the FileVersionRaw value for a file path.
.DESCRIPTION
    This function accepts a file path string and returns the file version in a stable 4-part format.
    It reads VersionInfo.FileVersionRaw and converts it to text so the value can be stored in metadata.
.EXAMPLE
    Get-FileVersion -Path 'C:\Program Files\Demo\demoapp.exe'
.INPUTS
    [System.String]
.OUTPUTS
    [System.String]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.1
    Author          : Imraan Iotana
    Creation Date   : July 2026
    Last Update     : July 2026
#>
####################################################################################################
function Get-FileVersion {
    [CmdletBinding()]
    [OutputType([System.String])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The full path to a file.')]
        [AllowEmptyString()]
        [System.String]$Path
    )

    try {
        # VALIDATION
        # Validate that the supplied string is populated
        if (Test-String -IsEmpty $Path) { return 'The Path string is empty.' }
        # Validate that the supplied path points to an existing file
        if (-not (Test-Path -Path $Path -PathType Leaf)) { return "The file does not exist, or could not be reached. ($Path)" }

        # PREPARATION
        # Read the file item and its version information
        [System.IO.FileInfo]$FileItem = Get-Item -LiteralPath $Path -ErrorAction Stop
        [System.Diagnostics.FileVersionInfo]$VersionInfo = $FileItem.VersionInfo

        # EXECUTION
        # Return FileVersionRaw in a stable 4-part dotted format when available
        if ($null -ne $VersionInfo -and $null -ne $VersionInfo.FileVersionRaw) {
            return $VersionInfo.FileVersionRaw.ToString()
        }

        # FALLBACK
        # Construct a 4-part version text from numeric fields when FileVersionRaw is unavailable
        if ($null -ne $VersionInfo) {
            return '{0}.{1}.{2}.{3}' -f $VersionInfo.FileMajorPart, $VersionInfo.FileMinorPart, $VersionInfo.FileBuildPart, $VersionInfo.FilePrivatePart
        }

        # OUTPUT
        # Return null when the version cannot be resolved
        $null
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
    Opens a standard file selection dialog and returns the selected file path.
.DESCRIPTION
    This function opens a Windows file picker so the user can select a file path.
    If an initial directory is supplied, the dialog opens there when the path is valid.
    When a TextBox or ComboBox is provided, the selected path is written back to the control.
.EXAMPLE
    Select-File -Type Word
.EXAMPLE
    Select-File -Type Json
.EXAMPLE
    Select-File
.EXAMPLE
    Select-File -InitialDirectory C:\Demo -TextBox $TextBox
.INPUTS
    [System.String]
    [System.Windows.Forms.TextBox]
    [System.Windows.Forms.ComboBox]
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.7.0
    Author          : Imraan Iotana
    Creation Date   : June 2026
    Last Update     : September 2026
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

        [Parameter(Mandatory=$false,HelpMessage='The ComboBox in which the selected file path will be displayed.')]
        [System.Windows.Forms.ComboBox]$ComboBox,

        [Parameter(Mandatory=$false,HelpMessage='The type of file being selected, used for logging purposes.')]
        [ValidateSet('Executable','Document','Word','Json','Csv','Inf','Msi','Icon','Image','Video','Audio','AppLocker','Other')]
        [System.String]$Type = 'Other'
    )

    try {
        # VALIDATION
        # Validate and normalize the initial directory
        if (Test-String -IsEmpty $InitialDirectory) {
            # If a target control already contains an existing file, reuse its parent folder as the initial directory
            [System.String]$CurrentFilePath = $null
            if ($null -ne $TextBox) {
                $CurrentFilePath = [System.String]$TextBox.Text
            }
            elseif ($null -ne $ComboBox) {
                $CurrentFilePath = [System.String]$ComboBox.Text
            }
            if ((Test-String -IsPopulated $CurrentFilePath) -and (Test-Path -Path $CurrentFilePath -PathType Leaf)) {
                $InitialDirectory = Split-Path -Path $CurrentFilePath -Parent
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

        # PREPARATION
        # Define the file type filters for the OpenFileDialog based on the selected type
        [System.String]$FileTypeFilter = switch ($Type) {
            'Executable' { 'Executable Files (*.exe;*.msi;*.bat;*.cmd)|*.exe;*.msi;*.bat;*.cmd|All Files (*.*)|*.*' }
            'Document'   { 'Document Files (*.txt;*.pdf;*.doc;*.docx;*.xls;*.xlsx;*.ppt;*.pptx)|*.txt;*.pdf;*.doc;*.docx;*.xls;*.xlsx;*.ppt;*.pptx|All Files (*.*)|*.*' }
            'Word'       { 'Word Files (*.doc;*.docx;*.dotx;*.dotm)|*.doc;*.docx;*.dotx;*.dotm|All Files (*.*)|*.*' }
            'Json'       { 'JSON Files (*.json)|*.json|All Files (*.*)|*.*' }
            'Csv'        { 'CSV Files (*.csv)|*.csv|All Files (*.*)|*.*' }
            'Inf'        { 'Driver Setup Information Files (*.inf)|*.inf' }
            'Msi'        { 'Windows Installer Packages (*.msi)|*.msi' }
            'Icon'       { 'Icon Source Files (*.ico;*.png;*.jpg;*.jpeg;*.bmp;*.gif)|*.ico;*.png;*.jpg;*.jpeg;*.bmp;*.gif' }
            'Image'      { 'Image Files (*.jpg;*.jpeg;*.png;*.bmp;*.gif;*.webp;*.ico)|*.jpg;*.jpeg;*.png;*.bmp;*.gif;*.webp;*.ico|All Files (*.*)|*.*' }
            'Video'      { 'Video Files (*.mp4;*.mkv;*.avi;*.mov;*.wmv;*.webm)|*.mp4;*.mkv;*.avi;*.mov;*.wmv;*.webm|All Files (*.*)|*.*' }
            'Audio'      { 'Audio Files (*.mp3;*.wav;*.flac;*.aac;*.ogg;*.wma)|*.mp3;*.wav;*.flac;*.aac;*.ogg;*.wma|All Files (*.*)|*.*' }
            'AppLocker'  { 'AppLocker Files (*.xml)|*.xml|All Files (*.*)|*.*' }
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
            #Write-Line "Selected file: $SelectedFile"
            # Write the selected file path back to the provided target control
            if ($null -ne $TextBox) { $TextBox.Text = $SelectedFile }
            if ($null -ne $ComboBox) { $ComboBox.Text = $SelectedFile }
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
    Opens a standard Save File dialog and returns the selected file path.
.DESCRIPTION
    This function opens a Windows SaveFileDialog so the user can select a destination file path.
    If an initial directory is supplied, the dialog opens there when the path is valid.
    When a TextBox is provided, the selected path is written back to the control.
.EXAMPLE
    Save-File -Type Json
.EXAMPLE
    Save-File -Type PowerShellData -DefaultFileName 'DeploymentData.psd1'
.EXAMPLE
    Save-File -InitialDirectory C:\Demo -TextBox $TextBox
.INPUTS
    [System.String]
    [System.Windows.Forms.TextBox]
.OUTPUTS
    [System.String]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.4
    Author          : Imraan Iotana
    Creation Date   : August 2026
    Last Update     : August 2026
#>
####################################################################################################
function Save-File {
    [CmdletBinding()]
    [OutputType([System.String])]
    param (
        [Parameter(Mandatory=$false,HelpMessage='The initial directory that the save dialog will open to.')]
        [AllowEmptyString()]
        [System.String]$InitialDirectory,

        [Parameter(Mandatory=$false,HelpMessage='Optional default file name shown in the save dialog.')]
        [AllowEmptyString()]
        [System.String]$DefaultFileName,

        [Parameter(Mandatory=$false,HelpMessage='The TextBox in which the selected file path will be displayed.')]
        [System.Windows.Forms.TextBox]$TextBox,

        [Parameter(Mandatory=$false,HelpMessage='The type of file being saved, used for file extension filters.')]
        [ValidateSet('Executable','Document','Word','Json','Image','Video','Audio','AppLocker','PowerShellData','Other')]
        [System.String]$Type = 'Other'
    )

    [System.String]$SelectedFile = $null
    [System.Windows.Forms.SaveFileDialog]$FileDialog = $null

    try {
        # VALIDATION - INITIAL DIRECTORY
        # Validate and normalize the initial directory.
        if (Test-String -IsEmpty $InitialDirectory) {
            [System.String]$TextBoxPath = $null
            if ($null -ne $TextBox) {
                $TextBoxPath = [System.String]$TextBox.Text
            }

            if ((Test-String -IsPopulated $TextBoxPath) -and (Test-Path -Path $TextBoxPath -PathType Leaf)) {
                $InitialDirectory = Split-Path -Path $TextBoxPath -Parent
            }
            elseif ((Test-String -IsPopulated $TextBoxPath) -and (Test-Path -Path $TextBoxPath -PathType Container)) {
                $InitialDirectory = $TextBoxPath
            }
            else {
                $InitialDirectory = $ENV:SystemDrive
            }
        }
        elseif (-not (Test-Path -Path $InitialDirectory -PathType Container)) {
            $InitialDirectory = $ENV:SystemDrive
        }

        # PREPARATION - FILTERS AND EXTENSION
        # Define file type filters and default extension based on requested save type.
        [System.String]$FileTypeFilter = switch ($Type) {
            'Executable'     { 'Executable Files (*.exe;*.msi;*.bat;*.cmd)|*.exe;*.msi;*.bat;*.cmd|All Files (*.*)|*.*' }
            'Document'       { 'Document Files (*.txt;*.pdf;*.doc;*.docx;*.xls;*.xlsx;*.ppt;*.pptx)|*.txt;*.pdf;*.doc;*.docx;*.xls;*.xlsx;*.ppt;*.pptx|All Files (*.*)|*.*' }
            'Word'           { 'Word Files (*.doc;*.docx;*.dotx;*.dotm)|*.doc;*.docx;*.dotx;*.dotm|All Files (*.*)|*.*' }
            'Json'           { 'JSON Files (*.json)|*.json|All Files (*.*)|*.*' }
            'Image'          { 'Image Files (*.jpg;*.jpeg;*.png;*.bmp;*.gif;*.webp;*.ico)|*.jpg;*.jpeg;*.png;*.bmp;*.gif;*.webp;*.ico|All Files (*.*)|*.*' }
            'Video'          { 'Video Files (*.mp4;*.mkv;*.avi;*.mov;*.wmv;*.webm)|*.mp4;*.mkv;*.avi;*.mov;*.wmv;*.webm|All Files (*.*)|*.*' }
            'Audio'          { 'Audio Files (*.mp3;*.wav;*.flac;*.aac;*.ogg;*.wma)|*.mp3;*.wav;*.flac;*.aac;*.ogg;*.wma|All Files (*.*)|*.*' }
            'AppLocker'      { 'AppLocker Files (*.xml)|*.xml|All Files (*.*)|*.*' }
            'PowerShellData' { 'PowerShell Data Files (*.psd1)|*.psd1|All Files (*.*)|*.*' }
            'Other'          { 'All Files (*.*)|*.*' }
        }

        [System.String]$DefaultExtension = switch ($Type) {
            'Json'           { 'json' }
            'AppLocker'      { 'xml' }
            'PowerShellData' { 'psd1' }
            default          { '' }
        }

        # EXECUTION - CONFIGURE DIALOG
        # Create and configure the SaveFileDialog.
        $FileDialog = [System.Windows.Forms.SaveFileDialog]::new()
        if (Test-String -IsPopulated $InitialDirectory) { $FileDialog.InitialDirectory = $InitialDirectory }
        if (Test-String -IsPopulated $DefaultFileName) { $FileDialog.FileName = $DefaultFileName }
        $FileDialog.Filter = $FileTypeFilter
        $FileDialog.FilterIndex = 1
        $FileDialog.OverwritePrompt = $true
        if (Test-String -IsPopulated $DefaultExtension) {
            $FileDialog.DefaultExt = $DefaultExtension
            $FileDialog.AddExtension = $true
        }

        # EXECUTION - SHOW DIALOG
        # Show the save dialog and capture the selected file path.
        if ($FileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $SelectedFile = [System.String]$FileDialog.FileName
            if ($null -ne $TextBox) { $TextBox.Text = $SelectedFile }
        }
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
    finally {
        # POST-EXECUTION - CLEANUP
        # Dispose of dialog resources.
        if ($null -ne $FileDialog) {
            $FileDialog.Dispose()
        }
    }

    # OUTPUT
    # Return selected path, or null when cancelled.
    return $SelectedFile
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Writes the main file properties of a path to the host.
.DESCRIPTION
    This function accepts a file path string, validates that the file exists, and writes a readable
    set of file properties to the host. It reuses the existing file version and bitness helpers so
    the output stays consistent with the rest of the utility module.
.EXAMPLE
    Write-FilePropertiesToHost -Path 'C:\Program Files\Demo\demoapp.exe'
.INPUTS
    [System.String]
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.1.0
    Author          : Imraan Iotana
    Creation Date   : July 2026
    Last Update     : August 2026
#>
####################################################################################################
function Write-FilePropertiesToHost {
    [CmdletBinding()]
    [OutputType([System.Void])]
    param (
        [Parameter(Mandatory=$true,Position=0,HelpMessage='The full path to a file to inspect.')]
        [AllowEmptyString()]
        [System.String]$Path
    )

    try {
        # VALIDATION
        # Validate that the supplied path points to an existing file
        if (-not (Confirm-FilePath -Path $Path -Name 'File Properties')) {
            return
        }

        # PREPARATION
        # Read the file item once so the host output can reuse the same object
        [System.IO.FileInfo]$FileItem = Get-Item -LiteralPath $Path -ErrorAction Stop
        [System.Double]$FileSizeMB = [System.Math]::Round(($FileItem.Length / 1MB), 3)
        [System.Double]$FileSizeGB = [System.Math]::Round(($FileItem.Length / 1GB), 3)

        # EXECUTION
        # Collect the additional file details that are already available through shared helpers
        [System.String]$FileVersion = Get-FileVersion -Path $Path
        [System.String]$Bitness = Get-FileBitness -Path $Path

        # OUTPUT
        # Write the file properties in a readable host-friendly format
        Write-Line ''
        Write-Line ("{0,-20}: {1}" -f 'File Path', $FileItem.FullName) -Type Special
        Write-Line ("{0,-20}: {1}" -f 'File Name', $FileItem.Name)
        Write-Line ("{0,-20}: {1}" -f 'Directory', $FileItem.DirectoryName)
        Write-Line ("{0,-20}: {1}" -f 'Extension', $FileItem.Extension)
        Write-Line ("{0,-20}: {1} bytes ({2} MB / {3} GB)" -f 'Size', $FileItem.Length, $FileSizeMB, $FileSizeGB)
        Write-Line ("{0,-20}: {1}" -f 'Created', $FileItem.CreationTime)
        Write-Line ("{0,-20}: {1}" -f 'Last Write Time', $FileItem.LastWriteTime)
        Write-Line ("{0,-20}: {1}" -f 'Last Access Time', $FileItem.LastAccessTime)
        Write-Line ("{0,-20}: {1}" -f 'Attributes', $FileItem.Attributes)

        if (Test-String -IsPopulated $FileVersion) {
            Write-Line ("{0,-20}: {1}" -f 'File Version', $FileVersion)
        }

        if (Test-String -IsPopulated $Bitness) {
            Write-Line ("{0,-20}: {1}" -f 'Bitness', $Bitness)
        }
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}
### END OF FUNCTION
####################################################################################################

