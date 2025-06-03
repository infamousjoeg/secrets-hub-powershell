<#
.SYNOPSIS
Establishes a connection to CyberArk Secrets Hub.

.DESCRIPTION
Connects to CyberArk Secrets Hub using authentication from IdentityCommand module.
Auto-discovers base URLs using platform discovery or accepts explicit base URL.

.PARAMETER Subdomain
The Secrets Hub subdomain for auto-discovery.

.PARAMETER BaseUrl
Explicit base URL for Secrets Hub API. Overrides subdomain discovery.

.PARAMETER Credential
PSCredential object for authentication. If not provided, uses IdentityCommand session.

.PARAMETER Force
Force a new connection even if one already exists.

.EXAMPLE
Connect-SecretsHub -Subdomain "mycompany"

.EXAMPLE
Connect-SecretsHub -BaseUrl "https://mycompany.secretshub.cyberark.cloud"

.NOTES
Requires IdentityCommand module for authentication.
#>
function Connect-SecretsHub {
    [CmdletBinding(DefaultParameterSetName = 'Subdomain')]
    param(
        [Parameter(Mandatory = $true, ParameterSetName = 'Subdomain')]
        [string]$Subdomain,
        
        [Parameter(Mandatory = $true, ParameterSetName = 'BaseUrl')]
        [string]$BaseUrl,
        
        [Parameter()]
        [PSCredential]$Credential,
        
        [Parameter()]
        [switch]$Force
    )
    
    begin {
        Write-Verbose "Starting connection to Secrets Hub"
    }
    
    process {
        try {
            # Check for existing connection
            if ($script:SecretsHubSession -and -not $Force) {
                Write-Warning "Already connected to Secrets Hub. Use -Force to create a new connection."
                return $script:SecretsHubSession
            }
            
            # Get base URL
            if ($PSCmdlet.ParameterSetName -eq 'Subdomain') {
                $BaseUrl = Get-SecretsHubBaseUrl -Subdomain $Subdomain
            }
            
            # Initialize connection
            $Session = Initialize-SecretsHubConnection -BaseUrl $BaseUrl -Credential $Credential
            $script:SecretsHubSession = $Session
            
            Write-Host "Successfully connected to Secrets Hub: $($Session.BaseUrl)" -ForegroundColor Green
            return $Session
        }
        catch {
            Write-SecretsHubError -ErrorRecord $_ -Operation "Connect-SecretsHub"
            throw
        }
    }
}
