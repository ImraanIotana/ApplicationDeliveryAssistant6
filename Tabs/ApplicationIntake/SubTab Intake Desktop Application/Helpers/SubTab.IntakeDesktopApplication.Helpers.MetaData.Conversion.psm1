####################################################################################################
<#
.SYNOPSIS
    Converts and sanitizes metadata objects recursively for JSON export.
.OUTPUTS
    [System.Object]
#>
####################################################################################################
function Convert-MetaDataObject {
    [CmdletBinding()]
    [OutputType([System.Object])]
    param (
        [Parameter(Mandatory=$false)]
        [System.Object]$MetaDataObject
    )

    try {
        [System.String[]]$PropertiesToRemove = @('Content','TemplatePath','FullName','Directory')
        if ($null -eq $MetaDataObject) { return $null }
        if ($MetaDataObject -is [System.String]) {
            return (ConvertTo-PrivacySafePath -Path ([System.String]$MetaDataObject))
        }
        if ($MetaDataObject -is [System.ValueType]) { return $MetaDataObject }

        if ($MetaDataObject -is [System.Collections.IDictionary]) {
            [System.Collections.Specialized.OrderedDictionary]$ResultDictionary = [ordered]@{}
            foreach ($Key in @($MetaDataObject.Keys | Sort-Object)) {
                [System.String]$PropertyName = [System.String]$Key
                if ($PropertiesToRemove -notcontains $PropertyName) {
                    $ResultDictionary[$PropertyName] = Convert-MetaDataObject -MetaDataObject $MetaDataObject[$Key]
                }
            }
            return [PSCustomObject]$ResultDictionary
        }

        if ($MetaDataObject -is [System.Collections.IEnumerable] -and -not ($MetaDataObject -is [System.String])) {
            [System.Collections.Generic.List[System.Object]]$Items = @()
            foreach ($Item in $MetaDataObject) {
                $Items.Add((Convert-MetaDataObject -MetaDataObject $Item))
            }
            return $Items
        }

        if ($MetaDataObject.PSObject -and $MetaDataObject.PSObject.Properties.Count -gt 0) {
            [System.Collections.Specialized.OrderedDictionary]$ResultObject = [ordered]@{}
            foreach ($Property in $MetaDataObject.PSObject.Properties) {
                if (-not $Property.IsGettable) { continue }
                [System.String]$PropertyName = [System.String]$Property.Name
                if ($PropertiesToRemove -notcontains $PropertyName) {
                    $ResultObject[$PropertyName] = Convert-MetaDataObject -MetaDataObject $Property.Value
                }
            }
            return [PSCustomObject]$ResultObject
        }

        return $MetaDataObject
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
        return $MetaDataObject
    }
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Converts a path string to a privacy-safe metadata value.
.OUTPUTS
    [System.String]
#>
####################################################################################################
function ConvertTo-PrivacySafePath {
    [CmdletBinding()]
    [OutputType([System.String])]
    param (
        [Parameter(Mandatory=$false)]
        [System.String]$Path
    )

    if (Test-String -IsEmpty $Path) { return $Path }
    [System.Collections.Hashtable[]]$PathTokenMap = @(
        @{ Root = [System.String]$env:APPDATA;      Token = '[APPDATA]' }
        @{ Root = [System.String]$env:LOCALAPPDATA; Token = '[LOCALAPPDATA]' }
        @{ Root = [System.String]$env:USERPROFILE;  Token = '[USERPROFILE]' }
    )

    [System.String]$NormalizedPath = $Path -replace '/','\'
    foreach ($PathToken in $PathTokenMap) {
        [System.String]$Root = [System.String]$PathToken.Root
        if ((Test-String -IsPopulated $Root) -and $NormalizedPath.StartsWith($Root,[System.StringComparison]::OrdinalIgnoreCase)) {
            [System.String]$RelativePath = $NormalizedPath.Substring($Root.Length).TrimStart('\')
            if (Test-String -IsEmpty $RelativePath) { return [System.String]$PathToken.Token }
            return "$($PathToken.Token)\$RelativePath"
        }
    }

    if ($NormalizedPath -match '^(?<Drive>[A-Za-z]:)\\Users\\[^\\]+(?<Suffix>(\\.*)?)$') {
        [System.String]$Suffix = [System.String]$Matches.Suffix
        if (Test-String -IsEmpty $Suffix) { return '[USERPROFILE]' }
        return "[USERPROFILE]$Suffix"
    }
    return $Path
}

### END OF FUNCTION
####################################################################################################
