####################################################################################################
<#
.SYNOPSIS
    Imports the Application Selection feature into the Intake sub-tab.
.DESCRIPTION
    This function imports the Application Selection feature into the Intake sub-tab by creating a new GroupBox and adding it to the specified parent TabPage.
.EXAMPLE
    Import-FeatureIntakeApplicationSelection -InputObject $MyApplicationObject -ParentTabPage $MyTabPage
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
function Import-FeatureIntakeTemplateSelection {
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
            Title           = 'TEMPLATE SELECTION'
            Color           = $Color
            NumberOfRows    = 2
            GroupBoxAbove   = $GroupBoxAbove
        }
        # Create the GroupBox
        [System.Windows.Forms.GroupBox]$FeatureGroupBox = New-GroupBox @FeatureProperties -OnSubTab

        # EXECUTION - COMBOBOXES
        # Set the ComboBox properties
        [System.Collections.Hashtable]$SelectedApplicationComboBoxProperties = @{
            RowNumber                   = 1
            Label                       = 'Select Customer Template:'
            PropertyName                = 'ComboBoxes.ApplicationIntake.TemplateSelection'
            ToolTip                     = 'The list of customer templates to select from.'
            SizeType                    = 'Medium'
            TextColor                   = $Color
            ApplicationsFromRegistry    = Get-InstalledApplicationsFromRegistry
        }
        # Create the ComboBoxes
        $Global:Graphics.ComboBoxes.ApplicationIntake.TemplateSelection = New-ComboBox @SelectedApplicationComboBoxProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ReturnComboBox

        # EXECUTION - BUTTONS
        # Set the Import Button properties
        [System.Collections.Hashtable[]]$ImportButtonPropertiesArray = @(
            @{
                ColumnNumber    = 1
                Text            = 'Select'
                PNGFileName     = 'page_white_word'
                SizeType        = 'Medium'
                ToolTip         = 'Select the template.'
                Function        = { Write-Line 'This functon is not implemented yet.' }.GetNewClosure()
            }
        )
        # Set the Small Buttons properties
        [System.Collections.Hashtable[]]$SmallButtonsPropertiesArray = @(
            @{ # Testing duplicate buttons with the same function to ensure they work as expected
                ColumnNumber    = 5
                Text            = 'Details'
                PNGFileName     = 'information'
                SizeType        = 'Small'
                ToolTip         = 'View details of the selected template.'
                Function        = { $Global:Graphics.ComboBoxes.ApplicationIntake.TemplateSelection.SelectedItem | Format-List | Out-String | Write-Host }.GetNewClosure()
            }
            @{
                ColumnNumber    = 6
                Text            = 'Show'
                PNGFileName     = 'folder_go'
                SizeType        = 'Small'
                ToolTip         = 'Open the folder containing the templates.'
                Function        = { Write-Line 'This functon is not implemented yet.' }.GetNewClosure()
            }
            @{
                ColumnNumber    = 7
                Text            = 'Refresh'
                PNGFileName     = 'arrow_refresh'
                SizeType        = 'Small'
                ToolTip         = 'Refresh the list of customer templates.'
                Function        = { Write-Line 'This functon is not implemented yet.' }.GetNewClosure()
            }
        )
        # Add the Buttons
        New-ButtonLine -InputObject $InputObject -ButtonPropertiesArray $SmallButtonsPropertiesArray -ParentGroupBox $FeatureGroupBox -RowNumber 1
        New-ButtonLine -InputObject $InputObject -ButtonPropertiesArray $ImportButtonPropertiesArray -ParentGroupBox $FeatureGroupBox -RowNumber 2

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
    Imports the selected registry application data into Intake textboxes.
.DESCRIPTION
    This function populates Application Formal Properties, Custom Properties, and Security fields
    with values from the selected application object.
.EXAMPLE
    Import-SelectedApplicationToIntake -SelectedApplication $SelectedApplication
.INPUTS
    [PSCustomObject]
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
function Import-SelectedApplicationToIntake {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false,HelpMessage='The selected application object from the registry.')]
        [PSCustomObject]$SelectedApplication
    )

    # VALIDATION
    # If SelectedApplication is not provided, throw an error
    if ($null -eq $SelectedApplication) {
        Write-Line 'No application selected. Please select an application from the dropdown menu.' ; return
    }

    # PREPARATION
    # Define the sections to populate
    [System.Object[]]$Sections = @(
        $Global:Graphics.TextBoxes.ApplicationIntake.FormalProperties
        $Global:Graphics.TextBoxes.ApplicationIntake.CustomProperties
    )
    # Set the mapping hashtable
    [System.Collections.Hashtable]$MappingHashtable = @{
        VendorName          = 'Publisher'
        ApplicationName     = 'DisplayName'
        ApplicationVersion  = 'DisplayVersion'
    }

    # EXECUTION
    # Populate the Application Formal Properties and Application Custom Properties sections with the selected application's information from the registry
    Write-Line "Importing application ($($SelectedApplication.DisplayName))..."
    foreach ($Section in $Sections) {
        foreach ($TextBoxName in $MappingHashtable.Keys) {
            [System.String]$SelectedApplicationPropertyName = $MappingHashtable[$TextBoxName]
            $Section.$TextBoxName.Text = $SelectedApplication.$SelectedApplicationPropertyName
        }
    }

    # Populate the Application Security section with the selected application's information from the registry
    $Global:Graphics.TextBoxes.ApplicationIntake.Security.InstallationFolder.Text = $SelectedApplication.InstallLocation
}

### END OF FUNCTION
####################################################################################################
