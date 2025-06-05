<#
.SYNOPSIS
Initializes a connection to Secrets Hub.

.DESCRIPTION
Internal function to establish connection and validate authentication.
#>
<#
.SYNOPSIS
Initializes a connection to Secrets Hub.

.DESCRIPTION
Internal function to establish connection and validate authentication.
Fixed version that properly stores the full token.
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

            Write-Verbose "Initializing connection with BaseUrl: $BaseUrl"

            # Get authentication token
            $Token = Get-SecretsHubToken -Credential $Credential
            Write-Verbose "Retrieved token with length: $($Token.Length)"

            # Validate token before using it
            if (-not $Token -or $Token.Length -lt 10) {
                throw "Invalid token retrieved: token is null or too short (length: $($Token.Length))"
            }

            # Create session object with explicit string conversion
            $Session = [PSCustomObject]@{
                BaseUrl = [string]$BaseUrl
                Token = [string]$Token  # Ensure this is stored as a string
                Headers = @{
                    'Authorization' = "Bearer $([string]$Token)"  # Explicit string conversion
                    'Content-Type' = 'application/json'
                    'Accept' = 'application/json'
                }
                Connected = $true
                ConnectedAt = Get-Date
            }

            # Validate the session was created correctly
            Write-Verbose "Session created - Token length: $($Session.Token.Length)"
            Write-Verbose "Session created - Auth header length: $($Session.Headers['Authorization'].Length)"

            # Test connection with a simple endpoint
            try {
                $TestUri = "${BaseUrl}api/info"
                Write-Verbose "Testing connection with: $TestUri"
                $TestResult = Invoke-RestMethod -Uri $TestUri -Headers $Session.Headers -Method GET -ErrorAction Stop
                Write-Verbose "Connection test successful"
                
                # Return the test result as well for the caller to use
                $Session | Add-Member -NotePropertyName 'TestResult' -NotePropertyValue $TestResult
            }
            catch {
                Write-Warning "Connection test failed, but proceeding with connection: $($_.Exception.Message)"
            }

            return $Session
        }
        catch {
            throw "Failed to initialize Secrets Hub connection: $($_.Exception.Message)"
        }
    }
}