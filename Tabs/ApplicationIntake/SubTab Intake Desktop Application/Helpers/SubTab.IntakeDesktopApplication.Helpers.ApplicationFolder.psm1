####################################################################################################
<#
.SYNOPSIS
    Recreates an application folder and its configured subfolders.
.DESCRIPTION
    Removes an existing application folder, creates a clean root folder, and creates each supplied subfolder.
.OUTPUTS
    No objects are returned to the pipeline.
#>
####################################################################################################
function New-ApplicationFolderStructure {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The application folder to recreate.')]
        [System.String]$ApplicationFolderPath,

        [Parameter(Mandatory=$true,HelpMessage='Relative subfolder paths to create.')]
        [System.String[]]$SubFolders
    )

    if (Test-Path -LiteralPath $ApplicationFolderPath -PathType Container) {
        Remove-Item -LiteralPath $ApplicationFolderPath -Recurse -Force
    }
    New-Item -Path $ApplicationFolderPath -ItemType Directory -Force | Out-Null

    foreach ($SubFolder in $SubFolders) {
        [System.String]$SubFolderPath = Join-Path -Path $ApplicationFolderPath -ChildPath $SubFolder
        New-Item -Path $SubFolderPath -ItemType Directory -Force | Out-Null
    }
}

### END OF FUNCTION
####################################################################################################
