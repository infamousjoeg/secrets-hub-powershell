<#
.SYNOPSIS
Gets secrets filters from Secrets Hub.

.DESCRIPTION
Retrieves secrets filters for a specified secret store.

.PARAMETER StoreId
The unique identifier of the secret store.

.PARAMETER FilterId
The unique identifier of a specific filter to retrieve.

.EXAMPLE
Get-Filter -StoreId "store-5a05468b-fa58-4bcf-84e9-62ede8af55f4"

.EXAMPLE
Get-Filter -StoreId "store-5a05468b-fa58-4bcf-84e9-62ede8af55f4" -FilterId "filter-5800242b-353c-4075-b865-f8ab3b75e279"
#>
function Get-Filter {
    [CmdletBinding(DefaultParameterSetName = 'List')]
    param(
        [Parameter(Mandatory = $true)]
        [string]$StoreId,

        [Parameter(ParameterSetName = 'ById')]
        [string]$FilterId
    )

    begin {
        Test-SecretsHubConnection
    }

    process {
        try {
            if ($FilterId) {
                $Uri = "api/secret-stores/$StoreId/filters/$FilterId"
            }
            else {
                $Uri = "api/secret-stores/$StoreId/filters"
            }

            $Result = Invoke-SecretsHubApi -Uri $Uri -Method GET
            return $Result
        }
        catch {
            Write-SecretsHubError -ErrorRecord $_ -Operation "Get-Filter"
            throw
        }
    }
}
