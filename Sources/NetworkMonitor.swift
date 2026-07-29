import Foundation

/// Lightweight network speed monitor using the `nettop`-style sysctl approach.
/// Reads byte counters from the system network interfaces and calculates delta speeds.
class NetworkMonitor {

    struct Speeds {
        let download: Double  // bytes per second
        let upload: Double    // bytes per second
    }

    struct Totals {
        let download: UInt64
        let upload: UInt64
    }

    private(set) var activeInterface: String = "--"

    private var previousBytesIn: UInt64 = 0
    private var previousBytesOut: UInt64 = 0
    private var previousTimestamp: TimeInterval = 0

    private var sessionStartBytesIn: UInt64 = 0
    private var sessionStartBytesOut: UInt64 = 0
    private var isFirstReading = true

    private var lastDownloadSpeed: Double = 0
    private var lastUploadSpeed: Double = 0

    init() {
        // Take an initial reading to establish baseline
        let (bytesIn, bytesOut, iface) = readSystemCounters()
        previousBytesIn = bytesIn
        previousBytesOut = bytesOut
        previousTimestamp = ProcessInfo.processInfo.systemUptime
        sessionStartBytesIn = bytesIn
        sessionStartBytesOut = bytesOut
        activeInterface = iface
    }

    /// Returns current network speeds (bytes/sec)
    func currentSpeeds() -> Speeds {
        let now = ProcessInfo.processInfo.systemUptime
        let (bytesIn, bytesOut, iface) = readSystemCounters()

        let elapsed = now - previousTimestamp
        guard elapsed > 0 else {
            return Speeds(download: lastDownloadSpeed, upload: lastUploadSpeed)
        }

        // Handle counter wraps or interface changes
        let deltaIn: UInt64
        let deltaOut: UInt64

        if bytesIn >= previousBytesIn {
            deltaIn = bytesIn - previousBytesIn
        } else {
            deltaIn = bytesIn // Counter wrapped
        }

        if bytesOut >= previousBytesOut {
            deltaOut = bytesOut - previousBytesOut
        } else {
            deltaOut = bytesOut
        }

        let downloadSpeed = Double(deltaIn) / elapsed
        let uploadSpeed = Double(deltaOut) / elapsed

        // Update state
        previousBytesIn = bytesIn
        previousBytesOut = bytesOut
        previousTimestamp = now
        activeInterface = iface
        lastDownloadSpeed = downloadSpeed
        lastUploadSpeed = uploadSpeed

        return Speeds(download: downloadSpeed, upload: uploadSpeed)
    }

    /// Returns total bytes transferred since app launch
    func sessionTotals() -> Totals {
        let (bytesIn, bytesOut, _) = readSystemCounters()

        let totalDown: UInt64
        let totalUp: UInt64

        if bytesIn >= sessionStartBytesIn {
            totalDown = bytesIn - sessionStartBytesIn
        } else {
            totalDown = bytesIn
        }

        if bytesOut >= sessionStartBytesOut {
            totalUp = bytesOut - sessionStartBytesOut
        } else {
            totalUp = bytesOut
        }

        return Totals(download: totalDown, upload: totalUp)
    }

    // MARK: - System Counter Reading

    /// Reads network byte counters from all active interfaces using sysctl/getifaddrs
    private func readSystemCounters() -> (bytesIn: UInt64, bytesOut: UInt64, interface: String) {
        var totalBytesIn: UInt64 = 0
        var totalBytesOut: UInt64 = 0
        var primaryInterface = "--"
        var maxBytes: UInt64 = 0

        var ifaddrPtr: UnsafeMutablePointer<ifaddrs>?

        guard getifaddrs(&ifaddrPtr) == 0, let firstAddr = ifaddrPtr else {
            return (0, 0, "--")
        }

        defer { freeifaddrs(ifaddrPtr) }

        var cursor: UnsafeMutablePointer<ifaddrs>? = firstAddr

        while let addr = cursor {
            let ifaAddr = addr.pointee

            // Only look at AF_LINK (data link layer) entries
            if let sa = ifaAddr.ifa_addr, sa.pointee.sa_family == UInt8(AF_LINK) {
                let name = String(cString: ifaAddr.ifa_name)

                // Skip loopback and virtual interfaces
                if !name.hasPrefix("lo") && !name.hasPrefix("utun") &&
                   !name.hasPrefix("gif") && !name.hasPrefix("stf") &&
                   !name.hasPrefix("awdl") && !name.hasPrefix("llw") &&
                   !name.hasPrefix("bridge") && !name.hasPrefix("ap") &&
                   !name.hasPrefix("anpi") {

                    // Check if interface is up and running
                    let flags = ifaAddr.ifa_flags
                    let isUp = (flags & UInt32(IFF_UP)) != 0
                    let isRunning = (flags & UInt32(IFF_RUNNING)) != 0

                    if isUp && isRunning {
                        // Get the data from if_data
                        if let data = ifaAddr.ifa_data {
                            let networkData = data.assumingMemoryBound(to: if_data.self).pointee
                            let bytesIn = UInt64(networkData.ifi_ibytes)
                            let bytesOut = UInt64(networkData.ifi_obytes)

                            totalBytesIn += bytesIn
                            totalBytesOut += bytesOut

                            // Track which interface has most traffic (primary)
                            let total = bytesIn + bytesOut
                            if total > maxBytes {
                                maxBytes = total
                                primaryInterface = name
                            }
                        }
                    }
                }
            }

            cursor = addr.pointee.ifa_next
        }

        return (totalBytesIn, totalBytesOut, primaryInterface)
    }
}
