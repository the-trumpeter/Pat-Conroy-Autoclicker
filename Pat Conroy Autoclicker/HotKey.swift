//
//  HotKey.swift
//  menuBarAppTemplate
//
//  Created by Gill Palmer on 29/8/2025.
//


import Carbon
import SwiftUI
import Carbon.HIToolbox



func keyCodeToString(_ keyCode: UInt16) -> String? {
    var keysDown: UInt32 = 0
    var chars: [UniChar] = [0, 0, 0, 0]
    var realLength: Int = 0

    guard let layout = TISCopyCurrentKeyboardLayoutInputSource()?.takeRetainedValue(),
          let ptr = TISGetInputSourceProperty(layout, kTISPropertyUnicodeKeyLayoutData) else {
        return nil
    }

    let layoutData = unsafeBitCast(ptr, to: UnsafePointer<UCKeyboardLayout>.self)

    let status = UCKeyTranslate(
        layoutData,
        keyCode,
        UInt16(kUCKeyActionDisplay),
        0,
        UInt32(LMGetKbdType()),
        UInt32(kUCKeyTranslateNoDeadKeysBit),
        &keysDown,
        chars.count,
        &realLength,
        &chars
    )

    if status != noErr { return nil }

    return String(utf16CodeUnits: chars, count: realLength)
}

/// Represents a global hotkey (keyCode + modifiers)
struct HotKey {
    let keyCode: UInt16
    let modifiers: NSEvent.ModifierFlags
    let character: String?  // <-- store the actual pressed character

    var description: String {
        // Modifier symbols
        let mods = [
            (modifiers.contains(.command), "⌘"),
            (modifiers.contains(.option), "⌥"),
            (modifiers.contains(.shift), "⇧"),
            (modifiers.contains(.control), "⌃")
        ].compactMap { $0.0 ? $0.1 : nil }.joined()
        
        let char = character?.uppercased() ?? "<?>"
        return mods + char
    }
}

/// Manages registration of global hotkeys via Carbon
final class HotKeyManager {
    static let shared = HotKeyManager()
    
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    private var callback: (() -> Void)?
    
    private init() {}
    
    /// Registers a hotkey. Example: keyCode = kVK_ANSI_A, modifiers = cmdKey + shiftKey
    func registerHotKey(keyCode: UInt32,
                        modifiers: UInt32,
                        handler: @escaping () -> Void) {
        unregisterHotKey()
        
        callback = handler
        
        var eventHotKeyRef: EventHotKeyRef?
        var eventHotKeyID = EventHotKeyID(signature: OSType("HTKY".fourCharCodeValue),
                                          id: 1)
        
        let status = RegisterEventHotKey(keyCode,
                                         modifiers,
                                         eventHotKeyID,
                                         GetApplicationEventTarget(),
                                         0,
                                         &eventHotKeyRef)
        hotKeyRef = eventHotKeyRef
        
        guard status == noErr else {
            print("Hotkey registration failed: \(status)")
            return
        }
        
        // Install event handler
        let eventSpec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                      eventKind: UInt32(kEventHotKeyPressed))
        
        InstallEventHandler(GetApplicationEventTarget(), { (_, event, refcon) -> OSStatus in
            guard let refcon else { return noErr }
            let manager = Unmanaged<HotKeyManager>.fromOpaque(refcon).takeUnretainedValue()
            manager.callback?()
            return noErr
        }, 1, [eventSpec], UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()), &eventHandler)

    }
    
    func unregisterHotKey() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
        if let eventHandler {
            RemoveEventHandler(eventHandler)
            self.eventHandler = nil
        }
    }
    
    deinit {
        unregisterHotKey()
    }
}

private extension String {
    var fourCharCodeValue: FourCharCode {
        var result: FourCharCode = 0
        for char in utf16 {
            result = (result << 8) + FourCharCode(char)
        }
        return result
    }
}




extension NSEvent.ModifierFlags {
    var carbonFlags: UInt32 {
        var carbon: UInt32 = 0
        if contains(.command) { carbon |= UInt32(cmdKey) }
        if contains(.option)  { carbon |= UInt32(optionKey) }
        if contains(.shift)   { carbon |= UInt32(shiftKey) }
        if contains(.control) { carbon |= UInt32(controlKey) }
        return carbon
    }
}


struct KeyCaptureView: NSViewRepresentable {
    @Binding var recording: Bool
    @Binding var hotKey: HotKey?
    var onHotKey: () -> Void
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            guard recording else { return event }

            // Capture the key
            let char = event.charactersIgnoringModifiers
            let mods = event.modifierFlags.intersection([.command, .option, .shift, .control])
            
            hotKey = HotKey(
                keyCode: event.keyCode,
                modifiers: mods,
                character: char
            )
            
            // Register with Carbon
            HotKeyManager.shared.registerHotKey(
                keyCode: UInt32(event.keyCode),
                modifiers: mods.carbonFlags
            ) {
                onHotKey()
            }
            
            recording = false
            return nil // swallow event
        }
        
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
}
