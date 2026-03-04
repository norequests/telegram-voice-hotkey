import Foundation

enum RecordingMode: String, Codable {
    case holdToRecord = "hold"
    case pressToToggle = "toggle"
}

enum SendMode: String, Codable {
    case botAPI = "bot"       // Send via Bot API (message appears from bot)
    case userAPI = "user"     // Send via User API/TDLib (message appears from you)
}

struct Config: Codable {
    var botToken: String
    var chatId: String
    var hotkeyKeyCode: UInt16
    var hotkeyModifiers: UInt
    var hotkeyDisplay: String
    var recordingMode: RecordingMode
    var launchAtLogin: Bool
    var sendMode: SendMode
    var apiId: Int
    var apiHash: String
    var userLoggedIn: Bool

    static let configURL: URL = {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("TelegramVoiceHotkey")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("config.json")
    }()

    static let `default` = Config(
        botToken: "",
        chatId: "",
        hotkeyKeyCode: 0x60,
        hotkeyModifiers: 0,
        hotkeyDisplay: "F5",
        recordingMode: .holdToRecord,
        launchAtLogin: false,
        sendMode: .botAPI,
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

    var isConfigured: Bool {
        switch sendMode {
        case .botAPI:
            return !botToken.isEmpty && !chatId.isEmpty
        case .userAPI:
            return apiId > 0 && !apiHash.isEmpty && !chatId.isEmpty && userLoggedIn
        }
    }
}
