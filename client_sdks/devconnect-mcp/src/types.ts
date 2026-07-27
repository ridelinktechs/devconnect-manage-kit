// Wire protocol message types — mirror lib/server/protocol/dc_message.dart
// on the Flutter side. Kept hand-rolled (no codegen) to keep this
// package dependency-free at the type level.

export type McpCommand =
  // ── Device control ──
  | { kind: 'list_devices' }
  | { kind: 'tap'; deviceId: string; x: number; y: number }
  | { kind: 'double_tap'; deviceId: string; x: number; y: number }
  | { kind: 'long_press'; deviceId: string; x: number; y: number; durationMs: number }
  | { kind: 'swipe'; deviceId: string; x1: number; y1: number; x2: number; y2: number; durationMs?: number }
  | { kind: 'drag_and_drop'; deviceId: string; x1: number; y1: number; x2: number; y2: number; durationMs?: number }
  | { kind: 'type_text'; deviceId: string; text: string }
  | { kind: 'press_button'; deviceId: string; button: 'HOME' | 'BACK' | 'VOLUME_UP' | 'VOLUME_DOWN' | 'ENTER' }
  | { kind: 'push_file'; deviceId: string; localPath: string; remotePath: string; packageId?: string }
  | { kind: 'pull_file'; deviceId: string; remotePath: string; localPath: string; packageId?: string }
  | { kind: 'start_screen_recording'; deviceId: string; path?: string }
  | { kind: 'stop_screen_recording'; deviceId: string; path?: string }
  | { kind: 'take_screenshot'; deviceId: string }
  | { kind: 'save_screenshot'; deviceId: string; path: string }
  | { kind: 'list_elements_on_screen'; deviceId: string }
  | { kind: 'list_apps'; deviceId: string }
  | { kind: 'launch_app'; deviceId: string; packageId: string }
  | { kind: 'terminate_app'; deviceId: string; packageId: string }
  | { kind: 'get_screen_size'; deviceId: string }
  | { kind: 'get_orientation'; deviceId: string }
  | { kind: 'set_orientation'; deviceId: string; orientation: 'portrait' | 'landscape' }
  | { kind: 'open_url'; deviceId: string; url: string }
  | { kind: 'push_file'; deviceId: string; localPath: string; remotePath: string; packageId?: string }
  | { kind: 'pull_file'; deviceId: string; remotePath: string; localPath: string; packageId?: string }
  | { kind: 'start_screen_recording'; deviceId: string; path?: string }
  | { kind: 'stop_screen_recording'; deviceId: string; path?: string }
  | { kind: 'clear_app_data'; deviceId: string; packageId: string }
  | { kind: 'install_app'; deviceId: string; localPath: string }
  | { kind: 'uninstall_app'; deviceId: string; packageId: string }
  | { kind: 'run_adb_command'; deviceId: string; adbArgs: string[] }
  // ── Telemetry reads (DevConnect-specific) ──
  | { kind: 'get_recent_logs'; deviceId?: string; level?: string; query?: string; limit?: number }
  | { kind: 'get_recent_requests'; deviceId?: string; urlPattern?: string; method?: string; statusMin?: number; statusMax?: number; query?: string; limit?: number }
  | { kind: 'get_request_detail'; requestId: string }
  | { kind: 'get_store_list'; deviceId?: string }
  | { kind: 'get_store_state'; storeId: string }
  | { kind: 'get_recent_dispatches'; storeId: string; limit?: number }
  | { kind: 'get_storage_keys'; deviceId?: string; backend?: string }
  | { kind: 'read_storage_value'; key: string; backend: string }
  | { kind: 'get_react_hierarchy'; deviceId: string }
  | { kind: 'get_performance_snapshot'; deviceId?: string }
  | { kind: 'get_recent_errors'; deviceId?: string; severity?: string; limit?: number }
  | { kind: 'get_recent_crashes'; deviceId?: string; platform?: string; limit?: number }
  | { kind: 'get_database_schema'; backend?: string };

export type McpCommandResult<T = unknown> =
  | { ok: true; data: T }
  | { ok: false; error: string };

export interface Device {
  id: string;
  platform: 'ios' | 'android';
  name: string;
  osVersion: string;
  model: string;
  currentApp?: string;
  isActive: boolean;
}

export interface ScreenshotResult {
  format: 'png';
  width: number;
  height: number;
  // base64-encoded PNG
  base64: string;
}

export interface ScreenSizeResult {
  width: number;
  height: number;
  orientation: 'portrait' | 'landscape';
}

export interface OrientationResult {
  orientation: 'portrait' | 'landscape';
}

export interface AppInfo {
  packageId: string;
  displayName?: string;
  isSystem: boolean;
}

export interface UiElement {
  uid: string;
  label?: string;
  value?: string;
  type?: string;
  frame?: { x: number; y: number; width: number; height: number };
  isVisible?: boolean;
}