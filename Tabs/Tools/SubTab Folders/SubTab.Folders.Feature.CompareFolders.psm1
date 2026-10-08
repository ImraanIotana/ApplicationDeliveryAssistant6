####################################################################################################
<#
.SYNOPSIS
    Imports the Folder Compare feature into the Folders sub-tab.
.DESCRIPTION
    This function imports the Folder Compare feature into the Folders sub-tab by creating a new GroupBox and adding it to the specified parent TabPage.
.EXAMPLE
    Import-FeatureCompareFolders -InputObject $MyApplicationObject -ParentTabPage $MyTabPage
.INPUTS
    [PSCustomObject]
    [System.Windows.Forms.TabPage]
    [System.Windows.Forms.GroupBox]
    [System.String]
.OUTPUTS
    [System.Windows.Forms.GroupBox]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.8.1
    Author          : Imraan Iotana
    Creation Date   : July 2026
    Last Update     : September 2026
#>
####################################################################################################
function Import-FeatureCompareFolders {
    [CmdletBinding()]
    [OutputType([System.Windows.Forms.GroupBox])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The ApplicationObject containing the Settings.')]
        [PSCustomObject]$InputObject,

        [Parameter(Mandatory=$true,HelpMessage='The Parent TabPage to which this Feature will be added.')]
        [System.Windows.Forms.TabPage]$ParentTabPage,

        [Parameter(Mandatory=$false,HelpMessage='The GroupBox underneath which this Feature will be added.')]
        [System.Windows.Forms.GroupBox]$GroupBoxAbove,

        [Parameter(Mandatory=$false,HelpMessage='The color of the GroupBox.')]
        [System.String]$Color
    )

    try {
        # PREPARATION - GROUPBOX PROPERTIES
        # Set the GroupBox properties
        [System.Collections.Hashtable]$GroupBoxProperties = @{
            InputObject     = $InputObject
            ParentTabPage   = $ParentTabPage
            Title           = 'COMPARE FOLDERS'
            Color           = $Color
            NumberOfRows    = 3
            GroupBoxAbove   = $GroupBoxAbove
        }

        # EXECUTION - GROUPBOX
        # Create the GroupBox
        [System.Windows.Forms.GroupBox]$FeatureGroupBox = New-GroupBox @GroupBoxProperties

        # PREPARATION - TEXTBOX PROPERTIES
        # Set the TextBox properties
        [System.Collections.Hashtable]$Folder1TextBoxProperties = @{
            RowNumber       = 1
            Label           = 'Select Folder 1'
            ToolTip         = 'The path of the first folder to compare.'
            SizeType        = 'Medium'
            SmallButtons    = @(@(5,'Browse Folder'),@(6,'Paste'),@(7,'Open'))
        }
        [System.Collections.Hashtable]$Folder2TextBoxProperties = @{
            RowNumber       = 2
            Label           = 'Select Folder 2'
            ToolTip         = 'The path of the second folder to compare.'
            SizeType        = 'Medium'
            SmallButtons    = @(@(5,'Browse Folder'),@(6,'Paste'),@(7,'Open'))
        }

        # EXECUTION - TEXTBOXES
        # Create the TextBoxes
        [System.Windows.Forms.TextBox]$FolderPath1TextBox = New-TextBox @Folder1TextBoxProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ReturnTextBox
        [System.Windows.Forms.TextBox]$FolderPath2TextBox = New-TextBox @Folder2TextBoxProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ReturnTextBox

        # PREPARATION - BUTTON PROPERTIES
        # Set the Button properties
        [System.Collections.Hashtable[]]$ButtonPropertiesArray = @(
            @{
                ColumnNumber    = 1
                Text            = 'Compare'
                PNGFileName     = 'price_comparison'
                SizeType        = 'Medium'
                Function        = {
                    Compare-Folders -Folder1Path $FolderPath1TextBox.Text -Folder2Path $FolderPath2TextBox.Text
                }.GetNewClosure()
            }
            @{
                ColumnNumber    = 7
                Text            = 'Clear Fields'
                PNGFileName     = 'textfield_delete'
                SizeType        = 'Small'
                ToolTip         = 'Clear both fields.'
                Function        = {
                    if (-not(Get-UserConfirmation -Title 'Clear Fields' -Body "This will CLEAR the fields.`n`nAre you sure you want to continue?")) { return }
                    Clear-TextBox -TextBox $FolderPath1TextBox -Force
                    Clear-TextBox -TextBox $FolderPath2TextBox -Force
                }.GetNewClosure()
            }
        )

        # EXECUTION - BUTTONS
        # Create the Buttons
        New-ButtonLine -InputObject $InputObject -ButtonPropertiesArray $ButtonPropertiesArray -ParentGroupBox $FeatureGroupBox -RowNumber 3

        # POST-EXECUTION
        # Return the GroupBox object
        $FeatureGroupBox
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
    Compares two folders and displays file-level differences.
.DESCRIPTION
    Reports files found only in one folder, newer modified timestamps, and content differences.
    Matching files are hashed to detect changes that have the same size and timestamp.
.EXAMPLE
    Compare-Folders -Folder1Path 'C:\Folder1' -Folder2Path 'C:\Folder2'
.INPUTS
    [System.String]
    [System.String]
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.8.1
    Author          : Imraan Iotana
    Creation Date   : July 2026
    Last Update     : September 2026
#>
####################################################################################################
function Compare-Folders {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false,HelpMessage='The path of the first folder.')]
        [System.String]$Folder1Path,

        [Parameter(Mandatory=$false,HelpMessage='The path of the second folder.')]
        [System.String]$Folder2Path,

        [Parameter(Mandatory=$false,HelpMessage='The hashing algorithm to use. Defaults to SHA256.')]
        [System.String]$Algorithm = 'SHA256',

        [Parameter(Mandatory=$false,HelpMessage='The folder size threshold in bytes used to trigger a confirmation before hash comparison. Defaults to 2GB.')]
        [System.Int64]$LargeFolderSizeThreshold = 2GB,

        [Parameter(Mandatory=$false,HelpMessage='If specified, returns $true when content comparison completes and the folders contain the same files and content.')]
        [System.Management.Automation.SwitchParameter]$PassThru
    )

    try {
        # VALIDATION
        # Validate the input folder paths
        if (-not (Test-CompareFolderPath -Path $Folder1Path -Name 'Folder 1')) {
            if ($PassThru) { return $false }
            return
        }
        if (-not (Test-CompareFolderPath -Path $Folder2Path -Name 'Folder 2')) {
            if ($PassThru) { return $false }
            return
        }

        # EXECUTION - COMPARE FOLDER CONTENTS
        [System.Int64]$Folder1Size = Get-FolderSize -Path $Folder1Path
        [System.Int64]$Folder2Size = Get-FolderSize -Path $Folder2Path
        [System.Double]$Folder1SizeMB = [System.Math]::Round($Folder1Size / 1MB, 3)
        [System.Double]$Folder2SizeMB = [System.Math]::Round($Folder2Size / 1MB, 3)
        Write-Line "Folder 1 size: [$Folder1SizeMB MB]."
        Write-Line "Folder 2 size: [$Folder2SizeMB MB]."

        [System.Boolean]$CompareContent = $true
        [System.Int64]$LargestFolderSizeBytes = [System.Math]::Max($Folder1Size, $Folder2Size)
        if ($LargestFolderSizeBytes -gt $LargeFolderSizeThreshold) {
            [System.Double]$ThresholdGB = [System.Math]::Round($LargeFolderSizeThreshold / 1GB, 3)
            if (-not (Get-UserConfirmation -Title 'Confirm Hash Large Folder' -Body "At least one folder is larger than [$ThresholdGB GB].`nComparing file contents may take a while.`n`nDo you want to continue?" -Type 'Warning')) {
                $CompareContent = $false
            }
        }

        [PSCustomObject[]]$Differences = @(Get-FolderComparisonDifferences -Folder1Path $Folder1Path -Folder2Path $Folder2Path -Algorithm $Algorithm -CompareContent:$CompareContent)
        Show-FolderComparisonResults -Differences $Differences -Folder1Path $Folder1Path -Folder2Path $Folder2Path -Folder1SizeBytes $Folder1Size -Folder2SizeBytes $Folder2Size -ContentComparisonComplete $CompareContent

        if ($PassThru) {
            [PSCustomObject[]]$ContentDifferences = @($Differences | Where-Object { ($_.Content -eq 'Different') -or ($_.Content -eq 'Present') })
            return (($ContentDifferences.Count -eq 0) -and $CompareContent)
        }
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
        if ($PassThru) { return $false }
    }
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Finds file-level differences between two folders.
.DESCRIPTION
    Compares relative paths, sizes, modified timestamps, and optionally hashes matching files.
.NOTES
    Version         : 6.8.1
    Last Update     : September 2026
#>
####################################################################################################
function Get-FolderComparisonDifferences {
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param (
        [Parameter(Mandatory=$true)]
        [System.String]$Folder1Path,

        [Parameter(Mandatory=$true)]
        [System.String]$Folder2Path,

        [Parameter(Mandatory=$false)]
        [System.String]$Algorithm = 'SHA256',

        [Parameter(Mandatory=$false)]
        [System.Management.Automation.SwitchParameter]$CompareContent
    )

    [System.String]$Folder1Root = [System.IO.Path]::GetFullPath($Folder1Path).TrimEnd([char[]]@('\','/'))
    [System.String]$Folder2Root = [System.IO.Path]::GetFullPath($Folder2Path).TrimEnd([char[]]@('\','/'))
    [System.Collections.Hashtable]$Folder1Files = @{}
    [System.Collections.Hashtable]$Folder2Files = @{}

    foreach ($File in @(Get-ChildItem -LiteralPath $Folder1Path -File -Recurse -Force -ErrorAction SilentlyContinue)) {
        [System.String]$RelativePath = $File.FullName.Substring($Folder1Root.Length).TrimStart([char[]]@('\','/'))
        $Folder1Files[$RelativePath] = $File
    }
    foreach ($File in @(Get-ChildItem -LiteralPath $Folder2Path -File -Recurse -Force -ErrorAction SilentlyContinue)) {
        [System.String]$RelativePath = $File.FullName.Substring($Folder2Root.Length).TrimStart([char[]]@('\','/'))
        $Folder2Files[$RelativePath] = $File
    }

    [System.String[]]$RelativePaths = @($Folder1Files.Keys) + @($Folder2Files.Keys)
    [System.String[]]$RelativePaths = @($RelativePaths | Sort-Object -Unique)
    [System.Collections.Generic.List[PSCustomObject]]$Differences = New-Object 'System.Collections.Generic.List[PSCustomObject]'
    [System.Int32]$ContentFilesToCheck = 0
    if ($CompareContent) {
        foreach ($RelativePath in $RelativePaths) {
            if ($Folder1Files.ContainsKey($RelativePath) -and $Folder2Files.ContainsKey($RelativePath) -and ($Folder1Files[$RelativePath].Length -eq $Folder2Files[$RelativePath].Length)) {
                $ContentFilesToCheck++
            }
        }
    }

    [System.Int32]$ContentFilesChecked = 0
    foreach ($RelativePath in $RelativePaths) {
        [System.IO.FileInfo]$File1 = $Folder1Files[$RelativePath]
        [System.IO.FileInfo]$File2 = $Folder2Files[$RelativePath]
        [System.String]$Status = ''
        [System.String]$ContentStatus = 'Not checked'

        if (-not $Folder1Files.ContainsKey($RelativePath)) {
            $Status = 'Only in Folder 2'
            $ContentStatus = 'Present'
        }
        elseif (-not $Folder2Files.ContainsKey($RelativePath)) {
            $Status = 'Only in Folder 1'
            $ContentStatus = 'Present'
        }
        else {
            if ($File1.Length -ne $File2.Length) {
                $ContentStatus = 'Different'
            }
            elseif ($CompareContent) {
                $ContentFilesChecked++
                Write-Progress -Activity 'Comparing folder contents' -Status "Checking file $ContentFilesChecked of $ContentFilesToCheck" -PercentComplete ([int](($ContentFilesChecked * 100) / [System.Math]::Max(1, $ContentFilesToCheck)))
                [System.String]$File1Hash = (Get-FileHash -LiteralPath $File1.FullName -Algorithm $Algorithm -ErrorAction Stop).Hash
                [System.String]$File2Hash = (Get-FileHash -LiteralPath $File2.FullName -Algorithm $Algorithm -ErrorAction Stop).Hash
                $ContentStatus = if ($File1Hash -eq $File2Hash) { 'Same' } else { 'Different' }
            }

            if ($File1.LastWriteTimeUtc -gt $File2.LastWriteTimeUtc) {
                $Status = 'Newer in Folder 1'
            }
            elseif ($File2.LastWriteTimeUtc -gt $File1.LastWriteTimeUtc) {
                $Status = 'Newer in Folder 2'
            }
            elseif ($ContentStatus -eq 'Different') {
                $Status = 'Content differs'
            }
        }

        if (-not [System.String]::IsNullOrEmpty($Status)) {
            [void]$Differences.Add([PSCustomObject]@{
                Status         = $Status
                RelativePath   = $RelativePath
                Folder1Modified = if ($Folder1Files.ContainsKey($RelativePath)) { $File1.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss') } else { '-' }
                Folder2Modified = if ($Folder2Files.ContainsKey($RelativePath)) { $File2.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss') } else { '-' }
                Folder1Size    = if ($Folder1Files.ContainsKey($RelativePath)) { '{0:N0} bytes' -f $File1.Length } else { '-' }
                Folder2Size    = if ($Folder2Files.ContainsKey($RelativePath)) { '{0:N0} bytes' -f $File2.Length } else { '-' }
                Content        = $ContentStatus
            })
        }
    }
    if ($CompareContent) { Write-Progress -Activity 'Comparing folder contents' -Completed }

    return $Differences.ToArray()
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Displays folder comparison differences in a results window.
.NOTES
    Version         : 6.8.1
    Last Update     : September 2026
#>
####################################################################################################
function Show-FolderComparisonResults {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false)]
        [AllowEmptyCollection()]
        [PSCustomObject[]]$Differences = @(),

        [Parameter(Mandatory=$true)]
        [System.String]$Folder1Path,

        [Parameter(Mandatory=$true)]
        [System.String]$Folder2Path,

        [Parameter(Mandatory=$true)]
        [System.Int64]$Folder1SizeBytes,

        [Parameter(Mandatory=$true)]
        [System.Int64]$Folder2SizeBytes,

        [Parameter(Mandatory=$true)]
        [System.Boolean]$ContentComparisonComplete
    )

    [System.Double]$Folder1SizeMB = [System.Math]::Round($Folder1SizeBytes / 1MB, 3)
    [System.Double]$Folder2SizeMB = [System.Math]::Round($Folder2SizeBytes / 1MB, 3)
    [System.String]$SummaryText = "Differences found: $($Differences.Count)   |   Folder 1: $Folder1SizeMB MB   |   Folder 2: $Folder2SizeMB MB"
    if (-not $ContentComparisonComplete) {
        $SummaryText += '   |   Content checks skipped for same-size files.'
    }
    elseif ($Differences.Count -eq 0) {
        $SummaryText = "No differences found   |   Folder size: $Folder1SizeMB MB"
    }

    [System.Windows.Forms.Form]$Dialog = New-Object System.Windows.Forms.Form
    $Dialog.Text = 'Folder Comparison Results'
    $Dialog.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterParent
    $Dialog.ClientSize = New-Object System.Drawing.Size(1180, 670)
    $Dialog.MinimumSize = New-Object System.Drawing.Size(900, 450)
    $Dialog.ShowInTaskbar = $false

    [System.Drawing.Bitmap]$WindowIconBitmap = $null
    [System.IntPtr]$WindowIconHandle = [System.IntPtr]::Zero
    try {
        [System.Drawing.Image]$WindowIconImage = $Global:ApplicationObject.GraphicalSettings.ButtonIcons['folder_lightbulb']
        if ($null -ne $WindowIconImage) {
            if (-not ('ADAFolderComparisonIconNativeMethods' -as [type])) {
                Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public static class ADAFolderComparisonIconNativeMethods
{
    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool DestroyIcon(IntPtr handle);
}
'@ -ErrorAction Stop | Out-Null
            }
            $WindowIconBitmap = New-Object System.Drawing.Bitmap($WindowIconImage)
            $WindowIconHandle = $WindowIconBitmap.GetHicon()
            $Dialog.Icon = [System.Drawing.Icon]::FromHandle($WindowIconHandle)
        }
    }
    catch {
        if ($null -ne $WindowIconBitmap) {
            $WindowIconBitmap.Dispose()
            $WindowIconBitmap = $null
        }
    }

    [System.Windows.Forms.Label]$SummaryLabel = New-Object System.Windows.Forms.Label
    $SummaryLabel.Location = New-Object System.Drawing.Point(12, 12)
    $SummaryLabel.Size = New-Object System.Drawing.Size(1140, 26)
    $SummaryLabel.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
    $SummaryLabel.AutoEllipsis = $true
    $SummaryLabel.Text = $SummaryText

    [System.Windows.Forms.Label]$FolderPathsLabel = New-Object System.Windows.Forms.Label
    $FolderPathsLabel.Location = New-Object System.Drawing.Point(12, 42)
    $FolderPathsLabel.Size = New-Object System.Drawing.Size(1140, 40)
    $FolderPathsLabel.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
    $FolderPathsLabel.AutoEllipsis = $true
    $FolderPathsLabel.Text = "Folder 1: $Folder1Path`r`nFolder 2: $Folder2Path"

    [System.Windows.Forms.ListView]$ResultsListView = New-Object System.Windows.Forms.ListView
    $ResultsListView.Location = New-Object System.Drawing.Point(12, 88)
    $ResultsListView.Size = New-Object System.Drawing.Size(1140, 516)
    $ResultsListView.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
    $ResultsListView.View = [System.Windows.Forms.View]::Details
    $ResultsListView.FullRowSelect = $true
    $ResultsListView.GridLines = $true
    $ResultsListView.MultiSelect = $false
    $ResultsListView.HideSelection = $false
    [void]$ResultsListView.Columns.Add('Status', 150)
    [void]$ResultsListView.Columns.Add('Relative path', 390)
    [void]$ResultsListView.Columns.Add('Folder 1 modified', 150)
    [void]$ResultsListView.Columns.Add('Folder 2 modified', 150)
    [void]$ResultsListView.Columns.Add('Folder 1 size', 100)
    [void]$ResultsListView.Columns.Add('Folder 2 size', 100)
    [void]$ResultsListView.Columns.Add('Content', 100)

    if ($Differences.Count -eq 0) {
        [System.String]$EmptyMessage = if ($ContentComparisonComplete) { 'No differences found.' } else { 'No path, size, or timestamp differences found.' }
        [System.Windows.Forms.ListViewItem]$EmptyRow = New-Object System.Windows.Forms.ListViewItem($EmptyMessage)
        for ([System.Int32]$ColumnIndex = 1; $ColumnIndex -lt $ResultsListView.Columns.Count; $ColumnIndex++) {
            [void]$EmptyRow.SubItems.Add('')
        }
        $null = $ResultsListView.Items.Add($EmptyRow)
    }
    else {
        foreach ($Difference in @($Differences | Sort-Object -Property Status, RelativePath)) {
            [System.Windows.Forms.ListViewItem]$Row = New-Object System.Windows.Forms.ListViewItem([System.String]$Difference.Status)
            [System.Drawing.Color]$StatusBackColor = [System.Drawing.SystemColors]::Window
            [System.Drawing.Color]$StatusForeColor = [System.Drawing.SystemColors]::WindowText
            switch ($Difference.Status) {
                'Newer in Folder 1' {
                    $StatusBackColor = [System.Drawing.Color]::FromArgb(226, 241, 240)
                    $StatusForeColor = [System.Drawing.Color]::FromArgb(24, 68, 74)
                    break
                }
                'Newer in Folder 2' {
                    $StatusBackColor = [System.Drawing.Color]::FromArgb(226, 235, 247)
                    $StatusForeColor = [System.Drawing.Color]::FromArgb(36, 58, 96)
                    break
                }
                'Only in Folder 1' {
                    $StatusBackColor = [System.Drawing.Color]::FromArgb(251, 240, 207)
                    $StatusForeColor = [System.Drawing.Color]::FromArgb(102, 64, 8)
                    break
                }
                'Only in Folder 2' {
                    $StatusBackColor = [System.Drawing.Color]::FromArgb(248, 229, 207)
                    $StatusForeColor = [System.Drawing.Color]::FromArgb(104, 55, 20)
                    break
                }
                'Content differs' {
                    $StatusBackColor = [System.Drawing.Color]::FromArgb(238, 241, 244)
                    $StatusForeColor = [System.Drawing.Color]::FromArgb(64, 76, 86)
                    break
                }
            }
            [void]$Row.SubItems.Add([System.String]$Difference.RelativePath)
            [void]$Row.SubItems.Add([System.String]$Difference.Folder1Modified)
            [void]$Row.SubItems.Add([System.String]$Difference.Folder2Modified)
            [void]$Row.SubItems.Add([System.String]$Difference.Folder1Size)
            [void]$Row.SubItems.Add([System.String]$Difference.Folder2Size)
            [void]$Row.SubItems.Add([System.String]$Difference.Content)
            $Row.UseItemStyleForSubItems = $false
            foreach ($SubItem in $Row.SubItems) {
                $SubItem.BackColor = $StatusBackColor
            }
            $Row.SubItems[0].ForeColor = $StatusForeColor
            $null = $ResultsListView.Items.Add($Row)
        }
    }

    [System.Collections.Hashtable]$SortState = @{ ColumnIndex = 0; Descending = $false }
    $ResultsListView.Add_ColumnClick({
        param ($Sender, $EventArgs)
        if ($EventArgs.Column -eq $SortState.ColumnIndex) {
            $SortState.Descending = -not $SortState.Descending
        }
        else {
            $SortState.ColumnIndex = $EventArgs.Column
            $SortState.Descending = $false
        }

        [System.Int32]$SortColumnIndex = $SortState.ColumnIndex
        [System.Boolean]$SortDescending = $SortState.Descending
        $SortExpression = {
            [System.String]$ColumnText = $_.SubItems[$SortColumnIndex].Text
            if (($SortColumnIndex -eq 4) -or ($SortColumnIndex -eq 5)) {
                [System.Int64]$SizeInBytes = 0
                [void][System.Int64]::TryParse(($ColumnText -replace '[^\d]', ''), [ref]$SizeInBytes)
                return $SizeInBytes
            }
            return $ColumnText
        }.GetNewClosure()

        [System.Windows.Forms.ListViewItem[]]$CurrentItems = @($Sender.Items | ForEach-Object { $_ })
        [System.Windows.Forms.ListViewItem[]]$SortedItems = @($CurrentItems | Sort-Object -Property $SortExpression -Descending:$SortDescending)
        $Sender.BeginUpdate()
        try {
            $Sender.Items.Clear()
            foreach ($Item in $SortedItems) {
                $null = $Sender.Items.Add($Item)
            }
        }
        finally {
            $Sender.EndUpdate()
        }
    }.GetNewClosure())

    $ResultsListView.Add_DoubleClick({
        param ($Sender, $EventArgs)
        if ($Sender.SelectedItems.Count -ne 1) { return }

        [System.Windows.Forms.ListViewItem]$SelectedRow = $Sender.SelectedItems[0]
        [System.String]$RelativePath = $SelectedRow.SubItems[1].Text
        [System.String]$TargetFolderPath = ''
        switch ($SelectedRow.Text) {
            'Only in Folder 1' { $TargetFolderPath = $Folder1Path; break }
            'Only in Folder 2' { $TargetFolderPath = $Folder2Path; break }
            'Newer in Folder 1' { $TargetFolderPath = $Folder1Path; break }
            'Newer in Folder 2' { $TargetFolderPath = $Folder2Path; break }
            'Content differs' {
                [System.String]$ChoiceMessage = "This file differs in both folders. Choose which copy to open:`r`n`r`nYes: Folder 1`r`nNo: Folder 2`r`nCancel: Do nothing`r`n`r`nFolder 1: $Folder1Path`r`nFolder 2: $Folder2Path"
                if ($Global:MainForm -is [System.Windows.Forms.Form]) {
                    [System.Windows.Forms.DialogResult]$Choice = [System.Windows.Forms.MessageBox]::Show($Global:MainForm, $ChoiceMessage, 'Open Compared File', [System.Windows.Forms.MessageBoxButtons]::YesNoCancel, [System.Windows.Forms.MessageBoxIcon]::Question)
                }
                else {
                    [System.Windows.Forms.DialogResult]$Choice = [System.Windows.Forms.MessageBox]::Show($ChoiceMessage, 'Open Compared File', [System.Windows.Forms.MessageBoxButtons]::YesNoCancel, [System.Windows.Forms.MessageBoxIcon]::Question)
                }
                if ($Choice -eq [System.Windows.Forms.DialogResult]::Yes) { $TargetFolderPath = $Folder1Path }
                elseif ($Choice -eq [System.Windows.Forms.DialogResult]::No) { $TargetFolderPath = $Folder2Path }
                break
            }
            default { return }
        }

        if ([System.String]::IsNullOrWhiteSpace($TargetFolderPath) -or [System.String]::IsNullOrWhiteSpace($RelativePath)) { return }
        [System.String]$FileToHighlight = Join-Path -Path $TargetFolderPath -ChildPath $RelativePath
        Open-Folder -HighlightItem $FileToHighlight
    }.GetNewClosure())

    [System.Windows.Forms.Button]$CloseButton = New-Object System.Windows.Forms.Button
    $CloseButton.Text = 'Close'
    $CloseButton.Size = New-Object System.Drawing.Size(100, 30)
    $CloseButton.Location = New-Object System.Drawing.Point(1068, 628)
    $CloseButton.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Right
    $CloseButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $Dialog.AcceptButton = $CloseButton

    $Dialog.Controls.AddRange(@($SummaryLabel, $FolderPathsLabel, $ResultsListView, $CloseButton))
    try {
        if ($Global:MainForm -is [System.Windows.Forms.Form]) {
            [void]$Dialog.ShowDialog($Global:MainForm)
        }
        else {
            [void]$Dialog.ShowDialog()
        }
    }
    finally {
        $Dialog.Dispose()
        if ($WindowIconHandle -ne [System.IntPtr]::Zero) {
            $null = [ADAFolderComparisonIconNativeMethods]::DestroyIcon($WindowIconHandle)
        }
        if ($null -ne $WindowIconBitmap) {
            $WindowIconBitmap.Dispose()
        }
    }
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Compares the recursive sizes of two folders.
.DESCRIPTION
    Retrieves and compares the recursive total sizes of two specified folders, writing the results to the host.
.EXAMPLE
    Compare-FolderSize -Folder1Path 'C:\Folder1' -Folder2Path 'C:\Folder2'
.INPUTS
    [System.String]
    [System.String]
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.8.1
    Author          : Imraan Iotana
    Creation Date   : July 2026
    Last Update     : September 2026
#>
####################################################################################################
function Compare-FolderSize {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false,HelpMessage='The path of the first folder.')]
        [System.String]$Folder1Path,

        [Parameter(Mandatory=$false,HelpMessage='The path of the second folder.')]
        [System.String]$Folder2Path,

        [Parameter(Mandatory=$false,HelpMessage='If specified, returns $true if the folders are the same size, otherwise $false.')]
        [System.Management.Automation.SwitchParameter]$PassThru
    )

    try {
        # VALIDATION
        # Validate the input folder paths
        if (-not (Test-CompareFolderPath -Path $Folder1Path -Name 'Folder 1')) {
            if ($PassThru) { return $false }
            return
        }
        if (-not (Test-CompareFolderPath -Path $Folder2Path -Name 'Folder 2')) {
            if ($PassThru) { return $false }
            return
        }

        # EXECUTION - GET FOLDER SIZES
        # Get recursive size of Folder 1
        Write-Line "Getting size of Folder 1 ($Folder1Path)..."
        [System.Int64]$Folder1Size = Get-FolderSize -Path $Folder1Path

        # Get recursive size of Folder 2
        Write-Line "Getting size of Folder 2 ($Folder2Path)..."
        [System.Int64]$Folder2Size = Get-FolderSize -Path $Folder2Path

        # POST-EXECUTION - COMPARE SIZES
        # Report the sizes and compare them
        [System.Double]$Folder1SizeMB = [System.Math]::Round($Folder1Size / 1MB, 3)
        [System.Double]$Folder2SizeMB = [System.Math]::Round($Folder2Size / 1MB, 3)
        Write-Line "Folder 1 size: [$Folder1SizeMB MB]."
        Write-Line "Folder 2 size: [$Folder2SizeMB MB]."

        [System.Boolean]$SizesMatch = $Folder1Size -eq $Folder2Size
        if ($SizesMatch) {
            Write-Line "Result: Both folders are the same size ([$Folder1SizeMB MB])."
        }
        elseif ($Folder1Size -gt $Folder2Size) {
            [System.Double]$DifferenceMB = [System.Math]::Round(($Folder1Size - $Folder2Size) / 1MB, 3)
            Write-Line "Result: Folder 1 is larger by [$DifferenceMB MB]."
        }
        else {
            [System.Double]$DifferenceMB = [System.Math]::Round(($Folder2Size - $Folder1Size) / 1MB, 3)
            Write-Line "Result: Folder 2 is larger by [$DifferenceMB MB]."
        }

        # Return the result if PassThru is specified
        if ($PassThru) { return $SizesMatch }
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
        if ($PassThru) { return $false }
    }
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Compares the content signatures of two folders.
.DESCRIPTION
    Builds a deterministic signature for each folder by hashing each file and its relative path,
    then hashing the combined manifest text.
.EXAMPLE
    Compare-FolderHash -Folder1Path 'C:\Folder1' -Folder2Path 'C:\Folder2'
.INPUTS
    [System.String]
    [System.String]
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.8.1
    Author          : Imraan Iotana
    Creation Date   : July 2026
    Last Update     : September 2026
#>
####################################################################################################
function Compare-FolderHash {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false,HelpMessage='The path of the first folder.')]
        [System.String]$Folder1Path,

        [Parameter(Mandatory=$false,HelpMessage='The path of the second folder.')]
        [System.String]$Folder2Path,

        [Parameter(Mandatory=$false,HelpMessage='The hashing algorithm to use. Defaults to SHA256.')]
        [System.String]$Algorithm = 'SHA256',

        [Parameter(Mandatory=$false,HelpMessage='If specified, returns $true if the folders have the same hash, otherwise $false.')]
        [System.Management.Automation.SwitchParameter]$PassThru
    )

    try {
        # VALIDATION
        # Validate the input folder paths
        if (-not (Test-CompareFolderPath -Path $Folder1Path -Name 'Folder 1')) {
            if ($PassThru) { return $false }
            return
        }
        if (-not (Test-CompareFolderPath -Path $Folder2Path -Name 'Folder 2')) {
            if ($PassThru) { return $false }
            return
        }

        # EXECUTION - GET FOLDER HASHES
        # Get the deterministic folder signature hash for Folder 1
        Write-Line "Getting hash of Folder 1 ($Folder1Path)..."
        [System.String]$Folder1Hash = Get-FolderSignatureHash -Path $Folder1Path -Algorithm $Algorithm
        Write-Line "Folder 1 hash ($Algorithm): [$Folder1Hash]."

        # Get the deterministic folder signature hash for Folder 2
        Write-Line "Getting hash of Folder 2 ($Folder2Path)..."
        [System.String]$Folder2Hash = Get-FolderSignatureHash -Path $Folder2Path -Algorithm $Algorithm
        Write-Line "Folder 2 hash ($Algorithm): [$Folder2Hash]."

        # POST-EXECUTION - COMPARE HASHES
        # Report the comparison result
        [System.Boolean]$FolderHashesAreEqual = $Folder1Hash -eq $Folder2Hash
        if ($FolderHashesAreEqual) {
            Write-Line "Result: Both folders have the same hash ([$Folder1Hash])." -Type Info
        }
        else {
            Write-Line 'Result: The folders have different hashes.' -Type Info
        }

        # Return the result if PassThru is specified
        if ($PassThru) { return $FolderHashesAreEqual }
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
        if ($PassThru) { return $false }
    }
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Returns recursive folder size in bytes.
.DESCRIPTION
    Retrieves all files recursively in the supplied folder and returns the total length in bytes.
.EXAMPLE
    Get-FolderSize -Path 'C:\Folder1'
.INPUTS
    [System.String]
.OUTPUTS
    [System.Int64]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.8.1
    Author          : Imraan Iotana
    Creation Date   : July 2026
    Last Update     : September 2026
#>
####################################################################################################
function Get-FolderSize {
    [CmdletBinding()]
    [OutputType([System.Int64])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The folder path to size.')]
        [System.String]$Path
    )

    # Sum recursive file lengths; inaccessible files are ignored by design
    [System.IO.FileInfo[]]$Files = @(Get-ChildItem -LiteralPath $Path -File -Recurse -Force -ErrorAction SilentlyContinue)
    [System.Int64](@($Files | Measure-Object -Property Length -Sum).Sum)
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Builds and returns a deterministic folder signature hash.
.DESCRIPTION
    Generates a manifest consisting of each file's relative path and file hash, sorted by path,
    and returns the hash of that manifest text.
.EXAMPLE
    Get-FolderSignatureHash -Path 'C:\Folder1' -Algorithm 'SHA256'
.INPUTS
    [System.String]
.OUTPUTS
    [System.String]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.8.1
    Author          : Imraan Iotana
    Creation Date   : July 2026
    Last Update     : September 2026
#>
####################################################################################################
function Get-FolderSignatureHash {
    [CmdletBinding()]
    [OutputType([System.String])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The folder path to hash.')]
        [System.String]$Path,

        [Parameter(Mandatory=$false,HelpMessage='The hashing algorithm to use. Defaults to SHA256.')]
        [System.String]$Algorithm = 'SHA256'
    )

    [System.String]$NormalizedRoot = [System.IO.Path]::GetFullPath($Path).TrimEnd('\\')
    [System.IO.FileInfo[]]$Files = @(Get-ChildItem -LiteralPath $Path -File -Recurse -Force -ErrorAction SilentlyContinue | Sort-Object -Property FullName)

    # Build stable manifest lines: relative-path|file-hash
    [System.Collections.Generic.List[System.String]]$ManifestLines = New-Object 'System.Collections.Generic.List[System.String]'
    foreach ($File in $Files) {
        [System.String]$RelativePath = $File.FullName.Substring($NormalizedRoot.Length).TrimStart('\\')
        [System.String]$FileHash = (Get-FileHash -LiteralPath $File.FullName -Algorithm $Algorithm -ErrorAction Stop).Hash
        [void]$ManifestLines.Add("$RelativePath|$FileHash")
    }

    [System.String]$ManifestText = ($ManifestLines -join "`n")
    [System.Byte[]]$ManifestBytes = [System.Text.Encoding]::UTF8.GetBytes($ManifestText)

    # Hash the manifest bytes through a temp file for PS 5.1 compatibility
    [System.String]$TempFilePath = [System.IO.Path]::GetTempFileName()
    try {
        [System.IO.File]::WriteAllBytes($TempFilePath, $ManifestBytes)
        (Get-FileHash -LiteralPath $TempFilePath -Algorithm $Algorithm -ErrorAction Stop).Hash
    }
    finally {
        if (Test-Path -LiteralPath $TempFilePath) {
            Remove-Item -LiteralPath $TempFilePath -Force -ErrorAction SilentlyContinue
        }
    }
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Validates that a comparison folder path is populated and exists.
.DESCRIPTION
    Shared validation helper for folder comparison functions.
.EXAMPLE
    Test-CompareFolderPath -Path 'C:\Folder1' -Name 'Folder 1'
.INPUTS
    [System.String]
.OUTPUTS
    [System.Boolean]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.8.1
    Author          : Imraan Iotana
    Creation Date   : July 2026
    Last Update     : September 2026
#>
####################################################################################################
function Test-CompareFolderPath {
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The folder path to validate.')]
        [System.String]$Path,

        [Parameter(Mandatory=$true,HelpMessage='The display name used in validation messages.')]
        [System.String]$Name
    )

    if (Test-String -IsEmpty $Path) {
        Write-Line "The path for '$Name' is empty. Please provide a valid path." -Type Warning
        return $false
    }
    if (-not (Test-Path -LiteralPath $Path)) {
        Write-Line "The path for '$Name' does not exist. Please provide a valid path. ($Path)" -Type Warning
        return $false
    }
    if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
        Write-Line "The path for '$Name' is not a folder. Please provide a valid folder path. ($Path)" -Type Warning
        return $false
    }

    return $true
}

### END OF FUNCTION
####################################################################################################
