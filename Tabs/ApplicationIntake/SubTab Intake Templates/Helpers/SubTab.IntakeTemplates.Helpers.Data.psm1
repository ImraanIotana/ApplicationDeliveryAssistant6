####################################################################################################
<#
.SYNOPSIS
    Imports and discovers customer template data.
.DESCRIPTION
    Provides the shared data functions used by customer template management and Intake consumers.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.9.0
    Author          : Imraan Iotana
    Creation Date   : August 2026
    Last Update     : October 2026
#>
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Gets the roaming customer template storage paths.
.DESCRIPTION
    Resolves the customer template and Universal Deployment Framework folders below the current
    user's roaming Application Data folder and optionally creates them.
.EXAMPLE
    Get-CustomerTemplateStoragePaths -Create
.OUTPUTS
    [PSCustomObject]
#>
####################################################################################################
function Get-CustomerTemplateStoragePaths {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory=$false,HelpMessage='Create the roaming storage folders when they do not exist.')]
        [System.Management.Automation.SwitchParameter]$Create
    )

    [System.String]$RoamingApplicationData = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::ApplicationData)
    if ([System.String]::IsNullOrWhiteSpace($RoamingApplicationData)) {
        throw 'The roaming Application Data folder could not be resolved.'
    }

    [System.String]$ApplicationDataRoot = Join-Path -Path $RoamingApplicationData -ChildPath 'Application Delivery Assistant'
    [System.String]$CustomerTemplatesRoot = Join-Path -Path $ApplicationDataRoot -ChildPath 'Customer Templates'
    [System.String]$UniversalDeploymentFrameworkRoot = Join-Path -Path $ApplicationDataRoot -ChildPath 'Universal Deployment Framework'

    if ($Create) {
        foreach ($FolderPath in @($CustomerTemplatesRoot,$UniversalDeploymentFrameworkRoot)) {
            if (-not (Test-Path -LiteralPath $FolderPath -PathType Container)) {
                New-Item -Path $FolderPath -ItemType Directory -Force -ErrorAction Stop | Out-Null
            }
        }
    }

    [PSCustomObject]@{
        ApplicationDataRoot              = $ApplicationDataRoot
        CustomerTemplatesRoot            = $CustomerTemplatesRoot
        UniversalDeploymentFrameworkRoot = $UniversalDeploymentFrameworkRoot
    }
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Imports normalized customer template data.
.DESCRIPTION
    Imports a pre-6.2 flat roaming customer template directly for upgrade compatibility, or
    validates and combines a Schema 2 component manifest into the normalized hashtable shape
    expected by Intake consumers.
.EXAMPLE
    Import-CustomerTemplateData -SettingsFilePath 'C:\Templates\Settings.Customer.Example.psd1'
.INPUTS
    [System.String]
.OUTPUTS
    [System.Collections.Hashtable]
#>
####################################################################################################
function Import-CustomerTemplateData {
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='Path to the customer template settings or manifest file.')]
        [System.String]$SettingsFilePath
    )

    [System.String]$ResolvedSettingsPath = [System.IO.Path]::GetFullPath($SettingsFilePath)
    [System.Collections.Hashtable]$TemplateData = Import-PowerShellDataFile -LiteralPath $ResolvedSettingsPath

    if (-not $TemplateData.ContainsKey('Components')) {
        return $TemplateData
    }
    if ((-not $TemplateData.ContainsKey('SchemaVersion')) -or ([System.Int32]$TemplateData.SchemaVersion -ne 2)) {
        throw "Component-based customer templates must declare SchemaVersion 2. ($ResolvedSettingsPath)"
    }
    [System.Guid]$TemplateId = [System.Guid]::Empty
    if ((-not $TemplateData.ContainsKey('TemplateId')) -or (-not [System.Guid]::TryParse([System.String]$TemplateData.TemplateId,[ref]$TemplateId))) {
        throw "Component-based customer templates must define a valid TemplateId. ($ResolvedSettingsPath)"
    }
    if ($TemplateData.Components -isnot [System.Collections.IDictionary]) {
        throw "The Components value must be a dictionary. ($ResolvedSettingsPath)"
    }

    [System.String]$TemplateDirectory = [System.IO.Path]::GetDirectoryName($ResolvedSettingsPath)
    [System.String]$TemplateDirectoryPrefix = $TemplateDirectory.TrimEnd([System.IO.Path]::DirectorySeparatorChar) + [System.IO.Path]::DirectorySeparatorChar
    [System.Collections.Hashtable]$ComponentMap = @{
        ApplicationFolderSubFolders = 'ApplicationFolderSubFolders'
        AppLockerDefaultSettings    = 'AppLockerDefaultSettings'
        MailTemplates               = 'MailTemplates'
    }

    foreach ($ComponentName in $ComponentMap.Keys) {
        if (-not $TemplateData.Components.Contains($ComponentName)) {
            throw "The Schema 2 manifest does not define the $ComponentName component. ($ResolvedSettingsPath)"
        }

        [System.String]$ComponentRelativePath = [System.String]$TemplateData.Components[$ComponentName]
        if ([System.String]::IsNullOrWhiteSpace($ComponentRelativePath)) {
            throw "The component path is empty: $ComponentName. ($ResolvedSettingsPath)"
        }

        [System.String]$ComponentPath = [System.IO.Path]::GetFullPath((Join-Path -Path $TemplateDirectory -ChildPath $ComponentRelativePath))
        if (-not $ComponentPath.StartsWith($TemplateDirectoryPrefix,[System.StringComparison]::OrdinalIgnoreCase)) {
            throw "The component path must remain inside the customer template folder: $ComponentRelativePath"
        }
        if (-not (Test-Path -LiteralPath $ComponentPath -PathType Leaf)) {
            throw "The customer template component does not exist: $ComponentPath"
        }

        $TemplateData[$ComponentMap[$ComponentName]] = Import-PowerShellDataFile -LiteralPath $ComponentPath
    }

    return $TemplateData
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Gets customer templates from the Customer folder.
.DESCRIPTION
    Retrieves customer template manifests from the supplied folder, imports their normalized
    content, and returns the objects consumed by template selectors and management features.
.EXAMPLE
    Get-CustomerTemplates
.INPUTS
    [System.String]
.OUTPUTS
    [PSCustomObject]
.NOTES
    Version         : 6.9.0
#>
####################################################################################################
function Get-CustomerTemplates {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false,HelpMessage='Folder searched recursively for customer template manifests.')]
        [System.String[]]$FolderToSearch
    )

    # PREPARATION
    if (-not $PSBoundParameters.ContainsKey('FolderToSearch')) {
        [PSCustomObject]$StoragePaths = Get-CustomerTemplateStoragePaths -Create
        # Built-in bundles are optional, so absent folders are skipped silently
        [System.String[]]$BuiltInFolders = @('Customer\ADA Default') |
            ForEach-Object { Join-Path -Path $Global:ApplicationObject.RootFolder -ChildPath $_ } |
            Where-Object { Test-Path -LiteralPath $_ -PathType Container }
        $FolderToSearch = @($BuiltInFolders) + @($StoragePaths.CustomerTemplatesRoot)
    }

    # EXECUTION
    [System.Collections.Generic.List[System.IO.FileInfo]]$TemplateFiles = New-Object 'System.Collections.Generic.List[System.IO.FileInfo]'
    foreach ($SearchFolder in $FolderToSearch) {
        if (-not (Test-Path -LiteralPath $SearchFolder -PathType Container)) {
            Write-Warning "The specified folder '$SearchFolder' does not exist."
            continue
        }

        Get-ChildItem -LiteralPath $SearchFolder -Filter '*.psd1' -File -Recurse |
            Where-Object { $_.BaseName.StartsWith('Settings.Customer.') } |
            ForEach-Object { [void]$TemplateFiles.Add($_) }
    }

    if ($TemplateFiles.Count -eq 0) {
        return @()
    }

    foreach ($TemplateFile in ($TemplateFiles | Sort-Object -Property Name, FullName)) {
        [System.Collections.Hashtable]$TemplateContent = Import-CustomerTemplateData -SettingsFilePath $TemplateFile.FullName
        [System.String]$TemplateName = $TemplateFile.BaseName -replace '^Settings\.Customer\.', ''
        [System.String]$BuiltInRoot = [System.IO.Path]::GetFullPath((Join-Path -Path $Global:ApplicationObject.RootFolder -ChildPath 'Customer')).TrimEnd([System.IO.Path]::DirectorySeparatorChar) + [System.IO.Path]::DirectorySeparatorChar
        [System.String]$TemplateDirectory = [System.IO.Path]::GetFullPath($TemplateFile.DirectoryName).TrimEnd([System.IO.Path]::DirectorySeparatorChar) + [System.IO.Path]::DirectorySeparatorChar
        [System.String]$Source = if ($TemplateDirectory.StartsWith($BuiltInRoot,[System.StringComparison]::OrdinalIgnoreCase)) { 'Built-in' } else { 'User' }

        [PSCustomObject]@{
            ComboBoxName                = $TemplateContent.Identity
            TemplatePath                = $TemplateFile.FullName
            TemplateName                = $TemplateName
            FileName                    = $TemplateFile.Name
            FullName                    = $TemplateFile.FullName
            Directory                   = $TemplateFile.DirectoryName
            Content                     = $TemplateContent
            Identity                    = $TemplateContent.Identity
            ApplicationFolderSubFolders = $TemplateContent.ApplicationFolderSubFolders
            Source                      = $Source
            IsReadOnly                  = ($Source -eq 'Built-in')
        }
    }
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Resolves the active customer template, falling back to ADA Default, then the first template.
.NOTES
    Version         : 6.9.0
#>
function Get-ActiveCustomerTemplate {
    [CmdletBinding()]
    param ()

    [System.Object[]]$CustomerTemplates = @(Get-CustomerTemplates)
    [System.String]$ActiveTemplatePath = [System.String](Get-UserSetting -PropertyName 'ApplicationIntake.ActiveCustomerTemplatePath')

    if (Test-String -IsPopulated $ActiveTemplatePath) {
        [System.Object]$ActiveTemplate = $CustomerTemplates |
            Where-Object { ([System.String]$_.TemplatePath).Equals($ActiveTemplatePath,[System.StringComparison]::OrdinalIgnoreCase) } |
            Select-Object -First 1
        if ($null -ne $ActiveTemplate) {
            return $ActiveTemplate
        }
    }

    [System.Object]$FallbackTemplate = $CustomerTemplates |
        Where-Object { ([System.String]$_.ComboBoxName).Equals('ADA - Default',[System.StringComparison]::OrdinalIgnoreCase) } |
        Select-Object -First 1
    if ($null -ne $FallbackTemplate) {
        return $FallbackTemplate
    }

    return $CustomerTemplates | Select-Object -First 1
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
function Set-ActiveCustomerTemplate {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The customer template to make active.')]
        [System.Object]$CustomerTemplate
    )

    if ($null -eq $CustomerTemplate.PSObject.Properties['TemplatePath'] -or (Test-String -IsEmpty ([System.String]$CustomerTemplate.TemplatePath))) {
        Write-Line 'The selected customer template does not contain a manifest path.' -Type Warning
        return
    }

    Set-UserSetting -PropertyName 'ApplicationIntake.ActiveCustomerTemplatePath' -PropertyValue ([System.String]$CustomerTemplate.TemplatePath)
    return $CustomerTemplate
}

### END OF FUNCTION
####################################################################################################