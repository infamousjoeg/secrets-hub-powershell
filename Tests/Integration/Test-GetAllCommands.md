# Test-AllGetCommands.ps1 Usage Guide

## Overview
Comprehensive test script for all Get-* commands in the CyberArk.SecretsHub module. Tests functionality, performance, and error handling across all API endpoints.

## Quick Start

### Basic Usage
```powershell
# Test with subdomain (auto-discovery)
./Test-AllGetCommands.ps1 -Subdomain "pineapple"

# Test with explicit base URL
./Test-AllGetCommands.ps1 -BaseUrl "https://pineapple.secretshub.cyberark.cloud"
```

### Advanced Options
```powershell
# Detailed output with performance metrics
./Test-AllGetCommands.ps1 -Subdomain "pineapple" -Detailed -PerformanceTest

# Export results to JSON for reporting
./Test-AllGetCommands.ps1 -Subdomain "pineapple" -OutputFormat JSON

# Skip connection (if already connected)
./Test-AllGetCommands.ps1 -SkipConnection -Detailed
```

## Commands Tested

### Core Commands
- ✅ **Get-SecretStore** (Default, All, Target, Source, ById)
- ✅ **Get-Configuration** 
- ✅ **Get-Policy** (WithFilter, ById)
- ✅ **Get-Filter** (ByStoreId)

### Beta Commands
- ⚠️ **Get-Scan** (Default)
- ⚠️ **Get-Secret** (Default, WithFilter) 
- ⚠️ **Get-SecretValue** (ById) - *Only runs with -Detailed flag*

## Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `-Subdomain` | String | Secrets Hub subdomain for auto-discovery |
| `-BaseUrl` | String | Explicit base URL for Secrets Hub |
| `-SkipConnection` | Switch | Skip connection step (assume already connected) |
| `-Detailed` | Switch | Show detailed output including sample data |
| `-PerformanceTest` | Switch | Include performance timing metrics |
| `-OutputFormat` | String | Output format: Console, JSON, CSV |

## Output Formats

### Console (Default)
Real-time progress with color-coded results:
```
✓ Success: 14 items (310.5ms)
✗ Failed: API Error: Response status code does not indicate success: 400 (Bad Request)
⚠ Skipped: No store ID available for filter test
```

### JSON Export
Structured data for reporting and analysis:
```json
{
  "Command": "Get-SecretStore",
  "ParameterSet": "All",
  "Status": "Success",
  "ResultCount": 14,
  "Duration": 310.5,
  "Timestamp": "2025-06-05 10:30:45"
}
```

### CSV Export
Tabular format for spreadsheet analysis.

## Example Output

```
=== CyberArk.SecretsHub Get-* Commands Test Suite ===
Started: 2025-06-05 10:30:45

1. Verifying module...
   ✓ Module imported successfully

2. Establishing connection...
   ✓ Connected successfully

3. Testing Get-* commands...

Testing Get-SecretStore...
  Testing Get-SecretStore (Default)...
    ✓ Success: 13 items (245.2ms)
  Testing Get-SecretStore (All)...
    ✓ Success: 14 items (310.5ms)
  Testing Get-SecretStore (Target)...
    ✓ Success: 13 items (198.7ms)
  Testing Get-SecretStore (Source)...
    ✓ Success: 1 items (156.3ms)
  Testing Get-SecretStore (ById)...
    ✓ Success: 1 items (89.4ms)

Testing Get-Configuration...
  Testing Get-Configuration (Default)...
    ✓ Success: 1 items (123.8ms)

=== Test Results Summary ===
Total Tests: 12
✓ Successful: 10
✗ Failed: 1
⚠ Skipped: 1
Duration: 3.45 seconds

✅ All critical tests passed successfully!
```

## CI/CD Integration

### GitHub Actions
```yaml
- name: Test CyberArk.SecretsHub Module
  shell: pwsh
  run: |
    Import-Module IdentityCommand
    Import-Module CyberArk.SecretsHub
    New-IdSession -tenant_url $TENANT_URL -Credential $PSCREDENTIALOBJECT
    ./Test-AllGetCommands.ps1 -Subdomain $env:SUBDOMAIN -OutputFormat JSON
    
- name: Upload Test Results
  uses: actions/upload-artifact@v4
  if: always()
  with:
    name: secretshub-test-results
    path: test-results-*.json
```

### Azure DevOps
```yaml
- task: PowerShell@2
  displayName: 'Test SecretsHub Module'
  inputs:
    targetType: 'filePath'
    filePath: './Test-AllGetCommands.ps1'
    arguments: '-Subdomain $(SUBDOMAIN) -PerformanceTest -OutputFormat CSV'
  continueOnError: true

- task: PublishTestResults@2
  displayName: 'Publish Test Results'
  inputs:
    testResultsFormat: 'VSTest'
    testResultsFiles: 'test-results-*.csv'
```

## Safety Features

- **Get-SecretValue Protection**: Only runs with `-Detailed` flag since it retrieves actual secret values
- **Beta API Warnings**: Clear indication of beta features
- **Graceful Degradation**: Skips tests when resources aren't available
- **Error Isolation**: Failed tests don't stop the entire suite

## Troubleshooting

### Common Issues

**Connection Failed**
```
✗ Connection failed: No active IdentityCommand session found
```
*Solution*: Run `Connect-Identity` first

**No Policies Found**
```
⚠ Skipped: No policies available for ID test
```
*Solution*: Normal if no sync policies are configured

**Permission Denied**
```
✗ Failed: Response status code does not indicate success: 403 (Forbidden)
```
*Solution*: Check user permissions for the specific API endpoint

## Performance Benchmarks

Typical performance on a standard environment:
- Get-SecretStore (All): ~300ms
- Get-Configuration: ~120ms  
- Get-Policy: ~200ms
- Beta APIs: ~400-600ms (higher latency expected)

Use `-PerformanceTest` to get detailed metrics for your environment.