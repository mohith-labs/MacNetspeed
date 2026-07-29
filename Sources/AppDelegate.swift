import Cocoa
import ServiceManagement

class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusItem: NSStatusItem!
    private var networkMonitor: NetworkMonitor!
    private var updateTimer: Timer?
    private var menu: NSMenu!

    // Menu items that get updated
    private var downloadDetailItem: NSMenuItem!
    private var uploadDetailItem: NSMenuItem!
    private var totalDownloadItem: NSMenuItem!
    private var totalUploadItem: NSMenuItem!
    private var interfaceItem: NSMenuItem!

    // Menu bar height constant
    private let menuBarHeight: CGFloat = 22.0

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Create the status bar item with fixed width to prevent jitter
        statusItem = NSStatusBar.system.statusItem(withLength: 62)

        // Initialize network monitor
        networkMonitor = NetworkMonitor()

        // Build the menu
        buildMenu()

        // Set initial display
        updateStatusBar()

        // Start the update timer at 2-second intervals (industry sweet spot)
        updateTimer = Timer.scheduledTimer(
            timeInterval: 2.0,
            target: self,
            selector: #selector(updateStatusBar),
            userInfo: nil,
            repeats: true
        )

        // Ensure timer fires even during menu tracking
        RunLoop.current.add(updateTimer!, forMode: .common)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        updateTimer?.invalidate()
        updateTimer = nil
    }

    private func buildMenu() {
        menu = NSMenu()

        // Detail section header
        let headerItem = NSMenuItem(title: "Network Speed", action: nil, keyEquivalent: "")
        headerItem.isEnabled = false
        headerItem.attributedTitle = NSAttributedString(
            string: "Network Speed",
            attributes: [.font: NSFont.boldSystemFont(ofSize: 13)]
        )
        menu.addItem(headerItem)

        menu.addItem(NSMenuItem.separator())

        // Download speed detail
        downloadDetailItem = NSMenuItem(title: "▼ Download: --", action: nil, keyEquivalent: "")
        downloadDetailItem.isEnabled = false
        menu.addItem(downloadDetailItem)

        // Upload speed detail
        uploadDetailItem = NSMenuItem(title: "▲ Upload: --", action: nil, keyEquivalent: "")
        uploadDetailItem.isEnabled = false
        menu.addItem(uploadDetailItem)

        menu.addItem(NSMenuItem.separator())

        // Session totals
        let totalsHeader = NSMenuItem(title: "Session Totals", action: nil, keyEquivalent: "")
        totalsHeader.isEnabled = false
        totalsHeader.attributedTitle = NSAttributedString(
            string: "Session Totals",
            attributes: [.font: NSFont.boldSystemFont(ofSize: 13)]
        )
        menu.addItem(totalsHeader)

        totalDownloadItem = NSMenuItem(title: "▼ Downloaded: --", action: nil, keyEquivalent: "")
        totalDownloadItem.isEnabled = false
        menu.addItem(totalDownloadItem)

        totalUploadItem = NSMenuItem(title: "▲ Uploaded: --", action: nil, keyEquivalent: "")
        totalUploadItem.isEnabled = false
        menu.addItem(totalUploadItem)

        menu.addItem(NSMenuItem.separator())

        // Active interface
        interfaceItem = NSMenuItem(title: "Interface: --", action: nil, keyEquivalent: "")
        interfaceItem.isEnabled = false
        menu.addItem(interfaceItem)

        menu.addItem(NSMenuItem.separator())

        // Launch at Login toggle
        let launchAtLoginItem = NSMenuItem(
            title: "Launch at Login",
            action: #selector(toggleLaunchAtLogin(_:)),
            keyEquivalent: ""
        )
        launchAtLoginItem.target = self
        launchAtLoginItem.state = isLaunchAtLoginEnabled() ? .on : .off
        menu.addItem(launchAtLoginItem)

        menu.addItem(NSMenuItem.separator())

        // Quit
        let quitItem = NSMenuItem(title: "Quit NetSpeed", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    @objc private func updateStatusBar() {
        let speeds = networkMonitor.currentSpeeds()

        let downStr = formatSpeedCompact(speeds.download)
        let upStr = formatSpeedCompact(speeds.upload)

        // Create stacked two-row display (like Stats/eul/iStat Menus)
        if let button = statusItem.button {
            let image = createStackedImage(upStr: upStr, downStr: downStr)
            button.image = image
            button.title = ""
        }

        // Update menu detail items (more verbose in dropdown)
        downloadDetailItem.title = "▼ Download:  \(formatSpeedVerbose(speeds.download))"
        uploadDetailItem.title = "▲ Upload:     \(formatSpeedVerbose(speeds.upload))"

        // Update session totals
        let totals = networkMonitor.sessionTotals()
        totalDownloadItem.title = "▼ Downloaded: \(formatBytes(totals.download))"
        totalUploadItem.title = "▲ Uploaded:     \(formatBytes(totals.upload))"

        // Update active interface
        interfaceItem.title = "Interface: \(networkMonitor.activeInterface)"
    }

    /// Creates a two-row stacked image for the menu bar
    /// Layout:  ▲ 1.2 MB/s
    ///          ▼ 340 KB/s
    private func createStackedImage(upStr: String, downStr: String) -> NSImage {
        let font = NSFont.monospacedDigitSystemFont(ofSize: 9, weight: .regular)
        let arrowFont = NSFont.systemFont(ofSize: 7, weight: .medium)

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .left
        paragraphStyle.lineSpacing = 0
        paragraphStyle.paragraphSpacing = 0

        // Use label color for good light/dark mode support
        let textAttrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.labelColor,
            .paragraphStyle: paragraphStyle
        ]

        let arrowUpAttrs: [NSAttributedString.Key: Any] = [
            .font: arrowFont,
            .foregroundColor: NSColor.systemGreen,
            .paragraphStyle: paragraphStyle
        ]

        let arrowDownAttrs: [NSAttributedString.Key: Any] = [
            .font: arrowFont,
            .foregroundColor: NSColor.systemBlue,
            .paragraphStyle: paragraphStyle
        ]

        // Measure text to determine image width
        let upText = NSAttributedString(string: upStr, attributes: textAttrs)
        let downText = NSAttributedString(string: downStr, attributes: textAttrs)
        let arrowUp = NSAttributedString(string: "▲", attributes: arrowUpAttrs)
        let arrowDown = NSAttributedString(string: "▼", attributes: arrowDownAttrs)

        let arrowWidth: CGFloat = 9
        let textWidth = max(upText.size().width, downText.size().width)
        let totalWidth = arrowWidth + textWidth + 2

        let imageHeight: CGFloat = menuBarHeight
        let imageSize = NSSize(width: totalWidth, height: imageHeight)

        let image = NSImage(size: imageSize, flipped: false) { rect in
            // Row heights: split the menu bar into two rows
            let rowHeight: CGFloat = imageHeight / 2.0

            // Top row: upload (▲ speed)
            let topY = rowHeight + 1  // top half
            let bottomY: CGFloat = 0  // bottom half

            // Draw upload arrow and text (top row)
            arrowUp.draw(at: NSPoint(x: 0, y: topY + 1))
            upText.draw(at: NSPoint(x: arrowWidth, y: topY))

            // Draw download arrow and text (bottom row)
            arrowDown.draw(at: NSPoint(x: 0, y: bottomY + 1))
            downText.draw(at: NSPoint(x: arrowWidth, y: bottomY))

            return true
        }

        image.isTemplate = false
        return image
    }

    /// Compact format for menu bar: adaptive decimals, no spaces
    /// e.g. "0 B/s", "156KB", "4.2MB", "1.1GB"
    private func formatSpeedCompact(_ bytesPerSecond: Double) -> String {
        if bytesPerSecond < 1024 {
            return "0KB/s"
        }

        let kb = bytesPerSecond / 1024
        if kb < 1000 {
            return String(format: "%.0fKB/s", kb)
        }

        let mb = bytesPerSecond / (1024 * 1024)
        if mb < 100 {
            return String(format: "%.1fMB/s", mb)
        }
        if mb < 1000 {
            return String(format: "%.0fMB/s", mb)
        }

        let gb = bytesPerSecond / (1024 * 1024 * 1024)
        if gb < 100 {
            return String(format: "%.1fGB/s", gb)
        }
        return String(format: "%.0fGB/s", gb)
    }

    /// Verbose format for dropdown menu with more detail
    private func formatSpeedVerbose(_ bytesPerSecond: Double) -> String {
        if bytesPerSecond < 1024 {
            return String(format: "%.0f B/s", bytesPerSecond)
        }

        let kb = bytesPerSecond / 1024
        if kb < 1000 {
            return String(format: "%.1f KB/s", kb)
        }

        let mb = bytesPerSecond / (1024 * 1024)
        if mb < 100 {
            return String(format: "%.2f MB/s", mb)
        }
        if mb < 1000 {
            return String(format: "%.1f MB/s", mb)
        }

        let gb = bytesPerSecond / (1024 * 1024 * 1024)
        return String(format: "%.2f GB/s", gb)
    }

    private func formatBytes(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .binary
        return formatter.string(fromByteCount: Int64(bytes))
    }

    // MARK: - Launch at Login

    @objc private func toggleLaunchAtLogin(_ sender: NSMenuItem) {
        let newState = sender.state == .off
        setLaunchAtLogin(enabled: newState)
        sender.state = newState ? .on : .off
    }

    private func isLaunchAtLoginEnabled() -> Bool {
        if #available(macOS 13.0, *) {
            return SMAppService.mainApp.status == .enabled
        }
        return false
    }

    private func setLaunchAtLogin(enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("Failed to \(enabled ? "enable" : "disable") launch at login: \(error)")
            }
        }
    }

    @objc private func quitApp() {
        NSApplication.shared.terminate(self)
    }
}
