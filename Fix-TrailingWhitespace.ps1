#!/usr/bin/env pwsh

<#
.SYNOPSIS
Removes trailing whitespace from PowerShell files.

.DESCRIPTION
Scans for .ps1, .psd1, .psm1 files and removes trailing whitespace.
#>

$FilesToFix = Get-ChildItem -Path . -Recurse -Include "*.ps1", "*.psd1", "*.psm1" | Where-Object {
    $_.FullName -notlike "*\.git\*" -and
    $_.FullName -notlike "*\Build\*" -and
    $_.FullName -notlike "*\node_modules\*"
}

$FixedCount = 0

foreach ($File in $FilesToFix) {
    $Content = Get-Content -Path $File.FullName -Raw
    $OriginalContent = $Content

    # Remove trailing whitespace from each line
    $Lines = $Content -split "`r?`n"
    $CleanLines = $Lines | ForEach-Object { $_.TrimEnd() }
    $CleanContent = $CleanLines -join "`n"

    # Add single newline at end if file doesn't end with one
    if ($CleanContent -and -not $CleanContent.EndsWith("`n")) {
        $CleanContent += "`n"
    }

    if ($OriginalContent -ne $CleanContent) {
        Set-Content -Path $File.FullName -Value $CleanContent -NoNewline
        Write-Host "Fixed: $($File.FullName)" -ForegroundColor Green
        $FixedCount++
    }
}

Write-Host "`nFixed $FixedCount file(s)" -ForegroundColor Cyan

if ($FixedCount -gt 0) {
    Write-Host "`nRun the following to commit changes:" -ForegroundColor Yellow
    Write-Host "git add ." -ForegroundColor Gray
    Write-Host "git commit -m 'Fix trailing whitespace'" -ForegroundColor Gray
    Write-Host "git push origin main" -ForegroundColor Gray
}
