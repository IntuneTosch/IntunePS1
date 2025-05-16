# 0.3
# List of required modules with optional minimum versions
$RequiredModules = @(
    @{ Name = "MSAL.PS" },
    @{ Name = "Microsoft.Graph.Groups" },
    @{ Name = "Microsoft.Graph.Identity.DirectoryManagement" },
    @{ Name = "Microsoft.Graph.Authentication" },
    @{ Name = "Microsoft.Graph.Intune" },
    @{ Name = "Intune.USB.Creator" },
    @{ Name = "WindowsAutopilotIntune"; MinimumVersion = "5.4" }

)

# Valid installation paths
$ValidPaths = @(
    "C:\Program Files\PowerShell\Modules",
    "C:\Program Files\WindowsPowerShell\Modules"
)

$TargetInstallPath = "C:\Program Files\PowerShell\Modules"

# Check for admin privileges
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script must be run as Administrator."
    exit 1
}

# Ensure NuGet provider is installed silently
try {
    if (-not (Get-PackageProvider -Name NuGet -ErrorAction Stop)) {
        throw "NuGet not installed"
    }
} catch {
    Write-Host "Installing NuGet provider..." -ForegroundColor Yellow
    Install-PackageProvider -Name NuGet -Force -Scope AllUsers -Confirm:$false
}

# Trust PSGallery
if ((Get-PSRepository -Name 'PSGallery').InstallationPolicy -ne 'Trusted') {
    Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted
}

# Process each module
foreach ($module in $RequiredModules) {
    $name = $module.Name
    $minVersion = if ($module.ContainsKey("MinimumVersion")) { [Version]$module.MinimumVersion } else { $null }
    $needsInstall = $true

    $installedModules = Get-InstalledModule -Name $name -AllVersions -ErrorAction SilentlyContinue

    if ($installedModules) {
        foreach ($mod in $installedModules) {
            $isValidLocation = $ValidPaths -contains (Split-Path $mod.InstalledLocation -Parent)
            $isCorrectVersion = ($minVersion -eq $null -or $mod.Version -ge $minVersion)

            if ($isValidLocation -and $isCorrectVersion) {
                Write-Host "✔ $name is already installed correctly at $($mod.InstalledLocation)." -ForegroundColor Cyan
                $needsInstall = $false
            } elseif (-not $isValidLocation) {
                Write-Host "✖ $name found at wrong location: $($mod.InstalledLocation). Removing..." -ForegroundColor Red
                Uninstall-Module -Name $name -AllVersions -Force -ErrorAction SilentlyContinue
            } elseif (-not $isCorrectVersion -and $isValidLocation) {
                Write-Host "⚠ $name is version $($mod.Version), below required $minVersion. Removing..." -ForegroundColor Yellow
                Uninstall-Module -Name $name -AllVersions -Force -ErrorAction SilentlyContinue
            }
        }
    }

    if ($needsInstall) {
        Write-Host "⬇ Installing $name to $TargetInstallPath..." -ForegroundColor Green
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

Write-Host "`n✅ All modules are validated and installed correctly." -ForegroundColor Green
