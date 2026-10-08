####################################################################################################
<#
.SYNOPSIS
    Generates the Application ID from current Intake values.
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    Version         : 6.5.0
#>
####################################################################################################
function New-ApplicationIDFromTextBoxes {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false,HelpMessage='The TextBox to write the Application ID into.')]
        [System.Windows.Forms.TextBox]$OutputTextBox,

        [Parameter(Mandatory=$false,HelpMessage='The TextBox to write the initial application folder name into.')]
        [System.Windows.Forms.TextBox]$ApplicationFolderNameTextBox
    )

    try {
        [System.String]$ApplicationID = New-ApplicationIDValue `
            -Vendor (Get-UserSetting -PropertyLeaf 'CustomVendorName') `
            -ApplicationName (Get-UserSetting -PropertyLeaf 'CustomApplicationName') `
            -ApplicationVersion (Get-UserSetting -PropertyLeaf 'CustomApplicationVersion')

        if (Test-String -IsEmpty $ApplicationID) {
            if ($null -ne $OutputTextBox) { Clear-TextBox -TextBox $OutputTextBox -Force }
            return
        }

        if ($null -ne $OutputTextBox) { $OutputTextBox.Text = $ApplicationID }
        if ($null -ne $ApplicationFolderNameTextBox) {
            [System.String]$ApplicationFolderPrefix = Get-UserSetting -PropertyName 'TextBoxes.applicationintake.desktopapplication.applicationid.ApplicationFolderPrefix'
            [System.String]$ApplicationFolderPostfix = Get-UserSetting -PropertyName 'TextBoxes.applicationintake.desktopapplication.applicationid.ApplicationFolderPostfix'
            [System.String]$ApplicationFolderSeparator = Get-UserSetting -PropertyName 'TextBoxes.applicationintake.desktopapplication.applicationid.ApplicationFolderSeparator'
            Set-ApplicationFolderNameFromPrefix -ApplicationID $ApplicationID -ApplicationFolderPrefix $ApplicationFolderPrefix -ApplicationFolderPostfix $ApplicationFolderPostfix -ApplicationFolderSeparator $ApplicationFolderSeparator -ApplicationFolderNameTextBox $ApplicationFolderNameTextBox
        }
        Write-Line "Generated Application ID: $ApplicationID" -Type Success
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
    Shows a dialog for configuring optional Application Folder Name affixes.
.NOTES
    Version         : 6.5.0
#>
####################################################################################################
function Show-ApplicationFolderPrefixDialog {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [System.Windows.Forms.TextBox]$ApplicationIDTextBox,

        [Parameter(Mandatory=$true)]
        [System.Windows.Forms.TextBox]$ApplicationFolderNameTextBox,

        [Parameter(Mandatory=$false)]
        [AllowNull()]
        [System.Windows.Forms.IWin32Window]$Owner
    )

    [System.String]$PrefixPropertyName = 'TextBoxes.applicationintake.desktopapplication.applicationid.ApplicationFolderPrefix'
    [System.String]$PostfixPropertyName = 'TextBoxes.applicationintake.desktopapplication.applicationid.ApplicationFolderPostfix'
    [System.String]$SeparatorPropertyName = 'TextBoxes.applicationintake.desktopapplication.applicationid.ApplicationFolderSeparator'
    [System.String]$SavedPrefix = Get-UserSetting -PropertyName $PrefixPropertyName
    [System.String]$SavedPostfix = Get-UserSetting -PropertyName $PostfixPropertyName
    [System.String]$SavedSeparator = Get-UserSetting -PropertyName $SeparatorPropertyName
    if ($null -eq $SavedSeparator) { $SavedSeparator = '_' }
    [System.String[]]$ApplicationFolderPostfixOptions = @('') + @(Get-ApplicationFolderPostfixOptions)
    [PSCustomObject[]]$SeparatorOptions = @(
        [PSCustomObject]@{ Name = '(no separator)'; Value = '' }
        [PSCustomObject]@{ Name = '(space)'; Value = ' ' }
        [PSCustomObject]@{ Name = '_'; Value = '_' }
        [PSCustomObject]@{ Name = '-'; Value = '-' }
        [PSCustomObject]@{ Name = ' - '; Value = ' - ' }
        [PSCustomObject]@{ Name = 'Custom...'; Value = $null }
    )
    [System.Windows.Forms.Form]$Dialog = New-ModalDialog -Title 'Customize Application Folder Name' -ClientWidth 460 -ClientHeight 330 -Owner $Owner
    try {
        [PSCustomObject]$DialogActions = New-ModalDialogActionBar -Dialog $Dialog -PrimaryText 'Save' -PrimaryDialogResult ([System.Windows.Forms.DialogResult]::OK) -ButtonWidth 75 -ButtonHeight 28
        [System.Windows.Forms.Label]$PrefixLabel = New-Object System.Windows.Forms.Label
        [System.Windows.Forms.TextBox]$PrefixTextBox = New-Object System.Windows.Forms.TextBox
        [System.Windows.Forms.Label]$PostfixLabel = New-Object System.Windows.Forms.Label
        [System.Windows.Forms.ComboBox]$PostfixComboBox = New-Object System.Windows.Forms.ComboBox
        [System.Windows.Forms.Label]$SeparatorLabel = New-Object System.Windows.Forms.Label
        [System.Windows.Forms.ComboBox]$SeparatorComboBox = New-Object System.Windows.Forms.ComboBox
        [System.Windows.Forms.Label]$CustomSeparatorLabel = New-Object System.Windows.Forms.Label
        [System.Windows.Forms.TextBox]$CustomSeparatorTextBox = New-Object System.Windows.Forms.TextBox

        $PrefixLabel.Text = 'Folder Name Prefix (optional)'
        $PrefixLabel.Location = New-Object System.Drawing.Point(15,18)
        $PrefixLabel.Size = New-Object System.Drawing.Size(430,24)

        $PrefixTextBox.Text = $SavedPrefix
        $PrefixTextBox.Location = New-Object System.Drawing.Point(15,45)
        $PrefixTextBox.Size = New-Object System.Drawing.Size(430,24)

        $PostfixLabel.Text = 'Folder Name Postfix (optional)'
        $PostfixLabel.Location = New-Object System.Drawing.Point(15,74)
        $PostfixLabel.Size = New-Object System.Drawing.Size(430,24)

        $PostfixComboBox.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
        $PostfixComboBox.Items.AddRange([System.Object[]]$ApplicationFolderPostfixOptions)
        $PostfixComboBox.SelectedIndex = [System.Math]::Max(0,$PostfixComboBox.FindStringExact($SavedPostfix))
        $PostfixComboBox.Location = New-Object System.Drawing.Point(15,101)
        $PostfixComboBox.Size = New-Object System.Drawing.Size(430,24)

        $SeparatorLabel.Text = 'Folder Name Separator'
        $SeparatorLabel.Location = New-Object System.Drawing.Point(15,132)
        $SeparatorLabel.Size = New-Object System.Drawing.Size(430,24)

        $SeparatorComboBox.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
        $SeparatorComboBox.DisplayMember = 'Name'
        $SeparatorComboBox.ValueMember = 'Value'
        $SeparatorComboBox.Items.AddRange([System.Object[]]$SeparatorOptions)
        [System.Int32]$SeparatorIndex = 5
        for ($OptionIndex = 0; $OptionIndex -lt ($SeparatorOptions.Count - 1); $OptionIndex++) {
            if ([System.String]::Equals($SeparatorOptions[$OptionIndex].Value,$SavedSeparator,[System.StringComparison]::Ordinal)) {
                $SeparatorIndex = $OptionIndex
                break
            }
        }
        $SeparatorComboBox.SelectedIndex = $SeparatorIndex
        $SeparatorComboBox.Location = New-Object System.Drawing.Point(15,159)
        $SeparatorComboBox.Size = New-Object System.Drawing.Size(430,24)

        $CustomSeparatorLabel.Text = 'Custom Separator'
        $CustomSeparatorLabel.Location = New-Object System.Drawing.Point(15,194)
        $CustomSeparatorLabel.Size = New-Object System.Drawing.Size(430,24)
        $CustomSeparatorTextBox.Text = if ($SeparatorIndex -eq 5) { $SavedSeparator } else { '' }
        $CustomSeparatorTextBox.Location = New-Object System.Drawing.Point(15,221)
        $CustomSeparatorTextBox.Size = New-Object System.Drawing.Size(430,24)
        [System.Boolean]$ShowCustomSeparator = $SeparatorIndex -eq 5
        $CustomSeparatorLabel.Visible = $ShowCustomSeparator
        $CustomSeparatorTextBox.Visible = $ShowCustomSeparator
        $SeparatorComboBox.Add_SelectedIndexChanged({
            [System.Boolean]$ShowCustomSeparator = $SeparatorComboBox.SelectedIndex -eq 5
            $CustomSeparatorLabel.Visible = $ShowCustomSeparator
            $CustomSeparatorTextBox.Visible = $ShowCustomSeparator
        }.GetNewClosure())

        $Dialog.Controls.AddRange(@($PrefixLabel,$PrefixTextBox,$PostfixLabel,$PostfixComboBox,$SeparatorLabel,$SeparatorComboBox,$CustomSeparatorLabel,$CustomSeparatorTextBox))
        if ((Show-ModalDialog -Dialog $Dialog -Owner $Owner) -eq [System.Windows.Forms.DialogResult]::OK) {
            [System.String]$ApplicationFolderPrefix = $PrefixTextBox.Text.Trim()
            [System.String]$ApplicationFolderPostfix = [System.String]$PostfixComboBox.SelectedItem
            [PSCustomObject]$SelectedSeparator = [PSCustomObject]$SeparatorComboBox.SelectedItem
            [System.String]$ApplicationFolderSeparator = if ($SeparatorComboBox.SelectedIndex -eq 5) { $CustomSeparatorTextBox.Text } else { [System.String]$SelectedSeparator.Value }
            Set-UserSetting -PropertyName $PrefixPropertyName -PropertyValue $ApplicationFolderPrefix
            Set-UserSetting -PropertyName $PostfixPropertyName -PropertyValue $ApplicationFolderPostfix
            Set-UserSetting -PropertyName $SeparatorPropertyName -PropertyValue $ApplicationFolderSeparator
            Set-ApplicationFolderNameFromPrefix -ApplicationID $ApplicationIDTextBox.Text -ApplicationFolderPrefix $ApplicationFolderPrefix -ApplicationFolderPostfix $ApplicationFolderPostfix -ApplicationFolderSeparator $ApplicationFolderSeparator -ApplicationFolderNameTextBox $ApplicationFolderNameTextBox
        }
    }
    finally {
        $Dialog.Dispose()
    }
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Gets Application Folder postfix options from the active customer template.
.NOTES
    Version         : 6.5.0
#>
####################################################################################################
function Get-ApplicationFolderPostfixOptions {
    [CmdletBinding()]
    [OutputType([System.String[]])]
    param ()

    [System.String[]]$DefaultOptions = @('x86','x64')
    [System.Object]$SelectedTemplate = Get-ActiveCustomerTemplate
    [System.Object]$FolderSettings = if ($null -ne $SelectedTemplate) { $SelectedTemplate.ApplicationFolderSubFolders } else { $null }
    [System.Object]$ConfiguredOptions = $null

    if (($FolderSettings -is [System.Collections.IDictionary]) -and $FolderSettings.Contains('ApplicationFolderPostfixOptions')) {
        $ConfiguredOptions = $FolderSettings['ApplicationFolderPostfixOptions']
    }
    elseif (($null -ne $FolderSettings) -and ($null -ne $FolderSettings.PSObject.Properties['ApplicationFolderPostfixOptions'])) {
        $ConfiguredOptions = $FolderSettings.ApplicationFolderPostfixOptions
    }

    [System.String[]]$ResolvedOptions = @($ConfiguredOptions | Where-Object { $_ -is [System.String] } | ForEach-Object { $_.Trim() } | Where-Object { Test-String -IsPopulated $_ } | Select-Object -Unique)
    if ($ResolvedOptions.Count -eq 0) { return $DefaultOptions }
    return $ResolvedOptions
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Applies optional prefix and postfix values to an Application Folder Name textbox.
.NOTES
    Version         : 6.5.0
#>
####################################################################################################
function Set-ApplicationFolderNameFromPrefix {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false)]
        [AllowEmptyString()]
        [System.String]$ApplicationID,

        [Parameter(Mandatory=$false)]
        [AllowEmptyString()]
        [System.String]$ApplicationFolderPrefix,

        [Parameter(Mandatory=$false)]
        [AllowEmptyString()]
        [System.String]$ApplicationFolderPostfix,

        [Parameter(Mandatory=$false)]
        [AllowEmptyString()]
        [System.String]$ApplicationFolderSeparator = '_',

        [Parameter(Mandatory=$true)]
        [System.Windows.Forms.TextBox]$ApplicationFolderNameTextBox
    )

    [System.String]$TrimmedApplicationID = ([System.String]$ApplicationID).Trim()
    [System.String]$TrimmedPrefix = ([System.String]$ApplicationFolderPrefix).Trim()
    [System.String]$TrimmedPostfix = ([System.String]$ApplicationFolderPostfix).Trim()
    if (Test-String -IsEmpty $TrimmedApplicationID) { return }

    [System.String[]]$FolderNameComponents = @($TrimmedPrefix,$TrimmedApplicationID,$TrimmedPostfix) | Where-Object { Test-String -IsPopulated $_ }
    $ApplicationFolderNameTextBox.Text = $FolderNameComponents -join $ApplicationFolderSeparator
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Resolves the Intake Application ID textbox.
.OUTPUTS
    [System.Windows.Forms.TextBox] when found; otherwise null.
.NOTES
    Version         : 6.5.0
#>
####################################################################################################
function Get-IntakeApplicationIDTextBox {
    [CmdletBinding()]
    [OutputType([System.Windows.Forms.TextBox])]
    param ()

    [System.String]$DesktopApplicationIDRoot = 'applicationintake.desktopapplication.applicationid'
    if ($Global:Graphics.TextBoxes -is [System.Collections.IDictionary] -and
        $Global:Graphics.TextBoxes.ContainsKey($DesktopApplicationIDRoot)) {
        [System.Object]$Section = $Global:Graphics.TextBoxes[$DesktopApplicationIDRoot]
        if ($Section -is [System.Collections.IDictionary] -and
            $Section.ContainsKey('ApplicationID') -and
            $Section.ApplicationID -is [System.Windows.Forms.TextBox]) {
            return $Section.ApplicationID
        }
    }

    return $null
}

### END OF FUNCTION
####################################################################################################
