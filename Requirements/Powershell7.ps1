Write-Host "Modules Version 0.2" -ForegroundColor Green
# Ensure winget is available
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Error "winget is niet geïnstalleerd of niet beschikbaar in het systeempad."
    exit 1
}

# Install PowerShell 7 using winget and accept terms automatically
try {
    Write-Host "PowerShell 7 wordt geïnstalleerd met winget..."
    winget install --id Microsoft.Powershell --source winget --accept-package-agreements --accept-source-agreements --silent
    Write-Host "Installatie van PowerShell 7 voltooid. Druk op een toets om door te gaan."
} catch {
    Write-Error "Er is een fout opgetreden tijdens het installeren van PowerShell 7: $_ Druk op een toets om door te gaan."
}
$Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
Remove-Item $env:TEMP\CheckModulesScript.ps1
exit 0  # 0 = success, non-zero = error