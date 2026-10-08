####################################################################################################
<#
.SYNOPSIS
    Provides certificate export helpers.
.DESCRIPTION
    Exports selected public certificates and exportable private keys from Certificate Management.
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
    Returns a safe default file name for a certificate export.
.DESCRIPTION
    Uses the certificate subject display name and a short thumbprint suffix while replacing invalid
    file-name characters and limiting the display-name portion to 80 characters.
.EXAMPLE
    Get-CertificateExportDefaultFileName -CertificateRecord $CertificateRecord
.INPUTS
    [PSCustomObject]
.OUTPUTS
    [System.String]
#>
####################################################################################################
function Get-CertificateExportDefaultFileName {
    [CmdletBinding()]
    [OutputType([System.String])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The normalized certificate record used to build the file name.')]
        [PSCustomObject]$CertificateRecord
    )

    # PREPARATION - DISPLAY NAME
    # Resolve a subject-based file name with a stable fallback
    [System.String]$DisplayName = [System.String]$CertificateRecord.SubjectName
    if ([System.String]::IsNullOrWhiteSpace($DisplayName)) {
        $DisplayName = 'Certificate'
    }

    # EXECUTION - FILE NAME SANITIZATION
    # Replace invalid characters and keep the descriptive portion reasonably short
    foreach ($InvalidCharacter in [System.IO.Path]::GetInvalidFileNameChars()) {
        $DisplayName = $DisplayName.Replace([System.String]$InvalidCharacter, '_')
    }

    $DisplayName = $DisplayName.Trim().TrimEnd('.')
    if ($DisplayName.Length -gt 80) {
        $DisplayName = $DisplayName.Substring(0, 80).Trim()
    }

    # PREPARATION - THUMBPRINT SUFFIX
    # Resolve a short thumbprint that distinguishes certificates with the same subject
    [System.String]$ThumbprintSuffix = [System.String]$CertificateRecord.Thumbprint
    if ($ThumbprintSuffix.Length -gt 8) {
        $ThumbprintSuffix = $ThumbprintSuffix.Substring(0, 8)
    }

    # OUTPUT
    # Return the display name alone or append its available thumbprint suffix
    if ([System.String]::IsNullOrWhiteSpace($ThumbprintSuffix)) {
        return $DisplayName
    }

    return "$DisplayName - $ThumbprintSuffix"
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Lets the user choose a certificate export format.
.DESCRIPTION
    Displays a modal format dialog for exporting the public certificate or the certificate together
    with its private key as a PFX package.
.EXAMPLE
    Select-CertificateExportFormat -Owner $MainForm
.INPUTS
    [System.Windows.Forms.IWin32Window]
.OUTPUTS
    [System.String]
#>
####################################################################################################
function Select-CertificateExportFormat {
    [CmdletBinding()]
    [OutputType([System.String])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The window that owns the certificate export format dialog.')]
        [System.Windows.Forms.IWin32Window]$Owner
    )

    # PREPARATION - DIALOG
    # Create the fixed export-format dialog and its prompt
    [System.Windows.Forms.Form]$Dialog = New-ModalDialog -Title 'Export Certificate' -ClientWidth 470 -ClientHeight 190 -Owner $Owner
    try {
        [System.Windows.Forms.Label]$PromptLabel = New-Object System.Windows.Forms.Label
        $PromptLabel.Text = 'Choose what the export should contain.'
        $PromptLabel.Location = New-Object System.Drawing.Point(18, 18)
        $PromptLabel.Size = New-Object System.Drawing.Size(430, 24)

        # PREPARATION - FORMAT ACTIONS
        # Create public certificate, PFX package, and cancellation actions
        [System.Windows.Forms.Button]$PublicButton = New-Object System.Windows.Forms.Button
        $PublicButton.Text = 'Public certificate (.cer)'
        $PublicButton.Location = New-Object System.Drawing.Point(18, 55)
        $PublicButton.Size = New-Object System.Drawing.Size(205, 48)
        $PublicButton.DialogResult = [System.Windows.Forms.DialogResult]::Yes

        [System.Windows.Forms.Button]$PfxButton = New-Object System.Windows.Forms.Button
        $PfxButton.Text = 'Certificate and private key (.pfx)'
        $PfxButton.Location = New-Object System.Drawing.Point(241, 55)
        $PfxButton.Size = New-Object System.Drawing.Size(205, 48)
        $PfxButton.DialogResult = [System.Windows.Forms.DialogResult]::No

        [System.Windows.Forms.Button]$CancelButton = New-Object System.Windows.Forms.Button
        $CancelButton.Text = 'Cancel'
        $CancelButton.Location = New-Object System.Drawing.Point(371, 130)
        $CancelButton.Size = New-Object System.Drawing.Size(75, 28)
        $CancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel

        # EXECUTION - SHOW DIALOG
        # Display the modal dialog and map its result to the selected export format
        $Dialog.Controls.AddRange(@($PromptLabel, $PublicButton, $PfxButton, $CancelButton))
        $Dialog.CancelButton = $CancelButton

        [System.Windows.Forms.DialogResult]$DialogResult = Show-ModalDialog -Dialog $Dialog -Owner $Owner
        if ($DialogResult -eq [System.Windows.Forms.DialogResult]::Yes) {
            return 'Cer'
        }
        if ($DialogResult -eq [System.Windows.Forms.DialogResult]::No) {
            return 'Pfx'
        }
        return $null
    }
    finally {
        # POST-EXECUTION - DIALOG CLEANUP
        # Dispose the temporary modal dialog
        $Dialog.Dispose()
    }
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Exports the certificate selected in Certificate Management.
.DESCRIPTION
    Resolves the selected certificate, requests CER or PFX output, obtains a PFX password when
    required, writes the selected file, and verifies the exported byte count.
.EXAMPLE
    Invoke-SelectedCertificateExport -ListView $CertificateResultsListView
.INPUTS
    [System.Windows.Forms.ListView]
.OUTPUTS
    No objects are returned to the pipeline.
#>
####################################################################################################
function Invoke-SelectedCertificateExport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The Certificate Results ListView containing the selected certificate.')]
        [System.Windows.Forms.ListView]$ListView
    )

    [System.String]$PfxPassword = $null
    [System.Windows.Forms.SaveFileDialog]$SaveDialog = $null
    try {
        # VALIDATION - SELECTED CERTIFICATE
        # Resolve the selected row and its attached X.509 certificate object
        [PSCustomObject]$CertificateRecord = Get-SelectedCertificateRecord -ListView $ListView
        if ($null -eq $CertificateRecord) {
            return
        }

        [System.Security.Cryptography.X509Certificates.X509Certificate2]$Certificate = $CertificateRecord.Certificate
        if ($null -eq $Certificate) {
            throw 'The selected certificate row does not contain an X.509 certificate object.'
        }

        # PREPARATION - EXPORT FORMAT
        # Offer PFX output only when the selected certificate has a private key
        [System.Windows.Forms.Form]$Owner = $ListView.FindForm()
        [System.String]$ExportFormat = 'Cer'
        if ($Certificate.HasPrivateKey) {
            $ExportFormat = Select-CertificateExportFormat -Owner $Owner
            if ([System.String]::IsNullOrWhiteSpace($ExportFormat)) {
                return
            }
        }

        # PREPARATION - OUTPUT FILE
        # Configure the save dialog for the selected certificate format
        [System.String]$DefaultFileName = Get-CertificateExportDefaultFileName -CertificateRecord $CertificateRecord
        $SaveDialog = New-Object System.Windows.Forms.SaveFileDialog
        $SaveDialog.FileName = $DefaultFileName
        $SaveDialog.OverwritePrompt = $true
        $SaveDialog.AddExtension = $true
        # PREPARATION - PFX PASSWORD
        # Request and confirm the password used to protect private-key output
        if ($ExportFormat -eq 'Pfx') {
            $SaveDialog.Filter = 'Personal Information Exchange (*.pfx)|*.pfx'
            $SaveDialog.DefaultExt = 'pfx'
        }
        else {
            $SaveDialog.Filter = 'DER encoded certificate (*.cer)|*.cer'
            $SaveDialog.DefaultExt = 'cer'
        }

        if ($SaveDialog.ShowDialog($Owner) -ne [System.Windows.Forms.DialogResult]::OK) {
            return
        }

        if ($ExportFormat -eq 'Pfx') {
            [PSCustomObject]$PasswordResult = Read-CertificatePassword -Owner $Owner -Title 'Protect PFX Export' -ConfirmPassword
            if (-not $PasswordResult.Confirmed) {
                return
            }
            $PfxPassword = [System.String]$PasswordResult.Password
            $PasswordResult.Password = $null
        }

        # EXECUTION - CERTIFICATE EXPORT
        # Export public certificate bytes or password-protected certificate and private-key bytes
        Write-Line "Exporting certificate from $($CertificateRecord.Scope)\$($CertificateRecord.Store)..." -Type Busy
        [System.Byte[]]$ExportBytes = if ($ExportFormat -eq 'Pfx') {
            $Certificate.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Pfx, $PfxPassword)
        }
        else {
            $Certificate.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Cert)
        }

        # VALIDATION - EXPORT RESULT
        # Require export data and verify the published file length
        if (($null -eq $ExportBytes) -or ($ExportBytes.Length -eq 0)) {
            throw 'The certificate export returned no data.'
        }

        [System.IO.File]::WriteAllBytes($SaveDialog.FileName, $ExportBytes)
        [System.IO.FileInfo]$ExportedFile = Get-Item -LiteralPath $SaveDialog.FileName -ErrorAction Stop
        if ($ExportedFile.Length -ne $ExportBytes.Length) {
            throw 'The exported certificate file could not be verified.'
        }

        Write-Line "Exported certificate to '$($ExportedFile.FullName)'." -Type Success
    }
    catch [System.Security.Cryptography.CryptographicException] {
        [System.String]$Message = 'The private key could not be exported. It may be non-exportable, inaccessible, or require administrator access.'
        [void][System.Windows.Forms.MessageBox]::Show($Owner, $Message, 'Certificate Export', [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
        Write-Line $Message -Type Warning
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
    finally {
        # POST-EXECUTION - DISPOSABLE VALUES
        # Clear the plain-text password and dispose the save dialog
        $PfxPassword = $null
        if ($null -ne $SaveDialog) {
            $SaveDialog.Dispose()
        }
    }
}

### END OF FUNCTION
####################################################################################################