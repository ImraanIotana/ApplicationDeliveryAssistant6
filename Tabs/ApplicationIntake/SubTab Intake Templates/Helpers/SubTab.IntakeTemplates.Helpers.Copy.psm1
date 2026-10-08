####################################################################################################
<#
.SYNOPSIS
    Copies customer template bundles into the current user's roaming template folder.
.DESCRIPTION
    Provides the name prompt, staged bundle copy, manifest update, validation, and ListView action
    used by the Customer Templates management interface.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.9.0
    Author          : Imraan Iotana
    Creation Date   : August 2026
    Last Update     : October 2026
#>
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Prompts for the identity of a copied customer template.
.DESCRIPTION
    Displays a modal dialog that lets the user review or change the identity assigned to a copied
    customer template. The supplied default identity is selected when the dialog opens.
.EXAMPLE
    Read-CustomerTemplateCopyIdentity -DefaultIdentity 'ADA Default Copy' -Owner $MainForm
    Prompts for a new customer template identity with the main form as the owner.
.INPUTS
    [System.String]
    [System.Windows.Forms.IWin32Window]
.OUTPUTS
    [System.String] when confirmed; otherwise no object is returned.
#>
####################################################################################################
function Read-CustomerTemplateCopyIdentity {
    [CmdletBinding()]
    [OutputType([System.String])]
    param (
        [Parameter(Mandatory=$false,HelpMessage='Initial value shown in the template name field.')]
        [System.String]$DefaultIdentity,

        [Parameter(Mandatory=$false,HelpMessage='Optional window that will own the template name dialog.')]
        [AllowNull()]
        [System.Windows.Forms.IWin32Window]$Owner
    )

    # PREPARATION - DIALOG
    # Create the modal dialog and its prompt, input, and action controls
    [System.Windows.Forms.Form]$Dialog = New-ModalDialog -Title 'Copy Customer Template' -ClientWidth 430 -ClientHeight 145 -Owner $Owner
    [System.Windows.Forms.Label]$PromptLabel = New-Object System.Windows.Forms.Label
    [System.Windows.Forms.TextBox]$IdentityTextBox = New-Object System.Windows.Forms.TextBox

    try {
        [PSCustomObject]$DialogActions = New-ModalDialogActionBar -Dialog $Dialog -PrimaryText 'Copy' -PrimaryDialogResult ([System.Windows.Forms.DialogResult]::OK) -ButtonWidth 75 -ButtonHeight 28
        # PREPARATION - IDENTITY CONTROLS
        # Configure the prompt and prepopulate the identity input with the suggested copy name
        $PromptLabel.Text = 'Enter a name for the new customer template:'
        $PromptLabel.Location = New-Object System.Drawing.Point(15,15)
        $PromptLabel.Size = New-Object System.Drawing.Size(400,22)

        $IdentityTextBox.Text = [System.String]$DefaultIdentity
        $IdentityTextBox.Location = New-Object System.Drawing.Point(15,42)
        $IdentityTextBox.Size = New-Object System.Drawing.Size(400,24)

        # EXECUTION - BUILD THE DIALOG
        # Add the controls and configure the default dialog actions
        $Dialog.Controls.AddRange(@($PromptLabel,$IdentityTextBox))
        # Select the suggested identity when the dialog is first displayed
        $Dialog.Add_Shown({
            $IdentityTextBox.SelectAll()
            $IdentityTextBox.Focus()
        }.GetNewClosure())

        # EXECUTION - SHOW THE DIALOG
        # Stop when the user cancels the copy-name prompt
        if ((Show-ModalDialog -Dialog $Dialog -Owner $Owner) -ne [System.Windows.Forms.DialogResult]::OK) {
            return
        }

        # VALIDATION - IDENTITY
        # Trim and validate the confirmed customer template identity
        [System.String]$Identity = $IdentityTextBox.Text.Trim()
        if ([System.String]::IsNullOrWhiteSpace($Identity)) {
            Write-Line 'The customer template name is empty. No template was copied.' -Type Warning
            return
        }

        # OUTPUT
        # Return the confirmed customer template identity
        return $Identity
    }
    finally {
        # POST-EXECUTION - DIALOG CLEANUP
        # Dispose the temporary modal dialog
        $Dialog.Dispose()
    }
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Copies a customer template bundle into roaming Application Data.
.DESCRIPTION
    Copies into a staging folder, updates the manifest identity and TemplateId, validates the
    normalized data, and publishes the bundle only after validation succeeds.
.EXAMPLE
    Copy-CustomerTemplateToUserStorage -CustomerTemplate $Template -NewIdentity 'Contoso Default'
    Copies the selected customer template into the current user's roaming template storage.
.INPUTS
    [System.Object]
    [System.String]
.OUTPUTS
    [PSCustomObject] describing the copied customer template.
#>
####################################################################################################
function Copy-CustomerTemplateToUserStorage {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The discovered customer template object to copy.')]
        [System.Object]$CustomerTemplate,

        [Parameter(Mandatory=$true,HelpMessage='Identity assigned to the copied customer template.')]
        [System.String]$NewIdentity,

        [Parameter(Mandatory=$false,HelpMessage='Optional destination root used for focused validation.')]
        [System.String]$DestinationRoot
    )

    # PREPARATION
    # Initialize the staging-folder path for transactional cleanup
    [System.String]$StagingFolder = ''
    try {
        # VALIDATION - COPY INPUT
        # Normalize the requested identity and verify that the source manifest exists
        [System.String]$ResolvedIdentity = $NewIdentity.Trim()
        if ([System.String]::IsNullOrWhiteSpace($ResolvedIdentity)) {
            throw 'The new customer template identity is empty.'
        }
        if ($null -eq $CustomerTemplate -or -not (Test-Path -LiteralPath ([System.String]$CustomerTemplate.TemplatePath) -PathType Leaf)) {
            throw 'The selected customer template manifest does not exist.'
        }

        # PREPARATION - DESTINATION ROOT
        # Resolve the default roaming destination or create the explicit validation destination
        if ([System.String]::IsNullOrWhiteSpace($DestinationRoot)) {
            $DestinationRoot = (Get-CustomerTemplateStoragePaths -Create).CustomerTemplatesRoot
        }
        elseif (-not (Test-Path -LiteralPath $DestinationRoot -PathType Container)) {
            New-Item -Path $DestinationRoot -ItemType Directory -Force -ErrorAction Stop | Out-Null
        }

        # PREPARATION - DESTINATION NAMES
        # Convert the requested identity into valid folder and manifest name components
        [System.String]$FolderName = $ResolvedIdentity
        foreach ($InvalidCharacter in [System.IO.Path]::GetInvalidFileNameChars()) {
            $FolderName = $FolderName.Replace($InvalidCharacter,'_')
        }
        $FolderName = $FolderName.Trim().TrimEnd('.').TrimEnd()
        [System.String]$ManifestNameStem = $ResolvedIdentity -replace '[^A-Za-z0-9_-]',''
        if ([System.String]::IsNullOrWhiteSpace($FolderName) -or [System.String]::IsNullOrWhiteSpace($ManifestNameStem)) {
            throw 'The new customer template name does not contain a valid folder or file name.'
        }

        # VALIDATION - DESTINATION
        # Prevent an existing customer template folder from being overwritten
        [System.String]$DestinationFolder = Join-Path -Path $DestinationRoot -ChildPath $FolderName
        if (Test-Path -LiteralPath $DestinationFolder) {
            throw "A customer template folder with this name already exists. ($DestinationFolder)"
        }

        # EXECUTION - STAGE THE TEMPLATE BUNDLE
        # Copy the complete source bundle into a uniquely named partial folder
        [System.String]$TransactionId = [System.Guid]::NewGuid().ToString('N')
        $StagingFolder = Join-Path -Path $DestinationRoot -ChildPath ('.' + $FolderName + '.partial-' + $TransactionId)
        New-Item -Path $StagingFolder -ItemType Directory -ErrorAction Stop | Out-Null
        Get-ChildItem -LiteralPath ([System.String]$CustomerTemplate.Directory) -Force | ForEach-Object {
            Copy-Item -LiteralPath $_.FullName -Destination $StagingFolder -Recurse -Force -ErrorAction Stop
        }

        # VALIDATION - STAGED MANIFEST
        # Resolve and verify the copied customer template manifest
        [System.String]$CopiedManifestPath = Join-Path -Path $StagingFolder -ChildPath ([System.IO.Path]::GetFileName([System.String]$CustomerTemplate.TemplatePath))
        if (-not (Test-Path -LiteralPath $CopiedManifestPath -PathType Leaf)) {
            throw "The copied customer template manifest could not be found. ($CopiedManifestPath)"
        }

        # EXECUTION - REMOVE SIBLING MANIFESTS
        # A bundle can hold several variants; keep only the copied one so no TemplateId is duplicated
        Get-ChildItem -LiteralPath $StagingFolder -Filter 'Settings.Customer.*.psd1' -File |
            Where-Object { $_.FullName -ne $CopiedManifestPath } |
            Remove-Item -Force -ErrorAction Stop
        # The extension descriptor belongs to the original bundle, not to the copy
        Remove-Item -LiteralPath (Join-Path -Path $StagingFolder -ChildPath 'Extension.psd1') -Force -ErrorAction SilentlyContinue

        # PREPARATION - MANIFEST IDENTITY
        # Read the staged manifest and prepare the escaped identity and new stable template ID
        [System.String]$ManifestText = [System.IO.File]::ReadAllText($CopiedManifestPath)
        [System.String]$EscapedIdentity = $ResolvedIdentity.Replace("'","''")
        [System.String]$NewTemplateId = [System.Guid]::NewGuid().ToString()
        # Locate and replace the required Identity entry
        [System.Text.RegularExpressions.Regex]$IdentityPattern = New-Object System.Text.RegularExpressions.Regex('(?m)^(?<Indent>\s*)Identity\s*=.*$')
        if (-not $IdentityPattern.IsMatch($ManifestText)) {
            throw 'The copied customer template manifest does not define Identity.'
        }
        $ManifestText = $IdentityPattern.Replace($ManifestText,({ param($Match) $Match.Groups['Indent'].Value + "Identity = '$EscapedIdentity'" }),1)

        # EXECUTION - UPDATE THE TEMPLATE ID
        # Replace the existing TemplateId or insert one immediately before Identity for legacy manifests
        [System.Text.RegularExpressions.Regex]$TemplateIdPattern = New-Object System.Text.RegularExpressions.Regex('(?m)^(?<Indent>\s*)TemplateId\s*=.*$')
        if ($TemplateIdPattern.IsMatch($ManifestText)) {
            $ManifestText = $TemplateIdPattern.Replace($ManifestText,({ param($Match) $Match.Groups['Indent'].Value + "TemplateId    = '$NewTemplateId'" }),1)
        }
        else {
            $ManifestText = $IdentityPattern.Replace($ManifestText,({ param($Match) $Match.Groups['Indent'].Value + "TemplateId = '$NewTemplateId'`r`n" + $Match.Value }),1)
        }

        # EXECUTION - WRITE THE RENAMED MANIFEST
        # Save the updated manifest with an identity-based filename and remove the original name
        [System.String]$RenamedManifestPath = Join-Path -Path $StagingFolder -ChildPath ("Settings.Customer.$ManifestNameStem.psd1")
        [System.IO.File]::WriteAllText($RenamedManifestPath,$ManifestText,(New-Object System.Text.UTF8Encoding($false)))
        if (-not $RenamedManifestPath.Equals($CopiedManifestPath,[System.StringComparison]::OrdinalIgnoreCase)) {
            Remove-Item -LiteralPath $CopiedManifestPath -Force -ErrorAction Stop
        }

        # VALIDATION - NORMALIZED TEMPLATE DATA
        # Import the staged bundle and verify its new identity and template ID before publication
        [System.Collections.Hashtable]$ValidatedData = Import-CustomerTemplateData -SettingsFilePath $RenamedManifestPath
        if ([System.String]$ValidatedData.Identity -ne $ResolvedIdentity) {
            throw 'The copied customer template identity could not be validated.'
        }
        if ([System.String]$ValidatedData.TemplateId -ne $NewTemplateId) {
            throw 'The copied customer template ID could not be validated.'
        }

        # EXECUTION - PUBLISH THE TEMPLATE BUNDLE
        # Atomically move the validated staging folder into its final destination
        Move-Item -LiteralPath $StagingFolder -Destination $DestinationFolder -ErrorAction Stop
        $StagingFolder = ''
        # Rediscover the published template through the normal inventory loader
        [System.String]$PublishedManifestPath = Join-Path -Path $DestinationFolder -ChildPath ([System.IO.Path]::GetFileName($RenamedManifestPath))
        [System.Object]$CopiedTemplate = @(Get-CustomerTemplates -FolderToSearch $DestinationRoot | Where-Object { $_.TemplatePath -eq $PublishedManifestPath }) | Select-Object -First 1
        if ($null -eq $CopiedTemplate) {
            throw 'The published customer template could not be rediscovered.'
        }

        # OUTPUT
        # Return the discovered user template to the inventory action
        return $CopiedTemplate
    }
    catch {
        # ERROR HANDLING
        # Report copy or validation failures through the shared error reporter
        Write-ErrorReport -ErrorRecord $_
    }
    finally {
        # POST-EXECUTION - TRANSACTION CLEANUP
        # Remove an unpublished partial folder after any failed copy operation
        if (-not [System.String]::IsNullOrWhiteSpace($StagingFolder) -and (Test-Path -LiteralPath $StagingFolder -PathType Container)) {
            Remove-Item -LiteralPath $StagingFolder -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Copies the selected customer template and refreshes the inventory ListView.
.DESCRIPTION
    Resolves the selected inventory item, prompts for its copied identity, publishes the template
    bundle to roaming storage, and refreshes the inventory with the new template selected.
.EXAMPLE
    Copy-SelectedCustomerTemplate -ListView $CustomerTemplateListView
    Copies the customer template selected in the supplied inventory ListView.
.INPUTS
    [System.Windows.Forms.ListView]
.OUTPUTS
    No objects are returned to the pipeline.
#>
####################################################################################################
function Copy-SelectedCustomerTemplate {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The customer template inventory ListView.')]
        [System.Windows.Forms.ListView]$ListView
    )

    # VALIDATION - INVENTORY SELECTION
    # Require exactly one customer template before starting the copy workflow
    if ($ListView.SelectedItems.Count -ne 1) {
        Write-Line 'Select one customer template to copy.' -Type Warning
        return
    }

    # PREPARATION - COPY IDENTITY
    # Resolve the selected template and use its parent form to own the copy-name dialog
    [System.Object]$SelectedTemplate = $ListView.SelectedItems[0].Tag
    [System.Windows.Forms.Form]$Owner = $ListView.FindForm()
    [System.String]$NewIdentity = Read-CustomerTemplateCopyIdentity -DefaultIdentity (([System.String]$SelectedTemplate.Identity) + ' Copy') -Owner $Owner
    if ([System.String]::IsNullOrWhiteSpace($NewIdentity)) { return }

    # EXECUTION - COPY THE TEMPLATE
    # Publish the selected customer template under the confirmed identity
    [System.Object]$CopiedTemplate = Copy-CustomerTemplateToUserStorage -CustomerTemplate $SelectedTemplate -NewIdentity $NewIdentity
    if ($null -eq $CopiedTemplate) { return }

    # POST-EXECUTION - REFRESH THE INVENTORY
    # Reload the inventory, select the copied template, and report its destination
    Update-CustomerTemplateListView -ListView $ListView -TemplatePathToSelect $CopiedTemplate.TemplatePath
    Write-Line "Customer template copied to: $($CopiedTemplate.Directory)" -Type Success
}

### END OF FUNCTION
####################################################################################################