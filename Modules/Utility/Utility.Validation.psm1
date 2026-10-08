####################################################################################################
<#
.SYNOPSIS
    This function ask the user for confirmation with a message box.
.DESCRIPTION
    This function is self-contained and does not refer to functions or variables, that are in other files.
.EXAMPLE
    Get-UserConfirmation -Title 'Removing File' -Body 'Are you sure you want to remove this file?'
.INPUTS
    [System.String]
.OUTPUTS
    [System.Boolean]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.0
    Author          : Imraan Iotana
    Creation Date   : June 2023
    Last Update     : June 2026
#>
####################################################################################################
function Get-UserConfirmation {
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    [Alias('Show-MessageBox')]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The text that will be written in the HEADER of the Message Box.')]
        [System.String]$Title,

        [Parameter(Mandatory=$true,HelpMessage='The main text that will be written in the MIDDLE of the Message Box.')]
        [System.String]$Body,

        [Parameter(Mandatory=$false,HelpMessage='String that will decide which icon and buttons to show. Valid values are: Information/Question/Warning/Error.')]
        [ValidateSet('Information','Question','Warning','Error')]
        [System.String]$Type = 'Question'
    )

    try {
        # PREPARATION
        # Set the MessageBox button configuration from the selected type
        [System.Windows.Forms.MessageBoxButtons]$Buttons = switch ($Type) {
            'Information'   { [System.Windows.Forms.MessageBoxButtons]::OK }
            'Question'      { [System.Windows.Forms.MessageBoxButtons]::YesNoCancel }
            'Warning'       { [System.Windows.Forms.MessageBoxButtons]::YesNoCancel }
            'Error'         { [System.Windows.Forms.MessageBoxButtons]::OK }
        }

        # Set the MessageBox icon from the selected type
        [System.Windows.Forms.MessageBoxIcon]$Icon = [System.Enum]::Parse([System.Windows.Forms.MessageBoxIcon], $Type)

        # EXECUTION
        # Show the message box and evaluate whether the user confirmed
        [System.Windows.Forms.DialogResult]$UserChoice = [System.Windows.Forms.MessageBox]::Show($Body, $Title, $Buttons, $Icon)
        [System.Boolean]$UserHasConfirmed = (($UserChoice -eq [System.Windows.Forms.DialogResult]::Yes) -or ($UserChoice -eq [System.Windows.Forms.DialogResult]::OK))

        # POST-EXECUTION
        # Write a status message
        if ($UserHasConfirmed) {
            Write-Line 'The user confirmed.'
        }
        else {
            Write-Line 'The user did not confirm. No action has been taken.'
        }
        # Return the result
        $UserHasConfirmed
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
    This function tests if a String is empty or populated.
.DESCRIPTION
    Tests if a String is empty or populated. The function has two parameter sets: one for testing if a string is empty, and another for testing if a string is populated.
    Depending on the parameter set used, it returns $true or $false accordingly.
.EXAMPLE
    Test-String -IsEmpty $MyString
.EXAMPLE
    Test-String -IsPopulated $MyString
.INPUTS
    [System.String]
.OUTPUTS
    [System.Boolean]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.0
    Author          : Imraan Iotana
    Creation Date   : February 2026
    Last Update     : May 2026
#>
####################################################################################################
function Test-String {
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param (
        [Parameter(Mandatory=$true,ParameterSetName='TestIsEmpty',HelpMessage='The string that will be handled.')]
        [AllowNull()][AllowEmptyString()][System.String]$IsEmpty,

        [Parameter(Mandatory=$true,ParameterSetName='TestIsPopulated',HelpMessage='The string that will be handled.')]
        [AllowNull()][AllowEmptyString()][System.String]$IsPopulated
    )

    begin {
        # PREPARATION
        # Set the context
        [System.Collections.Hashtable]$CTX = @{
            StringToTest        = switch ($PSCmdlet.ParameterSetName) {
                'TestIsEmpty'       { $IsEmpty }
                'TestIsPopulated'   { $IsPopulated }
            }
            ParameterSetName    = $PSCmdlet.ParameterSetName
            Output              = $null
        }
    }
    
    process {
        # Test if the string is empty
        [System.Boolean]$StringIsEmpty = if ( [System.String]::IsNullOrWhiteSpace($CTX.StringToTest) -or [System.String]::IsNullOrEmpty($CTX.StringToTest) ) { $true } else { $false }

        # Set the OutputObject based on the ParameterSetName
        $CTX.Output = switch ($CTX.ParameterSetName) {
            'TestIsEmpty'       { $StringIsEmpty }
            'TestIsPopulated'   { -Not($StringIsEmpty) }
        }
    }
    
    end {
        # Return the output
        $CTX.Output
    }
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Confirms that a provided path is a valid file path.
.DESCRIPTION
    Validates that the input path is populated, exists, and points to a file.
.EXAMPLE
    Confirm-FilePath -Path 'C:\Demo\MyFile.txt' -Name 'File 1'
.INPUTS
    [System.String]
.OUTPUTS
    [System.Boolean]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.1
    Author          : Imraan Iotana
    Creation Date   : July 2026
    Last Update     : July 2026
#>
####################################################################################################
function Confirm-FilePath {
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The file path to validate.')]
        [AllowNull()][AllowEmptyString()]
        [System.String]$Path,

        [Parameter(Mandatory=$true,HelpMessage='The display name used in validation messages.')]
        [System.String]$Name
    )

    # EXECUTION
    # Test if the string is empty
    if (Test-String -IsEmpty $Path) {
        Write-Line "The path for '$Name' is empty. Please provide a valid path." -Type Warning
        return $false
    }

    # Test if the path exists
    if (-Not (Test-Path -LiteralPath $Path)) {
        Write-Line "The path for '$Name' does not exist. Please provide a valid path. ($Path)" -Type Warning
        return $false
    }

    # Test if the path is a file
    if (-Not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        Write-Line "The path for '$Name' is not a file. Please provide a valid file path. ($Path)" -Type Warning
        return $false
    }

    # If all checks pass, return true
    return $true
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Confirms that a provided path is a valid folder path.
.DESCRIPTION
    Validates that the input path is populated, exists, and points to a folder.
.EXAMPLE
    Confirm-FolderPath -Path 'C:\Demo\MyFolder' -Name 'Output Folder'
.INPUTS
    [System.String]
.OUTPUTS
    [System.Boolean]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.1
    Author          : Imraan Iotana
    Creation Date   : July 2026
    Last Update     : July 2026
#>
####################################################################################################
function Confirm-FolderPath {
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param (
        [Parameter(Mandatory=$false,HelpMessage='The folder path to validate.')]
        [AllowNull()][AllowEmptyString()]
        [System.String]$Path,

        [Parameter(Mandatory=$true,HelpMessage='The display name used in validation messages.')]
        [System.String]$Name
    )

    # EXECUTION
    # Test if the string is empty
    if (Test-String -IsEmpty $Path) {
        Write-Line "The path for '$Name' is empty. Please provide a valid path." -Type Warning
        return $false
    }

    # Test if the path exists
    if (-Not (Test-Path -LiteralPath $Path)) {
        Write-Line "The path for '$Name' does not exist. Please provide a valid path. ($Path)" -Type Warning
        return $false
    }

    # Test if the path is a folder
    if (-Not (Test-Path -LiteralPath $Path -PathType Container)) {
        Write-Line "The path for '$Name' is not a folder. Please provide a valid folder path. ($Path)" -Type Warning
        return $false
    }

    # If all checks pass, return true
    return $true
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Confirms that a provided file path matches one of the allowed file extensions.
.DESCRIPTION
    Validates that the input path is a valid file and that its extension is included in the
    supplied list of allowed extensions.
.EXAMPLE
    Confirm-FileExtension -Path 'C:\Temp\Template.dotx' -Name 'Word Template' -AllowedExtensions @('.dotx','.docx','.doc')
.INPUTS
    [System.String]
    [System.String[]]
.OUTPUTS
    [System.Boolean]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.2
    Author          : Imraan Iotana
    Creation Date   : July 2026
    Last Update     : July 2026
#>
####################################################################################################
function Confirm-FileExtension {
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The file path to validate.')]
        [AllowNull()][AllowEmptyString()]
        [System.String]$Path,

        [Parameter(Mandatory=$true,HelpMessage='The display name used in validation messages.')]
        [System.String]$Name,

        [Parameter(Mandatory=$true,HelpMessage='The allowed file extensions, for example .dotx or json.')]
        [ValidateNotNullOrEmpty()]
        [System.String[]]$AllowedExtensions
    )

    try {
        # VALIDATION - FILE PATH
        # Validate the file path before extension checks
        if (-not (Confirm-FilePath -Path $Path -Name $Name)) {
            return $false
        }

        # PREPARATION - EXTENSIONS
        # Normalize the provided allowed extensions for case-insensitive matching
        [System.Collections.Generic.List[System.String]]$NormalizedAllowedExtensions = New-Object 'System.Collections.Generic.List[System.String]'
        foreach ($AllowedExtension in $AllowedExtensions) {
            if (Test-String -IsEmpty $AllowedExtension) {
                continue
            }

            [System.String]$NormalizedExtension = if ($AllowedExtension.StartsWith('.')) {
                $AllowedExtension.ToLowerInvariant()
            }
            else {
                ".{0}" -f $AllowedExtension.ToLowerInvariant()
            }
            [void]$NormalizedAllowedExtensions.Add($NormalizedExtension)
        }

        if ($NormalizedAllowedExtensions.Count -le 0) {
            Write-Line "No valid allowed extensions were supplied for '$Name'." -Type Warning
            return $false
        }

        # EXECUTION - EXTENSION CHECK
        # Validate that the file extension is included in the allowed list
        [System.String]$CurrentExtension = [System.IO.Path]::GetExtension($Path)
        if (Test-String -IsEmpty $CurrentExtension) {
            Write-Line "The file for '$Name' does not have an extension. ($Path)" -Type Warning
            return $false
        }

        [System.String]$CurrentExtensionLower = $CurrentExtension.ToLowerInvariant()
        if ($CurrentExtensionLower -notin $NormalizedAllowedExtensions) {
            [System.String]$AllowedExtensionText = ($NormalizedAllowedExtensions | Sort-Object -Unique) -join ', '
            Write-Line "The file extension for '$Name' is not allowed. Found '$CurrentExtensionLower'. Allowed: $AllowedExtensionText. ($Path)" -Type Warning
            return $false
        }

        # POST-EXECUTION
        # If all checks pass, return true
        return $true
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
    Confirms that a JSON file can be parsed successfully.
.DESCRIPTION
    Validates that the input path is a valid `.json` file and attempts to parse its content.
    Returns `$true` when parsing succeeds, otherwise writes a warning and returns `$false`.
.EXAMPLE
    Confirm-JsonFileContent -Path 'C:\Temp\Metadata.json' -Name 'Metadata JSON'
.INPUTS
    [System.String]
.OUTPUTS
    [System.Boolean]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.2
    Author          : Imraan Iotana
    Creation Date   : July 2026
    Last Update     : July 2026
#>
####################################################################################################
function Confirm-JsonFileContent {
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The JSON file path to validate and parse.')]
        [AllowNull()][AllowEmptyString()]
        [System.String]$Path,

        [Parameter(Mandatory=$true,HelpMessage='The display name used in validation messages.')]
        [System.String]$Name
    )

    try {
        # VALIDATION - FILE TYPE
        # Ensure the file exists and has a JSON extension before parsing
        if (-not (Confirm-FileExtension -Path $Path -Name $Name -AllowedExtensions @('.json'))) {
            return $false
        }

        # EXECUTION - PARSE JSON
        # Read and parse the JSON content to confirm it is syntactically valid
        try {
            [System.String]$JsonContent = Get-Content -LiteralPath $Path -Raw -ErrorAction Stop
            $null = $JsonContent | ConvertFrom-Json -ErrorAction Stop
            return $true
        }
        catch {
            Write-Line "The JSON content for '$Name' is invalid or could not be parsed. ($Path)" -Type Warning
            return $false
        }
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}

### END OF FUNCTION
####################################################################################################

