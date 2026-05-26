import Cocoa
import SwiftUI

@MainActor
public class FloatingPanel: NSPanel {
    public init(contentRect: NSRect, backing: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(
            contentRect: contentRect,
            styleMask: [.nonactivatingPanel, .fullSizeContentView],
            backing: backing,
            defer: flag
        )
        
        self.isFloatingPanel = true
        self.level = .statusBar
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        self.backgroundColor = .white
        self.hasShadow = true
        self.isOpaque = true
        self.ignoresMouseEvents = false
        
        // Clean layout without borders/window controls
        self.titleVisibility = .hidden
        self.titlebarAppearsTransparent = true
        self.standardWindowButton(.closeButton)?.isHidden = true
        self.standardWindowButton(.miniaturizeButton)?.isHidden = true
        self.standardWindowButton(.zoomButton)?.isHidden = true
    }
    
    public override var canBecomeKey: Bool {
        return true
    }
    
    public override var canBecomeMain: Bool {
        return false
    }
}

@MainActor
public class PanelController: NSObject, NSWindowDelegate {
    public static let shared = PanelController()
    
    public var panel: FloatingPanel?
    
    private override init() {
        super.init()
    }
    
    public func showPanel<Content: View>(withView view: Content) {
        let initialRect = NSRect(x: 0, y: 0, width: 440, height: 420)
        let currentPanel: FloatingPanel
        
        if let existing = panel {
            currentPanel = existing
        } else {
            currentPanel = FloatingPanel(contentRect: initialRect, backing: .buffered, defer: false)
            currentPanel.delegate = self
            currentPanel.isMovableByWindowBackground = true
            self.panel = currentPanel
        }
        
        // ALWAYS update the content view to display the newly passed view/text
        let hostingView = NSHostingView(rootView: view)
        hostingView.autoresizingMask = [.width, .height]
        currentPanel.contentView = hostingView
        
        // Auto position panel near the cursor
        positionPanelNearMouse()
        
        // Fade in panel and make key
        currentPanel.alphaValue = 0
        currentPanel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.15
            currentPanel.animator().alphaValue = 1.0
        }
    }
    
    public func hidePanel() {
        guard let panel = panel, panel.isVisible else { return }
        
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.12
            panel.animator().alphaValue = 0
        }, completionHandler: {
            panel.orderOut(nil)
        })
    }
    
    public func positionPanelNearMouse() {
        guard let panel = panel else { return }
        let mouseLocation = NSEvent.mouseLocation
        positionPanel(aroundMouseLocation: mouseLocation)
    }
    
    /// Positions the panel safely below the click/mouse location to avoid overlapping the highlighted text.
    public func positionPanel(aroundMouseLocation mouseLocation: NSPoint) {
        guard let panel = panel else { return }
        
        // Find which screen contains the mouse, fallback to main screen
        let screen = NSScreen.screens.first { NSMouseInRect(mouseLocation, $0.frame, false) } ?? NSScreen.main
        guard let activeScreen = screen else { return }
        
        let panelSize = panel.frame.size
        
        // Position panel centered horizontally relative to the mouse, but pushed 35px DOWN vertical to clear the line
        var x = mouseLocation.x - (panelSize.width / 2)
        var y = mouseLocation.y - panelSize.height - 35 // Generous 35px margin below selection to prevent overlapping
        
        // Safety adjustments to keep panel within screen boundaries
        let visibleFrame = activeScreen.visibleFrame
        
        // Adjust horizontal boundary
        if x + panelSize.width > visibleFrame.maxX {
            x = visibleFrame.maxX - panelSize.width - 15
        }
        if x < visibleFrame.minX {
            x = visibleFrame.minX + 15
        }
        
        // Adjust vertical boundary: if pushing it down goes off-screen, show it 35px ABOVE the text line
        if y < visibleFrame.minY {
            y = mouseLocation.y + 35
        }
        if y + panelSize.height > visibleFrame.maxY {
            y = visibleFrame.maxY - panelSize.height - 15
        }
        
        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }
    
    // MARK: - NSWindowDelegate
    
    public func windowDidResignKey(_ notification: Notification) {
        // Automatically hide the HUD panel whenever user clicks outside
        hidePanel()
    }
}
