#!/usr/bin/env pwsh
<#
.SYNOPSIS
Comprehensive test script for all Get-* commands in CyberArk.SecretsHub module.

.DESCRIPTION
Tests every Get-* command with various parameter combinations to validate functionality,
performance, and error handling. Useful for validation, CI/CD pipelines, and troubleshooting.

.PARAMETER BaseUrl
The base URL for Secrets Hub connection.

.PARAMETER Subdomain
The subdomain for Secrets Hub (alternative to BaseUrl).

.PARAMETER SkipConnection
Skip the connection step (assumes already connected).

.PARAMETER Detailed
Show detailed output including response previews.

.PARAMETER PerformanceTest
Include performance timing for all operations.

.PARAMETER OutputFormat
Output format: Console, JSON, or CSV.

.EXAMPLE
./Test-AllGetCommands.ps1 -Subdomain "mycompany" -Detailed

.EXAMPLE
./Test-AllGetCommands.ps1 -BaseUrl "https://mycompany.secretshub.cyberark.cloud" -PerformanceTest -OutputFormat JSON

.NOTES
Requires IdentityCommand module and active session.
Some commands may require specific permissions or configuration.
#>

[CmdletBinding(DefaultParameterSetName = 'Subdomain')]
param(
    [Parameter(Mandatory = $true, ParameterSetName = 'BaseUrl')]
    [string]$BaseUrl,

    [Parameter(Mandatory = $true, ParameterSetName = 'Subdomain')]
    [string]$Subdomain,

    [Parameter()]
    [switch]$SkipConnection,

    [Parameter()]
    [switch]$Detailed,

    [Parameter()]
    [switch]$PerformanceTest,

    [Parameter()]
    [ValidateSet('Console', 'JSON', 'CSV')]
    [string]$OutputFormat = 'Console'
)

# Initialize results collection
$TestResults = @()
$OverallStartTime = Get-Date

# Helper function to create test result objects
function New-TestResult {
    param(
        [string]$Command,
        [string]$ParameterSet,
        [string]$Status,
        [string]$Message,
        [int]$ResultCount = 0,
        [double]$Duration = 0,
        [object]$ErrorDetails = $null,
        [object]$SampleData = $null
    )
    
    return [PSCustomObject]@{
        Command = $Command
        ParameterSet = $ParameterSet
        Status = $Status
        Message = $Message
        ResultCount = $ResultCount
        Duration = $Duration
        ErrorDetails = $ErrorDetails
        SampleData = $SampleData
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
}

# Helper function to execute test with timing
function Invoke-TestCommand {
    param(
        [string]$CommandName,
        [string]$ParameterSetName,
        [scriptblock]$ScriptBlock,
        [switch]$Beta
    )
    
    $StartTime = Get-Date
    
    try {
        if ($Beta) {
            Write-Host "  [BETA] Testing $CommandName ($ParameterSetName)..." -ForegroundColor Yellow
        } else {
            Write-Host "  Testing $CommandName ($ParameterSetName)..." -ForegroundColor Cyan
        }
        
        $Result = & $ScriptBlock
        $EndTime = Get-Date
        $Duration = ($EndTime - $StartTime).TotalMilliseconds
        
        $ResultCount = if ($Result) {
            if ($Result -is [array]) { $Result.Count } else { 1 }
        } else { 0 }
        
        $SampleData = if ($Detailed -and $Result) {
            if ($Result -is [array] -and $Result.Count -gt 0) {
                $Result[0] | Select-Object -Property * -First 1
            } else {
                $Result | Select-Object -Property * -First 1
            }
        } else { $null }
        
        $TestResult = New-TestResult -Command $CommandName -ParameterSet $ParameterSetName -Status "Success" -Message "Retrieved $ResultCount items" -ResultCount $ResultCount -Duration $Duration -SampleData $SampleData
        
        Write-Host "    ✓ Success: $ResultCount items ($([math]::Round($Duration, 2))ms)" -ForegroundColor Green
        
        if ($Detailed -and $SampleData) {
            Write-Host "    Sample data: $($SampleData | ConvertTo-Json -Compress)" -ForegroundColor DarkGreen
        }
        
        return $TestResult
    }
    catch {
        $EndTime = Get-Date
        $Duration = ($EndTime - $StartTime).TotalMilliseconds
        $ErrorMessage = $_.Exception.Message
        
        $TestResult = New-TestResult -Command $CommandName -ParameterSet $ParameterSetName -Status "Failed" -Message $ErrorMessage -Duration $Duration -ErrorDetails $_
        
        Write-Host "    ✗ Failed: $ErrorMessage ($([math]::Round($Duration, 2))ms)" -ForegroundColor Red
        
        return $TestResult
    }
}

# Display header
Write-Host "=== CyberArk.SecretsHub Get-* Commands Test Suite ===" -ForegroundColor Green
Write-Host "Started: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Green
Write-Host ""

# Step 1: Verify module is loaded
Write-Host "1. Verifying module..." -ForegroundColor Yellow
if (-not (Get-Module CyberArk.SecretsHub)) {
    try {
        Import-Module CyberArk.SecretsHub -Force
        Write-Host "   ✓ Module imported successfully" -ForegroundColor Green
    } catch {
        Write-Host "   ✗ Failed to import module: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "   ✓ Module already loaded" -ForegroundColor Green
}

# Step 2: Connection (if not skipped)
if (-not $SkipConnection) {
    Write-Host "`n2. Establishing connection..." -ForegroundColor Yellow
    try {
        if ($PSCmdlet.ParameterSetName -eq 'BaseUrl') {
            Connect-SecretsHub -BaseUrl $BaseUrl -Force | Out-Null
        } else {
            Connect-SecretsHub -Subdomain $Subdomain -Force | Out-Null
        }
        Write-Host "   ✓ Connected successfully" -ForegroundColor Green
    } catch {
        Write-Host "   ✗ Connection failed: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "`n2. Skipping connection (assuming already connected)" -ForegroundColor Yellow
}

# Step 3: Test all Get-* commands
Write-Host "`n3. Testing Get-* commands..." -ForegroundColor Yellow

# Test Get-SecretStore
Write-Host "`nTesting Get-SecretStore..." -ForegroundColor Magenta
$TestResults += Invoke-TestCommand -CommandName "Get-SecretStore" -ParameterSetName "Default" -ScriptBlock {
    Get-SecretStore
}
$TestResults += Invoke-TestCommand -CommandName "Get-SecretStore" -ParameterSetName "All" -ScriptBlock {
    Get-SecretStore -All
}
$TestResults += Invoke-TestCommand -CommandName "Get-SecretStore" -ParameterSetName "Target" -ScriptBlock {
    Get-SecretStore -Behavior SECRETS_TARGET
}
$TestResults += Invoke-TestCommand -CommandName "Get-SecretStore" -ParameterSetName "Source" -ScriptBlock {
    Get-SecretStore -Behavior SECRETS_SOURCE
}

# Get a store ID for individual testing
$TestStoreId = $null
try {
    $AllStores = Get-SecretStore -All -ErrorAction SilentlyContinue
    if ($AllStores -and $AllStores.Count -gt 0) {
        $TestStoreId = $AllStores[0].id
        $TestResults += Invoke-TestCommand -CommandName "Get-SecretStore" -ParameterSetName "ById" -ScriptBlock {
            Get-SecretStore -StoreId $TestStoreId
        }
    }
} catch {
    $TestResults += New-TestResult -Command "Get-SecretStore" -ParameterSet "ById" -Status "Skipped" -Message "No stores available for ID test"
}

# Test Get-Configuration
Write-Host "`nTesting Get-Configuration..." -ForegroundColor Magenta
$TestResults += Invoke-TestCommand -CommandName "Get-Configuration" -ParameterSetName "Default" -ScriptBlock {
    Get-Configuration
}

# Test Get-Policy
Write-Host "`nTesting Get-Policy..." -ForegroundColor Magenta
$TestResults += Invoke-TestCommand -CommandName "Get-Policy" -ParameterSetName "WithFilter" -ScriptBlock {
    Get-Policy -Filter "createdAt GE `"2020-01-01T00:00:00Z`""
}

# Try to get a policy ID for individual testing
$TestPolicyId = $null
try {
    $AllPolicies = Get-Policy -Filter "name LIKE '%'" -ErrorAction SilentlyContinue
    if ($AllPolicies -and $AllPolicies.Count -gt 0) {
        $TestPolicyId = $AllPolicies[0].id
        $TestResults += Invoke-TestCommand -CommandName "Get-Policy" -ParameterSetName "ById" -ScriptBlock {
            Get-Policy -PolicyId $TestPolicyId
        }
    }
} catch {
    $TestResults += New-TestResult -Command "Get-Policy" -ParameterSet "ById" -Status "Skipped" -Message "No policies available for ID test"
}

# Test Get-Filter
Write-Host "`nTesting Get-Filter..." -ForegroundColor Magenta
if ($TestStoreId) {
    $TestResults += Invoke-TestCommand -CommandName "Get-Filter" -ParameterSetName "ByStoreId" -ScriptBlock {
        Get-Filter -StoreId $TestStoreId
    }
} else {
    $TestResults += New-TestResult -Command "Get-Filter" -ParameterSet "ByStoreId" -Status "Skipped" -Message "No store ID available for filter test"
}

# Test Get-Scan (Beta)
Write-Host "`nTesting Get-Scan (Beta)..." -ForegroundColor Magenta
$TestResults += Invoke-TestCommand -CommandName "Get-Scan" -ParameterSetName "Default" -ScriptBlock {
    Get-Scan
} -Beta

# Test Get-Secret (Beta)
Write-Host "`nTesting Get-Secret (Beta)..." -ForegroundColor Magenta
$TestResults += Invoke-TestCommand -CommandName "Get-Secret" -ParameterSetName "Default" -ScriptBlock {
    Get-Secret -Limit 10
} -Beta

$TestResults += Invoke-TestCommand -CommandName "Get-Secret" -ParameterSetName "WithFilter" -ScriptBlock {
    Get-Secret -Filter "syncedByCyberArk EQ true" -Limit 5
} -Beta

# Test Get-SecretValue (Beta) - Only if we have secrets
$TestSecretId = $null
try {
    $Secrets = Get-Secret -Limit 1 -ErrorAction SilentlyContinue
    if ($Secrets -and $Secrets.Count -gt 0) {
        # Try different possible ID field names
        $TestSecretId = if ($Secrets[0].id) { 
            $Secrets[0].id 
        } elseif ($Secrets[0].secretId) { 
            $Secrets[0].secretId 
        } elseif ($Secrets[0].externalId) { 
            $Secrets[0].externalId 
        } else { 
            $null 
        }
        
        if ($TestSecretId) {
            Write-Host "`nTesting Get-SecretValue (Beta)..." -ForegroundColor Magenta
            Write-Host "   ⚠️  WARNING: This will retrieve actual secret values!" -ForegroundColor Yellow
            
            # Only test if detailed mode is enabled (as a safety measure)
            if ($Detailed) {
                $TestResults += Invoke-TestCommand -CommandName "Get-SecretValue" -ParameterSetName "ById" -ScriptBlock {
                    Get-SecretValue -SecretId $TestSecretId
                } -Beta
            } else {
                $TestResults += New-TestResult -Command "Get-SecretValue" -ParameterSet "ById" -Status "Skipped" -Message "Skipped for security (use -Detailed to enable)"
            }
        } else {
            $TestResults += New-TestResult -Command "Get-SecretValue" -ParameterSet "ById" -Status "Skipped" -Message "No valid secret ID found in secret objects"
        }
    } else {
        $TestResults += New-TestResult -Command "Get-SecretValue" -ParameterSet "ById" -Status "Skipped" -Message "No secrets available for value test"
    }
} catch {
    $TestResults += New-TestResult -Command "Get-SecretValue" -ParameterSet "ById" -Status "Skipped" -Message "Error retrieving secrets for ID test: $($_.Exception.Message)"
}

# Step 4: Summary and Analysis
$OverallEndTime = Get-Date
$OverallDuration = ($OverallEndTime - $OverallStartTime).TotalSeconds
Write-Host "`n=== Test Results Summary ===" -ForegroundColor Green
Write-Host "DEBUG: Collected $($TestResults.Count) test results" -ForegroundColor DarkGray

$SuccessCount = ($TestResults | Where-Object { $_.Status -eq "Success" }).Count
$FailedCount = ($TestResults | Where-Object { $_.Status -eq "Failed" }).Count
$SkippedCount = ($TestResults | Where-Object { $_.Status -eq "Skipped" }).Count
$TotalTests = $TestResults.Count

Write-Host "Total Tests: $TotalTests" -ForegroundColor White
Write-Host "✓ Successful: $SuccessCount" -ForegroundColor Green
Write-Host "✗ Failed: $FailedCount" -ForegroundColor Red
Write-Host "⚠ Skipped: $SkippedCount" -ForegroundColor Yellow
Write-Host "Duration: $([math]::Round($OverallDuration, 2)) seconds" -ForegroundColor White

# Performance summary
if ($PerformanceTest) {
    Write-Host "`n=== Performance Summary ===" -ForegroundColor Cyan
    $SuccessfulTests = $TestResults | Where-Object { $_.Status -eq "Success" -and $_.Duration -gt 0 }
    if ($SuccessfulTests.Count -gt 0) {
        $AvgDuration = ($SuccessfulTests | Measure-Object -Property Duration -Average).Average
        $FastestTest = $SuccessfulTests | Sort-Object Duration | Select-Object -First 1
        $SlowestTest = $SuccessfulTests | Sort-Object Duration -Descending | Select-Object -First 1
        
        Write-Host "Average Duration: $([math]::Round($AvgDuration, 2))ms" -ForegroundColor White
        Write-Host "Fastest: $($FastestTest.Command) ($($FastestTest.ParameterSet)) - $([math]::Round($FastestTest.Duration, 2))ms" -ForegroundColor Green
        Write-Host "Slowest: $($SlowestTest.Command) ($($SlowestTest.ParameterSet)) - $([math]::Round($SlowestTest.Duration, 2))ms" -ForegroundColor Yellow
    }
}

# Detailed results
if ($Detailed) {
    Write-Host "`n=== Detailed Results ===" -ForegroundColor Cyan
    $TestResults | ForEach-Object {
        $StatusColor = switch ($_.Status) {
            "Success" { "Green" }
            "Failed" { "Red" }
            "Skipped" { "Yellow" }
            default { "White" }
        }
        Write-Host "$($_.Command) ($($_.ParameterSet)): $($_.Status) - $($_.Message)" -ForegroundColor $StatusColor
    }
}

# Failed tests analysis
$FailedTests = $TestResults | Where-Object { $_.Status -eq "Failed" }
if ($FailedTests.Count -gt 0) {
    Write-Host "`n=== Failed Tests Analysis ===" -ForegroundColor Red
    $FailedTests | ForEach-Object {
        Write-Host "$($_.Command) ($($_.ParameterSet)): $($_.Message)" -ForegroundColor Red
        if ($_.ErrorDetails -and $Detailed) {
            Write-Host "  Full Error: $($_.ErrorDetails.Exception.ToString())" -ForegroundColor DarkRed
        }
    }
}

# Output results in requested format
switch ($OutputFormat) {
    'JSON' {
        $OutputPath = "test-results-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
        $TestResults | ConvertTo-Json -Depth 3 | Out-File -FilePath $OutputPath -Encoding UTF8
        Write-Host "`nResults exported to: $OutputPath" -ForegroundColor Cyan
    }
    'CSV' {
        $OutputPath = "test-results-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv"
        $TestResults | Select-Object Command, ParameterSet, Status, Message, ResultCount, Duration, Timestamp | Export-Csv -Path $OutputPath -NoTypeInformation
        Write-Host "`nResults exported to: $OutputPath" -ForegroundColor Cyan
    }
    'Console' {
        # Already displayed above
    }
}

# Exit with appropriate code
if ($FailedTests.Count -gt 0) {
    Write-Host "`n❌ Some tests failed. Check the results above." -ForegroundColor Red
    exit 1
} else {
    Write-Host "`n✅ All tests passed successfully!" -ForegroundColor Green
    exit 0
}