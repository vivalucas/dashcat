# DashCat

A lightweight macOS menu bar app that combines clipboard history, system monitoring, and sleep prevention into one running cat.

[中文](README.md) | [English](README.en.md) | [日本語](README.ja.md) | [한국어](README.ko.md) | [Deutsch](README.de.md) | [Français](README.fr.md) | [Русский](README.ru.md)

---

I'd been running three menu bar tools on macOS: one for system load, one for clipboard history (Maccy), one for sleep prevention (Caffeine). Three icons, three background processes — felt like a waste. So I built one from scratch, keeping only the essentials: system monitoring, clipboard management, and sleep prevention. The monitor is optimized for Apple Silicon, the clipboard manager is streamlined and efficient, and sleep prevention is built right in. Just what you need, nothing more.

That's how DashCat came to be. A cat sitting in the menu bar — the faster it runs, the higher the load; left-click for clipboard history with instant search; right-click for sleep prevention, monitor mode, and language switching. One icon does the work of three. Zero dependencies, minimal resource usage, all data stored locally.

---

## Features

- **Clipboard Manager**
  - Left-click the cat icon to open a clipboard history panel
  - Real-time search filtering
  - Click to copy, `Option + Enter` to copy as plain text
  - Pin frequently used items to the top
  - Text and image support (JPEG compressed, toggleable image storage)
  - Customizable retention: 7 / 14 / 30 / 90 days, forever, or a custom 1-365 day value
  - All data stored locally — fully offline, no data collection

- **System Monitor**
  - Three modes: Combined, CPU, Memory
  - Cat animation speed reflects real-time system load — the faster it runs, the higher the pressure
  - Combined mode automatically picks the higher of CPU / memory to drive the animation
  - Optional percentage display in the status bar

- **Sleep Prevention**
  - Default color: normal — system can sleep
  - Blue: prevent system idle sleep (display can still turn off)
  - Orange: prevent display sleep
  - Switch directly from the right-click menu — cat color changes in real time

- **More**
  - 7 languages: English, 中文, 日本語, 한국어, Deutsch, Français, Русский
  - Launch at login support
  - Energy-efficient: 12 fps animation cap, 5 s sampling interval, auto-pause on system sleep
  - Zero external dependencies — pure AppKit + Swift

## Requirements

- macOS 26 (Tahoe) or later
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
  - Pin frequently used items
- **Right-click** the cat icon: open settings menu
  - Switch monitor mode, sleep prevention mode
  - Manage clipboard history (save images, retention days, clear history)
  - Change language, toggle percentage display, set launch at login

## FAQ

**Where is clipboard data stored?**

`~/Library/Application Support/DashCat/` — `clipboard.db` for text records, `Images/` for image files. Clearing history cleans both.

**How much disk space do images use?**

Images are stored as JPEG (a few hundred KB each). Image saving is off by default. When enabled, there is a 500 MB total cap — the oldest unpinned images are deleted automatically when the limit is reached.

**What do the cat colors mean?**

Default → normal sleep behavior. **Blue** → preventing system sleep. **Orange** → preventing display sleep. Toggle from the right-click menu.

**Does it support Intel Macs?**

No. arm64 only, designed for Apple Silicon.

**How is this different from Maccy / CopyClip / Amphetamine?**

DashCat combines clipboard management (like Maccy), system monitoring, and sleep prevention (like Amphetamine / Caffeine) into a single lightweight menu bar app — one icon, one process, zero dependencies. Pure AppKit for minimal memory footprint.

**Why does macOS say the app is "damaged" or "cannot verify the developer" on first launch?**

The prebuilt binary is not signed with an Apple Developer certificate, so Gatekeeper shows this message — the app itself is fine. Run `xattr -cr /Applications/DashCat.app` in Terminal to remove the quarantine flag, then launch normally. To avoid this step entirely, build from source and sign with your own account.

## License

MIT License
