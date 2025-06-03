<#
.SYNOPSIS
Creates a new Azure Key Vault secret store.

.DESCRIPTION
Creates a new secret store for Azure Key Vault with specified configuration.

.PARAMETER Name
The display name for the secret store.

.PARAMETER Description
Optional description for the secret store.

.PARAMETER VaultUrl
The Azure Key Vault URL.

.PARAMETER ClientId
The Azure application client ID.

.PARAMETER ClientSecret
The Azure application client secret.

.PARAMETER TenantId
The Azure tenant/directory ID.

.PARAMETER SubscriptionId
The Azure subscription ID.

.PARAMETER SubscriptionName
The Azure subscription name.

.PARAMETER ResourceGroupName
The Azure resource group name.

.PARAMETER ConnectionType
The connection type (PUBLIC or CONNECTOR).

.PARAMETER ConnectorId
The connector ID (required for CONNECTOR connection type).

.PARAMETER ConnectorPoolId
The connector pool ID (required for CONNECTOR connection type).

.PARAMETER State
The initial state of the secret store (ENABLED or DISABLED).

.EXAMPLE
New-AzureSecretStore -Name "Dev-Azure-Vault" -VaultUrl "https://myvault.vault.azure.net" -ClientId "12345678-1234-1234-1234-123456789012" -ClientSecret $SecureSecret -TenantId "87654321-4321-4321-4321-210987654321"

.NOTES
Requires appropriate Azure permissions and application registration.
#>
function New-AzureSecretStore {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter()]
        [string]$Description,

        [Parameter(Mandatory = $true)]
        [string]$VaultUrl,

        [Parameter(Mandatory = $true)]
        [string]$ClientId,

        [Parameter(Mandatory = $true)]
        [SecureString]$ClientSecret,

        [Parameter(Mandatory = $true)]
        [string]$TenantId,

        [Parameter()]
        [string]$SubscriptionId,

        [Parameter()]
        [string]$SubscriptionName,

        [Parameter()]
        [string]$ResourceGroupName,

        [Parameter()]
        [ValidateSet('PUBLIC', 'CONNECTOR')]
        [string]$ConnectionType = 'PUBLIC',

        [Parameter()]
        [string]$ConnectorId,

        [Parameter()]
        [string]$ConnectorPoolId,

        [Parameter()]
        [ValidateSet('ENABLED', 'DISABLED')]
        [string]$State = 'ENABLED'
    )

    begin {
        Test-SecretsHubConnection
    }

    process {
        try {
            if ($PSCmdlet.ShouldProcess($Name, "Create Azure Secret Store")) {
                # Convert SecureString to plain text
                $PlainSecret = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
                    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($ClientSecret)
                )

                $ConnectionConfig = @{
                    connectionType = $ConnectionType
                }

                if ($ConnectionType -eq 'CONNECTOR') {
                    if (-not $ConnectorId) {
                        throw "ConnectorId is required when ConnectionType is CONNECTOR"
                    }
                    $ConnectionConfig.connectorId = $ConnectorId
                    if ($ConnectorPoolId) {
                        $ConnectionConfig.connectorPoolId = $ConnectorPoolId
                    }
                }

                $Body = @{
                    type = "AZURE_AKV"
                    name = $Name
                    state = $State
                    data = @{
                        azureVaultUrl = $VaultUrl
                        appClientId = $ClientId
                        appClientSecret = $PlainSecret
                        appClientDirectoryId = $TenantId
                        connectionConfig = $ConnectionConfig
                    }
                }

                if ($Description) { $Body.description = $Description }
                if ($SubscriptionId) { $Body.data.subscriptionId = $SubscriptionId }
                if ($SubscriptionName) { $Body.data.subscriptionName = $SubscriptionName }
                if ($ResourceGroupName) { $Body.data.resourceGroupName = $ResourceGroupName }

                $Result = Invoke-SecretsHubApi -Uri "api/secret-stores" -Method POST -Body $Body
                Write-Information "Successfully created Azure secret store: $Name" -InformationAction Continue
                return $Result
            }
        }
        catch {
            Write-SecretsHubError -ErrorRecord $_ -Operation "New-AzureSecretStore"
            throw
        }
        finally {
            # Clear sensitive data
            if ($PlainSecret) {
                [Runtime.GC]::Collect()
            }
        }
    }
}
