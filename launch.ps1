Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

##Icon##
$iconPath = "$env:TEMP\tosch_icon.png"
if (-not (Test-Path $iconPath)) {
    Invoke-WebRequest -Uri "https://tosch.nl/wp-content/uploads/2024/12/cropped-favicon-32x32.png" -OutFile $iconPath
}

# Create XAML UI
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
$iconBitmap = New-Object System.Windows.Media.Imaging.BitmapImage
$iconBitmap.BeginInit()
$iconBitmap.UriSource = [Uri]::new($iconPath)
$iconBitmap.EndInit()
$Window.Icon = $iconBitmap

# Access Controls
$btnInstallPowershell = $Window.FindName("btnInstallPowershell")
$btnInstallModules = $Window.FindName("btnInstallModules")
$btnCheckModules   = $Window.FindName("btnCheckModules")
$btnCreateUSB      = $Window.FindName("btnCreateUSB")
$txtStatus         = $Window.FindName("txtStatus")

# Functions
function Install-Powershell {
    Start-Sleep -seconds 1
    $txtStatus.Text = "Installeren van Powershell 7 via Winget"
    winget install --id Microsoft.PowerShell
}
function Install-Modules {
    $txtStatus.Text = "Checking and installing modules..."
    Start-Sleep -Seconds 1

    $modules = @(
        @{ Name = "MSAL.PS"; MinimumVersion = $null },
        @{ Name = "Intune.USB.Creator"; MinimumVersion = $null },
        @{ Name = "Microsoft.Graph.Authentication"; MinimumVersion = $null },
        @{ Name = "WindowsAutopilotIntune"; MinimumVersion = "5.4" },
        @{ Name = "Microsoft.Graph.Groups"; MinimumVersion = $null },
        @{ Name = "Microsoft.Graph.Identity.DirectoryManagement"; MinimumVersion = $null }
    )

    $statusOutput = ""

    foreach ($module in $modules) {
        if (Get-Module -ListAvailable -Name $module.Name) {
            $statusOutput += "$($module.Name) already installed.`r`n"
        } else {
            try {
                if ($module.MinimumVersion) {
                    Install-Module -Name $module.Name -MinimumVersion $module.MinimumVersion -Scope AllUsers -Repository PSGallery -Force -ErrorAction Stop
                } else {
                    Install-Module -Name $module.Name -Scope AllUsers -Repository PSGallery -Force -ErrorAction Stop
                }
                $statusOutput += "$($module.Name) installed successfully.`r`n"
            } catch {
                $statusOutput += "Failed to install $($module.Name): $_`r`n"
            }
        }
    }

    $txtStatus.Text = $statusOutput.TrimEnd()
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
            $statusOutput += "$($module.Name) - Version: $($module.Version)`r`n"
        } else {
            $statusOutput += "$moduleName is not installed.`r`n"
        }
    }

    if ($statusOutput) {
        $txtStatus.Text = "Modules check result:`n" + $statusOutput
    } else {
        $txtStatus.Text = "No modules found."
    }
}
function Create-USB {
    $txtStatus.Text = "Downloaden van Script van github"
    # Define the URL to the raw GitHub script
    $githubRawUrl = "https://raw.githubusercontent.com/IntuneTosch/IntunePS1/refs/heads/main/main.ps1"
    # Define the path to the temporary script file
    $tempScript = "$env:TEMP\MainFunctionScript.ps1"
    # Download the script content from GitHub
    Invoke-WebRequest -Uri $githubRawUrl -OutFile $tempScript
    # Launch it in a separate PowerShell process
    $txtStatus.Text = "Openen van Script in een apart venster"
    Start-Sleep -seconds 5
    Start-Process pwsh.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$tempScript`""
    $txtStatus.Text = "Extern window met Script success geopend."
}

# Event Handlers
$btnInstallPowershell.Add_Click({ Install-Powershell })
$btnInstallModules.Add_Click({ Install-Modules })
$btnCheckModules.Add_Click({ Check-Modules })
$btnCreateUSB.Add_Click({ Create-USB })

# Show Window
$Window.ShowDialog() | Out-Null
