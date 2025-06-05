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
function Get-SecretStore {
    [CmdletBinding(DefaultParameterSetName = 'List')]
    param(
        [Parameter(Mandatory = $true, ParameterSetName = 'ById')]
        [ValidateNotNullOrEmpty()]
        [string]$StoreId,

        [Parameter(ParameterSetName = 'List')]
        [ValidateSet('SECRETS_SOURCE', 'SECRETS_TARGET')]
        [string]$Behavior = 'SECRETS_TARGET',

        [Parameter(ParameterSetName = 'List')]
        [string]$Filter,

        [Parameter(Mandatory = $true, ParameterSetName = 'All')]
        [switch]$All
    )

    begin {
        # Ensure we have a connection
        if (-not $script:SecretsHubSession) {
            throw "Not connected to Secrets Hub. Use Connect-SecretsHub first."
        }
        
        Write-Verbose "Get-SecretStore called with ParameterSet: $($PSCmdlet.ParameterSetName)"
    }

    process {
        try {
            switch ($PSCmdlet.ParameterSetName) {
                'ById' {
                    Write-Verbose "Getting secret store by ID: $StoreId"
                    $Result = Invoke-SecretsHubApi -Uri "api/secret-stores/$StoreId" -Method GET
                    return $Result
                }
                
                'All' {
                    Write-Verbose "Getting all secret stores"
                    
                    $AllStores = @()
                    
                    # Get source stores
                    try {
                        Write-Verbose "Retrieving SECRETS_SOURCE stores"
                        $SourceResult = Invoke-SecretsHubApi -Uri "api/secret-stores" -Method GET -QueryParameters @{behavior = 'SECRETS_SOURCE'}
                        if ($SourceResult -and $SourceResult.secretStores) {
                            $AllStores += $SourceResult.secretStores
                            Write-Verbose "Found $($SourceResult.secretStores.Count) source stores"
                        }
                    }
                    catch {
                        Write-Warning "Could not retrieve SECRETS_SOURCE stores: $($_.Exception.Message)"
                    }
                    
                    # Get target stores
                    try {
                        Write-Verbose "Retrieving SECRETS_TARGET stores"
                        $TargetResult = Invoke-SecretsHubApi -Uri "api/secret-stores" -Method GET -QueryParameters @{behavior = 'SECRETS_TARGET'}
                        if ($TargetResult -and $TargetResult.secretStores) {
                            $AllStores += $TargetResult.secretStores
                            Write-Verbose "Found $($TargetResult.secretStores.Count) target stores"
                        }
                    }
                    catch {
                        Write-Warning "Could not retrieve SECRETS_TARGET stores: $($_.Exception.Message)"
                    }
                    
                    Write-Verbose "Total stores retrieved: $($AllStores.Count)"
                    return $AllStores
                }
                
                'List' {
                    Write-Verbose "Getting secret stores with behavior: $Behavior"
                    $QueryParams = @{ behavior = $Behavior }
                    if ($Filter) { 
                        $QueryParams.filter = $Filter 
                        Write-Verbose "Applied filter: $Filter"
                    }
                    
                    $Result = Invoke-SecretsHubApi -Uri "api/secret-stores" -Method GET -QueryParameters $QueryParams
                    $Stores = if ($Result -and $Result.secretStores) { $Result.secretStores } else { @() }
                    Write-Verbose "Found $($Stores.Count) stores"
                    return $Stores
                }
            }
        }
        catch {
            Write-Error "Failed to get secret stores: $($_.Exception.Message)"
            throw
        }
    }
}