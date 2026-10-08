####################################################################################################
<#
.SYNOPSIS
    Provides certificate removal helpers.
.DESCRIPTION
    Resolves all installations of a selected certificate, lets the user choose exact store
    locations, removes CurrentUser certificates directly, and elevates LocalMachine removals.
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
    Returns live store locations containing the selected certificate.
.DESCRIPTION
    Refreshes the certificate inventory, matches the selected thumbprint, and returns one record
    for each unique scope and store location.
.EXAMPLE
    Get-CertificateRemovalLocations -CertificateRecord $SelectedCertificate
.INPUTS
    [PSCustomObject]
.OUTPUTS
    [PSCustomObject[]]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.1.0
    Author          : Imraan Iotana
    Creation Date   : August 2026
    Last Update     : August 2026
#>
####################################################################################################
function Get-CertificateRemovalLocations {
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The selected certificate record whose installations will be resolved.')]
        [PSCustomObject]$CertificateRecord
    )

    # VALIDATION - CERTIFICATE IDENTITY
    # Require the selected row to contain a hexadecimal certificate thumbprint
    [System.String]$Thumbprint = ([System.String]$CertificateRecord.Thumbprint).Replace(' ', '').ToUpperInvariant()
    if ([System.String]::IsNullOrWhiteSpace($Thumbprint) -or ($Thumbprint -notmatch '^[0-9A-F]+$')) {
        throw 'The selected certificate does not contain a valid thumbprint.'
    }

    # EXECUTION - LIVE INSTALLATION INVENTORY
    # Refresh every readable store and group matching records by their exact scope and store
    [PSCustomObject]$InstallationState = Get-CertificateInstallationState -Thumbprint $Thumbprint
    [PSCustomObject[]]$MatchingRecords = @($InstallationState.MatchingCertificates)
    [System.Object[]]$LocationGroups = @($MatchingRecords | Group-Object -Property Scope, Store)
    [System.Collections.Generic.List[PSCustomObject]]$Locations = New-Object 'System.Collections.Generic.List[PSCustomObject]'

    foreach ($LocationGroup in $LocationGroups) {
        [PSCustomObject]$LocationRecord = $LocationGroup.Group[0]
        [System.String]$Scope = [System.String]$LocationRecord.Scope
        [System.String]$Store = [System.String]$LocationRecord.Store
        $Locations.Add([PSCustomObject][ordered]@{
            Scope          = $Scope
            Store          = $Store
            StorePath      = "Cert:\$Scope\$Store"
            Thumbprint     = $Thumbprint
            Subject        = [System.String]$LocationRecord.Subject
            Issuer         = [System.String]$LocationRecord.Issuer
            HasPrivateKey  = [System.Boolean]$LocationRecord.HasPrivateKey
            InstanceCount  = [System.Int32]$LocationGroup.Count
            IsSelected     = (($Scope -eq [System.String]$CertificateRecord.Scope) -and ($Store -eq [System.String]$CertificateRecord.Store))
            IsHighRisk     = ($Store -in @('Root','AuthRoot','CA','TrustedPublisher'))
            NeedsElevation = ($Scope -eq 'LocalMachine')
        })
    }

    # OUTPUT
    # Return the selected location first followed by the remaining locations in stable order
    @($Locations | Sort-Object @{ Expression = 'IsSelected'; Descending = $true }, Scope, Store)
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Lets the user choose certificate installations to remove.
.DESCRIPTION
    Displays every live scope and store containing the selected thumbprint, checks only the selected
    location by default, and highlights trust stores and locations that require elevation.
.EXAMPLE
    Select-CertificateRemovalLocations -CertificateRecord $SelectedCertificate -Locations $Locations -Owner $MainForm
.INPUTS
    [PSCustomObject]
    [PSCustomObject[]]
    [System.Windows.Forms.IWin32Window]
.OUTPUTS
    [PSCustomObject]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.1.0
    Author          : Imraan Iotana
    Creation Date   : August 2026
    Last Update     : August 2026
#>
####################################################################################################
function Select-CertificateRemovalLocations {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The selected certificate record shown in the removal dialog.')]
        [PSCustomObject]$CertificateRecord,

        [Parameter(Mandatory=$true,HelpMessage='The live certificate store locations available for removal.')]
        [PSCustomObject[]]$Locations,

        [Parameter(Mandatory=$false,HelpMessage='The window that owns the certificate removal dialog.')]
        [AllowNull()]
        [System.Windows.Forms.IWin32Window]$Owner
    )

    # PREPARATION - DIALOG
    # Create a bounded dialog that can display several certificate store locations
    [System.Int32]$VisibleLocationCount = [System.Math]::Min([System.Math]::Max($Locations.Count, 3), 9)
    [System.Int32]$DialogHeight = 235 + ($VisibleLocationCount * 24)
    [System.Windows.Forms.Form]$Dialog = New-ModalDialog -Title 'Remove Certificate' -ClientWidth 700 -ClientHeight $DialogHeight -Owner $Owner
    try {
        # PREPARATION - CERTIFICATE DETAILS
        # Show the certificate identity before the user selects removal locations
        [System.Windows.Forms.Label]$SubjectLabel = New-Object System.Windows.Forms.Label
        $SubjectLabel.Text = "Subject: $([System.String]$CertificateRecord.Subject)"
        $SubjectLabel.Location = New-Object System.Drawing.Point(18, 16)
        $SubjectLabel.Size = New-Object System.Drawing.Size(664, 22)
        $SubjectLabel.AutoEllipsis = $true

        [System.Windows.Forms.Label]$ThumbprintLabel = New-Object System.Windows.Forms.Label
        $ThumbprintLabel.Text = "Thumbprint: $([System.String]$CertificateRecord.Thumbprint)"
        $ThumbprintLabel.Location = New-Object System.Drawing.Point(18, 42)
        $ThumbprintLabel.Size = New-Object System.Drawing.Size(664, 22)
        $ThumbprintLabel.AutoEllipsis = $true

        [System.Windows.Forms.Label]$InstructionLabel = New-Object System.Windows.Forms.Label
        $InstructionLabel.Text = 'Choose the exact certificate store locations to remove. Only the selected row is checked by default.'
        $InstructionLabel.Location = New-Object System.Drawing.Point(18, 72)
        $InstructionLabel.Size = New-Object System.Drawing.Size(664, 22)

        # PREPARATION - LOCATION CHECKLIST
        # Add one checklist entry for each unique scope and store location
        [System.Int32]$LocationListHeight = ($VisibleLocationCount * 24) + 8
        [System.Windows.Forms.CheckedListBox]$LocationList = New-Object System.Windows.Forms.CheckedListBox
        $LocationList.Location = New-Object System.Drawing.Point(18, 100)
        $LocationList.Size = New-Object System.Drawing.Size(664, $LocationListHeight)
        $LocationList.CheckOnClick = $true
        $LocationList.HorizontalScrollbar = $true
        for ([System.Int32]$Index = 0; $Index -lt $Locations.Count; $Index++) {
            [PSCustomObject]$Location = $Locations[$Index]
            [System.Collections.Generic.List[System.String]]$Markers = New-Object 'System.Collections.Generic.List[System.String]'
            if ($Location.IsSelected) { $Markers.Add('SELECTED') }
            if ($Location.IsHighRisk) { $Markers.Add('TRUST STORE - HIGH RISK') }
            if ($Location.NeedsElevation) { $Markers.Add('ADMINISTRATOR APPROVAL') }
            if ($Location.InstanceCount -gt 1) { $Markers.Add("$($Location.InstanceCount) IDENTICAL ENTRIES") }
            [System.String]$MarkerText = if ($Markers.Count -gt 0) { '  [' + ($Markers -join '; ') + ']' } else { [System.String]::Empty }
            $null = $LocationList.Items.Add("$($Location.Scope)\$($Location.Store)$MarkerText", [System.Boolean]$Location.IsSelected)
        }

        # PREPARATION - WARNING
        # Explain the trust, private-key, and elevation consequences represented by the locations
        [System.Int32]$WarningTop = $LocationList.Bottom + 10
        [System.Windows.Forms.Label]$WarningLabel = New-Object System.Windows.Forms.Label
        $WarningLabel.ForeColor = [System.Drawing.Color]::DarkRed
        $WarningLabel.Location = New-Object System.Drawing.Point(18, $WarningTop)
        $WarningLabel.Size = New-Object System.Drawing.Size(664, 42)
        [System.Collections.Generic.List[System.String]]$Warnings = New-Object 'System.Collections.Generic.List[System.String]'
        if (@($Locations | Where-Object IsHighRisk).Count -gt 0) {
            $Warnings.Add('Removing certificates from trust stores can break website, application, or signature validation.')
        }
        if ([System.Boolean]$CertificateRecord.HasPrivateKey) {
            $Warnings.Add('This certificate has a private key. Export a backup first if it may be needed later.')
        }
        if (@($Locations | Where-Object NeedsElevation).Count -gt 0) {
            $Warnings.Add('Checked LocalMachine locations will request administrator approval once.')
        }
        $WarningLabel.Text = $Warnings -join ' '

        # PREPARATION - DIALOG ACTIONS
        # Create checklist convenience actions and the destructive confirmation button
        [System.Int32]$ButtonTop = $DialogHeight - 48
        [System.Windows.Forms.Button]$SelectAllButton = New-Object System.Windows.Forms.Button
        $SelectAllButton.Text = 'Select All'
        $SelectAllButton.Location = New-Object System.Drawing.Point(18, $ButtonTop)
        $SelectAllButton.Size = New-Object System.Drawing.Size(90, 28)
        $SelectAllButton.Add_Click({
            for ([System.Int32]$Index = 0; $Index -lt $LocationList.Items.Count; $Index++) {
                $LocationList.SetItemChecked($Index, $true)
            }
        }.GetNewClosure())

        [System.Windows.Forms.Button]$ClearAllButton = New-Object System.Windows.Forms.Button
        $ClearAllButton.Text = 'Clear All'
        $ClearAllButton.Location = New-Object System.Drawing.Point(114, $ButtonTop)
        $ClearAllButton.Size = New-Object System.Drawing.Size(90, 28)
        $ClearAllButton.Add_Click({
            for ([System.Int32]$Index = 0; $Index -lt $LocationList.Items.Count; $Index++) {
                $LocationList.SetItemChecked($Index, $false)
            }
        }.GetNewClosure())

        [System.Windows.Forms.Button]$RemoveButton = New-Object System.Windows.Forms.Button
        $RemoveButton.Text = 'Remove Checked'
        $RemoveButton.Location = New-Object System.Drawing.Point(470, $ButtonTop)
        $RemoveButton.Size = New-Object System.Drawing.Size(125, 28)
        $RemoveButton.Add_Click({
            if ($LocationList.CheckedIndices.Count -eq 0) {
                [void][System.Windows.Forms.MessageBox]::Show($Dialog, 'Select at least one certificate store location.', 'Remove Certificate', [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
                return
            }
            $Dialog.DialogResult = [System.Windows.Forms.DialogResult]::OK
            $Dialog.Close()
        }.GetNewClosure())

        [System.Windows.Forms.Button]$CancelButton = New-Object System.Windows.Forms.Button
        $CancelButton.Text = 'Cancel'
        $CancelButton.Location = New-Object System.Drawing.Point(601, $ButtonTop)
        $CancelButton.Size = New-Object System.Drawing.Size(81, 28)
        $CancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel

        # EXECUTION - SHOW DIALOG
        # Display the modal dialog and collect the checked location records
        $Dialog.Controls.AddRange(@($SubjectLabel, $ThumbprintLabel, $InstructionLabel, $LocationList, $WarningLabel, $SelectAllButton, $ClearAllButton, $RemoveButton, $CancelButton))
        $Dialog.CancelButton = $CancelButton
        [System.Windows.Forms.DialogResult]$DialogResult = Show-ModalDialog -Dialog $Dialog -Owner $Owner

        # OUTPUT
        # Return confirmation state together with only the explicitly checked locations
        [System.Collections.Generic.List[PSCustomObject]]$SelectedLocations = New-Object 'System.Collections.Generic.List[PSCustomObject]'
        if ($DialogResult -eq [System.Windows.Forms.DialogResult]::OK) {
            foreach ($CheckedIndex in $LocationList.CheckedIndices) {
                $SelectedLocations.Add($Locations[[System.Int32]$CheckedIndex])
            }
        }
        [PSCustomObject][ordered]@{
            Confirmed = ($DialogResult -eq [System.Windows.Forms.DialogResult]::OK)
            Locations = @($SelectedLocations)
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
    Removes a certificate from one CurrentUser certificate store.
.DESCRIPTION
    Opens the exact existing CurrentUser store with write access, removes every identical
    certificate context matching the thumbprint, and verifies that none remain.
.EXAMPLE
    Remove-CertificateFromCurrentUserStore -Location $CertificateLocation
.INPUTS
    [PSCustomObject]
.OUTPUTS
    [PSCustomObject]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.1.0
    Author          : Imraan Iotana
    Creation Date   : August 2026
    Last Update     : August 2026
#>
####################################################################################################
function Remove-CertificateFromCurrentUserStore {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The exact CurrentUser certificate store location to remove.')]
        [PSCustomObject]$Location
    )

    # PREPARATION - CERTIFICATE STORE
    # Initialize the writable store and matching certificate collection
    [System.Security.Cryptography.X509Certificates.X509Store]$CertificateStore = $null
    [System.Security.Cryptography.X509Certificates.X509Certificate2Collection]$MatchingCertificates = $null
    try {
        # EXECUTION - LIVE STORE LOOKUP
        # Open only the selected CurrentUser store and resolve all identical certificate contexts
        $CertificateStore = New-Object System.Security.Cryptography.X509Certificates.X509Store(
            [System.String]$Location.Store,
            [System.Security.Cryptography.X509Certificates.StoreLocation]::CurrentUser
        )
        $CertificateStore.Open(
            [System.Security.Cryptography.X509Certificates.OpenFlags]::ReadWrite -bor
            [System.Security.Cryptography.X509Certificates.OpenFlags]::OpenExistingOnly
        )
        $MatchingCertificates = $CertificateStore.Certificates.Find(
            [System.Security.Cryptography.X509Certificates.X509FindType]::FindByThumbprint,
            [System.String]$Location.Thumbprint,
            $false
        )
        if ($MatchingCertificates.Count -eq 0) {
            return [PSCustomObject][ordered]@{
                Scope   = 'CurrentUser'
                Store   = [System.String]$Location.Store
                Success = $false
                Message = 'The certificate was no longer present in the selected store.'
            }
        }

        # EXECUTION - REMOVE CERTIFICATE
        # Remove every identical context represented by this scope, store, and thumbprint
        foreach ($Certificate in @($MatchingCertificates)) {
            $CertificateStore.Remove($Certificate)
        }
    }
    catch {
        return [PSCustomObject][ordered]@{
            Scope   = 'CurrentUser'
            Store   = [System.String]$Location.Store
            Success = $false
            Message = [System.String]$_.Exception.Message
        }
    }
    finally {
        # POST-EXECUTION - DISPOSABLE VALUES
        # Dispose matching certificates and close the writable certificate store
        if ($null -ne $MatchingCertificates) {
            foreach ($Certificate in $MatchingCertificates) { $Certificate.Dispose() }
        }
        if ($null -ne $CertificateStore) {
            $CertificateStore.Close()
            $CertificateStore.Dispose()
        }
    }

    # VALIDATION - REMOVAL RESULT
    # Verify the thumbprint is absent from the exact CurrentUser store
    [System.Boolean]$CertificateStillExists = Test-CertificateInExactStore -Scope CurrentUser -Store $Location.Store -Thumbprint $Location.Thumbprint
    [PSCustomObject][ordered]@{
        Scope   = 'CurrentUser'
        Store   = [System.String]$Location.Store
        Success = (-not $CertificateStillExists)
        Message = if ($CertificateStillExists) {
            'The certificate removal completed, but the certificate is still present.'
        }
        else {
            'Certificate removed and verified.'
        }
    }
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Builds the elevated LocalMachine certificate removal script.
.DESCRIPTION
    Encodes selected store names as JSON and returns a Windows PowerShell script that removes and
    verifies one thumbprint in every selected LocalMachine certificate store.
.EXAMPLE
    New-CertificateLocalMachineRemovalScript -StoreNames @('My','Root') -Thumbprint $Thumbprint -ResultFilePath $ResultFilePath
.INPUTS
    [System.String[]]
    [System.String]
.OUTPUTS
    [System.String]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.1.0
    Author          : Imraan Iotana
    Creation Date   : August 2026
    Last Update     : August 2026
#>
####################################################################################################
function New-CertificateLocalMachineRemovalScript {
    [CmdletBinding()]
    [OutputType([System.String])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The unique LocalMachine certificate store names to process.')]
        [System.String[]]$StoreNames,

        [Parameter(Mandatory=$true,HelpMessage='The hexadecimal certificate thumbprint to remove.')]
        [ValidatePattern('^[0-9A-Fa-f]+$')]
        [System.String]$Thumbprint,

        [Parameter(Mandatory=$true,HelpMessage='The JSON file that will receive elevated removal results.')]
        [System.String]$ResultFilePath
    )

    # PREPARATION - ELEVATED INPUT
    # Encode store names as JSON and escape the result path embedded in the administrator script
    [System.String]$StoreJson = ConvertTo-Json -InputObject @($StoreNames) -Compress
    [System.String]$EncodedStores = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($StoreJson))
    [System.String]$EscapedResultFilePath = $ResultFilePath.Replace("'", "''")

    # OUTPUT
    # Return the self-contained script used by the elevated Windows PowerShell process
    [System.String]$ElevatedScript = @"
`$ErrorActionPreference = 'Stop'
`$StoreNames = @([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('$EncodedStores')) | ConvertFrom-Json)
`$Results = @()
foreach (`$StoreName in `$StoreNames) {
    `$CertificateStore = `$null
    `$MatchingCertificates = `$null
    try {
        `$CertificateStore = New-Object System.Security.Cryptography.X509Certificates.X509Store([System.String]`$StoreName, [System.Security.Cryptography.X509Certificates.StoreLocation]::LocalMachine)
        `$CertificateStore.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadWrite -bor [System.Security.Cryptography.X509Certificates.OpenFlags]::OpenExistingOnly)
        `$MatchingCertificates = `$CertificateStore.Certificates.Find([System.Security.Cryptography.X509Certificates.X509FindType]::FindByThumbprint, '$Thumbprint', `$false)
        if (`$MatchingCertificates.Count -eq 0) {
            `$Results += [PSCustomObject]@{ Scope = 'LocalMachine'; Store = [System.String]`$StoreName; Success = `$false; Message = 'The certificate was no longer present in the selected store.' }
            continue
        }
        foreach (`$Certificate in @(`$MatchingCertificates)) {
            `$CertificateStore.Remove(`$Certificate)
        }
        `$CertificateStore.Close()
        `$CertificateStore.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadOnly -bor [System.Security.Cryptography.X509Certificates.OpenFlags]::OpenExistingOnly)
        `$Remaining = `$CertificateStore.Certificates.Find([System.Security.Cryptography.X509Certificates.X509FindType]::FindByThumbprint, '$Thumbprint', `$false)
        `$Success = (`$Remaining.Count -eq 0)
        foreach (`$Certificate in `$Remaining) { `$Certificate.Dispose() }
        `$Results += [PSCustomObject]@{
            Scope = 'LocalMachine'
            Store = [System.String]`$StoreName
            Success = `$Success
            Message = if (`$Success) { 'Certificate removed and verified.' } else { 'The certificate removal completed, but the certificate is still present.' }
        }
    }
    catch {
        `$Results += [PSCustomObject]@{ Scope = 'LocalMachine'; Store = [System.String]`$StoreName; Success = `$false; Message = [System.String]`$_.Exception.Message }
    }
    finally {
        if (`$null -ne `$MatchingCertificates) { foreach (`$Certificate in `$MatchingCertificates) { `$Certificate.Dispose() } }
        if (`$null -ne `$CertificateStore) { `$CertificateStore.Close(); `$CertificateStore.Dispose() }
    }
}
[System.IO.File]::WriteAllText('$EscapedResultFilePath', (ConvertTo-Json -InputObject @(`$Results) -Compress), [System.Text.Encoding]::UTF8)
exit 0
"@
    return $ElevatedScript
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Removes a certificate from selected LocalMachine certificate stores with elevation.
.DESCRIPTION
    Sends all selected LocalMachine store names to one elevated Windows PowerShell process, removes
    matching certificate contexts, verifies each store independently, and returns per-store results.
.EXAMPLE
    Remove-CertificateFromLocalMachineStores -Locations $MachineLocations -Thumbprint $Thumbprint
.INPUTS
    [PSCustomObject[]]
    [System.String]
.OUTPUTS
    [PSCustomObject[]]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.1.0
    Author          : Imraan Iotana
    Creation Date   : August 2026
    Last Update     : August 2026
#>
####################################################################################################
function Remove-CertificateFromLocalMachineStores {
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The selected LocalMachine certificate store locations to remove.')]
        [PSCustomObject[]]$Locations,

        [Parameter(Mandatory=$true,HelpMessage='The certificate thumbprint to remove from each selected store.')]
        [ValidatePattern('^[0-9A-Fa-f]+$')]
        [System.String]$Thumbprint
    )

    # PREPARATION - ELEVATED INPUT
    # Resolve unique store names and create a result file path for the elevated process
    [System.String[]]$StoreNames = @($Locations | ForEach-Object { [System.String]$_.Store } | Sort-Object -Unique)
    [System.String]$ResultFilePath = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath ("ADA-CertificateRemoval-{0}.json" -f [System.Guid]::NewGuid().ToString('N'))

    # PREPARATION - ELEVATED SCRIPT
    # Build one administrator script that removes and verifies the thumbprint in every selected store
    [System.String]$ElevatedScript = New-CertificateLocalMachineRemovalScript -StoreNames $StoreNames -Thumbprint $Thumbprint -ResultFilePath $ResultFilePath

    try {
        # EXECUTION - ELEVATED REMOVAL
        # Run all selected removals in one administrator process and collect its exit code
        [System.Int32]$ElevatedExitCode = Invoke-ElevatedPowerShell -Script $ElevatedScript -StartFailureMessage 'The elevated certificate removal process could not be started.'
        if ($ElevatedExitCode -ne 0) {
            throw "The elevated certificate removal failed with exit code $ElevatedExitCode."
        }
        if (-not (Test-Path -LiteralPath $ResultFilePath -PathType Leaf)) {
            throw 'The elevated certificate removal returned no results.'
        }

        # OUTPUT
        # Read and return the independently verified result for every selected LocalMachine store
        [PSCustomObject[]]$Results = @(Get-Content -LiteralPath $ResultFilePath -Raw -ErrorAction Stop | ConvertFrom-Json)
        @($Results)
    }
    finally {
        # POST-EXECUTION - RESULT CLEANUP
        # Remove the temporary elevated result file
        Remove-Item -LiteralPath $ResultFilePath -Force -ErrorAction SilentlyContinue
    }
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Removes selected installations of a certificate from Certificate Management.
.DESCRIPTION
    Resolves the selected row, refreshes all matching locations, lets the user choose exact stores,
    handles CurrentUser and LocalMachine removal, reports each result, and refreshes the active view.
.EXAMPLE
    Invoke-SelectedCertificateRemoval -ListView $CertificateResultsListView -SearchTextBox $SearchTextBox
.INPUTS
    [System.Windows.Forms.ListView]
    [System.Windows.Forms.TextBox]
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.1.0
    Author          : Imraan Iotana
    Creation Date   : August 2026
    Last Update     : August 2026
#>
####################################################################################################
function Invoke-SelectedCertificateRemoval {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The Certificate Results ListView containing the selected certificate.')]
        [System.Windows.Forms.ListView]$ListView,

        [Parameter(Mandatory=$false,HelpMessage='The Certificate Management search textbox whose view will be restored.')]
        [AllowNull()]
        [System.Windows.Forms.TextBox]$SearchTextBox
    )

    try {
        # VALIDATION - SELECTED CERTIFICATE
        # Resolve the selected row and require its supported scope and store identity
        [PSCustomObject]$CertificateRecord = Get-SelectedCertificateRecord -ListView $ListView
        if ($null -eq $CertificateRecord) { return }
        if ([System.String]$CertificateRecord.Scope -notin @('CurrentUser','LocalMachine')) {
            throw "The selected certificate scope is not supported. ($($CertificateRecord.Scope))"
        }
        if ([System.String]::IsNullOrWhiteSpace([System.String]$CertificateRecord.Store)) {
            throw 'The selected certificate does not contain a certificate store name.'
        }

        # PREPARATION - LIVE LOCATIONS
        # Refresh every store so the dialog never relies on stale ListView inventory
        Write-Line "Checking current installations for thumbprint $($CertificateRecord.Thumbprint)..." -Type Busy
        [PSCustomObject[]]$Locations = @(Get-CertificateRemovalLocations -CertificateRecord $CertificateRecord)
        if ($Locations.Count -eq 0) {
            Write-Line 'The selected certificate is no longer installed in any readable certificate store.' -Type Warning
            Update-CertificateResultsAfterMutation -ListView $ListView -SearchTextBox $SearchTextBox
            return
        }

        # CONFIRMATION - REMOVAL LOCATIONS
        # Let the user explicitly select every scope and store that may be changed
        [System.Windows.Forms.Form]$Owner = $ListView.FindForm()
        [PSCustomObject]$SelectionResult = Select-CertificateRemovalLocations -CertificateRecord $CertificateRecord -Locations $Locations -Owner $Owner
        if (-not $SelectionResult.Confirmed) {
            Write-Line 'The certificate removal was canceled.' -Type Warning
            return
        }

        # EXECUTION - CURRENTUSER REMOVAL
        # Remove each selected CurrentUser location directly in the application process
        [System.Collections.Generic.List[PSCustomObject]]$RemovalResults = New-Object 'System.Collections.Generic.List[PSCustomObject]'
        [PSCustomObject[]]$CurrentUserLocations = @($SelectionResult.Locations | Where-Object Scope -eq 'CurrentUser')
        foreach ($Location in $CurrentUserLocations) {
            Write-Line "Removing certificate from $($Location.StorePath)..." -Type Busy
            $RemovalResults.Add((Remove-CertificateFromCurrentUserStore -Location $Location))
        }

        # EXECUTION - LOCALMACHINE REMOVAL
        # Request administrator approval once for all selected LocalMachine locations
        [PSCustomObject[]]$LocalMachineLocations = @($SelectionResult.Locations | Where-Object Scope -eq 'LocalMachine')
        if ($LocalMachineLocations.Count -gt 0) {
            Write-Line "Requesting administrator approval to remove the certificate from $($LocalMachineLocations.Count) LocalMachine store location(s)..." -Type Busy
            foreach ($Result in @(Remove-CertificateFromLocalMachineStores -Locations $LocalMachineLocations -Thumbprint $CertificateRecord.Thumbprint)) {
                $RemovalResults.Add($Result)
            }
        }

        # POST-EXECUTION - RESULTS
        # Report every verified success and failure without hiding partial outcomes
        foreach ($Result in $RemovalResults) {
            [System.String]$ResultLocation = "$($Result.Scope)\$($Result.Store)"
            if ($Result.Success) {
                Write-Line "Removed certificate from $ResultLocation." -Type Success
            }
            else {
                Write-Line "Certificate was not removed from $ResultLocation. ($($Result.Message))" -Type Warning
            }
        }

        # POST-EXECUTION - LISTVIEW REFRESH
        # Refresh the cache after processing while preserving the active search or preset filter
        Update-CertificateResultsAfterMutation -ListView $ListView -SearchTextBox $SearchTextBox
    }
    catch [System.ComponentModel.Win32Exception] {
        if ($_.Exception.NativeErrorCode -eq 1223) {
            Write-Line 'The certificate removal was canceled at the administrator prompt.' -Type Warning
            return
        }
        Write-ErrorReport -ErrorRecord $_
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}

### END OF FUNCTION
####################################################################################################