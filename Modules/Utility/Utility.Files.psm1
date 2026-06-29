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
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. All rights reserved.
    Version         : 6.0.0.0
    Author          : Imraan Iotana
    Creation Date   : June 2026
    Last Update     : June 2026
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
    # Validate that the supplied string is populated
    if (Test-String -IsEmpty $Path) { return 'The Path string is empty.' }
    # Validate that the supplied path points to an existing file
    if (-not (Test-Path -Path $Path -PathType Leaf)) { return "The file does not exist, or could not be reached. ($Path)" }

    # PREPARATION
    # Read and normalize the file extension for branch selection
    [System.String]$Extension = [System.IO.Path]::GetExtension($Path).ToLowerInvariant()

    # EXECUTION
    [System.String]$BitnessText = switch ($Extension) {
        '.exe' {
            try {
                # Parse the PE header to determine the target machine architecture
                [System.Byte[]]$Bytes = Get-Content -Path $Path -Encoding Byte -ReadCount 0
                [System.Int32]$Pe = [System.BitConverter]::ToInt32($Bytes, 0x3C)
                [System.UInt16]$Machine = [System.BitConverter]::ToUInt16($Bytes, $Pe + 4)

                # Translate PE machine values to user-friendly bitness text
                switch ($Machine) {
                    0x014c  { '32bit (x86)' ; break }
                    0x8664  { '64bit (x64)' ; break }
                    default { 'Unknown/other format' ; break }
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
    # When -OutHost is supplied, write a sentence to the host and return nothing to the pipeline.
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
    No objects are returned to the pipeline.
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
            # If the textbox already contains an existing file, reuse its parent folder as the initial directory.
            [System.String]$TextBoxFilePath = $null
            if ($null -ne $TextBox) {
                $TextBoxFilePath = [System.String]$TextBox.Text
            }
            if ((Test-String -IsPopulated $TextBoxFilePath) -and (Test-Path -Path $TextBoxFilePath -PathType Leaf)) {
                $InitialDirectory = Split-Path -Path $TextBoxFilePath -Parent
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
            #Write-Line "Selected file: $SelectedFile"
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

