####################################################################################################
<#
.SYNOPSIS
    Presents normalized customer template information.
.DESCRIPTION
    Provides shared host output for customer templates selected from management ListViews or
    intake controls.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.6.0
    Author          : Imraan Iotana
    Creation Date   : August 2026
    Last Update     : September 2026
#>
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Writes customer template information to the host.
.DESCRIPTION
    Writes normalized identity, source, schema, storage, Intake artifact, and content summary
    information for a discovered customer template object.
.EXAMPLE
    Write-CustomerTemplateInformationToHost -CustomerTemplate $SelectedTemplate
    Writes information for the supplied customer template object.
.INPUTS
    [System.Object]
.OUTPUTS
    No objects are returned to the pipeline.
#>
####################################################################################################
function Write-CustomerTemplateInformationToHost {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The discovered customer template object to display.')]
        [System.Object]$CustomerTemplate
    )

    try {
        # VALIDATION - CUSTOMER TEMPLATE
        # Require a discovered customer template with normalized content
        if ($null -eq $CustomerTemplate) {
            Write-Line 'No customer template information is available.' -Type Warning
            return
        }

        [System.Collections.IDictionary]$Content = if ($CustomerTemplate.Content -is [System.Collections.IDictionary]) { $CustomerTemplate.Content } else { @{} }

        # PREPARATION - TEMPLATE METADATA
        # Resolve optional schema, identity, and artifact values for consistent host output
        [System.String]$Schema = if ($Content.Contains('SchemaVersion')) { [System.String]$Content.SchemaVersion } else { 'Legacy' }
        [System.String]$TemplateId = if ($Content.Contains('TemplateId') -and -not [System.String]::IsNullOrWhiteSpace([System.String]$Content.TemplateId)) { [System.String]$Content.TemplateId } else { 'Not defined' }
        [System.String]$TemplateDocument = if ($Content.Contains('TemplateName') -and -not [System.String]::IsNullOrWhiteSpace([System.String]$Content.TemplateName)) { [System.String]$Content.TemplateName } else { 'Not defined' }
        [System.String]$TatTemplateDocument = if ($Content.Contains('TatTemplateName') -and -not [System.String]::IsNullOrWhiteSpace([System.String]$Content.TatTemplateName)) { [System.String]$Content.TatTemplateName } elseif ($Content.Contains('TATTemplateName') -and -not [System.String]::IsNullOrWhiteSpace([System.String]$Content.TATTemplateName)) { [System.String]$Content.TATTemplateName } else { 'Not defined' }
        [System.String]$UDFPackage = if ($Content.Contains('UDFName') -and -not [System.String]::IsNullOrWhiteSpace([System.String]$Content.UDFName)) { [System.String]$Content.UDFName } else { 'Not defined' }
        [System.String]$ReadOnly = if ([System.Boolean]$CustomerTemplate.IsReadOnly) { 'Yes' } else { 'No' }

        # PREPARATION - CONTENT COUNTS
        # Count the normalized themed settings available to Intake consumers
        [System.Collections.IDictionary]$ApplicationFolders = if ($Content.Contains('ApplicationFolderSubFolders') -and ($Content.ApplicationFolderSubFolders -is [System.Collections.IDictionary])) { $Content.ApplicationFolderSubFolders } else { @{} }
        [System.Collections.IDictionary]$AppLockerSettings = if ($Content.Contains('AppLockerDefaultSettings') -and ($Content.AppLockerDefaultSettings -is [System.Collections.IDictionary])) { $Content.AppLockerDefaultSettings } else { @{} }
        [System.Collections.IDictionary]$MailTemplates = if ($Content.Contains('MailTemplates') -and ($Content.MailTemplates -is [System.Collections.IDictionary])) { $Content.MailTemplates } else { @{} }

        # OUTPUT - CUSTOMER TEMPLATE
        # Write the discovered template identity and storage information
        Write-Line ''
        Write-Line 'CUSTOMER TEMPLATE' -Type Special
        Write-Line ("Identity`t`t: {0}" -f [System.String]$CustomerTemplate.Identity)
        Write-Line ("Source`t`t`t: {0}" -f [System.String]$CustomerTemplate.Source)
        Write-Line ("Schema`t`t`t: {0}" -f $Schema)
        Write-Line ("Template ID`t`t: {0}" -f $TemplateId)
        Write-Line ("Read Only`t`t: {0}" -f $ReadOnly)
        Write-Line ("Manifest`t`t: {0}" -f [System.String]$CustomerTemplate.TemplatePath)
        Write-Line ("Folder`t`t`t: {0}" -f [System.String]$CustomerTemplate.Directory)

        # OUTPUT - INTAKE CONTENT
        # Write the configured Intake artifacts and normalized themed content counts
        Write-Line ''
        Write-Line 'INTAKE CONTENT' -Type Special
        Write-Line ("Template Document`t: {0}" -f $TemplateDocument)
        Write-Line ("TAT Document`t`t: {0}" -f $TatTemplateDocument)
        Write-Line ("UDF Package`t`t: {0}" -f $UDFPackage)
        Write-Line ("Application Folders`t: {0}" -f $ApplicationFolders.Count)
        Write-Line ("AppLocker Settings`t: {0}" -f $AppLockerSettings.Count)
        Write-Line ("Mail Templates`t`t: {0}" -f $MailTemplates.Count)

        # OUTPUT - APPLICATION FOLDERS
        # Write the configured application-folder mappings in their destination order
        if ($ApplicationFolders.Count -gt 0) {
            Write-Line ''
            Write-Line 'APPLICATION FOLDERS' -Type Special
            $ApplicationFolders.GetEnumerator() |
                Sort-Object -Property Value |
                Format-Table -Property Name, Value -AutoSize |
                Out-String |
                Write-Host
        }

        Write-Line '-------------------- End of customer template information --------------------' -Type Success
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
    Writes information for the selected customer template to the host.
.DESCRIPTION
    Resolves the selected customer template object from the inventory ListView and delegates its
    normalized presentation to the shared customer template information helper.
.EXAMPLE
    Write-SelectedCustomerTemplateInformation -ListView $CustomerTemplateListView
    Writes information for the selected customer template row.
.INPUTS
    [System.Windows.Forms.ListView]
.OUTPUTS
    No objects are returned to the pipeline.
#>
####################################################################################################
function Write-SelectedCustomerTemplateInformation {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The customer template inventory ListView.')]
        [System.Windows.Forms.ListView]$ListView
    )

    try {
        # VALIDATION - LISTVIEW SELECTION
        # Require one selected row containing a discovered customer template object
        if (($null -eq $ListView.SelectedItems) -or ($ListView.SelectedItems.Count -ne 1) -or ($null -eq $ListView.SelectedItems[0].Tag)) {
            Write-Line 'Select one customer template to show its information.' -Type Warning
            return
        }

        # EXECUTION - CUSTOMER TEMPLATE INFORMATION
        # Write the selected template through the shared normalized presenter
        Write-CustomerTemplateInformationToHost -CustomerTemplate $ListView.SelectedItems[0].Tag
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}

### END OF FUNCTION
####################################################################################################