<#
.SYNOPSIS
Creates a new AWS Secrets Manager secret store.

.DESCRIPTION
Creates a new secret store for AWS Secrets Manager with specified configuration.

.PARAMETER Name
The display name for the secret store.

.PARAMETER Description
Optional description for the secret store.

.PARAMETER AccountId
The 12-digit AWS account ID.

.PARAMETER AccountAlias
The AWS account alias.

.PARAMETER Region
The AWS region ID (e.g., us-east-1).

.PARAMETER RoleName
The AWS IAM role name for Secrets Hub access.

.PARAMETER State
The initial state of the secret store (ENABLED or DISABLED).

.EXAMPLE
New-AwsSecretStore -Name "Dev-AWS-East" -AccountId "123456789012" -AccountAlias "dev-account" -Region "us-east-1" -RoleName "SecretsHubRole"

.NOTES
Requires appropriate AWS IAM permissions and role setup.
#>
function New-AwsSecretStore {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter()]
        [string]$Description,

        [Parameter(Mandatory = $true)]
        [ValidatePattern('^\d{12}$')]
        [string]$AccountId,

        [Parameter(Mandatory = $true)]
        [string]$AccountAlias,

        [Parameter(Mandatory = $true)]
        [string]$Region,

        [Parameter(Mandatory = $true)]
        [string]$RoleName,

        [Parameter()]
        [ValidateSet('ENABLED', 'DISABLED')]
        [string]$State = 'ENABLED'
    )

    begin {
        Test-SecretsHubConnection
    }

    process {
        try {
            if ($PSCmdlet.ShouldProcess($Name, "Create AWS Secret Store")) {
                $Body = @{
                    type = "AWS_ASM"
                    name = $Name
                    state = $State
                    data = @{
                        accountId = $AccountId
                        accountAlias = $AccountAlias
                        regionId = $Region
                        roleName = $RoleName
                    }
                }

                if ($Description) {
                    $Body.description = $Description
                }

                $Result = Invoke-SecretsHubApi -Uri "api/secret-stores" -Method POST -Body $Body
                Write-Host "Successfully created AWS secret store: $Name" -ForegroundColor Green
                return $Result
            }
        }
        catch {
            Write-SecretsHubError -ErrorRecord $_ -Operation "New-AwsSecretStore"
            throw
        }
    }
}
