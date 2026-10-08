####################################################################################################
<#
.SYNOPSIS
    Builds a normalized Application ID from identity values.
.DESCRIPTION
    Removes whitespace, validates the required identity values, warns about duplicated components, and returns Vendor_Application_Version or Vendor_Application when an empty version is explicitly allowed.
.EXAMPLE
    New-ApplicationIDValue -Vendor 'Contoso Ltd' -ApplicationName 'Web Portal' -ApplicationVersion '1.0'
.OUTPUTS
    [System.String] when all required values are populated; otherwise null.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.3.4
    Author          : Imraan Iotana
    Creation Date   : August 2026
    Last Update     : August 2026
#>
####################################################################################################
function New-ApplicationIDValue {
    [CmdletBinding()]
    [OutputType([System.String])]
    param (
        [Parameter(Mandatory=$false)]
        [AllowNull()][AllowEmptyString()]
        [System.String]$Vendor,

        [Parameter(Mandatory=$false)]
        [AllowNull()][AllowEmptyString()]
        [System.String]$ApplicationName,

        [Parameter(Mandatory=$false)]
        [AllowNull()][AllowEmptyString()]
        [System.String]$ApplicationVersion,

        [Parameter(Mandatory=$false,HelpMessage='Allows an Application ID without a version component.')]
        [System.Management.Automation.SwitchParameter]$AllowEmptyVersion
    )

    # PREPARATION - NORMALIZED ID COMPONENTS
    [System.Collections.Specialized.OrderedDictionary]$NormalizedValues = [ordered]@{
        Vendor             = ($Vendor -replace '\s+', '')
        ApplicationName    = ($ApplicationName -replace '\s+', '')
        ApplicationVersion = ($ApplicationVersion -replace '\s+', '')
    }

    # VALIDATION - REQUIRED COMPONENTS
    foreach ($Entry in $NormalizedValues.GetEnumerator()) {
        if (($Entry.Key -eq 'ApplicationVersion') -and $AllowEmptyVersion.IsPresent) { continue }
        if (Test-String -IsEmpty ([System.String]$Entry.Value)) {
            Write-Line "$($Entry.Key) is empty. The Application ID cannot be generated." -Type Warning
            return
        }
    }

    [System.String]$NormalizedVendor = $NormalizedValues.Vendor
    [System.String]$NormalizedName = $NormalizedValues.ApplicationName
    [System.String]$NormalizedVersion = $NormalizedValues.ApplicationVersion

    # Keep duplicate components visible, but warn because silently changing identity values is riskier.
    if ((Test-String -IsPopulated $NormalizedVersion) -and $NormalizedName.Contains($NormalizedVersion)) {
        Write-Line 'The Application Name contains the Application Version. The version will be duplicated in the Application ID.' -Type Warning
    }
    if ($NormalizedName.Contains($NormalizedVendor)) {
        Write-Line 'The Application Name contains the Vendor. The vendor will be duplicated in the Application ID.' -Type Warning
    }

    # VALIDATION - SAFE FOLDER SEGMENT
    [System.String]$ApplicationID = if (Test-String -IsPopulated $NormalizedVersion) { "${NormalizedVendor}_${NormalizedName}_${NormalizedVersion}" } else { "${NormalizedVendor}_${NormalizedName}" }
    [System.Boolean]$ContainsInvalidCharacter = $ApplicationID.IndexOfAny([System.IO.Path]::GetInvalidFileNameChars()) -ge 0
    [System.Boolean]$ContainsPathSeparator = $ApplicationID.Contains([System.IO.Path]::DirectorySeparatorChar) -or $ApplicationID.Contains([System.IO.Path]::AltDirectorySeparatorChar)
    [System.Boolean]$IsUnsafePathSegment = [System.IO.Path]::IsPathRooted($ApplicationID) -or $ApplicationID -in @('.','..') -or $ApplicationID.EndsWith('.')
    if ($ContainsInvalidCharacter -or $ContainsPathSeparator -or $IsUnsafePathSegment) {
        Write-Line 'The Application ID contains characters that are unsafe for an application folder.' -Type Warning
        return
    }

    # OUTPUT - VERIFIED APPLICATION ID
    return $ApplicationID
}

### END OF FUNCTION
####################################################################################################