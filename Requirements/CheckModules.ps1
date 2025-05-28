# Check-Modules.ps1
Write-Host "Check Modules Version 0.3" -ForegroundColor Green

Write-Host "`nBezig met controleren van geïnstalleerde modules..."
Start-Sleep -Seconds 1

$modulesToCheck = @(
    "MSAL.PS",
    "Intune.USB.Creator",
    "Microsoft.Graph.Authentication",
    "WindowsAutopilotIntune",
    "Microsoft.Graph.Groups",
    "Microsoft.Graph.Identity.DirectoryManagement"
)

$results = @()

foreach ($moduleName in $modulesToCheck) {
    $module = Get-InstalledModule -Name $moduleName -ErrorAction SilentlyContinue
    if ($module) {
        $results += [PSCustomObject]@{
            Module = $module.Name
            Status = "Geïnstalleerd"
            Versie = $module.Version
        }
    } else {
        $results += [PSCustomObject]@{
            Module = $moduleName
            Status = "Niet geïnstalleerd"
            Versie = "-"
        }
    }
}

if ($results.Count -gt 0) {
    Write-Host "`nModules check resultaat:`n" -ForegroundColor Cyan
    $results | Format-Table -AutoSize
} else {
    Write-Host "Geen modules gevonden." -ForegroundColor Yellow
}

Write-Host "`nModules zijn nagelopen. Druk op een toets om terug te gaan naar het menu" -ForegroundColor Green
$Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
Remove-Item $env:TEMP\CheckModulesScript.ps1
exit 0  # 0 = success, non-zero = error
