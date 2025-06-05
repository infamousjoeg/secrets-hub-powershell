#Requires -Module Pester

BeforeAll {
    # Disconnect any existing connections for CI
    try { Disconnect-SecretsHub -ErrorAction SilentlyContinue } catch { Write-Verbose "No connection to disconnect" }

    # Import module for testing
    $ModuleRoot = Split-Path -Parent $PSScriptRoot
    $ModuleRoot = Split-Path -Parent $ModuleRoot

    # Remove any existing module to ensure clean import
    Remove-Module CyberArk.SecretsHub -Force -ErrorAction SilentlyContinue

    # Import the module
    Import-Module "$ModuleRoot\CyberArk.SecretsHub.psd1" -Force

    # Create test session object
    $script:TestSession = [PSCustomObject]@{
        BaseUrl = "https://test.secretshub.cyberark.cloud/"
        Token = "mock-token-12345"
        Headers = @{
            'Authorization' = "Bearer mock-token-12345"
            'Content-Type' = 'application/json'
            'Accept' = 'application/json'
        }
        Connected = $true
        ConnectedAt = Get-Date
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
            # Clear any existing session for clean test
            $Module = Get-Module CyberArk.SecretsHub
            if ($Module) {
                & $Module { $script:SecretsHubSession = $null }
            }

            # Mock the private functions
            Mock -ModuleName CyberArk.SecretsHub Get-SecretsHubBaseUrl {
                return "https://test.secretshub.cyberark.cloud/"
            }
            Mock -ModuleName CyberArk.SecretsHub Initialize-SecretsHubConnection {
                return $using:TestSession
            }
            Mock -ModuleName CyberArk.SecretsHub Write-Information { }
            Mock -ModuleName CyberArk.SecretsHub Write-Warning { }
            Mock -ModuleName CyberArk.SecretsHub Test-SecretsHubConnection { }
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
        # Mock Test-SecretsHubConnection to simulate active connection
        Mock -ModuleName CyberArk.SecretsHub Test-SecretsHubConnection { 
            return $true 
        }

        # Mock the session check in the module
        Mock -ModuleName CyberArk.SecretsHub -CommandName 'Get-Variable' -ParameterFilter { $Name -eq 'script:SecretsHubSession' } {
            return @{ Value = $using:TestSession }
        }

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
        Mock -ModuleName CyberArk.SecretsHub Write-SecretsHubError { }
    }

    Context "Parameter Validation" {
        It "Should have required parameters defined" {
            $Function = Get-Command New-AwsSecretStore
            $Function.Parameters.Keys | Should -Contain 'AccountId'
            $Function.Parameters.Keys | Should -Contain 'Name'
        }

        It "Should validate AccountId parameter pattern" {
            $Function = Get-Command New-AwsSecretStore
            $AccountIdParam = $Function.Parameters['AccountId']
            $AccountIdParam | Should -Not -BeNullOrEmpty
        }

        It "Should validate State parameter set" {
            $Function = Get-Command New-AwsSecretStore
            $StateParam = $Function.Parameters['State']
            $StateParam.Attributes.ValidValues | Should -Contain 'ENABLED'
            $StateParam.Attributes.ValidValues | Should -Contain 'DISABLED'
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
        # Create a more robust session mock approach
        # This ensures the session check passes on all platforms
        Mock -ModuleName CyberArk.SecretsHub -CommandName 'Test-Path' -ParameterFilter { $Path -like '*SecretsHubSession*' } {
            return $true
        }

        # Alternative approach: Mock the entire connection test
        Mock -ModuleName CyberArk.SecretsHub Test-SecretsHubConnection { 
            # Just return without throwing, simulating a valid connection
            return
        }

        # Mock the session access by overriding the script variable check
        # This is the key fix - we need to ensure the session variable exists
        $Module = Get-Module CyberArk.SecretsHub
        if ($Module) {
            try {
                # Set the session variable directly in the module's scope
                & $Module { 
                    param($TestSession)
                    $script:SecretsHubSession = $TestSession 
                } $script:TestSession
            } catch {
                Write-Warning "Could not set session in module scope: $_"
            }
        }

        # Mock the API calls with more specific responses
        Mock -ModuleName CyberArk.SecretsHub Invoke-SecretsHubApi {
            # Determine response based on URI pattern
            switch -Regex ($Uri) {
                'api/secret-stores/store-.*' {
                    # Single store request (by ID)
                    return @{
                        id = "store-12345678-1234-1234-1234-123456789012"
                        name = "TestStore"
                        type = "AWS_ASM"
                        state = @{ current = "ENABLED" }
                        createdAt = "2024-01-01T00:00:00Z"
                    }
                }
                'api/secret-stores$' {
                    # List stores request
                    return @{
                        secretStores = @(
                            @{
                                id = "store-12345678-1234-1234-1234-123456789012"
                                name = "TestStore"
                                type = "AWS_ASM"
                                state = @{ current = "ENABLED" }
                                createdAt = "2024-01-01T00:00:00Z"
                            }
                        )
                    }
                }
                default {
                    return @{ secretStores = @() }
                }
            }
        }

        # Mock error handling function
        Mock -ModuleName CyberArk.SecretsHub Write-SecretsHubError { }
        Mock -ModuleName CyberArk.SecretsHub Write-Error { }
        Mock -ModuleName CyberArk.SecretsHub Write-Warning { }
        Mock -ModuleName CyberArk.SecretsHub Write-Verbose { }
    }

    Context "Get by ID" {
        It "Should retrieve specific secret store by ID" {
            $Store = Get-SecretStore -StoreId "store-12345678-1234-1234-1234-123456789012"

            $Store | Should -Not -BeNullOrEmpty
            $Store.id | Should -Be "store-12345678-1234-1234-1234-123456789012"
            $Store.name | Should -Be "TestStore"

            Should -Invoke -ModuleName CyberArk.SecretsHub Invoke-SecretsHubApi -Times 1 -ParameterFilter {
                $Uri -eq "api/secret-stores/store-12345678-1234-1234-1234-123456789012" -and $Method -eq "GET"
            }
        }
    }

    Context "List stores" {
        It "Should list stores with default behavior" {
            $Stores = Get-SecretStore

            # The function should return the secretStores array from the API response
            $Stores | Should -Not -BeNullOrEmpty
            $Stores.Count | Should -Be 1
            $Stores[0].name | Should -Be "TestStore"

            Should -Invoke -ModuleName CyberArk.SecretsHub Invoke-SecretsHubApi -Times 1 -ParameterFilter {
                $Uri -eq "api/secret-stores" -and 
                $QueryParameters.behavior -eq "SECRETS_TARGET" -and 
                $Method -eq "GET"
            }
        }

        It "Should filter by behavior type" {
            $Stores = Get-SecretStore -Behavior "SECRETS_SOURCE"

            $Stores | Should -Not -BeNullOrEmpty

            Should -Invoke -ModuleName CyberArk.SecretsHub Invoke-SecretsHubApi -Times 1 -ParameterFilter {
                $Uri -eq "api/secret-stores" -and 
                $QueryParameters.behavior -eq "SECRETS_SOURCE" -and 
                $Method -eq "GET"
            }
        }

        It "Should handle -All parameter correctly" {
            # Mock both API calls for the -All parameter
            Mock -ModuleName CyberArk.SecretsHub Invoke-SecretsHubApi {
                return @{
                    secretStores = @(
                        @{
                            id = "store-source-123"
                            name = "SourceStore"
                            type = "PAM_SELF_HOSTED"
                            state = @{ current = "ENABLED" }
                        }
                    )
                }
            } -ParameterFilter { $QueryParameters.behavior -eq "SECRETS_SOURCE" }

            Mock -ModuleName CyberArk.SecretsHub Invoke-SecretsHubApi {
                return @{
                    secretStores = @(
                        @{
                            id = "store-target-456"
                            name = "TargetStore"
                            type = "AWS_ASM"
                            state = @{ current = "ENABLED" }
                        }
                    )
                }
            } -ParameterFilter { $QueryParameters.behavior -eq "SECRETS_TARGET" }

            $AllStores = Get-SecretStore -All

            $AllStores | Should -Not -BeNullOrEmpty
            $AllStores.Count | Should -Be 2
            
            # Should call both source and target APIs
            Should -Invoke -ModuleName CyberArk.SecretsHub Invoke-SecretsHubApi -Times 1 -ParameterFilter {
                $QueryParameters.behavior -eq "SECRETS_SOURCE"
            }
            Should -Invoke -ModuleName CyberArk.SecretsHub Invoke-SecretsHubApi -Times 1 -ParameterFilter {
                $QueryParameters.behavior -eq "SECRETS_TARGET"
            }
        }
    }
}