####################################################################################################
<#
.SYNOPSIS
    Imports the DSL Settings sub-tab into the DSL Management tab.
.DESCRIPTION
    This function imports the DSL Settings sub-tab into the DSL Management tab by creating a new TabPage and adding it to the specified parent TabControl.
.EXAMPLE
    Import-SubTabDSLManagementSettings -InputObject $MyApplicationObject -ParentTabControl $MySubTabControl
.INPUTS
    [PSCustomObject]
    [System.Windows.Forms.TabControl]
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.1.0
    Author          : Imraan Iotana
    Creation Date   : July 2026
    Last Update     : August 2026
#>
####################################################################################################
function Import-SubTabDSLManagementSettings {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The ApplicationObject containing the Settings.')]
        [PSCustomObject]$InputObject,

        [Parameter(Mandatory=$true,HelpMessage='The Parent TabControl to which this TabPage will be added.')]
        [System.Windows.Forms.TabControl]$ParentTabControl
    )

    try {
        # PREPARATION - TAB PROPERTIES
        # Tab properties
        [System.Collections.Hashtable]$TabProperties = @{
            ParentTabControl    = $ParentTabControl
            Title               = 'DSL SETTINGS'
            Version             = '6.0.1.0'
            BackGroundColor     = 'SteelBlue'
        }
        # Set the main color for the GroupBoxes in this sub-tab
        [System.String]$MainColor = 'Cyan'

        # EXECUTION - TAB
        # Create the TabPage
        [System.Windows.Forms.TabPage]$ParentTabPage = New-TabPage @TabProperties

        # EXECUTION - FEATURES
        # Import the placeholder Settings feature for future DSL settings controls.
        $null = Import-FeatureDSLManagementSettings -InputObject $InputObject -ParentTabPage $ParentTabPage -Color $MainColor
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
    Imports the Settings feature into the DSL Settings sub-tab.
.DESCRIPTION
    This function creates a placeholder GroupBox for future DSL settings controls.
.EXAMPLE
    Import-FeatureDSLManagementSettings -InputObject $MyApplicationObject -ParentTabPage $MyTabPage
.INPUTS
    [PSCustomObject]
    [System.Windows.Forms.TabPage]
    [System.Windows.Forms.GroupBox]
    [System.String]
.OUTPUTS
    [System.Windows.Forms.GroupBox]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.1.0
    Author          : Imraan Iotana
    Creation Date   : July 2026
    Last Update     : August 2026
#>
####################################################################################################
function Import-FeatureDSLManagementSettings {
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
        # PREPARATION - GROUPBOX PROPERTIES
        # Set the GroupBox properties
        [System.Collections.Hashtable]$GroupBoxProperties = @{
            InputObject     = $InputObject
            ParentTabPage   = $ParentTabPage
            Title           = 'DSL SETTINGS'
            Color           = $Color
            NumberOfRows    = 4
            GroupBoxAbove   = $GroupBoxAbove
        }

        # EXECUTION - GROUPBOX
        # Create the GroupBox
        [System.Windows.Forms.GroupBox]$FeatureGroupBox = New-GroupBox @GroupBoxProperties

        # PREPARATION - TEXTBOXES
        # Set the properties for the Software Library textbox
        [System.Collections.Hashtable]$SoftwareLibraryTextBoxProperties = @{
            RowNumber       = 1
            Label           = 'Software Library (DSL)'
            ToolTip         = 'The path to the Software Library'
            Buttons         = [System.Object[][]]@(@(1,'Browse Folder'), @(2,'Open'), @(3,'Copy'), @(4,'Paste'), @(5,'Clear'))
        }
        # Set the properties for the Software Library Archive textbox
        [System.Collections.Hashtable]$SoftwareLibraryArchiveTextBoxProperties = @{
            RowNumber       = 3
            Label           = 'Software Library Archive'
            ToolTip         = 'The path to the Software Library Archive'
            Buttons         = [System.Object[][]]@(@(1,'Browse Folder'), @(2,'Open'), @(3,'Copy'), @(4,'Paste'), @(5,'Clear'))
        }

        # EXECUTION - TEXTBOXES
        # Create the textboxes in DSL Settings.
        New-TextBox @SoftwareLibraryTextBoxProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox
        New-TextBox @SoftwareLibraryArchiveTextBoxProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox

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
