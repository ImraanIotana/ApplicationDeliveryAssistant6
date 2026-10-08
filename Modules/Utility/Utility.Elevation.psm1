####################################################################################################
<#
.SYNOPSIS
    Runs PowerShell scripts in an elevated Windows PowerShell process.
.DESCRIPTION
    Provides the shared elevation mechanism for operations that require administrator rights.
    The supplied script is encoded, started with the Windows UAC runas verb, and waited on until
    completion. Operation-specific result handling remains with the caller.
.EXAMPLE
    Invoke-ElevatedPowerShell -Script $ElevatedScript -StartFailureMessage 'The operation could not be started.'
.INPUTS
    [System.String]
.OUTPUTS
    [System.Int32]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.4.0
    Author          : Imraan Iotana
    Creation Date   : August 2026
    Last Update     : August 2026
#>
####################################################################################################
function Invoke-ElevatedPowerShell {
    [CmdletBinding()]
    [OutputType([System.Int32])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The Windows PowerShell script to run with administrator rights.')]
        [System.String]$Script,

        [Parameter(Mandatory=$true,HelpMessage='The error message used when the elevated process cannot be started.')]
        [System.String]$StartFailureMessage,

        [Parameter(Mandatory=$false,HelpMessage='The message written to the host once the administrator approval prompt has been accepted.')]
        [System.String]$PostApprovalMessage
    )

    # PREPARATION - ELEVATED PROCESS
    [System.String]$PowerShellPath = Join-Path -Path $env:WINDIR -ChildPath 'System32\WindowsPowerShell\v1.0\powershell.exe'
    [System.String]$EncodedScript = [System.Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($Script))
    [System.Diagnostics.ProcessStartInfo]$ProcessStartInfo = New-Object System.Diagnostics.ProcessStartInfo
    $ProcessStartInfo.FileName = $PowerShellPath
    $ProcessStartInfo.Arguments = '-NoProfile -NonInteractive -EncodedCommand ' + $EncodedScript
    $ProcessStartInfo.UseShellExecute = $true
    $ProcessStartInfo.Verb = 'runas'
    $ProcessStartInfo.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden

    # EXECUTION - ELEVATED PROCESS
    # Process.Start() only returns once the UAC prompt has been accepted and the process has launched
    [System.Diagnostics.Process]$ElevatedProcess = [System.Diagnostics.Process]::Start($ProcessStartInfo)
    if ($null -eq $ElevatedProcess) {
        throw $StartFailureMessage
    }
    if (-not [System.String]::IsNullOrWhiteSpace($PostApprovalMessage)) {
        Write-Line $PostApprovalMessage -Type Busy
    }
    try {
        $ElevatedProcess.WaitForExit()
        return [System.Int32]$ElevatedProcess.ExitCode
    }
    finally {
        $ElevatedProcess.Dispose()
    }
}


### END OF FUNCTION
####################################################################################################
