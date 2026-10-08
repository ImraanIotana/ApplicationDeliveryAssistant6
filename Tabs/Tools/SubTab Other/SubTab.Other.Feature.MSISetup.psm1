####################################################################################################
<#
.SYNOPSIS
    Imports the MSI Setup feature into the Other sub-tab.
.DESCRIPTION
    This function imports the MSI Setup feature into the Other sub-tab by creating a new GroupBox and adding it to the specified parent TabPage.
    It provides an MSI file selection field and a button for creating install and uninstall CMD files beside the selected MSI.
.EXAMPLE
    Import-FeatureMSISetup -InputObject $MyApplicationObject -ParentTabPage $MyTabPage
.INPUTS
    [PSCustomObject]
    [System.Windows.Forms.TabPage]
    [System.Windows.Forms.GroupBox]
.OUTPUTS
    [System.Windows.Forms.GroupBox]
.NOTES
    This script is part of the Application Delivery Assistant.
    Version         : 6.7.0
    Author          : Imraan Iotana
    Creation Date   : September 2026
    Last Update     : September 2026
#>
####################################################################################################
function Import-FeatureMSISetup {
    [CmdletBinding()]
    [OutputType([System.Windows.Forms.GroupBox])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The ApplicationObject containing the Settings.')]
        [PSCustomObject]$InputObject,

        [Parameter(Mandatory=$true,HelpMessage='The Parent TabPage to which this Feature will be added.')]
        [System.Windows.Forms.TabPage]$ParentTabPage,

        [Parameter(Mandatory=$false,HelpMessage='The GroupBox underneath which this Feature will be added.')]
        [System.Windows.Forms.GroupBox]$GroupBoxAbove,

        [Parameter(Mandatory=$false,HelpMessage='The color of the GroupBox.')]
        [System.String]$Color
    )

    try {
        # EXECUTION - GROUPBOX
        # Set the GroupBox properties
        [System.Collections.Hashtable]$GroupBoxProperties = @{
            InputObject     = $InputObject
            ParentTabPage   = $ParentTabPage
            Title           = 'Create MSI install and uninstall CMD files'
            Color           = $Color
            NumberOfRows    = 2
            GroupBoxAbove   = $GroupBoxAbove
        }
        # Create the GroupBox
        [System.Windows.Forms.GroupBox]$FeatureGroupBox = New-GroupBox @GroupBoxProperties

        # Set the TextBox properties
        [System.Collections.Hashtable]$FileTextBoxProperties = @{
            RowNumber       = 1
            Label           = 'Select MSI File'
            IsPath          = $true
            ToolTip         = 'The path of the Windows Installer package (.msi).'
            SizeType        = 'Medium'
            SmallButtons    = @(@(5,'Browse File','Msi'),@(6,'Paste'),@(7,'Open'))
        }
        # Create the TextBox
        [System.Windows.Forms.TextBox]$MSISetupFilePathTextBox = New-TextBox @FileTextBoxProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ReturnTextBox

        # EXECUTION - BUTTONS
        # Set the Button properties
        [System.Collections.Hashtable[]]$ActionButtons = @(
            @{
                ColumnNumber    = 1
                Text            = 'Create CMDs'
                PNGFileName     = 'script_palette'
                SizeType        = 'Medium'
                ToolTip         = 'Create Install.cmd and Uninstall.cmd beside the selected MSI file.'
                Function        = { New-MSICommandFiles -Path $MSISetupFilePathTextBox.Text }.GetNewClosure()
            }
            @{
                ColumnNumber    = 7
                Text            = 'Clear Fields'
                PNGFileName     = 'textfield_delete'
                SizeType        = 'Small'
                ToolTip         = 'Clear this field.'
                Function        = { Clear-TextBox -TextBox $MSISetupFilePathTextBox }.GetNewClosure()
            }
        )
        # Create the Buttons
        New-ButtonLine -InputObject $InputObject -ButtonPropertiesArray $ActionButtons -ParentGroupBox $FeatureGroupBox -RowNumber 2

        # POST-EXECUTION
        # Return the GroupBox object
        $FeatureGroupBox
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Creates install and uninstall CMD files for an MSI package.
.DESCRIPTION
    Writes Install.cmd and Uninstall.cmd beside the selected MSI, using a relative package path.
    Both scripts preserve the installer exit code, prevent automatic restarts, and write verbose logs to TEMP.
    REM comments explain the commands and how to run the generated scripts.
    Explorer-copied paths enclosed in double quotes are accepted.
    Existing CMD files require overwrite confirmation. The generated scripts are not executed or elevated.
.EXAMPLE
    New-MSICommandFiles -Path 'C:\Demo\Setup.msi'
.INPUTS
    [System.String]
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant.
    Version         : 6.7.0
    Author          : Imraan Iotana
    Creation Date   : September 2026
    Last Update     : September 2026
#>
####################################################################################################
function New-MSICommandFiles {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false,HelpMessage='The MSI package for which install and uninstall CMD files will be created.')]
        [AllowNull()][AllowEmptyString()]
        [System.String]$Path
    )

    try {
        # VALIDATION
        $Path = ConvertFrom-ExplorerFilePath -Path $Path
        if (-not (Confirm-FileExtension -Path $Path -Name 'MSI File' -AllowedExtensions @('.msi'))) { return }

        # PREPARATION
        [System.IO.FileInfo]$MSIFile = Get-Item -LiteralPath $Path -Force -ErrorAction Stop
        [System.String]$InstallPath = Join-Path -Path $MSIFile.DirectoryName -ChildPath 'Install.cmd'
        [System.String]$UninstallPath = Join-Path -Path $MSIFile.DirectoryName -ChildPath 'Uninstall.cmd'
        [System.String[]]$OutputPaths = @($InstallPath, $UninstallPath)
        foreach ($OutputPath in $OutputPaths) {
            if (Test-Path -LiteralPath $OutputPath -PathType Container) {
                Write-Line "A folder occupies the output file path: $OutputPath" -Type Warning
                return
            }
        }

        # CONFIRMATION
        [System.String[]]$ExistingPaths = @($OutputPaths | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf })
        if ($ExistingPaths.Count -gt 0) {
            [System.Boolean]$UserConfirmedOverwrite = Get-UserConfirmation -Title 'Confirm Overwrite' -Body ("The following CMD files will be overwritten:`n`n{0}`n`nDo you want to continue?" -f ($ExistingPaths -join "`n"))
            if (-not $UserConfirmedOverwrite) { return }
        }

        # PREPARATION - CMD CONTENT
        # Escape literal percent signs and disable delayed expansion to preserve package filenames.
        [System.String]$PackageName = $MSIFile.Name.Replace('%', '%%')
        [System.String]$LogName = $MSIFile.BaseName.Replace('%', '%%')
        [System.String[]]$ScriptHeader = @(
            '@echo off'
            'REM Hide commands to keep the console output readable.'
            ''
            'REM Preserve literal exclamation marks in filenames.'
            'setlocal DisableDelayedExpansion'
            ''
            'REM Use UTF-8 for accented filenames and hide the code-page message.'
            'chcp 65001 >nul'
        )
        [System.String]$InstallContent = ($ScriptHeader + @(
            ''
            'REM Install the MSI from this folder with its normal interface. Run as administrator if required.'
            'REM Prevent automatic restarts and write a verbose install log to the user TEMP folder.'
            ('msiexec.exe /i "%~dp0{0}" /norestart /L*v "%TEMP%\{1}-install.log"' -f $PackageName, $LogName)
            ''
            'REM Return the MSI exit code: 0 = success, 3010 = success with restart required.'
            'exit /b %errorlevel%'
        )) -join "`r`n"
        [System.String]$UninstallContent = ($ScriptHeader + @(
            ''
            'REM Uninstall using the MSI from this folder with its normal interface. Run as administrator if required.'
            'REM Prevent automatic restarts and write a verbose uninstall log to the user TEMP folder.'
            ('msiexec.exe /x "%~dp0{0}" /norestart /L*v "%TEMP%\{1}-uninstall.log"' -f $PackageName, $LogName)
            ''
            'REM Return the MSI exit code: 0 = success, 3010 = success with restart required.'
            'exit /b %errorlevel%'
        )) -join "`r`n"

        # EXECUTION
        [System.Text.UTF8Encoding]$Encoding = New-Object System.Text.UTF8Encoding($false)
        [System.IO.File]::WriteAllText($InstallPath, $InstallContent + "`r`n", $Encoding)
        [System.IO.File]::WriteAllText($UninstallPath, $UninstallContent + "`r`n", $Encoding)

        # POST-EXECUTION
        Write-Line "Created MSI install command file: $InstallPath" -Type Success
        Write-Line "Created MSI uninstall command file: $UninstallPath" -Type Success
        Open-Folder -Path $MSIFile.DirectoryName
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}

### END OF FUNCTION
####################################################################################################