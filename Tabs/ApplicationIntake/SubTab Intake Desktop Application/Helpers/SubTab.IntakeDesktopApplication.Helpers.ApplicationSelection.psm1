####################################################################################################
<#
.SYNOPSIS
    Imports selected registry application data into Intake textboxes.
.OUTPUTS
    No objects are returned to the pipeline.
#>
####################################################################################################
function Import-SelectedApplicationToIntakeTextBoxes {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false)]
        [PSCustomObject]$SelectedApplication
    )

    try {
        if ($null -eq $SelectedApplication) {
            Write-Line 'No application selected. Please select an application from the dropdown menu.'
            return
        }

        [System.Collections.Hashtable]$TextBoxes = @{
            FormalVendorName         = Get-TextBoxObject -TextBoxName 'FormalVendorName'
            FormalApplicationName    = Get-TextBoxObject -TextBoxName 'FormalApplicationName'
            FormalApplicationVersion = Get-TextBoxObject -TextBoxName 'FormalApplicationVersion'
            CustomVendorName         = Get-TextBoxObject -TextBoxName 'CustomVendorName'
            CustomApplicationName    = Get-TextBoxObject -TextBoxName 'CustomApplicationName'
            CustomApplicationVersion = Get-TextBoxObject -TextBoxName 'CustomApplicationVersion'
            InstallationFolder       = Get-TextBoxObject -TextBoxName 'InstallationFolder'
        }
        foreach ($TextBox in $TextBoxes.Values) {
            if ($TextBox -isnot [System.Windows.Forms.TextBox]) {
                Write-Line 'Unable to resolve Intake textboxes from Graphics.TextBoxes. Open the Intake tab first and try again.' -Type Error
                return
            }
        }

        Write-Line "Importing application ($($SelectedApplication.DisplayName))..."
        $TextBoxes.FormalVendorName.Text = $SelectedApplication.Publisher
        $TextBoxes.FormalApplicationName.Text = $SelectedApplication.DisplayName
        $TextBoxes.FormalApplicationVersion.Text = $SelectedApplication.DisplayVersion
        $TextBoxes.CustomVendorName.Text = $SelectedApplication.Publisher
        $TextBoxes.CustomApplicationName.Text = $SelectedApplication.DisplayName
        $TextBoxes.CustomApplicationVersion.Text = $SelectedApplication.DisplayVersion
        $TextBoxes.InstallationFolder.Text = $SelectedApplication.InstallLocation
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}

### END OF FUNCTION
####################################################################################################
