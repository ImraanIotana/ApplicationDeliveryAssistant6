####################################################################################################
<#
.SYNOPSIS
    Provides certificate import helpers.
.DESCRIPTION
    Imports public certificates and PFX packages into CurrentUser or LocalMachine certificate stores.
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
    Imports a certificate into a CurrentUser certificate store.
.DESCRIPTION
    Uses the PKI module to import a public certificate or PFX package directly into the selected
    CurrentUser certificate store and verifies that the command returned a certificate.
.EXAMPLE
    Import-CertificateToCurrentUserStore -CertificateFilePath 'C:\Certificates\Example.cer' -StorePath 'Cert:\CurrentUser\My' -IsPfx $false
.INPUTS
    [System.String]
    [System.String]
    [System.Boolean]
    [System.String]
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
function Import-CertificateToCurrentUserStore {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The certificate file to import.')]
        [System.String]$CertificateFilePath,

        [Parameter(Mandatory=$true,HelpMessage='The CurrentUser certificate store provider path.')]
        [System.String]$StorePath,

        [Parameter(Mandatory=$true,HelpMessage='Indicates whether the certificate file is a PFX package.')]
        [System.Boolean]$IsPfx,

        [Parameter(Mandatory=$false,HelpMessage='The password used to open the PFX package.')]
        [AllowEmptyString()]
        [System.String]$PfxPassword = [System.String]::Empty
    )

    # PREPARATION - DISPOSABLE VALUES
    # Initialize the secure password that must be disposed after the import
    [System.Security.SecureString]$SecureImportPassword = $null
    try {
        # PREPARATION - IMPORT PARAMETERS
        # Set the shared PKI import parameters for the selected certificate store
        [System.Collections.Hashtable]$ImportParameters = @{
            FilePath          = $CertificateFilePath
            CertStoreLocation = $StorePath
            ErrorAction       = 'Stop'
        }

        # EXECUTION - IMPORT CERTIFICATE
        # Import the PFX package with its password or import the public certificate directly
        [System.Object[]]$ImportedCertificates = if ($IsPfx) {
            if (-not [System.String]::IsNullOrEmpty($PfxPassword)) {
                $SecureImportPassword = ConvertTo-SecureString -String $PfxPassword -AsPlainText -Force
                $ImportParameters.Password = $SecureImportPassword
            }
            @(Import-PfxCertificate @ImportParameters)
        }
        else {
            @(Import-Certificate @ImportParameters)
        }

        # VALIDATION - IMPORT RESULT
        # Require the PKI command to return at least one imported certificate
        if ($ImportedCertificates.Count -eq 0) {
            throw 'The certificate import returned no certificates.'
        }
    }
    finally {
        # POST-EXECUTION - PASSWORD CLEANUP
        # Dispose the temporary secure password when one was created
        if ($null -ne $SecureImportPassword) {
            $SecureImportPassword.Dispose()
        }
    }
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Imports a certificate into a LocalMachine certificate store with elevation.
.DESCRIPTION
    Builds and starts an elevated Windows PowerShell process that imports a public certificate or
    PFX package into the selected LocalMachine certificate store.
.EXAMPLE
    Import-CertificateToLocalMachineStore -CertificateFilePath 'C:\Certificates\Example.cer' -StorePath 'Cert:\LocalMachine\My' -IsPfx $false
.INPUTS
    [System.String]
    [System.String]
    [System.Boolean]
    [System.String]
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
function Import-CertificateToLocalMachineStore {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The certificate file to import.')]
        [System.String]$CertificateFilePath,

        [Parameter(Mandatory=$true,HelpMessage='The LocalMachine certificate store provider path.')]
        [System.String]$StorePath,

        [Parameter(Mandatory=$true,HelpMessage='Indicates whether the certificate file is a PFX package.')]
        [System.Boolean]$IsPfx,

        [Parameter(Mandatory=$false,HelpMessage='The password used to open the PFX package.')]
        [AllowEmptyString()]
        [System.String]$PfxPassword = [System.String]::Empty
    )

    # PREPARATION - DISPOSABLE VALUES
    # Initialize the secure password that must be disposed after the import
    [System.Security.SecureString]$SecureImportPassword = $null
    try {
        # PREPARATION - ELEVATED IMPORT
        # Escape values embedded in the elevated script
        [System.String]$EscapedCertificateFilePath = $CertificateFilePath.Replace("'", "''")
        [System.String]$EscapedStorePath = $StorePath.Replace("'", "''")

        # PREPARATION - PROTECTED PASSWORD
        # Protect a populated PFX password for transfer to the elevated process
        [System.String]$ProtectedPassword = [System.String]::Empty
        if ($IsPfx -and (-not [System.String]::IsNullOrEmpty($PfxPassword))) {
            $SecureImportPassword = ConvertTo-SecureString -String $PfxPassword -AsPlainText -Force
            $ProtectedPassword = ConvertFrom-SecureString -SecureString $SecureImportPassword
        }
        [System.String]$EscapedProtectedPassword = $ProtectedPassword.Replace("'", "''")

        # PREPARATION - ELEVATED SCRIPT
        # Build the PKI command for a PFX package or public certificate
        [System.String]$ElevatedScript = if ($IsPfx) {
@"
`$ErrorActionPreference = 'Stop'
Import-Module PKI -ErrorAction Stop
`$ImportParameters = @{
    FilePath = '$EscapedCertificateFilePath'
    CertStoreLocation = '$EscapedStorePath'
    ErrorAction = 'Stop'
}
if (-not [System.String]::IsNullOrEmpty('$EscapedProtectedPassword')) {
    `$ImportParameters.Password = ConvertTo-SecureString '$EscapedProtectedPassword'
}
`$ImportedCertificates = @(Import-PfxCertificate @ImportParameters)
if (`$ImportedCertificates.Count -eq 0) { exit 2 }
exit 0
"@
        }
        else {
@"
`$ErrorActionPreference = 'Stop'
Import-Module PKI -ErrorAction Stop
`$ImportedCertificates = @(Import-Certificate -FilePath '$EscapedCertificateFilePath' -CertStoreLocation '$EscapedStorePath' -ErrorAction Stop)
if (`$ImportedCertificates.Count -eq 0) { exit 2 }
exit 0
"@
        }

        # EXECUTION - ELEVATED IMPORT
        # Run the import script in one administrator process and collect its exit code
        [System.Int32]$ElevatedExitCode = Invoke-ElevatedPowerShell -Script $ElevatedScript -StartFailureMessage 'The elevated certificate import process could not be started.'

        # VALIDATION - ELEVATED RESULT
        # Require the elevated import process to report a successful exit code
        if ($ElevatedExitCode -ne 0) {
            throw "The elevated certificate import failed with exit code $ElevatedExitCode."
        }
    }
    finally {
        # POST-EXECUTION - PASSWORD CLEANUP
        # Dispose the temporary secure password when one was created
        if ($null -ne $SecureImportPassword) {
            $SecureImportPassword.Dispose()
        }
    }
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Imports a certificate file into a selected Windows certificate store.
.DESCRIPTION
    Validates and confirms the certificate import, requests a PFX password when required, elevates
    LocalMachine imports, and verifies the imported certificate by thumbprint.
.EXAMPLE
    Import-CertificateFileToStore -CertificateFilePath 'C:\Certificates\Example.cer' -Scope CurrentUser -Store My
.INPUTS
    [System.String]
    [System.String]
    [System.String]
.OUTPUTS
    [System.Boolean]
#>
####################################################################################################
function Import-CertificateFileToStore {
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The certificate file to import.')]
        [AllowEmptyString()]
        [System.String]$CertificateFilePath,

        [Parameter(Mandatory=$true,HelpMessage='The certificate store scope.')]
        [ValidateSet('CurrentUser','LocalMachine')]
        [System.String]$Scope,

        [Parameter(Mandatory=$true,HelpMessage='The destination certificate store.')]
        [ValidateSet('My','Root','CA','TrustedPublisher','TrustedPeople','AuthRoot')]
        [System.String]$Store,

        [Parameter(Mandatory=$false,HelpMessage='The window that owns certificate dialogs.')]
        [AllowNull()]
        [System.Windows.Forms.IWin32Window]$Owner,

        [Parameter(Mandatory=$false,HelpMessage='The Certificate Management ListView to search after a successful import.')]
        [AllowNull()]
        [System.Windows.Forms.ListView]$ListView,

        [Parameter(Mandatory=$false,HelpMessage='The Certificate Management search textbox to populate after a successful import.')]
        [AllowNull()]
        [System.Windows.Forms.TextBox]$SearchTextBox
    )

    # PREPARATION - DISPOSABLE VALUES
    # Initialize certificate and password values that must be cleared after the import
    [System.Security.Cryptography.X509Certificates.X509Certificate2]$SourceCertificate = $null
    [System.String]$PfxPassword = [System.String]::Empty
    try {
        # PREPARATION - CERTIFICATE FILE
        # Validate and resolve the selected certificate file
        if ([System.String]::IsNullOrWhiteSpace($CertificateFilePath)) {
            Write-Line 'No certificate file was selected.' -Type Warning
            return $false
        }
        if (-not (Test-Path -LiteralPath $CertificateFilePath -PathType Leaf)) {
            Write-Line "Certificate file does not exist. ($CertificateFilePath)" -Type Warning
            return $false
        }

        [System.String]$ResolvedCertificateFilePath = [System.IO.Path]::GetFullPath($CertificateFilePath)
        [System.String]$CertificateExtension = [System.IO.Path]::GetExtension($ResolvedCertificateFilePath).ToLowerInvariant()
        [System.Boolean]$IsPfx = ($CertificateExtension -in @('.pfx','.p12'))
        if ($CertificateExtension -notin @('.cer','.crt','.der','.pfx','.p12')) {
            Write-Line "The selected file type is not supported for certificate import. ($CertificateExtension)" -Type Warning
            return $false
        }

        # EXECUTION - READ SOURCE CERTIFICATE
        # Read the source certificate and request a PFX password only when one is required
        [PSCustomObject]$ImportSource = Read-CertificateFileSource -CertificateFilePath $ResolvedCertificateFilePath -Owner $Owner -PasswordDialogTitle 'Import PFX Certificate' -CancellationMessage 'The certificate import was canceled.'
        if (-not $ImportSource.Confirmed) {
            return $false
        }
        $SourceCertificate = $ImportSource.Certificate
        $PfxPassword = [System.String]$ImportSource.Password
        $ImportSource.Password = $null

        # PREPARATION - INSTALLED CERTIFICATE CHECK
        # Resolve the shared installation state across CurrentUser and LocalMachine stores
        [System.String]$StorePath = "Cert:\$Scope\$Store"
        [PSCustomObject]$InstallationState = Get-CertificateInstallationState -Certificate $SourceCertificate

        # PREPARATION - IMPORT CONFIRMATION
        # Confirm the certificate and destination before modifying the selected store
        [System.String]$ConfirmationBody = if ($InstallationState.Installed) {
            [System.String]$InstalledLocationText = @(
                $InstallationState.InstalledLocations | ForEach-Object { "  - $_" }
            ) -join "`n"
            "The certificate is already installed in the following locations:`n`n$InstalledLocationText`n`nSelected destination: $StorePath`nSubject: $($SourceCertificate.Subject)`nThumbprint: $($SourceCertificate.Thumbprint)`n`nDo you want to import it anyway?"
        }
        else {
            "This will import the following certificate:`n`nSubject: $($SourceCertificate.Subject)`nThumbprint: $($SourceCertificate.Thumbprint)`nDestination: $StorePath`n`nDo you want to continue?"
        }
        [System.Collections.Hashtable]$ConfirmationParameters = @{
            Title = 'Import Certificate'
            Body  = $ConfirmationBody
        }
        if ($InstallationState.Installed) {
            $ConfirmationParameters.Type = 'Warning'
        }
        if (-not (Get-UserConfirmation @ConfirmationParameters)) {
            Write-Line 'The certificate import was canceled.' -Type Warning
            return $false
        }

        # EXECUTION - IMPORT CERTIFICATE
        # Import directly for CurrentUser or request elevation for LocalMachine
        Write-Line "Importing certificate into $StorePath..." -Type Busy
        if ($Scope -eq 'LocalMachine') {
            Import-CertificateToLocalMachineStore -CertificateFilePath $ResolvedCertificateFilePath -StorePath $StorePath -IsPfx $IsPfx -PfxPassword $PfxPassword
        }
        else {
            Import-CertificateToCurrentUserStore -CertificateFilePath $ResolvedCertificateFilePath -StorePath $StorePath -IsPfx $IsPfx -PfxPassword $PfxPassword
        }

        # POST-EXECUTION - VERIFY IMPORT
        # Verify the source certificate thumbprint in the selected destination store
        if (-not (Test-CertificateInExactStore -Scope $Scope -Store $Store -Thumbprint $SourceCertificate.Thumbprint)) {
            throw "The certificate import completed, but the certificate could not be verified in $StorePath."
        }

        Write-Line "Imported certificate into $StorePath." -Type Success
        Write-Line ("Subject`t`t: {0}" -f $SourceCertificate.Subject)
        Write-Line ("Thumbprint`t: {0}" -f $SourceCertificate.Thumbprint)

        # POST-EXECUTION - LISTVIEW SEARCH
        # Refresh Certificate Management by thumbprint only after the import has been verified
        if ($null -ne $ListView) {
            Show-CertificateThumbprintInListView -ListView $ListView -Thumbprint $SourceCertificate.Thumbprint -SearchTextBox $SearchTextBox -RefreshCache
        }

        return $true
    }
    catch [System.ComponentModel.Win32Exception] {
        if ($_.Exception.NativeErrorCode -eq 1223) {
            Write-Line 'The certificate import was canceled at the administrator prompt.' -Type Warning
            return $false
        }
        Write-Line "The certificate could not be imported. ($($_.Exception.Message))" -Type Error
        return $false
    }
    catch {
        Write-Line "The certificate could not be imported. ($($_.Exception.Message))" -Type Error
        return $false
    }
    finally {
        if ($null -ne $SourceCertificate) {
            $SourceCertificate.Dispose()
        }
        $PfxPassword = $null
    }
}

### END OF FUNCTION
####################################################################################################