####################################################################################################
<#
.SYNOPSIS
    Imports the SCCM Application sub-tab into the SCCM section.
.DESCRIPTION
    This function imports the SCCM Application sub-tab into the SCCM section by creating a new TabPage and adding it to the specified parent TabControl.
.EXAMPLE
    Import-SubTabSCCMApplication -InputObject $MyApplicationObject -ParentTabControl $MySubTabControl -Color 'Yellow'
.INPUTS
    [PSCustomObject]
    [System.Windows.Forms.TabControl]
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.1
    Author          : Imraan Iotana
    Creation Date   : July 2026
    Last Update     : July 2026
#>
####################################################################################################
function Import-SubTabSCCMApplication {
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
            Title               = 'SCCM APPLICATION'
            Version             = '6.0.0.1'
            BackGroundColor     = 'ForestGreen'
        }
        # Set the main color for the GroupBoxes in this sub-tab
        [System.String]$MainColor = 'Yellow'

        # EXECUTION - TAB
        # Create the TabPage
        [System.Windows.Forms.TabPage]$ParentTabPage = New-TabPage @TabProperties

        # EXECUTION - FEATURES
        # Import the Features
        $null = Import-FeatureSCCMApplication -InputObject $InputObject -ParentTabPage $ParentTabPage -Color $MainColor
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
    Imports the SCCM Application feature into the SCCM Application sub-tab.
.DESCRIPTION
    This function imports the SCCM Application feature by creating a GroupBox with an Application ID ComboBox and Check/Create/Delete action buttons.
.EXAMPLE
    Import-FeatureSCCMApplication -InputObject $MyApplicationObject -ParentTabPage $MyTabPage
.INPUTS
    [PSCustomObject]
    [System.Windows.Forms.TabPage]
    [System.Windows.Forms.GroupBox]
    [System.String]
.OUTPUTS
    [System.Windows.Forms.GroupBox]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.1
    Author          : Imraan Iotana
    Creation Date   : July 2026
    Last Update     : July 2026
#>
####################################################################################################
function Import-FeatureSCCMApplication {
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
            Title           = 'SCCM APPLICATION'
            Color           = $Color
            NumberOfRows    = 4
            GroupBoxAbove   = $GroupBoxAbove
        }

        # EXECUTION - GROUPBOX
        # Create the GroupBox
        [System.Windows.Forms.GroupBox]$FeatureGroupBox = New-GroupBox @GroupBoxProperties

        # PREPARATION - COMBOBOX PROPERTIES
        # Set the Application ID ComboBox properties
        [System.Collections.Hashtable]$ApplicationIDComboBoxProperties = @{
            RowNumber          = 1
            Label              = 'Application ID'
            ToolTip            = 'Select or type the Application ID to manage in SCCM.'
            SizeType           = 'Medium'
            Type               = 'Input'
            ContentStringArray = Get-DSLDirectSubFolderNames
            SmallButtons       = @(@(5,'Copy'),@(6,'Paste'),@(7,'Clear'))
        }

        # EXECUTION - INPUT CONTROLS
        # Create the Application ID ComboBox
        [System.Windows.Forms.ComboBox]$ApplicationIDComboBox = New-ComboBox @ApplicationIDComboBoxProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ReturnComboBox

        # PREPARATION - BUTTON PROPERTIES
        # Set the action button properties
        [System.Collections.Hashtable[]]$ActionButtons = @(
            @{
                ColumnNumber    = 1
                Text            = 'Check Application'
                PNGFileName     = 'package'
                SizeType        = 'Large'
                ToolTip         = 'Check whether the selected application exists in SCCM.'
                Function        = { Test-SCCMApplication -ApplicationID $ApplicationIDComboBox.Text }.GetNewClosure()
            }
            @{
                ColumnNumber    = 3
                Text            = 'Create Application'
                PNGFileName     = 'package_add'
                SizeType        = 'Large'
                ToolTip         = 'Create the selected application in SCCM.'
                Function        = { New-SCCMApplicationStub -ApplicationID $ApplicationIDComboBox.Text }.GetNewClosure()
            }
            @{
                ColumnNumber    = 5
                Text            = 'Delete Application'
                PNGFileName     = 'package_delete'
                SizeType        = 'Large'
                ToolTip         = 'Delete the selected application from SCCM.'
                Function        = { Remove-SCCMApplicationStub -ApplicationID $ApplicationIDComboBox.Text }.GetNewClosure()
            }
        )

        # EXECUTION - BUTTONS
        # Create the Buttons
        New-ButtonLine -InputObject $InputObject -ButtonPropertiesArray $ActionButtons -ParentGroupBox $FeatureGroupBox -RowNumber 3

        # OUTPUT
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
    Checks whether an SCCM application exists for the provided Application ID.
.DESCRIPTION
    Uses SCCM connection settings from the SCCM Settings sub-tab to query SMS_ApplicationLatest in the site namespace.
.EXAMPLE
    Test-SCCMApplication -ApplicationID 'Vendor_Product_1.0'
.INPUTS
    [System.String]
.OUTPUTS
    No objects are returned to the pipeline.
#>
####################################################################################################
function Test-SCCMApplication {
    [CmdletBinding()]
    [OutputType([System.Void])]
    param (
        [Parameter(Mandatory=$false,HelpMessage='The Application ID to check in SCCM.')]
        [AllowNull()][AllowEmptyString()]
        [System.String]$ApplicationID
    )

    try {
        if (-not (Test-String -IsPopulated $ApplicationID)) {
            Write-Line 'Application ID is empty. Please select or enter an Application ID first.' -Type Warning
            return
        }

        [System.Windows.Forms.TextBox]$SiteServerTextBox = Get-TextBoxObject -TextBoxName 'SiteServer'
        [System.Windows.Forms.TextBox]$SiteCodeTextBox = Get-TextBoxObject -TextBoxName 'SiteCode'

        [System.String]$SiteServer = if ($null -ne $SiteServerTextBox) { $SiteServerTextBox.Text } else { '' }
        [System.String]$SiteCode = if ($null -ne $SiteCodeTextBox) { $SiteCodeTextBox.Text } else { '' }

        if (-not (Test-String -IsPopulated $SiteServer) -or -not (Test-String -IsPopulated $SiteCode)) {
            Write-Line 'SCCM Site Server and Site Code must be configured first in SCCM Settings.' -Type Warning
            return
        }

        [System.String]$NormalizedSiteCode = $SiteCode.Trim().ToUpperInvariant()
        [System.String]$SiteNamespace = "root\\sms\\site_$NormalizedSiteCode"
        [System.String]$EscapedApplicationID = $ApplicationID.Replace("'", "''")
        [System.String]$Query = "SELECT CI_ID,LocalizedDisplayName,ModelName,SoftwareVersion FROM SMS_ApplicationLatest WHERE LocalizedDisplayName='$EscapedApplicationID' OR ModelName='$EscapedApplicationID'"

        Write-Line "Checking SCCM for ApplicationID=[$ApplicationID] on [$SiteServer] in [$SiteNamespace]..." -Type Busy
        [System.Object[]]$MatchingApplications = @(Get-CimInstance -ComputerName $SiteServer -Namespace $SiteNamespace -Query $Query -ErrorAction Stop)

        if ($MatchingApplications.Count -gt 0) {
            Write-Line "SCCM application exists. Matches found: [$($MatchingApplications.Count)]." -Type Success
            $MatchingApplications |
                Select-Object -Property CI_ID,LocalizedDisplayName,ModelName,SoftwareVersion |
                Format-Table -AutoSize |
                Out-Host
        }
        else {
            Write-Line "No SCCM application found for ApplicationID=[$ApplicationID]." -Type Warning
        }
    }
    catch {
        Write-Line "Failed to check SCCM application for ApplicationID=[$ApplicationID]." -Type Error
        Write-ErrorReport -ErrorRecord $_
    }
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Creates an SCCM application for the provided Application ID.
.DESCRIPTION
    Placeholder action for Create button. It validates input and reports the intended operation.
.EXAMPLE
    New-SCCMApplicationStub -ApplicationID 'Vendor_Product_1.0'
.INPUTS
    [System.String]
.OUTPUTS
    No objects are returned to the pipeline.
#>
####################################################################################################
function New-SCCMApplicationStub {
    [CmdletBinding()]
    [OutputType([System.Void])]
    param (
        [Parameter(Mandatory=$false,HelpMessage='The Application ID to create in SCCM.')]
        [AllowNull()][AllowEmptyString()]
        [System.String]$ApplicationID
    )

    try {
        if (-not (Test-String -IsPopulated $ApplicationID)) {
            Write-Line 'Application ID is empty. Please select or enter an Application ID first.' -Type Warning
            return
        }

        Write-Line "Create requested for SCCM ApplicationID=[$ApplicationID]." -Type Info
        Write-Line 'Create action is currently a placeholder. Implement the SCCM create workflow here.' -Type Warning
    }
    catch {
        Write-Line "Failed during Create action for ApplicationID=[$ApplicationID]." -Type Error
        Write-ErrorReport -ErrorRecord $_
    }
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Deletes an SCCM application for the provided Application ID.
.DESCRIPTION
    Placeholder action for Delete button. It validates input and reports the intended operation.
.EXAMPLE
    Remove-SCCMApplicationStub -ApplicationID 'Vendor_Product_1.0'
.INPUTS
    [System.String]
.OUTPUTS
    No objects are returned to the pipeline.
#>
####################################################################################################
function Remove-SCCMApplicationStub {
    [CmdletBinding()]
    [OutputType([System.Void])]
    param (
        [Parameter(Mandatory=$false,HelpMessage='The Application ID to delete from SCCM.')]
        [AllowNull()][AllowEmptyString()]
        [System.String]$ApplicationID
    )

    try {
        if (-not (Test-String -IsPopulated $ApplicationID)) {
            Write-Line 'Application ID is empty. Please select or enter an Application ID first.' -Type Warning
            return
        }

        Write-Line "Delete requested for SCCM ApplicationID=[$ApplicationID]." -Type Info
        Write-Line 'Delete action is currently a placeholder. Implement the SCCM delete workflow here.' -Type Warning
    }
    catch {
        Write-Line "Failed during Delete action for ApplicationID=[$ApplicationID]." -Type Error
        Write-ErrorReport -ErrorRecord $_
    }
}

### END OF FUNCTION
####################################################################################################
