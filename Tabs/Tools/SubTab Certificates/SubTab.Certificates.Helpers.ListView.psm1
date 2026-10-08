####################################################################################################
<#
.SYNOPSIS
    Provides Certificate Management ListView helpers.
.DESCRIPTION
    Defines the certificate result schema and fills the Certificate Results ListView from the
    normalized certificate inventory.
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
    Returns the canonical Certificate Results ListView column schema.
.EXAMPLE
    Get-CertificateListViewColumnSchema
.OUTPUTS
    [PSCustomObject[]]
#>
####################################################################################################
function Get-CertificateListViewColumnSchema {
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param ()

    @(
        [PSCustomObject]@{ Label = '#';           PropertyName = '';                  SortType = 'Integer' }
        [PSCustomObject]@{ Label = 'Scope';       PropertyName = 'Scope';             SortType = 'Text' }
        [PSCustomObject]@{ Label = 'Issuer Name'; PropertyName = 'IssuerName';        SortType = 'Text' }
        [PSCustomObject]@{ Label = 'Subject Name'; PropertyName = 'SubjectName';       SortType = 'Text' }
        [PSCustomObject]@{ Label = 'Store';       PropertyName = 'Store';             SortType = 'Text' }
        [PSCustomObject]@{ Label = 'Subject';     PropertyName = 'Subject';           SortType = 'Text' }
        [PSCustomObject]@{ Label = 'Issuer';      PropertyName = 'Issuer';            SortType = 'Text' }
        [PSCustomObject]@{ Label = 'Expires';     PropertyName = 'ExpirationText';    SortType = 'Date' }
        [PSCustomObject]@{ Label = 'Status';      PropertyName = 'Status';            SortType = 'Text' }
        [PSCustomObject]@{ Label = 'Private Key'; PropertyName = 'HasPrivateKeyText'; SortType = 'Text' }
        [PSCustomObject]@{ Label = 'Thumbprint';  PropertyName = 'Thumbprint';        SortType = 'Text' }
    )
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Returns the certificate record attached to the selected result row.
.DESCRIPTION
    Centralizes ListView selection and row-tag validation for selected-certificate actions.
.EXAMPLE
    Get-SelectedCertificateRecord -ListView $CertificateResultsListView
.INPUTS
    [System.Windows.Forms.ListView]
.OUTPUTS
    [PSCustomObject]
#>
####################################################################################################
function Get-SelectedCertificateRecord {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The Certificate Results ListView containing the selected certificate.')]
        [System.Windows.Forms.ListView]$ListView
    )

    if (($null -eq $ListView.SelectedItems) -or ($ListView.SelectedItems.Count -lt 1)) {
        Write-Line 'No certificate is selected.' -Type Warning
        return $null
    }

    [PSCustomObject]$CertificateRecord = $ListView.SelectedItems[0].Tag
    if ($null -eq $CertificateRecord) {
        Write-Line 'The selected certificate row does not contain certificate details.' -Type Warning
        return $null
    }

    return $CertificateRecord
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Shows details for the certificate selected in the Certificate Results ListView.
.DESCRIPTION
    Uses the native .NET certificate UI to display the exact X509Certificate2 object attached to the
    selected row without store lookup, a console window, or administrator elevation.
.EXAMPLE
    Show-SelectedCertificateDetails -ListView $CertificateResultsListView
.INPUTS
    [System.Windows.Forms.ListView]
.OUTPUTS
    No objects are returned to the pipeline.
#>
####################################################################################################
function Show-SelectedCertificateDetails {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The Certificate Results ListView containing the selected certificate.')]
        [System.Windows.Forms.ListView]$ListView
    )

    try {
        [PSCustomObject]$CertificateRecord = Get-SelectedCertificateRecord -ListView $ListView
        if ($null -eq $CertificateRecord) {
            return
        }

        [System.Security.Cryptography.X509Certificates.X509Certificate2]$Certificate = $CertificateRecord.Certificate
        if ($null -eq $Certificate) {
            throw 'The selected certificate row does not contain an X.509 certificate object.'
        }

        Add-Type -AssemblyName System.Security
        [System.Windows.Forms.Form]$ParentForm = $ListView.FindForm()
        Write-Line "Showing details for the selected certificate from $($CertificateRecord.Scope)\$($CertificateRecord.Store)..." -Type Busy
        if ($null -ne $ParentForm) {
            [System.Security.Cryptography.X509Certificates.X509Certificate2UI]::DisplayCertificate($Certificate, $ParentForm.Handle)
        }
        else {
            [System.Security.Cryptography.X509Certificates.X509Certificate2UI]::DisplayCertificate($Certificate)
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
    Refreshes Certificate Results using search or a preset filter.
.DESCRIPTION
    Reuses cached certificate inventory unless RefreshCache is specified, applies an optional
    case-insensitive search term or preset filter, and replaces displayed rows in one paint cycle.
.EXAMPLE
    Invoke-CertificateSearchResultsRefresh -ListView $CertificateResultsListView -SearchTerm 'DigiCert'
.INPUTS
    [System.Windows.Forms.ListView]
    [System.Management.Automation.SwitchParameter]
.OUTPUTS
    No objects are returned to the pipeline.
#>
####################################################################################################
function Invoke-CertificateSearchResultsRefresh {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The Certificate Results ListView to refresh.')]
        [System.Windows.Forms.ListView]$ListView,

        [Parameter(Mandatory=$false,HelpMessage='Optional text matched against all displayed certificate fields.')]
        [AllowNull()][AllowEmptyString()]
        [System.String]$SearchTerm,

        [Parameter(Mandatory=$false,HelpMessage='Forces certificate inventory to be enumerated again before filtering.')]
        [System.Management.Automation.SwitchParameter]$RefreshCache,

        [Parameter(Mandatory=$false,HelpMessage='Optional fresh certificate inventory to cache and display without enumerating stores again.')]
        [AllowNull()]
        [PSCustomObject[]]$CertificateInventory,

        [Parameter(Mandatory=$false,HelpMessage='Optional predefined certificate filter.')]
        [ValidateSet('Valid','Expiring','Expired','PrivateKey','PersonalStore')]
        [System.String]$PresetFilter
    )

    try {
        # PREPARATION - CACHE
        if ($null -eq $ListView.Tag) {
            $ListView.Tag = [PSCustomObject]@{}
        }
        elseif (-not ($ListView.Tag -is [System.Management.Automation.PSCustomObject])) {
            $ListView.Tag = [PSCustomObject]@{ LegacyTagValue = $ListView.Tag }
        }

        [System.Boolean]$HasInventoryCache = ($null -ne $ListView.Tag.PSObject.Properties['CertificateInventory'])
        [System.Boolean]$InventoryWasSupplied = $PSBoundParameters.ContainsKey('CertificateInventory')
        [PSCustomObject[]]$PreviousCertificateInventory = @()
        if ($HasInventoryCache -and ($RefreshCache.IsPresent -or $InventoryWasSupplied)) {
            $PreviousCertificateInventory = @($ListView.Tag.CertificateInventory)
        }

        if ($InventoryWasSupplied) {
            $CertificateInventory = @($CertificateInventory)
            $ListView.Tag | Add-Member -MemberType NoteProperty -Name CertificateInventory -Value $CertificateInventory -Force
        }
        elseif ($RefreshCache.IsPresent -or (-not $HasInventoryCache)) {
            Write-Line 'Obtaining certificate inventory, one moment please...' -Type Busy
            $CertificateInventory = @(Get-CertificateInventory)
            $ListView.Tag | Add-Member -MemberType NoteProperty -Name CertificateInventory -Value $CertificateInventory -Force
        }
        else {
            [PSCustomObject[]]$CertificateInventory = @($ListView.Tag.CertificateInventory)
        }

        # PREPARATION - ACTIVE FILTER
        # Remember the current search or preset so certificate mutations can restore the same view
        $ListView.Tag | Add-Member -MemberType NoteProperty -Name ActiveCertificateSearchTerm -Value ([System.String]$SearchTerm) -Force
        $ListView.Tag | Add-Member -MemberType NoteProperty -Name ActiveCertificatePresetFilter -Value ([System.String]$PresetFilter) -Force

        [PSCustomObject[]]$DisplayedCertificates = switch ($PresetFilter) {
            'Valid'         { @($CertificateInventory | Where-Object { $_.Status -eq 'Valid' }) }
            'Expiring'      { @($CertificateInventory | Where-Object { $_.Status -eq 'Expiring' }) }
            'Expired'       { @($CertificateInventory | Where-Object { $_.Status -eq 'Expired' }) }
            'PrivateKey'    { @($CertificateInventory | Where-Object { $_.HasPrivateKey }) }
            'PersonalStore' { @($CertificateInventory | Where-Object { $_.Store -eq 'My' }) }
            default         { @(Find-CertificateInventory -CertificateInventory $CertificateInventory -SearchTerm $SearchTerm) }
        }
        $DisplayedCertificates = @($DisplayedCertificates | Sort-Object -Property Scope,IssuerName)
        [PSCustomObject]$ColorTheme = Get-ListViewColorTheme -ListView $ListView
        [PSCustomObject[]]$DisplayColumns = @((Get-CertificateListViewColumnSchema) | Select-Object -Skip 1)

        # EXECUTION - LISTVIEW
        Invoke-ListViewBatchUpdate -ListView $ListView -Action {
            $ListView.Items.Clear()
            [System.Int32]$Index = 1

            foreach ($Certificate in $DisplayedCertificates) {
                [System.Windows.Forms.ListViewItem]$ResultItem = New-Object System.Windows.Forms.ListViewItem([System.String]$Index)
                $ResultItem.Tag = $Certificate
                foreach ($Column in $DisplayColumns) {
                    $null = $ResultItem.SubItems.Add([System.String]$Certificate.($Column.PropertyName))
                }
                Set-ListViewItemReadOnlyStyle -ListViewItem $ResultItem -ColorTheme $ColorTheme
                $null = $ListView.Items.Add($ResultItem)
                $Index++
            }

            if (($null -ne $ListView.Tag.PSObject.Properties['CertificateSortColumn']) -and ([System.Int32]$ListView.Tag.CertificateSortColumn -ge 0)) {
                $ListView.Sort()
            }
            Set-ListViewColumnAutoSize -ListView $ListView -Mode Widest
        }

        # POST-EXECUTION - PREVIOUS CACHE
        # Dispose certificate objects that are no longer retained by the ListView cache
        foreach ($PreviousCertificateRecord in $PreviousCertificateInventory) {
            if (($null -ne $PreviousCertificateRecord) -and ($null -ne $PreviousCertificateRecord.Certificate)) {
                $PreviousCertificateRecord.Certificate.Dispose()
            }
        }

        [System.Int32]$CurrentUserCertificateCount = @($DisplayedCertificates | Where-Object { $_.Scope -eq 'CurrentUser' }).Count
        [System.Int32]$LocalMachineCertificateCount = @($DisplayedCertificates | Where-Object { $_.Scope -eq 'LocalMachine' }).Count
        [System.String]$NormalizedSearchTerm = [System.String]$SearchTerm
        if (-not [System.String]::IsNullOrWhiteSpace($PresetFilter)) {
            [System.String]$PresetDescription = switch ($PresetFilter) {
                'Valid'         { 'valid certificates' }
                'Expiring'      { 'certificates expiring within 30 days' }
                'Expired'       { 'expired certificates' }
                'PrivateKey'    { 'certificates with a private key' }
                'PersonalStore' { 'certificates in the Personal store' }
            }
            Write-Line "Showing $($DisplayedCertificates.Count) $PresetDescription (CurrentUser: $CurrentUserCertificateCount, LocalMachine: $LocalMachineCertificateCount)." -Type Success
        }
        elseif ([System.String]::IsNullOrWhiteSpace($NormalizedSearchTerm)) {
            Write-Line "Showing all $($DisplayedCertificates.Count) certificates (CurrentUser: $CurrentUserCertificateCount, LocalMachine: $LocalMachineCertificateCount)." -Type Success
        }
        else {
            Write-Line "Found $($DisplayedCertificates.Count) certificates matching '$($NormalizedSearchTerm.Trim())' (CurrentUser: $CurrentUserCertificateCount, LocalMachine: $LocalMachineCertificateCount)." -Type Success
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
    Shows Certificate Management results matching one thumbprint.
.DESCRIPTION
    Updates the optional search textbox and refreshes Certificate Results using either supplied
    inventory or a newly enumerated cache after a certificate mutation.
.EXAMPLE
    Show-CertificateThumbprintInListView -ListView $CertificateResultsListView -Thumbprint $Thumbprint -RefreshCache
.OUTPUTS
    No objects are returned to the pipeline.
#>
####################################################################################################
function Show-CertificateThumbprintInListView {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The Certificate Results ListView to search.')]
        [System.Windows.Forms.ListView]$ListView,

        [Parameter(Mandatory=$true,HelpMessage='The certificate thumbprint to display.')]
        [System.String]$Thumbprint,

        [Parameter(Mandatory=$false,HelpMessage='The Certificate Management search textbox to update.')]
        [AllowNull()]
        [System.Windows.Forms.TextBox]$SearchTextBox,

        [Parameter(Mandatory=$false,HelpMessage='Optional fresh certificate inventory to reuse.')]
        [AllowNull()]
        [PSCustomObject[]]$CertificateInventory,

        [Parameter(Mandatory=$false,HelpMessage='Forces certificate inventory to be enumerated again before filtering.')]
        [System.Management.Automation.SwitchParameter]$RefreshCache
    )

    # PREPARATION - SEARCH TERM
    # Normalize the thumbprint and synchronize the visible search textbox
    [System.String]$NormalizedThumbprint = $Thumbprint.Replace(' ', '').ToUpperInvariant()
    if ($null -ne $SearchTextBox) {
        $SearchTextBox.Text = $NormalizedThumbprint
    }

    # EXECUTION - LISTVIEW REFRESH
    # Prefer caller-supplied inventory and otherwise honor the requested cache refresh
    [System.Collections.Hashtable]$RefreshParameters = @{
        ListView   = $ListView
        SearchTerm = $NormalizedThumbprint
    }
    if ($PSBoundParameters.ContainsKey('CertificateInventory')) {
        $RefreshParameters.CertificateInventory = @($CertificateInventory)
    }
    elseif ($RefreshCache.IsPresent) {
        $RefreshParameters.RefreshCache = $true
    }
    Invoke-CertificateSearchResultsRefresh @RefreshParameters
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Refreshes the active Certificate Management view after a mutation.
.DESCRIPTION
    Forces a fresh inventory while restoring the preset filter or search term displayed before a
    certificate import or removal changed the certificate stores.
.EXAMPLE
    Update-CertificateResultsAfterMutation -ListView $CertificateResultsListView -SearchTextBox $SearchTextBox
.OUTPUTS
    No objects are returned to the pipeline.
#>
####################################################################################################
function Update-CertificateResultsAfterMutation {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The Certificate Results ListView to refresh after a mutation.')]
        [System.Windows.Forms.ListView]$ListView,

        [Parameter(Mandatory=$false,HelpMessage='The Certificate Management search textbox used as a fallback search term.')]
        [AllowNull()]
        [System.Windows.Forms.TextBox]$SearchTextBox
    )

    # PREPARATION - ACTIVE FILTER
    # Recover the preset or search term recorded by the most recent ListView refresh
    [System.String]$PresetFilter = [System.String]::Empty
    [System.String]$SearchTerm = if ($null -ne $SearchTextBox) { [System.String]$SearchTextBox.Text } else { [System.String]::Empty }
    if (($null -ne $ListView.Tag) -and ($ListView.Tag -is [System.Management.Automation.PSCustomObject])) {
        if ($null -ne $ListView.Tag.PSObject.Properties['ActiveCertificatePresetFilter']) {
            $PresetFilter = [System.String]$ListView.Tag.ActiveCertificatePresetFilter
        }
        if ($null -ne $ListView.Tag.PSObject.Properties['ActiveCertificateSearchTerm']) {
            $SearchTerm = [System.String]$ListView.Tag.ActiveCertificateSearchTerm
        }
    }

    # EXECUTION - LISTVIEW REFRESH
    # Force a fresh inventory and restore the active Certificate Management view
    if (-not [System.String]::IsNullOrWhiteSpace($PresetFilter)) {
        Invoke-CertificateSearchResultsRefresh -ListView $ListView -PresetFilter $PresetFilter -RefreshCache
    }
    else {
        Invoke-CertificateSearchResultsRefresh -ListView $ListView -SearchTerm $SearchTerm -RefreshCache
    }
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
function Show-AllCertificatesInListView {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The Certificate Results ListView to refresh.')]
        [System.Windows.Forms.ListView]$ListView
    )

    Invoke-CertificateSearchResultsRefresh -ListView $ListView -RefreshCache
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
function Show-CertificatePresetInListView {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The Certificate Results ListView to refresh.')]
        [System.Windows.Forms.ListView]$ListView,

        [Parameter(Mandatory=$true,HelpMessage='The predefined certificate filter to apply.')]
        [ValidateSet('Valid','Expiring','Expired','PrivateKey','PersonalStore')]
        [System.String]$PresetFilter
    )

    Invoke-CertificateSearchResultsRefresh -ListView $ListView -PresetFilter $PresetFilter
}

### END OF FUNCTION
####################################################################################################