# CyberArk.SecretsHub PowerShell Module

[![PowerShell Gallery](https://img.shields.io/powershellgallery/v/CyberArk.SecretsHub.svg)](https://www.powershellgallery.com/packages/CyberArk.SecretsHub)
[![PowerShell Gallery Downloads](https://img.shields.io/powershellgallery/dt/CyberArk.SecretsHub.svg)](https://www.powershellgallery.com/packages/CyberArk.SecretsHub)
[![Build Status](https://github.com/infamousjoeg/secrets-hub-powershell/workflows/CI/badge.svg)](https://github.com/infamousjoeg/secrets-hub-powershell/actions)

PowerShell module for CyberArk Secrets Hub REST API automation, enabling DevOps teams to manage secret stores, sync policies, and secret operations programmatically.

## Features

- **Complete API Coverage**: All Secrets Hub REST API endpoints
- **Multi-Platform Support**: PowerShell 5.1+ and PowerShell Core on Windows, Linux, macOS
- **Authentication Integration**: Seamless integration with IdentityCommand module
- **Pipeline Support**: Full pipeline support for bulk operations
- **Error Handling**: Comprehensive error handling with retry logic
- **Beta API Support**: Clear handling and warnings for beta endpoints

## Installation

### From PowerShell Gallery

```powershell
Install-Module -Name CyberArk.SecretsHub -Scope CurrentUser
```

### Prerequisites

- PowerShell 5.1 or later
- [IdentityCommand](https://github.com/pspete/IdentityCommand) module for authentication

```powershell
Install-Module -Name IdentityCommand -Scope CurrentUser
```

## Quick Start

### 1. Establish Authentication

```powershell
# Using IdentityCommand for authentication
Connect-Identity -URL "https://your-identity-tenant.id.cyberark.cloud"

# Connect to Secrets Hub
Connect-SecretsHub -Subdomain "your-subdomain"
```

### 2. Manage Secret Stores

```powershell
# Create AWS Secrets Manager store
New-AwsSecretStore -Name "Dev-AWS-East" -AccountId "123456789012" `
    -AccountAlias "dev-account" -Region "us-east-1" -RoleName "SecretsHubRole"

# Create Azure Key Vault store
$ClientSecret = ConvertTo-SecureString "your-secret" -AsPlainText -Force
New-AzureSecretStore -Name "Dev-Azure-Vault" `
    -VaultUrl "https://myvault.vault.azure.net" `
    -ClientId "12345678-1234-1234-1234-123456789012" `
    -ClientSecret $ClientSecret `
    -TenantId "87654321-4321-4321-4321-210987654321"

# List all secret stores
Get-SecretStore -All

# Test connection
Get-SecretStore -All | Test-SecretStoreConnection
```

### 3. Create Sync Policies

```powershell
# Create a sync policy
New-Policy -Name "DevPolicy" `
    -SourceStoreId "store-source-123" `
    -TargetStoreId "store-target-456" `
    -SafeName "DevSafe"

# Enable policy
Enable-Policy -PolicyId "policy-123"

# Pipeline approach
New-Policy -Name "PipelinePolicy" | 
    Set-PolicySource -StoreId "store-123" | 
    Set-PolicyTarget -StoreId "store-456"
```

### 4. Work with Secrets (Beta)

```powershell
# List secrets (Beta feature)
Get-Secret -Filter "vendorType EQ AWS" -Limit 50

# Get secret value (Beta feature - use with caution)
$SecretValue = Get-SecretValue -SecretId "secret-123"
```

## Function Reference

### Connection Management
- `Connect-SecretsHub` - Connect to Secrets Hub
- `Disconnect-SecretsHub` - Disconnect from Secrets Hub

### Secret Stores
- `Get-SecretStore` - Get secret stores
- `New-AwsSecretStore` - Create AWS Secrets Manager store
- `New-AzureSecretStore` - Create Azure Key Vault store
- `New-GcpSecretStore` - Create GCP Secret Manager store
- `New-PamSecretStore` - Create PAM source store
- `Set-*SecretStore` - Update secret stores
- `Remove-SecretStore` - Delete secret store
- `Enable-SecretStore` / `Disable-SecretStore` - Manage store state
- `Test-SecretStoreConnection` - Test store connectivity

### Sync Policies
- `Get-Policy` - Get sync policies
- `New-Policy` - Create sync policy
- `Remove-Policy` - Delete policy
- `Enable-Policy` / `Disable-Policy` - Manage policy state
- `Set-PolicySource` / `Set-PolicyTarget` - Pipeline builders

### Secrets (Beta)
- `Get-Secret` - List secrets
- `Get-SecretValue` - Get secret value

### Scans (Beta)
- `Get-Scan` - Get scan information
- `Start-Scan` - Trigger scans

### Filters
- `Get-Filter` - Get secrets filters
- `New-Filter` - Create filter
- `Remove-Filter` - Delete filter

### Configuration
- `Get-Configuration` - Get configuration
- `Set-Configuration` - Update configuration

## Advanced Usage

### Error Handling

```powershell
try {
    $Store = New-AwsSecretStore -Name "Test" -AccountId "123456789012" `
        -AccountAlias "test" -Region "us-east-1" -RoleName "TestRole"
}
catch {
    Write-Error "Failed to create secret store: $($_.Exception.Message)"
}
```

### Bulk Operations

```powershell
# Enable multiple secret stores
Get-SecretStore -Behavior SECRETS_TARGET | 
    Where-Object { $_.state.current -eq 'DISABLED' } | 
    Enable-SecretStore

# Test all connections
Get-SecretStore -All | Test-SecretStoreConnection
```

### Pipeline Building

```powershell
# Complex policy creation with pipeline
$Policy = New-Policy -Name "ComplexPolicy" | 
    Set-PolicySource -StoreId $SourceStore.id | 
    Set-PolicyTarget -StoreId $TargetStore.id |
    ForEach-Object { 
        $_.SafeName = "ProdSafe"
        $_.Transformation = "password_only_plain_text"
        return $_
    }
```

### Working with Beta Features

```powershell
# Beta features show warnings
$Secrets = Get-Secret -Filter "syncedByCyberArk EQ true"
# WARNING: Get-Secret uses BETA APIs. Features may change without notice.

# Filter and sort secrets
$FilteredSecrets = Get-Secret -Filter "vendorType EQ AWS AND discoveredAt GE `"2024-01-01T00:00:00Z`"" `
    -Sort "name ASC" -Limit 100
```

## Configuration

### Environment Variables

```powershell
# For integration testing
$env:SECRETSHUB_SUBDOMAIN = "your-subdomain"
$env:SECRETSHUB_BASEURL = "https://your-subdomain.secretshub.cyberark.cloud"
```

### Custom Headers

```powershell
# The module automatically handles beta headers
# No manual header management required
```

## Testing

### Unit Tests

```powershell
# Run unit tests
Invoke-Pester -Path .\Tests\Unit\ -CodeCoverage

# Run specific test
Invoke-Pester -Path .\Tests\Unit\SecretStores.Tests.ps1
```

### Integration Tests

```powershell
# Set environment variables first
$env:SECRETSHUB_SUBDOMAIN = "your-test-subdomain"

# Run integration tests
Invoke-Pester -Path .\Tests\Integration\ -Tag Integration
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Run the test suite
6. Submit a pull request

### Development Setup

```powershell
# Clone repository
git clone https://github.com/infamousjoeg/secrets-hub-powershell.git
cd secrets-hub-powershell

# Install dependencies
Install-Module -Name Pester -Force
Install-Module -Name IdentityCommand -Force

# Run tests
.\build.ps1 -Task Test
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

- [Issues](https://github.com/cyberark/CyberArk.SecretsHub/issues)
- [Documentation](https://github.com/cyberark/CyberArk.SecretsHub/blob/main/docs/)
- [CyberArk Community](https://cyberark-customers.force.com/s/topic/0TO1J000000IMw8WAG/secrets-hub)

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for details on releases and changes.
