# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.1] - 2025-06-05

### Added
- **Testing**: Comprehensive test suite for all Get-* commands (`Test-AllGetCommands.ps1`)
  - Tests all 13 Get-* functions with multiple parameter sets
  - Performance benchmarking with detailed timing metrics
  - Support for multiple output formats (Console, JSON, CSV)
  - Safety features for sensitive operations (Get-SecretValue)
  - CI/CD integration ready with proper exit codes
  - Beta API testing with appropriate warnings
  - Real-world data validation using actual store IDs and configurations

### Fixed
- **Critical**: Fixed token corruption bug in `Initialize-SecretsHubConnection` that caused authentication failures
  - Token was correctly extracted (2607 characters) but corrupted during session storage (reduced to 2 characters)
  - Added explicit string conversions and validation to ensure proper token storage
  - Resolved intermittent 401 Unauthorized errors that occurred after successful connection
- **Authentication**: Enhanced token extraction logic in `Get-SecretsHubToken` for better IdentityCommand integration
  - Improved handling of different IdentityCommand session data structures
  - Added multiple fallback strategies for token extraction
  - Enhanced verbose logging for better debugging
- **Parameters**: Fixed parameter binding issues in `Get-SecretStore` function
  - Corrected parameter set definitions to prevent "positional parameter cannot be found" errors
  - Improved parameter validation and error handling
  - Fixed `-All` parameter behavior for retrieving both source and target stores
- **Module Loading**: Enhanced module initialization with better error handling
  - Improved function import order to handle dependencies correctly
  - Added validation for critical function availability during module load
  - Enhanced verbose logging during module initialization
- **Testing Framework**: Resolved PowerShell datetime arithmetic issues in test script
  - Fixed `(Get-Date - $StartTime)` parsing errors that prevented test result collection
  - Improved test result capture ensuring all API tests are properly recorded
  - Enhanced error handling in test execution with better diagnostic output

### Improved
- **Error Handling**: Added comprehensive error handling for permission differences between SOURCE and TARGET store access
  - `Get-SecretStore -All` now gracefully handles scenarios where user has access to only target or source stores
  - Added descriptive warnings when certain store types are inaccessible
- **Session Management**: Enhanced session state validation and monitoring
  - Added session integrity checks to prevent corruption
  - Improved connection test reliability
  - Enhanced verbose output for troubleshooting
- **Debugging**: Added extensive verbose logging throughout authentication and API call chain
  - Token extraction steps now provide detailed logging
  - Session creation includes validation checkpoints
  - API calls include detailed URI and header information (with sensitive data protection)
- **Code Quality**: Enhanced PowerShell best practices compliance
  - Fixed PSScriptAnalyzer warnings by renaming conflicting parameter names
  - Improved variable usage and eliminated unused assignments
  - Better parameter validation and type handling

### Performance
- **Benchmarked Performance**: Validated enterprise-grade response times across all operations
  - Average API response time: ~432ms for standard operations
  - Sub-second performance for most secret store operations (315-674ms)
  - Acceptable performance for beta APIs (1-4 seconds)
  - Identified Get-Configuration as potentially slower endpoint (6.5s average)

### Testing Coverage
- **Comprehensive Validation**: 77% success rate (10/13 tests) in production environment
  - 100% success rate for all core secret store management functions
  - Full validation of authentication and session management
  - Beta API functionality confirmed working
  - Expected API limitations properly identified and handled

### Technical Details
- Fixed token storage corruption in session initialization
- Enhanced IdentityCommand integration with multiple extraction strategies
- Improved PowerShell parameter set definitions for better cmdlet behavior
- Added explicit type conversions to prevent object type issues
- Enhanced module loading sequence with dependency validation
- Created professional test framework with performance monitoring
- Implemented safety measures for sensitive secret value operations

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

[Unreleased]: https://github.com/infamousjoeg/secrets-hub-powershell/compare/v1.0.1...HEAD
[1.0.1]: https://github.com/infamousjoeg/secrets-hub-powershell/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/infamousjoeg/secrets-hub-powershell/releases/tag/v1.0.0