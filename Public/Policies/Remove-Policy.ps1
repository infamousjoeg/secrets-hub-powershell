<#
.SYNOPSIS
Removes a sync policy from Secrets Hub.

.DESCRIPTION
Deletes the specified sync policy. Note that filters should be deleted after the policy.

.PARAMETER PolicyId
The unique identifier of the policy to remove.

.PARAMETER Force
Suppress confirmation prompts.

.EXAMPLE
Remove-Policy -PolicyId "policy-62d19762-85d0-4cc0-ba44-9e0156a5c9c6"
#>
function Remove-Policy {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('Id')]
        [string]$PolicyId,

        [Parameter()]
        [switch]$Force
    )

    begin {
        Test-SecretsHubConnection
    }

    process {
        try {
            if ($Force -or $PSCmdlet.ShouldProcess($PolicyId, "Remove Policy")) {
                $Uri = "api/policies/$PolicyId"
                $Result = Invoke-SecretsHubApi -Uri $Uri -Method DELETE
                Write-Warning "Successfully removed policy: $PolicyId"
                return $Result
            }
        }
        catch {
            Write-SecretsHubError -ErrorRecord $_ -Operation "Remove-Policy"
            throw
        }
    }
}
