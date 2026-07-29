#!/usr/bin/swift

import Cocoa

// All required macOS icon sizes (pixels)
let iconSizes: [(size: Int, scale: Int, name: String)] = [
    (16, 1, "icon_16x16"),
    (16, 2, "icon_16x16@2x"),
    (32, 1, "icon_32x32"),
    (32, 2, "icon_32x32@2x"),
    (128, 1, "icon_128x128"),
    (128, 2, "icon_128x128@2x"),
    (256, 1, "icon_256x256"),
    (256, 2, "icon_256x256@2x"),
    (512, 1, "icon_512x512"),
    (512, 2, "icon_512x512@2x"),
]

func drawIcon(in rect: NSRect) {
    let size = rect.size.width

    // === Background: Rounded rect with blue-teal gradient ===
    let cornerRadius = size * 0.22
    let bgPath = NSBezierPath(roundedRect: rect.insetBy(dx: size * 0.02, dy: size * 0.02), xRadius: cornerRadius, yRadius: cornerRadius)

    let gradient = NSGradient(colors: [
        NSColor(calibratedRed: 0.10, green: 0.45, blue: 0.90, alpha: 1.0),  // Blue top
        NSColor(calibratedRed: 0.05, green: 0.75, blue: 0.85, alpha: 1.0),  // Teal bottom
    ], atLocations: [0.0, 1.0], colorSpace: .deviceRGB)!

    gradient.draw(in: bgPath, angle: -45)

    // === Subtle inner shadow for depth ===
    let innerShadow = NSShadow()
    innerShadow.shadowColor = NSColor(white: 0, alpha: 0.15)
    innerShadow.shadowOffset = NSSize(width: 0, height: -size * 0.01)
    innerShadow.shadowBlurRadius = size * 0.03

    // === Draw up arrow (▲) ===
    let arrowColor = NSColor.white
    let arrowShadow = NSShadow()
    arrowShadow.shadowColor = NSColor(white: 0, alpha: 0.25)
    arrowShadow.shadowOffset = NSSize(width: 0, height: -size * 0.01)
    arrowShadow.shadowBlurRadius = size * 0.02

    NSGraphicsContext.saveGraphicsState()
    arrowShadow.set()

    // Up arrow - positioned in the upper portion
    let upArrowPath = NSBezierPath()
    let upCenterX = size * 0.5
    let upTopY = size * 0.78
    let upArrowWidth = size * 0.28
    let upArrowHeight = size * 0.18
    let upStemWidth = size * 0.10
    let upStemHeight = size * 0.12

    // Arrow head
    upArrowPath.move(to: NSPoint(x: upCenterX, y: upTopY))
    upArrowPath.line(to: NSPoint(x: upCenterX - upArrowWidth / 2, y: upTopY - upArrowHeight))
    upArrowPath.line(to: NSPoint(x: upCenterX - upStemWidth / 2, y: upTopY - upArrowHeight))
    // Stem
    upArrowPath.line(to: NSPoint(x: upCenterX - upStemWidth / 2, y: upTopY - upArrowHeight - upStemHeight))
    upArrowPath.line(to: NSPoint(x: upCenterX + upStemWidth / 2, y: upTopY - upArrowHeight - upStemHeight))
    upArrowPath.line(to: NSPoint(x: upCenterX + upStemWidth / 2, y: upTopY - upArrowHeight))
    // Other side of arrow head
    upArrowPath.line(to: NSPoint(x: upCenterX + upArrowWidth / 2, y: upTopY - upArrowHeight))
    upArrowPath.close()

    arrowColor.setFill()
    upArrowPath.fill()

    NSGraphicsContext.restoreGraphicsState()

    // === Draw down arrow (▼) ===
    NSGraphicsContext.saveGraphicsState()
    arrowShadow.set()

    let downArrowPath = NSBezierPath()
    let downCenterX = size * 0.5
    let downBottomY = size * 0.22
    let downArrowWidth = size * 0.28
    let downArrowHeight = size * 0.18
    let downStemWidth = size * 0.10
    let downStemHeight = size * 0.12

    // Arrow head (pointing down)
    downArrowPath.move(to: NSPoint(x: downCenterX, y: downBottomY))
    downArrowPath.line(to: NSPoint(x: downCenterX - downArrowWidth / 2, y: downBottomY + downArrowHeight))
    downArrowPath.line(to: NSPoint(x: downCenterX - downStemWidth / 2, y: downBottomY + downArrowHeight))
    // Stem
    downArrowPath.line(to: NSPoint(x: downCenterX - downStemWidth / 2, y: downBottomY + downArrowHeight + downStemHeight))
    downArrowPath.line(to: NSPoint(x: downCenterX + downStemWidth / 2, y: downBottomY + downArrowHeight + downStemHeight))
    downArrowPath.line(to: NSPoint(x: downCenterX + downStemWidth / 2, y: downBottomY + downArrowHeight))
    // Other side of arrow head
    downArrowPath.line(to: NSPoint(x: downCenterX + downArrowWidth / 2, y: downBottomY + downArrowHeight))
    downArrowPath.close()

    arrowColor.withAlphaComponent(0.85).setFill()
    downArrowPath.fill()

    NSGraphicsContext.restoreGraphicsState()

    // === Horizontal divider line between arrows ===
    let dividerY = size * 0.50
    let dividerPath = NSBezierPath()
    dividerPath.move(to: NSPoint(x: size * 0.25, y: dividerY))
    dividerPath.line(to: NSPoint(x: size * 0.75, y: dividerY))
    dividerPath.lineWidth = size * 0.015
    NSColor.white.withAlphaComponent(0.4).setStroke()
    dividerPath.stroke()
}

// Get the output directory from args or use current directory
let outputDir: String
if CommandLine.arguments.count > 1 {
    outputDir = CommandLine.arguments[1]
} else {
    outputDir = FileManager.default.currentDirectoryPath
}

// Create iconset directory
let iconsetPath = (outputDir as NSString).appendingPathComponent("AppIcon.iconset")
try? FileManager.default.createDirectory(atPath: iconsetPath, withIntermediateDirectories: true)

for entry in iconSizes {
    let pixelSize = entry.size * entry.scale
    let drawSize = NSSize(width: pixelSize, height: pixelSize)

    let image = NSImage(size: drawSize)
    image.lockFocus()

    // Set up high-quality rendering
    let ctx = NSGraphicsContext.current!
    ctx.imageInterpolation = .high
    ctx.shouldAntialias = true

    drawIcon(in: NSRect(origin: .zero, size: drawSize))

    image.unlockFocus()

    // Save as PNG
    guard let tiffData = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiffData),
          let pngData = bitmap.representation(using: .png, properties: [:]) else {
        print("Failed to generate \(entry.name)")
        continue
    }

    let filePath = (iconsetPath as NSString).appendingPathComponent("\(entry.name).png")
    try! pngData.write(to: URL(fileURLWithPath: filePath))
    print("Generated \(entry.name).png (\(pixelSize)x\(pixelSize)px)")
}

print("\nIconset created at: \(iconsetPath)")
print("Converting to .icns...")

// Convert iconset to icns using iconutil
let icnsPath = (outputDir as NSString).appendingPathComponent("AppIcon.icns")
let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
process.arguments = ["-c", "icns", iconsetPath, "-o", icnsPath]
try! process.run()
process.waitUntilExit()

if process.terminationStatus == 0 {
    print("✅ AppIcon.icns created at: \(icnsPath)")
} else {
    print("❌ Failed to create .icns file")
}
