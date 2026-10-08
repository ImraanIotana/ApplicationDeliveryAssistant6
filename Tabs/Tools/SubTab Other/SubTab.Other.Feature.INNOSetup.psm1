####################################################################################################
<#
.SYNOPSIS
    Imports the INNO Setup feature into the Other sub-tab.
.DESCRIPTION
    This function imports the INNO Setup feature into the Other sub-tab by creating a new GroupBox and adding it to the specified parent TabPage.
.EXAMPLE
    Import-FeatureINNOSetup -InputObject $MyApplicationObject -ParentTabPage $MyTabPage
.INPUTS
    [PSCustomObject]
    [System.Windows.Forms.TabPage]
    [System.Windows.Forms.GroupBox]
.OUTPUTS
    [System.Windows.Forms.GroupBox]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.1
    Author          : Imraan Iotana
    Creation Date   : May 2026
    Last Update     : July 2026
#>
####################################################################################################
function Import-FeatureINNOSetup {
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
            Title           = 'Create INNO Response File'
            Color           = $Color
            NumberOfRows    = 2
            GroupBoxAbove   = $GroupBoxAbove
        }
        # Create the GroupBox
        [System.Windows.Forms.GroupBox]$FeatureGroupBox = New-GroupBox @GroupBoxProperties

        # Set the TextBox properties
        [System.Collections.Hashtable]$FileTextBoxProperties = @{
            RowNumber       = 1
            Label           = 'Select Setup File'
            ToolTip         = 'The path of the Setup file (executable) to create a response file for.'
            SizeType        = 'Medium'
            SmallButtons    = @(@(5,'Browse File'),@(6,'Paste'),@(7,'Open'))
        }
        # Create the TextBox
        [System.Windows.Forms.TextBox]$INNOSetupFilePathTextBox = New-TextBox @FileTextBoxProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ReturnTextBox

        # EXECUTION - BUTTONS
        # Set the Button properties
        [System.Collections.Hashtable[]]$ActionButtons = @(
            @{
                ColumnNumber    = 1
                Text            = 'Create INF'
                PNGFileName     = 'script_palette'
                SizeType        = 'Medium'
                Function        = { New-INNOResponseFile -Path $INNOSetupFilePathTextBox.Text }.GetNewClosure()
            }
            @{
                ColumnNumber    = 7
                Text            = 'Clear Fields'
                PNGFileName     = 'textfield_delete'
                SizeType        = 'Small'
                ToolTip         = 'Clear this field.'
                Function        = { Clear-TextBox -TextBox $INNOSetupFilePathTextBox }.GetNewClosure()
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
    Creates an INNO Setup response file (INF) for an installer executable.
.DESCRIPTION
    This function launches an INNO Setup installer with the /SAVEINF switch to generate an INF response file.
    It validates the installer path and output folder, asks for confirmation before starting, and optionally
    confirms overwrite when the target INF file already exists.
.EXAMPLE
    New-INNOResponseFile -Path 'C:\Demo\setup.exe'
.EXAMPLE
    New-INNOResponseFile -Path 'C:\Demo\setup.exe' -OutputFolder 'C:\Temp\INNO'
.INPUTS
    [System.String]
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.1
    Author          : Imraan Iotana
    Creation Date   : October 2025
    Last Update     : July 2026
#>
####################################################################################################
function New-INNOResponseFile {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false,HelpMessage='The executable for which an INF file will be made.')]
        [System.String]
        $Path,

        [Parameter(Mandatory=$false,HelpMessage='The folder where the INF file will be placed.')]
        [System.String]
        $OutputFolder = (Get-Folder -OutputFolder)
    )

    try {
        # PREPARATION
        # Set main paths for the installer and generated response file
        [System.String]$ExecutablePath = $Path
        [System.String]$OutputFileName = 'Install.inf'

        # VALIDATION
        # Validate that the installer and output folder exist before starting
        if (Test-String -IsEmpty $ExecutablePath) {
            Write-Line 'No installer file was selected. Please select an INNO Setup file first.' -Type Warning
            return
        }
        if (Test-String -IsEmpty $OutputFolder) {
            Write-Line 'The output folder is empty or undefined.' -Type Warning
            return
        }
        if (-not (Test-Path -Path $ExecutablePath -PathType Leaf)) {
            Write-Line "The executable file cannot be found: $ExecutablePath" -Type Warning
            return
        }
        if (-not (Test-Path -Path $OutputFolder -PathType Container)) {
            Write-Line "The output folder cannot be found: $OutputFolder" -Type Warning
            return
        }

        # PREPARATION
        # Build the final output INF path after validation to avoid path binding errors
        $OutputFilePath = Join-Path -Path $OutputFolder -ChildPath $OutputFileName

        # CONFIRMATION
        # Confirm running the installer because this will execute the setup interactively
        [System.Boolean]$UserConfirmedCreation = Get-UserConfirmation -Title 'Confirm INF Creation' -Body ("This will run the installer and create a response file (INF):`n`n$ExecutablePath`n`nDo you want to continue?")
        if (-not $UserConfirmedCreation) { return }

        # CONFIRMATION
        # Confirm overwrite when an output file already exists
        if (Test-Path -Path $OutputFilePath -PathType Leaf) {
            [System.Boolean]$UserConfirmedOverWrite = Get-UserConfirmation -Title 'Confirm Overwrite' -Body ("The output file already exists and will be overwritten:`n`n$OutputFilePath`n`nDo you want to continue?")
            if (-not $UserConfirmedOverWrite) { return }

            Write-Line "Removing existing INF file: $OutputFilePath"
            Remove-Item -Path $OutputFilePath -Force
        }

        # EXECUTION
        # Launch installer with /SAVEINF to write the response file
        Write-Line "Running installer to create INF file: $OutputFilePath"
        Start-Process -FilePath $ExecutablePath -ArgumentList "/SAVEINF=$OutputFilePath" -Wait

        # POST-EXECUTION
        # Verify output creation and open the output folder for convenience
        if (Test-Path -Path $OutputFilePath -PathType Leaf) {
            Write-Line "The INF file has been created: $OutputFilePath" -Type Success
            Open-Folder -Path $OutputFolder
        }
        else {
            Write-Line "The installer finished, but no INF file was found at: $OutputFilePath" -Type Warning
        }
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}

### END OF FUNCTION
####################################################################################################
