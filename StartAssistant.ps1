####################################################################################################
<#
.SYNOPSIS
    This application assists Application Delivery Engineers by automating common and repetitive administrative tasks.
.DESCRIPTION
    This application performs tasks like creating an Application Intake, creating AppLocker files, exporting Shortcut information, etc.
.EXAMPLE
    C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -Executionpolicy Bypass -WindowStyle Normal -File "StartAssistant.ps1"
.EXAMPLE
    C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -Executionpolicy Bypass -WindowStyle Normal -File "StartAssistant.ps1" -Verbose
.INPUTS
    This script has no input parameters.
.OUTPUTS
    This script returns no stream-output. All output is written to the host during runtime.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. All rights reserved.
    Version         : See below at the Version property of the Global Application Object.
    Author          : Imraan Iotana
    Creation Date   : May 2026
    Last Update     : May 2026
#>
####################################################################################################

[CmdletBinding()]
param (
)

begin {
    ####################################################################################################
    ### MAIN OBJECT ###
    # Create the Global Application Object
    [PSCustomObject]$Global:ApplicationObject = @{
        # Application
        Name            = [System.String]'Application Delivery Assistant'
        Version         = [System.Version]'6.0.0.0'
        # Folder Handlers
        RootFolder      = [System.String]$PSScriptRoot
        # End Handlers
        LeaveHostOpen   = $false
    }

    ####################################################################################################
    ### SUPPORTING FUNCTION ###

    # Start the application stopwatch
    $Global:AppStopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    # Import all the modules
    Get-ChildItem -Path $PSScriptRoot -Filter *.psm1 -File -Recurse | ForEach-Object { Import-Module -Name $_.FullName -Force }

<#
    function New-LogFolder { param([PSCustomObject]$Object = $Global:ApplicationObject)
        # Create the LogFolder
        if (-Not(Test-Path -Path $Object.LogFolder)) { New-Item -Path $Object.LogFolder -ItemType Directory -Force | Out-Null }
    }

    function Add-SettingsToMainObject { param([PSCustomObject]$Object = $Global:ApplicationObject)
        # Import the Settings
        Write-Line 'Importing settings...'
        [System.String]$SettingsFilePath = Join-Path -Path $Object.WorkFolders.Settings -ChildPath $Object.SettingsFileName
        [System.Collections.Hashtable]$Settings = Import-PowerShellDataFile -Path $SettingsFilePath
        # Import the Customer Settings
        [System.String]$CustomerSettingsFilePath = Join-Path -Path $Object.WorkFolders.Settings -ChildPath $Object.CustomerSettingsFileName
        [System.Collections.Hashtable]$CustomerSettings = Import-PowerShellDataFile -Path $CustomerSettingsFilePath
        # Add the CustomerSettingsHashtable to the SettingsHashtable
        $CustomerSettings.Keys | ForEach-Object { $Settings[$_] = $CustomerSettings[$_] }
        # Add the Settings hashtable to the main object
        $Object | Add-Member -NotePropertyName Settings -NotePropertyValue $Settings
    }

    function Add-GraphicalPrerequisites { param([PSCustomObject]$Object = $Global:ApplicationObject)
        # Load the assemblies
        Write-Line 'Loading graphical prerequisites...'
        $Object.Settings.Assemblies | ForEach-Object { Add-Type -AssemblyName $_ }
        # Add the fonts
        [System.Drawing.Font]$MainFont = New-Object System.Drawing.Font($Object.Settings.MainFont.Name,$Object.Settings.MainFont.Size,[System.Drawing.FontStyle]::Bold)
        Add-Member -InputObject $Object.Settings -NotePropertyName MainFont -NotePropertyValue $MainFont
    }
        
    function Import-PAModules {
        # Add the Module Directories to the Environment Variable
        #$ENV:PSModulePath += ";$PSScriptRoot"
        $ENV:PSModulePath += ";$($Global:ApplicationObject.WorkFolders.SharedModules);$($Global:ApplicationObject.WorkFolders.Modules);$($Global:ApplicationObject.WorkFolders.MainApplication)"
        # Import the PA Modules
        Import-Module -Name PASystemModule
        Import-Module -Name PAWriteModule
        Import-Module -Name PADSLManagementModule
        Import-Module -Name PAOmnissaDEMModule
        Import-Module -Name PAShortcutModule
    }

    function Write-WelcomeMessage {
        # Write the copyright and welcome message
        Write-Line 'Copyright (C) Iotana. All rights reserved.'
        Write-Host ('Welcome to the {0} version {1}!' -f $Global:ApplicationObject.Name,[System.String]$Global:ApplicationObject.Version)
    }
#>

    ####################################################################################################
}

process {
    try {
        # Initialize the graphics by loading the settings and the assemblies
        Initialize-Graphics
        # Create the main form
        Invoke-MainForm
        # Stop the global timer and report elapsed time
        Stop-GlobalTimer
        # Show the Main Form
        Invoke-MainForm -Show
    }
    catch {
        Write-Error "The Application Delivery Assistant encountered an error: $_"
    }

}

end {
    # If LeaveHostOpen is set to true, leave the host open
    if ($Global:ApplicationObject.LeaveHostOpen) { Read-Host -Prompt 'Press Enter to close this window...' }
}

### END OF SCRIPT
####################################################################################################
