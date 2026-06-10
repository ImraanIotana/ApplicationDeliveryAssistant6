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
            Function        = { Write-Line "Import-FeatureIntakeApplicationID: This function is still in development." }.GetNewClosure()
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
function New-ApplicationIDFromTextBoxes {
    param (
        [Parameter(Mandatory=$false,HelpMessage='The TextBox to write the Application ID into.')]
        [System.Windows.Forms.TextBox]$OutputTextBox
    )
    
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
            Clear-TextBox -TextBox $OutputTextBox -Force
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

### END OF FUNCTION
####################################################################################################
