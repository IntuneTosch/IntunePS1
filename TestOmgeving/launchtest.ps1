#Version 1.6
# Check for admin rights
$IsAdmin = [Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
$IsAdminRole = $IsAdmin.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $IsAdminRole) {
    # Not elevated — save the current script to a temp file
    $LaunchScriptURL = "https://raw.githubusercontent.com/IntuneTosch/IntunePS1/refs/heads/main/launch.ps1"
    $LaunchScript = "$env:TEMP\launch_elevated.ps1"

    Invoke-WebRequest -Uri $LaunchScriptURL -OutFile $LaunchScript

    # Re-launch with elevated rights, hidden
    $command = "-NoProfile -ExecutionPolicy Bypass -File `"$LaunchScript`""
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = "pwsh.exe"
    $psi.Arguments = $command
    $psi.Verb = "runas"
    $psi.WindowStyle = "Hidden"
    [System.Diagnostics.Process]::Start($psi)
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
        Title="Tosch Intune 1.6" Height="390" Width="600" Background="#f5f1e9"
        WindowStartupLocation="CenterScreen">
    <Grid Margin="10">
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="150"/>
            <ColumnDefinition Width="*"/>
        </Grid.ColumnDefinitions>
        
        <!-- Sidebar -->
<StackPanel Grid.Column="0" Background="#1e4962" Margin="0,0,10,0">
        <TextBlock Text="Tosch" Foreground="#ff6f00" FontSize="45" FontWeight="Bold" Margin="10,20,10,10"/>
            <Button x:Name="btnInstallPowershell" Content="Install Powershell 7" Margin="10,5,10,5"
                Background="#ff6f00" Foreground="White" Padding="5"/>
            <Button x:Name="btnInstallModules" Content="Install Modules" Margin="10,5,10,5"
                Background="#ff6f00" Foreground="White" Padding="5"/>
            <Button x:Name="btnCheckModules" Content="Check Modules" Margin="10,5,10,5"
                Background="#ff6f00" Foreground="White" Padding="5"/>
    
        <!-- New Language Dropdown + Create USB -->
            <ComboBox x:Name="cmbLanguage" Margin="10,25,10,5" SelectedIndex="0">
                <ComboBoxItem>Nederlands</ComboBoxItem>
                <ComboBoxItem>Engels</ComboBoxItem>
            </ComboBox>
                <Button x:Name="btnCreateUSB" Content="Create USB" Margin="10,5,10,5"
                    Background="#ff6f00" Foreground="White" Padding="5"/>
            
                <Button x:Name="btnCreateUSBNP" Content="USB no Profile" Margin="10,5,10,5"
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
$cmbLanguage       = $Window.FindName("cmbLanguage")

# Functions
function Install-Powershell {
    # Controleer of PowerShell 7 al geinstalleerd is
    $pwshPath = Get-Command pwsh -ErrorAction SilentlyContinue

    if ($pwshPath) {
        $txtStatus.Text = "PowerShell 7 is al geinstalleerd. Installatie overgeslagen."
        return
    }

    # Installeer PowerShell 7
    $txtStatus.Text = "PowerShell 7 niet gevonden. Installatie wordt gestart..."
    $githubRawUrlPS = "https://raw.githubusercontent.com/IntuneTosch/IntunePS1/refs/heads/main/Requirements/Powershell7.ps1"
    $ScriptPowershell = "$env:TEMP\PowershellScript.ps1"

    try {
        $txtStatus.Text += "`nDownloaden van script van GitHub..."
        Invoke-WebRequest -Uri $githubRawUrlPS -OutFile $ScriptPowershell -UseBasicParsing
        Start-Sleep -Seconds 2
        Start-Process powershell.exe -WindowStyle Hidden -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$ScriptPowershell`""
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
        $txtStatus.Text = "PowerShell 7 is niet gevonden.`n`n`nInstalleer PowerShell 7 handmatig of start de computer opnieuw op als deze net is geinstalleerd."
        return
    }

    $txtStatus.Text = "PowerShell 7 is gevonden.`nDownloaden van script van GitHub..."
    
    $githubRawUrlInstallModules = "https://raw.githubusercontent.com/IntuneTosch/IntunePS1/refs/heads/main/Requirements/Modules.ps1"
    $ModulesScript = "$env:TEMP\ModulesScript.ps1"
    Invoke-WebRequest -Uri $githubRawUrlInstallModules -OutFile $ModulesScript

    $txtStatus.Text += "`nOpenen van script in een nieuw venster..."
    Start-Sleep -Seconds 2
    Start-Process pwsh.exe -WindowStyle Hidden -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$ModulesScript`""
    $txtStatus.Text += "`nExtern venster geopend."
}

function Check-Modules {
    # Controleer of pwsh.exe beschikbaar is
    $pwshPath = Get-Command pwsh.exe -ErrorAction SilentlyContinue

    if (-not $pwshPath) {
        $txtStatus.Text = "PowerShell 7 is niet gevonden.`n`nInstalleer PowerShell 7 handmatig of start de computer opnieuw op als deze net is geinstalleerd."
        return
    }

    $txtStatus.Text = "PowerShell 7 is gevonden.`nDownloaden van script van GitHub..."
    
    $githubRawUrlCheckModules = "https://raw.githubusercontent.com/IntuneTosch/IntunePS1/refs/heads/main/Requirements/CheckModules.ps1"
    $CheckModulesScript = "$env:TEMP\CheckModulesScript.ps1"
    Invoke-WebRequest -Uri $githubRawUrlCheckModules -OutFile $CheckModulesScript

    $txtStatus.Text += "`nOpenen van script in een nieuw venster..."
    Start-Sleep -Seconds 2
    Start-Process pwsh.exe -WindowStyle Hidden -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$CheckModulesScript`""
    $txtStatus.Text += "`n`nModules worden nagelopen in extern venster."
}

function Create-USB {
    # Controleer of pwsh.exe beschikbaar is
    $pwshPath = Get-Command pwsh.exe -ErrorAction SilentlyContinue

    if (-not $pwshPath) {
        $txtStatus.Text = "PowerShell 7 is niet gevonden.`nInstalleer PowerShell 7 handmatig of start de computer opnieuw op als deze net is geinstalleerd."
        return
    }

    $txtStatus.Text = "PowerShell 7 is gevonden.`nDownloaden van script van GitHub..."
    
    # Determine selected language
    $selectedLanguage = $cmbLanguage.SelectedItem.Content

    if ($selectedLanguage -eq "Nederlands") {
        $githubRawUrlCreateUSB = "https://raw.githubusercontent.com/IntuneTosch/IntunePS1/refs/heads/main/Production/ISOMetProfiel/main_nl.ps1"
    } elseif ($selectedLanguage -eq "Engels") {
        $githubRawUrlCreateUSB = "https://raw.githubusercontent.com/IntuneTosch/IntunePS1/refs/heads/main/Production/ISOMetProfiel/main_en.ps1"
    } else {
        $txtStatus.Text += "`nGeen geldige taal geselecteerd. Kies een taal."
        return
    }

    $CreateUSBScript = "$env:TEMP\CreateUSBScript.ps1"
    Invoke-WebRequest -Uri $githubRawUrlCreateUSB -OutFile $CreateUSBScript

    $txtStatus.Text += "`nOpenen van script in een nieuw venster..."
    Start-Sleep -Seconds 2
    Start-Process pwsh.exe -WindowStyle Hidden -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$CreateUSBScript`""
    $txtStatus.Text += "`nExtern venster geopend."
}

function Create-USBNP {
    # Controleer of pwsh.exe beschikbaar is
    $pwshPath = Get-Command pwsh.exe -ErrorAction SilentlyContinue

    if (-not $pwshPath) {
        $txtStatus.Text = "PowerShell 7 is niet gevonden.`nInstalleer PowerShell 7 handmatig of start de computer opnieuw op als deze net is geinstalleerd."
        return
    }

    $txtStatus.Text = "PowerShell 7 is gevonden.`nDownloaden van script van GitHub..."
    
    # Determine selected language
    $selectedLanguage = $cmbLanguage.SelectedItem.Content

    if ($selectedLanguage -eq "Nederlands") {
        $githubRawUrlCreateUSBNP = "https://raw.githubusercontent.com/IntuneTosch/IntunePS1/refs/heads/main/Production/ISOZonderProfiel/mainnp_nl.ps1"
    } elseif ($selectedLanguage -eq "Engels") {
        $githubRawUrlCreateUSBNP = "https://raw.githubusercontent.com/IntuneTosch/IntunePS1/refs/heads/main/Production/ISOZonderProfiel/mainnp_en.ps1"
    } else {
        $txtStatus.Text += "`nGeen geldige taal geselecteerd. Kies een taal."
        return
    }

    $CreateUSBScriptNP = "$env:TEMP\CreateUSBScriptNP.ps1"
    Invoke-WebRequest -Uri $githubRawUrlCreateUSBNP -OutFile $CreateUSBScriptNP

    $txtStatus.Text += "`nOpenen van script in een nieuw venster..."
    Start-Sleep -Seconds 2
    Start-Process pwsh.exe -WindowStyle Hidden -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$CreateUSBScriptNP`""
    $txtStatus.Text += "`nExtern venster geopend."
}

# Event Handlers
$btnInstallPowershell.Add_Click({ Install-Powershell })
$btnInstallModules.Add_Click({ Install-Modules })
$btnCheckModules.Add_Click({ Check-Modules })
$btnCreateUSB.Add_Click({ Create-USB })
$btnCreateUSBNP.Add_Click({ Create-USBNP })

# Run GUI
$Window.ShowDialog() | Out-Null
