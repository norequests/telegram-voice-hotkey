# Voice-to-Slop

A macOS menu bar app for sending voice notes and screenshots to your AI agent via Telegram. The fastest way to generate questionable code with your OpenClaw.

**Hold a hotkey → record → release → voice note sent as you** via Telegram's User API (TDLib).

**Hold screenshot hotkey → captures screen + records voice → transcribes → sends screenshot with your words as the caption** — one atomic message, full context for your AI.

> **Prerequisites:** You need an [OpenClaw](https://github.com/openclaw/openclaw) agent connected to Telegram that can receive and transcribe voice notes. See [Setup step 3](#3-set-up-your-ai-to-receive-voice-notes) for details.

## Features

- 🎤 **Global voice hotkey** — works from any app, any time (default: `⌃⌥N`)
- 📸 **Screenshot + voice combo** — capture screen + speak, sent as one message (default: `⌃⌥M`)
- 💬 **Send voice as text** — transcribe and send as a text message instead of audio
- 🧠 **Local transcription** — whisper.cpp transcribes your voice on-device (no cloud needed)
- 🌐 **Cloud transcription** — Gemini or any OpenAI-compatible API (Groq, OpenAI, self-hosted)
- 🔌 **Custom endpoints** — bring your own transcription API (OpenAI-compatible)
- 👤 **Sends as you** — Telegram User API (TDLib), messages appear from your account
- 🎵 **OGG/Opus format** — proper Telegram voice note with waveform player
- 📦 **Self-contained** — TDLib, ffmpeg bundled in the `.app`
- 🚀 **Launch at login** — optional auto-start
- 📊 **Menu bar status** — live recording state, connection status, hotkey info

## Install

### Option 1: Download ZIP (easiest)

1. Download the latest `.zip` from [**Releases**](https://github.com/norequests/voice-to-slop/releases)
2. Unzip and drag `VoiceToSlop.app` to `/Applications/`
3. If macOS blocks it: **System Settings → Privacy & Security → Open Anyway**

> **Note:** The app is not notarized. If macOS says it's "damaged":
> ```bash
> sudo xattr -cr /Applications/VoiceToSlop.app
> ```

### Option 2: Build from source

```bash
brew install cmake gperf openssl ffmpeg whisper-cpp

git clone https://github.com/norequests/voice-to-slop.git
cd voice-to-slop

# Build TDLib (first time only, ~5 minutes)
./scripts/setup-tdlib.sh

# Download whisper model for local transcription (optional — not needed for cloud transcription)
mkdir -p ~/Library/Application\ Support/TelegramVoiceHotkey/models/
curl -L "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-small.en.bin" \
  -o ~/Library/Application\ Support/TelegramVoiceHotkey/models/ggml-small.en.bin

# Build and install
./build.sh
sudo rm -rf /Applications/VoiceToSlop.app
cp -r VoiceToSlop.app /Applications/
```

**Requirements:** macOS 13+ (Ventura or later), Xcode Command Line Tools (`xcode-select --install`)

## Setup

On first launch, a setup window appears.

### 1. Get Telegram API credentials

1. Go to [my.telegram.org](https://my.telegram.org) → **API Development Tools**
2. Create an app → copy your **API ID** and **API Hash**

### 2. Configure the app

| Field | Description |
|-------|-------------|
| **API ID / Hash** | From step 1 |
| **Phone** | Your Telegram phone number → click **Send Code** → enter code |
| **Chat ID** | Numeric ID of the chat to send to (see [Finding a Chat ID](#finding-a-chat-id)) |
| **Hotkey** | Global shortcut for voice recording (default: `⌃⌥N`) |
| **Screenshot** | Global shortcut for screenshot + voice combo (default: `⌃⌥M`) |
| **Mode** | Hold-to-record (release sends) or press-to-toggle |
| **Transcription** | Local (whisper.cpp), Gemini, or Custom endpoint |
| **Send voice as text** | Transcribe and send text instead of audio (requires Gemini or Custom) |

### 3. Transcription options

| Mode | Description |
|------|-------------|
| **Local** | whisper.cpp — offline, ~10s, needs model download (~460MB) |
| **Gemini** | Google Gemini API — fast cloud transcription, needs API key |
| **Custom** | Any OpenAI-compatible `/v1/audio/transcriptions` endpoint |

**Custom endpoint** works with: OpenAI Whisper API, Groq, local whisper-server, or any service that accepts the OpenAI audio transcription format. Configure the endpoint URL, API key, and model name in settings.

### 4. Set up your AI to receive voice notes

For the full loop — speak → AI responds:

1. **Connect [OpenClaw](https://github.com/openclaw/openclaw) to Telegram** via the [Telegram channel plugin](https://docs.openclaw.ai)
2. **Configure audio transcription** — OpenClaw supports auto-transcription via Gemini, OpenAI Whisper API, Groq, Deepgram, or local whisper

The result: hold hotkey → speak → AI transcribes → responds in chat.

### 5. Permissions

The app needs three macOS permissions (prompted automatically):

- **Microphone** — for recording
- **Accessibility** — for global hotkey (System Settings → Privacy & Security → Accessibility)
- **Screen Recording** — for screenshot feature (prompted on first screenshot)

## Screenshot + Voice Combo

The killer feature. Hold the screenshot hotkey:

1. 📸 Screen captured instantly
2. 🎤 Voice recording starts
3. Release → voice transcribed (local or cloud)
4. 📤 Screenshot sent with transcription as caption — **one message**

Your AI gets the full context (visual + verbal) in a single message. No race condition, no partial responses.

## Send Voice as Text

When **"Send voice as transcribed text"** is enabled (and using Gemini or Custom transcription):

1. 🎤 Record your voice
2. 📝 Voice is transcribed via your chosen cloud provider
3. 💬 Transcript sent as a regular text message (not a voice note)

If transcription fails, it falls back to sending as a voice note automatically.

This is useful when you want your AI to receive clean text input without needing server-side audio processing.

### Whisper Model (local mode)

Local transcription uses whisper.cpp. Recommended model: **small.en** (~460MB, good accuracy):

```bash
mkdir -p ~/Library/Application\ Support/TelegramVoiceHotkey/models/
curl -L "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-small.en.bin" \
  -o ~/Library/Application\ Support/TelegramVoiceHotkey/models/ggml-small.en.bin
```

`base.en` (~140MB) also works but struggles with background noise. The app searches for `small.en` first, falls back to `base.en`.

You can also download the model from within the app when Local mode is selected.

## Finding a Chat ID

The Chat ID is the numeric ID of the target Telegram chat.

- **[@userinfobot](https://t.me/userinfobot)** — forward a message from the target chat, or message it directly for your own ID
- **For a bot** — the bot's user ID is the number before the `:` in its token (e.g. `8293553857:AAE...` → `8293553857`)

## Files

| Path | Description |
|------|-------------|
| `~/Library/Application Support/TelegramVoiceHotkey/config.json` | Settings |
| `~/Library/Application Support/TelegramVoiceHotkey/app.log` | App log |
| `~/Library/Application Support/TelegramVoiceHotkey/tdlib/` | Telegram session |
| `~/Library/Application Support/TelegramVoiceHotkey/tdlib.log` | TDLib internal log |
| `~/Library/Application Support/TelegramVoiceHotkey/models/` | Whisper models |

Menu bar icon → **View Log...** to check status.

## Troubleshooting

| Problem | Fix |
|---------|-----|
| "TDLib not found" | Run `./scripts/setup-tdlib.sh` then rebuild |
| Hotkey doesn't work | Grant Accessibility in System Settings |
| "Chat not found" | Use numeric Chat ID, not username |
| App won't open | Right-click → Open, or allow in Privacy & Security |
| Bad transcription | Use `small.en` model; speak clearly for 2+ seconds |
| Corrupt session | Delete `~/Library/Application Support/TelegramVoiceHotkey/tdlib/` and re-login |
| Screenshot not sending | Grant Screen Recording permission; restart app |
| TDLib stuck on startup | Delete `~/Library/Application Support/TelegramVoiceHotkey/` and reconfigure |
| Transcription hangs | Check API key; try switching transcription mode |

## Architecture

- **Swift/AppKit** — native macOS menu bar app
- **TDLib** — Telegram User API, loaded dynamically via `dlopen`
- **whisper.cpp** — local speech-to-text for screenshot captions
- **ffmpeg** — OGG/Opus encoding for Telegram voice notes
- **CGEventTap** — global hotkey interception (suppresses events, no beeping)

## macOS only

Native Swift app. Windows and Linux are not supported. PRs welcome.

## License

MIT
