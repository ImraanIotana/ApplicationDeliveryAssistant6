#
# Module 'Utility.Items.psm1'
# Last Update: May 2026
#

####################################################################################################
<#
.SYNOPSIS
    This function opens a folder in File Explorer, optionally highlighting a specific item.
.DESCRIPTION
    The Open-Folder function opens a specified folder in File Explorer.
    You can also choose to highlight a specific item within that folder when it opens. This is useful for quickly navigating to a particular file or subfolder.
.EXAMPLE
    Open-Folder -Path C:\Demo
.EXAMPLE
    Open-Folder -HighlightItem C:\Demo\NewFolder
.INPUTS
    [System.String]
.OUTPUTS
    No objects are returned to the pipeline. All output is written to the host.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. All rights reserved.
    Version         : 6.0.0.0
    Author          : Imraan Iotana
    Creation Date   : December 2025
    Last Update     : May 2026
#>
####################################################################################################
function Open-Folder {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,ParameterSetName='OpenTheFolder',HelpMessage='The path of the folder that will be opened.')]
        [AllowEmptyString()]
        [System.String]$Path,

        [Parameter(Mandatory=$true,ParameterSetName='HighlightTheItem',HelpMessage='The item that will be highlighted when the folder is opened.')]
        [Alias('Highlight','Select','SelectItem')]
        [AllowEmptyString()]
        [System.String]$HighlightItem
    )


    # Function
    [System.String]$ParameterSetName    = [System.String]$PSCmdlet.ParameterSetName
    
    # Input
    [System.String]$FolderToOpen        = $Path
    [System.String]$ItemToHighlight     = $HighlightItem

    # Handlers
    [System.String]$HighlightPrefix    = '/select,"{0}"'


    # VALIDATION
    switch ($ParameterSetName) {
        'OpenTheFolder'    {
            # Validate the string
            if (Test-String -IsEmpty $FolderToOpen) { Write-Line "The Path string is empty." -Type Fail ; Return }
            # Validate the path
            if (-Not(Test-Path -Path $FolderToOpen)) { Write-Line "The folder does not exist, or could not be reached. ($FolderToOpen)" -Type Fail ; Return }
        }
        'HighlightTheItem' {
            # Validate the string
            if (Test-String -IsEmpty $ItemToHighlight) { Write-Line "The SelectItem string is empty." -Type Fail ; Return }
            # Validate the path
            if (-Not(Test-Path -Path $ItemToHighlight)) {
                Write-Line "The selected item could not be reached. ($ItemToHighlight)" -Type Fail
                Open-Folder -Path (Split-Path -Path $ItemToHighlight -Parent) ; Return
            }
        }
    }

    # EXECUTION
    switch ($ParameterSetName) {
        'OpenTheFolder'    {
            # Open the folder
            try {
                Write-Line "Opening folder... ($FolderToOpen)"
                Invoke-Item -Path $FolderToOpen
            }
            catch {
                Write-FullError
            }
        }
        'HighlightTheItem' {
            # Open the folder
            try {
                Write-Line "Selecting item... ($ItemToHighlight)"
                Start-Process explorer.exe -ArgumentList ($HighlightPrefix -f $ItemToHighlight)
            }
            catch {
                Write-FullError
            }
        }
    }

}

### END OF SCRIPT
####################################################################################################

