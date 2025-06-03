<#
.SYNOPSIS
Updates an Azure Key Vault secret store.

.DESCRIPTION
Updates configuration for an existing Azure secret store using object-based approach.

.PARAMETER StoreId
The unique identifier of the secret store to update.

.PARAMETER Data
Hashtable containing the properties to update.

.EXAMPLE
Set-AzureSecretStore -StoreId "store-123" -Data @{ description = "Updated description" }
#>
function Set-AzureSecretStore {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('Id')]
        [string]$StoreId,

        [Parameter(Mandatory = $true)]
        [hashtable]$Data
    )

    begin {
        Test-SecretsHubConnection
    }

    process {
        try {
            if ($PSCmdlet.ShouldProcess($StoreId, "Update Azure Secret Store")) {
                $Uri = "api/secret-stores/$StoreId"
                $Result = Invoke-SecretsHubApi -Uri $Uri -Method PATCH -Body $Data
                Write-Host "Successfully updated Azure secret store: $StoreId" -ForegroundColor Green
                return $Result
            }
        }
        catch {
            Write-SecretsHubError -ErrorRecord $_ -Operation "Set-AzureSecretStore"
            throw
        }
    }
}
