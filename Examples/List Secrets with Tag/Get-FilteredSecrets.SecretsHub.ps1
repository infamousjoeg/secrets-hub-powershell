Import-Module IdentityCommand
Import-Module CyberArk.SecretsHub

#### VARIABLES
$tenantId = "aap4212"
$subdomain = "pineapple"
$tagKeyId = "cyberark:appowner"

Write-Output "+ Authenticating to CyberArk Identity @ ${tenantId}"
New-IDSession -tenant_url "https://${tenantId}.id.cyberark.cloud" -Credential $credential | Out-Null
Write-Output "Successfully authenticated..."

Write-Output "+ Connecting to Secrets Hub @ ${subdomain}.secretshub.cyberark.cloud"
Connect-SecretsHub -BaseUrl "https://${subdomain}.secretshub.cyberark.cloud" -Force | Out-Null
Write-Output "Successfully connected..."

Write-Output "+ Fetching complete list of secrets from Secrets Hub Visibility"
$secrets = Get-Secret -Projection EXTEND
if ($null -eq $secrets) {
    Write-Error "No secrets found in the Secrets Hub. Please ensure you have secrets stored."
    exit
}

# Initialize array to store filtered secrets
$filteredSecrets = @()

$secrets | Where-Object { $_.vendorData.tags -and $_.vendorData.tags.${tagKeyId} } | ForEach-Object {
    $secretObject = $null
    $currentSecret = $_  # Store the current secret object
    $vendorTypeSubType = "$($currentSecret.vendorType)-$($currentSecret.vendorSubType)"
    
    Write-Output "Processing secret: $($currentSecret.name)"
    Write-Output "Vendor Type/SubType: $vendorTypeSubType"
    Write-Output "Tag value: $($currentSecret.vendorData.tags.${tagKeyId})"
    
    # Create PSObject based on vendor type and subtype
    switch ($vendorTypeSubType) {
        "AWS-ASM" {
            $secretObject = [PSCustomObject]@{
                VendorType = $currentSecret.vendorType
                VendorSubType = $currentSecret.vendorSubType
                Id = $currentSecret.id
                OriginId = $currentSecret.originId
                Name = $currentSecret.name
                StoreId = $currentSecret.storeId
                StoreName = $currentSecret.storeName
                DiscoveredAt = $currentSecret.discoveredAt
                SyncedByCyberArk = $currentSecret.syncedByCyberArk
                Onboarded = $currentSecret.onboarded
                VendorCreatedAt = $currentSecret.vendorData.createdAt
                VendorUpdatedAt = $currentSecret.vendorData.updatedAt
                VendorTags = $currentSecret.vendorData.tags
                VendorLastRetrievedAt = $currentSecret.lastRetrievedAt
                VendorRegion = $currentSecret.vendorData.region
                VendorKMSKeyId = $currentSecret.vendorData.kmsKeyId
                VendorAWSAccountID = $currentSecret.vendorData.awsAccountId
                LastScannedAt = $currentSecret.lastScannedAt
            }
        }
        "GCP-GSM" {
            $secretObject = [PSCustomObject]@{
                VendorType = $currentSecret.vendorType
                VendorSubType = $currentSecret.vendorSubType
                Id = $currentSecret.id
                OriginId = $currentSecret.originId
                Name = $currentSecret.name
                StoreId = $currentSecret.storeId
                StoreName = $currentSecret.storeName
                DiscoveredAt = $currentSecret.discoveredAt
                SyncedByCyberArk = $currentSecret.syncedByCyberArk
                Onboarded = $currentSecret.onboarded
                VendorCreatedAt = $currentSecret.vendorData.createdAt
                VendorTags = $currentSecret.vendorData.tags
                VendorProjectName = $currentSecret.vendorData.projectName
                VendorProjectNumber = $currentSecret.vendorData.projectNumber
                VendorSecretEnabledVersions = $currentSecret.vendorData.secretEnabledVersions
                VendorSecretType = $currentSecret.vendorData.secretType
                VendorEnabled = $currentSecret.vendorData.enabled
                VendorExpiresAt = $currentSecret.vendorData.expiresAt
                VendorAnnotations = $currentSecret.vendorData.annotations
                VendorReplicationMethod = $currentSecret.vendorData.replicationMethod
                LastScannedAt = $currentSecret.lastScannedAt
            }
        }
        "Azure-AKV" {
            $secretObject = [PSCustomObject]@{
                VendorType = $currentSecret.vendorType
                VendorSubType = $currentSecret.vendorSubType
                Id = $currentSecret.id
                OriginId = $currentSecret.originId
                Name = $currentSecret.name
                StoreId = $currentSecret.storeId
                StoreName = $currentSecret.storeName
                DiscoveredAt = $currentSecret.discoveredAt
                SyncedByCyberArk = $currentSecret.syncedByCyberArk
                Onboarded = $currentSecret.onboarded
                VendorCreatedAt = $currentSecret.vendorData.createdAt
                VendorUpdatedAt = $currentSecret.vendorData.updatedAt
                VendorTags = $currentSecret.vendorData.tags
                VendorSubscriptionId = $currentSecret.vendorData.subscriptionId
                VendorSubscriptionName = $currentSecret.vendorData.subscriptionName
                VendorResourceGroupName = $currentSecret.vendorData.resourceGroupName
                VendorExpiresAt = $currentSecret.vendorData.expiresAt
                VendorEnabled = $currentSecret.vendorData.enabled
                LastScannedAt = $currentSecret.lastScannedAt
            }
        }
        default {
            Write-Warning "Unsupported vendor type/subtype combination: $vendorTypeSubType for secret $($_.name)"
        }
    }
    
    # Debug output
    if ($null -ne $secretObject) {
        Write-Output "Created object for: $($_.name)"
        Write-Output "Object properties: VendorType=$($secretObject.VendorType), Name=$($secretObject.Name), StoreName=$($secretObject.StoreName)"
        $filteredSecrets += $secretObject
    } else {
        Write-Warning "No object created for: $($_.name) with type: $vendorTypeSubType"
    }
}

Write-Output "Successfully returned $($filteredSecrets.Count) secrets."

# Output results in a formatted table
if ($filteredSecrets.Count -gt 0) {
    Write-Output "`nFiltered Secrets Summary:"
    $filteredSecrets | Format-Table -Property VendorType, VendorSubType, Name, StoreName, Onboarded -AutoSize
    
    # Optional: Export to CSV for further analysis
    $exportPath = "./filtered-secrets-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv"
    $filteredSecrets | Export-Csv -Path $exportPath -NoTypeInformation
    Write-Output "`nExported detailed results to: $exportPath"
} else {
    Write-Warning "No secrets found matching the specified criteria (vendor types: AWS-ASM, GCP-GSM, Azure-AKV with 'cyberark:appowner' tag)"
}