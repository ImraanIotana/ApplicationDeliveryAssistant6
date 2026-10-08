####################################################################################################
<#
.SYNOPSIS
    Provides validated transactional directory updates.
.DESCRIPTION
    Stages a complete directory copy, applies caller-defined changes, validates the staged result,
    and publishes it while retaining the original directory for rollback.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.2.0
    Author          : Imraan Iotana
    Creation Date   : August 2026
    Last Update     : August 2026
#>
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Publishes a validated update to an existing directory.
.DESCRIPTION
    Copies the source directory to a sibling staging directory, invokes the update and validation
    callbacks against staging, then replaces the destination. The original is restored when final
    publication fails.
.EXAMPLE
    Invoke-ValidatedDirectoryUpdate -DirectoryPath $Path -UpdateAction { param($Stage) } -ValidationAction { param($Stage) }
.OUTPUTS
    [System.Boolean]
#>
####################################################################################################
function Invoke-ValidatedDirectoryUpdate {
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='Existing directory that will be updated.')]
        [System.String]$DirectoryPath,

        [Parameter(Mandatory=$true,HelpMessage='Callback that writes changes into the staged directory.')]
        [System.Management.Automation.ScriptBlock]$UpdateAction,

        [Parameter(Mandatory=$true,HelpMessage='Callback that throws when the staged directory is invalid.')]
        [System.Management.Automation.ScriptBlock]$ValidationAction
    )

    [System.String]$ResolvedDirectory = [System.IO.Path]::GetFullPath($DirectoryPath).TrimEnd([System.IO.Path]::DirectorySeparatorChar,[System.IO.Path]::AltDirectorySeparatorChar)
    if (-not (Test-Path -LiteralPath $ResolvedDirectory -PathType Container)) {
        throw "The directory to update does not exist: $ResolvedDirectory"
    }

    [System.String]$ParentDirectory = [System.IO.Path]::GetDirectoryName($ResolvedDirectory)
    [System.String]$DirectoryName = [System.IO.Path]::GetFileName($ResolvedDirectory)
    [System.String]$OperationId = [System.Guid]::NewGuid().ToString('N')
    [System.String]$StagingDirectory = Join-Path -Path $ParentDirectory -ChildPath ".$DirectoryName.edit-partial-$OperationId"
    [System.String]$BackupDirectory = Join-Path -Path $ParentDirectory -ChildPath ".$DirectoryName.edit-backup-$OperationId"
    [System.Boolean]$OriginalMoved = $false

    try {
        Copy-Item -LiteralPath $ResolvedDirectory -Destination $StagingDirectory -Recurse -Force -ErrorAction Stop
        & $UpdateAction $StagingDirectory
        & $ValidationAction $StagingDirectory

        Move-Item -LiteralPath $ResolvedDirectory -Destination $BackupDirectory -ErrorAction Stop
        $OriginalMoved = $true
        Move-Item -LiteralPath $StagingDirectory -Destination $ResolvedDirectory -ErrorAction Stop
        $OriginalMoved = $false
        Remove-Item -LiteralPath $BackupDirectory -Recurse -Force -ErrorAction Stop
        return $true
    }
    catch {
        if ($OriginalMoved -and (-not (Test-Path -LiteralPath $ResolvedDirectory)) -and (Test-Path -LiteralPath $BackupDirectory -PathType Container)) {
            Move-Item -LiteralPath $BackupDirectory -Destination $ResolvedDirectory -ErrorAction SilentlyContinue
        }
        throw
    }
    finally {
        foreach ($TemporaryDirectory in @($StagingDirectory,$BackupDirectory)) {
            if (Test-Path -LiteralPath $TemporaryDirectory -PathType Container) {
                Remove-Item -LiteralPath $TemporaryDirectory -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
}

### END OF FUNCTION
####################################################################################################
