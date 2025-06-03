<#
.SYNOPSIS
Gets the value of a specific secret (BETA).

.DESCRIPTION
Retrieves the actual value/content of a secret. This is a beta feature.

.PARAMETER SecretId
The unique identifier of the secret.

.EXAMPLE
Get-SecretValue -SecretId "secret-73135722-1aef-5481-6a17-d7d4d3a70731-ca9dd371"

.NOTES
This is a BETA feature. Use with extreme caution in production environments.
Handle returned values securely.
#>
function Get-SecretValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('Id')]
        [string]$SecretId
    )

    begin {
        Test-SecretsHubConnection
        Write-Warning "Get-SecretValue uses BETA APIs and returns sensitive data. Use with extreme caution."
    }

    process {
        try {
            $Uri = "api/secrets/$SecretId/value"
            $Result = Invoke-SecretsHubApi -Uri $Uri -Method GET -Beta
            return $Result
        }
        catch {
            Write-SecretsHubError -ErrorRecord $_ -Operation "Get-SecretValue"
            throw
        }
    }
}
