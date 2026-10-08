####################################################################################################
<#
.SYNOPSIS
    Resolves a control owned by the Custom Application sub-tab.
.OUTPUTS
    A WinForms control when found; otherwise null.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.3.4
    Author          : Imraan Iotana
    Creation Date   : August 2026
    Last Update     : August 2026
#>
####################################################################################################
function Get-CustomApplicationControl {
    [CmdletBinding()]
    [OutputType([System.Windows.Forms.Control])]
    param (
        [Parameter(Mandatory=$true)]
        [ValidateSet('TextBoxes','ComboBoxes')]
        [System.String]$CollectionName,

        [Parameter(Mandatory=$true)]
        [System.String]$SectionName,

        [Parameter(Mandatory=$true)]
        [System.String]$ControlName
    )

    # VALIDATION - GRAPHICS COLLECTION
    if ($Global:Graphics -isnot [System.Collections.IDictionary] -or
        -not $Global:Graphics.ContainsKey($CollectionName)) {
        return $null
    }

    # PREPARATION - SCOPED ROOT
    [System.Object]$Collection = $Global:Graphics[$CollectionName]
    [System.String]$RootKey = "applicationintake.customapplication.$SectionName"
    if ($Collection -isnot [System.Collections.IDictionary] -or -not $Collection.ContainsKey($RootKey)) {
        return $null
    }

    # OUTPUT - MATCHED CONTROL
    [System.Object]$Section = $Collection[$RootKey]
    if ($Section -is [System.Collections.IDictionary] -and $Section.ContainsKey($ControlName)) {
        return $Section[$ControlName]
    }

    return $null
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Captures the current Custom Application form as plain values.
.DESCRIPTION
    Reads only controls registered under the Custom Application flattened graphics roots so sibling Desktop Application controls cannot be selected accidentally.
.OUTPUTS
    [PSCustomObject]
#>
####################################################################################################
function Get-CustomApplicationFormData {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param ()

    # PREPARATION - SCOPED CONTROLS
    [System.Windows.Forms.ComboBox]$ApplicationType = Get-CustomApplicationControl -CollectionName ComboBoxes -SectionName applicationtype -ControlName ApplicationType
    [System.Windows.Forms.TextBox]$ApplicationName = Get-CustomApplicationControl -CollectionName TextBoxes -SectionName applicationidentity -ControlName ApplicationName
    [System.Windows.Forms.TextBox]$VendorPublisher = Get-CustomApplicationControl -CollectionName TextBoxes -SectionName applicationidentity -ControlName VendorPublisher
    [System.Windows.Forms.ComboBox]$ApplicationVersion = Get-CustomApplicationControl -CollectionName ComboBoxes -SectionName applicationidentity -ControlName ApplicationVersion
    [System.Windows.Forms.ComboBox]$ApplicationExecutable = Get-CustomApplicationControl -CollectionName ComboBoxes -SectionName applicationexecutable -ControlName ApplicationExecutable
    [System.Windows.Forms.TextBox]$ApplicationParameter = Get-CustomApplicationControl -CollectionName TextBoxes -SectionName applicationexecutable -ControlName ApplicationParameter
    [System.Windows.Forms.TextBox]$AdditionalArguments = Get-CustomApplicationControl -CollectionName TextBoxes -SectionName applicationexecutable -ControlName AdditionalArguments
    [System.Windows.Forms.TextBox]$ApplicationIcon = Get-CustomApplicationControl -CollectionName TextBoxes -SectionName applicationexecutable -ControlName ApplicationIconOptional
    [System.Windows.Forms.TextBox]$ApplicationID = Get-CustomApplicationControl -CollectionName TextBoxes -SectionName applicationid -ControlName ApplicationID
    [System.String]$ApplicationVersionValue = if (($null -eq $ApplicationVersion) -or ($ApplicationVersion.Text -in @('(No Version)','Provider managed'))) { '' } else { [System.String]$ApplicationVersion.Text }

    # OUTPUT - PLAIN FORM VALUES
    return [PSCustomObject][ordered]@{
        ApplicationType       = if ($null -ne $ApplicationType) { [System.String]$ApplicationType.Text } else { '' }
        ApplicationName       = if ($null -ne $ApplicationName) { [System.String]$ApplicationName.Text } else { '' }
        VendorPublisher       = if ($null -ne $VendorPublisher) { [System.String]$VendorPublisher.Text } else { '' }
        ApplicationVersion    = $ApplicationVersionValue
        ApplicationExecutable = if ($null -ne $ApplicationExecutable) { [System.String]$ApplicationExecutable.Text } else { '' }
        ApplicationParameter  = if ($null -ne $ApplicationParameter) { [System.String]$ApplicationParameter.Text } else { '' }
        AdditionalArguments   = if ($null -ne $AdditionalArguments) { [System.String]$AdditionalArguments.Text } else { '' }
        ApplicationIcon       = if ($null -ne $ApplicationIcon) { [System.String]$ApplicationIcon.Text } else { '' }
        ApplicationID         = if ($null -ne $ApplicationID) { [System.String]$ApplicationID.Text } else { '' }
        ApplicationIDTextBox  = $ApplicationID
    }
}

### END OF FUNCTION
####################################################################################################