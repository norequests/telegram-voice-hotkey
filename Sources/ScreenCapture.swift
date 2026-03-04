import Foundation

/// Captures a screenshot silently using macOS screencapture.
class ScreenCapture {

    /// Capture the entire screen (or frontmost window) to a temp file.
    /// Returns the file path on success.
    static func captureScreen(completion: @escaping (String?) -> Void) {
        let tempDir = FileManager.default.temporaryDirectory
        let path = tempDir.appendingPathComponent("screenshot-\(Int(Date().timeIntervalSince1970)).png").path

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
        // -x: no sound, -C: capture cursor, captures full screen
        process.arguments = ["-x", path]

        do {
            try process.run()
            process.waitUntilExit()

            if process.terminationStatus == 0 && FileManager.default.fileExists(atPath: path) {
                log("📸 Screenshot captured: \(path)")
                completion(path)
            } else {
                log("❌ Screenshot capture failed (exit \(process.terminationStatus))")
                completion(nil)
            }
        } catch {
            log("❌ Screenshot error: \(error)")
            completion(nil)
        }
    }
}
