# Nova Agent 🤖📱

<div align="center">

[![npm version](https://img.shields.io/npm/v/nova-agent?color=7C3AED&style=flat-square&logo=npm)](https://www.npmjs.com/package/nova-agent)
[![License: MIT](https://img.shields.io/badge/License-MIT-7C3AED.svg?style=flat-square)](LICENSE)
[![Android](https://img.shields.io/badge/Android-7.0%2B-3DDC84?style=flat-square&logo=android&logoColor=white)](https://android.com)
[![Python](https://img.shields.io/badge/Python-3.8%2B-3776AB?style=flat-square&logo=python&logoColor=white)](https://python.org)
[![CI](https://img.shields.io/github/actions/workflow/status/lekhanpro/nova-agent/ci.yml?label=CI&style=flat-square)](https://github.com/lekhanpro/nova-agent/actions)
[![GitHub stars](https://img.shields.io/github/stars/lekhanpro/nova-agent?style=flat-square&color=7C3AED)](https://github.com/lekhanpro/nova-agent/stargazers)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=flat-square)](CONTRIBUTING.md)

**The AI agent that actually controls your Android phone.**

No root. No complex setup. Just `pip install openai` and you're running.

[**Quick Start**](#-quick-start) · [**Android Tools**](#-android-tools) · [**Examples**](#-real-examples) · [**CLI**](#-cli-reference) · [**Flutter App**](#-flutter-app) · [**Contributing**](#-contributing)

</div>

---

## What Makes Nova Agent Different?

Most "AI on Android" projects just run a chatbot in a terminal. 

**Nova Agent gives the AI real control over your Android phone** via [Termux:API](https://wiki.termux.com/wiki/Termux:API):

```
You: "Take a selfie, describe it, and send me a notification with the description"

Nova Agent: ⚡ take_photo(camera_id=1)
            → Photo saved to /sdcard/nova_agent_20260417_214532.jpg
            ⚡ send_notification(title="Selfie Analysis", message="You look focused...")
            → Notification sent

◆ Done! I took a selfie with your front camera. You appear to be indoors in
  good lighting, looking focused at a screen. I sent the analysis to your
  notification bar.
```

No cloud uploads. Everything runs on your device.

---

## 🛠️ Android Tools

| Tool | Termux:API Command | What the AI can do |
|------|-------------------|-------------------|
| 📷 `take_photo` | `termux-camera-photo` | Take front/back camera photos |
| 📍 `get_location` | `termux-location` | GPS coordinates + Google Maps link |
| 💬 `list_sms` | `termux-sms-list` | Read recent text messages |
| 🔋 `get_battery` | `termux-battery-status` | Level, charging status, health, temp |
| 📇 `get_contacts` | `termux-contact-list` | Search and list contacts |
| 📋 `read_clipboard` | `termux-clipboard-get` | Read clipboard content |
| 📋 `set_clipboard` | `termux-clipboard-set` | Copy text to clipboard |
| 🔔 `send_notification` | `termux-notification` | Push notifications |
| 🔊 `text_to_speech` | `termux-tts-speak` | Speak responses aloud |
| 📶 `get_wifi_info` | `termux-wifi-connectioninfo` | SSID, IP, signal strength |
| 📳 `vibrate` | `termux-vibrate` | Haptic feedback |
| 💡 `torch` | `termux-torch` | Flashlight on/off |
| 🖥️ `run_shell` | bash | Safe shell commands |
| 📱 `get_device_info` | system | Arch, kernel, storage |

> **14 tools today. More coming.** [Contribute a tool →](CONTRIBUTING.md)

---

## ⚡ Quick Start

### 1. Install (30 seconds)

```bash
# In Termux:
curl -fsSL https://raw.githubusercontent.com/lekhanpro/nova-agent/main/install.sh | bash
```

Or via npm:
```bash
pkg install nodejs-lts -y && npm install -g nova-agent
```

### 2. Install Termux:API companion app

Install from **[F-Droid](https://f-droid.org/en/packages/com.termux.api/)** (required for Android tools).

### 3. Configure your API key

```bash
novax configure
```

Supports **OpenAI**, **Anthropic Claude**, and **Google Gemini** (free tier available).

### 4. Start asking

```bash
novax ask "What's my battery level?"
# → Battery: 87% | Status: Discharging | Health: Good | Temp: 32.1°C

novax ask "Where am I?"
# → Location: 12.9716, 77.5946 (accuracy: 8m)
#   Maps: https://maps.google.com/?q=12.9716,77.5946

novax start   # interactive chat mode
```

---

## 🎮 Real Examples

```bash
# Morning briefing
novax ask "Give me a briefing: battery level, WiFi status, and read my last 3 SMS"

# Find your phone
novax ask "Turn on the torch, vibrate 3 times, and tell me my GPS location"

# Smart clipboard
novax ask "Read my clipboard and improve the grammar of whatever text is there, then copy the fixed version"

# Photo analysis
novax ask "Take a photo with my back camera and tell me what's in the room"

# Security check
novax ask "Take a selfie, check my battery, and notify me if battery is below 20%"

# Developer
novax ask "Run 'df -h' and summarize my storage situation"
novax ask "Check my WiFi signal and tell me if it's good enough for video calls"
```

---

## 📖 CLI Reference

```
novax setup        Install Python deps + Termux:API integration (~5 min)
novax configure    Set AI provider, model, and API key
novax start        Interactive chat mode
novax ask "..."    One-shot query (great for scripts/shortcuts)
novax status       Show agent status and config
novax update       Update nova_agent.py to latest version
novax version      Show version
novax help         Show all commands
```

### Run from Termux Shortcuts (Termux:Widget)

```bash
# ~/.shortcuts/nova_battery
#!/bin/bash
result=$(novax ask "Battery level and status")
termux-notification --title "Battery" --content "$result"
```

---

## 🔑 API Keys

| Provider | Free Tier | Get Key |
|----------|-----------|---------|
| **Google Gemini** | ✅ Yes | [aistudio.google.com](https://aistudio.google.com/app/apikey) |
| **OpenAI** | ❌ Paid | [platform.openai.com](https://platform.openai.com/api-keys) |
| **Anthropic** | ❌ Paid | [console.anthropic.com](https://console.anthropic.com/) |

> 💡 **Start free with Gemini 1.5 Flash** — fast, capable, and has a generous free tier.

---

## 📋 Requirements

| Component | Details |
|-----------|---------|
| Android | 7.0+ (API 24+) |
| [Termux](https://f-droid.org/en/packages/com.termux/) | From **F-Droid** (not Play Store) |
| [Termux:API](https://f-droid.org/en/packages/com.termux.api/) | For Android hardware tools |
| Storage | ~200 MB (simple mode) |
| Python | 3.8+ (via `pkg install python`) |

> ⚠️ Install Termux and Termux:API from **[F-Droid](https://f-droid.org)** — the Play Store versions are outdated.

---

## 🏗️ Architecture

```
┌──────────────────────────────────────────────────────┐
│  Termux (Android user space)                          │
│                                                       │
│  nova_agent.py                                        │
│  ┌─────────────────────────────────────────────────┐ │
│  │  Interactive REPL / One-shot mode               │ │
│  │  ↓                                              │ │
│  │  AI Provider (OpenAI / Anthropic / Gemini)      │ │
│  │  ↓  function_calling / tool_use                 │ │
│  │  Tool Dispatcher (14 Android tools)             │ │
│  └──────────────┬──────────────────────────────────┘ │
│                 │                                     │
│  ┌──────────────▼──────────────────────────────────┐ │
│  │  Termux:API (termux-camera, termux-location,    │ │
│  │  termux-sms-list, termux-battery-status, ...)   │ │
│  └──────────────┬──────────────────────────────────┘ │
└─────────────────┼────────────────────────────────────┘
                  │
┌─────────────────▼────────────────────────────────────┐
│  Android Hardware                                     │
│  Camera · GPS · SMS · Contacts · Sensors · Torch     │
└──────────────────────────────────────────────────────┘
```

```
nova-agent/
├── nova_agent.py           ← core agent (14 Android tools + AI loop)
├── install.sh              ← one-liner installer
├── package.json            ← npm package
├── bin/novax.js            ← CLI entry point
├── lib/index.js            ← command dispatcher
├── scripts/
│   ├── setup.sh            ← install deps + Termux:API
│   ├── configure.sh        ← API key wizard
│   ├── start.sh            ← interactive mode
│   ├── ask.sh              ← one-shot query
│   ├── status.sh           ← show config + status
│   ├── update.sh           ← update agent script
│   └── ...
└── flutter_app/            ← optional native Android UI
    ├── pubspec.yaml
    ├── lib/ (screens, providers, services)
    └── android/ (Kotlin native bridge)
```

---

## 📱 Flutter App

A native Android companion app with a beautiful UI.

- 🔘 **Dashboard** — start/stop agent, status indicator
- 📋 **Live output** — color-coded agent responses
- ⚙️ **Settings** — provider, model, API key
- 🔔 **Foreground Service** — keeps agent alive in background

**Build from source:**
```bash
cd flutter_app
flutter pub get
flutter build apk --release
```

---

## 📱 Battery Optimization

Android kills background processes. Disable battery optimization for Termux:

**Settings → Apps → Termux → Battery → Unrestricted**

Or install [Termux:Boot](https://f-droid.org/en/packages/com.termux.boot/) for auto-start on reboot.

---

## 🛠️ Troubleshooting

| Problem | Solution |
|---------|----------|
| `termux-battery-status: command not found` | Install [Termux:API app](https://f-droid.org/en/packages/com.termux.api/) from F-Droid |
| `openai: No module named` | Run `pip install openai` |
| `No API key configured` | Run `novax configure` |
| `Permission denied` (camera/SMS) | Open Termux:API app and grant permissions |
| GPS returns `null` | Go outside or use `network` provider: `termux-location -p network` |
| SMS permission denied | Grant SMS permission to **Termux:API** app (not Termux) |

---

## 🤝 Contributing

**Adding a new Android tool is the easiest contribution and makes the biggest impact.**

Termux:API has 40+ commands waiting to be added — sensors, NFC, microphone, call logs, media player, and more.

👉 **[Read the Contributing Guide →](CONTRIBUTING.md)**

```bash
# Tools waiting for contributors:
termux-sensor          # accelerometer, gyroscope
termux-microphone-record  # audio recording
termux-nfc             # NFC tag reading
termux-call-log        # call history
termux-media-player    # music control
termux-dialog          # native Android dialogs
termux-volume          # volume control
termux-brightness      # screen brightness
```

---

## 📄 License

MIT © [lekhanpro](https://github.com/lekhanpro)

---

<div align="center">

Made with ❤️ for the Android community

**Give your AI real Android superpowers — for free.**

```bash
curl -fsSL https://raw.githubusercontent.com/lekhanpro/nova-agent/main/install.sh | bash
```

⭐ Star this repo if Nova Agent helps you!

</div>
