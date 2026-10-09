####################################################################################################
<#
.SYNOPSIS
    Resolves the icon source for a Custom Application.
.DESCRIPTION
    Returns the optional application icon when supplied and otherwise falls back to the application executable so downstream documentation and shortcut workflows share one selection rule.
.EXAMPLE
    Resolve-CustomApplicationIconSourcePath -ApplicationIconPath 'C:\Icons\App.ico' -ApplicationExecutablePath 'C:\Apps\App.exe'
.INPUTS
    [System.String]
.OUTPUTS
    [System.String]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.3.1
    Author          : Imraan Iotana
    Creation Date   : August 2026
    Last Update     : August 2026
#>
####################################################################################################
function Resolve-CustomApplicationIconSourcePath {
    [CmdletBinding()]
    [OutputType([System.String])]
    param (
        [Parameter(Mandatory=$false,HelpMessage='Optional user-provided icon or image file path.')]
        [AllowNull()][AllowEmptyString()]
        [System.String]$ApplicationIconPath,

        [Parameter(Mandatory=$false,HelpMessage='Application executable path used when no icon was supplied.')]
        [AllowNull()][AllowEmptyString()]
        [System.String]$ApplicationExecutablePath
    )

    # OUTPUT - EXPLICIT ICON OR EXECUTABLE FALLBACK
    if (Test-String -IsPopulated $ApplicationIconPath) {
        return $ApplicationIconPath
    }

    return $ApplicationExecutablePath
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Exports portable PNG and ICO files for a Custom Application.
.DESCRIPTION
    Converts the optional icon source, or an executable fallback, into package-local files used by documentation and shortcut creation.
.OUTPUTS
    [PSCustomObject] containing SourcePath, PngPath, and IcoPath.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.9.3
    Author          : Imraan Iotana
    Creation Date   : August 2026
    Last Update     : October 2026
#>
####################################################################################################
function Export-CustomApplicationIconFiles {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory=$true)]
        [System.String]$SourcePath,

        [Parameter(Mandatory=$true)]
        [System.String]$OutputFolder,

        [Parameter(Mandatory=$true)]
        [System.String]$BaseName
    )

    # VALIDATION - SOURCE AND DESTINATION
    if (-not (Test-Path -LiteralPath $SourcePath -PathType Leaf)) {
        throw "The icon source file does not exist. ($SourcePath)"
    }
    if (-not (Test-Path -LiteralPath $OutputFolder -PathType Container)) {
        New-Item -Path $OutputFolder -ItemType Directory -Force | Out-Null
    }

    # PREPARATION - OUTPUT PATHS AND RESOURCES
    [System.String]$SafeBaseName = ($BaseName -replace '[\\/:*?""<>|]', '_')
    [System.String]$PngPath = Join-Path -Path $OutputFolder -ChildPath ($SafeBaseName + '.png')
    [System.String]$IcoPath = Join-Path -Path $OutputFolder -ChildPath ($SafeBaseName + '.ico')
    [System.String]$Extension = [System.IO.Path]::GetExtension($SourcePath).ToLowerInvariant()
    [System.Drawing.Icon]$Icon = $null
    [System.Drawing.Image]$Image = $null
    [System.Drawing.Bitmap]$Bitmap = $null
    [System.IO.FileStream]$IconStream = $null

    # EXECUTION - FORMAT-SPECIFIC CONVERSION
    try {
        if ($Extension -in @('.exe','.dll')) {
            $Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($SourcePath)
            if ($null -eq $Icon) { throw "No associated icon could be extracted. ($SourcePath)" }
            $Bitmap = $Icon.ToBitmap()
            $Bitmap.Save($PngPath,[System.Drawing.Imaging.ImageFormat]::Png)
            $IconStream = [System.IO.File]::Open($IcoPath,[System.IO.FileMode]::Create)
            $Icon.Save($IconStream)
        }
        elseif ($Extension -eq '.ico') {
            Copy-Item -LiteralPath $SourcePath -Destination $IcoPath -Force
            $Icon = New-Object System.Drawing.Icon($SourcePath)
            $Bitmap = $Icon.ToBitmap()
            $Bitmap.Save($PngPath,[System.Drawing.Imaging.ImageFormat]::Png)
        }
        elseif ($Extension -in @('.png','.jpg','.jpeg','.bmp','.gif')) {
            # WinForms shortcuts require ICO or executable resources. Convert before opening the source so the file is not locked.
            ConvertTo-IconFile -Path $SourcePath -Destination $IcoPath -Force | Out-Null
            $Image = [System.Drawing.Image]::FromFile($SourcePath)
            $Bitmap = New-Object System.Drawing.Bitmap($Image)
            $Bitmap.Save($PngPath,[System.Drawing.Imaging.ImageFormat]::Png)
        }
        else {
            throw "Unsupported icon source extension: ($Extension)"
        }
    }
    finally {
        if ($null -ne $IconStream) { $IconStream.Dispose() }
        if ($null -ne $Bitmap) { $Bitmap.Dispose() }
        if ($null -ne $Image) { $Image.Dispose() }
        if ($null -ne $Icon) { $Icon.Dispose() }
    }

    # VALIDATION - WRITTEN ICON FILES
    if (-not (Test-Path -LiteralPath $PngPath -PathType Leaf) -or -not (Test-Path -LiteralPath $IcoPath -PathType Leaf)) {
        throw 'The portable Custom Application icon files were not created.'
    }

    # OUTPUT - VERIFIED ICON ARTIFACTS
    return [PSCustomObject]@{
        SourcePath = $SourcePath
        PngPath    = $PngPath
        IcoPath    = $IcoPath
    }
}

### END OF FUNCTION
####################################################################################################