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

