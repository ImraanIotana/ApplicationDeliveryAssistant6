####################################################################################################
<#
.SYNOPSIS
	Resolves the configured log folder for an application package.
.DESCRIPTION
	Reads the Logs path from the selected customer template and combines it with the supplied
	application folder path. The resolved folder must already exist.
.EXAMPLE
	Get-ApplicationLogFolderPath -ApplicationFolderPath 'C:\Temp\Vendor_App_1.0' -SelectedTemplate $Template
.INPUTS
	[System.String]
	[System.Object]
.OUTPUTS
	[System.String]
.NOTES
	This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
	Version         : 6.3.1
	Author          : Imraan Iotana
	Creation Date   : August 2026
	Last Update     : August 2026
#>
####################################################################################################
function Get-ApplicationLogFolderPath {
	[CmdletBinding()]
	[OutputType([System.String])]
	param (
		[Parameter(Mandatory=$true,HelpMessage='The root folder of the application package.')]
		[System.String]$ApplicationFolderPath,

		[Parameter(Mandatory=$true,HelpMessage='The selected customer template object.')]
		[System.Object]$SelectedTemplate
	)

	try {
		# VALIDATION - APPLICATION FOLDER
		if (-not (Test-Path -LiteralPath $ApplicationFolderPath -PathType Container)) {
			throw "The application folder does not exist: ($ApplicationFolderPath)"
		}

		# PREPARATION - TEMPLATE LOG PATH
		[System.String]$LogRelativePath = [System.String]$SelectedTemplate.ApplicationFolderSubFolders.Logs
		if (Test-String -IsEmpty $LogRelativePath) {
			throw 'The selected customer template does not define ApplicationFolderSubFolders.Logs.'
		}

		# EXECUTION - LOG FOLDER RESOLUTION
		[System.String]$LogFolderPath = Join-Path -Path $ApplicationFolderPath -ChildPath $LogRelativePath
		if (-not (Test-Path -LiteralPath $LogFolderPath -PathType Container)) {
			throw "The configured log folder does not exist: ($LogFolderPath)"
		}

		# POST-EXECUTION
		return $LogFolderPath
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
	Resolves an application log and its canonical Application ID.
.DESCRIPTION
	Searches an application package recursively for its structured *_Log.csv file. The exact
	<ApplicationFolderName>_Log.csv file is preferred; otherwise one unambiguous log is accepted.
	When CreateIfMissing is specified, a new canonical log path is resolved in the package's unique
	Logs folder, or in 9. Archive\Logs when no Logs folder exists.
.EXAMPLE
	Get-ApplicationLogContext -ApplicationFolderPath 'C:\Temp\Vendor_App_1.0'
.EXAMPLE
	Get-ApplicationLogContext -ApplicationFolderPath 'C:\Temp\Vendor_App_1.0' -CreateIfMissing
.INPUTS
	[System.String]
.OUTPUTS
	[PSCustomObject] containing LogFilePath and ApplicationID, or no object when no log exists and
	CreateIfMissing is not specified.
.NOTES
	This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
	Version         : 6.0.3.0
	Author          : Imraan Iotana
	Creation Date   : August 2026
	Last Update     : August 2026
#>
####################################################################################################
function Get-ApplicationLogContext {
	[CmdletBinding()]
	[OutputType([PSCustomObject])]
	param (
		[Parameter(Mandatory=$true,HelpMessage='The root folder of the application package.')]
		[System.String]$ApplicationFolderPath,

		[Parameter(Mandatory=$false,HelpMessage='Resolve a canonical log path when no application log exists.')]
		[System.Management.Automation.SwitchParameter]$CreateIfMissing
	)

	try {
		# VALIDATION - APPLICATION FOLDER
		if (-not (Test-Path -LiteralPath $ApplicationFolderPath -PathType Container)) {
			throw "The application folder does not exist: ($ApplicationFolderPath)"
		}

		# PREPARATION - LOG CANDIDATES
		[System.String]$FolderApplicationID = Split-Path -Path $ApplicationFolderPath -Leaf
		[System.String]$ExpectedLogFileName = "${FolderApplicationID}_Log.csv"
		[System.IO.FileInfo[]]$LogFiles = @(Get-ChildItem -LiteralPath $ApplicationFolderPath -File -Filter '*_Log.csv' -Recurse -ErrorAction SilentlyContinue)
		if ($LogFiles.Count -eq 0) {
			if (-not $CreateIfMissing) {
				return
			}

			# PREPARATION - NEW LOG DESTINATION
			[System.IO.DirectoryInfo[]]$LogFolders = @(Get-ChildItem -LiteralPath $ApplicationFolderPath -Directory -Recurse -Force -ErrorAction SilentlyContinue | Where-Object { $_.Name -ieq 'Logs' })
			[System.String]$LogFolderPath = if ($LogFolders.Count -eq 1) {
				[System.String]$LogFolders[0].FullName
			}
			elseif ($LogFolders.Count -eq 0) {
				[System.String](Join-Path -Path $ApplicationFolderPath -ChildPath '9. Archive\Logs')
			}
			else {
				throw "Multiple Logs folders were found and no unique application log destination could be selected. ($ApplicationFolderPath)"
			}

			if (-not (Test-Path -LiteralPath $LogFolderPath -PathType Container)) {
				New-Item -Path $LogFolderPath -ItemType Directory -Force | Out-Null
			}

			return [PSCustomObject]@{
				LogFilePath  = [System.String](Join-Path -Path $LogFolderPath -ChildPath $ExpectedLogFileName)
				ApplicationID = $FolderApplicationID
			}
		}

		[System.IO.FileInfo[]]$ExactLogFiles = @($LogFiles | Where-Object { $_.Name -ieq $ExpectedLogFileName })
		[System.IO.FileInfo]$LogFile = if ($ExactLogFiles.Count -eq 1) {
			$ExactLogFiles[0]
		}
		elseif ($LogFiles.Count -eq 1) {
			$LogFiles[0]
		}
		else {
			throw "Multiple application log files were found and no unique canonical log could be selected. ($ApplicationFolderPath)"
		}

		# PREPARATION - CANONICAL APPLICATION ID
		[PSCustomObject]$FirstLogEntry = Import-Csv -LiteralPath $LogFile.FullName | Select-Object -First 1
		[System.String]$ApplicationID = if (($null -ne $FirstLogEntry) -and (Test-String -IsPopulated ([System.String]$FirstLogEntry.ApplicationID))) {
			[System.String]$FirstLogEntry.ApplicationID
		}
		else {
			$LogFile.BaseName -replace '_Log$', ''
		}

		# OUTPUT - LOG CONTEXT
		return [PSCustomObject]@{
			LogFilePath  = [System.String]$LogFile.FullName
			ApplicationID = $ApplicationID
		}
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
	Writes one structured event to an application CSV log file.
.DESCRIPTION
	Creates a schema version 1.0 log entry and writes it to the supplied CSV file. The first entry
	creates the file and header; subsequent entries are appended using the same canonical schema.
.EXAMPLE
	Write-ApplicationLogEntry -LogFilePath 'C:\Temp\Vendor_App_1.0_Log.csv' -ApplicationID 'Vendor_App_1.0' -Status Success -Action ApplicationFolderCreated -Details 'Created application folder.'
.INPUTS
	[System.String]
.OUTPUTS
	No objects are returned to the pipeline.
.NOTES
	This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
	Version         : 6.0.3.0
	Author          : Imraan Iotana
	Creation Date   : August 2026
	Last Update     : August 2026
#>
####################################################################################################
function Write-ApplicationLogEntry {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory=$true,HelpMessage='The application CSV log file to write to.')]
		[System.String]$LogFilePath,

		[Parameter(Mandatory=$true,HelpMessage='The Application ID associated with the event.')]
		[System.String]$ApplicationID,

		[Parameter(Mandatory=$true,HelpMessage='The outcome of the logged action.')]
		[ValidateSet('Started','Success','Warning','Failed','Cancelled')]
		[System.String]$Status,

		[Parameter(Mandatory=$true,HelpMessage='The stable identifier of the action that occurred.')]
		[System.String]$Action,

		[Parameter(Mandatory=$false,HelpMessage='Optional event-specific information.')]
		[AllowEmptyString()]
		[System.String]$Details = [System.String]::Empty,

		[Parameter(Mandatory=$false,HelpMessage='The identifier used to correlate entries from the same operation.')]
		[ValidateNotNullOrEmpty()]
		[System.String]$OperationID = [System.Guid]::NewGuid().ToString()
	)

	try {
		# VALIDATION - LOG DESTINATION
		if (Test-String -IsEmpty $LogFilePath) { throw 'The LogFilePath parameter is empty.' }
		if ([System.IO.Path]::GetExtension($LogFilePath) -ine '.csv') { throw "The application log file must use the .csv extension. ($LogFilePath)" }
		[System.String]$LogFolderPath = Split-Path -Path $LogFilePath -Parent
		if (-not (Test-Path -LiteralPath $LogFolderPath -PathType Container)) { throw "The application log folder does not exist. ($LogFolderPath)" }

		# PREPARATION - LOG ENTRY
		[System.DateTime]$EventTime = Get-Date
		[System.String]$UserName = if (Test-String -IsPopulated $env:USERDOMAIN) { "$env:USERDOMAIN\$env:USERNAME" } else { [System.String]$env:USERNAME }
		[System.String]$ToolVersion = if ($null -ne $Global:ApplicationObject -and $null -ne $Global:ApplicationObject.Version) { [System.String]$Global:ApplicationObject.Version } else { 'Unknown' }
		[PSCustomObject]$LogEntry = [PSCustomObject][ordered]@{
			Timestamp     = $EventTime.ToString('yyyy-MM-dd HH:mm:ss')
			Status        = $Status
			Action        = $Action
			Details       = $Details
			ApplicationID = $ApplicationID
			User          = $UserName
			Computer      = [System.String]$env:COMPUTERNAME
			EventID       = [System.Guid]::NewGuid().ToString()
			OperationID   = $OperationID
			SchemaVersion = '1.0'
			ToolVersion   = $ToolVersion
			TimestampUTC  = $EventTime.ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
		}

		# EXECUTION - WRITE LOG ENTRY
		[System.Boolean]$Append = Test-Path -LiteralPath $LogFilePath -PathType Leaf
		if ($Append) {
			$LogEntry | Export-Csv -LiteralPath $LogFilePath -Append -NoTypeInformation -Encoding UTF8
		}
		else {
			$LogEntry | Export-Csv -LiteralPath $LogFilePath -NoTypeInformation -Encoding UTF8
		}

		# VALIDATION - WRITTEN LOG FILE
		if (-not (Test-Path -LiteralPath $LogFilePath -PathType Leaf)) { throw "The application log entry was not written. ($LogFilePath)" }

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
	Writes a successful file-creation event when the expected artifact exists.
.DESCRIPTION
	Validates an artifact path, derives its filename for the event details, and delegates the
	structured CSV entry to Write-ApplicationLogEntry. No entry is written for an empty or missing path.
.EXAMPLE
	Write-ApplicationFileLogEntry -LogFilePath $LogFilePath -ApplicationID $ApplicationID -OperationID $OperationID -FilePath $MetaDataFilePath -Action MetadataFileCreated -DetailsPrefix 'Created metadata file'
.INPUTS
	[System.String]
.OUTPUTS
	No objects are returned to the pipeline.
.NOTES
	This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
	Version         : 6.3.1
	Author          : Imraan Iotana
	Creation Date   : August 2026
	Last Update     : August 2026
#>
####################################################################################################
function Write-ApplicationFileLogEntry {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory=$true,HelpMessage='The application CSV log file to write to.')]
		[System.String]$LogFilePath,

		[Parameter(Mandatory=$true,HelpMessage='The Application ID associated with the event.')]
		[System.String]$ApplicationID,

		[Parameter(Mandatory=$true,HelpMessage='The identifier used to correlate entries from the same operation.')]
		[System.String]$OperationID,

		[Parameter(Mandatory=$false,HelpMessage='The created artifact file to record.')]
		[AllowNull()][AllowEmptyString()]
		[System.String]$FilePath,

		[Parameter(Mandatory=$true,HelpMessage='The stable identifier of the file-creation action.')]
		[System.String]$Action,

		[Parameter(Mandatory=$true,HelpMessage='The text placed before the created artifact filename.')]
		[System.String]$DetailsPrefix
	)

	# VALIDATION - CREATED FILE
	if ((Test-String -IsEmpty $FilePath) -or (-not (Test-Path -LiteralPath $FilePath -PathType Leaf))) {
		return
	}

	# PREPARATION - EVENT DETAILS
	[System.String]$FileName = Split-Path -Path $FilePath -Leaf

	# EXECUTION - WRITE FILE EVENT
	Write-ApplicationLogEntry -LogFilePath $LogFilePath -ApplicationID $ApplicationID -Status Success -Action $Action -Details "${DetailsPrefix}: $FileName" -OperationID $OperationID
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
	Writes a successful folder-creation event when the expected folder exists.
.DESCRIPTION
	Validates an artifact path, derives its folder name for the event details, and delegates the
	structured CSV entry to Write-ApplicationLogEntry. No entry is written for an empty or missing path.
.EXAMPLE
	Write-ApplicationFolderLogEntry -LogFilePath $LogFilePath -ApplicationID $ApplicationID -OperationID $OperationID -FolderPath $AppLockerFolderPath -Action AppLockerPoliciesCreated -DetailsPrefix 'Created AppLocker policies in folder'
.INPUTS
	[System.String]
.OUTPUTS
	No objects are returned to the pipeline.
.NOTES
	This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
	Version         : 6.0.3.0
	Author          : Imraan Iotana
	Creation Date   : August 2026
	Last Update     : August 2026
#>
####################################################################################################
function Write-ApplicationFolderLogEntry {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory=$true,HelpMessage='The application CSV log file to write to.')]
		[System.String]$LogFilePath,

		[Parameter(Mandatory=$true,HelpMessage='The Application ID associated with the event.')]
		[System.String]$ApplicationID,

		[Parameter(Mandatory=$true,HelpMessage='The identifier used to correlate entries from the same operation.')]
		[System.String]$OperationID,

		[Parameter(Mandatory=$false,HelpMessage='The created artifact folder to record.')]
		[AllowNull()][AllowEmptyString()]
		[System.String]$FolderPath,

		[Parameter(Mandatory=$true,HelpMessage='The stable identifier of the folder-creation action.')]
		[System.String]$Action,

		[Parameter(Mandatory=$true,HelpMessage='The text placed before the created artifact folder name.')]
		[System.String]$DetailsPrefix
	)

	# VALIDATION - CREATED FOLDER
	if ((Test-String -IsEmpty $FolderPath) -or (-not (Test-Path -LiteralPath $FolderPath -PathType Container))) {
		return
	}

	# PREPARATION - EVENT DETAILS
	[System.String]$FolderName = Split-Path -Path $FolderPath -Leaf

	# EXECUTION - WRITE FOLDER EVENT
	Write-ApplicationLogEntry -LogFilePath $LogFilePath -ApplicationID $ApplicationID -Status Success -Action $Action -Details "${DetailsPrefix}: $FolderName" -OperationID $OperationID
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
	Creates the history log file for an application package.
.DESCRIPTION
	Resolves the template-configured log folder and creates <ApplicationID>_Log.csv with an initial
	ApplicationFolderCreated entry. The entry includes user-facing local time and enterprise metadata,
	including a precise UTC timestamp. An existing log file is returned without being overwritten.
.EXAMPLE
	New-ApplicationLogFile -ApplicationFolderPath 'C:\Temp\Vendor_App_1.0' -SelectedTemplate $Template
.INPUTS
	[System.String]
	[System.Object]
	[System.String]
.OUTPUTS
	[System.String]
.NOTES
	This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
	Version         : 6.3.1
	Author          : Imraan Iotana
	Creation Date   : August 2026
	Last Update     : August 2026
#>
####################################################################################################
function New-ApplicationLogFile {
	[CmdletBinding()]
	[OutputType([System.String])]
	param (
		[Parameter(Mandatory=$true,HelpMessage='The root folder of the application package.')]
		[System.String]$ApplicationFolderPath,

		[Parameter(Mandatory=$true,HelpMessage='The selected customer template object.')]
		[System.Object]$SelectedTemplate,

		[Parameter(Mandatory=$false,HelpMessage='The identifier used to correlate entries from the same operation.')]
		[ValidateNotNullOrEmpty()]
		[System.String]$OperationID = [System.Guid]::NewGuid().ToString(),

		[Parameter(Mandatory=$false,HelpMessage='Optional explicit Application ID when the package is created in a staging folder.')]
		[System.String]$ApplicationID
	)

	try {
		# PREPARATION - LOG FILE PATH
		[System.String]$LogFolderPath = Get-ApplicationLogFolderPath -ApplicationFolderPath $ApplicationFolderPath -SelectedTemplate $SelectedTemplate
		if (Test-String -IsEmpty $LogFolderPath) {
			throw 'The application log folder could not be resolved.'
		}
		if (Test-String -IsEmpty $ApplicationID) {
			$ApplicationID = Split-Path -Path $ApplicationFolderPath -Leaf
		}
		[System.String]$SafeApplicationID = ($ApplicationID -replace '[\\/:*?"<>|]', '_')
		[System.String]$LogFilePath = Join-Path -Path $LogFolderPath -ChildPath "${SafeApplicationID}_Log.csv"

		# VALIDATION - EXISTING LOG FILE
		if (Test-Path -LiteralPath $LogFilePath -PathType Leaf) {
			Write-Line "The application log file already exists: ($LogFilePath)" -Type Warning
			return $LogFilePath
		}

		# EXECUTION - CREATE LOG FILE
		Write-ApplicationLogEntry -LogFilePath $LogFilePath -ApplicationID $ApplicationID -Status Success -Action ApplicationFolderCreated -Details 'Application folder structure created.' -OperationID $OperationID
		if (-not (Test-Path -LiteralPath $LogFilePath -PathType Leaf)) {
			throw "The application log file was not created: ($LogFilePath)"
		}

		# POST-EXECUTION
		Write-Line "Created application log file: ($LogFilePath)" -Type Success
		return $LogFilePath
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
	Creates a WinForms application log viewer.
.DESCRIPTION
	Builds a resizable form with a read-only, sortable DataGridView bound to the supplied log entries.
.EXAMPLE
	New-ApplicationLogViewerForm -LogEntries $Entries -Title 'Application Log'
.INPUTS
	[System.Object[]]
	[System.String]
.OUTPUTS
	[System.Windows.Forms.Form]
.NOTES
	This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
	Version         : 6.4.1
	Author          : Imraan Iotana
	Creation Date   : August 2026
	Last Update     : August 2026
#>
####################################################################################################
function New-ApplicationLogViewerForm {
	[CmdletBinding()]
	[OutputType([System.Windows.Forms.Form])]
	param (
		[Parameter(Mandatory=$true,HelpMessage='The imported application log entries to display.')]
		[System.Object[]]$LogEntries,

		[Parameter(Mandatory=$true,HelpMessage='The title of the log viewer window.')]
		[System.String]$Title
	)

	# PREPARATION - DATA TABLE
	[System.Data.DataTable]$LogTable = New-Object System.Data.DataTable
	[System.String[]]$AvailableColumnNames = @($LogEntries[0].PSObject.Properties.Name)
	[System.String[]]$CanonicalColumnNames = @(
		'Timestamp',
		'Status',
		'Action',
		'Details',
		'ApplicationID',
		'User',
		'Computer',
		'EventID',
		'OperationID',
		'SchemaVersion',
		'ToolVersion',
		'TimestampUTC'
	)
	[System.String[]]$ColumnNames = @($CanonicalColumnNames | Where-Object { $_ -in $AvailableColumnNames })
	$ColumnNames += @($AvailableColumnNames | Where-Object { $_ -notin $CanonicalColumnNames })
	foreach ($ColumnName in $ColumnNames) {
		[void]$LogTable.Columns.Add($ColumnName, [System.String])
	}
	foreach ($LogEntry in $LogEntries) {
		[System.Data.DataRow]$DataRow = $LogTable.NewRow()
		foreach ($ColumnName in $ColumnNames) {
			$DataRow[$ColumnName] = [System.String]$LogEntry.$ColumnName
		}
		[void]$LogTable.Rows.Add($DataRow)
	}

	# PREPARATION - VIEWER FORM
	[System.Windows.Forms.Form]$ViewerForm = New-Object System.Windows.Forms.Form
	$ViewerForm.Text = $Title
	$ViewerForm.StartPosition = 'CenterParent'
	$ViewerForm.Size = New-Object System.Drawing.Size(1100, 550)
	$ViewerForm.MinimumSize = New-Object System.Drawing.Size(750, 350)
	$ViewerForm.FormBorderStyle = 'Sizable'
	$ViewerForm.MinimizeBox = $false
	$ViewerForm.MaximizeBox = $true
	$ViewerForm.KeyPreview = $true
	if ($null -ne $Global:MainForm -and $null -ne $Global:MainForm.Icon) {
		$ViewerForm.Icon = $Global:MainForm.Icon
	}

	# PREPARATION - DATA GRID
	[System.Windows.Forms.DataGridView]$LogGrid = New-Object System.Windows.Forms.DataGridView
	$LogGrid.Name = 'ApplicationLogGrid'
	$LogGrid.Dock = 'Fill'
	$LogGrid.ReadOnly = $true
	$LogGrid.AllowUserToAddRows = $false
	$LogGrid.AllowUserToDeleteRows = $false
	$LogGrid.AllowUserToOrderColumns = $true
	$LogGrid.AutoGenerateColumns = $false
	$LogGrid.AutoSizeColumnsMode = 'DisplayedCells'
	$LogGrid.BackgroundColor = [System.Drawing.Color]::White
	$LogGrid.BorderStyle = 'None'
	$LogGrid.MultiSelect = $false
	$LogGrid.RowHeadersVisible = $false
	$LogGrid.SelectionMode = 'FullRowSelect'
	$LogGrid.ClipboardCopyMode = 'EnableAlwaysIncludeHeaderText'

	# EXECUTION - DATA GRID COLUMNS
	foreach ($ColumnName in $ColumnNames) {
		[System.Windows.Forms.DataGridViewTextBoxColumn]$GridColumn = New-Object System.Windows.Forms.DataGridViewTextBoxColumn
		$GridColumn.Name = $ColumnName
		$GridColumn.HeaderText = $ColumnName
		$GridColumn.DataPropertyName = $ColumnName
		$GridColumn.SortMode = 'Automatic'
		[void]$LogGrid.Columns.Add($GridColumn)
	}
	$LogGrid.DataSource = $LogTable
	for ([System.Int32]$ColumnIndex = 0; $ColumnIndex -lt $ColumnNames.Count; $ColumnIndex++) {
		$LogGrid.Columns[$ColumnNames[$ColumnIndex]].DisplayIndex = $ColumnIndex
	}

	# EXECUTION - COLUMN PRESENTATION
	if ($LogGrid.Columns.Contains('Details')) {
		$LogGrid.Columns['Details'].AutoSizeMode = 'None'
		$LogGrid.Columns['Details'].MinimumWidth = 250
		$LogGrid.Columns['Details'].Width = 450
		$LogGrid.Columns['Details'].Resizable = 'True'
	}

	# PREPARATION - STATUS BAR
	[System.Windows.Forms.StatusStrip]$StatusBar = New-Object System.Windows.Forms.StatusStrip
	[System.Windows.Forms.ToolStripStatusLabel]$RowCountLabel = New-Object System.Windows.Forms.ToolStripStatusLabel
	$RowCountLabel.Text = "Entries: $($LogEntries.Count)"
	[void]$StatusBar.Items.Add($RowCountLabel)

	# EXECUTION - VIEWER CONTROLS
	[void]$ViewerForm.Controls.Add($LogGrid)
	[void]$ViewerForm.Controls.Add($StatusBar)
	$ViewerForm.Add_KeyDown({
		if ($_.KeyCode -eq [System.Windows.Forms.Keys]::Escape) {
			$this.Close()
		}
	})

	# POST-EXECUTION
	return $ViewerForm
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
	Displays a CSV application log file in the ADA log viewer.
.DESCRIPTION
	Validates and imports the selected CSV file, then shows its rows in an owned WinForms DataGridView.
.EXAMPLE
	Show-LogFileInGridView -Path 'C:\Temp\Vendor_App_1.0_Log.csv'
.INPUTS
	[System.String]
.OUTPUTS
	No objects are returned to the pipeline.
.NOTES
	This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
	Version         : 6.4.1
	Author          : Imraan Iotana
	Creation Date   : August 2026
	Last Update     : August 2026
#>
####################################################################################################
function Show-LogFileInGridView {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory=$false,HelpMessage='The CSV application log file to display.')]
		[AllowNull()][AllowEmptyString()]
		[System.String]$Path
	)

	try {
		# VALIDATION - LOG FILE
		if (-not (Confirm-FileExtension -Path $Path -Name 'CSV Log File' -AllowedExtensions @('.csv'))) {
			return
		}

		# EXECUTION - IMPORT LOG ENTRIES
		[System.Object[]]$LogEntries = @(Import-Csv -LiteralPath $Path -ErrorAction Stop)
		if ($LogEntries.Count -eq 0) {
			Write-Line "The selected CSV log file contains no entries. ($Path)" -Type Warning
			return
		}

		# PREPARATION - LOG VIEWER
		[System.String]$LogFileName = Split-Path -Path $Path -Leaf
		[System.Windows.Forms.Form]$ViewerForm = New-ApplicationLogViewerForm -LogEntries $LogEntries -Title "$LogFileName - Application Log"

		# EXECUTION - SHOW LOG VIEWER
		try {
			if ($null -ne $Global:MainForm -and -not $Global:MainForm.IsDisposed) {
				[void]$ViewerForm.ShowDialog($Global:MainForm)
			}
			else {
				[void]$ViewerForm.ShowDialog()
			}
		}
		finally {
			$ViewerForm.Dispose()
		}
	}
	catch {
		Write-ErrorReport -ErrorRecord $_
	}
}

### END OF FUNCTION
####################################################################################################
