<#
.SYNOPSIS
Enables a secret store in Secrets Hub.

.DESCRIPTION
Changes the state of a secret store to ENABLED.

.PARAMETER StoreId
The unique identifier of the secret store to enable.

.EXAMPLE
Enable-SecretStore -StoreId "store-5a05468b-fa58-4bcf-84e9-62ede8af55f4"

.EXAMPLE
Get-SecretStore -All | Where-Object { $_.state.current -eq 'DISABLED' } | Enable-SecretStore
#>
function Enable-SecretStore {
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
            if ($PSCmdlet.ShouldProcess($StoreId, "Enable Secret Store")) {
                $Uri = "api/secret-stores/$StoreId/state"
                $Body = @{ action = "enable" }

                Invoke-SecretsHubApi -Uri $Uri -Method PUT -Body $Body
                Write-Information "Successfully enabled secret store: $StoreId" -InformationAction Continue
            }
        }
        catch {
            Write-SecretsHubError -ErrorRecord $_ -Operation "Enable-SecretStore"
            throw
        }
    }
}