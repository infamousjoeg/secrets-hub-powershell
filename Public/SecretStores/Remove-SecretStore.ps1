<#
.SYNOPSIS
Removes a secret store from Secrets Hub.

.DESCRIPTION
Deletes the specified secret store. Note that linked policies must be deleted first.

.PARAMETER StoreId
The unique identifier of the secret store to remove.

.PARAMETER Force
Suppress confirmation prompts.

.EXAMPLE
Remove-SecretStore -StoreId "store-5a05468b-fa58-4bcf-84e9-62ede8af55f4"

.NOTES
All policies using this secret store must be deleted first.
#>
function Remove-SecretStore {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('Id')]
        [string]$StoreId,

        [Parameter()]
        [switch]$Force
    )

    begin {
        Test-SecretsHubConnection
    }

    process {
        try {
            if ($Force -or $PSCmdlet.ShouldProcess($StoreId, "Remove Secret Store")) {
                $Uri = "api/secret-stores/$StoreId"
                Invoke-SecretsHubApi -Uri $Uri -Method DELETE
                Write-Host "Successfully removed secret store: $StoreId" -ForegroundColor Yellow
            }
        }
        catch {
            Write-SecretsHubError -ErrorRecord $_ -Operation "Remove-SecretStore"
            throw
        }
    }
}
