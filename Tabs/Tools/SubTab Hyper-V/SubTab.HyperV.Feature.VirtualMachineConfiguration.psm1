####################################################################################################
<#
.SYNOPSIS
    Imports the virtual machine configuration feature into the Hyper-V sub-tab.
.DESCRIPTION
    Creates grouped location, hardware, configuration, security, and future action controls used to describe a new virtual machine. Hyper-V creation logic is intentionally not included.
.EXAMPLE
    Import-FeatureHyperVVirtualMachineConfiguration -InputObject $MyApplicationObject -ParentTabPage $MyTabPage
.INPUTS
    [PSCustomObject]
    [System.Windows.Forms.TabPage]
.OUTPUTS
    [System.Windows.Forms.GroupBox]
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.4.0
    Author          : Imraan Iotana
    Creation Date   : August 2026
    Last Update     : August 2026
#>
####################################################################################################
function Import-FeatureHyperVVirtualMachineConfiguration {
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
        [System.Collections.Hashtable]$LocationGroupBoxProperties = @{
            InputObject   = $InputObject
            ParentTabPage = $ParentTabPage
            Title         = 'VIRTUAL MACHINE LOCATION'
            Color         = $Color
            NumberOfRows  = 3
            GroupBoxAbove = $GroupBoxAbove
        }
        [System.Collections.Hashtable]$HardwareGroupBoxProperties = @{
            InputObject   = $InputObject
            ParentTabPage = $ParentTabPage
            Title         = 'VIRTUAL MACHINE HARDWARE'
            Color         = $Color
            NumberOfRows  = 3
        }
        [System.Collections.Hashtable]$ConfigurationGroupBoxProperties = @{
            InputObject   = $InputObject
            ParentTabPage = $ParentTabPage
            Title         = 'VIRTUAL MACHINE CONFIGURATION'
            Color         = $Color
            NumberOfRows  = 6.5
        }
        [System.Collections.Hashtable]$SelectionGroupBoxProperties = @{
            InputObject   = $InputObject
            ParentTabPage = $ParentTabPage
            Title         = 'VIRTUAL MACHINE SELECTION'
            Color         = $Color
            NumberOfRows  = 2
        }

        # EXECUTION - GROUPBOXES
        [System.Windows.Forms.GroupBox]$LocationGroupBox = New-GroupBox @LocationGroupBoxProperties
        $HardwareGroupBoxProperties.GroupBoxAbove = $LocationGroupBox
        [System.Windows.Forms.GroupBox]$HardwareGroupBox = New-GroupBox @HardwareGroupBoxProperties
        $ConfigurationGroupBoxProperties.GroupBoxAbove = $HardwareGroupBox
        [System.Windows.Forms.GroupBox]$ConfigurationGroupBox = New-GroupBox @ConfigurationGroupBoxProperties
        $SelectionGroupBoxProperties.GroupBoxAbove = $ConfigurationGroupBox
        [System.Windows.Forms.GroupBox]$SelectionGroupBox = New-GroupBox @SelectionGroupBoxProperties

        # PREPARATION - TEXTBOX PROPERTIES
        [System.Collections.Hashtable]$VirtualMachineNameTextBoxProperties = @{
            RowNumber    = 1
            Label        = 'Virtual Machine Name'
            PropertyName = 'HyperVVirtualMachineName'
            ToolTip      = 'Enter the name of the new virtual machine.'
            SizeType     = 'Medium'
            SmallButtons = @(@(5,'Copy'),@(6,'Paste'),@(7,'Clear'))
        }
        [System.Collections.Hashtable]$VirtualMachineFolderTextBoxProperties = @{
            RowNumber    = 2
            Label        = 'Virtual Machine Folder'
            PropertyName = 'HyperVVirtualMachineFolder'
            ToolTip      = 'Select the parent folder where the virtual machine will be stored.'
            SizeType     = 'Medium'
            SmallButtons = @(@(5,'Browse Folder'),@(6,'Paste'),@(7,'Open'))
        }
        [System.Collections.Hashtable]$WindowsIsoTextBoxProperties = @{
            RowNumber    = 3
            Label        = 'Windows Installation ISO'
            PropertyName = 'HyperVWindowsIsoPath'
            ToolTip      = 'Select the Windows 11 installation ISO file.'
            SizeType     = 'Medium'
            SmallButtons = @(@(5,'Browse File','Other'),@(6,'Paste'),@(7,'Open'))
        }

        # PREPARATION - COMBOBOX PROPERTIES
        [System.Collections.Hashtable]$VirtualHardDiskSizeComboBoxProperties = @{
            RowNumber          = 1
            Label              = 'Virtual Hard Disk Size (GB)'
            PropertyName       = 'HyperVVirtualHardDiskSizeGB'
            ToolTip            = 'Enter or select the maximum virtual hard disk size in gigabytes.'
            SizeType           = 'Medium'
            Type               = 'Input'
            DefaultValue       = '60'
            ContentStringArray = @('40','60','80','100','127')
            SmallButtons       = (, @(5,'Default'))
        }
        [System.Collections.Hashtable]$StartupMemoryComboBoxProperties = @{
            RowNumber          = 2
            Label              = 'Startup Memory (MB)'
            PropertyName       = 'HyperVStartupMemoryMB'
            ToolTip            = 'Enter or select the startup memory in megabytes.'
            SizeType           = 'Medium'
            Type               = 'Input'
            DefaultValue       = '4096'
            ContentStringArray = @('2048','4096','8192','16384')
            SmallButtons       = (, @(5,'Default'))
        }
        [System.Collections.Hashtable]$ProcessorCountComboBoxProperties = @{
            RowNumber          = 3
            Label              = 'Processor Count'
            PropertyName       = 'HyperVProcessorCount'
            ToolTip            = 'Enter or select the number of virtual processors.'
            SizeType           = 'Medium'
            Type               = 'Input'
            DefaultValue       = '2'
            ContentStringArray = @('1','2','4','8')
            SmallButtons       = (, @(5,'Default'))
        }
        [System.Collections.Hashtable]$VirtualSwitchComboBoxProperties = @{
            RowNumber          = 1
            Label              = 'Virtual Switch'
            PropertyName       = 'HyperVVirtualSwitch'
            ToolTip            = 'Select a host virtual switch, or choose (Not Connected) to create the virtual machine without network connectivity.'
            SizeType           = 'Medium'
            Type               = 'Output'
            DefaultValue       = 'Default Switch'
            ContentStringArray = @(Get-HyperVVirtualSwitchOptions)
            SmallButtons       = (, @(5,'Default'))
        }
        [System.Collections.Hashtable]$GenerationComboBoxProperties = @{
            RowNumber          = 2
            Label              = 'Generation'
            PropertyName       = 'HyperVGeneration'
            ToolTip            = 'Generation 2 is recommended for Windows 11 because it supports Secure Boot and virtual TPM. Generation 1 is available for other guest operating systems.'
            SizeType           = 'Medium'
            Type               = 'Output'
            DefaultValue       = 'Generation 2'
            ContentStringArray = @('Generation 1','Generation 2')
            SmallButtons       = (, @(5,'Default'))
        }
        [System.Collections.Hashtable]$SecureBootComboBoxProperties = @{
            RowNumber          = 3
            Label              = 'Secure Boot'
            PropertyName       = 'HyperVSecureBoot'
            ToolTip            = 'Select whether Secure Boot will be enabled for the Windows 11 virtual machine.'
            SizeType           = 'Medium'
            Type               = 'Output'
            DefaultValue       = 'Enabled'
            ContentStringArray = @('Enabled','Disabled')
            SmallButtons       = (, @(5,'Default'))
        }
        [System.Collections.Hashtable]$VirtualTpmComboBoxProperties = @{
            RowNumber          = 4
            Label              = 'Virtual TPM'
            PropertyName       = 'HyperVVirtualTPM'
            ToolTip            = 'Select whether a virtual Trusted Platform Module will be enabled.'
            SizeType           = 'Medium'
            Type               = 'Output'
            DefaultValue       = 'Enabled'
            ContentStringArray = @('Enabled','Disabled')
            SmallButtons       = (, @(5,'Default'))
        }
        [System.Collections.Hashtable]$EncryptStateAndMigrationComboBoxProperties = @{
            RowNumber          = 5
            Label              = 'Encrypt VM State / Migration'
            PropertyName       = 'HyperVEncryptStateAndMigrationTraffic'
            ToolTip            = 'Select whether virtual machine state and migration traffic will be encrypted.'
            SizeType           = 'Medium'
            Type               = 'Output'
            DefaultValue       = 'Enabled'
            ContentStringArray = @('Enabled','Disabled')
            SmallButtons       = (, @(5,'Default'))
        }
        [System.Collections.Hashtable]$StartAfterCreationComboBoxProperties = @{
            RowNumber          = 6
            Label              = 'Start VM After Creation'
            PropertyName       = 'HyperVStartAfterCreation'
            ToolTip            = 'Select whether the virtual machine will be started after all configuration steps have completed.'
            SizeType           = 'Medium'
            Type               = 'Output'
            DefaultValue       = 'No'
            ContentStringArray = @('Yes','No')
            SmallButtons       = (, @(5,'Default'))
        }

        # EXECUTION - CONTROLS
        [System.Windows.Forms.TextBox]$VirtualMachineNameTextBox = New-TextBox @VirtualMachineNameTextBoxProperties -InputObject $InputObject -ParentGroupBox $LocationGroupBox -ReturnTextBox
        [System.Windows.Forms.TextBox]$VirtualMachineFolderTextBox = New-TextBox @VirtualMachineFolderTextBoxProperties -InputObject $InputObject -ParentGroupBox $LocationGroupBox -ReturnTextBox
        [System.Windows.Forms.TextBox]$WindowsIsoTextBox = New-TextBox @WindowsIsoTextBoxProperties -InputObject $InputObject -ParentGroupBox $LocationGroupBox -ReturnTextBox
        [System.Windows.Forms.ComboBox]$VirtualHardDiskSizeComboBox = New-ComboBox @VirtualHardDiskSizeComboBoxProperties -InputObject $InputObject -ParentGroupBox $HardwareGroupBox -ReturnComboBox
        [System.Windows.Forms.ComboBox]$StartupMemoryComboBox = New-ComboBox @StartupMemoryComboBoxProperties -InputObject $InputObject -ParentGroupBox $HardwareGroupBox -ReturnComboBox
        [System.Windows.Forms.ComboBox]$ProcessorCountComboBox = New-ComboBox @ProcessorCountComboBoxProperties -InputObject $InputObject -ParentGroupBox $HardwareGroupBox -ReturnComboBox
        [System.Windows.Forms.ComboBox]$VirtualSwitchComboBox = New-ComboBox @VirtualSwitchComboBoxProperties -InputObject $InputObject -ParentGroupBox $ConfigurationGroupBox -ReturnComboBox
        [System.Windows.Forms.ComboBox]$GenerationComboBox = New-ComboBox @GenerationComboBoxProperties -InputObject $InputObject -ParentGroupBox $ConfigurationGroupBox -ReturnComboBox
        [System.Windows.Forms.ComboBox]$SecureBootComboBox = New-ComboBox @SecureBootComboBoxProperties -InputObject $InputObject -ParentGroupBox $ConfigurationGroupBox -ReturnComboBox
        [System.Windows.Forms.ComboBox]$VirtualTpmComboBox = New-ComboBox @VirtualTpmComboBoxProperties -InputObject $InputObject -ParentGroupBox $ConfigurationGroupBox -ReturnComboBox
        [System.Windows.Forms.ComboBox]$EncryptStateAndMigrationComboBox = New-ComboBox @EncryptStateAndMigrationComboBoxProperties -InputObject $InputObject -ParentGroupBox $ConfigurationGroupBox -ReturnComboBox
        [System.Windows.Forms.ComboBox]$StartAfterCreationComboBox = New-ComboBox @StartAfterCreationComboBoxProperties -InputObject $InputObject -ParentGroupBox $ConfigurationGroupBox -ReturnComboBox

        # PREPARATION - VM SELECTOR PROPERTIES
        [System.Collections.Hashtable]$VirtualMachineComboBoxProperties = @{
            RowNumber          = 1
            Label              = 'Virtual Machine'
            PropertyName       = 'HyperVManagementVirtualMachine'
            ToolTip            = 'Select a registered virtual machine to view it in Hyper-V Manager.'
            SizeType           = 'Medium'
            Type               = 'Output'
            ContentStringArray = @(Get-HyperVVirtualMachineOptions)
        }

        # EXECUTION - VM SELECTOR
        [System.Windows.Forms.ComboBox]$VirtualMachineComboBox = New-ComboBox @VirtualMachineComboBoxProperties -InputObject $InputObject -ParentGroupBox $SelectionGroupBox -ReturnComboBox
        $Global:HyperVManagementVirtualMachineComboBox = $VirtualMachineComboBox

        # PREPARATION - SELECTION BUTTONS
        [System.Collections.Hashtable[]]$SelectionButtons = @(
            @{
                ColumnNumber = 5
                Text         = 'Refresh VMs'
                PNGFileName  = 'arrow_refresh'
                SizeType     = 'Small'
                ToolTip      = 'Refresh the list of registered virtual machines.'
                Function     = { Update-HyperVManagementVirtualMachineSelector }.GetNewClosure()
            }
            @{
                ColumnNumber = 6
                Text         = 'Show Details'
                PNGFileName  = 'information'
                SizeType     = 'Small'
                ToolTip      = 'Show details for the selected virtual machine.'
                Function     = { Show-HyperVSelectedVirtualMachineDetails }.GetNewClosure()
            }
        )
        New-ButtonLine -InputObject $InputObject -ButtonPropertiesArray $SelectionButtons -ParentGroupBox $SelectionGroupBox -RowNumber 1

        # PREPARATION - REMOVE VM BUTTON
        [System.Collections.Hashtable[]]$RemovalButtons = @(
            @{
                ColumnNumber = 1
                Text         = 'Remove VM'
                PNGFileName  = 'package_delete'
                SizeType     = 'Medium'
                ToolTip      = 'Remove the selected virtual machine, its virtual hard disk file(s), and its virtual machine folder.'
                Function     = { Remove-HyperVVirtualMachine }.GetNewClosure()
            }
        )
        New-ButtonLine -InputObject $InputObject -ButtonPropertiesArray $RemovalButtons -ParentGroupBox $SelectionGroupBox -RowNumber 2

        [System.Windows.Forms.TextBox[]]$HyperVTextBoxes = @($VirtualMachineNameTextBox,$VirtualMachineFolderTextBox,$WindowsIsoTextBox)
        [System.Windows.Forms.ComboBox[]]$HyperVComboBoxes = @($VirtualHardDiskSizeComboBox,$StartupMemoryComboBox,$ProcessorCountComboBox,$VirtualSwitchComboBox,$GenerationComboBox,$SecureBootComboBox,$VirtualTpmComboBox,$EncryptStateAndMigrationComboBox,$StartAfterCreationComboBox)

        # PREPARATION - UI-ONLY ACTION BUTTONS
        [System.Collections.Hashtable[]]$ActionButtons = @(
            @{
                ColumnNumber = 1
                Text         = 'Validate Configuration'
                PNGFileName  = 'check_box'
                SizeType     = 'Large'
                ToolTip      = 'Validate the Hyper-V configuration without creating or changing a virtual machine.'
                Function     = {
                    Test-HyperVConfiguration `
                        -VirtualMachineName $VirtualMachineNameTextBox.Text `
                        -VirtualMachineFolder $VirtualMachineFolderTextBox.Text `
                        -WindowsIsoPath $WindowsIsoTextBox.Text `
                        -VirtualHardDiskSizeGB $VirtualHardDiskSizeComboBox.Text `
                        -StartupMemoryMB $StartupMemoryComboBox.Text `
                        -ProcessorCount $ProcessorCountComboBox.Text `
                        -VirtualSwitch $VirtualSwitchComboBox.Text `
                        -Generation $GenerationComboBox.Text `
                        -SecureBoot $SecureBootComboBox.Text `
                        -VirtualTPM $VirtualTpmComboBox.Text
                }.GetNewClosure()
            }
            @{
                ColumnNumber = 2
                Text         = 'Create Virtual Machine'
                PNGFileName  = 'computer_go'
                SizeType     = 'Large'
                ToolTip      = 'Create the VM shell, VHDX, memory, processors, generation, and selected switch. ISO and security setup are separate steps.'
                Function     = {
                    if (-not (Test-HyperVConfiguration `
                            -VirtualMachineName $VirtualMachineNameTextBox.Text `
                            -VirtualMachineFolder $VirtualMachineFolderTextBox.Text `
                            -WindowsIsoPath $WindowsIsoTextBox.Text `
                            -VirtualHardDiskSizeGB $VirtualHardDiskSizeComboBox.Text `
                            -StartupMemoryMB $StartupMemoryComboBox.Text `
                            -ProcessorCount $ProcessorCountComboBox.Text `
                            -VirtualSwitch $VirtualSwitchComboBox.Text `
                            -Generation $GenerationComboBox.Text `
                            -SecureBoot $SecureBootComboBox.Text `
                            -VirtualTPM $VirtualTpmComboBox.Text)) { return }

                    [System.Boolean]$ReplaceExisting = $false
                    [System.String]$ConfirmationTitle = 'Confirm Create Hyper-V Virtual Machine'
                    [System.String]$ConfirmationBody = "This will create the VM shell and VHDX for '$($VirtualMachineNameTextBox.Text)'. The ISO, security settings, and VM startup will be handled in later steps. Do you want to continue?"
                    $ExistingVirtualMachine = Get-VM -Name $VirtualMachineNameTextBox.Text -ErrorAction SilentlyContinue
                    if ($null -ne $ExistingVirtualMachine) {
                        $ReplaceExisting = $true
                        $ConfirmationTitle = 'Confirm Replace Hyper-V Virtual Machine'
                        $ConfirmationBody = "A virtual machine named '$($VirtualMachineNameTextBox.Text)' already exists.`n`nReplacing it will stop it if necessary, remove its VM configuration, remove its VHDX at the configured path, and create a new VM with the current settings.`n`nDo you want to continue?"
                    }

                    [System.Boolean]$UserHasConfirmed = Get-UserConfirmation -Title $ConfirmationTitle -Body $ConfirmationBody -Type Warning
                    if (-not $UserHasConfirmed) { return }

                    New-HyperVVirtualMachineCore `
                        -VirtualMachineName $VirtualMachineNameTextBox.Text `
                        -VirtualMachineFolder $VirtualMachineFolderTextBox.Text `
                        -WindowsIsoPath $WindowsIsoTextBox.Text `
                        -VirtualHardDiskSizeGB $VirtualHardDiskSizeComboBox.Text `
                        -StartupMemoryMB $StartupMemoryComboBox.Text `
                        -ProcessorCount $ProcessorCountComboBox.Text `
                        -Generation $GenerationComboBox.Text `
                        -VirtualSwitch $VirtualSwitchComboBox.Text `
                        -SecureBoot $SecureBootComboBox.Text `
                        -VirtualTPM $VirtualTpmComboBox.Text `
                        -ReplaceExisting:$ReplaceExisting
                }.GetNewClosure()
            }
                @{
                    ColumnNumber = 3
                    Text         = 'Open Hyper-V Manager'
                    PNGFileName  = 'computer'
                    SizeType     = 'Large'
                    ToolTip      = 'Open the standard Hyper-V Manager console.'
                    Function     = {
                        Open-HyperVManager
                    }.GetNewClosure()
                }
            @{
                ColumnNumber = 5
                Text         = 'Clear Fields'
                PNGFileName  = 'textfield_delete'
                SizeType     = 'Large'
                ToolTip      = 'Clear the virtual machine name, folder, and Windows ISO fields after one confirmation.'
                Function     = {
                    [System.Boolean]$UserHasConfirmed = Get-UserConfirmation -Title 'Confirm Clear Hyper-V Text Fields' -Body 'This will clear the virtual machine name, folder, and Windows ISO fields. Do you want to continue?'
                    if (-not $UserHasConfirmed) { return }

                    foreach ($TextBox in $HyperVTextBoxes) {
                        Clear-TextBox -TextBox $TextBox -Force
                    }
                }.GetNewClosure()
            }
            @{
                ColumnNumber = 4
                Text         = 'Reset All Defaults'
                PNGFileName  = 'arrow_undo'
                SizeType     = 'Large'
                ToolTip      = 'Reset all Hyper-V combo boxes to their configured default values after one confirmation.'
                Function     = {
                    [System.Boolean]$UserHasConfirmed = Get-UserConfirmation -Title 'Confirm Reset Hyper-V Combo Boxes' -Body 'This will reset all Hyper-V combo boxes to their default values. Do you want to continue?'
                    if (-not $UserHasConfirmed) { return }

                    foreach ($ComboBox in $HyperVComboBoxes) {
                        Reset-ComboBox -ComboBox $ComboBox -Force
                    }
                }.GetNewClosure()
            }
        )

        # EXECUTION - UI-ONLY ACTION BUTTONS
    New-ButtonLine -InputObject $InputObject -ButtonPropertiesArray $ActionButtons -ParentGroupBox $ConfigurationGroupBox -RowNumber 7

        # OUTPUT
    $SelectionGroupBox
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}

### END OF FUNCTION
####################################################################################################


