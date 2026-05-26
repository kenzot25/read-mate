import Cocoa
import SwiftUI

@MainActor
public final class FloatingSelectionButtonController: NSObject {
    public static let shared = FloatingSelectionButtonController()
    
    private var panel: NSPanel?
    private var selectedText: String = ""
    private var mouseMonitor: Any?
    private var mouseDownMonitor: Any?
    
    private override init() {
        super.init()
    }
    
    /// Starts monitoring global mouse events to show the selection button
    public func startMonitoring() {
        // Monitor Left Mouse Up (finish selecting text)
        mouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseUp) { [weak self] event in
            guard let self = self else { return }
            self.handleMouseUp()
        }
        
        // Monitor Left Mouse Down (click elsewhere to dismiss button)
        mouseDownMonitor = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDown) { [weak self] event in
            guard let self = self else { return }
            self.hideButton()
        }
    }
    
    /// Stops monitoring
    public func stopMonitoring() {
        if let monitor = mouseMonitor {
            NSEvent.removeMonitor(monitor)
            mouseMonitor = nil
        }
        if let monitor = mouseDownMonitor {
            NSEvent.removeMonitor(monitor)
            mouseDownMonitor = nil
        }
    }
    
    private func handleMouseUp() {
        // Prevent showing if the main HUD panel is already visible
        if let hudPanel = PanelController.shared.panel, hudPanel.isVisible {
            return
        }
        
        // Wait a tiny fraction of a second for system selection state to settle
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) { [weak self] in
            guard let self = self else { return }
            
            // Query selected text silently via Accessibility (no clipboard modification)
            guard SelectionService.shared.isAccessibilityGranted(),
                  let text = SelectionService.shared.getSelectedTextViaAccessibility(),
                  !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                return
            }
            
            // Limit selection length to avoid showing it on massive paragraphs
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard trimmed.count < 300 else { return }
            
            self.selectedText = trimmed
            self.showButtonAtMouse()
        }
    }
    
    private func showButtonAtMouse() {
        let mouseLoc = NSEvent.mouseLocation
        
        // Create panel if it doesn't exist
        if panel == nil {
            let btnSize = NSSize(width: 32, height: 32)
            let newPanel = NSPanel(
                contentRect: NSRect(origin: .zero, size: btnSize),
                styleMask: [.borderless, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            
            newPanel.isOpaque = false
            newPanel.backgroundColor = .clear
            newPanel.hasShadow = true
            newPanel.level = .statusBar
            newPanel.collectionBehavior = [.canJoinAllSpaces, .ignoresCycle]
            
            // Small round glassmorphic button view
            let buttonView = FloatingButtonView { [weak self] in
                self?.onButtonClicked()
            }
            
            newPanel.contentView = NSHostingView(rootView: buttonView)
            self.panel = newPanel
        }
        
        // Position button slightly offset from the mouse pointer (up and to the right)
        if let panel = panel {
            let offsetMouseX = mouseLoc.x + 10
            let offsetMouseY = mouseLoc.y + 10
            
            panel.setFrameOrigin(NSPoint(x: offsetMouseX, y: offsetMouseY))
            panel.orderFrontRegardless()
        }
    }
    
    private func onButtonClicked() {
        let textToExplain = self.selectedText
        hideButton()
        
        // Open the premium SwiftUI HUD loaded with the selected text!
        let hudView = HUDView(initialSelectedText: textToExplain)
        PanelController.shared.showPanel(withView: hudView)
        
        // Center the panel safely near the click position using our screen-aware margin algorithm
        let mouseLoc = NSEvent.mouseLocation
        PanelController.shared.positionPanel(aroundMouseLocation: mouseLoc)
    }
    
    public func hideButton() {
        panel?.orderOut(nil)
    }
}

// MARK: - SwiftUI Button View

struct FloatingButtonView: View {
    let action: () -> Void
    @State private var isHovering = false
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // Bright background for high visibility
                Circle()
                    .fill(isHovering ? Color(red: 0.1, green: 0.35, blue: 0.95) : Color.blue)
                    .frame(width: 28, height: 28)
                    .shadow(color: Color.blue.opacity(0.35), radius: 4, x: 0, y: 2)

                Circle()
                    .stroke(Color.white.opacity(0.5), lineWidth: 1.5)
                    .frame(width: 28, height: 28)

                // Sparkles icon
                Image(systemName: "sparkles")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                self.isHovering = hovering
            }
        }
    }
}
