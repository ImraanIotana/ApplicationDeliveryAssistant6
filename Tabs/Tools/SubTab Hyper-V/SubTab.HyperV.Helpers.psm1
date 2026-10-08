####################################################################################################
<#
.SYNOPSIS
    Provides helper functions for the Hyper-V tab.
.DESCRIPTION
    Contains reusable Hyper-V discovery and configuration helpers shared by Hyper-V features.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.4.0
    Author          : Imraan Iotana
    Creation Date   : August 2026
    Last Update     : August 2026
#>
####################################################################################################
function Get-HyperVVirtualSwitchOptions {
    [CmdletBinding()]
    [OutputType([System.String[]])]
    param ()

    # PREPARATION - FALLBACK OPTIONS
    [System.Collections.Generic.List[string]]$SwitchOptions = New-Object 'System.Collections.Generic.List[string]'
    $null = $SwitchOptions.Add('(Not Connected)')
    $null = $SwitchOptions.Add('Default Switch')

    # EXECUTION - HOST SWITCH DISCOVERY
    try {
        if ($null -ne (Get-Command -Name 'Get-VMSwitch' -ErrorAction SilentlyContinue)) {
            $HostSwitches = @(Get-VMSwitch -ErrorAction Stop | Sort-Object -Property Name)
            foreach ($HostSwitch in $HostSwitches) {
                [System.String]$SwitchName = [System.String]$HostSwitch.Name
                if ([string]::IsNullOrWhiteSpace($SwitchName) -or $SwitchOptions.Contains($SwitchName)) { continue }
                $null = $SwitchOptions.Add($SwitchName)
            }
        }
    }
    catch {
        # Hyper-V discovery can require elevation; retain the fallback options when it is unavailable.
    }

    # OUTPUT
    return $SwitchOptions.ToArray()
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Gets virtual machine names for the Hyper-V management UI.
.DESCRIPTION
    Reads VM names from the current Hyper-V host and returns a stable placeholder when discovery is unavailable or no VMs exist.
.EXAMPLE
    Get-HyperVVirtualMachineOptions
.OUTPUTS
    [System.String[]]
#>
####################################################################################################
function Get-HyperVVirtualMachineOptions {
    [CmdletBinding()]
    [OutputType([System.String[]])]
    param ()

    # PREPARATION - FALLBACK OPTIONS
    [System.Collections.Generic.List[string]]$VirtualMachineOptions = New-Object 'System.Collections.Generic.List[string]'

    # EXECUTION - VM DISCOVERY
    try {
        if ($null -ne (Get-Command -Name 'Get-VM' -ErrorAction SilentlyContinue)) {
            $VirtualMachines = @(Get-VM -ErrorAction Stop | Sort-Object -Property Name)
            foreach ($VirtualMachine in $VirtualMachines) {
                [System.String]$VirtualMachineName = [System.String]$VirtualMachine.Name
                if ([string]::IsNullOrWhiteSpace($VirtualMachineName) -or $VirtualMachineOptions.Contains($VirtualMachineName)) { continue }
                $null = $VirtualMachineOptions.Add($VirtualMachineName)
            }
        }
    }
    catch {
        # Hyper-V discovery can require elevation; retain the placeholder when it is unavailable.
    }

    if ($VirtualMachineOptions.Count -eq 0) {
        $null = $VirtualMachineOptions.Add('(No Virtual Machines Found)')
    }

    # OUTPUT
    return $VirtualMachineOptions.ToArray()
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Gets Hyper-V virtual machine names through an elevated worker.
.DESCRIPTION
    Queries the elevated Hyper-V host inventory so the management UI can see the same registered VMs as Hyper-V Manager.
.EXAMPLE
    Get-HyperVElevatedVirtualMachineOptions
.OUTPUTS
    [System.String[]]
#>
####################################################################################################
function Get-HyperVElevatedVirtualMachineOptions {
    [CmdletBinding()]
    [OutputType([System.String[]])]
    param ()

    [System.String]$ResultFilePath = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath ('ADA-HyperV-Inventory-' + [System.Guid]::NewGuid().ToString('N') + '.result')
    [System.String]$EscapedResultFilePath = $ResultFilePath.Replace("'", "''")
    [System.String]$ElevatedScript = @"
`$ErrorActionPreference = 'Stop'
Import-Module Hyper-V -ErrorAction Stop
`$VirtualMachineNames = @(Get-VM -ErrorAction Stop | Sort-Object -Property Name | ForEach-Object { [System.String]`$_.Name })
[System.IO.File]::WriteAllLines('$EscapedResultFilePath', [System.String[]]`$VirtualMachineNames)
exit 0
"@

    try {
        # EXECUTION - ELEVATED INVENTORY
        Write-Line 'Waiting for administrator approval...' -Type Busy
        [System.Int32]$ElevatedExitCode = Invoke-ElevatedPowerShell -Script $ElevatedScript -StartFailureMessage 'The elevated Hyper-V inventory process could not be started.' -PostApprovalMessage 'Refreshing the Hyper-V virtual machine inventory...'
        if ($ElevatedExitCode -ne 0) { throw "The elevated Hyper-V inventory failed with exit code $ElevatedExitCode." }

        # OUTPUT
        [System.String[]]$VirtualMachineNames = if (Test-Path -LiteralPath $ResultFilePath -PathType Leaf) { @(Get-Content -LiteralPath $ResultFilePath | Where-Object { -not [System.String]::IsNullOrWhiteSpace($_) }) } else { @() }
        if ($VirtualMachineNames.Count -eq 0) { return @('(No Virtual Machines Found)') }
        return $VirtualMachineNames
    }
    catch {
        Write-Line "Elevated Hyper-V inventory refresh failed: $($_.Exception.Message)" -Type Warning
        return @('(No Virtual Machines Found)')
    }
    finally {
        Remove-Item -LiteralPath $ResultFilePath -Force -ErrorAction SilentlyContinue
    }
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Refreshes the Hyper-V management VM selector.
.DESCRIPTION
    Updates the management selector from the Hyper-V host inventory and optionally selects a requested VM name.
.EXAMPLE
    Update-HyperVManagementVirtualMachineSelector -VirtualMachineName 'Demo VM'
.OUTPUTS
    No objects are returned to the pipeline.
#>
####################################################################################################
function Update-HyperVManagementVirtualMachineSelector {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false)]
        [AllowEmptyString()]
        [System.String]$VirtualMachineName,

        [Parameter(Mandatory=$false,HelpMessage='A virtual machine inventory already fetched by another elevated operation, used to avoid a second administrator approval prompt.')]
        [AllowNull()]
        [System.String[]]$VirtualMachineInventory
    )

    # VALIDATION - MANAGEMENT CONTROL
    if ($null -eq $Global:HyperVManagementVirtualMachineComboBox) { return }

    # PREPARATION - CURRENT SELECTION
    [System.String]$PreviouslySelectedVirtualMachine = [System.String]$Global:HyperVManagementVirtualMachineComboBox.Text
    [System.String[]]$VirtualMachineOptions = if ($null -ne $VirtualMachineInventory) { @($VirtualMachineInventory) } else { @(Get-HyperVElevatedVirtualMachineOptions) }
    if ($VirtualMachineOptions.Count -eq 0) { $VirtualMachineOptions = @('(No Virtual Machines Found)') }
    if (-not [System.String]::IsNullOrWhiteSpace($PreviouslySelectedVirtualMachine) -and
        $PreviouslySelectedVirtualMachine -ne '(No Virtual Machines Found)' -and
        -not $VirtualMachineOptions.Contains($PreviouslySelectedVirtualMachine)) {
        $VirtualMachineOptions = @($VirtualMachineOptions + $PreviouslySelectedVirtualMachine)
    }

    # EXECUTION - REFRESH CONTENT
    Update-ComboBox -ComboBox $Global:HyperVManagementVirtualMachineComboBox -ContentStringArray $VirtualMachineOptions -PreservePreviousSelection -Silent

    # POST-EXECUTION - SELECT REQUESTED VM
    if (-not [System.String]::IsNullOrWhiteSpace($VirtualMachineName)) {
        if (-not $Global:HyperVManagementVirtualMachineComboBox.Items.Contains($VirtualMachineName)) {
            if ($Global:HyperVManagementVirtualMachineComboBox.Items.Contains('(No Virtual Machines Found)')) {
                $Global:HyperVManagementVirtualMachineComboBox.Items.Remove('(No Virtual Machines Found)')
            }
            [void]$Global:HyperVManagementVirtualMachineComboBox.Items.Add($VirtualMachineName)
        }
        $Global:HyperVManagementVirtualMachineComboBox.SelectedItem = $VirtualMachineName
    }

    # POST-EXECUTION - REFRESH STATUS
    [System.Int32]$VirtualMachineCount = @($VirtualMachineOptions | Where-Object { $_ -ne '(No Virtual Machines Found)' }).Count
    Write-Line "Hyper-V virtual machine list refreshed successfully. ($VirtualMachineCount VM(s) found.)" -Type Success
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Opens Hyper-V Manager.
.DESCRIPTION
    Starts the standard Windows Hyper-V Manager console for the local host.
.EXAMPLE
    Open-HyperVManager
.OUTPUTS
    No objects are returned to the pipeline.
#>
####################################################################################################
function Open-HyperVManager {
    [CmdletBinding()]
    param ()

    try {
        # VALIDATION - HYPER-V MANAGER
        [System.String]$HyperVManagerPath = Join-Path -Path $env:WINDIR -ChildPath 'System32\virtmgmt.msc'
        if (-not (Test-Path -LiteralPath $HyperVManagerPath -PathType Leaf)) {
            throw "Hyper-V Manager was not found. ($HyperVManagerPath)"
        }

        # EXECUTION - HYPER-V MANAGER
        Start-Process -FilePath $HyperVManagerPath -ErrorAction Stop
        Write-Line 'Opened Hyper-V Manager.' -Type Success
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
    Shows details for the virtual machine selected in the Hyper-V management selector.
.DESCRIPTION
    Queries the elevated Hyper-V host for the selected VM's state, hardware, and security configuration and writes the result to the host.
.EXAMPLE
    Show-HyperVSelectedVirtualMachineDetails
.OUTPUTS
    No objects are returned to the pipeline.
#>
####################################################################################################
function Show-HyperVSelectedVirtualMachineDetails {
    [CmdletBinding()]
    param ()

    [System.String]$ResultFilePath = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath ('ADA-HyperV-Details-' + [System.Guid]::NewGuid().ToString('N') + '.result')

    try {
        # VALIDATION - SELECTED VIRTUAL MACHINE
        if ($null -eq $Global:HyperVManagementVirtualMachineComboBox) {
            Write-Line 'The virtual machine selector is not available.' -Type Warning
            return
        }
        [System.String]$SelectedVirtualMachineName = [System.String]$Global:HyperVManagementVirtualMachineComboBox.Text
        if ([System.String]::IsNullOrWhiteSpace($SelectedVirtualMachineName) -or $SelectedVirtualMachineName -eq '(No Virtual Machines Found)') {
            Write-Line 'No virtual machine is selected.' -Type Warning
            return
        }

        # PREPARATION - ELEVATED SCRIPT
        [System.String]$EscapedResultFilePath = $ResultFilePath.Replace("'", "''")
        [System.String]$EscapedVirtualMachineName = $SelectedVirtualMachineName.Replace("'", "''")
        [System.String]$ElevatedScript = @"
`$ErrorActionPreference = 'Stop'
Import-Module Hyper-V -ErrorAction Stop
`$VirtualMachine = Get-VM -Name '$EscapedVirtualMachineName' -ErrorAction Stop
`$SecureBootState = 'N/A'
try { `$SecureBootState = (Get-VMFirmware -VMName `$VirtualMachine.Name -ErrorAction Stop).SecureBoot } catch {}
`$TpmState = 'N/A'
try { `$TpmState = if ((Get-VMSecurity -VMName `$VirtualMachine.Name -ErrorAction Stop).TpmEnabled) { 'Enabled' } else { 'Disabled' } } catch {}
`$DetailLines = @(
    "Name: `$(`$VirtualMachine.Name)"
    "State: `$(`$VirtualMachine.State)"
    "Generation: `$(`$VirtualMachine.Generation)"
    "Processor Count: `$(`$VirtualMachine.ProcessorCount)"
    "Startup Memory (MB): `$([Math]::Round(`$VirtualMachine.MemoryStartup / 1MB))"
    "Assigned Memory (MB): `$([Math]::Round(`$VirtualMachine.MemoryAssigned / 1MB))"
    "Uptime: `$(`$VirtualMachine.Uptime)"
    "Status: `$(`$VirtualMachine.Status)"
    "Secure Boot: `$SecureBootState"
    "Virtual TPM: `$TpmState"
    "Path: `$(`$VirtualMachine.Path)"
)
[System.IO.File]::WriteAllLines('$EscapedResultFilePath', [System.String[]]`$DetailLines)
exit 0
"@

        # EXECUTION - ELEVATED DETAILS REQUEST
        Write-Line 'Waiting for administrator approval...' -Type Busy
        [System.Int32]$ElevatedExitCode = Invoke-ElevatedPowerShell -Script $ElevatedScript -StartFailureMessage 'The elevated Hyper-V details process could not be started.' -PostApprovalMessage "Retrieving details for '$SelectedVirtualMachineName'..."
        if ($ElevatedExitCode -ne 0) { throw "The elevated Hyper-V details request failed with exit code $ElevatedExitCode." }
        if (-not (Test-Path -LiteralPath $ResultFilePath -PathType Leaf)) { throw 'The elevated Hyper-V details request did not return any results.' }

        # OUTPUT - DETAILS
        [System.String[]]$DetailLines = @(Get-Content -LiteralPath $ResultFilePath | Where-Object { -not [System.String]::IsNullOrWhiteSpace($_) })
        Write-Line "Virtual machine details for '$SelectedVirtualMachineName':" -Type Success
        foreach ($DetailLine in $DetailLines) {
            Write-Line "  $DetailLine" -Type Info
        }
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
    finally {
        Remove-Item -LiteralPath $ResultFilePath -Force -ErrorAction SilentlyContinue
    }
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Validates the Hyper-V configuration values entered in the UI.
.DESCRIPTION
    Validates required paths, hardware values, selector values, and compatibility between the selected VM generation and Windows 11 security settings. This function does not create or modify a virtual machine.
.EXAMPLE
    Test-HyperVConfiguration -VirtualMachineName 'Demo VM' -VirtualMachineFolder 'D:\VMs' -WindowsIsoPath 'D:\ISO\Windows.iso' -VirtualHardDiskSizeGB '60' -StartupMemoryMB '4096' -ProcessorCount '2' -VirtualSwitch 'Default Switch' -Generation 'Generation 2' -SecureBoot 'Enabled' -VirtualTPM 'Enabled'
.INPUTS
    [System.String]
.OUTPUTS
    [System.Boolean]
#>
####################################################################################################
function Test-HyperVConfiguration {
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param (
        [Parameter(Mandatory=$true)]
        [AllowEmptyString()]
        [System.String]$VirtualMachineName,

        [Parameter(Mandatory=$true)]
        [AllowEmptyString()]
        [System.String]$VirtualMachineFolder,

        [Parameter(Mandatory=$true)]
        [AllowEmptyString()]
        [System.String]$WindowsIsoPath,

        [Parameter(Mandatory=$true)]
        [AllowEmptyString()]
        [System.String]$VirtualHardDiskSizeGB,

        [Parameter(Mandatory=$true)]
        [AllowEmptyString()]
        [System.String]$StartupMemoryMB,

        [Parameter(Mandatory=$true)]
        [AllowEmptyString()]
        [System.String]$ProcessorCount,

        [Parameter(Mandatory=$true)]
        [AllowEmptyString()]
        [System.String]$VirtualSwitch,

        [Parameter(Mandatory=$true)]
        [ValidateSet('Generation 1','Generation 2')]
        [System.String]$Generation,

        [Parameter(Mandatory=$true)]
        [ValidateSet('Enabled','Disabled')]
        [System.String]$SecureBoot,

        [Parameter(Mandatory=$true)]
        [ValidateSet('Enabled','Disabled')]
        [System.String]$VirtualTPM
    )

    # PREPARATION - VALIDATION STATE
    [System.Collections.Generic.List[string]]$ValidationErrors = New-Object 'System.Collections.Generic.List[string]'

    # VALIDATION - REQUIRED VALUES
    if ([System.String]::IsNullOrWhiteSpace($VirtualMachineName)) {
        $null = $ValidationErrors.Add('Virtual Machine Name is required.')
    }
    elseif ($VirtualMachineName.IndexOfAny([System.Char[]]'\\/:*?"<>|') -ge 0) {
        $null = $ValidationErrors.Add('Virtual Machine Name contains characters that are not valid in a VM name.')
    }

    if ([System.String]::IsNullOrWhiteSpace($VirtualMachineFolder)) {
        $null = $ValidationErrors.Add('Virtual Machine Folder is required.')
    }
    elseif (Test-Path -LiteralPath $VirtualMachineFolder -PathType Leaf) {
        $null = $ValidationErrors.Add("Virtual Machine Folder points to a file instead of a folder. ($VirtualMachineFolder)")
    }
    elseif (-not (Test-Path -LiteralPath $VirtualMachineFolder -PathType Container)) {
        [System.String]$VirtualMachineParentFolder = Split-Path -Path $VirtualMachineFolder -Parent
        if ([System.String]::IsNullOrWhiteSpace($VirtualMachineParentFolder) -or
            -not (Test-Path -LiteralPath $VirtualMachineParentFolder -PathType Container)) {
            $null = $ValidationErrors.Add("Virtual Machine Folder and its parent do not exist. Create or select a valid parent folder. ($VirtualMachineFolder)")
        }
    }

    if ([System.String]::IsNullOrWhiteSpace($WindowsIsoPath)) {
        $null = $ValidationErrors.Add('Windows Installation ISO is required.')
    }
    elseif (-not (Test-Path -LiteralPath $WindowsIsoPath -PathType Leaf)) {
        $null = $ValidationErrors.Add("Windows Installation ISO does not exist or is not a file. ($WindowsIsoPath)")
    }
    elseif (-not [System.String]::Equals([System.IO.Path]::GetExtension($WindowsIsoPath), '.iso', [System.StringComparison]::OrdinalIgnoreCase)) {
        $null = $ValidationErrors.Add('Windows Installation ISO must have an .iso extension.')
    }

    # VALIDATION - NUMERIC VALUES
    [System.Int64]$DiskSize = 0
    [System.Int64]$MemorySize = 0
    [System.Int32]$ProcessorTotal = 0
    if (-not [System.Int64]::TryParse($VirtualHardDiskSizeGB, [ref]$DiskSize) -or $DiskSize -le 0) {
        $null = $ValidationErrors.Add('Virtual Hard Disk Size must be a whole number greater than zero.')
    }
    if (-not [System.Int64]::TryParse($StartupMemoryMB, [ref]$MemorySize) -or $MemorySize -le 0) {
        $null = $ValidationErrors.Add('Startup Memory must be a whole number greater than zero.')
    }
    if (-not [System.Int32]::TryParse($ProcessorCount, [ref]$ProcessorTotal) -or $ProcessorTotal -lt 1 -or $ProcessorTotal -gt 64) {
        $null = $ValidationErrors.Add('Processor Count must be a whole number between 1 and 64.')
    }

    # VALIDATION - CONFIGURATION COMPATIBILITY
    if ([System.String]::IsNullOrWhiteSpace($VirtualSwitch)) {
        $null = $ValidationErrors.Add('Virtual Switch must be selected.')
    }
    if (($Generation -eq 'Generation 1') -and ($SecureBoot -eq 'Enabled' -or $VirtualTPM -eq 'Enabled')) {
        $null = $ValidationErrors.Add('Generation 1 cannot use Secure Boot or virtual TPM. Select Generation 2 or disable both security options.')
    }

    # OUTPUT
    if ($ValidationErrors.Count -gt 0) {
        foreach ($ValidationError in $ValidationErrors) {
            Write-Line $ValidationError -Type Warning
        }
        return $false
    }

    Write-Line 'Hyper-V configuration validation succeeded.' -Type Success
    return $true
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Creates the initial Hyper-V virtual machine shell.
.DESCRIPTION
    Creates the VM, its dynamically expanding VHDX, startup memory, processor count, generation, and optional virtual switch. ISO attachment, security configuration, and startup are deliberately separate later steps.
.EXAMPLE
    New-HyperVVirtualMachineCore -VirtualMachineName 'Demo VM' -VirtualMachineFolder 'D:\VMs' -VirtualHardDiskSizeGB '60' -StartupMemoryMB '4096' -ProcessorCount '2' -Generation 'Generation 2' -VirtualSwitch 'Default Switch'
.INPUTS
    [System.String]
.OUTPUTS
    No objects are returned to the pipeline.
.OUTPUTS
    No objects are returned to the pipeline.
#>
####################################################################################################
function New-HyperVVirtualMachineCore {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [System.String]$VirtualMachineName,

        [Parameter(Mandatory=$true)]
        [System.String]$VirtualMachineFolder,

        [Parameter(Mandatory=$true)]
        [System.String]$WindowsIsoPath,

        [Parameter(Mandatory=$true)]
        [System.String]$VirtualHardDiskSizeGB,

        [Parameter(Mandatory=$true)]
        [System.String]$StartupMemoryMB,

        [Parameter(Mandatory=$true)]
        [System.String]$ProcessorCount,

        [Parameter(Mandatory=$true)]
        [ValidateSet('Generation 1','Generation 2')]
        [System.String]$Generation,

        [Parameter(Mandatory=$true)]
        [System.String]$VirtualSwitch,

        [Parameter(Mandatory=$true)]
        [ValidateSet('Enabled','Disabled')]
        [System.String]$SecureBoot,

        [Parameter(Mandatory=$true)]
        [ValidateSet('Enabled','Disabled')]
        [System.String]$VirtualTPM,

        [Parameter(Mandatory=$false,HelpMessage='Replace an existing VM with the same name after confirmation.')]
        [System.Management.Automation.SwitchParameter]$ReplaceExisting
    )

    try {
        # VALIDATION - NUMERIC VALUES
        [System.Int64]$DiskSizeBytes = 0
        [System.Int64]$MemoryBytes = 0
        [System.Int32]$ProcessorTotal = 0
        if (-not [System.Int64]::TryParse($VirtualHardDiskSizeGB, [ref]$DiskSizeBytes) -or $DiskSizeBytes -le 0) {
            throw 'Virtual Hard Disk Size must be a whole number greater than zero.'
        }
        if (-not [System.Int64]::TryParse($StartupMemoryMB, [ref]$MemoryBytes) -or $MemoryBytes -le 0) {
            throw 'Startup Memory must be a whole number greater than zero.'
        }
        if (-not [System.Int32]::TryParse($ProcessorCount, [ref]$ProcessorTotal) -or $ProcessorTotal -lt 1 -or $ProcessorTotal -gt 64) {
            throw 'Processor Count must be a whole number between 1 and 64.'
        }

        # PREPARATION - ELEVATED SCRIPT VALUES
        [System.String]$EscapedVirtualMachineName = $VirtualMachineName.Replace("'", "''")
        [System.String]$EscapedVirtualMachineFolder = $VirtualMachineFolder.Replace("'", "''")
        [System.String]$EscapedWindowsIsoPath = $WindowsIsoPath.Replace("'", "''")
        [System.String]$EscapedVirtualHardDiskPath = (Join-Path -Path $VirtualMachineFolder -ChildPath ($VirtualMachineName + '.vhdx')).Replace("'", "''")
        [System.String]$EscapedVirtualSwitch = $VirtualSwitch.Replace("'", "''")
        [System.String]$ReplaceExistingValue = if ($ReplaceExisting.IsPresent) { '$true' } else { '$false' }
        [System.String]$SecureBootState = if ($SecureBoot -eq 'Enabled') { 'On' } else { 'Off' }
        [System.String]$VirtualTPMEnabled = if ($VirtualTPM -eq 'Enabled') { '$true' } else { '$false' }
        [System.String]$ResultFilePath = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath ('ADA-HyperV-' + [System.Guid]::NewGuid().ToString('N') + '.result')
        [System.String]$EscapedResultFilePath = $ResultFilePath.Replace("'", "''")
        [System.Int32]$GenerationNumber = [System.Int32]($Generation -replace '[^0-9]', '')
        [System.String]$VirtualSwitchLine = if (-not [System.String]::Equals($VirtualSwitch, '(Not Connected)', [System.StringComparison]::OrdinalIgnoreCase)) {
            "`$NewVMParameters.SwitchName = '$EscapedVirtualSwitch'"
        }
        else {
            [System.String]::Empty
        }

        [System.String]$ElevatedScript = @"
`$ErrorActionPreference = 'Stop'
Import-Module Hyper-V -ErrorAction Stop
`$CreatedVirtualMachine = `$null
try {
    New-Item -ItemType Directory -Path '$EscapedVirtualMachineFolder' -Force -ErrorAction Stop | Out-Null
    `$ExistingVirtualMachine = Get-VM -Name '$EscapedVirtualMachineName' -ErrorAction SilentlyContinue
    if (`$null -ne `$ExistingVirtualMachine) {
        if (-not __REPLACE_EXISTING_VALUE__) {
            Add-Type -AssemblyName System.Windows.Forms
            `$ReplaceChoice = [System.Windows.Forms.MessageBox]::Show("A virtual machine named '$EscapedVirtualMachineName' already exists.`n`nReplacing it will stop it if necessary, remove its VM configuration, remove its VHDX at the configured path, and create a new VM with the current settings.`n`nDo you want to continue?", 'Confirm Replace Hyper-V Virtual Machine', [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Warning)
            if (`$ReplaceChoice -ne [System.Windows.Forms.DialogResult]::Yes) {
                [System.IO.File]::WriteAllText('$EscapedResultFilePath', 'CANCELLED')
                exit 3
            }
        }
        if (`$ExistingVirtualMachine.State -ne 'Off') {
            Stop-VM -VM `$ExistingVirtualMachine -TurnOff -Force -ErrorAction Stop
        }
        `$ExistingHardDiskPaths = @(Get-VMHardDiskDrive -VM `$ExistingVirtualMachine -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Path)
        Remove-VM -VM `$ExistingVirtualMachine -Force -ErrorAction Stop
        if ((`$ExistingHardDiskPaths -contains '$EscapedVirtualHardDiskPath') -and (Test-Path -LiteralPath '$EscapedVirtualHardDiskPath' -PathType Leaf)) {
            Remove-Item -LiteralPath '$EscapedVirtualHardDiskPath' -Force -ErrorAction Stop
        }
    }
    if (Test-Path -LiteralPath '$EscapedVirtualHardDiskPath' -PathType Leaf) {
        Remove-Item -LiteralPath '$EscapedVirtualHardDiskPath' -Force -ErrorAction Stop
    }
    `$NewVMParameters = @{
        Name               = '$EscapedVirtualMachineName'
        Path               = '$EscapedVirtualMachineFolder'
        MemoryStartupBytes = $($MemoryBytes) * 1MB
        Generation         = $GenerationNumber
        NewVHDPath         = '$EscapedVirtualHardDiskPath'
        NewVHDSizeBytes    = $($DiskSizeBytes) * 1GB
        ErrorAction        = 'Stop'
    }
    $VirtualSwitchLine
    `$CreatedVirtualMachine = New-VM @NewVMParameters
    Set-VM -VM `$CreatedVirtualMachine -ProcessorCount $ProcessorTotal -ErrorAction Stop
    `$DvdDrive = Add-VMDvdDrive -VM `$CreatedVirtualMachine -Path '$EscapedWindowsIsoPath' -Passthru -ErrorAction Stop
    if ($GenerationNumber -eq 2) {
        Set-VMFirmware -VM `$CreatedVirtualMachine -FirstBootDevice `$DvdDrive -ErrorAction Stop
    }
    Set-VMFirmware -VM `$CreatedVirtualMachine -EnableSecureBoot $SecureBootState -ErrorAction Stop
    if ($VirtualTPMEnabled) {
        Set-VMKeyProtector -VM `$CreatedVirtualMachine -NewLocalKeyProtector -ErrorAction Stop
        Enable-VMTPM -VM `$CreatedVirtualMachine -ErrorAction Stop
    }
    `$FreshVirtualMachineNames = @(Get-VM -ErrorAction SilentlyContinue | Sort-Object -Property Name | ForEach-Object { [System.String]`$_.Name })
    [System.IO.File]::WriteAllLines('$EscapedResultFilePath', (@('SUCCESS') + `$FreshVirtualMachineNames))
    exit 0
}
catch {
    if (`$null -ne `$CreatedVirtualMachine) {
        Remove-VM -VM `$CreatedVirtualMachine -Force -ErrorAction SilentlyContinue
    }
    [System.IO.File]::WriteAllText('$EscapedResultFilePath', ((`$_ | Out-String).Trim()))
    exit 1
}
"@
    $ElevatedScript = $ElevatedScript.Replace('__REPLACE_EXISTING_VALUE__', $ReplaceExistingValue)

        # EXECUTION - ELEVATED VM CORE
        Write-Line 'Waiting for administrator approval...' -Type Busy
        try {
            [System.Int32]$ElevatedExitCode = Invoke-ElevatedPowerShell -Script $ElevatedScript -StartFailureMessage 'The elevated Hyper-V creation process could not be started.' -PostApprovalMessage "Creating Hyper-V virtual machine '$VirtualMachineName'..."
        }
        catch {
            [System.Exception]$ProcessException = $_.Exception
            while ($null -ne $ProcessException) {
                if (($ProcessException -is [System.ComponentModel.Win32Exception]) -and ($ProcessException.NativeErrorCode -eq 1223)) {
                    Write-Line 'Hyper-V VM creation was cancelled at the administrator approval prompt.' -Type Warning
                    return
                }
                $ProcessException = $ProcessException.InnerException
            }
            throw
        }

        # VALIDATION - ELEVATED RESULT
        [System.String[]]$ElevatedResultLines = if (Test-Path -LiteralPath $ResultFilePath -PathType Leaf) { @(Get-Content -LiteralPath $ResultFilePath) } else { @() }
        [System.String]$ElevatedResult = if ($ElevatedResultLines.Count -gt 0) { $ElevatedResultLines[0].Trim() } else { [System.String]::Empty }
        if ($ElevatedExitCode -eq 3 -or $ElevatedResult -eq 'CANCELLED') {
            Write-Line 'Hyper-V VM replacement was cancelled. No changes were made.' -Type Warning
            return
        }

        if ($ElevatedExitCode -ne 0) {
            [System.String]$ElevatedError = if (Test-Path -LiteralPath $ResultFilePath -PathType Leaf) { (Get-Content -LiteralPath $ResultFilePath -Raw).Trim() } else { [System.String]::Empty }
            if ([System.String]::IsNullOrWhiteSpace($ElevatedError)) {
                throw "The elevated Hyper-V VM creation failed with exit code $ElevatedExitCode."
            }
            throw "The elevated Hyper-V VM creation failed: $ElevatedError"
        }

        # POST-EXECUTION - SUCCESS
        Write-Line "Created Hyper-V virtual machine '$VirtualMachineName' with generation $Generation." -Type Success
        [System.String[]]$FreshVirtualMachineInventory = if ($ElevatedResultLines.Count -gt 1) { $ElevatedResultLines[1..($ElevatedResultLines.Count - 1)] } else { @() }
        Update-HyperVManagementVirtualMachineSelector -VirtualMachineName $VirtualMachineName -VirtualMachineInventory $FreshVirtualMachineInventory
        Open-Folder -Path $VirtualMachineFolder
    }
    catch {
        if ($null -ne $CreatedVirtualMachine) {
            try {
                Remove-VM -VM $CreatedVirtualMachine -Force -ErrorAction Stop
                Write-Line "Removed the partially created virtual machine '$VirtualMachineName' after the creation step failed." -Type Warning
            }
            catch {
                Write-Line "The virtual machine '$VirtualMachineName' may be partially created and could not be removed automatically." -Type Error
            }
        }
        Write-ErrorReport -ErrorRecord $_
    }
    finally {
        # POST-EXECUTION - TEMPORARY RESULT CLEANUP
        if ($null -ne $ResultFilePath) {
            Remove-Item -LiteralPath $ResultFilePath -Force -ErrorAction SilentlyContinue
        }
    }
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Removes the virtual machine selected in the Hyper-V management selector.
.DESCRIPTION
    Stops the selected VM if running, removes its VM configuration, deletes its virtual hard disk file(s), and permanently deletes the VM's own folder through an elevated worker.
.EXAMPLE
    Remove-HyperVVirtualMachine
.OUTPUTS
    No objects are returned to the pipeline.
#>
####################################################################################################
function Remove-HyperVVirtualMachine {
    [CmdletBinding()]
    param ()

    [System.String]$ResultFilePath = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath ('ADA-HyperV-Remove-' + [System.Guid]::NewGuid().ToString('N') + '.result')

    try {
        # VALIDATION - SELECTED VIRTUAL MACHINE
        if ($null -eq $Global:HyperVManagementVirtualMachineComboBox) {
            Write-Line 'The virtual machine selector is not available.' -Type Warning
            return
        }
        [System.String]$SelectedVirtualMachineName = [System.String]$Global:HyperVManagementVirtualMachineComboBox.Text
        if ([System.String]::IsNullOrWhiteSpace($SelectedVirtualMachineName) -or $SelectedVirtualMachineName -eq '(No Virtual Machines Found)') {
            Write-Line 'No virtual machine is selected.' -Type Warning
            return
        }

        # VALIDATION - USER CONFIRMATION
        [System.Boolean]$UserHasConfirmed = Get-UserConfirmation -Title 'Confirm Remove Hyper-V Virtual Machine' -Body "This will stop '$SelectedVirtualMachineName' if it is running, remove its VM configuration, delete its virtual hard disk file(s), and permanently delete its virtual machine folder.`n`nThis cannot be undone. Do you want to continue?" -Type Warning
        if (-not $UserHasConfirmed) { return }

        # PREPARATION - ELEVATED SCRIPT
        [System.String]$EscapedResultFilePath = $ResultFilePath.Replace("'", "''")
        [System.String]$EscapedVirtualMachineName = $SelectedVirtualMachineName.Replace("'", "''")
        [System.String]$ElevatedScript = @"
`$ErrorActionPreference = 'Stop'
Import-Module Hyper-V -ErrorAction Stop
try {
    `$VirtualMachine = Get-VM -Name '$EscapedVirtualMachineName' -ErrorAction Stop
    `$VirtualMachineFolder = [System.String]`$VirtualMachine.Path
    `$VirtualMachineParentFolder = Split-Path -Path `$VirtualMachineFolder -Parent
    `$HardDiskPaths = @(Get-VMHardDiskDrive -VM `$VirtualMachine -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Path)
    if (`$VirtualMachine.State -ne 'Off') {
        Stop-VM -VM `$VirtualMachine -TurnOff -Force -ErrorAction Stop
    }
    Remove-VM -VM `$VirtualMachine -Force -ErrorAction Stop
    foreach (`$HardDiskPath in `$HardDiskPaths) {
        if ((-not [System.String]::IsNullOrWhiteSpace(`$HardDiskPath)) -and (Test-Path -LiteralPath `$HardDiskPath -PathType Leaf)) {
            Remove-Item -LiteralPath `$HardDiskPath -Force -ErrorAction Stop
        }
    }
    function Test-IsPathSafeToRemove {
        param ([System.String]`$FolderPath)
        if ([System.String]::IsNullOrWhiteSpace(`$FolderPath) -or -not (Test-Path -LiteralPath `$FolderPath -PathType Container)) { return `$false }
        `$FolderPathRoot = [System.IO.Path]::GetPathRoot(`$FolderPath)
        return -not [System.String]::Equals(`$FolderPath.TrimEnd('\'), `$FolderPathRoot.TrimEnd('\'), [System.StringComparison]::OrdinalIgnoreCase)
    }
    if (Test-IsPathSafeToRemove -FolderPath `$VirtualMachineFolder) {
        Remove-Item -LiteralPath `$VirtualMachineFolder -Recurse -Force -ErrorAction Stop
    }
    # Also remove the user-selected parent VM folder once it no longer contains any files
    if ((Test-IsPathSafeToRemove -FolderPath `$VirtualMachineParentFolder) -and (`$null -eq (Get-ChildItem -LiteralPath `$VirtualMachineParentFolder -Force -ErrorAction SilentlyContinue))) {
        Remove-Item -LiteralPath `$VirtualMachineParentFolder -Recurse -Force -ErrorAction Stop
    }
    `$FreshVirtualMachineNames = @(Get-VM -ErrorAction SilentlyContinue | Sort-Object -Property Name | ForEach-Object { [System.String]`$_.Name })
    [System.IO.File]::WriteAllLines('$EscapedResultFilePath', (@('SUCCESS') + `$FreshVirtualMachineNames))
    exit 0
}
catch {
    [System.IO.File]::WriteAllText('$EscapedResultFilePath', ((`$_ | Out-String).Trim()))
    exit 1
}
"@

        # EXECUTION - ELEVATED REMOVAL
        Write-Line 'Waiting for administrator approval...' -Type Busy
        try {
            [System.Int32]$ElevatedExitCode = Invoke-ElevatedPowerShell -Script $ElevatedScript -StartFailureMessage 'The elevated Hyper-V removal process could not be started.' -PostApprovalMessage "Removing Hyper-V virtual machine '$SelectedVirtualMachineName'..."
        }
        catch {
            [System.Exception]$ProcessException = $_.Exception
            while ($null -ne $ProcessException) {
                if (($ProcessException -is [System.ComponentModel.Win32Exception]) -and ($ProcessException.NativeErrorCode -eq 1223)) {
                    Write-Line 'Hyper-V VM removal was cancelled at the administrator approval prompt.' -Type Warning
                    return
                }
                $ProcessException = $ProcessException.InnerException
            }
            throw
        }

        # VALIDATION - ELEVATED RESULT
        [System.String[]]$ElevatedResultLines = if (Test-Path -LiteralPath $ResultFilePath -PathType Leaf) { @(Get-Content -LiteralPath $ResultFilePath) } else { @() }
        [System.String]$ElevatedResult = if ($ElevatedResultLines.Count -gt 0) { $ElevatedResultLines[0].Trim() } else { [System.String]::Empty }
        if ($ElevatedExitCode -ne 0) {
            [System.String]$ElevatedError = if (Test-Path -LiteralPath $ResultFilePath -PathType Leaf) { (Get-Content -LiteralPath $ResultFilePath -Raw).Trim() } else { [System.String]::Empty }
            if ([System.String]::IsNullOrWhiteSpace($ElevatedError)) {
                throw "The elevated Hyper-V VM removal failed with exit code $ElevatedExitCode."
            }
            throw "The elevated Hyper-V VM removal failed: $ElevatedError"
        }

        # POST-EXECUTION - SUCCESS
        Write-Line "Removed Hyper-V virtual machine '$SelectedVirtualMachineName' and its virtual machine folder." -Type Success
        $Global:HyperVManagementVirtualMachineComboBox.SelectedIndex = -1
        [System.String[]]$FreshVirtualMachineInventory = if ($ElevatedResultLines.Count -gt 1) { $ElevatedResultLines[1..($ElevatedResultLines.Count - 1)] } else { @() }
        Update-HyperVManagementVirtualMachineSelector -VirtualMachineInventory $FreshVirtualMachineInventory
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
    finally {
        Remove-Item -LiteralPath $ResultFilePath -Force -ErrorAction SilentlyContinue
    }
}

### END OF FUNCTION
####################################################################################################


