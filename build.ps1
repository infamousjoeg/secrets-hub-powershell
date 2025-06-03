[CmdletBinding()]
param(
    [Parameter()]
    [ValidateSet('Build', 'Test', 'Publish', 'Clean')]
    [string]$Task = 'Build',

    [Parameter()]
    [string]$Version,

    [Parameter()]
    [string]$ApiKey
)

# Build configuration
$ModuleName = 'CyberArk.SecretsHub'
$BuildDir = Join-Path $PSScriptRoot 'Build'
#$DocsDir = Join-Path $PSScriptRoot 'docs'

switch ($Task) {
    'Clean' {
        Write-Warning "Cleaning build directory..."
        if (Test-Path $BuildDir) {
            Remove-Item $BuildDir -Recurse -Force
        }
    }

    'Build' {
        Write-Information "Building module..." -InformationAction Continue

        # Clean first
        & $PSCommandPath -Task Clean

        # Create build directory
        $ModuleBuildDir = New-Item -Path $BuildDir\$ModuleName -ItemType Directory -Force

        # Copy module files
        $FilesToCopy = @(
            'CyberArk.SecretsHub.psd1',
            'CyberArk.SecretsHub.psm1',
            'Public',
            'Private',
            'Types',
            'Formats',
            'LICENSE',
            'README.md'
        )

        foreach ($File in $FilesToCopy) {
            $Source = Join-Path $PSScriptRoot $File
            if (Test-Path $Source) {
                Copy-Item $Source -Destination $ModuleBuildDir -Recurse -Force
                Write-Information "  Copied: $File" -InformationAction Continue
            }
        }

        # Update version if specified
        if ($Version) {
            Write-Information "Updating version to $Version..." -InformationAction Continue
            $ManifestPath = Join-Path $ModuleBuildDir 'CyberArk.SecretsHub.psd1'
            $Content = Get-Content $ManifestPath -Raw
            $Content = $Content -replace "ModuleVersion = '.*'", "ModuleVersion = '$Version'"
            Set-Content -Path $ManifestPath -Value $Content
        }

        Write-Information "Build completed: $ModuleBuildDir" -InformationAction Continue
    }

    'Test' {
        Write-Information "Running tests..." -InformationAction Continue

        # Install Pester if not available
        if (-not (Get-Module -Name Pester -ListAvailable)) {
            Install-Module -Name Pester -Force -SkipPublisherCheck
        }

        # Configure Pester
        $Config = New-PesterConfiguration
        $Config.Run.Path = './Tests'
        $Config.CodeCoverage.Enabled = $true
        $Config.CodeCoverage.Path = './Public', './Private'
        $Config.Output.Verbosity = 'Detailed'

        # Run tests
        $Results = Invoke-Pester -Configuration $Config

        if ($Results.FailedCount -gt 0) {
            throw "Tests failed: $($Results.FailedCount) failed out of $($Results.TotalCount)"
        }

        Write-Information "All tests passed!" -InformationAction Continue
    }

    'Publish' {
        Write-Information "Publishing module..." -InformationAction Continue

        if (-not $ApiKey) {
            throw "ApiKey parameter is required for publishing"
        }

        # Build first
        & $PSCommandPath -Task Build -Version $Version

        # Publish
        $ModulePath = Join-Path $BuildDir $ModuleName
        Publish-Module -Path $ModulePath -NuGetApiKey $ApiKey -Repository PSGallery -Verbose

        Write-Information "Module published successfully!" -InformationAction Continue
    }
}
