# devconnect-manage

MCP server that lets AI coding assistants (Claude Code, Codex, Cursor, Windsurf, …) control a mobile device (iOS Simulator or Android Emulator/USB) via a running [DevConnect Manage Tool](https://github.com/ridelinktechs/devconnect-manage-kit) desktop app.

## Install

Install the server into your AI client via DevConnect's MCP pairing page (Settings → MCP → Copy / Run install) — the snippet looks like:

```
claude mcp add -s user --transport stdio devconnect-manage -- npx -y devconnect-manage
```

Or run it standalone:

```bash
npx devconnect-manage
```

## Requirements

- A running DevConnect desktop app with the WebSocket server started (default port `9090`).
- The mobile device you want to control must be:
  - An iOS Simulator on the same Mac (DevConnect auto-detects booted simulators), OR
  - An Android Emulator / USB device with `adb` on `$PATH` (DevConnect's existing `adb_resolver` handles this).

## Configuration

Override the desktop host/port via env vars:

```bash
DEVCONNECT_HOST=192.168.1.10 DEVCONNECT_PORT=9090 npx devconnect-manage
```

## Tools (15 — full parity with [mobile-next/mobile-mcp](https://github.com/mobile-next/mobile-mcp))

| Tool | Description |
|---|---|
| `list_devices` | List all mobile devices currently connected to the desktop. |
| `take_screenshot` | Capture a PNG screenshot of the current screen. Returns base64 + dimensions. |
| `save_screenshot` | Capture a screenshot and save it to a path on the host. |
| `list_elements_on_screen` | Return the accessibility tree (uid, label, value, frame, type). |
| `tap` | Tap at (x, y) in screen pixels. |
| `double_tap` | Double-tap at (x, y). |
| `long_press` | Press and hold at (x, y) for N ms. |
| `swipe` | Swipe from (x1, y1) → (x2, y2). |
| `type_text` | Type text into the focused input field. |
| `press_button` | Press HOME / BACK / VOLUME_UP / VOLUME_DOWN / ENTER. |
| `list_apps` | List installed apps (packageId + display name + system flag). |
| `launch_app` | Launch an app by its packageId / bundleId. |
| `terminate_app` | Force-stop the app. |
| `get_screen_size` | Screen size in pixels + current orientation. |
| `get_orientation` | Current orientation only. |
| `set_orientation` | Force portrait/landscape (simulators only). |
| `open_url` | Open a URL in the device's default browser. |

## How it works

```
┌──────────────────┐  stdio (MCP)  ┌──────────────────┐  WebSocket (JSON-RPC over WS)  ┌─────────────────────┐
│  Claude / Codex  │ ◄──────────► │  devconnect-manage  │ ◄──────────────────────────► │  DevConnect desktop  │
│  (AI client)     │   JSON-RPC   │  (this package)   │   mcp:command / mcp:response │   + adb / simctl      │
└──────────────────┘               └──────────────────┘                                └─────────────────────┘
```

The desktop translates each `mcp:command` into either:
- `adb shell input tap x y` / `adb shell screencap` / `adb shell pm list packages` … (Android)
- `xcrun simctl io booted screenshot` / `xcrun simctl launch booted <bundleId>` … (iOS sim)
- Or a desktop-native handler (e.g. `list_devices` reads the WS connection map).

## License

MIT — by [Ridelink Techs](https://github.com/ridelinktechs).