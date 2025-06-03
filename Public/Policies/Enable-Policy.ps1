<#
.SYNOPSIS
Enables a sync policy in Secrets Hub.

.DESCRIPTION
Changes the state of a sync policy to ENABLED.

.PARAMETER PolicyId
The unique identifier of the policy to enable.

.EXAMPLE
Enable-Policy -PolicyId "policy-62d19762-85d0-4cc0-ba44-9e0156a5c9c6"
#>
function Enable-Policy {
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
            if ($PSCmdlet.ShouldProcess($PolicyId, "Enable Policy")) {
                $Uri = "api/policies/$PolicyId/state"
                $Body = @{ action = "enable" }
                
                Invoke-SecretsHubApi -Uri $Uri -Method PUT -Body $Body
                Write-Host "Successfully enabled policy: $PolicyId" -ForegroundColor Green
            }
        }
        catch {
            Write-SecretsHubError -ErrorRecord $_ -Operation "Enable-Policy"
            throw
        }
    }
}
