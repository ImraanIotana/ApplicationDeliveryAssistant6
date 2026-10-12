####################################################################################################
<#
.SYNOPSIS
    Provides the Service Management selected-service actions and details.
.DESCRIPTION
    Handles the selected service, the live service state, the elevated start, stop, restart and
    startup type actions, and the service details written to the host.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.10.0
    Author          : Imraan Iotana
    Creation Date   : October 2026
    Last Update     : October 2026
#>
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Returns the ListViewItem of the selected Service Results row.
.DESCRIPTION
    Centralizes selection and ListViewItem Tag validation for all selected-service actions. A warning
    is written and $null is returned when no valid row is selected.
.EXAMPLE
    Get-SelectedServiceItem -ListView $ServiceResultsListView
.INPUTS
    [System.Windows.Forms.ListView]
.OUTPUTS
    [System.Windows.Forms.ListViewItem]
#>
####################################################################################################
function Get-SelectedServiceItem {
    [CmdletBinding()]
    [OutputType([System.Windows.Forms.ListViewItem])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The Service Results ListView containing the selected service.')]
        [System.Windows.Forms.ListView]$ListView
    )

    if (($null -eq $ListView.SelectedItems) -or ($ListView.SelectedItems.Count -lt 1)) {
        Write-Line 'No service is selected.' -Type Warning
        return $null
    }

    [System.Windows.Forms.ListViewItem]$Item = $ListView.SelectedItems[0]
    if ($null -eq $Item.Tag) {
        Write-Line 'The selected service row does not contain service details.' -Type Warning
        return $null
    }

    $Item
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Returns the live Win32_Service object of a service.
.DESCRIPTION
    Queries the current state of one service by its service name. $null is returned when the
    service does not exist (anymore).
.EXAMPLE
    Get-ServiceLiveState -ServiceName 'Spooler'
.INPUTS
    [System.String]
.OUTPUTS
    [Microsoft.Management.Infrastructure.CimInstance]
#>
####################################################################################################
function Get-ServiceLiveState {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The service name of the service.')]
        [ValidateNotNullOrEmpty()]
        [System.String]$ServiceName
    )

    [System.String]$EscapedName = $ServiceName.Replace('\', '\\').Replace("'", "\'")
    Get-CimInstance -ClassName Win32_Service -Filter "Name='$EscapedName'" -ErrorAction Stop
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Updates a Service Results row and its cached service object with the live service state.
.DESCRIPTION
    Writes the status, startup type and process ID of the live service to the service object in the
    ListViewItem Tag, which is the same object as in the inventory cache, and to the cells of the row.
.EXAMPLE
    Update-ServiceListViewItem -ListViewItem $Item -LiveService $LiveService
.INPUTS
    [System.Windows.Forms.ListViewItem]
.OUTPUTS
    No objects are returned to the pipeline.
#>
####################################################################################################
function Update-ServiceListViewItem {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The ListViewItem of the service.')]
        [System.Windows.Forms.ListViewItem]$ListViewItem,

        [Parameter(Mandatory=$true,HelpMessage='The live Win32_Service object of the service.')]
        $LiveService
    )

    [PSCustomObject]$Service = $ListViewItem.Tag
    $Service.Status = [System.String]$LiveService.State
    $Service.StartupType = Get-ServiceStartupTypeText -StartMode $LiveService.StartMode -DelayedAutoStart ([System.Boolean]$LiveService.DelayedAutoStart)
    $Service.ProcessId = [System.Int32]$LiveService.ProcessId

    [PSCustomObject[]]$Columns = @(Get-ServiceListViewColumnSchema)
    for ([System.Int32]$Index = 1; $Index -lt $Columns.Count; $Index++) {
        if ($Columns[$Index].PropertyName -in @('Status','StartupType')) {
            $ListViewItem.SubItems[$Index].Text = [System.String]$Service.($Columns[$Index].PropertyName)
        }
    }
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Lets the user choose a startup type for a service.
.DESCRIPTION
    Displays a modal dialog with the startup types Automatic, Automatic (Delayed Start), Manual and
    Disabled. The current startup type is preselected. $null is returned when the dialog is cancelled.
.EXAMPLE
    Select-ServiceStartupType -Owner $MainForm -DisplayName 'Print Spooler' -CurrentStartupType 'Automatic'
.INPUTS
    [System.Windows.Forms.IWin32Window]
    [System.String]
.OUTPUTS
    [System.String]
#>
####################################################################################################
function Select-ServiceStartupType {
    [CmdletBinding()]
    [OutputType([System.String])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The window that owns the startup type dialog.')]
        [System.Windows.Forms.IWin32Window]$Owner,

        [Parameter(Mandatory=$true,HelpMessage='The display name of the service.')]
        [AllowEmptyString()]
        [System.String]$DisplayName,

        [Parameter(Mandatory=$false,HelpMessage='The current startup type of the service.')]
        [AllowNull()][AllowEmptyString()]
        [System.String]$CurrentStartupType
    )

    # PREPARATION - DIALOG
    [System.Windows.Forms.Form]$Dialog = New-ModalDialog -Title 'Set Startup Type' -ClientWidth 430 -ClientHeight 150 -Owner $Owner
    try {
        [System.Windows.Forms.Label]$PromptLabel = New-Object System.Windows.Forms.Label
        $PromptLabel.Text = "Choose the new startup type for:`n$DisplayName"
        $PromptLabel.Location = New-Object System.Drawing.Point(18, 14)
        $PromptLabel.Size = New-Object System.Drawing.Size(394, 40)

        [System.Windows.Forms.ComboBox]$StartupTypeComboBox = New-Object System.Windows.Forms.ComboBox
        $StartupTypeComboBox.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
        $StartupTypeComboBox.Location = New-Object System.Drawing.Point(18, 62)
        $StartupTypeComboBox.Size = New-Object System.Drawing.Size(394, 24)
        [void]$StartupTypeComboBox.Items.AddRange(@('Automatic', 'Automatic (Delayed Start)', 'Manual', 'Disabled'))
        [System.Int32]$CurrentIndex = $StartupTypeComboBox.Items.IndexOf($CurrentStartupType)
        $StartupTypeComboBox.SelectedIndex = [System.Math]::Max(0, $CurrentIndex)

        $Dialog.Controls.AddRange(@($PromptLabel, $StartupTypeComboBox))
        $null = New-ModalDialogActionBar -Dialog $Dialog -PrimaryText 'OK' -PrimaryDialogResult ([System.Windows.Forms.DialogResult]::OK)

        # EXECUTION - SHOW DIALOG
        [System.Windows.Forms.DialogResult]$DialogResult = Show-ModalDialog -Dialog $Dialog -Owner $Owner
        if ($DialogResult -eq [System.Windows.Forms.DialogResult]::OK) {
            return [System.String]$StartupTypeComboBox.SelectedItem
        }
        return $null
    }
    finally {
        $Dialog.Dispose()
    }
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Wraps a service script so that its error message is written to a file.
.DESCRIPTION
    Returns the script text that runs the supplied script with ErrorActionPreference Stop, and writes
    the error message to the error file and exits with code 1 when the script fails. The elevated
    process is started without a console, so the error file is the only way to return the message.
.EXAMPLE
    New-ServiceScriptWrapper -ScriptText 'Start-Service -Name Spooler' -ErrorFilePath $ErrorFilePath
.INPUTS
    [System.String]
.OUTPUTS
    [System.String]
#>
####################################################################################################
function New-ServiceScriptWrapper {
    [CmdletBinding()]
    [OutputType([System.String])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The script text to run.')]
        [System.String]$ScriptText,

        [Parameter(Mandatory=$true,HelpMessage='The path of the file to which an error message is written.')]
        [System.String]$ErrorFilePath
    )

    [System.String]$EscapedErrorFilePath = $ErrorFilePath.Replace("'", "''")
    @"
`$ErrorActionPreference = 'Stop'
try {
$ScriptText
}
catch {
    [System.IO.File]::WriteAllText('$EscapedErrorFilePath', [System.String]`$_.Exception.Message)
    exit 1
}
"@
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Runs a script in an elevated Windows PowerShell process.
.DESCRIPTION
    Starts a hidden elevated Windows PowerShell process that runs the script, waits for it to finish,
    and returns the outcome. A cancelled administrator approval prompt is reported as Cancelled and is
    not an application error.
.EXAMPLE
    Invoke-ElevatedServiceScript -ScriptText 'Start-Service -Name Spooler'
.INPUTS
    [System.String]
.OUTPUTS
    [PSCustomObject]
#>
####################################################################################################
function Invoke-ElevatedServiceScript {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The script text to run elevated.')]
        [System.String]$ScriptText
    )

    [System.String]$ErrorFilePath = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath ('ADA.ServiceAction.{0}.txt' -f [System.Guid]::NewGuid().ToString('N'))
    try {
        # PREPARATION - PROCESS
        [System.String]$WrappedScript = New-ServiceScriptWrapper -ScriptText $ScriptText -ErrorFilePath $ErrorFilePath
        [System.String]$EncodedCommand = [System.Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($WrappedScript))
        [System.Diagnostics.ProcessStartInfo]$ProcessStartInfo = New-Object System.Diagnostics.ProcessStartInfo
        $ProcessStartInfo.FileName = Join-Path -Path $PSHOME -ChildPath 'powershell.exe'
        $ProcessStartInfo.Arguments = "-NoProfile -NonInteractive -ExecutionPolicy Bypass -WindowStyle Hidden -EncodedCommand $EncodedCommand"
        $ProcessStartInfo.Verb = 'runas'
        $ProcessStartInfo.UseShellExecute = $true
        $ProcessStartInfo.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden

        # EXECUTION
        try {
            [System.Diagnostics.Process]$Process = [System.Diagnostics.Process]::Start($ProcessStartInfo)
            $Process.WaitForExit()
        }
        catch {
            [System.Exception]$ProcessException = $_.Exception
            while ($null -ne $ProcessException) {
                if (($ProcessException -is [System.ComponentModel.Win32Exception]) -and ($ProcessException.NativeErrorCode -eq 1223)) {
                    return [PSCustomObject]@{ Cancelled = $true; Succeeded = $false; Message = '' }
                }
                $ProcessException = $ProcessException.InnerException
            }
            throw
        }

        # POST-EXECUTION
        [System.String]$Message = ''
        if ([System.IO.File]::Exists($ErrorFilePath)) {
            $Message = [System.IO.File]::ReadAllText($ErrorFilePath).Trim()
        }
        if (($Process.ExitCode -ne 0) -and [System.String]::IsNullOrWhiteSpace($Message)) {
            $Message = "The elevated process ended with exit code $($Process.ExitCode)."
        }
        [PSCustomObject]@{ Cancelled = $false; Succeeded = ($Process.ExitCode -eq 0); Message = $Message }
    }
    finally {
        Remove-Item -LiteralPath $ErrorFilePath -Force -ErrorAction SilentlyContinue
    }
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Starts, stops, restarts or changes the startup type of the selected service.
.DESCRIPTION
    Checks the live state of the selected service, asks for confirmation (except for Start), runs the
    action in an elevated process, and updates the row with the live state afterwards. Stopping and
    restarting do not force dependent services to stop: when dependent services are running, Windows
    refuses the action and the message is shown.
.EXAMPLE
    Invoke-SelectedServiceAction -ListView $ServiceResultsListView -Action Start
.INPUTS
    [System.Windows.Forms.ListView]
    [System.String]
.OUTPUTS
    No objects are returned to the pipeline.
#>
####################################################################################################
function Invoke-SelectedServiceAction {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The Service Results ListView containing the selected service.')]
        [System.Windows.Forms.ListView]$ListView,

        [Parameter(Mandatory=$true,HelpMessage='The action to run on the selected service.')]
        [ValidateSet('Start','Stop','Restart','SetStartupType')]
        [System.String]$Action
    )

    try {
        # VALIDATION - SELECTED SERVICE
        [System.Windows.Forms.ListViewItem]$Item = Get-SelectedServiceItem -ListView $ListView
        if ($null -eq $Item) { return }

        [System.String]$ServiceName = [System.String]$Item.Tag.ServiceName
        [System.String]$DisplayName = [System.String]$Item.Tag.DisplayName
        $LiveService = Get-ServiceLiveState -ServiceName $ServiceName
        if ($null -eq $LiveService) {
            Write-Line "The service does not exist (anymore). ($ServiceName)" -Type Warning
            return
        }
        [System.String]$CurrentStatus = [System.String]$LiveService.State
        [System.String]$CurrentStartupType = Get-ServiceStartupTypeText -StartMode $LiveService.StartMode -DelayedAutoStart ([System.Boolean]$LiveService.DelayedAutoStart)
        [System.String]$QuotedName = "'" + $ServiceName.Replace("'", "''") + "'"

        # PREPARATION - ACTION
        # Check the current state, ask for confirmation and prepare the script, messages and expected result
        [System.String]$ScriptText = ''
        [System.String]$BusyText = ''
        [System.String]$SuccessText = ''
        [System.String]$ExpectedStatus = ''
        [System.String]$ExpectedStartupType = ''
        switch ($Action) {
            'Start' {
                if ($CurrentStatus -eq 'Running') { Write-Line "The service is already running. ($DisplayName)" -Type Warning ; return }
                if ($CurrentStartupType -eq 'Disabled') { Write-Line "The service is disabled and cannot be started. Set the startup type first. ($DisplayName)" -Type Warning ; return }
                $ScriptText = "Start-Service -Name $QuotedName"
                $BusyText = "Requesting administrator approval to start service $DisplayName..."
                $SuccessText = "Service started. ($DisplayName)"
                $ExpectedStatus = 'Running'
            }
            'Stop' {
                if ($CurrentStatus -eq 'Stopped') { Write-Line "The service is already stopped. ($DisplayName)" -Type Warning ; return }
                [System.String]$StopBody = "This will stop the service:`n`n$DisplayName ($ServiceName)`n`nWindows will request administrator approval. The service will not be stopped when other running services depend on it.`n`nDo you want to continue?"
                if (-not (Get-UserConfirmation -Title 'Stop Service' -Body $StopBody -Type Warning)) { return }
                $ScriptText = "Stop-Service -Name $QuotedName"
                $BusyText = "Requesting administrator approval to stop service $DisplayName..."
                $SuccessText = "Service stopped. ($DisplayName)"
                $ExpectedStatus = 'Stopped'
            }
            'Restart' {
                [System.String]$RestartBody = "This will restart the service:`n`n$DisplayName ($ServiceName)`n`nWindows will request administrator approval. The service will not be restarted when other running services depend on it.`n`nDo you want to continue?"
                if (-not (Get-UserConfirmation -Title 'Restart Service' -Body $RestartBody -Type Warning)) { return }
                $ScriptText = "Restart-Service -Name $QuotedName"
                $BusyText = "Requesting administrator approval to restart service $DisplayName..."
                $SuccessText = "Service restarted. ($DisplayName)"
                $ExpectedStatus = 'Running'
            }
            'SetStartupType' {
                [System.String]$NewStartupType = Select-ServiceStartupType -Owner $ListView.FindForm() -DisplayName $DisplayName -CurrentStartupType $CurrentStartupType
                if ([System.String]::IsNullOrWhiteSpace($NewStartupType)) { Write-Line 'The startup type was not changed.' ; return }
                if ($NewStartupType -eq $CurrentStartupType) { Write-Line "The startup type is already $NewStartupType. ($DisplayName)" -Type Warning ; return }
                [System.String]$StartMode = switch ($NewStartupType) {
                    'Automatic'                 { 'auto' }
                    'Automatic (Delayed Start)' { 'delayed-auto' }
                    'Manual'                    { 'demand' }
                    'Disabled'                  { 'disabled' }
                }
                [System.String]$StartupBody = "This will change the startup type of the service:`n`n$DisplayName ($ServiceName)`n`nFrom: $CurrentStartupType`nTo: $NewStartupType`n`nWindows will request administrator approval.`n`nDo you want to continue?"
                if (-not (Get-UserConfirmation -Title 'Set Startup Type' -Body $StartupBody -Type Warning)) { return }
                $ScriptText = "`$Output = & sc.exe config $QuotedName start= $StartMode 2>&1`nif (`$LASTEXITCODE -ne 0) { throw ('sc.exe failed with error {0}: {1}' -f `$LASTEXITCODE, (New-Object System.ComponentModel.Win32Exception(`$LASTEXITCODE)).Message) }"
                $BusyText = "Requesting administrator approval to set the startup type of service $DisplayName to $NewStartupType..."
                $SuccessText = "Startup type set to $NewStartupType. ($DisplayName)"
                $ExpectedStartupType = $NewStartupType
            }
        }

        # EXECUTION
        Write-Line $BusyText -Type Busy
        [PSCustomObject]$Result = Invoke-ElevatedServiceScript -ScriptText $ScriptText
        if ($Result.Cancelled) {
            Write-Line 'The action was cancelled at the administrator approval prompt.' -Type Warning
            return
        }

        # POST-EXECUTION
        # Update the row with the live state, also when the action failed, and report the result
        $LiveService = Get-ServiceLiveState -ServiceName $ServiceName
        if ($null -ne $LiveService) {
            Update-ServiceListViewItem -ListViewItem $Item -LiveService $LiveService
        }
        if (-not $Result.Succeeded) {
            Write-Line "The action failed. ($DisplayName): $($Result.Message)" -Type Fail
            return
        }
        [System.String]$ActualStartupType = if ($null -ne $LiveService) { [System.String]$Item.Tag.StartupType } else { '' }
        if ((-not [System.String]::IsNullOrWhiteSpace($ExpectedStartupType)) -and ($ActualStartupType -ne $ExpectedStartupType)) {
            Write-Line "The startup type is $ActualStartupType instead of $ExpectedStartupType. ($DisplayName)" -Type Warning
        }
        elseif ((-not [System.String]::IsNullOrWhiteSpace($ExpectedStatus)) -and ($null -ne $LiveService) -and ([System.String]$Item.Tag.Status -ne $ExpectedStatus)) {
            Write-Line "The service status is $([System.String]$Item.Tag.Status) instead of $ExpectedStatus. ($DisplayName)" -Type Warning
        }
        else {
            Write-Line $SuccessText -Type Success
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
    Returns the detail sections of a service.
.DESCRIPTION
    Queries the live state of the service in the ListViewItem, updates the row with it, and returns the
    general information, state, executable, and dependencies as sections. Each section has a Title and
    Lines with a Label, a Value and an optional Type. $null is returned when the service does not exist.
.EXAMPLE
    Get-ServiceDetailSections -ListViewItem $Item
.INPUTS
    [System.Windows.Forms.ListViewItem]
.OUTPUTS
    [PSCustomObject[]]
#>
####################################################################################################
function Get-ServiceDetailSections {
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The ListViewItem of the service.')]
        [System.Windows.Forms.ListViewItem]$ListViewItem
    )

    try {
        # VALIDATION - LIVE SERVICE
        [System.Windows.Forms.ListViewItem]$Item = $ListViewItem
        [PSCustomObject]$CachedService = $Item.Tag
        $LiveService = Get-ServiceLiveState -ServiceName ([System.String]$CachedService.ServiceName)
        if ($null -eq $LiveService) {
            Write-Line "The service does not exist (anymore). ($($CachedService.ServiceName))" -Type Warning
            return $null
        }
        Update-ServiceListViewItem -ListViewItem $Item -LiveService $LiveService

        # PREPARATION - DISPLAY VALUES
        [System.String]$ServiceName = [System.String]$LiveService.Name
        [System.String]$ExecutablePath = Get-ServiceExecutablePath -PathName ([System.String]$LiveService.PathName)
        [System.Boolean]$ExecutableExists = ((-not [System.String]::IsNullOrWhiteSpace($ExecutablePath)) -and [System.IO.File]::Exists($ExecutablePath))
        [System.String]$FileVersion = 'Unknown'
        [System.String]$ProductName = 'Unknown'
        if ($ExecutableExists) {
            [System.Diagnostics.FileVersionInfo]$VersionInfo = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($ExecutablePath)
            if (-not [System.String]::IsNullOrWhiteSpace($VersionInfo.FileVersion)) { $FileVersion = [System.String]$VersionInfo.FileVersion }
            if (-not [System.String]::IsNullOrWhiteSpace($VersionInfo.ProductName)) { $ProductName = [System.String]$VersionInfo.ProductName }
        }
        [System.String]$InstallDateText = if ([System.String]::IsNullOrWhiteSpace([System.String]$CachedService.InstallDateText)) { 'Unknown' } else { [System.String]$CachedService.InstallDateText }
        [System.String]$RecentService = 'Unknown'
        [System.String]$ServiceAge = 'Unknown'
        if ($null -ne $CachedService.InstallDate) {
            [System.DateTime]$Now = Get-Date
            $RecentService = if (([System.DateTime]$CachedService.InstallDate -ge $Now.AddDays(-7)) -and ([System.DateTime]$CachedService.InstallDate -le $Now)) { 'Yes' } else { 'No' }
            $ServiceAge = "$([System.Math]::Max(0, [System.Int32]$Now.Date.Subtract(([System.DateTime]$CachedService.InstallDate).Date).TotalDays)) days"
        }
        [System.String]$Company = if ([System.String]::IsNullOrWhiteSpace([System.String]$CachedService.Company)) { 'Unknown' } else { [System.String]$CachedService.Company }
        [System.String]$Description = if ([System.String]::IsNullOrWhiteSpace([System.String]$CachedService.Description)) { 'None' } else { [System.String]$CachedService.Description }
        [System.String]$ProcessText = 'Not running'
        if ([System.Int32]$LiveService.ProcessId -gt 0) {
            $ProcessText = [System.String]$LiveService.ProcessId
            $ServiceProcess = Get-Process -Id ([System.Int32]$LiveService.ProcessId) -ErrorAction SilentlyContinue
            if ($null -ne $ServiceProcess) {
                $ProcessText = "$($LiveService.ProcessId) ($($ServiceProcess.ProcessName).exe, working set $([System.Math]::Round($ServiceProcess.WorkingSet64 / 1MB, 1)) MB, shared when the process hosts more services)"
            }
        }
        $LiveServiceController = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
        [System.String]$CanStop = 'Unknown'
        [System.String]$CanPause = 'Unknown'
        [System.String]$DependsOn = 'None'
        [System.String]$RequiredBy = 'None'
        if ($null -ne $LiveServiceController) {
            $CanStop = if ($LiveServiceController.CanStop) { 'Yes' } else { 'No' }
            $CanPause = if ($LiveServiceController.CanPauseAndContinue) { 'Yes' } else { 'No' }
            if (@($LiveServiceController.ServicesDependedOn).Count -gt 0) {
                $DependsOn = (@($LiveServiceController.ServicesDependedOn) | ForEach-Object { "$($_.DisplayName) ($($_.Name), $($_.Status))" }) -join '; '
            }
            if (@($LiveServiceController.DependentServices).Count -gt 0) {
                $RequiredBy = (@($LiveServiceController.DependentServices) | ForEach-Object { "$($_.DisplayName) ($($_.Name), $($_.Status))" }) -join '; '
            }
        }

        # OUTPUT - SECTIONS
        # Clarify that the install date is the creation date of the executable
        @(
            [PSCustomObject]@{ Title = 'SERVICE'; Lines = @(
                [PSCustomObject]@{ Label = 'Display Name'; Value = [System.String]$LiveService.DisplayName; Type = '' }
                [PSCustomObject]@{ Label = 'Service Name'; Value = $ServiceName; Type = '' }
                [PSCustomObject]@{ Label = 'Description'; Value = $Description; Type = '' }
                [PSCustomObject]@{ Label = 'Registry Key'; Value = "HKLM\SYSTEM\CurrentControlSet\Services\$ServiceName"; Type = '' }
            ) }
            [PSCustomObject]@{ Title = 'STATE'; Lines = @(
                [PSCustomObject]@{ Label = 'Status'; Value = [System.String]$LiveService.State; Type = '' }
                [PSCustomObject]@{ Label = 'Startup Type'; Value = [System.String]$CachedService.StartupType; Type = '' }
                [PSCustomObject]@{ Label = 'Log On As'; Value = [System.String]$LiveService.StartName; Type = '' }
                [PSCustomObject]@{ Label = 'Service Type'; Value = [System.String]$LiveService.ServiceType; Type = '' }
                [PSCustomObject]@{ Label = 'Process'; Value = $ProcessText; Type = '' }
                [PSCustomObject]@{ Label = 'Can Stop'; Value = $CanStop; Type = '' }
                [PSCustomObject]@{ Label = 'Can Pause'; Value = $CanPause; Type = '' }
            ) }
            [PSCustomObject]@{ Title = 'EXECUTABLE'; Lines = @(
                [PSCustomObject]@{ Label = 'Path Name'; Value = [System.String]$LiveService.PathName; Type = '' }
                [PSCustomObject]@{ Label = 'Executable'; Value = $(if ($ExecutableExists) { $ExecutablePath } else { "$ExecutablePath (not found)" }); Type = '' }
                [PSCustomObject]@{ Label = 'Company'; Value = $Company; Type = '' }
                [PSCustomObject]@{ Label = 'Origin'; Value = [System.String]$CachedService.Origin; Type = '' }
                [PSCustomObject]@{ Label = 'Product'; Value = $ProductName; Type = '' }
                [PSCustomObject]@{ Label = 'File Version'; Value = $FileVersion; Type = '' }
                [PSCustomObject]@{ Label = 'Install Date'; Value = $InstallDateText; Type = '' }
                [PSCustomObject]@{ Label = 'Age'; Value = $ServiceAge; Type = '' }
                [PSCustomObject]@{ Label = 'Recent Service'; Value = $RecentService; Type = '' }
                [PSCustomObject]@{ Label = 'Date Source'; Value = 'Executable CreationTime (approximate)'; Type = 'Warning' }
            ) }
            [PSCustomObject]@{ Title = 'DEPENDENCIES'; Lines = @(
                [PSCustomObject]@{ Label = 'Depends On'; Value = $DependsOn; Type = '' }
                [PSCustomObject]@{ Label = 'Required By'; Value = $RequiredBy; Type = '' }
            ) }
        )
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
    Writes details for the selected service to the application host.
.DESCRIPTION
    Queries the live state of the selected service and reports its general information, state,
    executable, and the services it depends on and the services that depend on it.
.EXAMPLE
    Write-SelectedServiceDetailsToHost -ListView $ServiceResultsListView
.INPUTS
    [System.Windows.Forms.ListView]
.OUTPUTS
    No objects are returned to the pipeline.
#>
####################################################################################################
function Write-SelectedServiceDetailsToHost {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The Service Results ListView containing the selected service.')]
        [System.Windows.Forms.ListView]$ListView
    )

    try {
        # VALIDATION - SELECTED SERVICE
        [System.Windows.Forms.ListViewItem]$Item = Get-SelectedServiceItem -ListView $ListView
        if ($null -eq $Item) { return }
        [PSCustomObject[]]$Sections = @(Get-ServiceDetailSections -ListViewItem $Item)
        if (($Sections.Count -eq 0) -or ($null -eq $Sections[0])) { return }

        # OUTPUT
        foreach ($Section in $Sections) {
            Write-Line ''
            Write-Line $Section.Title -Type Special
            foreach ($Line in $Section.Lines) {
                if ([System.String]::IsNullOrWhiteSpace($Line.Type)) {
                    Write-Line ('{0}: {1}' -f $Line.Label.PadRight(16), $Line.Value)
                }
                else {
                    Write-Line ('{0}: {1}' -f $Line.Label.PadRight(16), $Line.Value) -Type $Line.Type
                }
            }
        }
        Write-Line ''
        Write-Line '-------------------- End of service information --------------------' -Type Success
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}

### END OF FUNCTION
####################################################################################################
