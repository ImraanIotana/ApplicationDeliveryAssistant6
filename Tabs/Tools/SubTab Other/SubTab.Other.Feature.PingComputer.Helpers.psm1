####################################################################################################
<#
.SYNOPSIS
    Returns the Test-NetConnection core script used by Ping feature job handlers.
.DESCRIPTION
    This helper returns a script string that can be recreated as a ScriptBlock inside background jobs.
    It encapsulates shared Test-NetConnection behavior for both ICMP and optional TCP port tests.
.EXAMPLE
    [System.String]$CoreScript = Get-PingFeatureTestNetConnectionCoreScript
.INPUTS
    No inputs are accepted.
.OUTPUTS
    [System.String]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.6
    Author          : Imraan Iotana
    Creation Date   : August 2026
    Last Update     : August 2026
#>
####################################################################################################
function Get-PingFeatureTestNetConnectionCoreScript {
    [CmdletBinding()]
    [OutputType([System.String])]
    param ()

@'
param (
    [System.String]$TargetComputerName,
    [System.String]$TargetPort
)

$ProgressPreference = 'SilentlyContinue'
$InformationPreference = 'SilentlyContinue'
$VerbosePreference = 'SilentlyContinue'
$WarningPreference = 'SilentlyContinue'

if ([System.String]::IsNullOrWhiteSpace($TargetPort)) {
    # Use Test-Connection -Quiet to avoid host progress panel artifacts from Test-NetConnection.
    [System.Boolean]$PingSucceeded = [System.Boolean](Test-Connection -ComputerName $TargetComputerName -Count 1 -Quiet -ErrorAction SilentlyContinue)
    [PSCustomObject]@{
        ComputerName = $TargetComputerName
        Port         = $null
        Reachable    = $PingSucceeded
        Status       = if ($PingSucceeded) { 'Reachable' } else { 'Not reachable' }
        Mode         = 'ICMP'
    }
}
else {
    [System.Int32]$ParsedPort = [System.Int32]$TargetPort

    # Use TcpClient to avoid Test-NetConnection progress stream in console hosts.
    [System.Boolean]$TcpSucceeded = $false
    [System.Net.Sockets.TcpClient]$TcpClient = New-Object System.Net.Sockets.TcpClient
    try {
        [System.Threading.Tasks.Task]$ConnectTask = $TcpClient.ConnectAsync($TargetComputerName, $ParsedPort)
        if ($ConnectTask.Wait(5000) -and $TcpClient.Connected) {
            $TcpSucceeded = $true
        }
    }
    catch {
        $TcpSucceeded = $false
    }
    finally {
        if ($null -ne $TcpClient) {
            $TcpClient.Close()
            $TcpClient.Dispose()
        }
    }

    [PSCustomObject]@{
        ComputerName = $TargetComputerName
        Port         = $ParsedPort
        Reachable    = $TcpSucceeded
        Status       = if ($TcpSucceeded) { 'Reachable' } else { 'Not reachable' }
        Mode         = 'TCP'
    }
}
'@
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Validates that a computer name input is populated.
.DESCRIPTION
    This helper checks whether a computer name or IP address value is populated.
    If the value is empty, a warning is written and the function returns false.
.EXAMPLE
    Test-PingFeatureComputerNameInput -ComputerName 'localhost'
.INPUTS
    [System.String]
.OUTPUTS
    [System.Boolean]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.6
    Author          : Imraan Iotana
    Creation Date   : August 2026
    Last Update     : August 2026
#>
####################################################################################################
function Test-PingFeatureComputerNameInput {
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param (
        [Parameter(Mandatory=$false)]
        [AllowNull()][AllowEmptyString()]
        [System.String]$ComputerName
    )

    if (-not (Test-String -IsPopulated $ComputerName)) {
        Write-Line 'The computer name is empty. Please provide a valid computer name or IP address.' -Type Warning
        return $false
    }

    return $true
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Validates the optional TCP port input used by Test-NetConnection.
.DESCRIPTION
    This helper accepts empty values as valid and validates populated values as numeric ports in the range 1-65535.
    If the value is invalid, a warning is written and the function returns false.
.EXAMPLE
    Test-PingFeaturePortInput -Port '443'
.EXAMPLE
    Test-PingFeaturePortInput -Port ''
.INPUTS
    [System.String]
.OUTPUTS
    [System.Boolean]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.6
    Author          : Imraan Iotana
    Creation Date   : August 2026
    Last Update     : August 2026
#>
####################################################################################################
function Test-PingFeaturePortInput {
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param (
        [Parameter(Mandatory=$false)]
        [AllowNull()][AllowEmptyString()]
        [System.String]$Port
    )

    if (-not (Test-String -IsPopulated $Port)) {
        return $true
    }

    [System.Int32]$ParsedPortForValidation = 0
    if ((-not [System.Int32]::TryParse($Port, [ref]$ParsedPortForValidation)) -or ($ParsedPortForValidation -lt 1) -or ($ParsedPortForValidation -gt 65535)) {
        Write-Line "The optional port value [$Port] is invalid. Please provide a number between 1 and 65535." -Type Warning
        return $false
    }

    return $true
}

### END OF FUNCTION
####################################################################################################
