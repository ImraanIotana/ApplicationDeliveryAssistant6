####################################################################################################
<#
.SYNOPSIS
    Provides driver package staging and installation helpers.
.DESCRIPTION
    Tests whether exact driver INF packages are staged or assigned to devices, and uses elevated
    PnPUtil operations to add packages to the Windows Driver Store, optionally installing them on
    compatible connected devices.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.2.0
    Author          : Imraan Iotana
    Creation Date   : August 2026
    Last Update     : August 2026
#>
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Tests whether an exact driver INF package is staged or assigned to devices.
.DESCRIPTION
    Compares the selected INF SHA-256 hash with published OEM INF files and Driver Store INF files.
    Matching published packages are correlated with signed-device records to distinguish a package
    that is staged in the Driver Store from one that is assigned to devices.
.EXAMPLE
    Test-DriverPackageInstallation -InfPath 'C:\Drivers\Example\driver.inf'
.EXAMPLE
    $State = Test-DriverPackageInstallation -InfPath 'C:\Drivers\Example\driver.inf' -PassThru
.INPUTS
    [System.String]
.OUTPUTS
    [PSCustomObject] when PassThru is specified; otherwise no objects are returned to the pipeline.
#>
####################################################################################################
function Test-DriverPackageInstallation {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The driver INF file to test against the Windows Driver Store.')]
        [AllowNull()][AllowEmptyString()]
        [System.String]$InfPath,

        [Parameter(Mandatory=$false,HelpMessage='Returns the structured installation state after writing the status report.')]
        [System.Management.Automation.SwitchParameter]$PassThru
    )

    try {
        # VALIDATION - DRIVER INF
        if (-not (Confirm-FileExtension -Path $InfPath -Name 'Driver INF File' -AllowedExtensions @('.inf'))) {
            return
        }
        [System.IO.FileInfo]$SourceInfFile = Get-Item -LiteralPath $InfPath -ErrorAction Stop

        # EXECUTION - EXACT PACKAGE MATCHING
        Write-Line "Checking whether driver package $($SourceInfFile.Name) is already available, one moment please..." -Type Busy
        [System.String]$SourceInfHash = [System.String](Get-FileHash -LiteralPath $SourceInfFile.FullName -Algorithm SHA256 -ErrorAction Stop).Hash
        [System.String]$PublishedInfRoot = Join-Path -Path $env:WINDIR -ChildPath 'INF'
        [System.IO.FileInfo[]]$PublishedInfFiles = @(Get-ChildItem -LiteralPath $PublishedInfRoot -Filter 'oem*.inf' -File -ErrorAction Stop)
        [System.String[]]$PublishedInfNames = @(
            foreach ($PublishedInfFile in $PublishedInfFiles) {
                [System.String]$PublishedInfHash = [System.String](Get-FileHash -LiteralPath $PublishedInfFile.FullName -Algorithm SHA256 -ErrorAction Stop).Hash
                if ($PublishedInfHash -eq $SourceInfHash) {
                    [System.String]$PublishedInfFile.Name
                }
            }
        )

        [System.Collections.Hashtable]$DriverStoreLookup = Get-DriverStoreFolderLookup
        [PSCustomObject[]]$DriverStoreMatches = if ($DriverStoreLookup.ContainsKey($SourceInfHash)) {
            @($DriverStoreLookup[$SourceInfHash])
        }
        else {
            @()
        }
        [System.String[]]$DriverStorePaths = @($DriverStoreMatches.Path | Sort-Object -Unique)

        # EXECUTION - DEVICE ASSIGNMENTS
        [PSCustomObject[]]$AssociatedDevices = @(
            foreach ($PublishedInfName in $PublishedInfNames) {
                Get-DriverAssociatedDeviceInventory -PublishedInfName $PublishedInfName
            }
        )
        [PSCustomObject[]]$UniqueAssociatedDevices = @(
            $AssociatedDevices | Sort-Object InstanceId -Unique
        )
        [PSCustomObject[]]$PresentDevices = @($UniqueAssociatedDevices | Where-Object { $_.Present -eq $true })

        # OUTPUT - STRUCTURED STATE
        [PSCustomObject]$InstallationState = [PSCustomObject][ordered]@{
            SourceInfPath           = [System.String]$SourceInfFile.FullName
            SourceInfSha256         = $SourceInfHash
            IsStaged                = (($PublishedInfNames.Count -gt 0) -or ($DriverStorePaths.Count -gt 0))
            PublishedInfNames       = @($PublishedInfNames)
            DriverStorePaths        = @($DriverStorePaths)
            IsAssignedToDevices     = ($UniqueAssociatedDevices.Count -gt 0)
            AssociatedDeviceCount   = $UniqueAssociatedDevices.Count
            PresentDeviceCount      = $PresentDevices.Count
            AssociatedDevices       = @($UniqueAssociatedDevices)
        }

        # OUTPUT - HOST REPORT
        Write-Line ''
        Write-Line 'DRIVER PACKAGE INSTALLATION STATUS' -Type Special
        Write-Line ("Source INF`t`t: {0}" -f $InstallationState.SourceInfPath)
        Write-Line ("SHA-256`t`t`t: {0}" -f $InstallationState.SourceInfSha256)
        Write-Line ("In Driver Store`t`t: {0}" -f $(if ($InstallationState.IsStaged) { 'Yes' } else { 'No' }))
        Write-Line ("Published INF`t`t: {0}" -f $(if ($PublishedInfNames.Count -gt 0) { $PublishedInfNames -join ', ' } else { 'None' }))
        Write-Line ("Driver Store Folders`t: {0}" -f $DriverStorePaths.Count)
        Write-Line ("Assigned to Devices`t: {0}" -f $(if ($InstallationState.IsAssignedToDevices) { 'Yes' } else { 'No' }))
        Write-Line ("Associated Devices`t: {0}" -f $InstallationState.AssociatedDeviceCount)
        Write-Line ("Present Devices`t`t: {0}" -f $InstallationState.PresentDeviceCount)
        Write-Line ''
        if ($InstallationState.IsStaged) {
            Write-Line 'The exact driver package is already available in the Windows Driver Store.' -Type Success
        }
        else {
            Write-Line 'The exact driver package is not currently available in the Windows Driver Store.' -Type Warning
        }

        if ($PassThru.IsPresent) {
            $InstallationState
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
    Adds a driver package to the Windows Driver Store and optionally installs it.
.DESCRIPTION
    Validates one INF file, confirms the requested operation, and starts elevated PnPUtil with
    /add-driver. When Install is specified, /install is added so Windows applies the package to
    compatible connected devices. Cancelling the UAC prompt is handled as a normal cancellation.
.EXAMPLE
    Add-DriverPackage -InfPath 'C:\Drivers\Example\driver.inf'
.EXAMPLE
    Add-DriverPackage -InfPath 'C:\Drivers\Example\driver.inf' -Install
.INPUTS
    [System.String]
.OUTPUTS
    No objects are returned to the pipeline.
#>
####################################################################################################
function Add-DriverPackage {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The driver INF file to add to the Windows Driver Store.')]
        [AllowNull()][AllowEmptyString()]
        [System.String]$InfPath,

        [Parameter(Mandatory=$false,HelpMessage='Installs the added package on compatible connected devices.')]
        [System.Management.Automation.SwitchParameter]$Install
    )

    try {
        # VALIDATION - DRIVER INF
        if (-not (Confirm-FileExtension -Path $InfPath -Name 'Driver INF File' -AllowedExtensions @('.inf'))) {
            return
        }
        [System.String]$ResolvedInfPath = [System.String](Get-Item -LiteralPath $InfPath -ErrorAction Stop).FullName

        # CONFIRMATION
        [System.String]$OperationDescription = if ($Install.IsPresent) {
            'add this driver package to the Windows Driver Store and install it on compatible connected devices'
        }
        else {
            'add this driver package to the Windows Driver Store for later use without updating connected devices now'
        }
        [System.String]$ConfirmationBody = "This will $($OperationDescription):`n`n$ResolvedInfPath`n`nWindows will request administrator approval.`n`nDo you want to continue?"
        if (-not (Get-UserConfirmation -Title 'Add Driver Package' -Body $ConfirmationBody -Type Warning)) {
            return
        }

        # EXECUTION
        [System.Management.Automation.ApplicationInfo]$PnPUtilCommand = Get-Command -Name 'pnputil.exe' -CommandType Application -ErrorAction Stop
        [System.String]$ActionText = if ($Install.IsPresent) { 'add and install' } else { 'add' }
        Write-Line "Requesting administrator approval to $ActionText driver package $([System.IO.Path]::GetFileName($ResolvedInfPath))..." -Type Busy
        try {
            [System.Diagnostics.ProcessStartInfo]$ProcessStartInfo = New-Object System.Diagnostics.ProcessStartInfo
            $ProcessStartInfo.FileName = $PnPUtilCommand.Source
            $ProcessStartInfo.Arguments = "/add-driver `"$ResolvedInfPath`"$(if ($Install.IsPresent) { ' /install' } else { '' })"
            $ProcessStartInfo.Verb = 'runas'
            $ProcessStartInfo.UseShellExecute = $true
            [System.Diagnostics.Process]$PnPUtilProcess = [System.Diagnostics.Process]::Start($ProcessStartInfo)
            $PnPUtilProcess.WaitForExit()
        }
        catch {
            [System.Exception]$ProcessException = $_.Exception
            while ($null -ne $ProcessException) {
                if (($ProcessException -is [System.ComponentModel.Win32Exception]) -and ($ProcessException.NativeErrorCode -eq 1223)) {
                    Write-Line 'Driver package addition was cancelled at the administrator approval prompt.' -Type Warning
                    return
                }
                $ProcessException = $ProcessException.InnerException
            }
            throw
        }

        if ($PnPUtilProcess.ExitCode -ne 0) {
            throw "PnPUtil driver package addition failed with exit code $($PnPUtilProcess.ExitCode)."
        }

        # POST-EXECUTION
        if ($Install.IsPresent) {
            Write-Line "Driver package added and installed successfully. ($ResolvedInfPath)" -Type Success
        }
        else {
            Write-Line "Driver package added to the Windows Driver Store successfully. ($ResolvedInfPath)" -Type Success
        }
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}

### END OF FUNCTION
####################################################################################################