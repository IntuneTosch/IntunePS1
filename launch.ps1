# Check if the script is run as Administrator
$IsAdmin = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
$IsAdminRole = $IsAdmin.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $IsAdminRole) {
    # Relaunch the script with elevated privileges
    $arguments = "& '" + $MyInvocation.MyCommand.Definition + "'"
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command $arguments" -Verb RunAs
    exit
} else {
    Write-Host "The script is running with elevated privileges."
}

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

# Icon
$iconPath = "$env:TEMP\tosch_icon.png"
if (-not (Test-Path $iconPath)) {
    Invoke-WebRequest -Uri "https://tosch.nl/wp-content/uploads/2024/12/cropped-favicon-32x32.png" -OutFile $iconPath
}

# GUI XAML
$XAML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Tosch Intune" Height="400" Width="600" Background="#1E1B2E"
        WindowStartupLocation="CenterScreen">
    <Grid Margin="10">
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="150"/>
            <ColumnDefinition Width="*"/>
        </Grid.ColumnDefinitions>
        
        <!-- Sidebar -->
        <StackPanel Grid.Column="0" Background="#2A273E" Margin="0,0,10,0">
            <TextBlock Text="Tosch" Foreground="Orange" FontSize="45" FontWeight="Bold" 
                       Margin="10,20,10,10"/>
            <Button x:Name="btnInstallPowershell" Content="Install Powershell 7" Margin="10,5,10,5"
                    Background="#5A4BFF" Foreground="White" Padding="5"/>
            <Button x:Name="btnInstallModules" Content="Install Modules" Margin="10,5,10,5"
                    Background="#5A4BFF" Foreground="White" Padding="5"/>
            <Button x:Name="btnCheckModules" Content="Check Modules" Margin="10,5,10,5"
                    Background="#4BC6FF" Foreground="White" Padding="5"/>
            <Button x:Name="btnCreateUSB" Content="Create USB" Margin="10,5,10,10"
                    Background="#FACC15" Foreground="Black" Padding="5"/>
        </StackPanel>

        <!-- Main Display -->
        <StackPanel Grid.Column="1">
            <TextBlock Text="Intune USB Installer" Foreground="White"
                       FontSize="40" FontWeight="Bold" Margin="10,25,10,20"/>
            <TextBlock x:Name="txtStatus" Text="Selecteer links een optie..."
                       Foreground="LightGray" FontSize="14" Margin="10,0,10,0" TextWrapping="Wrap"/>
        </StackPanel>
    </Grid>
</Window>
"@

# Load XAML
[xml]$XAMLWindow = $XAML
$reader = (New-Object System.Xml.XmlNodeReader $XAMLWindow)
$Window = [Windows.Markup.XamlReader]::Load($reader)

# Set icon
$iconBitmap = New-Object System.Windows.Media.Imaging.BitmapImage
$iconBitmap.BeginInit()
$iconBitmap.UriSource = [Uri]::new($iconPath)
$iconBitmap.EndInit()
$Window.Icon = $iconBitmap

# Access controls
$btnInstallPowershell = $Window.FindName("btnInstallPowershell")
$btnInstallModules = $Window.FindName("btnInstallModules")
$btnCheckModules   = $Window.FindName("btnCheckModules")
$btnCreateUSB      = $Window.FindName("btnCreateUSB")
$txtStatus         = $Window.FindName("txtStatus")

# Functions
function Install-Powershell {
    $txtStatus.Text = "Controleren of PowerShell 7 al geïnstalleerd is..."

    # Use winget list to check if PowerShell 7 is already installed
    $output = winget list --id Microsoft.PowerShell | Out-String

    if ($output -match "Microsoft.PowerShell") {
        $txtStatus.Text += "`nPowerShell 7 is al geïnstalleerd."
    } else {
        $txtStatus.Text += "`nPowerShell 7 is niet gevonden. Installatie wordt gestart..."

        $installScript = @"
winget install --id Microsoft.PowerShell --silent
"@
        $tempInstallScript = "$env:TEMP\InstallPowerShell.ps1"
        $installScript | Set-Content -Path $tempInstallScript -Encoding UTF8

        # Launch external process
        $process = Start-Process powershell.exe -ArgumentList "-NoProfile", "-WindowStyle", "Hidden", "-File", "`"$tempInstallScript`"" -PassThru
        $process.WaitForExit()

        # Re-check installation
        Start-Sleep -Seconds 2
        $verify = winget list --id Microsoft.PowerShell | Out-String

        if ($verify -match "Microsoft.PowerShell") {
            $txtStatus.Text += "`nPowerShell 7 is succesvol geïnstalleerd."
        } else {
            $txtStatus.Text += "`nInstallatie mislukt of PowerShell 7 is nog steeds niet gevonden."
        }

        Remove-Item $tempInstallScript -Force -ErrorAction SilentlyContinue
    }
}
function Install-Modules {
    $txtStatus.Text = "Bezig met controleren/installeren van modules..."
    Start-Sleep -Seconds 1

    $modules = @(
        @{ Name = "MSAL.PS"; MinimumVersion = $null },
        @{ Name = "Intune.USB.Creator"; MinimumVersion = $null },
        @{ Name = "Microsoft.Graph.Authentication"; MinimumVersion = $null },
        @{ Name = "WindowsAutopilotIntune"; MinimumVersion = "5.4" },
        @{ Name = "Microsoft.Graph.Groups"; MinimumVersion = $null },
        @{ Name = "Microsoft.Graph.Identity.DirectoryManagement"; MinimumVersion = $null }
    )

    $syncContext = [System.Threading.SynchronizationContext]::Current

    foreach ($module in $modules) {
        if (Get-Module -ListAvailable -Name $module.Name) {
            $syncContext.Post({ param($msg) $txtStatus.Text += "`n$msg" }, "$($module.Name) is al geïnstalleerd.")
        } else {
            $arguments = if ($module.MinimumVersion) {
                "-NoProfile -Command `"Install-Module -Name '$($module.Name)' -MinimumVersion $($module.MinimumVersion) -Scope AllUsers -Force -Repository PSGallery`""
            } else {
                "-NoProfile -Command `"Install-Module -Name '$($module.Name)' -Scope AllUsers -Force -Repository PSGallery`""
            }

            $process = New-Object System.Diagnostics.Process
            $process.StartInfo.FileName = "powershell.exe"
            $process.StartInfo.Arguments = $arguments
            $process.StartInfo.RedirectStandardOutput = $true
            $process.StartInfo.RedirectStandardError = $true
            $process.StartInfo.UseShellExecute = $false
            $process.StartInfo.CreateNoWindow = $true

            $process.Start() | Out-Null

            while (-not $process.HasExited) {
                $line = $process.StandardOutput.ReadLine()
                if ($line) {
                    $syncContext.Post({ param($msg) $txtStatus.Text += "`n$msg" }, $line)
                }
            }

            while (!$process.StandardOutput.EndOfStream) {
                $line = $process.StandardOutput.ReadLine()
                $syncContext.Post({ param($msg) $txtStatus.Text += "`n$msg" }, $line)
            }

            if ($process.ExitCode -eq 0) {
                $syncContext.Post({ param($msg) $txtStatus.Text += "`n$msg" }, "$($module.Name) succesvol geïnstalleerd.")
            } else {
                $errorText = $process.StandardError.ReadToEnd()
                $syncContext.Post({ param($msg) $txtStatus.Text += "`n$msg" }, "Fout bij installeren van $($module.Name): $errorText")
            }
        }
    }
}

function Check-Modules {
    $txtStatus.Text = "Checking installed modules..."
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
            $statusOutput += "$moduleName is niet geïnstalleerd.`r`n"
        }
    }

    if ($statusOutput) {
        $txtStatus.Text = "Modules check resultaat:`n" + $statusOutput
    } else {
        $txtStatus.Text = "Geen modules gevonden."
    }
}

function Create-USB {
    $txtStatus.Text = "Downloaden van Script van GitHub..."
    $githubRawUrl = "https://raw.githubusercontent.com/IntuneTosch/IntunePS1/refs/heads/main/main.ps1"
    $tempScript = "$env:TEMP\MainFunctionScript.ps1"
    Invoke-WebRequest -Uri $githubRawUrl -OutFile $tempScript
    $txtStatus.Text = "Openen van Script in een nieuw venster..."
    Start-Sleep -Seconds 2
    Start-Process pwsh.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$tempScript`""
    $txtStatus.Text += "`nExtern venster geopend."
}

# Event Handlers
$btnInstallPowershell.Add_Click({ Install-Powershell })
$btnInstallModules.Add_Click({ Install-Modules })
$btnCheckModules.Add_Click({ Check-Modules })
$btnCreateUSB.Add_Click({ Create-USB })

# Run GUI
$Window.ShowDialog() | Out-Null
