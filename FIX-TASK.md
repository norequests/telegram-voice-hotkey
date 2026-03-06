# Task: Fix Review Issues — Dictation Hotkey

Fix ALL issues found in the code reviews below. This is a Swift/macOS menu bar app.

## MEDIUM — Must Fix

### 1. NSPasteboard write on background thread
**File:** `Sources/App.swift:583-586` (inside `makeDictationClosure`)
The transcription callback from Gemini/custom endpoints runs on a URLSession background thread. `NSPasteboard` must be used from the main thread.
**Fix:** Wrap the clipboard write AND notification call in `DispatchQueue.main.async { ... }`:
```swift
DispatchQueue.main.async {
    let pasteboard = NSPasteboard.general
    pasteboard.clearContents()
    let copied = pasteboard.setString(text, forType: .string)
    // ... notification calls ...
}
```

### 2. Can't disable dictation hotkey
**File:** `Sources/SetupWindow.swift:710-712`, `Sources/Config.swift:90-92`
The save path falls back to `⌃⌥B` when the field is cleared, making it impossible to disable.
**Fix:** Change the fallback in `saveConfig()` to match screenshot hotkey pattern:
```swift
dictationKeyCode: dictationHotkeyField.recordedHotkey?.keyCode ?? 0,
dictationModifiers: dictationHotkeyField.recordedHotkey?.modifiers ?? 0,
dictationDisplay: dictationHotkeyField.recordedHotkey?.displayString ?? "",
```

### 3. Dictation requires Telegram isConfigured
**File:** `Sources/App.swift` — `startDictationRecording()` calls `startRecording()` which checks `config.isConfigured` (requires Telegram setup).
Dictation doesn't use Telegram at all — it should work without Telegram being configured.
**Fix:** In `startDictationRecording()`, don't delegate to `startRecording()` for the config check. Either:
- Add a separate guard that only checks transcription is configured (API key exists), OR
- Extract the recording setup from `startRecording()` into a shared helper that both can call, with `startRecording()` adding the Telegram check

### 4. Silent failure with local transcription mode
**File:** `Sources/App.swift:578-580`
When `transcriptionMode = "local"` and no whisper model is installed, dictation shows "No speech detected" which is misleading.
**Fix:** Before starting dictation, check if transcription can work. If mode is "local" and no model exists, show a notification: "Local transcription model not found. Switch to Gemini or Custom mode in settings."

### 5. Remove TASK.md from the repo
**Fix:** Delete `TASK.md` and add it to `.gitignore`

## LOW — Fix if straightforward

### 6. First notification can be dropped
**File:** `Sources/App.swift:603-617`
`showLocalNotification()` requests authorization and immediately posts. On first use the notification may not appear.
**Fix:** Chain the notification post inside the authorization callback on first request.

### 7. Help text width too narrow
**File:** `Sources/SetupWindow.swift:239-241`
The dictation help text at 200px width may truncate.
**Fix:** Increase width to 250px.

## When done
- Commit all fixes to the `feat/dictation-hotkey` branch
- Push to origin
- Run: `openclaw system event --text "Done: fix-dictation" --mode now`
