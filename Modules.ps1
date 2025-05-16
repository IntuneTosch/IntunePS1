0.1
# Script to ensure required modules are installed under C:\Program Files\PowerShell\Modules

# Required modules list with optional minimum versions
$RequiredModules = @(
    @{ Name = "MSAL.PS" },
    @{ Name = "Intune.USB.Creator" },
    @{ Name = "Microsoft.Graph.Authentication" },
    @{ Name = "Microsoft.Graph.Intune" },
    @{ Name = "WindowsAutopilotIntune"; MinimumVersion = "5.4" },
    @{ Name = "Microsoft.Graph.Groups" },
    @{ Name = "Microsoft.Graph.Identity.DirectoryManagement" }
)

$RequiredPath = "C:\Program Files\PowerShell\Modules"

# Check for admin rights
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script must be run as administrator."
    exit 1
}

# Ensure NuGet provider is installed silently
try {
    if (-not (Get-PackageProvider -Name NuGet -ErrorAction Stop)) {
        throw "NuGet provider not found"
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
    $minVersion = $module.MinimumVersion
    $isCorrectlyInstalled = $false

    # Get all installed versions of the module
    $installedModules = Get-InstalledModule -Name $name -AllVersions -ErrorAction SilentlyContinue

    if ($installedModules) {
        foreach ($mod in $installedModules) {
            if ($mod.InstalledLocation -eq "$RequiredPath\$name") {
                if ($minVersion) {
                    if ($mod.Version -ge [Version]$minVersion) {
                        $isCorrectlyInstalled = $true
                    }
                } else {
                    $isCorrectlyInstalled = $true
                }
            } else {
                # Remove modules from incorrect paths
                Write-Host "Removing $name from $($mod.InstalledLocation)..." -ForegroundColor Red
                Uninstall-Module -Name $name -AllVersions -Force -ErrorAction SilentlyContinue
            }
        }
    }

    # Reinstall if not correctly installed
    if (-not $isCorrectlyInstalled) {
        Write-Host "Installing module $name..." -ForegroundColor Green
        $installParams = @{
            Name         = $name
            Scope        = 'AllUsers'
            Force        = $true
            AllowClobber = $true
        }
        if ($minVersion) {
            $installParams['MinimumVersion'] = $minVersion
        }
        Install-Module @installParams
    } else {
        Write-Host "Module $name is correctly installed." -ForegroundColor Cyan
    }
}

Write-Host "`nAll modules checked and installed if necessary." -ForegroundColor Green
