import Foundation

enum RecordingMode: String, Codable {
    case holdToRecord = "hold"
    case pressToToggle = "toggle"
}

struct Config: Codable {
    var chatId: String
    var hotkeyKeyCode: UInt16
    var hotkeyModifiers: UInt
    var hotkeyDisplay: String
    var recordingMode: RecordingMode
    var launchAtLogin: Bool
    var apiId: Int
    var apiHash: String
    var userLoggedIn: Bool

    init(chatId: String, hotkeyKeyCode: UInt16, hotkeyModifiers: UInt,
         hotkeyDisplay: String, recordingMode: RecordingMode, launchAtLogin: Bool,
         apiId: Int, apiHash: String, userLoggedIn: Bool) {
        self.chatId = chatId; self.hotkeyKeyCode = hotkeyKeyCode
        self.hotkeyModifiers = hotkeyModifiers; self.hotkeyDisplay = hotkeyDisplay
        self.recordingMode = recordingMode; self.launchAtLogin = launchAtLogin
        self.apiId = apiId; self.apiHash = apiHash; self.userLoggedIn = userLoggedIn
    }

    enum CodingKeys: String, CodingKey {
        case chatId, hotkeyKeyCode, hotkeyModifiers, hotkeyDisplay
        case recordingMode, launchAtLogin, apiId, apiHash, userLoggedIn
        // Legacy keys we skip on read
        case botToken, sendMode
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        chatId = try c.decodeIfPresent(String.self, forKey: .chatId) ?? ""
        hotkeyKeyCode = try c.decodeIfPresent(UInt16.self, forKey: .hotkeyKeyCode) ?? 0x60
        hotkeyModifiers = try c.decodeIfPresent(UInt.self, forKey: .hotkeyModifiers) ?? 0
        hotkeyDisplay = try c.decodeIfPresent(String.self, forKey: .hotkeyDisplay) ?? "F5"
        recordingMode = try c.decodeIfPresent(RecordingMode.self, forKey: .recordingMode) ?? .holdToRecord
        launchAtLogin = try c.decodeIfPresent(Bool.self, forKey: .launchAtLogin) ?? false
        apiId = try c.decodeIfPresent(Int.self, forKey: .apiId) ?? 0
        apiHash = try c.decodeIfPresent(String.self, forKey: .apiHash) ?? ""
        userLoggedIn = try c.decodeIfPresent(Bool.self, forKey: .userLoggedIn) ?? false
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(chatId, forKey: .chatId)
        try c.encode(hotkeyKeyCode, forKey: .hotkeyKeyCode)
        try c.encode(hotkeyModifiers, forKey: .hotkeyModifiers)
        try c.encode(hotkeyDisplay, forKey: .hotkeyDisplay)
        try c.encode(recordingMode, forKey: .recordingMode)
        try c.encode(launchAtLogin, forKey: .launchAtLogin)
        try c.encode(apiId, forKey: .apiId)
        try c.encode(apiHash, forKey: .apiHash)
        try c.encode(userLoggedIn, forKey: .userLoggedIn)
    }

    static let configURL: URL = {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("TelegramVoiceHotkey")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("config.json")
    }()

    static let `default` = Config(
        chatId: "",
        hotkeyKeyCode: 0x60,
        hotkeyModifiers: 0,
        hotkeyDisplay: "F5",
        recordingMode: .holdToRecord,
        launchAtLogin: false,
        apiId: 0,
        apiHash: "",
        userLoggedIn: false
    )

    static func load() -> Config {
        guard FileManager.default.fileExists(atPath: configURL.path),
              let data = try? Data(contentsOf: configURL),
              let config = try? JSONDecoder().decode(Config.self, from: data)
        else {
            return .default
        }
        return config
    }

    func save() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        if let data = try? encoder.encode(self) {
            try? data.write(to: Config.configURL)
        }
    }

    var hasCredentials: Bool {
        apiId > 0 && !apiHash.isEmpty
    }

    var isConfigured: Bool {
        hasCredentials && !chatId.isEmpty && userLoggedIn
    }
}
