####################################################################################################
<#
.SYNOPSIS
    Provides read-only Windows certificate inventory helpers.
.DESCRIPTION
    Enumerates certificates from readable CurrentUser and LocalMachine stores and normalizes them
    for certificate management features.
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
    Returns the organization from a certificate distinguished name.
.OUTPUTS
    [System.String]
#>
####################################################################################################
function Get-CertificateOrganizationName {
    [CmdletBinding()]
    [OutputType([System.String])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The distinguished name containing the organization.')]
        [AllowEmptyString()]
        [System.String]$DistinguishedName
    )

    # EXECUTION - ORGANIZATION NAME
    # Extract the organization while supporting quoted and escaped distinguished-name values
    if ($DistinguishedName -match '(?:^|,\s*)O=(?:"(?<QuotedOrganization>(?:[^"]|"")*)"|(?<Organization>(?:\\.|[^,])*))') {
        # Normalize the extracted organization name
        [System.String]$OrganizationName = if (-not [System.String]::IsNullOrWhiteSpace([System.String]$Matches.QuotedOrganization)) {
            ([System.String]$Matches.QuotedOrganization).Replace('""','"')
        }
        else {
            ([System.String]$Matches.Organization).Replace('\,',',').Replace('\\','\')
        }
        if (-not [System.String]::IsNullOrWhiteSpace($OrganizationName)) {
            return $OrganizationName.Trim()
        }
    }

    # POST-EXECUTION
    # Return an empty string when no organization could be resolved
    return [System.String]::Empty
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Returns a concise certificate display name.
.DESCRIPTION
    Omits one or more trailing parenthetical qualifiers when a meaningful base name remains.
.OUTPUTS
    [System.String]
#>
####################################################################################################
function Get-ConciseCertificateDisplayName {
    [CmdletBinding()]
    [OutputType([System.String])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The certificate display name to make concise.')]
        [AllowEmptyString()]
        [System.String]$DisplayName
    )

    # EXECUTION - DISPLAY NAME
    # Remove trailing parenthetical qualifiers from the display name
    [System.String]$ConciseDisplayName = [System.Text.RegularExpressions.Regex]::Replace(
        $DisplayName,
        '(?:\s*\([^()]*\))+\s*$',
        [System.String]::Empty
    ).Trim()
    if (-not [System.String]::IsNullOrWhiteSpace($ConciseDisplayName)) {
        return $ConciseDisplayName
    }

    # POST-EXECUTION
    # Return the original trimmed display name when no concise value remains
    return $DisplayName.Trim()
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Returns a user-friendly issuer name for a certificate.
.DESCRIPTION
    Prefers the issuer organization from the distinguished name, then the certificate API's issuer
    simple name, and finally the complete issuer distinguished name. Trailing parenthetical
    qualifiers are omitted from the friendly display while the complete raw issuer remains available.
.EXAMPLE
    Get-CertificateIssuerDisplayName -Certificate $Certificate
.INPUTS
    [System.Security.Cryptography.X509Certificates.X509Certificate2]
.OUTPUTS
    [System.String]
#>
####################################################################################################
function Get-CertificateIssuerDisplayName {
    [CmdletBinding()]
    [OutputType([System.String])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The certificate whose issuer name will be resolved.')]
        [System.Security.Cryptography.X509Certificates.X509Certificate2]$Certificate
    )

    # PREPARATION - ISSUER PROPERTIES
    # Get the complete issuer name and its organization value
    [System.String]$IssuerDistinguishedName = [System.String]$Certificate.Issuer
    [System.String]$OrganizationName = Get-CertificateOrganizationName -DistinguishedName $IssuerDistinguishedName

    # EXECUTION - ISSUER ORGANIZATION
    # Return the issuer organization when it is available
    if (-not [System.String]::IsNullOrWhiteSpace($OrganizationName)) {
        return Get-ConciseCertificateDisplayName -DisplayName $OrganizationName
    }

    # EXECUTION - ISSUER SIMPLE NAME
    # Get and return the certificate API issuer name when it is available
    [System.String]$SimpleIssuerName = [System.String]$Certificate.GetNameInfo(
        [System.Security.Cryptography.X509Certificates.X509NameType]::SimpleName,
        $true
    )
    if (-not [System.String]::IsNullOrWhiteSpace($SimpleIssuerName)) {
        return Get-ConciseCertificateDisplayName -DisplayName $SimpleIssuerName
    }

    # POST-EXECUTION
    # Return the complete issuer name as the fallback
    return Get-ConciseCertificateDisplayName -DisplayName $IssuerDistinguishedName
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Returns a user-friendly subject name for a certificate.
.DESCRIPTION
    Prefers the certificate API's subject simple name, then the subject organization from the
    distinguished name, and finally the complete subject distinguished name. Trailing parenthetical
    qualifiers are omitted from the friendly display while the complete raw subject remains available.
.EXAMPLE
    Get-CertificateSubjectDisplayName -Certificate $Certificate
.INPUTS
    [System.Security.Cryptography.X509Certificates.X509Certificate2]
.OUTPUTS
    [System.String]
#>
####################################################################################################
function Get-CertificateSubjectDisplayName {
    [CmdletBinding()]
    [OutputType([System.String])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The certificate whose subject name will be resolved.')]
        [System.Security.Cryptography.X509Certificates.X509Certificate2]$Certificate
    )

    # PREPARATION - SUBJECT PROPERTIES
    # Get the simple and complete subject names
    [System.String]$SimpleSubjectName = [System.String]$Certificate.GetNameInfo(
        [System.Security.Cryptography.X509Certificates.X509NameType]::SimpleName,
        $false
    )
    [System.String]$SubjectDistinguishedName = [System.String]$Certificate.Subject
    [System.String]$SubjectDisplayName = $SimpleSubjectName

    # EXECUTION - SUBJECT ORGANIZATION
    # Use the subject organization when no simple name is available
    if ([System.String]::IsNullOrWhiteSpace($SubjectDisplayName)) {
        $SubjectDisplayName = Get-CertificateOrganizationName -DistinguishedName $SubjectDistinguishedName
    }

    # EXECUTION - COMPLETE SUBJECT
    # Use the complete subject name when no concise value is available
    if ([System.String]::IsNullOrWhiteSpace($SubjectDisplayName)) {
        $SubjectDisplayName = $SubjectDistinguishedName
    }

    # POST-EXECUTION
    # Return the concise subject display name
    return Get-ConciseCertificateDisplayName -DisplayName $SubjectDisplayName
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Filters a normalized certificate inventory using one optional search term.
.DESCRIPTION
    Searches every field displayed in Certificate Management. An empty search term returns all certificates.
.EXAMPLE
    Find-CertificateInventory -CertificateInventory $Certificates -SearchTerm 'DigiCert'
.INPUTS
    [PSCustomObject[]]
    [System.String]
.OUTPUTS
    [PSCustomObject[]]
#>
####################################################################################################
function Find-CertificateInventory {
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param (
        [Parameter(Mandatory=$false,HelpMessage='The normalized certificate inventory to filter.')]
        [AllowNull()]
        [PSCustomObject[]]$CertificateInventory,

        [Parameter(Mandatory=$false,HelpMessage='Optional text matched against all displayed certificate fields.')]
        [AllowNull()][AllowEmptyString()]
        [System.String]$SearchTerm
    )

    # PREPARATION - SEARCH TERM
    # Normalize the optional search term
    [System.String]$NormalizedSearchTerm = [System.String]$SearchTerm
    if ($null -ne $NormalizedSearchTerm) {
        $NormalizedSearchTerm = $NormalizedSearchTerm.Trim()
    }
    if ([System.String]::IsNullOrWhiteSpace($NormalizedSearchTerm)) {
        return @($CertificateInventory)
    }

    # PREPARATION - SEARCHABLE PROPERTIES
    # Derive searchable fields from the canonical Certificate Results column schema
    [System.String[]]$SearchPropertyNames = @(
        Get-CertificateListViewColumnSchema |
            Where-Object { -not [System.String]::IsNullOrWhiteSpace([System.String]$_.PropertyName) } |
            ForEach-Object { [System.String]$_.PropertyName }
    )

    # EXECUTION - FILTER INVENTORY
    # Match the search term against every displayed certificate property
    @(
        $CertificateInventory | Where-Object {
            [PSCustomObject]$CertificateInventoryItem = $_
            # Collect the searchable values for the current certificate
            [System.String[]]$SearchValues = @($SearchPropertyNames | ForEach-Object { [System.String]$CertificateInventoryItem.$_ })

            # Test each value until the search term is found
            [System.Boolean]$MatchesSearchTerm = $false
            foreach ($SearchValue in $SearchValues) {
                if ($SearchValue.IndexOf($NormalizedSearchTerm, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
                    $MatchesSearchTerm = $true
                    break
                }
            }
            $MatchesSearchTerm
        }
    )
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Returns certificates from readable Windows certificate stores.
.DESCRIPTION
    Enumerates CurrentUser and LocalMachine stores without modifying them. Each certificate is
    normalized with its store location, validity status, private-key state, and original object.
.EXAMPLE
    Get-CertificateInventory
.OUTPUTS
    [PSCustomObject[]]
#>
####################################################################################################
function Get-CertificateInventory {
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param ()

    try {
        # PREPARATION
        # Set the validity threshold, certificate scopes, and result collection
        [System.DateTime]$Now = Get-Date
        [System.DateTime]$ExpiringThreshold = $Now.AddDays(30)
        [System.String[]]$CertificateScopes = @('CurrentUser','LocalMachine')
        [System.Collections.Generic.List[PSCustomObject]]$CertificateInventory = New-Object 'System.Collections.Generic.List[PSCustomObject]'

        # EXECUTION - ENUMERATE STORES
        # Enumerate each readable certificate store in both supported scopes
        foreach ($Scope in $CertificateScopes) {
            [System.String]$ScopePath = "Cert:\$Scope"
            [System.Object[]]$CertificateStores = @(Get-ChildItem -Path $ScopePath -ErrorAction Stop)

            foreach ($CertificateStore in $CertificateStores) {
                # Resolve the current store name and provider path
                [System.String]$StoreName = [System.String]$CertificateStore.Name
                if ([System.String]::IsNullOrWhiteSpace($StoreName)) {
                    continue
                }

                [System.String]$StorePath = "$ScopePath\$StoreName"
                try {
                    # Read all certificates from the current store
                    [System.Security.Cryptography.X509Certificates.X509Certificate2[]]$Certificates = @(
                        Get-ChildItem -Path $StorePath -ErrorAction Stop |
                            Where-Object { $_ -is [System.Security.Cryptography.X509Certificates.X509Certificate2] }
                    )
                }
                catch {
                    Write-Line "Certificate store could not be read and was skipped. ($StorePath)" -Type Warning
                    continue
                }

                foreach ($Certificate in $Certificates) {
                    # Determine the certificate validity status
                    [System.String]$Status = if ($Certificate.NotAfter -lt $Now) {
                        'Expired'
                    }
                    elseif ($Certificate.NotBefore -gt $Now) {
                        'Not Yet Valid'
                    }
                    elseif ($Certificate.NotAfter -le $ExpiringThreshold) {
                        'Expiring'
                    }
                    else {
                        'Valid'
                    }

                    # Add the normalized certificate details to the inventory
                    $CertificateInventory.Add([PSCustomObject][ordered]@{
                        Scope             = $Scope
                        Store             = $StoreName
                        SubjectName       = Get-CertificateSubjectDisplayName -Certificate $Certificate
                        IssuerName        = Get-CertificateIssuerDisplayName -Certificate $Certificate
                        Subject           = [System.String]$Certificate.Subject
                        Issuer            = [System.String]$Certificate.Issuer
                        NotBefore         = [System.DateTime]$Certificate.NotBefore
                        NotAfter          = [System.DateTime]$Certificate.NotAfter
                        ExpirationText    = $Certificate.NotAfter.ToString('yyyy-MM-dd HH:mm', [System.Globalization.CultureInfo]::InvariantCulture)
                        Status            = $Status
                        HasPrivateKey     = [System.Boolean]$Certificate.HasPrivateKey
                        HasPrivateKeyText = $(if ($Certificate.HasPrivateKey) { 'Yes' } else { 'No' })
                        Thumbprint        = [System.String]$Certificate.Thumbprint
                        StorePath         = $StorePath
                        Certificate       = $Certificate
                    })
                }
            }
        }

        # POST-EXECUTION
        # Return the normalized inventory in a stable display order
        @($CertificateInventory | Sort-Object Scope, Store, Subject, Thumbprint)
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
        @()
    }
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Returns the installation state of a certificate across all readable Windows certificate stores.
.DESCRIPTION
    Matches a certificate thumbprint against CurrentUser and LocalMachine inventory and returns the
    matching certificate records together with their unique store locations.
.EXAMPLE
    Get-CertificateInstallationState -Certificate $Certificate
.INPUTS
    [System.Security.Cryptography.X509Certificates.X509Certificate2]
.OUTPUTS
    [PSCustomObject]
#>
####################################################################################################
function Get-CertificateInstallationState {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory=$true,ParameterSetName='Certificate',HelpMessage='The certificate whose installation state will be resolved.')]
        [System.Security.Cryptography.X509Certificates.X509Certificate2]$Certificate,

        [Parameter(Mandatory=$true,ParameterSetName='Thumbprint',HelpMessage='The certificate thumbprint whose installation state will be resolved.')]
        [System.String]$Thumbprint,

        [Parameter(Mandatory=$false,HelpMessage='Optional fresh inventory to reuse instead of enumerating certificate stores.')]
        [AllowNull()]
        [PSCustomObject[]]$CertificateInventory
    )

    # PREPARATION - CERTIFICATE IDENTITY
    # Normalize the certificate or explicit thumbprint used for inventory matching
    [System.String]$NormalizedThumbprint = if ($PSCmdlet.ParameterSetName -eq 'Certificate') {
        [System.String]$Certificate.Thumbprint
    }
    else {
        [System.String]$Thumbprint
    }
    $NormalizedThumbprint = $NormalizedThumbprint.Replace(' ', '').ToUpperInvariant()
    if ([System.String]::IsNullOrWhiteSpace($NormalizedThumbprint) -or ($NormalizedThumbprint -notmatch '^[0-9A-F]+$')) {
        throw 'The certificate does not contain a valid thumbprint.'
    }

    # PREPARATION - CERTIFICATE INVENTORY
    # Reuse caller-supplied inventory or enumerate every readable store once
    if (-not $PSBoundParameters.ContainsKey('CertificateInventory')) {
        $CertificateInventory = @(Get-CertificateInventory)
    }

    # EXECUTION - MATCH CERTIFICATE INVENTORY
    # Find matching thumbprints in every readable CurrentUser and LocalMachine store
    [PSCustomObject[]]$MatchingCertificates = @(
        $CertificateInventory |
            Where-Object { ([System.String]$_.Thumbprint).Replace(' ', '').ToUpperInvariant() -eq $NormalizedThumbprint }
    )
    [System.String[]]$InstalledLocations = @(
        $MatchingCertificates |
            ForEach-Object { $_.StorePath } |
            Sort-Object -Unique
    )

    # POST-EXECUTION
    # Return the structured installation state for status and import workflows
    [PSCustomObject][ordered]@{
        Installed            = ($InstalledLocations.Count -gt 0)
        MatchingStoreCount   = [System.Int32]$InstalledLocations.Count
        InstalledLocations   = @($InstalledLocations)
        MatchingCertificates = @($MatchingCertificates)
        CertificateInventory = @($CertificateInventory)
    }
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Checks whether a certificate file is installed in any readable Windows certificate store.
.DESCRIPTION
    Reads the certificate from disk and compares its thumbprint to certificates in every readable
    CurrentUser and LocalMachine store.
.EXAMPLE
    Test-CertificateInstalledInStore -CertificateFilePath 'C:\Certs\Example.cer'
.INPUTS
    [System.String]
.OUTPUTS
    [System.Boolean]
#>
####################################################################################################
function Test-CertificateInstalledInStore {
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The certificate file path to check.')]
        [AllowEmptyString()]
        [System.String]$CertificateFilePath,

        [Parameter(Mandatory=$false,HelpMessage='Optional password for PFX files.')]
        [AllowEmptyString()]
        [System.String]$Password = [System.String]::Empty,

        [Parameter(Mandatory=$false,HelpMessage='The window that owns the PFX password dialog.')]
        [AllowNull()]
        [System.Windows.Forms.IWin32Window]$Owner,

        [Parameter(Mandatory=$false,HelpMessage='The Certificate Management ListView to search after checking status.')]
        [AllowNull()]
        [System.Windows.Forms.ListView]$ListView,

        [Parameter(Mandatory=$false,HelpMessage='The Certificate Management search textbox to populate with the certificate thumbprint.')]
        [AllowNull()]
        [System.Windows.Forms.TextBox]$SearchTextBox
    )

    [System.Security.Cryptography.X509Certificates.X509Certificate2]$Certificate = $null
    try {
        # PREPARATION - CERTIFICATE FILE
        # Validate the selected certificate file path
        [System.String]$NormalizedCertificateFilePath = [System.String]$CertificateFilePath
        if ([System.String]::IsNullOrWhiteSpace($NormalizedCertificateFilePath)) {
            Write-Line 'No certificate file was selected.' -Type Warning
            return $false
        }

        if (-not (Test-Path -LiteralPath $NormalizedCertificateFilePath)) {
            Write-Line "Certificate file does not exist. ($NormalizedCertificateFilePath)" -Type Warning
            return $false
        }

        # EXECUTION - LOAD CERTIFICATE
        # Use the shared source reader for public certificates and password-protected packages
        [PSCustomObject]$CertificateSource = Read-CertificateFileSource -CertificateFilePath $NormalizedCertificateFilePath -Password $Password -Owner $Owner -PasswordDialogTitle 'Open PFX Certificate' -CancellationMessage 'The certificate status check was canceled.'
        if (-not $CertificateSource.Confirmed) {
            return $false
        }
        $Certificate = $CertificateSource.Certificate
        $CertificateSource.Password = $null

        # EXECUTION - CHECK ALL CERTIFICATE STORES
        # Resolve the shared installation state for the loaded certificate
        [PSCustomObject]$InstallationState = Get-CertificateInstallationState -Certificate $Certificate

        # POST-EXECUTION - HOST REPORT
        # Write the certificate and installation details to the host
        Write-Line ''
        Write-Line 'CERTIFICATE INSTALLATION STATUS' -Type Special
        Write-Line ("Certificate File`t: {0}" -f $NormalizedCertificateFilePath)
        Write-Line ("Subject`t`t`t: {0}" -f $Certificate.Subject)
        Write-Line ("Thumbprint`t`t: {0}" -f $Certificate.Thumbprint)
        Write-Line ("Installed`t`t: {0}" -f $(if ($InstallationState.Installed) { 'Yes' } else { 'No' }))
        Write-Line ("Matching Stores`t`t: {0}" -f $InstallationState.MatchingStoreCount)
        Write-Line ''

        # Write the final installation status
        if ($InstallationState.Installed) {
            Write-Line 'The certificate is installed in the following locations:' -Type Success
            foreach ($InstalledLocation in $InstallationState.InstalledLocations) {
                Write-Line ("  - {0}" -f $InstalledLocation) -Type Success
            }
        }
        else {
            Write-Line 'The certificate is not installed in any readable Windows certificate store.' -Type Warning
        }

        # POST-EXECUTION - LISTVIEW SEARCH
        # Search Certificate Management by thumbprint when its controls are available
        if ($null -ne $ListView) {
            Show-CertificateThumbprintInListView -ListView $ListView -Thumbprint $Certificate.Thumbprint -SearchTextBox $SearchTextBox -CertificateInventory $InstallationState.CertificateInventory
        }

        # Return the installation state
        return [System.Boolean]$InstallationState.Installed
    }
    catch {
        Write-Line "The certificate installation status could not be checked. ($($_.Exception.Message))" -Type Error
        return $false
    }
    finally {
        if ($null -ne $Certificate) {
            $Certificate.Dispose()
        }
    }
}

### END OF FUNCTION
####################################################################################################
