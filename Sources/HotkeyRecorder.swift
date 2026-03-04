import Cocoa
import Carbon.HIToolbox

/// A text field that captures keyboard shortcuts when focused.
/// Click the field, press your combo (e.g. ⌘⇧V), and it records it.
class HotkeyRecorderField: NSTextField {
    var onRecorded: ((RecordedHotkey) -> Void)?
    var recordedHotkey: RecordedHotkey?

    private var localMonitor: Any?

    struct RecordedHotkey: Codable, Equatable {
        var keyCode: UInt16
        var modifiers: UInt  // NSEvent.ModifierFlags.rawValue
        var displayString: String

        var hasModifiers: Bool {
            modifiers != 0
        }
    }

    override func becomeFirstResponder() -> Bool {
        let result = super.becomeFirstResponder()
        if result {
            self.stringValue = "Press shortcut..."
            self.textColor = .placeholderTextColor
            startListening()
        }
        return result
    }

    override func resignFirstResponder() -> Bool {
        stopListening()
        if let hk = recordedHotkey {
            self.stringValue = hk.displayString
            self.textColor = .labelColor
        } else {
            self.stringValue = "Click to record"
            self.textColor = .placeholderTextColor
        }
        return super.resignFirstResponder()
    }

    private func startListening() {
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            self?.handleKeyEvent(event)
            return nil // consume the event
        }
    }

    private func stopListening() {
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
            localMonitor = nil
        }
    }

    private func handleKeyEvent(_ event: NSEvent) {
        let mods = event.modifierFlags.intersection(.deviceIndependentFlagsMask)

        // Build display string
        var parts: [String] = []
        if mods.contains(.control) { parts.append("⌃") }
        if mods.contains(.option)  { parts.append("⌥") }
        if mods.contains(.shift)   { parts.append("⇧") }
        if mods.contains(.command) { parts.append("⌘") }

        // Get key name
        let keyName = keyCodeToString(event.keyCode)
        parts.append(keyName)

        let display = parts.joined()

        let hotkey = RecordedHotkey(
            keyCode: event.keyCode,
            modifiers: mods.rawValue,
            displayString: display
        )

        self.recordedHotkey = hotkey
        self.stringValue = display
        self.textColor = .labelColor
        onRecorded?(hotkey)

        // Resign focus after recording
        self.window?.makeFirstResponder(nil)
    }

    private func keyCodeToString(_ keyCode: UInt16) -> String {
        // Function keys
        let fKeys: [UInt16: String] = [
            UInt16(kVK_F1): "F1", UInt16(kVK_F2): "F2", UInt16(kVK_F3): "F3",
            UInt16(kVK_F4): "F4", UInt16(kVK_F5): "F5", UInt16(kVK_F6): "F6",
            UInt16(kVK_F7): "F7", UInt16(kVK_F8): "F8", UInt16(kVK_F9): "F9",
            UInt16(kVK_F10): "F10", UInt16(kVK_F11): "F11", UInt16(kVK_F12): "F12",
            UInt16(kVK_F13): "F13", UInt16(kVK_F14): "F14", UInt16(kVK_F15): "F15",
            UInt16(kVK_F16): "F16", UInt16(kVK_F17): "F17", UInt16(kVK_F18): "F18",
            UInt16(kVK_F19): "F19", UInt16(kVK_F20): "F20",
        ]
        if let name = fKeys[keyCode] { return name }

        // Special keys
        let special: [UInt16: String] = [
            UInt16(kVK_Space): "Space", UInt16(kVK_Return): "Return",
            UInt16(kVK_Tab): "Tab", UInt16(kVK_Delete): "Delete",
            UInt16(kVK_Escape): "Esc", UInt16(kVK_UpArrow): "↑",
            UInt16(kVK_DownArrow): "↓", UInt16(kVK_LeftArrow): "←",
            UInt16(kVK_RightArrow): "→",
        ]
        if let name = special[keyCode] { return name }

        // Regular character — use InputSource to get the character
        let source = TISCopyCurrentKeyboardInputSource().takeRetainedValue()
        guard let layoutDataRef = TISGetInputSourceProperty(source, kTISPropertyUnicodeKeyLayoutData) else {
            return "Key\(keyCode)"
        }
        let layoutData = unsafeBitCast(layoutDataRef, to: CFData.self) as Data
        var deadKeyState: UInt32 = 0
        var chars = [UniChar](repeating: 0, count: 4)
        var length = 0

        layoutData.withUnsafeBytes { ptr in
            guard let basePtr = ptr.baseAddress else { return }
            let layoutPtr = basePtr.assumingMemoryBound(to: UCKeyboardLayout.self)
            UCKeyTranslate(
                layoutPtr,
                keyCode,
                UInt16(kUCKeyActionDown),
                0, // no modifiers for the base character
                UInt32(LMGetKbdType()),
                UInt32(kUCKeyTranslateNoDeadKeysBit),
                &deadKeyState,
                chars.count,
                &length,
                &chars
            )
        }

        if length > 0 {
            return String(utf16CodeUnits: chars, count: length).uppercased()
        }

        return "Key\(keyCode)"
    }
}
