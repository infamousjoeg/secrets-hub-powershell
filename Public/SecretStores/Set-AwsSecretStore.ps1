<#
.SYNOPSIS
Updates an AWS Secrets Manager secret store.

.DESCRIPTION
Updates configuration for an existing AWS secret store using object-based approach.

.PARAMETER StoreId
The unique identifier of the secret store to update.

.PARAMETER Data
Hashtable containing the properties to update.

.PARAMETER Name
The display name for the secret store.

.PARAMETER Description
Description for the secret store.

.EXAMPLE
Set-AwsSecretStore -StoreId "store-123" -Data @{ description = "Updated description"; roleName = "NewRole" }

.EXAMPLE
Set-AwsSecretStore -StoreId "store-123" -Name "New Name" -Description "New Description"

.NOTES
Uses object-based approach for flexibility in updates.
#>
function Set-AwsSecretStore {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('Id')]
        [string]$StoreId,

        [Parameter(ParameterSetName = 'Object')]
        [hashtable]$Data,

        [Parameter(ParameterSetName = 'Properties')]
        [string]$Name,

        [Parameter(ParameterSetName = 'Properties')]
        [string]$Description,

        [Parameter(ParameterSetName = 'Properties')]
        [string]$AccountAlias,

        [Parameter(ParameterSetName = 'Properties')]
        [string]$RoleName
    )

    begin {
        Test-SecretsHubConnection
    }

    process {
        try {
            if ($PSCmdlet.ShouldProcess($StoreId, "Update AWS Secret Store")) {
                $Body = @{}

                if ($PSCmdlet.ParameterSetName -eq 'Object') {
                    $Body = $Data
                }
                else {
                    if ($Name) { $Body.name = $Name }
                    if ($Description) { $Body.description = $Description }

                    if ($AccountAlias -or $RoleName) {
                        $Body.data = @{}
                        if ($AccountAlias) { $Body.data.accountAlias = $AccountAlias }
                        if ($RoleName) { $Body.data.roleName = $RoleName }
                    }
                }

                if ($Body.Count -eq 0) {
                    throw "No update parameters provided"
                }

                $Uri = "api/secret-stores/$StoreId"
                $Result = Invoke-SecretsHubApi -Uri $Uri -Method PATCH -Body $Body
                Write-Information "Successfully updated AWS secret store: $StoreId" -InformationAction Continue
                return $Result
            }
        }
        catch {
            Write-SecretsHubError -ErrorRecord $_ -Operation "Set-AwsSecretStore"
            throw
        }
    }
}
