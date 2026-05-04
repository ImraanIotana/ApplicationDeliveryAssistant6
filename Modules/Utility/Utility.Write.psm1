#
# Module 'UI.Host.Write.psm1'
# Last Update: April 2026
#

####################################################################################################
<#
.SYNOPSIS
    Outputs a formatted message to the host with customizable colors for enhanced readability and status indication.
.DESCRIPTION
    Provides a function for writing messages to the host in various colors, supporting multiple message types for deployment and automation scenarios.
.EXAMPLE
    Write-Line "Hello World!"
.EXAMPLE
    Write-Line "Deployment completed successfully." -Type Success
.INPUTS
    [System.String]
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

function Write-Line {
    [CmdletBinding()]
    [OutputType([System.Void])]
    param (
        [Parameter(Mandatory=$false,Position=0,HelpMessage='The message that will be written to the host.')]
        [AllowNull()][AllowEmptyString()]
        [System.String]$Message,

        [Parameter(Mandatory=$false,HelpMessage='Type for deciding the colors.')]
        [ValidateSet('Info','Busy','Success','Fail','Error','Warning','Special','Debug')]
        [AllowNull()][AllowEmptyString()]
        [System.String]$Type
    )


    # PREPARATION - MAIN PROPERTIES
    # Set the main properties for the message
    [System.String]$OriginalMessage = $Message
    [System.String]$MessageType     = $Type


    # PREPARATION - MESSAGE FORMATTING
    # Set the message based on the MessageType
    [System.String]$MessageToWrite = switch ($MessageType) {
        'Debug'             { [System.String]$TimeStamp = Get-TimeStamp -ForHost ; [System.String]$CallingFunction = (Get-PSCallStack)[1].Command ; "$TimeStamp [$CallingFunction] $OriginalMessage" }
        Default             { $OriginalMessage }
    }

    # PREPARATION - FOREGROUND COLOR SELECTION
    # Set the foreground color based on the MessageType
    [System.String]$ForegroundColor = switch ($MessageType) {
        'Info'      { 'White' }
        'Busy'      { 'Yellow' }
        'Success'   { 'Green' }
        'Fail'      { 'Red' }
        'Error'     { 'Red' }
        'Warning'   { 'Yellow' }
        'Special'   { 'Cyan' }
        'Debug'     { 'Cyan' }
        Default     { 'DarkGray' }
    }

    # PREPARATION - BACKGROUND COLOR SELECTION
    # Set the background color based on the MessageType
    [System.String]$BackgroundColor = switch ($MessageType) {
        'Error'     { 'White' }
        Default     { '' }
    }

    # EXECUTION
    # Set the parameters for Write-Host
    [System.Collections.Hashtable]$WriteParameters = @{ ForegroundColor = $ForegroundColor }
    if ($BackgroundColor) { $WriteParameters.BackgroundColor = $BackgroundColor }
    # Write the message
    Write-Host $MessageToWrite @WriteParameters

}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Writes the full details of an error to the host and logs it to a file.
.DESCRIPTION
    Provides a function for writing the full details of an error to the host in yellow color, including the error message, exception type, invoking function hierarchy and error details.
    The error is also logged to a file in the log folder.
.EXAMPLE
    Write-ErrorReport -ErrorRecord $_
.INPUTS
    [System.Management.Automation.ErrorRecord]$ErrorRecord
    The error record of which the details will be written.
.OUTPUTS
    No objects are returned to the pipeline. All operational output is written to the host and logged to the deployment logfile.
.NOTES
    This script is part of the Universal Deployment Framework. Copyright (C) Iotana. All rights reserved.
    Version         : 6.0.0.0
    Author          : Imraan Iotana
    Creation Date   : February 2026
    Last Update     : February 2026
#>
####################################################################################################

function Write-ErrorReport {
    [CmdletBinding()]
    [OutputType([System.Void])]
    param (
        [Parameter(Mandatory=$true,Position=0,HelpMessage='The error record of which the details will be written.')]
        [System.Management.Automation.ErrorRecord]$ErrorRecord
    )
    
    begin {
        # PREPARATION
        # Set the context
        [System.Collections.Hashtable]$CTX = @{
            ErrorRecord     = $ErrorRecord
            ErrorFullName   = $ErrorRecord.Exception.GetType().FullName
            StackTrace      = $ErrorRecord.ScriptStackTrace
            CallingFunction  = (Get-PSCallStack)[1].Command
        }
    }
    
    process {
        # Write the error message and details to the host
        #Write-Line -Type ErrorSeparator
        Write-Line "ERRORMESSAGE: [$($CTX.CallingFunction)] has encountered an error." -Type Special
        # Write the original error message (colored)
        [System.String]$ErrorText = ($ErrorRecord | Out-String).Trim()
        Write-Line $ErrorText -Type Warning
        # Write the details to the host
        Write-Line "Please use the following StackTrace of Calling Functions to pinpoint the issue:" -Type Special
        Write-Line "Exception Type: $($CTX.ErrorFullName)"
        # Write the stack trace
        [System.String[]]$TraceLines = $CTX.StackTrace -split "`n"
        # Remove the last 2 lines of the stack trace as they are not relevant (they only contain the line where the error was caught and the line where Write-ErrorReport was called)
        $TraceLines = $TraceLines[0..($TraceLines.Length - 3)]
        # Write the remaining stack trace lines to the host in dark gray color
        foreach ($TraceLine in $TraceLines) {
            if ($TraceLine.TrimStart().StartsWith('at ')) {
                # Remove the "at " from the beginning of the line
                [System.String]$ShortTraceLine = $TraceLine.TrimStart().Substring(3)
                # Split the line into the function part and the file part
                [System.String[]]$Parts = $ShortTraceLine -split ',\s*'
                # Add labels to the parts for better readability
                [System.String[]]$PartsWithLabel = @(("Function`t: " +  $Parts[0]),("In File`t: " +  $Parts[1]))
            }
            $PartsWithLabel | ForEach-Object { Write-Line $_ }
        }
        # Write a separator line
        #Write-Line -Type ErrorSeparator
    }
    
    end {
    }
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Writes a welcome message to the host, including copyright information and the application name and version.
.DESCRIPTION
    This function is called at the start of the application to greet the user and provide basic information about the application.
.EXAMPLE
    Write-WelcomeMessage
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
function Write-WelcomeMessage {
    # Write the copyright and welcome message
    Write-Line 'Copyright (C) Iotana. All rights reserved.'
    Write-Line "Welcome to the $($Global:ApplicationObject.Name) $($Global:ApplicationObject.Version)" -Type Info
}

### END OF FUNCTION
####################################################################################################