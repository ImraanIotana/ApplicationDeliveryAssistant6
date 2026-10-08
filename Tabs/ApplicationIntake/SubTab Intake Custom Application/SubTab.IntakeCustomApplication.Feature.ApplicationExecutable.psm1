####################################################################################################
<#
.SYNOPSIS
    Imports the Application Executable feature into the Custom Application sub-tab.
.DESCRIPTION
    This function creates the Application Executable GroupBox with persisted executable and parameter inputs plus type-driven application discovery.
.EXAMPLE
    Import-FeatureCustomApplicationExecutable -InputObject $MyApplicationObject -ParentTabPage $MyTabPage
.INPUTS
    [PSCustomObject]
    [System.Windows.Forms.TabPage]
    [System.Windows.Forms.GroupBox]
    [System.String]
.OUTPUTS
    [System.Windows.Forms.GroupBox]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.3.1
    Author          : Imraan Iotana
    Creation Date   : August 2026
    Last Update     : August 2026
#>
####################################################################################################
function Import-FeatureCustomApplicationExecutable {
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
        # Set the Application Executable GroupBox properties.
        [System.Collections.Hashtable]$GroupBoxProperties = @{
            InputObject   = $InputObject
            ParentTabPage = $ParentTabPage
            Title         = 'APPLICATION EXECUTABLE'
            Color         = $Color
            NumberOfRows  = 4.5
            GroupBoxAbove = $GroupBoxAbove
        }

        # EXECUTION - GROUPBOX
        # Create the GroupBox that contains executable selection controls.
        [System.Windows.Forms.GroupBox]$FeatureGroupBox = New-GroupBox @GroupBoxProperties

        # PREPARATION - COMBOBOX PROPERTIES
        # Allow an executable path to be entered manually or selected from discovered browser and Office installations.
        [System.Collections.Hashtable]$ApplicationExecutableComboBoxProperties = @{
            RowNumber    = 1
            Label        = 'Application Executable'
            ToolTip      = 'Enter or select the executable that will launch the custom application.'
            SizeType     = 'Medium'
            Type         = 'Input'
            SmallButtons = @(@(5,'Browse File','Executable'),@(6,'Copy'),@(7,'Paste'))
        }

        # EXECUTION - COMBOBOX
        # Create the editable ComboBox; New-ComboBox registers and persists it automatically.
        [System.Windows.Forms.ComboBox]$ApplicationExecutableComboBox = New-ComboBox @ApplicationExecutableComboBoxProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ReturnComboBox

        # PREPARATION - TEXTBOX PROPERTIES
        # Define the URL, document path, or other target passed to the selected executable.
        [System.Collections.Hashtable]$ApplicationParameterTextBoxProperties = @{
            RowNumber    = 3
            Label        = 'Application Parameter'
            ToolTip      = 'Enter the target passed to the executable, such as a web application URL or an Office document path.'
            SizeType     = 'Medium'
            SmallButtons = @(@(5,'Browse File','Document'),@(6,'Copy'),@(7,'Paste'))
        }

        # EXECUTION - TEXTBOX
        # Create the parameter input; New-TextBox registers and persists it automatically.
        $null = New-TextBox @ApplicationParameterTextBoxProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox

        # PREPARATION - TEXTBOX PROPERTIES
        # Define optional switches that modify how the executable starts.
        [System.Collections.Hashtable]$AdditionalArgumentsTextBoxProperties = @{
            RowNumber    = 4
            Label        = 'Additional Arguments'
            ToolTip      = 'Enter optional command-line switches passed to the executable in addition to the application parameter.'
            SizeType     = 'Medium'
            SmallButtons = @(@(5,'Copy'),@(6,'Paste'))
        }

        # EXECUTION - TEXTBOX
        # Create the optional arguments input; New-TextBox registers and persists it automatically.
        $null = New-TextBox @AdditionalArgumentsTextBoxProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox

        # PREPARATION - TEXTBOX PROPERTIES
        # Allow an optional image or icon file to override icon extraction from the executable.
        [System.Collections.Hashtable]$ApplicationIconTextBoxProperties = @{
            RowNumber    = 5
            Label        = 'Application Icon (Optional)'
            ToolTip      = 'Select an icon for documentation and shortcut creation. When empty, the application executable will be used as the icon source.'
            SizeType     = 'Medium'
            SmallButtons = @(@(5,'Browse File','Icon'),@(6,'Copy'),@(7,'Paste'))
        }

        # EXECUTION - TEXTBOX
        # Create the optional icon input; New-TextBox registers and persists it automatically.
        $null = New-TextBox @ApplicationIconTextBoxProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox

        # PREPARATION - BUTTON PROPERTIES
        # Configure type-driven application discovery.
        [System.Collections.Hashtable]$FindAppsButtonProperties = @{
            ColumnNumber = 1
            RowNumber    = 2
            Text         = 'Find Apps'
            PNGFileName  = 'magnifier'
            SizeType     = 'Medium'
            ToolTip      = 'Find installed applications appropriate for the selected application type.'
            Function     = {
                [System.Windows.Forms.ComboBox]$ApplicationTypeComboBox = Get-ComboBoxObject -ComboBoxName 'ApplicationType'
                if ($null -eq $ApplicationTypeComboBox) {
                    Write-Line 'The Application Type selector is unavailable.' -Type Warning
                    return
                }
                Update-CustomApplicationExecutableCandidates -ApplicationTypeComboBox $ApplicationTypeComboBox -ApplicationExecutableComboBox $ApplicationExecutableComboBox
            }.GetNewClosure()
        }

        # EXECUTION - BUTTONS
        # Create the application discovery button.
        New-Button @FindAppsButtonProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox

        # POST-EXECUTION
        # Return the GroupBox so later features can be positioned underneath it.
        return $FeatureGroupBox
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}

### END OF FUNCTION
####################################################################################################