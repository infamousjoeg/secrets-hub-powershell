<#
.SYNOPSIS
Writes formatted error messages for Secrets Hub operations.

.DESCRIPTION
Provides consistent error formatting and logging.
#>
function Write-SecretsHubError {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.ErrorRecord]$ErrorRecord,

        [Parameter()]
        [string]$Operation
    )

    process {
        $ErrorMessage = "Secrets Hub operation failed"

        if ($Operation) {
            $ErrorMessage += " [$Operation]"
        }

        $ErrorMessage += ": $($ErrorRecord.Exception.Message)"

        Write-Error $ErrorMessage -Category $ErrorRecord.CategoryInfo.Category
        Write-Verbose "Full error details: $($ErrorRecord | Out-String)"
    }
}
