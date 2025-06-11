###############################################################################################################
######                                          Variable                                                 ######
###############################################################################################################

#Script Version
$Scriptversion = "1.7.3"

# Define default ISO file path
$DefaultISOPath1 = "C:\Users\$env:USERNAME\Tosch Automatisering B.V\Techniek - General\ISO\Windows 11 Intune\W11Intune1.7.iso"
$DefaultISOPath2 = "C:\Users\$env:USERNAME\Tosch Automatisering B.V\Techniek - Documenten\General\ISO\Windows 11 Intune\W11Intune1.7.iso"

# Define default provision file path
$DefaultProvisionPath1 = "C:\Users\$env:USERNAME\Tosch Automatisering B.V\Techniek - General\ISO\Windows 11 Intune\Invoke-Provision.ps1"
$DefaultProvisionPath2 = "C:\Users\$env:USERNAME\Tosch Automatisering B.V\Techniek - Documenten\General\ISO\Windows 11 Intune\Invoke-Provision.ps1"

# Resolve default path with current username
$DefaultDriversPath1 = "C:\Users\$env:USERNAME\Tosch Automatisering B.V\Techniek - General\ISO\Windows 11 Intune\Drivers"
$DefaultDriversPath2 = "C:\Users\$env:USERNAME\Tosch Automatisering B.V\Techniek - Documenten\General\ISO\Windows 11 Intune\Drivers"

###############################################################################################################
######                                          Start Script                                             ######
###############################################################################################################
Clear-Host
$welcomeScreen = "IF9fX19fX19fXyAgICBfX19fX19fXyAgICAgX19fX19fX18gICAgICBfX19fX19fXyAgICAgX19fICBfX18gICAgIA0KfFxfX18gICBfX19cIHxcICAgX18gIFwgICB8XCAgIF9fX19cICAgIHxcICAgX19fX1wgICB8XCAgXHxcICBcICAgIA0KXHxfX18gXCAgXF98IFwgXCAgXHxcICBcICBcIFwgIFxfX198XyAgIFwgXCAgXF9fX3wgICBcIFwgIFxcXCAgXCAgIA0KICAgICBcIFwgIFwgICBcIFwgIFxcXCAgXCAgXCBcX19fX18gIFwgICBcIFwgIFwgICAgICAgXCBcICAgX18gIFwgIA0KICAgICAgXCBcICBcICAgXCBcICBcXFwgIFwgIFx8X19fX3xcICBcICAgXCBcICBcX19fXyAgIFwgXCAgXCBcICBcIA0KICAgICAgIFwgXCAgXCAgIFwgXCAgXFxcICBcICAgX19fX1xfXCAgXCAgIFwgXCAgICAgICBcICBcIFwgIFwgXCAgXA0KICAgICAgICBcIFxfX1wgICBcIFxfX19fX19fXCAgfFxfX19fX19fX1wgICBcIFxfX19fX19fXCAgXCBcX19cIFxfX1wNCiAgICAgICAgIFx8X198ICAgIFx8X19fX19fX3wgIFx8X19fX19fX19ffCAgIFx8X19fX19fX3wgICBcfF9ffFx8X198IA0KICAgICAgICAgICAgICAgICAgICBXaW5kb3dzIEVuZHBvaW50IFByb3Zpc2lvbmluZyBUb29sDQogICAgICAgICAgICAgICAgICAgKioqKioqKioqKioqKioqKioqKioqKioqKioqKioqKioqKioq"
Write-Host $([system.text.encoding]::UTF8.GetString([system.convert]::FromBase64String($welcomeScreen)))            
Write-host "Version $Scriptversion No Profile - Nederlands" -ForegroundColor DarkRed
Start-Sleep -Seconds 3
Clear-Host
###############################################################################################################
######                                          Import Modules                                           ######
###############################################################################################################
Import-Module MSAL.PS
Import-Module Intune.USB.Creator
Import-Module Microsoft.Graph.Authentication
Import-Module Microsoft.Graph.Intune
Import-Module WindowsAutopilotIntune -MinimumVersion 5.4
Import-Module Microsoft.Graph.Groups
Import-Module Microsoft.Graph.Identity.DirectoryManagement
#  -RequiredVersion 2.8.0
Write-Host $([system.text.encoding]::UTF8.GetString([system.convert]::FromBase64String($welcomeScreen)))          
Write-Host "Modules zijn succesvol geïmporteerd."  -ForegroundColor Green
""
Start-Sleep -Seconds 1.5

###############################################################################################################
######                                          Create Dir                                               ######
###############################################################################################################

#Create path for files
$DirectoryToCreate = "c:\temp"
if (-not (Test-Path -LiteralPath $DirectoryToCreate)) {
    
    try {
        New-Item -Path $DirectoryToCreate -ItemType Directory -ErrorAction Stop | Out-Null #-Force
    }
    catch {
        Write-Error -Message "De tijdelijke map kon niet worden aangemaakt: '$DirectoryToCreate'. Error was: $_" -ErrorAction Stop
    }
    Write-Host "Tijdelijke bestandslocatie is aangemaakt.'$DirectoryToCreate'." -ForegroundColor Green
    ""
}
else {
    Write-Host "Tijdelijke bestandslocatie bestaat al." -ForegroundColor Green
    ""
    Start-Sleep -Seconds 1.5
}


$random = Get-Random -Maximum 1000 
$random = $random.ToString()
$date =get-date -format yyMMddmmss
$date = $date.ToString()
$path2 = $random + "-"  + $date
$path = "c:\temp\" + $path2

New-Item -ItemType Directory -Path $path -Force | Out-Null
if (Test-Path $path) {
    Write-Host "De willekeurige map is succesvol aangemaakt." -ForegroundColor Green
    ""
    Start-Sleep -Seconds 1.5
}
else {
    Write-Host $([system.text.encoding]::UTF8.GetString([system.convert]::FromBase64String($welcomeScreen)))    
    Write-Error "De willekeurige map kon niet worden aangemaakt." -ErrorAction Stop
    ""
    Start-Sleep -Seconds 10
}

###############################################################################################################
######                                          Add Extra Functions                                      ######
###############################################################################################################

##Functie nalopen ISO
Add-Type -AssemblyName PresentationFramework, System.Drawing
function Select-Drive($volumeLabel) {
    $ListUSB = [System.IO.DriveInfo]::getdrives() | Where-Object {$_.DriveType -ne 'Network'} | Select-Object -Property VolumeLabel,Name

    $Drives = $ListUSB | Where-Object {$_.VolumeLabel -eq $volumeLabel} | Select-Object -ExpandProperty Name

    if ($Drives.Count -gt 1) {
    Write-Host "Fout: Er zijn meerdere drives met de VolumeLabel 'WINPE'. Gebruik 1 USB."  -ForegroundColor DarkRed
    } elseif ($Drives.Count -eq 1) {
        return ($Drives[0] + ":\")
    } else {
        Write-Host "Er zijn geen drives gevonden met de VolumeLabel '$volumeLabel'."  -ForegroundColor DarkRed
        return $null
    }
}

##ISO Selecteren Functie:
function Select-ISO {
    [CmdletBinding()]
    param ()

    Add-Type -AssemblyName System.Windows.Forms
    
    #Variablen staan bovenaan
    if (Test-Path $DefaultISOPath1) {
        $DefaultISOPath = $DefaultISOPath1
    } elseif (Test-Path $DefaultISOPath2) {
        $DefaultISOPath = $DefaultISOPath2
    } else {
        $DefaultISOPath = ""
    }

    if (Test-Path $DefaultISOPath) {
        return $DefaultISOPath
    } else {
        $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
        $OpenFileDialog.Filter = 'ISO Files (*.iso)|*.iso'
        $OpenFileDialog.Title = "Selecteer de Windows ISO bestand"

        if ($OpenFileDialog.ShowDialog() -eq 'OK') {
            return $OpenFileDialog.FileName
        } else {
            return $null
        }
    }
}

##Provisioning file PS1 Selecteren Functie:
function Select-Provision {
    [CmdletBinding()]
    param ()

    Add-Type -AssemblyName System.Windows.Forms

    #Variablen staan bovenaan
    if (Test-Path $DefaultProvisionPath1) {
        $DefaultProvisionPath = $DefaultProvisionPath1
    } elseif (Test-Path $DefaultProvisionPath2) {
        $DefaultProvisionPath = $DefaultProvisionPath2
    } else {
        $DefaultProvisionPath = ""
    }

    if (Test-Path $DefaultProvisionPath) {
        return $DefaultProvisionPath
    } else {
        $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
        $OpenFileDialog.Filter = 'PS1 Files (*.ps1)|*.ps1'
        $OpenFileDialog.Title = "Selecteer de PowerShell provisioning script"

        if ($OpenFileDialog.ShowDialog() -eq 'OK') {
            return $OpenFileDialog.FileName
        } else {
            return $null
        }
    }
}

##Driver folder kiezen
function Select-DriverFolder {
    [CmdletBinding()]
    param ()

    Add-Type -AssemblyName System.Windows.Forms

    #Variablen staan bovenaan
    if (Test-Path $DefaultDriversPath1) {
        $DefaultDriversPath = $DefaultDriversPath1
    } elseif (Test-Path $DefaultDriversPath2) {
        $DefaultDriversPath = $DefaultDriversPath2
    } else {
        $DefaultDriversPath = ""
    }

    if (Test-Path $DefaultDriversPath) {
        return $DefaultDriversPath
    } else {
        $FolderBrowserDialog = New-Object System.Windows.Forms.FolderBrowserDialog
        $FolderBrowserDialog.Description = "Selecteer de driver Map"

        if ($FolderBrowserDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            return $FolderBrowserDialog.SelectedPath
        } else {
            return $null
        }
    }
}
Write-Host "Functies zijn succesvol geïmporteerd." -ForegroundColor Green
""
Start-Sleep -Seconds 2
###############################################################################################################
######                                              Execution Endpoint                                   ######
###############################################################################################################

##Selecteren ISO:
$WindowsISO = Select-ISO
if (-not $WindowsISO -or -not (Test-Path $WindowsISO)) {
    Write-Error "Er is geen geldig ISO-bestand geselecteerd. Het script wordt beëindigd."
    exit 1
}
$DriverFolder = Select-DriverFolder
if (-not $DriverFolder -or -not (Test-Path $DriverFolder)) {
    Write-Error "Er is geen geldig ISO-bestand geselecteerd. Het script wordt beëindigd."
    exit 1
}
$ProvisionInvoke = Select-Provision
if (-not $ProvisionInvoke -or -not (Test-Path $ProvisionInvoke)) {
    Write-Error "Er is geen geldig ISO-bestand geselecteerd. Het script wordt beëindigd."
    exit 1
}

Write-Host "Alle voorbereidingen zijn succesvol afgerond." -ForegroundColor Red
Start-Sleep -Seconds 2
Clear-Host
Write-Host "Installatie van USB gaat nu gebeuren" -ForegroundColor Green -BackgroundColor Black
Start-Sleep -Seconds 3

##Installatie Endpoint Stick:
Publish-ImageToUSB -winPEPath "https://githublfs.blob.core.windows.net/storage/WinPE.zip" -windowsIsoPath $WindowsISO

##Kijken of er 1 USB is met de naam "WINPE"
$WINPE = Select-Drive -volumeLabel "WINPE"

##Kopieren JSON
$profilejson | Out-file -Filepath $winpe\Scripts\AutopilotConfigurationFile.json

##Kijken of er 1 USB is met de naam "Images"
$USBImages = Select-Drive -volumeLabel "Images"

##Kopieren van ProvisionInvoke PS1 script naar de juiste folder en overschrijven
Get-Item -Path $ProvisionInvoke
Copy-Item $ProvisionInvoke $winpe\Scripts\ -Force

##Kijken of er 1 USB is met de naam "Images"
$USBImages = Select-Drive -volumeLabel "Images"

Remove-Item $env:TEMP\CreateUSBScriptNP.ps1
""
""
""
Write-Host "USB Is Succesvol gemaakt, Druk op een toets om dit venster af te sluiten." -ForegroundColor Green
$Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
exit 0  # 0 = success, non-zero = error
""
""
""
