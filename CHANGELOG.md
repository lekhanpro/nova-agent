# Changelog

All notable changes to **nova-agent** are documented here.

This project adheres to [Semantic Versioning](https://semver.org/).

---

## [1.1.0] — 2025-07-14

### 🚀 Major Release — Nova Agent Rewrite

This release replaces the proot-based AutoGPT Classic runner with a native
Python agent that runs **directly in Termux**, communicating with your phone's
hardware through **Termux:API**. No Ubuntu container, no root, just Python.

#### Added — AI Providers
- **Full Gemini support** — `google-generativeai` SDK with native function
  calling; strips unsupported `"default"` keys from JSON schemas automatically
- **Fixed Anthropic provider** — was silently falling back to OpenAI; now
  properly calls Claude with correct `system`-parameter handling and adapter
  classes (`_TC`/`_Msg`) to match the internal OpenAI interface
- **OpenAI streaming** — `_stream_openai()` accumulates delta chunks so
  responses print as they arrive (token-by-token)
- Model menu updated: GPT-4.1, o4-mini, Claude 3.5 Haiku, claude-opus-4-5,
  Gemini 2.0 Flash, Gemini 2.0 Pro Exp

#### Added — Android Tools (14 → 27)
- `analyze_photo` — take a photo and vision-analyze it via AI (base64 JPEG)
- `send_sms` — send an SMS to any contact
- `get_sensor` — read any Android sensor (accelerometer, gyroscope, light, …)
- `set_volume` — set stream volume (music, alarm, ring, notification, call)
- `get_volume` — read current volume levels for all streams
- `set_brightness` — set screen brightness (0–255)
- `get_call_log` — read recent call history (missed/incoming/outgoing)
- `show_dialog` — display a native Android dialog/picker and wait for input
- `open_url` — open a URL in the default browser
- `list_files` — list directory contents
- `read_file` — read a file (plain text or base64 for binary)
- `write_file` — write/append to a file
- `media_play` — play audio file via MediaPlayer

#### Added — Persistent Conversation History
- History auto-saved to `~/.nova_agent/history.json` (rolling 50-message window)
- `novax start` resumes prior conversation on relaunch
- `--no-history` flag to disable for this session
- `--clear-history` flag to wipe history and start fresh

#### Added — Interactive Mode Improvements
- `history` — print current conversation history
- `clear` — clear conversation history mid-session
- `tools` — list all 27 available tools with descriptions
- `version` — print version info
- `!<cmd>` — pass-through shell commands from inside the REPL
- Ctrl+C gracefully moves to next prompt (no crash)

#### Added — CLI Improvements
- `--version` / `-v` flag on `novax` and `nova ask`
- `lib/index.js` `printVersion()` now uses `readFileSync` instead of
  `execFileSync('cat', …)` — works on Windows/macOS dev environments too
- Updated help text lists all 27 tools with emoji categories

#### Fixed
- **Critical**: `agent_loop()` always called OpenAI regardless of configured
  provider — Anthropic and Gemini were completely broken. Fixed by proper
  `if/elif/else` dispatch.
- **Security**: `tool_set_clipboard` used shell string interpolation with
  untrusted user text — fixed by using `subprocess.run(["termux-clipboard-set"],
  input=text)` pipe instead.
- `TOOL_MAP` now covers all 27 tools (was missing entries for some tools)
- Anthropic `system` message now passed as top-level param (not in messages
  array) — prevents API 400 errors

#### Changed
- `VERSION` constant added (`1.1.0`) — printed in `--version` and `version`
  interactive command
- `SYSTEM_PROMPT` dynamically references `len(TOOL_DEFINITIONS)` so it stays
  accurate as tools are added
- ANSI color output via `class C` constants + `clr()` helper (no dependency on
  `chalk` inside Python)

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
- Persistent memory with ChromaDB / SQLite vector store
- Plugin / skill system for adding custom tools
- Web UI improvements (dark theme, real-time streaming)
- Voice input via Termux microphone + Whisper transcription
- Scheduled tasks / cron-style automation
