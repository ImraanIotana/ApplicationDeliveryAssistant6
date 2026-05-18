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
    No objects are returned to the pipeline. All output is written to the host.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. All rights reserved.
    Version         : 6.0.0.0
    Author          : Imraan Iotana
    Creation Date   : May 2026
    Last Update     : May 2026
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
            Color           = 'White'
            NumberOfRows    = 2
        }
        # If the GroupBoxAbove parameter is provided, set the GroupBoxAbove property
        if ($PSBoundParameters.ContainsKey('GroupBoxAbove')) { $FeatureProperties.GroupBoxAbove = $GroupBoxAbove }

        # PREPARATION - TEXTBOXES
        # Set the TextBox properties
        [System.Collections.Hashtable[]]$TextBoxPropertiesArray = @(
            @{
                RowNumber       = 1
                Label           = 'ComputerName / IP address:'
                PropertyName    = 'SubTab.Connections.Ping.ComputerName'
                ToolTip         = 'The name or IP address of the computer to ping'
                Buttons         = [System.Object[][]]@(@(1, 'Copy'), @(2, 'Paste'))
            }
        )

        # PREPARATION - BUTTONS
        # Set the Button properties
        [System.Collections.Hashtable[]]$ButtonPropertiesArray1 = @(
            @{
                ColumnNumber    = 4
                Text            = 'Ping'
                PNGFileName     = 'computer_go'
                SizeType        = 'Medium'
                Function        = {  }
            }
            @{
                ColumnNumber    = 5
                Text            = 'IP Report'
                PNGFileName     = 'report_go'
                SizeType        = 'Medium'
                Function        = {
                    [System.String]$ComputerName = Get-UserSetting -InputObject $InputObject -PropertyName 'SubTab.Connections.Ping.ComputerName'
                    Get-ComputerIPReport -ComputerNames @($ComputerName)
                }.GetNewClosure()
            }
        )


        # EXECUTION
        # Create the GroupBox
        [System.Windows.Forms.GroupBox]$FeatureGroupBox = New-GroupBox @FeatureProperties
        # Create the TextBoxes
        foreach ($TextBoxProperties in $TextBoxPropertiesArray) { New-TextBox @TextBoxProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox }
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
        [Parameter(Mandatory=$true,HelpMessage='The computer names to ping.')]
        [System.String[]]$ComputerNames,

        [Parameter(Mandatory=$false,HelpMessage='The output folder where the results will be saved.')]
        [System.String]$OutputFolder = (Get-UserProperty -PropertyName 'OutputFolder')
    )

    try {
        # VALIDATION
        # Validate the array of computer names
        if (($null -eq $ComputerNames) -or ($ComputerNames.Count -eq 0)) {
            throw "The array of computer names is null or empty. Please provide at least one computer name to ping."
        }
        # Validate the computer names
        foreach ($ComputerName in $ComputerNames) {
            if ([System.String]::IsNullOrWhiteSpace($ComputerName)) {
                throw "One of the computer names is null, empty, or consists only of whitespace. Please provide valid computer names."
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
                Test-NetConnection -ComputerName $ComputerName -ErrorAction Stop | Format-List | Out-String
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
                Resolve-DnsName -Name $ComputerName -ErrorAction Stop | Format-List | Out-String
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
        Write-Error "The file $(Split-Path -Leaf $PSCommandPath) has encountered an error: $_"
    }

}

### END OF SCRIPT
####################################################################################################
