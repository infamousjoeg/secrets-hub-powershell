#Requires -Version 5.1

# Module variables
$script:SecretsHubSession = $null

Write-Verbose "Loading CyberArk.SecretsHub module from: $PSScriptRoot"

# Import helper functions first - with better error handling and path validation
try {
    $PrivatePath = Join-Path $PSScriptRoot "Private"
    $PublicPath = Join-Path $PSScriptRoot "Public"
    
    Write-Verbose "Private functions path: $PrivatePath"
    Write-Verbose "Public functions path: $PublicPath"
    
    # Validate paths exist
    if (-not (Test-Path $PrivatePath)) {
        throw "Private functions directory not found: $PrivatePath"
    }
    if (-not (Test-Path $PublicPath)) {
        throw "Public functions directory not found: $PublicPath"
    }
    
    $PrivateFunctions = Get-ChildItem -Path $PrivatePath -Recurse -Filter "*.ps1" -ErrorAction Stop
    $PublicFunctions = Get-ChildItem -Path $PublicPath -Recurse -Filter "*.ps1" -ErrorAction Stop
    
    Write-Verbose "Found $($PrivateFunctions.Count) private functions"
    Write-Verbose "Found $($PublicFunctions.Count) public functions"
    
    # Import private functions first (dependencies)
    foreach ($Function in $PrivateFunctions) {
        try {
            Write-Verbose "Importing private function: $($Function.Name)"
            . $Function.FullName
        }
        catch {
            Write-Error "Failed to import private function $($Function.FullName): $($_.Exception.Message)"
            throw
        }
    }
    
    # Then import public functions
    foreach ($Function in $PublicFunctions) {
        try {
            Write-Verbose "Importing public function: $($Function.Name)"
            . $Function.FullName
        }
        catch {
            Write-Error "Failed to import public function $($Function.FullName): $($_.Exception.Message)"
            throw
        }
    }
}
catch {
    Write-Error "Critical error loading module functions: $($_.Exception.Message)"
    throw
}

# Load format and type files
try {
    $FormatFile = Join-Path $PSScriptRoot "Formats\CyberArk.SecretsHub.format.ps1xml"
    $TypeFile = Join-Path $PSScriptRoot "Types\CyberArk.SecretsHub.types.ps1xml"

    if (Test-Path $FormatFile) {
        Write-Verbose "Loading format file: $FormatFile"
        Update-FormatData -PrependPath $FormatFile
    }

    if (Test-Path $TypeFile) {
        Write-Verbose "Loading type file: $TypeFile"
        Update-TypeData -PrependPath $TypeFile
    }
}
catch {
    Write-Warning "Failed to load format/type files: $($_.Exception.Message)"
}

# Export public functions
$FunctionsToExport = $PublicFunctions.BaseName
Write-Verbose "Exporting $($FunctionsToExport.Count) public functions"
Export-ModuleMember -Function $FunctionsToExport

# Module cleanup
$MyInvocation.MyCommand.ScriptBlock.Module.OnRemove = {
    Write-Verbose "Cleaning up SecretsHub module"
    if ($script:SecretsHubSession) {
        try {
            Disconnect-SecretsHub
        }
        catch {
            Write-Verbose "Error during cleanup: $($_.Exception.Message)"
        }
    }
}