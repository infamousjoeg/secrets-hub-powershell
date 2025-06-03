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
        [Parameter(Mandatory = $true, ParameterSetName = 'ById', ValueFromPipeline = $true)]
        [string]$StoreId,
        
        [Parameter(ParameterSetName = 'List')]
        [ValidateSet('SECRETS_SOURCE', 'SECRETS_TARGET')]
        [string]$Behavior = 'SECRETS_TARGET',
        
        [Parameter(ParameterSetName = 'List')]
        [string]$Filter,
        
        [Parameter(ParameterSetName = 'All')]
        [switch]$All
    )
    
    begin {
        Test-SecretsHubConnection
        Write-Verbose "Getting secret stores"
    }
    
    process {
        try {
            if ($PSCmdlet.ParameterSetName -eq 'ById') {
                $Uri = "api/secret-stores/$StoreId"
                $Result = Invoke-SecretsHubApi -Uri $Uri -Method GET
                return $Result
            }
            elseif ($PSCmdlet.ParameterSetName -eq 'All') {
                # Get both source and target stores
                $SourceStores = Get-SecretStore -Behavior 'SECRETS_SOURCE'
                $TargetStores = Get-SecretStore -Behavior 'SECRETS_TARGET'
                return @($SourceStores) + @($TargetStores)
            }
            else {
                $Uri = "api/secret-stores"
                $QueryParams = @{
                    behavior = $Behavior
                }
                
                if ($Filter) {
                    $QueryParams.filter = $Filter
                }
                
                $Result = Invoke-SecretsHubApi -Uri $Uri -Method GET -QueryParameters $QueryParams
                return $Result.secretStores
            }
        }
        catch {
            Write-SecretsHubError -ErrorRecord $_ -Operation "Get-SecretStore"
            throw
        }
    }
}
