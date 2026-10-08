####################################################################################################
<#
.SYNOPSIS
    Imports the Application ID feature into the Desktop Application sub-tab.
.DESCRIPTION
    Creates the Application ID group, output textbox, and workflow buttons.
.OUTPUTS
    [System.Windows.Forms.GroupBox]
.NOTES
    Version         : 6.5.0
#>
####################################################################################################
function Import-FeatureIntakeApplicationID {
    [CmdletBinding()]
    [OutputType([System.Windows.Forms.GroupBox])]
    param (
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$InputObject,

        [Parameter(Mandatory=$true)]
        [System.Windows.Forms.TabPage]$ParentTabPage,

        [Parameter(Mandatory=$false)]
        [System.Windows.Forms.GroupBox]$GroupBoxAbove,

        [Parameter(Mandatory=$false)]
        [System.String]$Color
    )

    try {
        [System.Collections.Hashtable]$GroupBoxProperties = @{
            InputObject   = $InputObject
            ParentTabPage = $ParentTabPage
            Title         = 'APPLICATION ID'
            Color         = $Color
            NumberOfRows  = 3
            GroupBoxAbove = $GroupBoxAbove
        }
        [System.Windows.Forms.GroupBox]$FeatureGroupBox = New-GroupBox @GroupBoxProperties

        [System.Collections.Hashtable]$ApplicationIDTextBoxProperties = @{
            RowNumber = 2
            Label     = 'Application ID'
            ToolTip   = 'The ID of the application to intake'
            SizeType  = 'Medium'
            Type      = 'Output'
        }
        [System.Collections.Hashtable]$ApplicationFolderNameTextBoxProperties = @{
            RowNumber = 3
            Label     = 'Application Folder Name'
            ToolTip   = 'The name of the application folder that will be created.'
            SizeType  = 'Medium'
            Type      = 'Input'
        }
        [System.Windows.Forms.TextBox]$ApplicationIDTextBox = New-TextBox @ApplicationIDTextBoxProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ReturnTextBox
        [System.Windows.Forms.TextBox]$ApplicationFolderNameTextBox = New-TextBox @ApplicationFolderNameTextBoxProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox -ReturnTextBox

        [System.Collections.Hashtable]$ApplicationIDButtonProperties = @{
            ColumnNumber = 1
            RowNumber    = 1
            Text         = 'Application ID'
            PNGFileName  = 'download_for_windows'
            SizeType     = 'Medium'
            ToolTip      = 'Generate the Application ID from the current Intake values.'
            Function     = { New-ApplicationIDFromTextBoxes -OutputTextBox $ApplicationIDTextBox -ApplicationFolderNameTextBox $ApplicationFolderNameTextBox }.GetNewClosure()
        }
        [System.Collections.Hashtable]$CustomizeApplicationIDButtonProperties = @{
            ColumnNumber = 5
            RowNumber    = 2
            Text         = 'Customize'
            PNGFileName  = 'textfield_add'
            SizeType     = 'Medium'
            ToolTip      = 'Set optional prefix, postfix, and separator values for the Application Folder Name.'
            Function     = { Show-ApplicationFolderPrefixDialog -ApplicationIDTextBox $ApplicationIDTextBox -ApplicationFolderNameTextBox $ApplicationFolderNameTextBox -Owner $FeatureGroupBox.FindForm() }.GetNewClosure()
        }
        [System.Collections.Hashtable]$CreateFolderButtonProperties = @{
            ColumnNumber = 5
            RowNumber    = 3
            Text         = 'Create Folder'
            PNGFileName  = 'folder_add'
            SizeType     = 'Medium'
            ToolTip      = 'Create the application folder and initial artifacts.'
            Function     = { New-ApplicationFolder }.GetNewClosure()
        }
        New-Button @ApplicationIDButtonProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox
        New-Button @CustomizeApplicationIDButtonProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox
        New-Button @CreateFolderButtonProperties -InputObject $InputObject -ParentGroupBox $FeatureGroupBox

        return $FeatureGroupBox
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}

### END OF FUNCTION
####################################################################################################
