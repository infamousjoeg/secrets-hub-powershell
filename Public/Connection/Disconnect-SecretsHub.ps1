<#
.SYNOPSIS
Disconnects from CyberArk Secrets Hub.

.DESCRIPTION
Cleans up the current Secrets Hub session and clears authentication tokens.

.EXAMPLE
Disconnect-SecretsHub
#>
function Disconnect-SecretsHub {
    [CmdletBinding()]
    param()
    
    process {
        if ($script:SecretsHubSession) {
            Write-Verbose "Disconnecting from Secrets Hub"
            $script:SecretsHubSession = $null
            Write-Host "Disconnected from Secrets Hub" -ForegroundColor Yellow
        }
        else {
            Write-Warning "No active Secrets Hub connection found"
        }
    }
}
