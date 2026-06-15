####################################################################################################
<#
.SYNOPSIS
    Imports the Application Detection feature into the Intake sub-tab.
.DESCRIPTION
    This function imports the Application Detection feature into the Intake sub-tab by creating a new GroupBox and adding it to the specified parent TabPage.
.EXAMPLE
    Import-FeatureIntakeApplicationDetection -InputObject $MyApplicationObject -ParentTabPage $MyTabPage
.INPUTS
    [PSCustomObject]
    [System.Windows.Forms.TabPage]
    [System.Windows.Forms.GroupBox]
.OUTPUTS
    [System.Windows.Forms.GroupBox]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. All rights reserved.
    Version         : 6.0.0.0
    Author          : Imraan Iotana
    Creation Date   : May 2026
    Last Update     : June 2026
#>
####################################################################################################
function Import-FeatureIntakeApplicationID {
    [CmdletBinding()]
    [OutputType([System.Windows.Forms.GroupBox])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The ApplicationObject containing the Settings.')]
        [PSCustomObject]$InputObject,

        [Parameter(Mandatory=$true,HelpMessage='The Parent TabPage to which this Feature will be added.')]
        [System.Windows.Forms.TabPage]$ParentTabPage,

        [Parameter(Mandatory=$false,HelpMessage='The GroupBox above which this Feature will be added.')]
        [System.Windows.Forms.GroupBox]$GroupBoxAbove,

        [Parameter(Mandatory=$false,HelpMessage='The color of the GroupBox.')]
        [System.String]$Color
    )

    try {
        # EXECUTION - GROUPBOX
        # Feature properties
        [System.Collections.Hashtable]$FeatureProperties = @{
            InputObject     = $InputObject
            ParentTabPage   = $ParentTabPage
            Title           = 'APPLICATION ID'
            Color           = $Color
            NumberOfRows    = 2
            GroupBoxAbove   = $GroupBoxAbove
        }
        # Create the GroupBox
        [System.Windows.Forms.GroupBox]$FeatureGroupBox = New-GroupBox @FeatureProperties -OnSubTab

        # EXECUTION - TEXTBOX
        # Set the TextBox properties
        [System.Collections.Hashtable]$ApplicationIDTextBoxProperties = @{
            RowNumber       = 2
            Label           = 'Application ID'
            PropertyName    = 'TextBoxes.ApplicationIntake.ApplicationID'
            ToolTip         = 'The ID of the application to intake'
            SizeType        = 'Medium'
            Type            = 'Output'
        }
        # Create the hashtables for the TextBoxes in the Global Graphics object if they do not already exist
        if (-not $Global:Graphics.TextBoxes.ContainsKey('ApplicationIntake')) { $Global:Graphics.TextBoxes.ApplicationIntake = @{} }
        # Create the TextBox
        $Global:Graphics.TextBoxes.ApplicationIntake.ApplicationID = New-TextBox @ApplicationIDTextBoxProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ReturnTextBox

        # EXECUTION - BUTTONS
        # Set the Buttons properties
        [System.Collections.Hashtable]$ApplicationIDButtonProperties = @{
            ColumnNumber    = 1
            RowNumber       = 1
            Text            = 'Application ID'
            PNGFileName     = 'download_for_windows'
            SizeType        = 'Medium'
            ToolTip         = 'Browse for a detection file or MSI.'
            Function        = { New-ApplicationIDFromTextBoxes -OutputTextBox $Global:Graphics.TextBoxes.ApplicationIntake.ApplicationID }.GetNewClosure()
        }
        [System.Collections.Hashtable]$CreateFolderButtonProperties = @{
            ColumnNumber    = 5
            RowNumber       = 2
            Text            = 'Create Folder'
            PNGFileName     = 'folder_add'
            SizeType        = 'Medium'
            ToolTip         = 'Browse for a detection file or MSI.'
            Function        = { New-ApplicationFolder }.GetNewClosure()
        }
        # Add the Buttons
        New-Button @ApplicationIDButtonProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox
        New-Button @CreateFolderButtonProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox

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
    Creates the application folder structure for the generated Application ID.
.DESCRIPTION
    This function creates the application folder for the current Application ID in the configured output folder.
    It validates the output folder and Application ID, asks for confirmation before overwriting an existing folder,
    creates the folder and its configured subfolders, and opens the output folder afterwards.
.EXAMPLE
    New-ApplicationFolder
.INPUTS
    [System.String]
.OUTPUTS
    No objects are returned to the pipeline. All output is written to the host.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. All rights reserved.
    Version         : 6.0.0.0
    Author          : Imraan Iotana
    Creation Date   : June 2026
    Last Update     : June 2026
#>
####################################################################################################
function New-ApplicationIDFromTextBoxes {
    param (
        [Parameter(Mandatory=$false,HelpMessage='The TextBox to write the Application ID into.')]
        [System.Windows.Forms.TextBox]$OutputTextBox
    )
    
    try {
        # VALIDATION
        # Define the TextBoxes to get the text from
        [System.String[]]$TextBoxesToGetTextFrom = @(
            'VendorName'
            'ApplicationName'
            'ApplicationVersion'
        )
        # Create a hashtable to store the trimmed values of the TextBoxes
        [System.Collections.Hashtable]$TrimmedValues = @{}
        # Loop through the TextBoxes, get the text, trim it and store it in the hashtable
        foreach ($TextBoxName in $TextBoxesToGetTextFrom) {
            $TrimmedValues[$TextBoxName] = ($Global:Graphics.TextBoxes.ApplicationIntake.CustomProperties.$TextBoxName.Text -replace '\s+', '')
        }
        # Validate that none of the trimmed values are empty
        foreach ($Key in $TrimmedValues.Keys) {
            if (Test-String -IsEmpty $TrimmedValues[$Key]) {
                Write-Line "$Key is empty. The Application ID cannot be generated."
                if ($OutputTextBox) { Clear-TextBox -TextBox $OutputTextBox -Force }
                return
            }
        }
        # Reuse the already validated and normalized values
        [System.String]$VendorName          = $TrimmedValues.VendorName
        [System.String]$ApplicationName     = $TrimmedValues.ApplicationName
        [System.String]$ApplicationVersion  = $TrimmedValues.ApplicationVersion


        # VALIDATION
        # If the Application Name contains the Application Version, write a warning
        if ($ApplicationName.Contains($ApplicationVersion)) {
            Write-Line "Warning: The Custom Application Name contains the Application Version. This will cause the Application Version to be duplicated in the Application ID." -Type Warning
        }
        # If the Application Name contains the Vendor Name, write a warning
        if ($ApplicationName.Contains($VendorName)) {
            Write-Line "Warning: The Custom Application Name contains the Vendor Name. This will cause the Vendor Name to be duplicated in the Application ID." -Type Warning
        }

        # EXECUTION
        # Generate the Application ID in the format VendorName_ApplicationName_ApplicationVersion, without any whitespace
        [System.String]$ApplicationID = "$($VendorName)_$($ApplicationName)_$($ApplicationVersion)"
        Write-Line "Generated Application ID: $ApplicationID"

        # EXECUTION
        # Set the text to the textbox
        if ($OutputTextBox) { $OutputTextBox.Text = $ApplicationID }
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
    Generates an Application ID from Intake Custom Properties textboxes.
.DESCRIPTION
    This function reads Vendor Name, Application Name, and Application Version from the Intake Custom Properties textboxes.
    It removes all whitespace from each value, validates that all values are populated, and generates an Application ID string.
    The generated ID is written to the supplied output textbox when one is provided.
.EXAMPLE
    New-ApplicationIDFromTextBoxes -OutputTextBox $Global:Graphics.TextBoxes.ApplicationIntake.ApplicationID
.INPUTS
    [System.Windows.Forms.TextBox]
.OUTPUTS
    No objects are returned to the pipeline. The result is written to the provided textbox.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. All rights reserved.
    Version         : 6.0.0.0
    Author          : Imraan Iotana
    Creation Date   : June 2026
    Last Update     : June 2026
#>
####################################################################################################
function New-ApplicationFolder {
    param (
        [Parameter(Mandatory=$false,HelpMessage='Destination folder where the export text file will be created.')]
        [System.String]$OutputFolder = (Get-OutputFolder)
    )
    
    try {
        # VALIDATION
        # If OutputFolder is not provided, throw an error
        if (Test-String -IsEmpty $OutputFolder) { throw "The OutputFolder parameter is empty." }
        # If the output folder does not exist, create it
        if (-not (Test-Path -Path $OutputFolder -PathType Container)) { New-Item -Path $OutputFolder -ItemType Directory -Force | Out-Null }

        # PREPARATION
        # Get the Application ID from the ApplicationID TextBox
        [System.String]$ApplicationID = $Global:Graphics.TextBoxes.ApplicationIntake.ApplicationID.Text
        # If the Application ID is empty, throw an error
        if (Test-String -IsEmpty $ApplicationID) {
            Write-Line "The Application ID is empty. Please generate an Application ID before creating the application folder. No action has been taken."
            return
        }
        # Set the path for the new folder
        [System.String]$NewFolderPath = Join-Path -Path $OutputFolder -ChildPath $ApplicationID

        # CONFIRMATION
        # Set the Title and Body for the confirmation message box
        if (Test-Path -Path $NewFolderPath -PathType Container) {
            [System.String]$Title   = "Confirm Overwrite Application Folder"
            [System.String]$Body    = "This will OVERWRITE the EXISTING Application Folder with the following name:`n`n$ApplicationID`n`nDo you want to continue?"
        }
        else {
            [System.String]$Title   = "Create Application Folder"
            [System.String]$Body    = "This will create a NEW Application Folder with the following name:`n`n$ApplicationID`n`nDo you want to continue?"
        }
        # If the user did not confirm, return
        if (-not (Get-UserConfirmation -Title $Title -Body $Body)) { return }

        # EXECUTION
        # Remove the existing folder if it exists
        if (Test-Path -Path $NewFolderPath -PathType Container) { Remove-Item -Path $NewFolderPath -Recurse -Force }
        # Create the new folder
        New-Item -Path $NewFolderPath -ItemType Directory -Force | Out-Null
        # Get the subfolders from the Application Folder Template
        [System.Collections.Generic.List[System.String]]$SubFolders = $Global:Graphics.ComboBoxes.ApplicationIntake.TemplateSelection.SelectedItem.ApplicationFolderSubFolders.GetEnumerator() | ForEach-Object { $_.Value }
        # Create the subfolders in the new folder
        foreach ($SubFolder in $SubFolders) {
            [System.String]$SubFolderPath = Join-Path -Path $NewFolderPath -ChildPath $SubFolder
            New-Item -Path $SubFolderPath -ItemType Directory -Force | Out-Null
        }

        # Create the initial Word document in the Documentation subfolder from the selected template.
        [System.Object]$SelectedTemplate = $Global:Graphics.ComboBoxes.ApplicationIntake.TemplateSelection.SelectedItem
        New-ApplicationIntakeDocument -ApplicationFolderPath $NewFolderPath -SelectedTemplate $SelectedTemplate

        # This function is still in development. The output folder is set to: $OutputFolder
        Write-Line "New-ApplicationFolder: This function is still in development. The output folder is set to: $OutputFolder"

        # POST-EXECUTION
        # Open the OutputFolder
        Open-Folder -Path $OutputFolder
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
    Creates a Word document from the selected customer template in the Documentation subfolder.
.DESCRIPTION
    Resolves the selected customer template from the Template Selection combobox, finds the configured Word template
    below the application root folder, opens it in Word, and saves it as a .docx file in the Documentation subfolder
    of the supplied application folder.
.EXAMPLE
    New-ApplicationIntakeDocument -ApplicationFolderPath 'C:\Temp\Vendor_App_1.0'
.INPUTS
    [System.String]
.OUTPUTS
    No objects are returned to the pipeline. All output is written to the host.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. All rights reserved.
    Version         : 6.0.0.0
    Author          : Imraan Iotana
    Creation Date   : June 2026
    Last Update     : June 2026
#>
####################################################################################################
function New-ApplicationIntakeDocument {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The root folder of the created application package.')]
        [System.String]$ApplicationFolderPath,

        [Parameter(Mandatory=$true,HelpMessage='The selected customer template object from the Template Selection ComboBox.')]
        [System.Object]$SelectedTemplate
    )

    try {
        # VALIDATION
        # Validate the target application folder path
        if (Test-String -IsEmpty $ApplicationFolderPath) { throw 'The ApplicationFolderPath parameter is empty.' }
        if (-not (Test-Path -LiteralPath $ApplicationFolderPath -PathType Container)) { throw "The application folder does not exist. ($ApplicationFolderPath)" }

        # VALIDATION
        # Ensure a template object is provided
        if ($null -eq $SelectedTemplate) {
            Write-Line 'No customer template is selected. Skipping document creation.' -Type Warning
            return
        }

        # PREPARATION
        # Read the configured Word template name from the selected customer template
        [System.String]$WordTemplateName = $SelectedTemplate.Content.TemplateName
        if (Test-String -IsEmpty $WordTemplateName) {
            Write-Line 'The selected customer template does not define Content.TemplateName. Skipping document creation.' -Type Warning
            return
        }

        # PREPARATION
        # Read the application root folder used to locate templates
        [System.String]$RootFolder = $Global:ApplicationObject.RootFolder
        if (Test-String -IsEmpty $RootFolder) { throw 'Global ApplicationObject.RootFolder is empty.' }

        # PREPARATION
        # Search the template file from the application root folder.
        [System.String]$ResolvedTemplatePath = $null
        [System.IO.FileInfo]$TemplateFile = Get-ChildItem -LiteralPath $RootFolder -Recurse -File -Filter $WordTemplateName -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($null -ne $TemplateFile) { $ResolvedTemplatePath = $TemplateFile.FullName }

        if (Test-String -IsEmpty $ResolvedTemplatePath) {
            Write-Line "The selected Word template could not be found in the application root folder. ($WordTemplateName)" -Type Fail
            return
        }

        # PREPARATION
        # Resolve the Documentation subfolder configured by the selected customer template
        [System.String]$DocumentationRelativePath = $SelectedTemplate.ApplicationFolderSubFolders.Documentation
        if (Test-String -IsEmpty $DocumentationRelativePath) {
            Write-Line 'The selected customer template does not define ApplicationFolderSubFolders.Documentation. Skipping document creation.' -Type Warning
            return
        }

        # EXECUTION
        # Ensure the target Documentation subfolder exists
        [System.String]$DocumentationFolderPath = Join-Path -Path $ApplicationFolderPath -ChildPath $DocumentationRelativePath
        if (-not (Test-Path -LiteralPath $DocumentationFolderPath -PathType Container)) {
            New-Item -Path $DocumentationFolderPath -ItemType Directory -Force | Out-Null
        }

        # PREPARATION
        # Build the output document name using the generated Application ID
        [System.String]$ApplicationID = $Global:Graphics.TextBoxes.ApplicationIntake.ApplicationID.Text
        if (Test-String -IsEmpty $ApplicationID) {
            [System.String]$ApplicationID = 'ApplicationDossier'
        }

        [System.String]$OutputDocumentPath = Join-Path -Path $DocumentationFolderPath -ChildPath ('KPN Dossier ' + $ApplicationID + '.docx')

        # EXECUTION
        # Start Word, create a document from template and save it to the Documentation folder
        [System.__ComObject]$WordApplication = New-Object -ComObject Word.Application
        $WordApplication.Visible = $true

        [System.__ComObject]$WordDocument = $WordApplication.Documents.Add($ResolvedTemplatePath)
        $WordDocument.SaveAs2($OutputDocumentPath)

        # POST-EXECUTION
        # Close Word and report the created document path
        $WordDocument.Close($false)
        $WordApplication.Quit()
        Write-Line "Created Word document from template: $OutputDocumentPath" -Type Success

        # POST-EXECUTION
        # Release COM objects to avoid stale Word processes
        [void][System.Runtime.InteropServices.Marshal]::ReleaseComObject($WordDocument)
        [void][System.Runtime.InteropServices.Marshal]::ReleaseComObject($WordApplication)
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}

### END OF FUNCTION
####################################################################################################

