import Carbon
import Cocoa

public final class HotKeyManager: @unchecked Sendable {
    public static let shared = HotKeyManager()
    
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?
    private var isRegistered = false
    private var handler: (() -> Void)?
    
    private init() {}
    
    /// Registers the global shortcut Cmd + Shift + E
    public func register(handler: @escaping () -> Void) {
        guard !isRegistered else { return }
        self.handler = handler
        
        // Modifier masks in Carbon:
        // cmdKey   = 0x0100 (256)
        // shiftKey = 0x0200 (512)
        // Cmd + Shift = 0x0300 (768)
        let cmdShiftModifiers: UInt32 = 0x0300
        
        // Virtual Key Code for 'E' is 14 (kVK_ANSI_E)
        let keyCodeE: UInt32 = 14
        
        // Use clean integer four-character code (RMTE: R=0x52, M=0x4D, T=0x54, E=0x45)
        let hotKeyID = EventHotKeyID(signature: 0x524D5445, id: 1)
        var ref: EventHotKeyRef?
        
        let status = RegisterEventHotKey(
            keyCodeE,
            cmdShiftModifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &ref
        )
        
        guard status == noErr, let registeredRef = ref else {
            print("[HotKeyManager] Failed to register Carbon Event Hotkey: \(status)")
            return
        }
        
        self.hotKeyRef = registeredRef
        
        // Install the system event handler for hotkey pressed events
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        
        let eventHandlerCallback: EventHandlerUPP = { (nextHandler, event, userData) -> OSStatus in
            // Handle global hotkey trigger asynchronously on the main runloop
            DispatchQueue.main.async {
                HotKeyManager.shared.handler?()
            }
            return noErr
        }
        
        var handlerRef: EventHandlerRef?
        let handlerStatus = InstallEventHandler(
            GetApplicationEventTarget(),
            eventHandlerCallback,
            1,
            &eventType,
            nil,
            &handlerRef
        )
        
        if handlerStatus == noErr {
            self.eventHandlerRef = handlerRef
            self.isRegistered = true
            print("[HotKeyManager] Global Hotkey Cmd+Shift+E registered successfully.")
        } else {
            print("[HotKeyManager] Failed to install Carbon Event Handler: \(handlerStatus)")
            UnregisterEventHotKey(registeredRef)
        }
    }
    
    public func unregister() {
        guard isRegistered else { return }
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
            hotKeyRef = nil
        }
        if let ref = eventHandlerRef {
            RemoveEventHandler(ref)
            eventHandlerRef = nil
        }
        isRegistered = false
        print("[HotKeyManager] Global Hotkey unregistered.")
    }
    
    deinit {
        unregister()
    }
}
