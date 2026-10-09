####################################################################################################
<#
.SYNOPSIS
    This application assists Application Delivery Engineers by automating common and repetitive administrative tasks.
.DESCRIPTION
    This application performs tasks like creating an Application Intake, creating AppLocker files, exporting Shortcut information, etc.
.EXAMPLE
    C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -Executionpolicy Bypass -WindowStyle Normal -File "StartAssistant.ps1"
.INPUTS
    This script has no input parameters.
.OUTPUTS
    This script returns no stream-output. All output is written to the host during runtime.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : See below at the Version property of the Global Application Object.
    Author          : Imraan Iotana
    Creation Date   : April 2026
    Last Update     : October 2026
#>
####################################################################################################
[CmdletBinding()]
param (
)

try {
    # Create the Global Application Object
    [PSCustomObject]$Global:ApplicationObject = @{
        # Application properties
        Name        = [System.String]'Application Delivery Assistant'
        Version     = [System.Version]'6.9.5'
        RootFolder  = [System.String]$PSScriptRoot
        LoadTimer   = [System.Diagnostics.Stopwatch]::StartNew()
    }
    # Unblock only the blocked files, skipping the .git folder
    Get-ChildItem -Path $PSScriptRoot -Force | Where-Object { $_.Name -ne '.git' } | Get-ChildItem -Recurse -File |
        Where-Object { Get-Item -LiteralPath $_.FullName -Stream 'Zone.Identifier' -ErrorAction SilentlyContinue } | Unblock-File -ErrorAction SilentlyContinue
    # Move the window to the top-left corner before the other modules load, so the window is in place straight away
    $FormModulePath = Join-Path -Path $PSScriptRoot -ChildPath 'Modules\Graphics\Graphics.Form.psm1'
    Import-Module -Name $FormModulePath -Force
    Move-WindowToTopLeft
    # Import the other modules
    Get-ChildItem -Path $PSScriptRoot -Filter *.psm1 -File -Recurse | Where-Object { $_.FullName -ne $FormModulePath } | ForEach-Object { Import-Module -Name $_.FullName -Force }
    # Start the application
    Start-Application
}
catch {
    Write-Error "The Application Delivery Assistant encountered an error: $_"
}

### END OF SCRIPT
####################################################################################################
