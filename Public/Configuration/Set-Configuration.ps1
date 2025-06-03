<#
.SYNOPSIS
Updates Secrets Hub configuration.

.DESCRIPTION
Updates configuration settings such as secret validity period.

.PARAMETER SecretValidity
The number of days secrets will be valid after sync (1-730 days).

.EXAMPLE
Set-Configuration -SecretValidity 300

.NOTES
Only sync settings can be updated via this API.
#>
function Set-Configuration {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateRange(1, 730)]
        [int]$SecretValidity
    )
    
    begin {
        Test-SecretsHubConnection
    }
    
    process {
        try {
            if ($PSCmdlet.ShouldProcess("Secrets Hub Configuration", "Update Secret Validity to $SecretValidity days")) {
                $Body = @{
                    syncSettings = @{
                        secretValidity = $SecretValidity
                    }
                }
                
                Invoke-SecretsHubApi -Uri "api/configuration" -Method PATCH -Body $Body
                Write-Host "Successfully updated configuration: Secret validity set to $SecretValidity days" -ForegroundColor Green
            }
        }
        catch {
            Write-SecretsHubError -ErrorRecord $_ -Operation "Set-Configuration"
            throw
        }
    }
}
