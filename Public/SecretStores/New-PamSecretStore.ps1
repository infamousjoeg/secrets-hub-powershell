<#
.SYNOPSIS
Creates a new PAM secret store (Self-Hosted or PCloud).

.DESCRIPTION
Creates a source secret store for CyberArk PAM (Self-Hosted or Privileged Cloud).

.PARAMETER Name
The display name for the secret store.

.PARAMETER Description
Optional description for the secret store.

.PARAMETER Type
The PAM type (PAM_SELF_HOSTED or PAM_PCLOUD).

.PARAMETER Url
The PAM URL (PVWA URL for Self-Hosted, PCloud URL for PCloud).

.PARAMETER UserName
The username for Secrets Hub service account.

.PARAMETER Password
The password for the service account (Self-Hosted only).

.PARAMETER ConnectorId
The connector ID for Self-Hosted installations.

.PARAMETER ConnectorPoolId
The connector pool ID for Self-Hosted installations.

.PARAMETER State
The initial state of the secret store.

.EXAMPLE
New-PamSecretStore -Name "PAM-SelfHosted" -Type PAM_SELF_HOSTED -Url "https://pam.company.com/PasswordVault" -UserName "SecretsHub" -Password $SecurePassword

.EXAMPLE
New-PamSecretStore -Name "PAM-PCloud" -Type PAM_PCLOUD -Url "https://company.privilegecloud.cyberark.cloud" -UserName "SecretsHub"

.NOTES
PAM source stores provide secrets to sync to target stores.
#>
function New-PamSecretStore {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter()]
        [string]$Description,

        [Parameter(Mandatory = $true)]
        [ValidateSet('PAM_SELF_HOSTED', 'PAM_PCLOUD')]
        [string]$Type,

        [Parameter(Mandatory = $true)]
        [string]$Url,

        [Parameter(Mandatory = $true)]
        [string]$UserName,

        [Parameter()]
        [SecureString]$Password,

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
            if ($PSCmdlet.ShouldProcess($Name, "Create PAM Secret Store")) {
                $Data = @{
                    url = $Url
                    userName = $UserName
                }

                # Add password for Self-Hosted
                if ($Type -eq 'PAM_SELF_HOSTED') {
                    if (-not $Password) {
                        throw "Password is required for PAM_SELF_HOSTED type"
                    }

                    $PlainPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
                        [Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password)
                    )
                    $Data.password = $PlainPassword

                    if ($ConnectorId) { $Data.connectorId = $ConnectorId }
                    if ($ConnectorPoolId) { $Data.connectorPoolId = $ConnectorPoolId }
                }

                $Body = @{
                    type = $Type
                    name = $Name
                    state = $State
                    data = $Data
                }

                if ($Description) {
                    $Body.description = $Description
                }

                $Result = Invoke-SecretsHubApi -Uri "api/secret-stores" -Method POST -Body $Body
                Write-Information "Successfully created PAM secret store: $Name" -InformationAction Continue
                return $Result
            }
        }
        catch {
            Write-SecretsHubError -ErrorRecord $_ -Operation "New-PamSecretStore"
            throw
        }
        finally {
            # Clear sensitive data
            if ($PlainPassword) {
                [Runtime.GC]::Collect()
            }
        }
    }
}
