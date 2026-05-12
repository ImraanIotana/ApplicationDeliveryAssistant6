#
# Module 'Utility.Validation.psm1'
# Last Update: May 2026
#

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
