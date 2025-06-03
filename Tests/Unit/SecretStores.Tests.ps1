#Requires -Module Pester

BeforeAll {
    # Import module for testing
    $ModuleRoot = Split-Path -Parent $PSScriptRoot
    $ModuleRoot = Split-Path -Parent $ModuleRoot
    Import-Module "$ModuleRoot\CyberArk.SecretsHub.psd1" -Force
    
    # Mock session for testing
    $script:TestSession = [PSCustomObject]@{
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
            Mock Get-SecretsHubBaseUrl { return "https://test.secretshub.cyberark.cloud/" }
            Mock Initialize-SecretsHubConnection { return $script:TestSession }
        }
        
        It "Should connect using subdomain discovery" {
            $Result = Connect-SecretsHub -Subdomain "test"
            $Result.BaseUrl | Should -Be "https://test.secretshub.cyberark.cloud/"
        }
        
        It "Should connect using explicit base URL" {
            $Result = Connect-SecretsHub -BaseUrl "https://custom.secretshub.cyberark.cloud"
            $Result.BaseUrl | Should -Be "https://test.secretshub.cyberark.cloud/"
        }
    }
}

Describe "New-AwsSecretStore" {
    BeforeEach {
        # Set up mock session
        $script:SecretsHubSession = $script:TestSession
        Mock Invoke-SecretsHubApi { 
            return @{
                id = "store-12345678-1234-1234-1234-123456789012"
                name = $Body.name
                type = "AWS_ASM"
                state = $Body.state
            }
        }
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
            
            $Result.name | Should -Be "TestStore"
            $Result.type | Should -Be "AWS_ASM"
            Should -Invoke Invoke-SecretsHubApi -Times 1 -ParameterFilter {
                $Uri -eq "api/secret-stores" -and $Method -eq "POST"
            }
        }
        
        It "Should include description when provided" {
            $Result = New-AwsSecretStore -Name "TestStore" -Description "Test Description" -AccountId "123456789012" -AccountAlias "test-alias" -Region "us-east-1" -RoleName "TestRole"
            
            Should -Invoke Invoke-SecretsHubApi -Times 1 -ParameterFilter {
                $Body.description -eq "Test Description"
            }
        }
    }
}

Describe "Get-SecretStore" {
    BeforeEach {
        $script:SecretsHubSession = $script:TestSession
        Mock Invoke-SecretsHubApi { 
            if ($Uri -like "*store-*") {
                return @{
                    id = "store-12345678-1234-1234-1234-123456789012"
                    name = "TestStore"
                    type = "AWS_ASM"
                }
            }
            else {
                return @{
                    secretStores = @(
                        @{
                            id = "store-12345678-1234-1234-1234-123456789012"
                            name = "TestStore"
                            type = "AWS_ASM"
                        }
                    )
                }
            }
        }
    }
    
    Context "Get by ID" {
        It "Should retrieve specific secret store by ID" {
            $Result = Get-SecretStore -StoreId "store-12345678-1234-1234-1234-123456789012"
            $Result.id | Should -Be "store-12345678-1234-1234-1234-123456789012"
        }
    }
    
    Context "List stores" {
        It "Should list stores with default behavior" {
            $Result = Get-SecretStore
            $Result | Should -HaveCount 1
            $Result[0].name | Should -Be "TestStore"
        }
        
        It "Should filter by behavior type" {
            $Result = Get-SecretStore -Behavior "SECRETS_SOURCE"
            Should -Invoke Invoke-SecretsHubApi -Times 1 -ParameterFilter {
                $QueryParameters.behavior -eq "SECRETS_SOURCE"
            }
        }
    }
}
