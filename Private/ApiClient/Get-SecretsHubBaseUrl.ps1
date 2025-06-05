<#
.SYNOPSIS
Discovers Secrets Hub base URL from subdomain.

.DESCRIPTION
Uses platform discovery endpoint to find the appropriate base URL.
#>
function Get-SecretsHubBaseUrl {
    [CmdletBinding()]
    [OutputType([System.String])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Subdomain
    )

    process {
        try {
            $DiscoveryUrl = "https://platform-discovery.cyberark.cloud/api/v2/services/subdomain/$Subdomain"
            Write-Verbose "Discovering base URL for subdomain: $Subdomain"

            $Response = Invoke-RestMethod -Uri $DiscoveryUrl -Method GET -ErrorAction Stop

            # Look for Secrets Hub service
            $SecretsHubService = $Response.secrets_hub.api -replace '/api$', ''

            if (-not $SecretsHubService) {
                throw "Secrets Hub service not found for subdomain: $Subdomain"
            }

            $BaseUrl = $SecretsHubService

            if (-not $BaseUrl.EndsWith('/')) {
                $BaseUrl += '/'
            }

            Write-Verbose "Discovered base URL: $BaseUrl"
            return $BaseUrl
        }
        catch {
            # Fallback to standard URL format
            $FallbackUrl = "https://$Subdomain.secretshub.cyberark.cloud"
            Write-Warning "Platform discovery failed, using fallback URL: $FallbackUrl"
            Write-Error "Discovery failed: $($_.Exception.Message)" -ErrorAction Continue
            return $FallbackUrl
        }
    }
}