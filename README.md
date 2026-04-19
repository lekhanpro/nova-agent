# Nova Agent 🤖📱

<div align="center">

[![npm version](https://img.shields.io/npm/v/%40lekhanpro%2Fnova-agent?color=7C3AED&style=flat-square&logo=npm)](https://www.npmjs.com/package/@lekhanpro/nova-agent)
[![License: MIT](https://img.shields.io/badge/License-MIT-7C3AED.svg?style=flat-square)](LICENSE)
[![Android](https://img.shields.io/badge/Android-7.0%2B-3DDC84?style=flat-square&logo=android&logoColor=white)](https://android.com)
[![Python](https://img.shields.io/badge/Python-3.8%2B-3776AB?style=flat-square&logo=python&logoColor=white)](https://python.org)
[![CI](https://img.shields.io/github/actions/workflow/status/lekhanpro/nova-agent/ci.yml?label=CI&style=flat-square)](https://github.com/lekhanpro/nova-agent/actions)
[![GitHub stars](https://img.shields.io/github/stars/lekhanpro/nova-agent?style=flat-square&color=7C3AED)](https://github.com/lekhanpro/nova-agent/stargazers)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=flat-square)](CONTRIBUTING.md)

**The AI agent that actually controls your Android phone.**  
27 native tools. 3 AI providers. Free tier available. No root.

[**Quick Start**](#-quick-start) · [**27 Android Tools**](#-android-tools-27) · [**Examples**](#-real-examples) · [**CLI**](#-cli-reference) · [**Providers**](#-api-keys--providers) · [**Contributing**](#-contributing)

</div>

---

## What Makes Nova Agent Different?

Most "AI on Android" projects just run a chatbot in a terminal.

**Nova Agent gives the AI real control over your Android phone** via [Termux:API](https://wiki.termux.com/wiki/Termux:API) — every action happens locally on your device:

```
You: "Take a selfie, describe what I look like, and send me a notification"

Nova Agent:
  ⚡ analyze_photo(camera_id=1)
     → Photo: /sdcard/nova_photo_20250714_143201.jpg
     → [base64 image sent to AI vision model]
  ⚡ send_notification(title="Selfie Analysis",
       message="You're indoors, good lighting, looks focused at screen")
     → Notification sent ✓

◆ Done! Front camera photo taken and analyzed. You look focused —
  sent the description to your notification bar.
```

**No cloud uploads. Runs entirely on your device. Persistent conversation memory.**

---

## ⚡ Quick Start

### 1. Install (30 seconds)

```bash
# In Termux (recommended):
curl -fsSL https://raw.githubusercontent.com/lekhanpro/nova-agent/main/install.sh | bash
```

Or via npm:
```bash
pkg install nodejs-lts -y && npm install -g @lekhanpro/nova-agent
```

### 2. Install the Termux:API companion app

Install from **[F-Droid](https://f-droid.org/en/packages/com.termux.api/)** ← required for all 27 Android tools.

> ⚠️ Use **F-Droid** versions of both Termux and Termux:API. The Play Store versions are outdated.

### 3. Get a free API key (60 seconds)

The fastest way to start is **Google Gemini** — completely free:

```
https://aistudio.google.com/app/apikey
```

### 4. Configure and run

```bash
novax configure   # choose provider + paste API key

novax ask "What's my battery level?"
# → Battery: 87% | Discharging | Health: Good | Temp: 32.1°C

novax ask "Where am I?"
# → 12.9716°N, 77.5946°E (±8m)
# → Maps: https://maps.google.com/?q=12.9716,77.5946

novax start       # interactive multi-turn chat with memory
```

---

## 🛠️ Android Tools (27)

| # | Tool | What the AI can do |
|---|------|--------------------|
| 📷 | `take_photo` | Take front/back camera photos |
| 🔬 | `analyze_photo` | Take photo + vision-analyze it (GPT-4o / Claude / Gemini) |
| 📍 | `get_location` | GPS coordinates + Google Maps link |
| 💬 | `list_sms` | Read recent SMS messages (filter by contact/count) |
| 📤 | `send_sms` | **Send** an SMS to any number |
| 🔋 | `get_battery` | Level, charging status, health, temperature |
| 📇 | `get_contacts` | Search and list phone contacts |
| 📋 | `read_clipboard` | Read current clipboard content |
| 📋 | `set_clipboard` | Copy text to clipboard (injection-safe) |
| 🔔 | `send_notification` | Push Android notifications |
| 🔊 | `text_to_speech` | Speak responses aloud (TTS) |
| 📶 | `get_wifi_info` | SSID, IP address, signal strength |
| 📳 | `vibrate` | Haptic feedback patterns |
| 💡 | `torch` | Flashlight on/off |
| 📊 | `get_sensor` | Any sensor: accelerometer, gyroscope, light, proximity… |
| 🔊 | `set_volume` | Set music/alarm/ring/notification/call volume |
| 🔈 | `get_volume` | Read current volume levels for all streams |
| ☀️ | `set_brightness` | Screen brightness 0–255 |
| 📞 | `get_call_log` | Missed/incoming/outgoing call history |
| 💬 | `show_dialog` | Native Android dialogs, date/time pickers |
| 🌐 | `open_url` | Open URL in device browser |
| 📁 | `list_files` | List directory contents |
| 📄 | `read_file` | Read text or binary files (base64) |
| ✏️ | `write_file` | Write/append to files |
| 🎵 | `media_play` | Play audio files via MediaPlayer |
| 📱 | `get_device_info` | Architecture, kernel, storage, uptime |
| 🖥️ | `run_shell` | Safe shell command execution |

> 💡 **Tip:** Gemini 2.0 Flash and GPT-4o have built-in vision — `analyze_photo` will describe what the camera sees.

---

## 🎮 Real Examples

```bash
# Morning briefing
novax ask "Give me my morning briefing: battery, WiFi, and last 3 SMS messages"

# Home automation
novax ask "Set volume to 20%, dim screen to minimum, and turn off torch"

# Find your phone
novax ask "Vibrate 5 times, flash the torch, and tell me my GPS location"

# Vision AI
novax ask "Take a photo with the back camera and describe everything you see"

# Smart clipboard
novax ask "Read my clipboard and fix any grammar mistakes, then copy it back"

# Device health
novax ask "Check battery health, temperature, WiFi signal, and give me a report"

# Automation scripts
novax ask "Read my last 10 calls, find all missed calls, and list the numbers"

# File operations
novax ask "List files in /sdcard/Download and tell me the 5 largest by name"

# Sensor data
novax ask "Read the light sensor and tell me if I should turn on a lamp"

# Send messages
novax ask "Send a text to +1234567890 saying I'll be 10 minutes late"
```

**Interactive mode remembers context across turns:**
```
You: What's my battery?
Nova: 72% — discharging. Temperature 31°C.

You: Is that temperature normal?
Nova: Yes, 31°C is normal for active use. Anything above 45°C is concerning.

You: Set an alarm and remind me to charge at 20%
Nova: ⚡ show_dialog(...) — Done! I'll remind you when battery hits 20%.
```

---

## 📖 CLI Reference

```
novax setup            Install Python deps + Termux:API integration (~5 min)
novax configure        Set AI provider, model, and API key interactively
novax start            Interactive multi-turn chat mode (with memory)
novax ask "..."        One-shot query — perfect for Termux shortcuts/scripts
novax status           Show agent config and all 27 tool availability
novax update           Pull latest nova_agent.py from GitHub
novax logs             Tail session logs
novax version          Print version (currently v1.1.0)
novax help             Show all commands
```

### Interactive mode commands

Inside `novax start`:

```
history     Print conversation history
clear       Wipe conversation history (fresh start)
tools       List all 27 available tools with descriptions
version     Show version info
!<cmd>      Run a shell command (e.g., !ls, !pwd, !cat file.txt)
exit/quit   Exit the agent
Ctrl+C      Cancel current input (doesn't exit)
```

### CLI flags

```bash
novax ask --no-history "..."     # Disable history for this session
novax ask --clear-history "..."  # Wipe history, then run query
nova_agent.py --version          # Print version
```

### Termux Shortcut example (Termux:Widget)

```bash
# ~/.shortcuts/nova_battery
#!/data/data/com.termux/files/usr/bin/bash
result=$(novax ask "Battery level, temp, and charging status in one line")
termux-notification --title "🔋 Battery" --content "$result"
```

---

## 🔑 API Keys & Providers

| Provider | Free Tier | Best Model | Speed | Get Key |
|----------|-----------|------------|-------|---------|
| **Google Gemini** | ✅ Yes | `gemini-2.0-flash` | ⚡⚡⚡ | [aistudio.google.com](https://aistudio.google.com/app/apikey) |
| **OpenAI** | ❌ Paid | `gpt-4o` / `gpt-4.1` | ⚡⚡ | [platform.openai.com](https://platform.openai.com/api-keys) |
| **Anthropic** | ❌ Paid | `claude-3-5-sonnet` | ⚡⚡ | [console.anthropic.com](https://console.anthropic.com/) |

> 💡 **Start with Gemini** — free, fast, and supports vision (needed for `analyze_photo`).

---

## 💾 Persistent Conversation History

Nova Agent **remembers your conversations** across sessions:

```bash
novax start
# You: My name is Alex, I'm in Mumbai
# Nova: Nice to meet you Alex! You're in Mumbai.

# [close terminal, come back tomorrow]

novax start
# You: What's my location again?
# Nova: You're in Mumbai — you told me yesterday!
```

History is saved to `~/.nova_agent/history.json` (rolling 50-message window).

```bash
novax ask --no-history "Fresh start"    # ignore saved history
novax ask --clear-history "Reset"       # wipe history permanently
```

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│  Termux (Android user-space — no root needed)               │
│                                                             │
│  nova_agent.py                                              │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  Interactive REPL / One-shot mode                   │   │
│  │  Persistent history  ←→  ~/.nova_agent/history.json │   │
│  │            ↓                                        │   │
│  │  Provider Router                                    │   │
│  │  ┌──────────┬──────────────┬─────────────────────┐ │   │
│  │  │  OpenAI  │  Anthropic   │  Google Gemini      │ │   │
│  │  │ streaming│  tool_use    │  function_calling   │ │   │
│  │  └────┬─────┴──────┬───────┴──────────┬──────────┘ │   │
│  │       └────────────┴──────────────────┘             │   │
│  │                    ↓                                │   │
│  │  Tool Dispatcher  (27 Android tools)                │   │
│  └──────────────────────┬──────────────────────────────┘   │
│                         │                                   │
│  ┌──────────────────────▼──────────────────────────────┐   │
│  │  Termux:API  (termux-camera, termux-location,       │   │
│  │  termux-sms-list, termux-sensor, termux-volume, …)  │   │
│  └──────────────────────┬──────────────────────────────┘   │
└─────────────────────────┼───────────────────────────────────┘
                          │
┌─────────────────────────▼───────────────────────────────────┐
│  Android Hardware                                            │
│  Camera · GPS · SMS · Contacts · Sensors · Torch · Volume   │
│  Clipboard · Notifications · TTS · WiFi · Files · Media      │
└──────────────────────────────────────────────────────────────┘
```

**Project layout:**

```
nova-agent/
├── nova_agent.py           ← Core agent (27 Android tools, 3 providers, history)
├── install.sh              ← One-liner installer
├── package.json            ← npm package (v1.1.0)
├── bin/novax.js            ← CLI entry point
├── lib/index.js            ← Command dispatcher + help system
├── scripts/
│   ├── setup.sh            ← Install deps + Termux:API
│   ├── configure.sh        ← Interactive provider/model/key wizard
│   ├── start.sh            ← Launch interactive mode
│   ├── ask.sh              ← One-shot query
│   ├── status.sh           ← Show config + tool availability
│   ├── update.sh           ← Update agent from GitHub
│   └── logs.sh             ← Tail session logs
└── flutter_app/            ← Optional native Android UI
    ├── pubspec.yaml
    ├── lib/                ← Screens, providers, services
    └── android/            ← Kotlin native bridge
```

---

## 📋 Requirements

| Component | Details |
|-----------|---------|
| Android | 7.0+ (API 24+) |
| [Termux](https://f-droid.org/en/packages/com.termux/) | From **F-Droid** (not Play Store!) |
| [Termux:API](https://f-droid.org/en/packages/com.termux.api/) | Android hardware bridge |
| Python | 3.8+ (`pkg install python`) |
| Storage | ~50 MB |
| AI provider | OpenAI / Anthropic / Gemini API key |

---

## 📱 Flutter App

A native Android companion app with beautiful UI:

- 🔘 **Dashboard** — start/stop agent, live status indicator
- 📋 **Chat view** — color-coded streaming responses
- ⚙️ **Settings** — provider, model, API key management
- 🔔 **Foreground Service** — keeps agent alive in background

**Build from source:**
```bash
cd flutter_app
flutter pub get
flutter build apk --release
```

---

## 🔧 Troubleshooting

| Problem | Solution |
|---------|----------|
| `termux-battery-status: not found` | Install [Termux:API](https://f-droid.org/en/packages/com.termux.api/) from F-Droid |
| `No module named openai` | `pip install openai` (or `anthropic`, `google-generativeai`) |
| `No API key configured` | Run `novax configure` |
| Camera/SMS permission denied | Open Termux:API app → grant permissions |
| GPS returns null | Step outside, or use: `termux-location -p network` |
| SMS read/send fails | Grant SMS permission to **Termux:API** (not Termux itself) |
| Gemini tool calling fails | Ensure `google-generativeai >= 0.5.0`: `pip install -U google-generativeai` |
| Agent killed by Android | Settings → Apps → Termux → Battery → **Unrestricted** |

---

## 📱 Keep Agent Running (Background)

Android kills background apps. Two options:

**Option 1 — Disable battery optimization** (recommended):
```
Settings → Apps → Termux → Battery → Unrestricted
```

**Option 2 — Auto-start on reboot:**
```bash
pkg install termux-boot
# Then place a startup script in ~/.termux/boot/
```

---

## 🤝 Contributing

**Adding a new Android tool is the easiest high-impact contribution.**

Termux:API has 40+ commands — NFC, microphone recording, fingerprint, Bluetooth, and more — all waiting to be wired up.

👉 **[Read the Contributing Guide →](CONTRIBUTING.md)**

### Adding a tool (template)

```python
# 1. Add the function to nova_agent.py
def tool_my_new_tool(param1: str, param2: int = 0) -> dict:
    """Brief description of what this does."""
    result = run_termux(f"termux-my-command '{param1}' {param2}")
    return json.loads(result) if result else {"error": "no output"}

# 2. Add to TOOL_DEFINITIONS
{
    "name": "my_new_tool",
    "description": "What this tool does and when to use it.",
    "parameters": {
        "type": "object",
        "properties": {
            "param1": {"type": "string", "description": "…"},
            "param2": {"type": "integer", "description": "…", "default": 0},
        },
        "required": ["param1"],
    }
}

# 3. Add to TOOL_MAP
"my_new_tool": tool_my_new_tool,
```

That's it. Open a PR — tools with tests get merged faster.

---

## 📄 License

MIT © [lekhanpro](https://github.com/lekhanpro)

---

<div align="center">

**If Nova Agent controls your phone better than you expected, give it a ⭐**

[GitHub](https://github.com/lekhanpro/nova-agent) · [npm](https://www.npmjs.com/package/@lekhanpro/nova-agent) · [Issues](https://github.com/lekhanpro/nova-agent/issues) · [Contributing](CONTRIBUTING.md)

</div>


---

<div align="center">

Made with ❤️ for the Android community

**Give your AI real Android superpowers — for free.**

```bash
curl -fsSL https://raw.githubusercontent.com/lekhanpro/nova-agent/main/install.sh | bash
```

⭐ Star this repo if Nova Agent helps you!

</div>
