####################################################################################################
<#
.SYNOPSIS
    Clears Intake textboxes and comboboxes from the Graphics object.
.OUTPUTS
    No objects are returned to the pipeline.
#>
####################################################################################################
function Clear-IntakeFormFields {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false)]
        [System.Collections.Hashtable]$GlobalGraphicsObject = $Global:Graphics
    )

    try {
        if ($GlobalGraphicsObject -isnot [System.Collections.IDictionary]) {
            Write-Line 'Global Graphics object is unavailable. Nothing to clear.' -Type Warning
            return
        }

        [System.Int32]$ClearedTextBoxes = 0
        [System.Int32]$ClearedComboBoxes = 0
        if ($GlobalGraphicsObject.ContainsKey('TextBoxes') -and $GlobalGraphicsObject.TextBoxes -is [System.Collections.IDictionary]) {
            foreach ($Node in (Get-TargetIntakeNodes -RootNode $GlobalGraphicsObject.TextBoxes)) {
                [System.Collections.Stack]$Stack = New-Object System.Collections.Stack
                $Stack.Push($Node)
                while ($Stack.Count -gt 0) {
                    [System.Object]$CurrentNode = $Stack.Pop()
                    if ($CurrentNode -is [System.Collections.IDictionary]) {
                        foreach ($ChildKey in $CurrentNode.Keys) { $Stack.Push($CurrentNode[$ChildKey]) }
                    }
                    elseif ($CurrentNode -is [System.Windows.Forms.TextBox]) {
                        Clear-TextBox -TextBox $CurrentNode -Force
                        $ClearedTextBoxes++
                    }
                }
            }
        }

        if ($GlobalGraphicsObject.ContainsKey('ComboBoxes') -and $GlobalGraphicsObject.ComboBoxes -is [System.Collections.IDictionary]) {
            foreach ($Node in (Get-TargetIntakeNodes -RootNode $GlobalGraphicsObject.ComboBoxes)) {
                [System.Collections.Stack]$Stack = New-Object System.Collections.Stack
                $Stack.Push($Node)
                while ($Stack.Count -gt 0) {
                    [System.Object]$CurrentNode = $Stack.Pop()
                    if ($CurrentNode -is [System.Collections.IDictionary]) {
                        foreach ($ChildKey in $CurrentNode.Keys) { $Stack.Push($CurrentNode[$ChildKey]) }
                    }
                    elseif ($CurrentNode -is [System.Windows.Forms.ComboBox]) {
                        Clear-ComboBox -ComboBox $CurrentNode -Force
                        $ClearedComboBoxes++
                    }
                }
            }
        }

        Write-Line "Cleared $ClearedTextBoxes textboxes and $ClearedComboBoxes comboboxes in the Application Intake Form." -Type Info
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
    Resolves flattened Intake nodes from a Graphics root dictionary.
.OUTPUTS
    [System.Collections.ArrayList]
#>
####################################################################################################
function Get-TargetIntakeNodes {
    [CmdletBinding()]
    [OutputType([System.Collections.ArrayList])]
    param (
        [Parameter(Mandatory=$true)]
        [System.Collections.IDictionary]$RootNode
    )

    [System.Collections.ArrayList]$TargetNodes = New-Object System.Collections.ArrayList
    foreach ($Key in $RootNode.Keys) {
        [System.String]$NormalizedKey = ($Key -replace '\s+', '').ToLowerInvariant()
        if ($NormalizedKey -eq 'applicationintake.desktopapplication' -or
            $NormalizedKey -like 'applicationintake.desktopapplication.*') {
            Add-TargetNode -TargetNodes $TargetNodes -Node $RootNode[$Key]
        }
    }
    return $TargetNodes
}

### END OF FUNCTION
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    Adds a valid unique node to a target collection.
.OUTPUTS
    No objects are returned to the pipeline.
#>
####################################################################################################
function Add-TargetNode {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [AllowEmptyCollection()]
        [System.Collections.ArrayList]$TargetNodes,

        [Parameter(Mandatory=$false)]
        [System.Object]$Node
    )

    if ($null -ne $Node -and -not ($TargetNodes -contains $Node)) {
        [void]$TargetNodes.Add($Node)
    }
}

### END OF FUNCTION
####################################################################################################
