import { DesktopClient } from './desktop-client.js';
import {
  AppInfo,
  Device,
  McpCommand,
  OrientationResult,
  ScreenSizeResult,
  ScreenshotResult,
  UiElement,
} from './types.js';
import {
  Server,
} from '@modelcontextprotocol/sdk/server/index.js';
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} from '@modelcontextprotocol/sdk/types.js';
import type {
  CallToolResult,
} from '@modelcontextprotocol/sdk/types.js';

/**
 * Register all 15 MCP tools. Each tool is a thin wrapper that maps its
 * MCP argument schema to a [McpCommand] sent over the desktop WebSocket.
 *
 * If the desktop returns `{ ok: false, error: ... }`, we surface the
 * error string to the AI client as the tool result.
 */
export function registerTools(server: Server, desktop: DesktopClient) {
  server.setRequestHandler(CallToolRequestSchema, async (request) => {
    const args = (request.params.arguments ?? {}) as Record<string, unknown>;
    return (await callTool(request.params.name, args, desktop)) as CallToolResult;
  });

  server.setRequestHandler(ListToolsRequestSchema, async () => {
    return { tools: TOOL_SCHEMAS as any };
  });
}

async function callTool(name: string, args: Record<string, unknown>, desktop: DesktopClient) {
  try {
    switch (name) {
      // ── Device discovery ──
      case 'list_devices': {
        return wrap(await desktop.sendCommand<Device[]>({ kind: 'list_devices' }));
      }

      // ── Screen capture ──
      case 'take_screenshot': {
        const deviceId = str(args, 'deviceId');
        return wrap(await desktop.sendCommand<ScreenshotResult>({ kind: 'take_screenshot', deviceId }));
      }
      case 'save_screenshot': {
        const deviceId = str(args, 'deviceId');
        const path = str(args, 'path');
        return wrap(await desktop.sendCommand<{ path: string }>({ kind: 'save_screenshot', deviceId, path }));
      }

      // ── Accessibility ──
      case 'list_elements_on_screen': {
        const deviceId = str(args, 'deviceId');
        return wrap(await desktop.sendCommand<UiElement[]>({ kind: 'list_elements_on_screen', deviceId }));
      }

      // ── Input — taps ──
      case 'tap': {
        const deviceId = str(args, 'deviceId');
        const x = num(args, 'x');
        const y = num(args, 'y');
        return wrap(await desktop.sendCommand({ kind: 'tap', deviceId, x, y }));
      }
      case 'double_tap': {
        const deviceId = str(args, 'deviceId');
        const x = num(args, 'x');
        const y = num(args, 'y');
        return wrap(await desktop.sendCommand({ kind: 'double_tap', deviceId, x, y }));
      }
      case 'long_press': {
        const deviceId = str(args, 'deviceId');
        const x = num(args, 'x');
        const y = num(args, 'y');
        const durationMs = num(args, 'durationMs', 500);
        return wrap(await desktop.sendCommand({ kind: 'long_press', deviceId, x, y, durationMs }));
      }

      // ── Input — gestures ──
      case 'swipe': {
        const deviceId = str(args, 'deviceId');
        const x1 = num(args, 'x1');
        const y1 = num(args, 'y1');
        const x2 = num(args, 'x2');
        const y2 = num(args, 'y2');
        const durationMs = args.durationMs != null ? num(args, 'durationMs') : undefined;
        return wrap(await desktop.sendCommand({ kind: 'swipe', deviceId, x1, y1, x2, y2, durationMs }));
      }
      case 'drag_and_drop': {
        const deviceId = str(args, 'deviceId');
        const x1 = num(args, 'x1');
        const y1 = num(args, 'y1');
        const x2 = num(args, 'x2');
        const y2 = num(args, 'y2');
        const durationMs = args.durationMs != null ? num(args, 'durationMs') : undefined;
        return wrap(await desktop.sendCommand({ kind: 'drag_and_drop', deviceId, x1, y1, x2, y2, durationMs }));
      }

      // ── Input — keyboard ──
      case 'type_text': {
        const deviceId = str(args, 'deviceId');
        const text = str(args, 'text');
        return wrap(await desktop.sendCommand({ kind: 'type_text', deviceId, text }));
      }
      case 'press_button': {
        const deviceId = str(args, 'deviceId');
        const button = str(args, 'button') as 'HOME' | 'BACK' | 'VOLUME_UP' | 'VOLUME_DOWN' | 'ENTER';
        return wrap(await desktop.sendCommand({ kind: 'press_button', deviceId, button }));
      }

      // ── File transfer ──
      case 'push_file': {
        const deviceId = str(args, 'deviceId');
        const localPath = str(args, 'localPath');
        const remotePath = str(args, 'remotePath');
        const packageId = args.packageId ? String(args.packageId) : undefined;
        return wrap(await desktop.sendCommand({ kind: 'push_file', deviceId, localPath, remotePath, packageId }));
      }
      case 'pull_file': {
        const deviceId = str(args, 'deviceId');
        const remotePath = str(args, 'remotePath');
        const localPath = str(args, 'localPath');
        const packageId = args.packageId ? String(args.packageId) : undefined;
        return wrap(await desktop.sendCommand({ kind: 'pull_file', deviceId, remotePath, localPath, packageId }));
      }

      // ── Screen recording ──
      case 'start_screen_recording': {
        const deviceId = str(args, 'deviceId');
        const path = args.path ? String(args.path) : undefined;
        return wrap(await desktop.sendCommand({ kind: 'start_screen_recording', deviceId, path }));
      }
      case 'stop_screen_recording': {
        const deviceId = str(args, 'deviceId');
        const path = args.path ? String(args.path) : undefined;
        return wrap(await desktop.sendCommand({ kind: 'stop_screen_recording', deviceId, path }));
      }
      case 'get_react_hierarchy': {
        const deviceId = str(args, 'deviceId');
        return wrap(await desktop.sendCommand({ kind: 'get_react_hierarchy', deviceId }));
      }

      // ── Apps ──
      case 'list_apps': {
        const deviceId = str(args, 'deviceId');
        return wrap(await desktop.sendCommand<AppInfo[]>({ kind: 'list_apps', deviceId }));
      }
      case 'launch_app': {
        const deviceId = str(args, 'deviceId');
        const packageId = str(args, 'packageId');
        return wrap(await desktop.sendCommand({ kind: 'launch_app', deviceId, packageId }));
      }
      case 'terminate_app': {
        const deviceId = str(args, 'deviceId');
        const packageId = str(args, 'packageId');
        return wrap(await desktop.sendCommand({ kind: 'terminate_app', deviceId, packageId }));
      }

      // ── Screen geometry ──
      case 'get_screen_size': {
        const deviceId = str(args, 'deviceId');
        return wrap(await desktop.sendCommand<ScreenSizeResult>({ kind: 'get_screen_size', deviceId }));
      }
      case 'get_orientation': {
        const deviceId = str(args, 'deviceId');
        return wrap(await desktop.sendCommand<OrientationResult>({ kind: 'get_orientation', deviceId }));
      }
      case 'set_orientation': {
        const deviceId = str(args, 'deviceId');
        const orientation = str(args, 'orientation') as 'portrait' | 'landscape';
        return wrap(await desktop.sendCommand({ kind: 'set_orientation', deviceId, orientation }));
      }

      // ── Misc ──
      case 'open_url': {
        const deviceId = str(args, 'deviceId');
        const url = str(args, 'url');
        return wrap(await desktop.sendCommand({ kind: 'open_url', deviceId, url }));
      }
      case 'push_file': {
        const deviceId = str(args, 'deviceId');
        const localPath = str(args, 'localPath');
        const remotePath = str(args, 'remotePath');
        const packageId = args.packageId as string | undefined;
        return wrap(await desktop.sendCommand({ kind: 'push_file', deviceId, localPath, remotePath, packageId }));
      }
      case 'pull_file': {
        const deviceId = str(args, 'deviceId');
        const remotePath = str(args, 'remotePath');
        const localPath = str(args, 'localPath');
        const packageId = args.packageId as string | undefined;
        return wrap(await desktop.sendCommand({ kind: 'pull_file', deviceId, remotePath, localPath, packageId }));
      }
      case 'start_screen_recording': {
        const deviceId = str(args, 'deviceId');
        const path = args.path as string | undefined;
        return wrap(await desktop.sendCommand({ kind: 'start_screen_recording', deviceId, path }));
      }
      case 'stop_screen_recording': {
        const deviceId = str(args, 'deviceId');
        const path = args.path as string | undefined;
        return wrap(await desktop.sendCommand({ kind: 'stop_screen_recording', deviceId, path }));
      }
      case 'clear_app_data': {
        const deviceId = str(args, 'deviceId');
        const packageId = str(args, 'packageId');
        return wrap(await desktop.sendCommand({ kind: 'clear_app_data', deviceId, packageId }));
      }
      case 'install_app': {
        const deviceId = str(args, 'deviceId');
        const localPath = str(args, 'localPath');
        return wrap(await desktop.sendCommand({ kind: 'install_app', deviceId, localPath }));
      }
      case 'uninstall_app': {
        const deviceId = str(args, 'deviceId');
        const packageId = str(args, 'packageId');
        return wrap(await desktop.sendCommand({ kind: 'uninstall_app', deviceId, packageId }));
      }
      case 'run_adb_command': {
        const deviceId = str(args, 'deviceId');
        const adbArgs = args.adbArgs as string[];
        if (!Array.isArray(adbArgs)) {
          throw new Error('adbArgs must be an array of strings');
        }
        return wrap(await desktop.sendCommand({ kind: 'run_adb_command', deviceId, adbArgs }));
      }

      // ────────────────────────────────────────────────────────────────
      // DevConnect-specific telemetry reads — the AI debugger's
      // "what just happened in the app?" tools.
      // ────────────────────────────────────────────────────────────────

      case 'get_recent_logs': {
        const deviceId = args.deviceId as string | undefined;
        const level = args.level as string | undefined;
        const query = args.query as string | undefined;
        const limit = args.limit != null ? num(args, 'limit') : 100;
        return wrap(await desktop.sendCommand({
          kind: 'get_recent_logs', deviceId, level, query, limit,
        }));
      }

      case 'get_recent_requests': {
        const deviceId = args.deviceId as string | undefined;
        const urlPattern = args.urlPattern as string | undefined;
        const method = args.method as string | undefined;
        const statusMin = args.statusMin as number | undefined;
        const statusMax = args.statusMax as number | undefined;
        const query = args.query as string | undefined;
        const limit = args.limit != null ? num(args, 'limit') : 100;
        return wrap(await desktop.sendCommand({
          kind: 'get_recent_requests',
          deviceId, urlPattern, method, statusMin, statusMax, query, limit,
        }));
      }

      case 'get_request_detail': {
        const requestId = str(args, 'requestId');
        return wrap(await desktop.sendCommand({
          kind: 'get_request_detail', requestId,
        }));
      }

      case 'get_store_list': {
        const deviceId = args.deviceId as string | undefined;
        return wrap(await desktop.sendCommand({
          kind: 'get_store_list', deviceId,
        }));
      }

      case 'get_store_state': {
        const storeId = str(args, 'storeId');
        return wrap(await desktop.sendCommand({
          kind: 'get_store_state', storeId,
        }));
      }

      case 'get_recent_dispatches': {
        const storeId = str(args, 'storeId');
        const limit = args.limit != null ? num(args, 'limit') : 20;
        return wrap(await desktop.sendCommand({
          kind: 'get_recent_dispatches', storeId, limit,
        }));
      }

      case 'get_storage_keys': {
        const deviceId = args.deviceId as string | undefined;
        const backend = args.backend as string | undefined;
        return wrap(await desktop.sendCommand({
          kind: 'get_storage_keys', deviceId, backend,
        }));
      }

      case 'read_storage_value': {
        const key = str(args, 'key');
        const backend = str(args, 'backend');
        return wrap(await desktop.sendCommand({
          kind: 'read_storage_value', key, backend,
        }));
      }

      case 'get_performance_snapshot': {
        const deviceId = args.deviceId as string | undefined;
        return wrap(await desktop.sendCommand({
          kind: 'get_performance_snapshot', deviceId,
        }));
      }

      case 'get_recent_errors': {
        const deviceId = args.deviceId as string | undefined;
        const severity = args.severity as string | undefined;
        const limit = args.limit != null ? num(args, 'limit') : 100;
        return wrap(await desktop.sendCommand({
          kind: 'get_recent_errors', deviceId, severity, limit,
        }));
      }

      case 'get_recent_crashes': {
        const deviceId = args.deviceId as string | undefined;
        const platform = args.platform as string | undefined;
        const limit = args.limit != null ? num(args, 'limit') : 20;
        return wrap(await desktop.sendCommand({
          kind: 'get_recent_crashes', deviceId, platform, limit,
        }));
      }

      case 'get_database_schema': {
        const backend = (args.backend as string | undefined) ?? 'sqlite';
        return wrap(await desktop.sendCommand({
          kind: 'get_database_schema', backend,
        }));
      }

      default:
        return errorResult(`Unknown tool: ${name}`);
    }
  } catch (e) {
    return errorResult(e instanceof Error ? e.message : String(e));
  }
}

function str(args: Record<string, unknown>, key: string): string {
  const v = args[key];
  if (typeof v !== 'string' || !v) {
    throw new Error(`Missing or invalid string argument: ${key}`);
  }
  return v;
}

function num(args: Record<string, unknown>, key: string, fallback?: number): number {
  const v = args[key];
  if (v == null && fallback !== undefined) return fallback;
  if (typeof v !== 'number' || !Number.isFinite(v)) {
    throw new Error(`Missing or invalid number argument: ${key}`);
  }
  return v;
}

function wrap<T>(result: { ok: true; data: T } | { ok: false; error: string }) {
  if (result.ok) {
    return { content: [{ type: 'text' as const, text: JSON.stringify(result.data) }] };
  }
  return errorResult(result.error);
}

function errorResult(message: string) {
  return { content: [{ type: 'text' as const, text: `Error: ${message}` }], isError: true };
}

// ── Tool schemas (advertised to the AI client via tools/list) ───────────

const TOOL_SCHEMAS = [
  {
    name: 'list_devices',
    description: 'List all mobile devices (iOS simulators + Android emulators/USB) currently connected to this DevConnect desktop.',
    inputSchema: { type: 'object', properties: {}, required: [] },
  },
  {
    name: 'take_screenshot',
    description: 'Capture a PNG screenshot of the current screen of the given device. Returns base64-encoded PNG plus dimensions.',
    inputSchema: {
      type: 'object',
      properties: { deviceId: { type: 'string', description: 'Device id returned by list_devices.' } },
      required: ['deviceId'],
    },
  },
  {
    name: 'save_screenshot',
    description: 'Capture a screenshot and save it to a file path on the host desktop.',
    inputSchema: {
      type: 'object',
      properties: {
        deviceId: { type: 'string' },
        path: { type: 'string', description: 'Absolute path on the host machine. Will be overwritten if it exists.' },
      },
      required: ['deviceId', 'path'],
    },
  },
  {
    name: 'start_screen_recording',
    description: 'Start screen recording on the device.',
    inputSchema: {
      type: 'object',
      properties: {
        deviceId: { type: 'string' },
        path: { type: 'string', description: 'Optional host path to write the finalized MP4 file.' },
      },
      required: ['deviceId'],
    },
  },
  {
    name: 'stop_screen_recording',
    description: 'Stop the active screen recording and return the saved MP4 file path.',
    inputSchema: {
      type: 'object',
      properties: {
        deviceId: { type: 'string' },
        path: { type: 'string', description: 'Optional host path to write the finalized MP4 file.' },
      },
      required: ['deviceId'],
    },
  },
  {
    name: 'list_elements_on_screen',
    description: 'Return the accessibility tree of elements currently visible on screen (uid, label, value, frame, type). Use the uid for subsequent tap calls.',
    inputSchema: {
      type: 'object',
      properties: { deviceId: { type: 'string' } },
      required: ['deviceId'],
    },
  },
  {
    name: 'tap',
    description: 'Tap at (x, y) on the device screen. Coordinates are in screen pixels.',
    inputSchema: {
      type: 'object',
      properties: {
        deviceId: { type: 'string' },
        x: { type: 'number' },
        y: { type: 'number' },
      },
      required: ['deviceId', 'x', 'y'],
    },
  },
  {
    name: 'double_tap',
    description: 'Double-tap at (x, y).',
    inputSchema: {
      type: 'object',
      properties: {
        deviceId: { type: 'string' },
        x: { type: 'number' },
        y: { type: 'number' },
      },
      required: ['deviceId', 'x', 'y'],
    },
  },
  {
    name: 'long_press',
    description: 'Press and hold at (x, y) for durationMs milliseconds.',
    inputSchema: {
      type: 'object',
      properties: {
        deviceId: { type: 'string' },
        x: { type: 'number' },
        y: { type: 'number' },
        durationMs: { type: 'number', description: 'Default 500.' },
      },
      required: ['deviceId', 'x', 'y'],
    },
  },
  {
    name: 'swipe',
    description: 'Swipe from (x1, y1) to (x2, y2). Optionally provide durationMs (default 300).',
    inputSchema: {
      type: 'object',
      properties: {
        deviceId: { type: 'string' },
        x1: { type: 'number' },
        y1: { type: 'number' },
        x2: { type: 'number' },
        y2: { type: 'number' },
        durationMs: { type: 'number' },
      },
      required: ['deviceId', 'x1', 'y1', 'x2', 'y2'],
    },
  },
  {
    name: 'drag_and_drop',
    description: 'Drag and drop from (x1, y1) to (x2, y2). Optionally provide durationMs (default 1000).',
    inputSchema: {
      type: 'object',
      properties: {
        deviceId: { type: 'string' },
        x1: { type: 'number' },
        y1: { type: 'number' },
        x2: { type: 'number' },
        y2: { type: 'number' },
        durationMs: { type: 'number' },
      },
      required: ['deviceId', 'x1', 'y1', 'x2', 'y2'],
    },
  },
  {
    name: 'type_text',
    description: 'Type text into the focused input field on the device. Use list_elements_on_screen first to find an input and tap it to focus.',
    inputSchema: {
      type: 'object',
      properties: {
        deviceId: { type: 'string' },
        text: { type: 'string' },
      },
      required: ['deviceId', 'text'],
    },
  },
  {
    name: 'press_button',
    description: 'Press a hardware button (HOME, BACK, VOLUME_UP, VOLUME_DOWN, ENTER). BACK is Android only.',
    inputSchema: {
      type: 'object',
      properties: {
        deviceId: { type: 'string' },
        button: { type: 'string', enum: ['HOME', 'BACK', 'VOLUME_UP', 'VOLUME_DOWN', 'ENTER'] },
      },
      required: ['deviceId', 'button'],
    },
  },
  {
    name: 'push_file',
    description: 'Push a file from the host machine to the device storage or app container.',
    inputSchema: {
      type: 'object',
      properties: {
        deviceId: { type: 'string' },
        localPath: { type: 'string', description: 'Absolute path to the local file on the host machine.' },
        remotePath: { type: 'string', description: 'Destination path on the device (absolute for Android, relative to app container for iOS).' },
        packageId: { type: 'string', description: 'Optional app package ID / bundle ID (required for iOS container push).' },
      },
      required: ['deviceId', 'localPath', 'remotePath'],
    },
  },
  {
    name: 'pull_file',
    description: 'Pull a file from the device to the host machine.',
    inputSchema: {
      type: 'object',
      properties: {
        deviceId: { type: 'string' },
        remotePath: { type: 'string', description: 'Source path on the device (absolute for Android, relative to app container for iOS).' },
        localPath: { type: 'string', description: 'Destination path on the host machine.' },
        packageId: { type: 'string', description: 'Optional app package ID / bundle ID (required for iOS container pull).' },
      },
      required: ['deviceId', 'remotePath', 'localPath'],
    },
  },
  {
    name: 'list_apps',
    description: 'List installed apps on the device (packageId + display name + system flag).',
    inputSchema: {
      type: 'object',
      properties: { deviceId: { type: 'string' } },
      required: ['deviceId'],
    },
  },
  {
    name: 'launch_app',
    description: 'Launch an app on the device by its packageId / bundleId.',
    inputSchema: {
      type: 'object',
      properties: {
        deviceId: { type: 'string' },
        packageId: { type: 'string', description: 'Android package id (com.example.app) or iOS bundle id.' },
      },
      required: ['deviceId', 'packageId'],
    },
  },
  {
    name: 'terminate_app',
    description: 'Force-stop / kill the app identified by packageId.',
    inputSchema: {
      type: 'object',
      properties: {
        deviceId: { type: 'string' },
        packageId: { type: 'string' },
      },
      required: ['deviceId', 'packageId'],
    },
  },
  {
    name: 'get_screen_size',
    description: 'Return device screen size in pixels + current orientation.',
    inputSchema: {
      type: 'object',
      properties: { deviceId: { type: 'string' } },
      required: ['deviceId'],
    },
  },
  {
    name: 'get_orientation',
    description: 'Return current device orientation (portrait / landscape).',
    inputSchema: {
      type: 'object',
      properties: { deviceId: { type: 'string' } },
      required: ['deviceId'],
    },
  },
  {
    name: 'set_orientation',
    description: 'Force the device into portrait or landscape (simulators only — physical devices ignore this).',
    inputSchema: {
      type: 'object',
      properties: {
        deviceId: { type: 'string' },
        orientation: { type: 'string', enum: ['portrait', 'landscape'] },
      },
      required: ['deviceId', 'orientation'],
    },
  },
  {
    name: 'open_url',
    description: 'Open a URL in the device\'s default browser.',
    inputSchema: {
      type: 'object',
      properties: {
        deviceId: { type: 'string' },
        url: { type: 'string' },
      },
      required: ['deviceId', 'url'],
    },
  },
  // ════════════════════════════════════════════════════════════════════
  // DevConnect-specific telemetry — the AI debugger's reading tools.
  // These read from the in-memory event buffers that the desktop has
  // captured from devices running DevConnect SDK. All read; nothing
  // here triggers anything on the device itself.
  // ════════════════════════════════════════════════════════════════════

  {
    name: 'get_recent_logs',
    description: 'Return the most recent console logs captured by the DevConnect SDK on the given device. Filter by level (log/debug/info/warn/error).',
    inputSchema: {
      type: 'object',
      properties: {
        deviceId: { type: 'string', description: 'Filter to one device. Omit to read from all devices.' },
        level: { type: 'string', enum: ['log', 'debug', 'info', 'warn', 'error'] },
        query: { type: 'string', description: 'Filter entries by a search keyword (e.g. "auth" or "failure").' },
        limit: { type: 'number', description: 'Default 100.' },
      },
    },
  },
  {
    name: 'get_recent_requests',
    description: 'Return recent HTTP requests captured by the SDK. Useful for diagnosing API calls. Each entry has method/url/timing; use get_request_detail for the full body.',
    inputSchema: {
      type: 'object',
      properties: {
        deviceId: { type: 'string' },
        urlPattern: { type: 'string', description: 'Substring match on URL.' },
        method: { type: 'string', enum: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE'] },
        statusMin: { type: 'number' },
        statusMax: { type: 'number' },
        query: { type: 'string', description: 'Filter requests by a search keyword in URL or error message.' },
        limit: { type: 'number', description: 'Default 100.' },
      },
    },
  },
  {
    name: 'get_request_detail',
    description: 'Return the full record for one request by id, including method/url/timing/error.',
    inputSchema: {
      type: 'object',
      properties: {
        requestId: { type: 'string' },
      },
      required: ['requestId'],
    },
  },
  {
    name: 'get_store_list',
    description: 'Return the list of state-management stores currently registered on any device (Redux/Zustand/MobX/Jotai/Valtio/XState).',
    inputSchema: {
      type: 'object',
      properties: {
        deviceId: { type: 'string' },
      },
    },
  },
  {
    name: 'get_store_state',
    description: 'Return the latest snapshot of state for a single store. Use get_store_list first to discover storeId values.',
    inputSchema: {
      type: 'object',
      properties: {
        storeId: { type: 'string', description: 'e.g. "Redux:AuthStore", "Zustand:cart"' },
      },
      required: ['storeId'],
    },
  },
  {
    name: 'get_recent_dispatches',
    description: 'Return the most recent actions dispatched to a store, with previousState → nextState diff per action.',
    inputSchema: {
      type: 'object',
      properties: {
        storeId: { type: 'string' },
        limit: { type: 'number', description: 'Default 20.' },
      },
      required: ['storeId'],
    },
  },
  {
    name: 'get_storage_keys',
    description: 'Return all storage entries currently known across backends (async_storage/mmkv/sqlite/…). Optionally filter by backend or device.',
    inputSchema: {
      type: 'object',
      properties: {
        deviceId: { type: 'string' },
        backend: { type: 'string', description: 'async_storage, mmkv, sqlite, sqflite, watermelondb, encrypted_storage, hive, …' },
      },
    },
  },
  {
    name: 'read_storage_value',
    description: 'Return the most recent value of a single storage key. Encrypted backends return the raw ciphertext string.',
    inputSchema: {
      type: 'object',
      properties: {
        key: { type: 'string' },
        backend: { type: 'string', description: 'Same values as get_storage_keys.' },
      },
      required: ['key', 'backend'],
    },
  },
  {
    name: 'get_performance_snapshot',
    description: 'Return the latest value per performance metric (FPS, JS thread ms, used memory MB, …). Use this to detect jank/memory leaks.',
    inputSchema: {
      type: 'object',
      properties: {
        deviceId: { type: 'string' },
      },
    },
  },
  {
    name: 'get_recent_errors',
    description: 'Return recent JS errors + promise rejections captured by the SDK. Filter by severity.',
    inputSchema: {
      type: 'object',
      properties: {
        deviceId: { type: 'string' },
        severity: { type: 'string', enum: ['warning', 'error', 'fatal'] },
        limit: { type: 'number', description: 'Default 100.' },
      },
    },
  },
  {
    name: 'get_recent_crashes',
    description: 'Return recent native crashes (iOS crash reports, Android NDK/JNI crashes). Each carries a raw stack trace.',
    inputSchema: {
      type: 'object',
      properties: {
        deviceId: { type: 'string' },
        platform: { type: 'string', enum: ['ios', 'android'] },
        limit: { type: 'number', description: 'Default 20.' },
      },
    },
  },
  {
    name: 'get_database_schema',
    description: 'Return the most recent SQLite/database schema dump captured by the SDK (tables + columns). Backend defaults to sqlite.',
    inputSchema: {
      type: 'object',
      properties: {
        backend: { type: 'string', description: 'sqlite, sqflite, sqldelight, watermelondb, realm. Default: sqlite.' },
      },
    },
  },
  {
    name: 'get_react_hierarchy',
    description: 'Get the React Native component tree hierarchy (components, props, states) from the connected app.',
    inputSchema: {
      type: 'object',
      properties: {
        deviceId: { type: 'string', description: 'Device id returned by list_devices.' },
      },
      required: ['deviceId'],
    },
  },
  {
    name: 'push_file',
    description: 'Copy a local file from the host machine to the mobile device/simulator.',
    inputSchema: {
      type: 'object',
      properties: {
        deviceId: { type: 'string' },
        localPath: { type: 'string', description: 'Absolute path on the host machine.' },
        remotePath: { type: 'string', description: 'Relative path in the device app container / storage.' },
        packageId: { type: 'string', description: 'Required for iOS non-media files or sandboxed folders.' },
      },
      required: ['deviceId', 'localPath', 'remotePath'],
    },
  },
  {
    name: 'pull_file',
    description: 'Copy a file from the mobile device/simulator back to the host machine.',
    inputSchema: {
      type: 'object',
      properties: {
        deviceId: { type: 'string' },
        remotePath: { type: 'string', description: 'Relative path in the device app container / storage.' },
        localPath: { type: 'string', description: 'Absolute path on the host machine.' },
        packageId: { type: 'string', description: 'Required for iOS files.' },
      },
      required: ['deviceId', 'remotePath', 'localPath'],
    },
  },
  {
    name: 'start_screen_recording',
    description: 'Start recording the screen of the mobile device/simulator.',
    inputSchema: {
      type: 'object',
      properties: {
        deviceId: { type: 'string' },
        path: { type: 'string', description: 'Optional custom output path on the host.' },
      },
      required: ['deviceId'],
    },
  },
  {
    name: 'stop_screen_recording',
    description: 'Stop recording the screen and save the MP4 video to the host.',
    inputSchema: {
      type: 'object',
      properties: {
        deviceId: { type: 'string' },
        path: { type: 'string', description: 'Optional custom output path on the host.' },
      },
      required: ['deviceId'],
    },
  },
  {
    name: 'clear_app_data',
    description: 'Wipe all user data, preferences, caches, and storage for the specified app (reset to clean install).',
    inputSchema: {
      type: 'object',
      properties: {
        deviceId: { type: 'string' },
        packageId: { type: 'string', description: 'The bundleId or packageId of the app.' },
      },
      required: ['deviceId', 'packageId'],
    },
  },
  {
    name: 'install_app',
    description: 'Install an app package (.apk or .app) from the host machine onto the mobile device/simulator.',
    inputSchema: {
      type: 'object',
      properties: {
        deviceId: { type: 'string' },
        localPath: { type: 'string', description: 'Absolute path to the app package on the host.' },
      },
      required: ['deviceId', 'localPath'],
    },
  },
  {
    name: 'uninstall_app',
    description: 'Remove/uninstall an app from the mobile device/simulator.',
    inputSchema: {
      type: 'object',
      properties: {
        deviceId: { type: 'string' },
        packageId: { type: 'string', description: 'The bundleId or packageId of the app.' },
      },
      required: ['deviceId', 'packageId'],
    },
  },
  {
    name: 'run_adb_command',
    description: 'Run an arbitrary adb command on the connected Android device.',
    inputSchema: {
      type: 'object',
      properties: {
        deviceId: { type: 'string' },
        adbArgs: {
          type: 'array',
          items: { type: 'string' },
          description: 'Arguments to pass to adb (e.g. ["shell", "getprop", "ro.product.model"]). Do not include "adb" itself.',
        },
      },
      required: ['deviceId', 'adbArgs'],
    },
  },
] as const;