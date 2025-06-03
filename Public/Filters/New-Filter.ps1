<#
.SYNOPSIS
Creates a new secrets filter in Secrets Hub.

.DESCRIPTION
Creates a filter that defines which secrets to include from a source secret store.

.PARAMETER StoreId
The unique identifier of the secret store.

.PARAMETER SafeName
The PAM Safe name for PAM_SAFE filter type.

.PARAMETER Type
The filter type (currently only PAM_SAFE is supported).

.EXAMPLE
New-Filter -StoreId "store-5a05468b-fa58-4bcf-84e9-62ede8af55f4" -SafeName "DevSafe"

.NOTES
Every sync policy should have its own secrets filter.
#>
function New-Filter {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true)]
        [string]$StoreId,
        
        [Parameter(Mandatory = $true)]
        [string]$SafeName,
        
        [Parameter()]
        [ValidateSet('PAM_SAFE')]
        [string]$Type = 'PAM_SAFE'
    )
    
    begin {
        Test-SecretsHubConnection
    }
    
    process {
        try {
            if ($PSCmdlet.ShouldProcess($SafeName, "Create Filter")) {
                $Body = @{
                    type = $Type
                    data = @{
                        safeName = $SafeName
                    }
                }
                
                $Uri = "api/secret-stores/$StoreId/filters"
                $Result = Invoke-SecretsHubApi -Uri $Uri -Method POST -Body $Body
                Write-Host "Successfully created filter for Safe: $SafeName" -ForegroundColor Green
                return $Result
            }
        }
        catch {
            Write-SecretsHubError -ErrorRecord $_ -Operation "New-Filter"
            throw
        }
    }
}
