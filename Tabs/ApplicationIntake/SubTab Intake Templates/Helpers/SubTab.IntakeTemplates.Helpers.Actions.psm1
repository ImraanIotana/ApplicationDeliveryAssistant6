####################################################################################################
<#
.SYNOPSIS
    Provides customer template inventory actions.
.DESCRIPTION
    Provides actions performed on customer templates selected in the management inventory.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.3.3
    Author          : Imraan Iotana
    Creation Date   : August 2026
    Last Update     : August 2026
#>
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Opens the folder of the selected customer template.
.DESCRIPTION
    Resolves the selected inventory record from its ListViewItem Tag, validates the customer
    template directory, and opens it through the shared Open-Folder helper.
.EXAMPLE
    Open-SelectedCustomerTemplateFolder -ListView $CustomerTemplateListView
    Opens the folder belonging to the selected customer template row.
.INPUTS
    [System.Windows.Forms.ListView]
.OUTPUTS
    No objects are returned to the pipeline.
#>
####################################################################################################
function Open-SelectedCustomerTemplateFolder {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The customer template inventory ListView.')]
        [System.Windows.Forms.ListView]$ListView
    )

    try {
        # PREPARATION - TEMPLATE DIRECTORY
        # Resolve the Directory property from the selected inventory record
        [System.String]$TemplateDirectory = Get-SelectedListViewItemPath -ListView $ListView -PathPropertyName 'Directory' -ItemName 'customer template'
        if ([System.String]::IsNullOrWhiteSpace($TemplateDirectory)) { return }

        # VALIDATION - TEMPLATE DIRECTORY
        # Stop when the selected customer template folder is missing or unavailable
        if ([System.String]::IsNullOrWhiteSpace($TemplateDirectory) -or (-not (Test-Path -LiteralPath $TemplateDirectory -PathType Container))) {
            Write-Line "The selected customer template folder could not be found or reached. ($TemplateDirectory)" -Type Warning
            return
        }

        # EXECUTION - OPEN THE TEMPLATE DIRECTORY
        # Open the selected customer template directory in File Explorer
        Open-Folder -Path $TemplateDirectory
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
    Removes the selected user customer template.
.DESCRIPTION
    Validates that the selected template is user-owned and stored below the roaming Customer
    Templates root, then delegates confirmation and Recycle Bin deletion to Remove-WithGUI.
.EXAMPLE
    Remove-SelectedCustomerTemplate -ListView $CustomerTemplateListView
    Confirms and removes the selected user customer template folder, then refreshes the inventory.
.INPUTS
    [System.Windows.Forms.ListView]
.OUTPUTS
    No objects are returned to the pipeline.
#>
####################################################################################################
function Remove-SelectedCustomerTemplate {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The customer template inventory ListView.')]
        [System.Windows.Forms.ListView]$ListView
    )

    try {
        # VALIDATION - LISTVIEW SELECTION
        # Require one selected row containing a discovered customer template object
        if (($null -eq $ListView.SelectedItems) -or ($ListView.SelectedItems.Count -ne 1) -or ($null -eq $ListView.SelectedItems[0].Tag)) {
            Write-Line 'Select one customer template to delete.' -Type Warning
            return
        }

        # PREPARATION - CUSTOMER TEMPLATE
        # Resolve the selected template and its full folder path
        [System.Object]$CustomerTemplate = $ListView.SelectedItems[0].Tag
        if ([System.String]::IsNullOrWhiteSpace([System.String]$CustomerTemplate.Directory)) {
            Write-Line 'The selected customer template does not contain a folder path.' -Type Warning
            return
        }
        [System.String]$TemplateDirectory = [System.IO.Path]::GetFullPath([System.String]$CustomerTemplate.Directory).TrimEnd([System.IO.Path]::DirectorySeparatorChar,[System.IO.Path]::AltDirectorySeparatorChar)

        # VALIDATION - TEMPLATE OWNERSHIP
        # Built-in templates are application content and must never be removed from this interface
        if (($CustomerTemplate.Source -ne 'User') -or [System.Boolean]$CustomerTemplate.IsReadOnly) {
            Write-Line 'Built-in customer templates cannot be deleted.' -Type Warning
            return
        }

        # PREPARATION - ROAMING STORAGE BOUNDARY
        # Resolve the canonical roaming root used for user customer templates
        [System.String]$CustomerTemplatesRoot = [System.IO.Path]::GetFullPath([System.String](Get-CustomerTemplateStoragePaths).CustomerTemplatesRoot).TrimEnd([System.IO.Path]::DirectorySeparatorChar,[System.IO.Path]::AltDirectorySeparatorChar)
        [System.String]$CustomerTemplatesRootPrefix = $CustomerTemplatesRoot + [System.IO.Path]::DirectorySeparatorChar

        # VALIDATION - ROAMING STORAGE BOUNDARY
        # Require a child folder below the roaming root and never allow deletion of the root itself
        if (($TemplateDirectory -eq $CustomerTemplatesRoot) -or (-not $TemplateDirectory.StartsWith($CustomerTemplatesRootPrefix,[System.StringComparison]::OrdinalIgnoreCase))) {
            Write-Line "The selected customer template is outside the roaming Customer Templates folder and cannot be deleted. ($TemplateDirectory)" -Type Warning
            return
        }
        if (-not (Test-Path -LiteralPath $TemplateDirectory -PathType Container)) {
            Write-Line "The selected customer template folder could not be found or reached. ($TemplateDirectory)" -Type Warning
            return
        }

        # EXECUTION - REMOVE THE TEMPLATE FOLDER
        # Show the shared confirmation and move the complete user template bundle to the Recycle Bin
        Remove-WithGUI -Path $TemplateDirectory -OutHost

        # POST-EXECUTION - REFRESH THE INVENTORY
        # Reload the inventory whether deletion was confirmed or cancelled
        Update-CustomerTemplateListView -ListView $ListView
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}

### END OF FUNCTION
####################################################################################################