<#
.SYNOPSIS
Gets sync policies from Secrets Hub.

.DESCRIPTION
Retrieves sync policies based on filter criteria or gets a specific policy by ID.

.PARAMETER PolicyId
The unique identifier of a specific policy to retrieve.

.PARAMETER Filter
Filter expression for querying policies (e.g., "filter.safeName EQ MySafe").

.PARAMETER Projection
Data representation method (REGULAR, EXTEND, or METADATA).

.EXAMPLE
Get-Policy -Filter "filter.safeName EQ DevSafe" -Projection REGULAR

.EXAMPLE
Get-Policy -PolicyId "policy-62d19762-85d0-4cc0-ba44-9e0156a5c9c6" -Projection EXTEND
#>
function Get-Policy {
    [CmdletBinding(DefaultParameterSetName = 'List')]
    param(
        [Parameter(Mandatory = $true, ParameterSetName = 'ById')]
        [string]$PolicyId,

        [Parameter(Mandatory = $true, ParameterSetName = 'List')]
        [string]$Filter,

        [Parameter()]
        [ValidateSet('REGULAR', 'EXTEND', 'METADATA')]
        [string]$Projection = 'REGULAR'
    )

    begin {
        Test-SecretsHubConnection
    }

    process {
        try {
            if ($PSCmdlet.ParameterSetName -eq 'ById') {
                $Uri = "api/policies/$PolicyId"
                $QueryParams = @{ projection = $Projection }
                $Result = Invoke-SecretsHubApi -Uri $Uri -Method GET -QueryParameters $QueryParams
                return $Result
            }
            else {
                $Uri = "api/policies"
                $QueryParams = @{
                    filter = $Filter
                    projection = $Projection
                }

                $Result = Invoke-SecretsHubApi -Uri $Uri -Method GET -QueryParameters $QueryParams
                return $Result.policies
            }
        }
        catch {
            Write-SecretsHubError -ErrorRecord $_ -Operation "Get-Policy"
            throw
        }
    }
}
