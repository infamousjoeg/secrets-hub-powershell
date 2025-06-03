<#
.SYNOPSIS
Triggers a scan on secret stores (BETA).

.DESCRIPTION
Initiates a scan on specified secret stores. This is a beta feature.

.PARAMETER StoreId
The unique identifier of the secret store to scan.

.PARAMETER Type
The type of scan (typically "secret-store").

.PARAMETER Id
The scan definition ID (typically "default").

.EXAMPLE
Start-Scan -StoreId "store-5a05468b-fa58-4bcf-84e9-62ede8af55f4"

.NOTES
This is a BETA feature. Use with caution in production environments.
#>
function Start-Scan {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [string]$StoreId,

        [Parameter()]
        [string]$Type = "secret-store",

        [Parameter()]
        [string]$Id = "default"
    )

    begin {
        Test-SecretsHubConnection
        Write-Warning "Start-Scan uses BETA APIs. Features may change without notice."
    }

    process {
        try {
            if ($PSCmdlet.ShouldProcess($StoreId, "Start Scan")) {
                $Uri = "api/scan-definitions/$Type/$Id/scan"
                $Body = @{
                    scope = @{
                        secretStoresIds = @($StoreId)
                    }
                }

                $Result = Invoke-SecretsHubApi -Uri $Uri -Method POST -Body $Body -Beta
                Write-Information "Successfully triggered scan for store: $StoreId" -InformationAction Continue
                return $Result
            }
        }
        catch {
            Write-SecretsHubError -ErrorRecord $_ -Operation "Start-Scan"
            throw
        }
    }
}