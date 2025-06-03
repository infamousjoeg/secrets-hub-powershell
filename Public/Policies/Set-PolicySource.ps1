<#
.SYNOPSIS
Sets the source secret store for a policy (pipeline builder).

.DESCRIPTION
Pipeline function to set the source secret store ID for policy creation.

.PARAMETER InputObject
The policy object from pipeline.

.PARAMETER StoreId
The source secret store ID.

.EXAMPLE
New-Policy -Name "Test" | Set-PolicySource -StoreId "store-123" | Set-PolicyTarget -StoreId "store-456"

.NOTES
Part of the policy builder pipeline pattern.
#>
function Set-PolicySource {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [object]$InputObject,
        
        [Parameter(Mandatory = $true)]
        [string]$StoreId
    )
    
    process {
        $InputObject.SourceStoreId = $StoreId
        return $InputObject
    }
}
