<#
.SYNOPSIS
Creates a new GCP Secret Manager secret store.

.DESCRIPTION
Creates a new secret store for Google Cloud Secret Manager with specified configuration.

.PARAMETER Name
The display name for the secret store.

.PARAMETER Description
Optional description for the secret store.

.PARAMETER ProjectName
The GCP project name.

.PARAMETER ProjectNumber
The GCP project number.

.PARAMETER WorkloadIdentityPoolId
The GCP workload identity pool ID.

.PARAMETER PoolProviderId
The GCP pool provider ID.

.PARAMETER ServiceAccountEmail
The service account email.

.PARAMETER State
The initial state of the secret store (ENABLED or DISABLED).

.EXAMPLE
New-GcpSecretStore -Name "Dev-GCP-Secrets" -ProjectName "my-project" -ProjectNumber "123456789" -WorkloadIdentityPoolId "my-pool" -PoolProviderId "my-provider" -ServiceAccountEmail "service@project.iam.gserviceaccount.com"

.NOTES
Requires appropriate GCP permissions and service account setup.
#>
function New-GcpSecretStore {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter()]
        [string]$Description,

        [Parameter(Mandatory = $true)]
        [string]$ProjectName,

        [Parameter(Mandatory = $true)]
        [string]$ProjectNumber,

        [Parameter(Mandatory = $true)]
        [string]$WorkloadIdentityPoolId,

        [Parameter(Mandatory = $true)]
        [string]$PoolProviderId,

        [Parameter(Mandatory = $true)]
        [string]$ServiceAccountEmail,

        [Parameter()]
        [ValidateSet('ENABLED', 'DISABLED')]
        [string]$State = 'ENABLED'
    )

    begin {
        Test-SecretsHubConnection
    }

    process {
        try {
            if ($PSCmdlet.ShouldProcess($Name, "Create GCP Secret Store")) {
                $Body = @{
                    type = "GCP_GSM"
                    name = $Name
                    state = $State
                    data = @{
                        gcpProjectName = $ProjectName
                        gcpProjectNumber = $ProjectNumber
                        gcpWorkloadIdentityPoolId = $WorkloadIdentityPoolId
                        gcpPoolProviderId = $PoolProviderId
                        serviceAccountEmail = $ServiceAccountEmail
                        connectionConfig = @{
                            connectionType = "PUBLIC"
                        }
                    }
                }

                if ($Description) {
                    $Body.description = $Description
                }

                $Result = Invoke-SecretsHubApi -Uri "api/secret-stores" -Method POST -Body $Body
                Write-Host "Successfully created GCP secret store: $Name" -ForegroundColor Green
                return $Result
            }
        }
        catch {
            Write-SecretsHubError -ErrorRecord $_ -Operation "New-GcpSecretStore"
            throw
        }
    }
}
