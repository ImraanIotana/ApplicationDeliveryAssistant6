# Application Delivery Assistant 6
Application Delivery Assistant version 6 - Copyright (C) Iotana. Licensed under the Apache License 2.0.

Getting started
1. Download the ZIP file. Before extracting it, right-click it, choose Properties and tick Unblock (if shown), then click OK.
2. Extract it to a folder that you can write to, for example %LOCALAPPDATA%\Programs\Application Delivery Assistant. Avoid Program Files.
3. Double-click Start Application Delivery Assistant.cmd.
4. Optional: install the application in a folder of your choice with the Install Application to Folder action on the SETTINGS tab, Maintenance sub-tab, and create your own Start Menu or Desktop shortcut with the Create Startmenu Shortcut or Create Desktop Shortcut actions.

Version 6.9.1  
October 2026
- ADA Settings - Maintenance: Added the Install Application to Folder action. After choosing a folder, the application is copied to an 'Application Delivery Assistant' subfolder (a staged copy that is published only when complete; the .git, .vs and .vscode folders are not copied). An existing installation in that folder is kept as a backup named '<folder>.previous' (one backup is kept) and restored if publishing fails. A folder that is not empty and does not contain an installation, a drive root, a folder inside the running application folder, and a folder without write access are refused. Afterwards the application offers to create Start Menu and Desktop shortcuts for the installed copy and to start it. Installed copies contain an Installed.marker file.
- General: The startup messages now show a tip about the launcher and the Install Application to Folder action, unless the application runs from an installed copy.
- General: Added Start Application Delivery Assistant.cmd, a launcher that works from any folder, bypasses the PowerShell execution policy for the application only, and shows a welcome line while the application loads. Added a Getting started section to this README.
- Customer Templates: Made the ADA Default dossier template neutral so the application can be shared publicly: removed the customer sensitivity label metadata and Templafy content-control tags, replaced the customer fonts with Calibri, renamed the customer-branded style names, and replaced the header logo with a placeholder. The document properties were cleared with Inspect Document.
- General: The copyright notice in the README, the startup message and all file headers now states that the application is licensed under the Apache License 2.0, instead of 'All rights reserved'. The Start Application Delivery Assistant.lnk shortcut was removed from the repository; shortcuts are created from the application. Older changelog entries no longer name specific customers.
- ADA Settings - Maintenance: The Check for Updates action now works. It reads the version of StartAssistant.ps1 on GitHub (https only), compares it with the running version and reports whether the application is up to date. When a newer version exists, it offers to update. The update downloads the ZIP file of the public repository to a temporary folder, extracts it with the safe ZIP extraction, and checks that it is a complete application, that it is newer, and that all scripts parse without errors. After confirmation the application closes, and a helper script waits until it has ended, replaces the application folder with the staged copy (the previous version is kept as '<folder>.previous' and restored when the replacement fails), and starts the application again. Development copies (a folder with a .git folder) and folders whose parent folder cannot be written to are not updated. Settings in the registry and Customer Templates in the roaming profile are not affected; extra files you placed in the application folder remain in the '.previous' folder.
- General: The ZipFileOnGithub and VersionFileOnGithub settings now point to the public repository (the raw StartAssistant.ps1 for the version). Added the Utility Update module.
- General: Added a .gitignore for installation markers, backups and temporary files, and made the version and date lines of the changelog separate lines on GitHub. The Production LDAP placeholder in the AppLocker settings now clearly reads as a placeholder.
- General: Updated startup, Settings tab, Maintenance sub-tab, Application Maintenance, AppLocker Settings (Import-FeatureAppLockerSettings), Utility Installation, Utility Update, Application Settings data file and Write-WelcomeMessage metadata to Version 6.9.1.

Version 6.9.0  
October 2026
- ADA Settings - Maintenance: Added a Check for Updates action to the Application Maintenance list. Only the UI entry is present; the update check itself is not implemented yet.
- Application Intake - Intake Templates: Added Export ZIP and Import ZIP buttons to the Available Customer Templates group. Export ZIP packages the selected built-in or user customer template bundle, with its Word templates, into a Customer Extension ZIP file in the output folder without prompting. The extension version is derived automatically from the newest file in the bundle (Year.Month.Day.HHmm, for example 2026.10.5.1432), and a SHA-256 content fingerprint of all bundle files is stored in the Extension.psd1 descriptor together with the name, TemplateId, folder and manifest names, and minimum application version. Import ZIP extracts a Customer Extension in a temporary folder, validates it (descriptor, application version requirement, safe folder name, content fingerprint, every template manifest and Word template), refuses templates that are already built in or installed from another folder, and compares it with an installed copy by fingerprint and version. After confirmation it installs the bundle into the roaming Customer Templates folder transactionally, keeps the previous version in a Customer Template Backups folder (the newest 3 backups per template folder are kept and older ones are removed automatically), warns when the installed copy was changed locally, and refreshes the template list. Customer Extensions may only contain .psd1 and .dotx files: Export ZIP refuses other file types, subfolder values that are rooted or use .., and open Word lock files, and Import ZIP checks the archive before extracting it (at most 200 entries, 50 MB per file and 100 MB in total, measured on the real decompressed bytes; only Extension.psd1 at the root; no unsafe entry names or disallowed file types) and rejects unsafe application subfolder paths in the templates.
- Application Intake - Intake Templates: Restored the ADA Default built-in template, which had been temporarily hidden.
- Application Intake - Intake Templates: Export ZIP now runs a read-only hygiene scan first and warns before sharing a template that contains personal or internal information (author and company properties, shared-with names, label and tenant properties, comment authors, email addresses, user or network paths, external links). You can cancel or export anyway; nothing is changed or removed.
- Application Intake - Intake Templates: The Edit Customer Template window now uses the same Word icon as the template list buttons, through the new shared Set-FormIconFromButtonIcon helper. Built-in bundle folders that are not present are now skipped silently instead of printing a startup warning, and the active-template fallback is now ADA - Default (then the first available template), so an imported extension never becomes the default by itself.
- Customer Templates: The customer-specific templates that were built in are no longer shipped with the application. Their two variants were merged into one bundle (same identities and TemplateIds) and are distributed as a Customer Extension ZIP, which is imported with Import Template from ZIP. ADA Default is the only built-in template. Make Copy keeps only the copied variant's manifest, and Export ZIP packages every variant in the folder and lists them in Extension.psd1.
- Application Intake - Word Documents: The output document name of a template named '<Prefix> Dossier' now keeps its own prefix, and the DSL documentation lookup accepts any Dossier document, so both work for every customer template and not only for one customer.
- Customer Templates: Removed a customer file transfer reference from the ADA Default request source files mail template.
- General: Added the Customer Extension helper module and updated startup, Application Maintenance, Application Intake and Intake Templates runtime, Customer Template List, and Get-CustomerTemplates metadata to Version 6.9.0.

Version 6.8.1  
September 2026
- Tools - Folders: Folder comparison now displays sortable file-level differences for files found only in one folder, newer timestamps, and changed content. Full-row status colors distinguish Folder 1 from Folder 2, and the results window uses the folder_lightbulb icon. Double-clicking opens the relevant file in File Explorer; same-time content differences prompt the user to choose a folder. Large comparisons retain a confirmation prompt before hashing; if declined, path, size, and timestamp differences are still shown.
- General: Updated startup, Folders sub-tab, and folder-comparison function metadata to Version 6.8.1.

Version 6.8.0  
September 2026
- Utilities - Compression: Added reusable native .NET ZIP64 creation, extraction, integrity testing, and streaming archive-entry replacement helpers.
- DSL Management - Search: Wired archive and restore operations to the native streaming ZIP64 helpers with an owned progress dialog, while retaining the legacy PowerShell archive path behind a fallback switch.
- General: Updated startup, Launcher, DSL Search, and Utility Compression version metadata to Version 6.8.0.

Version 6.7.2  
September 2026
- Launcher - System Folders: Replaced the Windows button with Start Menu, opening the all-users Start Menu Programs folder and using the application_side_tree icon.
- Launcher - User Folders: Replaced Downloads with Start Menu, opening the current user's Start Menu Programs folder with the application_side_tree icon; Output Folder remains unchanged.
- General: Updated startup versioning, Launcher tab runtime version, and touched function metadata to Version 6.7.2.

Version 6.7.1  
September 2026
- DSL Management - Documentation: Fixed the customer-template prompt appearing when a dossier already exists but no copied Word template is present. The existing dossier now opens directly; missing documentation still follows the template fallback workflow.
- General: Updated startup versioning and touched function metadata to Version 6.7.1.

Version 6.7.0  
September 2026
- Tools - Other: Added an MSI group below Ping Computers with MSI-only browsing and generation of Install.cmd and Uninstall.cmd beside the selected package.
- Tools - Other: Generated CMD files use relative MSI paths, verbose logs in TEMP, restart prevention, installer exit codes, and concise REM explanations; existing files require overwrite confirmation. Generation does not execute or elevate the scripts.
- Graphics: Added opt-in IsPath textboxes, initially enabled for MSI and Compare Files. Enclosing double quotes remain visible while editing and are removed on leaving the field, pressing Enter, or before a button action; cleaned values are persisted through the existing settings binding. Ordinary text, password, and read-only fields are unchanged.
- Utilities: Moved Explorer-copied path normalization into shared file utilities and added quoted-path support to direct MSI command-file generation calls.
- General: Updated startup and touched function metadata for Version 6.7.0.

Version 6.6.1  
September 2026
- Customer Templates: Limited built-in template discovery to the default customer template and made it the fallback selection. ADA Default and the extended folder structure customer template remain in the repository and can be re-enabled by uncommenting their discovery paths; no new UI controls were added.
- Application Intake - Desktop Application: Missing Detection File / MSI now prompts for confirmation before creating the application folder, instead of failing partway through with a cascade of errors.
- Application Intake - Desktop Application: Detection File is now optional; metadata JSON generation no longer requires it and proceeds cleanly when the user confirms creating the folder without one.
- Application Intake - Desktop Application: Metadata resolution and creation errors now propagate once to the existing rollback/error-reporting logic instead of being swallowed and surfacing as confusing follow-on errors.
- General: Updated touched Application Intake function metadata and startup versioning to Version 6.6.1.

Version 6.6.0  
September 2026
- Application Intake - Word Documents: Added support for generating both Dossier and TAT (Technical Acceptance Test) Word documents (`<Customer> TAT <ApplicationID>.docx`) during Application Intake.
- Customer Templates: Added `TatTemplateName` configuration to the customer templates for `<Customer> TAT APPLICATIONID.dotx`.
- Customer Templates: Updated Customer Template presentation and editor helpers to support viewing and editing `TatTemplateName`.
- Word Automation: Added `[APPLICATIONID]` placeholder token replacement support across metadata-based and UI-based document generation workflows.
- Word Automation: Dynamic output document naming based on template filename pattern (handling `APPLICATIONID` token in template name, `<Customer> Dossier`, `Applicatie Dossier`, etc.).
- Word Automation: Reordered Word application check before user confirmation prompt, skipping prompts and logging a host warning when Word is not installed before copying fallback template files.
- Word Automation: Automatically skips shortcut table detection and chapter processing for TAT documents.
- Registry: Creates the Regedit user settings key on first use before writing `LastKey`, preventing errors on new VMs.
- User Settings: Removed obsolete Intake registry-property migration code; current installations now initialize the User Settings key without scanning for legacy prefixes.
- DSL Management: Shortened temporary archive and restore staging folder names by removing the `ADA_DSL` prefix and replacing 32-character GUID folder names with short random names.
- DSL Management - Documentation: Creates only missing Dossier and TAT documents, using package templates when available and, after confirmation, the selected customer template from the Intake Templates screen when package templates are absent.
- DSL Management - Documentation: Writes fallback-generated documents to the customer template's configured Documentation folder inside the selected DSL application package.
- General: Updated startup versioning and touched modules to Version 6.6.0.

Version 6.5.4  
September 2026
- General: Added unblocking of the modules.
- Tools - Files: File comparison now accepts Explorer-copied paths enclosed in double quotes.

Version 6.5.3  
September 2026
- DSL Management - Search: Changed the Documentation action to open existing documentation or report the template and metadata inputs for deferred document generation.
- DSL Management - Search: Added a confirmation popup asking whether to create the dossier document when no dossier exists but the copied template is available.
- DSL Management - Search: Deferred dossier creation now generates the Word document from the copied template and package metadata in the application Documentation folder.
- DSL Management - Search: Updated the DSL Search sub-tab runtime to Version 6.5.3.
- Word: Moved reusable document generation into the shared Word module so Application Intake and DSL Management use the same creation workflow.
- General: Updated startup versioning to Version 6.5.3.

Version 6.5.2  
August 2026
- Application Intake - Desktop Application: Formal Application Properties fields (Vendor Name, Application Name, and Application Version) are now writable, matching the behavior of Custom Application Properties.
- Application Intake - Desktop Application: Updated the Desktop Application subtab runtime (`Import-SubTabIntake`) to Version 6.5.2.
- General: Updated touched function metadata and startup versioning to Version 6.5.2.

Version 6.5.1  
August 2026
- Maintenance: Added a read-only `GENERAL: View Change Log` action that displays the application README changelog without allowing edits.
- Application Intake - Desktop Application: Stores document-ready bitness text including the detection file path in metadata JSON.
- Document Generation: Restores the detection-file sentence from stored metadata when the target detection file is not available on the current computer.
- General: Updated touched function metadata to Version 6.5.1.

Version 6.5.0  
August 2026
- Application Intake - Desktop Application: Added a Customize dialog beside Application ID for persisted optional Application Folder Name prefix, template-driven selectable postfix values, and a shared separator selected from no separator, space, underscore, hyphen, spaced hyphen, or a custom value, without changing Application ID.
- Application Intake - Desktop Application: Added an editable Application Folder Name field below Application ID; it defaults from ID generation and determines the created package folder without changing the Application ID used by artifacts.
- Application Intake - Desktop Application: Records the Application Folder Name plus optional Prefix, Postfix, and Separator in generated metadata JSON files.
- Application Intake - Desktop Application: Fixed metadata creation after folder generation by removing malformed runtime help-note statements from the metadata helper.
- Application Intake - Desktop Application: Combined Application Security and Detection, placing the detection file selector beneath Installation Folder and removing the separate detection group.
- Application Intake - Desktop Application: Added a persisted Create AppLocker files Yes/No selector and an AppLocker configuration dialog for AD Group Name and AD Group SID, including default-value reset, opened through a Customize action matching the Application Folder Name control.
- Application Intake - Desktop Application: Creates AppLocker artifacts only when selected, without a redundant second confirmation, and records the selected AD group values in metadata.
- AppLocker: Writes policy XML files and reports inside the current application package using the selected customer template's AppLocker subfolder, supports both hashtable and object-based template data, and records the Application ID in generated rule descriptions.
- User Settings: Migrates prior Application Security and standalone Detection File settings into the combined group to preserve saved values and prevent duplicate metadata keys.
- Customer Templates: Added the AppLocker archive folder mapping to the default customer template.
- Customer Templates: Added ApplicationFolderPostfixOptions to every built-in application-folder settings file for per-customer folder-name postfix choices; shared folder creation now ignores non-folder option values safely.
- General: Updated the application, Application Intake and Desktop Application runtimes, and touched function metadata to Version 6.5.0.

Version 6.4.1  
August 2026
- DSL Management - Search: Split Search helpers into a dedicated helper module and separated active DSL results from archive results in the UI.
- DSL Management - Search: Added Open Documentation and Open Log actions for selected DSL folders, including support for matching Word documents and lifecycle logs inside archived ZIP packages.
- DSL Management - Search: Added shared archive artifact resolution used by both log and documentation actions, preferring customer-template folders such as Documentation and Logs.
- Tools - Other: Reused the shared application log viewer from Utility Logging and updated log buttons to use the file_extension_log icon.
- Module Utility: Moved application log viewer functions into Utility Logging for reuse and expanded folder information output with total recursive subfolder and file counts.
- General: Updated the application, DSL Management runtime versions, and touched function metadata to Version 6.4.1.

Version 6.4.0  
August 2026
- Tools: Added a new Hyper-V subtab with virtual machine location, hardware, configuration, and selection groupboxes.
- Tools - Hyper-V: Added elevated Windows 11 virtual machine creation with VHDX, memory, processor count, generation, virtual switch, ISO boot, Secure Boot, and virtual TPM configuration, plus a Replace Existing workflow and stray-VHDX cleanup.
- Tools - Hyper-V: Added a VM selector with elevated Refresh VMs and Show Details actions reporting state, generation, memory, uptime, Secure Boot, and virtual TPM status.
- Tools - Hyper-V: Added a Remove VM action that stops the VM if needed, deletes its VHDX file(s), and permanently deletes its virtual machine folder (including the now-empty parent folder) through an elevated worker.
- Tools - Hyper-V: Combined the post-action VM inventory refresh into the same elevated session as VM creation and removal so only one administrator approval prompt is shown per action.
- General: Added an optional post-approval status message to the shared elevated PowerShell helper, shown once the UAC prompt is accepted and before the elevated work begins.
- General: Restored the alternating Tools subtab color sequence after inserting Hyper-V between Certificates and UDF.
- General: Updated the application, Tools subtab runtime versions, and touched function metadata to Version 6.4.0.

Version 6.3.4  
August 2026
- Tools - UDF: Replaced obsolete smoke-test terminology with workspace terminology in the workspace creation interface, documentation, generated folder names, and status output.
- Tools - Drivers: Added a busy message and fresh inventory refresh when Show All is selected, matching the Certificates workflow.
- Tools - Certificates: Sorted all search and preset results by scope and then issuer name.
- Custom Application: Replaced Provider managed with (No Version), treating that selection as an empty version and omitting the version component from generated Application IDs.
- General: Updated the application, UDF tab runtime version, and touched function metadata to Version 6.3.4.

Version 6.3.3  
August 2026
- Application Intake: Renamed the Intake Extras subtab, folder, modules, and import function to Intake Templates.
- Customer Templates: Moved the complete customer template inventory and management interface into Intake Templates and removed the dedicated Customer Templates subtab.
- Customer Templates: Replaced the separate customer-template ComboBox with a persisted active-template selection in the inventory ListView, including an Active column and highlighted active row.
- Customer Templates: Updated application-folder, mail-template, and AppLocker workflows to resolve the active customer template without depending on a UI control.
- Tools - Other: Moved Shortcut Export from Intake Templates to the Other subtab and preserved its complete action workflow.
- User Settings: Added backward-compatible TextBox and ComboBox setting migrations from Intake Extras to Intake Templates.
- General: Updated the application, affected tab runtime versions, and touched function metadata to Version 6.3.3.

Version 6.3.2  
August 2026
- Application Intake: Renamed the Desktop and Custom Application subtab folders and module files to the consistent Intake Desktop Application and Intake Custom Application naming convention.
- Custom Application: Moved Vendor / Publisher before Application Name in the Application Identity section to match the Desktop Application workflow.
- General: Updated the application and affected Application Intake runtime versions to 6.3.2.

Version 6.3.1  
August 2026
- Application Intake: Centralized whitespace-normalized Vendor_Application_Version ID construction for Desktop and Custom Application workflows.
- Application Intake: Scoped Desktop and Custom Application ID control resolution so duplicate control names cannot cross sub-tab boundaries.
- Application Intake: Extracted shared customer-template folder preparation, overwrite confirmation, folder creation, artifact-path resolution, lifecycle logging, and completion behavior.
- Application Intake: Made folder replacement transactional with sibling staging, required-artifact validation, backup publication, rollback restoration, and warning-only post-commit cleanup.
- Application Intake: Hardened Application IDs and template-derived artifact paths against rooted paths, traversal, invalid filename characters, and destination escape.
- Custom Application: Implemented Create Folder with template-defined folder creation, portable PNG/ICO generation, a launch shortcut, privacy-safe JSON metadata, Word documentation, and structured lifecycle logging.
- Custom Application: Uses an optional supplied icon for documentation and shortcut creation, with executable icon extraction as the fallback.
- Custom Application: Restricted the icon picker to image formats supported by the portable icon conversion pipeline.
- Custom Application: Consolidated Application Type choices to Web Application, Office Application, and Custom Application, with installed browser and Microsoft Office executable discovery.
- Custom Application: Added a nonblocking Application ID warning when a selected Office executable and document parameter use incompatible file types.
- Custom Application: Added Windows-compatible shortcut argument quoting, verified COM cleanup, and package-local shortcut icon paths.
- Custom Application: Added the Desktop-equivalent shortcut properties report plus companion PNG and ICO files to every created application folder.
- Custom Application: Sanitized path-like metadata recursively before JSON serialization and required all core artifacts before publication.
- Word: Added explicit Application ID and icon-folder inputs to shared intake document generation while retaining scoped Desktop fallback behavior.
- Word: Isolated template resolution to the selected customer, rejected unsafe template filenames, and logged skipped document creation accurately.
- Word: Displays the executable icon source or supplied icon filename while resolving the package-local PNG separately for document image insertion.
- General: Standardized Custom Application and shared intake function help blocks, inline lifecycle comments, and Version 6.3.1 metadata.
- General: Updated the application, Application Intake, and Custom Application runtime versions to 6.3.1.

Version 6.3.0  
August 2026
- Application Intake: Added a Custom Application subtab after Desktop Application as the foundation for incremental intake UI development for web applications and other nonstandard application types.
- Custom Application: Added the Application Type group with a persisted selector for web applications, PWAs, browser extensions, scripts or automation, services or APIs, virtual applications, custom launchers, and other application types.
- Custom Application: Added the Application Identity group with persisted Application Name and Vendor / Publisher fields.
- Custom Application: Added an editable persisted Application Version selector with Provider managed as a predefined lifecycle option.
- Custom Application: Added the Application Executable UI with an editable persisted selector and type-driven Find Apps discovery for installed web browsers.
- Custom Application: Browser discovery queries Windows StartMenuInternet registrations and known browser installation paths on demand without scanning the drive.
- Custom Application: Added manual executable browsing and document browsing for file-based Application Parameter targets.
- Custom Application: Added a persisted Application Parameter field for launch targets such as web application URLs and Office document paths.
- Custom Application: Added an optional persisted Additional Arguments field for executable command-line switches.
- Custom Application: Added an optional persisted Application Icon field for documentation and shortcuts, with automatic fallback to icon extraction from the selected executable.
- Custom Application: Added the final Application ID group UI with a generated-ID output field and initial Application ID and Create Folder workflow buttons matching Desktop Application.
- Custom Application: Implemented Application ID generation as whitespace-normalized Vendor_Application_Version output with required-field validation, while Clear All Fields also clears the generated ID within the scoped Custom Application form.
- Custom Application: Added a confirmed Clear All Fields workflow scoped to persisted controls in the Custom Application subtab.
- General: Updated the application and Application Intake runtime versions to 6.3.0.

Version 6.2.2  
August 2026
- User Settings: Added startup migration of persisted Application Intake TextBox and ComboBox registry properties to the Desktop Application paths.
- User Settings: Preserved populated settings at their current paths, restored values where the new paths were missing or empty, and removed obsolete properties to prevent duplicate leaf-name resolution errors.
- Module Utility: Added reusable User Setting property-prefix migration for backward-compatible control-path renames.
- General: Finalized Version 6.2.2 and synchronized the application, Application Intake, Desktop Application, and touched module metadata.

Version 6.2.1  
August 2026
- Application Intake: Renamed the Intake subtab to Desktop Application to distinguish the existing locally installed application workflow from future custom application intake functionality.
- Application Intake: Updated the flattened graphics roots for Desktop Application TextBox and ComboBox controls while keeping established internal function and module names compatible.
- Application Intake: Fixed Clear All Fields so it resolves and clears every TextBox and ComboBox registered under the Desktop Application subtab without affecting sibling subtabs.
- General: Continued three-segment versioning and updated the application version to 6.2.1.

Version 6.2.0  
August 2026
- Customer Templates: Added a dedicated Application Intake subtab with sortable built-in and user template inventory.
- Customer Templates: Added roaming template storage, dual-root discovery, folder access, template information, transactional Make Copy, and guarded Recycle Bin deletion workflows.
- Customer Templates: Added backward-compatible Schema 2 manifests with themed component files for application folders, AppLocker settings, and mail templates.
- Customer Templates: Retained discovery and import compatibility for pre-6.2 flat roaming templates while enforcing complete component contracts for Schema 2 bundles.
- Customer Templates: Migrated the built-in customer bundles (default and extended folder structure) to Schema 2, so all built-in templates now use themed components while preserving their existing settings.
- Customer Templates: Renamed the extended customer profile, bundle, manifest, and Word template to describe its folder structure without obsolete customer-specific naming.
- Customer Templates: Added a user-owned Schema 2 editor with explicit add/edit/delete controls and sortable tables for general settings, application folders, AppLocker settings, and multiline mail templates.
- Customer Templates: Added validated transactional bundle saving with staged writes, normalized re-import, rollback, inventory refresh, and selection restoration.
- Customer Templates: Isolated Intake and Document Generation customer template selectors so each workflow resolves the correct selected template.
- Customer Templates: Moved the diagnostic Schema field to the final inventory column after the template folder path.
- Customer Templates: Standardized touched function help blocks, lifecycle comments, and runtime/header version metadata to Version 6.2.0.
- Module Graphics: Added reusable fixed/resizable modal shells, standardized primary/cancel action bars, selected-ListView path resolution, and inline ListView value editor helpers.
- Module Utility: Added reusable validated transactional directory updates with staging, publication, rollback, and cleanup behavior.
- General: Refactored compatible certificate, UDF, DSL, and customer-template dialogs or path actions to use shared helpers.
- General: Adopted three-segment versioning and updated the application version to 6.2.0.

Version 6.1.0  
August 2026
- Tools - Certificates: Added Certificates as the second Tools subtab after Drivers and standardized its modules to the SubTab.Certificates Feature/Helpers naming convention.
- Tools - Certificates: Added certificate search, results, selected-certificate actions, and import controls.
- Certificates: Added cached, case-insensitive search across every displayed certificate field with Search button and Enter-key support.
- Certificates: Added read-only CurrentUser and LocalMachine certificate inventory for the Show All action.
- Certificates: Added a Clear All action for clearing the certificate search term and result rows.
- Certificates: Added a preset-filter row for valid, expiring, expired, private-key, and Personal-store certificates.
- Certificates: Added typed ascending and descending sorting for every Certificate Results column.
- Certificates: Added a friendly Subject Name column derived from subject simple-name and organization data, omitting trailing parenthetical qualifiers.
- Certificates: Added a friendly Issuer Name column derived from issuer organization and simple-name data, omitting trailing parenthetical qualifiers.
- Certificates: Added a Show Details action that displays the exact selected certificate in the native Windows properties dialog.
- Certificates: Added one capability-aware Export Certificate action for public CER and password-protected PFX exports.
- Certificates: Added public CER and password-protected PFX import into exact CurrentUser or elevated LocalMachine stores with post-import verification.
- Certificates: Added installation-status checks across all readable CurrentUser and LocalMachine stores with matching results shown by thumbprint.
- Certificates: Added safe exact-store removal with multi-location selection, trust-store warnings, CurrentUser verification, and one elevation request for selected LocalMachine stores.
- Certificates: Added an Open Current User Certificates action that starts the normal Current User MMC console without elevation.
- Certificates: Added an Open Local Computer Certificates action that starts the elevated machine MMC console.
- Certificates: Centered Current User and Local Computer Certificate Manager windows over ADA at a monitor-bounded 1100 by 750 pixel size.
- Certificates: Consolidated certificate-file loading, exact-store lookup, elevated PowerShell execution, inventory matching, and active ListView refresh behavior.
- Launcher: Added separate Current User and elevated Local Computer certificate actions, each opening one native MMC console.
- Tools: Restored the alternating background and feature-color pattern after inserting Certificates.
- Module Graphics: Added reusable typed ListView column sorting and migrated Drivers to the shared helper.
- General: Adopted three-segment versioning and updated the application version to 6.1.0.

Version 6.0.3.0  
August 2026
- Module ApplicationIntake: Added correlated lifecycle logging for folder, metadata, shortcut, Word, registry, AppLocker, UDF, and workflow completion events.
- Module ApplicationIntake: Added artifact-focused workflow actions that log only verified file and folder outputs.
- Module DSL Management: Added verified lifecycle log events when application folders are archived and restored.
- Module DSL Management: Added automatic lifecycle log creation for archived or restored legacy packages that do not contain an application CSV log.
- Module DSL Management: Fixed Show All, Archive, and Restore to use the archive path saved by the current DSL Settings textbox, with legacy setting fallback.
- Modules Utility and Word: Added optional PassThru output contracts for registry, AppLocker, UDF, and Word artifact creation.
- General: Updated the application version to 6.0.3.0 so lifecycle CSV entries report the matching ToolVersion.

Version 6.0.2.0  
August 2026
- Tools - Drivers: Added searchable driver inventory, recent-driver filtering, typed column sorting, and quick/full package details.
- Tools - Drivers: Added exact SHA-256 Driver Store mapping, associated-device information, and direct access to package folders.
- Tools - Drivers: Added transactional driver package export with administrative reports, file manifests, PnPUtil logs, overwrite confirmation, and rollback protection.
- Tools - Drivers: Added confirmed elevated driver removal with inventory refresh and graceful UAC cancellation handling.
- Tools - Drivers: Added INF package staging, installation on compatible devices, and exact staged/assigned package status checks.
- Module Graphics and Utility: Added typed Browse File actions and a strict INF file-selection filter for driver installation.
- Tools - Drivers: Refactored driver functionality into responsibility-based Feature and Helpers modules for export, installation, inventory, and ListView behavior.
- Tools: Moved Drivers and UDF from the main tab bar into the Tools subtabs, with UDF placed second and aligned to the shared subtab background.
- Tools - UDF: Relocated UDF modules under Tools and standardized filenames to the SubTab.UDF Feature/Helpers naming convention.
- General: Updated the application and touched Drivers, Graphics, and Utility version metadata to 6.0.2.0.

Version 6.0.1.0  
August 2026
- Module DSL Management - Settings: Added Software Library Archive path textbox configuration for DSL archive location.
- Module DSL Management - Search: Added dual-listview workflow for active DSL folders and archived zip files.
- Module DSL Management - Search: Added archive and restore actions with context-aware Open, Copy Path, and Show Info behavior.
- Module DSL Management - Search: Added archive/restore refresh flow and cleanup semantics (source removed after successful move).
- Module DSL Management - Search: Added user confirmations for archive and restore actions using Get-UserConfirmation.
- Module Utility: Extended Get-Folder with SoftwareLibraryArchive parameter mapped to SoftwareLibraryArchiveDSL user setting.
- Module Utility: Enhanced Write-FilePropertiesToHost with file size output in bytes, MB, and GB.
- General: Updated touched DSL and utility function version headers to 6.0.1.0.

Version 6.0.0.6  
August 2026
- Tools - Other - Ping Computers: Added optional Port field and validation (1-65535) for Test-NetConnection and IP Report.
- Tools - Other - Ping Computers: Added shared helper module for Ping feature input validation and Test-NetConnection core logic.
- Tools - Other - Ping Computers: Standardized host status lifecycle messages with [START], [END], and [FAIL] markers.
- Tools - Other - Ping Computers: Improved Test-NetConnection behavior to avoid sticky progress UI and added explicit timeout/failure handling.
- Tools - Other - Ping Computers: Enhanced IP Report content with requested port and updated report filenames to include _Port<value> when provided.
- Module Graphics: Added Compact and Tiny TextBox size support used by the new optional Port field.
- General: Updated touched function comment blocks and Other sub-tab metadata to Version 6.0.0.6.

Version 6.0.0.5  
August 2026
- Module Graphics: Added reusable ListView helpers for batch updates, row selection by text/index, and value-cell hit testing.
- Module UDF: Refactored inline edit/list refresh flows to use shared ListView helpers, reducing overlap and improving maintainability.
- Module UDF: Flattened deployment object list action flows (add/move/delete) via shared update/selection helper usage.
- Module DSL Management: Migrated Search ListView refresh flow to shared batch update helper for consistent behavior.
- Module UDF: Added user-facing gray status lines for edit start, cancel, no-change, and auto-save on focus change.
- General: Standardized updated function comment blocks to Version 6.0.0.5 for touched ListView-related helpers.

Version 6.0.0.4  
August 2026
- Module UDF: Added dedicated DeploymentObjectCatalog.psd1 metadata catalog usage for object picker/default definitions.
- Module UDF: Expanded and standardized deployment object catalog metadata and display naming.
- Module UDF: Added PickerOrder metadata to all catalog object types for deterministic ordering.
- Module UDF: Applied category-specific priority ordering (including tuned priority for category 90 - OTHER).
- Module UDF: Improved catalog maintainability by sorting object definitions by category and PickerOrder.
- Assets UDF: Rebuilt UniversalDeploymentFramework.zip to include the latest catalog metadata updates.

Version 6.0.0.3  
July 2026
- Module ApplicationIntake: Improved shortcut metadata icon path fallback for document output.
- Module ApplicationIntake: Prevented duplicate shortcut export folders during document generation.
- Module ApplicationIntake: Improved Document Generation template selection and input validation behavior.

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
- General: Built from the ground up for a new customer.
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
- Module Settings: Switched the positions of the two DSL selection buttons.
- Module Settings: When changing your DSL, all relevant comboboxes are automatically updated. Also updated the reboot message.

Version 4.6
20240731
- Module CreateIntunePackage: Corrected the install commands in the Intune commands file. The Verbose parameter is now trailing.
- Module CreateIntunePackage: Changed the output folder to '2. Oplevering'.
- Module CreateIntunePackage: When the Intune Input file already exists, then it will be renamed, similar to the intunewin file.

Version 4.5
20240730
- Module ModifyMSIX: Added a new button that creates Ivanti Objects.
- Module Settings: Switched the positions of the two DSL selection buttons.

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
- Module DeploymentScript: Updated the Deploymentscript. The Administration key changed to a new registry key for the application administration.
- Module DeploymentScript: Updated the Detectionscript. The Detection key changed to the same registry key.

Version 4.1
20240620
- Module DeploymentScript: Added new module to create a Deployment and Detection script.
- Module DeploymentScript: Updated the Deployment and Detection script.

Version 4.0.1
20240620
- Module MSIInfo: Updated graphics functions. Moved Signature textbox down. Update Get Info icon.
- Module Settings: Updated User Manual with tables.
20240619
- Module Settings: Updated the DSL selection button icons.
- Module Settings: Updated graphics functions.
- Module Settings: Updated Confirmation messages.
- Module ModifyMSIX: Updated Confirmation message.

Version 4.0
20240619
- Module Settings: Added two buttons to select your DSL.
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
