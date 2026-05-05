

####################################################################################################
<#
.SYNOPSIS
    This function imports the Module Launcher.
.DESCRIPTION
    This function is part of the Packaging Assistant. It contains functions and variables that are in other files.
.EXAMPLE
    Import-ModuleLauncher
.INPUTS
    [System.Windows.Forms.TabControl]
.OUTPUTS
    This function returns no stream output.
.NOTES
    Version         : See below at 'Main Properties'
    Author          : Imraan Iotana
    Creation Date   : October 2023
    Last Update     : February 2026
#>
####################################################################################################
function Import-ModuleLauncher {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false,HelpMessage='The Parent TabControl to which this new TabPage will be added.')]
        [System.Windows.Forms.TabControl]$ParentTabControl = $Global:MainTabControl
    )

    begin {
        ####################################################################################################
        ### MAIN PROPERTIES ###

        # Module properties
        [System.Collections.Hashtable]$ModuleProperties = @{
            ParentTabControl    = $ParentTabControl
            Title               = 'LAUNCHER'
            Version             = '5.7.2'
            BackGroundColor     = 'ForestGreen'
        }

        # Set the Helpfile properties
        [System.String]$HelpFileName    = "HelpFile Module $($ModuleProperties.Title).pdf"
        [System.String]$HelpFilePath    = (Get-ChildItem -Path $PSScriptRoot -File -Recurse -Filter $HelpFileName -ErrorAction SilentlyContinue).FullName


        ####################################################################################################
    }
    
    process {
        try {
            # Create the Module TabPage
            [System.Windows.Forms.TabPage]$ParentTabPage = New-TabPage @ModuleProperties

            # Register the help file in the main Help menu
            if ($HelpFilePath) {
                Register-HelpMenuItem -Text "Module $($ModuleProperties.Title) Help" -HelpFilePath $HelpFilePath
            } else {
                Write-Line "Help file not found for module '$($ModuleProperties.Title)'. Expected at: $HelpFilePath" -Type Fail
            }

            # Import the Features
            [System.Windows.Forms.GroupBox]$SystemFolderGroupBox = Import-FeatureSystemFolderLauncher -ParentTabPage $ParentTabPage -ReturnGroupBox
            [System.Windows.Forms.GroupBox]$UserFolderGroupBox = Import-FeatureUserFolderLauncher -ParentTabPage $ParentTabPage -ReturnGroupBox -GroupBoxAbove $SystemFolderGroupBox
            [System.Windows.Forms.GroupBox]$AppLauncherGroupBox = Import-FeatureAppLauncher -ParentTabPage $ParentTabPage -ReturnGroupBox -GroupBoxAbove $UserFolderGroupBox
            Import-FeatureRegistryLauncher -ParentTabPage $ParentTabPage -GroupBoxAbove $AppLauncherGroupBox
        }
        catch {
            Write-FullError
        }
    }

    end {
    }
}

### END OF FUNCTION
####################################################################################################
