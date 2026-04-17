# Nova Agent 🤖📱

<div align="center">

<img src="assets/banner.svg" alt="Nova Agent Banner" width="100%">

[![npm version](https://img.shields.io/npm/v/nova-agent?color=7C3AED&style=flat-square)](https://www.npmjs.com/package/nova-agent)
[![License: MIT](https://img.shields.io/badge/License-MIT-7C3AED.svg?style=flat-square)](LICENSE)
[![Android](https://img.shields.io/badge/Android-7.0%2B-3DDC84?style=flat-square&logo=android&logoColor=white)](https://android.com)
[![Node.js](https://img.shields.io/badge/Node.js-%3E%3D18-339933?style=flat-square&logo=node.js&logoColor=white)](https://nodejs.org)
[![CI](https://img.shields.io/github/actions/workflow/status/lekhanpro/nova-agent/ci.yml?style=flat-square&label=CI)](https://github.com/lekhanpro/nova-agent/actions)
[![GitHub stars](https://img.shields.io/github/stars/lekhanpro/nova-agent?style=flat-square&color=7C3AED)](https://github.com/lekhanpro/nova-agent/stargazers)

**Run AutoGPT AI Agent on Android — one-tap setup via Termux. No root required.**

Supports OpenAI GPT-4o · Anthropic Claude · Google Gemini

[**Quick Start**](#-quick-start) · [**CLI Usage**](#-cli-usage) · [**Flutter App**](#-flutter-app) · [**Architecture**](#-architecture) · [**Troubleshooting**](#-troubleshooting)

</div>

---

## ✨ Features

| Feature | Description |
|---------|-------------|
| 🚀 **One-command install** | `curl \| bash` or `npm install -g nova-agent` |
| 🔒 **No root required** | Sandboxed Ubuntu via `proot-distro` |
| 🤖 **AutoGPT Classic** | Full agent with goals, memory, and tools |
| 🔑 **Multi-provider** | OpenAI, Anthropic Claude, Google Gemini |
| 📊 **Live web dashboard** | Color-coded log viewer at `localhost:8000` |
| 📱 **Flutter App** | Native Android UI with terminal & status controls |
| 🔔 **Foreground service** | Keeps agent alive with persistent notification |
| 🛠️ **Full CLI** | 10 commands: setup, start, stop, logs, configure… |
| 🏗️ **ARM64 + x86_64** | Tested on Snapdragon, Exynos, and emulators |

---

## 📋 Requirements

| Component | Minimum |
|-----------|---------|
| Android | 7.0+ (API 24+) |
| [Termux](https://f-droid.org/en/packages/com.termux/) | Latest from **F-Droid** |
| Storage | ~2 GB free |
| RAM | 2 GB+ recommended (3 GB+ for large models) |
| Network | Required for initial setup & API calls |

> ⚠️ **Install Termux from [F-Droid](https://f-droid.org/en/packages/com.termux/)** — the Play Store version is outdated and unsupported.

---

## 🚀 Quick Start

### Option A — One-liner *(recommended)*

Open Termux and paste:

```bash
curl -fsSL https://raw.githubusercontent.com/lekhanpro/nova-agent/main/install.sh | bash
```

### Option B — npm global install

```bash
pkg install nodejs-lts -y
npm install -g nova-agent
```

Then follow the steps:

```bash
novax setup        # 1. Install Ubuntu + Python 3.11 + AutoGPT (~5-15 min)
novax configure    # 2. Enter your API key
novax start        # 3. Launch the agent 🚀
```

---

## 📖 CLI Usage

```bash
novax setup        # Install proot Ubuntu + Python 3.11 + AutoGPT
novax configure    # Interactive API key wizard (OpenAI / Anthropic / Gemini)
novax start        # Launch AutoGPT agent + web log viewer
novax stop         # Stop the running agent
novax restart      # Stop then start
novax status       # Show process status + recent log lines
novax logs         # Tail live logs (Ctrl+C to stop)
novax update       # Pull latest AutoGPT source + reinstall deps
novax shell        # Open bash shell inside Ubuntu container
novax uninstall    # Remove everything (with confirmation)
novax help         # Show this help
```

---

## 🔑 API Keys

You need **at least one**:

| Provider | Get Key | Env Var |
|----------|---------|---------|
| OpenAI (GPT-4o) | [platform.openai.com](https://platform.openai.com/api-keys) | `OPENAI_API_KEY` |
| Anthropic (Claude) | [console.anthropic.com](https://console.anthropic.com/) | `ANTHROPIC_API_KEY` |
| Google Gemini | [aistudio.google.com](https://aistudio.google.com/app/apikey) | `GOOGLE_API_KEY` |

```bash
novax configure    # Interactive wizard — set keys, choose model & memory backend
```

Or edit directly:
```bash
novax shell
nano /root/autogpt/.env
```

---

## 🖥️ Web Dashboard

Once running, open any browser at:

```
http://localhost:8000
```

Color-coded real-time logs, updated every 2 seconds.

---

## 📱 Flutter App

A native Android app that wraps the CLI with a beautiful UI.

### Features
- **One-Tap Setup** — animated 8-step progress wizard
- **Dashboard** — start/stop agent with live status indicator
- **Live Logs** — color-coded log viewer with auto-scroll
- **Terminal** — built-in monospace terminal display
- **Configure** — API key guide with provider docs
- **Settings** — auto-start, battery optimization, system info
- **Foreground Service** — keeps agent alive in background
- **Kotlin Native Bridge** — shell execution, process management, battery control

### Build from source
```bash
cd flutter_app
flutter pub get
flutter build apk --release
```

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────┐
│                Flutter App (Dart)                        │
│  ┌──────────┐  ┌──────────┐  ┌────────┐  ┌──────────┐  │
│  │ Dashboard│  │ Terminal │  │  Logs  │  │ Settings │  │
│  └────┬─────┘  └────┬─────┘  └───┬────┘  └────┬─────┘  │
│       └─────────────┴────────────┴─────────────┘         │
│                      Provider Layer                       │
│              GatewayProvider · SetupProvider              │
│  ┌────────────────────────────────────────────────────┐  │
│  │        Native Bridge (Kotlin MethodChannel)         │  │
│  │  Shell · Process · Logs · Battery · ForegroundSvc  │  │
│  └─────────────────────┬──────────────────────────────┘  │
└────────────────────────┼────────────────────────────────┘
                         │
┌────────────────────────┼────────────────────────────────┐
│            proot-distro Ubuntu container                  │
│  ┌──────────────────────────────────────────────────┐    │
│  │  Python 3.11 venv                                 │    │
│  │  ┌─────────────────────────────────────────────┐ │    │
│  │  │  AutoGPT Classic Agent                       │ │    │
│  │  │  /tmp/autogpt.log  ←  log web viewer :8000  │ │    │
│  │  └─────────────────────────────────────────────┘ │    │
│  └──────────────────────────────────────────────────┘    │
└──────────────────────────────────────────────────────────┘
```

```
nova-agent/
├── install.sh                 ← one-liner installer (curl | bash)
├── package.json               ← npm package config
├── bin/
│   └── novax.js               ← CLI entry point
├── lib/
│   ├── index.js               ← command dispatcher + help
│   └── postinstall.js         ← npm postinstall chmod hook
├── scripts/
│   ├── setup.sh               ← 8-step Ubuntu + AutoGPT installer
│   ├── configure.sh           ← interactive API key wizard
│   ├── start.sh               ← launch agent + web viewer
│   ├── stop.sh                ← graceful stop + force kill
│   ├── status.sh              ← process & port health check
│   ├── logs.sh                ← tail live logs from container
│   ├── update.sh              ← git pull + pip reinstall
│   ├── shell.sh               ← open Ubuntu bash shell
│   └── uninstall.sh           ← destroy container + confirmation
└── flutter_app/
    ├── pubspec.yaml           ← Flutter dependencies
    ├── lib/
    │   ├── main.dart          ← app entry + dark theme
    │   ├── constants.dart     ← all app constants
    │   ├── providers/         ← GatewayProvider, SetupProvider
    │   ├── screens/           ← Splash, Setup, Dashboard, Logs, Terminal, Settings
    │   └── services/          ← NativeBridge, GatewayService, BootstrapService
    └── android/
        └── .../kotlin/com/novaagent/app/
            ├── MainActivity.kt              ← Flutter entry
            ├── NativeBridgePlugin.kt        ← MethodChannel + EventChannel
            └── NovaAgentForegroundService.kt ← background keep-alive
```

---

## 🔧 What `setup` Does

The 8-step setup script:

1. **Update** Termux packages (`pkg update`)
2. **Install** `proot-distro`, `nodejs-lts`, `git`, `curl`
3. **Install Ubuntu** rootfs via proot-distro (~500 MB)
4. **Install Python 3.11** + build tools inside Ubuntu
5. **Clone** [AutoGPT/AutoGPT](https://github.com/Significant-Gravitas/AutoGPT) repository
6. **Create virtualenv** + install Python dependencies
7. **Configure `.env`** with Termux-compatible defaults
8. **Install web log viewer** (Python HTTP server on port 8000)

Setup is **idempotent** — safe to re-run if anything fails.

---

## 📱 Battery Optimization

Android aggressively kills background processes. Disable this for Termux:

1. **Settings** → **Apps** → **Termux**
2. **Battery** → **Unrestricted**
3. Optionally install [Termux:Boot](https://f-droid.org/en/packages/com.termux.boot/) to auto-start on reboot

---

## 🛠️ Troubleshooting

| Problem | Solution |
|---------|----------|
| `proot-distro: not found` | Run `novax setup` first |
| `Ubuntu not installed` | Run `novax setup` |
| API errors in logs | Run `novax configure` and enter key |
| Setup fails at Python | Retry — setup is idempotent |
| Agent exits immediately | Check: `novax logs` |
| Port 8000 busy | `novax shell` → `pkill -f server.py` |
| Killed in background | Disable battery optimization (see above) |

### Manual log check
```bash
novax shell
tail -f /tmp/autogpt.log
```

---

## 🤝 Contributing

1. Fork the repository
2. Create a branch: `git checkout -b feat/my-feature`
3. Test on a real Android device with Termux (or an x86_64 emulator)
4. Submit a pull request

Please read [CHANGELOG.md](CHANGELOG.md) before contributing.

---

## 📄 License

MIT © [lekhanpro](https://github.com/lekhanpro)

---

<div align="center">

Made with ❤️ for the Android community

⭐ Star this repo if it helps you run AI on your phone!

```bash
curl -fsSL https://raw.githubusercontent.com/lekhanpro/nova-agent/main/install.sh | bash
```

</div>
