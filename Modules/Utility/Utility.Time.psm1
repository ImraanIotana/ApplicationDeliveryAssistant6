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
    [System.Management.Automation.SwitchParameter]
.OUTPUTS
    [System.String]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. All rights reserved.
    Version         : 6.0.0.0
    Author          : Imraan Iotana
    Creation Date   : April 2026
    Last Update     : April 2026
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


####################################################################################################
<#
.SYNOPSIS
    Stops the load timer and reports elapsed time.
.DESCRIPTION
    This function stops the load timer that was started at the beginning of the application and reports the elapsed time in seconds.
    If the load timer was not started, a fail message is written to the host.
.EXAMPLE
    Stop-LoadTimer
.INPUTS
    None.
.OUTPUTS
    No objects are returned to the pipeline. All output is written to the host.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. All rights reserved.
    Version         : 6.0.0.0
    Author          : Imraan Iotana
    Creation Date   : April 2026
    Last Update     : April 2026
#>
####################################################################################################
function Stop-LoadTimer {
        
    # EXECUTION
    # Stop the load timer and report elapsed time
    if ($Global:ApplicationObject.LoadTimer) {

        # Stop the stopwatch
        $Global:ApplicationObject.LoadTimer.Stop()
        # Get the elapsed time in seconds and round to 2 decimal places
        [double]$Seconds = $Global:ApplicationObject.LoadTimer.Elapsed.TotalSeconds
        [string]$RoundedSeconds = $Seconds.ToString("F2")
        # Write the elapsed time to the host
        Write-Line "Loading time: $RoundedSeconds seconds"

    } else {
        # Write a fail message if the load timer was not started
        Write-Line "The Load Timer was not started. The elapsed time cannot be determined." -Type Fail
    }
}

# END OF FUNCTION
####################################################################################################
