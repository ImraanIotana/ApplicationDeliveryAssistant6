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
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. All rights reserved.
    Version         : See below at the Version property of the Global Application Object.
    Author          : Imraan Iotana
    Creation Date   : April 2026
    Last Update     : June 2026
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
        Version     = [System.Version]'6.0.0.0'
        RootFolder  = [System.String]$PSScriptRoot
        LoadTimer   = [System.Diagnostics.Stopwatch]::StartNew()
    }
    # Import the modules
    Get-ChildItem -Path $PSScriptRoot -Filter *.psm1 -File -Recurse | ForEach-Object { Import-Module -Name $_.FullName -Force }
    # Start the application
    Start-Application
}
catch {
    Write-Error "The Application Delivery Assistant encountered an error: $_"
}

### END OF SCRIPT
####################################################################################################
