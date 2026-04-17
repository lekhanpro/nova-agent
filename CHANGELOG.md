# Changelog

All notable changes to **nova-agent** are documented here.

This project adheres to [Semantic Versioning](https://semver.org/).

---

## [1.0.0] — 2026-04-17

### 🎉 Initial Release

#### Added
- `novax setup` — installs proot-distro Ubuntu + Python 3.11 + AutoGPT Classic in 8 steps
- `novax configure` — interactive wizard for OpenAI / Anthropic / Google Gemini API keys
- `novax start` — launches AutoGPT agent inside proot container with log web viewer
- `novax stop` — gracefully stops agent (SIGTERM → SIGKILL fallback)
- `novax restart` — atomic stop + start
- `novax status` — shows agent process status, web UI status, port 8000, recent logs
- `novax logs` — tail live logs from inside Ubuntu container (Ctrl+C to stop)
- `novax update` — git pull + pip reinstall without losing configuration
- `novax shell` — drops into interactive Ubuntu bash shell
- `novax uninstall` — removes Ubuntu container with confirmation prompt
- Live log web dashboard at `http://localhost:8000` with color-coded log levels
- ARM64, ARMv7, and x86_64 architecture detection
- Termux battery optimization tips
- One-liner installer: `curl -fsSL .../install.sh | bash`
- npm global install: `npm install -g nova-agent`
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
