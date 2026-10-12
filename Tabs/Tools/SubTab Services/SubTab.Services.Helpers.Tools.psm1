####################################################################################################
<#
.SYNOPSIS
    Provides the Service Tools helpers for the selected service.
.DESCRIPTION
    Handles opening the executable folder and the registry key, copying service information,
    exporting the service information and removing the service.
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
    Opens the folder of the executable of the selected service.
.DESCRIPTION
    Opens File Explorer with the executable of the selected service highlighted.
.EXAMPLE
    Open-SelectedServiceFolder -ListView $ServiceResultsListView
.INPUTS
    [System.Windows.Forms.ListView]
.OUTPUTS
    No objects are returned to the pipeline.
#>
####################################################################################################
function Open-SelectedServiceFolder {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The Service Results ListView containing the selected service.')]
        [System.Windows.Forms.ListView]$ListView
    )

    try {
        [System.Windows.Forms.ListViewItem]$Item = Get-SelectedServiceItem -ListView $ListView
        if ($null -eq $Item) { return }

        [System.String]$ExecutablePath = [System.String]$Item.Tag.ExecutablePath
        if ([System.String]::IsNullOrWhiteSpace($ExecutablePath) -or (-not (Test-Path -LiteralPath $ExecutablePath))) {
            Write-Line "The executable of the service could not be found. ($($Item.Tag.DisplayName))" -Type Warning
            return
        }
        Open-Folder -HighlightItem $ExecutablePath
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
    Opens the Registry Editor at the key of the selected service.
.DESCRIPTION
    Starts the Registry Editor at HKLM\SYSTEM\CurrentControlSet\Services\<service name>. When the
    Registry Editor is already open, it is brought to that key only when it is restarted.
.EXAMPLE
    Open-SelectedServiceRegistryKey -ListView $ServiceResultsListView
.INPUTS
    [System.Windows.Forms.ListView]
.OUTPUTS
    No objects are returned to the pipeline.
#>
####################################################################################################
function Open-SelectedServiceRegistryKey {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The Service Results ListView containing the selected service.')]
        [System.Windows.Forms.ListView]$ListView
    )

    try {
        [System.Windows.Forms.ListViewItem]$Item = Get-SelectedServiceItem -ListView $ListView
        if ($null -eq $Item) { return }

        Start-RegistryEditor -Key "Computer\HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\$($Item.Tag.ServiceName)"
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
    Lets the user choose which service information to copy.
.DESCRIPTION
    Displays a modal dialog with the options Service Name, Display Name, Executable Path and
    Summary. $null is returned when the dialog is cancelled.
.EXAMPLE
    Select-ServiceCopyOption -Owner $MainForm
.INPUTS
    [System.Windows.Forms.IWin32Window]
.OUTPUTS
    [System.String]
#>
####################################################################################################
function Select-ServiceCopyOption {
    [CmdletBinding()]
    [OutputType([System.String])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The window that owns the copy option dialog.')]
        [System.Windows.Forms.IWin32Window]$Owner
    )

    [System.Windows.Forms.Form]$Dialog = New-ModalDialog -Title 'Copy Service Information' -ClientWidth 470 -ClientHeight 200 -Owner $Owner
    try {
        [System.Windows.Forms.Label]$PromptLabel = New-Object System.Windows.Forms.Label
        $PromptLabel.Text = 'Choose what to copy to the clipboard.'
        $PromptLabel.Location = New-Object System.Drawing.Point(18, 18)
        $PromptLabel.Size = New-Object System.Drawing.Size(430, 24)

        # Each option button returns its own DialogResult, which is mapped to the option below
        [System.Collections.Hashtable[]]$OptionDefinitions = @(
            @{ Text = 'Service Name';    Result = [System.Windows.Forms.DialogResult]::Yes;    X = 18;  Y = 55 }
            @{ Text = 'Display Name';    Result = [System.Windows.Forms.DialogResult]::No;     X = 241; Y = 55 }
            @{ Text = 'Executable Path'; Result = [System.Windows.Forms.DialogResult]::Retry;  X = 18;  Y = 108 }
            @{ Text = 'Summary';         Result = [System.Windows.Forms.DialogResult]::Ignore; X = 241; Y = 108 }
        )
        [System.Windows.Forms.Control[]]$Controls = @($PromptLabel)
        foreach ($OptionDefinition in $OptionDefinitions) {
            [System.Windows.Forms.Button]$OptionButton = New-Object System.Windows.Forms.Button
            $OptionButton.Text = $OptionDefinition.Text
            $OptionButton.Location = New-Object System.Drawing.Point($OptionDefinition.X, $OptionDefinition.Y)
            $OptionButton.Size = New-Object System.Drawing.Size(205, 40)
            $OptionButton.DialogResult = $OptionDefinition.Result
            $Controls += $OptionButton
        }

        [System.Windows.Forms.Button]$CancelButton = New-Object System.Windows.Forms.Button
        $CancelButton.Text = 'Cancel'
        $CancelButton.Location = New-Object System.Drawing.Point(371, 160)
        $CancelButton.Size = New-Object System.Drawing.Size(75, 28)
        $CancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
        $Controls += $CancelButton

        $Dialog.Controls.AddRange($Controls)
        $Dialog.CancelButton = $CancelButton

        [System.Windows.Forms.DialogResult]$DialogResult = Show-ModalDialog -Dialog $Dialog -Owner $Owner
        switch ($DialogResult) {
            'Yes'       { return 'ServiceName' }
            'No'        { return 'DisplayName' }
            'Retry'     { return 'ExecutablePath' }
            'Ignore'    { return 'Summary' }
            default     { return $null }
        }
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
    Copies information of the selected service to the clipboard.
.DESCRIPTION
    Asks which information to copy (service name, display name, executable path or a summary), and
    copies it to the clipboard.
.EXAMPLE
    Copy-SelectedServiceInformation -ListView $ServiceResultsListView
.INPUTS
    [System.Windows.Forms.ListView]
.OUTPUTS
    No objects are returned to the pipeline.
#>
####################################################################################################
function Copy-SelectedServiceInformation {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The Service Results ListView containing the selected service.')]
        [System.Windows.Forms.ListView]$ListView
    )

    try {
        [System.Windows.Forms.ListViewItem]$Item = Get-SelectedServiceItem -ListView $ListView
        if ($null -eq $Item) { return }

        [System.String]$CopyOption = Select-ServiceCopyOption -Owner $ListView.FindForm()
        if ([System.String]::IsNullOrWhiteSpace($CopyOption)) { return }

        [PSCustomObject]$Service = $Item.Tag
        [System.String]$TextToCopy = switch ($CopyOption) {
            'ServiceName'       { [System.String]$Service.ServiceName }
            'DisplayName'       { [System.String]$Service.DisplayName }
            'ExecutablePath'    { [System.String]$Service.ExecutablePath }
            'Summary'           {
                @(
                    "Display Name : $($Service.DisplayName)"
                    "Service Name : $($Service.ServiceName)"
                    "Status       : $($Service.Status)"
                    "Startup Type : $($Service.StartupType)"
                    "Log On As    : $($Service.LogOnAs)"
                    "Path Name    : $($Service.PathName)"
                ) -join [System.Environment]::NewLine
            }
        }
        if ([System.String]::IsNullOrWhiteSpace($TextToCopy)) {
            Write-Line 'There is no information to copy.' -Type Warning
            return
        }
        [System.Windows.Forms.Clipboard]::SetText($TextToCopy)
        Write-Line "Copied to the clipboard. ($($TextToCopy.Split("`n")[0].Trim()))" -Type Success
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
    Returns the commands to recreate a service.
.DESCRIPTION
    Builds the text with the sc.exe and PowerShell commands to create, control and delete a service,
    based on the live service. A service that does not run under LocalSystem needs its password to
    be filled in.
.EXAMPLE
    New-ServiceCommandText -LiveService $LiveService -StartupType 'Automatic'
.INPUTS
    [System.String]
.OUTPUTS
    [System.String]
#>
####################################################################################################
function New-ServiceCommandText {
    [CmdletBinding()]
    [OutputType([System.String])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The live Win32_Service object of the service.')]
        $LiveService,

        [Parameter(Mandatory=$true,HelpMessage='The startup type text of the service.')]
        [System.String]$StartupType,

        [Parameter(Mandatory=$false,HelpMessage='The names of the services the service depends on.')]
        [AllowNull()]
        [System.String[]]$DependsOn
    )

    [System.String]$Name = [System.String]$LiveService.Name
    [System.String]$StartMode = switch ($StartupType) {
        'Automatic'                 { 'auto' }
        'Automatic (Delayed Start)' { 'delayed-auto' }
        'Disabled'                  { 'disabled' }
        default                     { 'demand' }
    }
    [System.String]$PowerShellStartupType = switch ($StartupType) {
        'Automatic'                 { 'Automatic' }
        'Automatic (Delayed Start)' { 'AutomaticDelayedStart' }
        'Disabled'                  { 'Disabled' }
        default                     { 'Manual' }
    }
    [System.String]$ServiceType = switch ([System.String]$LiveService.ServiceType) {
        'Own Process'   { 'own' }
        'Share Process' { 'share' }
        default         { '' }
    }
    [System.String]$CmdBinaryPath = ([System.String]$LiveService.PathName).Replace('"', '\"')
    [System.String]$CmdDescription = ([System.String]$LiveService.Description).Replace('"', '\"')
    [System.Boolean]$HasAccount = ((-not [System.String]::IsNullOrWhiteSpace([System.String]$LiveService.StartName)) -and ([System.String]$LiveService.StartName -ne 'LocalSystem'))

    [System.String]$CreateCommand = "sc.exe create `"$Name`" binPath= `"$CmdBinaryPath`""
    if ($ServiceType) { $CreateCommand += " type= $ServiceType" }
    $CreateCommand += " start= $StartMode DisplayName= `"$($LiveService.DisplayName)`""
    if ($HasAccount) { $CreateCommand += " obj= `"$($LiveService.StartName)`" password= `"<password>`"" }
    if (@($DependsOn).Count -gt 0) { $CreateCommand += " depend= `"$(@($DependsOn) -join '/')`"" }

    [System.Collections.Generic.List[System.String]]$Lines = New-Object System.Collections.Generic.List[System.String]
    $Lines.Add("Commands for the service: $($LiveService.DisplayName) ($Name)")
    $Lines.Add('Review the commands before using them. Run them from an elevated command prompt.')
    $Lines.Add('')
    $Lines.Add('CREATE THE SERVICE (command prompt)')
    $Lines.Add($CreateCommand)
    if (-not [System.String]::IsNullOrWhiteSpace($CmdDescription)) { $Lines.Add("sc.exe description `"$Name`" `"$CmdDescription`"") }
    if ($HasAccount) { $Lines.Add("Note: the service runs as $($LiveService.StartName). Replace <password> with the password of that account.") }
    $Lines.Add('')
    $Lines.Add('CREATE THE SERVICE (PowerShell)')
    [System.String]$PowerShellCreate = "New-Service -Name '$($Name.Replace("'", "''"))' -BinaryPathName '$(([System.String]$LiveService.PathName).Replace("'", "''"))' -DisplayName '$(([System.String]$LiveService.DisplayName).Replace("'", "''"))' -StartupType $PowerShellStartupType"
    if (-not [System.String]::IsNullOrWhiteSpace($CmdDescription)) { $PowerShellCreate += " -Description '$(([System.String]$LiveService.Description).Replace("'", "''"))'" }
    if (@($DependsOn).Count -gt 0) { $PowerShellCreate += " -DependsOn '$((@($DependsOn) -join "','"))'" }
    $Lines.Add($PowerShellCreate)
    $Lines.Add('')
    $Lines.Add('CONTROL THE SERVICE')
    $Lines.Add("sc.exe start `"$Name`"")
    $Lines.Add("sc.exe stop `"$Name`"")
    $Lines.Add("sc.exe config `"$Name`" start= $StartMode")
    $Lines.Add("sc.exe qc `"$Name`"")
    $Lines.Add("Start-Service -Name '$($Name.Replace("'", "''"))'")
    $Lines.Add("Stop-Service -Name '$($Name.Replace("'", "''"))'")
    $Lines.Add('')
    $Lines.Add('DELETE THE SERVICE')
    $Lines.Add("sc.exe delete `"$Name`"")

    $Lines -join [System.Environment]::NewLine
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Exports the information of the selected service to the output folder.
.DESCRIPTION
    Creates a folder with a service report, a registry export (.reg) of the service key, and a text
    file with the commands to recreate, control and delete the service. An existing export folder is
    replaced after confirmation.
.EXAMPLE
    Export-SelectedService -ListView $ServiceResultsListView
.INPUTS
    [System.Windows.Forms.ListView]
.OUTPUTS
    No objects are returned to the pipeline.
#>
####################################################################################################
function Export-SelectedService {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The Service Results ListView containing the selected service.')]
        [System.Windows.Forms.ListView]$ListView,

        [Parameter(Mandatory=$false,HelpMessage='The parent folder where the service export folder will be created.')]
        [AllowNull()][AllowEmptyString()]
        [System.String]$OutputFolder = (Get-Folder -OutputFolder),

        [Parameter(Mandatory=$false,HelpMessage='Opens the completed service export folder.')]
        [System.Management.Automation.SwitchParameter]$OpenOutputFolder
    )

    try {
        # VALIDATION - SELECTED SERVICE
        [System.Windows.Forms.ListViewItem]$Item = Get-SelectedServiceItem -ListView $ListView
        if ($null -eq $Item) { return }
        if ([System.String]::IsNullOrWhiteSpace($OutputFolder)) {
            Write-Line 'The configured user output folder is empty.' -Type Warning
            return
        }
        [PSCustomObject[]]$Sections = @(Get-ServiceDetailSections -ListViewItem $Item)
        if (($Sections.Count -eq 0) -or ($null -eq $Sections[0])) { return }

        [PSCustomObject]$Service = $Item.Tag
        [System.String]$ServiceName = [System.String]$Service.ServiceName
        $LiveService = Get-ServiceLiveState -ServiceName $ServiceName

        # PREPARATION - OUTPUT PATHS
        [System.String]$SafeDisplayName = (([System.String]$Service.DisplayName) -replace '[\\/:*?"<>|]', '_').Trim().TrimEnd([System.Char[]]' .')
        [System.String]$SafeServiceName = ($ServiceName -replace '[\\/:*?"<>|]', '_').Trim()
        [System.String]$ExportFolder = Join-Path -Path $OutputFolder -ChildPath "Service Export - $SafeDisplayName - $SafeServiceName"
        if ($ExportFolder.Length -gt 200) { $ExportFolder = Join-Path -Path $OutputFolder -ChildPath "Service Export - $SafeServiceName" }

        # CONFIRMATION
        if (Test-Path -LiteralPath $ExportFolder) {
            if (-not (Test-Path -LiteralPath $ExportFolder -PathType Container)) {
                Write-Line "The export destination exists but is not a folder. ($ExportFolder)" -Type Warning
                return
            }
            [System.String]$OverwriteBody = "The service export folder already exists:`n`n$ExportFolder`n`nThe folder and all files inside it will be replaced.`n`nDo you want to overwrite it?"
            if (-not (Get-UserConfirmation -Title 'Overwrite Service Export' -Body $OverwriteBody -Type Warning)) { return }
            Remove-Item -LiteralPath $ExportFolder -Recurse -Force -ErrorAction Stop
        }

        # EXECUTION - EXPORT
        Write-Line "Exporting service $($Service.DisplayName), one moment please..." -Type Busy
        $null = New-Item -Path $ExportFolder -ItemType Directory -Force

        # The service report
        [System.Collections.Generic.List[System.String]]$ReportLines = New-Object System.Collections.Generic.List[System.String]
        $ReportLines.Add("SERVICE REPORT - $($Service.DisplayName) ($ServiceName)")
        $ReportLines.Add("Exported at     : $((Get-Date).ToString('yyyy-MM-dd HH:mm:ss', [System.Globalization.CultureInfo]::InvariantCulture))")
        $ReportLines.Add("Exported by     : $env:USERNAME on $env:COMPUTERNAME")
        foreach ($Section in $Sections) {
            $ReportLines.Add('')
            $ReportLines.Add($Section.Title)
            foreach ($Line in $Section.Lines) { $ReportLines.Add(('{0}: {1}' -f $Line.Label.PadRight(16), $Line.Value)) }
        }
        Set-Content -LiteralPath (Join-Path -Path $ExportFolder -ChildPath 'Service Report.txt') -Value $ReportLines -Encoding UTF8

        # The registry export
        [System.String]$RegistryPath = Join-Path -Path $ExportFolder -ChildPath "$SafeServiceName.reg"
        $null = & reg.exe export "HKLM\SYSTEM\CurrentControlSet\Services\$ServiceName" $RegistryPath /y 2>&1
        if (($LASTEXITCODE -ne 0) -or (-not (Test-Path -LiteralPath $RegistryPath))) {
            Write-Line "The registry key of the service could not be exported. ($ServiceName)" -Type Warning
        }

        # The commands
        $LiveController = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
        [System.String[]]$DependsOn = if ($null -ne $LiveController) { @($LiveController.ServicesDependedOn | ForEach-Object { [System.String]$_.Name }) } else { @() }
        [System.String]$CommandText = New-ServiceCommandText -LiveService $LiveService -StartupType ([System.String]$Service.StartupType) -DependsOn $DependsOn
        Set-Content -LiteralPath (Join-Path -Path $ExportFolder -ChildPath 'Service Commands.txt') -Value $CommandText -Encoding UTF8

        # POST-EXECUTION
        Write-Line "Service information exported successfully. ($ExportFolder)" -Type Success
        if ($OpenOutputFolder.IsPresent) {
            Open-Folder -Path $ExportFolder
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
    Removes the selected service.
.DESCRIPTION
    Confirms the destructive action, deletes the service with sc.exe in an elevated process, and
    removes the row from the results. A running service is not removed: stop it first. A service that
    still exists after the deletion is marked for deletion by Windows, and disappears when it is no
    longer in use.
.EXAMPLE
    Remove-SelectedService -ListView $ServiceResultsListView
.INPUTS
    [System.Windows.Forms.ListView]
.OUTPUTS
    No objects are returned to the pipeline.
#>
####################################################################################################
function Remove-SelectedService {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The Service Results ListView containing the selected service.')]
        [System.Windows.Forms.ListView]$ListView
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
        if ([System.String]$LiveService.State -ne 'Stopped') {
            Write-Line "The service is not stopped, so it will not be removed. Stop the service first. ($DisplayName)" -Type Warning
            return
        }

        # CONFIRMATION
        [System.String]$MicrosoftWarning = if ([System.String]$Item.Tag.Origin -eq 'Microsoft') { "`n`nThis is a Microsoft service. Removing it can make Windows unstable." } else { '' }
        [System.String]$ConfirmationBody = "This will permanently remove the service:`n`n$DisplayName ($ServiceName)`n$([System.String]$LiveService.PathName)$MicrosoftWarning`n`nWindows will request administrator approval. Consider exporting the service first.`n`nDo you want to continue?"
        if (-not (Get-UserConfirmation -Title 'Remove Service' -Body $ConfirmationBody -Type Warning)) { return }

        # EXECUTION
        Write-Line "Requesting administrator approval to remove service $DisplayName..." -Type Busy
        [System.String]$QuotedName = "'" + $ServiceName.Replace("'", "''") + "'"
        [System.String]$ScriptText = "`$Output = & sc.exe delete $QuotedName 2>&1`nif (`$LASTEXITCODE -ne 0) { throw ('sc.exe failed with error {0}: {1}' -f `$LASTEXITCODE, (New-Object System.ComponentModel.Win32Exception(`$LASTEXITCODE)).Message) }"
        [PSCustomObject]$Result = Invoke-ElevatedServiceScript -ScriptText $ScriptText
        if ($Result.Cancelled) {
            Write-Line 'Service removal was cancelled at the administrator approval prompt.' -Type Warning
            return
        }
        if (-not $Result.Succeeded) {
            Write-Line "The service could not be removed. ($DisplayName): $($Result.Message)" -Type Fail
            return
        }

        # POST-EXECUTION
        # Remove the row and the cached service, and report whether Windows only marked the service for deletion
        if (($null -ne $ListView.Tag) -and ($null -ne $ListView.Tag.PSObject.Properties['ServiceInventory'])) {
            $ListView.Tag.ServiceInventory = @($ListView.Tag.ServiceInventory | Where-Object { $_.ServiceName -ne $ServiceName })
        }
        $ListView.Items.Remove($Item)
        if ($null -ne (Get-ServiceLiveState -ServiceName $ServiceName)) {
            Write-Line "The service is marked for deletion. It will disappear when it is no longer in use, or after a restart. ($DisplayName)" -Type Warning
        }
        else {
            Write-Line "Service removed successfully. ($DisplayName)" -Type Success
        }
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}

### END OF FUNCTION
####################################################################################################
