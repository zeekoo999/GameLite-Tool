<#
    GameLite - Windows debloater for gaming PCs
    Version 1.0

    Removes unwanted preinstalled apps, disables unneeded background services
    and applies gaming/privacy tweaks, all from a simple GUI.

    Run with Run-GameLite.bat (it asks for administrator rights).
    Works on Windows 10 (1809+) and Windows 11.

    Safety:
      - Creates a System Restore point before changing anything (on by default).
      - Saves the original startup type of every service it touches, so
        "Undo services" puts them back exactly as they were.
      - Every tweak has a matching revert.
      - Core components (Store, App Installer, runtimes, Photos, Calculator,
        Notepad, Terminal, codecs, Security) are hard-protected and never removed.
#>

# ------------------------------------------------------------------ elevation
$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process -FilePath 'powershell.exe' -ArgumentList "-NoProfile -ExecutionPolicy Bypass -STA -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

$ErrorActionPreference = 'Continue'
$AppName   = 'GameLite'
$DataDir   = Join-Path $env:ProgramData 'GameLite'
$SvcBackup = Join-Path $DataDir 'services-backup.json'
$PlanFile  = Join-Path $DataDir 'ultimate-plan-guid.txt'
$LogFile   = Join-Path $DataDir ('log-{0:yyyyMMdd-HHmmss}.txt' -f (Get-Date))
New-Item -ItemType Directory -Path $DataDir -Force | Out-Null

# ------------------------------------------------------------------ protected packages (never removed)
$ProtectedPackages = @(
    'Microsoft.WindowsStore', 'Microsoft.StorePurchaseApp', 'Microsoft.DesktopAppInstaller',
    'Microsoft.VCLibs*', 'Microsoft.NET*', 'Microsoft.UI.Xaml*', 'Microsoft.WindowsAppRuntime*',
    'Microsoft.Windows.ShellExperienceHost', 'Microsoft.Windows.StartMenuExperienceHost',
    'Microsoft.SecHealthUI', 'Microsoft.WindowsTerminal', 'Microsoft.WindowsNotepad',
    'Microsoft.Windows.Photos', 'Microsoft.WindowsCalculator', 'Microsoft.Paint',
    'Microsoft.ScreenSketch', 'Microsoft.HEIFImageExtension', 'Microsoft.HEVCVideoExtension',
    'Microsoft.VP9VideoExtensions', 'Microsoft.WebMediaExtensions', 'Microsoft.WebpImageExtension',
    'Microsoft.AV1VideoExtension', 'Microsoft.RawImageExtension', 'Microsoft.MPEG2VideoExtension'
)

function Test-Protected([string]$Name) {
    foreach ($p in $ProtectedPackages) { if ($Name -like $p) { return $true } }
    return $false
}

# ------------------------------------------------------------------ catalog: apps
# Level: Recommended (pre-ticked) | Optional (your call) | Caution (can break something you may use)
function New-App($Id, $Label, $Desc, $Level) {
    [pscustomobject]@{ Id = $Id; Label = $Label; Desc = $Desc; Level = $Level }
}

$Apps = @(
    New-App 'Microsoft.BingNews'                     'Microsoft News'            'News feed app. Runs background updates.' 'Recommended'
    New-App 'Microsoft.BingFinance'                  'MSN Money'                 'Legacy finance app.' 'Recommended'
    New-App 'Microsoft.BingSports'                   'MSN Sports'                'Legacy sports app.' 'Recommended'
    New-App 'Microsoft.BingSearch'                   'Bing Search'               'Bing search companion app.' 'Recommended'
    New-App 'Microsoft.BingWeather'                  'Weather'                   'Weather app and live tile.' 'Optional'
    New-App 'Microsoft.Getstarted'                   'Tips'                      'Windows tips and "get started" prompts.' 'Recommended'
    New-App 'Microsoft.GetHelp'                      'Get Help'                  'Support app. Some Windows 11 troubleshooters open through it.' 'Optional'
    New-App 'Microsoft.MicrosoftSolitaireCollection' 'Solitaire Collection'      'Ad-supported card games.' 'Recommended'
    New-App 'Microsoft.MicrosoftOfficeHub'           'Microsoft 365 hub'         'Office launcher / upsell app (does not remove Office itself).' 'Recommended'
    New-App 'Microsoft.People'                       'People'                    'Contacts app.' 'Recommended'
    New-App 'Microsoft.WindowsFeedbackHub'           'Feedback Hub'              'Sends feedback to Microsoft.' 'Recommended'
    New-App 'Microsoft.WindowsMaps'                  'Maps'                      'Offline maps app.' 'Recommended'
    New-App 'Microsoft.ZuneVideo'                    'Movies & TV'               'Legacy video player/store.' 'Recommended'
    New-App 'Microsoft.ZuneMusic'                    'Media Player (Groove)'     'Default music/video player. Remove only if you use VLC/foobar etc.' 'Optional'
    New-App 'Microsoft.YourPhone'                    'Phone Link'                'Phone integration. Runs in the background.' 'Optional'
    New-App 'Microsoft.SkypeApp'                     'Skype'                     'Skype was retired by Microsoft in 2025.' 'Recommended'
    New-App 'Microsoft.Todos'                        'Microsoft To Do'           'Task list app.' 'Optional'
    New-App 'Microsoft.PowerAutomateDesktop'         'Power Automate'            'Business automation tool.' 'Recommended'
    New-App 'Clipchamp.Clipchamp'                    'Clipchamp'                 'Web-based video editor.' 'Recommended'
    New-App 'Microsoft.549981C3F5F10'                'Cortana'                   'Discontinued voice assistant.' 'Recommended'
    New-App 'Microsoft.MixedReality.Portal'          'Mixed Reality Portal'      'Windows Mixed Reality headset app.' 'Recommended'
    New-App 'Microsoft.Microsoft3DViewer'            '3D Viewer'                 '3D model viewer.' 'Recommended'
    New-App 'Microsoft.MSPaint'                      'Paint 3D'                  'Paint 3D (classic Paint is protected and kept).' 'Recommended'
    New-App 'Microsoft.Office.OneNote'               'OneNote (Store app)'       'Store version of OneNote.' 'Optional'
    New-App 'MicrosoftTeams'                         'Teams (personal, old)'     'Consumer Teams chat app.' 'Recommended'
    New-App 'MSTeams'                                'Teams (personal, new)'     'Consumer Teams. Starts with Windows.' 'Recommended'
    New-App 'Microsoft.OutlookForWindows'            'New Outlook'               'New Outlook mail app.' 'Optional'
    New-App 'Microsoft.Windows.DevHome'              'Dev Home'                  'Developer dashboard (retired).' 'Recommended'
    New-App 'Microsoft.Copilot'                      'Copilot app'               'Copilot AI app.' 'Recommended'
    New-App 'MicrosoftCorporationII.MicrosoftFamily' 'Microsoft Family'          'Family Safety app.' 'Recommended'
    New-App 'Microsoft.Wallet'                       'Wallet'                    'Payments app.' 'Recommended'
    New-App 'Microsoft.WindowsAlarms'                'Clock / Alarms'            'Alarms, timers and focus sessions.' 'Optional'
    New-App 'Microsoft.WindowsSoundRecorder'         'Sound Recorder'            'Voice recorder.' 'Optional'
    New-App 'Microsoft.MicrosoftStickyNotes'         'Sticky Notes'              'Desktop notes.' 'Optional'
    New-App 'MicrosoftCorporationII.QuickAssist'     'Quick Assist'              'Remote help tool.' 'Optional'
    New-App '*king.com*'                             'Candy Crush & King games'  'Preinstalled promo games.' 'Recommended'
    New-App '*Disney*'                               'Disney+'                   'Preinstalled promo app.' 'Recommended'
    New-App '*TikTok*'                               'TikTok'                    'Preinstalled promo app.' 'Recommended'
    New-App '*Instagram*'                            'Instagram'                 'Preinstalled promo app.' 'Recommended'
    New-App '*Facebook*'                             'Facebook'                  'Preinstalled promo app.' 'Recommended'
    New-App '*Twitter*'                              'X / Twitter'               'Preinstalled promo app.' 'Recommended'
    New-App '*LinkedIn*'                             'LinkedIn'                  'Preinstalled promo app.' 'Recommended'
    New-App '*PrimeVideo*'                           'Prime Video'               'Preinstalled promo app.' 'Optional'
    New-App '*SpotifyMusic*'                         'Spotify (Store)'           'Only if you do not use Spotify.' 'Optional'
    New-App 'Microsoft.XboxApp'                      'Xbox Console Companion'    'Old console companion app.' 'Recommended'
    New-App 'Microsoft.XboxGameOverlay'              'Xbox Game Overlay (old)'   'Legacy overlay component.' 'Optional'
    New-App 'Microsoft.XboxSpeechToTextOverlay'      'Xbox Speech-to-Text'       'Party chat transcription overlay.' 'Optional'
    New-App 'Microsoft.GamingApp'                    'Xbox app'                  'REQUIRED for PC Game Pass and Microsoft Store games.' 'Caution'
    New-App 'Microsoft.XboxGamingOverlay'            'Xbox Game Bar'             'Win+G overlay: FPS counter, capture, Xbox party chat.' 'Caution'
    New-App 'Microsoft.XboxIdentityProvider'         'Xbox Identity Provider'    'Xbox sign-in for many PC games (Minecraft, Forza, Halo...).' 'Caution'
    New-App 'Microsoft.Xbox.TCUI'                    'Xbox TCUI'                 'Xbox friends/profile UI used inside games.' 'Caution'
)

# ------------------------------------------------------------------ catalog: services
function New-Svc($Name, $Label, $Desc, $Target, $Level) {
    [pscustomobject]@{ Name = $Name; Label = $Label; Desc = $Desc; Target = $Target; Level = $Level }
}

$Services = @(
    New-Svc 'DiagTrack'        'Connected User Experiences and Telemetry' 'Main telemetry service. Constant background disk/network use.' 'Disabled' 'Recommended'
    New-Svc 'dmwappushservice' 'Device Management WAP Push'               'Telemetry message routing.' 'Disabled' 'Recommended'
    New-Svc 'WerSvc'           'Windows Error Reporting'                  'Uploads crash reports to Microsoft.' 'Disabled' 'Recommended'
    New-Svc 'MapsBroker'       'Downloaded Maps Manager'                  'Background map updates.' 'Disabled' 'Recommended'
    New-Svc 'RetailDemo'       'Retail Demo'                              'Store display demo mode.' 'Disabled' 'Recommended'
    New-Svc 'Fax'              'Fax'                                      'Fax support.' 'Disabled' 'Recommended'
    New-Svc 'WMPNetworkSvc'    'Windows Media Player Network Sharing'     'Media library sharing.' 'Disabled' 'Recommended'
    New-Svc 'RemoteRegistry'   'Remote Registry'                          'Lets remote users edit the registry. Security risk.' 'Disabled' 'Recommended'
    New-Svc 'WpcMonSvc'        'Parental Controls'                        'Family Safety enforcement.' 'Disabled' 'Recommended'
    New-Svc 'wisvc'            'Windows Insider Service'                  'Only needed for Insider builds.' 'Disabled' 'Recommended'
    New-Svc 'lfsvc'            'Geolocation'                              'Location for apps. Set to Manual (starts only when asked).' 'Manual' 'Optional'
    New-Svc 'PhoneSvc'         'Phone Service'                            'Telephony state. Set to Manual.' 'Manual' 'Optional'
    New-Svc 'SEMgrSvc'         'Payments and NFC/SE Manager'              'NFC payments. Set to Manual.' 'Manual' 'Optional'
    New-Svc 'PcaSvc'           'Program Compatibility Assistant'          'Pop-ups about old programs. Set to Manual.' 'Manual' 'Optional'
    New-Svc 'edgeupdate'       'Microsoft Edge Update'                    'Edge updater. Set to Manual (Edge still updates when opened).' 'Manual' 'Optional'
    New-Svc 'edgeupdatem'      'Microsoft Edge Update (m)'                'Edge updater, second task. Set to Manual.' 'Manual' 'Optional'
    New-Svc 'SysMain'          'SysMain (Superfetch)'                     'Preloads apps into RAM. Can cause disk spikes; helpful on HDDs.' 'Manual' 'Optional'
    New-Svc 'Spooler'          'Print Spooler'                            'Printing. Set to Manual only if you never print.' 'Manual' 'Optional'
    New-Svc 'WSearch'          'Windows Search (indexing)'                'File indexing. Start-menu file search gets slower without it.' 'Manual' 'Caution'
    New-Svc 'XblAuthManager'   'Xbox Live Auth Manager'                   'Needed for Game Pass / Xbox sign-in in games.' 'Manual' 'Caution'
    New-Svc 'XblGameSave'      'Xbox Live Game Save'                      'Cloud saves for Xbox/Game Pass games.' 'Manual' 'Caution'
    New-Svc 'XboxNetApiSvc'    'Xbox Live Networking'                     'Xbox multiplayer networking.' 'Manual' 'Caution'
    New-Svc 'XboxGipSvc'       'Xbox Accessory Management'                'Xbox controller firmware/accessories. Keep if you use an Xbox pad.' 'Manual' 'Caution'
)

# ------------------------------------------------------------------ registry helpers
function Set-Reg {
    param([string]$Path, [string]$Name, $Value, [string]$Type = 'DWord')
    if (-not (Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null }
    New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType $Type -Force | Out-Null
}
function Remove-Reg {
    param([string]$Path, [string]$Name)
    if (Test-Path $Path) { Remove-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue }
}

$CDM = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'
$CDMValues = @(
    'ContentDeliveryAllowed', 'OemPreInstalledAppsEnabled', 'PreInstalledAppsEnabled',
    'PreInstalledAppsEverEnabled', 'SilentInstalledAppsEnabled', 'SubscribedContentEnabled',
    'SystemPaneSuggestionsEnabled', 'SoftLandingEnabled', 'SubscribedContent-310093Enabled',
    'SubscribedContent-338387Enabled', 'SubscribedContent-338388Enabled',
    'SubscribedContent-338389Enabled', 'SubscribedContent-353694Enabled',
    'SubscribedContent-353696Enabled'
)

# ------------------------------------------------------------------ catalog: tweaks
function New-Tweak($Label, $Desc, $Level, [scriptblock]$Apply, [scriptblock]$Revert) {
    [pscustomobject]@{ Label = $Label; Desc = $Desc; Level = $Level; Apply = $Apply; Revert = $Revert }
}

$Tweaks = @(
    New-Tweak 'Turn off telemetry' 'Sets diagnostic data to the minimum allowed by your edition.' 'Recommended' {
        Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' 'AllowTelemetry' 0
        Set-Reg 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection' 'AllowTelemetry' 0
    } {
        Remove-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' 'AllowTelemetry'
        Remove-Reg 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection' 'AllowTelemetry'
    }

    New-Tweak 'Turn off advertising ID' 'Stops apps from using your ad ID for personalised ads.' 'Recommended' {
        Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo' 'Enabled' 0
    } {
        Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo' 'Enabled' 1
    }

    New-Tweak 'Block suggested & auto-installed apps' 'Stops Start-menu ads, tips, and Windows silently reinstalling promo apps (Candy Crush etc.).' 'Recommended' {
        foreach ($v in $CDMValues) { Set-Reg $CDM $v 0 }
        Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent' 'DisableWindowsConsumerFeatures' 1
    } {
        foreach ($v in $CDMValues) { Set-Reg $CDM $v 1 }
        Remove-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent' 'DisableWindowsConsumerFeatures'
    }

    New-Tweak 'Remove Bing web results from Start search' 'Start-menu search only searches your PC. Faster and quieter.' 'Recommended' {
        Set-Reg 'HKCU:\Software\Policies\Microsoft\Windows\Explorer' 'DisableSearchBoxSuggestions' 1
    } {
        Remove-Reg 'HKCU:\Software\Policies\Microsoft\Windows\Explorer' 'DisableSearchBoxSuggestions'
    }

    New-Tweak 'Turn off Copilot and Recall' 'Disables the Copilot sidebar and Recall screenshot snapshots.' 'Recommended' {
        Set-Reg 'HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot' 'TurnOffWindowsCopilot' 1
        Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot' 'TurnOffWindowsCopilot' 1
        Set-Reg 'HKCU:\Software\Policies\Microsoft\Windows\WindowsAI' 'DisableAIDataAnalysis' 1
        Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI' 'DisableAIDataAnalysis' 1
    } {
        Remove-Reg 'HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot' 'TurnOffWindowsCopilot'
        Remove-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot' 'TurnOffWindowsCopilot'
        Remove-Reg 'HKCU:\Software\Policies\Microsoft\Windows\WindowsAI' 'DisableAIDataAnalysis'
        Remove-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI' 'DisableAIDataAnalysis'
    }

    New-Tweak 'Turn off Widgets / News feed' 'Removes the taskbar widgets board and its background web processes.' 'Recommended' {
        Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Dsh' 'AllowNewsAndInterests' 0
        Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds' 'EnableFeeds' 0
    } {
        Remove-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Dsh' 'AllowNewsAndInterests'
        Remove-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds' 'EnableFeeds'
    }

    New-Tweak 'Turn off Game DVR background recording' 'Stops Windows constantly recording gameplay in the background. Game Bar itself still works.' 'Recommended' {
        Set-Reg 'HKCU:\System\GameConfigStore' 'GameDVR_Enabled' 0
        Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR' 'AppCaptureEnabled' 0
    } {
        Set-Reg 'HKCU:\System\GameConfigStore' 'GameDVR_Enabled' 1
        Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR' 'AppCaptureEnabled' 1
    }

    New-Tweak 'Turn on Game Mode' 'Lets Windows prioritise the game and pause Windows Update installs while playing.' 'Recommended' {
        Set-Reg 'HKCU:\Software\Microsoft\GameBar' 'AutoGameModeEnabled' 1
        Set-Reg 'HKCU:\Software\Microsoft\GameBar' 'AllowAutoGameMode' 1
    } {
        Remove-Reg 'HKCU:\Software\Microsoft\GameBar' 'AutoGameModeEnabled'
        Remove-Reg 'HKCU:\Software\Microsoft\GameBar' 'AllowAutoGameMode'
    }

    New-Tweak 'Block Store apps running in background' 'Store apps stop running when closed. Their notifications may stop. Desktop apps (Discord, Steam) are unaffected.' 'Optional' {
        Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications' 'GlobalUserDisabled' 1
    } {
        Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications' 'GlobalUserDisabled' 0
    }

    New-Tweak 'Turn off mouse acceleration' 'Disables "Enhance pointer precision" for 1:1 aim. Applies after sign-out.' 'Optional' {
        Set-Reg 'HKCU:\Control Panel\Mouse' 'MouseSpeed' '0' 'String'
        Set-Reg 'HKCU:\Control Panel\Mouse' 'MouseThreshold1' '0' 'String'
        Set-Reg 'HKCU:\Control Panel\Mouse' 'MouseThreshold2' '0' 'String'
    } {
        Set-Reg 'HKCU:\Control Panel\Mouse' 'MouseSpeed' '1' 'String'
        Set-Reg 'HKCU:\Control Panel\Mouse' 'MouseThreshold1' '6' 'String'
        Set-Reg 'HKCU:\Control Panel\Mouse' 'MouseThreshold2' '10' 'String'
    }

    New-Tweak 'Hardware-accelerated GPU scheduling' 'Can lower latency on modern GPUs (GTX 10-series / RX 5000 and newer). Needs a restart.' 'Optional' {
        Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers' 'HwSchMode' 2
    } {
        Remove-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers' 'HwSchMode'
    }

    New-Tweak 'Ultimate Performance power plan' 'Keeps the CPU at full clocks. Uses more power - not for laptops on battery.' 'Optional' {
        $guid = $null
        if (Test-Path $PlanFile) {
            $saved = (Get-Content $PlanFile -Raw).Trim()
            if ((powercfg -list) -match [regex]::Escape($saved)) { $guid = $saved }
        }
        if (-not $guid) {
            $out = (powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61) -join ' '
            if ($out -match '([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12})') {
                $guid = $Matches[1]
                Set-Content -Path $PlanFile -Value $guid
            }
        }
        if ($guid) { powercfg -setactive $guid | Out-Null } else { throw 'Could not create the Ultimate Performance plan.' }
    } {
        powercfg -setactive 381b4222-f694-41f0-9685-ff5bb260df2e | Out-Null   # Balanced
        if (Test-Path $PlanFile) {
            powercfg -delete ((Get-Content $PlanFile -Raw).Trim()) 2>$null | Out-Null
            Remove-Item $PlanFile -Force
        }
    }

    New-Tweak 'Visual effects: best performance' 'Turns off animations, shadows and fades. Snappier, plainer look. Applies after sign-out.' 'Optional' {
        Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects' 'VisualFXSetting' 2
        Set-Reg 'HKCU:\Control Panel\Desktop' 'UserPreferencesMask' ([byte[]](0x90,0x12,0x03,0x80,0x10,0x00,0x00,0x00)) 'Binary'
    } {
        Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects' 'VisualFXSetting' 0
        Set-Reg 'HKCU:\Control Panel\Desktop' 'UserPreferencesMask' ([byte[]](0x9E,0x1E,0x07,0x80,0x12,0x00,0x00,0x00)) 'Binary'
    }

    New-Tweak 'Uninstall OneDrive' 'Removes OneDrive sync. Your cloud files stay online; local synced files stay on disk. Revert = reinstall from microsoft.com.' 'Caution' {
        Stop-Process -Name OneDrive -Force -ErrorAction SilentlyContinue
        $done = $false
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            winget uninstall --id Microsoft.OneDrive --silent --accept-source-agreements | Out-Null
            if ($LASTEXITCODE -eq 0) { $done = $true }
        }
        if (-not $done) {
            foreach ($p in "$env:SystemRoot\System32\OneDriveSetup.exe", "$env:SystemRoot\SysWOW64\OneDriveSetup.exe") {
                if (Test-Path $p) { Start-Process $p -ArgumentList '/uninstall' -Wait; $done = $true; break }
            }
        }
        if (-not $done) { throw 'OneDrive uninstaller not found (it may already be removed).' }
    } {
        Write-Log 'OneDrive cannot be auto-restored. Download it from https://www.microsoft.com/microsoft-365/onedrive/download' 'WARN'
    }
)

# ------------------------------------------------------------------ logging / UI helpers
$script:Window = $null
$script:LogBox = $null

function Update-UI {
    if ($script:Window) {
        $script:Window.Dispatcher.Invoke([action]{}, [System.Windows.Threading.DispatcherPriority]::Background)
    }
}

function Write-Log([string]$Message, [string]$Level = 'INFO') {
    $prefix = if ($Level -eq 'INFO') { '' } else { "[$Level] " }
    $line = '[{0:HH:mm:ss}] {1}{2}' -f (Get-Date), $prefix, $Message
    Add-Content -Path $LogFile -Value $line
    if ($script:LogBox) {
        $script:LogBox.AppendText($line + "`r`n")
        $script:LogBox.ScrollToEnd()
        Update-UI
    } else {
        Write-Host $line
    }
}

$BrushConv = New-Object System.Windows.Media.BrushConverter
function Get-Brush([string]$Hex) { $BrushConv.ConvertFromString($Hex) }

function Get-LevelColor([string]$Level) {
    switch ($Level) {
        'Recommended' { '#4ADE80' }
        'Optional'    { '#60A5FA' }
        'Caution'     { '#F59E0B' }
        default       { '#9AA3AF' }
    }
}

# ------------------------------------------------------------------ service helpers
function Get-SvcStart([string]$Name) {
    $p = Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\$Name" -ErrorAction SilentlyContinue
    if (-not $p -or $null -eq $p.Start) { return $null }
    switch ([int]$p.Start) {
        2       { if ([int]$p.DelayedAutostart -eq 1) { 'delayed-auto' } else { 'auto' } }
        3       { 'demand' }
        4       { 'disabled' }
        default { 'other' }
    }
}

function Format-Start([string]$Mode) {
    if ([string]::IsNullOrEmpty($Mode)) { return 'Not present' }
    switch ($Mode) {
        'auto'         { 'Automatic' }
        'delayed-auto' { 'Automatic (delayed)' }
        'demand'       { 'Manual' }
        'disabled'     { 'Disabled' }
        default        { 'System' }
    }
}

function Get-SvcBackup {
    $h = @{}
    if (Test-Path $SvcBackup) {
        $obj = Get-Content $SvcBackup -Raw | ConvertFrom-Json
        foreach ($prop in $obj.psobject.Properties) { $h[$prop.Name] = $prop.Value }
    }
    return $h
}

function Save-SvcBackup($Table) {
    $Table | ConvertTo-Json | Set-Content -Path $SvcBackup -Encoding UTF8
}

function Set-ServiceMode($Svc) {
    $current = Get-SvcStart $Svc.Name
    if ($null -eq $current) { Write-Log "Service $($Svc.Name) not found, skipped."; return $false }
    if ($current -eq 'other') { Write-Log "Service $($Svc.Name) is a system/boot service, skipped." 'WARN'; return $false }

    $backup = Get-SvcBackup
    if (-not $backup.ContainsKey($Svc.Name)) {   # keep the very first original value
        $backup[$Svc.Name] = $current
        Save-SvcBackup $backup
    }

    $mode = if ($Svc.Target -eq 'Disabled') { 'disabled' } else { 'demand' }
    if ($mode -eq 'disabled') { Stop-Service -Name $Svc.Name -Force -ErrorAction SilentlyContinue }
    $null = sc.exe config $Svc.Name start= $mode
    if ($LASTEXITCODE -eq 0) {
        Write-Log "Service $($Svc.Label): $(Format-Start $current) -> $(Format-Start $mode)"
        return $true
    }
    Write-Log "Could not change $($Svc.Name) (Windows protects some services)." 'WARN'
    return $false
}

# ------------------------------------------------------------------ app helpers
function Remove-App($App) {
    $any = $false
    $pkgs = @(Get-AppxPackage -AllUsers -Name $App.Id -ErrorAction SilentlyContinue |
              Where-Object { -not (Test-Protected $_.Name) })
    foreach ($p in $pkgs) {
        try {
            Remove-AppxPackage -Package $p.PackageFullName -AllUsers -ErrorAction Stop
            Write-Log "Removed $($p.Name)"; $any = $true
        } catch {
            try {
                Remove-AppxPackage -Package $p.PackageFullName -ErrorAction Stop
                Write-Log "Removed $($p.Name) (current user)"; $any = $true
            } catch {
                Write-Log "Could not remove $($p.Name): $($_.Exception.Message)" 'WARN'
            }
        }
    }
    $prov = @($script:Provisioned | Where-Object { $_.DisplayName -like $App.Id -and -not (Test-Protected $_.DisplayName) })
    foreach ($pp in $prov) {
        try {
            Remove-AppxProvisionedPackage -Online -PackageName $pp.PackageName -ErrorAction Stop | Out-Null
            Write-Log "Deprovisioned $($pp.DisplayName) (will not return for new users)"; $any = $true
        } catch {
            Write-Log "Could not deprovision $($pp.DisplayName): $($_.Exception.Message)" 'WARN'
        }
    }
    return $any
}

function New-RestorePoint {
    try {
        Enable-ComputerRestore -Drive "$env:SystemDrive\" -ErrorAction Stop
        # Windows normally allows only one restore point per 24h; lift that for this run
        Set-Reg 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore' 'SystemRestorePointCreationFrequency' 0
        Write-Log 'Creating restore point (this can take a minute)...'
        Checkpoint-Computer -Description 'GameLite - before changes' -RestorePointType MODIFY_SETTINGS -ErrorAction Stop
        Write-Log 'Restore point created.'
        return $true
    } catch {
        Write-Log "Restore point failed: $($_.Exception.Message)" 'WARN'
        return $false
    }
}

# ------------------------------------------------------------------ scan system
Write-Host 'GameLite: scanning installed apps and services, please wait...'
$script:Installed   = @(Get-AppxPackage -AllUsers -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name)
$script:Provisioned = @(Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue)
$provNames = @($script:Provisioned | Select-Object -ExpandProperty DisplayName)

function Test-AppPresent($App) {
    $hits = @($script:Installed + $provNames | Where-Object { $_ -like $App.Id -and -not (Test-Protected $_) })
    return ($hits.Count -gt 0)
}

$os = Get-CimInstance Win32_OperatingSystem

# ------------------------------------------------------------------ GUI
[xml]$Xaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="GameLite - Gaming PC Debloater" Width="1000" Height="780" MinWidth="840" MinHeight="600"
        WindowStartupLocation="CenterScreen" Background="#0F1115" Foreground="#E6E8EB"
        FontFamily="Segoe UI" FontSize="13">
  <Window.Resources>
    <Style TargetType="Button">
      <Setter Property="Background" Value="#22262E"/>
      <Setter Property="Foreground" Value="#E6E8EB"/>
      <Setter Property="BorderBrush" Value="#343A45"/>
      <Setter Property="Padding" Value="14,7"/>
      <Setter Property="Margin" Value="8,0,0,0"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border x:Name="Bd" Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}"
                    BorderThickness="1" CornerRadius="6" Padding="{TemplateBinding Padding}">
              <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True">
                <Setter TargetName="Bd" Property="BorderBrush" Value="#4ADE80"/>
              </Trigger>
              <Trigger Property="IsEnabled" Value="False">
                <Setter TargetName="Bd" Property="Opacity" Value="0.4"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
    <Style TargetType="TabItem">
      <Setter Property="Foreground" Value="#E6E8EB"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="TabItem">
            <Border x:Name="Tb" Padding="18,9" Margin="0,0,4,0" CornerRadius="6,6,0,0" Background="#181B21">
              <ContentPresenter ContentSource="Header"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsSelected" Value="True">
                <Setter TargetName="Tb" Property="Background" Value="#22262E"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
    <Style TargetType="CheckBox">
      <Setter Property="Foreground" Value="#E6E8EB"/>
    </Style>
  </Window.Resources>

  <Grid Margin="18">
    <Grid.RowDefinitions>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="*"/>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="150"/>
    </Grid.RowDefinitions>

    <DockPanel Grid.Row="0" Margin="0,0,0,14">
      <StackPanel DockPanel.Dock="Left">
        <TextBlock Text="GameLite" FontSize="28" FontWeight="Bold" Foreground="#4ADE80"/>
        <TextBlock x:Name="SubTitle" Foreground="#9AA3AF"/>
      </StackPanel>
      <StackPanel Orientation="Horizontal" HorizontalAlignment="Right" VerticalAlignment="Bottom">
        <TextBlock Text="Recommended" Foreground="#4ADE80" Margin="0,0,14,0"/>
        <TextBlock Text="Optional" Foreground="#60A5FA" Margin="0,0,14,0"/>
        <TextBlock Text="Caution" Foreground="#F59E0B"/>
      </StackPanel>
    </DockPanel>

    <TabControl Grid.Row="1" Background="#22262E" BorderThickness="0" Padding="0">
      <TabItem x:Name="TabApps" Header="Apps">
        <ScrollViewer VerticalScrollBarVisibility="Auto"><StackPanel x:Name="AppsPanel" Margin="12"/></ScrollViewer>
      </TabItem>
      <TabItem x:Name="TabSvcs" Header="Services">
        <ScrollViewer VerticalScrollBarVisibility="Auto"><StackPanel x:Name="SvcsPanel" Margin="12"/></ScrollViewer>
      </TabItem>
      <TabItem x:Name="TabTweaks" Header="Tweaks">
        <ScrollViewer VerticalScrollBarVisibility="Auto"><StackPanel x:Name="TweaksPanel" Margin="12"/></ScrollViewer>
      </TabItem>
    </TabControl>

    <DockPanel Grid.Row="2" Margin="0,14,0,12">
      <CheckBox x:Name="ChkRestore" DockPanel.Dock="Left" IsChecked="True" VerticalAlignment="Center"
                Content="Create a restore point first"/>
      <StackPanel Orientation="Horizontal" HorizontalAlignment="Right">
        <Button x:Name="BtnRecommended" Content="Select recommended"/>
        <Button x:Name="BtnNone" Content="Select none"/>
        <Button x:Name="BtnUndoSvcs" Content="Undo services"/>
        <Button x:Name="BtnRevert" Content="Revert selected tweaks"/>
        <Button x:Name="BtnApply" Content="Apply selected" FontWeight="SemiBold"
                Background="#14532D" BorderBrush="#22C55E"/>
      </StackPanel>
    </DockPanel>

    <TextBox x:Name="LogBox" Grid.Row="3" IsReadOnly="True" Background="#0A0C10" Foreground="#9AE6B4"
             FontFamily="Consolas" FontSize="12" BorderBrush="#343A45" Padding="8"
             VerticalScrollBarVisibility="Auto" TextWrapping="Wrap"/>
  </Grid>
</Window>
'@

$reader = New-Object System.Xml.XmlNodeReader $Xaml
$script:Window = [Windows.Markup.XamlReader]::Load($reader)
$W = $script:Window

$AppsPanel   = $W.FindName('AppsPanel')
$SvcsPanel   = $W.FindName('SvcsPanel')
$TweaksPanel = $W.FindName('TweaksPanel')
$ChkRestore  = $W.FindName('ChkRestore')
$script:LogBox = $W.FindName('LogBox')
$Buttons = @('BtnRecommended', 'BtnNone', 'BtnUndoSvcs', 'BtnRevert', 'BtnApply') | ForEach-Object { $W.FindName($_) }
$W.FindName('SubTitle').Text = "$($os.Caption) (build $($os.BuildNumber))  -  logs and backups: $DataDir"

$script:AppChecks   = New-Object System.Collections.Generic.List[object]
$script:SvcChecks   = New-Object System.Collections.Generic.List[object]
$script:TweakChecks = New-Object System.Collections.Generic.List[object]

function Add-Section($Panel, [string]$Text) {
    $tb = New-Object System.Windows.Controls.TextBlock
    $tb.Text = $Text
    $tb.Foreground = Get-Brush '#9AA3AF'
    $tb.FontSize = 12
    $tb.TextWrapping = 'Wrap'
    $tb.Margin = New-Object System.Windows.Thickness(2, 0, 2, 10)
    [void]$Panel.Children.Add($tb)
}

function Add-Row($Panel, $Item, [string]$Title, [string]$Desc, [string]$Status, [bool]$Enabled, $List) {
    $border = New-Object System.Windows.Controls.Border
    $border.Background   = Get-Brush '#181B21'
    $border.CornerRadius = New-Object System.Windows.CornerRadius(6)
    $border.Padding      = New-Object System.Windows.Thickness(12, 8, 12, 8)
    $border.Margin       = New-Object System.Windows.Thickness(0, 0, 0, 6)

    $grid = New-Object System.Windows.Controls.Grid
    $c1 = New-Object System.Windows.Controls.ColumnDefinition
    $c1.Width = New-Object System.Windows.GridLength(1, [System.Windows.GridUnitType]::Star)
    $c2 = New-Object System.Windows.Controls.ColumnDefinition
    $c2.Width = [System.Windows.GridLength]::Auto
    $grid.ColumnDefinitions.Add($c1)
    $grid.ColumnDefinitions.Add($c2)

    $left = New-Object System.Windows.Controls.StackPanel
    $cb = New-Object System.Windows.Controls.CheckBox
    $cb.Content    = $Title
    $cb.FontWeight = [System.Windows.FontWeights]::SemiBold
    $cb.IsEnabled  = $Enabled
    $cb.IsChecked  = ($Enabled -and $Item.Level -eq 'Recommended')

    $descText = New-Object System.Windows.Controls.TextBlock
    $descText.Text = $Desc
    $descText.Foreground = Get-Brush '#9AA3AF'
    $descText.FontSize = 12
    $descText.TextWrapping = 'Wrap'
    $descText.Margin = New-Object System.Windows.Thickness(22, 2, 12, 0)
    [void]$left.Children.Add($cb)
    [void]$left.Children.Add($descText)

    $right = New-Object System.Windows.Controls.StackPanel
    $right.HorizontalAlignment = 'Right'
    $right.VerticalAlignment = 'Center'
    $lvl = New-Object System.Windows.Controls.TextBlock
    $lvl.Text = $Item.Level
    $lvl.Foreground = Get-Brush (Get-LevelColor $Item.Level)
    $lvl.FontSize = 11
    $lvl.FontWeight = [System.Windows.FontWeights]::SemiBold
    $lvl.HorizontalAlignment = 'Right'
    $st = New-Object System.Windows.Controls.TextBlock
    $st.Text = $Status
    $st.Foreground = Get-Brush '#6B7280'
    $st.FontSize = 11
    $st.HorizontalAlignment = 'Right'
    [void]$right.Children.Add($lvl)
    [void]$right.Children.Add($st)
    [System.Windows.Controls.Grid]::SetColumn($right, 1)

    [void]$grid.Children.Add($left)
    [void]$grid.Children.Add($right)
    $border.Child = $grid
    [void]$Panel.Children.Add($border)
    if (-not $Enabled) { $border.Opacity = 0.45 }

    $cb.Tag = @{ Item = $Item; Status = $st }
    $List.Add($cb)
}

# Populate tabs
Add-Section $AppsPanel 'Removed for all users and de-provisioned so they do not come back for new accounts. Most can be reinstalled from the Microsoft Store. The Store, runtimes, codecs, Photos, Calculator, Notepad, Paint, Snipping Tool and Terminal are protected.'
foreach ($a in $Apps) {
    $present = Test-AppPresent $a
    $status  = if ($present) { 'Installed' } else { 'Not installed' }
    Add-Row $AppsPanel $a $a.Label $a.Desc $status $present $script:AppChecks
}

Add-Section $SvcsPanel 'Original startup types are saved before any change. "Undo services" restores them exactly. Manual = the service still starts when something needs it.'
foreach ($s in $Services) {
    $cur = Get-SvcStart $s.Name
    $ok  = ($null -ne $cur -and $cur -ne 'other')
    $status = "Now: $(Format-Start $cur)  ->  $($s.Target)"
    Add-Row $SvcsPanel $s $s.Label $s.Desc $status $ok $script:SvcChecks
}

Add-Section $TweaksPanel 'Tick tweaks and press "Apply selected". To undo, tick the same tweaks and press "Revert selected tweaks". Some take effect after sign-out or restart.'
foreach ($t in $Tweaks) {
    Add-Row $TweaksPanel $t $t.Label $t.Desc '' $true $script:TweakChecks
}

function Get-AllChecks { @($script:AppChecks) + @($script:SvcChecks) + @($script:TweakChecks) }

function Set-Busy([bool]$Busy) {
    foreach ($b in $Buttons) { $b.IsEnabled = -not $Busy }
    $W.Cursor = if ($Busy) { [System.Windows.Input.Cursors]::Wait } else { $null }
    Update-UI
}

function Update-ServiceStatus {
    foreach ($cb in $script:SvcChecks) {
        $s = $cb.Tag.Item
        $cb.Tag.Status.Text = "Now: $(Format-Start (Get-SvcStart $s.Name))  ->  $($s.Target)"
    }
}

# ------------------------------------------------------------------ button handlers
$W.FindName('BtnRecommended').Add_Click({
    foreach ($cb in Get-AllChecks) { if ($cb.IsEnabled) { $cb.IsChecked = ($cb.Tag.Item.Level -eq 'Recommended') } }
})

$W.FindName('BtnNone').Add_Click({
    foreach ($cb in Get-AllChecks) { $cb.IsChecked = $false }
})

$W.FindName('BtnApply').Add_Click({
    $selApps   = @($script:AppChecks   | Where-Object { $_.IsChecked -and $_.IsEnabled })
    $selSvcs   = @($script:SvcChecks   | Where-Object { $_.IsChecked -and $_.IsEnabled })
    $selTweaks = @($script:TweakChecks | Where-Object { $_.IsChecked -and $_.IsEnabled })
    $total = $selApps.Count + $selSvcs.Count + $selTweaks.Count
    if ($total -eq 0) {
        [void][System.Windows.MessageBox]::Show('Nothing is selected.', $AppName, 'OK', 'Information')
        return
    }

    $caution = @(($selApps + $selSvcs + $selTweaks) | Where-Object { $_.Tag.Item.Level -eq 'Caution' } |
                 ForEach-Object { '  - ' + $_.Content })
    $msg = "GameLite will:`n`n  - Remove $($selApps.Count) app(s)`n  - Change $($selSvcs.Count) service(s)`n  - Apply $($selTweaks.Count) tweak(s)`n"
    if ($caution.Count -gt 0) { $msg += "`nYou selected CAUTION items:`n" + ($caution -join "`n") + "`n" }
    $msg += "`nContinue?"
    if ([System.Windows.MessageBox]::Show($msg, $AppName, 'YesNo', 'Question') -ne 'Yes') { return }

    Set-Busy $true
    try {
        if ($ChkRestore.IsChecked) {
            if (-not (New-RestorePoint)) {
                $r = [System.Windows.MessageBox]::Show('A restore point could not be created. Continue anyway?', $AppName, 'YesNo', 'Warning')
                if ($r -ne 'Yes') { Write-Log 'Cancelled.'; return }
            }
        }

        if ($selApps.Count) { Write-Log "--- Removing $($selApps.Count) app(s) ---" }
        foreach ($cb in $selApps) {
            if (Remove-App $cb.Tag.Item) {
                $cb.IsChecked = $false; $cb.IsEnabled = $false; $cb.Tag.Status.Text = 'Removed'
            }
        }

        if ($selSvcs.Count) { Write-Log "--- Changing $($selSvcs.Count) service(s) ---" }
        foreach ($cb in $selSvcs) { [void](Set-ServiceMode $cb.Tag.Item) }
        Update-ServiceStatus

        if ($selTweaks.Count) { Write-Log "--- Applying $($selTweaks.Count) tweak(s) ---" }
        foreach ($cb in $selTweaks) {
            $t = $cb.Tag.Item
            try { & $t.Apply; Write-Log "Applied: $($t.Label)"; $cb.Tag.Status.Text = 'Applied' }
            catch { Write-Log "Failed: $($t.Label) - $($_.Exception.Message)" 'WARN' }
        }

        Write-Log "Done. Full log: $LogFile"
        [void][System.Windows.MessageBox]::Show("Finished.`n`nRestart your PC so every change takes effect.", $AppName, 'OK', 'Information')
    } finally {
        Set-Busy $false
    }
})

$W.FindName('BtnUndoSvcs').Add_Click({
    $backup = Get-SvcBackup
    if ($backup.Count -eq 0) {
        [void][System.Windows.MessageBox]::Show('No service backup found - nothing to undo.', $AppName, 'OK', 'Information')
        return
    }
    if ([System.Windows.MessageBox]::Show("Restore $($backup.Count) service(s) to their original startup type?", $AppName, 'YesNo', 'Question') -ne 'Yes') { return }

    Set-Busy $true
    try {
        Write-Log '--- Restoring services ---'
        $failed = @{}
        foreach ($name in @($backup.Keys)) {
            $mode = [string]$backup[$name]
            if ($mode -notin @('auto', 'delayed-auto', 'demand', 'disabled')) { continue }
            $null = sc.exe config $name start= $mode
            if ($LASTEXITCODE -eq 0) { Write-Log "Restored $name -> $(Format-Start $mode)" }
            else { Write-Log "Could not restore $name" 'WARN'; $failed[$name] = $mode }
        }
        if ($failed.Count -eq 0) { Remove-Item $SvcBackup -Force } else { Save-SvcBackup $failed }
        Update-ServiceStatus
        Write-Log 'Services restored. Restart to start them again.'
    } finally {
        Set-Busy $false
    }
})

$W.FindName('BtnRevert').Add_Click({
    $sel = @($script:TweakChecks | Where-Object { $_.IsChecked })
    if ($sel.Count -eq 0) {
        [void][System.Windows.MessageBox]::Show('Tick the tweaks you want to revert on the Tweaks tab first.', $AppName, 'OK', 'Information')
        return
    }
    if ([System.Windows.MessageBox]::Show("Revert $($sel.Count) tweak(s) to Windows defaults?", $AppName, 'YesNo', 'Question') -ne 'Yes') { return }

    Set-Busy $true
    try {
        Write-Log '--- Reverting tweaks ---'
        foreach ($cb in $sel) {
            $t = $cb.Tag.Item
            try { & $t.Revert; Write-Log "Reverted: $($t.Label)"; $cb.Tag.Status.Text = 'Reverted' }
            catch { Write-Log "Revert failed: $($t.Label) - $($_.Exception.Message)" 'WARN' }
        }
        Write-Log 'Done. Restart to finish reverting.'
    } finally {
        Set-Busy $false
    }
})

Write-Log "GameLite ready. Found $(@($script:AppChecks | Where-Object IsEnabled).Count) removable app(s) on this PC."
[void]$W.ShowDialog()
