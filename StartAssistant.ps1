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
    # Start the application stopwatch
    $Global:AppStopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    # Create the Global Application Object
    [PSCustomObject]$Global:ApplicationObject = @{
        # Application
        Name                        = [System.String]'Packaging Assistant'
        Version                     = [System.Version]'5.7.2.100'
        # Folder Handlers
        RootFolder                  = [System.String]$PSScriptRoot
        LogFolder                   = [System.String](Join-Path -Path $ENV:TEMP -ChildPath 'PALogs')
        DefaultOutputFolder         = [System.String](Join-Path -Path $ENV:USERPROFILE -ChildPath 'Downloads')
        DefaultInstallationParent   = [System.String]$ENV:LOCALAPPDATA
        UserDesktopFolder           = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::Desktop)
        UserStartMenuFolder         = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::StartMenu)
        WindowsFolder               = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::Windows)
        # Work Folder Leaf Names
        WorkFolderLeafNames         = [System.Collections.Hashtable]@{
            MainApplication         = 'MainApplication'
            SharedFunctions         = 'MainApplication\Shared Functions'
            SharedModules           = 'MainApplication\Shared Modules'
            SharedAssets            = 'MainApplication\Shared Assets'
            Settings                = 'MainApplication\Settings'
            Modules                 = 'Modules'
        }
        # File Handlers
        MainScriptFileName          = [System.String]'PackagingAssistant.ps1'
        SettingsFileName            = [System.String]'ApplicationSettings.psd1'
        CustomerSettingsFileName    = [System.String]'CustomerSettings.psd1'
        IconFileName                = [System.String]'KPN.ico'
        VersionHistoryFileName      = [System.String]'README.md'
        # Message Handlers
        Messages                    = [System.Collections.Hashtable]@{
            CopyrightNotice         = 'Copyright (C) Iotana. All rights reserved.'
            LoadingMessageFix       = 'Loading the {0} version {1}...'
            WelcomeMessageFix       = 'Welcome to the {0} version {1}.'
            HostPromptText          = 'Press Enter to close this window...'
        }
        # End Handlers
        LeaveHostOpen               = $false
    }
    # Add the calculated properties to the main object
    $Global:ApplicationObject | Add-Member -MemberType ScriptProperty -Name VersionHistoryFilePath -Value { Join-Path -Path $this.RootFolder -ChildPath $this.VersionHistoryFileName }
    $Global:ApplicationObject | Add-Member -MemberType ScriptProperty -Name DefaultInstallationFolder -Value { Join-Path -Path $this.DefaultInstallationParent -ChildPath $this.Name }
    $Global:ApplicationObject | Add-Member -MemberType ScriptProperty -Name PowerShellExecutablePath -Value { Join-Path -Path $this.WindowsFolder -ChildPath 'System32\WindowsPowerShell\v1.0\powershell.exe' }

    ####################################################################################################
    ### SUPPORTING FUNCTION ###

    function Add-WorkFoldersToMainObject { param([PSCustomObject]$Object = $Global:ApplicationObject)
        # Create a new empty WorkFolders hashtable
        Write-Host 'Setting workfolders...' -ForegroundColor DarkGray
        [System.Collections.Hashtable]$WorkFolders = @{}
        # Add the full paths to the new WorkFolders hashtable
        $Object.WorkFolderLeafNames.GetEnumerator() | ForEach-Object {
            [System.String]$FolderId    = $_.Name
            [System.String]$FullPath    = Join-Path -Path $Object.RootFolder -ChildPath $_.Value
            $WorkFolders[$FolderId] = $FullPath
        }
        # Add the new WorkFolders hashtable to the main object
        $Object | Add-Member -NotePropertyName WorkFolders -NotePropertyValue $WorkFolders
    }

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
        Write-Line $Global:ApplicationObject.Messages.CopyrightNotice
        Write-Host ($Global:ApplicationObject.Messages.WelcomeMessageFix -f $Global:ApplicationObject.Name,[System.String]$Global:ApplicationObject.Version)
    }

    ####################################################################################################
}

process {
    <# Start the Initialization
    Write-Host ($Global:ApplicationObject.Messages.LoadingMessageFix -f $Global:ApplicationObject.Name,[System.String]$Global:ApplicationObject.Version) -ForegroundColor DarkGray
    Add-WorkFoldersToMainObject

    # LOADING AND UNBLOCKING FILES
    # Set the full paths to search
    [System.String[]]$FullPathsToSearch = @('SharedFunctions','SharedModules','Modules') | ForEach-Object { $Global:ApplicationObject.WorkFolders[$_] }
    # Get all PS1 and PSM1 file objects
    [System.IO.FileSystemInfo[]]$AllFilesToUnblock = $FullPathsToSearch | ForEach-Object { Get-ChildItem -Path $_ -Recurse -File -Include *.ps1,*.psm1 -ErrorAction SilentlyContinue }
    # Unblock all files and dotsource the PS1 files
    Write-Host 'Loading functions...' -ForegroundColor DarkGray
    $AllFilesToUnblock | ForEach-Object {
        # Unblock the file
        Unblock-File -Path $_.FullName
        # If the file is a ps1, then also dotsource it
        if ($_.Extension -eq '.ps1') { . $_.FullName }
    }


    # CONTINUE THE INITIALIZATION
    # After dotsourcing, all functions have become available.
    New-LogFolder
    Import-PAModules
    Add-SettingsToMainObject
    Add-GraphicalPrerequisites
    Invoke-UserSettings -Initialize
    
    # Build the Form
    try {
        # Build the Global Main Form (Name: $Global:MainForm)
        Invoke-MainForm
        # Add the dimensions of the graphical child objects to the Settings
        Add-GraphicalDimensionsToSettings
        Add-IconsToSettings
        # Build the Global Main Tabcontrol (Name: $Global:MainTabControl)
        Invoke-MainTabControl -ParentForm $Global:MainForm
        # Build the Global Main Form (Name: $Global:MainForm)
        #Invoke-MainForm

        # Check if the machine is an SCCM server
        [System.ComponentModel.Component[]]$SCCMServices = Get-Service | Where-Object { $_.Name.StartsWith('SMS') } -ErrorAction SilentlyContinue
        [System.Boolean]$IsSCCMServer = if ($SCCMServices) { $true } else { $false }
        Add-Member -InputObject $Global:ApplicationObject -NotePropertyName IsSCCMServer -NotePropertyValue $IsSCCMServer

        # Load the SCCM/MECM module only on an SCCM server
        if ($IsSCCMServer) {        
            Import-Module -Name PASCCMModule
            Import-ModuleSCCMApplication
        }
        # Import these modules, for all machines
        Import-ModuleLauncher
        # Hide these modules on an SCCM server
        if (-Not($IsSCCMServer)) {
            Import-ModuleApplicationIntake
        }
        # Import these modules, for all machines
        Import-ModuleApplicationManagement
        # Hide these modules on an SCCM server
        if (-Not($IsSCCMServer)) {
            Import-ModuleAppLocker
            Import-ModuleOmnissaDEMManagement
        }
        # Import these modules, for all machines
        Import-ModuleIntakeExtras
        Import-ModuleSettings

        # Stop the stopwatch and write the elapsed time
        $Global:AppStopwatch.Stop()
        #$Seconds = $Global:AppStopwatch.Elapsed.TotalSeconds
        $RoundedSeconds = ($Global:AppStopwatch.Elapsed.TotalSeconds).ToString("F2")
        Write-Line "Loading time: $RoundedSeconds seconds"

        Write-Host "Aantal tabbladen: $($Global:MainTabControl.TabPages.Count)"
        $Global:MainTabControl.TabPages | Select-Object Text | Out-Host
        # Write the welcome message
        Write-WelcomeMessage
        # Show the Main Form
        Show-MainForm
    }
    catch {
        Write-FullError
    }#>
}

end {
    # Stop the stopwatch and write the elapsed time
    $Global:AppStopwatch.Stop()
    #$Seconds = $Global:AppStopwatch.Elapsed.TotalSeconds
    $RoundedSeconds = ($Global:AppStopwatch.Elapsed.TotalSeconds).ToString("F2")
        Write-Host "Loading time: $RoundedSeconds seconds"

    # If LeaveHostOpen is set to true, leave the host open
    if ($Global:ApplicationObject.LeaveHostOpen) { Read-Host -Prompt $Global:ApplicationObject.Messages.HostPromptText }
}

### END OF SCRIPT
####################################################################################################
