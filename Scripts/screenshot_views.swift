import Cocoa
import SwiftUI

@MainActor
func saveViewAsImage(_ view: some View, size: CGSize, path: String) {
    let image = NSImage(size: size)
    image.lockFocus()

    let hostingView = NSHostingView(rootView: view.frame(width: size.width, height: size.height))
    hostingView.frame = NSRect(origin: .zero, size: size)
    hostingView.layout()
    hostingView.display(hostingView.bounds)

    hostingView.layer?.render(in: NSGraphicsContext.current!.cgContext)

    image.unlockFocus()

    guard let tiff = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiff),
          let png = bitmap.representation(using: .png, properties: [:]) else {
        print("Failed to generate \(path)")
        return
    }

    do {
        try png.write(to: URL(fileURLWithPath: path))
        print("Saved \(path)")
    } catch {
        print("Error writing \(path): \(error)")
    }
}

let outputDir = "screenshots"

// 1. Empty state HUD
let emptyHUD = HUDView(initialSelectedText: "")
saveViewAsImage(emptyHUD, size: CGSize(width: 440, height: 420), path: "\(outputDir)/hud_empty.png")

// 2. Settings panel
let settingsPanel = SettingsPanelView()
saveViewAsImage(settingsPanel, size: CGSize(width: 440, height: 420), path: "\(outputDir)/settings.png")

print("Done!")