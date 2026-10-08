####################################################################################################
<#
.SYNOPSIS
    Provides shared certificate infrastructure helpers.
.DESCRIPTION
    Opens certificate files, checks exact certificate stores, and runs certificate operations in
    an elevated Windows PowerShell process.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.1.0
    Author          : Imraan Iotana
    Creation Date   : August 2026
    Last Update     : August 2026
#>
####################################################################################################
####################################################################################################
<#
.SYNOPSIS
    Opens a public certificate or PFX package from disk.
.DESCRIPTION
    Loads public certificate files directly, opens PFX packages with the supplied password, and
    requests a password when a PFX package cannot be opened with an empty password.
.EXAMPLE
    Read-CertificateFileSource -CertificateFilePath 'C:\Certificates\Example.pfx' -Owner $MainForm
.INPUTS
    [System.String]
    [System.Windows.Forms.IWin32Window]
.OUTPUTS
    [PSCustomObject]
#>
####################################################################################################
function Read-CertificateFileSource {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The certificate file to open.')]
        [System.String]$CertificateFilePath,

        [Parameter(Mandatory=$false,HelpMessage='Optional password used to open a PFX package.')]
        [AllowEmptyString()]
        [System.String]$Password = [System.String]::Empty,

        [Parameter(Mandatory=$false,HelpMessage='The window that owns the PFX password dialog.')]
        [AllowNull()]
        [System.Windows.Forms.IWin32Window]$Owner,

        [Parameter(Mandatory=$false,HelpMessage='The title displayed by the PFX password dialog.')]
        [System.String]$PasswordDialogTitle = 'Open PFX Certificate',

        [Parameter(Mandatory=$false,HelpMessage='The host message written when password entry is canceled.')]
        [System.String]$CancellationMessage = 'Opening the certificate was canceled.'
    )

    # PREPARATION - CERTIFICATE TYPE
    # Determine whether the selected file is a password-capable certificate package
    [System.String]$CertificateExtension = [System.IO.Path]::GetExtension($CertificateFilePath).ToLowerInvariant()
    [System.Boolean]$IsPfx = ($CertificateExtension -in @('.pfx','.p12'))
    [System.String]$PfxPassword = $Password

    # EXECUTION - PUBLIC CERTIFICATE
    # Open a public certificate without requesting a password
    if (-not $IsPfx) {
        return [PSCustomObject][ordered]@{
            Confirmed   = $true
            Certificate = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($CertificateFilePath)
            Password    = [System.String]::Empty
            IsPfx       = $false
        }
    }

    # EXECUTION - PFX CERTIFICATE
    # Attempt to open the PFX package with the supplied or empty password
    try {
        [System.Security.Cryptography.X509Certificates.X509Certificate2]$Certificate = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2(
            $CertificateFilePath,
            $PfxPassword,
            [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::EphemeralKeySet
        )
    }
    catch [System.Security.Cryptography.CryptographicException] {
        # VALIDATION - SUPPLIED PASSWORD
        # Report a supplied invalid password without prompting for a replacement
        if (-not [System.String]::IsNullOrEmpty($PfxPassword)) {
            Write-Line 'The PFX file could not be opened. The password may be incorrect.' -Type Warning
            return [PSCustomObject][ordered]@{
                Confirmed   = $false
                Certificate = $null
                Password    = $null
                IsPfx       = $true
            }
        }

        # EXECUTION - PASSWORD PROMPT
        # Request a password only when the PFX package cannot be opened without one
        [PSCustomObject]$PasswordResult = Read-CertificatePassword -Owner $Owner -Title $PasswordDialogTitle -PasswordLabel 'PFX password'
        if (-not $PasswordResult.Confirmed) {
            Write-Line $CancellationMessage -Type Warning
            return [PSCustomObject][ordered]@{
                Confirmed   = $false
                Certificate = $null
                Password    = $null
                IsPfx       = $true
            }
        }

        $PfxPassword = [System.String]$PasswordResult.Password
        $PasswordResult.Password = $null

        # EXECUTION - PROTECTED PFX CERTIFICATE
        # Retry the PFX package with the password supplied by the user
        try {
            $Certificate = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2(
                $CertificateFilePath,
                $PfxPassword,
                [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::EphemeralKeySet
            )
        }
        catch [System.Security.Cryptography.CryptographicException] {
            Write-Line 'The PFX file could not be opened. The password may be incorrect.' -Type Warning
            return [PSCustomObject][ordered]@{
                Confirmed   = $false
                Certificate = $null
                Password    = $null
                IsPfx       = $true
            }
        }
    }

    # OUTPUT
    # Return the loaded certificate together with the password required by import callers
    [PSCustomObject][ordered]@{
        Confirmed   = $true
        Certificate = $Certificate
        Password    = $PfxPassword
        IsPfx       = $true
    }
}

### END OF FUNCTION
####################################################################################################
####################################################################################################
<#
.SYNOPSIS
    Tests whether a certificate exists in an exact Windows certificate store.
.DESCRIPTION
    Opens an existing CurrentUser or LocalMachine store as read-only and matches the supplied
    thumbprint without applying certificate validity filtering.
.EXAMPLE
    Test-CertificateInExactStore -Scope CurrentUser -Store My -Thumbprint '0123456789ABCDEF'
.INPUTS
    [System.String]
.OUTPUTS
    [System.Boolean]
#>
####################################################################################################
function Test-CertificateInExactStore {
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The certificate store scope to inspect.')]
        [ValidateSet('CurrentUser','LocalMachine')]
        [System.String]$Scope,

        [Parameter(Mandatory=$true,HelpMessage='The existing certificate store name to inspect.')]
        [System.String]$Store,

        [Parameter(Mandatory=$true,HelpMessage='The certificate thumbprint to find.')]
        [System.String]$Thumbprint
    )

    # PREPARATION - CERTIFICATE STORE
    # Resolve the .NET store location and initialize disposable store values
    [System.Security.Cryptography.X509Certificates.StoreLocation]$StoreLocation = [System.Enum]::Parse([System.Security.Cryptography.X509Certificates.StoreLocation], $Scope)
    [System.Security.Cryptography.X509Certificates.X509Store]$CertificateStore = $null
    [System.Security.Cryptography.X509Certificates.X509Certificate2Collection]$MatchingCertificates = $null
    try {
        # EXECUTION - LIVE STORE LOOKUP
        # Open only an existing store and find every certificate with the exact thumbprint
        $CertificateStore = New-Object System.Security.Cryptography.X509Certificates.X509Store($Store, $StoreLocation)
        $CertificateStore.Open(
            [System.Security.Cryptography.X509Certificates.OpenFlags]::ReadOnly -bor
            [System.Security.Cryptography.X509Certificates.OpenFlags]::OpenExistingOnly
        )
        $MatchingCertificates = $CertificateStore.Certificates.Find(
            [System.Security.Cryptography.X509Certificates.X509FindType]::FindByThumbprint,
            $Thumbprint,
            $false
        )

        # OUTPUT
        # Return whether at least one matching certificate remains in the exact store
        return ($MatchingCertificates.Count -gt 0)
    }
    finally {
        # POST-EXECUTION - DISPOSABLE VALUES
        # Dispose certificates returned by the lookup and close the certificate store
        if ($null -ne $MatchingCertificates) {
            foreach ($Certificate in $MatchingCertificates) { $Certificate.Dispose() }
        }
        if ($null -ne $CertificateStore) {
            $CertificateStore.Close()
            $CertificateStore.Dispose()
        }
    }
}

### END OF FUNCTION
####################################################################################################
