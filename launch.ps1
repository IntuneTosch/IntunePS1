#Version 0.8.2
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
        Title="Tosch Intune" Height="360" Width="600" Background="#f5f1e9"
        WindowStartupLocation="CenterScreen">
    <Grid Margin="10">
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="150"/>
            <ColumnDefinition Width="*"/>
        </Grid.ColumnDefinitions>
        
        <!-- Sidebar -->
        <StackPanel Grid.Column="0" Background="#1e4962" Margin="0,0,10,0">
            <TextBlock Text="Tosch" Foreground="#ff6f00" FontSize="45" FontWeight="Bold" 
                       Margin="10,20,10,10"/>
            <Button x:Name="btnInstallPowershell" Content="Install Powershell 7" Margin="10,5,10,5"
                    Background="#ff6f00" Foreground="White" Padding="5"/>
            <Button x:Name="btnInstallModules" Content="Install Modules" Margin="10,5,10,5"
                    Background="#ff6f00" Foreground="White" Padding="5"/>
            <Button x:Name="btnCheckModules" Content="Check Modules" Margin="10,5,10,5"
                    Background="#ff6f00" Foreground="White" Padding="5"/>
            <Button x:Name="btnCreateUSB" Content="Create USB" Margin="10,5,10,10"
                    Background="#ff6f00" Foreground="White" Padding="5"/>
            <Button x:Name="btnCreateUSBNP" Content="USB no Profile" Margin="10,15,10,10"
                    Background="#ff6f00" Foreground="White" Padding="5"/>
        </StackPanel>

        <!-- Main Display -->
        <StackPanel Grid.Column="1">
            <TextBlock Text="Intune USB Installer" Foreground="#ff6f00"
                       FontSize="40" FontWeight="Bold" Margin="10,25,10,20"/>
            <TextBlock x:Name="txtStatus" Text="Selecteer links een optie..."
                       Foreground="Black" FontSize="14" Margin="10,0,10,0" TextWrapping="Wrap"/>
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
$btnCreateUSBNP    = $Window.FindName("btnCreateUSBNP")
$txtStatus         = $Window.FindName("txtStatus")

# Functions
function Install-Powershell {
    # Controleer of PowerShell 7 al geïnstalleerd is
    $pwshPath = Get-Command pwsh -ErrorAction SilentlyContinue

    if ($pwshPath) {
        $txtStatus.Text = "PowerShell 7 is al geïnstalleerd. Installatie overgeslagen."
        return
    }

    # Installeer PowerShell 7
    $txtStatus.Text = "PowerShell 7 niet gevonden. Installatie wordt gestart..."
    $githubRawUrl = "https://raw.githubusercontent.com/IntuneTosch/IntunePS1/refs/heads/main/Powershell7.ps1"
    $ScriptPowershell = "$env:TEMP\PowershellScript.ps1"

    try {
        $txtStatus.Text += "`nDownloaden van script van GitHub..."
        Invoke-WebRequest -Uri $githubRawUrl -OutFile $ScriptPowershell -UseBasicParsing
        Start-Sleep -Seconds 2
        Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$ScriptPowershell`""
        $txtStatus.Text += "`nInstallatie van PowerShell 7 is gestart in een nieuw venster."
        $txtStatus.Text += "`n`nHertstart de Computer na installatie"
    }
    catch {
        $txtStatus.Text += "`nFout tijdens downloaden of starten van installatie: $_"
    }
}
function Install-Modules {

    # Controleer of pwsh.exe beschikbaar is
    $pwshPath = Get-Command pwsh.exe -ErrorAction SilentlyContinue

    if (-not $pwshPath) {
        $txtStatus.Text = "PowerShell 7 is niet gevonden.`n`n`nInstalleer PowerShell 7 handmatig of start de computer opnieuw op als deze net is geïnstalleerd."
        return
    }

    $txtStatus.Text = "PowerShell 7 is gevonden. Downloaden van script van GitHub..."
    
    $githubRawUrl = "https://raw.githubusercontent.com/IntuneTosch/IntunePS1/refs/heads/main/Modules.ps1"
    $ModulesScript = "$env:TEMP\ModulesScript.ps1"
    Invoke-WebRequest -Uri $githubRawUrl -OutFile $ModulesScript

    $txtStatus.Text += "`nOpenen van script in een nieuw venster..."
    Start-Sleep -Seconds 2
    Start-Process pwsh.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$ModulesScript`""
    $txtStatus.Text += "`nExtern venster geopend."
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

function Create-USBNP {
    $txtStatus.Text = "Downloaden van Script van GitHub..."
    $githubRawUrl = "https://raw.githubusercontent.com/IntuneTosch/IntunePS1/refs/heads/main/mainnp.ps1"
    $tempScriptNP = "$env:TEMP\MainFunctionScriptNP.ps1"
    Invoke-WebRequest -Uri $githubRawUrl -OutFile $tempScriptNP
    $txtStatus.Text = "Openen van Script in een nieuw venster..."
    Start-Sleep -Seconds 2
    Start-Process pwsh.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$tempScriptNP`""
    $txtStatus.Text += "`nExtern venster geopend. Zorg ervoor dat je zelf het provisioning-bestand kopieert."
}

# Event Handlers
$btnInstallPowershell.Add_Click({ Install-Powershell })
$btnInstallModules.Add_Click({ Install-Modules })
$btnCheckModules.Add_Click({ Check-Modules })
$btnCreateUSB.Add_Click({ Create-USB })
$btnCreateUSBNP.Add_Click({ Create-USBNP })

# Run GUI
$Window.ShowDialog() | Out-Null
