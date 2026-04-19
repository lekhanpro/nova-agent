#!/usr/bin/env python3
"""
Nova Agent — Your AI assistant with native Android superpowers.
Powered by OpenAI / Anthropic / Google Gemini + Termux:API

Usage:
  python nova_agent.py                          # interactive chat mode
  python nova_agent.py "take a photo"           # one-shot mode
  python nova_agent.py --provider gemini "..."  # override provider
  python nova_agent.py --no-history             # start fresh session
"""

import base64
import json
import os
import subprocess
import sys
import argparse
import datetime
import shlex
from pathlib import Path

VERSION = "1.1.0"

# ──────────────────────────────────────────────────────────────────────────────
# TERMINAL COLORS
# ──────────────────────────────────────────────────────────────────────────────

class C:
    RESET   = '\033[0m'
    BOLD    = '\033[1m'
    DIM     = '\033[2m'
    RED     = '\033[31m'
    GREEN   = '\033[32m'
    YELLOW  = '\033[33m'
    BLUE    = '\033[34m'
    MAGENTA = '\033[35m'
    CYAN    = '\033[36m'

def clr(color: str, text: str) -> str:
    return f"{color}{text}{C.RESET}"

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
    ts = datetime.datetime.now().strftime('%Y%m%d_%H%M%S')
    photo_path = f"/sdcard/nova_photo_{ts}.jpg"
    result = run_termux(f"termux-camera-photo -c {int(camera_id)} {shlex.quote(photo_path)}")
    if "error" in result.lower():
        return f"Failed to take photo: {result}"
    return f"Photo saved to: {photo_path}"


def tool_analyze_photo(camera_id: int = 0) -> str:
    """Take a photo and return base64 data for vision analysis."""
    ts = datetime.datetime.now().strftime('%Y%m%d_%H%M%S')
    photo_path = f"/sdcard/nova_photo_{ts}.jpg"
    result = run_termux(f"termux-camera-photo -c {int(camera_id)} {shlex.quote(photo_path)}")
    if "error" in result.lower():
        return f"Failed to take photo: {result}"
    try:
        with open(photo_path, "rb") as f:
            b64 = base64.b64encode(f.read()).decode()
        return json.dumps({"path": photo_path, "base64": b64, "mime": "image/jpeg"})
    except Exception as e:
        return f"Photo taken at {photo_path} but could not encode: {e}"


def tool_get_location() -> str:
    """Get current GPS location."""
    raw = run_termux("termux-location -p gps -r once", timeout=25)
    try:
        loc = json.loads(raw)
        lat = loc.get("latitude", "?")
        lng = loc.get("longitude", "?")
        acc = loc.get("accuracy", "?")
        alt = loc.get("altitude", "?")
        return (
            f"Location: {lat}, {lng} (accuracy: {acc}m, altitude: {alt}m)\n"
            f"Maps: https://maps.google.com/?q={lat},{lng}"
        )
    except Exception:
        return f"Raw location data: {raw}"


def tool_list_sms(limit: int = 5) -> str:
    """Read recent SMS messages."""
    raw = run_termux(f"termux-sms-list -l {int(limit)}")
    try:
        msgs = json.loads(raw)
        lines = []
        for m in msgs:
            sender = m.get("number", "Unknown")
            body   = m.get("body", "")[:200]
            date   = m.get("received", "")
            lines.append(f"From: {sender} | {date}\n  {body}")
        return "\n\n".join(lines) if lines else "No messages found."
    except Exception:
        return f"Raw SMS data: {raw}"


def tool_send_sms(phone_number: str, message: str) -> str:
    """Send an SMS message to a phone number."""
    result = subprocess.run(
        ["termux-sms-send", "-n", phone_number, message],
        capture_output=True, text=True
    )
    if result.returncode != 0:
        return f"Failed to send SMS: {result.stderr}"
    return f"SMS sent to {phone_number}."


def tool_get_battery() -> str:
    """Get battery level and charging status."""
    raw = run_termux("termux-battery-status")
    try:
        b = json.loads(raw)
        level   = b.get("percentage", "?")
        status  = b.get("status", "?")
        health  = b.get("health", "?")
        temp    = b.get("temperature", "?")
        plugged = b.get("plugged", "?")
        return f"Battery: {level}% | Status: {status} | Health: {health} | Temp: {temp}°C | Plugged: {plugged}"
    except Exception:
        return f"Raw battery data: {raw}"


def tool_get_contacts(limit: int = 10, search: str = "") -> str:
    """Get contacts list, optionally filtered by name or number."""
    raw = run_termux("termux-contact-list")
    try:
        contacts = json.loads(raw)
        if search:
            contacts = [
                c for c in contacts
                if search.lower() in c.get("name", "").lower()
                or search in c.get("number", "")
            ]
        contacts = contacts[:limit]
        lines = [f"{c.get('name','?')} — {c.get('number','?')}" for c in contacts]
        return "\n".join(lines) if lines else "No contacts found."
    except Exception:
        return f"Raw contacts data: {raw}"


def tool_read_clipboard() -> str:
    """Read current clipboard content."""
    return run_termux("termux-clipboard-get")


def tool_set_clipboard(text: str) -> str:
    """Set clipboard content safely via stdin."""
    try:
        result = subprocess.run(
            ["termux-clipboard-set"],
            input=text, text=True, capture_output=True
        )
        if result.returncode != 0:
            return f"Failed to set clipboard: {result.stderr}"
        preview = text[:80] + ("..." if len(text) > 80 else "")
        return f"Clipboard set to: {preview}"
    except Exception as e:
        return f"Error setting clipboard: {e}"


def tool_send_notification(title: str, message: str, sound: bool = False) -> str:
    """Send an Android push notification."""
    cmd = ["termux-notification", "--title", title, "--content", message]
    if sound:
        cmd.append("--sound")
    subprocess.run(cmd, capture_output=True)
    return f"Notification sent: [{title}] {message}"


def tool_text_to_speech(text: str, rate: float = 1.0) -> str:
    """Speak the given text aloud via Android TTS."""
    subprocess.run(["termux-tts-speak", "-r", str(rate), text], capture_output=True)
    return f"Speaking: {text[:80]}"


def tool_get_wifi_info() -> str:
    """Get current WiFi connection info."""
    raw = run_termux("termux-wifi-connectioninfo")
    try:
        w = json.loads(raw)
        ssid   = w.get("ssid", "?")
        bssid  = w.get("bssid", "?")
        ip     = w.get("ip", "?")
        signal = w.get("rssi", "?")
        freq   = w.get("frequency_mhz", "?")
        speed  = w.get("link_speed_mbps", "?")
        return (
            f"WiFi: {ssid} ({bssid})\n"
            f"IP: {ip} | Signal: {signal} dBm | Freq: {freq} MHz | Speed: {speed} Mbps"
        )
    except Exception:
        return f"Raw WiFi data: {raw}"


def tool_vibrate(duration_ms: int = 500) -> str:
    """Vibrate the phone."""
    run_termux(f"termux-vibrate -d {int(duration_ms)}")
    return f"Vibrated for {duration_ms}ms."


def tool_run_shell(command: str) -> str:
    """Run a safe shell command and return output."""
    BLOCKED = [
        "rm -rf /", "dd if=", "mkfs", "shutdown", "reboot",
        "> /dev/", ":(){:|:&};:",
    ]
    for bad in BLOCKED:
        if bad in command:
            return f"Blocked for safety: command contains '{bad}'."
    return run_termux(command, timeout=30)


def tool_get_device_info() -> str:
    """Get device hostname and system info."""
    hostname  = run_termux("hostname")
    arch      = run_termux("uname -m")
    kernel    = run_termux("uname -r")
    os_info   = run_termux("uname -o")
    storage   = run_termux("df -h /sdcard 2>/dev/null | tail -1")
    memory    = run_termux("free -h 2>/dev/null | grep Mem")
    cpu_cores = run_termux("nproc 2>/dev/null")
    return (
        f"Device: {hostname} | Arch: {arch} | OS: {os_info}\n"
        f"Kernel: {kernel}\nStorage: {storage}\n"
        f"Memory: {memory}\nCPU cores: {cpu_cores}"
    )


def tool_torch(state: str = "on") -> str:
    """Turn torch/flashlight on or off."""
    if state not in ("on", "off"):
        return "State must be 'on' or 'off'."
    run_termux(f"termux-torch {state}")
    return f"Torch turned {state}."


def tool_get_sensor(sensor_type: str = "all") -> str:
    """Get data from device sensors (accelerometer, gyroscope, light, etc.)."""
    raw = run_termux(f"termux-sensor -s {shlex.quote(sensor_type)} -n 1", timeout=10)
    try:
        data = json.loads(raw)
        lines = []
        for name, vals in data.items():
            v = vals.get("values", [])
            if isinstance(v, list):
                values_str = ", ".join(f"{x:.3f}" for x in v)
            else:
                values_str = str(v)
            lines.append(f"{name}: [{values_str}]")
        return "\n".join(lines) if lines else raw
    except Exception:
        return f"Sensor data: {raw[:500]}"


def tool_set_volume(stream: str = "music", volume: int = 50) -> str:
    """Set the device volume for a specific audio stream (0–100)."""
    STREAMS = ["music", "call", "ring", "alarm", "notification", "system"]
    if stream not in STREAMS:
        return f"Invalid stream. Choose from: {', '.join(STREAMS)}"
    run_termux(f"termux-volume {stream} {int(volume)}")
    return f"Volume set: {stream} → {volume}%"


def tool_get_volume() -> str:
    """Get current volume levels for all audio streams."""
    raw = run_termux("termux-volume")
    try:
        vols = json.loads(raw)
        lines = [f"{item['stream']}: {item['volume']}/{item['max_volume']}" for item in vols]
        return "\n".join(lines)
    except Exception:
        return f"Volume data: {raw}"


def tool_set_brightness(level: int = 128) -> str:
    """Set screen brightness (0–255)."""
    level = max(0, min(255, int(level)))
    run_termux(f"termux-brightness {level}")
    pct = round(level / 255 * 100)
    return f"Brightness set to {level}/255 ({pct}%)"


def tool_get_call_log(limit: int = 10) -> str:
    """Get recent call history (incoming, outgoing, missed)."""
    raw = run_termux(f"termux-call-log -l {int(limit)}")
    try:
        calls = json.loads(raw)
        lines = []
        for c in calls:
            num  = c.get("number", "?")
            kind = c.get("type", "?")
            dur  = c.get("duration", 0)
            date = c.get("date", "?")
            lines.append(f"{kind.upper():<10} {num:<15} {dur}s | {date}")
        return "\n".join(lines) if lines else "No call logs found."
    except Exception:
        return f"Raw call log: {raw}"


def tool_show_dialog(title: str, hint: str = "") -> str:
    """Show a native Android text input dialog and return what the user types."""
    cmd = ["termux-dialog", "text", "-t", title]
    if hint:
        cmd += ["-h", hint]
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=60)
        data = json.loads(result.stdout)
        code = data.get("code", -1)
        if code == -2:
            return "Dialog cancelled by user."
        return f"User entered: {data.get('text', '')}"
    except subprocess.TimeoutExpired:
        return "Dialog timed out."
    except Exception as e:
        return f"Dialog error: {e}"


def tool_open_url(url: str) -> str:
    """Open a URL in the Android browser."""
    subprocess.run(["termux-open-url", url], capture_output=True)
    return f"Opened URL: {url}"


def tool_list_files(path: str = "/sdcard") -> str:
    """List files in a directory on the device."""
    result = run_termux(f"ls -lh {shlex.quote(path)} 2>/dev/null | head -40")
    return result or f"No files found in {path}"


def tool_read_file(path: str) -> str:
    """Read a text file from the device (up to 4 KB)."""
    try:
        with open(path, "r", errors="replace") as f:
            content = f.read(4096)
        if len(content) == 4096:
            content += "\n... (truncated at 4KB)"
        return content
    except Exception as e:
        return f"Could not read file: {e}"


def tool_write_file(path: str, content: str) -> str:
    """Write text content to a file on the device."""
    try:
        Path(path).parent.mkdir(parents=True, exist_ok=True)
        with open(path, "w") as f:
            f.write(content)
        return f"File written: {path} ({len(content)} chars)"
    except Exception as e:
        return f"Could not write file: {e}"


def tool_media_play(action: str = "play", path: str = "") -> str:
    """Control media playback or play a specific file."""
    VALID = ["play", "pause", "stop", "next", "previous"]
    if action not in VALID:
        return f"Invalid action. Choose from: {', '.join(VALID)}"
    if path and action == "play":
        result = subprocess.run(
            ["termux-media-player", "play", path], capture_output=True
        )
        return f"Playing: {path}"
    run_termux(f"termux-media-player {action}")
    return f"Media player: {action}"


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
            "name": "analyze_photo",
            "description": "Take a photo with the camera and analyze its contents using computer vision. Returns a description of what's visible.",
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
            "name": "send_sms",
            "description": "Send an SMS message to a phone number.",
            "parameters": {
                "type": "object",
                "properties": {
                    "phone_number": {"type": "string", "description": "Recipient phone number"},
                    "message":      {"type": "string", "description": "Message text to send"},
                },
                "required": ["phone_number", "message"],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "get_battery",
            "description": "Get battery level %, charging status, health, temperature, and plugged state.",
            "parameters": {"type": "object", "properties": {}},
        },
    },
    {
        "type": "function",
        "function": {
            "name": "get_contacts",
            "description": "Retrieve contacts list from the device. Optionally filter by name or number.",
            "parameters": {
                "type": "object",
                "properties": {
                    "limit":  {"type": "integer", "description": "Max contacts to return", "default": 10},
                    "search": {"type": "string",  "description": "Filter by name or number substring", "default": ""},
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
            "description": "Copy text to the device clipboard.",
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
            "description": "Send an Android push notification with optional sound.",
            "parameters": {
                "type": "object",
                "properties": {
                    "title":   {"type": "string",  "description": "Notification title"},
                    "message": {"type": "string",  "description": "Notification body"},
                    "sound":   {"type": "boolean", "description": "Play sound with notification", "default": False},
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
                    "text": {"type": "string", "description": "Text to speak"},
                    "rate": {"type": "number", "description": "Speech rate multiplier (0.5–2.0)", "default": 1.0},
                },
                "required": ["text"],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "get_wifi_info",
            "description": "Get WiFi SSID, BSSID, IP address, signal strength, frequency, and link speed.",
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
            "description": "Run a safe shell command and return its output. Good for system queries and file operations.",
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
            "description": "Get device hostname, architecture, kernel, OS, memory, storage, and CPU count.",
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
    {
        "type": "function",
        "function": {
            "name": "get_sensor",
            "description": "Read data from device sensors: accelerometer, gyroscope, magnetometer, light, pressure, etc.",
            "parameters": {
                "type": "object",
                "properties": {
                    "sensor_type": {
                        "type": "string",
                        "description": "Sensor to read: 'accelerometer', 'gyroscope', 'light', 'magnetic_field', 'all', etc.",
                        "default": "all",
                    }
                },
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "set_volume",
            "description": "Set the device volume for a specific audio stream (0–100).",
            "parameters": {
                "type": "object",
                "properties": {
                    "stream": {
                        "type": "string",
                        "enum": ["music", "call", "ring", "alarm", "notification", "system"],
                        "description": "Audio stream to adjust",
                    },
                    "volume": {
                        "type": "integer",
                        "description": "Volume level 0–100",
                    },
                },
                "required": ["stream", "volume"],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "get_volume",
            "description": "Get current volume levels for all audio streams.",
            "parameters": {"type": "object", "properties": {}},
        },
    },
    {
        "type": "function",
        "function": {
            "name": "set_brightness",
            "description": "Set the screen brightness level (0=min, 255=max).",
            "parameters": {
                "type": "object",
                "properties": {
                    "level": {
                        "type": "integer",
                        "description": "Brightness 0–255",
                    }
                },
                "required": ["level"],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "get_call_log",
            "description": "Get recent call history (incoming, outgoing, missed calls).",
            "parameters": {
                "type": "object",
                "properties": {
                    "limit": {
                        "type": "integer",
                        "description": "Number of call records to retrieve",
                        "default": 10,
                    }
                },
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "show_dialog",
            "description": "Show a native Android text input dialog and return what the user types.",
            "parameters": {
                "type": "object",
                "properties": {
                    "title": {"type": "string", "description": "Dialog title"},
                    "hint":  {"type": "string", "description": "Placeholder hint text", "default": ""},
                },
                "required": ["title"],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "open_url",
            "description": "Open a URL in the Android browser.",
            "parameters": {
                "type": "object",
                "properties": {
                    "url": {"type": "string", "description": "URL to open"}
                },
                "required": ["url"],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "list_files",
            "description": "List files and directories at a given path on the device.",
            "parameters": {
                "type": "object",
                "properties": {
                    "path": {
                        "type": "string",
                        "description": "Directory path to list (default: /sdcard)",
                        "default": "/sdcard",
                    }
                },
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "read_file",
            "description": "Read a text file from the device (up to 4 KB).",
            "parameters": {
                "type": "object",
                "properties": {
                    "path": {"type": "string", "description": "Full path to the file"}
                },
                "required": ["path"],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "write_file",
            "description": "Write text content to a file on the device.",
            "parameters": {
                "type": "object",
                "properties": {
                    "path":    {"type": "string", "description": "Full path to write"},
                    "content": {"type": "string", "description": "Text content to write"},
                },
                "required": ["path", "content"],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "media_play",
            "description": "Control media playback (play/pause/stop/next/previous) or play a specific file.",
            "parameters": {
                "type": "object",
                "properties": {
                    "action": {
                        "type": "string",
                        "enum": ["play", "pause", "stop", "next", "previous"],
                        "description": "Playback action",
                        "default": "play",
                    },
                    "path": {
                        "type": "string",
                        "description": "File path to play (for 'play' action only)",
                        "default": "",
                    },
                },
            },
        },
    },
]

TOOL_MAP = {
    "take_photo":        lambda a: tool_take_photo(a.get("camera_id", 0)),
    "analyze_photo":     lambda a: tool_analyze_photo(a.get("camera_id", 0)),
    "get_location":      lambda _: tool_get_location(),
    "list_sms":          lambda a: tool_list_sms(a.get("limit", 5)),
    "send_sms":          lambda a: tool_send_sms(a["phone_number"], a["message"]),
    "get_battery":       lambda _: tool_get_battery(),
    "get_contacts":      lambda a: tool_get_contacts(a.get("limit", 10), a.get("search", "")),
    "read_clipboard":    lambda _: tool_read_clipboard(),
    "set_clipboard":     lambda a: tool_set_clipboard(a["text"]),
    "send_notification": lambda a: tool_send_notification(a["title"], a["message"], a.get("sound", False)),
    "text_to_speech":    lambda a: tool_text_to_speech(a["text"], a.get("rate", 1.0)),
    "get_wifi_info":     lambda _: tool_get_wifi_info(),
    "vibrate":           lambda a: tool_vibrate(a.get("duration_ms", 500)),
    "run_shell":         lambda a: tool_run_shell(a["command"]),
    "get_device_info":   lambda _: tool_get_device_info(),
    "torch":             lambda a: tool_torch(a.get("state", "on")),
    "get_sensor":        lambda a: tool_get_sensor(a.get("sensor_type", "all")),
    "set_volume":        lambda a: tool_set_volume(a["stream"], a["volume"]),
    "get_volume":        lambda _: tool_get_volume(),
    "set_brightness":    lambda a: tool_set_brightness(a["level"]),
    "get_call_log":      lambda a: tool_get_call_log(a.get("limit", 10)),
    "show_dialog":       lambda a: tool_show_dialog(a["title"], a.get("hint", "")),
    "open_url":          lambda a: tool_open_url(a["url"]),
    "list_files":        lambda a: tool_list_files(a.get("path", "/sdcard")),
    "read_file":         lambda a: tool_read_file(a["path"]),
    "write_file":        lambda a: tool_write_file(a["path"], a["content"]),
    "media_play":        lambda a: tool_media_play(a.get("action", "play"), a.get("path", "")),
}

# ──────────────────────────────────────────────────────────────────────────────
# AI PROVIDERS
# ──────────────────────────────────────────────────────────────────────────────

SYSTEM_PROMPT = f"""You are Nova Agent v{VERSION} — a powerful AI assistant running directly on an Android phone via Termux.

You have {len(TOOL_DEFINITIONS)} Android tools at your disposal:
- 📷 Camera     : take_photo, analyze_photo
- 📍 Location   : get_location
- 💬 SMS        : list_sms, send_sms
- 🔋 Battery    : get_battery
- 📇 Contacts   : get_contacts
- 📋 Clipboard  : read_clipboard, set_clipboard
- 🔔 Notify     : send_notification
- 🔊 Audio      : text_to_speech, set_volume, get_volume, media_play
- ☀️  Display   : set_brightness
- 📶 WiFi       : get_wifi_info
- 📳 Haptics    : vibrate
- 💡 Torch      : torch
- 🖥️  Shell     : run_shell
- 📊 Sensors    : get_sensor
- 📞 Calls      : get_call_log
- 💬 Dialog     : show_dialog
- 🌐 Browser    : open_url
- 📁 Files      : list_files, read_file, write_file
- 📱 Device     : get_device_info

Guidelines:
- Use tools proactively when real device data would help answer the user's request
- Chain multiple tools together to complete complex multi-step requests
- Always confirm completed actions with a short summary
- When showing GPS coordinates, include the Google Maps link
- Be concise and practical in your responses
"""


def _stream_openai(resp) -> "_MockMsg":
    """Collect a streamed OpenAI response into a mock message object."""
    content = ""
    tool_calls_raw: dict = {}
    print(f"\n{C.GREEN}◆ Nova Agent:{C.RESET} ", end="", flush=True)
    for chunk in resp:
        if not chunk.choices:
            continue
        delta = chunk.choices[0].delta
        if delta.content:
            print(delta.content, end="", flush=True)
            content += delta.content
        if delta.tool_calls:
            for tc in delta.tool_calls:
                idx = tc.index
                if idx not in tool_calls_raw:
                    tool_calls_raw[idx] = {"id": "", "name": "", "arguments": ""}
                if tc.id:
                    tool_calls_raw[idx]["id"] = tc.id
                if tc.function:
                    if tc.function.name:
                        tool_calls_raw[idx]["name"] += tc.function.name
                    if tc.function.arguments:
                        tool_calls_raw[idx]["arguments"] += tc.function.arguments
    print()

    class _Fn:
        def __init__(self, name, args):
            self.name = name
            self.arguments = args

    class _TC:
        def __init__(self, d):
            self.id = d["id"]
            self.function = _Fn(d["name"], d["arguments"])

    class _Msg:
        def __init__(self, content, tcs):
            self.content = content
            self.tool_calls = [_TC(d) for d in tcs.values()] if tcs else []
            self.role = "assistant"

    return _Msg(content, tool_calls_raw)


def call_openai(messages: list, api_key: str, model: str = "gpt-4o-mini",
                stream: bool = False) -> object:
    """Call OpenAI chat completions with tool support."""
    try:
        from openai import OpenAI
    except ImportError:
        print(clr(C.RED, "✗ openai not installed. Run: pip install openai"))
        sys.exit(1)

    client = OpenAI(api_key=api_key)
    resp = client.chat.completions.create(
        model=model,
        messages=messages,
        tools=TOOL_DEFINITIONS,
        tool_choice="auto",
        stream=stream,
    )
    if stream:
        return _stream_openai(resp)
    return resp.choices[0].message


def call_anthropic(messages: list, api_key: str,
                   model: str = "claude-3-5-haiku-20241022") -> object:
    """Call Anthropic Claude with tool support."""
    try:
        import anthropic as ant
    except ImportError:
        print(clr(C.RED, "✗ anthropic not installed. Run: pip install anthropic"))
        sys.exit(1)

    client = ant.Anthropic(api_key=api_key)
    ant_tools = [
        {
            "name": t["function"]["name"],
            "description": t["function"]["description"],
            "input_schema": t["function"]["parameters"],
        }
        for t in TOOL_DEFINITIONS
    ]
    # Anthropic takes system as a top-level param; strip it from messages
    ant_messages = [m for m in messages if m.get("role") != "system"]

    resp = client.messages.create(
        model=model,
        max_tokens=4096,
        system=SYSTEM_PROMPT,
        messages=ant_messages,
        tools=ant_tools,
    )

    # Wrap Anthropic response to match OpenAI interface
    class _Fn:
        def __init__(self, name, args):
            self.name = name
            self.arguments = json.dumps(args)

    class _TC:
        def __init__(self, block):
            self.id = block.id
            self.function = _Fn(block.name, block.input)

    class _Msg:
        def __init__(self, r):
            self.role = "assistant"
            self.content = "\n".join(
                b.text for b in r.content if b.type == "text"
            )
            self.tool_calls = [
                _TC(b) for b in r.content if b.type == "tool_use"
            ]
            self._raw = r.content  # keep raw blocks for Anthropic message reconstruction

    return _Msg(resp)


def call_gemini(messages: list, api_key: str,
                model: str = "gemini-2.0-flash") -> object:
    """Call Google Gemini with tool support."""
    try:
        import google.generativeai as genai
        from google.generativeai.types import FunctionDeclaration, Tool
    except ImportError:
        print(clr(C.RED, "✗ google-generativeai not installed. Run: pip install google-generativeai"))
        sys.exit(1)

    genai.configure(api_key=api_key)

    # Build Gemini-compatible tool declarations (strip 'default' from schema)
    declarations = []
    for t in TOOL_DEFINITIONS:
        fn = t["function"]
        params = fn.get("parameters", {})
        cleaned_props = {
            k: {pk: pv for pk, pv in v.items() if pk != "default"}
            for k, v in params.get("properties", {}).items()
        }
        cleaned_params = {"type": params.get("type", "object"), "properties": cleaned_props}
        if "required" in params:
            cleaned_params["required"] = params["required"]
        declarations.append(FunctionDeclaration(
            name=fn["name"],
            description=fn["description"],
            parameters=cleaned_params,
        ))

    gemini_model = genai.GenerativeModel(
        model_name=model,
        system_instruction=SYSTEM_PROMPT,
        tools=[Tool(function_declarations=declarations)],
    )

    # Convert messages to Gemini format; tool results go as user parts
    history = []
    for m in messages:
        role = m.get("role")
        if role == "system":
            continue
        elif role == "user":
            history.append({"role": "user", "parts": [m["content"]]})
        elif role == "assistant":
            if isinstance(m.get("content"), str) and m["content"]:
                history.append({"role": "model", "parts": [m["content"]]})
        elif role == "tool":
            pass  # Gemini handles tool responses inline in chat

    chat = gemini_model.start_chat(history=history[:-1] if len(history) > 1 else [])
    last_part = history[-1]["parts"][0] if history else ""
    resp = chat.send_message(last_part)

    class _Fn:
        def __init__(self, fc):
            self.name = fc.name
            self.arguments = json.dumps(dict(fc.args))

    class _TC:
        def __init__(self, fc):
            self.id = f"gemini_{fc.name}_{id(fc)}"
            self.function = _Fn(fc)

    class _Msg:
        def __init__(self, r):
            self.role = "assistant"
            self.content = ""
            self.tool_calls = []
            for part in r.parts:
                if hasattr(part, "text") and part.text:
                    self.content += part.text
                elif hasattr(part, "function_call") and part.function_call.name:
                    self.tool_calls.append(_TC(part.function_call))

    return _Msg(resp)


# ──────────────────────────────────────────────────────────────────────────────
# CONFIG & HISTORY
# ──────────────────────────────────────────────────────────────────────────────

NOVA_DIR = Path.home() / ".nova_agent"


def load_config() -> dict:
    cfg_path = NOVA_DIR / "config.json"
    if cfg_path.exists():
        with open(cfg_path) as f:
            return json.load(f)
    return {}


def load_history() -> list:
    """Load conversation history from disk."""
    hist_path = NOVA_DIR / "history.json"
    if hist_path.exists():
        try:
            with open(hist_path) as f:
                return json.load(f)
        except Exception:
            pass
    return []


def save_history(messages: list):
    """Persist conversation history (keep last 50 user/assistant turns)."""
    NOVA_DIR.mkdir(parents=True, exist_ok=True)
    keep = [
        m for m in messages
        if m.get("role") in ("user", "assistant") and isinstance(m.get("content"), str)
    ][-50:]
    with open(NOVA_DIR / "history.json", "w") as f:
        json.dump(keep, f, indent=2)


def clear_history():
    hist_path = NOVA_DIR / "history.json"
    if hist_path.exists():
        hist_path.unlink()
    print(clr(C.GREEN, "✓ Conversation history cleared."))


# ──────────────────────────────────────────────────────────────────────────────
# TOOL EXECUTION
# ──────────────────────────────────────────────────────────────────────────────

def run_tool(name: str, args: dict) -> str:
    """Dispatch a tool call and return its result."""
    fn = TOOL_MAP.get(name)
    if not fn:
        return f"Unknown tool: {name}"
    args_display = json.dumps(args)[:80] if args else ""
    print(f"\n  {C.CYAN}⚡ {name}({args_display}){C.RESET}")
    try:
        result = fn(args)
    except Exception as e:
        result = f"Tool error: {e}"
    print(f"  {C.GREEN}→{C.RESET} {str(result)[:200]}")
    return result


# ──────────────────────────────────────────────────────────────────────────────
# AGENT LOOP
# ──────────────────────────────────────────────────────────────────────────────

def agent_loop(user_input: str, config: dict, history: list,
               one_shot: bool = False) -> str:
    """Main agent loop with tool-calling support. Returns the final response."""
    provider  = config.get("provider", "openai")
    api_key   = config.get("api_key", "")
    model     = config.get("model", "gpt-4o-mini")
    do_stream = config.get("stream", False) and provider == "openai"

    if not api_key:
        print(clr(C.RED, "✗ No API key configured. Run: novax configure"))
        sys.exit(1)

    messages = [{"role": "system", "content": SYSTEM_PROMPT}]
    messages.extend(history)
    messages.append({"role": "user", "content": user_input})

    if not one_shot:
        print(f"\n{C.MAGENTA}★ Nova Agent{C.RESET} [{provider}/{model}]")
        print("─" * 50)

    for _round in range(15):  # max 15 tool-call rounds
        if provider == "anthropic":
            msg = call_anthropic(messages, api_key, model)
        elif provider == "gemini":
            msg = call_gemini(messages, api_key, model)
        else:
            msg = call_openai(messages, api_key, model,
                              stream=(do_stream and _round == 0))

        tool_calls = getattr(msg, "tool_calls", None) or []

        if not tool_calls:
            content = getattr(msg, "content", "") or ""
            if not do_stream or _round > 0:
                print(f"\n{C.GREEN}◆ Nova Agent:{C.RESET} {content}\n")
            if not one_shot and config.get("tts"):
                tool_text_to_speech(content[:200])
            return content

        # Append assistant message with tool call metadata
        tool_calls_serialized = [
            {
                "id":       tc.id,
                "type":     "function",
                "function": {
                    "name":      tc.function.name,
                    "arguments": tc.function.arguments,
                },
            }
            for tc in tool_calls
        ]
        messages.append({
            "role":       "assistant",
            "content":    getattr(msg, "content", "") or "",
            "tool_calls": tool_calls_serialized,
        })

        # Execute each tool call
        for tc in tool_calls:
            try:
                args = json.loads(tc.function.arguments or "{}")
            except json.JSONDecodeError:
                args = {}
            result = run_tool(tc.function.name, args)
            messages.append({
                "role":         "tool",
                "tool_call_id": tc.id,
                "content":      result,
            })

    msg = "⚠ Reached maximum tool-call rounds. Please try a simpler request."
    print(clr(C.YELLOW, msg))
    return msg


# ──────────────────────────────────────────────────────────────────────────────
# INTERACTIVE MODE
# ──────────────────────────────────────────────────────────────────────────────

def interactive_mode(config: dict, load_prev_history: bool = True):
    """Interactive chat REPL with persistent multi-turn conversation history."""
    print(f"\n{C.MAGENTA}{C.BOLD}╔═══════════════════════════════════════════════╗")
    print(f"║    Nova Agent v{VERSION}  ·  Android AI Assistant  ║")
    print(f"║  'exit' quit · 'tools' list · 'history' view  ║")
    print(f"║  'clear' reset history · '!cmd' run shell     ║")
    print(f"╚═══════════════════════════════════════════════╝{C.RESET}\n")

    EXAMPLES = [
        "What's my battery level and WiFi status?",
        "Take a selfie and describe what you see",
        "Where am I? Show me on Google Maps",
        "Read my last 3 SMS messages",
        "Set volume to 50% and turn on the torch",
        "What sensors does this phone have?",
        "Write a haiku to /sdcard/nova_haiku.txt",
    ]
    print(f"{C.DIM}Try asking:{C.RESET}")
    for ex in EXAMPLES:
        print(f"  {C.DIM}• {ex}{C.RESET}")
    print()

    history = load_history() if load_prev_history else []
    if history:
        print(f"  {C.DIM}↩ Loaded {len(history)} messages from previous session.{C.RESET}\n")

    provider = config.get("provider", "openai")
    model    = config.get("model", "gpt-4o-mini")
    print(f"  {C.DIM}Provider: {provider} | Model: {model}{C.RESET}\n")

    while True:
        try:
            user_input = input(f"{C.CYAN}You:{C.RESET} ").strip()
        except (KeyboardInterrupt, EOFError):
            print(f"\n{C.DIM}Goodbye!{C.RESET}")
            break

        if not user_input:
            continue

        lower = user_input.lower()

        if lower in ("exit", "quit", "q", "bye"):
            print(f"{C.DIM}Goodbye!{C.RESET}")
            break

        if lower == "tools":
            print(f"\n{C.MAGENTA}Available tools ({len(TOOL_DEFINITIONS)}):{C.RESET}")
            for t in TOOL_DEFINITIONS:
                name = t["function"]["name"]
                desc = t["function"]["description"]
                print(f"  {C.CYAN}•{C.RESET} {name:<22} {C.DIM}{desc}{C.RESET}")
            print()
            continue

        if lower == "history":
            if not history:
                print(f"  {C.DIM}No conversation history yet.{C.RESET}\n")
            else:
                print(f"\n{C.MAGENTA}Conversation history ({len(history)} messages):{C.RESET}")
                for m in history[-20:]:
                    role_color = C.CYAN if m["role"] == "user" else C.GREEN
                    snippet = str(m.get("content", ""))[:100]
                    print(f"  {role_color}{m['role'].upper():<12}{C.RESET} {snippet}")
                print()
            continue

        if lower in ("clear", "reset"):
            history.clear()
            clear_history()
            print()
            continue

        if lower == "version":
            print(f"  nova-agent v{VERSION}\n")
            continue

        # Shell passthrough: !command
        if user_input.startswith("!"):
            result = tool_run_shell(user_input[1:].strip())
            print(f"  {C.GREEN}{result}{C.RESET}\n")
            continue

        response = agent_loop(user_input, config, history, one_shot=False)

        history.append({"role": "user",      "content": user_input})
        history.append({"role": "assistant",  "content": response})
        save_history(history)


# ──────────────────────────────────────────────────────────────────────────────
# ENTRY POINT
# ──────────────────────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(
        description=f"Nova Agent v{VERSION} — AI assistant with Android superpowers",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python nova_agent.py                              # interactive chat
  python nova_agent.py "What's my battery?"         # one-shot query
  python nova_agent.py --provider gemini "Where am I?"
  python nova_agent.py --model gpt-4o "analyze my surroundings"
  python nova_agent.py --no-history                 # start fresh session
  python nova_agent.py --clear-history              # wipe stored history
        """,
    )
    parser.add_argument("query",             nargs="?",            help="One-shot query")
    parser.add_argument("--provider",        choices=["openai", "anthropic", "gemini"],
                        help="AI provider override")
    parser.add_argument("--model",           help="Model name override")
    parser.add_argument("--no-history",      action="store_true",  help="Don't load previous history")
    parser.add_argument("--clear-history",   action="store_true",  help="Clear stored history and exit")
    parser.add_argument("--version", "-v",   action="store_true",  help="Print version and exit")
    args = parser.parse_args()

    if args.version:
        print(f"nova-agent v{VERSION}")
        sys.exit(0)

    if args.clear_history:
        clear_history()
        sys.exit(0)

    config = load_config()
    if args.provider:
        config["provider"] = args.provider
    if args.model:
        config["model"] = args.model

    if args.query:
        agent_loop(args.query, config, [], one_shot=True)
    else:
        interactive_mode(config, load_prev_history=not args.no_history)


if __name__ == "__main__":
    main()
