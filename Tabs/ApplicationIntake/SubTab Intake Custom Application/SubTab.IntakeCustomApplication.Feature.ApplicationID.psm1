####################################################################################################
<#
.SYNOPSIS
    Imports the Application ID feature into the Custom Application sub-tab.
.DESCRIPTION
    This function creates the Application ID GroupBox with an output field and the initial workflow buttons.
.EXAMPLE
    Import-FeatureCustomApplicationID -InputObject $MyApplicationObject -ParentTabPage $MyTabPage
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
function Import-FeatureCustomApplicationID {
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
        # Match the two-row Application ID layout used by Desktop Application.
        [System.Collections.Hashtable]$GroupBoxProperties = @{
            InputObject   = $InputObject
            ParentTabPage = $ParentTabPage
            Title         = 'APPLICATION ID'
            Color         = $Color
            NumberOfRows  = 2
            GroupBoxAbove = $GroupBoxAbove
        }

        # EXECUTION - GROUPBOX
        [System.Windows.Forms.GroupBox]$FeatureGroupBox = New-GroupBox @GroupBoxProperties

        # PREPARATION - TEXTBOX PROPERTIES
        [System.Collections.Hashtable]$ApplicationIDTextBoxProperties = @{
            RowNumber = 2
            Label     = 'Application ID'
            ToolTip   = 'The generated ID of the custom application.'
            SizeType  = 'Medium'
            Type      = 'Output'
        }

        # EXECUTION - TEXTBOX
        [System.Windows.Forms.TextBox]$ApplicationIDTextBox = New-TextBox @ApplicationIDTextBoxProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ReturnTextBox

        # PREPARATION - BUTTON PROPERTIES
        [System.Collections.Hashtable]$ApplicationIDButtonProperties = @{
            ColumnNumber = 1
            RowNumber    = 1
            Text         = 'Application ID'
            PNGFileName  = 'download_for_windows'
            SizeType     = 'Medium'
            ToolTip      = 'Generate the Application ID from the current Custom Application values.'
            Function     = {
                [PSCustomObject]$FormData = Get-CustomApplicationFormData
                $null = Test-CustomApplicationOfficeParameterCompatibility `
                    -ApplicationType $FormData.ApplicationType `
                    -ApplicationExecutable $FormData.ApplicationExecutable `
                    -ApplicationParameter $FormData.ApplicationParameter
                New-CustomApplicationID `
                    -VendorPublisher $FormData.VendorPublisher `
                    -ApplicationName $FormData.ApplicationName `
                    -ApplicationVersion $FormData.ApplicationVersion `
                    -OutputTextBox $ApplicationIDTextBox | Out-Null
            }.GetNewClosure()
        }
        [System.Collections.Hashtable]$CreateFolderButtonProperties = @{
            ColumnNumber = 5
            RowNumber    = 2
            Text         = 'Create Folder'
            PNGFileName  = 'folder_add'
            SizeType     = 'Medium'
            ToolTip      = 'Create the custom application folder and initial artifacts.'
            Function     = { New-CustomApplicationFolder }.GetNewClosure()
        }

        # EXECUTION - BUTTONS
        New-Button @ApplicationIDButtonProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox
        New-Button @CreateFolderButtonProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox

        # POST-EXECUTION
        return $FeatureGroupBox
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}

### END OF FUNCTION
####################################################################################################