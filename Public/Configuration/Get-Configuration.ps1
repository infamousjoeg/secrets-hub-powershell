<#
.SYNOPSIS
Gets Secrets Hub configuration.

.DESCRIPTION
Retrieves the current configuration settings for Secrets Hub.

.EXAMPLE
Get-Configuration

.NOTES
Shows secrets source, authentication identities, and sync settings.
#>
function Get-Configuration {
    [CmdletBinding()]
    param()
    
    begin {
        Test-SecretsHubConnection
    }
    
    process {
        try {
            $Result = Invoke-SecretsHubApi -Uri "api/configuration" -Method GET
            return $Result
        }
        catch {
            Write-SecretsHubError -ErrorRecord $_ -Operation "Get-Configuration"
            throw
        }
    }
}
