#Requires -Module Pester

BeforeAll {
    # Import module for testing
    $ModuleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)

    # Clean import
    Remove-Module CyberArk.SecretsHub -Force -ErrorAction SilentlyContinue
    Import-Module "$ModuleRoot\CyberArk.SecretsHub.psd1" -Force
}

Describe "Module Import and Function Availability" {
    It "Should import the module successfully" {
        Get-Module CyberArk.SecretsHub | Should -Not -BeNullOrEmpty
    }

    It "Should export all expected functions" {
        $Module = Get-Module CyberArk.SecretsHub
        $ExportedFunctions = $Module.ExportedFunctions.Keys

        # Core functions should be available
        $ExportedFunctions | Should -Contain 'Connect-SecretsHub'
        $ExportedFunctions | Should -Contain 'Get-SecretStore'
        $ExportedFunctions | Should -Contain 'New-AwsSecretStore'
        $ExportedFunctions | Should -Contain 'New-AzureSecretStore'
        $ExportedFunctions | Should -Contain 'New-GcpSecretStore'
        $ExportedFunctions | Should -Contain 'New-PamSecretStore'
    }
}

Describe "Connect-SecretsHub" {
    Context "Parameter Validation" {
        It "Should have Subdomain parameter" {
            $Function = Get-Command Connect-SecretsHub
            $Function.Parameters.Keys | Should -Contain 'Subdomain'
        }

        It "Should have BaseUrl parameter" {
            $Function = Get-Command Connect-SecretsHub
            $Function.Parameters.Keys | Should -Contain 'BaseUrl'
        }

        It "Should have correct parameter sets" {
            $Function = Get-Command Connect-SecretsHub
            $ParameterSets = $Function.ParameterSets.Name

            $ParameterSets | Should -Contain 'Subdomain'
            $ParameterSets | Should -Contain 'BaseUrl'
        }

        It "Should require Subdomain when empty string provided" {
            { Connect-SecretsHub -Subdomain "" } | Should -Throw
        }

        It "Should require BaseUrl when empty string provided" {
            { Connect-SecretsHub -BaseUrl "" } | Should -Throw
        }
    }
}

Describe "New-AwsSecretStore" {
    Context "Parameter Validation" {
        It "Should have all required parameters" {
            $Function = Get-Command New-AwsSecretStore
            $RequiredParams = @('Name', 'AccountId', 'AccountAlias', 'Region', 'RoleName')

            foreach ($Param in $RequiredParams) {
                $Function.Parameters.Keys | Should -Contain $Param -Because "Parameter '$Param' should exist"
            }
        }

        It "Should have State parameter with correct ValidateSet" {
            $Function = Get-Command New-AwsSecretStore
            $StateParam = $Function.Parameters['State']

            $StateParam | Should -Not -BeNullOrEmpty
            $StateParam.Attributes.ValidValues | Should -Contain 'ENABLED'
            $StateParam.Attributes.ValidValues | Should -Contain 'DISABLED'
        }

        It "Should have AccountId parameter with validation pattern" {
            $Function = Get-Command New-AwsSecretStore
            $AccountIdParam = $Function.Parameters['AccountId']

            $AccountIdParam | Should -Not -BeNullOrEmpty
            # Check for validation attributes
            $AccountIdParam.Attributes | Should -Not -BeNullOrEmpty
        }

        It "Should support WhatIf" {
            $Function = Get-Command New-AwsSecretStore
            $Function.Parameters.Keys | Should -Contain 'WhatIf'
        }
    }
}

Describe "New-AzureSecretStore" {
    Context "Parameter Validation" {
        It "Should have all required parameters" {
            $Function = Get-Command New-AzureSecretStore
            $RequiredParams = @('Name', 'VaultUrl', 'ClientId', 'ClientSecret', 'TenantId')

            foreach ($Param in $RequiredParams) {
                $Function.Parameters.Keys | Should -Contain $Param -Because "Parameter '$Param' should exist"
            }
        }

        It "Should have ClientSecret as SecureString" {
            $Function = Get-Command New-AzureSecretStore
            $ClientSecretParam = $Function.Parameters['ClientSecret']

            $ClientSecretParam.ParameterType | Should -Be ([SecureString])
        }

        It "Should have ConnectionType parameter with ValidateSet" {
            $Function = Get-Command New-AzureSecretStore
            $ConnectionTypeParam = $Function.Parameters['ConnectionType']

            $ConnectionTypeParam.Attributes.ValidValues | Should -Contain 'PUBLIC'
            $ConnectionTypeParam.Attributes.ValidValues | Should -Contain 'CONNECTOR'
        }
    }
}

Describe "Get-SecretStore" {
    Context "Parameter Validation" {
        It "Should have correct parameter sets" {
            $Function = Get-Command Get-SecretStore
            $ParameterSets = $Function.ParameterSets.Name

            $ParameterSets | Should -Contain 'List'
            $ParameterSets | Should -Contain 'ById'
            $ParameterSets | Should -Contain 'All'
        }

        It "Should have Behavior parameter with correct ValidateSet" {
            $Function = Get-Command Get-SecretStore
            $BehaviorParam = $Function.Parameters['Behavior']

            $BehaviorParam.Attributes.ValidValues | Should -Contain 'SECRETS_SOURCE'
            $BehaviorParam.Attributes.ValidValues | Should -Contain 'SECRETS_TARGET'
        }

        It "Should have StoreId parameter in ById parameter set" {
            $Function = Get-Command Get-SecretStore
            $StoreIdParam = $Function.Parameters['StoreId']

            $StoreIdParam | Should -Not -BeNullOrEmpty
            # StoreId should be mandatory in ById parameter set
            $StoreIdParam.ParameterSets['ById'].IsMandatory | Should -Be $true
        }

        It "Should have All parameter in All parameter set" {
            $Function = Get-Command Get-SecretStore
            $AllParam = $Function.Parameters['All']

            $AllParam | Should -Not -BeNullOrEmpty
            $AllParam.ParameterSets['All'].IsMandatory | Should -Be $true
        }
    }
}

Describe "Policy Functions" {
    Context "Function Availability" {
        It "Should have Get-Policy function" {
            Get-Command Get-Policy -Module CyberArk.SecretsHub | Should -Not -BeNullOrEmpty
        }

        It "Should have New-Policy function" {
            Get-Command New-Policy -Module CyberArk.SecretsHub | Should -Not -BeNullOrEmpty
        }

        It "Should have Enable-Policy function" {
            Get-Command Enable-Policy -Module CyberArk.SecretsHub | Should -Not -BeNullOrEmpty
        }

        It "Should have Disable-Policy function" {
            Get-Command Disable-Policy -Module CyberArk.SecretsHub | Should -Not -BeNullOrEmpty
        }
    }

    Context "Parameter Validation" {
        It "New-Policy should have required parameters" {
            $Function = Get-Command New-Policy
            $RequiredParams = @('Name', 'SourceStoreId', 'TargetStoreId')

            foreach ($Param in $RequiredParams) {
                $Function.Parameters.Keys | Should -Contain $Param
            }
        }

        It "Enable-Policy should accept PolicyId from pipeline" {
            $Function = Get-Command Enable-Policy
            $PolicyIdParam = $Function.Parameters['PolicyId']

            $PolicyIdParam.Attributes.ValueFromPipeline | Should -Be $true
        }
    }
}

Describe "Filter Functions" {
    Context "Function Availability" {
        It "Should have Get-Filter function" {
            Get-Command Get-Filter -Module CyberArk.SecretsHub | Should -Not -BeNullOrEmpty
        }

        It "Should have New-Filter function" {
            Get-Command New-Filter -Module CyberArk.SecretsHub | Should -Not -BeNullOrEmpty
        }

        It "Should have Remove-Filter function" {
            Get-Command Remove-Filter -Module CyberArk.SecretsHub | Should -Not -BeNullOrEmpty
        }
    }
}

Describe "Configuration Functions" {
    Context "Function Availability" {
        It "Should have Get-Configuration function" {
            Get-Command Get-Configuration -Module CyberArk.SecretsHub | Should -Not -BeNullOrEmpty
        }

        It "Should have Set-Configuration function" {
            Get-Command Set-Configuration -Module CyberArk.SecretsHub | Should -Not -BeNullOrEmpty
        }
    }

    Context "Parameter Validation" {
        It "Set-Configuration should have SecretValidity parameter with range validation" {
            $Function = Get-Command Set-Configuration
            $SecretValidityParam = $Function.Parameters['SecretValidity']

            $SecretValidityParam | Should -Not -BeNullOrEmpty
            $SecretValidityParam.ParameterType | Should -Be ([int])
        }
    }
}

Describe "Help and Documentation" {
    Context "Function Help" {
        It "Connect-SecretsHub should have help documentation" {
            $Help = Get-Help Connect-SecretsHub
            $Help.Synopsis | Should -Not -BeNullOrEmpty
            $Help.Description | Should -Not -BeNullOrEmpty
        }

        It "Get-SecretStore should have help documentation" {
            $Help = Get-Help Get-SecretStore
            $Help.Synopsis | Should -Not -BeNullOrEmpty
            $Help.Description | Should -Not -BeNullOrEmpty
        }

        It "New-AwsSecretStore should have examples" {
            $Help = Get-Help New-AwsSecretStore
            $Help.Examples | Should -Not -BeNullOrEmpty
        }
    }
}