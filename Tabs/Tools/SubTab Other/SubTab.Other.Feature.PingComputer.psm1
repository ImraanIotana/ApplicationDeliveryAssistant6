####################################################################################################
<#
.SYNOPSIS
    Imports the Ping Computer feature into the Other sub-tab.
.DESCRIPTION
    This function imports the Ping Computer feature into the Other sub-tab by creating a new GroupBox and adding it to the specified parent TabPage.
.EXAMPLE
    Import-FeaturePingComputer -InputObject $MyApplicationObject -ParentTabPage $MyTabPage
.INPUTS
    [PSCustomObject]
    [System.Windows.Forms.TabPage]
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.6
    Author          : Imraan Iotana
    Creation Date   : May 2026
    Last Update     : August 2026
#>
####################################################################################################
function Import-FeaturePingComputer {
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
            Title           = 'PING COMPUTERS'
            Color           = $Color
            NumberOfRows    = 4
            GroupBoxAbove   = $GroupBoxAbove
        }

        # EXECUTION - GROUPBOX
        # Create the GroupBox
        [System.Windows.Forms.GroupBox]$FeatureGroupBox = New-GroupBox @GroupBoxProperties

        # PREPARATION - TEXTBOX PROPERTIES
        # Set the TextBox properties
        [System.Collections.Hashtable]$ComputerNameTextBoxProperties = @{
            RowNumber       = 1
            Label           = 'ComputerName / IP address'
            ToolTip         = 'The name or IP address of the computer to ping'
            SizeType        = 'Medium'
            SmallButtons    = @(@(5,'Copy'),@(6,'Paste'),@(7,'Clear'))
        }

        # EXECUTION - TEXTBOXES
        # Create the TextBox
        [System.Windows.Forms.TextBox]$ComputerNameTextBox = New-TextBox @ComputerNameTextBoxProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ReturnTextBox

        # PREPARATION - PORT TEXTBOX PROPERTIES
        # Set the optional Port TextBox properties for service-level connectivity tests
        [System.Collections.Hashtable]$PortTextBoxProperties = @{
            RowNumber       = 2
            Label           = 'Port (optional)'
            ToolTip         = 'Optional TCP port used by Test-NetConnection only (range: 1-65535).'
            SizeType        = 'Tiny'
            SmallButtons    = @(@(5,'Copy'),@(6,'Paste'),@(7,'Clear'))
        }

        # EXECUTION - PORT TEXTBOX
        # Create the Port TextBox
        [System.Windows.Forms.TextBox]$PortTextBox = New-TextBox @PortTextBoxProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ReturnTextBox

        # PREPARATION - BUTTON PROPERTIES
        # Set the Button properties
        [System.Collections.Hashtable[]]$ActionButtons = @(
            @{
                ColumnNumber    = 1
                Text            = 'Ping'
                PNGFileName     = 'network_ip'
                SizeType        = 'Large'
                Function        = { Write-PingResultToHost -ComputerName $ComputerNameTextBox.Text }.GetNewClosure()
            }
            @{
                ColumnNumber    = 2
                Text            = 'Test-Connection'
                PNGFileName     = 'ip'
                SizeType        = 'Large'
                Function        = { Write-TestConnectionResultToHost -ComputerName $ComputerNameTextBox.Text }.GetNewClosure()
            }
            @{
                ColumnNumber    = 3
                Text            = 'Test-NetConnection'
                PNGFileName     = 'ip_class'
                SizeType        = 'Large'
                Function        = { Write-TestNetConnectionResultToHost -ComputerName $ComputerNameTextBox.Text -Port $PortTextBox.Text }.GetNewClosure()
            }
            @{
                ColumnNumber    = 5
                Text            = 'Create IP Report'
                PNGFileName     = 'report_go'
                SizeType        = 'Large'
                Function        = { New-IPReport -ComputerNames @($ComputerNameTextBox.Text) -Port $PortTextBox.Text }.GetNewClosure()
            }
        )

        # EXECUTION - BUTTONS
        # Create the Buttons
        New-ButtonLine -InputObject $InputObject -ButtonPropertiesArray $ActionButtons -ParentGroupBox $FeatureGroupBox -RowNumber 3

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
    Writes the result of a ping test to the host.
.DESCRIPTION
    This helper runs the Windows ping command for a single target and streams the output to the host.
.EXAMPLE
    Write-PingResultToHost -ComputerName 'ServerName.domain.com'
.INPUTS
    [System.String]
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.6
    Author          : Imraan Iotana
    Creation Date   : July 2026
    Last Update     : August 2026
#>
####################################################################################################
function Write-PingResultToHost {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false,HelpMessage='The name or IP address of the computer to ping.')]
        [AllowNull()][AllowEmptyString()]
        [System.String]$ComputerName
    )

    try {
        # VALIDATION
        # Validate the computer name before attempting to ping it
        if (-not (Test-PingFeatureComputerNameInput -ComputerName $ComputerName)) { return }

        # USER FEEDBACK
        # Write a neutral start-status line with full action context
        Write-Line "[START] Ping | Target=[$ComputerName] | Mode=[ICMP] | Count=[1] | Tool=[PING.EXE]"

        # EXECUTION
        # Ping the target and write the result to the host
        PING.EXE -n 1 $ComputerName | Out-Host

        # POST-EXECUTION
        # Write a closing line to the host to indicate the end of the ping result
        Write-Line "[END] Ping | Target=[$ComputerName] | Result=[Success]"
    }
    catch {
        Write-Line "[FAIL] Ping | Target=[$ComputerName] | Reason=[Command failed or timed out]" -Type Error
        Write-ErrorReport -ErrorRecord $_
    }
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Writes the result of a Test-Connection call to the host.
.DESCRIPTION
    This helper runs Test-Connection for a single target and streams the formatted output to the host.
.EXAMPLE
    Write-TestConnectionResultToHost -ComputerName 'ServerName.domain.com'
.INPUTS
    [System.String]
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.6
    Author          : Imraan Iotana
    Creation Date   : July 2026
    Last Update     : August 2026
#>
####################################################################################################
function Write-TestConnectionResultToHost {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false,HelpMessage='The name or IP address of the computer to test.')]
        [AllowNull()][AllowEmptyString()]
        [System.String]$ComputerName
    )

    try {
        # VALIDATION
        # Validate the computer name before attempting to test it
        if (-not (Test-PingFeatureComputerNameInput -ComputerName $ComputerName)) { return }

        # USER FEEDBACK
        # Write a neutral start-status line with full action context
        Write-Line "[START] Test-Connection | Target=[$ComputerName] | Mode=[ICMP] | Count=[1]"

        # EXECUTION
        # Run Test-Connection and write the formatted result to the host
        Test-Connection -ComputerName $ComputerName -Count 1 -ErrorAction Stop | Format-Table -AutoSize | Out-Host
        
        # POST-EXECUTION
        # Write a closing line to the host to indicate the end of the Test-Connection result
        Write-Line "[END] Test-Connection | Target=[$ComputerName] | Result=[Success]"
    }
    catch {
        Write-Line "[FAIL] Test-Connection | Target=[$ComputerName] | Reason=[Command failed or timed out]" -Type Error
        Write-ErrorReport -ErrorRecord $_
    }
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Writes the result of a Test-NetConnection call to the host.
.DESCRIPTION
    This helper runs Test-NetConnection for a single target and streams the formatted output to the host.
.EXAMPLE
    Write-TestNetConnectionResultToHost -ComputerName 'ServerName.domain.com'
.EXAMPLE
    Write-TestNetConnectionResultToHost -ComputerName 'ServerName.domain.com' -Port '443'
.INPUTS
    [System.String]
    [System.String]
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.6
    Author          : Imraan Iotana
    Creation Date   : May 2026
    Last Update     : August 2026
#>
####################################################################################################
function Write-TestNetConnectionResultToHost {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false,HelpMessage='The name or IP address of the computer to test.')]
        [AllowNull()][AllowEmptyString()]
        [System.String]$ComputerName,

        [Parameter(Mandatory=$false,HelpMessage='Optional TCP port for service-level connectivity testing (range: 1-65535).')]
        [AllowNull()][AllowEmptyString()]
        [System.String]$Port
    )

    [System.Management.Automation.Job]$Job = $null
    [System.String]$OriginalProgressPreference = $ProgressPreference
    try {
        # PREPARATION
        # Resolve local timeout/core-script settings
        [System.Int32]$TimeoutSeconds = 10
        [System.String]$CoreScriptText = Get-PingFeatureTestNetConnectionCoreScript

        # PREPARATION - HOST PROGRESS SUPPRESSION
        # Some hosts keep Test-NetConnection progress panels visible; suppress progress in this caller scope.
        $ProgressPreference = 'SilentlyContinue'

        # VALIDATION
        # Validate the computer name before attempting to test it
        if (-not (Test-PingFeatureComputerNameInput -ComputerName $ComputerName)) { return }

        # Validate the optional Port input when provided
        if (-not (Test-PingFeaturePortInput -Port $Port)) { return }

        # USER FEEDBACK
        # Write a start line immediately so users know the check is in progress
        [System.String]$ModeText = if (Test-String -IsPopulated $Port) { 'TCP' } else { 'ICMP' }
        [System.String]$PortText = if (Test-String -IsPopulated $Port) { $Port } else { 'N/A (ICMP)' }
        Write-Line "[START] Test-NetConnection | Target=[$ComputerName] | Mode=[$ModeText] | Port=[$PortText]"

        # EXECUTION
        # Run Test-NetConnection in a background job so the UI cannot hang on slow ICMP responses
        $Job = Start-Job -ArgumentList $ComputerName, $Port, $CoreScriptText -ScriptBlock {
            param(
                [System.String]$TargetComputerName,
                [System.String]$TargetPort,
                [System.String]$CoreScriptText
            )

            [System.Management.Automation.ScriptBlock]$CoreScriptBlock = [System.Management.Automation.ScriptBlock]::Create($CoreScriptText)
            & $CoreScriptBlock -TargetComputerName $TargetComputerName -TargetPort $TargetPort
        }

        # EXECUTION - WAIT FOR COMPLETION
        # Wait for the background job and handle timeout explicitly
        if (-not (Wait-Job -Job $Job -Timeout $TimeoutSeconds)) {
            Stop-Job -Job $Job -ErrorAction SilentlyContinue
            Write-Line "[FAIL] Test-NetConnection | Target=[$ComputerName] | Reason=[Timeout after $TimeoutSeconds second(s)]" -Type Error
            return
        }

        # EXECUTION - READ RESULT
        # Read the resolved result object from the completed job
        [PSCustomObject]$ConnectionResult = [PSCustomObject](Receive-Job -Job $Job -ErrorAction Stop)

        # EXECUTION - WRITE RESULT
        # Write mode-specific output for TCP port tests or ICMP reachability tests
        if ($ConnectionResult.Mode -eq 'TCP') {
            @(
                "ComputerName : $($ConnectionResult.ComputerName)"
                "Port         : $($ConnectionResult.Port)"
                "Reachable    : $($ConnectionResult.Reachable)"
                "Status       : $($ConnectionResult.Status)"
                "Mode         : TCP"
            ) -join [System.Environment]::NewLine | Out-Host
            Write-Line "[END] Test-NetConnection | Target=[$ComputerName] | Mode=[TCP] | Port=[$($ConnectionResult.Port)] | Reachable=[$($ConnectionResult.Reachable)] | Result=[Success]"
        }
        else {
            @(
                "ComputerName : $($ConnectionResult.ComputerName)"
                "Reachable    : $($ConnectionResult.Reachable)"
                "Status       : $($ConnectionResult.Status)"
                "Mode         : ICMP"
            ) -join [System.Environment]::NewLine | Out-Host
            Write-Line "[END] Test-NetConnection | Target=[$ComputerName] | Mode=[ICMP] | Port=[N/A (ICMP)] | Reachable=[$($ConnectionResult.Reachable)] | Result=[Success]"
        }
    }
    catch {
        Write-Line "[FAIL] Test-NetConnection | Target=[$ComputerName] | Reason=[Command failed or timed out]" -Type Error
        Write-ErrorReport -ErrorRecord $_
    }
    finally {
        # CLEANUP
        # Remove the background job object if it was created
        if ($null -ne $Job) {
            Remove-Job -Job $Job -Force -ErrorAction SilentlyContinue
        }

        # CLEANUP - PROGRESS DISPLAY
        # Clear any lingering progress UI panel and restore the previous host preference.
        Write-Progress -Activity 'Test-NetConnection' -Completed
        $ProgressPreference = $OriginalProgressPreference
    }
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Creates IP reports asynchronously in a background PowerShell job.
.DESCRIPTION
    This function queues report generation in a background job so the UI thread remains responsive.
.EXAMPLE
    New-IPReport -ComputerNames @('localhost') -OutputFolder 'C:\Demo\IPReports'
.EXAMPLE
    New-IPReport -ComputerNames @('google.com') -Port '443' -OutputFolder 'C:\Demo\IPReports'
.INPUTS
    [System.String[]]
    [System.String]
    [System.String]
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.0.0.6
    Author          : Imraan Iotana
    Creation Date   : July 2026
    Last Update     : August 2026
#>
####################################################################################################
function New-IPReport {
    [CmdletBinding()]
    [OutputType([System.Void])]
    param (
        [Parameter(Mandatory=$false,HelpMessage='The computer names to ping.')]
        [AllowEmptyCollection()]
        [System.String[]]$ComputerNames,

        [Parameter(Mandatory=$false,HelpMessage='Optional TCP port used for Test-NetConnection results in the report.')]
        [AllowNull()][AllowEmptyString()]
        [System.String]$Port,

        [Parameter(Mandatory=$false,HelpMessage='The output folder where the results will be saved.')]
        [System.String]$OutputFolder = (Get-Folder -OutputFolder)
    )

    try {
        # PREPARATION
        # Resolve the shared Test-NetConnection core script for this report run
        [System.String]$CoreScriptText = Get-PingFeatureTestNetConnectionCoreScript

        # VALIDATION
        # Validate the output folder setting
        if (Test-String -IsEmpty $OutputFolder) {
            Write-Line 'The output folder is empty. Please configure a valid output folder first.' -Type Warning
            return
        }

        # Validate the array of computer names
        if (($null -eq $ComputerNames) -or ($ComputerNames.Count -eq 0)) {
            Write-Line "The array of computer names is null or empty. Please provide at least one computer name to ping." -Type Warning ; return
        }

        # Validate each computer name
        foreach ($ComputerName in $ComputerNames) {
            if (-not (Test-PingFeatureComputerNameInput -ComputerName $ComputerName)) { return }
        }

        # Validate the optional Port input when provided
        if (-not (Test-PingFeaturePortInput -Port $Port)) { return }

        # USER FEEDBACK
        # Write a neutral start-status line with full action context
        [System.String]$TargetsText = $ComputerNames -join ', '
        [System.String]$RequestedPortText = if (Test-String -IsPopulated $Port) { $Port } else { 'N/A (ICMP)' }
        Write-Line "[START] IP Report | Targets=[$TargetsText] | RequestedPort=[$RequestedPortText] | OutputFolder=[$OutputFolder]"

        # EXECUTION - START BACKGROUND JOB
        # Queue the report creation work so the UI thread remains responsive
        [System.Management.Automation.Job]$Job = Start-Job -Name "ADA-IPReport-$(Get-Date -Format 'yyyyMMddHHmmss')" -ArgumentList (,$ComputerNames), $Port, $OutputFolder, $CoreScriptText -ScriptBlock {
            param (
                [System.String[]]$ComputerNames,
                [System.String]$TargetPort,
                [System.String]$OutputFolder,
                [System.String]$CoreScriptText
            )

            # Host-writer helpers (Write-PingResultToHost / Write-TestConnectionResultToHost / Write-TestNetConnectionResultToHost)
            # are designed for UI-host output and are not directly reusable for report capture in this background runspace
            # PREPARATION - OUTPUT FOLDER
            # Create the output folder if it does not exist
            if (-not (Test-Path -LiteralPath $OutputFolder)) { New-Item -Path $OutputFolder -ItemType Directory | Out-Null }

            # PREPARATION - TEST-NETCONNECTION CORE
            # Create the shared script block once for all hosts in this report run
            [System.Management.Automation.ScriptBlock]$CoreScriptBlock = [System.Management.Automation.ScriptBlock]::Create($CoreScriptText)

            # EXECUTION - PING COMPUTERS AND GENERATE REPORTS
            # Ping the computers and generate the reports
            foreach ($ComputerName in $ComputerNames) {
                if ([System.String]::IsNullOrWhiteSpace($ComputerName)) { continue }

                # Replace invalid file name characters to avoid output file errors
                [System.String]$SafeComputerName = [System.Text.RegularExpressions.Regex]::Replace($ComputerName, '[\\/:*?""<>|]', '_')
                [System.String]$SafePortSuffix = if ([System.String]::IsNullOrWhiteSpace($TargetPort)) {
                    ''
                }
                else {
                    [System.String]$_SafeTargetPort = [System.Text.RegularExpressions.Regex]::Replace([System.String]$TargetPort, '[\\/:*?""<>|]', '_')
                    "_Port$($_SafeTargetPort)"
                }
                [System.String]$OutputFile = Join-Path -Path $OutputFolder -ChildPath "IP-Report_$($SafeComputerName)$($SafePortSuffix).txt"

                # If the output file already exists, remove it to ensure we start with a clean slate for this report
                if (Test-Path -LiteralPath $OutputFile) { Remove-Item -Path $OutputFile -Force }

                # Try to ping the computer with [PING.EXE] and capture the results, handling any errors that may occur
                [System.String]$PingResultWithPing = try {
                    PING.EXE -n 1 $ComputerName | Out-String
                }
                catch {
                    "The Ping command failed. The Computer named ($ComputerName) could not be reached from this host ($env:COMPUTERNAME)."
                }

                # Try to ping the computer with [Test-NetConnection] and capture the results, handling any errors that may occur
                [System.String]$PingResultWithTestNetConnection = try {
                    [PSCustomObject]$ConnectionResult = [PSCustomObject](& $CoreScriptBlock -TargetComputerName $ComputerName -TargetPort $TargetPort)
                    [System.String]$PortText = if ([System.String]::IsNullOrWhiteSpace([System.String]$ConnectionResult.Port)) { 'N/A (ICMP)' } else { [System.String]$ConnectionResult.Port }
                    @(
                        "ComputerName : $($ConnectionResult.ComputerName)"
                        "Port         : $PortText"
                        "Reachable    : $($ConnectionResult.Reachable)"
                        "Status       : $($ConnectionResult.Status)"
                        "Mode         : $($ConnectionResult.Mode)"
                    ) -join [System.Environment]::NewLine
                }
                catch {
                    "The Test-NetConnection command failed. The Computer named ($ComputerName) could not be reached from this host ($env:COMPUTERNAME)."
                }

                # Try to ping the computer with [Test-Connection] and capture the results, handling any errors that may occur
                [System.String]$PingResultWithTestConnection = try {
                    Test-Connection -ComputerName $ComputerName -Count 1 -ErrorAction Stop | Format-Table -AutoSize | Out-String
                }
                catch {
                    "The Test-Connection command failed. The Computer named ($ComputerName) could not be reached from this host ($env:COMPUTERNAME)."
                }

                # Try to resolve the DNS name of the computer with [Resolve-DnsName] and capture the results, handling any errors that may occur
                [System.String]$PingResultWithResolveDnsName = try {
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
                    "Requested Port: $(if ([System.String]::IsNullOrWhiteSpace($TargetPort)) { 'N/A (ICMP)' } else { $TargetPort })"
                    "----------------------------------------------------------------------",""
                    "----------------------------------------------------------------------"
                    "RESULT OF [PING.EXE] for ($ComputerName):"
                    $PingResultWithPing
                    "----------------------------------------------------------------------"
                    "RESULT OF [Test-NetConnection] for ($ComputerName):"
                    $PingResultWithTestNetConnection
                    ""
                    "----------------------------------------------------------------------"
                    "RESULT OF [Test-Connection] for ($ComputerName):"
                    $PingResultWithTestConnection
                    "----------------------------------------------------------------------"
                    "RESULT OF [Resolve-DnsName] for ($ComputerName):"
                    $PingResultWithResolveDnsName
                    "----------------------------------------------------------------------"
                ) | Out-File -FilePath $OutputFile -Append -Encoding utf8
            }
        }

        # POST-EXECUTION
        # Open the output folder for convenience and confirm the queue operation
        Write-Line "[END] IP Report | Result=[Queued] | JobId=[$($Job.Id)] | Targets=[$TargetsText]"
        Open-Folder -Path $OutputFolder
    }
    catch {
        Write-Line "[FAIL] IP Report | Reason=[Failed to queue or prepare report generation]" -Type Error
        Write-ErrorReport -ErrorRecord $_
    }
}

### END OF FUNCTION
####################################################################################################

