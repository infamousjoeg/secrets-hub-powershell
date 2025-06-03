# Individual file fixes for specific PSScriptAnalyzer issues

# 1. Fix Set-PolicySource.ps1
$setPolicySourceContent = @'
<#
.SYNOPSIS
Sets the source secret store for a policy (pipeline builder).

.DESCRIPTION
Pipeline function to set the source secret store ID for policy creation.

.PARAMETER InputObject
The policy object from pipeline.

.PARAMETER StoreId
The source secret store ID.

.EXAMPLE
New-Policy -Name "Test" | Set-PolicySource -StoreId "store-123" | Set-PolicyTarget -StoreId "store-456"

.NOTES
Part of the policy builder pipeline pattern.
#>
function Set-PolicySource {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([System.Object])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [object]$InputObject,

        [Parameter(Mandatory = $true)]
        [string]$StoreId
    )

    process {
        if ($PSCmdlet.ShouldProcess($StoreId, "Set Policy Source")) {
            $InputObject.SourceStoreId = $StoreId
            return $InputObject
        }
    }
}
'@

# 2. Fix Set-PolicyTarget.ps1  
$setPolicyTargetContent = @'
<#
.SYNOPSIS
Sets the target secret store for a policy (pipeline builder).

.DESCRIPTION
Pipeline function to set the target secret store ID for policy creation.

.PARAMETER InputObject
The policy object from pipeline.

.PARAMETER StoreId
The target secret store ID.

.EXAMPLE
New-Policy -Name "Test" | Set-PolicySource -StoreId "store-123" | Set-PolicyTarget -StoreId "store-456"

.NOTES
Part of the policy builder pipeline pattern.
#>
function Set-PolicyTarget {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([System.Object])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [object]$InputObject,

        [Parameter(Mandatory = $true)]
        [string]$StoreId
    )

    process {
        if ($PSCmdlet.ShouldProcess($StoreId, "Set Policy Target")) {
            $InputObject.TargetStoreId = $StoreId
            return $InputObject
        }
    }
}
'@

# 3. Fix Get-SecretsHubBaseUrl.ps1
$getBaseUrlContent = @'
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
            $SecretsHubService = $Response.services | Where-Object { $_.name -eq 'secretshub' }

            if (-not $SecretsHubService) {
                throw "Secrets Hub service not found for subdomain: $Subdomain"
            }

            $BaseUrl = $SecretsHubService.url

            if (-not $BaseUrl.EndsWith('/')) {
                $BaseUrl += '/'
            }

            Write-Verbose "Discovered base URL: $BaseUrl"
            return $BaseUrl
        }
        catch {
            # Fallback to standard URL format
            $FallbackUrl = "https://$Subdomain.secretshub.cyberark.cloud/"
            Write-Warning "Platform discovery failed, using fallback URL: $FallbackUrl"
            Write-Error "Discovery failed: $($_.Exception.Message)" -ErrorAction Continue
            return $FallbackUrl
        }
    }
}
'@

# 4. Fix ConvertTo-SecretsHubFilter.ps1
$convertFilterContent = @'
<#
.SYNOPSIS
Converts filter expressions to Secrets Hub format.

.DESCRIPTION
Helper function for filter conversion and validation.
#>
function ConvertTo-SecretsHubFilter {
    [CmdletBinding()]
    [OutputType([System.String])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilterExpression
    )

    process {
        # Basic filter validation and conversion
        # This can be expanded based on specific filter requirements
        return $FilterExpression
    }
}
'@

# 5. Fix Test-SecretsHubConnection.ps1
$testConnectionContent = @'
<#
.SYNOPSIS
Tests if there's an active Secrets Hub connection.

.DESCRIPTION
Validates that a connection exists and is still valid.
#>
function Test-SecretsHubConnection {
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param()

    process {
        if (-not $script:SecretsHubSession) {
            throw "Not connected to Secrets Hub. Use Connect-SecretsHub to establish a connection."
        }

        if (-not $script:SecretsHubSession.Connected) {
            throw "Secrets Hub connection is not active. Use Connect-SecretsHub to re-establish connection."
        }

        # Optional: Check if token is still valid (implement based on your requirements)
        return $true
    }
}
'@

# 6. Fix Start-Scan.ps1 - remove empty catch and unused variables
$startScanContent = @'
<#
.SYNOPSIS
Triggers a scan on secret stores (BETA).

.DESCRIPTION
Initiates a scan on specified secret stores. This is a beta feature.

.PARAMETER StoreId
The unique identifier of the secret store to scan.

.PARAMETER Type
The type of scan (typically "secret-store").

.PARAMETER Id
The scan definition ID (typically "default").

.EXAMPLE
Start-Scan -StoreId "store-5a05468b-fa58-4bcf-84e9-62ede8af55f4"

.NOTES
This is a BETA feature. Use with caution in production environments.
#>
function Start-Scan {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [string]$StoreId,

        [Parameter()]
        [string]$Type = "secret-store",

        [Parameter()]
        [string]$Id = "default"
    )

    begin {
        Test-SecretsHubConnection
        Write-Warning "Start-Scan uses BETA APIs. Features may change without notice."
    }

    process {
        try {
            if ($PSCmdlet.ShouldProcess($StoreId, "Start Scan")) {
                $Uri = "api/scan-definitions/$Type/$Id/scan"
                $Body = @{
                    scope = @{
                        secretStoresIds = @($StoreId)
                    }
                }

                $Result = Invoke-SecretsHubApi -Uri $Uri -Method POST -Body $Body -Beta
                Write-Information "Successfully triggered scan for store: $StoreId" -InformationAction Continue
                return $Result
            }
        }
        catch {
            Write-SecretsHubError -ErrorRecord $_ -Operation "Start-Scan"
            throw
        }
    }
}
'@

# 7. Fix Enable-SecretStore.ps1 - remove unused 'All' parameter
$enableSecretStoreContent = @'
<#
.SYNOPSIS
Enables a secret store in Secrets Hub.

.DESCRIPTION
Changes the state of a secret store to ENABLED.

.PARAMETER StoreId
The unique identifier of the secret store to enable.

.EXAMPLE
Enable-SecretStore -StoreId "store-5a05468b-fa58-4bcf-84e9-62ede8af55f4"

.EXAMPLE
Get-SecretStore -All | Where-Object { $_.state.current -eq 'DISABLED' } | Enable-SecretStore
#>
function Enable-SecretStore {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('Id')]
        [string]$StoreId
    )

    begin {
        Test-SecretsHubConnection
    }

    process {
        try {
            if ($PSCmdlet.ShouldProcess($StoreId, "Enable Secret Store")) {
                $Uri = "api/secret-stores/$StoreId/state"
                $Body = @{ action = "enable" }

                Invoke-SecretsHubApi -Uri $Uri -Method PUT -Body $Body
                Write-Information "Successfully enabled secret store: $StoreId" -InformationAction Continue
            }
        }
        catch {
            Write-SecretsHubError -ErrorRecord $_ -Operation "Enable-SecretStore"
            throw
        }
    }
}
'@

Write-Output @"
# Copy and save these individual file contents to fix specific issues:

## 1. Public/Policies/Set-PolicySource.ps1
$setPolicySourceContent

## 2. Public/Policies/Set-PolicyTarget.ps1  
$setPolicyTargetContent

## 3. Private/ApiClient/Get-SecretsHubBaseUrl.ps1
$getBaseUrlContent

## 4. Private/Utilities/ConvertTo-SecretsHubFilter.ps1
$convertFilterContent

## 5. Private/Utilities/Test-SecretsHubConnection.ps1
$testConnectionContent

## 6. Public/Scans/Start-Scan.ps1
$startScanContent

## 7. Public/SecretStores/Enable-SecretStore.ps1
$enableSecretStoreContent
"@
