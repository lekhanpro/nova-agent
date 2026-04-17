# AutoGPT-Termux 🤖📱

> **Run AutoGPT AI Agent on Android — No root required.**

One-tap install that sets up AutoGPT Classic inside a proot-distro Ubuntu container on Termux. Supports OpenAI, Anthropic (Claude), and Google Gemini APIs.

---

## ✨ Features

- 🚀 **One-command install** — `curl | bash` or `npm install -g`
- 🔒 **No root required** — uses proot-distro sandboxed Ubuntu
- 🤖 **AutoGPT Classic** — full agent with goals, memory, and tools
- 🔑 **Multi-provider** — OpenAI, Anthropic Claude, Google Gemini
- 📊 **Live web dashboard** — log viewer at `http://localhost:8000`
- 📱 **ARM64 optimized** — tested on Snapdragon & Exynos devices
- 🛠️ **Full CLI** — `setup`, `start`, `stop`, `logs`, `configure`, `update`, `shell`

---

## 📋 Requirements

| Component | Requirement |
|-----------|-------------|
| Android   | 7.0+ (API 24+) |
| [Termux](https://f-droid.org/en/packages/com.termux/) | Latest from F-Droid |
| Storage   | ~2 GB free |
| RAM       | 2 GB+ recommended |
| Network   | Required for initial setup & API calls |

> ⚠️ **Install Termux from [F-Droid](https://f-droid.org/en/packages/com.termux/)**, NOT the Play Store (outdated).

---

## 🚀 Quick Start

### Option A — One-liner (recommended)

Open Termux and paste:

```bash
curl -fsSL https://raw.githubusercontent.com/lekhanpro/autogpt-termux/main/install.sh | bash
```

### Option B — npm global install

```bash
pkg install nodejs-lts -y
npm install -g autogpt-termux
```

---

## 📖 Usage

```bash
autogptx setup        # Install Ubuntu + Python 3.11 + AutoGPT (~5-15 min)
autogptx configure    # Enter your API key (OpenAI / Anthropic / Gemini)
autogptx start        # Launch the AutoGPT agent
autogptx logs         # Watch live output (Ctrl+C to stop)
autogptx status       # Check if agent is running
autogptx stop         # Stop the agent
autogptx restart      # Stop then start
autogptx update       # Pull latest AutoGPT + reinstall deps
autogptx shell        # Open a bash shell inside Ubuntu
autogptx uninstall    # Remove everything
autogptx help         # Show all commands
```

---

## 🔑 API Keys

You need at least one of:

| Provider | Get Key | Env Var |
|----------|---------|---------|
| OpenAI (GPT-4o) | [platform.openai.com](https://platform.openai.com/api-keys) | `OPENAI_API_KEY` |
| Anthropic (Claude) | [console.anthropic.com](https://console.anthropic.com/) | `ANTHROPIC_API_KEY` |
| Google Gemini | [aistudio.google.com](https://aistudio.google.com/app/apikey) | `GOOGLE_API_KEY` |

Set keys interactively:
```bash
autogptx configure
```

Or edit `.env` directly inside the container:
```bash
autogptx shell
nano /root/autogpt/.env
```

---

## 🖥️ Web Dashboard

Once the agent is running, open a browser and go to:

```
http://localhost:8000
```

This shows live, color-coded logs updated every 2 seconds.

---

## 🏗️ Project Architecture

```
autogpt-termux/
├── install.sh              ← one-liner installer (curl | bash)
├── package.json            ← npm package config
├── bin/
│   └── autogptx.js         ← CLI entry point (node)
├── lib/
│   ├── index.js            ← command dispatcher
│   └── postinstall.js      ← npm postinstall hook
└── scripts/
    ├── setup.sh            ← install proot Ubuntu + AutoGPT
    ├── configure.sh        ← API key wizard
    ├── start.sh            ← launch agent
    ├── stop.sh             ← stop agent
    ├── status.sh           ← process & port status
    ├── logs.sh             ← tail live logs
    ├── update.sh           ← git pull + pip update
    ├── shell.sh            ← open Ubuntu bash shell
    └── uninstall.sh        ← remove everything
```

---

## 🔧 What `setup` Does

The setup script performs 8 steps inside Termux/Ubuntu:

1. **Update** Termux packages
2. **Install** `proot-distro`, `nodejs-lts`, `git`, `curl`
3. **Install Ubuntu** rootfs via proot-distro (~500 MB)
4. **Install Python 3.11** + build tools inside Ubuntu
5. **Clone** [AutoGPT/AutoGPT](https://github.com/Significant-Gravitas/AutoGPT) repo
6. **Create venv** + install Python dependencies
7. **Configure `.env`** with Termux-compatible defaults
8. **Install log web viewer** (Python HTTP server on port 8000)

---

## 📱 Battery Optimization (Important!)

Android kills background processes to save battery. Disable this for Termux:

1. **Settings** → **Apps** → **Termux**
2. **Battery** → **Unrestricted** (or "Don't optimize")
3. Optionally use [Termux:Boot](https://f-droid.org/en/packages/com.termux.boot/) to auto-start sessions

---

## 🛠️ Troubleshooting

| Problem | Fix |
|---------|-----|
| `proot-distro: command not found` | Run `autogptx setup` first |
| `Ubuntu not installed` | Run `autogptx setup` |
| API errors | Run `autogptx configure` and set your key |
| Out of memory | Close other apps; 3+ GB RAM recommended |
| Setup fails at Python | Retry: `autogptx setup` is idempotent |
| Agent exits immediately | Check logs: `autogptx logs` |
| Port 8000 busy | Kill: `proot-distro login ubuntu -- pkill -f server.py` |

### Check logs manually
```bash
autogptx shell
tail -f /tmp/autogpt.log
```

---

## 🤝 Contributing

1. Fork the repo
2. Create a feature branch: `git checkout -b feat/my-feature`
3. Test on a real Android device with Termux
4. Submit a PR

---

## 📄 License

MIT © autogpt-termux contributors

---

## ⭐ Star History

If this project helps you run AI agents on your phone, please ⭐ star it!

```
curl -fsSL https://raw.githubusercontent.com/lekhanpro/autogpt-termux/main/install.sh | bash
```
