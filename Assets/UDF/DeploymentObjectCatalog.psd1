####################################################################################################
<#
.SYNOPSIS
    UNIVERSAL DEPLOYMENT FRAMEWORK: Deployment object catalog metadata.
.DESCRIPTION
    This file contains machine-readable metadata used by the UDF editor Add dialog and
    property Info column. It is intentionally separated from DeploymentData.psd1 so user-facing
    deployment content stays clean and easy to copy/paste.
.NOTES
    Version         : See below at the CatalogVersion property.
    Author          : Imraan Iotana
    Creation Date   : August 2026
    Last Update     : August 2026
.COPYRIGHT
    This script is part of the Universal Deployment Framework. Copyright (C) Iotana. Licensed under the Apache License 2.0.
#>
####################################################################################################

# MAINTENANCE GUIDANCE
# - Keep object type keys stable (for example: DEPLOYMSI, DEPLOYREGFILE, DEPLOYPAUSE).
# - Keep Fields order intentional; it is used as preferred UI/edit order.
# - Keep TemplateComment aligned with the user-facing green inline guidance text.
# - Add new object types here first before enabling them in user templates.
@{
    CatalogVersion = '1.2.3'

    # Top-level DeploymentData properties shown in the editor main settings area.
    MainProperties = @(
        @{ Name = 'ApplicationID'; Type = 'System.String'; Required = $true; Default = '<<APPLICATIONID>>'; DisplayType = 'Mandatory String'; Description = 'Unique application identifier used for logging and reporting.'; TemplateComment = '(Mandatory String) Set the APPLICATION ID. (This is used for logging and reporting, and must be unique for each application. Example: ''Contoso_WebViewer_3.14'')' }
        @{ Name = 'BuildNumber'; Type = 'System.String'; Required = $true; Default = '01'; DisplayType = 'Mandatory String'; Description = 'Build number used for logging and reporting.'; TemplateComment = '(Mandatory String) Set the BUILD NUMBER. (This is used for logging and reporting, and can be used to differentiate between different builds of the same application. Example: ''02'')' }
        @{ Name = 'SourceFilesFolder'; Type = 'System.String'; Required = $true; Default = 'Default'; DisplayType = 'Mandatory String'; Description = 'Source files folder or token used by the deployment.'; TemplateComment = '(Mandatory String) If the sourcefiles are on a hardcoded location, then change this value. Else leave it as ''Default'' and place your sourcefiles in the subfolder named ''SourceFiles''' }
    )

    # Deployment object definitions used for Add dialog options and default values.
    ObjectTypes = @{
        DEPLOYMSI = @{
            Category = '10 - GENERAL INSTALLATIONS'
            DisplayName = 'Deploy MSI'
            PickerOrder = 10
            Description = 'Installs and uninstalls an MSI package.'
            Fields = @(
                @{ Name = 'MSIFileName'; Type = 'System.String'; Required = $true; Default = ''; DisplayType = 'Mandatory String'; Description = 'MSI file name including extension.'; TemplateComment = '(Mandatory String) Set the MSI FILENAME. Example: ''Contoso-Webviewer-3.14.msi''.' }
                @{ Name = 'MSTFileName'; Type = 'System.String'; Required = $false; Default = ''; DisplayType = 'Optional String'; Description = 'Optional MST transform file name.'; TemplateComment = '(Optional String) Set the MST FILENAME. Example: ''Webviewer_WithMyAdjustments.mst''. (If there is no MST file then leave this empty.)' }
                @{ Name = 'MSPFileNames'; Type = 'System.String[]'; Required = $false; Default = @(); DisplayType = 'Optional String Array'; Description = 'Optional MSP patch files.'; TemplateComment = '(Optional String Array) Set the MSP FILENAMES. Example: @(''WebviewerPatch01.msp'',''WebviewerPatch02.msp''). (If there are no MSP''s then leave this empty.)' }
                @{ Name = 'AdditionalArguments'; Type = 'System.String[]'; Required = $false; Default = @(); DisplayType = 'Optional String Array'; Description = 'Additional MSI install arguments.'; TemplateComment = '(Optional String Array) Add any ADDITIONAL INSTALL arguments. Example: @(''ADDLOCAL=ALL'',''ALLUSERS=1'',''REBOOT=Suppress''). (If there are no additional arguments then leave this empty.)' }
                @{ Name = 'InstallSuccessExitCodes'; Type = 'System.Int32[]'; Required = $true; Default = @(0,3010); DisplayType = 'Mandatory Integer Array'; Description = 'Accepted install return codes.'; TemplateComment = '(Mandatory Integer Array) Set the INSTALL SUCCESS EXIT CODES for the MSI. (The default value is @(0,3010).)' }
                @{ Name = 'UninstallSuccessExitCodes'; Type = 'System.Int32[]'; Required = $true; Default = @(0,3010); DisplayType = 'Mandatory Integer Array'; Description = 'Accepted uninstall return codes.'; TemplateComment = '(Mandatory Integer Array) Set the UNINSTALL SUCCESS EXIT CODES for the MSI. (The default value is @(0,3010).)' }
            )
        }

        MSIX = @{
            Category = '10 - GENERAL INSTALLATIONS'
            DisplayName = 'Deploy MSIX'
            PickerOrder = 20
            Description = 'Deploys one or more MSIX packages machine-wide.'
            Fields = @(
                @{ Name = 'MSIXFileNames'; Type = 'System.String[]'; Required = $true; Default = @(); DisplayType = 'Mandatory String Array'; Description = 'MSIX filenames including extension.'; TemplateComment = '(Mandatory String Array) Set the MSIX Filenames WITH the extension. Example: @(''NotepadPlusPlus_8.4.8.1_x64__h8vhay9grb1ec.msix'',''Orca-5.0.10011x64__h8vhay9grb1ec.msix'')' }
            )
        }

        DEPLOYEXECUTABLE = @{
            Category = '10 - GENERAL INSTALLATIONS'
            DisplayName = 'Deploy Executable'
            PickerOrder = 30
            Description = 'Legacy executable deployment object for install/uninstall flows.'
            Fields = @(
                @{ Name = 'InstallEXEBaseName'; Type = 'System.String'; Required = $true; Default = ''; DisplayType = 'Mandatory String'; Description = 'Install EXE base name without extension.'; TemplateComment = '(Mandatory String) Set the INSTALL EXE BASENAME WITHOUT the extension. Example: ''setup''' }
                @{ Name = 'InstallArguments'; Type = 'System.String[]'; Required = $false; Default = @(); DisplayType = 'Optional String Array'; Description = 'Optional install arguments.'; TemplateComment = '(Optional String Array) Set the INSTALL ARGUMENTS for the Executable. Example: @(''/SILENT'',''/nodesktopshortcut'')' }
                @{ Name = 'InstallSuccessExitCodes'; Type = 'System.Int32[]'; Required = $true; Default = @(0); DisplayType = 'Mandatory Integer Array'; Description = 'Accepted install return codes.'; TemplateComment = '(Mandatory Integer Array) Set the INSTALL SUCCESS EXIT CODES for the Executable. Example: @(0,123) (The default value is @(0).)' }
                @{ Name = 'UninstallEXEOnLocalSystem'; Type = 'System.String'; Required = $false; Default = ''; DisplayType = 'Optional String'; Description = 'Optional full path of uninstall executable.'; TemplateComment = '(Exclusive String) If the UNINSTALL EXE file is on the Local System, then enter the FULL PATH. Example: ''C:\Program Files\MyApplication\Uninstall.exe''' }
                @{ Name = 'UninstallEXEBaseName'; Type = 'System.String'; Required = $false; Default = ''; DisplayType = 'Optional String'; Description = 'Optional uninstall executable base name in source files.'; TemplateComment = '(Exclusive String) If the UNINSTALL EXE file is in the Source Files, then enter the BASENAME. Example: ''setup''' }
                @{ Name = 'UninstallArguments'; Type = 'System.String[]'; Required = $false; Default = @(); DisplayType = 'Optional String Array'; Description = 'Optional uninstall arguments.'; TemplateComment = '(Optional String Array) Set the UNINSTALL ARGUMENTS for the Executable. Example: @(''/SILENT'')' }
                @{ Name = 'UninstallSuccessExitCodes'; Type = 'System.Int32[]'; Required = $true; Default = @(0); DisplayType = 'Mandatory Integer Array'; Description = 'Accepted uninstall return codes.'; TemplateComment = '(Mandatory Integer Array) Set the UNINSTALL SUCCESS EXIT CODES for the Executable. Example: @(0,123) (The default value is @(0).)' }
                @{ Name = 'ZipFileBaseName'; Type = 'System.String'; Required = $false; Default = ''; DisplayType = 'Optional String'; Description = 'Optional source zip base name without extension.'; TemplateComment = '(Optional String) If the Source Files are in a zip file, then set the BASENAME of the zip-file, EXCLUDING the extension (.zip). Example: ''MyZipFile''.' }
            )
        }

        DEPLOYINNOSETUP = @{
            Category = '10 - GENERAL INSTALLATIONS'
            DisplayName = 'Deploy Inno Setup'
            PickerOrder = 40
            Description = 'Legacy executable deployment for Inno Setup based installers.'
            Fields = @(
                @{ Name = 'InstallEXEBaseName'; Type = 'System.String'; Required = $true; Default = ''; DisplayType = 'Mandatory String'; Description = 'Install EXE base name without extension.'; TemplateComment = '(Mandatory String) Set the INSTALL EXE BASENAME WITHOUT the extension. Example: ''setup''' }
                @{ Name = 'InstallINFBaseName'; Type = 'System.String'; Required = $true; Default = ''; DisplayType = 'Mandatory String'; Description = 'Install INF base name without extension.'; TemplateComment = '(Mandatory String) Set the INSTALL INF BASENAME WITHOUT the extension. Example: ''InstallationConfuguration''.' }
                @{ Name = 'AdditionalInstallArguments'; Type = 'System.String[]'; Required = $false; Default = @('/VERYSILENT'); DisplayType = 'Optional String Array'; Description = 'Optional additional install arguments.'; TemplateComment = '(Optional String Array) Set the INSTALL ARGUMENTS for the Executable. Example: @(''/SILENT'',''/nodesktopshortcut'')' }
                @{ Name = 'InstallSuccessExitCodes'; Type = 'System.Int32[]'; Required = $true; Default = @(0); DisplayType = 'Mandatory Integer Array'; Description = 'Accepted install return codes.'; TemplateComment = '(Mandatory Integer Array) Set the INSTALL SUCCESS EXIT CODES for the Executable. Example: @(0,123) (The default value is @(0).)' }
                @{ Name = 'UninstallEXEFilePath'; Type = 'System.String'; Required = $false; Default = ''; DisplayType = 'Optional String'; Description = 'Optional full path to uninstall executable including extension.'; TemplateComment = '(Optional String) Set the UNINSTALL EXE file path INCLUDING the extension (.exe). If there is no executable to run during UNINSTALL, then leave this empty.' }
                @{ Name = 'UninstallArguments'; Type = 'System.String[]'; Required = $false; Default = @('/VERYSILENT'); DisplayType = 'Optional String Array'; Description = 'Optional uninstall arguments.'; TemplateComment = '(Optional String Array) Set the UNINSTALL ARGUMENTS for the Executable. Example: @(''/SILENT'')' }
                @{ Name = 'UninstallSuccessExitCodes'; Type = 'System.Int32[]'; Required = $true; Default = @(0); DisplayType = 'Mandatory Integer Array'; Description = 'Accepted uninstall return codes.'; TemplateComment = '(Mandatory Integer Array) Set the UNINSTALL SUCCESS EXIT CODES for the Executable. Example: @(0,123) (The default value is @(0).)' }
            )
        }

        DEPLOYISSSETUP = @{
            Category = '10 - GENERAL INSTALLATIONS'
            DisplayName = 'Deploy ISS Setup'
            PickerOrder = 50
            Description = 'Legacy executable deployment using ISS response files.'
            Fields = @(
                @{ Name = 'InstallEXEBaseName'; Type = 'System.String'; Required = $true; Default = ''; DisplayType = 'Mandatory String'; Description = 'Install EXE base name without extension.'; TemplateComment = '(Mandatory String) Set the INSTALL EXE BASENAME WITHOUT the extension. Example: ''setup''' }
                @{ Name = 'InstallISSBaseName'; Type = 'System.String'; Required = $true; Default = ''; DisplayType = 'Mandatory String'; Description = 'Install ISS base name without extension.'; TemplateComment = '(Mandatory String) Set the INSTALL INF BASENAME WITHOUT the extension. Example: ''InstallationConfuguration''.' }
                @{ Name = 'AdditionalInstallArguments'; Type = 'System.String[]'; Required = $false; Default = @(); DisplayType = 'Optional String Array'; Description = 'Optional additional install arguments.'; TemplateComment = '(Optional String Array) Set any ADDITIONAL INSTALL ARGUMENTS for the Executable. Example: @(''/norestart'',''/nodesktopshortcut'')' }
                @{ Name = 'InstallSuccessExitCodes'; Type = 'System.Int32[]'; Required = $true; Default = @(0); DisplayType = 'Mandatory Integer Array'; Description = 'Accepted install return codes.'; TemplateComment = '(Mandatory Integer Array) Set the INSTALL SUCCESS EXIT CODES for the Executable. Example: @(0,123) (The default value is @(0).)' }
                @{ Name = 'UninstallEXEOnLocalSystem'; Type = 'System.String'; Required = $false; Default = ''; DisplayType = 'Optional String'; Description = 'Optional full path to uninstall executable.'; TemplateComment = '(Exclusive String) If the UNINSTALL EXE file is on the Local System, then enter the FULL PATH. Example: ''C:\Program Files\MyApplication\Uninstall.exe''' }
                @{ Name = 'UninstallEXEInSourceFiles'; Type = 'System.String'; Required = $false; Default = ''; DisplayType = 'Optional String'; Description = 'Optional uninstall executable base name in source files.'; TemplateComment = '(Exclusive String) If the UNINSTALL EXE file is in the Source Files, then enter the BASENAME. Example: ''setup''' }
                @{ Name = 'UninstallISSBaseName'; Type = 'System.String'; Required = $false; Default = ''; DisplayType = 'Optional String'; Description = 'Optional uninstall ISS base name.'; TemplateComment = '(Optional String) Set the UNINSTALL INF BASENAME WITHOUT the extension. Example: ''UninstallConfuguration''.' }
                @{ Name = 'AdditionalUninstallArguments'; Type = 'System.String[]'; Required = $false; Default = @(); DisplayType = 'Optional String Array'; Description = 'Optional additional uninstall arguments.'; TemplateComment = '(Optional String Array) Set any ADDITIONAL UNINSTALL ARGUMENTS for the Executable. Example: @(''/norestart'')' }
                @{ Name = 'UninstallSuccessExitCodes'; Type = 'System.Int32[]'; Required = $true; Default = @(0); DisplayType = 'Mandatory Integer Array'; Description = 'Accepted uninstall return codes.'; TemplateComment = '(Mandatory Integer Array) Set the UNINSTALL SUCCESS EXIT CODES for the Executable. Example: @(0,123) (The default value is @(0).)' }
            )
        }

        DEPLOYMSOFFICE = @{
            Category = '10 - GENERAL INSTALLATIONS'
            DisplayName = 'Deploy MS Office'
            PickerOrder = 60
            Description = 'Deploys Microsoft Office using setup and configuration files.'
            Fields = @(
                @{ Name = 'SetupFileBaseName'; Type = 'System.String'; Required = $true; Default = ''; DisplayType = 'Mandatory String'; Description = 'Office setup file base name without extension.'; TemplateComment = '(Mandatory String) Set the BASENAME the SETUP file. Example: ''setup''' }
                @{ Name = 'InstallXMLFileBaseName'; Type = 'System.String'; Required = $true; Default = ''; DisplayType = 'Mandatory String'; Description = 'Office configuration XML base name without extension.'; TemplateComment = '(Mandatory String) Set the BASENAME the CONFIGURATION file. Example: ''Office2024Configuration''' }
                @{ Name = 'ProductsToLicense'; Type = 'System.String[]'; Required = $false; Default = @(); DisplayType = 'Optional String Array'; Description = 'Optional Office product IDs to license.'; TemplateComment = '(Optional String Array) Set the PRODUCT ID''s that need to be licensed. Example: @(''ProPlus2024Volume'',''VisioPro2024Volume''). When using MS Office AutoActivation, then leave this empty.' }
            )
        }

        VSTO = @{
            Category = '10 - GENERAL INSTALLATIONS'
            DisplayName = 'Deploy VSTO'
            PickerOrder = 70
            Description = 'Deploys a VSTO add-in from a path or URL.'
            Fields = @(
                @{ Name = 'VSTOPathOrURL'; Type = 'System.String'; Required = $true; Default = ''; DisplayType = 'Mandatory String'; Description = 'Path or URL of VSTO add-in.'; TemplateComment = '(Mandatory String) The URL of the VSTO. Example: ''https://VendorURL.com/OfficeAddins/VendorAddin.vsto''' }
            )
        }

        DOTNET35 = @{
            Category = '10 - GENERAL INSTALLATIONS'
            DisplayName = 'Deploy .NET 3.5'
            PickerOrder = 80
            Description = 'Installs .NET Framework 3.5 from local source or online source.'
            Fields = @(
                @{ Name = 'LocalSourcePath'; Type = 'System.String'; Required = $false; Default = ''; DisplayType = 'Optional String'; Description = 'Optional local source path for Windows feature files.'; TemplateComment = '(Optional String) If there is an on-premise location with the Windows Features, then add this here. If empty then the sourcefiles will be downloaded from the internet.' }
                @{ Name = 'RemoveDuringUninstall'; Type = 'System.Boolean'; Required = $true; Default = $false; DisplayType = 'Mandatory Boolean'; Description = 'Remove .NET 3.5 during uninstall.'; TemplateComment = '(Mandatory Boolean) If DotNet should be removed during UNINSTALL, then set this value to $true.' }
            )
        }

        REMOVEMSI = @{
            Category = '10 - GENERAL INSTALLATIONS'
            DisplayName = 'Remove MSI'
            PickerOrder = 90
            Description = 'Legacy MSI removal object for compatibility scenarios.'
            Fields = @(
                @{ Name = 'MSIBaseNamesOrProductCodes'; Type = 'System.String[]'; Required = $true; Default = @(); DisplayType = 'Mandatory String Array'; Description = 'MSI file names or product codes to remove.'; TemplateComment = '(Mandatory String Array) Enter EITHER the MSI Filename OR the MSI Productcode. Example: @(''MyApplication.msi'',''{6B29FC40-CA47-1067-B31D-00DD010662DA}'').' }
                @{ Name = 'RemoveDuringInstall'; Type = 'System.Boolean'; Required = $true; Default = $true; DisplayType = 'Mandatory Boolean'; Description = 'Remove MSI during install.'; TemplateComment = '(Mandatory Boolean) If the MSI should be removed DURING INSTALL, then set this to $true.' }
                @{ Name = 'RemoveDuringUninstall'; Type = 'System.Boolean'; Required = $true; Default = $false; DisplayType = 'Mandatory Boolean'; Description = 'Remove MSI during uninstall.'; TemplateComment = '(Mandatory Boolean) If the MSI should be removed DURING UNINSTALL, then set this to $true.' }
                @{ Name = 'UninstallSuccessExitCodes'; Type = 'System.Int32[]'; Required = $true; Default = @(0,3010); DisplayType = 'Mandatory Integer Array'; Description = 'Accepted uninstall return codes.'; TemplateComment = '(Mandatory Integer Array) Set the UNINSTALL SUCCESS EXIT CODES for the MSI. Example: @(0,123) (The default value is @(0,3010).)' }
            )
        }

        DEPLOYBASICFILECOPY = @{
            Category = '20 - FILES AND FOLDERS'
            DisplayName = 'Deploy Basic File Copy'
            PickerOrder = 10
            Description = 'Copies a file during install and removes it during uninstall.'
            Fields = @(
                @{ Name = 'FileToCopy'; Type = 'System.String'; Required = $true; Default = ''; DisplayType = 'Mandatory String'; Description = 'Name of the source file to copy.'; TemplateComment = '(Mandatory String) Set NAME of the FILE to copy. Example: ''WebViewerConfiguration.xml''' }
                @{ Name = 'DestinationFolder'; Type = 'System.String'; Required = $true; Default = ''; DisplayType = 'Mandatory String'; Description = 'Destination folder path for copied file.'; TemplateComment = '(Mandatory String) Set the DESTINATION FOLDER to which the file will be copied. Example: ''C:\ProgramData\WebViewer''' }
                @{ Name = 'OverwriteExistingFile'; Type = 'System.Boolean'; Required = $true; Default = $false; DisplayType = 'Mandatory Boolean'; Description = 'Overwrite destination file if it already exists.'; TemplateComment = '(Mandatory Boolean) If an existing file needs to be overwritten, then set this value to $true.' }
            )
        }

        DEPLOYBASICFOLDERCOPY = @{
            Category = '20 - FILES AND FOLDERS'
            DisplayName = 'Deploy Basic Folder Copy'
            PickerOrder = 20
            Description = 'Copies a source folder during install and removes it during uninstall.'
            Fields = @(
                @{ Name = 'FolderToCopy'; Type = 'System.String'; Required = $true; Default = ''; DisplayType = 'Mandatory String'; Description = 'Name of the source folder to copy.'; TemplateComment = '(Mandatory String) Set NAME OF THE FOLDER to copy. Example: ''MyApplication''' }
                @{ Name = 'DestinationFolder'; Type = 'System.String'; Required = $true; Default = 'C:\Program Files'; DisplayType = 'Mandatory String'; Description = 'Destination folder path on the local system.'; TemplateComment = '(Mandatory String) Set the DESTINATION FOLDER to which your folder will be copied. Example: ''C:\Program Files''' }
                @{ Name = 'KeepCurrentFolderName'; Type = 'System.Boolean'; Required = $true; Default = $true; DisplayType = 'Mandatory Boolean'; Description = 'Keep the copied folder name instead of renaming.'; TemplateComment = '(Mandatory Boolean) If you want to keep the current foldername, then set this value to $true. Otherwise it will be renamed to the ApplicationID.' }
            )
        }

        DEPLOYCOMPRESSEDFOLDER = @{
            Category = '20 - FILES AND FOLDERS'
            DisplayName = 'Deploy Compressed Folder'
            PickerOrder = 30
            Description = 'Extracts a zip file to a destination folder and removes that folder during uninstall.'
            Fields = @(
                @{ Name = 'ZipFileName'; Type = 'System.String'; Required = $true; Default = ''; DisplayType = 'Mandatory String'; Description = 'Zip file name including extension.'; TemplateComment = '(Mandatory String) Set the NAME of the zip-file, including the extension. Example: ''MyZipFile.zip''.' }
                @{ Name = 'DestinationFolder'; Type = 'System.String'; Required = $true; Default = 'C:\Program Files\Webviewer'; DisplayType = 'Mandatory String'; Description = 'Destination folder where the zip content will be extracted.'; TemplateComment = '(Mandatory String) Set the DESTINATION FOLDER to which the zipfile will be extracted. Example: ''C:\Program Files\Contoso\WebViewer''' }
                @{ Name = 'SkipTopFolderInsideZipFile'; Type = 'System.Boolean'; Required = $true; Default = $true; DisplayType = 'Mandatory Boolean'; Description = 'Ignore the top-level folder inside the zip file.'; TemplateComment = '(Mandatory Boolean) If the topmost folder inside the zip file should be ignored, then set this value to $true.' }
            )
        }

        DEPLOYFONT = @{
            Category = '20 - FILES AND FOLDERS'
            DisplayName = 'Deploy Fonts'
            PickerOrder = 40
            Description = 'Installs one or more font files.'
            Fields = @(
                @{ Name = 'FontFileNames'; Type = 'System.String[]'; Required = $true; Default = @(); DisplayType = 'Mandatory String Array'; Description = 'Font filenames including extension (.ttf/.otf).'; TemplateComment = '(Mandatory String Array) Set the font FILENAMES INCLUDING the EXTENSION (.ttf, .otf). Example: @(''Flora.ttf'',''Fauna.otf'')' }
            )
        }

        DEPLOYPOWERSHELLAPP = @{
            Category = '20 - FILES AND FOLDERS'
            DisplayName = 'Deploy PowerShell App'
            PickerOrder = 50
            Description = 'Deploys a PowerShell app package and shortcut metadata.'
            Fields = @(
                @{ Name = 'Ps1FileBaseName'; Type = 'System.String'; Required = $true; Default = ''; DisplayType = 'Mandatory String'; Description = 'PS1 script base name without extension.'; TemplateComment = '(Mandatory String) Set the BASENAME of the PS1-file, WITHOUT the extension (.ps1). Example: ''MyScript''.' }
                @{ Name = 'ShortcutDisplayName'; Type = 'System.String'; Required = $true; Default = ''; DisplayType = 'Mandatory String'; Description = 'Shortcut display name.'; TemplateComment = '(Mandatory String) Set the DISPLAYNAME of the shortcut. Example: ''Start MyScript''' }
                @{ Name = 'StartMenuSubFolder'; Type = 'System.String'; Required = $false; Default = ''; DisplayType = 'Optional String'; Description = 'Optional start menu subfolder.'; TemplateComment = '(Optional String) Set the Startmenu SUBFOLDER. Example: ''My Application''' }
            )
        }

        DEPLOYSYSTEMFILECOPY = @{
            Category = '20 - FILES AND FOLDERS'
            DisplayName = 'Deploy System File Copy'
            PickerOrder = 60
            Description = 'Copies a file from local system to another local folder during install and/or uninstall.'
            Fields = @(
                @{ Name = 'FilePathToCopy'; Type = 'System.String'; Required = $true; Default = ''; DisplayType = 'Mandatory String'; Description = 'Full path to the source file.'; TemplateComment = '(Mandatory String) Set FULL PATH of the FILE to copy. Example: ''C:\Windows\System32\Robocopy.exe''' }
                @{ Name = 'DestinationFolder'; Type = 'System.String'; Required = $true; Default = ''; DisplayType = 'Mandatory String'; Description = 'Destination folder path.'; TemplateComment = '(Mandatory String) Set the DESTINATION FOLDER to which your file will be copied. Example: ''C:\Program Files\MyApplication''' }
                @{ Name = 'NewFileName'; Type = 'System.String'; Required = $false; Default = ''; DisplayType = 'Optional String'; Description = 'Optional new filename after copy.'; TemplateComment = '(Optional String) If the file must be renamed, then set NEW NAME of the file to copy. Example: ''MyCopyOfRobocopy.exe''. Otherwise leave this empty.' }
                @{ Name = 'OverwriteExistingFile'; Type = 'System.Boolean'; Required = $true; Default = $false; DisplayType = 'Mandatory Boolean'; Description = 'Overwrite destination file if it already exists.'; TemplateComment = '(Mandatory Boolean) If an existing file needs to be overwritten, then set this value to $true.' }
                @{ Name = 'CopyDuringInstall'; Type = 'System.Boolean'; Required = $true; Default = $true; DisplayType = 'Mandatory Boolean'; Description = 'Copy file during install.'; TemplateComment = '(Mandatory Boolean) If the file needs to be copied during INSTALL, then set this value to $true.' }
                @{ Name = 'CopyDuringUninstall'; Type = 'System.Boolean'; Required = $true; Default = $false; DisplayType = 'Mandatory Boolean'; Description = 'Copy file during uninstall.'; TemplateComment = '(Mandatory Boolean) If the file needs to be copied during UNINSTALL, then set this value to $true.' }
            )
        }

        DEPLOYUSERFILE = @{
            Category = '20 - FILES AND FOLDERS'
            DisplayName = 'Deploy User File'
            PickerOrder = 70
            Description = 'Copies a file to a selected user profile location and optionally removes it during uninstall.'
            Fields = @(
                @{ Name = 'FileToCopy'; Type = 'System.String'; Required = $true; Default = ''; DisplayType = 'Mandatory String'; Description = 'Source file name including extension.'; TemplateComment = '(Mandatory String) Set the FILE name INCLUDING the extension. Example: ''settings.ini''' }
                @{ Name = 'UserProfileLocation'; Type = 'System.String'; Required = $true; Default = 'Roaming'; DisplayType = 'Mandatory String'; Description = 'Target user profile location (Roaming, Local, LocalLow, UserProfile).'; TemplateComment = '(Mandatory String) Set the Userfolder to copy to. Valid values are ''Roaming'', ''Local'', ''LocalLow'' or ''UserProfile''' }
                @{ Name = 'SubfolderToCopyTo'; Type = 'System.String'; Required = $true; Default = ''; DisplayType = 'Mandatory String'; Description = 'Subfolder path under selected user profile location.'; TemplateComment = '(Mandatory String) Set the subfolder to copy the file to. Example: ''Vendor\Configuration Files''.' }
                @{ Name = 'OverwriteExistingFile'; Type = 'System.Boolean'; Required = $true; Default = $false; DisplayType = 'Mandatory Boolean'; Description = 'Overwrite destination file when it already exists.'; TemplateComment = '(Mandatory Boolean) If an existing file needs to be overwritten, then set this value to $true.' }
                @{ Name = 'RemoveDuringUninstall'; Type = 'System.Boolean'; Required = $true; Default = $false; DisplayType = 'Mandatory Boolean'; Description = 'Remove copied file during uninstall.'; TemplateComment = '(Mandatory Boolean) If the file needs to be removed during uninstall, then set this value to $true.' }
            )
        }

        DEPLOYUSERPROFILEFOLDER = @{
            Category = '20 - FILES AND FOLDERS'
            DisplayName = 'Deploy User Profile Folder'
            PickerOrder = 80
            Description = 'Copies a folder to a selected user profile location and optionally removes it during uninstall.'
            Fields = @(
                @{ Name = 'FolderToCopy'; Type = 'System.String'; Required = $true; Default = ''; DisplayType = 'Mandatory String'; Description = 'Source folder name to copy.'; TemplateComment = '(Mandatory String) Set the FOLDER name to copy. Example: ''MyConfigFolder''' }
                @{ Name = 'UserProfileLocation'; Type = 'System.String'; Required = $true; Default = 'Roaming'; DisplayType = 'Mandatory String'; Description = 'Target user profile location (Roaming, Local, LocalLow, UserProfile).'; TemplateComment = '(Mandatory String) Set the UserProfileLocation to copy to. Valid values are ''Roaming'', ''Local'', ''LocalLow'' or ''UserProfile''' }
                @{ Name = 'OverwriteExistingFolder'; Type = 'System.Boolean'; Required = $true; Default = $false; DisplayType = 'Mandatory Boolean'; Description = 'Overwrite destination folder when it already exists.'; TemplateComment = '(Mandatory Boolean) If an existing folder needs to be overwritten, then set this value to $true.' }
                @{ Name = 'RemoveDuringUninstall'; Type = 'System.Boolean'; Required = $true; Default = $false; DisplayType = 'Mandatory Boolean'; Description = 'Remove copied folder during uninstall.'; TemplateComment = '(Mandatory Boolean) If the folder needs to be removed during uninstall, then set this value to $true.' }
            )
        }

        DEPLOYCOPYFILE = @{
            Category = '30 - FILES'
            DisplayName = 'Copy File'
            PickerOrder = 10
            Description = 'Copies a file during install and optionally removes it during uninstall.'
            Fields = @(
                @{ Name = 'SourceFileName'; Type = 'System.String'; Required = $true; Default = ''; DisplayType = 'Mandatory String'; Description = 'Source file name including extension.'; TemplateComment = '(Mandatory String) Set the SOURCE FILE NAME including extension. Example: ''config.json''.' }
                @{ Name = 'DestinationPath'; Type = 'System.String'; Required = $true; Default = ''; DisplayType = 'Mandatory String'; Description = 'Destination folder path where the file is copied.'; TemplateComment = '(Mandatory String) Set the DESTINATION PATH where the file should be copied. Example: ''C:\ProgramData\Contoso''.' }
                @{ Name = 'OverwriteIfExists'; Type = 'System.Boolean'; Required = $true; Default = $true; DisplayType = 'Mandatory Boolean'; Description = 'Overwrite destination file when it already exists.'; TemplateComment = '(Mandatory Boolean) If an existing destination file should be overwritten, set this value to $true.' }
                @{ Name = 'RemoveDuringUninstall'; Type = 'System.Boolean'; Required = $true; Default = $false; DisplayType = 'Mandatory Boolean'; Description = 'Remove copied file during uninstall.'; TemplateComment = '(Mandatory Boolean) If the copied file should be removed during UNINSTALL, set this value to $true.' }
            )
        }

        DEPLOYSHORTCUT = @{
            Category = '50 - SHORTCUTS'
            DisplayName = 'Deploy Shortcut'
            PickerOrder = 10
            Description = 'Creates shortcut(s) during install and removes them during uninstall.'
            Fields = @(
                @{ Name = 'DisplayName'; Type = 'System.String'; Required = $true; Default = ''; DisplayType = 'Mandatory String'; Description = 'Shortcut display name.'; TemplateComment = '(Mandatory String) Set the DISPLAYNAME of the Shortcut. Example: ''Help for Users''' }
                @{ Name = 'TargetPath'; Type = 'System.String'; Required = $true; Default = ''; DisplayType = 'Mandatory String'; Description = 'Full path to target file or folder.'; TemplateComment = '(Mandatory String) Set the FULL PATH of the Target file or folder. Example: ''C:\Program Files\MyDemoApp\help.exe''' }
                @{ Name = 'WorkingDirectory'; Type = 'System.String'; Required = $false; Default = ''; DisplayType = 'Optional String'; Description = 'Working directory used by the shortcut.'; TemplateComment = '(Optional String) Set the WORKING DIRECTORY of the Shortcut. Example: ''C:\Program Files\MyDemoApp''' }
                @{ Name = 'Arguments'; Type = 'System.String'; Required = $false; Default = ''; DisplayType = 'Optional String'; Description = 'Optional arguments for target process.'; TemplateComment = '(Optional String) Set the ARGUMENTS for the Target File. Example: ''-readonly''' }
                @{ Name = 'IconFileName'; Type = 'System.String'; Required = $false; Default = ''; DisplayType = 'Optional String'; Description = 'Optional icon file name from source files.'; TemplateComment = '(Optional String) Set the FILENAME of the ICON FILE, INCLUDING the extension (.ico), and add it to the sourcefiles. Example: ''MyIcon.ico''' }
                @{ Name = 'StartMenuSubFolder'; Type = 'System.String'; Required = $false; Default = ''; DisplayType = 'Optional String'; Description = 'Optional Start menu subfolder.'; TemplateComment = '(Optional String) Set the Startmenu SUBFOLDER. Example: ''MyDemoApp''' }
                @{ Name = 'AlsoPlaceOnDesktop'; Type = 'System.Boolean'; Required = $true; Default = $false; DisplayType = 'Mandatory Boolean'; Description = 'Also place the shortcut on desktop.'; TemplateComment = '(Mandatory Boolean) If the shortcut should also be placed on the Desktop, then set this value to $true. Otherwise it will be placed in the Startmenu only.' }
            )
        }

        REMOVESHORTCUT = @{
            Category = '50 - SHORTCUTS'
            DisplayName = 'Remove Shortcut'
            PickerOrder = 20
            Description = 'Removes shortcut files during install and/or uninstall.'
            Fields = @(
                @{ Name = 'ShortcutFileName'; Type = 'System.String'; Required = $true; Default = ''; DisplayType = 'Mandatory String'; Description = 'Shortcut file name including extension.'; TemplateComment = '(Mandatory String) Set the FILENAME of the SHORTCUT to remove, INCLUDING the extension. Examples: ''Acrobat Cloud.lnk'' or ''Online Registration.url''' }
                @{ Name = 'PerformDuringInstall'; Type = 'System.Boolean'; Required = $true; Default = $true; DisplayType = 'Mandatory Boolean'; Description = 'Perform shortcut removal during install.'; TemplateComment = '(Mandatory Boolean) If the shortcut must be removed during INSTALL, then set this value to $true.' }
                @{ Name = 'PerformDuringUninstall'; Type = 'System.Boolean'; Required = $true; Default = $false; DisplayType = 'Mandatory Boolean'; Description = 'Perform shortcut removal during uninstall.'; TemplateComment = '(Mandatory Boolean) If the shortcut must be removed during UNINSTALL, then set this value to $true.' }
                @{ Name = 'AlsoRemoveFromStartMenu'; Type = 'System.Boolean'; Required = $true; Default = $true; DisplayType = 'Mandatory Boolean'; Description = 'Also remove from Start menu in addition to desktop.'; TemplateComment = '(Mandatory Boolean) If the shortcut must be removed from the Desktop AND THE STARTMENU, then set this value to $true. (If false, it will be removed from the Desktop only.)' }
            )
        }

        DEPLOYLOCALGROUP = @{
            Category = '60 - LOCAL GROUPS AND USERS'
            DisplayName = 'Deploy Local Group'
            PickerOrder = 10
            Description = 'Creates a local group and optionally memberships, with optional uninstall removal.'
            Fields = @(
                @{ Name = 'LocalGroupName'; Type = 'System.String'; Required = $true; Default = ''; DisplayType = 'Mandatory String'; Description = 'Name of local group to create.'; TemplateComment = '(Mandatory String) The NAME of the LOCAL GROUP you wish to create. Example: ''Adobe_Administrators''' }
                @{ Name = 'Description'; Type = 'System.String'; Required = $false; Default = ''; DisplayType = 'Optional String'; Description = 'Optional local group description.'; TemplateComment = '(Optional String) The DESCRIPTION of the LOCAL GROUP. Example: ''Administrators of Adobe Products''' }
                @{ Name = 'MakeMemberOfParentGroups'; Type = 'System.String[]'; Required = $false; Default = @(); DisplayType = 'Optional String Array'; Description = 'Optional parent groups this group should join.'; TemplateComment = '(Optional String Array) The NAMES of the PARENT GROUPS, that this new Group must become a member of. Example: @(''Administrators'',''Guests'')' }
                @{ Name = 'AddMemberUsersOrGroups'; Type = 'System.String[]'; Required = $false; Default = @(); DisplayType = 'Optional String Array'; Description = 'Optional users/groups to add as members.'; TemplateComment = '(Optional String Array) The NAMES of the MEMBERS, you wish to ADD to this new Group. Example: @(''DOMAIN\ADGroupName1'',''DOMAIN\ADGroupName2'')' }
                @{ Name = 'CreateDuringInstall'; Type = 'System.Boolean'; Required = $true; Default = $true; DisplayType = 'Mandatory Boolean'; Description = 'Create group during install.'; TemplateComment = '(Mandatory Boolean) If the GROUP must be CREATED during INSTALL, then set this value to $true.' }
                @{ Name = 'RemoveDuringUninstall'; Type = 'System.Boolean'; Required = $true; Default = $false; DisplayType = 'Mandatory Boolean'; Description = 'Remove group during uninstall.'; TemplateComment = '(Mandatory Boolean) If the GROUP must be REMOVED during UNINSTALL, then set this value to $true.' }
            )
        }

        REMOVELOCALGROUPMEMBER = @{
            Category = '60 - LOCAL GROUPS AND USERS'
            DisplayName = 'Remove Local Group Member'
            PickerOrder = 20
            Description = 'Removes a member from a local group during install and/or uninstall.'
            Fields = @(
                @{ Name = 'LocalGroupName'; Type = 'System.String'; Required = $true; Default = ''; DisplayType = 'Mandatory String'; Description = 'Name of local group.'; TemplateComment = '(Mandatory String) The NAME of the LOCAL GROUP. Example: ''Adobe_Users''' }
                @{ Name = 'MemberNameToRemove'; Type = 'System.String'; Required = $false; Default = ''; DisplayType = 'Optional String'; Description = 'Optional member name to remove.'; TemplateComment = '(Exclusive String) The NAME of the MEMBER that will be REMOVED. Example: ''Everyone''. (This is exclusive with MemberSIDToRemove)' }
                @{ Name = 'MemberSIDToRemove'; Type = 'System.String'; Required = $false; Default = ''; DisplayType = 'Optional String'; Description = 'Optional member SID to remove.'; TemplateComment = '(Exclusive String) The SID of the MEMBER that will be REMOVED. Example: ''S-1-1-0''. (This is exclusive with MemberNameToRemove)' }
                @{ Name = 'RemoveDuringInstall'; Type = 'System.Boolean'; Required = $true; Default = $true; DisplayType = 'Mandatory Boolean'; Description = 'Remove member during install.'; TemplateComment = '(Mandatory Boolean) If the MEMBER must be removed during INSTALL, then set this value to $true.' }
                @{ Name = 'RemoveDuringUninstall'; Type = 'System.Boolean'; Required = $true; Default = $false; DisplayType = 'Mandatory Boolean'; Description = 'Remove member during uninstall.'; TemplateComment = '(Mandatory Boolean) If the MEMBER must be removed during UNINSTALL, then set this value to $true.' }
            )
        }

        DEPLOYSQLEXPRESS = @{
            Category = '70 - SQL'
            DisplayName = 'Deploy SQL Express'
            PickerOrder = 10
            Description = 'Installs and uninstalls SQL Express using setup and configuration files.'
            Fields = @(
                @{ Name = 'SetupFileBaseName'; Type = 'System.String'; Required = $true; Default = ''; DisplayType = 'Mandatory String'; Description = 'Setup executable base name without extension.'; TemplateComment = '(Mandatory String) Set the BASENAME of the SETUP FILE, WITHOUT the extension (.exe). Example: ''SQLEXPR_x64_ENU''.' }
                @{ Name = 'InstallConfigurationBaseName'; Type = 'System.String'; Required = $true; Default = ''; DisplayType = 'Mandatory String'; Description = 'Install configuration file base name without extension.'; TemplateComment = '(Mandatory String) Set the BASENAME the CONFIGURATION FILE that will be used for INSTALLATION, WITHOUT the extension (.ini). Example: ''InstallConfiguration''' }
                @{ Name = 'UninstallConfigurationBaseName'; Type = 'System.String'; Required = $true; Default = ''; DisplayType = 'Mandatory String'; Description = 'Uninstall configuration file base name without extension.'; TemplateComment = '(Mandatory String) Set the BASENAME the CONFIGURATION FILE that will be used for UNINSTALL, WITHOUT the extension (.ini). Example: ''UninstallConfiguration''' }
            )
        }

        DEPLOYSQLSCRIPT = @{
            Category = '70 - SQL'
            DisplayName = 'Deploy SQL Script'
            PickerOrder = 20
            Description = 'Runs a SQL script during install and/or uninstall.'
            Fields = @(
                @{ Name = 'SQLFileBaseName'; Type = 'System.String'; Required = $true; Default = ''; DisplayType = 'Mandatory String'; Description = 'SQL script base name without extension.'; TemplateComment = '(Mandatory String) Set the BASENAME of the SQLFILE, WITHOUT the extension (.sql). Example: ''ConfigureDatabase''' }
                @{ Name = 'SQLInstanceName'; Type = 'System.String'; Required = $true; Default = ''; DisplayType = 'Mandatory String'; Description = 'SQL instance name.'; TemplateComment = '(Mandatory String) Set the NAME of the SQL INSTANCE. Example: ''SQLEXPRESS2012''' }
                @{ Name = 'RunScriptDuringInstall'; Type = 'System.Boolean'; Required = $true; Default = $true; DisplayType = 'Mandatory Boolean'; Description = 'Run SQL script during install.'; TemplateComment = '(Mandatory Boolean) If the SCRIPT should RUN during INSTALL, then set this value to $true.' }
                @{ Name = 'RunScriptDuringUninstall'; Type = 'System.Boolean'; Required = $true; Default = $false; DisplayType = 'Mandatory Boolean'; Description = 'Run SQL script during uninstall.'; TemplateComment = '(Mandatory Boolean) If the SCRIPT should RUN during UNINSTALL, then set this value to $true.' }
            )
        }

        DEPLOYACTIVESETUP = @{
            Category = '80 - REGISTRY'
            DisplayName = 'Deploy Active Setup'
            PickerOrder = 10
            Description = 'Imports HKCU settings using Active Setup during install and/or uninstall.'
            Fields = @(
                @{ Name = 'HKCURegFileName'; Type = 'System.String'; Required = $true; Default = ''; DisplayType = 'Mandatory String'; Description = 'HKCU REG filename including extension.'; TemplateComment = '(Mandatory String) Set the REGFILE name (containing the HKCU keys), INCLUDING the extension. Example: ''HKCUSettings.reg''' }
                @{ Name = 'ImportDuringInstall'; Type = 'System.Boolean'; Required = $true; Default = $true; DisplayType = 'Mandatory Boolean'; Description = 'Import HKCU REG file during install.'; TemplateComment = '(Mandatory Boolean) If the regfile should be IMPORTED DURING INSTALL, then set this to $true.' }
                @{ Name = 'ImportDuringUninstall'; Type = 'System.Boolean'; Required = $true; Default = $false; DisplayType = 'Mandatory Boolean'; Description = 'Import HKCU REG file during uninstall.'; TemplateComment = '(Mandatory Boolean) If the regfile should be IMPORTED DURING UNINSTALL, then set this to $true.' }
            )
        }

        DEPLOYREGFILE = @{
            Category = '80 - REGISTRY'
            DisplayName = 'Deploy REG File'
            PickerOrder = 20
            Description = 'Imports a REG file and removes the imported keys during uninstall.'
            Fields = @(
                @{ Name = 'REGFileName'; Type = 'System.String'; Required = $true; Default = ''; DisplayType = 'Mandatory String'; Description = 'REG file name including extension.'; TemplateComment = '(Mandatory String) Set the FILENAME of the REGFILE, INCLUDING the extension (.reg). Example: ''AppSettings.reg''' }
                @{ Name = 'AlsoRemoveParentKeys'; Type = 'System.Boolean'; Required = $true; Default = $true; DisplayType = 'Mandatory Boolean'; Description = 'Also remove parent keys during uninstall.'; TemplateComment = '(Mandatory Boolean) If during UNINSTALL also the PARENTKEYS should be removed (not only the properties), then set this value to $true.' }
            )
        }

        DEPLOYTRUSTEDLOCATION = @{
            Category = '80 - REGISTRY'
            DisplayName = 'Deploy Trusted Location'
            PickerOrder = 30
            Description = 'Adds an Office trusted location.'
            Fields = @(
                @{ Name = 'TrustedLocationPath'; Type = 'System.String'; Required = $true; Default = ''; DisplayType = 'Mandatory String'; Description = 'Full path of trusted location.'; TemplateComment = '(Mandatory String) Set the FULL PATH of the Trusted Location. Example: ''C:\Data\ExtraOfficeFiles''' }
                @{ Name = 'OfficeProduct'; Type = 'System.String'; Required = $true; Default = ''; DisplayType = 'Mandatory String'; Description = 'Office product name (Word, Excel, PowerPoint, Access).'; TemplateComment = '(Mandatory String) Set the OFFICE PRODUCT for which the Trusted Location must be added. Valid values are: Word, Excel, PowerPoint, Access' }
                @{ Name = 'OfficeVersion'; Type = 'System.String'; Required = $true; Default = '2024'; DisplayType = 'Mandatory String'; Description = 'Office version.'; TemplateComment = '(Mandatory String) Set the OFFICE VERSION. Example: ''2024''' }
                @{ Name = 'AllowSubfolders'; Type = 'System.Boolean'; Required = $true; Default = $true; DisplayType = 'Mandatory Boolean'; Description = 'Allow subfolders under trusted location.'; TemplateComment = '(Mandatory Boolean) If the SUBFOLDERS of the Trusted Location should also be allowed, then set this value to $true.' }
            )
        }

        IMPORTREGFILE = @{
            Category = '80 - REGISTRY'
            DisplayName = 'Import REG File'
            PickerOrder = 40
            Description = 'Imports a REG file during install and/or uninstall.'
            Fields = @(
                @{ Name = 'REGFileName'; Type = 'System.String'; Required = $true; Default = ''; DisplayType = 'Mandatory String'; Description = 'REG file name including extension.'; TemplateComment = '(Mandatory String) Set the FILENAME of the REGFILE, INCLUDING the extension (.reg). Example: ''AppSettings.reg''' }
                @{ Name = 'PerformDuringInstall'; Type = 'System.Boolean'; Required = $true; Default = $true; DisplayType = 'Mandatory Boolean'; Description = 'Import the REG file during install.'; TemplateComment = '(Mandatory Boolean) If the regfile should be IMPORTED during INSTALL, then set this value to $true.' }
                @{ Name = 'PerformDuringUninstall'; Type = 'System.Boolean'; Required = $true; Default = $false; DisplayType = 'Mandatory Boolean'; Description = 'Import the REG file during uninstall.'; TemplateComment = '(Mandatory Boolean) If the regfile should be IMPORTED during UNINSTALL, then set this value to $true.' }
            )
        }

        RUNPS1SCRIPT = @{
            Category = '90 - OTHER'
            DisplayName = 'Run PowerShell Script'
            PickerOrder = 10
            Description = 'Runs a PowerShell script during install and/or uninstall with optional arguments and success exit codes.'
            Fields = @(
                @{ Name = 'PS1FileName'; Type = 'System.String'; Required = $true; Default = ''; DisplayType = 'Mandatory String'; Description = 'PS1 filename including extension, or full path when absolute mode is used.'; TemplateComment = '(Mandatory String) Set the file name of the script INCLUDING the extension (.ps1). Example: ''MyScript.ps1''' }
                @{ Name = 'PS1PathIsAbsolute'; Type = 'System.Boolean'; Required = $true; Default = $false; DisplayType = 'Mandatory Boolean'; Description = 'Use absolute path from PS1FileName instead of source files.'; TemplateComment = '(Mandatory Boolean) If the script is on the local system, then set the FULL PATH as the PS1FileName, and set this to $true.' }
                @{ Name = 'RunDuringInstall'; Type = 'System.Boolean'; Required = $true; Default = $true; DisplayType = 'Mandatory Boolean'; Description = 'Run script during install.'; TemplateComment = '(Mandatory Boolean) If the script must run during INSTALL, then set this to $true.' }
                @{ Name = 'InstallArguments'; Type = 'System.String[]'; Required = $false; Default = @(); DisplayType = 'Optional String Array'; Description = 'Optional script arguments used during install.'; TemplateComment = '(Optional String Array) Set the INSTALL ARGUMENTS for the script. Example: @(''-Verbose'')' }
                @{ Name = 'InstallSuccessExitCodes'; Type = 'System.Int32[]'; Required = $true; Default = @(0); DisplayType = 'Mandatory Integer Array'; Description = 'Accepted exit codes for install phase.'; TemplateComment = '(Mandatory Integer Array) Set the INSTALL SUCCESS EXIT CODES for the script, the default value is @(0). Example: @(0,1223,1651)' }
                @{ Name = 'RunDuringUninstall'; Type = 'System.Boolean'; Required = $true; Default = $false; DisplayType = 'Mandatory Boolean'; Description = 'Run script during uninstall.'; TemplateComment = '(Mandatory Boolean) If the script must run during UNINSTALL, then set this to $true.' }
                @{ Name = 'UninstallArguments'; Type = 'System.String[]'; Required = $false; Default = @(); DisplayType = 'Optional String Array'; Description = 'Optional script arguments used during uninstall.'; TemplateComment = '(Optional String Array) Set the UNINSTALL ARGUMENTS for the script. Example: @(''-Verbose'')' }
                @{ Name = 'UninstallSuccessExitCodes'; Type = 'System.Int32[]'; Required = $true; Default = @(0); DisplayType = 'Mandatory Integer Array'; Description = 'Accepted exit codes for uninstall phase.'; TemplateComment = '(Mandatory Integer Array) Set the UNINSTALL SUCCESS EXIT CODES for the script, the default value is @(0). Example: @(0,1223,1651)' }
            )
        }

        RUNCMDFILE = @{
            Category = '90 - OTHER'
            DisplayName = 'Run CMD/BAT File'
            PickerOrder = 20
            Description = 'Runs a CMD or BAT script during install and/or uninstall.'
            Fields = @(
                @{ Name = 'CmdBatFileName'; Type = 'System.String'; Required = $true; Default = ''; DisplayType = 'Mandatory String'; Description = 'Script filename including extension (.cmd or .bat).'; TemplateComment = '(Mandatory String) Set the FILENAME of the cmd/bat-file, INCLUDING the extension (.cmd or .bat). Example: ''MyConfiguration.bat''.' }
                @{ Name = 'ArgumentList'; Type = 'System.String[]'; Required = $false; Default = @(); DisplayType = 'Optional String Array'; Description = 'Optional arguments passed to the script.'; TemplateComment = '(Optional String Array) Set the EXTRA ARGUMENTS for the cmd/bat. Example: @(''/SILENT'',''/nodesktopshortcut'')' }
                @{ Name = 'RunDuringInstall'; Type = 'System.Boolean'; Required = $true; Default = $true; DisplayType = 'Mandatory Boolean'; Description = 'Run the script during install.'; TemplateComment = '(Mandatory Boolean) If the script must RUN during INSTALL, then set this value to $true.' }
                @{ Name = 'RunDuringUninstall'; Type = 'System.Boolean'; Required = $true; Default = $false; DisplayType = 'Mandatory Boolean'; Description = 'Run the script during uninstall.'; TemplateComment = '(Mandatory Boolean) If the script must RUN during UNINSTALL, then set this value to $true.' }
            )
        }

        RUNEXE = @{
            Category = '90 - OTHER'
            DisplayName = 'Run EXE'
            PickerOrder = 30
            Description = 'Runs an executable from local system during install and/or uninstall.'
            Fields = @(
                @{ Name = 'ExeFullPath'; Type = 'System.String'; Required = $true; Default = ''; DisplayType = 'Mandatory String'; Description = 'Full path to executable file.'; TemplateComment = '(Mandatory String) Set the full path of the exe that must be started. Example: ''C:\Program Files\MyApp\MyService.exe''' }
                @{ Name = 'ArgumentList'; Type = 'System.String[]'; Required = $false; Default = @(); DisplayType = 'Optional String Array'; Description = 'Optional argument list passed to executable.'; TemplateComment = '(Optional String Array) Set the ARGUMENTS for the Executable. Example: @(''-start'',''-database:SQL01'')' }
                @{ Name = 'WaitUntilFinished'; Type = 'System.Boolean'; Required = $true; Default = $true; DisplayType = 'Mandatory Boolean'; Description = 'Wait for process completion before continuing.'; TemplateComment = '(Mandatory Boolean) If the process should wait until this exe is done, then set this boolean to $true.' }
                @{ Name = 'RunDuringInstall'; Type = 'System.Boolean'; Required = $true; Default = $true; DisplayType = 'Mandatory Boolean'; Description = 'Run executable during install.'; TemplateComment = '(Mandatory Boolean) If this should be executed during INSTALL, then set this value to $true.' }
                @{ Name = 'RunDuringUninstall'; Type = 'System.Boolean'; Required = $true; Default = $false; DisplayType = 'Mandatory Boolean'; Description = 'Run executable during uninstall.'; TemplateComment = '(Mandatory Boolean) If this should be executed during UNINSTALL, then set this value to $true.' }
            )
        }

        DEPLOYARPENTRY = @{
            Category = '90 - OTHER'
            DisplayName = 'Deploy ARP Entry'
            PickerOrder = 40
            Description = 'Creates an Add/Remove Programs entry during install and removes it during uninstall.'
            Fields = @(
                @{ Name = 'DisplayName'; Type = 'System.String'; Required = $false; Default = ''; DisplayType = 'Optional String'; Description = 'Display name shown in Add/Remove Programs.'; TemplateComment = '(Optional String) Set the DISPLAYNAME of the application. Example: ''WebViewer''. (If this is empty, then the ApplicationID will be used)' }
                @{ Name = 'DisplayVersion'; Type = 'System.String'; Required = $true; Default = ''; DisplayType = 'Mandatory String'; Description = 'Displayed application version.'; TemplateComment = '(Mandatory String) Set the version. Example: ''3.14''' }
                @{ Name = 'PublisherName'; Type = 'System.String'; Required = $true; Default = ''; DisplayType = 'Mandatory String'; Description = 'Publisher name shown in ARP.'; TemplateComment = '(Mandatory String) Set the NAME of the PUBLISHER. Example: ''Contoso''' }
                @{ Name = 'DisplayIconFileName'; Type = 'System.String'; Required = $false; Default = ''; DisplayType = 'Optional String'; Description = 'Optional icon file name from source files.'; TemplateComment = '(Optional String) Set the FILENAME of the icon, and add it to the sourcefiles. Example: ''MyIcon.ico''. (If this is empty, then shell32.dll,15 will be used).' }
                @{ Name = 'QuietUninstallString'; Type = 'System.String'; Required = $false; Default = ''; DisplayType = 'Optional String'; Description = 'Optional custom quiet uninstall command.'; TemplateComment = '(Optional String) Set the uninstallstring. Example: ''C:\Program Files\MyApp\Uninstall.exe /silent''. (If this is empty, then this Deployment Framework will be used).' }
                @{ Name = 'HideOriginalARPEntries'; Type = 'System.String[]'; Required = $false; Default = @(); DisplayType = 'Optional String Array'; Description = 'Optional list of existing ARP entry names to hide.'; TemplateComment = '(Optional String Array) If there are existing ARP entries for this application that should be hidden after installation, then enter their DISPLAYNAMES in this array. Example: @(''WebViewer'',''Audio Driver''). (If there are no ARP entries to hide, then leave this empty.)' }
            )
        }

        ADDENVIRONMENTPATH = @{
            Category = '90 - OTHER'
            DisplayName = 'Add Environment Path'
            PickerOrder = 50
            Description = 'Adds a directory to the system PATH and optionally removes it during uninstall.'
            Fields = @(
                @{ Name = 'Directory'; Type = 'System.String'; Required = $true; Default = ''; DisplayType = 'Mandatory String'; Description = 'Directory path to add to system PATH.'; TemplateComment = '(Mandatory String) Set the DIRECTORY that should be added to the SYSTEM Environment Variable PATH. (Example: ''C:\Program Files\Contoso\WebViewer'')' }
                @{ Name = 'RemoveDuringUninstall'; Type = 'System.Boolean'; Required = $true; Default = $true; DisplayType = 'Mandatory Boolean'; Description = 'Remove added path during uninstall.'; TemplateComment = '(Mandatory Boolean) If the Path should be REMOVED during UNINSTALL, then set this to $true.' }
            )
        }

        CERTIFICATE = @{
            Category = '90 - OTHER'
            DisplayName = 'Deploy Certificate'
            PickerOrder = 60
            Description = 'Imports a certificate into a machine store and optionally removes it during uninstall.'
            Fields = @(
                @{ Name = 'CertificateFileName'; Type = 'System.String'; Required = $true; Default = ''; DisplayType = 'Mandatory String'; Description = 'Certificate filename including extension (.cer or .pfx).'; TemplateComment = '(Mandatory String) Set the CERTIFICATE file name INCLUDING the extension (.cer, .pfx). Example: ''VendorCertificate.cer''' }
                @{ Name = 'CertificateStoreName'; Type = 'System.String'; Required = $true; Default = 'TrustedPublisher'; DisplayType = 'Mandatory String'; Description = 'Certificate store name.'; TemplateComment = '(Mandatory String) Set the STORE name. (The default store is set to TrustedPublisher.)' }
                @{ Name = 'RemoveDuringUninstall'; Type = 'System.Boolean'; Required = $true; Default = $false; DisplayType = 'Mandatory Boolean'; Description = 'Remove certificate during uninstall.'; TemplateComment = '(Mandatory Boolean) If the certificate should be removed during uninstall, then set this value to $true.' }
            )
        }

        INFDRIVER = @{
            Category = '90 - OTHER'
            DisplayName = 'Deploy INF Driver'
            PickerOrder = 70
            Description = 'Installs one or more INF drivers from source files.'
            Fields = @(
                @{ Name = 'INFFileNames'; Type = 'System.String[]'; Required = $true; Default = @(); DisplayType = 'Mandatory String Array'; Description = 'INF filenames including extension.'; TemplateComment = '(Mandatory String Array) Set the INF file names INCLUDING the extension (.inf). Example: @(''driver64.inf'',''driver32.inf'')' }
            )
        }

        DEPLOYPYTHONMODULE = @{
            Category = '90 - OTHER'
            DisplayName = 'Deploy Python Module'
            PickerOrder = 80
            Description = 'Installs a Python module using pip from local path or source files.'
            Fields = @(
                @{ Name = 'PipPathOnLocalSystem'; Type = 'System.String'; Required = $true; Default = ''; DisplayType = 'Mandatory String'; Description = 'Full path to pip.exe on local system.'; TemplateComment = '(Mandatory String) Set the FULL PATH of pip.exe on the local system. Example: ''C:\Program Files\Python\pip.exe''' }
                @{ Name = 'ModulePathOnLocalSystem'; Type = 'System.String'; Required = $false; Default = ''; DisplayType = 'Optional String'; Description = 'Optional full path to module file on local system.'; TemplateComment = '(Optional String) If the MODULE file is on the Local System, then enter the FULL PATH. Example: ''C:\Program Files\MyApplication\MyModule.whl''' }
                @{ Name = 'ModuleFileNameInSourceFiles'; Type = 'System.String'; Required = $false; Default = ''; DisplayType = 'Optional String'; Description = 'Optional module filename from source files.'; TemplateComment = '(Optional String) If the MODULE file is in the Source Files, then enter the FILENAME. Example: ''MyModule.tar.gz''' }
            )
        }

        VSCODEEXTENSION = @{
            Category = '90 - OTHER'
            DisplayName = 'Deploy VS Code Extension'
            PickerOrder = 90
            Description = 'Installs a VS Code extension from a VSIX package.'
            Fields = @(
                @{ Name = 'VSCodeExtensionBaseName'; Type = 'System.String'; Required = $true; Default = ''; DisplayType = 'Mandatory String'; Description = 'VSIX file base name without extension.'; TemplateComment = '(Mandatory String) Set the BASENAME of the VSIX file WITHOUT the file-extension. Example: ''ms-vscode.PowerShell-2025.5.0''' }
            )
        }

        DEPLOYWINDOWSPACKAGE = @{
            Category = '90 - OTHER'
            DisplayName = 'Deploy Windows Package'
            PickerOrder = 100
            Description = 'Installs a Windows package from a CAB file.'
            Fields = @(
                @{ Name = 'CABFileBaseName'; Type = 'System.String'; Required = $true; Default = ''; DisplayType = 'Mandatory String'; Description = 'CAB file base name without extension.'; TemplateComment = '(Mandatory String) Set the BASENAME of the CAB file (WITHOUT the extension). Example: ''microsoft-windows-netfx3-ondemand-package~31bf3856ad364e35~amd64~~''' }
            )
        }

        STOPSERVICE = @{
            Category = '90 - OTHER'
            DisplayName = 'Stop Service'
            PickerOrder = 110
            Description = 'Stops a Windows service during install and/or uninstall.'
            Fields = @(
                @{ Name = 'ServiceName'; Type = 'System.String'; Required = $true; Default = ''; DisplayType = 'Mandatory String'; Description = 'Windows service name.'; TemplateComment = '(Mandatory String) Set the NAME of the SERVICE.' }
                @{ Name = 'StopDuringInstall'; Type = 'System.Boolean'; Required = $true; Default = $true; DisplayType = 'Mandatory Boolean'; Description = 'Stop service during install.'; TemplateComment = '(Mandatory Boolean) If this should be executed during INSTALL, then set this value to $true.' }
                @{ Name = 'StopDuringUninstall'; Type = 'System.Boolean'; Required = $true; Default = $false; DisplayType = 'Mandatory Boolean'; Description = 'Stop service during uninstall.'; TemplateComment = '(Mandatory Boolean) If this should be executed during UNINSTALL, then set this value to $true.' }
            )
        }

        DISABLESERVICE = @{
            Category = '90 - OTHER'
            DisplayName = 'Disable Service'
            PickerOrder = 120
            Description = 'Disables a Windows service during install and/or uninstall.'
            Fields = @(
                @{ Name = 'ServiceName'; Type = 'System.String'; Required = $true; Default = ''; DisplayType = 'Mandatory String'; Description = 'Windows service name.'; TemplateComment = '(Mandatory String) Set the NAME of the SERVICE.' }
                @{ Name = 'StopDuringInstall'; Type = 'System.Boolean'; Required = $true; Default = $true; DisplayType = 'Mandatory Boolean'; Description = 'Disable service action during install.'; TemplateComment = '(Mandatory Boolean) If this should be executed during INSTALL, then set this value to $true.' }
                @{ Name = 'StopDuringUninstall'; Type = 'System.Boolean'; Required = $true; Default = $false; DisplayType = 'Mandatory Boolean'; Description = 'Disable service action during uninstall.'; TemplateComment = '(Mandatory Boolean) If this should be executed during UNINSTALL, then set this value to $true.' }
            )
        }

        DEPLOYPROCESSSTOP = @{
            Category = '90 - OTHER'
            DisplayName = 'Stop Process'
            PickerOrder = 130
            Description = 'Stops a process during install and/or uninstall.'
            Fields = @(
                @{ Name = 'ProcessBaseName'; Type = 'System.String'; Required = $true; Default = ''; DisplayType = 'Mandatory String'; Description = 'Process base name without extension.'; TemplateComment = '(Mandatory String) Set the BASENAME of the PROCESS to stop (WITHOUT the extension). Example: ''vpn-connector''' }
                @{ Name = 'StopDuringInstall'; Type = 'System.Boolean'; Required = $true; Default = $false; DisplayType = 'Mandatory Boolean'; Description = 'Stop process during install.'; TemplateComment = '(Mandatory Boolean) If the PROCESS must be stopped during INSTALL, then set this value to $true.' }
                @{ Name = 'StopDuringUninstall'; Type = 'System.Boolean'; Required = $true; Default = $true; DisplayType = 'Mandatory Boolean'; Description = 'Stop process during uninstall.'; TemplateComment = '(Mandatory Boolean) If the PROCESS must be stopped during UNINSTALL, then set this value to $true.' }
            )
        }

        DISABLESCHEDULEDTASK = @{
            Category = '90 - OTHER'
            DisplayName = 'Disable Scheduled Task'
            PickerOrder = 140
            Description = 'Disables a scheduled task during install and/or uninstall.'
            Fields = @(
                @{ Name = 'TaskName'; Type = 'System.String'; Required = $true; Default = ''; DisplayType = 'Mandatory String'; Description = 'Scheduled task name.'; TemplateComment = '(Mandatory String) Set the NAME of the TASK.' }
                @{ Name = 'DisableDuringInstall'; Type = 'System.Boolean'; Required = $true; Default = $true; DisplayType = 'Mandatory Boolean'; Description = 'Disable task during install.'; TemplateComment = '(Mandatory Boolean) If the TASK should be DISABLED during INSTALL, then set this value to $true.' }
                @{ Name = 'DisableDuringUninstall'; Type = 'System.Boolean'; Required = $true; Default = $false; DisplayType = 'Mandatory Boolean'; Description = 'Disable task during uninstall.'; TemplateComment = '(Mandatory Boolean) If the TASK should be DISABLED during UNINSTALL, then set this value to $true.' }
            )
        }

        DEPLOYPAUSE = @{
            Category = '90 - OTHER'
            DisplayName = 'Pause Deployment'
            PickerOrder = 150
            Description = 'Pauses the deployment process for a defined number of seconds.'
            Fields = @(
                @{ Name = 'SecondsToPause'; Type = 'System.String'; Required = $true; Default = ''; DisplayType = 'Mandatory String'; Description = 'Pause duration in seconds.'; TemplateComment = '(Mandatory String) Set the length of the pause in SECONDS. Example: ''10''.' }
                @{ Name = 'PerformDuringInstall'; Type = 'System.Boolean'; Required = $true; Default = $true; DisplayType = 'Mandatory Boolean'; Description = 'Execute during install phase.'; TemplateComment = '(Mandatory Boolean) If the PAUSE be executed during INSTALL, then set this value to $true.' }
                @{ Name = 'PerformDuringUninstall'; Type = 'System.Boolean'; Required = $true; Default = $false; DisplayType = 'Mandatory Boolean'; Description = 'Execute during uninstall phase.'; TemplateComment = '(Mandatory Boolean) If the PAUSE be executed during UNINSTALL, then set this value to $true.' }
            )
        }

        PAUSE = @{
            Category = '90 - OTHER'
            DisplayName = 'Pause (Legacy)'
            PickerOrder = 160
            Description = 'Legacy pause object for backward compatibility.'
            Fields = @(
                @{ Name = 'Seconds'; Type = 'System.String'; Required = $true; Default = ''; DisplayType = 'Mandatory String'; Description = 'Pause duration in seconds.'; TemplateComment = '(Mandatory String) Set the length of the pause in SECONDS. Example: ''10''.' }
                @{ Name = 'DuringInstall'; Type = 'System.Boolean'; Required = $true; Default = $true; DisplayType = 'Mandatory Boolean'; Description = 'Pause during install.'; TemplateComment = '(Mandatory Boolean) If this should be executed during INSTALL, then set this value to $true.' }
                @{ Name = 'DuringUninstall'; Type = 'System.Boolean'; Required = $true; Default = $false; DisplayType = 'Mandatory Boolean'; Description = 'Pause during uninstall.'; TemplateComment = '(Mandatory Boolean) If this should be executed during UNINSTALL, then set this value to $true.' }
            )
        }
    }
}

