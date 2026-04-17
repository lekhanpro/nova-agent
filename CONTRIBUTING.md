# Contributing to Nova Agent

Thank you for helping make Nova Agent better! 🤖📱

## Ways to Contribute

### 🔧 Add a New Android Tool
The easiest and most impactful contribution. Each tool maps a `termux-*` command to an AI-callable function.

**Example — adding a sensor tool:**

1. Add the Python function in `nova_agent.py`:
```python
def tool_read_sensor(sensor: str = "accelerometer") -> str:
    """Read an Android sensor."""
    raw = run_termux(f"termux-sensor -s {sensor} -n 1", timeout=5)
    try:
        data = json.loads(raw)
        return json.dumps(data, indent=2)
    except Exception:
        return raw
```

2. Add the tool definition to `TOOL_DEFINITIONS`:
```python
{
    "type": "function",
    "function": {
        "name": "read_sensor",
        "description": "Read an Android sensor (accelerometer, gyroscope, etc.)",
        "parameters": {
            "type": "object",
            "properties": {
                "sensor": {
                    "type": "string",
                    "description": "Sensor name: accelerometer, gyroscope, magnetic_field, etc.",
                    "default": "accelerometer"
                }
            }
        }
    }
}
```

3. Register it in `TOOL_MAP`:
```python
"read_sensor": lambda a: tool_read_sensor(a.get("sensor", "accelerometer")),
```

4. Test it:
```bash
novax ask "Read the accelerometer sensor and tell me if I'm moving"
```

### 🐛 Fix a Bug
- Check existing [issues](https://github.com/lekhanpro/nova-agent/issues)
- Fix and submit a PR with a description of what you changed

### 📖 Improve Docs
- Add examples to README
- Document edge cases
- Add a new section to docs/

### 🌐 Translations
Native-language error messages and setup instructions are welcome.

## Pull Request Process

1. Fork the repo
2. Create a branch: `git checkout -b feat/my-tool` or `fix/my-bug`
3. Make your changes
4. Test on a real Android device with Termux
5. Submit a PR with:
   - What you changed
   - Why
   - A test showing it works (`novax ask "..."` output)

## Available Termux:API Commands

Here are unexplored commands waiting for contributors:

| Command | What it does |
|---------|-------------|
| `termux-sensor` | Read accelerometer, gyroscope, etc. |
| `termux-fingerprint` | Fingerprint authentication |
| `termux-call-log` | Read call history |
| `termux-media-player` | Control media playback |
| `termux-microphone-record` | Record audio |
| `termux-nfc` | Read NFC tags |
| `termux-share` | Share files/text to other apps |
| `termux-dialog` | Show native Android dialogs |
| `termux-telephony-*` | Cell info, IMEI, signal |
| `termux-volume` | Get/set volume |
| `termux-brightness` | Get/set screen brightness |

Full list: https://wiki.termux.com/wiki/Termux:API

## Code Style

- Python: PEP 8, type hints encouraged
- Shell: `shellcheck`-clean scripts, `set -uo pipefail`
- Keep tool functions small and focused
- Always handle JSON parse errors gracefully

## Community

- [GitHub Issues](https://github.com/lekhanpro/nova-agent/issues)
- [GitHub Discussions](https://github.com/lekhanpro/nova-agent/discussions)
