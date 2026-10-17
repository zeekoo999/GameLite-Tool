<div align="center">

# GameLite

**A lightweight, open-source Windows debloater for gaming PCs - with a GUI.**

Remove preinstalled bloat, switch off background services you don't need, and apply
gaming and privacy tweaks - all from one window, and all reversible.

![Platform](https://img.shields.io/badge/platform-Windows%2010%20%7C%2011-0078D6?logo=windows)
![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-5391FE?logo=powershell&logoColor=white)
![License](https://img.shields.io/badge/license-MIT-green)
![Status](https://img.shields.io/badge/status-v1.0-brightgreen)

</div>

---
<img width="1720" height="1347" alt="image" src="https://github.com/user-attachments/assets/652bcc19-02f2-415e-8b33-0cdc6ec091ea" />

## Table of contents

- [Why GameLite](#why-gamelite)
- [Features](#features)
- [Screenshots](#screenshots)
- [Requirements](#requirements)
- [Installation](#installation)
- [Usage](#usage)
- [What GameLite changes](#what-gamelite-changes)
  - [Apps](#apps)
  - [Services](#services)
  - [Tweaks](#tweaks)
- [Undoing changes](#undoing-changes)
- [Safety design](#safety-design)
- [Files and logs](#files-and-logs)
- [FAQ](#faq)
- [Troubleshooting](#troubleshooting)
- [Customising the lists](#customising-the-lists)
- [Contributing](#contributing)
- [Disclaimer](#disclaimer)
- [License](#license)

---

## Why GameLite

A fresh Windows install ships with promo apps, telemetry, ad-driven Start menu
suggestions and background services that most gamers never use. They cost RAM,
CPU time and disk activity, and can cause small stutters while you play.

GameLite cleans that up **without** breaking the things gamers actually rely on.
Anything that affects Xbox / PC Game Pass, Game Bar or controllers is clearly marked
and **never** selected by default.

> **Honest expectations:** GameLite makes the system leaner and quieter in the
> background. You'll usually see lower idle RAM/CPU usage and fewer background
> hiccups - not a huge FPS jump. GPU drivers and in-game settings matter more for raw FPS.

## Features

- **Graphical interface** - dark-themed WPF window with three tabs: Apps, Services, Tweaks.
- **Detects your system** - only apps that are actually installed can be selected; each
  service shows its current startup type.
- **Colour-coded risk levels** - Recommended, Optional and Caution.
- **One-click presets** - *Select recommended* or *Select none*.
- **Automatic restore point** before any change.
- **Exact service undo** - original startup types are saved and restored precisely.
- **Revertible tweaks** - every tweak has a matching revert action.
- **Protected core apps** - Store, runtimes, codecs and essential apps can never be removed.
- **Live log** in the window, saved to disk for every session.
- **No install, no dependencies** - pure PowerShell, built into Windows.

## Screenshots

> _Add your screenshots to `docs/` and update the paths below._

| Apps tab | Tweaks tab |
|---|---|
| ![Apps tab](docs/screenshot-apps.png) | ![Tweaks tab](docs/screenshot-tweaks.png) |

## Requirements

| Requirement | Details |
|---|---|
| OS | Windows 10 (version 1809 or newer) or Windows 11 |
| PowerShell | Windows PowerShell 5.1 (preinstalled on Windows 10/11) |
| Rights | Administrator (GameLite asks for elevation automatically) |
| Disk | System Protection enabled on `C:` if you want a restore point (GameLite tries to enable it) |

## Installation

### Option 1 - Download a release (recommended)

1. Go to the [Releases](../../releases) page and download `GameLite.zip`.
2. Extract it to any folder, e.g. `C:\Tools\GameLite`.
3. If Windows marked the files as downloaded from the internet, right-click
   `GameLite.ps1` -> **Properties** -> tick **Unblock** -> **OK**.

### Option 2 - Clone the repository

```powershell
git clone https://github.com/<your-username>/GameLite.git
cd GameLite
```

### Project structure

```
GameLite/
|-- GameLite.ps1        # The application (GUI + all logic)
|-- Run-GameLite.bat    # Double-click launcher
`-- README.md           # This file
```

## Usage

### Start GameLite

Double-click **`Run-GameLite.bat`** and accept the administrator (UAC) prompt.

Or from PowerShell:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -File .\GameLite.ps1
```

> If SmartScreen shows "Windows protected your PC", click **More info** -> **Run anyway**.
> This happens with any unsigned script; you can read the full source in `GameLite.ps1`.

### Step by step

1. **Wait a few seconds** while GameLite scans installed apps and services.
2. **Review each tab.** Recommended items are pre-ticked. Hover-free descriptions explain
   what each item does.
3. **Keep "Create a restore point first" ticked.**
4. Click **Apply selected**. A confirmation dialog shows a summary and lists any
   Caution items you picked.
5. Watch the log at the bottom of the window.
6. **Restart your PC** when finished.

### Buttons

| Button | What it does |
|---|---|
| **Select recommended** | Ticks every green item, unticks everything else |
| **Select none** | Unticks everything |
| **Undo services** | Restores every service GameLite changed to its original startup type |
| **Revert selected tweaks** | Runs the revert action for each ticked tweak |
| **Apply selected** | Applies all ticked apps, services and tweaks |

### Risk levels

| Level | Colour | Meaning | Ticked by default |
|---|---|---|---|
| **Recommended** | Green | Safe for almost every gaming PC | Yes |
| **Optional** | Blue | Depends on what you use | No |
| **Caution** | Orange | Can break a feature you might use (e.g. Game Pass) | No |

---

## What GameLite changes

### Apps

Apps are removed for **all users** and **de-provisioned**, so they don't come back when
a new user account is created. Most can be reinstalled from the Microsoft Store.

<details>
<summary><b>Recommended</b> (ticked by default)</summary>

| App | Package |
|---|---|
| Microsoft News | `Microsoft.BingNews` |
| MSN Money | `Microsoft.BingFinance` |
| MSN Sports | `Microsoft.BingSports` |
| Bing Search | `Microsoft.BingSearch` |
| Tips | `Microsoft.Getstarted` |
| Solitaire Collection | `Microsoft.MicrosoftSolitaireCollection` |
| Microsoft 365 hub | `Microsoft.MicrosoftOfficeHub` |
| People | `Microsoft.People` |
| Feedback Hub | `Microsoft.WindowsFeedbackHub` |
| Maps | `Microsoft.WindowsMaps` |
| Movies & TV | `Microsoft.ZuneVideo` |
| Skype | `Microsoft.SkypeApp` |
| Power Automate | `Microsoft.PowerAutomateDesktop` |
| Clipchamp | `Clipchamp.Clipchamp` |
| Cortana | `Microsoft.549981C3F5F10` |
| Mixed Reality Portal | `Microsoft.MixedReality.Portal` |
| 3D Viewer | `Microsoft.Microsoft3DViewer` |
| Paint 3D | `Microsoft.MSPaint` |
| Teams (personal, old / new) | `MicrosoftTeams`, `MSTeams` |
| Dev Home | `Microsoft.Windows.DevHome` |
| Copilot app | `Microsoft.Copilot` |
| Microsoft Family | `MicrosoftCorporationII.MicrosoftFamily` |
| Wallet | `Microsoft.Wallet` |
| Xbox Console Companion | `Microsoft.XboxApp` |
| Candy Crush & King games | `*king.com*` |
| Disney+, TikTok, Instagram, Facebook, X/Twitter, LinkedIn | `*Disney*`, `*TikTok*`, `*Instagram*`, `*Facebook*`, `*Twitter*`, `*LinkedIn*` |

</details>

<details>
<summary><b>Optional</b></summary>

| App | Package | Note |
|---|---|---|
| Weather | `Microsoft.BingWeather` | |
| Get Help | `Microsoft.GetHelp` | Some Windows 11 troubleshooters open through it |
| Media Player (Groove) | `Microsoft.ZuneMusic` | Default player - remove only if you use VLC etc. |
| Phone Link | `Microsoft.YourPhone` | |
| Microsoft To Do | `Microsoft.Todos` | |
| OneNote (Store) | `Microsoft.Office.OneNote` | |
| New Outlook | `Microsoft.OutlookForWindows` | |
| Clock / Alarms | `Microsoft.WindowsAlarms` | |
| Sound Recorder | `Microsoft.WindowsSoundRecorder` | |
| Sticky Notes | `Microsoft.MicrosoftStickyNotes` | |
| Quick Assist | `MicrosoftCorporationII.QuickAssist` | |
| Prime Video | `*PrimeVideo*` | |
| Spotify (Store) | `*SpotifyMusic*` | |
| Xbox Game Overlay (old) | `Microsoft.XboxGameOverlay` | |
| Xbox Speech-to-Text | `Microsoft.XboxSpeechToTextOverlay` | |

</details>

<details>
<summary><b>Caution</b> - gaming-related, never ticked by default</summary>

| App | Package | What breaks if removed |
|---|---|---|
| Xbox app | `Microsoft.GamingApp` | PC Game Pass and Microsoft Store games |
| Xbox Game Bar | `Microsoft.XboxGamingOverlay` | Win+G overlay, FPS counter, captures, party chat |
| Xbox Identity Provider | `Microsoft.XboxIdentityProvider` | Xbox sign-in in games like Minecraft, Forza, Halo |
| Xbox TCUI | `Microsoft.Xbox.TCUI` | Xbox friends/profile UI inside games |

</details>

#### Protected - never removed

These are on a hard-coded block list and are skipped even if a wildcard matches them:

Microsoft Store, Store Purchase, App Installer (winget), VCLibs, .NET, UI.Xaml and
Windows App runtimes, Shell / Start menu hosts, Windows Security, Terminal, Notepad,
Photos, Calculator, Paint, Snipping Tool, and the HEIF / HEVC / VP9 / AV1 / WebP /
Web Media / Raw / MPEG-2 codec extensions.

### Services

**Disabled** = the service never starts. **Manual** = it only starts when something
actually needs it.

| Service | Display name | Target | Level |
|---|---|---|---|
| `DiagTrack` | Connected User Experiences and Telemetry | Disabled | Recommended |
| `dmwappushservice` | Device Management WAP Push | Disabled | Recommended |
| `WerSvc` | Windows Error Reporting | Disabled | Recommended |
| `MapsBroker` | Downloaded Maps Manager | Disabled | Recommended |
| `RetailDemo` | Retail Demo | Disabled | Recommended |
| `Fax` | Fax | Disabled | Recommended |
| `WMPNetworkSvc` | Windows Media Player Network Sharing | Disabled | Recommended |
| `RemoteRegistry` | Remote Registry | Disabled | Recommended |
| `WpcMonSvc` | Parental Controls | Disabled | Recommended |
| `wisvc` | Windows Insider Service | Disabled | Recommended |
| `lfsvc` | Geolocation | Manual | Optional |
| `PhoneSvc` | Phone Service | Manual | Optional |
| `SEMgrSvc` | Payments and NFC/SE Manager | Manual | Optional |
| `PcaSvc` | Program Compatibility Assistant | Manual | Optional |
| `edgeupdate`, `edgeupdatem` | Microsoft Edge Update | Manual | Optional |
| `SysMain` | SysMain (Superfetch) | Manual | Optional |
| `Spooler` | Print Spooler | Manual | Optional |
| `WSearch` | Windows Search (indexing) | Manual | Caution |
| `XblAuthManager` | Xbox Live Auth Manager | Manual | Caution |
| `XblGameSave` | Xbox Live Game Save | Manual | Caution |
| `XboxNetApiSvc` | Xbox Live Networking | Manual | Caution |
| `XboxGipSvc` | Xbox Accessory Management | Manual | Caution |

Services that don't exist on your PC are greyed out. Boot and system-level services
are never touched.

### Tweaks

| Tweak | Level | What it does | Applies after |
|---|---|---|---|
| Turn off telemetry | Recommended | Sets diagnostic data to the minimum your edition allows | Restart |
| Turn off advertising ID | Recommended | Stops personalised ads across apps | Immediately |
| Block suggested & auto-installed apps | Recommended | Removes Start menu ads/tips and stops Windows silently reinstalling promo apps | Restart |
| Remove Bing web results from Start search | Recommended | Start search only searches your PC | Sign-out |
| Turn off Copilot and Recall | Recommended | Disables Copilot and Recall snapshots via policy | Restart |
| Turn off Widgets / News feed | Recommended | Removes the widgets board and its background processes | Restart |
| Turn off Game DVR background recording | Recommended | Stops constant background capture; Game Bar still works | Immediately |
| Turn on Game Mode | Recommended | Prioritises the game, pauses update installs while playing | Immediately |
| Block Store apps running in background | Optional | Store apps stop when closed. Desktop apps (Steam, Discord) are unaffected | Restart |
| Turn off mouse acceleration | Optional | Disables "Enhance pointer precision" for 1:1 aim | Sign-out |
| Hardware-accelerated GPU scheduling | Optional | Can lower latency on GTX 10-series / RX 5000 and newer | Restart |
| Ultimate Performance power plan | Optional | Keeps CPU clocks high. Not for laptops on battery | Immediately |
| Visual effects: best performance | Optional | Turns off animations, shadows and fades | Sign-out |
| Uninstall OneDrive | Caution | Removes OneDrive sync; cloud and local files stay | Immediately |

<details>
<summary>Registry details for each tweak</summary>

| Tweak | Key / value |
|---|---|
| Telemetry | `HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection\AllowTelemetry = 0` and `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection\AllowTelemetry = 0` |
| Advertising ID | `HKCU\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo\Enabled = 0` |
| Suggested apps | `HKCU\...\ContentDeliveryManager` (14 values) `= 0`, `HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent\DisableWindowsConsumerFeatures = 1` |
| Bing in Start | `HKCU\Software\Policies\Microsoft\Windows\Explorer\DisableSearchBoxSuggestions = 1` |
| Copilot / Recall | `...\WindowsCopilot\TurnOffWindowsCopilot = 1`, `...\WindowsAI\DisableAIDataAnalysis = 1` (HKCU and HKLM) |
| Widgets | `HKLM\SOFTWARE\Policies\Microsoft\Dsh\AllowNewsAndInterests = 0`, `HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds\EnableFeeds = 0` |
| Game DVR | `HKCU\System\GameConfigStore\GameDVR_Enabled = 0`, `HKCU\...\CurrentVersion\GameDVR\AppCaptureEnabled = 0` |
| Game Mode | `HKCU\Software\Microsoft\GameBar\AutoGameModeEnabled = 1`, `AllowAutoGameMode = 1` |
| Background apps | `HKCU\...\BackgroundAccessApplications\GlobalUserDisabled = 1` |
| Mouse acceleration | `HKCU\Control Panel\Mouse\MouseSpeed = "0"`, `MouseThreshold1 = "0"`, `MouseThreshold2 = "0"` |
| GPU scheduling | `HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers\HwSchMode = 2` |
| Ultimate Performance | `powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61`, then sets it active |
| Visual effects | `HKCU\...\Explorer\VisualEffects\VisualFXSetting = 2`, `HKCU\Control Panel\Desktop\UserPreferencesMask` |
| OneDrive | `winget uninstall Microsoft.OneDrive`, falling back to `OneDriveSetup.exe /uninstall` |

</details>

---

## Undoing changes

| What | How to undo |
|---|---|
| **Services** | Click **Undo services**. Every service returns to the exact startup type it had before GameLite first changed it (Automatic, Automatic (delayed), Manual or Disabled). |
| **Tweaks** | Tick the tweaks on the Tweaks tab and click **Revert selected tweaks**. |
| **Apps** | Reinstall from the Microsoft Store (or `winget install <name>`). |
| **OneDrive** | Download it again from [microsoft.com/onedrive](https://www.microsoft.com/microsoft-365/onedrive/download). |
| **Everything** | Use System Restore: press `Win + R`, run `rstrui`, and pick **"GameLite - before changes"**. |

## Safety design

- **Restore point first** - enabled by default. If it can't be created, GameLite asks
  before continuing.
- **First-value service backup** - if you run GameLite several times, it always keeps the
  *original* value from before the first change, never an already-modified one.
- **Hard block list** for essential packages, checked on every removal.
- **Confirmation dialog** summarising the changes, with Caution items listed by name.
- **Nothing hidden** - every action is written to the on-screen log and to a log file.
- **Single readable script** - no binaries, no downloads, no network calls (apart from
  `winget` if you choose to uninstall OneDrive).

## Files and logs

GameLite stores its data in `C:\ProgramData\GameLite\`:

| File | Purpose |
|---|---|
| `log-YYYYMMDD-HHMMSS.txt` | Full log of each session |
| `services-backup.json` | Original service startup types (deleted after a successful undo) |
| `ultimate-plan-guid.txt` | ID of the power plan GameLite created, so it can be reused and deleted on revert |

## FAQ

**Will this increase my FPS?**
Sometimes a little, mainly in CPU-limited games and on lower-end systems. The bigger win
is fewer background interruptions, which means smoother frame times.

**Is it safe to run with the default selection?**
Yes. The Recommended set avoids anything gamers commonly rely on. Xbox, Game Bar,
Windows Search and OneDrive are all unticked by default.

**I play PC Game Pass. What should I avoid?**
Leave every **Caution** item in the Apps and Services tabs unticked.

**Will Windows Update undo this?**
Large feature updates can reinstall some apps or reset some settings. Just run GameLite
again afterwards. The "Block suggested & auto-installed apps" tweak reduces this.

**Does it work on Windows 11 24H2 / 25H2?**
Yes. Items that don't exist on your build are simply greyed out.

**Do I need to run it on every user account?**
App removal and service changes apply to the whole PC. Tweaks under `HKCU` apply to the
account that approved the admin prompt, so run GameLite from the account you game on.

**Does it touch Microsoft Edge?**
No. Only the Edge *update services* are offered (as Optional, set to Manual). Edge still
updates itself when you open it.

## Troubleshooting

| Problem | Fix |
|---|---|
| The window flashes and closes | Run from PowerShell to see the error: `powershell -NoProfile -ExecutionPolicy Bypass -STA -File .\GameLite.ps1` |
| "running scripts is disabled on this system" | Use `Run-GameLite.bat`, which bypasses the execution policy for this run only |
| SmartScreen blocks the script | **More info** -> **Run anyway**, or right-click the file -> Properties -> **Unblock** |
| "Restore point failed" | Turn on System Protection: `Win + R` -> `sysdm.cpl` -> **System Protection** -> select `C:` -> **Configure** -> **Turn on** |
| "Could not change <service>" | Windows protects some services on some builds. It's safe to ignore. |
| An app shows "Not installed" | It isn't on your PC, so there's nothing to remove |
| Game Pass / Xbox sign-in stopped working | Click **Undo services**, then reinstall **Xbox** and **Xbox Identity Provider** from the Microsoft Store |
| Start menu search feels slow | Windows Search was set to Manual. Click **Undo services** or set `WSearch` back to Automatic (delayed) |

## Customising the lists

All lists live at the top of `GameLite.ps1` and are plain data, so they're easy to edit.

**Add an app:**

```powershell
New-App 'Publisher.PackageName' 'Display name' 'Short description.' 'Optional'
```

Find package names with:

```powershell
Get-AppxPackage | Select-Object Name | Sort-Object Name
```

**Add a service** (`Target` is `Disabled` or `Manual`):

```powershell
New-Svc 'ServiceName' 'Display name' 'Short description.' 'Manual' 'Optional'
```

**Add a tweak** (an apply block and a revert block):

```powershell
New-Tweak 'Tweak name' 'Short description.' 'Optional' {
    Set-Reg 'HKCU:\Path\To\Key' 'ValueName' 1
} {
    Remove-Reg 'HKCU:\Path\To\Key' 'ValueName'
}
```

**Protect a package** by adding its name (wildcards allowed) to `$ProtectedPackages`.

> Keep the script **ASCII-only**. Windows PowerShell 5.1 reads files without a BOM as
> ANSI, so characters like curly quotes or em dashes can break it.

## Contributing

Contributions are welcome.

1. Fork the repository and create a branch: `git checkout -b feature/my-change`
2. Make your change and test it on a **Windows 10 or 11 virtual machine** first.
3. For every new item, include a clear description and an honest risk level.
   Every tweak must have a working revert.
4. Open a pull request describing what you changed and which Windows builds you tested.

Bug reports: please open an issue with your Windows version (`winver`) and the matching
log file from `C:\ProgramData\GameLite\`.

### Roadmap ideas

- [ ] Export / import a selection profile
- [ ] Reinstall removed Store apps from the GUI
- [ ] Scheduled-task cleanup (telemetry tasks)
- [ ] Dry-run mode that only logs what would change
- [ ] Signed release builds

## Disclaimer

GameLite modifies system settings, services and installed apps. It is provided **as is**,
without warranty of any kind. Always keep the restore point option enabled and back up
important data. You use this tool at your own risk.

GameLite is not affiliated with or endorsed by Microsoft. Windows, Xbox and related names
are trademarks of Microsoft Corporation.

## License

Released under the [MIT License](LICENSE).
