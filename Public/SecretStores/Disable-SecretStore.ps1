<#
.SYNOPSIS
Disables a secret store in Secrets Hub.

.DESCRIPTION
Changes the state of a secret store to DISABLED.

.PARAMETER StoreId
The unique identifier of the secret store to disable.

.EXAMPLE
Disable-SecretStore -StoreId "store-5a05468b-fa58-4bcf-84e9-62ede8af55f4"
#>
function Disable-SecretStore {
    [CmdletBinding(SupportsShouldProcess)]
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
            if ($PSCmdlet.ShouldProcess($StoreId, "Disable Secret Store")) {
                $Uri = "api/secret-stores/$StoreId/state"
                $Body = @{ action = "disable" }

                Invoke-SecretsHubApi -Uri $Uri -Method PUT -Body $Body
                Write-Host "Successfully disabled secret store: $StoreId" -ForegroundColor Yellow
            }
        }
        catch {
            Write-SecretsHubError -ErrorRecord $_ -Operation "Disable-SecretStore"
            throw
        }
    }
}
