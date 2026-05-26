import Cocoa
import ApplicationServices

public final class SelectionService: @unchecked Sendable {
    public static let shared = SelectionService()
    
    private init() {}
    
    public func isAccessibilityGranted(prompt: Bool = false) -> Bool {
        let options = ["AXTrustedCheckOptionPrompt": prompt]
        return AXIsProcessTrustedWithOptions(options as CFDictionary)
    }
    
    /// Main entry point to fetch currently selected text.
    public func getSelectedText() -> String? {
        // Try Accessibility API first
        if let text = getSelectedTextViaAccessibility(), !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return text
        }
        
        // Fall back to Clipboard copy simulation
        if let text = getSelectedTextViaClipboardFallback(), !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return text
        }
        
        return nil
    }
    
    /// Attempts to read selection using AXUIElement Accessibility APIs
    public func getSelectedTextViaAccessibility() -> String? {
        guard isAccessibilityGranted() else { return nil }
        
        let systemWide = AXUIElementCreateSystemWide()
        var focusedElement: AnyObject?
        
        let err = AXUIElementCopyAttributeValue(systemWide, kAXFocusedUIElementAttribute as CFString, &focusedElement)
        guard err == .success, let element = focusedElement as! AXUIElement? else {
            return nil
        }
        
        var selectedText: AnyObject?
        let textErr = AXUIElementCopyAttributeValue(element, kAXSelectedTextAttribute as CFString, &selectedText)
        
        if textErr == .success, let text = selectedText as? String {
            return text
        }
        
        return nil
    }
    
    // Structure to preserve all clipboard content forms (images, text, rich types)
    private struct SavedPasteboardItem {
        let types: [NSPasteboard.PasteboardType]
        let data: [NSPasteboard.PasteboardType: Data]
    }
    
    /// Fallback that simulates Cmd+C and reads pasteboard, preserving previous pasteboard contents
    private func getSelectedTextViaClipboardFallback() -> String? {
        let pasteboard = NSPasteboard.general
        let originalChangeCount = pasteboard.changeCount
        
        // 1. Back up current clipboard items and all associated data types
        var savedItems = [SavedPasteboardItem]()
        if let items = pasteboard.pasteboardItems {
            for item in items {
                var dataMap = [NSPasteboard.PasteboardType: Data]()
                for type in item.types {
                    if let data = pasteboard.data(forType: type) {
                        dataMap[type] = data
                    }
                }
                savedItems.append(SavedPasteboardItem(types: item.types, data: dataMap))
            }
        }
        
        // 2. Simulate Command + C
        let source = CGEventSource(stateID: .combinedSessionState)
        let keyC: UInt16 = 0x08 // Virtual key code for 'c'
        
        let cDown = CGEvent(keyboardEventSource: source, virtualKey: keyC, keyDown: true)
        cDown?.flags = .maskCommand
        let cUp = CGEvent(keyboardEventSource: source, virtualKey: keyC, keyDown: false)
        cUp?.flags = .maskCommand
        
        cDown?.post(tap: .cghidEventTap)
        usleep(10000) // Small micro-sleep to separate events
        cUp?.post(tap: .cghidEventTap)
        
        // 3. Wait up to 150ms for clipboard change count to increment
        var textRetrieved: String? = nil
        let checkInterval: useconds_t = 10000 // 10ms
        let maxRetries = 15 // 150ms total
        
        for _ in 0..<maxRetries {
            usleep(checkInterval)
            if pasteboard.changeCount != originalChangeCount {
                if let text = pasteboard.string(forType: .string) {
                    textRetrieved = text
                    break
                }
            }
        }
        
        // 4. Restore original clipboard content
        pasteboard.clearContents()
        for item in savedItems {
            let pbItem = NSPasteboardItem()
            for (type, data) in item.data {
                pbItem.setData(data, forType: type)
            }
            pasteboard.writeObjects([pbItem])
        }
        
        return textRetrieved
    }
}
