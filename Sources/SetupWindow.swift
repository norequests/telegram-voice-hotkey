import Cocoa

class SetupWindowController: NSWindowController, NSWindowDelegate {
    var onComplete: ((Config) -> Void)?

    private let botTokenField = NSTextField()
    private let chatIdField = NSTextField()
    private let hotkeyField = HotkeyRecorderView(frame: .zero)
    private let modePopup = NSPopUpButton()
    private let launchAtLoginCheck = NSButton(checkboxWithTitle: "Launch at login", target: nil, action: nil)

    convenience init(existing: Config, onComplete: @escaping (Config) -> Void) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 300),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Telegram Voice Hotkey"
        window.center()

        self.init(window: window)
        self.onComplete = onComplete
        window.delegate = self

        let view = NSView(frame: window.contentView!.bounds)
        view.autoresizingMask = [.width, .height]

        var y = 255

        // Bot Token
        let tokenLabel = makeLabel("Bot Token:")
        tokenLabel.frame = NSRect(x: 20, y: y, width: 90, height: 20)
        view.addSubview(tokenLabel)

        botTokenField.frame = NSRect(x: 115, y: y - 2, width: 385, height: 24)
        botTokenField.placeholderString = "123456:ABC-DEF..."
        botTokenField.stringValue = existing.botToken
        botTokenField.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        botTokenField.usesSingleLineMode = true
        botTokenField.cell?.isScrollable = true
        view.addSubview(botTokenField)
        y -= 40

        // Chat ID
        let chatLabel = makeLabel("Chat ID:")
        chatLabel.frame = NSRect(x: 20, y: y, width: 90, height: 20)
        view.addSubview(chatLabel)

        chatIdField.frame = NSRect(x: 115, y: y - 2, width: 385, height: 24)
        chatIdField.placeholderString = "Your Telegram chat ID"
        chatIdField.stringValue = existing.chatId
        chatIdField.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        chatIdField.usesSingleLineMode = true
        chatIdField.cell?.isScrollable = true
        view.addSubview(chatIdField)
        y -= 40

        // Hotkey recorder
        let hotkeyLabel = makeLabel("Hotkey:")
        hotkeyLabel.frame = NSRect(x: 20, y: y, width: 90, height: 20)
        view.addSubview(hotkeyLabel)

        hotkeyField.frame = NSRect(x: 115, y: y - 4, width: 200, height: 28)
        if !existing.hotkeyDisplay.isEmpty {
            hotkeyField.title = existing.hotkeyDisplay
            hotkeyField.recordedHotkey = HotkeyRecorderView.RecordedHotkey(
                keyCode: existing.hotkeyKeyCode,
                modifiers: existing.hotkeyModifiers,
                displayString: existing.hotkeyDisplay
            )
        }
        view.addSubview(hotkeyField)
        y -= 40

        // Recording mode
        let modeLabel = makeLabel("Mode:")
        modeLabel.frame = NSRect(x: 20, y: y, width: 90, height: 20)
        view.addSubview(modeLabel)

        modePopup.frame = NSRect(x: 115, y: y - 2, width: 385, height: 24)
        modePopup.addItems(withTitles: [
            "Hold to record (release sends)",
            "Press to start, any key stops"
        ])
        modePopup.selectItem(at: existing.recordingMode == .pressToToggle ? 1 : 0)
        view.addSubview(modePopup)
        y -= 35

        // Launch at login
        launchAtLoginCheck.frame = NSRect(x: 115, y: y, width: 380, height: 20)
        launchAtLoginCheck.state = existing.launchAtLogin ? .on : .off
        view.addSubview(launchAtLoginCheck)
        y -= 15

        // Help text
        let helpLabel = makeLabel("Click the hotkey button, then press your desired shortcut.", bold: false, size: 11)
        helpLabel.textColor = .secondaryLabelColor
        helpLabel.frame = NSRect(x: 20, y: y, width: 480, height: 18)
        view.addSubview(helpLabel)

        // Save button — anchored at bottom with breathing room
        let saveButton = NSButton(title: "Save & Start", target: self, action: #selector(saveConfig))
        saveButton.frame = NSRect(x: 380, y: 15, width: 120, height: 36)
        saveButton.bezelStyle = .rounded
        saveButton.keyEquivalent = "\r"
        view.addSubview(saveButton)

        window.contentView = view
    }

    @objc func saveConfig() {
        let token = botTokenField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        let chatId = chatIdField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !token.isEmpty, !chatId.isEmpty else {
            let alert = NSAlert()
            alert.messageText = "Missing fields"
            alert.informativeText = "Bot token and chat ID are required."
            alert.runModal()
            return
        }

        guard let recorded = hotkeyField.recordedHotkey, !recorded.displayString.isEmpty else {
            let alert = NSAlert()
            alert.messageText = "No hotkey set"
            alert.informativeText = "Click the hotkey field and press your desired shortcut."
            alert.runModal()
            return
        }

        let mode: RecordingMode = modePopup.indexOfSelectedItem == 1 ? .pressToToggle : .holdToRecord
        let launchAtLogin = launchAtLoginCheck.state == .on

        let config = Config(
            botToken: token,
            chatId: chatId,
            hotkeyKeyCode: recorded.keyCode,
            hotkeyModifiers: recorded.modifiers,
            hotkeyDisplay: recorded.displayString,
            recordingMode: mode,
            launchAtLogin: launchAtLogin
        )
        config.save()
        onComplete?(config)
        close()
    }

    private func makeLabel(_ text: String, bold: Bool = false, size: CGFloat = 13) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.font = bold ? .boldSystemFont(ofSize: size) : .systemFont(ofSize: size)
        return label
    }
}
