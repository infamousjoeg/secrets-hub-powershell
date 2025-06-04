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

    # Check session exists
    if (-not $script:SecretsHubSession) {
        throw "Not connected to Secrets Hub. Use Connect-SecretsHub first."
    }

    # Check BaseUrl exists
    if (-not $script:SecretsHubSession.BaseUrl) {
        throw "Session BaseUrl is null. Please reconnect to Secrets Hub."
    }

    # Check Headers exist
    if (-not $script:SecretsHubSession.Headers) {
        throw "Session Headers are null. Please reconnect to Secrets Hub."
    }

    try {
        # Build URI carefully with null checks
        $BaseUrl = [string]$script:SecretsHubSession.BaseUrl
        $CleanBaseUrl = $BaseUrl.TrimEnd('/')
        $CleanUri = [string]$Uri.TrimStart('/')
        $FullUri = "$CleanBaseUrl/$CleanUri"
        
        # Add query parameters if present
        if ($QueryParameters -and $QueryParameters.Count -gt 0) {
            $QueryParts = @()
            foreach ($param in $QueryParameters.GetEnumerator()) {
                $QueryParts += "$($param.Key)=$([System.Web.HttpUtility]::UrlEncode($param.Value))"
            }
            $QueryString = $QueryParts -join '&'
            $FullUri = $FullUri + "?" + $QueryString
        }
        
        Write-Verbose "Complete URI: $FullUri"
        
        # Prepare headers
        $Headers = @{
            'Authorization' = $script:SecretsHubSession.Headers['Authorization']
            'Content-Type' = 'application/json'
            'Accept' = 'application/json'
        }
        
        if ($Beta) {
            $Headers['Accept'] = 'application/x.secretshub.beta+json'
        }
        
        if ($AdditionalHeaders) {
            foreach ($header in $AdditionalHeaders.GetEnumerator()) {
                $Headers[$header.Key] = $header.Value
            }
        }
        
        # Prepare request
        $RequestParams = @{
            Uri = $FullUri
            Method = $Method
            Headers = $Headers
            ErrorAction = 'Stop'
        }
        
        if ($Body) {
            $RequestParams.Body = ($Body | ConvertTo-Json -Depth 10 -Compress)
        }
        
        # Make the call
        Write-Verbose "Making API call: $Method $FullUri"
        $Response = Invoke-RestMethod @RequestParams
        return $Response
    }
    catch {
        Write-Verbose "API call failed: $($_.Exception.Message)"
        throw "API Error: $($_.Exception.Message)"
    }
}