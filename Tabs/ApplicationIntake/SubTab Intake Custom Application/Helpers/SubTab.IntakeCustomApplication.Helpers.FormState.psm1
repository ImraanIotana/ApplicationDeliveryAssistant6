####################################################################################################
<#
.SYNOPSIS
    Clears all persisted controls in the Custom Application sub-tab.
.DESCRIPTION
    This function resolves TextBox and ComboBox controls registered under the Custom Application graphics path and clears their current values.
.EXAMPLE
    Clear-CustomApplicationFormFields
.INPUTS
    [System.Collections.Hashtable]
.OUTPUTS
    No objects are returned to the pipeline.
.NOTES
    This script is part of the Application Delivery Assistant. Copyright (C) Iotana. Licensed under the Apache License 2.0.
    Version         : 6.3.1
    Author          : Imraan Iotana
    Creation Date   : August 2026
    Last Update     : August 2026
#>
####################################################################################################
function Clear-CustomApplicationFormFields {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false)]
        [System.Collections.Hashtable]$GlobalGraphicsObject = $Global:Graphics
    )

    try {
        # VALIDATION - GRAPHICS ROOT
        if ($GlobalGraphicsObject -isnot [System.Collections.IDictionary]) {
            Write-Line 'Global Graphics object is unavailable. Nothing to clear.' -Type Warning
            return
        }

        # PREPARATION - SCOPED CONTROL COLLECTION
        [System.Collections.ArrayList]$ResolvedControls = New-Object System.Collections.ArrayList
        [System.Int32]$ClearedTextBoxes = 0
        [System.Int32]$ClearedComboBoxes = 0

        foreach ($ControlCollectionName in @('TextBoxes','ComboBoxes')) {
            if (-not $GlobalGraphicsObject.ContainsKey($ControlCollectionName)) { continue }

            [System.Object]$RootNode = $GlobalGraphicsObject[$ControlCollectionName]
            if ($RootNode -isnot [System.Collections.IDictionary]) { continue }

            foreach ($RootKey in $RootNode.Keys) {
                [System.String]$NormalizedKey = ($RootKey -replace '\s+', '').ToLowerInvariant()
                if ($NormalizedKey -ne 'applicationintake.customapplication' -and
                    $NormalizedKey -notlike 'applicationintake.customapplication.*') {
                    continue
                }

                [System.Collections.Stack]$Stack = New-Object System.Collections.Stack
                $Stack.Push($RootNode[$RootKey])
                while ($Stack.Count -gt 0) {
                    [System.Object]$CurrentNode = $Stack.Pop()
                    if ($CurrentNode -is [System.Collections.IDictionary]) {
                        foreach ($ChildKey in $CurrentNode.Keys) { $Stack.Push($CurrentNode[$ChildKey]) }
                    }
                    elseif (($CurrentNode -is [System.Windows.Forms.TextBox] -or $CurrentNode -is [System.Windows.Forms.ComboBox]) -and
                            -not ($ResolvedControls -contains $CurrentNode)) {
                        [void]$ResolvedControls.Add($CurrentNode)
                    }
                }
            }
        }

        # EXECUTION - CLEAR RESOLVED CONTROLS
        foreach ($Control in $ResolvedControls) {
            if ($Control -is [System.Windows.Forms.TextBox]) {
                Clear-TextBox -TextBox $Control -Force
                $ClearedTextBoxes++
            }
            elseif ($Control -is [System.Windows.Forms.ComboBox]) {
                Clear-ComboBox -ComboBox $Control -Force
                $ClearedComboBoxes++
            }
        }

        # POST-EXECUTION - REPORT RESULT
        Write-Line "Cleared $ClearedTextBoxes textboxes and $ClearedComboBoxes comboboxes in the Custom Application form." -Type Info
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
    }
}

### END OF FUNCTION
####################################################################################################