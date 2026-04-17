# Changelog

All notable changes to **autogpt-termux** are documented here.

This project adheres to [Semantic Versioning](https://semver.org/).

---

## [1.0.0] — 2026-04-17

### 🎉 Initial Release

#### Added
- `autogptx setup` — installs proot-distro Ubuntu + Python 3.11 + AutoGPT Classic in 8 steps
- `autogptx configure` — interactive wizard for OpenAI / Anthropic / Google Gemini API keys
- `autogptx start` — launches AutoGPT agent inside proot container with log web viewer
- `autogptx stop` — gracefully stops agent (SIGTERM → SIGKILL fallback)
- `autogptx restart` — atomic stop + start
- `autogptx status` — shows agent process status, web UI status, port 8000, recent logs
- `autogptx logs` — tail live logs from inside Ubuntu container (Ctrl+C to stop)
- `autogptx update` — git pull + pip reinstall without losing configuration
- `autogptx shell` — drops into interactive Ubuntu bash shell
- `autogptx uninstall` — removes Ubuntu container with confirmation prompt
- Live log web dashboard at `http://localhost:8000` with color-coded log levels
- ARM64, ARMv7, and x86_64 architecture detection
- Termux battery optimization tips
- One-liner installer: `curl -fsSL .../install.sh | bash`
- npm global install: `npm install -g autogpt-termux`
- Postinstall hook to make shell scripts executable
- Multi-provider support: OpenAI, Anthropic Claude, Google Gemini

---

## [Unreleased]

### Planned
- Termux:Widget integration for one-tap start/stop from home screen
- Background wake-lock via Termux:Boot
- Persistent memory with ChromaDB
- Web UI improvements (dark theme, real-time streaming)
- Plugin support for AutoGPT tools
