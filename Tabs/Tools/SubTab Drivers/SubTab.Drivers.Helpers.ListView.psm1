####################################################################################################
<#
.SYNOPSIS
    Provides Driver Management ListView and selected-package presentation helpers.
.DESCRIPTION
    Handles typed sorting, selected package actions, host details, cached inventory, and ListView refresh behavior.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.3.4
    Author          : Imraan Iotana
    Creation Date   : August 2026
    Last Update     : August 2026
#>
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Returns the canonical Driver Results ListView column schema.
.DESCRIPTION
    Keeps column labels, driver property bindings, and typed sort behavior in one ordered schema.
.EXAMPLE
    Get-DriverListViewColumnSchema
.OUTPUTS
    [PSCustomObject[]]
#>
####################################################################################################
function Get-DriverListViewColumnSchema {
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param ()

    @(
        [PSCustomObject]@{ Label = '#';                 PropertyName = '';                     SortType = 'Integer' }
        [PSCustomObject]@{ Label = 'Provider';          PropertyName = 'ProviderName';         SortType = 'Text' }
        [PSCustomObject]@{ Label = 'Original INF';      PropertyName = 'OriginalName';         SortType = 'Text' }
        [PSCustomObject]@{ Label = 'Version';           PropertyName = 'Version';              SortType = 'Version' }
        [PSCustomObject]@{ Label = 'Installation Date'; PropertyName = 'InstallationDateText'; SortType = 'Date' }
        [PSCustomObject]@{ Label = 'Class';             PropertyName = 'ClassName';            SortType = 'Text' }
        [PSCustomObject]@{ Label = 'Published INF';     PropertyName = 'DriverName';           SortType = 'Text' }
        [PSCustomObject]@{ Label = 'Driver Date';       PropertyName = 'DriverDate';           SortType = 'Date' }
        [PSCustomObject]@{ Label = 'Signer';            PropertyName = 'SignerName';           SortType = 'Text' }
    )
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Returns the driver package attached to the selected Driver Results row.
.DESCRIPTION
    Centralizes selection and ListViewItem Tag validation for all selected-package actions.
.EXAMPLE
    Get-SelectedDriverPackage -ListView $DriverResultsListView
.INPUTS
    [System.Windows.Forms.ListView]
.OUTPUTS
    [PSCustomObject]
#>
####################################################################################################
function Get-SelectedDriverPackage {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The Driver Results ListView containing the selected package.')]
        [System.Windows.Forms.ListView]$ListView
    )

    if (($null -eq $ListView) -or ($null -eq $ListView.SelectedItems) -or ($ListView.SelectedItems.Count -lt 1)) {
        Write-Line 'No driver package is selected.' -Type Warning
        return $null
    }

    [PSCustomObject]$Driver = $ListView.SelectedItems[0].Tag
    if ($null -eq $Driver) {
        Write-Line 'The selected driver row does not contain package details.' -Type Warning
        return $null
    }

    $Driver
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Enables typed column sorting for the Driver Results ListView.
.DESCRIPTION
    Attaches one ColumnClick handler that sorts text, integer, version, and date columns. Clicking
    the active column reverses its direction; clicking a different column starts ascending.
.EXAMPLE
    Enable-DriverListViewSorting -ListView $DriverResultsListView
.INPUTS
    [System.Windows.Forms.ListView]
.OUTPUTS
    No objects are returned to the pipeline.
#>
####################################################################################################
function Enable-DriverListViewSorting {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The Driver Results ListView that receives column sorting.')]
        [System.Windows.Forms.ListView]$ListView
    )

    Enable-ListViewColumnSorting -ListView $ListView -ColumnTypes @((Get-DriverListViewColumnSchema).SortType) -MetadataPrefix 'Driver'
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Opens the Driver Store folder for the selected driver package.
.DESCRIPTION
    Reads the cached StorePath from the selected ListViewItem and opens the package folder through
    the shared Open-Folder helper.
.EXAMPLE
    Open-SelectedDriverStoreFolder -ListView $DriverResultsListView
.INPUTS
    [System.Windows.Forms.ListView]
.OUTPUTS
    No objects are returned to the pipeline.
#>
####################################################################################################
function Open-SelectedDriverStoreFolder {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The Driver Results ListView containing the selected package.')]
        [System.Windows.Forms.ListView]$ListView
    )

    try {
        # VALIDATION - LISTVIEW SELECTION
        [PSCustomObject]$Driver = Get-SelectedDriverPackage -ListView $ListView
        if ($null -eq $Driver) { return }

        [System.String]$StorePath = [System.String]$Driver.StorePath
        if ([System.String]::IsNullOrWhiteSpace($StorePath)) {
            Write-Line 'No Driver Store folder is available for the selected driver package.' -Type Warning
            return
        }
        if (-not (Test-Path -LiteralPath $StorePath -PathType Container)) {
            Write-Line "The Driver Store folder could not be found or reached. ($StorePath)" -Type Warning
            return
        }

        # EXECUTION
        Open-Folder -Path $StorePath
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
    Removes the selected driver package from the Windows Driver Store.
.DESCRIPTION
    Confirms the destructive action, starts elevated PnPUtil with /delete-driver and /uninstall,
    handles a cancelled UAC prompt without reporting an application error, and refreshes the
    driver inventory after successful removal. The package is not forcibly removed when in use.
.EXAMPLE
    Remove-SelectedDriverPackage -ListView $DriverResultsListView -SearchTerm 'Intel'
.INPUTS
    [System.Windows.Forms.ListView]
    [System.String]
.OUTPUTS
    No objects are returned to the pipeline.
#>
####################################################################################################
function Remove-SelectedDriverPackage {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The Driver Results ListView containing the selected package.')]
        [System.Windows.Forms.ListView]$ListView,

        [Parameter(Mandatory=$false,HelpMessage='The search term reapplied after successful removal.')]
        [AllowNull()][AllowEmptyString()]
        [System.String]$SearchTerm
    )

    try {
        # VALIDATION - SELECTED DRIVER
        [PSCustomObject]$Driver = Get-SelectedDriverPackage -ListView $ListView
        if ($null -eq $Driver) { return }

        [System.String]$PublishedInfName = [System.String]$Driver.DriverName
        if ($PublishedInfName -notmatch '^oem\d+\.inf$') {
            Write-Line "The published INF name is not valid for driver removal. ($PublishedInfName)" -Type Warning
            return
        }

        # CONFIRMATION
        [System.String]$ConfirmationBody = "This will remove the driver package from the Windows Driver Store and uninstall it from matching devices:`n`n$PublishedInfName`n$([System.String]$Driver.ProviderName)`n$([System.String]$Driver.Version)`n`nWindows will request administrator approval. The package will not be forcibly removed if it is still in use.`n`nDo you want to continue?"
        if (-not (Get-UserConfirmation -Title 'Remove Driver Package' -Body $ConfirmationBody -Type Warning)) {
            return
        }

        # EXECUTION
        [System.Management.Automation.ApplicationInfo]$PnPUtilCommand = Get-Command -Name 'pnputil.exe' -CommandType Application -ErrorAction Stop
        Write-Line "Requesting administrator approval to remove driver package $PublishedInfName..." -Type Busy
        try {
            [System.Diagnostics.ProcessStartInfo]$ProcessStartInfo = New-Object System.Diagnostics.ProcessStartInfo
            $ProcessStartInfo.FileName = $PnPUtilCommand.Source
            $ProcessStartInfo.Arguments = "/delete-driver $PublishedInfName /uninstall"
            $ProcessStartInfo.Verb = 'runas'
            $ProcessStartInfo.UseShellExecute = $true
            [System.Diagnostics.Process]$PnPUtilProcess = [System.Diagnostics.Process]::Start($ProcessStartInfo)
            $PnPUtilProcess.WaitForExit()
        }
        catch {
            [System.Exception]$ProcessException = $_.Exception
            while ($null -ne $ProcessException) {
                if (($ProcessException -is [System.ComponentModel.Win32Exception]) -and ($ProcessException.NativeErrorCode -eq 1223)) {
                    Write-Line 'Driver package removal was cancelled at the administrator approval prompt.' -Type Warning
                    return
                }
                $ProcessException = $ProcessException.InnerException
            }
            throw
        }

        if ($PnPUtilProcess.ExitCode -ne 0) {
            throw "PnPUtil driver removal failed with exit code $($PnPUtilProcess.ExitCode)."
        }

        # POST-EXECUTION
        Write-Line "Driver package removed successfully. ($PublishedInfName)" -Type Success
        Invoke-DriverSearchResultsRefresh -ListView $ListView -SearchTerm $SearchTerm -RefreshCache
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
    Writes details for the selected driver package to the application host.
.DESCRIPTION
    Reads the normalized driver object stored in the selected ListViewItem Tag and reports package,
    signing, local Driver Store information, and live state for associated devices.
.EXAMPLE
    Write-SelectedDriverDetailsToHost -ListView $DriverResultsListView
.INPUTS
    [System.Windows.Forms.ListView]
.OUTPUTS
    No objects are returned to the pipeline.
#>
####################################################################################################
function Write-SelectedDriverDetailsToHost {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The Driver Results ListView containing the selected package.')]
        [System.Windows.Forms.ListView]$ListView,

        [Parameter(Mandatory=$false,HelpMessage='Returns cached package information without querying associated hardware devices.')]
        [System.Management.Automation.SwitchParameter]$Quick
    )

    try {
        # VALIDATION - LISTVIEW SELECTION
        [PSCustomObject]$Driver = Get-SelectedDriverPackage -ListView $ListView
        if ($null -eq $Driver) { return }

        # PREPARATION - DISPLAY VALUES
        # Resolve optional values and determine whether the approximate installation date is recent.
        [System.String]$InstallationDateText = if ([System.String]::IsNullOrWhiteSpace([System.String]$Driver.InstallationDateText)) { 'Unknown' } else { [System.String]$Driver.InstallationDateText }
        [System.String]$StorePath = if ([System.String]::IsNullOrWhiteSpace([System.String]$Driver.StorePath)) { 'Unknown' } else { [System.String]$Driver.StorePath }
        [System.String]$RecentPackage = 'Unknown'
        [System.String]$PackageAge = 'Unknown'
        if ($null -ne $Driver.InstallationDate) {
            [System.DateTime]$Now = Get-Date
            [System.DateTime]$RecentStartDate = $Now.AddDays(-7)
            $RecentPackage = if (([System.DateTime]$Driver.InstallationDate -ge $RecentStartDate) -and ([System.DateTime]$Driver.InstallationDate -le $Now)) { 'Yes' } else { 'No' }
            [System.Int32]$PackageAgeDays = [System.Math]::Max(0, [System.Int32]$Now.Date.Subtract(([System.DateTime]$Driver.InstallationDate).Date).TotalDays)
            $PackageAge = "$PackageAgeDays days"
        }
        [System.String]$DriverAge = 'Unknown'
        [System.DateTime]$ParsedDriverDate = [System.DateTime]::MinValue
        if ([System.DateTime]::TryParseExact([System.String]$Driver.DriverDate, 'yyyy-MM-dd', [System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::None, [ref]$ParsedDriverDate)) {
            [System.Int32]$DriverAgeDays = [System.Math]::Max(0, [System.Int32](Get-Date).Date.Subtract($ParsedDriverDate.Date).TotalDays)
            $DriverAge = "$DriverAgeDays days"
        }
        [System.String]$MicrosoftPackage = if (([System.String]$Driver.ProviderName).IndexOf('Microsoft', [System.StringComparison]::OrdinalIgnoreCase) -ge 0) { 'Yes' } else { 'No' }
        [PSCustomObject]$PackageDetails = Get-DriverPackageQuickDetails -StorePath ([System.String]$Driver.StorePath)

        # OUTPUT - DRIVER PACKAGE
        # Write the cached package metadata in a stable, readable layout.
        Write-Line ''
        Write-Line 'DRIVER PACKAGE' -Type Special
        Write-Line ("Provider`t`t: {0}" -f [System.String]$Driver.ProviderName)
        Write-Line ("Original INF`t`t: {0}" -f [System.String]$Driver.OriginalName)
        Write-Line ("Published INF`t`t: {0}" -f [System.String]$Driver.DriverName)
        Write-Line ("Version`t`t`t: {0}" -f [System.String]$Driver.Version)
        Write-Line ("Driver Date`t`t: {0}" -f [System.String]$Driver.DriverDate)
        Write-Line ("Driver Age`t`t: {0}" -f $DriverAge)

        # OUTPUT - DRIVER CLASSIFICATION
        Write-Line ''
        Write-Line 'DRIVER CLASSIFICATION' -Type Special
        Write-Line ("Class`t`t`t: {0}" -f [System.String]$Driver.ClassName)
        Write-Line ("Class GUID`t`t: {0}" -f [System.String]$Driver.ClassGuid)
        Write-Line ("Architecture`t`t: {0}" -f [System.String]$PackageDetails.Architecture)
        Write-Line ("Microsoft Package`t: {0}" -f $MicrosoftPackage)

        # OUTPUT - DRIVER SIGNING
        Write-Line ''
        Write-Line 'DRIVER SIGNING' -Type Special
        Write-Line ("Signed`t`t`t: {0}" -f [System.String]$PackageDetails.Signed)
        Write-Line ("Signature Status`t: {0}" -f [System.String]$PackageDetails.SignatureStatus)
        Write-Line ("Signer`t`t`t: {0}" -f [System.String]$Driver.SignerName)
        Write-Line ("Catalog Files`t`t: {0}" -f [System.String]$PackageDetails.CatalogFiles)

        # OUTPUT - PACKAGE CONTENTS
        Write-Line ''
        Write-Line 'PACKAGE CONTENTS' -Type Special
        Write-Line ("Package Size`t`t: {0}" -f [System.String]$PackageDetails.PackageSizeText)
        Write-Line ("File Count`t`t: {0}" -f [System.Int32]$PackageDetails.FileCount)
        Write-Line ("INF Files`t`t: {0}" -f [System.String]$PackageDetails.InfFiles)

        # OUTPUT - LOCAL DRIVER STORE
        # Clarify that Installation Date is inferred from the package folder creation timestamp.
        Write-Line ''
        Write-Line 'LOCAL DRIVER STORE' -Type Special
        Write-Line ("Installation Date`t: {0}" -f $InstallationDateText)
        Write-Line ("Package Age`t`t: {0}" -f $PackageAge)
        Write-Line ("Recent Package`t`t: {0}" -f $RecentPackage)
        Write-Line ("Driver Store Folder`t: {0}" -f $StorePath)
        Write-Line "Date Source`t`t: Driver Store folder CreationTime (approximate)" -Type Warning

        if ($Quick.IsPresent) {
            Write-Line ''
            Write-Line '-------------------- End of driver information --------------------' -Type Success
            return
        }

        # OUTPUT - ASSOCIATED DEVICES
        # Query live PnP state only when details are requested and summarize it before listing devices.
        Write-Line 'Obtaining driver information, one moment please...' -Type Busy
        [PSCustomObject[]]$AssociatedDevices = @(Get-DriverAssociatedDeviceInventory -PublishedInfName ([System.String]$Driver.DriverName))
        [PSCustomObject]$DeviceSummary = Get-DriverAssociatedDeviceSummary -AssociatedDevices $AssociatedDevices -PackageVersion ([System.String]$Driver.Version)

        Write-Line ''
        Write-Line 'ASSOCIATED DEVICES' -Type Special
        Write-Line ("Associated Devices`t: {0}" -f $DeviceSummary.AssociatedCount)
        Write-Line ("Present Devices`t`t: {0}" -f $DeviceSummary.PresentCount)
        Write-Line ("Started Devices`t`t: {0}" -f $DeviceSummary.StartedCount)
        Write-Line ("Working Devices`t`t: {0}" -f $DeviceSummary.WorkingCount)
        Write-Line ("Devices With Problems`t: {0}" -f $DeviceSummary.ProblemCount)
        Write-Line ("Not Present`t`t: {0}" -f $DeviceSummary.NotPresentCount)
        Write-Line ("Using Selected Version`t: {0}" -f $DeviceSummary.MatchingVersionCount)

        [System.Int32]$DeviceNumber = 1
        foreach ($AssociatedDevice in $AssociatedDevices) {
            [System.String]$PresentText = if ($null -eq $AssociatedDevice.Present) { 'Unknown' } elseif ([System.Boolean]$AssociatedDevice.Present) { 'Yes' } else { 'No' }
            [System.String]$StartedText = if ($null -eq $AssociatedDevice.Started) { 'Unknown' } elseif ([System.Boolean]$AssociatedDevice.Started) { 'Yes' } else { 'No' }
            [System.String]$ProblemText = if ([System.String]::IsNullOrWhiteSpace([System.String]$AssociatedDevice.Problem)) { 'Unknown' } else { [System.String]$AssociatedDevice.Problem }
            [System.String]$ConfigurationCodeText = if ([System.String]::IsNullOrWhiteSpace([System.String]$AssociatedDevice.ConfigurationCode)) { 'Unknown' } else { [System.String]$AssociatedDevice.ConfigurationCode }
            [System.String]$LocationText = if ([System.String]::IsNullOrWhiteSpace([System.String]$AssociatedDevice.Location)) { 'Unknown' } else { [System.String]$AssociatedDevice.Location }
            [System.String]$ServiceText = if ([System.String]::IsNullOrWhiteSpace([System.String]$AssociatedDevice.Service)) { 'Unknown' } else { [System.String]$AssociatedDevice.Service }
            [System.String]$HardwareIdsText = if ([System.String]::IsNullOrWhiteSpace([System.String]$AssociatedDevice.HardwareIds)) { 'Unknown' } else { [System.String]$AssociatedDevice.HardwareIds }
            [System.String]$InstalledVersionText = if ([System.String]::IsNullOrWhiteSpace([System.String]$AssociatedDevice.InstalledVersion)) { 'Unknown' } else { [System.String]$AssociatedDevice.InstalledVersion }
            [System.String]$VersionMatchText = if ($InstalledVersionText -eq 'Unknown') { 'Unknown' } elseif ($InstalledVersionText -eq [System.String]$Driver.Version) { 'Yes' } else { 'No' }

            Write-Line ''
            Write-Line ("DEVICE {0}" -f $DeviceNumber) -Type Special
            Write-Line ("Name`t`t`t: {0}" -f [System.String]$AssociatedDevice.Name)
            Write-Line ("Manufacturer`t`t: {0}" -f [System.String]$AssociatedDevice.Manufacturer)
            Write-Line ("Class`t`t`t: {0}" -f [System.String]$AssociatedDevice.Class)
            Write-Line ("Present`t`t`t: {0}" -f $PresentText)
            Write-Line ("Started`t`t`t: {0}" -f $StartedText)
            Write-Line ("Status`t`t`t: {0}" -f [System.String]$AssociatedDevice.Status)
            Write-Line ("Problem`t`t`t: {0}" -f $ProblemText)
            Write-Line ("Configuration Code`t: {0}" -f $ConfigurationCodeText)
            Write-Line ("Location`t`t: {0}" -f $LocationText)
            Write-Line ("Service`t`t`t: {0}" -f $ServiceText)
            Write-Line ("Hardware IDs`t`t: {0}" -f $HardwareIdsText)
            Write-Line ("Installed Version`t: {0}" -f $InstalledVersionText)
            Write-Line ("Package Version`t`t: {0}" -f [System.String]$Driver.Version)
            Write-Line ("Version Match`t`t: {0}" -f $VersionMatchText)
            Write-Line ("Instance ID`t`t: {0}" -f [System.String]$AssociatedDevice.InstanceId)
            $DeviceNumber++
        }

        Write-Line ''
        Write-Line '-------------------- End of driver information --------------------' -Type Success
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
    Refreshes the Driver Results ListView using cached or newly enumerated driver data.
.DESCRIPTION
    Loads and caches inventory when necessary, applies the optional search term, and fills the
    ListView in one paint cycle. Empty search text displays all cached drivers.
.EXAMPLE
    Invoke-DriverSearchResultsRefresh -ListView $DriverResultsListView -SearchTerm 'Intel'
.INPUTS
    [System.Windows.Forms.ListView]
    [System.String]
.OUTPUTS
    No objects are returned to the pipeline.
#>
####################################################################################################
function Invoke-DriverSearchResultsRefresh {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The Driver Results ListView to refresh.')]
        [System.Windows.Forms.ListView]$ListView,

        [Parameter(Mandatory=$false,HelpMessage='Optional text matched against all displayed driver fields.')]
        [AllowNull()][AllowEmptyString()]
        [System.String]$SearchTerm,

        [Parameter(Mandatory=$false,HelpMessage='Forces driver inventory to be enumerated again before filtering.')]
        [System.Management.Automation.SwitchParameter]$RefreshCache,

        [Parameter(Mandatory=$false,HelpMessage='Shows only packages whose Driver Store folders were created during the last seven days.')]
        [System.Management.Automation.SwitchParameter]$Recent
    )

    try {
        # PREPARATION - CACHE
        # Preserve existing ListView metadata and add driver inventory when it is first requested.
        if ($null -eq $ListView.Tag) {
            $ListView.Tag = [PSCustomObject]@{}
        }
        elseif (-not ($ListView.Tag -is [System.Management.Automation.PSCustomObject])) {
            $ListView.Tag = [PSCustomObject]@{ LegacyTagValue = $ListView.Tag }
        }

        [System.Boolean]$HasInventoryCache = ($null -ne $ListView.Tag.PSObject.Properties['DriverInventory'])
        if ($RefreshCache.IsPresent -or (-not $HasInventoryCache)) {
            Write-Line 'Obtaining driver inventory, one moment please...' -Type Busy
            [PSCustomObject[]]$DriverInventory = @(Get-DriverInventory)
            $ListView.Tag | Add-Member -MemberType NoteProperty -Name DriverInventory -Value $DriverInventory -Force
        }
        else {
            [PSCustomObject[]]$DriverInventory = @($ListView.Tag.DriverInventory)
        }

        [PSCustomObject[]]$FilteredDrivers = if ($Recent.IsPresent) {
            @(Find-RecentDriverInventory -DriverInventory $DriverInventory -Days 7)
        }
        else {
            @(Find-DriverInventory -DriverInventory $DriverInventory -SearchTerm $SearchTerm)
        }
        [PSCustomObject]$ColorTheme = Get-ListViewColorTheme -ListView $ListView
        [PSCustomObject[]]$DisplayColumns = @((Get-DriverListViewColumnSchema) | Select-Object -Skip 1)

        # EXECUTION - LISTVIEW
        # Replace the displayed rows in one paint cycle to avoid flicker with large inventories.
        Invoke-ListViewBatchUpdate -ListView $ListView -Action {
            $ListView.Items.Clear()
            [System.Int32]$Index = 1

            foreach ($Driver in $FilteredDrivers) {
                [System.Windows.Forms.ListViewItem]$ResultItem = New-Object System.Windows.Forms.ListViewItem([System.String]$Index)
                $ResultItem.Tag = $Driver
                foreach ($Column in $DisplayColumns) {
                    $null = $ResultItem.SubItems.Add([System.String]$Driver.($Column.PropertyName))
                }
                Set-ListViewItemReadOnlyStyle -ListViewItem $ResultItem -ColorTheme $ColorTheme
                $null = $ListView.Items.Add($ResultItem)
                $Index++
            }

            # Reapply the selected column sort after search or inventory refresh replaces the rows.
            if (($null -ne $ListView.Tag.PSObject.Properties['DriverSortColumn']) -and ([System.Int32]$ListView.Tag.DriverSortColumn -ge 0)) {
                $ListView.Sort()
            }
            Set-ListViewColumnAutoSize -ListView $ListView -Mode Widest
        }

        [System.String]$NormalizedSearchTerm = [System.String]$SearchTerm
        if ($Recent.IsPresent) {
            Write-Line "Found $($FilteredDrivers.Count) driver packages with a Driver Store folder created during the last 7 days."
        }
        elseif ([System.String]::IsNullOrWhiteSpace($NormalizedSearchTerm)) {
            Write-Line "Showing all $($FilteredDrivers.Count) third-party driver packages."
        }
        else {
            Write-Line "Found $($FilteredDrivers.Count) third-party driver packages matching '$($NormalizedSearchTerm.Trim())'."
        }
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}

### END OF FUNCTION
####################################################################################################
