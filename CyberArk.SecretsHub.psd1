@{
    RootModule = 'CyberArk.SecretsHub.psm1'
    ModuleVersion = '1.0.0'
    GUID = 'a1b2c3d4-e5f6-7890-1234-567890abcdef'
    Author = 'Joe Garcia'
    CompanyName = 'CyberArk Software Ltd.'
    Copyright = '(c) 2025 Joe Garcia. All rights reserved.'
    Description = 'PowerShell module for CyberArk Secrets Hub REST API automation'
    
    PowerShellVersion = '5.1'
    CompatiblePSEditions = @('Desktop', 'Core')
    
    RequiredModules = @(
        @{
            ModuleName = 'IdentityCommand'
            ModuleVersion = '2.0.0'
            RequiredVersion = '2.0.0'
        }
    )
    
    FunctionsToExport = @(
        # Secret Stores
        'Get-SecretStore', 'New-AwsSecretStore', 'New-AzureSecretStore', 'New-GcpSecretStore', 'New-PamSecretStore',
        'Set-AwsSecretStore', 'Set-AzureSecretStore', 'Set-GcpSecretStore', 'Set-PamSecretStore',
        'Remove-SecretStore', 'Enable-SecretStore', 'Disable-SecretStore', 'Test-SecretStoreConnection',
        
        # Policies
        'Get-Policy', 'New-Policy', 'Remove-Policy', 'Enable-Policy', 'Disable-Policy',
        'Set-PolicySource', 'Set-PolicyTarget',
        
        # Secrets (Beta)
        'Get-Secret', 'Get-SecretValue',
        
        # Scans (Beta)
        'Get-Scan', 'Start-Scan',
        
        # Filters
        'Get-Filter', 'New-Filter', 'Remove-Filter',
        
        # Configuration
        'Get-Configuration', 'Set-Configuration',
        
        # Connection Management
        'Connect-SecretsHub', 'Disconnect-SecretsHub'
    )
    
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
    
    FileList = @(
        'CyberArk.SecretsHub.psm1',
        'Public/SecretStores/Get-SecretStore.ps1',
        'Public/SecretStores/New-AwsSecretStore.ps1',
        'Public/SecretStores/New-AzureSecretStore.ps1',
        'Public/SecretStores/New-GcpSecretStore.ps1',
        'Public/SecretStores/New-PamSecretStore.ps1',
        'Public/SecretStores/Set-AwsSecretStore.ps1',
        'Public/SecretStores/Set-AzureSecretStore.ps1',
        'Public/SecretStores/Set-GcpSecretStore.ps1',
        'Public/SecretStores/Set-PamSecretStore.ps1',
        'Public/SecretStores/Remove-SecretStore.ps1',
        'Public/SecretStores/Enable-SecretStore.ps1',
        'Public/SecretStores/Disable-SecretStore.ps1',
        'Public/SecretStores/Test-SecretStoreConnection.ps1',
        'Public/Policies/Get-Policy.ps1',
        'Public/Policies/New-Policy.ps1',
        'Public/Policies/Remove-Policy.ps1',
        'Public/Policies/Enable-Policy.ps1',
        'Public/Policies/Disable-Policy.ps1',
        'Public/Policies/Set-PolicySource.ps1',
        'Public/Policies/Set-PolicyTarget.ps1',
        'Public/Secrets/Get-Secret.ps1',
        'Public/Secrets/Get-SecretValue.ps1',
        'Public/Scans/Get-Scan.ps1',
        'Public/Scans/Start-Scan.ps1',
        'Public/Filters/Get-Filter.ps1',
        'Public/Filters/New-Filter.ps1',
        'Public/Filters/Remove-Filter.ps1',
        'Public/Configuration/Get-Configuration.ps1',
        'Public/Configuration/Set-Configuration.ps1',
        'Public/Connection/Connect-SecretsHub.ps1',
        'Public/Connection/Disconnect-SecretsHub.ps1',
        'Private/Authentication/Get-SecretsHubToken.ps1',
        'Private/Authentication/Initialize-SecretsHubConnection.ps1',
        'Private/ApiClient/Invoke-SecretsHubApi.ps1',
        'Private/ApiClient/Get-SecretsHubBaseUrl.ps1',
        'Private/Utilities/ConvertTo-SecretsHubFilter.ps1',
        'Private/Utilities/Test-SecretsHubConnection.ps1',
        'Private/Utilities/Write-SecretsHubError.ps1',
        'Types/CyberArk.SecretsHub.types.ps1xml',
        'Formats/CyberArk.SecretsHub.format.ps1xml'
    )
    
    PrivateData = @{
        PSData = @{
            Tags = @('CyberArk', 'SecretsHub', 'SecretManagement', 'DevOps', 'Automation', 'Security', 'API')
            LicenseUri = 'https://github.com/infamousjoeg/secrets-hub-powershell/blob/main/LICENSE'
            ProjectUri = 'https://github.com/infamousjoeg/secrets-hub-powershell'
            IconUri = 'https://www.cyberark.com/wp-content/uploads/2021/01/cyberark-logo-dark.svg'
            ReleaseNotes = 'Initial release of CyberArk Secrets Hub PowerShell module'
            Prerelease = ''
            RequireLicenseAcceptance = $false
            ExternalModuleDependencies = @('IdentityCommand')
        }
    }
    
    HelpInfoURI = 'https://github.com/infamousjoeg/secrets-hub-powershell/blob/main/docs/'
    DefaultCommandPrefix = ''
}
