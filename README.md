# NetSpeed

A lightweight macOS menu bar app that displays real-time network upload and download speeds.

<p align="center">
  <img src="https://img.shields.io/badge/Platform-macOS%2013%2B-blue" alt="Platform">
  <img src="https://img.shields.io/badge/Swift-5.9-orange" alt="Swift">
  <img src="https://img.shields.io/badge/Size-~100KB-green" alt="Size">
  <img src="https://img.shields.io/badge/Dependencies-None-brightgreen" alt="Dependencies">
  <img src="https://img.shields.io/badge/License-MIT-lightgrey" alt="License">
</p>

## Features

- **Compact stacked display** — Upload (▲) and download (▼) speeds shown in two rows, taking minimal menu bar space
- **Color-coded arrows** — Green ▲ for upload, blue ▼ for download
- **Adaptive formatting** — Automatically switches between KB/s, MB/s, and GB/s with smart decimal precision
- **Session totals** — Click to see total data transferred since the app was launched
- **Active interface detection** — Shows which network interface is being used (Wi-Fi, Ethernet, etc.)
- **Launch at Login** — Built-in toggle to auto-start on login
- **Truly lightweight** — ~100 KB app size, near-zero CPU usage, no third-party dependencies
- **Dark mode support** — Adapts to your system appearance automatically

## Menu Bar Preview

The app displays a compact two-row layout in your menu bar:

```
▲ 1.2MB/s
▼ 340KB/s
```

Click it to see the dropdown with detailed speeds, session totals, and settings.

## Installation

### Build from Source

**Requirements:** macOS 13.0+ and Swift 5.9+ (included with Xcode or Command Line Tools)

```bash
# Clone the repository
git clone https://github.com/mohith-labs/MacNetspeed.git
cd MacNetspeed

# Build and create the app bundle
./build.sh

# Install to Applications
cp -r build/NetSpeed.app /Applications/

# Launch
open /Applications/NetSpeed.app
```

### Manual Build

```bash
# Build release binary
swift build -c release

# Create app bundle manually
mkdir -p build/NetSpeed.app/Contents/MacOS
cp .build/release/NetSpeed build/NetSpeed.app/Contents/MacOS/
cp Resources/Info.plist build/NetSpeed.app/Contents/
echo -n "APPL????" > build/NetSpeed.app/Contents/PkgInfo
```

## How It Works

NetSpeed reads network byte counters directly from the operating system using the `getifaddrs` POSIX API at the data-link layer (`AF_LINK`). This is the same low-level approach used by macOS's own Activity Monitor.

- **No shell commands** — Doesn't spawn `netstat`, `nettop`, or any subprocess
- **No polling of files** — Reads kernel counters directly via C API
- **No network access needed** — Only reads local interface statistics
- **Minimal overhead** — Updates every 2 seconds (the industry-standard sweet spot used by apps like MenuMeters)

### Technical Details

| Component | Detail |
|---|---|
| **Data source** | `getifaddrs()` → `AF_LINK` → `if_data.ifi_ibytes` / `ifi_obytes` |
| **Update interval** | 2 seconds |
| **Font** | Monospaced digit system font (prevents jitter as numbers change) |
| **Menu bar layout** | Custom `NSImage` rendering with stacked rows |
| **Launch at login** | `SMAppService` (macOS 13+) |
| **App type** | `LSUIElement` — menu bar only, no Dock icon |

### Filtered Interfaces

The app automatically filters out virtual/internal interfaces and only monitors real network interfaces:

- ✅ `en0` (Wi-Fi), `en1`–`en9` (Ethernet/Thunderbolt)
- ❌ `lo0` (loopback), `utun` (VPN tunnels), `awdl` (AirDrop), `bridge`, `ap` (access point), `llw`, `gif`, `stf`, `anpi`

## Project Structure

```
MacNetspeed/
├── Package.swift              # Swift Package Manager configuration
├── build.sh                   # One-click build script
├── Sources/
│   ├── main.swift             # App entry point & run loop
│   ├── AppDelegate.swift      # Menu bar UI, stacked display rendering
│   └── NetworkMonitor.swift   # Network byte counter reader (getifaddrs)
├── Resources/
│   └── Info.plist             # App metadata (LSUIElement for menu-bar-only)
├── LICENSE
└── README.md
```

## Configuration

Currently, the app uses sensible defaults based on research of popular network monitors (Stats, eul, MenuMeters, iStat Menus):

| Setting | Value | Rationale |
|---|---|---|
| Update interval | 2 seconds | Balance between responsiveness and CPU usage |
| Display format | Stacked two-row | Most compact; used by Stats, eul, iStat Menus |
| Font size | 9pt | Standard for stacked menu bar widgets |
| Unit base | Binary (1024) | Matches macOS conventions |

## Contributing

Contributions are welcome! Some ideas for future improvements:

- [ ] Configurable update interval via the dropdown menu
- [ ] Toggle between bits/s and bytes/s
- [ ] Mini speed graph in the dropdown
- [ ] Notification when speed drops below threshold
- [ ] Per-interface speed breakdown

## License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

## Acknowledgments

Design decisions informed by research into these excellent open-source projects:
- [Stats](https://github.com/exelban/stats) — macOS system monitor
- [eul](https://github.com/gao-sun/eul) — SwiftUI status monitoring app
- [MenuMeters](https://github.com/yujitach/MenuMeters) — Classic macOS menu bar meters
