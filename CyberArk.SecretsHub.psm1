#Requires -Version 5.1

# Module variables
$script:SecretsHubSession = $null

# Import helper functions first
$PrivateFunctions = Get-ChildItem -Path $PSScriptRoot\Private -Recurse -Filter "*.ps1"
$PublicFunctions = Get-ChildItem -Path $PSScriptRoot\Public -Recurse -Filter "*.ps1"

# Import all functions
foreach ($Function in @($PrivateFunctions + $PublicFunctions)) {
    try {
        . $Function.FullName
    }
    catch {
        Write-Error "Failed to import function $($Function.FullName): $($_.Exception.Message)"
    }
}

# Load format and type files
$FormatFile = Join-Path $PSScriptRoot "Formats\CyberArk.SecretsHub.format.ps1xml"
$TypeFile = Join-Path $PSScriptRoot "Types\CyberArk.SecretsHub.types.ps1xml"

if (Test-Path $FormatFile) {
    Update-FormatData -PrependPath $FormatFile
}

if (Test-Path $TypeFile) {
    Update-TypeData -PrependPath $TypeFile
}

# Export public functions
Export-ModuleMember -Function $PublicFunctions.BaseName

# Module cleanup
$MyInvocation.MyCommand.ScriptBlock.Module.OnRemove = {
    if ($script:SecretsHubSession) {
        Disconnect-SecretsHub
    }
}
