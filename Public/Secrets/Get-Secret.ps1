<#
.SYNOPSIS
Gets secrets from Secrets Hub (BETA).

.DESCRIPTION
Retrieves scanned secrets from secret stores. This is a beta feature.

.PARAMETER Filter
Filter expression for querying secrets.

.PARAMETER Projection
Data representation method (REGULAR or EXTEND).

.PARAMETER Offset
Number of secrets to skip.

.PARAMETER Limit
Number of secrets to return (max 1000).

.PARAMETER Sort
Sort order (e.g., "storeName ASC").

.EXAMPLE
Get-Secret -Filter "vendorType EQ AWS" -Projection EXTEND -Limit 50

.NOTES
This is a BETA feature. Use with caution in production environments.
#>
function Get-Secret {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$Filter,

        [Parameter()]
        [ValidateSet('REGULAR', 'EXTEND')]
        [string]$Projection = 'REGULAR',

        [Parameter()]
        [ValidateRange(0, 150000)]
        [int]$Offset = 0,

        [Parameter()]
        [ValidateRange(1, 1000)]
        [int]$Limit = 100,

        [Parameter()]
        [string]$Sort = "storeName ASC"
    )

    begin {
        Test-SecretsHubConnection
        Write-Warning "Get-Secret uses BETA APIs. Features may change without notice."
    }

    process {
        try {
            $QueryParams = @{
                projection = $Projection
                offset = $Offset
                limit = $Limit
                sort = $Sort
            }

            if ($Filter) {
                $QueryParams.filter = $Filter
            }

            $Result = Invoke-SecretsHubApi -Uri "api/secrets" -Method GET -QueryParameters $QueryParams -Beta
            return $Result.secrets
        }
        catch {
            Write-SecretsHubError -ErrorRecord $_ -Operation "Get-Secret"
            throw
        }
    }
}
