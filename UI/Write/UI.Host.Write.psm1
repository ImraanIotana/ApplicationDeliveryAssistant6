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
    This function returns no stream output. All output is written to the host.
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
        [ValidateSet('Info','Busy','Success','Fail','Warning','Special','Separator')]
        [AllowNull()][AllowEmptyString()]
        [System.String]$Type
    )

    begin {
        ####################################################################################################
        ### MAIN PROPERTIES ###

        # Set the main properties for the message
        [System.String]$OriginalMessage         = $Message
        [System.String]$MessageType             = $Type
        [System.String]$TimeStamp               = Get-TimeStamp -ForHost
        # Set the calling function
        [System.String]$FirstCallingFunction    = (Get-PSCallStack)[1].Command
        [System.String]$SecondCallingFunction   = (Get-PSCallStack)[2].Command
        [System.String]$CallingFunctionName     = if ($FirstCallingFunction -eq 'Write-DeploymentMessage' -or $FirstCallingFunction -eq 'Write-ErrorReport') { $SecondCallingFunction } else { $FirstCallingFunction }
        [System.String]$CallingFunction         = "[$CallingFunctionName]:"

        ####################################################################################################
    }
    
    process {
        # PREPARATION - MESSAGE FORMATTING
        # Set the message based on the MessageType
        [System.String]$FullMessage = switch ($MessageType) {
            'Separator'         { "$TimeStamp ----------------------------------------------------------------------------------------------------" }
            Default             { "$TimeStamp $CallingFunction $OriginalMessage" }
        }

        # PREPARATION - FOREGROUND COLOR SELECTION
        # Set the foreground color based on the MessageType
        [System.String]$ForegroundColor = switch ($MessageType) {
            'Info'              { 'White' }
            'Busy'              { 'Yellow' }
            'Success'           { 'Green' }
            'Fail'              { 'Red' }
            'Warning'           { 'Yellow' }
            'Special'           { 'Cyan' }
            'Separator'         { 'DarkGray' }
            Default             { 'DarkGray' }
        }

        # PREPARATION - BACKGROUND COLOR SELECTION
        # Set the background color based on the MessageType
        [System.String]$BackgroundColor = switch ($MessageType) {
            Default             { '' }
        }

        # EXECUTION
        # Write the message
        switch ([System.String]::IsNullOrEmpty($BackgroundColor)) {
            $false  { Write-Host $FullMessage -ForegroundColor $ForegroundColor -BackgroundColor $BackgroundColor }
            $true   { Write-Host $FullMessage -ForegroundColor $ForegroundColor }
        }
    }
    
    end {
    }
}

### END OF FUNCTION
####################################################################################################

