<#
.SYNOPSIS
Initializes a connection to Secrets Hub.

.DESCRIPTION
Internal function to establish connection and validate authentication.
#>
function Initialize-SecretsHubConnection {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$BaseUrl,

        [Parameter()]
        [PSCredential]$Credential
    )

    process {
        try {
            # Normalize base URL
            if (-not $BaseUrl.EndsWith('/')) {
                $BaseUrl += '/'
            }

            # Get authentication token
            $Token = Get-SecretsHubToken -Credential $Credential

            # Create session object
            $Session = [PSCustomObject]@{
                BaseUrl = $BaseUrl
                Token = $Token
                Headers = @{
                    'Authorization' = "Bearer $Token"
                    'Content-Type' = 'application/json'
                    'Accept' = 'application/json'
                }
                Connected = $true
                ConnectedAt = Get-Date
            }

            # Test connection
            try {
                Invoke-RestMethod -Uri "${BaseUrl}api/info" -Headers $Session.Headers -Method GET -ErrorAction Stop
                Write-Verbose "Connection test successful"
            }
            catch {
                Write-Warning "Connection test failed, but proceeding with connection"
            }

            return $Session
        }
        catch {
            throw "Failed to initialize Secrets Hub connection: $($_.Exception.Message)"
        }
    }
}