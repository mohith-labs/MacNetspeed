import Cocoa

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate

// Activate the app so the status item appears
app.setActivationPolicy(.accessory)

app.run()
