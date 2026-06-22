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
        [ValidateNotNullOrEmpty()]
        [System.String]$ApplicationFolderPath,

        [Parameter(Mandatory=$true,HelpMessage='The selected customer template object from the Template Selection ComboBox.')]
        [ValidateNotNullOrEmpty()]
        [System.Object]$SelectedTemplate,

        [Parameter(Mandatory=$true,HelpMessage='The folder where Word templates are searched.')]
        [ValidateNotNullOrEmpty()]
        [System.String]$FolderToSearch
    )

    try {
        # VALIDATION
        # Validate all input parameters and paths exist
        if (-not (Test-Path -LiteralPath $ApplicationFolderPath -PathType Container)) { throw "The application folder does not exist. ($ApplicationFolderPath)" }
        if (-not (Test-Path -LiteralPath $FolderToSearch -PathType Container)) { throw "Template search folder not found. ($FolderToSearch)" }
        # Validate template object has required properties
        [System.String]$WordTemplateName = $SelectedTemplate.Content.TemplateName
        if (Test-String -IsEmpty $WordTemplateName) {
            Write-Line 'The selected customer template does not define Content.TemplateName. Skipping document creation.' -Type Warning
            return
        }
        # Validate template object has required properties for output path construction
        [System.String]$DocumentationRelativePath = $SelectedTemplate.ApplicationFolderSubFolders.Documentation
        if (Test-String -IsEmpty $DocumentationRelativePath) {
            Write-Line 'The selected customer template does not define ApplicationFolderSubFolders.Documentation. Skipping document creation.' -Type Warning
            return
        }
        # Validate template file can be found
        [System.String]$ResolvedTemplatePath = (Get-ChildItem -LiteralPath $FolderToSearch -Recurse -File -Filter $WordTemplateName -ErrorAction SilentlyContinue | Select-Object -First 1).FullName
        if (Test-String -IsEmpty $ResolvedTemplatePath) {
            Write-Line "The selected Word template could not be found in the template search folder. ($WordTemplateName)" -Type Fail
            return
        }

        # PREPARATION
        # Build the output document name using the generated Application ID
        [System.String]$ApplicationID = $Global:Graphics.TextBoxes.ApplicationIntake.ApplicationID.Text
        if (Test-String -IsEmpty $ApplicationID) {
            $ApplicationID = 'ApplicationDossier'
        }
        # Ensure the target Documentation subfolder exists
        [System.String]$DocumentationFolderPath = Join-Path -Path $ApplicationFolderPath -ChildPath $DocumentationRelativePath
        if (-not (Test-Path -LiteralPath $DocumentationFolderPath -PathType Container)) {
            New-Item -Path $DocumentationFolderPath -ItemType Directory -Force | Out-Null
        }

        [System.String]$OutputDocumentPath = Join-Path -Path $DocumentationFolderPath -ChildPath ('KPN Dossier ' + $ApplicationID + '.docx')

        # EXECUTION
        # Create the intake document from template and fill the fields
        New-WordDocumentFromTemplate -TemplatePath $ResolvedTemplatePath -OutputPath $OutputDocumentPath

        # POST-EXECUTION
        # Report the created document path.
        Write-Line "Succesfully created Word document: $OutputDocumentPath" -Type Success
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
    Creates an application documentation Word file from a template and replaces placeholder text.
.DESCRIPTION
    Opens a Word template as a new document, replaces known placeholder text values, and saves the result
    to the supplied output path as a .docx document.
.EXAMPLE
    New-WordDocumentFromTemplate -TemplatePath 'C:\Templates\Dossier.dotx' -OutputPath 'C:\Out\Dossier.docx'
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
function New-WordDocumentFromTemplate {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='Path to the Word template file (.dotx) to use as the base for the new document.')]
        [ValidateNotNullOrEmpty()]
        [System.String]$TemplatePath,

        [Parameter(Mandatory=$true,HelpMessage='Path where the generated Word document (.docx) will be saved.')]
        [ValidateNotNullOrEmpty()]
        [System.String]$OutputPath
    )

    # PREPARATION
    # Initialize COM objects to ensure cleanup in finally block even if exception occurs early
    [System.Object]$Word = $null
    [System.Object]$Document = $null

    try {
        # VALIDATION
        if (-not (Test-Path -LiteralPath $TemplatePath -PathType Leaf)) { throw "Template not found. ($TemplatePath)" }

        # CONFIRMATION
        # Ask the user to confirm creating the Word document.
        [System.String]$Title = 'Confirm Word Document'
        [System.String]$Body = "Do you want to create the Word document?"
        if (-not (Get-UserConfirmation -Title $Title -Body $Body)) { return }
        
        # PREPARATION
        # Start Word in the background and create a new document from the template.
        Write-Line "Creating Word document, one moment please..."
        $Word = New-Object -ComObject Word.Application
        $Word.Visible = $false
        $Document = $Word.Documents.Add($TemplatePath)

        # PREPARATION
        # Map placeholder text to replacement values.
        [System.Collections.Hashtable]$ReplaceMap = Get-DocumentReplacementMap

        # EXECUTION
        # Replace placeholder text in the whole document body.
        Update-WordDocument -Document $Document -ReplaceMap $ReplaceMap

        # EXECUTION
        # Save the generated document.
        [System.String]$ResolvedOutputPath = [System.IO.Path]::GetFullPath($OutputPath)
        [System.String]$OutputDirectory = [System.IO.Path]::GetDirectoryName($ResolvedOutputPath)
        if (-not (Test-Path -LiteralPath $OutputDirectory -PathType Container)) {
            New-Item -Path $OutputDirectory -ItemType Directory -Force | Out-Null
        }
        $Document.SaveAs2($ResolvedOutputPath)
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
    finally {
        # POST-EXECUTION
        # Ensure COM objects are closed and released.
        if ($Document) {
            $Document.Close($false)
            [void][System.Runtime.InteropServices.Marshal]::ReleaseComObject($Document)
        }
        if ($Word) {
            $Word.Quit()
            [void][System.Runtime.InteropServices.Marshal]::ReleaseComObject($Word)
        }
        # Clean up variables to avoid accidental reuse and reduce memory footprint.
        Remove-Variable Document -ErrorAction SilentlyContinue
        Remove-Variable Word -ErrorAction SilentlyContinue
    }
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Updates a Word document by replacing placeholder text values.
.DESCRIPTION
    Uses a supplied replacement map to perform Find/Replace operations over the whole document body.
.EXAMPLE
    Update-WordDocument -Document $Document -ReplaceMap $ReplaceMap
.INPUTS
    [System.Object]
    [System.Collections.Hashtable]
.OUTPUTS
    No objects are returned to the pipeline. The Word document is modified in place.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. All rights reserved.
    Version         : 6.0.0.0
    Author          : Imraan Iotana
    Creation Date   : June 2026
    Last Update     : June 2026
#>
####################################################################################################
function Update-WordDocument {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The Word document object to update.')]
        [System.Object]$Document,

        [Parameter(Mandatory=$true,HelpMessage='Hashtable mapping placeholder text tokens to their replacement values.')]
        [System.Collections.Hashtable]$ReplaceMap
    )

    foreach ($Key in $ReplaceMap.Keys) {
        [System.Object]$Find = $Document.Content.Find
        [void]$Find.ClearFormatting()
        [void]$Find.Replacement.ClearFormatting()
        [void]$Find.Execute(
            [ref]$Key,
            [ref]$false,
            [ref]$false,
            [ref]$false,
            [ref]$false,
            [ref]$false,
            [ref]$true,
            [ref]1,
            [ref]$false,
            [ref]$ReplaceMap[$Key],
            [ref]2
        )
    }
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Builds the placeholder-to-value map for Word document replacement.
.DESCRIPTION
    Returns a hashtable that maps the supported document placeholder tokens to their current values
    from the Intake textboxes. This map is used by New-WordDocumentFromTemplate to perform Find/Replace updates
    in the generated Word document.
.EXAMPLE
    Get-DocumentReplacementMap
.INPUTS
    None.
.OUTPUTS
    [System.Collections.Hashtable]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. All rights reserved.
    Version         : 6.0.0.0
    Author          : Imraan Iotana
    Creation Date   : June 2026
    Last Update     : June 2026
#>
####################################################################################################
function Get-DocumentReplacementMap {
    # EXECUTION
    # Build a static replacement map from the corresponding textbox values.
    return @{
        # Formal Application Properties
        '[FORMALVENDORNAME]'         = $Global:Graphics.TextBoxes.ApplicationIntake.FormalProperties.VendorName.Text
        '[FORMALAPPLICATIONNAME]'    = $Global:Graphics.TextBoxes.ApplicationIntake.FormalProperties.ApplicationName.Text
        '[FORMALAPPLICATIONVERSION]' = $Global:Graphics.TextBoxes.ApplicationIntake.FormalProperties.ApplicationVersion.Text
        # Custom Application Properties
        '[CUSTOMVENDORNAME]'         = $Global:Graphics.TextBoxes.ApplicationIntake.CustomProperties.VendorName.Text
        '[CUSTOMAPPLICATIONNAME]'    = $Global:Graphics.TextBoxes.ApplicationIntake.CustomProperties.ApplicationName.Text
        '[CUSTOMAPPLICATIONVERSION]' = $Global:Graphics.TextBoxes.ApplicationIntake.CustomProperties.ApplicationVersion.Text
        # Other Intake Properties
        '[INSTALLATIONFOLDER]'       = $Global:Graphics.TextBoxes.ApplicationIntake.Security.InstallationFolder.Text
        '[BITNESS]'                  = (Get-FileBitness -Path $Global:Graphics.TextBoxes.ApplicationIntake.Detection.DetectionFile.Text -ForDocument)
        # User properties
        '[USERFULLNAME]'             = $Global:Graphics.TextBoxes.IntakeSettings.ExtraDocumentInformation.UserFullName.Text
        '[USEREMAILADDRESS]'         = $Global:Graphics.TextBoxes.IntakeSettings.ExtraDocumentInformation.UserEmailAddress.Text
    }
}

### END OF FUNCTION
####################################################################################################

