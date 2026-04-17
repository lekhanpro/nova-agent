#!/usr/bin/env python3
"""
Nova Agent — Your AI assistant with native Android superpowers.
Powered by OpenAI / Anthropic / Google Gemini + Termux:API

Usage:
  python nova_agent.py                 # interactive chat mode
  python nova_agent.py "take a photo and describe it"   # one-shot mode
"""

import json
import os
import subprocess
import sys
import argparse
import tempfile
import datetime
from pathlib import Path

# ──────────────────────────────────────────────────────────────────────────────
# ANDROID TOOLS (via termux-api)
# ──────────────────────────────────────────────────────────────────────────────

def run_termux(cmd: str, timeout: int = 15) -> str:
    """Run a termux-api command and return its output."""
    try:
        result = subprocess.run(
            cmd, shell=True, capture_output=True, text=True, timeout=timeout
        )
        return result.stdout.strip() or result.stderr.strip() or "(no output)"
    except subprocess.TimeoutExpired:
        return "Command timed out."
    except Exception as e:
        return f"Error: {e}"


def tool_take_photo(camera_id: int = 0) -> str:
    """Take a photo with the camera."""
    photo_path = f"/sdcard/nova_agent_{datetime.datetime.now().strftime('%Y%m%d_%H%M%S')}.jpg"
    result = run_termux(f"termux-camera-photo -c {camera_id} {photo_path}")
    if "error" in result.lower():
        return f"Failed to take photo: {result}"
    return f"Photo saved to: {photo_path}"


def tool_get_location() -> str:
    """Get current GPS location."""
    raw = run_termux("termux-location -p gps -r once", timeout=20)
    try:
        loc = json.loads(raw)
        lat  = loc.get("latitude", "?")
        lng  = loc.get("longitude", "?")
        acc  = loc.get("accuracy", "?")
        return f"Location: {lat}, {lng} (accuracy: {acc}m)\nMaps: https://maps.google.com/?q={lat},{lng}"
    except Exception:
        return f"Raw location data: {raw}"


def tool_list_sms(limit: int = 5) -> str:
    """Read recent SMS messages."""
    raw = run_termux(f"termux-sms-list -l {limit}")
    try:
        msgs = json.loads(raw)
        lines = []
        for m in msgs:
            sender = m.get("number", "Unknown")
            body   = m.get("body", "")[:100]
            date   = m.get("received", "")
            lines.append(f"From: {sender} | {date}\n  {body}")
        return "\n\n".join(lines) if lines else "No messages found."
    except Exception:
        return f"Raw SMS data: {raw}"


def tool_get_battery() -> str:
    """Get battery level and charging status."""
    raw = run_termux("termux-battery-status")
    try:
        b = json.loads(raw)
        level  = b.get("percentage", "?")
        status = b.get("status", "?")
        health = b.get("health", "?")
        temp   = b.get("temperature", "?")
        return f"Battery: {level}% | Status: {status} | Health: {health} | Temp: {temp}°C"
    except Exception:
        return f"Raw battery data: {raw}"


def tool_get_contacts(limit: int = 10) -> str:
    """Get contacts list."""
    raw = run_termux("termux-contact-list")
    try:
        contacts = json.loads(raw)[:limit]
        lines = [f"{c.get('name','?')} — {c.get('number','?')}" for c in contacts]
        return "\n".join(lines) if lines else "No contacts found."
    except Exception:
        return f"Raw contacts data: {raw}"


def tool_read_clipboard() -> str:
    """Read current clipboard content."""
    return run_termux("termux-clipboard-get")


def tool_set_clipboard(text: str) -> str:
    """Set clipboard content."""
    run_termux(f"termux-clipboard-set '{text}'")
    return f"Clipboard set to: {text}"


def tool_send_notification(title: str, message: str) -> str:
    """Send an Android notification."""
    run_termux(f'termux-notification --title "{title}" --content "{message}"')
    return f"Notification sent: [{title}] {message}"


def tool_text_to_speech(text: str) -> str:
    """Speak the given text aloud via Android TTS."""
    run_termux(f'termux-tts-speak "{text}"')
    return f"Speaking: {text}"


def tool_get_wifi_info() -> str:
    """Get current WiFi connection info."""
    raw = run_termux("termux-wifi-connectioninfo")
    try:
        w = json.loads(raw)
        ssid    = w.get("ssid", "?")
        ip      = w.get("ip", "?")
        signal  = w.get("rssi", "?")
        return f"WiFi: {ssid} | IP: {ip} | Signal: {signal} dBm"
    except Exception:
        return f"Raw WiFi data: {raw}"


def tool_vibrate(duration_ms: int = 500) -> str:
    """Vibrate the phone."""
    run_termux(f"termux-vibrate -d {duration_ms}")
    return f"Vibrated for {duration_ms}ms."


def tool_run_shell(command: str) -> str:
    """Run a shell command and return output."""
    if any(bad in command for bad in ["rm -rf", "dd if=", "mkfs", "shutdown", "reboot"]):
        return "Blocked for safety: this command is not allowed."
    return run_termux(command, timeout=30)


def tool_get_device_info() -> str:
    """Get device hostname and Termux info."""
    hostname = run_termux("hostname")
    arch     = run_termux("uname -m")
    kernel   = run_termux("uname -r")
    storage  = run_termux("df -h /sdcard 2>/dev/null | tail -1")
    return f"Device: {hostname} | Arch: {arch} | Kernel: {kernel}\nStorage: {storage}"


def tool_torch(state: str = "on") -> str:
    """Turn torch/flashlight on or off."""
    run_termux(f"termux-torch {state}")
    return f"Torch turned {state}."


# ──────────────────────────────────────────────────────────────────────────────
# TOOL REGISTRY (OpenAI function-calling format)
# ──────────────────────────────────────────────────────────────────────────────

TOOL_DEFINITIONS = [
    {
        "type": "function",
        "function": {
            "name": "take_photo",
            "description": "Take a photo with the Android camera. Saves to /sdcard/.",
            "parameters": {
                "type": "object",
                "properties": {
                    "camera_id": {
                        "type": "integer",
                        "description": "Camera ID: 0=back, 1=front",
                        "default": 0,
                    }
                },
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "get_location",
            "description": "Get the device's current GPS location with coordinates and a Google Maps link.",
            "parameters": {"type": "object", "properties": {}},
        },
    },
    {
        "type": "function",
        "function": {
            "name": "list_sms",
            "description": "Read recent SMS text messages from the device.",
            "parameters": {
                "type": "object",
                "properties": {
                    "limit": {
                        "type": "integer",
                        "description": "How many messages to retrieve (default 5)",
                        "default": 5,
                    }
                },
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "get_battery",
            "description": "Get battery level percentage, charging status, health, and temperature.",
            "parameters": {"type": "object", "properties": {}},
        },
    },
    {
        "type": "function",
        "function": {
            "name": "get_contacts",
            "description": "Retrieve contacts list from the device.",
            "parameters": {
                "type": "object",
                "properties": {
                    "limit": {
                        "type": "integer",
                        "description": "Max contacts to return",
                        "default": 10,
                    }
                },
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "read_clipboard",
            "description": "Read the current clipboard content.",
            "parameters": {"type": "object", "properties": {}},
        },
    },
    {
        "type": "function",
        "function": {
            "name": "set_clipboard",
            "description": "Set the clipboard to a given text.",
            "parameters": {
                "type": "object",
                "properties": {
                    "text": {"type": "string", "description": "Text to copy to clipboard"}
                },
                "required": ["text"],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "send_notification",
            "description": "Send an Android push notification.",
            "parameters": {
                "type": "object",
                "properties": {
                    "title":   {"type": "string", "description": "Notification title"},
                    "message": {"type": "string", "description": "Notification body"},
                },
                "required": ["title", "message"],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "text_to_speech",
            "description": "Speak text aloud using Android TTS.",
            "parameters": {
                "type": "object",
                "properties": {
                    "text": {"type": "string", "description": "Text to speak"}
                },
                "required": ["text"],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "get_wifi_info",
            "description": "Get WiFi SSID, IP address, and signal strength.",
            "parameters": {"type": "object", "properties": {}},
        },
    },
    {
        "type": "function",
        "function": {
            "name": "vibrate",
            "description": "Vibrate the phone for a given duration.",
            "parameters": {
                "type": "object",
                "properties": {
                    "duration_ms": {
                        "type": "integer",
                        "description": "Vibration duration in milliseconds",
                        "default": 500,
                    }
                },
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "run_shell",
            "description": "Run a safe shell command and return output.",
            "parameters": {
                "type": "object",
                "properties": {
                    "command": {"type": "string", "description": "Shell command to run"}
                },
                "required": ["command"],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "get_device_info",
            "description": "Get device hostname, architecture, kernel, and storage info.",
            "parameters": {"type": "object", "properties": {}},
        },
    },
    {
        "type": "function",
        "function": {
            "name": "torch",
            "description": "Turn the flashlight/torch on or off.",
            "parameters": {
                "type": "object",
                "properties": {
                    "state": {
                        "type": "string",
                        "enum": ["on", "off"],
                        "description": "Torch state",
                    }
                },
                "required": ["state"],
            },
        },
    },
]

TOOL_MAP = {
    "take_photo":        lambda a: tool_take_photo(a.get("camera_id", 0)),
    "get_location":      lambda _: tool_get_location(),
    "list_sms":          lambda a: tool_list_sms(a.get("limit", 5)),
    "get_battery":       lambda _: tool_get_battery(),
    "get_contacts":      lambda a: tool_get_contacts(a.get("limit", 10)),
    "read_clipboard":    lambda _: tool_read_clipboard(),
    "set_clipboard":     lambda a: tool_set_clipboard(a["text"]),
    "send_notification": lambda a: tool_send_notification(a["title"], a["message"]),
    "text_to_speech":    lambda a: tool_text_to_speech(a["text"]),
    "get_wifi_info":     lambda _: tool_get_wifi_info(),
    "vibrate":           lambda a: tool_vibrate(a.get("duration_ms", 500)),
    "run_shell":         lambda a: tool_run_shell(a["command"]),
    "get_device_info":   lambda _: tool_get_device_info(),
    "torch":             lambda a: tool_torch(a.get("state", "on")),
}

# ──────────────────────────────────────────────────────────────────────────────
# AGENT LOOP
# ──────────────────────────────────────────────────────────────────────────────

SYSTEM_PROMPT = """You are Nova Agent — an AI assistant running directly on an Android phone via Termux.

You have access to powerful Android tools:
- 📷 Camera (take photos)
- 📍 GPS (get location)
- 💬 SMS (read messages)
- 🔋 Battery (check status)
- 📱 Notifications (send alerts)
- 🔊 TTS (speak aloud)
- 📋 Clipboard (read/write)
- 📶 WiFi info
- 📇 Contacts
- 💡 Torch (flashlight)
- 🖥️  Shell (run commands)

Be concise, helpful, and use tools proactively when the user's request would benefit from real Android data.
Always confirm when you've completed an action.
When showing locations, include the Google Maps link.
"""


def call_openai(messages: list, api_key: str, model: str = "gpt-4o-mini") -> dict:
    """Call OpenAI chat completions with tool support."""
    try:
        from openai import OpenAI
        client = OpenAI(api_key=api_key)
        resp = client.chat.completions.create(
            model=model,
            messages=messages,
            tools=TOOL_DEFINITIONS,
            tool_choice="auto",
        )
        return resp.choices[0].message
    except ImportError:
        print("Run: pip install openai")
        sys.exit(1)


def call_anthropic(messages: list, api_key: str, model: str = "claude-3-haiku-20240307") -> dict:
    """Call Anthropic with tool support (simplified)."""
    try:
        import anthropic
        client = anthropic.Anthropic(api_key=api_key)
        # Convert tools to Anthropic format
        ant_tools = [
            {
                "name": t["function"]["name"],
                "description": t["function"]["description"],
                "input_schema": t["function"]["parameters"],
            }
            for t in TOOL_DEFINITIONS
        ]
        resp = client.messages.create(
            model=model,
            max_tokens=2048,
            system=SYSTEM_PROMPT,
            messages=messages,
            tools=ant_tools,
        )
        return resp
    except ImportError:
        print("Run: pip install anthropic")
        sys.exit(1)


def load_config() -> dict:
    """Load config from ~/.nova_agent/config.json"""
    cfg_path = Path.home() / ".nova_agent" / "config.json"
    if cfg_path.exists():
        with open(cfg_path) as f:
            return json.load(f)
    return {}


def run_tool(name: str, args: dict) -> str:
    """Execute a tool call and return the result."""
    fn = TOOL_MAP.get(name)
    if not fn:
        return f"Unknown tool: {name}"
    print(f"\n  \033[36m⚡ {name}({json.dumps(args) if args else ''})\033[0m")
    result = fn(args)
    print(f"  \033[32m→\033[0m {result[:200]}")
    return result


def agent_loop(user_input: str, config: dict, one_shot: bool = False):
    """Main agent loop with tool-calling support."""
    provider  = config.get("provider", "openai")
    api_key   = config.get("api_key", "")
    model     = config.get("model", "gpt-4o-mini")

    if not api_key:
        print("\033[31m✗ No API key configured. Run: novax configure\033[0m")
        sys.exit(1)

    messages = [
        {"role": "system", "content": SYSTEM_PROMPT},
        {"role": "user",   "content": user_input},
    ]

    print(f"\n\033[35m★ Nova Agent\033[0m [{provider}/{model}]")
    print("─" * 50)

    for _round in range(10):  # max 10 tool rounds
        if provider == "openai":
            msg = call_openai(messages, api_key, model)
        else:
            msg = call_openai(messages, api_key, model)  # fallback

        # No more tool calls — final answer
        if not getattr(msg, "tool_calls", None):
            content = getattr(msg, "content", str(msg))
            print(f"\n\033[32m◆ Nova Agent:\033[0m {content}\n")
            if not one_shot and config.get("tts"):
                tool_text_to_speech(content[:200])
            return

        # Execute tool calls
        messages.append(msg)
        for tc in msg.tool_calls:
            name   = tc.function.name
            args   = json.loads(tc.function.arguments or "{}")
            result = run_tool(name, args)
            messages.append({
                "role":         "tool",
                "tool_call_id": tc.id,
                "content":      result,
            })

    print("\033[33m⚠ Reached maximum tool rounds.\033[0m")


def interactive_mode(config: dict):
    """Interactive chat REPL."""
    print("\n\033[35m╔═══════════════════════════════════════════╗")
    print("║       Nova Agent — Android AI Assistant    ║")
    print("║  Type 'exit' to quit · 'tools' to list    ║")
    print("╚═══════════════════════════════════════════╝\033[0m\n")

    EXAMPLES = [
        "What's my battery level?",
        "Take a selfie and describe what you see",
        "Where am I right now?",
        "Read my last 3 SMS messages",
        "Set a reminder notification for 5 minutes",
    ]
    print("\033[2mExamples:\033[0m")
    for ex in EXAMPLES:
        print(f"  \033[2m• {ex}\033[0m")
    print()

    while True:
        try:
            user_input = input("\033[36mYou:\033[0m ").strip()
        except (KeyboardInterrupt, EOFError):
            print("\n\033[2mGoodbye!\033[0m")
            break

        if not user_input:
            continue
        if user_input.lower() in ("exit", "quit", "q"):
            print("\033[2mGoodbye!\033[0m")
            break
        if user_input.lower() == "tools":
            print("\n\033[35mAvailable Android tools:\033[0m")
            for t in TOOL_DEFINITIONS:
                print(f"  • {t['function']['name']} — {t['function']['description']}")
            print()
            continue

        agent_loop(user_input, config, one_shot=False)


def main():
    parser = argparse.ArgumentParser(
        description="Nova Agent — AI assistant with Android superpowers"
    )
    parser.add_argument("query", nargs="?", help="One-shot query (omit for interactive mode)")
    parser.add_argument("--provider", choices=["openai", "anthropic", "gemini"], help="AI provider")
    parser.add_argument("--model", help="Model name")
    args = parser.parse_args()

    config = load_config()
    if args.provider:
        config["provider"] = args.provider
    if args.model:
        config["model"] = args.model

    if args.query:
        agent_loop(args.query, config, one_shot=True)
    else:
        interactive_mode(config)


if __name__ == "__main__":
    main()
