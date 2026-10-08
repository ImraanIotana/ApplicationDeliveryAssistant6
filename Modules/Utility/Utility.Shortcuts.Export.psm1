
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
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.1
    Author          : Imraan Iotana
    Creation Date   : June 2026
    Last Update     : July 2026
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
        # Validate output folder and output type switches
        if (Test-String -IsEmpty $OutputFolder) { throw 'The OutputFolder parameter is empty.' }
        if ($PNG -and $ICO) {
            Write-Line 'Please select only one output format switch: -PNG or -ICO.' -Type Fail
            return
        }

        # PREPARATION
        # Ensure output folder exists and determine file extension
        if (-not (Test-Path -LiteralPath $OutputFolder -PathType Container)) {
            New-Item -Path $OutputFolder -ItemType Directory -Force | Out-Null
        }
        [System.String]$Extension = if ($ICO) { 'ico' } else { 'png' }

        # PREPARATION
        # Read properties from the provided shortcut object
        [System.String]$BaseName = [System.String]$InputObject.BaseName
        [System.String]$IconFilePath = [System.String]$InputObject.IconFilePath
        [System.String]$TargetPath = [System.String]$InputObject.TargetPath
        if (Test-String -IsEmpty $BaseName) { $BaseName = 'ShortcutIcon' }

        [System.String]$OutputFileName = ('{0}.{1}' -f $BaseName,$Extension)
        [System.String]$OutputFilePath = Join-Path -Path $OutputFolder -ChildPath $OutputFileName

        # EXECUTION
        # Try IconFilePath first, then fall back to TargetPath
        [System.Boolean]$Saved = $false
        if ((Test-String -IsPopulated $IconFilePath) -and (Test-Path -LiteralPath $IconFilePath -PathType Leaf)) {
            try {
                [System.Drawing.Icon]::ExtractAssociatedIcon($IconFilePath).ToBitmap().Save($OutputFilePath)
                $Saved = $true
            }
            catch {
                # Keep trying with TargetPath when icon extraction from IconFilePath fails
                $Saved = $false
            }
        }
        # Fallback: try extracting the icon from the shortcut target file
        if (-not $Saved -and (Test-String -IsPopulated $TargetPath) -and (Test-Path -LiteralPath $TargetPath -PathType Leaf)) {
            try {
                [System.Drawing.Icon]::ExtractAssociatedIcon($TargetPath).ToBitmap().Save($OutputFilePath)
                $Saved = $true
            }
            catch {
                # Leave Saved as false so a warning is emitted below
                $Saved = $false
            }
        }
        # Report a warning when both extraction attempts fail
        if (-not $Saved) {
            Write-Line "The $Extension file could not be extracted from IconFilePath or TargetPath." -Type Warning
            return
        }

        # POST-EXECUTION
        # Report success and optionally open the output folder
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
    Universal shortcut export function for path-based and UI-based workflows.
.DESCRIPTION
    This function exports shortcut details from either:
    - A direct path (file or folder),
    - A selected shortcut object (with FullPath), or
    - A shortcut ComboBox (using SelectedItem.FullPath).

    It can export to a generic output folder or to an application archive location
    (9. Archive\Shortcuts) when ApplicationFolderPath is supplied.
.EXAMPLE
    Export-ShortcutInformation -Path 'C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Acrobat Reader.lnk'
.EXAMPLE
    Export-ShortcutInformation -ShortcutItem (Get-ComboBoxObject -ComboBoxName 'SelectShortcutFolder').SelectedItem -OpenOutputFolder
.EXAMPLE
    Export-ShortcutInformation -ApplicationFolderPath 'C:\Temp\Vendor_App_1.0' -ShortcutComboBox (Get-ComboBoxObject -ComboBoxName 'SelectShortcutFolder') -SkipConfirmation -PassThru
.INPUTS
    [System.String]
    [System.Object]
    [System.Windows.Forms.ComboBox]
.OUTPUTS
    [System.String] when PassThru is specified and the export succeeds; otherwise no objects are returned.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.1
    Author          : Imraan Iotana
    Creation Date   : June 2026
    Last Update     : July 2026
#>
####################################################################################################
function Export-ShortcutInformation {
    [CmdletBinding(DefaultParameterSetName='ByPath')]
    param (
        [Parameter(Mandatory=$true,ParameterSetName='ByPath',HelpMessage='The shortcut file or folder path to export.')]
        [ValidateNotNullOrEmpty()]
        [System.String]$Path,

        [Parameter(Mandatory=$true,ParameterSetName='ByShortcutItem',HelpMessage='Shortcut item that contains the FullPath property.')]
        [System.Object]$ShortcutItem,

        [Parameter(Mandatory=$true,ParameterSetName='ByComboBox',HelpMessage='Shortcut ComboBox; the SelectedItem.FullPath value will be exported.')]
        [System.Windows.Forms.ComboBox]$ShortcutComboBox,

        [Parameter(Mandatory=$false,HelpMessage='Destination folder where the export output will be created.')]
        [Alias('OutputFolder')]
        [System.String]$ParentOutputFolder = (Get-Folder -OutputFolder),

        [Parameter(Mandatory=$false,HelpMessage='The root folder of the created application package. When supplied, output is written to ..\9. Archive\Shortcuts.')]
        [System.String]$ApplicationFolderPath,

        [Parameter(Mandatory=$false,HelpMessage='Open the output folder after export.')]
        [System.Management.Automation.SwitchParameter]$OpenOutputFolder,

        [Parameter(Mandatory=$false,HelpMessage='Skip the confirmation prompt and export immediately.')]
        [System.Management.Automation.SwitchParameter]$SkipConfirmation,

        [Parameter(Mandatory=$false,HelpMessage='Return the exported shortcut report file path.')]
        [System.Management.Automation.SwitchParameter]$PassThru
    )

    try {
        # PREPARATION
        # Resolve input path from parameter set via shared shortcut resolver.
        [System.Collections.Hashtable]$ResolvePathParameters = @{ WriteMessages = $true }
        switch ($PSCmdlet.ParameterSetName) {
            'ByPath' { $ResolvePathParameters.Path = $Path }
            'ByShortcutItem' { $ResolvePathParameters.ShortcutItem = $ShortcutItem }
            'ByComboBox' { $ResolvePathParameters.ShortcutComboBox = $ShortcutComboBox }
        }
        [System.String]$InputPath = Resolve-ShortcutInputPath @ResolvePathParameters
        if (Test-String -IsEmpty $InputPath) {
            return
        }

        # CONFIRMATION
        # Ask for confirmation only when -SkipConfirmation is not specified
        if (-not $SkipConfirmation) {
            [System.String]$Title   = 'Confirm Export Shortcut Information'
            [System.String]$Body    = "Would you like to EXPORT the SHORTCUT information for the following path:`n`n$InputPath"
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

        # VALIDATION
        # Validate resolved input and output paths
        if (-not (Test-Path -LiteralPath $InputPath)) { Write-Line "The supplied path could not be reached. ($InputPath)" -Type Fail ; return }
        if (Test-String -IsEmpty $OutputRootFolder) { throw 'The output folder is empty.' }
        if (-not (Test-Path -Path $OutputRootFolder)) { New-Item -Path $OutputRootFolder -ItemType Directory -Force | Out-Null }

        # PREPARATION
        # Resolve input path and output file paths
        [System.IO.FileSystemInfo]$SelectedItem = Get-Item -LiteralPath $InputPath -ErrorAction Stop
        [System.String]$ItemBaseName = if ($SelectedItem.PSIsContainer) { $SelectedItem.Name } else { $SelectedItem.BaseName }
        [System.String]$ActualOutputFolder = Get-ShortcutExportOutputFolderPath -OutputRootFolder $OutputRootFolder -ItemBaseName $ItemBaseName
        if (-not (Test-Path -Path $ActualOutputFolder)) { New-Item -Path $ActualOutputFolder -ItemType Directory -Force | Out-Null }

        [System.String]$OutputFilePath = Join-Path -Path $ActualOutputFolder -ChildPath ("_Shortcut Properties - $ItemBaseName.txt")
        if (Test-Path -LiteralPath $OutputFilePath) { Remove-Item -LiteralPath $OutputFilePath -Force }

        # Reuse the shared shortcut resolver so report and metadata paths stay aligned
        [PSCustomObject[]]$ShortcutEntries = Get-ShortcutInformationCollection -Path $InputPath -WriteMessages
        if ($ShortcutEntries.Count -eq 0) {
            return
        }

        # EXECUTION - HEADER
        # Write header
        Write-ShortcutReportHeader -OutputFilePath $OutputFilePath -ItemBaseName $ItemBaseName

        # EXECUTION - BODY (SHORTCUTS)
        # Write one section per shortcut
        Write-ShortcutReportBody -ShortcutEntries $ShortcutEntries -OutputFilePath $OutputFilePath -ActualOutputFolder $ActualOutputFolder

        # EXECUTION - FOOTER
        # Write footer
        Write-ShortcutReportFooter -OutputFilePath $OutputFilePath

        # Write a final message to the host indicating where the output was saved
        Write-Line "Shortcut information of file/folder ($InputPath) exported to the following file: $OutputFilePath" -Type Success

        # POST-EXECUTION
        if ($OpenOutputFolder) {
            Open-Folder -Path $ActualOutputFolder
        }
        if ($PassThru) {
            return $OutputFilePath
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
    Builds the shortcut export output folder path for a selected item name.
.DESCRIPTION
    This helper composes the standardized shortcut export folder name
    "Shortcuts - <ItemBaseName>" under the supplied output root folder.
.EXAMPLE
    Get-ShortcutExportOutputFolderPath -OutputRootFolder 'C:\Temp\9. Archive\Shortcuts' -ItemBaseName 'FileZilla FTP Client'
.INPUTS
    [System.String]
.OUTPUTS
    [System.String]
#>
####################################################################################################
function Get-ShortcutExportOutputFolderPath {
    [CmdletBinding()]
    [OutputType([System.String])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='Root shortcuts output folder path.')]
        [ValidateNotNullOrEmpty()]
        [System.String]$OutputRootFolder,

        [Parameter(Mandatory=$true,HelpMessage='Selected item base name used in the export folder name.')]
        [ValidateNotNullOrEmpty()]
        [System.String]$ItemBaseName
    )

    # EXECUTION
    # Compose and return the standardized shortcut export folder path.
    return (Join-Path -Path $OutputRootFolder -ChildPath ("Shortcuts - $ItemBaseName"))
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Writes shortcut export entries and their icon files.
.DESCRIPTION
    This helper iterates shortcut entries, formats each report entry, appends it to the report file,
    and exports the associated icon images into the output folder.
.INPUTS
    [PSCustomObject[]]
    [System.String]
    [System.String]
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.1
    Author          : Imraan Iotana
    Creation Date   : June 2026
    Last Update     : July 2026
#>
####################################################################################################
function Write-ShortcutReportBody {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The shortcut entries being exported.')]
        [PSCustomObject[]]$ShortcutEntries,

        [Parameter(Mandatory=$true,HelpMessage='The output report file path where the entry will be appended.')]
        [System.String]$OutputFilePath,

        [Parameter(Mandatory=$true,HelpMessage='The folder where shortcut icon exports will be written.')]
        [System.String]$ActualOutputFolder
    )

    [System.Int32]$ShortcutCounter = 0
    foreach ($ShortcutEntry in $ShortcutEntries | Sort-Object FullPath) {
        $ShortcutCounter++

        # Keep body rows value-only to make copy/paste into tables easy
        [System.String[]]$ShortcutLines = @(
            '******************************',
            "* Shortcut $ShortcutCounter of $($ShortcutEntries.Count)",
            '******************************',
            "$($ShortcutEntry.BaseName)",
            "$($ShortcutEntry.TargetPath)",
            "$($ShortcutEntry.WorkingDirectory)",
            "$($ShortcutEntry.Arguments)",
            "$($ShortcutEntry.StartMenuLocation)",
            "$($ShortcutEntry.IconFilePath)",
            '******************************',
            ''
        )
        Add-Content -Path $OutputFilePath -Value $ShortcutLines -Encoding UTF8

        # Export icon image to the same output folder as the text report
        [PSCustomObject]$ShortcutImageProperties = [PSCustomObject]@{
            BaseName     = $ShortcutEntry.BaseName
            IconFilePath = $ShortcutEntry.IconFilePath
            TargetPath   = $ShortcutEntry.TargetPath
        }
        Export-ShortcutImage -InputObject $ShortcutImageProperties -OutputFolder $ActualOutputFolder -PNG
        Export-ShortcutImage -InputObject $ShortcutImageProperties -OutputFolder $ActualOutputFolder -ICO
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
    Write-ShortcutReportHeader -OutputFilePath 'C:\Temp\_Shortcut Properties - Demo.txt' -ItemBaseName 'Demo'
.INPUTS
    [System.String]
.OUTPUTS
    No objects are returned to the pipeline. The report header is written to the output file.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.1
    Author          : Imraan Iotana
    Creation Date   : June 2026
    Last Update     : July 2026
#>
####################################################################################################
function Write-ShortcutReportHeader {
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
    # Write the report header in a fixed format for consistent exports
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
    Write-ShortcutReportFooter -OutputFilePath 'C:\Temp\_Shortcut Properties - Demo.txt'
.INPUTS
    [System.String]
.OUTPUTS
    No objects are returned to the pipeline. The report footer is appended to the output file.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.1
    Author          : Imraan Iotana
    Creation Date   : June 2026
    Last Update     : July 2026
#>
####################################################################################################
function Write-ShortcutReportFooter {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The output report file path where the footer will be appended.')]
        [ValidateNotNullOrEmpty()]
        [System.String]$OutputFilePath
    )

    # EXECUTION
    # Append the report footer in a fixed format for consistent exports
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

