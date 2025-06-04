<#
.SYNOPSIS
Invokes Secrets Hub REST API.

.DESCRIPTION
Central function for making API calls with error handling and retry logic.
#>
function Invoke-SecretsHubApi {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Uri,

        [Parameter()]
        [string]$Method = 'GET',

        [Parameter()]
        [hashtable]$Body,

        [Parameter()]
        [hashtable]$QueryParameters,

        [Parameter()]
        [hashtable]$AdditionalHeaders,

        [Parameter()]
        [switch]$Beta,

        [Parameter()]
        [int]$MaxRetries = 3,

        [Parameter()]
        [int]$RetryDelay = 1
    )

    process {
        if (-not $script:SecretsHubSession) {
            throw "Not connected to Secrets Hub. Use Connect-SecretsHub first."
        }

        try {
            # Build full URI
            $FullUri = $script:SecretsHubSession.BaseUrl + $Uri.TrimStart('/')

            # Add query parameters
            if ($QueryParameters) {
                $QueryString = ($QueryParameters.GetEnumerator() | ForEach-Object {
                    "$($_.Key)=$([System.Web.HttpUtility]::UrlEncode($_.Value))"
                }) -join '&'
                $FullUri += "?$QueryString"
            }

            # Prepare headers
            $Headers = $script:SecretsHubSession.Headers.Clone()

            # Add beta header if needed
            if ($Beta) {
                $Headers['Accept'] = 'application/x.secretshub.beta+json'
            }

            # Add additional headers
            if ($AdditionalHeaders) {
                foreach ($Header in $AdditionalHeaders.GetEnumerator()) {
                    $Headers[$Header.Key] = $Header.Value
                }
            }

            # Prepare request parameters
            $RequestParams = @{
                Uri = $FullUri
                Method = $Method
                Headers = $Headers
                ErrorAction = 'Stop'
            }

            # Add body if provided
            if ($Body) {
                $RequestParams.Body = ($Body | ConvertTo-Json -Depth 10 -Compress)
                Write-Verbose "Request body: $($RequestParams.Body)"
            }

            # Retry logic
            $Attempt = 0
            do {
                $Attempt++
                try {
                    Write-Verbose "API call: $Method $FullUri (Attempt $Attempt)"
                    $Response = Invoke-RestMethod @RequestParams
                    return $Response
                }
                catch {
                    $StatusCode = $null
                    if ($_.Exception.Response) {
                        $StatusCode = [int]$_.Exception.Response.StatusCode
                    }

                    # Retry on transient errors
                    if ($Attempt -lt $MaxRetries -and ($StatusCode -eq 429 -or $StatusCode -ge 500)) {
                        Write-Warning "API call failed with status $StatusCode, retrying in $RetryDelay seconds..."
                        Start-Sleep -Seconds $RetryDelay
                        $RetryDelay *= 2  # Exponential backoff
                        continue
                    }

                    # Parse error response if available
                    $ErrorDetails = $null
                    try {
                        if ($_.Exception.Response) {
                            $Reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
                            $ErrorBody = $Reader.ReadToEnd()
                            $ErrorDetails = $ErrorBody | ConvertFrom-Json
                        }
                    }
                    catch {
                        # Log error parsing failure but continue with original error
                        Write-Verbose "Failed to parse error response: $($_.Exception.Message)"
                    }

                    # Throw with enhanced error information
                    if ($ErrorDetails) {
                        throw "API Error [$($ErrorDetails.code)]: $($ErrorDetails.message) - $($ErrorDetails.description)"
                    }
                    else {
                        throw "API Error: $($_.Exception.Message)"
                    }
                }
            } while ($Attempt -lt $MaxRetries)
        }
        catch {
            Write-Verbose "API call failed: $($_.Exception.Message)"
            throw
        }
    }
}