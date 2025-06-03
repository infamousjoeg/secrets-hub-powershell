<#
.SYNOPSIS
Removes a secrets filter from Secrets Hub.

.DESCRIPTION
Deletes the specified secrets filter. Linked policies must be deleted first.

.PARAMETER StoreId
The unique identifier of the secret store.

.PARAMETER FilterId
The unique identifier of the filter to remove.

.PARAMETER Force
Suppress confirmation prompts.

.EXAMPLE
Remove-Filter -StoreId "store-5a05468b-fa58-4bcf-84e9-62ede8af55f4" -FilterId "filter-5800242b-353c-4075-b865-f8ab3b75e279"

.NOTES
All policies using this filter must be deleted first.
#>
function Remove-Filter {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory = $true)]
        [string]$StoreId,
        
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('Id')]
        [string]$FilterId,
        
        [Parameter()]
        [switch]$Force
    )
    
    begin {
        Test-SecretsHubConnection
    }
    
    process {
        try {
            if ($Force -or $PSCmdlet.ShouldProcess($FilterId, "Remove Filter")) {
                $Uri = "api/secret-stores/$StoreId/filters/$FilterId"
                Invoke-SecretsHubApi -Uri $Uri -Method DELETE
                Write-Host "Successfully removed filter: $FilterId" -ForegroundColor Yellow
            }
        }
        catch {
            Write-SecretsHubError -ErrorRecord $_ -Operation "Remove-Filter"
            throw
        }
    }
}
