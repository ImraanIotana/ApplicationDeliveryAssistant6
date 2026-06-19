####################################################################################################
<#
.SYNOPSIS
    Imports the File Compare feature into the Files sub-tab.
.DESCRIPTION
    This function imports the File Compare feature into the Files sub-tab by creating a new GroupBox and adding it to the specified parent TabPage.
.EXAMPLE
    Import-FeatureCompareFiles -InputObject $MyApplicationObject -ParentTabPage $MyTabPage
.INPUTS
    [PSCustomObject]
    [System.Windows.Forms.TabPage]
.OUTPUTS
    No objects are returned to the pipeline. All output is written to the host.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. All rights reserved.
    Version         : 6.0.0.0
    Author          : Imraan Iotana
    Creation Date   : May 2026
    Last Update     : June 2026
#>
####################################################################################################
function Import-FeatureCompareFiles {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The ApplicationObject containing the Settings.')]
        [PSCustomObject]$InputObject,

        [Parameter(Mandatory=$true,HelpMessage='The Parent TabPage to which this Feature will be added.')]
        [System.Windows.Forms.TabPage]$ParentTabPage,

        [Parameter(Mandatory=$false,HelpMessage='The GroupBox above which this Feature will be added.')]
        [System.Windows.Forms.GroupBox]$GroupBoxAbove
    )

    try {
        # PREPARATION - FEATURE PROPERTIES
        # Feature properties
        [System.Collections.Hashtable]$FeatureProperties = @{
            InputObject     = $InputObject
            ParentTabPage   = $ParentTabPage
            Title           = 'COMPARE FILES'
            Color           = 'Cyan'
            NumberOfRows    = 3
            GroupBoxAbove   = $GroupBoxAbove
        }

        # PREPARATION - TEXTBOXES
        # Set the TextBox properties
        [System.Collections.Hashtable]$File1TextBoxProperties = @{
            RowNumber       = 1
            Label           = 'Select File 1'
            PropertyName    = 'TextBoxes.Tools.Files.CompareFiles.FilePath1'
            ToolTip         = 'The path of the first file to compare'
            SizeType        = 'Medium'
            SmallButtons    = @(@(5,'Browse File'),@(6,'Paste'),@(7,'Open'))
        }
        # Set the TextBox properties
        [System.Collections.Hashtable]$File2TextBoxProperties = @{
            RowNumber       = 2
            Label           = 'Select File 2'
            PropertyName    = 'TextBoxes.Tools.Files.CompareFiles.FilePath2'
            ToolTip         = 'The path of the second file to compare'
            SizeType        = 'Medium'
            SmallButtons    = @(@(5,'Browse File'),@(6,'Paste'),@(7,'Open'))
        }

        # PREPARATION - BUTTONS
        # Set the Button properties
        [System.Collections.Hashtable[]]$ButtonPropertiesArray1 = @(
            @{
                ColumnNumber    = 1
                Text            = 'Compare Files'
                PNGFileName     = 'price_comparison'
                SizeType        = 'Medium'
                Function        = {
                    Compare-Files -File1Path $Global:Graphics.TextBoxes.Tools.Files.CompareFiles.FilePath1.Text -File2Path $Global:Graphics.TextBoxes.Tools.Files.CompareFiles.FilePath2.Text
                }
            }
        )

        # EXECUTION
        # Create the GroupBox
        [System.Windows.Forms.GroupBox]$FeatureGroupBox = New-GroupBox @FeatureProperties -OnSubTab
        # Create the TextBoxes
        if (-not $Global:Graphics.TextBoxes.Tools.Files.ContainsKey('CompareFiles')) { $Global:Graphics.TextBoxes.Tools.Files.CompareFiles = @{} }
        $Global:Graphics.TextBoxes.Tools.Files.CompareFiles.FilePath1 = New-TextBox @File1TextBoxProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ReturnTextBox
        $Global:Graphics.TextBoxes.Tools.Files.CompareFiles.FilePath2 = New-TextBox @File2TextBoxProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ReturnTextBox
        # Add the Buttons
        New-ButtonLine -InputObject $InputObject -ButtonPropertiesArray $ButtonPropertiesArray1 -ParentGroupBox $FeatureGroupBox -RowNumber 3
        # Return the GroupBox object
        $FeatureGroupBox
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
    Validates that a compare-file input points to an existing file.
.DESCRIPTION
    Checks whether the supplied path is populated and resolves to an existing file before continuing with compare operations.
.EXAMPLE
    Test-CompareFilePath -Path 'C:\File1.txt' -Label 'File 1'
.INPUTS
    [System.String]
    [System.String]
.OUTPUTS
    [System.Boolean]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. All rights reserved.
    Version         : 6.0.0.0
    Author          : Imraan Iotana
    Creation Date   : June 2026
    Last Update     : June 2026
#>
####################################################################################################
function Test-CompareFilePath {
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The file path to validate.')]
        [AllowEmptyString()]
        [System.String]$Path,

        [Parameter(Mandatory=$true,HelpMessage='The display label for the file path.')]
        [System.String]$Label
    )

    if ([System.String]::IsNullOrWhiteSpace($Path)) {
        Write-Line "$Label path is empty." -Type Fail
        return $false
    }

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        Write-Line "$Label does not exist, or could not be reached. ($Path)" -Type Fail
        return $false
    }

    return $true
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Compares the file sizes of two files.
.DESCRIPTION
    Retrieves and compares the file sizes of two specified files, writing the results to the host.
.EXAMPLE
    Compare-FileSize -File1Path 'C:\File1.txt' -File2Path 'C:\File2.txt'
.INPUTS
    [System.String]
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
function Compare-FileSize {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The path of the first file.')]
        [System.String]$File1Path,

        [Parameter(Mandatory=$true,HelpMessage='The path of the second file.')]
        [System.String]$File2Path,

        [Parameter(Mandatory=$false,HelpMessage='If specified, returns $true if the files are the same size, otherwise $false.')]
        [System.Management.Automation.SwitchParameter]$PassThru
    )

    try {
        # PREPARATION - VALIDATE INPUT PATHS
        if (-not (Test-CompareFilePath -Path $File1Path -Label 'File 1')) {
            if ($PassThru) { return $false }
            return
        }
        if (-not (Test-CompareFilePath -Path $File2Path -Label 'File 2')) {
            if ($PassThru) { return $false }
            return
        }

        # EXECUTION - GET FILE SIZES
        # Get the size of File 1
        Write-Line "Getting size of File 1 ($File1Path)..."
        [System.IO.FileInfo]$File1 = Get-Item -LiteralPath $File1Path -ErrorAction Stop
        [System.Int64]$File1Size = $File1.Length
        # Get the size of File 2
        Write-Line "Getting size of File 2 ($File2Path)..."
        [System.IO.FileInfo]$File2 = Get-Item -LiteralPath $File2Path -ErrorAction Stop
        [System.Int64]$File2Size = $File2.Length

        # POST-EXECUTION - COMPARE SIZES
        # Report the sizes and compare them
        [System.Double]$File1SizeMB = [System.Math]::Round($File1Size / 1MB, 3)
        [System.Double]$File2SizeMB = [System.Math]::Round($File2Size / 1MB, 3)
        Write-Line "File 1 size: [$File1SizeMB MB]."
        Write-Line "File 2 size: [$File2SizeMB MB]."

        [System.Boolean]$SizesMatch = $File1Size -eq $File2Size
        if ($SizesMatch) {
            Write-Line "Result: Both files are the same size ([$File1SizeMB MB])."
        }
        elseif ($File1Size -gt $File2Size) {
            [System.Double]$DifferenceMB = [System.Math]::Round(($File1Size - $File2Size) / 1MB, 3)
            Write-Line "Result: File 1 is larger by [$DifferenceMB MB]."
        }
        else {
            [System.Double]$DifferenceMB = [System.Math]::Round(($File2Size - $File1Size) / 1MB, 3)
            Write-Line "Result: File 2 is larger by [$DifferenceMB MB]."
        }

        # Return the result if PassThru is specified
        if ($PassThru) { return $SizesMatch }
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
        # Return false on error if PassThru is specified
        if ($PassThru) { return $false }
    }
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Compares the file hashes of two files.
.DESCRIPTION
    Retrieves and compares the file hashes of two specified files, writing the results to the host.
.EXAMPLE
    Compare-FileHash -File1Path 'C:\File1.txt' -File2Path 'C:\File2.txt'
.INPUTS
    [System.String]
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
function Compare-FileHash {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The path of the first file.')]
        [System.String]$File1Path,

        [Parameter(Mandatory=$true,HelpMessage='The path of the second file.')]
        [System.String]$File2Path,

        [Parameter(Mandatory=$false,HelpMessage='The hashing algorithm to use. Defaults to SHA256.')]
        [System.String]$Algorithm = 'SHA256',

        [Parameter(Mandatory=$false,HelpMessage='If specified, returns $true if the files have the same hash, otherwise $false.')]
        [System.Management.Automation.SwitchParameter]$PassThru
    )

    try {
        # PREPARATION - VALIDATE INPUT PATHS
        if (-not (Test-CompareFilePath -Path $File1Path -Label 'File 1')) {
            if ($PassThru) { return $false }
            return
        }
        if (-not (Test-CompareFilePath -Path $File2Path -Label 'File 2')) {
            if ($PassThru) { return $false }
            return
        }

        # EXECUTION - GET FILE HASHES
        # Get the hash of File 1
        Write-Line "Getting hash of File 1 ($File1Path)..."
        [System.String]$File1Hash = (Get-FileHash -LiteralPath $File1Path -Algorithm $Algorithm -ErrorAction Stop).Hash
        Write-Line "File 1 hash ($Algorithm): [$File1Hash]."
        # Get the hash of File 2
        Write-Line "Getting hash of File 2 ($File2Path)..."
        [System.String]$File2Hash = (Get-FileHash -LiteralPath $File2Path -Algorithm $Algorithm -ErrorAction Stop).Hash
        Write-Line "File 2 hash ($Algorithm): [$File2Hash]."

        # POST-EXECUTION - COMPARE HASHES
        # Report the comparison result
        [System.Boolean]$FileHashesAreEqual = $File1Hash -eq $File2Hash
        if ($FileHashesAreEqual) {
            Write-Line "Result: Both files have the same hash ([$File1Hash])." -Type Info
        }
        else {
            Write-Line "Result: The files have different hashes." -Type Info
        }

        # Return the result if PassThru is specified
        if ($PassThru) { return $FileHashesAreEqual }
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
        # Return false on error if PassThru is specified
        if ($PassThru) { return $false }
    }
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Compares two files by size and hash.
.DESCRIPTION
    Compares two files by first checking their sizes. If the sizes differ, the comparison stops early. If the sizes match, the file hashes are also compared.
.EXAMPLE
    Compare-Files -File1Path 'C:\File1.txt' -File2Path 'C:\File2.txt'
.INPUTS
    [System.String]
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
function Compare-Files {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The path of the first file.')]
        [System.String]$File1Path,

        [Parameter(Mandatory=$true,HelpMessage='The path of the second file.')]
        [System.String]$File2Path,

        [Parameter(Mandatory=$false,HelpMessage='The hashing algorithm to use. Defaults to SHA256.')]
        [System.String]$Algorithm = 'SHA256',

        [Parameter(Mandatory=$false,HelpMessage='The file size threshold in bytes used to trigger a confirmation before hash comparison. Defaults to 500MB.')]
        [System.Int64]$LargeFileSizeThreshold = 500MB,

        [Parameter(Mandatory=$false,HelpMessage='If specified, returns $true if the files are the same size and hash, otherwise $false.')]
        [System.Management.Automation.SwitchParameter]$PassThru
    )

    try {
        # PREPARATION - VALIDATE INPUT PATHS
        if (-not (Test-CompareFilePath -Path $File1Path -Label 'File 1')) {
            if ($PassThru) { return $false }
            return
        }
        if (-not (Test-CompareFilePath -Path $File2Path -Label 'File 2')) {
            if ($PassThru) { return $false }
            return
        }

        # EXECUTION - COMPARE FILE SIZES
        # Compare the sizes first; stop early if they differ
        [System.Boolean]$SizesMatch = Compare-FileSize -File1Path $File1Path -File2Path $File2Path -PassThru
        if (-not $SizesMatch) {
            Write-Line "Skipping hash comparison: files are different sizes."
            if ($PassThru) { return $false }
            return
        }

        # EXECUTION - COMPARE FILE HASHES
        # If the file sizes is large, prompt the user for confirmation before proceeding with the hash comparison
        [System.Int64]$File1Size = (Get-Item -LiteralPath $File1Path -ErrorAction Stop).Length
        if ($File1Size -gt $LargeFileSizeThreshold) {
            [System.Double]$ThresholdMB = [System.Math]::Round($LargeFileSizeThreshold / 1MB, 3)
            if (-not (Get-UserConfirmation -Title 'Confirm Hash Large File' -Body "The file is larger than [$ThresholdMB MB].`nRetrieving the hash may take a while.`n`nDo you want to continue?" -Type 'Warning')) {
                if ($PassThru) { return $false }
                return
            }
        }
        # Compare the hashes
        [System.Boolean]$FileHashesAreEqual = Compare-FileHash -File1Path $File1Path -File2Path $File2Path -Algorithm $Algorithm -PassThru

        # Return the result if PassThru is specified
        if ($PassThru) { return $FileHashesAreEqual }
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
        if ($PassThru) { return $false }
    }
}

### END OF FUNCTION
####################################################################################################

