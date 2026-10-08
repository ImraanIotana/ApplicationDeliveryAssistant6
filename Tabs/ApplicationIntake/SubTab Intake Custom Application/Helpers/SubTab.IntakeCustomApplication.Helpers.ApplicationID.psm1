####################################################################################################
<#
.SYNOPSIS
    Warns when an Office executable and its document parameter use incompatible file types.
.DESCRIPTION
    Infers the Office product from the executable name and compares a file-based Application Parameter with that product's supported document extensions. The check is informational and does not block Application ID generation.
.OUTPUTS
    [System.Boolean] indicating whether the supplied values are compatible or do not require validation.
#>
####################################################################################################
function Test-CustomApplicationOfficeParameterCompatibility {
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param (
        [Parameter(Mandatory=$false)]
        [AllowNull()][AllowEmptyString()]
        [System.String]$ApplicationType,

        [Parameter(Mandatory=$false)]
        [AllowNull()][AllowEmptyString()]
        [System.String]$ApplicationExecutable,

        [Parameter(Mandatory=$false)]
        [AllowNull()][AllowEmptyString()]
        [System.String]$ApplicationParameter
    )

    # VALIDATION - APPLICABLE OFFICE INPUT
    if ($ApplicationType -ne 'Office Application' -or
        (Test-String -IsEmpty $ApplicationExecutable) -or
        (Test-String -IsEmpty $ApplicationParameter)) {
        return $true
    }

    # PREPARATION - SUPPORTED OFFICE FILE TYPES
    [System.Collections.Hashtable]$OfficeApplications = @{
        'MSACCESS.EXE' = @{ Name = 'Microsoft Access'; Extensions = @('.accdb','.accde','.accdr','.mdb','.mde') }
        'EXCEL.EXE'    = @{ Name = 'Microsoft Excel'; Extensions = @('.csv','.xls','.xlsb','.xlsm','.xlsx','.xlt','.xltm','.xltx') }
        'ONENOTE.EXE'  = @{ Name = 'Microsoft OneNote'; Extensions = @('.one','.onepkg','.onetoc2') }
        'OUTLOOK.EXE'  = @{ Name = 'Microsoft Outlook'; Extensions = @('.eml','.ics','.msg','.oft','.pst','.vcf') }
        'POWERPNT.EXE' = @{ Name = 'Microsoft PowerPoint'; Extensions = @('.pot','.potm','.potx','.pps','.ppsm','.ppsx','.ppt','.pptm','.pptx') }
        'WINPROJ.EXE'  = @{ Name = 'Microsoft Project'; Extensions = @('.mpp','.mpt') }
        'MSPUB.EXE'    = @{ Name = 'Microsoft Publisher'; Extensions = @('.pub') }
        'VISIO.EXE'    = @{ Name = 'Microsoft Visio'; Extensions = @('.vsd','.vsdm','.vsdx','.vss','.vssm','.vssx','.vst','.vstm','.vstx') }
        'WINWORD.EXE'  = @{ Name = 'Microsoft Word'; Extensions = @('.doc','.docm','.docx','.dot','.dotm','.dotx','.rtf') }
    }

    [System.String]$ExecutableName = [System.IO.Path]::GetFileName($ApplicationExecutable).ToUpperInvariant()
    if (-not $OfficeApplications.ContainsKey($ExecutableName)) { return $true }

    # VALIDATION - FILE PARAMETER
    [System.String]$NormalizedParameter = $ApplicationParameter.Trim().Trim('"')
    [System.Uri]$ParameterUri = $null
    if ([System.Uri]::TryCreate($NormalizedParameter,[System.UriKind]::Absolute,[ref]$ParameterUri) -and
        $ParameterUri.Scheme -in @('http','https')) {
        return $true
    }

    [System.String]$ParameterExtension = [System.IO.Path]::GetExtension($NormalizedParameter).ToLowerInvariant()
    if (Test-String -IsEmpty $ParameterExtension) { return $true }

    [System.Collections.Hashtable]$OfficeApplication = $OfficeApplications[$ExecutableName]
    if ($OfficeApplication.Extensions -contains $ParameterExtension) { return $true }

    # OUTPUT - NONBLOCKING COMPATIBILITY RESULT
    Write-Line "The Application Parameter uses file type '$ParameterExtension', which does not match the selected $($OfficeApplication.Name) executable. Please verify the application and document combination." -Type Warning
    return $false
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Generates an Application ID from Custom Application identity values.
.DESCRIPTION
    Removes whitespace from vendor, application name, and optional version values, validates the required values, and writes the resulting Vendor_Application or Vendor_Application_Version ID to the output TextBox.
.EXAMPLE
    New-CustomApplicationID -VendorPublisher 'Contoso' -ApplicationName 'Web Portal' -ApplicationVersion '1.0' -OutputTextBox $ApplicationIDTextBox
.INPUTS
    [System.String]
    [System.Windows.Forms.TextBox]
.OUTPUTS
    [System.String]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.3.4
    Author          : Imraan Iotana
    Creation Date   : August 2026
    Last Update     : August 2026
#>
####################################################################################################
function New-CustomApplicationID {
    [CmdletBinding()]
    [OutputType([System.String])]
    param (
        [Parameter(Mandatory=$false,HelpMessage='The custom application vendor or publisher.')]
        [AllowNull()][AllowEmptyString()]
        [System.String]$VendorPublisher,

        [Parameter(Mandatory=$false,HelpMessage='The custom application name.')]
        [AllowNull()][AllowEmptyString()]
        [System.String]$ApplicationName,

        [Parameter(Mandatory=$false,HelpMessage='The custom application version.')]
        [AllowNull()][AllowEmptyString()]
        [System.String]$ApplicationVersion,

        [Parameter(Mandatory=$false,HelpMessage='The TextBox to write the generated Application ID into.')]
        [System.Windows.Forms.TextBox]$OutputTextBox
    )

    try {
        # EXECUTION - BUILD SHARED APPLICATION ID
        [System.String]$ApplicationID = New-ApplicationIDValue -Vendor $VendorPublisher -ApplicationName $ApplicationName -ApplicationVersion $ApplicationVersion -AllowEmptyVersion
        if (Test-String -IsEmpty $ApplicationID) {
            if ($null -ne $OutputTextBox) { Clear-TextBox -TextBox $OutputTextBox -Force }
            return
        }

        # POST-EXECUTION - UPDATE CONTROL AND REPORT RESULT
        if ($null -ne $OutputTextBox) { $OutputTextBox.Text = $ApplicationID }
        Write-Line "Generated Custom Application ID: $ApplicationID" -Type Success
        return $ApplicationID
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}

### END OF FUNCTION
####################################################################################################