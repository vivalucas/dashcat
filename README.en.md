# DashCat

A lightweight macOS menu bar app that combines clipboard history, system monitoring, sleep prevention, and mouse wheel reversal into one running cat.

[中文](README.md) | [English](README.en.md) | [日本語](README.ja.md) | [한국어](README.ko.md) | [Deutsch](README.de.md) | [Français](README.fr.md) | [Español](README.es.md) | [Português](README.pt-BR.md) | [Italiano](README.it.md) | [繁體中文](README.zh-TW.md) | [Русский](README.ru.md)

---

I'd been running several menu bar tools on macOS: one for system load, one for clipboard history (Maccy), one for sleep prevention (Caffeine), plus another fix for external mouse wheel direction. Multiple icons, multiple background processes — felt like a waste. So I built one from scratch, keeping only the essentials: system monitoring, clipboard management, sleep prevention, and mouse wheel reversal. The monitor is optimized for Apple Silicon, the clipboard manager is streamlined and efficient, and sleep prevention plus wheel reversal are built right in. Just what you need, nothing more.

That's how DashCat came to be. A cat sitting in the menu bar — the faster it runs, the higher the load; left-click for clipboard history with instant search; right-click for sleep prevention, mouse wheel direction, monitor mode, and language switching. One icon handles several everyday tools. Zero dependencies, minimal resource usage, all data stored locally.

---

## Features

- **Clipboard Manager**
  - Left-click the cat icon to open a clipboard history panel
  - Real-time search filtering
  - Click to copy, `Option + Enter` to copy as plain text
  - Right-click an item to pin it to the top
  - Text and image support (JPEG compressed, toggleable image storage)
  - Customizable retention: 7 / 14 / 30 / 90 days, forever, or a custom 1-365 day value
  - Optional filter terms so matching future text clips are not saved
  - All data stored locally — fully offline, no data collection

- **System Monitor**
  - Defaults to Compact Values: a two-line C/M percentage readout for CPU + memory that saves menu bar space
  - Custom Display lets you choose the monitor source (Combined, CPU, Memory) and display style (Animation, Animation + Value)
  - Cat animation speed reflects real-time system load — the faster it runs, the higher the pressure
  - Combined mode automatically picks the higher of CPU / memory to drive the animation

- **Minimal Battery Display**
  - Optional standalone menu bar battery indicator, separate from the cat item
  - Shows a narrow number without the percent sign, backed by a subtle green battery fill for crowded notched menu bars
  - Shows a non-widening blue outline when plugged in or charging
  - Click the battery number to view level, power source, charging status, Low Power Mode, and Battery Settings
  - Can hide automatically when plugged in, leaving no menu bar gap
  - Uses system power information with low-frequency refresh, no animation, and minimal overhead

- **Sleep Prevention**
  - Default color: normal — system can sleep
  - Blue: prevent system idle sleep (display can still turn off)
  - Orange: prevent display sleep
  - Switch directly from the right-click menu — cat color changes in real time

- **More**
  - 11 languages: English, 中文, 日本語, 한국어, Deutsch, Français, Español, Português, Italiano, 繁體中文, Русский
  - Reverse external mouse wheel direction while keeping the trackpad on macOS natural scrolling
  - Create a TXT or Markdown file in Finder, with the target path shown before creation and an option to choose another folder
  - Launch at login support
  - Energy-efficient: 12 fps animation cap, 5 s sampling interval, auto-pause on system sleep
  - Zero external dependencies — pure AppKit + Swift

## Requirements

- macOS 13 (Ventura) or later
- Apple Silicon Mac (M-series chips)

## Installation

**Option 1: DMG installer**

1. Go to the [Releases](../../releases) page and download the latest `DashCat-<version>.dmg`
2. Open the DMG and drag DashCat into your Applications folder
3. On first launch, macOS may show "app is damaged" or "cannot verify the developer" — this is Gatekeeper blocking an unsigned app; the app itself is fine. Run the following command in Terminal to remove the quarantine flag:
   ```bash
   xattr -cr /Applications/DashCat.app
   ```
   Then double-click to launch normally. Alternatively, right-click → Open → click Open in the dialog.

**Option 2: Build from source (no Gatekeeper bypass needed)**

1. Clone this repository
2. Open `DashCat.xcodeproj` in Xcode
3. Select your own developer account under **Signing & Capabilities**
4. Run with `⌘R` — Xcode signs the app automatically

## Usage

- **Left-click** the cat icon: open clipboard history panel
  - Type in the search box to filter
  - Click an item to copy it
  - `Option + Enter` to copy as plain text
  - Right-click an item to pin or unpin it
- **Right-click** the cat icon: open settings menu
  - Switch Monitor between Compact Values and custom animation display
  - Manage image saving, retention, filter terms, and clearing history in Clipboard Settings
  - Toggle the compact battery display and plugged-in hide behavior
  - Create a file in Finder, reverse mouse wheel, change language, set launch at login

## FAQ

**Where is clipboard data stored?**

`~/Library/Application Support/DashCat/` — `clipboard.db` for text records, `Images/` for image files. Clearing history cleans both.

**How much disk space do images use?**

Images are stored as JPEG (a few hundred KB each). Image saving is off by default. When enabled, there is a 500 MB total cap — the oldest unpinned images are deleted automatically when the limit is reached.

**What do the cat colors mean?**

Default → normal sleep behavior. **Blue** → preventing system sleep. **Orange** → preventing display sleep. Toggle from the right-click menu.

**Why does reversing the mouse wheel require Accessibility permission?**

DashCat needs to identify mouse wheel events in the system event stream and flip their direction, so macOS requires Accessibility permission. Without it, clipboard history, system monitoring, and sleep prevention still work; the right-click menu shows a hint and a shortcut to System Settings.

**Why does creating a Finder file ask to control Finder?**

DashCat only reads the current Finder window folder when you choose “New File in Finder”. macOS may show an Automation permission prompt so DashCat can get that path; DashCat does not monitor Finder in the background. The command lives in DashCat’s menu and does not inject itself into Finder’s blank-area context menu.

**Does it support Intel Macs?**

No. arm64 only, designed for Apple Silicon.

**How is this different from Maccy / CopyClip / Amphetamine?**

DashCat combines clipboard management (like Maccy), system monitoring, and sleep prevention (like Amphetamine / Caffeine) into a single lightweight menu bar app — one icon, one process, zero dependencies. Pure AppKit for minimal memory footprint.

**Why does macOS say the app is "damaged" or "cannot verify the developer" on first launch?**

The prebuilt binary is not signed with an Apple Developer certificate, so Gatekeeper shows this message — the app itself is fine. Run `xattr -cr /Applications/DashCat.app` in Terminal to remove the quarantine flag, then launch normally. To avoid this step entirely, build from source and sign with your own account.

## License

MIT License
