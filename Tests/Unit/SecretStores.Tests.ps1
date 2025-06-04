#Requires -Module Pester

BeforeAll {
    # Import module for testing
    $ModuleRoot = Split-Path -Parent $PSScriptRoot
    $ModuleRoot = Split-Path -Parent $ModuleRoot

    # Remove any existing module to ensure clean import
    Remove-Module CyberArk.SecretsHub -Force -ErrorAction SilentlyContinue

    # Import the module
    Import-Module "$ModuleRoot\CyberArk.SecretsHub.psd1" -Force

    # Create test session object
    $Global:TestSession = [PSCustomObject]@{
        BaseUrl = "https://test.secretshub.cyberark.cloud/"
        Token = "mock-token"
        Headers = @{
            'Authorization' = "Bearer mock-token"
            'Content-Type' = 'application/json'
            'Accept' = 'application/json'
        }
        Connected = $true
        ConnectedAt = Get-Date
    }
}

# Helper function to set module session
function Set-TestSession {
    $Module = Get-Module CyberArk.SecretsHub
    if ($Module) {
        & $Module { $script:SecretsHubSession = $Global:TestSession }
    }
}

Describe "Connect-SecretsHub" {
    Context "Parameter Validation" {
        It "Should require Subdomain in Subdomain parameter set" {
            { Connect-SecretsHub -Subdomain "" } | Should -Throw
        }

        It "Should require BaseUrl in BaseUrl parameter set" {
            { Connect-SecretsHub -BaseUrl "" } | Should -Throw
        }

        It "Should validate parameter sets are mutually exclusive" {
            { Connect-SecretsHub -Subdomain "test" -BaseUrl "https://test.com" } | Should -Throw
        }
    }

    Context "Connection Logic" -Tag "Integration" {
        BeforeEach {
            # Mock the private functions
            Mock -ModuleName CyberArk.SecretsHub Get-SecretsHubBaseUrl {
                return "https://test.secretshub.cyberark.cloud/"
            }
            Mock -ModuleName CyberArk.SecretsHub Initialize-SecretsHubConnection {
                return $Global:TestSession
            }
            Mock -ModuleName CyberArk.SecretsHub Write-Information { }
        }

        It "Should connect using subdomain discovery" {
            Connect-SecretsHub -Subdomain "test"
            # Verify the mock was called
            Should -Invoke -ModuleName CyberArk.SecretsHub Get-SecretsHubBaseUrl -Times 1 -ParameterFilter { $Subdomain -eq "test" }
        }

        It "Should connect using explicit base URL" {
            Connect-SecretsHub -BaseUrl "https://custom.secretshub.cyberark.cloud"
            # Verify connection was established
            Should -Invoke -ModuleName CyberArk.SecretsHub Initialize-SecretsHubConnection -Times 1
        }
    }
}

Describe "New-AwsSecretStore" {
    BeforeEach {
        # Set up test session
        Set-TestSession

        # Mock the API call
        Mock -ModuleName CyberArk.SecretsHub Invoke-SecretsHubApi {
            return @{
                id = "store-12345678-1234-1234-1234-123456789012"
                name = $Body.name
                type = "AWS_ASM"
                state = $Body.state
                data = $Body.data
            }
        }

        # Mock output functions
        Mock -ModuleName CyberArk.SecretsHub Write-Information { }
    }

    Context "Parameter Validation" {
        It "Should validate AWS Account ID format" {
            { New-AwsSecretStore -Name "Test" -AccountId "invalid" -AccountAlias "test" -Region "us-east-1" -RoleName "role" } | Should -Throw
        }

        It "Should require all mandatory parameters" {
            { New-AwsSecretStore -Name "Test" } | Should -Throw
        }

        It "Should validate State parameter" {
            { New-AwsSecretStore -Name "Test" -AccountId "123456789012" -AccountAlias "test" -Region "us-east-1" -RoleName "role" -State "INVALID" } | Should -Throw
        }
    }

    Context "Store Creation" {
        It "Should create AWS secret store with required parameters" {
            $Result = New-AwsSecretStore -Name "TestStore" -AccountId "123456789012" -AccountAlias "test-alias" -Region "us-east-1" -RoleName "TestRole"

            # Verify the API was called correctly
            Should -Invoke -ModuleName CyberArk.SecretsHub Invoke-SecretsHubApi -Times 1 -ParameterFilter {
                $Uri -eq "api/secret-stores" -and $Method -eq "POST" -and $Body.name -eq "TestStore"
            }

            # Verify return value
            $Result.name | Should -Be "TestStore"
            $Result.type | Should -Be "AWS_ASM"
        }

        It "Should include description when provided" {
            New-AwsSecretStore -Name "TestStore" -Description "Test Description" -AccountId "123456789012" -AccountAlias "test-alias" -Region "us-east-1" -RoleName "TestRole"

            Should -Invoke -ModuleName CyberArk.SecretsHub Invoke-SecretsHubApi -Times 1 -ParameterFilter {
                $Body.description -eq "Test Description"
            }
        }
    }
}

Describe "Get-SecretStore" {
    BeforeEach {
        # Set up test session
        Set-TestSession

        # Mock the API calls
        Mock -ModuleName CyberArk.SecretsHub Invoke-SecretsHubApi {
            if ($Uri -like "*store-*") {
                # Single store request
                return @{
                    id = "store-12345678-1234-1234-1234-123456789012"
                    name = "TestStore"
                    type = "AWS_ASM"
                    state = @{ current = "ENABLED" }
                }
            }
            else {
                # List stores request
                return @{
                    secretStores = @(
                        @{
                            id = "store-12345678-1234-1234-1234-123456789012"
                            name = "TestStore"
                            type = "AWS_ASM"
                            state = @{ current = "ENABLED" }
                        }
                    )
                }
            }
        }
    }

    Context "Get by ID" {
        It "Should retrieve specific secret store by ID" {
            $Store = Get-SecretStore -StoreId "store-12345678-1234-1234-1234-123456789012"

            $Store.id | Should -Be "store-12345678-1234-1234-1234-123456789012"
            $Store.name | Should -Be "TestStore"

            Should -Invoke -ModuleName CyberArk.SecretsHub Invoke-SecretsHubApi -Times 1 -ParameterFilter {
                $Uri -eq "api/secret-stores/store-12345678-1234-1234-1234-123456789012"
            }
        }
    }

    Context "List stores" {
        It "Should list stores with default behavior" {
            $Stores = Get-SecretStore

            $Stores | Should -HaveCount 1
            $Stores[0].name | Should -Be "TestStore"

            Should -Invoke -ModuleName CyberArk.SecretsHub Invoke-SecretsHubApi -Times 1 -ParameterFilter {
                $Uri -eq "api/secret-stores" -and $QueryParameters.behavior -eq "SECRETS_TARGET"
            }
        }

        It "Should filter by behavior type" {
            Get-SecretStore -Behavior "SECRETS_SOURCE"

            Should -Invoke -ModuleName CyberArk.SecretsHub Invoke-SecretsHubApi -Times 1 -ParameterFilter {
                $QueryParameters.behavior -eq "SECRETS_SOURCE"
            }
        }
    }
}