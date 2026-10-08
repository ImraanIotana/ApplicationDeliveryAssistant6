####################################################################################################
<#
.SYNOPSIS
    Provides Certificate Manager launch helpers.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.1.0
    Author          : Imraan Iotana
    Creation Date   : August 2026
    Last Update     : August 2026
#>
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Gets the target bounds for a Certificate Manager window.
.DESCRIPTION
    Calculates a monitor-bounded 1100 by 750 pixel rectangle centered over ADA.
.EXAMPLE
    Get-CertificateManagerWindowBounds
.OUTPUTS
    [System.Drawing.Rectangle]
#>
####################################################################################################
function Get-CertificateManagerWindowBounds {
    [CmdletBinding()]
    [OutputType([System.Drawing.Rectangle])]
    param ()

    [System.Windows.Forms.Screen]$TargetScreen = [System.Windows.Forms.Screen]::PrimaryScreen
    [System.Drawing.Rectangle]$OwnerBounds = $TargetScreen.WorkingArea
    if ($null -ne $Global:MainForm) {
        $TargetScreen = [System.Windows.Forms.Screen]::FromControl($Global:MainForm)
        $OwnerBounds = $Global:MainForm.Bounds
    }

    [System.Drawing.Rectangle]$WorkingArea = $TargetScreen.WorkingArea
    [System.Int32]$WindowWidth = [System.Math]::Min(1100, $WorkingArea.Width)
    [System.Int32]$WindowHeight = [System.Math]::Min(750, $WorkingArea.Height)
    [System.Int32]$WindowLeft = $OwnerBounds.Left + [System.Int32](($OwnerBounds.Width - $WindowWidth) / 2)
    [System.Int32]$WindowTop = $OwnerBounds.Top + [System.Int32](($OwnerBounds.Height - $WindowHeight) / 2)
    $WindowLeft = [System.Math]::Max($WorkingArea.Left, [System.Math]::Min($WindowLeft, $WorkingArea.Right - $WindowWidth))
    $WindowTop = [System.Math]::Max($WorkingArea.Top, [System.Math]::Min($WindowTop, $WorkingArea.Bottom - $WindowHeight))

    New-Object System.Drawing.Rectangle($WindowLeft, $WindowTop, $WindowWidth, $WindowHeight)
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Sizes and centers a Certificate Manager window over ADA.
.DESCRIPTION
    Waits briefly for the MMC main window, then sizes it to 1100 by 750 pixels and centers it over
    ADA within the active monitor working area when window positioning is available.
.PARAMETER Process
    The MMC process hosting Certificate Manager.
.EXAMPLE
    Move-CertificateManagerWindow -Process $CertificateManagerProcess
.OUTPUTS
    No objects are returned to the pipeline.
#>
####################################################################################################
function Move-CertificateManagerWindow {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The MMC process hosting Certificate Manager.')]
        [System.Diagnostics.Process]$Process
    )

    if (-not ('ADA.Win32Window' -as [System.Type])) {
        return
    }

    [System.IntPtr]$CertificateManagerWindowHandle = [System.IntPtr]::Zero
    for ([System.Int32]$Attempt = 1; $Attempt -le 20; $Attempt++) {
        $Process.Refresh()
        $CertificateManagerWindowHandle = $Process.MainWindowHandle
        if ($CertificateManagerWindowHandle -ne [System.IntPtr]::Zero) {
            break
        }
        [System.Threading.Thread]::Sleep(50)
    }

    if ($CertificateManagerWindowHandle -eq [System.IntPtr]::Zero) {
        return
    }

    [System.Drawing.Rectangle]$WindowBounds = Get-CertificateManagerWindowBounds

    $null = [ADA.Win32Window]::MoveWindow(
        $CertificateManagerWindowHandle,
        $WindowBounds.Left,
        $WindowBounds.Top,
        $WindowBounds.Width,
        $WindowBounds.Height,
        $true
    )
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Opens Current User Certificate Manager without elevation.
.DESCRIPTION
    Starts the normal MMC certificate console with a process-scoped RunAsInvoker compatibility
    setting so MMC uses the application's existing user token instead of requesting its highest
    available token. The console is sized to 1100 by 750 pixels and centered over the application
    within the active monitor working area when window positioning is available.
.EXAMPLE
    Open-CurrentUserCertificateManager
.OUTPUTS
    No objects are returned to the pipeline.
#>
####################################################################################################
function Open-CurrentUserCertificateManager {
    [CmdletBinding()]
    param ()

    try {
        [System.String]$CertificateManagerPath = Join-Path -Path $env:WINDIR -ChildPath 'System32\certmgr.msc'
        [System.String]$MMCPath = Join-Path -Path $env:WINDIR -ChildPath 'System32\mmc.exe'

        [System.Diagnostics.ProcessStartInfo]$ProcessStartInfo = New-Object System.Diagnostics.ProcessStartInfo
        $ProcessStartInfo.FileName = $MMCPath
        $ProcessStartInfo.Arguments = '"' + $CertificateManagerPath + '"'
        $ProcessStartInfo.UseShellExecute = $false
        $ProcessStartInfo.EnvironmentVariables['__COMPAT_LAYER'] = 'RunAsInvoker'

        [System.Diagnostics.Process]$CertificateManagerProcess = [System.Diagnostics.Process]::Start($ProcessStartInfo)
        if ($null -eq $CertificateManagerProcess) {
            throw 'Windows Certificate Manager could not be started.'
        }

        Move-CertificateManagerWindow -Process $CertificateManagerProcess

        $CertificateManagerProcess.Dispose()
        Write-Line 'Opened Current User Certificate Manager without elevation.' -Type Success
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
    Opens Local Computer Certificate Manager with elevation.
.DESCRIPTION
    Requests elevation, starts the built-in Local Computer certificate console, and centers it over
    ADA within the active monitor working area when window positioning is available.
.EXAMPLE
    Open-LocalComputerCertificateManagerAsAdministrator
.OUTPUTS
    No objects are returned to the pipeline.
#>
####################################################################################################
function Open-LocalComputerCertificateManagerAsAdministrator {
    [CmdletBinding()]
    param ()

    try {
        [System.String]$LocalComputerCertificateManagerPath = Join-Path -Path $env:WINDIR -ChildPath 'System32\certlm.msc'
        [System.String]$MMCPath = Join-Path -Path $env:WINDIR -ChildPath 'System32\mmc.exe'
        [System.Drawing.Rectangle]$WindowBounds = Get-CertificateManagerWindowBounds

        [System.String]$EscapedMMCPath = $MMCPath.Replace("'", "''")
        [System.String]$EscapedCertificateManagerPath = $LocalComputerCertificateManagerPath.Replace("'", "''")
        [System.String]$ElevatedScript = @"
`$ErrorActionPreference = 'Stop'
try {
    `$CertificateManagerProcess = Start-Process -FilePath '$EscapedMMCPath' -ArgumentList '"$EscapedCertificateManagerPath"' -PassThru -ErrorAction Stop
    Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public static class ADACertificateManagerWindow {
    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool MoveWindow(IntPtr hWnd, int X, int Y, int Width, int Height, bool Repaint);
}
'@
    `$WindowHandle = [IntPtr]::Zero
    for (`$Attempt = 1; `$Attempt -le 100; `$Attempt++) {
        `$CertificateManagerProcess.Refresh()
        `$WindowHandle = `$CertificateManagerProcess.MainWindowHandle
        if (`$WindowHandle -ne [IntPtr]::Zero) {
            break
        }
        [Threading.Thread]::Sleep(50)
    }
    if (`$WindowHandle -eq [IntPtr]::Zero) {
        exit 2
    }
    if (-not [ADACertificateManagerWindow]::MoveWindow(`$WindowHandle, $($WindowBounds.Left), $($WindowBounds.Top), $($WindowBounds.Width), $($WindowBounds.Height), `$true)) {
        exit 3
    }
    exit 0
}
catch {
    exit 1
}
"@
        Write-Line 'Requesting administrator access for Local Computer Certificate Manager...' -Type Busy
        [System.Int32]$ElevatedLauncherExitCode = Invoke-ElevatedPowerShell -Script $ElevatedScript -StartFailureMessage 'Local Computer Certificate Manager could not be started.'
        if ($ElevatedLauncherExitCode -ne 0) {
            throw "Local Computer Certificate Manager window could not be positioned (exit code $ElevatedLauncherExitCode)."
        }

        Write-Line 'Opened Local Computer Certificate Manager with elevation.' -Type Success
    }
    catch [System.ComponentModel.Win32Exception] {
        if ($_.Exception.NativeErrorCode -eq 1223) {
            Write-Line 'Opening Local Computer Certificate Manager was canceled.' -Type Warning
            return
        }
        Write-ErrorReport -ErrorRecord $_
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}

### END OF FUNCTION
####################################################################################################