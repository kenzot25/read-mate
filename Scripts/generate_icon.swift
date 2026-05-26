import Cocoa

let sizes: [(name: String, size: Int)] = [
    ("icon_16x16", 16),
    ("icon_16x16@2x", 32),
    ("icon_32x32", 32),
    ("icon_32x32@2x", 64),
    ("icon_128x128", 128),
    ("icon_128x128@2x", 256),
    ("icon_256x256", 256),
    ("icon_256x256@2x", 512),
    ("icon_512x512", 512),
    ("icon_512x512@2x", 1024),
]

func drawIcon(size: Int) -> NSImage {
    let s = CGFloat(size)
    let image = NSImage(size: NSSize(width: s, height: s))

    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: size,
        pixelsHigh: size,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )!

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

    let ctx = NSGraphicsContext.current!.cgContext
    let cornerRadius = s * 0.2236
    let rect = CGRect(x: 0, y: 0, width: s, height: s)

    // Clip to rounded rect
    ctx.beginPath()
    ctx.move(to: CGPoint(x: cornerRadius, y: 0))
    ctx.addLine(to: CGPoint(x: s - cornerRadius, y: 0))
    ctx.addArc(center: CGPoint(x: s - cornerRadius, y: cornerRadius), radius: cornerRadius, startAngle: 270, endAngle: 0, clockwise: false)
    ctx.addLine(to: CGPoint(x: s, y: s - cornerRadius))
    ctx.addArc(center: CGPoint(x: s - cornerRadius, y: s - cornerRadius), radius: cornerRadius, startAngle: 0, endAngle: 90, clockwise: false)
    ctx.addLine(to: CGPoint(x: cornerRadius, y: s))
    ctx.addArc(center: CGPoint(x: cornerRadius, y: s - cornerRadius), radius: cornerRadius, startAngle: 90, endAngle: 180, clockwise: false)
    ctx.addLine(to: CGPoint(x: 0, y: cornerRadius))
    ctx.addArc(center: CGPoint(x: cornerRadius, y: cornerRadius), radius: cornerRadius, startAngle: 180, endAngle: 270, clockwise: false)
    ctx.closePath()
    ctx.clip()

    // Blue gradient background
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let gradientColors = [
        CGColor(red: 0.2, green: 0.45, blue: 1.0, alpha: 1.0),
        CGColor(red: 0.08, green: 0.25, blue: 0.85, alpha: 1.0),
    ] as CFArray
    if let gradient = CGGradient(colorsSpace: colorSpace, colors: gradientColors, locations: [0.0, 1.0]) {
        ctx.drawLinearGradient(
            gradient,
            start: CGPoint(x: 0, y: s),
            end: CGPoint(x: s, y: 0),
            options: []
        )
    }

    // Draw sparkles symbol using SF Symbols
    if let sparklesImage = NSImage(systemSymbolName: "sparkles", accessibilityDescription: nil) {
        let pointSize = s * 0.45
        let config = NSImage.SymbolConfiguration(pointSize: pointSize, weight: .bold)
        let configured = sparklesImage.withSymbolConfiguration(config) ?? sparklesImage

        // Tint white by compositing
        let tinted = NSImage(size: configured.size)
        tinted.lockFocus()
        configured.draw(at: .zero, from: NSRect(origin: .zero, size: configured.size), operation: .sourceOver, fraction: 1.0)
        NSColor.white.set()
        NSRect(origin: .zero, size: configured.size).fill(using: .sourceAtop)
        tinted.unlockFocus()

        let imgSize = tinted.size
        let x = (s - imgSize.width) / 2
        let y = (s - imgSize.height) / 2
        tinted.draw(at: NSPoint(x: x, y: y), from: .zero, operation: .sourceOver, fraction: 1.0)
    }

    // Subtle highlight on top edge
    let highlightColors = [
        CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.25),
        CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.0),
    ] as CFArray
    if let highlightGradient = CGGradient(colorsSpace: colorSpace, colors: highlightColors, locations: [0.0, 0.3]) {
        ctx.drawLinearGradient(
            highlightGradient,
            start: CGPoint(x: 0, y: s),
            end: CGPoint(x: 0, y: s * 0.7),
            options: []
        )
    }

    NSGraphicsContext.restoreGraphicsState()
    image.addRepresentation(rep)
    return image
}

let outputDir = "Resources/Assets.xcassets/AppIcon.appiconset"

for item in sizes {
    let image = drawIcon(size: item.size)
    guard let tiffData = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiffData),
          let pngData = bitmap.representation(using: .png, properties: [:]) else {
        print("Failed to generate \(item.name)")
        continue
    }

    let url = URL(fileURLWithPath: "\(outputDir)/\(item.name).png")
    do {
        try pngData.write(to: url)
        print("Generated \(item.name).png (\(item.size)x\(item.size))")
    } catch {
        print("Error writing \(item.name): \(error)")
    }
}

print("Done! Icon PNGs generated in \(outputDir)")