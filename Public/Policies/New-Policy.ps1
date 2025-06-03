<#
.SYNOPSIS
Creates a new sync policy in Secrets Hub.

.DESCRIPTION
Creates a policy that defines which secrets to sync from source to target secret store.
Supports pipeline building pattern and direct parameter specification.

.PARAMETER Name
The policy name.

.PARAMETER Description
Optional policy description.

.PARAMETER SourceStoreId
The ID of the source secret store.

.PARAMETER TargetStoreId
The ID of the target secret store.

.PARAMETER FilterData
Filter configuration object or hashtable.

.PARAMETER SafeName
Safe name for PAM_SAFE filter (convenience parameter).

.PARAMETER Transformation
Transformation type (default or password_only_plain_text).

.EXAMPLE
New-Policy -Name "DevPolicy" -SourceStoreId "store-123" -TargetStoreId "store-456" -SafeName "DevSafe"

.EXAMPLE
$Policy = New-Policy -Name "DevPolicy" -SourceStoreId "store-123" -TargetStoreId "store-456" -SafeName "DevSafe"
#>
function New-Policy {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter()]
        [string]$Description,

        [Parameter(Mandatory = $true)]
        [string]$SourceStoreId,

        [Parameter(Mandatory = $true)]
        [string]$TargetStoreId,

        [Parameter(ParameterSetName = 'FilterObject')]
        [object]$FilterData,

        [Parameter(ParameterSetName = 'SafeName')]
        [string]$SafeName,

        [Parameter()]
        [ValidateSet('default', 'password_only_plain_text')]
        [string]$Transformation = 'default'
    )

    begin {
        Test-SecretsHubConnection
    }

    process {
        try {
            if ($PSCmdlet.ShouldProcess($Name, "Create Sync Policy")) {
                # Build filter
                $Filter = $null
                if ($PSCmdlet.ParameterSetName -eq 'SafeName') {
                    $Filter = @{
                        type = "PAM_SAFE"
                        data = @{
                            safeName = $SafeName
                        }
                    }
                }
                elseif ($FilterData) {
                    $Filter = $FilterData
                }
                else {
                    throw "Either SafeName or FilterData must be provided"
                }

                $Body = @{
                    name = $Name
                    source = @{ id = $SourceStoreId }
                    target = @{ id = $TargetStoreId }
                    filter = $Filter
                    transformation = @{
                        predefined = $Transformation
                    }
                }

                if ($Description) {
                    $Body.description = $Description
                }

                $Result = Invoke-SecretsHubApi -Uri "api/policies" -Method POST -Body $Body
                Write-Information "Successfully created policy: $Name" -InformationAction Continue
                return $Result
            }
        }
        catch {
            Write-SecretsHubError -ErrorRecord $_ -Operation "New-Policy"
            throw
        }
    }
}
