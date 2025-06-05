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

            # Mock all the required functions with consistent behavior
            Mock -ModuleName CyberArk.SecretsHub Get-SecretsHubBaseUrl {
                param($Subdomain)
                return "https://$Subdomain.secretshub.cyberark.cloud/"
            }

            Mock -ModuleName CyberArk.SecretsHub Initialize-SecretsHubConnection {
                param($BaseUrl)
                # Return a consistent test session
                return [PSCustomObject]@{
                    BaseUrl = $BaseUrl
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

            Mock -ModuleName CyberArk.SecretsHub Write-Information {
                # Mock the information output
            }
            Mock -ModuleName CyberArk.SecretsHub Write-Warning {
                # Mock the warning output
            }
        }

        It "Should connect using subdomain discovery" {
            $Result = Connect-SecretsHub -Subdomain "test"

            # Verify the discovery function was called with correct subdomain
            Should -Invoke -ModuleName CyberArk.SecretsHub Get-SecretsHubBaseUrl -Times 1 -ParameterFilter {
                $Subdomain -eq "test"
            }

            # Verify connection was initialized
            Should -Invoke -ModuleName CyberArk.SecretsHub Initialize-SecretsHubConnection -Times 1 -ParameterFilter {
                $BaseUrl -eq "https://test.secretshub.cyberark.cloud/"
            }

            # Verify we got a session back
            $Result | Should -Not -BeNullOrEmpty
            $Result.Connected | Should -Be $true
        }

        It "Should connect using explicit base URL" {
            $BaseUrl = "https://custom.secretshub.cyberark.cloud"
            $Result = Connect-SecretsHub -BaseUrl $BaseUrl

            # Should NOT call discovery when base URL is provided
            Should -Invoke -ModuleName CyberArk.SecretsHub Get-SecretsHubBaseUrl -Times 0

            # Should call initialize with the provided URL
            Should -Invoke -ModuleName CyberArk.SecretsHub Initialize-SecretsHubConnection -Times 1 -ParameterFilter {
                $BaseUrl -eq "https://custom.secretshub.cyberark.cloud"
            }

            # Verify we got a session back
            $Result | Should -Not -BeNullOrEmpty
            $Result.Connected | Should -Be $true
        }
    }
}

Describe "New-AwsSecretStore" {
    BeforeEach {
        # Use a more direct approach to mock the session check
        Mock -ModuleName CyberArk.SecretsHub Test-SecretsHubConnection {
            # Simply return without error to simulate valid connection
        }

        # Mock the API call with consistent response
        Mock -ModuleName CyberArk.SecretsHub Invoke-SecretsHubApi {
            param($Uri, $Method, $Body)

            return @{
                id = "store-12345678-1234-1234-1234-123456789012"
                name = $Body.name
                type = "AWS_ASM"
                state = $Body.state
                data = $Body.data
                createdAt = "2024-01-01T00:00:00Z"
            }
        }

        # Mock all output functions
        Mock -ModuleName CyberArk.SecretsHub Write-Information { }
        Mock -ModuleName CyberArk.SecretsHub Write-SecretsHubError { }
        Mock -ModuleName CyberArk.SecretsHub Write-Error { }
        Mock -ModuleName CyberArk.SecretsHub Write-Warning { }
    }

    Context "Parameter Validation" {
        It "Should have required parameters defined" {
            $Function = Get-Command New-AwsSecretStore
            $Function.Parameters.Keys | Should -Contain 'AccountId'
            $Function.Parameters.Keys | Should -Contain 'Name'
            $Function.Parameters.Keys | Should -Contain 'AccountAlias'
            $Function.Parameters.Keys | Should -Contain 'Region'
            $Function.Parameters.Keys | Should -Contain 'RoleName'
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
                $Uri -eq "api/secret-stores" -and
                $Method -eq "POST" -and
                $Body.name -eq "TestStore" -and
                $Body.type -eq "AWS_ASM" -and
                $Body.data.accountId -eq "123456789012" -and
                $Body.data.roleName -eq "TestRole"
            }

            # Verify return value
            $Result | Should -Not -BeNullOrEmpty
            $Result.name | Should -Be "TestStore"
            $Result.type | Should -Be "AWS_ASM"
        }

        It "Should include description when provided" {
            New-AwsSecretStore -Name "TestStore" -Description "Test Description" -AccountId "123456789012" -AccountAlias "test-alias" -Region "us-east-1" -RoleName "TestRole" | Out-Null

            Should -Invoke -ModuleName CyberArk.SecretsHub Invoke-SecretsHubApi -Times 1 -ParameterFilter {
                $Body.description -eq "Test Description"
            }
        }
    }
}

Describe "Get-SecretStore" {
    BeforeEach {
        # Use a completely different approach - mock at the module level
        # This approach should work consistently across platforms

        # Mock the connection validation to always pass
        Mock -ModuleName CyberArk.SecretsHub Test-SecretsHubConnection { }

        # Set session directly in module scope using InvokeScript
        $Module = Get-Module CyberArk.SecretsHub
        if ($Module) {
            $Module.Invoke({
                param($TestSession)
                $script:SecretsHubSession = $TestSession
            }, $script:TestSession)
        }

        # Mock the API calls with detailed responses
        Mock -ModuleName CyberArk.SecretsHub Invoke-SecretsHubApi {
            param($Uri, $QueryParameters)

            # Return response based on URI pattern and query parameters
            if ($Uri -match 'api/secret-stores/store-.*') {
                # Single store request (by ID)
                return @{
                    id = "store-12345678-1234-1234-1234-123456789012"
                    name = "TestStore"
                    type = "AWS_ASM"
                    state = @{ current = "ENABLED" }
                    createdAt = "2024-01-01T00:00:00Z"
                }
            }
            elseif ($Uri -eq 'api/secret-stores') {
                # List stores request - check behavior parameter
                $Behavior = $QueryParameters.behavior

                if ($Behavior -eq 'SECRETS_SOURCE') {
                    return @{
                        secretStores = @(
                            @{
                                id = "store-source-123"
                                name = "SourceStore"
                                type = "PAM_SELF_HOSTED"
                                state = @{ current = "ENABLED" }
                                createdAt = "2024-01-01T00:00:00Z"
                            }
                        )
                    }
                }
                else {
                    # SECRETS_TARGET or default
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
            }
            else {
                # Fallback empty response
                return @{ secretStores = @() }
            }
        }

        # Mock all output functions
        Mock -ModuleName CyberArk.SecretsHub Write-Error { }
        Mock -ModuleName CyberArk.SecretsHub Write-Warning { }
        Mock -ModuleName CyberArk.SecretsHub Write-Verbose { }
        Mock -ModuleName CyberArk.SecretsHub Write-Information { }
    }

    Context "Get by ID" {
        It "Should retrieve specific secret store by ID" {
            $Store = Get-SecretStore -StoreId "store-12345678-1234-1234-1234-123456789012"

            $Store | Should -Not -BeNullOrEmpty
            $Store.id | Should -Be "store-12345678-1234-1234-1234-123456789012"
            $Store.name | Should -Be "TestStore"
            $Store.type | Should -Be "AWS_ASM"

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
            $Stores[0].type | Should -Be "AWS_ASM"

            Should -Invoke -ModuleName CyberArk.SecretsHub Invoke-SecretsHubApi -Times 1 -ParameterFilter {
                $Uri -eq "api/secret-stores" -and
                $QueryParameters.behavior -eq "SECRETS_TARGET" -and
                $Method -eq "GET"
            }
        }

        It "Should filter by behavior type" {
            $Stores = Get-SecretStore -Behavior "SECRETS_SOURCE"

            $Stores | Should -Not -BeNullOrEmpty
            $Stores.Count | Should -Be 1
            $Stores[0].name | Should -Be "SourceStore"
            $Stores[0].type | Should -Be "PAM_SELF_HOSTED"

            Should -Invoke -ModuleName CyberArk.SecretsHub Invoke-SecretsHubApi -Times 1 -ParameterFilter {
                $Uri -eq "api/secret-stores" -and
                $QueryParameters.behavior -eq "SECRETS_SOURCE" -and
                $Method -eq "GET"
            }
        }

        It "Should handle -All parameter correctly" {
            $AllStores = Get-SecretStore -All

            $AllStores | Should -Not -BeNullOrEmpty
            $AllStores.Count | Should -Be 2

            # Should have both source and target stores
            $SourceStores = $AllStores | Where-Object { $_.type -eq "PAM_SELF_HOSTED" }
            $TargetStores = $AllStores | Where-Object { $_.type -eq "AWS_ASM" }

            $SourceStores.Count | Should -Be 1
            $TargetStores.Count | Should -Be 1

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