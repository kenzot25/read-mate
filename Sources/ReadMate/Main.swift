import Cocoa
import SwiftUI

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Set activation policy to .accessory to run as an agent (no Dock icon, stays in menu bar)
        NSApp.setActivationPolicy(.accessory)
        
        // Initialize the Status Bar icon
        setupStatusItem()
        
        // Register the global hotkey (Cmd + Shift + E)
        registerGlobalHotkey()
        
        // Start monitoring text selection to show floating action button
        FloatingSelectionButtonController.shared.startMonitoring()
        
        print("[AppDelegate] ReadMate successfully launched.")
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // Clean up hotkeys and monitors on termination
        HotKeyManager.shared.unregister()
        FloatingSelectionButtonController.shared.stopMonitoring()
    }
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            if let image = NSImage(systemSymbolName: "sparkles", accessibilityDescription: "ReadMate") {
                image.isTemplate = true // Auto-adapts to Light/Dark mode status bar
                button.image = image
            } else {
                button.title = "✨"
            }
            button.action = #selector(statusItemClicked(_:))
            button.target = self
            // Allow clicking the status item to trigger even when other apps are active
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }
    
    @objc private func statusItemClicked(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent
        
        // Right click opens a quick native backup menu (Quit, Settings link, etc.)
        if event?.type == .rightMouseUp {
            showBackupMenu(sender)
        } else {
            // Left click triggers the premium SwiftUI HUD directly below the status icon
            triggerHUD(anchoredTo: sender)
        }
    }
    
    private func showBackupMenu(_ sender: NSStatusBarButton) {
        let menu = NSMenu()

        let openItem = NSMenuItem(title: "Open ReadMate HUD", action: #selector(menuOpenHUD), keyEquivalent: "")
        openItem.target = self
        menu.addItem(openItem)

        let settingsItem = NSMenuItem(title: "Settings...", action: #selector(menuOpenSettings), keyEquivalent: "")
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit ReadMate", action: #selector(menuQuit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem?.menu = menu
        statusItem?.button?.performClick(nil)

        // Remove menu afterward so subsequent left clicks continue to trigger HUD directly
        statusItem?.menu = nil
    }
    
    @objc private func menuOpenHUD() {
        if let button = statusItem?.button {
            triggerHUD(anchoredTo: button)
        }
    }

    @objc private func menuOpenSettings() {
        let settingsView = SettingsPanelView()
        PanelController.shared.showPanel(withView: settingsView)
        if let panel = PanelController.shared.panel, let button = statusItem?.button, let window = button.window {
            let buttonFrame = window.frame
            let panelSize = panel.frame.size
            let x = buttonFrame.midX - (panelSize.width / 2)
            let y = buttonFrame.minY - panelSize.height - 5
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        }
    }

    @objc private func menuQuit() {
        NSApp.terminate(nil)
    }
    
    /// Registers the global shortcut Cmd + Shift + E to read selection and open HUD
    private func registerGlobalHotkey() {
        HotKeyManager.shared.register { [weak self] in
            guard let self = self else { return }
            print("[AppDelegate] Hotkey triggered.")
            
            // Check accessibility permissions first (if not granted, we'll prompt the user)
            if !SelectionService.shared.isAccessibilityGranted() {
                // If not granted, show HUD anyway so the HUD can display a friendly setup guide
                self.showHUDView(withText: "")
                return
            }
            
            // Fetch selected text system-wide
            let selectedText = SelectionService.shared.getSelectedText() ?? ""
            self.showHUDView(withText: selectedText)
        }
    }
    
    /// Triggers the HUD anchored specifically under the status bar button
    private func triggerHUD(anchoredTo button: NSStatusBarButton) {
        // If HUD is already visible, toggle it off
        if let panel = PanelController.shared.panel, panel.isVisible {
            PanelController.shared.hidePanel()
            return
        }
        
        // Create HUD view
        showHUDView(withText: "", anchoredTo: button)
    }
    
    /// Launches the HUD Panel near the cursor with the specified text
    private func showHUDView(withText text: String) {
        // Build the SwiftUI HUDView container
        let hudView = HUDView(initialSelectedText: text)
        PanelController.shared.showPanel(withView: hudView)
    }
    
    /// Launches the HUD Panel anchored to the status bar button
    private func showHUDView(withText text: String, anchoredTo button: NSStatusBarButton) {
        let hudView = HUDView(initialSelectedText: text)
        PanelController.shared.showPanel(withView: hudView)
        
        // Re-position the panel directly under the status bar icon instead of near the mouse
        if let panel = PanelController.shared.panel, let window = button.window {
            let buttonFrame = window.frame
            let panelSize = panel.frame.size
            
            let x = buttonFrame.midX - (panelSize.width / 2)
            let y = buttonFrame.minY - panelSize.height - 5
            
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        }
    }
}

@main
struct ReadMateApp {
    @MainActor
    static var delegate: AppDelegate?
    
    @MainActor
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        self.delegate = delegate
        app.delegate = delegate
        app.run()
    }
}
