# Check-Modules.ps1
Write-Host "Check Modules Version 0.1" -ForegroundColor Green

Write-Host "Checking installed modules..."
Start-Sleep -Seconds 1

$modulesToCheck = @(
    "MSAL.PS",
    "Intune.USB.Creator",
    "Microsoft.Graph.Authentication",
    "WindowsAutopilotIntune",
    "Microsoft.Graph.Groups",
    "Microsoft.Graph.Identity.DirectoryManagement"
)

$statusOutput = ""

foreach ($moduleName in $modulesToCheck) {
    $module = Get-InstalledModule -Name $moduleName -ErrorAction SilentlyContinue
    if ($module) {
        $statusOutput += "$($module.Name) - Versie: $($module.Version)`r`n"
    } else {
        $statusOutput += "$moduleName is niet geinstalleerd.`r`n"
    }
}

if ($statusOutput) {
    Write-Host "`nModules check resultaat:`n$statusOutput"
} else {
    Write-Host "Geen modules gevonden."
}
Write-Host "Modules zijn nagelopen. Druk op een toets om terug te gaan naar het menu" -ForegroundColor Green
$Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
exit 0  # 0 = success, non-zero = error