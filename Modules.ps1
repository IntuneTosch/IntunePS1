#0.2
# List of required modules and optional minimum versions
$RequiredModules = @(
    @{ Name = "MSAL.PS" },
    @{ Name = "Intune.USB.Creator" },
    @{ Name = "Microsoft.Graph.Authentication" },
    @{ Name = "Microsoft.Graph.Intune" },
    @{ Name = "WindowsAutopilotIntune"; MinimumVersion = "5.4" },
    @{ Name = "Microsoft.Graph.Groups" },
    @{ Name = "Microsoft.Graph.Identity.DirectoryManagement" }
)

# Target module install path
$RequiredPath = "C:\Program Files\PowerShell\Modules"

# Ensure script runs as Administrator
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script must be run as Administrator."
    exit 1
}

# Install NuGet provider silently if missing
try {
    if (-not (Get-PackageProvider -Name NuGet -ErrorAction Stop)) {
        throw "NuGet not installed"
    }
} catch {
    Write-Host "Installing NuGet provider..." -ForegroundColor Yellow
    Install-PackageProvider -Name NuGet -Force -Scope AllUsers -Confirm:$false
}

# Trust PSGallery if not trusted
if ((Get-PSRepository -Name 'PSGallery').InstallationPolicy -ne 'Trusted') {
    Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted
}

# Loop through each required module
foreach ($module in $RequiredModules) {
    $name = $module.Name
    $minVersion = if ($module.ContainsKey("MinimumVersion")) { [Version]$module.MinimumVersion } else { $null }
    $needsInstall = $true

    $installedModules = Get-InstalledModule -Name $name -AllVersions -ErrorAction SilentlyContinue

    if ($installedModules) {
        foreach ($mod in $installedModules) {
            $isCorrectLocation = ($mod.InstalledLocation -eq "$RequiredPath\$name")
            $isCorrectVersion = ($minVersion -eq $null -or $mod.Version -ge $minVersion)

            if ($isCorrectLocation -and $isCorrectVersion) {
                Write-Host "✔ $name is already installed correctly." -ForegroundColor Cyan
                $needsInstall = $false
            } elseif (-not $isCorrectLocation) {
                Write-Host "✖ $name found at wrong location: $($mod.InstalledLocation). Removing..." -ForegroundColor Red
                Uninstall-Module -Name $name -AllVersions -Force -ErrorAction SilentlyContinue
            } elseif (-not $isCorrectVersion -and $isCorrectLocation) {
                Write-Host "⚠ $name is at $($mod.Version), which is below required version $minVersion. Reinstalling..." -ForegroundColor Yellow
                Uninstall-Module -Name $name -AllVersions -Force -ErrorAction SilentlyContinue
            }
        }
    }

    if ($needsInstall) {
        Write-Host "⬇ Installing $name..." -ForegroundColor Green
        $params = @{
            Name         = $name
            Scope        = "AllUsers"
            Force        = $true
            AllowClobber = $true
        }
        if ($minVersion) { $params["MinimumVersion"] = $minVersion }
        Install-Module @params
    }
}

Write-Host "`n✅ All modules are installed and validated." -ForegroundColor Green
