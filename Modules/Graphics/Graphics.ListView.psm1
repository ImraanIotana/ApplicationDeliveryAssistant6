####################################################################################################
<#
.SYNOPSIS
    Adds graphical dimensions to the ListView settings based on GroupBox dimensions and margins.
.DESCRIPTION
    This function calculates ListView width profiles and ensures base ListView sizing settings exist in the GraphicalSettings hashtable.
.EXAMPLE
    Add-ListViewDimensions -InputObject $MyApplicationObject
.INPUTS
    [PSCustomObject]
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.3
    Author          : Imraan Iotana
    Creation Date   : July 2026
    Last Update     : July 2026
#>
####################################################################################################
function Add-ListViewDimensions {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The ApplicationObject containing the settings.')]
        [PSCustomObject]$InputObject
    )

    try {
        # PREPARATION - GET SETTINGS
        # Get the GraphicalSettings settings
        [System.Collections.Hashtable]$Settings = $InputObject.GraphicalSettings

        # Ensure the ListView settings object exists.
        if ($null -eq $Settings.ListView) {
            $Settings.ListView = @{}
        }

        # Provide defaults when values are not present in the settings data file.
        if ($null -eq $Settings.ListView.TopMargin) { $Settings.ListView.TopMargin = $Settings.TextBox.TopMargin }
        if ($null -eq $Settings.ListView.LeftMargin) { $Settings.ListView.LeftMargin = $Settings.TextBox.LeftMargin }
        if ($null -eq $Settings.ListView.RightMargin) { $Settings.ListView.RightMargin = $Settings.TextBox.RightMargin }
        if ($null -eq $Settings.ListView.Height) { $Settings.ListView.Height = ($Settings.GroupBox.RowHeight * 3) }

        # PREPARATION
        # Set width ratios for Medium and Small ListView profiles based on Large width.
        [System.Double]$MediumRatio = 0.8
        [System.Double]$SmallRatio  = 0.6

        # LISTVIEW WIDTH
        # Add the width of the Large ListView.
        [System.Int32]$ListViewLargeWidth = $Settings.GroupBox.Width - $Settings.ListView.LeftMargin - $Settings.ListView.RightMargin
        $Settings.ListView.LargeWidth = $ListViewLargeWidth
        # Add the width of the Medium ListView.
        $Settings.ListView.MediumWidth = (($ListViewLargeWidth * $MediumRatio) - 3)
        # Add the width of the Small ListView.
        $Settings.ListView.SmallWidth = (($ListViewLargeWidth * $SmallRatio) - 3)
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
    Auto-sizes all columns of a ListView based on either the header or the content.
.DESCRIPTION
    This function uses the built-in ListView column auto-size behavior and can choose
    the most appropriate mode automatically when requested.
.EXAMPLE
    Set-ListViewColumnAutoSize -ListView $MyListView
.EXAMPLE
    Set-ListViewColumnAutoSize -ListView $MyListView -Mode Content
.EXAMPLE
    Set-ListViewColumnAutoSize -ListView $MyListView -Mode Widest
.INPUTS
    [System.Windows.Forms.ListView]
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.3
    Author          : Imraan Iotana
    Creation Date   : July 2026
    Last Update     : July 2026
#>
####################################################################################################
function Set-ListViewColumnAutoSize {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The ListView whose columns will be auto-sized.')]
        [System.Windows.Forms.ListView]$ListView,

        [Parameter(Mandatory=$false,HelpMessage='The auto-size mode to use for the columns.')]
        [ValidateSet('Auto','Header','Content','Widest')]
        [System.String]$Mode = 'Auto'
    )

    try {
        # PREPARATION
        # Only process Details view list views with columns.
        if (($null -eq $ListView) -or ($ListView.View -ne [System.Windows.Forms.View]::Details) -or ($ListView.Columns.Count -eq 0)) {
            return
        }

        # EXECUTION - SET COLUMN WIDTHS
        # Use the requested mode, or choose the most suitable width automatically.
        switch ($Mode) {
            'Header' {
                $ListView.AutoResizeColumns([System.Windows.Forms.ColumnHeaderAutoResizeStyle]::HeaderSize)
            }
            'Content' {
                $ListView.AutoResizeColumns([System.Windows.Forms.ColumnHeaderAutoResizeStyle]::ColumnContent)
            }
            'Widest' {
                if ($ListView.Columns.Count -gt 0) {
                    $ListView.AutoResizeColumn(0, [System.Windows.Forms.ColumnHeaderAutoResizeStyle]::HeaderSize)
                }

                for ([System.Int32]$Index = 1; $Index -lt $ListView.Columns.Count; $Index++) {
                    $ListView.AutoResizeColumn($Index, [System.Windows.Forms.ColumnHeaderAutoResizeStyle]::HeaderSize)
                    [System.Int32]$HeaderWidth = $ListView.Columns[$Index].Width

                    $ListView.AutoResizeColumn($Index, [System.Windows.Forms.ColumnHeaderAutoResizeStyle]::ColumnContent)
                    [System.Int32]$ContentWidth = $ListView.Columns[$Index].Width

                    $ListView.Columns[$Index].Width = [System.Math]::Max($HeaderWidth, $ContentWidth)
                }
            }
            default {
                if ($ListView.Items.Count -gt 0) {
                    $ListView.AutoResizeColumns([System.Windows.Forms.ColumnHeaderAutoResizeStyle]::ColumnContent)
                }
                else {
                    $ListView.AutoResizeColumns([System.Windows.Forms.ColumnHeaderAutoResizeStyle]::HeaderSize)
                }
            }
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
    Creates a new ListView and adds it to the specified parent GroupBox.
.DESCRIPTION
    This function creates a ListView with shared graphical settings, optional label, and optional details columns.
.EXAMPLE
    New-ListView -InputObject $MyApplicationObject -ParentGroupBox $MyGroupBox -Label 'Results'
.EXAMPLE
    New-ListView -InputObject $MyApplicationObject -ParentGroupBox $MyGroupBox -RowNumber 2 -Columns @('Name','Path') -ReturnListView
.INPUTS
    [PSCustomObject]
    [System.Windows.Forms.GroupBox]
    [System.Int32]
    [System.String]
.OUTPUTS
    [System.Windows.Forms.ListView]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.3
    Author          : Imraan Iotana
    Creation Date   : July 2026
    Last Update     : July 2026
#>
####################################################################################################
function New-ListView {
    [CmdletBinding()]
    [OutputType([System.Windows.Forms.ListView])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The ApplicationObject containing the settings.')]
        [PSCustomObject]$InputObject,

        [Parameter(Mandatory=$true,HelpMessage='The Parent GroupBox to which this ListView will be added.')]
        [System.Windows.Forms.GroupBox]$ParentGroupBox,

        [Parameter(Mandatory=$false,HelpMessage='The RowNumber where the ListView will be placed.')]
        [System.Int32]$RowNumber = 1,

        [Parameter(Mandatory=$false,HelpMessage='The SizeType of the ListView. This influences only width.')]
        [ValidateSet('Small','Medium','Large')]
        [System.String]$SizeType = 'Large',

        [Parameter(Mandatory=$false,HelpMessage='Optional number of visible rows in Details view. If set, this overrides default ListView height.')]
        [System.Int32]$VisibleRowCount = 0,

        [Parameter(Mandatory=$false,HelpMessage='Optional label text shown to the left of the ListView.')]
        [System.String]$Label,

        [Parameter(Mandatory=$false,HelpMessage='Optional text color name.')]
        [System.String]$TextColor,

        [Parameter(Mandatory=$false,HelpMessage='Optional background color name.')]
        [System.String]$BackColor,

        [Parameter(Mandatory=$false,HelpMessage='The ListView view style.')]
        [ValidateSet('Details','List','SmallIcon','LargeIcon','Tile')]
        [System.String]$View = 'Details',

        [Parameter(Mandatory=$false,HelpMessage='Optional column headers when using Details view.')]
        [System.String[]]$Columns,

        [Parameter(Mandatory=$false,HelpMessage='Optional auto-size mode for Details columns.')]
        [ValidateSet('Auto','Header','Content','Widest')]
        [System.String]$ColumnAutoSizeMode = 'Auto',

        [Parameter(Mandatory=$false,HelpMessage='Optional per-control ListView theme overrides with keys like ReadOnlyBackColor and EditableTextColor.')]
        [System.Object]$ThemeOverrides,

        [Parameter(Mandatory=$false,HelpMessage='The ToolTip text to display when hovering over the ListView.')]
        [System.String]$ToolTip,

        [Parameter(Mandatory=$false,HelpMessage='Enable visible grid lines for Details view.')]
        [System.Management.Automation.SwitchParameter]$GridLines,

        [Parameter(Mandatory=$false,HelpMessage='Enable full-row selection in Details view.')]
        [System.Management.Automation.SwitchParameter]$FullRowSelect,

        [Parameter(Mandatory=$false,HelpMessage='Switch for returning the ListView object after it is created and added to the parent.')]
        [System.Management.Automation.SwitchParameter]$ReturnListView
    )

    try {
        # PREPARATION
        # Input settings and output control.
        [System.Collections.Hashtable]$Settings = $InputObject.GraphicalSettings
        [System.Windows.Forms.ListView]$NewListView = New-Object System.Windows.Forms.ListView

        # EXECUTION - SET PROPERTIES
        # LOCATION
        [System.Int32]$ListViewTopLeftX = $ParentGroupBox.Location.X + $Settings.ListView.LeftMargin
        [System.Int32]$ListViewTopLeftY = $Settings.ListView.TopMargin + (($RowNumber - 1) * $Settings.TextBox.Height)
        $NewListView.Location = New-Object System.Drawing.Point($ListViewTopLeftX, $ListViewTopLeftY)

        # SIZE
        [System.Int32]$ListViewWidth = switch ($SizeType) {
            'Large'     { $Settings.ListView.LargeWidth }
            'Medium'    { $Settings.ListView.MediumWidth }
            'Small'     { $Settings.ListView.SmallWidth }
        }
        [System.Int32]$ListViewHeight = $Settings.ListView.Height
        if (($VisibleRowCount -gt 0) -and ($View -eq 'Details')) {
            # Estimate details-row and header heights so callers can tune visible row count.
            [System.Int32]$EstimatedRowHeight = [System.Math]::Max(16, ($Settings.MainFont.Height + 4))
            [System.Int32]$EstimatedHeaderHeight = ($EstimatedRowHeight + 4)
            $ListViewHeight = $EstimatedHeaderHeight + ($EstimatedRowHeight * $VisibleRowCount) + 4
        }
        $NewListView.Size = New-Object System.Drawing.Size($ListViewWidth, $ListViewHeight)

        # FONT AND COLORS
        $NewListView.Font = $Settings.MainFont
        [System.String]$DefaultBackColor = 'White'
        [System.String]$DefaultTextColor = 'Black'
        if (($Settings.ListView -is [System.Collections.Hashtable]) -and $Settings.ListView.ContainsKey('ReadOnlyBackColor') -and (Test-String -IsPopulated ([System.String]$Settings.ListView.ReadOnlyBackColor))) {
            $DefaultBackColor = [System.String]$Settings.ListView.ReadOnlyBackColor
        }
        if (($Settings.ListView -is [System.Collections.Hashtable]) -and $Settings.ListView.ContainsKey('ReadOnlyTextColor') -and (Test-String -IsPopulated ([System.String]$Settings.ListView.ReadOnlyTextColor))) {
            $DefaultTextColor = [System.String]$Settings.ListView.ReadOnlyTextColor
        }
        $NewListView.BackColor = if (Test-String -IsPopulated $BackColor) { $BackColor } else { $DefaultBackColor }
        $NewListView.ForeColor = if (Test-String -IsPopulated $TextColor) { $TextColor } else { $DefaultTextColor }

        # VIEW STYLE
        $NewListView.View = [System.Windows.Forms.View]::$View
        $NewListView.HideSelection = $false
        $NewListView.MultiSelect = $false
        $NewListView.GridLines = $GridLines.IsPresent
        $NewListView.FullRowSelect = $FullRowSelect.IsPresent

        # METADATA
        # Store optional theme metadata on the control in a neutral, reusable shape.
        Set-ListViewThemeMetadata -ListView $NewListView -ThemeSettings $ThemeOverrides -ApplicationObject $InputObject

        # DETAILS COLUMNS
        if ($View -eq 'Details') {
            [System.String[]]$ResolvedColumns = if ($Columns.Count -gt 0) { $Columns } else { @('Result') }
            foreach ($ColumnName in $ResolvedColumns) {
                [void]$NewListView.Columns.Add([System.String]$ColumnName, -2)
            }

            Set-ListViewColumnAutoSize -ListView $NewListView -Mode $ColumnAutoSizeMode
        }

        # LABEL
        # Create the label that corresponds to this ListView when a label is provided.
        if (Test-String -IsPopulated $Label) {
            New-Label -InputObject $InputObject -ParentGroupBox $ParentGroupBox -Text $Label -RowNumber $RowNumber
        }

        # TOOLTIP
        if (Test-String -IsPopulated $ToolTip) {
            [System.Windows.Forms.ToolTip]$ListViewToolTip = New-Object System.Windows.Forms.ToolTip
            $ListViewToolTip.SetToolTip($NewListView, $ToolTip)
        }

        # ADD TO PARENT
        $ParentGroupBox.Controls.Add($NewListView)

        # POST-EXECUTION
        if ($ReturnListView) { $NewListView }
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}

### END OF FUNCTION
####################################################################################################
