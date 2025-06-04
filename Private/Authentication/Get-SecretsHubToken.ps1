<#
.SYNOPSIS
Gets authentication token for Secrets Hub.

.DESCRIPTION
Retrieves bearer token using IdentityCommand module or provided credentials.
#>
function Get-SecretsHubToken {
    [CmdletBinding()]
    param(
        [Parameter()]
        [PSCredential]$Credential
    )

    process {
        try {
            # Try to use IdentityCommand session first
            if (-not $Credential -and (Get-Module -Name IdentityCommand)) {
                try {
                    # Use the correct function name for IdentityCommand
                    $IdentitySession = Get-IDSession -ErrorAction SilentlyContinue
                    if ($IdentitySession) {
                        Write-Verbose "Found IdentityCommand session for user: $($IdentitySession.User)"
                        
                        # Extract token from LastCommandResults
                        if ($IdentitySession.LastCommandResults) {
                            try {
                                $TokenData = $IdentitySession.LastCommandResults | ConvertFrom-Json
                                
                                # Check for nested Token in Result object (IdentityCommand structure)
                                if ($TokenData.Result -and $TokenData.Result.Token) {
                                    Write-Verbose "Using IdentityCommand session Result.Token"
                                    return $TokenData.Result.Token
                                }
                                # Fallback: Check for direct access_token
                                elseif ($TokenData.access_token) {
                                    Write-Verbose "Using IdentityCommand session access_token"
                                    return $TokenData.access_token
                                }
                            }
                            catch {
                                Write-Verbose "Could not parse token from LastCommandResults: $($_.Exception.Message)"
                            }
                        }
                        
                        # Fallback: Check if there's a Token property directly
                        if ($IdentitySession.Token) {
                            Write-Verbose "Using IdentityCommand session Token property"
                            return $IdentitySession.Token
                        }
                    }
                    else {
                        Write-Verbose "No IdentityCommand session found"
                    }
                }
                catch {
                    Write-Verbose "Could not retrieve IdentityCommand session: $($_.Exception.Message)"
                }
            }

            # If no IdentityCommand session, require credential
            if (-not $Credential) {
                throw "No active IdentityCommand session found. Please provide credentials or establish IdentityCommand session using New-IDSession."
            }

            # Use provided credentials (implement based on your auth requirements)
            Write-Verbose "Using provided credentials for authentication"
            # This would integrate with your specific authentication mechanism
            throw "Direct credential authentication not yet implemented. Please use IdentityCommand module with New-IDSession."
        }
        catch {
            throw "Failed to get authentication token: $($_.Exception.Message)"
        }
    }
}