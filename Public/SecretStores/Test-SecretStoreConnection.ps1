<#
.SYNOPSIS
Tests the connection status of a secret store.

.DESCRIPTION
Validates that Secrets Hub can connect to the specified secret store.

.PARAMETER StoreId
The unique identifier of the secret store to test.

.EXAMPLE
Test-SecretStoreConnection -StoreId "store-5a05468b-fa58-4bcf-84e9-62ede8af55f4"

.EXAMPLE
Get-SecretStore -All | Test-SecretStoreConnection
#>
function Test-SecretStoreConnection {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('Id')]
        [string]$StoreId
    )
    
    begin {
        Test-SecretsHubConnection
    }
    
    process {
        try {
            $Uri = "api/secret-stores/$StoreId/status/connection"
            $Result = Invoke-SecretsHubApi -Uri $Uri -Method GET
            
            if ($Result.status -eq 'OK') {
                Write-Host "✓ Secret store connection test passed: $StoreId" -ForegroundColor Green
            }
            else {
                Write-Warning "✗ Secret store connection test failed: $StoreId - $($Result.message)"
            }
            
            return $Result
        }
        catch {
            Write-SecretsHubError -ErrorRecord $_ -Operation "Test-SecretStoreConnection"
            throw
        }
    }
}
