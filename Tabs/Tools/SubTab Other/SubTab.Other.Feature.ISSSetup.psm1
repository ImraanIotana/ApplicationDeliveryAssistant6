####################################################################################################
<#
.SYNOPSIS
    Imports the ISS Setup feature into the Other sub-tab.
.DESCRIPTION
    This function imports the ISS Setup feature into the Other sub-tab by creating a new GroupBox and adding it to the specified parent TabPage.
.EXAMPLE
    Import-FeatureISSSetup -InputObject $MyApplicationObject -ParentTabPage $MyTabPage
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
    Creation Date   : July 2026
    Last Update     : July 2026
#>
####################################################################################################
function Import-FeatureISSSetup {
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
            Title           = 'Create ISS Response File'
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
        [System.Windows.Forms.TextBox]$ISSSetupFilePathTextBox = New-TextBox @FileTextBoxProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ReturnTextBox

        # EXECUTION - BUTTONS
        # Set the Button properties
        [System.Collections.Hashtable[]]$ActionButtons = @(
            @{
                ColumnNumber    = 1
                Text            = 'Create ISS'
                PNGFileName     = 'script_palette'
                SizeType        = 'Medium'
                Function        = { New-ISSResponseFile -Path $ISSSetupFilePathTextBox.Text }.GetNewClosure()
            }
            @{
                ColumnNumber    = 7
                Text            = 'Clear Fields'
                PNGFileName     = 'textfield_delete'
                SizeType        = 'Small'
                ToolTip         = 'Clear this field.'
                Function        = { Clear-TextBox -TextBox $ISSSetupFilePathTextBox }.GetNewClosure()
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
    Creates an InstallShield response file (ISS) for an installer executable.
.DESCRIPTION
    This function launches an InstallShield installer with recording switches to generate an ISS response file.
    It validates the installer path and output folder, asks for confirmation before starting, and optionally
    confirms overwrite when the target ISS file already exists.
.EXAMPLE
    New-ISSResponseFile -Path 'C:\Demo\setup.exe'
.EXAMPLE
    New-ISSResponseFile -Path 'C:\Demo\setup.exe' -OutputFolder 'C:\Temp\ISS'
.INPUTS
    [System.String]
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
function New-ISSResponseFile {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false,HelpMessage='The executable for which an ISS file will be made.')]
        [System.String]
        $Path,

        [Parameter(Mandatory=$false,HelpMessage='The folder where the ISS file will be placed.')]
        [System.String]
        $OutputFolder = (Get-Folder -OutputFolder)
    )

    try {
        # PREPARATION
        # Set main paths for the installer and generated response file
        [System.String]$ExecutablePath = $Path
        [System.String]$OutputFileName = 'Setup.iss'

        # VALIDATION
        # Validate that the installer and output folder exist before starting
        if (Test-String -IsEmpty $ExecutablePath) {
            Write-Line 'No installer file was selected. Please select an InstallShield setup file first.' -Type Warning
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
        # Build the final output ISS path after validation to avoid path binding errors
        $OutputFilePath = Join-Path -Path $OutputFolder -ChildPath $OutputFileName

        # CONFIRMATION
        # Confirm running the installer because this will execute the setup interactively
        [System.Boolean]$UserConfirmedCreation = Get-UserConfirmation -Title 'Confirm ISS Creation' -Body ("This will run the installer and create a response file (ISS):`n`n$ExecutablePath`n`nDo you want to continue?")
        if (-not $UserConfirmedCreation) { return }

        # CONFIRMATION
        # Confirm overwrite when an output file already exists
        if (Test-Path -Path $OutputFilePath -PathType Leaf) {
            [System.Boolean]$UserConfirmedOverWrite = Get-UserConfirmation -Title 'Confirm Overwrite' -Body ("The output file already exists and will be overwritten:`n`n$OutputFilePath`n`nDo you want to continue?")
            if (-not $UserConfirmedOverWrite) { return }

            Write-Line "Removing existing ISS file: $OutputFilePath"
            Remove-Item -Path $OutputFilePath -Force
        }

        # EXECUTION
        # Launch installer in record mode to write the response file
        Write-Line "Running installer to create ISS file: $OutputFilePath"
        Start-Process -FilePath $ExecutablePath -ArgumentList @('/r', "/f1`"$OutputFilePath`"") -Wait

        # POST-EXECUTION
        # Verify output creation and open the output folder for convenience
        if (Test-Path -Path $OutputFilePath -PathType Leaf) {
            Write-Line "The ISS file has been created: $OutputFilePath" -Type Success
            Open-Folder -Path $OutputFolder
        }
        else {
            Write-Line "The installer finished, but no ISS file was found at: $OutputFilePath" -Type Warning
        }
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}

### END OF FUNCTION
####################################################################################################
