# Ensure winget is available
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Error "winget is not installed or not available in the system PATH."
    exit 1
}

# Install PowerShell 7 using winget and accept terms automatically
try {
    Write-Host "Installing PowerShell 7 using winget..."
    winget install --id Microsoft.Powershell --source winget --accept-package-agreements --accept-source-agreements --silent
    Write-Host "PowerShell 7 installation completed."
} catch {
    Write-Error "An error occurred while installing PowerShell 7: $_"
}
exit
