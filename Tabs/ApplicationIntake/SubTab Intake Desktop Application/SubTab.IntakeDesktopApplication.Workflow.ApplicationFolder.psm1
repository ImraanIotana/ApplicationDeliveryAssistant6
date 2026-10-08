####################################################################################################
<#
.SYNOPSIS
    Creates the application folder structure and initial Intake artifacts.
.DESCRIPTION
    Validates the current Intake state, confirms replacement when needed, initializes lifecycle
    logging, and invokes each artifact action in workflow order.
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    Version         : 6.6.1
#>
####################################################################################################
function New-ApplicationFolder {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false,HelpMessage='Parent folder where the application folder will be created.')]
        [System.String]$OutputFolder = (Get-Folder -OutputFolder)
    )

    [PSCustomObject]$Context = $null
    try {
        if (Test-String -IsEmpty $OutputFolder) { throw 'The OutputFolder parameter is empty.' }

        [System.Windows.Forms.TextBox]$ApplicationIDTextBox = Get-IntakeApplicationIDTextBox
        New-ApplicationIDFromTextBoxes -OutputTextBox $ApplicationIDTextBox
        [System.String]$ApplicationID = if ($null -ne $ApplicationIDTextBox) { $ApplicationIDTextBox.Text } else { $null }
        [System.Windows.Forms.TextBox]$ApplicationFolderNameTextBox = Get-TextBoxObject -TextBoxName 'ApplicationFolderName'
        [System.String]$ApplicationFolderName = if ($null -ne $ApplicationFolderNameTextBox) { $ApplicationFolderNameTextBox.Text.Trim() } else { $null }
        if (Test-String -IsEmpty $ApplicationID) {
            Write-Line 'The Application ID is empty. Please generate an Application ID before creating the application folder. No action has been taken.'
            return
        }
        if (Test-String -IsEmpty $ApplicationFolderName) {
            Write-Line 'The Application Folder Name is empty. Please enter a folder name before creating the application folder. No action has been taken.'
            return
        }

        # Detection File is required for distribution detection; confirm with the user before proceeding without one.
        [System.String]$DetectionFilePath = Get-UserSetting -PropertyLeaf 'DetectionfileMSI'
        if (Test-String -IsEmpty $DetectionFilePath) {
            [System.String]$DetectionFileWarningBody = "The Detection file / MSI field is empty.`n`nDo you want to continue creating the application folder WITHOUT a detection file?"
            if (-not (Get-UserConfirmation -Title 'Detection File Is Missing' -Body $DetectionFileWarningBody)) {
                Write-Line 'The Detection file / MSI field is empty. Application folder creation was cancelled by the user. No action has been taken.' -Type Warning
                return
            }
        }

        # Shared preparation owns template validation, confirmation, folder creation, and log initialization.
        $Context = New-ApplicationFolderContext -ApplicationID $ApplicationID -ApplicationFolderName $ApplicationFolderName -OutputFolder $OutputFolder
        if ($null -eq $Context) { return }

        [System.String]$MetaDataFilePath = New-ApplicationMetadataArtifact -ApplicationFolderPath $Context.ApplicationFolderPath -SelectedTemplate $Context.SelectedTemplate -ApplicationLog $Context.ApplicationLog
        Export-ApplicationShortcutArtifact -ApplicationFolderPath $Context.ApplicationFolderPath -ApplicationLog $Context.ApplicationLog
        New-ApplicationDocumentArtifact -ApplicationFolderPath $Context.ApplicationFolderPath -SelectedTemplate $Context.SelectedTemplate -MetaDataFilePath $MetaDataFilePath -ApplicationLog $Context.ApplicationLog
        Export-ApplicationRegistryArtifact -ApplicationFolderPath $Context.ApplicationFolderPath -SelectedTemplate $Context.SelectedTemplate -ApplicationLog $Context.ApplicationLog
        New-ApplicationAppLockerArtifacts -ApplicationID $Context.ApplicationID -ApplicationFolderPath $Context.ApplicationFolderPath -SelectedTemplate $Context.SelectedTemplate -ApplicationLog $Context.ApplicationLog
        Copy-ApplicationUDFArtifact -ApplicationFolderPath $Context.ApplicationFolderPath -SelectedTemplate $Context.SelectedTemplate -ApplicationLog $Context.ApplicationLog
        # Metadata is the required Desktop Intake artifact; the other exports are conditional on user selections.
        Complete-ApplicationFolderContext -Context $Context -RequiredFilePaths @($MetaDataFilePath)
    }
    catch {
        Remove-ApplicationFolderContextStaging -Context $Context
        Write-ErrorReport -ErrorRecord $_
    }
}

### END OF FUNCTION
####################################################################################################
