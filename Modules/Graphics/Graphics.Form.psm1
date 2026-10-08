
####################################################################################################
<#
.SYNOPSIS
    Sets the window icon of a form from one of the button icons.
.DESCRIPTION
    Converts a loaded button icon image to a window icon and releases the native icon handle when
    the form closes. Nothing changes when the icon is unknown or cannot be converted.
.EXAMPLE
    Set-FormIconFromButtonIcon -Form $Dialog -IconName 'report_word'
.INPUTS
    [System.Windows.Forms.Form]
    [System.String]
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.9.0
    Author          : Imraan Iotana
    Creation Date   : October 2026
    Last Update     : October 2026
#>
####################################################################################################
function Set-FormIconFromButtonIcon {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The form that receives the window icon.')]
        [System.Windows.Forms.Form]$Form,

        [Parameter(Mandatory=$true,HelpMessage='The file name (without extension) of the button icon.')]
        [System.String]$IconName
    )

    [System.Drawing.Bitmap]$IconBitmap = $null
    try {
        # VALIDATION - ICON
        [System.Collections.Hashtable]$ButtonIcons = $Global:ApplicationObject.GraphicalSettings.ButtonIcons
        if (($null -eq $ButtonIcons) -or (-not $ButtonIcons.ContainsKey($IconName))) { return }

        # PREPARATION - NATIVE METHOD
        if (-not ('ADAFormIconNativeMethods' -as [type])) {
            Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public static class ADAFormIconNativeMethods
{
    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool DestroyIcon(IntPtr handle);
}
'@ -ErrorAction Stop | Out-Null
        }

        # EXECUTION - SET THE ICON
        $IconBitmap = New-Object System.Drawing.Bitmap([System.Drawing.Image]$ButtonIcons[$IconName])
        [System.IntPtr]$IconHandle = $IconBitmap.GetHicon()
        $Form.Icon = [System.Drawing.Icon]::FromHandle($IconHandle)

        # POST-EXECUTION - RELEASE THE HANDLE
        $Form.Add_FormClosed({
            [void][ADAFormIconNativeMethods]::DestroyIcon($IconHandle)
            $IconBitmap.Dispose()
        }.GetNewClosure())
    }
    catch {
        # The default window icon is an acceptable fallback
        if ($null -ne $IconBitmap) { $IconBitmap.Dispose() }
    }
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Creates a consistently configured modal dialog form.
.DESCRIPTION
    Creates a fixed or resizable dialog with owner-aware centering and no separate taskbar entry.
    Callers remain responsible for adding feature-specific controls and disposal.
.EXAMPLE
    $Dialog = New-ModalDialog -Title 'Enter Name' -ClientWidth 430 -ClientHeight 145
    Creates an unowned modal dialog that is centered on the screen.
.EXAMPLE
    $Dialog = New-ModalDialog -Title 'Export Certificate' -ClientWidth 470 -ClientHeight 190 -Owner $MainForm
    Creates a modal dialog that is centered on the supplied owner window.
.INPUTS
    [System.String]
    [System.Int32]
    [System.Windows.Forms.IWin32Window]
.OUTPUTS
    [System.Windows.Forms.Form]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.2.0
    Author          : Imraan Iotana
    Creation Date   : August 2026
    Last Update     : August 2026
#>
####################################################################################################
function New-ModalDialog {
    [CmdletBinding()]
    [OutputType([System.Windows.Forms.Form])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The title shown in the modal dialog title bar.')]
        [System.String]$Title,

        [Parameter(Mandatory=$true,HelpMessage='The width of the modal dialog client area.')]
        [ValidateRange(1,32767)]
        [System.Int32]$ClientWidth,

        [Parameter(Mandatory=$true,HelpMessage='The height of the modal dialog client area.')]
        [ValidateRange(1,32767)]
        [System.Int32]$ClientHeight,

        [Parameter(Mandatory=$false,HelpMessage='Optional window that will own the modal dialog.')]
        [AllowNull()]
        [System.Windows.Forms.IWin32Window]$Owner,

        [Parameter(Mandatory=$false,HelpMessage='Allow the dialog to be resized and maximized.')]
        [System.Management.Automation.SwitchParameter]$Resizable,

        [Parameter(Mandatory=$false,HelpMessage='Optional minimum width for a resizable dialog.')]
        [ValidateRange(0,32767)]
        [System.Int32]$MinimumWidth = 0,

        [Parameter(Mandatory=$false,HelpMessage='Optional minimum height for a resizable dialog.')]
        [ValidateRange(0,32767)]
        [System.Int32]$MinimumHeight = 0
    )

    # PREPARATION
    # Create a new Form Object
    [System.Windows.Forms.Form]$Dialog = New-Object System.Windows.Forms.Form

    # EXECUTION - SET THE DIALOG PROPERTIES
    # Set the title and client dimensions of the new modal dialog
    $Dialog.Text = $Title
    $Dialog.ClientSize = New-Object System.Drawing.Size($ClientWidth,$ClientHeight)
    # Configure fixed prompts or resizable editor windows through one shared shell
    $Dialog.FormBorderStyle = if ($Resizable) { [System.Windows.Forms.FormBorderStyle]::Sizable } else { [System.Windows.Forms.FormBorderStyle]::FixedDialog }
    $Dialog.MaximizeBox = [System.Boolean]$Resizable
    $Dialog.MinimizeBox = $false
    $Dialog.ShowInTaskbar = $false
    if ($Resizable -and ($MinimumWidth -gt 0) -and ($MinimumHeight -gt 0)) {
        $Dialog.MinimumSize = New-Object System.Drawing.Size($MinimumWidth,$MinimumHeight)
    }

    # EXECUTION - SET THE START POSITION
    # Center the modal dialog on its owner when supplied, or on the screen when no owner is available
    $Dialog.StartPosition = if ($null -ne $Owner) {
        [System.Windows.Forms.FormStartPosition]::CenterParent
    }
    else {
        [System.Windows.Forms.FormStartPosition]::CenterScreen
    }

    # OUTPUT
    # Return the configured modal dialog to the caller
    return $Dialog
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Adds a standard primary/cancel action bar to a modal dialog.
.DESCRIPTION
    Creates a bottom-docked panel with right-aligned primary and Cancel buttons, configures the
    dialog's default and cancel actions, and returns the controls for feature-specific event wiring.
.EXAMPLE
    $Actions = New-ModalDialogActionBar -Dialog $Dialog -PrimaryText 'Save'
.OUTPUTS
    [PSCustomObject]
#>
####################################################################################################
function New-ModalDialogActionBar {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The modal dialog that owns the action bar.')]
        [System.Windows.Forms.Form]$Dialog,

        [Parameter(Mandatory=$true,HelpMessage='Text shown on the primary action button.')]
        [System.String]$PrimaryText,

        [Parameter(Mandatory=$false,HelpMessage='Dialog result assigned directly by the primary button.')]
        [System.Windows.Forms.DialogResult]$PrimaryDialogResult = [System.Windows.Forms.DialogResult]::None,

        [Parameter(Mandatory=$false,HelpMessage='Whether the primary action starts enabled.')]
        [System.Boolean]$PrimaryEnabled = $true,

        [Parameter(Mandatory=$false,HelpMessage='Height of the bottom action panel.')]
        [ValidateRange(1,32767)]
        [System.Int32]$PanelHeight = 52,

        [Parameter(Mandatory=$false,HelpMessage='Width of each action button.')]
        [ValidateRange(1,32767)]
        [System.Int32]$ButtonWidth = 80,

        [Parameter(Mandatory=$false,HelpMessage='Height of each action button.')]
        [ValidateRange(1,32767)]
        [System.Int32]$ButtonHeight = 30,

        [Parameter(Mandatory=$false,HelpMessage='Right and top margin used inside the action panel.')]
        [ValidateRange(0,32767)]
        [System.Int32]$Margin = 12,

        [Parameter(Mandatory=$false,HelpMessage='Space between the primary and Cancel buttons.')]
        [ValidateRange(0,32767)]
        [System.Int32]$Spacing = 10
    )

    [System.Windows.Forms.Panel]$ActionPanel = New-Object System.Windows.Forms.Panel
    $ActionPanel.Dock = [System.Windows.Forms.DockStyle]::Bottom
    $ActionPanel.Height = $PanelHeight
    $ActionPanel.Width = $Dialog.ClientSize.Width
    $Dialog.Controls.Add($ActionPanel)
    $Dialog.PerformLayout()

    [System.Windows.Forms.Button]$CancelButton = New-Object System.Windows.Forms.Button
    $CancelButton.Text = 'Cancel'
    $CancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $CancelButton.Size = New-Object System.Drawing.Size($ButtonWidth,$ButtonHeight)
    $CancelButton.Location = New-Object System.Drawing.Point(($ActionPanel.ClientSize.Width - $Margin - $ButtonWidth),$Margin)
    $CancelButton.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Right

    [System.Windows.Forms.Button]$PrimaryButton = New-Object System.Windows.Forms.Button
    $PrimaryButton.Text = $PrimaryText
    $PrimaryButton.DialogResult = $PrimaryDialogResult
    $PrimaryButton.Enabled = $PrimaryEnabled
    $PrimaryButton.Size = New-Object System.Drawing.Size($ButtonWidth,$ButtonHeight)
    $PrimaryButton.Location = New-Object System.Drawing.Point(($CancelButton.Left - $Spacing - $ButtonWidth),$Margin)
    $PrimaryButton.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Right

    $ActionPanel.Controls.AddRange(@($PrimaryButton,$CancelButton))
    $Dialog.AcceptButton = $PrimaryButton
    $Dialog.CancelButton = $CancelButton

    return [PSCustomObject]@{
        Panel        = $ActionPanel
        PrimaryButton = $PrimaryButton
        CancelButton  = $CancelButton
    }
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Displays a form as an optionally owned modal dialog.
.DESCRIPTION
    Displays the supplied Form as a modal dialog. When an owner window is provided, the dialog is
    shown as an owned modal window; otherwise, it is shown without an owner.
.EXAMPLE
    Show-ModalDialog -Dialog $Dialog -Owner $MainForm
    Displays the modal dialog with the main form as its owner.
.EXAMPLE
    Show-ModalDialog -Dialog $Dialog
    Displays the modal dialog without an owner window.
.INPUTS
    [System.Windows.Forms.Form]
    [System.Windows.Forms.IWin32Window]
.OUTPUTS
    [System.Windows.Forms.DialogResult]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.2.0
    Author          : Imraan Iotana
    Creation Date   : August 2026
    Last Update     : August 2026
#>
####################################################################################################
function Show-ModalDialog {
    [CmdletBinding()]
    [OutputType([System.Windows.Forms.DialogResult])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The configured form to display as a modal dialog.')]
        [System.Windows.Forms.Form]$Dialog,

        [Parameter(Mandatory=$false,HelpMessage='Optional window that will own the modal dialog.')]
        [AllowNull()]
        [System.Windows.Forms.IWin32Window]$Owner
    )

    # EXECUTION - SHOW THE OWNED MODAL DIALOG
    # Display the modal dialog with the supplied owner window
    if ($null -ne $Owner) {
        return $Dialog.ShowDialog($Owner)
    }

    # EXECUTION - SHOW THE UNOWNED MODAL DIALOG
    # Display the modal dialog without an owner window
    return $Dialog.ShowDialog()
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    This function creates the main form of the application.
.DESCRIPTION
    This function creates the main form of the application. It sets the properties of the form, including size, position, and window buttons.
.EXAMPLE
    Initialize-MainForm
    Creates the main form of the application and sets its properties, but does not show it.
.INPUTS
    [PSCustomObject]
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.2.0
    Author          : Imraan Iotana
    Creation Date   : May 2026
    Last Update     : May 2026
#>
####################################################################################################
function Initialize-MainForm {
    [CmdletBinding()]
    [OutputType([System.Void])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The ApplicationObject containing the settings.')]
        [PSCustomObject]$InputObject
    )

    try {
        # PREPARATION
        # Create a new Form Object
        [System.Windows.Forms.Form]$NewForm     = New-Object System.Windows.Forms.Form
        # Get the graphical settings from the main object
        [System.Collections.Hashtable]$Settings = $InputObject.GraphicalSettings
        # Set the form title
        [System.String]$FormTitle               = "$($InputObject.Name) - Version $($InputObject.Version)"
        # Set the form size based
        [System.Drawing.Size]$FormSize          = New-Object System.Drawing.Size($Settings.MainForm.Width, $Settings.MainForm.Height)
        # Set the properties of the new Form
        [System.Collections.Hashtable]$FormProperties = @{
            Text            = $FormTitle
            Size            = $FormSize
            StartPosition   = 'CenterScreen'
            MinimizeBox     = $true
            MaximizeBox     = $false
            FormBorderStyle = 'FixedSingle'
            Icon            = $Settings.MainIcon
        }

        # EXECUTION - APPLY THE PROPERTIES TO THE NEW FORM OBJECT
        # Apply the properties to the new Form Object
        $FormProperties.GetEnumerator() | ForEach-Object { $NewForm.$($_.Key) = $_.Value }
        # Create the Global Main Form variable and assign the new Form to it
        [System.Windows.Forms.Form]$Global:MainForm = $NewForm
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
    This function shows the main form of the application.
.DESCRIPTION
    This function shows the main form of the application. It displays the form that was created and configured by the Initialize-MainForm function.
.EXAMPLE
    Show-MainForm
    Displays the main form of the application.
.INPUTS
    None.
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.0
    Author          : Imraan Iotana
    Creation Date   : April 2026
    Last Update     : May 2026
#>
####################################################################################################
function Show-MainForm {
    [CmdletBinding()]
    [OutputType([System.Void])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The ApplicationObject containing the settings.')]
        [PSCustomObject]$InputObject,

        [Parameter(Mandatory=$false,HelpMessage='The main form of the application.')]
        [System.Windows.Forms.Form]$FormToShow = $Global:MainForm
    )

    try {
        # PREPARATION
        # Stop the load timer and report elapsed time
        Stop-LoadTimer -InputObject $InputObject
        # Write the welcome message
        Write-WelcomeMessage -InputObject $InputObject

        # EXECUTION - SHOW THE MAIN FORM
        # Show the main form
        $null = $FormToShow.ShowDialog()
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
    This function moves the PowerShell host window to the top-left corner of the screen.
.DESCRIPTION
    This function locates the current PowerShell host window handle and repositions that window to screen coordinates (0,0) without changing its size.
.EXAMPLE
    Move-WindowToTopLeft
    Moves the current PowerShell host window to the top-left corner of the primary display.
.INPUTS
    None.
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.1
    Author          : Imraan Iotana
    Creation Date   : July 2026
    Last Update     : July 2026
#>
####################################################################################################
function Move-WindowToTopLeft {

    try {
        # Console-first fallback for classic Windows PowerShell hosts
        try {
            [System.Management.Automation.Host.Coordinates]$TopLeft = New-Object System.Management.Automation.Host.Coordinates(0,0)
            $Host.UI.RawUI.WindowPosition = $TopLeft
        }
        catch {
        }

        # Add native methods once per session for moving the host window
        # This avoids recompiling the same C# interop type on repeated starts
        if (-not ('ADA.Win32Window' -as [System.Type])) {
            Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

namespace ADA {
    [StructLayout(LayoutKind.Sequential)]
    public struct RECT {
        public int Left;
        public int Top;
        public int Right;
        public int Bottom;
    }

    public static class Win32Window {
        [DllImport("kernel32.dll")]
        public static extern IntPtr GetConsoleWindow();

        [DllImport("user32.dll")]
        public static extern IntPtr GetForegroundWindow();

        [DllImport("user32.dll")]
        public static extern bool IsWindow(IntPtr hWnd);

        [DllImport("user32.dll")]
        public static extern bool IsWindowVisible(IntPtr hWnd);

        [DllImport("user32.dll")]
        public static extern IntPtr GetAncestor(IntPtr hWnd, uint gaFlags);

        [DllImport("user32.dll")]
        public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);

        [DllImport("user32.dll", SetLastError = true)]
        public static extern bool SetWindowPos(
            IntPtr hWnd,
            IntPtr hWndInsertAfter,
            int X,
            int Y,
            int cx,
            int cy,
            uint uFlags
        );

        [DllImport("user32.dll", SetLastError = true)]
        public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);

        [DllImport("user32.dll", SetLastError = true)]
        public static extern bool MoveWindow(IntPtr hWnd, int X, int Y, int nWidth, int nHeight, bool bRepaint);
    }
}
"@ -Language CSharp
        }

        # Build candidate handles in priority order
        [System.Collections.Generic.List[System.IntPtr]]$CandidateHandles = New-Object 'System.Collections.Generic.List[System.IntPtr]'
        [System.UInt32]$GA_ROOT = 2
        [System.Int32]$SW_RESTORE = 9
        [System.UInt32]$SWP_NOSIZE = 0x0001
        [System.UInt32]$SWP_NOZORDER = 0x0004
        [System.UInt32]$Flags = $SWP_NOSIZE -bor $SWP_NOZORDER

        # Candidate 0: foreground top-level window (usually the visible terminal host)
        [System.IntPtr]$ForegroundHandle = [ADA.Win32Window]::GetForegroundWindow()
        if ($ForegroundHandle -ne [System.IntPtr]::Zero) {
            $CandidateHandles.Add($ForegroundHandle)
        }

        # Candidate 1: current PowerShell process main window
        [System.Diagnostics.Process]$CurrentProcess = Get-Process -Id $PID -ErrorAction SilentlyContinue
        if ($null -ne $CurrentProcess -and $CurrentProcess.MainWindowHandle -ne [System.IntPtr]::Zero) {
            $CandidateHandles.Add($CurrentProcess.MainWindowHandle)
        }

        # Candidate 2: console window handle
        [System.IntPtr]$ConsoleHandle = [ADA.Win32Window]::GetConsoleWindow()
        if ($ConsoleHandle -ne [System.IntPtr]::Zero) {
            $CandidateHandles.Add($ConsoleHandle)
        }

        # Reduce candidates to distinct top-level windows while preserving insertion order
        [System.Collections.Generic.List[System.IntPtr]]$UniqueHandles = New-Object 'System.Collections.Generic.List[System.IntPtr]'
        [System.Collections.Generic.HashSet[System.IntPtr]]$SeenHandles = New-Object 'System.Collections.Generic.HashSet[System.IntPtr]'

        foreach ($CandidateHandle in $CandidateHandles) {
            if ($CandidateHandle -eq [System.IntPtr]::Zero) {
                continue
            }

            if (-not [ADA.Win32Window]::IsWindow($CandidateHandle)) {
                continue
            }

            # Normalize child/owned handles to their root top-level window
            [System.IntPtr]$RootHandle = [ADA.Win32Window]::GetAncestor($CandidateHandle, $GA_ROOT)
            if ($RootHandle -eq [System.IntPtr]::Zero) {
                $RootHandle = $CandidateHandle
            }

            if ($SeenHandles.Add($RootHandle)) {
                $UniqueHandles.Add($RootHandle)
            }
        }

        # Fast path: keep retries short so startup is not blocked
        for ([System.Int32]$Attempt = 1; $Attempt -le 3; $Attempt++) {
            foreach ($WindowHandle in $UniqueHandles) {
                if (-not [ADA.Win32Window]::IsWindowVisible($WindowHandle)) {
                    continue
                }

                # Ensure window is restored before moving
                $null = [ADA.Win32Window]::ShowWindowAsync($WindowHandle, $SW_RESTORE)

                [System.Boolean]$Moved = [ADA.Win32Window]::SetWindowPos(
                    $WindowHandle,
                    [System.IntPtr]::Zero,
                    0,
                    0,
                    0,
                    0,
                    $Flags
                )

                if ($Moved) {
                    # Exit immediately on first successful reposition
                    return
                }
            }

            # Small delay gives late-initializing host windows time to appear
            [System.Threading.Thread]::Sleep(75)
        }

        # Slow fallback: parent process chain can help hosted shells, but CIM is expensive
        # Run this only if the fast path did not succeed
        [System.Int32]$ParentProcessId = 0
        try {
            $ParentProcessId = [System.Int32](Get-CimInstance -ClassName Win32_Process -Filter "ProcessId = $PID" -ErrorAction Stop).ParentProcessId
        }
        catch {
            $ParentProcessId = 0
        }

        for ([System.Int32]$Index = 0; $Index -lt 3 -and $ParentProcessId -gt 0; $Index++) {
            [System.Diagnostics.Process]$ParentProcess = Get-Process -Id $ParentProcessId -ErrorAction SilentlyContinue
            if ($null -ne $ParentProcess -and $ParentProcess.MainWindowHandle -ne [System.IntPtr]::Zero) {
                [System.IntPtr]$ParentRootHandle = [ADA.Win32Window]::GetAncestor($ParentProcess.MainWindowHandle, $GA_ROOT)
                if ($ParentRootHandle -eq [System.IntPtr]::Zero) {
                    $ParentRootHandle = $ParentProcess.MainWindowHandle
                }

                if ($SeenHandles.Add($ParentRootHandle)) {
                    $UniqueHandles.Add($ParentRootHandle)
                }
            }

            try {
                $ParentProcessId = [System.Int32](Get-CimInstance -ClassName Win32_Process -Filter "ProcessId = $ParentProcessId" -ErrorAction Stop).ParentProcessId
            }
            catch {
                break
            }
        }

        # Fallback retries include MoveWindow for hosts that reject SetWindowPos
        for ([System.Int32]$Attempt = 1; $Attempt -le 4; $Attempt++) {
            foreach ($WindowHandle in $UniqueHandles) {
                if (-not [ADA.Win32Window]::IsWindowVisible($WindowHandle)) {
                    continue
                }

                $null = [ADA.Win32Window]::ShowWindowAsync($WindowHandle, $SW_RESTORE)

                [System.Boolean]$Moved = [ADA.Win32Window]::SetWindowPos(
                    $WindowHandle,
                    [System.IntPtr]::Zero,
                    0,
                    0,
                    0,
                    0,
                    $Flags
                )

                if ($Moved) {
                    return
                }

                [ADA.RECT]$WindowRectangle = New-Object ADA.RECT
                [System.Boolean]$RectangleAvailable = [ADA.Win32Window]::GetWindowRect($WindowHandle, [ref]$WindowRectangle)
                if ($RectangleAvailable) {
                    [System.Int32]$Width = $WindowRectangle.Right - $WindowRectangle.Left
                    [System.Int32]$Height = $WindowRectangle.Bottom - $WindowRectangle.Top
                    [System.Boolean]$MoveWindowResult = [ADA.Win32Window]::MoveWindow($WindowHandle, 0, 0, $Width, $Height, $true)
                    if ($MoveWindowResult) {
                        return
                    }
                }
            }

            [System.Threading.Thread]::Sleep(100)
        }
    }
    catch {
        # Do not block startup when host window move is unavailable
        return
    }
}

### END OF FUNCTION
####################################################################################################
