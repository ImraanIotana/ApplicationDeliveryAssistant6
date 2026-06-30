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
    [System.String]
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
            GroupBoxAbove   = $GroupBoxAbove
        }
        # Create the GroupBox
        [System.Windows.Forms.GroupBox]$FeatureGroupBox = New-GroupBox @FeatureProperties -OnSubTab

        # PREPARATION - COMBOBOXES
        # Derive the subkeys for the TextBoxes and ComboBoxes from the current tab
        [System.String]$SubKeyForBoxes = New-SubKeyForBoxes -ParentTabPage $ParentTabPage -PassThru

        # EXECUTION - COMBOBOXES
        # Set the ComboBox properties
        [System.Collections.Hashtable]$InstalledApplicationsComboBoxProperties = @{
            RowNumber                   = 1
            Label                       = 'Import from Registry'
            PropertyName                = "ComboBoxes.$SubKeyForBoxes.InstalledApplications"
            ToolTip                     = 'The list of installed applications to select from and import into the intake form.'
            SizeType                    = 'Medium'
            ApplicationsFromRegistry    = Get-InstalledApplicationsFromRegistry
        }
        # Create the ComboBox
        [System.Windows.Forms.ComboBox]$InstalledApplicationsComboBox = New-ComboBox @InstalledApplicationsComboBoxProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ReturnComboBox
        $Global:Graphics.ComboBoxes.$SubKeyForBoxes.InstalledApplications = $InstalledApplicationsComboBox

        # EXECUTION - BUTTONS
        # Set the Import Button properties
        [System.Collections.Hashtable[]]$ImportButtonPropertiesArray = @(
            @{
                ColumnNumber    = 1
                Text            = 'Import'
                PNGFileName     = 'download_for_windows'
                SizeType        = 'Medium'
                ToolTip         = 'Import the selected application from the registry.'
                Function        = { Import-SelectedApplicationToIntakeTextBoxes -SelectedApplication $InstalledApplicationsComboBox.SelectedItem }.GetNewClosure()
            }
            @{
                ColumnNumber    = 5
                Text            = 'Refresh'
                PNGFileName     = 'arrow_refresh'
                SizeType        = 'Small'
                ToolTip         = 'Refresh the list of applications from the registry.'
                Function        = {
                    Update-ComboBox -ComboBox $InstalledApplicationsComboBox -ApplicationsFromRegistry (Get-InstalledApplicationsFromRegistry)
                    Update-ComboBox -ComboBox $Global:Graphics.ComboBoxes[$SubKeyForBoxes].ApplicationShortcuts -Shortcuts (Get-Shortcuts -IncludeInternetShortcuts)
                }.GetNewClosure()
            }
            @{
                ColumnNumber    = 7
                Text            = 'Clear All Fields'
                PNGFileName     = 'textfield_delete'
                SizeType        = 'Small'
                ToolTip         = 'Clear all fields.'
                Function        = {
                    if (-not(Get-UserConfirmation -Title 'Clear All Fields' -Body "This will clear ALL fields in the intake form.`n`nAre you sure you want to continue?")) { return }
                    Clear-IntakeFormFields
                }.GetNewClosure()
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
                Function        = { $InstalledApplicationsComboBox.SelectedItem | Format-List | Out-String | Write-Host }.GetNewClosure()
            }
            @{
                ColumnNumber    = 6
                Text            = 'Show'
                PNGFileName     = 'regedit'
                SizeType        = 'Small'
                ToolTip         = 'Open the registry editor at the selected applications registry path.'
                Function        = { Start-RegistryEditor -Key $InstalledApplicationsComboBox.SelectedItem.RegistryPath }.GetNewClosure()
            }
            @{
                ColumnNumber    = 7
                Text            = 'Export'
                PNGFileName     = 'table_export'
                SizeType        = 'Small'
                ToolTip         = 'Export the selected application to a text file.'
                Function        = { Export-RegistryKey -RegistryKeyPath $InstalledApplicationsComboBox.SelectedItem.RegistryPath -OpenOutputFolder }.GetNewClosure()
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
    Import-SelectedApplicationToIntakeTextBoxes -SelectedApplication $SelectedApplication
.INPUTS
    [PSCustomObject]
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. All rights reserved.
    Version         : 6.0.0.0
    Author          : Imraan Iotana
    Creation Date   : June 2026
    Last Update     : June 2026
#>
####################################################################################################
function Import-SelectedApplicationToIntakeTextBoxes {
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
    # Resolve formal/custom sections from flattened keys first, then fallback to legacy nested paths.
    [System.Object]$FormalSection = $null
    [System.Object]$CustomSection = $null
    [System.Object]$SecuritySection = $null

    foreach ($Key in $Global:Graphics.TextBoxes.Keys) {
        [System.Object]$Section = $Global:Graphics.TextBoxes[$Key]
        if ($null -eq $Section -or $Section -isnot [System.Collections.IDictionary]) { continue }

        if ($Section.ContainsKey('FormalProperties') -and $null -eq $FormalSection) {
            $FormalSection = $Section.FormalProperties
        }
        if ($Section.ContainsKey('CustomProperties') -and $null -eq $CustomSection) {
            $CustomSection = $Section.CustomProperties
        }
        if ($Section.ContainsKey('Security') -and $null -eq $SecuritySection) {
            $SecuritySection = $Section.Security
        }
    }

    if ($null -eq $FormalSection -or $null -eq $CustomSection -or $null -eq $SecuritySection) {
        if ($Global:Graphics.TextBoxes.ContainsKey('ApplicationIntake') -and $Global:Graphics.TextBoxes.ApplicationIntake -is [System.Collections.IDictionary]) {
            [System.String]$FormalPropertiesKey = 'FormalApplicationProperties'
            if (-not $Global:Graphics.TextBoxes.ApplicationIntake.ContainsKey($FormalPropertiesKey)) { $FormalPropertiesKey = 'FormalProperties' }

            if ($null -eq $FormalSection -and $Global:Graphics.TextBoxes.ApplicationIntake.ContainsKey($FormalPropertiesKey)) {
                $FormalSection = $Global:Graphics.TextBoxes.ApplicationIntake.$FormalPropertiesKey
            }
            if ($null -eq $CustomSection -and $Global:Graphics.TextBoxes.ApplicationIntake.ContainsKey('CustomProperties')) {
                $CustomSection = $Global:Graphics.TextBoxes.ApplicationIntake.CustomProperties
            }
            if ($null -eq $SecuritySection -and $Global:Graphics.TextBoxes.ApplicationIntake.ContainsKey('Security')) {
                $SecuritySection = $Global:Graphics.TextBoxes.ApplicationIntake.Security
            }
        }
    }

    if ($null -eq $FormalSection -or $null -eq $CustomSection -or $null -eq $SecuritySection) {
        Write-Line 'Unable to resolve Formal/Custom/Security intake textboxes from Graphics.TextBoxes. Open the Intake tab first and try again.' -Type Error
        return
    }

    # Define the sections to populate
    [System.Object[]]$Sections = @(
        $FormalSection
        $CustomSection
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
    $SecuritySection.InstallationFolder.Text = $SelectedApplication.InstallLocation
}

### END OF FUNCTION
####################################################################################################


function Clear-IntakeFormFields {
    param (
        [Parameter(Mandatory=$false,HelpMessage='The ApplicationObject containing the Settings.')]
        [System.Collections.Hashtable]$GlobalGraphicsObject = $Global:Graphics
    )

    if ($null -eq $GlobalGraphicsObject) {
        Write-Line 'Global Graphics object is null. Nothing to clear.' -Type Warning
        return
    }

    [System.Int32]$ClearedTextBoxes = 0
    [System.Int32]$ClearedComboBoxes = 0

    function Get-TargetIntakeNodes {
        param (
            [Parameter(Mandatory=$true)]
            [System.Collections.IDictionary]$RootNode
        )

        [System.Collections.ArrayList]$TargetNodes = @()

        foreach ($Key in $RootNode.Keys) {
            [System.String]$NormalizedKey = ($Key -replace '\s+', '').ToLowerInvariant()

            if (
                $NormalizedKey -eq 'intake.applicationintake' -or
                $NormalizedKey -eq 'applicationintake.intake' -or
                $NormalizedKey -like 'applicationintake.*' -or
                $NormalizedKey -like 'intake.applicationintake.*'
            ) {
                [void]$TargetNodes.Add($RootNode[$Key])
            }
        }

        if ($RootNode.ContainsKey('ApplicationIntake')) {
            [void]$TargetNodes.Add($RootNode.ApplicationIntake)
        }

        if ($RootNode.ContainsKey('Intake') -and $RootNode.Intake -is [System.Collections.IDictionary] -and $RootNode.Intake.ContainsKey('ApplicationIntake')) {
            [void]$TargetNodes.Add($RootNode.Intake.ApplicationIntake)
        }

        return $TargetNodes
    }

    # Clear textboxes in Intake/ApplicationIntake subtree.
    if ($GlobalGraphicsObject.ContainsKey('TextBoxes') -and $GlobalGraphicsObject.TextBoxes -is [System.Collections.IDictionary]) {
        foreach ($Node in (Get-TargetIntakeNodes -RootNode $GlobalGraphicsObject.TextBoxes)) {
            [System.Collections.Stack]$Stack = New-Object System.Collections.Stack
            $Stack.Push($Node)

            while ($Stack.Count -gt 0) {
                [System.Object]$CurrentNode = $Stack.Pop()
                if ($null -eq $CurrentNode) { continue }

                if ($CurrentNode -is [System.Collections.IDictionary]) {
                    foreach ($ChildKey in $CurrentNode.Keys) {
                        $Stack.Push($CurrentNode[$ChildKey])
                    }
                    continue
                }

                if ($CurrentNode -is [System.Windows.Forms.TextBox]) {
                    Clear-TextBox -TextBox $CurrentNode -Force
                    $ClearedTextBoxes++
                }
            }
        }
    }

    # Clear comboboxes in Intake/ApplicationIntake subtree.
    if ($GlobalGraphicsObject.ContainsKey('ComboBoxes') -and $GlobalGraphicsObject.ComboBoxes -is [System.Collections.IDictionary]) {
        foreach ($Node in (Get-TargetIntakeNodes -RootNode $GlobalGraphicsObject.ComboBoxes)) {
            [System.Collections.Stack]$Stack = New-Object System.Collections.Stack
            $Stack.Push($Node)

            while ($Stack.Count -gt 0) {
                [System.Object]$CurrentNode = $Stack.Pop()
                if ($null -eq $CurrentNode) { continue }

                if ($CurrentNode -is [System.Collections.IDictionary]) {
                    foreach ($ChildKey in $CurrentNode.Keys) {
                        $Stack.Push($CurrentNode[$ChildKey])
                    }
                    continue
                }

                if ($CurrentNode -is [System.Windows.Forms.ComboBox]) {
                    Clear-ComboBox -ComboBox $CurrentNode -Force
                    $ClearedComboBoxes++
                }
            }
        }
    }

    Write-Line "Cleared $ClearedTextBoxes textboxes and $ClearedComboBoxes comboboxes in the Application Intake Form." -Type Info
}