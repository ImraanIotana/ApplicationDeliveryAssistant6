# Application Delivery Assistant 6
Application Delivery Assistant version 6 - Copyright (C) Iotana. All rights reserved.

Version 6.0.0
May 2026
- Complete rewrite of the application.
- Renamed application from Packaging Assistent to Application Delivery Assistant.

Version 5.7.2
February 2026
- ModuleSettings: Updated to 5.7.2

Version 5.7.1
February 2026
- ModuleGraphics: Added MenuBar and Help Items.
- ModuleGraphics: Added Default Functions to TextBoxes.
- ModuleGraphics: Added Default Icons.
- ModuleAppLocker: Merged 3 submodules.

Version 5.7.0
January 2026
- General: Converted ModuleLauncher to Powershell Module.
- General: Converted ModuleGraphics to Powershell Module.
- General: Converted ModuleSettings to Powershell Module.
- General: Converted SubModuleAppLockerSettings to Powershell Module.
- General: Converted SubModuleGeneralSettings to Powershell Module.
- General: Converted SubModuleMaintenance to Powershell Module.
- General: Converted SubModuleSCCMSettings to Powershell Module.

Version 5.5.1
20250806
- General: Created Modules.
- PASystemModule: Added Get-Path.

Version 5.5
20250806
- General: Updated script methods in functions.
- Module DSL Synchronization: Added new function Sync-DEMShortcuts
- Write-Object: Added new Shared Function.
- New-ApplicationBackup: Added new function for Module DSL Synchronization.

Version 5.4.10
20250724
- Module MECMApplication: Added Update feature for updating new sources.

Version 5.4.9
20250724
- Module AppLockerImport: Added new module for importing AppLocker policy files into the Test environment.

Version 5.4.8
20250724
- Module AppLockerImport: Added new module for importing AppLocker policy files into the Test environment.
- Get-DSLApplicationFolder: Added new shared function.
- Module ApplicationIntake: Added Confirmation for each step.
- Module ApplicationIntake: Added Publisher to AppLocker creation and IgnoreMissingFileInformation.

Version 5.4.7
20250721
- Module MECMApplication: Added search feature.
- Module Settings: Added subtab for SCCM Settings.
- Settings: Added SCCM default values to the Settingsfile.
- Get-FolderSize: Added new function.
- Get-TimeStamp: Added new function.

Version 5.4.6
20250710
- Module ApplicationIntake: Added hash to the AppLocker file.

Version 5.4.5
20250709
- Module ApplicationIntake: Added function to extract executables from Installation folder.
- Module ApplicationIntake: Merged ARP Extract function to the main button.
- Module Settings: Corrected shortcut icon.

Version 5.4.4
20250704
- Module MECMApplication: Added Get-SCCMApplication function.

Version 5.4.3
20250626
- Module ApplicationIntake: Added Deploymentscript.

Version 5.4.2
20250625
- Module ApplicationIntake: Updated Word Document.
- Module ApplicationIntake: Added new folder for Hardening.

Version 5.4.1
20250528
- Module ApplicationIntake: Removes spaces from ApplicationID.
- Module ApplicationIntake: Added subfolders to the Application folder.
- Format-AssetID: Renamed to Format-ApplicationID.

Version 5.3.4
20250528
- Module ApplicationIntake: Updated Intake Document.

Version 5.3.3
20250527
- Module ApplicationIntake: Added metafile with Application information.
- Module Launcher: Added DSL button.

Version 5.3.2
20250526
- Module ApplicationIntake: Updated Word Document.
- Get-ShortcutInfo: Changed to English.

Version 5.3.1
20250526
- Module MECMApplication: Disabled module. It will be used later.
- Module Settings: Added DSL Folder.
- Import-FeaturePersonalSettings: Added new Feature for Personal Settings.
- Get-SharedAssetPath: Added DSL Folder. Added Personal Settings.
- Format-AssetID: Added unserscores to AssetID.

Version 5.3
20250521
- General: Updated for new customer.
- Module IntunewinFile: Removed this moduel and all executbales.
- Module MECMApplication: Added new module.
- Module MECMPackage: Added new module.
- Write-FullError: Removed Open-Folder.
- New-ApplicationFolder: Added new function.

Version 5.2.7
20250515
- Module IntunewinFile: Added functions to the TextBoxes.
- Feature FolderSettings: Added functions to the TextBoxes.
- Confirm-Object: Added new function to confirm/validate objects.
- Get-SharedAssetPath: Added IconExtractor from the source https://github.com/bertjohnson/ExtractIcon


Version 5.2.6
20250514
- Module ShortcutInfo: Added Refresh and Clear buttons.
- Update-ComboBox: Updated to 5.2.6
- Invoke-ClipBoard: Updated to 5.2.6

Version 5.2.5
20250514
- Get-LocallyInstalledApplications: Added Unique parameter.
- Get-UserConfirmation: Updated to 5.2.5
- Invoke-NewShortcut: Updated to 5.2.5
- Write-Message: Updated to 5.2.5

Version 5.2.4
20250512
- Get-ShortcutInfo: Added icon size 64x64.
- Get-ShortcutInfo: Added name to the Output FileName

Version 5.2.3
20250509
- Module IntunewinFile: Disabled feature because of issue with extracting intunewinfiles.

Version 5.2.2
20250509
- Module ApplicationIntake: Removed obsolete icons.
- Module Settings: Added new function to reset all settings.
- Install Packaging Assistant.ps1 : Added pause to end method.
- Get-ShortcutInfo: Added Item name to the output file header.
- Invoke-RegistrySettings: Added the ResetAll method.

Version 5.2
20250509
- General: Merged the unblocking and dotsourcing of the ps1 files, to load faster.
- Get-ShortcutInfo: Added errorhandling for invalid characters.

Version 5.1
20250508
- Module ApplicationIntake: Updated export button. Shortened labels. Updated Helpfile.
- Module ShortcutInfo: Changed outputfolder to include name of the folder/shortcut. Updated to 5.1
- Module IntunewinFile: Added feature to create IntuneWin files.
- Module IntunewinFile: Added Helpfile.
- Get-SharedAssetPath: Added IntuneWinAppUtil.exe.

Version 5.0.11
20250506
- Module ShortcutInfo: Updated buttons and Helpfile. Updated to 5.0.11.
- Module ApplicationIntake: Updated Helpfile.
- Module Settings: Changed label to 'My Output Folder:'. Updated to 5.0.11.
- Get-SharedAssetPath: Added Logfolder as a parameter. Updated to 5.0.11.
- Write-FullError: Added new Logfolder function. Updated to 5.0.11.
- Install Packaging Assistant.ps1 : Updated to 5.0.11.

Version 5.0.10
20250506
- Module ApplicationIntake: Changed buttons. Updated Helpfile
- Module ShortcutInfo: Added buttons to open the Startmenu folder.
- Module ShortcutInfo: Added helpfile.
- Multiple Modules: Changed colors.
- Invoke-TextBox: Commented out Write-Verbose.

Version 5.0.9
20250501
- Updated Install Packaging Assistant.ps1 to remove old folders and shortcuts.

Version 5.0.8
20250501
- Module ApplicationIntake: Added Helpfile and button.
- Updated the WriteImportMessage method of the TabControl.

Version 5.0.7
20250429
- Import-ModuleExtractIntunePackage: Small updates.

Version 5.0.6
20250428
- Invoke-MainTabControl: Added the WriteImportMessage method.
- Import-ModuleExtractIntunePackage: Added a new Module to extract an IntuneWin file.

Version 5.0.5
20250420
- Module ApplicationIntake: Added Vendorname to the Asset ID.
- General: Outcommented many Write-Verbose command, to increase loading time.

Version 5.0.3
20250404
- Get-GraphicalDimension: Added new function for getting graphical dimensions.
- General: Outcommented many Write-Verbose command, to increase loading time.

Version 5.0.1
20250404
- Module ApplicationIntake: Added the Install Location.

Version 5.0
20250317
- General: Built from the ground up for KPN.
- Module ShortcutInfo: Added new Module for obtaining shortcut information.
- Module Launcher: Added new Module for launching common folders and apps.
- Module ApplicationIntake: Added new Module for creating an Intake Document.


***** ***** *****

Version 4.12
20241022
- Module Launcher: Added new Module for launching common apps and folders.

Version 4.11
20241007
- General: Updated Open-Folder and Open-ApplicationFolder to 4.11.0.1
- Module MSIXIvantiObjects: Updated Import-ModuleMSIXIvantiObjects to 4.11.

Version 4.10
20241004
- General: Archived unused Modules to make loading faster.
- General: Added new shared function Get-SharedAssetPath.
- General: Updated several functions to 4.10.0.0.
- General: Updated Open-Folder to 4.10.0.1.
- Module MSIXIvantiObjects: Added a new Module to create Ivanti Objects from an MSIX file.

Version 4.9.3
20241004
- Module MECMApplication: Added rule when the sourcefolder is larger than 10 GB.

Version 4.9.2
20241002
- Main Application: Updated Invoke-Button to hide the text when using the Small button size.
- Module MECMApplication: Renamed Module SCCMApplication to MECMApplication.
- Module SCCMApplication: Removed comment about US Date format. Updated popup message.
- Module SCCMApplication: Added input parameter for the TabControl.
- Module SCCMPackage: Updated Import Module to 4.9. But not activated yet.

Version 4.9.1
20241001
- General: Added Function-Template 4.9.
- Module ContentShareCleanup: Increased rows to 9.
- Module ExtractIntunePackage: Increased rows to 9.
- Module CreateIntunePackage: Increased rows to 9.
- Module ModifyMSIX: Increased rows to 9.
- Module ModifyMSIX: Disabled this module, because makeappx.exe is not on the new system.
- Module ModifyMSIX: Added SDK files to the Asset folder, to prepare for using the local makeappx.exe.

Version 4.9
20240930
- General: Changed size from 800x415 to 900x445.
- Module SCCMApplication: Increased rows to 9.
- Module DeploymentScript: Increased rows to 9.
- Module AzureBulkAdministration: Moved to the Archive folder.
- Module AzureConnection: Moved to the Archive folder.
- Module ApplicationIntake: Moved to the Archive folder.
- Module AzureDeviceAdministration: Moved to the Archive folder.
- Module SignFiles: Moved to the Archive folder.
- Module SetMSIXStartupApp: Moved to the Archive folder.

Version 4.8.2
20240930
- General: Several cosmetic and administrative changes.
- Module SCCMApplication: Moved this Tab more to the left.

Version 4.8.1
20240930
- Module SCCMApplication: Added mandatory field for the icon file. The icon is now added to the SCCM Application.

Version 4.8
20240929
- Module SCCMApplication: Added a new module to manage a SCCM Application.
- Main Application: Added logging to the function Write-FullError. It now writes the error into a logfile.
- Module Settings: Added a button to open the LogFolder.

Version 4.7.1
20240924
- Module ExtractIntunePackage: Added a new module to extract an intunewin file.
- Module Settings: Switched the positions of the DWR365 and DWRNEXT buttons.
- Module Settings: When changing your DSL, all relevant comboboxes are automatically updated. Also updated the reboot message.

Version 4.6
20240731
- Module CreateIntunePackage: Corrected the install commands in the Intune commands file. The Verbose parameter is now trailing.
- Module CreateIntunePackage: Changed the output folder to '2. Oplevering'.
- Module CreateIntunePackage: When the Intune Input file already exists, then it will be renamed, similar to the intunewin file.

Version 4.5
20240730
- Module ModifyMSIX: Added a new button that creates Ivanti Objects.
- Module Settings: Switched the positions of the DWR365 and DWRNEXT buttons.

Version 4.4
20240724
- Module ModifyMSIX: Updated fields and buttons. The user can now just click a button instead of changing the settings individualy.
- Module ContentShareCleanup: Added a new module to cleanup applications from the Content Share.
- Module MSIInfo: Added a pdf help file for this module, and a help button.
- Module Settings: Added a pdf help file for this module, and a help button.

Version 4.3
20240722
- Main Application: Renamed the application to Packaging Assistant.
- Module CreateIntunePackage: Removed the packagefolder field. Now you only need to enter the setup file.
- Module CreateIntunePackage: Added a pdf help file for this module, and a help button.
- Module ContentShareDeployment: Removed the packagefolder field. Now you only need to enter the package file.
- Module ContentShareDeployment: Changed the color of the ResultingFolder feature, to gray.
- Module ContentShareDeployment: Added a pdf help file for this module, and a help button.
- Module Settings: Added button that creates a desktop shortcut.
- Module DeploymentScript: Added a pdf help file for this module, and a help button.

Version 4.2
20240704
- Module DeploymentScript: Updated the Deploymentscript. The logfolder is changed to C:\Windows\System32\LogFiles.
- Module DeploymentScript: Updated the Deploymentscript. The Administration key changed to HKLM:\SOFTWARE\Rijksoverheid\SSC-ICT Application Administration.
- Module DeploymentScript: Updated the Detectionscript. The Detection key changed to HKLM:\SOFTWARE\Rijksoverheid\SSC-ICT Application Administration.

Version 4.1
20240620
- Module DeploymentScript: Added new module to create a Deployment and Detection script.
- Module DeploymentScript: Updated the Deployment and Detection script.

Version 4.0.1
20240620
- Module MSIInfo: Updated graphics functions. Moved Signature textbox down. Update Get Info icon.
- Module Settings: Updated User Manual with tables.
20240619
- Module Settings: Updated DWRNEXT and DWR365 icons.
- Module Settings: Updated graphics functions.
- Module Settings: Updated Confirmation messages.
- Module ModifyMSIX: Updated Confirmation message.

Version 4.0
20240619
- Module Settings: Added DWRNEXT and DWR365 buttons to select your DSL.
20240618
- Module DeploymentScript: Added new module to create Deployment and Detection scripts.
20240606
- Main Application: Added new graphic function Invoke-ButtonLine
- Module ContentShareDeployment: Added new module to deploy packages to the Content Share.
- Module CreateIntunePackage: Updated the module to 4.0.
- Module CreateIntunePackage: Changed the executable that makes the intunewin files, cause the other version produced an error.
- Module Settings: Updated User Manual.
- Module Settings: Added User Manual Word button.
- Module Settings: Made the CSV delimiter field hidden.
20240509
- Module ModifyMSIX: Added new module to modify an MSIX manifest.
- Main Application: Changed author name to Iotana.

Version 3.0
20231218
- Main Application: Renamed the application to Iotana IT Assistant.
- Main Application: Corrected SupportFiles folder to Asset folder.
- Main Application: Changed the application icon.
- Main Application: Moved icon filename from the settings file to the Invoke-Form function.
- Main Application: Remove old digital signatures.
- Main Application: Added the Test-Object function.
- Main Application: Added the FunctionHandler Class version 3.0.
- Main Application: Main script updated to 3.0.
- Main Application: Invoke-Form updated to 3.0.
- Module CreateIntunePackage: Invoke-CreateIntuneFile updated to 3.0.

Version 2.2
20231215
- Module Settings: Added CSV Delimiter Feature. The user can now choose the delimiter for importing and exporting CSV files.
- Module AzureBulkAdministration: Importing and exporting a csv file now uses the CSV Delimiter from the Settings Module.
- Module AzureBulkAdministration: When a device has no history of loggedon users, then the Primary User of that device will not be changed.
- Module Settings: Updated User Manual.

Version 2.1
20231214
- Module Settings: Added Version History Feature.
- Module Settings: Corrected SupportFiles folder to Asset folder.
- Module Settings: Updated User Manual.
- Module AzureBulkAdministration: Importing a csv file now ignores empty lines.
- Main Application: Removed old JSON setting files.
