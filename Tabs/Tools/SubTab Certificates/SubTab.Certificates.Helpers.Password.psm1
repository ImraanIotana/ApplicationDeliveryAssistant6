####################################################################################################
<#
.SYNOPSIS
    Provides a shared password dialog for certificate operations.
.DESCRIPTION
    Displays a masked password field and optionally requires password confirmation for operations
    that create a new PFX password.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.2.0
    Author          : Imraan Iotana
    Creation Date   : August 2026
    Last Update     : August 2026
#>
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Prompts the user for a certificate password.
.DESCRIPTION
    Displays one masked password field for opening a PFX file or two masked fields when a new export
    password must be entered and confirmed.
.EXAMPLE
    Read-CertificatePassword -Owner $MainForm -Title 'Open PFX Certificate' -PasswordLabel 'PFX password'
.EXAMPLE
    Read-CertificatePassword -Owner $MainForm -Title 'Protect PFX Export' -ConfirmPassword
.INPUTS
    [System.Windows.Forms.IWin32Window]
    [System.String]
    [System.String]
.OUTPUTS
    [PSCustomObject]
#>
####################################################################################################
function Read-CertificatePassword {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory=$false,HelpMessage='The window that owns the password dialog.')]
        [AllowNull()]
        [System.Windows.Forms.IWin32Window]$Owner,

        [Parameter(Mandatory=$true,HelpMessage='The title of the password dialog.')]
        [System.String]$Title,

        [Parameter(Mandatory=$false,HelpMessage='The label shown beside the password field.')]
        [System.String]$PasswordLabel = 'Password',

        [Parameter(Mandatory=$false,HelpMessage='Require the password to be entered a second time.')]
        [System.Management.Automation.SwitchParameter]$ConfirmPassword
    )

    # PREPARATION - DIALOG
    # Create the fixed password dialog and disposable password controls
    [System.Int32]$DialogHeight = if ($ConfirmPassword.IsPresent) { 180 } else { 130 }
    [System.Windows.Forms.Form]$Dialog = New-ModalDialog -Title $Title -ClientWidth 430 -ClientHeight $DialogHeight -Owner $Owner
    [System.Windows.Forms.TextBox]$PasswordTextBox = $null
    [System.Windows.Forms.TextBox]$ConfirmationTextBox = $null
    try {
        [PSCustomObject]$DialogActions = New-ModalDialogActionBar -Dialog $Dialog -PrimaryText 'OK' -ButtonWidth 75 -ButtonHeight 28
        [System.Windows.Forms.Button]$OkButton = $DialogActions.PrimaryButton
        [System.Int32]$ValidationTop = if ($ConfirmPassword.IsPresent) { 101 } else { 50 }

        # PREPARATION - PASSWORD CONTROLS
        # Create the primary password label and masked textbox
        [System.Windows.Forms.Label]$PrimaryPasswordLabel = New-Object System.Windows.Forms.Label
        $PrimaryPasswordLabel.Text = $PasswordLabel
        $PrimaryPasswordLabel.Location = New-Object System.Drawing.Point(18, 23)
        $PrimaryPasswordLabel.Size = New-Object System.Drawing.Size(120, 23)

        $PasswordTextBox = New-Object System.Windows.Forms.TextBox
        $PasswordTextBox.Location = New-Object System.Drawing.Point(150, 20)
        $PasswordTextBox.Size = New-Object System.Drawing.Size(255, 25)
        $PasswordTextBox.UseSystemPasswordChar = $true

        [System.Collections.Generic.List[System.Windows.Forms.Control]]$DialogControls = New-Object 'System.Collections.Generic.List[System.Windows.Forms.Control]'
        $DialogControls.Add($PrimaryPasswordLabel)
        $DialogControls.Add($PasswordTextBox)

        # PREPARATION - CONFIRMATION CONTROLS
        # Add a second masked field when the password must be confirmed
        if ($ConfirmPassword.IsPresent) {
            [System.Windows.Forms.Label]$ConfirmationLabel = New-Object System.Windows.Forms.Label
            $ConfirmationLabel.Text = 'Confirm password'
            $ConfirmationLabel.Location = New-Object System.Drawing.Point(18, 65)
            $ConfirmationLabel.Size = New-Object System.Drawing.Size(120, 23)

            $ConfirmationTextBox = New-Object System.Windows.Forms.TextBox
            $ConfirmationTextBox.Location = New-Object System.Drawing.Point(150, 62)
            $ConfirmationTextBox.Size = New-Object System.Drawing.Size(255, 25)
            $ConfirmationTextBox.UseSystemPasswordChar = $true

            $DialogControls.Add($ConfirmationLabel)
            $DialogControls.Add($ConfirmationTextBox)
        }

        # PREPARATION - VALIDATION AND ACTIONS
        # Create the validation label and dialog buttons
        [System.Windows.Forms.Label]$ValidationLabel = New-Object System.Windows.Forms.Label
        $ValidationLabel.ForeColor = [System.Drawing.Color]::DarkRed
        $ValidationLabel.Location = New-Object System.Drawing.Point(18, $ValidationTop)
        $ValidationLabel.Size = New-Object System.Drawing.Size(270, 23)

        $OkButton.Add_Click({
            if ([System.String]::IsNullOrEmpty($PasswordTextBox.Text)) {
                $ValidationLabel.Text = 'Enter a password.'
                return
            }
            if ($ConfirmPassword.IsPresent -and ($PasswordTextBox.Text -cne $ConfirmationTextBox.Text)) {
                $ValidationLabel.Text = 'The passwords do not match.'
                return
            }
            $Dialog.DialogResult = [System.Windows.Forms.DialogResult]::OK
            $Dialog.Close()
        }.GetNewClosure())

        # EXECUTION - SHOW DIALOG
        # Add the controls and show the password dialog
        $DialogControls.Add($ValidationLabel)
        $Dialog.Controls.AddRange($DialogControls.ToArray())
        $Dialog.ActiveControl = $PasswordTextBox

        [System.Windows.Forms.DialogResult]$DialogResult = Show-ModalDialog -Dialog $Dialog -Owner $Owner

        # POST-EXECUTION
        # Return the confirmation state and entered password
        [PSCustomObject][ordered]@{
            Confirmed = ($DialogResult -eq [System.Windows.Forms.DialogResult]::OK)
            Password  = if ($DialogResult -eq [System.Windows.Forms.DialogResult]::OK) {
                [System.String]$PasswordTextBox.Text
            }
            else {
                $null
            }
        }
    }
    finally {
        if ($null -ne $PasswordTextBox) {
            $PasswordTextBox.Clear()
        }
        if ($null -ne $ConfirmationTextBox) {
            $ConfirmationTextBox.Clear()
        }
        $Dialog.Dispose()
    }
}

### END OF FUNCTION
####################################################################################################