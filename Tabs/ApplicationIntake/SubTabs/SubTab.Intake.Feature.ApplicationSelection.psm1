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
    Last Update     : May 2026
#>
####################################################################################################
function Import-FeatureIntakeApplicationSelection {
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
            Title           = 'APPLICATION SELECTION'
            Color           = $Color
            NumberOfRows    = 2
        }
        # If the GroupBoxAbove parameter is provided, set the GroupBoxAbove property
        if ($PSBoundParameters.ContainsKey('GroupBoxAbove')) { $FeatureProperties.GroupBoxAbove = $GroupBoxAbove }
        # Create the GroupBox
        [System.Windows.Forms.GroupBox]$FeatureGroupBox = New-GroupBox @FeatureProperties -OnSubTab

        # EXECUTION - COMBOBOXES
        # Set the ComboBox properties
        [System.Collections.Hashtable]$SelectedApplicationComboBoxProperties = @{
            RowNumber                   = 1
            Label                       = 'Import from Registry'
            PropertyName                = 'SubTab.Intake.SelectedApplicationFromRegistry'
            ToolTip                     = 'The name of the application to intake'
            SizeType                    = 'Medium'
            ApplicationsFromRegistry    = Get-InstalledApplicationsFromRegistry
        }
        # Create the ComboBoxes
        [System.Windows.Forms.ComboBox]$SelectedApplicationComboBox = New-ComboBox @SelectedApplicationComboBoxProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ReturnComboBox

        # EXECUTION - BUTTONS
        # Set the Import Button properties
        [System.Collections.Hashtable[]]$ImportButtonPropertiesArray = @(
            @{
                ColumnNumber    = 1
                Text            = 'Import'
                PNGFileName     = 'download_for_windows'
                SizeType        = 'Medium'
                ToolTip         = 'Import the selected application from the registry.'
                Function        = { Import-SelectedApplicationToIntake -SelectedApplication $SelectedApplicationComboBox.SelectedItem }.GetNewClosure()
            }
            @{
                ColumnNumber    = 5
                Text            = 'Refresh'
                PNGFileName     = 'arrow_refresh'
                SizeType        = 'Medium'
                ToolTip         = 'Refresh the list of applications from the registry.'
                Function        = { Update-ComboBox -ComboBox $SelectedApplicationComboBox -ApplicationsFromRegistry (Get-InstalledApplicationsFromRegistry) }.GetNewClosure()
            }
        )
        # Set the Small Buttons properties
        [System.Collections.Hashtable[]]$SmallButtonsPropertiesArray = @(
            @{ # Testing duplicate buttons with the same function to ensure they work as expected
                ColumnNumber    = 5
                Text            = 'Details'
                PNGFileName     = 'information'
                SizeType        = 'Small'
                ToolTip         = 'View details of the selected application.'
                Function        = { $SelectedApplicationComboBox.SelectedItem | Format-List | Out-String | Write-Host }.GetNewClosure()
            }
            @{
                ColumnNumber    = 6
                Text            = 'Show'
                PNGFileName     = 'regedit'
                SizeType        = 'Small'
                ToolTip         = 'Open the registry editor at the selected applications registry path.'
                Function        = { Start-RegistryEditor -Key $SelectedApplicationComboBox.SelectedItem.RegistryPath }.GetNewClosure()
            }
            @{
                ColumnNumber    = 7
                Text            = 'Export'
                PNGFileName     = 'table_export'
                SizeType        = 'Small'
                ToolTip         = 'Export the selected application to a text file.'
                Function        = { Export-RegistryKey -RegistryKeyPath $SelectedApplicationComboBox.SelectedItem.RegistryPath -OpenOutputFolder }.GetNewClosure()
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
