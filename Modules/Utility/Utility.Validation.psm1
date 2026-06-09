####################################################################################################
<#
.SYNOPSIS
    This function ask the user for confirmation with a message box.
.DESCRIPTION
    This function is self-contained and does not refer to functions or variables, that are in other files.
.EXAMPLE
    Get-UserConfirmation -Title 'Removing File' -Body 'Are you sure you want to remove this file?'
.INPUTS
    [System.String]
.OUTPUTS
    [System.Boolean]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. All rights reserved.
    Version         : 6.0.0.0
    Author          : Imraan Iotana
    Creation Date   : June 2023
    Last Update     : June 2026
#>
####################################################################################################
function Get-UserConfirmation {
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    [Alias('Show-MessageBox')]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The text that will be written in the HEADER of the Message Box.')]
        [System.String]$Title,

        [Parameter(Mandatory=$true,HelpMessage='The main text that will be written in the MIDDLE of the Message Box.')]
        [System.String]$Body,

        [Parameter(Mandatory=$false,HelpMessage='String that will decide which icon and buttons to show. Valid values are: Information/Question/Warning/Error.')]
        [ValidateSet('Information','Question','Warning','Error')]
        [System.String]$Type = 'Question'
    )

    try {
        # PREPARATION
        # Set the MessageBox button configuration from the selected type.
        [System.Windows.Forms.MessageBoxButtons]$Buttons = switch ($Type) {
            'Information'   { [System.Windows.Forms.MessageBoxButtons]::OK }
            'Question'      { [System.Windows.Forms.MessageBoxButtons]::YesNoCancel }
            'Warning'       { [System.Windows.Forms.MessageBoxButtons]::YesNoCancel }
            'Error'         { [System.Windows.Forms.MessageBoxButtons]::OKCancel }
        }

        # Set the MessageBox icon from the selected type.
        [System.Windows.Forms.MessageBoxIcon]$Icon = switch ($Type) {
            'Information'   { [System.Windows.Forms.MessageBoxIcon]::Information }
            'Question'      { [System.Windows.Forms.MessageBoxIcon]::Question }
            'Warning'       { [System.Windows.Forms.MessageBoxIcon]::Warning }
            'Error'         { [System.Windows.Forms.MessageBoxIcon]::Error }
        }

        # EXECUTION
        # Show the message box and evaluate whether the user confirmed.
        [System.Windows.Forms.DialogResult]$UserChoice = [System.Windows.Forms.MessageBox]::Show($Body, $Title, $Buttons, $Icon)
        [System.Boolean]$UserHasConfirmed = (($UserChoice -eq [System.Windows.Forms.DialogResult]::Yes) -or ($UserChoice -eq [System.Windows.Forms.DialogResult]::OK))

        # POST-EXECUTION
        # Write a status message
        if ($UserHasConfirmed) {
            Write-Line 'The user confirmed.'
        }
        else {
            Write-Line 'The user did not confirm. No action has been taken.'
        }
        # Return the result
        $UserHasConfirmed
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
    This function tests if a String is empty or populated.
.DESCRIPTION
    Tests if a String is empty or populated. The function has two parameter sets: one for testing if a string is empty, and another for testing if a string is populated.
    Depending on the parameter set used, it returns $true or $false accordingly.
.EXAMPLE
    Test-String -IsEmpty $MyString
.EXAMPLE
    Test-String -IsPopulated $MyString
.INPUTS
    [System.String]
.OUTPUTS
    [System.Boolean]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. All rights reserved.
    Version         : 6.0.0.0
    Author          : Imraan Iotana
    Creation Date   : February 2026
    Last Update     : May 2026
#>
####################################################################################################
function Test-String {
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param (
        [Parameter(Mandatory=$true,ParameterSetName='TestIsEmpty',HelpMessage='The string that will be handled.')]
        [AllowNull()][AllowEmptyString()][System.String]$IsEmpty,

        [Parameter(Mandatory=$true,ParameterSetName='TestIsPopulated',HelpMessage='The string that will be handled.')]
        [AllowNull()][AllowEmptyString()][System.String]$IsPopulated
    )

    begin {
        # PREPARATION
        # Set the context
        [System.Collections.Hashtable]$CTX = @{
            StringToTest        = switch ($PSCmdlet.ParameterSetName) {
                'TestIsEmpty'       { $IsEmpty }
                'TestIsPopulated'   { $IsPopulated }
            }
            ParameterSetName    = $PSCmdlet.ParameterSetName
            Output              = $null
        }
    }
    
    process {
        # Test if the string is empty
        [System.Boolean]$StringIsEmpty = if ( [System.String]::IsNullOrWhiteSpace($CTX.StringToTest) -or [System.String]::IsNullOrEmpty($CTX.StringToTest) ) { $true } else { $false }

        # Set the OutputObject based on the ParameterSetName
        $CTX.Output = switch ($CTX.ParameterSetName) {
            'TestIsEmpty'       { $StringIsEmpty }
            'TestIsPopulated'   { -Not($StringIsEmpty) }
        }
    }
    
    end {
        # Return the output
        $CTX.Output
    }
}

### END OF FUNCTION
####################################################################################################
