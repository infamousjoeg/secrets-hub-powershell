<#
.SYNOPSIS
Gets authentication token for Secrets Hub.

.DESCRIPTION
Retrieves bearer token using IdentityCommand module or provided credentials.
Fixed version that properly handles IdentityCommand session data.
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
                    Write-Verbose "Attempting to retrieve IdentityCommand session"
                    $IdentitySession = Get-IDSession -ErrorAction SilentlyContinue
                    
                    if ($IdentitySession) {
                        Write-Verbose "Found IdentityCommand session for user: $($IdentitySession.User)"
                        
                        # The key insight: LastCommandResults might be a web response object
                        # Let's try multiple approaches to extract the token
                        
                        $Token = $null
                        
                        # Approach 1: Direct extraction from LastCommandResults
                        if ($IdentitySession.LastCommandResults) {
                            Write-Verbose "Attempting to extract token from LastCommandResults"
                            
                            try {
                                # If it's already a string/JSON, parse it directly
                                if ($IdentitySession.LastCommandResults -is [string]) {
                                    Write-Verbose "LastCommandResults is a string, parsing as JSON"
                                    $TokenData = $IdentitySession.LastCommandResults | ConvertFrom-Json -ErrorAction Stop
                                } else {
                                    # If it's a web response object, get the content
                                    Write-Verbose "LastCommandResults is an object, trying to extract content"
                                    $Content = $IdentitySession.LastCommandResults.Content
                                    if ($Content) {
                                        $TokenData = $Content | ConvertFrom-Json -ErrorAction Stop
                                    } else {
                                        # Try converting the object directly
                                        $TokenData = $IdentitySession.LastCommandResults | ConvertFrom-Json -ErrorAction Stop
                                    }
                                }
                                
                                # Extract token from the parsed data
                                if ($TokenData.Result -and $TokenData.Result.Token) {
                                    $Token = $TokenData.Result.Token
                                    Write-Verbose "Successfully extracted token from Result.Token (length: $($Token.Length))"
                                } elseif ($TokenData.access_token) {
                                    $Token = $TokenData.access_token
                                    Write-Verbose "Successfully extracted token from access_token (length: $($Token.Length))"
                                } elseif ($TokenData.token) {
                                    $Token = $TokenData.token
                                    Write-Verbose "Successfully extracted token from token (length: $($Token.Length))"
                                }
                                
                            } catch {
                                Write-Verbose "Could not parse LastCommandResults as JSON: $($_.Exception.Message)"
                            }
                        }
                        
                        # Approach 2: Try the same manual extraction that worked
                        if (-not $Token) {
                            Write-Verbose "Trying manual extraction approach that worked in testing"
                            try {
                                # Use the exact same approach that worked in the manual test
                                $IdSession = Get-IdSession
                                $TokenData = $IdSession.LastCommandResults | ConvertFrom-Json
                                if ($TokenData.Result.Token) {
                                    $Token = $TokenData.Result.Token
                                    Write-Verbose "Manual extraction successful (length: $($Token.Length))"
                                }
                            } catch {
                                Write-Verbose "Manual extraction approach failed: $($_.Exception.Message)"
                            }
                        }
                        
                        # Approach 3: Check for direct Token property on session
                        if (-not $Token -and $IdentitySession.Token) {
                            Write-Verbose "Using IdentityCommand session Token property"
                            $Token = $IdentitySession.Token
                        }
                        
                        # Validate and return token
                        if ($Token) {
                            # Validate JWT format
                            if ($Token -match '^eyJ[A-Za-z0-9_-]+\.eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+$') {
                                Write-Verbose "Token validated as JWT format (length: $($Token.Length))"
                                return $Token
                            } else {
                                Write-Verbose "Token doesn't appear to be JWT format, but proceeding anyway (length: $($Token.Length))"
                                return $Token
                            }
                        }
                        
                        # If we get here, token extraction failed
                        Write-Warning "IdentityCommand session found but no token could be extracted"
                        Write-Verbose "Session properties: $($IdentitySession.PSObject.Properties.Name -join ', ')"
                        
                        # Provide debugging info
                        if ($IdentitySession.LastCommandResults) {
                            $ResultType = $IdentitySession.LastCommandResults.GetType().FullName
                            Write-Verbose "LastCommandResults type: $ResultType"
                            
                            if ($IdentitySession.LastCommandResults -is [string]) {
                                Write-Verbose "LastCommandResults length: $($IdentitySession.LastCommandResults.Length)"
                            }
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
                throw "No active IdentityCommand session found or token could not be extracted. Please provide credentials or establish IdentityCommand session using New-IDSession."
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