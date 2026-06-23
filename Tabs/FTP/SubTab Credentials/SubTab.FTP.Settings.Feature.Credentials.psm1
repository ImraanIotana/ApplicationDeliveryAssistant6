####################################################################################################
<#
.SYNOPSIS
    Imports the File Bitness feature into the Files sub-tab.
.DESCRIPTION
    This function imports the File Bitness feature into the Files sub-tab by creating a new GroupBox and adding it to the specified parent TabPage.
.EXAMPLE
    Import-FeatureFileBitness -InputObject $MyApplicationObject -ParentTabPage $MyTabPage
.INPUTS
    [PSCustomObject]
    [System.Windows.Forms.TabPage]
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. All rights reserved.
    Version         : 6.0.0.0
    Author          : Imraan Iotana
    Creation Date   : June 2026
    Last Update     : June 2026
#>
####################################################################################################
function Import-FeatureFTPCredentials {
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
            Title           = 'CREDENTIALS'
            Color           = 'Indigo'
            NumberOfRows    = 4
            GroupBoxAbove   = $GroupBoxAbove
        }
        # Create the GroupBox
        [System.Windows.Forms.GroupBox]$FeatureGroupBox = New-GroupBox @FeatureProperties -OnSubTab

        # PREPARATION - TEXTBOXES
        # Set the FTP Server URL TextBox properties
        [System.Collections.Hashtable]$ServerURLTextBoxProperties = @{
            RowNumber       = 1
            Label           = 'Server URL / Host'
            PropertyName    = 'TextBoxes.FTP.Credentials.ServerURL'
            ToolTip         = 'The URL, hostname, or IP address of the FTP/SFTP server. Use ftp://, ftps://, or sftp:// when needed.'
            SizeType        = 'Medium'
            SmallButtons    = @(@(5,'Copy'),@(6,'Paste'),@(7,'Clear'))
        }
        # Set the Username TextBox properties
        [System.Collections.Hashtable]$UsernameTextBoxProperties = @{
            RowNumber       = 2
            Label           = 'Username'
            PropertyName    = 'TextBoxes.FTP.Credentials.Username'
            ToolTip         = 'The username for FTP authentication'
            SizeType        = 'Medium'
            SmallButtons    = @(@(5,'Copy'),@(6,'Paste'),@(7,'Clear'))
        }
        # Set the Password TextBox properties
        [System.Collections.Hashtable]$PasswordTextBoxProperties = @{
            RowNumber       = 3
            Label           = 'Password'
            PropertyName    = 'TextBoxes.FTP.Credentials.Password'
            ToolTip         = 'The password for FTP authentication'
            SizeType        = 'Medium'
            UsePasswordChar = $true
            SmallButtons    = @(@(5,'Show'),@(6,'Paste'),@(7,'Clear'))
        }
        # Create the TextBoxes
        if (-not $Global:Graphics.TextBoxes.FTP.ContainsKey('Credentials')) { $Global:Graphics.TextBoxes.FTP.Credentials = @{} }
        $Global:Graphics.TextBoxes.FTP.Credentials.ServerURL = New-TextBox @ServerURLTextBoxProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ReturnTextBox
        $Global:Graphics.TextBoxes.FTP.Credentials.Username = New-TextBox @UsernameTextBoxProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ReturnTextBox
        $Global:Graphics.TextBoxes.FTP.Credentials.Password = New-TextBox @PasswordTextBoxProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ReturnTextBox

        # PREPARATION - BUTTONS
        # Set the Test Connection Button properties
        [System.Collections.Hashtable]$TestConnectionButtonProperties = @{
            RowNumber       = 4
            ToolTip         = 'Test the FTP connection using the provided credentials'
            SizeType        = 'Medium'
            Function        = {
                # Retrieve the values from the TextBoxes
                $ServerURL = $Global:Graphics.TextBoxes.FTP.Credentials.ServerURL.Text
                $Username  = $Global:Graphics.TextBoxes.FTP.Credentials.Username.Text
                $Password  = $Global:Graphics.TextBoxes.FTP.Credentials.Password.Text

                # Call a function to test the FTP connection (this function should be defined elsewhere)
                Test-FTPConnection -ServerURL $ServerURL -Username $Username -Password $Password
            }
        }
        # Create the Test Connection Button
        New-Button @TestConnectionButtonProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ColumnNumber 1

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
    Tests an FTP or SFTP connection using the provided server URL and credentials.
.DESCRIPTION
    This function validates the connection input values and tests FTP, FTPS, or SFTP
    connectivity and authentication based on the supplied URL.
.EXAMPLE
    Test-FTPConnection -ServerURL 'ftp://my-server.local/' -Username 'myUser' -Password 'myPassword'
.INPUTS
    [System.String]
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. All rights reserved.
    Version         : 6.0.0.0
    Author          : Imraan Iotana
    Creation Date   : June 2026
    Last Update     : June 2026
#>
####################################################################################################
function Test-FTPConnection {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The FTP server URL to test.')]
        [System.String]$ServerURL,

        [Parameter(Mandatory=$true,HelpMessage='The username for FTP authentication.')]
        [System.String]$Username,

        [Parameter(Mandatory=$true,HelpMessage='The password for FTP authentication.')]
        [System.String]$Password
    )

    try {
        function Test-TcpPort {
            param (
                [Parameter(Mandatory=$true)]
                [System.String]$HostName,

                [Parameter(Mandatory=$true)]
                [System.Int32]$Port,

                [Parameter(Mandatory=$false)]
                [System.Int32]$TimeoutMilliseconds = 1500
            )

            [System.Net.Sockets.TcpClient]$TcpClient = $null

            try {
                $TcpClient = [System.Net.Sockets.TcpClient]::new()
                [System.IAsyncResult]$ConnectTask = $TcpClient.BeginConnect($HostName, $Port, $null, $null)

                if (-not $ConnectTask.AsyncWaitHandle.WaitOne($TimeoutMilliseconds, $false)) {
                    return $false
                }

                $TcpClient.EndConnect($ConnectTask)
                return $true
            }
            catch {
                return $false
            }
            finally {
                if ($null -ne $TcpClient) {
                    $TcpClient.Dispose()
                }
            }
        }

        function Get-SftpAssemblyDirectory {
            [System.String[]]$CandidatePaths = @(
                (Join-Path $PSScriptRoot '..\..\..\Packages\Posh-SSH.3.2.4\Assembly'),
                (Join-Path $PSScriptRoot '..\..\..\Packages\SSH.NET')
            )

            foreach ($CandidatePath in $CandidatePaths) {
                if (Test-Path -Path (Join-Path $CandidatePath 'Renci.SshNet.dll')) {
                    return $CandidatePath
                }
            }

            return $null
        }

        function Import-SftpAssemblies {
            param (
                [Parameter(Mandatory=$true)]
                [System.String]$AssemblyDirectory
            )

            [System.String[]]$AssemblyNames = @(
                'Microsoft.Bcl.AsyncInterfaces.dll',
                'System.Buffers.dll',
                'System.Memory.dll',
                'System.Numerics.Vectors.dll',
                'System.Runtime.CompilerServices.Unsafe.dll',
                'System.Threading.Tasks.Extensions.dll',
                'Newtonsoft.Json.dll',
                'SshNet.Security.Cryptography.dll',
                'Renci.SshNet.dll'
            )

            foreach ($AssemblyName in $AssemblyNames) {
                [System.String]$AssemblyPath = Join-Path $AssemblyDirectory $AssemblyName

                if (Test-Path -Path $AssemblyPath) {
                    Add-Type -Path $AssemblyPath -ErrorAction SilentlyContinue
                }
            }
        }

        function Test-SFTPConnection {
            param (
                [Parameter(Mandatory=$true)]
                [System.Uri]$Uri,

                [Parameter(Mandatory=$true)]
                [System.String]$UserName,

                [Parameter(Mandatory=$true)]
                [System.String]$UserPassword
            )

            [System.String]$SftpAssemblyDirectory = Get-SftpAssemblyDirectory
            if (Test-String -IsEmpty $SftpAssemblyDirectory) {
                throw 'SFTP support is not installed. Expected SSH.NET assemblies under Packages\\Posh-SSH.3.2.4\\Assembly or Packages\\SSH.NET.'
            }

            Import-SftpAssemblies -AssemblyDirectory $SftpAssemblyDirectory

            [System.Int32]$Port = if ($Uri.IsDefaultPort -or $Uri.Port -lt 1) { 22 } else { $Uri.Port }
            [System.String]$ConnectionTarget = 'sftp://{0}:{1}' -f $Uri.Host, $Port
            [Renci.SshNet.SftpClient]$Client = $null

            try {
                Write-Line "Attempting to connect to SFTP server at '$ConnectionTarget' with username '$UserName'..." -Type Info
                $Client = [Renci.SshNet.SftpClient]::new($Uri.Host, $Port, $UserName, $UserPassword)
                $Client.ConnectionInfo.Timeout = [System.TimeSpan]::FromSeconds(10)
                $Client.OperationTimeout = [System.TimeSpan]::FromSeconds(10)
                $Client.Connect()

                Write-Line 'Success! SFTP connection established and credentials are valid.' -Type Success
                Write-Line "Technical details: Connected to $($Uri.Host) on port $Port using SFTP." -Type Info
            }
            finally {
                if ($null -ne $Client) {
                    if ($Client.IsConnected) {
                        $Client.Disconnect()
                    }

                    $Client.Dispose()
                }
            }
        }

        # VALIDATION
        # Ensure all required values are populated.
        if (Test-String -IsEmpty $ServerURL) { throw 'The FTP Server URL is empty.' }
        if (Test-String -IsEmpty $Username)  { throw 'The FTP Username is empty.' }
        if (Test-String -IsEmpty $Password)  { throw 'The FTP Password is empty.' }

        # PREPARATION
        # Normalize and validate the server URL before creating the request.
        [System.String]$NormalizedServerURL = $ServerURL.Trim()
        [System.Boolean]$HadExplicitScheme = $NormalizedServerURL -match '^(?i)\w+://'
        [System.Boolean]$UseSsl = $false
        [System.Uri]$ServerUri = $null
        [System.String]$ConnectionScheme = $null

        if (-not $HadExplicitScheme) {
            $NormalizedServerURL = 'ftp://' + $NormalizedServerURL
        }

        if (-not [System.Uri]::TryCreate($NormalizedServerURL, [System.UriKind]::Absolute, [ref]$ServerUri)) {
            throw 'The FTP Server URL is not a valid absolute URI.'
        }

        $ConnectionScheme = $ServerUri.Scheme.ToLowerInvariant()

        if (-not $HadExplicitScheme) {
            if ($ServerUri.Port -eq 22) {
                $ConnectionScheme = 'sftp'
            }
            elseif ((-not (Test-TcpPort -HostName $ServerUri.Host -Port $ServerUri.Port)) -and (Test-TcpPort -HostName $ServerUri.Host -Port 22)) {
                $ConnectionScheme = 'sftp'
            }
        }

        switch ($ConnectionScheme) {
            'ftp' {
                $UseSsl = $false
            }
            'ftps' {
                $UseSsl = $true
            }
            'sftp' {
                Test-SFTPConnection -Uri $ServerUri -UserName $Username -UserPassword $Password
                return
            }
            default {
                throw "Unsupported server URL scheme '$($ServerUri.Scheme)'. Use ftp:// for FTP, ftps:// for explicit FTPS, or sftp:// for SFTP."
            }
        }

        if ($ServerUri.Port -eq 990 -and $UseSsl) {
            throw 'Implicit FTPS on port 990 is not supported by this test. Use an explicit FTPS endpoint or plain FTP.'
        }

        [System.String]$RequestUrl = 'ftp://{0}{1}' -f $ServerUri.Authority, $ServerUri.AbsolutePath
        if (-not $RequestUrl.EndsWith('/')) {
            $RequestUrl += '/'
        }

        # Build the FTP request.
        [System.Net.NetworkCredential]$Credentials = New-Object System.Net.NetworkCredential($Username, $Password)
        [System.Net.FtpWebRequest]$Request = [System.Net.FtpWebRequest]::Create($RequestUrl)
        $Request.Method = [System.Net.WebRequestMethods+Ftp]::PrintWorkingDirectory
        $Request.Credentials = $Credentials
        $Request.KeepAlive = $false
        $Request.UseBinary = $true
        $Request.UsePassive = $true
        $Request.EnableSsl = $UseSsl
        $Request.Timeout = 10000
        $Request.ReadWriteTimeout = 10000

        # EXECUTION
        # Try to connect and authenticate.
        Write-Line "Attempting to connect to FTP server at '$RequestUrl' with username '$Username'..." -Type Info
        [System.Net.FtpWebResponse]$Response = $Request.GetResponse()

        Write-Line 'Success! FTP connection established and credentials are valid.' -Type Success
        Write-Line "Technical details: $($Response.StatusDescription.Trim())" -Type Info

        $Response.Close()
    }
    catch {
        [System.Exception]$Exception = $_.Exception
        [System.Exception]$ClassifiedException = if ($Exception.InnerException) { $Exception.InnerException } else { $Exception }
        [System.String]$FailureMessage = $ClassifiedException.Message

        if ($ClassifiedException -is [System.Net.WebException]) {
            $FailureMessage = 'Failed to connect. Please verify the server URL, username, and password.'

            if ($ClassifiedException.Status -eq [System.Net.WebExceptionStatus]::ConnectFailure) {
                [System.Boolean]$FtpPortReachable = Test-TcpPort -HostName $ServerUri.Host -Port $ServerUri.Port
                [System.Boolean]$SftpPortReachable = Test-TcpPort -HostName $ServerUri.Host -Port 22
                [System.Boolean]$ImplicitFtpsPortReachable = Test-TcpPort -HostName $ServerUri.Host -Port 990

                if (($ServerUri.Scheme -eq 'ftp') -and (-not $FtpPortReachable) -and $SftpPortReachable) {
                    $FailureMessage = 'Failed to connect with FTP because this host is reachable on port 22 (SFTP), not on the FTP port. Use an SFTP client/workflow for this server.'
                }
                elseif (($ServerUri.Scheme -eq 'ftp') -and (-not $FtpPortReachable) -and $ImplicitFtpsPortReachable) {
                    $FailureMessage = 'Failed to connect with FTP because this host appears to expose FTPS on port 990 instead of FTP on port 21.'
                }
                else {
                    $FailureMessage = 'Failed to connect to the FTP server. Verify the hostname, port, firewall access, and whether the server expects FTP or explicit FTPS.'
                }
            }
            elseif ($ClassifiedException.Response -is [System.Net.FtpWebResponse]) {
                [System.Net.FtpWebResponse]$FailedResponse = $ClassifiedException.Response
                [System.String]$StatusDescription = $FailedResponse.StatusDescription

                if (Test-String -IsPopulated $StatusDescription) {
                    $FailureMessage = "FTP server rejected the request: $($StatusDescription.Trim())"
                }
                else {
                    $FailureMessage = "FTP server rejected the request with status '$($FailedResponse.StatusCode)'."
                }

                $FailedResponse.Close()
            }
            elseif ($ClassifiedException.Status -eq [System.Net.WebExceptionStatus]::Timeout) {
                $FailureMessage = 'The FTP server did not respond in time. Verify the hostname, port, and network connectivity.'
            }
        }
        elseif ($ConnectionScheme -eq 'sftp') {
            if ($ClassifiedException.Message -match '(?i)permission denied') {
                $FailureMessage = 'SFTP authentication failed. Verify the username, password, and required SSH authentication method.'
            }
            else {
                $FailureMessage = "SFTP connection failed: $($ClassifiedException.Message)"
            }
        }

        Write-Line $FailureMessage -Type Fail

        if (($ClassifiedException -is [System.Net.WebException]) -or ($ConnectionScheme -eq 'sftp')) {
            return
        }

        Write-ErrorReport -ErrorRecord $_
    }
}

### END OF FUNCTION
####################################################################################################
