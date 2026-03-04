import Cocoa
import Carbon.HIToolbox

/// A button-style view that captures keyboard shortcuts when clicked.
/// Click it, press your combo (e.g. ⌘⇧V), and it records it.
class HotkeyRecorderView: NSButton {
    var onRecorded: ((RecordedHotkey) -> Void)?
    var recordedHotkey: RecordedHotkey?
    private var isListening = false
    private var globalMonitor: Any?
    private var localMonitor: Any?

    struct RecordedHotkey: Codable, Equatable {
        var keyCode: UInt16
        var modifiers: UInt  // NSEvent.ModifierFlags.rawValue
        var displayString: String
    }

    override init(frame: NSRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        self.bezelStyle = .rounded
        self.title = "Click to record"
        self.target = self
        self.action = #selector(startListening)
        self.focusRingType = .exterior
    }

    @objc func startListening() {
        guard !isListening else {
            stopListening()
            return
        }
        isListening = true
        self.title = "Press shortcut..."

        // Listen for key events
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKeyEvent(event)
            return nil
        }

        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKeyEvent(event)
        }

        // Escape to cancel
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == UInt16(kVK_Escape) {
                self?.stopListening()
                return nil
            }
            return event
        }
    }

    private func stopListening() {
        isListening = false
        if let m = localMonitor { NSEvent.removeMonitor(m); localMonitor = nil }
        if let m = globalMonitor { NSEvent.removeMonitor(m); globalMonitor = nil }

        if let hk = recordedHotkey {
            self.title = hk.displayString
        } else {
            self.title = "Click to record"
        }
    }

    private func handleKeyEvent(_ event: NSEvent) {
        // Ignore bare modifier keys and escape
        if event.keyCode == UInt16(kVK_Escape) {
            stopListening()
            return
        }

        let mods = event.modifierFlags.intersection(.deviceIndependentFlagsMask)

        var parts: [String] = []
        if mods.contains(.control) { parts.append("⌃") }
        if mods.contains(.option)  { parts.append("⌥") }
        if mods.contains(.shift)   { parts.append("⇧") }
        if mods.contains(.command) { parts.append("⌘") }

        let keyName = keyCodeToString(event.keyCode)
        parts.append(keyName)

        let display = parts.joined()

        let hotkey = RecordedHotkey(
            keyCode: event.keyCode,
            modifiers: mods.rawValue,
            displayString: display
        )

        self.recordedHotkey = hotkey
        onRecorded?(hotkey)
        stopListening()
    }

    private func keyCodeToString(_ keyCode: UInt16) -> String {
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

        let special: [UInt16: String] = [
            UInt16(kVK_Space): "Space", UInt16(kVK_Return): "Return",
            UInt16(kVK_Tab): "Tab", UInt16(kVK_Delete): "Delete",
            UInt16(kVK_Escape): "Esc", UInt16(kVK_UpArrow): "↑",
            UInt16(kVK_DownArrow): "↓", UInt16(kVK_LeftArrow): "←",
            UInt16(kVK_RightArrow): "→",
        ]
        if let name = special[keyCode] { return name }

        // Regular character
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
                layoutPtr, keyCode, UInt16(kUCKeyActionDown), 0,
                UInt32(LMGetKbdType()), UInt32(kUCKeyTranslateNoDeadKeysBit),
                &deadKeyState, chars.count, &length, &chars
            )
        }

        if length > 0 {
            return String(utf16CodeUnits: chars, count: length).uppercased()
        }
        return "Key\(keyCode)"
    }
}
