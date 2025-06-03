<#
.SYNOPSIS
Disables a sync policy in Secrets Hub.

.DESCRIPTION
Changes the state of a sync policy to DISABLED.

.PARAMETER PolicyId
The unique identifier of the policy to disable.

.EXAMPLE
Disable-Policy -PolicyId "policy-62d19762-85d0-4cc0-ba44-9e0156a5c9c6"
#>
function Disable-Policy {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('Id')]
        [string]$PolicyId
    )

    begin {
        Test-SecretsHubConnection
    }

    process {
        try {
            if ($PSCmdlet.ShouldProcess($PolicyId, "Disable Policy")) {
                $Uri = "api/policies/$PolicyId/state"
                $Body = @{ action = "disable" }

                Invoke-SecretsHubApi -Uri $Uri -Method PUT -Body $Body
                Write-Host "Successfully disabled policy: $PolicyId" -ForegroundColor Yellow
            }
        }
        catch {
            Write-SecretsHubError -ErrorRecord $_ -Operation "Disable-Policy"
            throw
        }
    }
}
