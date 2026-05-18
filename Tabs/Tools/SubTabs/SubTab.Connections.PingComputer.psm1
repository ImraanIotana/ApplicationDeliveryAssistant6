####################################################################################################
<#
.SYNOPSIS
    Imports the Ping Computer feature into the Connections sub-tab.
.DESCRIPTION
    This function imports the Ping Computer feature into the Connections sub-tab by creating a new GroupBox and adding it to the specified parent TabPage.
.EXAMPLE
    Import-FeaturePingComputer -InputObject $MyApplicationObject -ParentTabPage $MyTabPage
.INPUTS
    [PSCustomObject]
    [System.Windows.Forms.TabPage]
.OUTPUTS
    No objects are returned to the pipeline. All output is written to the host.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. All rights reserved.
    Version         : 6.0.0.0
    Author          : Imraan Iotana
    Creation Date   : May 2026
    Last Update     : May 2026
#>
####################################################################################################
function Import-FeaturePingComputer {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The ApplicationObject containing the Settings.')]
        [PSCustomObject]$InputObject,

        [Parameter(Mandatory=$true,HelpMessage='The Parent TabPage to which this Feature will be added.')]
        [System.Windows.Forms.TabPage]$ParentTabPage,

        [Parameter(Mandatory=$false,HelpMessage='The GroupBox above which this Feature will be added.')]
        [System.Windows.Forms.GroupBox]$GroupBoxAbove
    )

    try {
        # PREPARATION - FEATURE PROPERTIES
        # Feature properties
        [System.Collections.Hashtable]$FeatureProperties = @{
            InputObject     = $InputObject
            ParentTabPage   = $ParentTabPage
            Title           = 'PING COMPUTERS'
            Color           = 'White'
            NumberOfRows    = 2
        }
        # If the GroupBoxAbove parameter is provided, set the GroupBoxAbove property
        if ($PSBoundParameters.ContainsKey('GroupBoxAbove')) { $FeatureProperties.GroupBoxAbove = $GroupBoxAbove }

        # PREPARATION - TEXTBOXES
        # Set the TextBox properties
        [System.Collections.Hashtable[]]$TextBoxPropertiesArray = @(
            @{
                RowNumber       = 1
                Label           = 'ComputerName / IP address:'
                PropertyName    = 'SubTab.Connections.Ping.ComputerNameOrIP'
                ToolTip         = 'The name or IP address of the computer to ping'
                Buttons         = [System.Object[][]]@(@(1, 'Copy'), @(2, 'Paste'))
            }
        )

        # PREPARATION - BUTTONS
        # Set the Button properties
        [System.Collections.Hashtable[]]$ButtonPropertiesArray1 = @(
            @{
                ColumnNumber    = 4
                Text            = 'Ping'
                PNGFileName     = 'computer_go'
                SizeType        = 'Medium'
                Function        = {  }
            }
            @{
                ColumnNumber    = 5
                Text            = 'IP Report'
                PNGFileName     = 'report_go'
                SizeType        = 'Medium'
                Function        = {  }
            }
        )


        # EXECUTION
        # Create the GroupBox
        [System.Windows.Forms.GroupBox]$FeatureGroupBox = New-GroupBox @FeatureProperties
        # Create the TextBoxes
        foreach ($TextBoxProperties in $TextBoxPropertiesArray) { New-TextBox @TextBoxProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox }
        # Add the Buttons
        New-ButtonLine -InputObject $InputObject -ButtonPropertiesArray $ButtonPropertiesArray1 -ParentGroupBox $FeatureGroupBox -RowNumber 2
        # Return the GroupBox object
        $FeatureGroupBox
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}

### END OF FUNCTION
####################################################################################################
