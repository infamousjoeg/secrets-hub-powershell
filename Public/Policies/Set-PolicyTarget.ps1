<#
.SYNOPSIS
Sets the target secret store for a policy (pipeline builder).

.DESCRIPTION
Pipeline function to set the target secret store ID for policy creation.

.PARAMETER InputObject
The policy object from pipeline.

.PARAMETER StoreId
The target secret store ID.

.EXAMPLE
New-Policy -Name "Test" | Set-PolicySource -StoreId "store-123" | Set-PolicyTarget -StoreId "store-456"

.NOTES
Part of the policy builder pipeline pattern.
#>
function Set-PolicyTarget {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([System.Object])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [object]$InputObject,

        [Parameter(Mandatory = $true)]
        [string]$StoreId
    )

    process {
        if ($PSCmdlet.ShouldProcess($StoreId, "Set Policy Target")) {
            $InputObject.TargetStoreId = $StoreId
            return $InputObject
        }
    }
}