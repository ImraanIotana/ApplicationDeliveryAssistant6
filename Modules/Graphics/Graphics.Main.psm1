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
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.1.0
    Author          : Imraan Iotana
    Creation Date   : April 2026
    Last Update     : August 2026
#>
####################################################################################################
function Initialize-Graphics {
    [CmdletBinding()]
    [OutputType([System.Void])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The ApplicationObject containing the settings.')]
        [PSCustomObject]$InputObject
    )

    try {
        # PREPARATION - IMPORT SETTINGS
        # Import the graphical settings from the Graphics Settings file
        Import-GraphicalSettings -InputObject $InputObject

        # PREPARATION - ADD PROPERTIES TO THE MAIN OBJECT
        # Load the assemblies
        Add-Assemblies -InputObject $InputObject
        # Add the main icon to the GraphicalSettings hashtable
        Add-MainIconToSettings -InputObject $InputObject
        # Add the button icons to the GraphicalSettings hashtable
        Add-ButtonIconsToSettings -InputObject $InputObject
        # Add the font properties
        Add-FontProperties -InputObject $InputObject
        # Add the graphical dimensions of the other controls to the GraphicalSettings hashtable
        Add-GraphicalDimensions -InputObject $InputObject

        # EXECUTION - INITIALIZE THE MAIN FORM
        # Create the main form
        Initialize-MainForm -InputObject $InputObject
        # Add the main tab control to the main form
        Add-MainTabControl -InputObject $InputObject -ParentForm $Global:MainForm

        # EXECUTION - Create the Global Graphics Objects
        [System.Collections.Hashtable]$Global:Graphics = @{}
        $Global:Graphics.TextBoxes = @{}
        $Global:Graphics.ComboBoxes = @{}

        # EXECUTION - ADD TABS
        # Get the Global ParentTabControl
        [System.Windows.Forms.TabControl]$ParentTabControl = $Global:MainTabControl
        # Import the tabs
        Import-TabLauncher -InputObject $InputObject -ParentTabControl $ParentTabControl
        Import-TabApplicationIntake -InputObject $InputObject -ParentTabControl $ParentTabControl
        Import-TabDSLManagement -InputObject $InputObject -ParentTabControl $ParentTabControl
        #Import-TabSCCM -InputObject $InputObject -ParentTabControl $ParentTabControl
        #Import-TabAppLocker -InputObject $InputObject -ParentTabControl $ParentTabControl
        Import-TabTools -InputObject $InputObject -ParentTabControl $ParentTabControl
        Import-TabApplicationSettings -InputObject $InputObject -ParentTabControl $ParentTabControl
        
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
    Creates flattened graphics subkeys for both TextBoxes and ComboBoxes.
.DESCRIPTION
    This function creates a normalized flat storage key for controls and initializes it under both $Global:Graphics.TextBoxes and $Global:Graphics.ComboBoxes.
    The key can be built from names, a parent tab page, or a GroupBox, and is used to register TextBox or ComboBox controls with their metadata.
.EXAMPLE
    New-SubKeyForBoxes -TabName 'ApplicationIntake' -FeatureName 'Main'
.EXAMPLE
    New-SubKeyForBoxes -GroupBox $FeatureGroupBox -TextBox $MyTextBox
.INPUTS
    [System.String]
    [System.Windows.Forms.TabPage]
    [System.Windows.Forms.GroupBox]
    [System.Windows.Forms.TextBox]
    [System.Windows.Forms.ComboBox]
.OUTPUTS
    [System.String] The generated flattened key name, or a full TextBoxes/ComboBoxes PropertyName when -TextBox or -ComboBox is supplied.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.2
    Author          : Imraan Iotana
    Creation Date   : July 2026
    Last Update     : July 2026
#>
####################################################################################################
function New-SubKeyForBoxes {
    [CmdletBinding()]
    [OutputType([System.String])]
    param (
        [Parameter(Mandatory=$true,ParameterSetName='ByName',HelpMessage='The tab name for the key path.')]
        [System.String]$TabName,

        [Parameter(Mandatory=$true,ParameterSetName='ByName',HelpMessage='The feature name for the key path.')]
        [System.String]$FeatureName,

        [Parameter(Mandatory=$true,ParameterSetName='ByParentTabPage',HelpMessage='The sub tab page used to derive the tab and feature keys from the current UI hierarchy.')]
        [System.Windows.Forms.TabPage]$ParentTabPage,

        [Parameter(Mandatory=$true,ParameterSetName='ByGroupBox',HelpMessage='The GroupBox used to derive the tab name, feature name, and group box key from the current UI hierarchy.')]
        [System.Windows.Forms.GroupBox]$GroupBox,

        [Parameter(Mandatory=$false,ParameterSetName='ByGroupBox',HelpMessage='Optional TextBox used to derive and return a full TextBoxes PropertyName for the current GroupBox root key.')]
        [System.Windows.Forms.TextBox]$TextBox,

        [Parameter(Mandatory=$false,ParameterSetName='ByGroupBox',HelpMessage='Optional ComboBox used to derive and return a full ComboBoxes PropertyName for the current GroupBox root key.')]
        [System.Windows.Forms.ComboBox]$ComboBox
    )

    try {
        # PREPARATION - ROOT VALIDATION
        # Root keys are initialized by Initialize-Graphics
        if (-not $Global:Graphics -or -not $Global:Graphics.ContainsKey('TextBoxes') -or -not $Global:Graphics.ContainsKey('ComboBoxes')) {
            throw 'Global Graphics root keys are not initialized. Run Initialize-Graphics first.'
        }

        # PREPARATION - LOCAL HELPERS
        # Normalize key parts for consistent flattened storage
        [scriptblock]$NormalizeKeyPart = {
            param([System.String]$Value)

            if ([System.String]::IsNullOrWhiteSpace($Value)) {
                return [System.String]::Empty
            }

            return (($Value -replace '[^A-Za-z0-9]+', '').ToLowerInvariant())
        }

        # PREPARATION - RESOLVE TAB/FEATURE NAMES
        # Resolve names from ParentTabPage when requested
        [System.String[]]$KeyParts = @()
        if ($PSCmdlet.ParameterSetName -eq 'ByGroupBox') {
            if ($GroupBox.Parent -isnot [System.Windows.Forms.TabPage]) {
                throw 'Unable to resolve ParentTabPage from GroupBox. Ensure the GroupBox is attached to a tab page.'
            }

            [System.Windows.Forms.TabPage]$ParentTabPage = $GroupBox.Parent
            [System.Windows.Forms.TabControl]$ParentTabControl = $ParentTabPage.Parent
            [System.Windows.Forms.Control]$ParentTab = if ($ParentTabControl -is [System.Windows.Forms.TabControl]) { $ParentTabControl.Parent } else { $null }

            if ($ParentTab -is [System.Windows.Forms.TabPage]) {
                # Sub-tab scenario: GroupBox is attached to a child page inside a sub-tab control
                $KeyParts = @($ParentTab.Text, $ParentTabPage.Text, $GroupBox.Text)
            }
            elseif ($ParentTabControl -is [System.Windows.Forms.TabControl]) {
                # Main-tab scenario: GroupBox is attached to a page directly on the main tab control
                $KeyParts = @($ParentTabPage.Text, $ParentTabPage.Text, $GroupBox.Text)
            }
            else {
                throw 'Unable to resolve parent tab from GroupBox. Ensure the GroupBox is attached to a tab page inside a tab control.'
            }
        }
        elseif ($PSCmdlet.ParameterSetName -eq 'ByParentTabPage') {
            [System.Windows.Forms.TabControl]$ParentTabControl = $ParentTabPage.Parent
            [System.Windows.Forms.Control]$ParentTab = if ($ParentTabControl -is [System.Windows.Forms.TabControl]) { $ParentTabControl.Parent } else { $null }

            if ($ParentTab -is [System.Windows.Forms.TabPage]) {
                # Sub-tab scenario: ParentTabPage is a child page inside a sub-tab control
                $KeyParts = @($ParentTab.Text, $ParentTabPage.Text)
            }
            elseif ($ParentTabControl -is [System.Windows.Forms.TabControl]) {
                # Main-tab scenario: ParentTabPage is directly attached to the main tab control
                $KeyParts = @($ParentTabPage.Text, $ParentTabPage.Text)
            }
            else {
                throw 'Unable to resolve parent tab from ParentTabPage. Ensure ParentTabPage is attached to a tab control.'
            }
        }
        else {
            $KeyParts = @($TabName, $FeatureName)
        }

        # PREPARATION - NORMALIZE KEY PARTS
        # Normalize names for consistent key storage
        [System.String[]]$NormalizedKeyParts = @(
            $KeyParts |
            ForEach-Object { [System.String](& $NormalizeKeyPart $_) } |
            Where-Object { -not [System.String]::IsNullOrWhiteSpace($_) }
        )

        if ($NormalizedKeyParts.Count -lt 2) {
            throw 'The resolved key must contain at least a tab name and feature name after normalization.'
        }

        # EXECUTION - BUILD AND INITIALIZE FLAT KEY
        # Build a flattened key path in the format tabname.featurename(.groupboxname)
        [System.String]$FlatKeyName = [System.String]::Join('.', $NormalizedKeyParts)

        foreach ($KeyType in @('TextBoxes','ComboBoxes')) {
            if (-not $Global:Graphics.$KeyType.ContainsKey($FlatKeyName)) {
                $Global:Graphics.$KeyType.$FlatKeyName = @{}
            }
        }

        # POST-EXECUTION - CONTROL REGISTRATION
        # When a control is supplied, derive storage metadata, assign Tag properties, and register it in the flattened graphics store.
        if ($PSCmdlet.ParameterSetName -eq 'ByGroupBox') {
            if (($null -ne $TextBox) -and ($null -ne $ComboBox)) {
                throw 'Specify only one control: use either -TextBox or -ComboBox.'
            }
        }

        # Register TextBox controls in the flattened TextBoxes store.
        if ($PSCmdlet.ParameterSetName -eq 'ByGroupBox' -and $null -ne $TextBox) {
            return (Register-GraphicsTextBox -TextBox $TextBox -FlatKeyName $FlatKeyName)
        }

        # Register ComboBox controls in the flattened ComboBoxes store.
        if ($PSCmdlet.ParameterSetName -eq 'ByGroupBox' -and $null -ne $ComboBox) {
            return (Register-GraphicsComboBox -ComboBox $ComboBox -FlatKeyName $FlatKeyName)
        }

        # POST-EXECUTION
        # Return the generated key for follow-up control registration
        $FlatKeyName
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
    Import-GraphicalSettings -InputObject $MyApplicationObject
.INPUTS
    [PSCustomObject]
    [System.String]
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
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
        [System.String]$GraphicalSettingsFileName = 'Settings.Graphics.psd1'
    )

    try {
        # PREPARATION
        # Get the full path to the graphical settings file
        [System.String]$FolderToSearch = $InputObject.RootFolder
        [System.IO.FileInfo]$GraphicalSettingsFileObject = Get-ChildItem -Path $FolderToSearch -File -Filter $GraphicalSettingsFileName -Recurse

        # Check if the graphical settings file was found
        if ($GraphicalSettingsFileObject.Count -ne 1) {
            throw "The graphical settings file ($GraphicalSettingsFileName) was not found in folder ($FolderToSearch) or its subfolders. (Found $($GraphicalSettingsFileObject.Count) files.)"
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
    Add-Assemblies -InputObject $MyApplicationObject
.INPUTS
    [PSCustomObject]
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
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
    Add-GraphicalDimensions -InputObject $MyApplicationObject
.INPUTS
    [PSCustomObject]
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
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
        # Add the graphical dimensions of the TextBoxes
        Add-TextBoxDimensions -InputObject $InputObject
        # Add the graphical dimensions of the ComboBoxes
        Add-ComboBoxDimensions -InputObject $InputObject
        # Add the graphical dimensions of the ListViews
        Add-ListViewDimensions -InputObject $InputObject
        # Add the graphical dimensions of the Buttons
        Add-ButtonDimensions -InputObject $InputObject
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
    Add-FontProperties -InputObject $MyApplicationObject
.INPUTS
    [PSCustomObject]
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
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
        # Set the font for the application based on the MainFont properties from the GraphicalSettings
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
    Add-MainIconToSettings -InputObject $MyApplicationObject
.INPUTS
    [PSCustomObject]
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.0
    Author          : Imraan Iotana
    Creation Date   : May 2026
    Last Update     : May 2026
#>
####################################################################################################
function Add-MainIconToSettings {
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
        [System.Drawing.Icon]$MainIcon = New-Object System.Drawing.Icon($MainIconFileObject.FullName)
        $InputObject.GraphicalSettings.MainIcon = $MainIcon
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
    Adds the ButtonIcons properties to the Global ApplicationObject.
.DESCRIPTION
    This function finds the button icon files from the configured icon file names and stores them as System.Drawing.Image objects in GraphicalSettings.
.EXAMPLE
    Add-ButtonIconsToSettings -InputObject $MyApplicationObject
.INPUTS
    [PSCustomObject]
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.0
    Author          : Imraan Iotana
    Creation Date   : May 2026
    Last Update     : May 2026
#>
####################################################################################################
function Add-ButtonIconsToSettings {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The ApplicationObject containing the settings.')]
        [PSCustomObject]$InputObject
    )

    try {
        # PREPARATION
        # Get the button icon files
        [System.String]$FolderToSearch = $InputObject.RootFolder
        [System.IO.FileInfo[]]$ButtonIconFileObjects = Get-ChildItem -Path $FolderToSearch -File -Filter *.png -Recurse

        # Create a hashtable for the button icons
        [System.Collections.Hashtable]$ButtonIcons = @{}
        # Add the button icons to the hashtable
        foreach ($ButtonIconFileObject in $ButtonIconFileObjects) {
            [System.Byte[]]$IconBytes                       = [System.IO.File]::ReadAllBytes($ButtonIconFileObject.FullName)
            [System.IO.MemoryStream]$MemoryStream           = New-Object System.IO.MemoryStream(,$IconBytes)
            [System.Drawing.Image]$ButtonIcon               = [System.Drawing.Image]::FromStream($MemoryStream)
            $ButtonIcons[$ButtonIconFileObject.BaseName]    = $ButtonIcon
        }
        $InputObject.GraphicalSettings.ButtonIcons = $ButtonIcons
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}

### END OF FUNCTION
####################################################################################################
