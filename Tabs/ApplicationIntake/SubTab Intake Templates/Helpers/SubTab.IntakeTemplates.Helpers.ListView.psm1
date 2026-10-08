####################################################################################################
<#
.SYNOPSIS
    Manages the customer template inventory ListView.
.DESCRIPTION
    Provides customer template row population, selection preservation, sorting, and refresh behavior.
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
    Refreshes the customer template inventory ListView.
.DESCRIPTION
    Replaces the current rows with normalized records returned by Get-CustomerTemplates.
.EXAMPLE
    Update-CustomerTemplateListView -ListView $MyListView
.INPUTS
    [System.Windows.Forms.ListView]
.OUTPUTS
    No objects are returned to the pipeline.
#>
####################################################################################################
function Update-CustomerTemplateListView {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The customer template inventory ListView.')]
        [System.Windows.Forms.ListView]$ListView,

        [Parameter(Mandatory=$false,HelpMessage='Optional manifest path to select after the inventory is refreshed.')]
        [System.String]$TemplatePathToSelect
    )

    try {
        if ([System.String]::IsNullOrWhiteSpace($TemplatePathToSelect) -and $ListView.SelectedItems.Count -eq 1 -and $null -ne $ListView.SelectedItems[0].Tag) {
            $TemplatePathToSelect = [System.String]$ListView.SelectedItems[0].Tag.TemplatePath
        }

        [System.Object[]]$CustomerTemplates = @(Get-CustomerTemplates)
        [System.Object]$ActiveCustomerTemplate = Get-ActiveCustomerTemplate
        [System.String]$ActiveTemplatePath = if ($null -ne $ActiveCustomerTemplate) { [System.String]$ActiveCustomerTemplate.TemplatePath } else { '' }

        Invoke-ListViewBatchUpdate -ListView $ListView -Action {
            $ListView.Items.Clear()

            foreach ($CustomerTemplate in $CustomerTemplates) {
                [System.String]$Schema = if (($CustomerTemplate.Content -is [System.Collections.IDictionary]) -and $CustomerTemplate.Content.Contains('SchemaVersion')) { [System.String]$CustomerTemplate.Content.SchemaVersion } else { 'Legacy' }
                [System.Boolean]$IsActive = (Test-String -IsPopulated $ActiveTemplatePath) -and ([System.String]$CustomerTemplate.TemplatePath).Equals($ActiveTemplatePath,[System.StringComparison]::OrdinalIgnoreCase)

                [System.Windows.Forms.ListViewItem]$TemplateItem = New-Object System.Windows.Forms.ListViewItem($(if ($IsActive) { 'Yes' } else { '' }))
                [void]$TemplateItem.SubItems.Add([System.String]$CustomerTemplate.Identity)
                [void]$TemplateItem.SubItems.Add([System.String]$CustomerTemplate.Source)
                [void]$TemplateItem.SubItems.Add([System.String]$CustomerTemplate.Directory)
                [void]$TemplateItem.SubItems.Add($Schema)
                $TemplateItem.Tag = $CustomerTemplate
                if ($IsActive) {
                    $TemplateItem.BackColor = [System.Drawing.Color]::PaleGreen
                    $TemplateItem.ForeColor = [System.Drawing.Color]::DarkGreen
                }
                [void]$ListView.Items.Add($TemplateItem)

                if (-not [System.String]::IsNullOrWhiteSpace($TemplatePathToSelect) -and ([System.String]$CustomerTemplate.TemplatePath).Equals($TemplatePathToSelect,[System.StringComparison]::OrdinalIgnoreCase)) {
                    $TemplateItem.Selected = $true
                    $TemplateItem.Focused = $true
                }
            }

            if (($null -ne $ListView.Tag.PSObject.Properties['CustomerTemplateSortColumn']) -and ([System.Int32]$ListView.Tag.CustomerTemplateSortColumn -ge 0)) {
                $ListView.Sort()
            }
            Set-ListViewColumnAutoSize -ListView $ListView -Mode Widest

            if ($ListView.SelectedItems.Count -eq 1) {
                $ListView.SelectedItems[0].EnsureVisible()
            }
        }
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
function Select-ActiveCustomerTemplate {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The customer template inventory ListView.')]
        [System.Windows.Forms.ListView]$ListView
    )

    if ($ListView.SelectedItems.Count -ne 1 -or $null -eq $ListView.SelectedItems[0].Tag) {
        Write-Line 'Select one customer template to make active.' -Type Warning
        return
    }

    [System.Object]$CustomerTemplate = Set-ActiveCustomerTemplate -CustomerTemplate $ListView.SelectedItems[0].Tag
    if ($null -eq $CustomerTemplate) {
        return
    }

    Update-CustomerTemplateListView -ListView $ListView -TemplatePathToSelect ([System.String]$CustomerTemplate.TemplatePath)

    [System.Windows.Forms.ComboBox]$MailTemplateSelection = Get-ComboBoxObject -ComboBoxName 'MailTemplateSelection'
    if ($null -ne $MailTemplateSelection -and -not $MailTemplateSelection.IsDisposed) {
        Update-ComboBox -ComboBox $MailTemplateSelection -MailTemplates (Get-MailTemplates -SettingsFilePath ([System.String]$CustomerTemplate.TemplatePath))
    }

    Write-Line "Active customer template: $($CustomerTemplate.Identity)" -Type Success
}

### END OF FUNCTION
####################################################################################################