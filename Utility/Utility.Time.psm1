#
# Module 'Utility.Time.psm1'
# Last Update: April 2026
#

####################################################################################################
<#
.SYNOPSIS
    Returns a timestamp in a format suitable for filenames.
.DESCRIPTION
    This function returns the current timestamp. If the -ForFileName switch is used, the timestamp is formatted in a way that is suitable for use in filenames.
.EXAMPLE
    Get-TimeStamp -ForFileName
.INPUTS
    [System.Management.Automation.SwitchParameter]$ForFileName
    A switch parameter that indicates whether the timestamp should be formatted for use in filenames.
    [System.Management.Automation.SwitchParameter]$ForHost
    A switch parameter that indicates whether the timestamp should be formatted for display in the host.
.OUTPUTS
    [System.String] The timestamp is returned as a string.
.NOTES
    This script is part of the Universal Deployment Framework. Copyright (C) Iotana. All rights reserved.
    Version         : 6.0.0.0
    Author          : Imraan Iotana
    Creation Date   : February 2026
    Last Update     : March 2026
#>
####################################################################################################
function Get-TimeStamp {
    [CmdletBinding()]
    [OutputType([System.String])]
    param (
        [Parameter(Mandatory=$true,ParameterSetName='ForFileName',HelpMessage='Returns the timestamp in a format suitable for filenames.')]
        [System.Management.Automation.SwitchParameter]$ForFileName,

        [Parameter(Mandatory=$true,ParameterSetName='ForHost',HelpMessage='Returns the timestamp in a format suitable for display.')]
        [System.Management.Automation.SwitchParameter]$ForHost
    )


    # PROPERTIES
    # Get the UTC TimeStamp
    [System.DateTime]$UTCTimeStamp = (Get-Date).ToUniversalTime()

    # Set the context
    [System.Collections.Hashtable]$CTX = @{
        ParameterSetName        = $PSCmdlet.ParameterSetName
        TimeStampForFileName    = $UTCTimeStamp.ToString('yyyy_MM_dd_HHmm')
        TimeStampDateForHost    = $UTCTimeStamp.ToString('yyyy-MM-dd')
        TimeStampTimeForHost    = $UTCTimeStamp.ToString('HH:mm:ss.fff')
        TimeStampDefault        = $UTCTimeStamp.ToString()
        Output                  = [System.String]::Empty
    }

    # EXECUTION
    # Switch the timestamp format based on the ParameterSetName
    $CTX.Output = switch ($CTX.ParameterSetName) {
        'ForFileName'   { $CTX.TimeStampForFileName }
        'ForHost'       { "[$($CTX.TimeStampDateForHost) $($CTX.TimeStampTimeForHost)]" }
        Default         { $CTX.TimeStampDefault }
    }

    # Return the output
    $CTX.Output
}

# END OF FUNCTION
####################################################################################################