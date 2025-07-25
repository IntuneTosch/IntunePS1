###############################################################################################################
######                                          Variable                                                 ######
###############################################################################################################

#Script Version
$Scriptversion = "1.8.0"

# Define default ISO file path
$DefaultISOPath1 = "C:\Users\$env:USERNAME\Tosch Automatisering B.V\Techniek - General\ISO\Windows 11 Intune\W11IntuneEnglish1.8.iso"
$DefaultISOPath2 = "C:\Users\$env:USERNAME\Tosch Automatisering B.V\Techniek - Documenten\General\ISO\Windows 11 Intune\W11IntuneEnglish1.8.iso"
$DefaultISOPath3 = "C:\Users\$env:USERNAME\Tosch Automatisering B.V\Techniek - Documents\General\ISO\Windows 11 Intune\W11IntuneEnglish1.8.iso"

# Define default provision file path
$DefaultProvisionPath1 = "C:\Users\$env:USERNAME\Tosch Automatisering B.V\Techniek - General\ISO\Windows 11 Intune\Invoke-Provision.ps1"
$DefaultProvisionPath2 = "C:\Users\$env:USERNAME\Tosch Automatisering B.V\Techniek - Documenten\General\ISO\Windows 11 Intune\Invoke-Provision.ps1"
$DefaultProvisionPath3 = "C:\Users\$env:USERNAME\Tosch Automatisering B.V\Techniek - Documents\General\ISO\Windows 11 Intune\Invoke-Provision.ps1"

# Resolve default path with current username
$DefaultDriversPath1 = "C:\Users\$env:USERNAME\Tosch Automatisering B.V\Techniek - General\ISO\Windows 11 Intune\Drivers"
$DefaultDriversPath2 = "C:\Users\$env:USERNAME\Tosch Automatisering B.V\Techniek - Documenten\General\ISO\Windows 11 Intune\Drivers"
$DefaultDriversPath3 = "C:\Users\$env:USERNAME\Tosch Automatisering B.V\Techniek - Documents\General\ISO\Windows 11 Intune\Drivers"

###############################################################################################################
######                                          Start Script                                             ######
###############################################################################################################

Clear-Host
$welcomeScreen = "IF9fX19fX19fXyAgICBfX19fX19fXyAgICAgX19fX19fX18gICAgICBfX19fX19fXyAgICAgX19fICBfX18gICAgIA0KfFxfX18gICBfX19cIHxcICAgX18gIFwgICB8XCAgIF9fX19cICAgIHxcICAgX19fX1wgICB8XCAgXHxcICBcICAgIA0KXHxfX18gXCAgXF98IFwgXCAgXHxcICBcICBcIFwgIFxfX198XyAgIFwgXCAgXF9fX3wgICBcIFwgIFxcXCAgXCAgIA0KICAgICBcIFwgIFwgICBcIFwgIFxcXCAgXCAgXCBcX19fX18gIFwgICBcIFwgIFwgICAgICAgXCBcICAgX18gIFwgIA0KICAgICAgXCBcICBcICAgXCBcICBcXFwgIFwgIFx8X19fX3xcICBcICAgXCBcICBcX19fXyAgIFwgXCAgXCBcICBcIA0KICAgICAgIFwgXCAgXCAgIFwgXCAgXFxcICBcICAgX19fX1xfXCAgXCAgIFwgXCAgICAgICBcICBcIFwgIFwgXCAgXA0KICAgICAgICBcIFxfX1wgICBcIFxfX19fX19fXCAgfFxfX19fX19fX1wgICBcIFxfX19fX19fXCAgXCBcX19cIFxfX1wNCiAgICAgICAgIFx8X198ICAgIFx8X19fX19fX3wgIFx8X19fX19fX19ffCAgIFx8X19fX19fX3wgICBcfF9ffFx8X198IA0KICAgICAgICAgICAgICAgICAgICBXaW5kb3dzIEVuZHBvaW50IFByb3Zpc2lvbmluZyBUb29sDQogICAgICAgICAgICAgICAgICAgKioqKioqKioqKioqKioqKioqKioqKioqKioqKioqKioqKioq"
Write-Host $([system.text.encoding]::UTF8.GetString([system.convert]::FromBase64String($welcomeScreen)))            
Write-host "Version $Scriptversion - Engels" -ForegroundColor DarkRed
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
######                                          Add Functions                                            ######
###############################################################################################################

function GrabProfiles() {
    # Define Graph API endpoint
    $graphApiVersion = "beta"
    $Resource = "deviceManagement/windowsAutopilotDeploymentProfiles"
    $uri = "https://graph.microsoft.com/$graphApiVersion/$Resource"

    # Initial request
    $response = Invoke-MGGraphRequest -Uri $uri -Method Get -OutputType PSObject
    $profiles = $response.value
    $profilesNextLink = $response."@odata.nextLink"

    # Handle pagination
    while ($null -ne $profilesNextLink) {
        $profilesResponse = Invoke-MGGraphRequest -Uri $profilesNextLink -Method Get -OutputType PSObject
        $profilesNextLink = $profilesResponse."@odata.nextLink"
        $profiles += $profilesResponse.value
    }

    if (-not $profiles) {
        Write-Host "Geen autopilot profielen gevonden." -ForegroundColor Yellow
        return $null
    }

    # Display profiles as numbered list with extra fields
    Write-Host ""
    Write-Host "Beschikbare Autopilot Profielen:`n" -ForegroundColor Cyan

    $i = 1
    foreach ($profile in $profiles) {
        $displayName         = $profile.displayName
        $language            = if ($profile.language) { $profile.language } else { "[None]" }
        $createdDateTime     = $profile.createdDateTime
        $modifiedDateTime    = $profile.lastModifiedDateTime
        $description         = if ($profile.description) { $profile.description } else { "[No description]" }
        $deviceNameTemplate  = if ($profile.deviceNameTemplate) { $profile.deviceNameTemplate } else { "[None]" }

        Write-Host ("[{0}] Profiel: {1}" -f $i, $displayName) -ForegroundColor White
        Write-Host ("     Gecreëerd:            {0}" -f $createdDateTime)
        Write-Host ("     Aangepast:            {0}" -f $modifiedDateTime)
        Write-Host ("     Taal:                 {0}" -f $language)
        Write-Host ("     Beschrijving:         {0}" -f $description)
        Write-Host ("     Apparaatsjabloon:     {0}" -f $deviceNameTemplate)
        Write-Host ""
        $i++
    }

    $selection = Read-Host "Geef het nummer op van het profiel dat je wilt selecteren."

    if ($selection -match '^\d+$' -and [int]$selection -ge 1 -and [int]$selection -le $profiles.Count) {
        $selectedProfile = $profiles[([int]$selection - 1)]
        return $selectedProfile.id
    } else {
        Write-Host "Invalid selection." -ForegroundColor Red
        return $null
    }
}
function grabandoutput() {
[cmdletbinding()]

param
(
[string]$id

)

        # Defining Variables
        $graphApiVersion = "beta"
    $Resource = "deviceManagement/windowsAutopilotDeploymentProfiles"

$uri = "https://graph.microsoft.com/$graphApiVersion/$Resource/$id"
$approfile = Invoke-MGGraphRequest -Uri $uri -Method Get -OutputType PSObject

# Set the org-related info
$script:TenantOrg = (Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/organization" -OutputType PSObject).value
foreach ($domain in $script:TenantOrg.VerifiedDomains) {
    if ($domain.isDefault) {
        $script:TenantDomain = $domain.name
    }
}
$oobeSettings = $approfile.outOfBoxExperienceSettings

# Build up properties
$json = @{}
$json.Add("Comment_File", "Profile $($approfile.displayName)")
$json.Add("Version", 2049)
$json.Add("ZtdCorrelationId", $approfile.id)
if ($approfile."@odata.type" -eq "#microsoft.graph.activeDirectoryWindowsAutopilotDeploymentProfile") {
    $json.Add("CloudAssignedDomainJoinMethod", 1)
}
else {
    $json.Add("CloudAssignedDomainJoinMethod", 0)
}
if ($approfile.deviceNameTemplate) {
    $json.Add("CloudAssignedDeviceName", $approfile.deviceNameTemplate)
}

# Figure out config value
$oobeConfig = 8 + 256
if ($oobeSettings.userType -eq 'standard') {
    $oobeConfig += 2
}
if ($oobeSettings.hidePrivacySettings -eq $true) {
    $oobeConfig += 4
}
if ($oobeSettings.hideEULA -eq $true) {
    $oobeConfig += 16
}
if ($oobeSettings.skipKeyboardSelectionPage -eq $true) {
    $oobeConfig += 1024
    if ($_.language) {
        $json.Add("CloudAssignedLanguage", $_.language)
        # Use the same value for region so that screen is skipped too
        $json.Add("CloudAssignedRegion", $_.language)
    }
}
if ($oobeSettings.deviceUsageType -eq 'shared') {
    $oobeConfig += 32 + 64
}
$json.Add("CloudAssignedOobeConfig", $oobeConfig)

# Set the forced enrollment setting
if ($oobeSettings.hideEscapeLink -eq $true) {
    $json.Add("CloudAssignedForcedEnrollment", 1)
}
else {
    $json.Add("CloudAssignedForcedEnrollment", 0)
}

$json.Add("CloudAssignedTenantId", $script:TenantOrg.id)
$json.Add("CloudAssignedTenantDomain", $script:TenantDomain)
$embedded = @{}
$embedded.Add("CloudAssignedTenantDomain", $script:TenantDomain)
$embedded.Add("CloudAssignedTenantUpn", "")
if ($oobeSettings.hideEscapeLink -eq $true) {
    $embedded.Add("ForcedEnrollment", 1)
}
else {
    $embedded.Add("ForcedEnrollment", 0)
}
$ztc = @{}
$ztc.Add("ZeroTouchConfig", $embedded)
$json.Add("CloudAssignedAadServerData", (ConvertTo-JSON $ztc -Compress))

# Skip connectivity check
if ($approfile.hybridAzureADJoinSkipConnectivityCheck -eq $true) {
    $json.Add("HybridJoinSkipDCConnectivityCheck", 1)
}

# Hard-code properties not represented in Intune
$json.Add("CloudAssignedAutopilotUpdateDisabled", 1)
$json.Add("CloudAssignedAutopilotUpdateTimeout", 1800000)

# Return the JSON
ConvertTo-JSON $json
}

Function Connect-ToGraph {
    <#
.SYNOPSIS
Authenticates to the Graph API via the Microsoft.Graph.Authentication module.
 
.DESCRIPTION
The Connect-ToGraph cmdlet is a wrapper cmdlet that helps authenticate to the Intune Graph API using the Microsoft.Graph.Authentication module. It leverages an Azure AD app ID and app secret for authentication or user-based auth.
 
.PARAMETER Tenant
Specifies the tenant (e.g. contoso.onmicrosoft.com) to which to authenticate.
 
.PARAMETER AppId
Specifies the Azure AD app ID (GUID) for the application that will be used to authenticate.
 
.PARAMETER AppSecret
Specifies the Azure AD app secret corresponding to the app ID that will be used to authenticate.

.PARAMETER Scopes
Specifies the user scopes for interactive authentication.
 
.EXAMPLE
Connect-ToGraph -TenantId $tenantID -AppId $app -AppSecret $secret
 
-#>
    [cmdletbinding()]
    param
    (
        [Parameter(Mandatory = $false)] [string]$Tenant,
        [Parameter(Mandatory = $false)] [string]$AppId,
        [Parameter(Mandatory = $false)] [string]$AppSecret,
        [Parameter(Mandatory = $false)] [string]$scopes
    )

    Process {
        #Import-Module Microsoft.Graph.Authentication
        $version = (get-module microsoft.graph.authentication | Select-Object -expandproperty Version).major

        if ($AppId -ne "") {
            $body = @{
                grant_type    = "client_credentials";
                client_id     = $AppId;
                client_secret = $AppSecret;
                scope         = "https://graph.microsoft.com/.default";
            }
     
            $response = Invoke-RestMethod -Method Post -Uri https://login.microsoftonline.com/$Tenant/oauth2/v2.0/token -Body $body
            $accessToken = $response.access_token
     
            $accessToken
            if ($version -eq 2) {
                write-host "Graph versie 2 is gedetecteerd." -ForegroundColor Red
                $accesstokenfinal = ConvertTo-SecureString -String $accessToken -AsPlainText -Force
            }
            else {
                write-host "Graph versie 1 is gedetecteerd." -ForegroundColor Red
                Select-MgProfile -Name Beta
                $accesstokenfinal = $accessToken
            }
            $graph = Connect-MgGraph  -AccessToken $accesstokenfinal 
            Write-Host "Verbonden met Intune Tennant $TenantId using app-based authentication (Azure AD authentication not supported)" -ForegroundColor Green
        }
        else {
            if ($version -eq 2) {
                write-host "Version 2 module detected" -ForegroundColor Cyan
                ""
            }
            else {
                write-host "Version 1 Module Detected" -ForegroundColor Cyan
                ""
                Select-MgProfile -Name Beta
            }
            $graph = Connect-MgGraph -scopes $scopes
            Write-Host "Verbonden met Intune Tennant $($graph.TenantId)" -ForegroundColor Green
            ""
        }
    }
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
        Write-Error "Er zijn geen drives gevonden met de VolumeLabel '$volumeLabel'." -ErrorAction Stop
        return $null
    }
}

##ISO Selecteren Functie:
function Select-ISO {
    [CmdletBinding()]
    param ()

    Add-Type -AssemblyName System.Windows.Forms

    if (Test-Path $DefaultISOPath1) {
        $DefaultISOPath = $DefaultISOPath1
    } elseif (Test-Path $DefaultISOPath2) {
        $DefaultISOPath = $DefaultISOPath2
    } elseif (Test-Path $DefaultISOPath3) {
        $DefaultISOPath = $DefaultISOPath3
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

    if (Test-Path $DefaultProvisionPath1) {
        $DefaultProvisionPath = $DefaultProvisionPath1
    } elseif (Test-Path $DefaultProvisionPath2) {
        $DefaultProvisionPath = $DefaultProvisionPath2
    } elseif (Test-Path $DefaultProvisionPath3) {
        $DefaultProvisionPath = $DefaultProvisionPath3
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

    if (Test-Path $DefaultDriversPath1) {
        $DefaultDriversPath = $DefaultDriversPath1
    } elseif (Test-Path $DefaultDriversPath2) {
        $DefaultDriversPath = $DefaultDriversPath2
    } elseif (Test-Path $DefaultDriversPath3) {
        $DefaultDriversPath = $DefaultDriversPath3
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
######                                        Graph Connection                                           ######
###############################################################################################################
##Killing old sessions
try {
    # Attempt to remove the directory
    Remove-Item "$env:USERPROFILE\.mg" -Recurse -Force -ErrorAction Stop
    Write-Host "Het verwijderen van de oude cache is voltooid." -Foregroundcolor Green
    ""
    Start-sleep -Seconds 1.5
    Write-Host "Disconnect-MgGraph wordt nu uitgevoerd." -Foregroundcolor Green
    ""
    Start-Sleep -Seconds 1.5

} catch {
    # If directory doesn't exist or another error occurs, Disconnect-MgGraph will be executed
    if ($_ -match "cannot find path") {
        Write-Host "Er is geen actieve inlogsessie gevonden. Het script wordt voortgezet." -Foregroundcolor Green
        ""
    } else {
        Write-Host "An error occurred: $($_.Exception.Message)"
    }

    # Check if there is an active session before trying to disconnect
    $mgContext = Get-MgContext -ErrorAction SilentlyContinue
    if ($mgContext) {
        # Only disconnect if a valid session exists
        Disconnect-MgGraph | Out-Null
    }
}
Write-Host "Verbinding maken met MS Graph"  -ForegroundColor Green
""
Start-Sleep -Seconds 2

if ($clientid -and $clientsecret -and $tenant) {
    Connect-ToGraph -Tenant $tenant -AppId $clientid -AppSecret $clientsecret
    Write-Host $([system.text.encoding]::UTF8.GetString([system.convert]::FromBase64String($welcomeScreen)))    
    write-output "Graph Connection Established"
    }
    else {
    ##Connect to Graph
    Connect-ToGraph -scopes "Group.ReadWrite.All, Device.ReadWrite.All, DeviceManagementManagedDevices.ReadWrite.All, DeviceManagementServiceConfig.ReadWrite.All, GroupMember.ReadWrite.All, Domain.ReadWrite.All, Organization.Read.All"
    }
    Write-Host "Verbinding geslaagd, Profielen ophalen. Kies het juiste profiel" -ForegroundColor Green
    ""
    Start-Sleep -Seconds 3
###############################################################################################################
######                                              Execution JSON                                       ######
###############################################################################################################

##Grab all profiles and output to gridview
$selectedprofile = GrabProfiles

if (-not $selectedprofile) {
    Write-Error -Message "Er is geen profiel geselcteerd Hierdoor kan het script niet verder." -ErrorAction Stop
}
##Grab JSON for selected profile
$profilejson = grabandoutput -id $selectedprofile

##Save JSON to temp
$profilejson | Out-File -FilePath $path\AutopilotConfigurationFile.json

##Open folder containing json
#Invoke-Item $path

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

#Kijken of er een USB beschikbaar is
$usbDrives = Get-WmiObject Win32_LogicalDisk | Where-Object {
    $_.DriveType -eq 2 -and $_.VolumeName -ne $null
}

if ($usbDrives) {
    Write-Host "Er is een USB-opslagapparaat aangesloten:" -ForegroundColor Green
    $usbDrives | ForEach-Object {
        Write-Host "Drive: $($_.DeviceID) - Label: $($_.VolumeName)"
    }
} else {
    Write-Error "Er is geen USB-opslagapparaat aangesloten." -ErrorAction Stop
}

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

##kopieren van driver files naar de juiste folder
Get-Item -Path $DriverFolder
Copy-Item -Path $DriverFolder -Destination $USBImages\ -Recurse -Force

Remove-Item $env:TEMP\CreateUSBScript.ps1
""
""
""
Write-Host "USB Is Succesvol gemaakt, Druk op een toets om dit venster af te sluiten." -ForegroundColor Green
$Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
exit 0  # 0 = success, non-zero = error
""
""
""
