####################################################################################################
<#
.SYNOPSIS
    Imports the Ping Computer feature into the Connections sub-tab.
.DESCRIPTION
    This function imports the Ping Computer feature into the Connections sub-tab by creating a new GroupBox and adding it to the specified parent TabPage.
.EXAMPLE
    Import-FeaturePingComputer -InputObject $MyApplicationObject -ParentTabPage $MyTabPage
.INPUTS
    [PSCustomObject]
    [System.Windows.Forms.TabPage]
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. All rights reserved.
    Version         : 6.0.0.0
    Author          : Imraan Iotana
    Creation Date   : May 2026
    Last Update     : June 2026
#>
####################################################################################################
function Import-FeaturePingComputer {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The ApplicationObject containing the Settings.')]
        [PSCustomObject]$InputObject,

        [Parameter(Mandatory=$true,HelpMessage='The Parent TabPage to which this Feature will be added.')]
        [System.Windows.Forms.TabPage]$ParentTabPage,

        [Parameter(Mandatory=$false,HelpMessage='The GroupBox above which this Feature will be added.')]
        [System.Windows.Forms.GroupBox]$GroupBoxAbove
    )

    try {
        # PREPARATION - FEATURE PROPERTIES
        # Feature properties
        [System.Collections.Hashtable]$FeatureProperties = @{
            InputObject     = $InputObject
            ParentTabPage   = $ParentTabPage
            Title           = 'PING COMPUTERS'
            Color           = 'Cyan'
            NumberOfRows    = 3
        }
        # If the GroupBoxAbove parameter is provided, set the GroupBoxAbove property
        if ($PSBoundParameters.ContainsKey('GroupBoxAbove')) { $FeatureProperties.GroupBoxAbove = $GroupBoxAbove }

        # PREPARATION - TEXTBOXES
        # Set the TextBox properties
        [System.Collections.Hashtable]$TextBoxProperties = @{
            RowNumber       = 1
            Label           = 'ComputerName / IP address'
            PropertyName    = 'TextBoxes.Connections.ComputerName'
            ToolTip         = 'The name or IP address of the computer to ping'
            SizeType        = 'Medium'
            SmallButtons    = @(@(5,'Copy'),(6,'Paste'))
        }

        # PREPARATION - BUTTONS
        # Set the Button properties
        [System.Collections.Hashtable[]]$ButtonPropertiesArray1 = @(
            @{
                ColumnNumber    = 1
                Text            = 'Ping'
                PNGFileName     = 'network_ip'
                SizeType        = 'Large'
                Function        = {
                    [System.String]$ComputerName = Get-UserSetting -PropertyName 'TextBoxes.Connections.ComputerName'
                    if (Test-String -IsPopulated $ComputerName) { PING.EXE -n 1 $ComputerName | Out-Host }
                }
            }
            @{
                ColumnNumber    = 2
                Text            = 'Test-Connection'
                PNGFileName     = 'ip'
                SizeType        = 'Large'
                Function        = {
                    [System.String]$ComputerName = Get-UserSetting -PropertyName 'TextBoxes.Connections.ComputerName'
                    if (Test-String -IsPopulated $ComputerName) { 
                        try {
                            Test-Connection -ComputerName $ComputerName -Count 1 -ErrorAction Stop | Format-Table -AutoSize | Out-Host
                        }
                        catch {
                            Write-Line "The Test-Connection command failed or timed out for ($ComputerName)." -Type Error
                            Write-ErrorReport -ErrorRecord $_
                        }
                    }
                }
            }
            @{
                ColumnNumber    = 3
                Text            = 'Test-NetConnection'
                PNGFileName     = 'ip_class'
                SizeType        = 'Large'
                Function        = {
                    [System.String]$ComputerName = Get-UserSetting -PropertyName 'TextBoxes.Connections.ComputerName'
                    if (Test-String -IsPopulated $ComputerName) {
                        try {
                            Invoke-TestNetConnectionWithTimeout -ComputerName $ComputerName -TimeoutSeconds 10 | Out-Host
                        }
                        catch {
                            Write-Line "The Test-NetConnection command failed or timed out for ($ComputerName)." -Type Error
                            Write-ErrorReport -ErrorRecord $_
                        }
                    }
                }
            }
            @{
                ColumnNumber    = 4
                Text            = 'IP Report'
                PNGFileName     = 'report_go'
                SizeType        = 'Large'
                Function        = {
                    [System.String]$ComputerName = Get-UserSetting -PropertyName 'TextBoxes.Connections.ComputerName'
                    [System.String]$OutputFolder = Get-OutputFolder
                    Start-ComputerIPReportAsync -ComputerNames @($ComputerName) -OutputFolder $OutputFolder
                }.GetNewClosure()
            }
        )


        # EXECUTION
        # Create the GroupBox
        [System.Windows.Forms.GroupBox]$FeatureGroupBox = New-GroupBox @FeatureProperties -OnSubTab
        # Create the hashtables for the TextBoxes in the Global Graphics object if they do not already exist
        if (-not $Global:Graphics.TextBoxes.ContainsKey('Connections')) { $Global:Graphics.TextBoxes.Connections = @{} }
        # Create the TextBoxes
        $Global:Graphics.TextBoxes.Connections.ComputerName = New-TextBox @TextBoxProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ReturnTextBox
        # Add the Buttons
        New-ButtonLine -InputObject $InputObject -ButtonPropertiesArray $ButtonPropertiesArray1 -ParentGroupBox $FeatureGroupBox -RowNumber 2
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
    Runs Test-NetConnection with a hard timeout.
.DESCRIPTION
    This helper prevents long waits when ICMP is blocked or a target is not responding. It wraps Test-NetConnection in a background job and kills it after the specified timeout.
.EXAMPLE
    Invoke-TestNetConnectionWithTimeout -ComputerName 'ServerName.domain.com' -TimeoutSeconds 10
.INPUTS
    [System.String]
    [System.Int32]
.OUTPUTS
    [System.String]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. All rights reserved.
    Version         : 6.0.0.0
    Author          : Imraan Iotana
    Creation Date   : May 2026
    Last Update     : May 2026
#>
####################################################################################################
function Invoke-TestNetConnectionWithTimeout {
    [CmdletBinding()]
    [OutputType([System.String])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The name or IP address of the computer to test.')]
        [System.String]$ComputerName,

        [Parameter(Mandatory=$false,HelpMessage='The maximum number of seconds to wait before timing out.')]
        [System.Int32]$TimeoutSeconds = 10
    )

    [System.Management.Automation.Job]$Job = $null
    [System.DateTime]$StartTime = Get-Date
    try {
        Write-Line "Starting [Test-NetConnection] for ($ComputerName) with timeout [$TimeoutSeconds] second(s)..."

        # EXECUTION - START BACKGROUND JOB
        # Start the Test-NetConnection command in a background job to allow timeout control
        $Job = Start-Job -ArgumentList $ComputerName -ScriptBlock {
            param([System.String]$TargetComputerName)

            # Suppress progress and informational chatter from Test-NetConnection.
            $ProgressPreference = 'SilentlyContinue'
            $InformationPreference = 'SilentlyContinue'
            $VerbosePreference = 'SilentlyContinue'
            $WarningPreference = 'SilentlyContinue'

            Test-NetConnection -ComputerName $TargetComputerName -InformationLevel Quiet -ErrorAction Stop
        }

        # EXECUTION - WAIT FOR JOB
        # Wait for the job to complete within the specified timeout; stop it if it exceeds the limit
        if (-not (Wait-Job -Job $Job -Timeout $TimeoutSeconds)) {
            Stop-Job -Job $Job -Force -ErrorAction SilentlyContinue
            Write-Line "[Test-NetConnection] timed out for ($ComputerName) after [$TimeoutSeconds] second(s)." -Type Error
            throw "The Test-NetConnection command timed out after $TimeoutSeconds seconds."
        }

        # POST-EXECUTION - RETURN RESULTS
        # Receive and return the job output as a detailed string
        [System.Boolean]$PingSucceeded = [System.Boolean](Receive-Job -Job $Job -ErrorAction Stop)
        [System.Double]$DurationSeconds = [System.Math]::Round(((Get-Date) - $StartTime).TotalSeconds, 2)

        Write-Line "Completed [Test-NetConnection] for ($ComputerName). Reachable = [$PingSucceeded]. Duration = [$DurationSeconds] second(s)."

        @(
            "ComputerName : $ComputerName"
            "Reachable    : $PingSucceeded"
            "DurationSec  : $DurationSeconds"
        ) -join [System.Environment]::NewLine
    }
    catch {
        Write-Line "[Test-NetConnection] failed for ($ComputerName)." -Type Error
        Write-ErrorReport -ErrorRecord $_
    }
    finally {
        # CLEANUP - REMOVE JOB
        # Always remove the job to free up resources, regardless of success or failure
        if ($null -ne $Job) {
            Remove-Job -Job $Job -Force -ErrorAction SilentlyContinue
        }
    }
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Starts IP report generation asynchronously in a background PowerShell job.
.DESCRIPTION
    This function queues report generation in a background job so the UI thread remains responsive.
.EXAMPLE
    Start-ComputerIPReportAsync -ComputerNames @('localhost') -OutputFolder 'C:\Demo\IPReports'
#>
####################################################################################################
function Start-ComputerIPReportAsync {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false,HelpMessage='The computer names to ping.')]
        [AllowEmptyCollection()]
        [System.String[]]$ComputerNames,

        [Parameter(Mandatory=$false,HelpMessage='The output folder where the results will be saved.')]
        [System.String]$OutputFolder = (Get-UserSetting -PropertyName 'SubTab.FolderSettings.UserFolders.MyOutputFolder')
    )

    try {
        # VALIDATION
        if (($null -eq $ComputerNames) -or ($ComputerNames.Count -eq 0)) {
            Write-Line "The array of computer names is null or empty. Please provide at least one computer name to ping." -Type Error ; return
        }
        foreach ($ComputerName in $ComputerNames) {
            if ([System.String]::IsNullOrWhiteSpace($ComputerName)) {
                Write-Line "The computer name is null, empty, or consists only of whitespace. No action has been taken." -Type Error ; return
            }
        }

        [System.Management.Automation.Job]$Job = Start-Job -Name "ADA-IPReport-$(Get-Date -Format 'yyyyMMddHHmmss')" -ArgumentList (,$ComputerNames), $OutputFolder -ScriptBlock {
            param (
                [System.String[]]$ComputerNames,
                [System.String]$OutputFolder
            )

            # PREPARATION - OUTPUT FOLDER
            # Create the output folder if it does not exist
            if (-not (Test-Path -Path $OutputFolder)) { New-Item -Path $OutputFolder -ItemType Directory | Out-Null }

            # EXECUTION - PING COMPUTERS AND GENERATE REPORTS
            # Ping the computers and generate the reports
            foreach ($ComputerName in $ComputerNames) {
                if ([System.String]::IsNullOrWhiteSpace($ComputerName)) { continue }

                # Replace invalid file name characters to avoid output file errors.
                [System.String]$SafeComputerName = [System.Text.RegularExpressions.Regex]::Replace($ComputerName, '[\\/:*?""<>|]', '_')
                [System.String]$OutputFile = Join-Path -Path $OutputFolder -ChildPath "IP-Report_$($SafeComputerName).txt"

                # If the output file already exists, remove it to ensure we start with a clean slate for this report.
                if (Test-Path -Path $OutputFile) { Remove-Item -Path $OutputFile -Force }

                # Try to ping the computer with [Test-NetConnection] and capture the results, handling any errors that may occur
                [System.String]$PingResultWithTestNetConnection = try {
                    Write-Line "Generating IP-Report for ($ComputerName) with [Test-NetConnection]..."
                    Invoke-TestNetConnectionWithTimeout -ComputerName $ComputerName -TimeoutSeconds 10
                }
                catch {
                    "The Test-NetConnection command failed. The Computer named ($ComputerName) could not be reached from this host ($env:COMPUTERNAME)."
                }

                # Try to ping the computer with [Test-Connection] and capture the results, handling any errors that may occur
                [System.String]$PingResultWithTestConnection = try {
                    Write-Line "Generating IP-Report for ($ComputerName) with [Test-Connection]..."
                    Test-Connection -ComputerName $ComputerName -Count 1 -ErrorAction Stop | Format-List | Out-String
                }
                catch {
                    "The Test-Connection command failed. The Computer named ($ComputerName) could not be reached from this host ($env:COMPUTERNAME)."
                }

                # Try to resolve the DNS name of the computer with [Resolve-DnsName] and capture the results, handling any errors that may occur
                [System.String]$PingResultWithResolveDnsName = try {
                    Write-Line "Generating IP-Report for ($ComputerName) with [Resolve-DnsName]..."
                    Resolve-DnsName -Name $ComputerName -QuickTimeout -ErrorAction Stop | Format-List | Out-String
                }
                catch {
                    "The Resolve-DnsName command failed. The Computer named ($ComputerName) could not be resolved from this host ($env:COMPUTERNAME)."
                }

                # Write the report to the output file
                @(
                    "----------------------------------------------------------------------"
                    "IP-Report for TARGET HOST: $ComputerName"
                    "Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
                    "Source host: $env:COMPUTERNAME"
                    "----------------------------------------------------------------------",""
                    "----------------------------------------------------------------------"
                    "RESULT OF [Test-NetConnection] for ($ComputerName):"
                    $PingResultWithTestNetConnection
                    "----------------------------------------------------------------------"
                    "RESULT OF [Test-Connection] for ($ComputerName):"
                    $PingResultWithTestConnection
                    "----------------------------------------------------------------------"
                    "RESULT OF [Resolve-DnsName] for ($ComputerName):"
                    $PingResultWithResolveDnsName
                    "----------------------------------------------------------------------"
                ) | Out-File -FilePath $OutputFile -Append
            }
        }

        Write-Line "Started IP-Report generation in background Job Id [$($Job.Id)] for target(s): $($ComputerNames -join ', ')."

        # POST-EXECUTION
        # Open the output folder
        Open-Folder -Path $OutputFolder
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
    This script generates an IP report for specified computer names.
.DESCRIPTION
    This script pings the specified computer names and resolves their DNS names, saving the results to an output file.
.EXAMPLE
    Get-ComputerIPReport -ComputerNames @('Computer1', 'Computer2') -OutputFolder 'C:\Demo\IPReports'
.INPUTS
    [System.String[]]
    [System.String]
.OUTPUTS
    No objects are returned to the pipeline. All output is written to the host and saved to files.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. All rights reserved.
    Version         : 6.0.0.0
    Author          : Imraan Iotana
    Creation Date   : May 2026
    Last Update     : May 2026
#>
####################################################################################################
function Get-ComputerIPReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false,HelpMessage='The computer names to ping.')]
        [AllowEmptyCollection()]
        [System.String[]]$ComputerNames,

        [Parameter(Mandatory=$false,HelpMessage='The output folder where the results will be saved.')]
        [System.String]$OutputFolder = (Get-UserSetting -PropertyName 'SubTab.FolderSettings.UserFolders.MyOutputFolder')
    )

    try {
        # VALIDATION
        # Validate the array of computer names
        if (($null -eq $ComputerNames) -or ($ComputerNames.Count -eq 0)) {
            Write-Line "The array of computer names is null or empty. Please provide at least one computer name to ping." -Type Error ; return
        }
        # Validate the computer names
        foreach ($ComputerName in $ComputerNames) {
            if ([System.String]::IsNullOrWhiteSpace($ComputerName)) {
                Write-Line "The computer name is null, empty, or consists only of whitespace. No action has been taken." -Type Error ; return
            }
        }

        # PREPARATION - OUTPUT FOLDER
        # Create the output folder if it does not exist
        if (Test-Path -Path $OutputFolder) {
            Write-Line "Output folder already exists: $OutputFolder" 
        } else {
            Write-Line "Creating output folder: $OutputFolder" ; New-Item -Path $OutputFolder -ItemType Directory | Out-Null
        }

        # EXECUTION - PING COMPUTERS AND GENERATE REPORTS
        # Ping the computers
        foreach ($ComputerName in $ComputerNames) {

            # PREPARATION - OUTPUT FILE
            # Set the name of the outputfile
            [System.String]$OutputFile = Join-Path -Path $OutputFolder -ChildPath "IP-Report_$($ComputerName).txt"
            # Remove the output file if it already exists
            if (Test-Path -Path $OutputFile) { Write-Line "Removing existing output file: $OutputFile" ; Remove-Item -Path $OutputFile -Force }

            # EXECUTION - 1. PING COMPUTER WITH TEST-NETCONNECTION
            # Try to ping the computer and capture the result, handling any errors that may occur
            Write-Line "Generating IP-Report for ($ComputerName) with [Test-NetConnection]..."
            [System.String]$PingResultWithTestNetConnection = try {
                Invoke-TestNetConnectionWithTimeout -ComputerName $ComputerName -TimeoutSeconds 10
            }
            catch {
                # Write an error message to the console, and return it as the ping result
                [System.String]$ErrorMessage = "The Test-NetConnection command failed. The Computer named ($ComputerName) could not be reached from this host ($env:COMPUTERNAME)."
                Write-Line $ErrorMessage -Type Error
                $ErrorMessage
            }

            # EXECUTION - 2. PING COMPUTER WITH TEST-CONNECTION
            # Try to ping the computer and capture the result, handling any errors that may occur
            Write-Line "Generating IP-Report for ($ComputerName) with [Test-Connection]..."
            [System.String]$PingResultWithTestConnection = try {
                Test-Connection -ComputerName $ComputerName -Count 1 -ErrorAction Stop | Format-List | Out-String
            }
            catch {
                # Write an error message to the console, and return it as the ping result
                [System.String]$ErrorMessage = "The Test-Connection command failed. The Computer named ($ComputerName) could not be reached from this host ($env:COMPUTERNAME)."
                Write-Line $ErrorMessage -Type Error
                $ErrorMessage
            }

            # EXECUTION - 3. PING COMPUTER WITH RESOLVE-DNSNAME
            # Try to resolve the DNS name of the computer and capture the result, handling any errors that may occur
            Write-Line "Generating IP-Report for ($ComputerName) with [Resolve-DnsName]..."
            [System.String]$PingResultWithResolveDnsName = try {
                Resolve-DnsName -Name $ComputerName -QuickTimeout -ErrorAction Stop | Format-List | Out-String
            }
            catch {
                # Write an error message to the console, and return it as the ping result
                [System.String]$ErrorMessage = "The Resolve-DnsName command failed. The Computer named ($ComputerName) could not be resolved from this host ($env:COMPUTERNAME)."
                Write-Line $ErrorMessage -Type Error
                $ErrorMessage
            }

            # Write the report to the output file
            @(
                "----------------------------------------------------------------------"
                "IP-Report for TARGET HOST: $ComputerName"
                "Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
                "Source host: $env:COMPUTERNAME"
                "----------------------------------------------------------------------",""
                "----------------------------------------------------------------------"
                "RESULT OF [Test-NetConnection] for ($ComputerName):"
                $PingResultWithTestNetConnection
                "----------------------------------------------------------------------"
                "RESULT OF [Test-Connection] for ($ComputerName):"
                $PingResultWithTestConnection
                "----------------------------------------------------------------------"
                "RESULT OF [Resolve-DnsName] for ($ComputerName):"
                $PingResultWithResolveDnsName
                "----------------------------------------------------------------------"
            ) | Out-File -FilePath $OutputFile -Append
        }

        # POST-EXECUTION
        # Open the output folder
        Open-Folder -Path $OutputFolder
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }

}

### END OF FUNCTION
####################################################################################################
