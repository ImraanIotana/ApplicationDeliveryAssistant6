####################################################################################################
<#
.SYNOPSIS
    Prepares a shared Application Intake folder workflow context.
.DESCRIPTION
    Validates the Application ID, output folder, and selected customer template; confirms replacement; creates the configured folder structure; and initializes lifecycle logging.
.EXAMPLE
    New-ApplicationFolderContext -ApplicationID 'Contoso_App_1.0' -OutputFolder 'C:\Applications'
.OUTPUTS
    [PSCustomObject] containing the folder path, selected template, and logging context; otherwise null.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.5.0
    Author          : Imraan Iotana
    Creation Date   : August 2026
    Last Update     : August 2026
#>
####################################################################################################
function New-ApplicationFolderContext {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [System.String]$ApplicationID,

        [Parameter(Mandatory=$false)]
        [System.String]$ApplicationFolderName,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [System.String]$OutputFolder,

        [Parameter(Mandatory=$false)]
        [System.Object]$SelectedTemplate
    )

    # VALIDATION - OUTPUT AND CUSTOMER TEMPLATE
    if (-not (Test-Path -LiteralPath $OutputFolder -PathType Container)) {
        throw "The output folder does not exist. ($OutputFolder)"
    }

    if ($null -eq $SelectedTemplate) {
        $SelectedTemplate = Get-ActiveCustomerTemplate
    }
    if ($null -eq $SelectedTemplate) {
        Write-Line 'No customer template selected. Please select a template first. No action has been taken.' -Type Warning
        return
    }

    [System.Object]$ApplicationFolderSubFolders = $SelectedTemplate.ApplicationFolderSubFolders
    if ($ApplicationFolderSubFolders -isnot [System.Collections.IDictionary]) {
        Write-Line 'The selected template has no ApplicationFolderSubFolders configuration. No action has been taken.' -Type Warning
        return
    }
    [System.String[]]$SubFolders = @($ApplicationFolderSubFolders.GetEnumerator() | Where-Object { $_.Value -is [System.String] } | ForEach-Object { [System.String]$_.Value } | Where-Object { Test-String -IsPopulated $_ })
    if ($SubFolders.Count -eq 0) {
        Write-Line 'The selected template defines no application subfolders. No action has been taken.' -Type Warning
        return
    }

    if (Test-String -IsEmpty $ApplicationFolderName) {
        $ApplicationFolderName = $ApplicationID
    }

    # PREPARATION - CONTAINED FINAL AND STAGING PATHS
    [System.String]$CanonicalOutputFolder = [System.IO.Path]::GetFullPath($OutputFolder).TrimEnd('\')
    [System.String]$FinalApplicationFolderPath = [System.IO.Path]::GetFullPath((Join-Path -Path $CanonicalOutputFolder -ChildPath $ApplicationFolderName))
    [System.String]$DestinationParentPath = [System.IO.Path]::GetDirectoryName($FinalApplicationFolderPath).TrimEnd('\')
    if (-not [System.String]::Equals($CanonicalOutputFolder,$DestinationParentPath,[System.StringComparison]::OrdinalIgnoreCase)) {
        throw 'The Application ID must resolve to one direct child folder beneath the configured output folder.'
    }

    # CONFIRMATION - CREATE OR REPLACE DESTINATION
    [System.Boolean]$FolderExists = Test-Path -LiteralPath $FinalApplicationFolderPath -PathType Container
    [System.String]$ConfirmationTitle = if ($FolderExists) { 'Confirm Overwrite Application Folder' } else { 'Create Application Folder' }
    [System.String]$ConfirmationAction = if ($FolderExists) { 'OVERWRITE the EXISTING APPLICATION FOLDER' } else { 'create a NEW APPLICATION FOLDER' }
    [System.String]$ConfirmationBody = "This will $ConfirmationAction with the following name:`n`n$ApplicationFolderName`n`nDo you want to continue?"
    if (-not (Get-UserConfirmation -Title $ConfirmationTitle -Body $ConfirmationBody)) { return }

    # Build in a sibling staging folder so an existing package remains intact until all required artifacts succeed.
    [System.String]$StagingFolderName = ".$ApplicationFolderName.partial-$([System.Guid]::NewGuid().ToString('N'))"
    [System.String]$ApplicationFolderPath = Join-Path -Path $CanonicalOutputFolder -ChildPath $StagingFolderName
    try {
        [System.String]$CanonicalStagingPrefix = [System.IO.Path]::GetFullPath($ApplicationFolderPath).TrimEnd('\') + '\'
        foreach ($SubFolder in $SubFolders) {
            [System.String]$CanonicalSubFolderPath = [System.IO.Path]::GetFullPath((Join-Path -Path $ApplicationFolderPath -ChildPath $SubFolder))
            if (-not $CanonicalSubFolderPath.StartsWith($CanonicalStagingPrefix,[System.StringComparison]::OrdinalIgnoreCase)) {
                throw "The selected template contains an unsafe application subfolder path. ($SubFolder)"
            }
        }

        Write-Line "Preparing application folder: $FinalApplicationFolderPath. One moment please..." -Type Busy
        New-ApplicationFolderStructure -ApplicationFolderPath $ApplicationFolderPath -SubFolders $SubFolders

        [System.Collections.Hashtable]$ApplicationLog = @{
            ApplicationID = $ApplicationID
            OperationID   = [System.Guid]::NewGuid().ToString()
        }
        $ApplicationLog.LogFilePath = New-ApplicationLogFile -ApplicationFolderPath $ApplicationFolderPath -SelectedTemplate $SelectedTemplate -OperationID $ApplicationLog.OperationID -ApplicationID $ApplicationID
        if (Test-String -IsEmpty $ApplicationLog.LogFilePath) {
            throw 'The application log file could not be initialized.'
        }
    }
    catch {
        if (Test-Path -LiteralPath $ApplicationFolderPath -PathType Container) {
            Remove-Item -LiteralPath $ApplicationFolderPath -Recurse -Force -ErrorAction Stop
        }
        throw
    }

    # OUTPUT - TRANSACTION CONTEXT
    return [PSCustomObject]@{
        ApplicationID        = $ApplicationID
        ApplicationFolderName = $ApplicationFolderName
        OutputFolder         = $CanonicalOutputFolder
        ApplicationFolderPath = $ApplicationFolderPath
        FinalApplicationFolderPath = $FinalApplicationFolderPath
        SelectedTemplate     = $SelectedTemplate
        ApplicationLog       = $ApplicationLog
    }
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Resolves and creates a template-configured application subfolder.
.OUTPUTS
    [System.String]
#>
####################################################################################################
function Get-ApplicationArtifactFolderPath {
    [CmdletBinding()]
    [OutputType([System.String])]
    param (
        [Parameter(Mandatory=$true)]
        [System.String]$ApplicationFolderPath,

        [Parameter(Mandatory=$true)]
        [System.Object]$SelectedTemplate,

        [Parameter(Mandatory=$true)]
        [System.String]$FolderName,

        [Parameter(Mandatory=$true)]
        [System.String]$DefaultRelativePath
    )

    # PREPARATION - TEMPLATE OR DEFAULT RELATIVE PATH
    [System.String]$RelativePath = ''
    [System.Object]$SubFolders = $SelectedTemplate.ApplicationFolderSubFolders
    if ($SubFolders -is [System.Collections.IDictionary] -and $SubFolders.Contains($FolderName)) {
        $RelativePath = [System.String]$SubFolders[$FolderName]
    }
    if (Test-String -IsEmpty $RelativePath) {
        $RelativePath = $DefaultRelativePath
        Write-Line "The selected customer template does not define ApplicationFolderSubFolders.$FolderName. Using default path: ($DefaultRelativePath)" -Type Warning
    }

    # VALIDATION - CONTAINED ARTIFACT PATH
    [System.String]$CanonicalApplicationFolderPath = [System.IO.Path]::GetFullPath($ApplicationFolderPath).TrimEnd('\')
    [System.String]$ResolvedPath = [System.IO.Path]::GetFullPath((Join-Path -Path $CanonicalApplicationFolderPath -ChildPath $RelativePath))
    if (-not $ResolvedPath.StartsWith(($CanonicalApplicationFolderPath + '\'),[System.StringComparison]::OrdinalIgnoreCase)) {
        throw "The selected template contains an unsafe artifact folder path. ($RelativePath)"
    }
    if (-not (Test-Path -LiteralPath $ResolvedPath -PathType Container)) {
        New-Item -Path $ResolvedPath -ItemType Directory -Force | Out-Null
    }
    # OUTPUT - VERIFIED ARTIFACT FOLDER
    return $ResolvedPath
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Converts a staging artifact path to its final published package path.
.OUTPUTS
    [System.String]
#>
####################################################################################################
function Get-PublishedApplicationArtifactPath {
    [CmdletBinding()]
    [OutputType([System.String])]
    param (
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Context,

        [Parameter(Mandatory=$true)]
        [System.String]$StagedPath
    )

    # VALIDATION - STAGED ARTIFACT CONTAINMENT
    [System.String]$CanonicalStagingRoot = [System.IO.Path]::GetFullPath($Context.ApplicationFolderPath).TrimEnd('\')
    [System.String]$CanonicalStagedPath = [System.IO.Path]::GetFullPath($StagedPath)
    [System.String]$RequiredPrefix = $CanonicalStagingRoot + '\'
    if (-not $CanonicalStagedPath.StartsWith($RequiredPrefix,[System.StringComparison]::OrdinalIgnoreCase)) {
        throw "The artifact path is outside the application staging folder. ($StagedPath)"
    }

    # OUTPUT - FINAL PUBLISHED PATH
    [System.String]$RelativePath = $CanonicalStagedPath.Substring($RequiredPrefix.Length)
    return Join-Path -Path $Context.FinalApplicationFolderPath -ChildPath $RelativePath
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Completes and logs a shared Application Intake folder workflow.
.OUTPUTS
    No objects are returned to the pipeline.
#>
####################################################################################################
function Complete-ApplicationFolderContext {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Context,

        [Parameter(Mandatory=$false)]
        [System.String]$Details = 'Completed initial application intake processing.',

        [Parameter(Mandatory=$false)]
        [System.String[]]$RequiredFilePaths = @()
    )

    # VALIDATION - REQUIRED ARTIFACTS
    foreach ($RequiredFilePath in $RequiredFilePaths) {
        if ((Test-String -IsEmpty $RequiredFilePath) -or -not (Test-Path -LiteralPath $RequiredFilePath -PathType Leaf)) {
            throw "A required application artifact was not created. ($RequiredFilePath)"
        }
    }

    # PowerShell 5.1 requires a variable name for hashtable splatting; object properties cannot be splatted directly.
    [System.Collections.Hashtable]$ApplicationLog = $Context.ApplicationLog
    Write-ApplicationLogEntry @ApplicationLog -Status Success -Action ApplicationIntakeCompleted -Details $Details

    # EXECUTION - TRANSACTIONAL PUBLICATION
    [System.String]$BackupFolderPath = ''
    try {
        if (Test-Path -LiteralPath $Context.FinalApplicationFolderPath -PathType Container) {
            $BackupFolderPath = "$($Context.FinalApplicationFolderPath).backup-$([System.Guid]::NewGuid().ToString('N'))"
            Move-Item -LiteralPath $Context.FinalApplicationFolderPath -Destination $BackupFolderPath -Force -ErrorAction Stop
        }
        Move-Item -LiteralPath $Context.ApplicationFolderPath -Destination $Context.FinalApplicationFolderPath -Force -ErrorAction Stop
    }
    catch {
        if (-not (Test-Path -LiteralPath $Context.FinalApplicationFolderPath) -and
            (Test-String -IsPopulated $BackupFolderPath) -and
            (Test-Path -LiteralPath $BackupFolderPath -PathType Container)) {
            Move-Item -LiteralPath $BackupFolderPath -Destination $Context.FinalApplicationFolderPath -Force -ErrorAction Stop
        }
        throw
    }

    # Publication is committed once staging is moved; backup cleanup must not turn that success into a false rollback failure.
    if (Test-String -IsPopulated $BackupFolderPath) {
        try {
            Remove-Item -LiteralPath $BackupFolderPath -Recurse -Force -ErrorAction Stop
        }
        catch {
            Write-Line "The new application folder was published, but its backup could not be removed. ($BackupFolderPath)" -Type Warning
        }
    }

    # POST-EXECUTION - REPORT COMMITTED PUBLICATION
    Write-Line "The new application folder has been created. ($($Context.ApplicationID))" -Type Success
    Open-Folder -Path $Context.OutputFolder
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Removes an unpublished Application Intake staging folder.
#>
####################################################################################################
function Remove-ApplicationFolderContextStaging {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false)]
        [AllowNull()]
        [PSCustomObject]$Context
    )

    # EXECUTION - REMOVE UNPUBLISHED STAGING DATA
    if ($null -ne $Context -and
        (Test-String -IsPopulated $Context.ApplicationFolderPath) -and
        (Test-Path -LiteralPath $Context.ApplicationFolderPath -PathType Container)) {
        Remove-Item -LiteralPath $Context.ApplicationFolderPath -Recurse -Force -ErrorAction Stop
    }
}

### END OF FUNCTION
####################################################################################################