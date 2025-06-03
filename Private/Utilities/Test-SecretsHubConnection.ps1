<#
.SYNOPSIS
Tests if there's an active Secrets Hub connection.

.DESCRIPTION
Validates that a connection exists and is still valid.
#>
function Test-SecretsHubConnection {
    [CmdletBinding()]
    param()
    
    process {
        if (-not $script:SecretsHubSession) {
            throw "Not connected to Secrets Hub. Use Connect-SecretsHub to establish a connection."
        }
        
        if (-not $script:SecretsHubSession.Connected) {
            throw "Secrets Hub connection is not active. Use Connect-SecretsHub to re-establish connection."
        }
        
        # Optional: Check if token is still valid (implement based on your requirements)
        return $true
    }
}
