<#
.SYNOPSIS
Gets secret stores from CyberArk Secrets Hub.

.DESCRIPTION
Retrieves secret stores based on filter criteria. Can get all stores or a specific store by ID.

.PARAMETER StoreId
The unique identifier of a specific secret store to retrieve.

.PARAMETER Behavior
Filter by secret store behavior (SECRETS_SOURCE or SECRETS_TARGET).

.PARAMETER Filter
Advanced filter expression for querying secret stores.

.PARAMETER All
Retrieve all secret stores without filtering.

.EXAMPLE
Get-SecretStore -All

.EXAMPLE
Get-SecretStore -StoreId "store-5a05468b-fa58-4bcf-84e9-62ede8af55f4"

.EXAMPLE
Get-SecretStore -Behavior SECRETS_TARGET -Filter "type EQ AWS_ASM"

.NOTES
Requires an active Secrets Hub connection.
#>
# Override the function with a clean implementation
function Get-SecretStore {
    [CmdletBinding(DefaultParameterSetName = 'List')]
    param(
        [Parameter(Mandatory = $true, ParameterSetName = 'ById')]
        [string]$StoreId,

        [Parameter(ParameterSetName = 'List')]
        [ValidateSet('SECRETS_SOURCE', 'SECRETS_TARGET')]
        [string]$Behavior = 'SECRETS_TARGET',

        [Parameter(ParameterSetName = 'List')]
        [string]$Filter,

        [Parameter(ParameterSetName = 'All')]
        [switch]$All
    )

    # Ensure we have a connection
    if (-not $script:SecretsHubSession) {
        throw "Not connected to Secrets Hub. Use Connect-SecretsHub first."
    }

    try {
        if ($PSCmdlet.ParameterSetName -eq 'ById') {
            Write-Verbose "Getting secret store by ID: $StoreId"
            $Result = Invoke-SecretsHubApi -Uri "api/secret-stores/$StoreId" -Method GET
            return $Result
        }
        elseif ($PSCmdlet.ParameterSetName -eq 'All') {
            Write-Verbose "Getting all secret stores"
            
            # Get source stores
            $SourceResult = Invoke-SecretsHubApi -Uri "api/secret-stores" -Method GET -QueryParameters @{behavior = 'SECRETS_SOURCE'}
            $SourceStores = if ($SourceResult -and $SourceResult.secretStores) { $SourceResult.secretStores } else { @() }
            
            # Get target stores
            $TargetResult = Invoke-SecretsHubApi -Uri "api/secret-stores" -Method GET -QueryParameters @{behavior = 'SECRETS_TARGET'}
            $TargetStores = if ($TargetResult -and $TargetResult.secretStores) { $TargetResult.secretStores } else { @() }
            
            # Combine results
            $AllStores = @()
            if ($SourceStores) { $AllStores += $SourceStores }
            if ($TargetStores) { $AllStores += $TargetStores }
            
            return $AllStores
        }
        else {
            Write-Verbose "Getting secret stores with behavior: $Behavior"
            $QueryParams = @{ behavior = $Behavior }
            if ($Filter) { $QueryParams.filter = $Filter }
            
            $Result = Invoke-SecretsHubApi -Uri "api/secret-stores" -Method GET -QueryParameters $QueryParams
            return if ($Result -and $Result.secretStores) { $Result.secretStores } else { @() }
        }
    }
    catch {
        Write-Error "Failed to get secret stores: $($_.Exception.Message)"
        throw
    }
}