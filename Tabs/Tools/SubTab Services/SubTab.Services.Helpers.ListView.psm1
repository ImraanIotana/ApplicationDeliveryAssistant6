####################################################################################################
<#
.SYNOPSIS
    Provides the Service Management ListView helpers.
.DESCRIPTION
    Handles the column schema, typed sorting and the refresh of the Service Results ListView.
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
    Returns the canonical Service Results ListView column schema.
.DESCRIPTION
    Keeps column labels, service property bindings, and typed sort behavior in one ordered schema.
.EXAMPLE
    Get-ServiceListViewColumnSchema
.OUTPUTS
    [PSCustomObject[]]
#>
####################################################################################################
function Get-ServiceListViewColumnSchema {
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param ()

    @(
        [PSCustomObject]@{ Label = '#';               PropertyName = '';                SortType = 'Integer' }
        [PSCustomObject]@{ Label = 'Display Name';    PropertyName = 'DisplayName';     SortType = 'Text' }
        [PSCustomObject]@{ Label = 'Service Name';    PropertyName = 'ServiceName';     SortType = 'Text' }
        [PSCustomObject]@{ Label = 'Status';          PropertyName = 'Status';          SortType = 'Text' }
        [PSCustomObject]@{ Label = 'Startup Type';    PropertyName = 'StartupType';     SortType = 'Text' }
        [PSCustomObject]@{ Label = 'Log On As';       PropertyName = 'LogOnAs';         SortType = 'Text' }
        [PSCustomObject]@{ Label = 'Install Date';    PropertyName = 'InstallDateText'; SortType = 'Date' }
        [PSCustomObject]@{ Label = 'Executable Path'; PropertyName = 'PathName';        SortType = 'Text' }
        [PSCustomObject]@{ Label = 'Description';     PropertyName = 'Description';     SortType = 'Text' }
    )
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Enables typed column sorting for the Service Results ListView.
.DESCRIPTION
    Attaches the shared ColumnClick handler that sorts text, integer, and date columns. Clicking
    the active column reverses its direction; clicking a different column starts ascending.
.EXAMPLE
    Enable-ServiceListViewSorting -ListView $ServiceResultsListView
.INPUTS
    [System.Windows.Forms.ListView]
.OUTPUTS
    No objects are returned to the pipeline.
#>
####################################################################################################
function Enable-ServiceListViewSorting {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The Service Results ListView that receives column sorting.')]
        [System.Windows.Forms.ListView]$ListView
    )

    Enable-ListViewColumnSorting -ListView $ListView -ColumnTypes @((Get-ServiceListViewColumnSchema).SortType) -MetadataPrefix 'Service'
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Refreshes the Service Results ListView using cached or newly enumerated service data.
.DESCRIPTION
    Loads and caches the service inventory when necessary, applies the search term and the status,
    startup type and origin filters, and fills the ListView in one paint cycle.
.EXAMPLE
    Invoke-ServiceSearchResultsRefresh -ListView $ServiceResultsListView -SearchTerm 'Intel' -Status 'Running'
.INPUTS
    [System.Windows.Forms.ListView]
    [System.String]
.OUTPUTS
    No objects are returned to the pipeline.
#>
####################################################################################################
function Invoke-ServiceSearchResultsRefresh {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The Service Results ListView to refresh.')]
        [System.Windows.Forms.ListView]$ListView,

        [Parameter(Mandatory=$false,HelpMessage='Optional text matched against the displayed service fields.')]
        [AllowNull()][AllowEmptyString()]
        [System.String]$SearchTerm,

        [Parameter(Mandatory=$false,HelpMessage='The status to show: All, Running, Stopped or Paused.')]
        [AllowNull()][AllowEmptyString()]
        [System.String]$Status = 'All',

        [Parameter(Mandatory=$false,HelpMessage='The startup type to show.')]
        [AllowNull()][AllowEmptyString()]
        [System.String]$StartupType = 'All',

        [Parameter(Mandatory=$false,HelpMessage='The origin to show: All services, Non-Microsoft only or Microsoft only.')]
        [AllowNull()][AllowEmptyString()]
        [System.String]$Origin = 'All services',

        [Parameter(Mandatory=$false,HelpMessage='Forces the service inventory to be enumerated again before filtering.')]
        [System.Management.Automation.SwitchParameter]$RefreshCache,

        [Parameter(Mandatory=$false,HelpMessage='Shows only the services whose executable was created during the last seven days.')]
        [System.Management.Automation.SwitchParameter]$Recent
    )

    try {
        # PREPARATION - CACHE
        # Preserve existing ListView metadata and add the service inventory when it is first requested
        if ($null -eq $ListView.Tag) {
            $ListView.Tag = [PSCustomObject]@{}
        }
        elseif (-not ($ListView.Tag -is [System.Management.Automation.PSCustomObject])) {
            $ListView.Tag = [PSCustomObject]@{ LegacyTagValue = $ListView.Tag }
        }

        [System.Boolean]$HasInventoryCache = ($null -ne $ListView.Tag.PSObject.Properties['ServiceInventory'])
        if ($RefreshCache.IsPresent -or (-not $HasInventoryCache)) {
            Write-Line 'Obtaining service inventory, one moment please...' -Type Busy
            [PSCustomObject[]]$ServiceInventory = @(Get-ServiceInventory)
            $ListView.Tag | Add-Member -MemberType NoteProperty -Name ServiceInventory -Value $ServiceInventory -Force
        }
        else {
            [PSCustomObject[]]$ServiceInventory = @($ListView.Tag.ServiceInventory)
        }

        [PSCustomObject[]]$FilteredServices = @(Find-ServiceInventory -ServiceInventory $ServiceInventory -SearchTerm $SearchTerm -Status $Status -StartupType $StartupType -Origin $Origin -Recent:$Recent -Days 7)
        [PSCustomObject]$ColorTheme = Get-ListViewColorTheme -ListView $ListView
        [PSCustomObject[]]$DisplayColumns = @((Get-ServiceListViewColumnSchema) | Select-Object -Skip 1)

        # EXECUTION - LISTVIEW
        # Replace the displayed rows in one paint cycle to avoid flicker
        Invoke-ListViewBatchUpdate -ListView $ListView -Action {
            $ListView.Items.Clear()
            [System.Int32]$Index = 1

            foreach ($Service in $FilteredServices) {
                [System.Windows.Forms.ListViewItem]$ResultItem = New-Object System.Windows.Forms.ListViewItem([System.String]$Index)
                $ResultItem.Tag = $Service
                foreach ($Column in $DisplayColumns) {
                    $null = $ResultItem.SubItems.Add([System.String]$Service.($Column.PropertyName))
                }
                Set-ListViewItemReadOnlyStyle -ListViewItem $ResultItem -ColorTheme $ColorTheme
                $null = $ListView.Items.Add($ResultItem)
                $Index++
            }

            # Reapply the selected column sort after the rows have been replaced
            if (($null -ne $ListView.Tag.PSObject.Properties['ServiceSortColumn']) -and ([System.Int32]$ListView.Tag.ServiceSortColumn -ge 0)) {
                $ListView.Sort()
            }
            Set-ListViewColumnAutoSize -ListView $ListView -Mode Widest
        }

        # POST-EXECUTION
        # Report the result
        [System.String]$NormalizedSearchTerm = ([System.String]$SearchTerm).Trim()
        [System.String]$FilterText = "(status: $Status, startup type: $StartupType, origin: $Origin)"
        if ($Recent.IsPresent) {
            Write-Line "Found $($FilteredServices.Count) services with an executable created during the last 7 days $FilterText."
        }
        elseif ([System.String]::IsNullOrWhiteSpace($NormalizedSearchTerm)) {
            Write-Line "Showing $($FilteredServices.Count) of $($ServiceInventory.Count) services $FilterText."
        }
        else {
            Write-Line "Found $($FilteredServices.Count) services matching '$NormalizedSearchTerm' $FilterText."
        }
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}

### END OF FUNCTION
####################################################################################################
