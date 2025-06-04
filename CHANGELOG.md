# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.0] - 2025-06-04

### Added
- Initial release of CyberArk.SecretsHub PowerShell module
- Complete coverage of Secrets Hub REST API endpoints
- Authentication integration with IdentityCommand module
- Auto-discovery of base URLs using platform discovery endpoint
- Comprehensive error handling with retry logic for transient failures
- Support for all secret store types (AWS, Azure, GCP, PAM)
- Sync policy management with pipeline builder pattern
- Beta API support with appropriate warnings
- Custom PowerShell formatting and type definitions
- Extensive test coverage with unit and integration tests
- GitHub Actions CI/CD pipeline
- PSScriptAnalyzer compliance
- Cross-platform support (Windows, Linux, macOS)
- PowerShell 5.1 and PowerShell Core compatibility

### Functions Added

#### Connection Management
- `Connect-SecretsHub` - Establish connection to Secrets Hub
- `Disconnect-SecretsHub` - Disconnect from Secrets Hub

#### Secret Stores
- `Get-SecretStore` - Retrieve secret stores
- `New-AwsSecretStore` - Create AWS Secrets Manager store
- `New-AzureSecretStore` - Create Azure Key Vault store  
- `New-GcpSecretStore` - Create GCP Secret Manager store
- `New-PamSecretStore` - Create PAM source store (Self-Hosted/PCloud)
- `Set-AwsSecretStore` - Update AWS secret store
- `Set-AzureSecretStore` - Update Azure secret store
- `Set-GcpSecretStore` - Update GCP secret store
- `Set-PamSecretStore` - Update PAM secret store
- `Remove-SecretStore` - Delete secret store
- `Enable-SecretStore` - Enable secret store
- `Disable-SecretStore` - Disable secret store
- `Test-SecretStoreConnection` - Test store connectivity

#### Sync Policies
- `Get-Policy` - Retrieve sync policies
- `New-Policy` - Create sync policy
- `Remove-Policy` - Delete sync policy
- `Enable-Policy` - Enable sync policy
- `Disable-Policy` - Disable sync policy
- `Set-PolicySource` - Set policy source (pipeline builder)
- `Set-PolicyTarget` - Set policy target (pipeline builder)

#### Secrets (Beta)
- `Get-Secret` - List discovered secrets
- `Get-SecretValue` - Retrieve secret values

#### Scans (Beta)
- `Get-Scan` - Get scan information
- `Start-Scan` - Trigger secret store scans

#### Filters
- `Get-Filter` - Retrieve secrets filters
- `New-Filter` - Create secrets filter
- `Remove-Filter` - Delete secrets filter

#### Configuration
- `Get-Configuration` - Get Secrets Hub configuration
- `Set-Configuration` - Update configuration settings

### Security
- Secure handling of sensitive parameters (passwords, secrets)
- Automatic token management and renewal
- Input validation and parameter constraints
- No sensitive data logging or output

### Documentation
- Comprehensive README with examples
- Complete comment-based help for all functions
- Integration examples for DevOps scenarios
- Contributing guidelines
- Security disclosure policy

[Unreleased]: https://github.com/infamousjoeg/secrets-hub-powershell/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/infamousjoeg/secrets-hub-powershell/releases/tag/v1.0.0
