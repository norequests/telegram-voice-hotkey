import Foundation
import CTDLib

/// Wraps TDLib JSON client for sending messages as the authenticated user.
class TelegramClient {
    private let clientId: Int32
    private var running = false
    private let queue = DispatchQueue(label: "tdlib.receive", qos: .background)

    // Auth state
    enum AuthState {
        case waitingForPhone
        case waitingForCode
        case waitingForPassword
        case ready
        case closed
    }

    var authState: AuthState = .waitingForPhone
    var onAuthStateChanged: ((AuthState) -> Void)?
    var onError: ((String) -> Void)?

    // Telegram API credentials (get from https://my.telegram.org)
    private let apiId: Int
    private let apiHash: String

    init(apiId: Int, apiHash: String) {
        self.apiId = apiId
        self.apiHash = apiHash
        self.clientId = td_create_client_id()
    }

    func start() {
        running = true

        // Set TDLib parameters
        send([
            "@type": "setTdlibParameters",
            "database_directory": tdlibDataDir(),
            "use_message_database": true,
            "use_secret_chats": false,
            "api_id": apiId,
            "api_hash": apiHash,
            "system_language_code": "en",
            "device_model": "macOS",
            "application_version": "1.0.0",
        ])

        // Start receive loop
        queue.async { [weak self] in
            self?.receiveLoop()
        }
    }

    func stop() {
        running = false
        send(["@type": "close"])
    }

    // MARK: - Auth

    func sendPhoneNumber(_ phone: String) {
        send([
            "@type": "setAuthenticationPhoneNumber",
            "phone_number": phone,
        ])
    }

    func sendCode(_ code: String) {
        send([
            "@type": "checkAuthenticationCode",
            "code": code,
        ])
    }

    func sendPassword(_ password: String) {
        send([
            "@type": "checkAuthenticationPassword",
            "password": password,
        ])
    }

    // MARK: - Send Voice Note

    func sendVoiceNote(chatId: Int64, filePath: String, duration: Int, completion: @escaping (Bool) -> Void) {
        let requestId = UUID().uuidString
        send([
            "@type": "sendMessage",
            "@extra": requestId,
            "chat_id": chatId,
            "input_message_content": [
                "@type": "inputMessageVoiceNote",
                "voice_note": [
                    "@type": "inputFileLocal",
                    "path": filePath,
                ],
                "duration": duration,
            ],
        ])
        // For simplicity, assume success after a short delay
        // In production, track @extra to match response
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            completion(true)
        }
    }

    // MARK: - Get chat by username/title

    func searchChat(username: String, completion: @escaping (Int64?) -> Void) {
        let extra = UUID().uuidString
        send([
            "@type": "searchPublicChat",
            "@extra": extra,
            "username": username,
        ])
        // Simplified — in production, track responses by @extra
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            completion(nil) // Would parse from response
        }
    }

    // MARK: - Internal

    private func send(_ dict: [String: Any]) {
        guard let data = try? JSONSerialization.data(withJSONObject: dict),
              let json = String(data: data, encoding: .utf8) else { return }
        td_send(clientId, json)
    }

    private func receiveLoop() {
        while running {
            guard let resultPtr = td_receive(1.0) else { continue }
            let json = String(cString: resultPtr)

            guard let data = json.data(using: .utf8),
                  let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let type = dict["@type"] as? String else { continue }

            handleUpdate(type: type, data: dict)
        }
    }

    private func handleUpdate(type: String, data: [String: Any]) {
        switch type {
        case "updateAuthorizationState":
            guard let authState = data["authorization_state"] as? [String: Any],
                  let stateType = authState["@type"] as? String else { return }

            switch stateType {
            case "authorizationStateWaitPhoneNumber":
                updateAuthState(.waitingForPhone)
            case "authorizationStateWaitCode":
                updateAuthState(.waitingForCode)
            case "authorizationStateWaitPassword":
                updateAuthState(.waitingForPassword)
            case "authorizationStateReady":
                updateAuthState(.ready)
                log("✅ Telegram User API: logged in")
            case "authorizationStateClosed":
                updateAuthState(.closed)
            default:
                break
            }

        case "error":
            let msg = data["message"] as? String ?? "Unknown error"
            log("❌ TDLib error: \(msg)")
            DispatchQueue.main.async { self.onError?(msg) }

        default:
            break
        }
    }

    private func updateAuthState(_ state: AuthState) {
        DispatchQueue.main.async {
            self.authState = state
            self.onAuthStateChanged?(state)
        }
    }

    private func tdlibDataDir() -> String {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("TelegramVoiceHotkey/tdlib")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.path
    }

    var isLoggedIn: Bool {
        authState == .ready
    }
}
