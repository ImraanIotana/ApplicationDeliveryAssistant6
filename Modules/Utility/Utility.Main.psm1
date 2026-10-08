####################################################################################################
<#
.SYNOPSIS
    Starts the Application Delivery Assistant.
.DESCRIPTION
    This function starts the Application Delivery Assistant by initializing the necessary components and displaying the main form.
.EXAMPLE
    Start-Application
.INPUTS
    None.
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.0
    Author          : Imraan Iotana
    Creation Date   : May 2026
    Last Update     : May 2026
#>
####################################################################################################
function Start-Application {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false,HelpMessage='The ApplicationObject containing the settings.')]
        [PSCustomObject]$InputObject = $Global:ApplicationObject
    )

    try {
        # Move the window to the top-left corner of the screen
        Move-WindowToTopLeft
        # Import and attach application settings to the ApplicationObject
        Import-ApplicationSettings -InputObject $InputObject
        # Initialize the User Settings
        Initialize-UserSettings -InputObject $InputObject
        # Initialize the graphics
        Initialize-Graphics -InputObject $InputObject
        # Show the Main Form
        Show-MainForm -InputObject $InputObject       
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}

# END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Returns type information for one or more input objects.
.DESCRIPTION
    This function accepts input via parameter or pipeline and returns structured type information.
.EXAMPLE
    Get-ObjectType -InputObject (Get-Item .)
.EXAMPLE
    Get-Process | Get-ObjectType
.INPUTS
    [System.Object]
.OUTPUTS
    [PSCustomObject]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.0
    Author          : Imraan Iotana
    Creation Date   : July 2026
    Last Update     : July 2026
#>
####################################################################################################
function Get-ObjectType {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,HelpMessage='The object to inspect.')]
        [AllowNull()]
        [System.Object]$InputObject,

        [Parameter(Mandatory=$false,HelpMessage='Return only the full type name as a string.')]
        [System.Management.Automation.SwitchParameter]$AsString
    )

    process {
        try {
            [System.Type]$Type = if ($null -eq $InputObject) { [System.Object] } else { $InputObject.GetType() }

            if ($AsString) {
                $Type.FullName
                return
            }

            [System.String]$BaseTypeName = $null
            if ($null -ne $Type.BaseType) {
                $BaseTypeName = $Type.BaseType.FullName
            }

            [PSCustomObject]@{
                InputValue        = $InputObject
                TypeName          = $Type.Name
                FullTypeName      = $Type.FullName
                BaseTypeName      = $BaseTypeName
                IsArray           = $Type.IsArray
                IsEnum            = $Type.IsEnum
                IsValueType       = $Type.IsValueType
                IsClass           = $Type.IsClass
            }
        }
        catch {
            Write-ErrorReport -ErrorRecord $_
        }
    }
}

# END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Imports an application settings data file and attaches it to the ApplicationObject.
.DESCRIPTION
    This function locates a PowerShell data file, imports it, and adds it to the provided
    ApplicationObject as a NoteProperty.
.EXAMPLE
    Import-ApplicationSettings -InputObject $ApplicationObject -SettingsFileName 'Settings.UserSettings.psd1' -OutputPropertyName 'UserSettings'
.INPUTS
    [PSCustomObject]
    [System.String]
    [System.String]
.OUTPUTS
    [System.Collections.Hashtable] The imported settings hashtable.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.0
    Author          : Imraan Iotana
    Creation Date   : May 2026
    Last Update     : May 2026
#>
####################################################################################################
function Import-ApplicationSettings {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The ApplicationObject containing the settings.')]
        [PSCustomObject]$InputObject,

        [Parameter(Mandatory=$false,HelpMessage='The name of the settings file to import.')]
        [System.String]$SettingsFileName = 'Settings.ApplicationSettings.psd1'
    )

    try {
        # PREPARATION
        # Get the full path to the settings file
        [System.String]$FolderToSearch = $InputObject.RootFolder
        [System.IO.FileInfo]$SettingsFileObject = Get-ChildItem -Path $FolderToSearch -File -Filter $SettingsFileName -Recurse

        # VALIDATION
        # Check if the settings file was found
        if ($SettingsFileObject.Count -ne 1) {
            throw "The settings file ($SettingsFileName) was not found in folder ($FolderToSearch) or its subfolders. (Found $($SettingsFileObject.Count) files.)"
        }

        # EXECUTION
        # Import the settings from the data file
        [System.Collections.Hashtable]$ApplicationSettings = Import-PowerShellDataFile -Path $SettingsFileObject.FullName
        # Add the settings hashtable to the main object
        $InputObject | Add-Member -NotePropertyName ApplicationSettings -NotePropertyValue $ApplicationSettings -Force
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}

# END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Restarts the Application Delivery Assistant.
.DESCRIPTION
    This function optionally asks the user for confirmation, starts a new assistant process,
    and then closes the current main form.
.EXAMPLE
    Restart-ApplicationDeliveryAssistant -InputObject $ApplicationObject
.INPUTS
    [PSCustomObject]
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.1
    Author          : Imraan Iotana
    Creation Date   : July 2026
    Last Update     : July 2026
#>
####################################################################################################
function Restart-ApplicationDeliveryAssistant {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false,HelpMessage='The ApplicationObject containing the settings.')]
        [PSCustomObject]$InputObject = $Global:ApplicationObject,

        [Parameter(Mandatory=$false,HelpMessage='Skip the restart confirmation dialog.')]
        [System.Management.Automation.SwitchParameter]$SkipConfirmation
    )

    try {
        # PREPARATION
        # Resolve the startup script path from the application root folder
        [System.String]$StartScriptPath = Join-Path -Path $InputObject.RootFolder -ChildPath 'StartAssistant.ps1'
        # Resolve the Windows PowerShell host path explicitly
        [System.String]$PowerShellHostPath = Join-Path -Path $env:WINDIR -ChildPath 'System32\WindowsPowerShell\v1.0\powershell.exe'

        # VALIDATION
        # Ensure the startup script exists before attempting relaunch
        if (-not (Test-Path -Path $StartScriptPath -PathType Leaf)) {
            Write-Line "The restart script could not be found: ($StartScriptPath)" -Type Warning
            return
        }
        if (-not (Test-Path -Path $PowerShellHostPath -PathType Leaf)) {
            Write-Line "The PowerShell host executable could not be found: ($PowerShellHostPath)" -Type Warning
            return
        }

        # VALIDATION
        # Confirm restart intent unless explicitly skipped
        if (-not $SkipConfirmation.IsPresent) {
            [System.String]$Title = 'Restart Application Delivery Assistant'
            [System.String]$Body = "Do you want to restart the application?"
            if (-not (Get-UserConfirmation -Title $Title -Body $Body)) {
                return
            }
        }

        # EXECUTION
        # Start a new assistant process with STA to ensure WinForms UI is shown
        [System.String[]]$ArgumentList = @(
            '-NoLogo',
            '-NoProfile',
            '-STA',
            '-ExecutionPolicy',
            'Bypass',
            '-WindowStyle',
            'Normal',
            '-File',
            $StartScriptPath
        )
        Start-Process -FilePath $PowerShellHostPath -WorkingDirectory $InputObject.RootFolder -ArgumentList $ArgumentList -ErrorAction Stop | Out-Null
        Write-Line 'A new Application Delivery Assistant instance has been started.' -Type Success

        # POST-EXECUTION
        # Close the current main form to complete the restart cycle
        if ($null -ne $Global:MainForm -and -not $Global:MainForm.IsDisposed) {
            $Global:MainForm.Close()
        }
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}

# END OF FUNCTION
####################################################################################################
