#
# Module 'Graphics.Main.psm1'
# Last Update: May 2026
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
    [PSCustomObject]
    [System.String]
.OUTPUTS
    No objects are returned to the pipeline. All output is written to the host.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. All rights reserved.
    Version         : 6.0.0.0
    Author          : Imraan Iotana
    Creation Date   : April 2026
    Last Update     : May 2026
#>
####################################################################################################
function Initialize-Graphics {
    [CmdletBinding()]
    [OutputType([System.Void])]
    param (
        [Parameter(Mandatory=$false,HelpMessage='The ApplicationObject containing the settings.')]
        [PSCustomObject]$InputObject = $Global:ApplicationObject
    )

    try {
        # PREPARATION - IMPORT SETTINGS
        # Import the graphical settings from the Graphics Settings file
        Import-GraphicalSettings -InputObject $InputObject

        # PREPARATION - ADD PROPERTIES TO THE MAIN OBJECT
        # Load the assemblies
        Add-Assemblies -InputObject $InputObject
        # Add the main icon to the GraphicalSettings hashtable
        Add-MainIconProperties -InputObject $InputObject
        # Add the font properties
        Add-FontProperties -InputObject $InputObject
        # Add the graphical dimensions of the other controls to the GraphicalSettings hashtable
        Add-GraphicalDimensions -InputObject $InputObject


        # EXECUTION - INITIALIZE THE MAIN FORM
        # Create the main form
        Initialize-MainForm -InputObject $InputObject
        # Add the main tab control to the main form
        Add-MainTabControl -InputObject $InputObject -ParentForm $Global:MainForm

        # EXECUTION - ADD TABS
        # Import the tabs
        Import-TabLauncher -InputObject $InputObject -ParentTabControl $Global:MainTabControl
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
    Imports the graphical settings from a specified file and adds them to the main application object.
.DESCRIPTION
    This function imports the graphical settings from a specified file and adds them to the main application object. It searches for the graphical settings file in the specified root folder and its subfolders, imports the settings from the file, and adds them to the main application object under the GraphicalSettings property.
.EXAMPLE
    Import-GraphicalSettings -InputObject $Global:ApplicationObject
.INPUTS
    [PSCustomObject]
    [System.String]
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
function Import-GraphicalSettings {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false,HelpMessage='The ApplicationObject containing the settings.')]
        [PSCustomObject]$InputObject,

        [Parameter(Mandatory=$false,HelpMessage='The name of the graphical settings file.')]
        [System.String]$GraphicalSettingsFileName = 'UI.Graphics.Settings.psd1'
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
        [Parameter(Mandatory=$true,HelpMessage='The ApplicationObject containing the settings.')]
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
        [Parameter(Mandatory=$true,HelpMessage='The ApplicationObject containing the settings.')]
        [PSCustomObject]$InputObject
    )

    try {
        # Add the graphical dimensions of the MainTabControl
        Add-MainTabControlDimensions -InputObject $InputObject
        # Add the graphical dimensions of the GroupBoxes
        Add-GroupBoxDimensions -InputObject $InputObject
        # Add the graphical dimensions of the TextBoxes and ComboBoxes
        Add-TextBoxDimensions -InputObject $InputObject
        # Add the graphical dimensions of the Buttons
        Add-ButtonDimensions -InputObject $InputObject
        # Add the Button Icons as images to the ImageList
        #Add-ButtonIconsToImageList -InputObject $InputObject
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
    Adds an ImageList to the Global ApplicationObject.
.DESCRIPTION
    This function adds an ImageList to the Global ApplicationObject based on the ButtonDimensions in the GraphicalSettings.
.EXAMPLE
    Add-ImageList -InputObject $Global:ApplicationObject
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
function Add-ButtonIconsToImageList {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The ApplicationObject containing the settings.')]
        [PSCustomObject]$InputObject
    )

    try {
        # PREPARATION
        # Create an ImageList object
        [System.Windows.Forms.ImageList]$ImageList = New-Object System.Windows.Forms.ImageList
        # Set the ImageSize property of the ImageList based on the ButtonDimensions in the GraphicalSettings
        [System.Int32]$ImageSize = $InputObject.GraphicalSettings.Button.ImageSize
        # Set the ImageSize property of the ImageList to a square size based on the Button ImageSize
        $ImageList.ImageSize = New-Object System.Drawing.Size($ImageSize,$ImageSize)
        $imageList.ColorDepth = [System.Windows.Forms.ColorDepth]::Depth32Bit

        # PREPARATION - CREATE THE IMAGE LIST        
        Get-ChildItem $InputObject.RootFolder -Filter *.png -Recurse | ForEach-Object {
            # Use the base name of the image file as the key in the ImageList, and load the image from the file
            [System.String]$ImageKeyName        = $_.BaseName
            [System.Drawing.Image]$ImageObject  = [System.Drawing.Image]::FromFile($_.FullName)
            # Add the image to the ImageList with the key name
            $ImageList.Images.Add($ImageKeyName, $ImageObject)
        }

        # EXECUTION - ADD THE IMAGE LIST TO THE GRAPHICAL SETTINGS
        # Set the ImageList in the GraphicalSettings hashtable
        $InputObject.GraphicalSettings.ImageList = $ImageList
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
        [Parameter(Mandatory=$true,HelpMessage='The ApplicationObject containing the settings.')]
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
        [Parameter(Mandatory=$true,HelpMessage='The ApplicationObject containing the settings.')]
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
