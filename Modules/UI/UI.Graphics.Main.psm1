#
# Module 'UI.Graphics.Main.psm1'
# Last Update: April 2026
#

####################################################################################################
<#
.SYNOPSIS
    Initializes the graphical settings for the application by importing settings from a specified file and loading necessary assemblies.
.DESCRIPTION
    This function initializes the graphical settings for the application by importing settings from a specified file and loading necessary assemblies.
    It sets the properties of the main form, including size, position, and window buttons.
.EXAMPLE
    Initialize-Graphics
    Initializes the graphical settings for the application.
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

function Initialize-Graphics {
    [CmdletBinding()]
    [OutputType([System.Void])]
    param (
        [Parameter(Mandatory=$false,HelpMessage='The name of the graphical settings file.')]
        [System.String]$GraphicalSettingsFileName = 'UI.Graphics.Settings.psd1',

        [Parameter(Mandatory=$false,HelpMessage='The ApplicationObject containing the settings.')]
        [PSCustomObject]$InputObject = $Global:ApplicationObject
    )

    try {
        # PREPARATION
        # Get the full path to the graphical settings file
        [System.String]$FolderToSearch = $InputObject.RootFolder
        [System.IO.FileInfo]$GraphicalSettingsFileObject = Get-ChildItem -Path $FolderToSearch -File -Filter $GraphicalSettingsFileName -Recurse

        # Check if the graphical settings file was found
        if ($GraphicalSettingsFileObject.Count -ne 1) {
            [System.String]$ErrorMessage = "The graphical settings file ($GraphicalSettingsFileName) was not found in folder ($FolderToSearch) or its subfolders. (Found $($GraphicalSettingsFileObject.Count) files.)"
            Write-Line $ErrorMessage -Type Error
            throw $ErrorMessage
        }

        # EXECUTION - IMPORT THE GRAPHICAL SETTINGS
        # Import the graphical settings from the Graphics Settings file
        Write-Line 'Importing graphical settings...'
        [System.Collections.Hashtable]$GraphicalSettings = Import-PowerShellDataFile -Path $GraphicalSettingsFileObject.FullName
        # Add the GraphicalSettings hashtable to the main object
        $InputObject | Add-Member -NotePropertyName GraphicalSettings -NotePropertyValue $GraphicalSettings
        
        # Load the assemblies
        Add-Assemblies -InputObject $InputObject
        # Add the main icon to the GraphicalSettings hashtable
        Add-MainIconProperties -InputObject $InputObject
        # Add the font properties
        Add-FontProperties -InputObject $InputObject
        # Add the graphical dimensions of the other controls to the GraphicalSettings hashtable
        Add-GraphicalDimensions -InputObject $InputObject
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
    Adds the necessary assemblies for the graphical interface to the application.
.DESCRIPTION
    This function adds the necessary assemblies for the graphical interface to the application by loading them based on the configuration in the GraphicalSettings of the main object.
.EXAMPLE
    Add-Assemblies -InputObject $Global:ApplicationObject
.INPUTS
    [PSCustomObject]
.OUTPUTS
    No objects are returned to the pipeline. All output is written to the host.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. All rights reserved.
    Version         : 6.0.0.0
    Author          : Imraan Iotana
    Creation Date   : May 2026
    Last Update     : May 2026
#>
####################################################################################################
function Add-Assemblies {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false,HelpMessage='The ApplicationObject containing the settings.')]
        [PSCustomObject]$InputObject
    )

    try {
        # EXECUTION - LOAD ASSEMBLIES
        # Load the assemblies
        Write-Line 'Loading assemblies...'
        $InputObject.GraphicalSettings.Assemblies | ForEach-Object { Add-Type -AssemblyName $_ }
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
    Adds graphical dimensions to the Global ApplicationObject.
.DESCRIPTION
    This function adds graphical dimensions to the Global ApplicationObject based on the MainForm dimensions and the MainTabControl margins.
.EXAMPLE
    Add-GraphicalDimensions -InputObject $Global:ApplicationObject
.INPUTS
    [PSCustomObject]
.OUTPUTS
    No objects are returned to the pipeline. All output is written to the host.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. All rights reserved.
    Version         : 6.0.0.0
    Author          : Imraan Iotana
    Creation Date   : May 2026
    Last Update     : May 2026
#>
####################################################################################################
function Add-GraphicalDimensions {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false,HelpMessage='The ApplicationObject containing the settings.')]
        [PSCustomObject]$InputObject
    )

    # Add the graphical dimensions of the MainTabControl
    Add-MainTabControlDimensions -InputObject $InputObject
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Adds graphical dimensions to the MainTabControl settings based on the MainForm dimensions and the MainTabControl margins.
.DESCRIPTION
    This function adds graphical dimensions to the MainTabControl settings based on the MainForm dimensions and the MainTabControl margins.
     It calculates the width and height of the MainTabControl based on the MainForm dimensions and the MainTabControl margins, and adds these dimensions to the MainTabControl settings in the GraphicalSettings hashtable of the main object.
.EXAMPLE
    Add-MainTabControlDimensions -InputObject $Global:ApplicationObject
.INPUTS
    [PSCustomObject]
.OUTPUTS
    No objects are returned to the pipeline. All output is written to the host.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. All rights reserved.
    Version         : 6.0.0.0
    Author          : Imraan Iotana
    Creation Date   : May 2026
    Last Update     : May 2026
#>
####################################################################################################
function Add-MainTabControlDimensions {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false,HelpMessage='The ApplicationObject containing the settings.')]
        [PSCustomObject]$InputObject
    )

    try {
        # Get the MainForm settings
        [System.Collections.Hashtable]$MainForm         = $InputObject.GraphicalSettings.MainForm
        # Get the MainTabControl settings
        [System.Collections.Hashtable]$MainTabControl   = $InputObject.GraphicalSettings.MainTabControl

        # Add the MainTabControl Width to the MainTabControl settings based on the MainForm dimensions and the MainTabControl margins
        $MainTabControl.Width   = $MainForm.Width - $MainTabControl.LeftMargin - $MainTabControl.RightMargin
        # Add the MainTabControl Height to the MainTabControl settings based on the MainForm dimensions and the MainTabControl margins
        $MainTabControl.Height  = $MainForm.Height - $MainTabControl.TopMargin - $MainTabControl.BottomMargin
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
    Adds font properties to the Global ApplicationObject.
.DESCRIPTION
    This function adds font properties to the Global ApplicationObject based on the MainForm dimensions and the MainTabControl margins.
.EXAMPLE
    Add-FontProperties -InputObject $Global:ApplicationObject
.INPUTS
    [PSCustomObject]
.OUTPUTS
    No objects are returned to the pipeline. All output is written to the host.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. All rights reserved.
    Version         : 6.0.0.0
    Author          : Imraan Iotana
    Creation Date   : May 2026
    Last Update     : May 2026
#>
####################################################################################################
function Add-FontProperties {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false,HelpMessage='The ApplicationObject containing the settings.')]
        [PSCustomObject]$InputObject
    )

    try {
        # PREPARATION
        # Get the Font Name
        [System.String]$FontName                = $InputObject.GraphicalSettings.MainFont.Name
        # Get the Font Size
        [System.Single]$FontSize                = $InputObject.GraphicalSettings.MainFont.Size
        # Set the Font Style to Bold
        [System.Drawing.FontStyle]$FontStyle    = [System.Drawing.FontStyle]::Bold

        # EXECUTION - ADD FONT
        # Set the font
        Write-Line 'Adding font...'
        [System.Drawing.Font]$MainFont = New-Object System.Drawing.Font($FontName,$FontSize,$FontStyle)
        # Replace the MainFont in the GraphicalSettings hashtable with the actual Font object
        $InputObject.GraphicalSettings.MainFont = $MainFont
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
    Adds the MainIcon properties to the Global ApplicationObject.
.DESCRIPTION
    This function finds the main icon file from the configured icon file name and stores it as a System.Drawing.Icon object in GraphicalSettings.
.EXAMPLE
    Add-MainIconProperties -InputObject $Global:ApplicationObject
.INPUTS
    [PSCustomObject]
.OUTPUTS
    No objects are returned to the pipeline. All output is written to the host.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. All rights reserved.
    Version         : 6.0.0.0
    Author          : Imraan Iotana
    Creation Date   : May 2026
    Last Update     : May 2026
#>
####################################################################################################
function Add-MainIconProperties {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false,HelpMessage='The ApplicationObject containing the settings.')]
        [PSCustomObject]$InputObject
    )

    try {
        # Get the full path to the main icon file
        [System.String]$MainIconFileName        = $InputObject.GraphicalSettings.MainForm.IconFileName
        [System.String]$FolderToSearch          = $InputObject.RootFolder
        [System.IO.FileInfo]$MainIconFileObject = Get-ChildItem -Path $FolderToSearch -File -Filter $MainIconFileName -Recurse

        # Check if the main icon file was found
        if ($MainIconFileObject.Count -ne 1) {
            [System.String]$ErrorMessage = "The main icon file ($MainIconFileName) was not found in folder ($FolderToSearch) or its subfolders. (Found $($MainIconFileObject.Count) files.)"
            Write-Line $ErrorMessage -Type Error
            throw $ErrorMessage
        }

        # Replace the MainIcon in the GraphicalSettings hashtable with the actual Icon object
        Write-Line 'Setting main icon...'
        [System.Drawing.Icon]$MainIcon = New-Object System.Drawing.Icon($MainIconFileObject.FullName)
        $InputObject.GraphicalSettings.MainIcon = $MainIcon
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}

### END OF FUNCTION
####################################################################################################
