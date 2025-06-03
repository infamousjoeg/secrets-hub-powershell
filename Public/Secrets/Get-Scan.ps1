<#
.SYNOPSIS
Gets scan information from Secrets Hub (BETA).

.DESCRIPTION
Retrieves scan status and history. This is a beta feature.

.EXAMPLE
Get-Scan

.NOTES
This is a BETA feature. Use with caution in production environments.
#>
function Get-Scan {
    [CmdletBinding()]
    param()
    
    begin {
        Test-SecretsHubConnection
        Write-Warning "Get-Scan uses BETA APIs. Features may change without notice."
    }
    
    process {
        try {
            $Result = Invoke-SecretsHubApi -Uri "api/scans" -Method GET -Beta
            return $Result.scans
        }
        catch {
            Write-SecretsHubError -ErrorRecord $_ -Operation "Get-Scan"
            throw
        }
    }
}
