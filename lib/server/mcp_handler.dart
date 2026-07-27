import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../core/constants/ws_constants.dart';
import '../core/preferences/app_preferences.dart';
import '../features/console/provider/console_providers.dart';
import '../features/error_inspector/provider/error_providers.dart';
import '../features/network_inspector/provider/network_providers.dart';
import '../features/performance/provider/performance_providers.dart';
import '../features/state_inspector/provider/state_providers.dart';
import '../features/storage_viewer/provider/storage_providers.dart';
import 'protocol/dc_message.dart';
import 'providers/server_providers.dart';
import 'ws_server.dart';

/// Dispatcher for MCP control-channel messages coming from the
/// `devconnect-manage` server (npm). Each command is mapped to one of:
///
///  - **OS-level device control** via `adb` (Android) or `xcrun simctl`
///    (iOS Simulator on macOS) — parity with mobile-next/mobile-mcp.
///  - **Pure desktop-side query** — e.g. `list_devices` reads the WS
///    connection map + queries adb/simctl.
///  - **Telemetry read** — pulls the captured events from the existing
///    Riverpod providers (console / network / state / storage / perf /
///    errors) so an AI agent can ask "what just happened in the app?"
///    without re-instrumenting anything.
///
/// Pending request/response correlation is keyed on [DCMessage.correlationId]
/// and resolves back to the MCP caller via `serverMcpResponse` over WS.
class McpHandler {
  final WsServer mcpServer;
  final WsServer deviceServer;
  final Ref ref;
  final _uuid = const Uuid();
  final _recordings = <String, Process>{};

  McpHandler(this.mcpServer, this.deviceServer, this.ref);

  void register() {
    mcpServer.onMessage.listen((msg) {
      if (msg.type == WsMessageTypes.clientMcpCommand) {
        _dispatch(msg);
      }
    });
  }

  void dispose() {
    for (final process in _recordings.values) {
      try {
        process.kill();
      } catch (_) {}
    }
    _recordings.clear();
  }

  Future<void> _dispatch(DCMessage msg) async {
    final correlationId = msg.correlationId;
    if (correlationId == null) return;

    final payload = msg.payload;
    final kind = payload['kind'] as String?;
    if (kind == null) return;

    Map<String, dynamic> response;

    const controlCommands = {
      'tap',
      'double_tap',
      'long_press',
      'swipe',
      'drag_and_drop',
      'type_text',
      'press_button',
      'launch_app',
      'terminate_app',
      'push_file',
      'pull_file',
      'start_screen_recording',
      'stop_screen_recording',
      'clear_app_data',
      'install_app',
      'uninstall_app',
      'run_adb_command',
    };

    try {
      if (controlCommands.contains(kind)) {
        final confirm = AppPreferences().get<bool>('mcpConfirmationRequired') ?? true;
        if (confirm) {
          final completer = Completer<bool>();
          ref.read(mcpConfirmationProvider.notifier).addRequest(
            McpConfirmationRequest(
              id: _uuid.v4(),
              command: kind,
              payload: payload,
              completer: completer,
            ),
          );
          final approved = await completer.future;
          if (!approved) {
            _respond(msg.deviceId, correlationId, {'ok': false, 'error': 'Action denied by developer'});
            return;
          }
        }
      }

      switch (kind) {
        // ── Device discovery ──
        case 'list_devices':
          response = await _listDevices();
          break;

        // ── OS-level device control (adb / simctl) ──
        case 'tap':
        case 'double_tap':
        case 'long_press':
        case 'swipe':
        case 'drag_and_drop':
        case 'type_text':
        case 'press_button':
        case 'launch_app':
        case 'terminate_app':
        case 'list_apps':
        case 'push_file':
        case 'pull_file':
        case 'start_screen_recording':
        case 'stop_screen_recording':
        case 'take_screenshot':
        case 'save_screenshot':
        case 'list_elements_on_screen':
        case 'get_screen_size':
        case 'get_orientation':
        case 'set_orientation':
        case 'open_url':
        case 'clear_app_data':
        case 'install_app':
        case 'uninstall_app':
        case 'run_adb_command':
          response = await _dispatchShellCommand(payload);
          break;

        // ── Telemetry reads (DevConnect-specific value-add) ──
        case 'get_recent_logs':
          response = _getRecentLogs(payload);
          break;
        case 'get_recent_requests':
          response = _getRecentRequests(payload);
          break;
        case 'get_request_detail':
          response = _getRequestDetail(payload);
          break;
        case 'get_store_list':
          response = _getStoreList(payload);
          break;
        case 'get_store_state':
          response = _getStoreState(payload);
          break;
        case 'get_recent_dispatches':
          response = _getRecentDispatches(payload);
          break;
        case 'get_storage_keys':
          response = _getStorageKeys(payload);
          break;
        case 'read_storage_value':
          response = _readStorageValue(payload);
          break;
        case 'get_performance_snapshot':
          response = _getPerformanceSnapshot(payload);
          break;
        case 'get_recent_errors':
          response = _getRecentErrors(payload);
          break;
        case 'get_recent_crashes':
          response = _getRecentCrashes(payload);
          break;
        case 'get_database_schema':
          response = _getDatabaseSchema(payload);
          break;
        case 'get_react_hierarchy':
          response = await _getReactHierarchy(payload);
          break;

        default:
          response = {'ok': false, 'error': 'Unknown command: $kind'};
      }
    } catch (e) {
      response = {'ok': false, 'error': e.toString()};
    }

    _respond(msg.deviceId, correlationId, response);
  }

  void _respond(String deviceId, String correlationId, Map<String, dynamic> payload) {
    final conn = mcpServer.connections[deviceId];
    if (conn == null) return;
    final response = DCMessage(
      id: _uuid.v4(),
      type: WsMessageTypes.serverMcpResponse,
      deviceId: 'server',
      timestamp: DateTime.now().millisecondsSinceEpoch,
      payload: payload,
      correlationId: correlationId,
    );
    conn.send(response);
  }

  // ── list_devices ────────────────────────────────────────────────────
  // Returns a mix of:
  //  - DevConnect SDK-connected devices (already in deviceServer.connections).
  //  - adb-attached Android devices (if adb on PATH).
  //  - Booted iOS Simulators (if xcrun simctl on PATH and macOS).
  Future<Map<String, dynamic>> _listDevices() async {
    final devices = <Map<String, dynamic>>[];

    // DevConnect SDK devices first.
    for (final c in deviceServer.connections.values) {
      final info = c.deviceInfo;
      devices.add({
        'id': info.deviceId,
        'platform': info.platform,
        'name': info.deviceName,
        'osVersion': info.appVersion,
        'model': info.deviceName,
        'currentApp': info.appName,
        'isActive': true,
      });
    }

    // adb devices (if available).
    final adbDevices = await _adbDevices();
    devices.addAll(adbDevices);

    // iOS Simulators (if macOS + simctl).
    final sims = await _simctlDevices();
    devices.addAll(sims);

    return {'ok': true, 'data': devices};
  }

  // ── shell dispatch ─────────────────────────────────────────────────
  Future<Map<String, dynamic>> _dispatchShellCommand(Map<String, dynamic> payload) async {
    final kind = payload['kind'] as String;
    final deviceId = payload['deviceId'] as String?;

    // Resolve which transport this command targets.
    final transport = await _resolveTransport(deviceId);
    if (transport == null) {
      return {'ok': false, 'error': 'Device $deviceId not found or no transport (adb/simctl) available'};
    }

    switch (transport.platform) {
      case 'android':
        return _runAdb(transport.target, kind, payload);
      case 'ios':
        return _runSimctl(transport.target, kind, payload);
      default:
        return {'ok': false, 'error': 'Unsupported platform for ${transport.platform}'};
    }
  }

  // ── transport resolution ───────────────────────────────────────────
  // Maps a deviceId (from list_devices) to a concrete adb serial /
  // simctl UDID + platform.

  Future<_Transport?> _resolveTransport(String? deviceId) async {
    if (deviceId == null) return null;

    // First check DevConnect SDK connections.
    final conn = deviceServer.connections[deviceId];
    if (conn != null) {
      final p = conn.deviceInfo.platform;
      if (p == 'android') {
        final serial = await _matchAdbByName(conn.deviceInfo.deviceName);
        if (serial != null) return _Transport('android', serial);
      } else if (p == 'ios') {
        final udid = await _matchSimByName(conn.deviceInfo.deviceName);
        if (udid != null) return _Transport('ios', udid);
      }
    }

    // Then check adb devices directly.
    final adbList = await _adbDevices();
    for (final d in adbList) {
      if (d['id'] == deviceId) {
        return _Transport('android', d['serial'] as String);
      }
    }

    // Then simctl.
    final sims = await _simctlDevices();
    for (final d in sims) {
      if (d['id'] == deviceId) {
        return _Transport('ios', d['serial'] as String);
      }
    }

    return null;
  }

  // ── adb ────────────────────────────────────────────────────────────
  static String? _adbPath;

  Future<String> _resolveAdbPath() async {
    final cached = _adbPath;
    if (cached != null) return cached;
    try {
      final r = await Process.run('which', ['adb']).timeout(const Duration(seconds: 2));
      if (r.exitCode == 0) {
        final p = r.stdout.toString().trim().split('\n').first;
        if (p.isNotEmpty) {
          _adbPath = p;
          return p;
        }
      }
    } catch (_) {}
    // Fallbacks
    const fallbacks = [
      '/opt/homebrew/bin/adb',
      '/usr/local/bin/adb',
      '/usr/bin/adb',
    ];
    for (final p in fallbacks) {
      if (await File(p).exists()) {
        _adbPath = p;
        return p;
      }
    }
    throw Exception('adb not found in PATH');
  }

  Future<List<Map<String, dynamic>>> _adbDevices() async {
    try {
      final adb = await _resolveAdbPath();
      final r = await Process.run(adb, ['devices']).timeout(const Duration(seconds: 5));
      if (r.exitCode != 0) return [];
      final lines = r.stdout.toString().split('\n');
      final out = <Map<String, dynamic>>[];
      // Skip header line ("List of devices attached")
      for (var i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;
        final m = RegExp(r'^(\S+)\s+(\S+)').firstMatch(line);
        if (m == null) continue;
        final serial = m.group(1)!;
        final state = m.group(2)!;
        if (state == 'offline') continue;
        // Try to enrich with model + osVersion.
        final model = await _adbGetProp(adb, serial, 'ro.product.model');
        final osVersion = await _adbGetProp(adb, serial, 'ro.build.version.release');
        out.add({
          'id': 'adb:$serial',
          'serial': serial,
          'platform': 'android',
          'name': model ?? serial,
          'osVersion': osVersion ?? '',
          'model': model ?? serial,
          'currentApp': null,
          'isActive': state == 'device',
        });
      }
      return out;
    } catch (_) {
      return [];
    }
  }

  Future<String?> _adbGetProp(String adb, String serial, String prop) async {
    try {
      final r = await Process.run(adb, ['-s', serial, 'shell', 'getprop', prop])
          .timeout(const Duration(seconds: 3));
      if (r.exitCode == 0) {
        final v = r.stdout.toString().trim();
        return v.isEmpty ? null : v;
      }
    } catch (_) {}
    return null;
  }

  Future<String?> _matchAdbByName(String name) async {
    final all = await _adbDevices();
    for (final d in all) {
      if ((d['model'] as String?) == name) return d['serial'] as String;
    }
    // Fallback: first device.
    if (all.isNotEmpty) return all.first['serial'] as String;
    return null;
  }

  Future<Map<String, dynamic>> _runAdb(String serial, String kind, Map<String, dynamic> p) async {
    final adb = await _resolveAdbPath();
    List<String> args;
    switch (kind) {
      case 'tap':
        args = ['-s', serial, 'shell', 'input', 'tap', '${p['x']}', '${p['y']}'];
        break;
      case 'double_tap':
        args = ['-s', serial, 'shell', 'input', 'tap', '${p['x']}', '${p['y']}',
                '&&', 'sleep', '0.1', '&&', 'adb', '-s', serial, 'shell', 'input', 'tap', '${p['x']}', '${p['y']}'];
        break;
      case 'long_press':
        final ms = p['durationMs'] ?? 500;
        args = ['-s', serial, 'shell', 'input', 'swipe', '${p['x']}', '${p['y']}', '${p['x']}', '${p['y']}', '$ms'];
        break;
      case 'swipe':
        final ms = p['durationMs'] ?? 300;
        args = ['-s', serial, 'shell', 'input', 'swipe', '${p['x1']}', '${p['y1']}', '${p['x2']}', '${p['y2']}', '$ms'];
        break;
      case 'type_text':
        // adb input text doesn't handle spaces well; replace with %s.
        final text = (p['text'] as String).replaceAll(' ', '%s');
        args = ['-s', serial, 'shell', 'input', 'text', text];
        break;
      case 'press_button':
        final keycode = _androidKeycode(p['button'] as String);
        if (keycode == null) return {'ok': false, 'error': 'Unsupported button: ${p['button']}'};
        args = ['-s', serial, 'shell', 'input', 'keyevent', '$keycode'];
        break;
      case 'launch_app':
        args = ['-s', serial, 'shell', 'monkey', '-p', p['packageId'] as String, '-c', 'android.intent.category.LAUNCHER', '1'];
        break;
      case 'terminate_app':
        args = ['-s', serial, 'shell', 'am', 'force-stop', p['packageId'] as String];
        break;
      case 'list_apps':
        return _adbListApps(adb, serial);
      case 'take_screenshot':
        return _adbTakeScreenshot(adb, serial);
      case 'save_screenshot':
        return _adbSaveScreenshot(adb, serial, p['path'] as String);
      case 'list_elements_on_screen':
        return _adbUiDump(adb, serial);
      case 'get_screen_size':
        return _adbScreenSize(adb, serial);
      case 'get_orientation':
        return _adbOrientation(adb, serial);
      case 'set_orientation':
        return _adbSetOrientation(adb, serial, p['orientation'] as String);
      case 'open_url':
        args = ['-s', serial, 'shell', 'am', 'start', '-a', 'android.intent.action.VIEW', '-d', p['url'] as String];
        break;
      case 'drag_and_drop':
        final ms = p['durationMs'] ?? 1000;
        args = ['-s', serial, 'shell', 'input', 'draganddrop', '${p['x1']}', '${p['y1']}', '${p['x2']}', '${p['y2']}', '$ms'];
        break;
      case 'push_file':
        args = ['-s', serial, 'push', p['localPath'] as String, p['remotePath'] as String];
        break;
      case 'pull_file':
        args = ['-s', serial, 'pull', p['remotePath'] as String, p['localPath'] as String];
        break;
      case 'clear_app_data':
        args = ['-s', serial, 'shell', 'pm', 'clear', p['packageId'] as String];
        break;
      case 'install_app':
        args = ['-s', serial, 'install', '-r', p['localPath'] as String];
        break;
      case 'uninstall_app':
        args = ['-s', serial, 'uninstall', p['packageId'] as String];
        break;
      case 'run_adb_command':
        final adbArgs = List<String>.from(p['adbArgs'] as List);
        args = ['-s', serial, ...adbArgs];
        break;
      case 'start_screen_recording':
        if (_recordings.containsKey(serial)) {
          try {
            _recordings[serial]?.kill();
          } catch (_) {}
          _recordings.remove(serial);
        }
        try {
          await Process.run(adb, ['-s', serial, 'shell', 'rm', '-f', '/sdcard/devconnect_record.mp4']);
        } catch (_) {}
        final process = await Process.start(adb, ['-s', serial, 'shell', 'screenrecord', '/sdcard/devconnect_record.mp4']);
        _recordings[serial] = process;
        return {'ok': true, 'message': 'Screen recording started on Android device'};
      case 'stop_screen_recording':
        final process = _recordings[serial];
        if (process == null) {
          return {'ok': false, 'error': 'No active recording found for device'};
        }
        try {
          await Process.run(adb, ['-s', serial, 'shell', 'pkill', '-2', 'screenrecord']);
          await process.exitCode.timeout(const Duration(seconds: 5), onTimeout: () => 0);
        } catch (_) {}
        _recordings.remove(serial);
        final localPath = p['path'] as String? ?? '${Directory.systemTemp.path}/devconnect_record_$serial.mp4';
        final pullResult = await Process.run(adb, ['-s', serial, 'pull', '/sdcard/devconnect_record.mp4', localPath]);
        try {
          await Process.run(adb, ['-s', serial, 'shell', 'rm', '-f', '/sdcard/devconnect_record.mp4']);
        } catch (_) {}
        if (pullResult.exitCode == 0) {
          return {
            'ok': true,
            'data': {'path': localPath}
          };
        } else {
          return {'ok': false, 'error': 'Failed to pull video: ${pullResult.stderr}'};
        }
      default:
        return {'ok': false, 'error': 'Command $kind not implemented for android'};
    }

    try {
      final r = await Process.run(adb, args).timeout(const Duration(seconds: 30));
      return {
        'ok': r.exitCode == 0,
        'data': {
          'exitCode': r.exitCode,
          'stdout': r.stdout.toString(),
          'stderr': r.stderr.toString(),
        },
        if (r.exitCode != 0) 'error': 'exit ${r.exitCode}: ${r.stderr.toString().trim()}',
      };
    } on Exception catch (e) {
      return {'ok': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _adbListApps(String adb, String serial) async {
    try {
      final r = await Process.run(adb, ['-s', serial, 'shell', 'pm', 'list', 'packages', '-3'])
          .timeout(const Duration(seconds: 10));
      final lines = r.stdout.toString().split('\n')
        ..removeWhere((l) => !l.startsWith('package:'));
      final apps = lines.map((l) => {
        'packageId': l.replaceFirst('package:', '').trim(),
        'displayName': null,
        'isSystem': false,
      }).toList();
      return {'ok': true, 'data': apps};
    } on Exception catch (e) {
      return {'ok': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _adbTakeScreenshot(String adb, String serial) async {
    try {
      final r = await Process.run(adb, ['-s', serial, 'exec-out', 'screencap', '-p'])
          .timeout(const Duration(seconds: 15));
      if (r.exitCode != 0) {
        return {'ok': false, 'error': 'screencap failed: ${r.stderr}'};
      }
      final bytes = r.stdout as List<int>;
      // adb exec-out returns raw PNG bytes; encode as base64.
      return {
        'ok': true,
        'data': {
          'format': 'png',
          'width': 0,    // adb screencap doesn't return dims cheaply
          'height': 0,
          'base64': base64Encode(bytes),
        },
      };
    } on Exception catch (e) {
      return {'ok': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _adbSaveScreenshot(String adb, String serial, String path) async {
    try {
      final r = await Process.run(adb, ['-s', serial, 'exec-out', 'screencap', '-p'])
          .timeout(const Duration(seconds: 15));
      if (r.exitCode != 0) {
        return {'ok': false, 'error': 'screencap failed: ${r.stderr}'};
      }
      final file = File(path);
      await file.parent.create(recursive: true);
      await file.writeAsBytes(r.stdout as List<int>);
      return {'ok': true, 'data': {'path': path, 'bytes': (r.stdout as List).length}};
    } on Exception catch (e) {
      return {'ok': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _adbUiDump(String adb, String serial) async {
    try {
      final r = await Process.run(adb, ['-s', serial, 'exec-out', 'uiautomator', 'dump', '/dev/tty'])
          .timeout(const Duration(seconds: 10));
      if (r.exitCode != 0) {
        return {'ok': false, 'error': 'uiautomator dump failed: ${r.stderr}'};
      }
      // Parse the dump XML — naive extraction of bounds, text, resource-id.
      final xml = r.stdout.toString();
      final elements = <Map<String, dynamic>>[];
      final nodeRegex = RegExp(r'<node\s+([^>]+)/?>');
      for (final m in nodeRegex.allMatches(xml)) {
        final attrs = m.group(1)!;
        String? attr(String name) {
          final r = RegExp('$name="([^"]*)"').firstMatch(attrs);
          return r?.group(1);
        }

        final bounds = attr('bounds');
        Map<String, dynamic>? frame;
        if (bounds != null) {
          final bm = RegExp(r'\[(\d+),(\d+)\]\[(\d+),(\d+)\]').firstMatch(bounds);
          if (bm != null) {
            frame = {
              'x': int.parse(bm.group(1)!),
              'y': int.parse(bm.group(2)!),
              'width': int.parse(bm.group(3)!) - int.parse(bm.group(1)!),
              'height': int.parse(bm.group(4)!) - int.parse(bm.group(2)!),
            };
          }
        }
        elements.add({
          'uid': attr('resource-id') ?? 'unknown',
          'label': attr('content-desc'),
          'value': attr('text'),
          'type': attr('class'),
          'frame': frame,
          'isVisible': true,
        });
      }
      return {'ok': true, 'data': elements};
    } on Exception catch (e) {
      return {'ok': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _adbScreenSize(String adb, String serial) async {
    try {
      final r = await Process.run(adb, ['-s', serial, 'shell', 'wm', 'size'])
          .timeout(const Duration(seconds: 3));
      final m = RegExp(r'(\d+)x(\d+)').firstMatch(r.stdout.toString());
      if (m == null) return {'ok': false, 'error': 'Could not parse wm size'};
      final w = int.parse(m.group(1)!);
      final h = int.parse(m.group(2)!);
      return {'ok': true, 'data': {'width': w, 'height': h, 'orientation': w > h ? 'landscape' : 'portrait'}};
    } on Exception catch (e) {
      return {'ok': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _adbOrientation(String adb, String serial) async {
    try {
      final r = await Process.run(adb, ['-s', serial, 'shell', 'dumpsys', 'input'])
          .timeout(const Duration(seconds: 5));
      final m = RegExp(r'SurfaceOrientation:\s*(\d)').firstMatch(r.stdout.toString());
      if (m == null) return {'ok': false, 'error': 'Could not parse orientation'};
      final n = int.parse(m.group(1)!);
      return {'ok': true, 'data': {'orientation': (n == 0 || n == 2) ? 'portrait' : 'landscape'}};
    } on Exception catch (e) {
      return {'ok': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _adbSetOrientation(String adb, String serial, String orientation) async {
    try {
      final n = orientation == 'portrait' ? 0 : 1;
      await Process.run(adb, ['-s', serial, 'shell', 'settings', 'put', 'system', 'accelerometer_rotation', '0'])
          .timeout(const Duration(seconds: 3));
      await Process.run(adb, ['-s', serial, 'shell', 'settings', 'put', 'system', 'user_rotation', '$n'])
          .timeout(const Duration(seconds: 3));
      return {'ok': true, 'data': {'orientation': orientation}};
    } on Exception catch (e) {
      return {'ok': false, 'error': e.toString()};
    }
  }

  int? _androidKeycode(String button) {
    switch (button) {
      case 'HOME': return 3;
      case 'BACK': return 4;
      case 'VOLUME_UP': return 24;
      case 'VOLUME_DOWN': return 25;
      case 'ENTER': return 66;
      case 'DPAD_UP': return 19;
      case 'DPAD_DOWN': return 20;
      case 'DPAD_LEFT': return 21;
      case 'DPAD_RIGHT': return 22;
      case 'TAB': return 61;
      case 'ESCAPE': return 111;
      case 'DELETE': return 67;
      default: return null;
    }
  }

  // ── xcrun simctl ───────────────────────────────────────────────────
  bool _simctlAvailable() => Platform.isMacOS;

  Future<List<Map<String, dynamic>>> _simctlDevices() async {
    if (!_simctlAvailable()) return [];
    try {
      final r = await Process.run('xcrun', ['simctl', 'list', 'devices', 'booted', '-j'])
          .timeout(const Duration(seconds: 5));
      if (r.exitCode != 0) return [];
      final json = jsonDecode(r.stdout.toString()) as Map<String, dynamic>;
      final runtimeMap = (json['devices'] as Map<String, dynamic>);
      final out = <Map<String, dynamic>>[];
      runtimeMap.forEach((runtime, devices) {
        for (final d in (devices as List)) {
          if (d['state'] != 'Booted') continue;
          out.add({
            'id': 'sim:${d['udid']}',
            'serial': d['udid'] as String,
            'platform': 'ios',
            'name': d['name'] as String,
            'osVersion': runtime.replaceAll('com.apple.CoreSimulator.SimRuntime.', ''),
            'model': d['deviceTypeIdentifier'] ?? d['name'],
            'currentApp': null,
            'isActive': true,
          });
        }
      });
      return out;
    } catch (_) {
      return [];
    }
  }

  Future<String?> _matchSimByName(String name) async {
    final all = await _simctlDevices();
    for (final d in all) {
      if ((d['name'] as String?) == name) return d['serial'] as String;
    }
    if (all.isNotEmpty) return all.first['serial'] as String;
    return null;
  }

  Future<Map<String, dynamic>> _runSimctl(String udid, String kind, Map<String, dynamic> p) async {
    if (!_simctlAvailable()) {
      return {'ok': false, 'error': 'simctl only available on macOS'};
    }

    List<String> args;
    Future<ProcessResult> Function() runner;

    switch (kind) {
      case 'tap':
      case 'double_tap':
      case 'long_press':
      case 'swipe':
      case 'type_text':
        return {'ok': false, 'error': 'simulator touch input requires `xcrun simctl ui` (limited). Use ADB-emulator or a physical device for these.'};
      case 'press_button':
        final button = p['button'] as String;
        if (button == 'HOME') {
          try {
            final script = 'tell application "System Events" to tell process "Simulator" to keystroke "h" using {command down, shift down}';
            final r = await Process.run('osascript', ['-e', script]).timeout(const Duration(seconds: 5));
            return {
              'ok': r.exitCode == 0,
              if (r.exitCode != 0) 'error': 'AppleScript failed: ${r.stderr.toString().trim()}',
            };
          } catch (e) {
            return {'ok': false, 'error': e.toString()};
          }
        }
        return {'ok': false, 'error': 'Button $button not supported on iOS Simulator'};
      case 'drag_and_drop':
        return {'ok': false, 'error': 'Simulator touch/drag input not supported via simctl. Use an Android emulator or a physical device.'};
      case 'launch_app':
        args = ['simctl', 'launch', udid, p['packageId'] as String];
        runner = () => Process.run('xcrun', args);
        break;
      case 'terminate_app':
        args = ['simctl', 'terminate', udid, p['packageId'] as String];
        runner = () => Process.run('xcrun', args);
        break;
      case 'list_apps':
        args = ['simctl', 'listapps', udid];
        runner = () => Process.run('xcrun', args);
        break;
      case 'take_screenshot':
        return _simctlTakeScreenshot(udid);
      case 'save_screenshot':
        return _simctlSaveScreenshot(udid, p['path'] as String);
      case 'list_elements_on_screen':
        return _simctlUiDump(udid);
      case 'get_screen_size':
        return _simctlScreenSize();
      case 'get_orientation':
        return {'ok': true, 'data': {'orientation': 'portrait'}};
      case 'set_orientation':
        return {'ok': false, 'error': 'simctl does not support rotation. Use Simulator menu.'};
      case 'open_url':
        args = ['simctl', 'openurl', udid, p['url'] as String];
        runner = () => Process.run('xcrun', args);
        break;
      case 'push_file':
        final localPath = p['localPath'] as String;
        final remotePath = p['remotePath'] as String;
        final packageId = p['packageId'] as String?;
        if (packageId != null && packageId.isNotEmpty) {
          final containerRes = await Process.run('xcrun', ['simctl', 'container', udid, packageId]);
          if (containerRes.exitCode != 0) {
            return {'ok': false, 'error': 'Failed to resolve app container: ${containerRes.stderr}'};
          }
          final containerPath = containerRes.stdout.toString().trim();
          final dest = '$containerPath/$remotePath'.replaceAll('//', '/');
          final r = await Process.run('cp', [localPath, dest]);
          return {
            'ok': r.exitCode == 0,
            if (r.exitCode != 0) 'error': r.stderr.toString().trim(),
          };
        } else {
          final isMedia = ['.png', '.jpg', '.jpeg', '.gif', '.mp4', '.mov'].any((ext) => localPath.toLowerCase().endsWith(ext));
          if (isMedia) {
            final r = await Process.run('xcrun', ['simctl', 'addmedia', udid, localPath]);
            return {
              'ok': r.exitCode == 0,
              if (r.exitCode != 0) 'error': r.stderr.toString().trim(),
            };
          } else {
            return {'ok': false, 'error': 'packageId is required to copy non-media files to app container'};
          }
        }
      case 'pull_file':
        final remotePath = p['remotePath'] as String;
        final localPath = p['localPath'] as String;
        final packageId = p['packageId'] as String?;
        if (packageId == null || packageId.isEmpty) {
          return {'ok': false, 'error': 'packageId is required to pull files from app container'};
        }
        final containerRes = await Process.run('xcrun', ['simctl', 'container', udid, packageId]);
        if (containerRes.exitCode != 0) {
          return {'ok': false, 'error': 'Failed to resolve app container: ${containerRes.stderr}'};
        }
        final containerPath = containerRes.stdout.toString().trim();
        final src = '$containerPath/$remotePath'.replaceAll('//', '/');
        final r = await Process.run('cp', [src, localPath]);
        return {
          'ok': r.exitCode == 0,
          if (r.exitCode != 0) 'error': r.stderr.toString().trim(),
        };
      case 'clear_app_data':
        final packageId = p['packageId'] as String;
        final containerRes = await Process.run('xcrun', ['simctl', 'container', udid, packageId]);
        if (containerRes.exitCode != 0) {
          return {'ok': false, 'error': 'Failed to resolve app container: ${containerRes.stderr}'};
        }
        final containerPath = containerRes.stdout.toString().trim();
        try {
          await Process.run('rm', ['-rf', '$containerPath/Documents']);
          await Process.run('rm', ['-rf', '$containerPath/Library']);
          await Process.run('rm', ['-rf', '$containerPath/tmp']);
          await Process.run('mkdir', ['-p', '$containerPath/Documents']);
          await Process.run('mkdir', ['-p', '$containerPath/Library']);
          await Process.run('mkdir', ['-p', '$containerPath/tmp']);
          return {'ok': true, 'message': 'Successfully cleared app data for $packageId'};
        } catch (e) {
          return {'ok': false, 'error': 'Failed to clear directories: $e'};
        }
      case 'install_app':
        args = ['simctl', 'install', udid, p['localPath'] as String];
        runner = () => Process.run('xcrun', args);
        break;
      case 'uninstall_app':
        args = ['simctl', 'uninstall', udid, p['packageId'] as String];
        runner = () => Process.run('xcrun', args);
        break;
      case 'run_adb_command':
        return {'ok': false, 'error': 'run_adb_command is only supported on Android devices'};
      case 'start_screen_recording':
        if (_recordings.containsKey(udid)) {
          try {
            _recordings[udid]?.kill();
          } catch (_) {}
          _recordings.remove(udid);
        }
        final localPath = p['path'] as String? ?? '${Directory.systemTemp.path}/devconnect_sim_record_$udid.mp4';
        final process = await Process.start('xcrun', ['simctl', 'io', udid, 'record-video', '--force', localPath]);
        _recordings[udid] = process;
        return {'ok': true, 'message': 'Screen recording started on iOS Simulator'};
      case 'stop_screen_recording':
        final process = _recordings[udid];
        if (process == null) {
          return {'ok': false, 'error': 'No active recording found for Simulator'};
        }
        try {
          process.kill(ProcessSignal.sigint);
          await process.exitCode.timeout(const Duration(seconds: 5), onTimeout: () => 0);
        } catch (_) {}
        _recordings.remove(udid);
        final localPath = p['path'] as String? ?? '${Directory.systemTemp.path}/devconnect_sim_record_$udid.mp4';
        return {
          'ok': true,
          'data': {'path': localPath}
        };
      default:
        return {'ok': false, 'error': 'Command $kind not implemented for ios'};
    }

    try {
      final r = await runner().timeout(const Duration(seconds: 30));
      return {
        'ok': r.exitCode == 0,
        'data': {
          'exitCode': r.exitCode,
          'stdout': r.stdout.toString(),
          'stderr': r.stderr.toString(),
        },
        if (r.exitCode != 0) 'error': 'exit ${r.exitCode}: ${r.stderr.toString().trim()}',
      };
    } on Exception catch (e) {
      return {'ok': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _simctlUiDump(String udid) async {
    try {
      final script = 'tell application "System Events" to tell process "Simulator" to get entire contents of window 1';
      final r = await Process.run('osascript', ['-e', script]).timeout(const Duration(seconds: 10));
      if (r.exitCode != 0) {
        return {'ok': false, 'error': 'AppleScript failed: ${r.stderr}'};
      }
      final raw = r.stdout.toString().trim();
      final elements = <Map<String, dynamic>>[];
      final items = raw.split(', ');
      for (final item in items) {
        final m = RegExp(r'^([^"]+?)\s+"([^"]*)"\s+of\s+(.+)$').firstMatch(item);
        if (m != null) {
          final type = m.group(1)!.trim();
          final label = m.group(2)!.trim();
          elements.add({
            'uid': label.isNotEmpty ? label : type,
            'label': label,
            'value': null,
            'type': type,
            'frame': null,
            'isVisible': true,
          });
        } else {
          final typeParts = item.split(' of ');
          if (typeParts.isNotEmpty) {
            elements.add({
              'uid': typeParts.first.trim(),
              'label': null,
              'value': null,
              'type': typeParts.first.trim(),
              'frame': null,
              'isVisible': true,
            });
          }
        }
      }
      return {'ok': true, 'data': elements};
    } catch (e) {
      return {'ok': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _simctlTakeScreenshot(String udid) async {
    final tmp = File('${Directory.systemTemp.path}/devconnect_sim_$udid.png');
    try {
      final r = await Process.run('xcrun', ['simctl', 'io', udid, 'screenshot', tmp.path])
          .timeout(const Duration(seconds: 15));
      if (r.exitCode != 0) {
        return {'ok': false, 'error': 'simctl io screenshot failed: ${r.stderr}'};
      }
      final bytes = await tmp.readAsBytes();
      await tmp.delete();
      return {
        'ok': true,
        'data': {
          'format': 'png',
          'width': 0,
          'height': 0,
          'base64': base64Encode(bytes),
        },
      };
    } on Exception catch (e) {
      return {'ok': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _simctlSaveScreenshot(String udid, String path) async {
    final tmp = File('${Directory.systemTemp.path}/devconnect_sim_$udid.png');
    try {
      final r = await Process.run('xcrun', ['simctl', 'io', udid, 'screenshot', tmp.path])
          .timeout(const Duration(seconds: 15));
      if (r.exitCode != 0) {
        return {'ok': false, 'error': 'simctl io screenshot failed: ${r.stderr}'};
      }
      final file = File(path);
      await file.parent.create(recursive: true);
      await file.writeAsBytes(await tmp.readAsBytes());
      await tmp.delete();
      return {'ok': true, 'data': {'path': path}};
    } on Exception catch (e) {
      return {'ok': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _simctlScreenSize() async {
    // simctl doesn't expose screen size cleanly; default to a sensible
    // portrait iPhone size and let the AI adapt. The real device list
    // returns from list_devices already, so the AI can usually see
    // model identifier.
    return {'ok': true, 'data': {'width': 393, 'height': 852, 'orientation': 'portrait'}};
  }

  // ──────────────────────────────────────────────────────────────────
  // Telemetry reads — DevConnect-specific value-add. Each pulls from
  // an in-memory Riverpod provider that the WS server has already
  // populated from device events.
  // ──────────────────────────────────────────────────────────────────

  // ── get_recent_logs ────────────────────────────────────────────────
  Map<String, dynamic> _getRecentLogs(Map<String, dynamic> p) {
    final all = ref.read(consoleEntriesProvider);
    final deviceId = p['deviceId'] as String?;
    final level = p['level'] as String?;
    final query = p['query'] as String?;
    final limit = (p['limit'] as int?) ?? 100;

    var filtered = all;
    if (deviceId != null) {
      filtered = filtered.where((e) => e.deviceId == deviceId).toList();
    }
    if (level != null) {
      filtered = filtered.where((e) => e.level.name == level).toList();
    }
    if (query != null && query.isNotEmpty) {
      final lower = query.toLowerCase();
      filtered = filtered.where((e) =>
          e.message.toLowerCase().contains(lower) ||
          (e.tag != null && e.tag!.toLowerCase().contains(lower))).toList();
    }
    final entries = filtered.take(limit).map((e) => {
          'id': e.id,
          'deviceId': e.deviceId,
          'timestamp': e.timestamp,
          'level': e.level.name,
          'message': e.message,
          'tag': e.tag,
          'stackTrace': e.stackTrace,
          'metadata': e.metadata,
        }).toList();
    return {'ok': true, 'data': entries};
  }

  // ── get_recent_requests ───────────────────────────────────────────
  Map<String, dynamic> _getRecentRequests(Map<String, dynamic> p) {
    final all = ref.read(networkEntriesProvider);
    final deviceId = p['deviceId'] as String?;
    final urlPattern = p['urlPattern'] as String?;
    final method = p['method'] as String?;
    final statusMin = p['statusMin'] as int?;
    final statusMax = p['statusMax'] as int?;
    final query = p['query'] as String?;
    final limit = (p['limit'] as int?) ?? 100;

    var filtered = all;
    if (deviceId != null) {
      filtered = filtered.where((e) => e.deviceId == deviceId).toList();
    }
    if (urlPattern != null && urlPattern.isNotEmpty) {
      filtered = filtered.where((e) => e.url.contains(urlPattern)).toList();
    }
    if (method != null) {
      filtered = filtered.where((e) => e.method.toUpperCase() == method.toUpperCase()).toList();
    }
    if (query != null && query.isNotEmpty) {
      final lower = query.toLowerCase();
      filtered = filtered.where((e) =>
          e.url.toLowerCase().contains(lower) ||
          (e.error != null && e.error!.toLowerCase().contains(lower))).toList();
    }
    if (statusMin != null) {
      // NetworkEntry doesn't carry status code directly — derive from
      // endTime presence (errors logged when present). For richer status
      // matching the SDK needs to surface status code in future.
      // No-op fallback: include only completed (endTime != null).
      filtered = filtered.where((e) => e.endTime != null).toList();
    }
    if (statusMax != null) {
      filtered = filtered.where((e) => e.endTime != null).toList();
    }

    final entries = filtered.take(limit).map((e) => {
          'id': e.id,
          'deviceId': e.deviceId,
          'method': e.method,
          'url': e.url,
          'startTime': e.startTime,
          'endTime': e.endTime,
          'duration': e.duration,
          'error': e.error,
          'serviceName': e.serviceName,
          'serviceAction': e.serviceAction,
        }).toList();
    return {'ok': true, 'data': entries};
  }

  // ── get_request_detail ────────────────────────────────────────────
  Map<String, dynamic> _getRequestDetail(Map<String, dynamic> p) {
    final requestId = p['requestId'] as String?;
    if (requestId == null) {
      return {'ok': false, 'error': 'requestId is required'};
    }
    final all = ref.read(networkEntriesProvider);
    final entry = all.where((e) => e.id == requestId).firstOrNull;
    if (entry == null) {
      return {'ok': false, 'error': 'Request $requestId not found'};
    }
    return {
      'ok': true,
      'data': {
        'id': entry.id,
        'deviceId': entry.deviceId,
        'method': entry.method,
        'url': entry.url,
        'startTime': entry.startTime,
        'endTime': entry.endTime,
        'duration': entry.duration,
        'error': entry.error,
        'serviceName': entry.serviceName,
        'serviceAction': entry.serviceAction,
      },
    };
  }

  // ── get_store_list ─────────────────────────────────────────────────
  Map<String, dynamic> _getStoreList(Map<String, dynamic> p) {
    final all = ref.read(stateChangesProvider);
    final deviceId = p['deviceId'] as String?;
    final filtered = deviceId == null
        ? all
        : all.where((e) => e.deviceId == deviceId);
    final ids = <String>{for (final e in filtered) e.stateManagerType};
    return {
      'ok': true,
      'data': {
        'stores': ids.toList()..sort(),
      },
    };
  }

  // ── get_store_state ───────────────────────────────────────────────
  Map<String, dynamic> _getStoreState(Map<String, dynamic> p) {
    final storeId = p['storeId'] as String?;
    if (storeId == null) {
      return {'ok': false, 'error': 'storeId is required'};
    }
    final all = ref.read(stateChangesProvider);
    // Latest snapshot for this store, by latest timestamp.
    final matches = all.where((e) => e.stateManagerType == storeId).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final latest = matches.isEmpty ? null : matches.first;
    if (latest == null) {
      return {'ok': false, 'error': 'No state for store $storeId'};
    }
    return {
      'ok': true,
      'data': {
        'storeId': storeId,
        'stateManagerType': latest.stateManagerType,
        'timestamp': latest.timestamp,
        'actionName': latest.actionName,
        'state': latest.nextState,
      },
    };
  }

  // ── get_recent_dispatches ──────────────────────────────────────────
  Map<String, dynamic> _getRecentDispatches(Map<String, dynamic> p) {
    final storeId = p['storeId'] as String?;
    if (storeId == null) {
      return {'ok': false, 'error': 'storeId is required'};
    }
    final all = ref.read(stateChangesProvider);
    final limit = (p['limit'] as int?) ?? 20;
    final filtered = all.where((e) => e.stateManagerType == storeId).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final entries = filtered.take(limit).map((e) => {
          'id': e.id,
          'deviceId': e.deviceId,
          'timestamp': e.timestamp,
          'actionName': e.actionName,
          'previousState': e.previousState,
          'nextState': e.nextState,
          'diff': e.diff.map((d) => {
            'path': d.path,
            'operation': d.operation,
          }).toList(),
        }).toList();
    return {'ok': true, 'data': entries};
  }

  // ── get_storage_keys ───────────────────────────────────────────────
  Map<String, dynamic> _getStorageKeys(Map<String, dynamic> p) {
    final all = ref.read(storageEntriesProvider);
    final deviceId = p['deviceId'] as String?;
    final backend = p['backend'] as String?; // 'async_storage', 'mmkv', 'sqlite', ...

    var filtered = all;
    if (deviceId != null) {
      filtered = filtered.where((e) => e.deviceId == deviceId).toList();
    }
    if (backend != null) {
      filtered = filtered.where((e) => e.storageType.name == backend).toList();
    }

    // Collapse to (key, backend) — last write wins.
    final seen = <String, Map<String, dynamic>>{};
    for (final e in filtered) {
      seen['${e.storageType.name}:${e.key}'] = {
        'backend': e.storageType.name,
        'key': e.key,
        'operation': e.operation,
        'timestamp': e.timestamp,
        'hasValue': e.value != null,
        'valueType': e.value.runtimeType.toString(),
      };
    }
    final entries = seen.values.toList()..sort((a, b) => (a['key'] as String).compareTo(b['key'] as String));
    return {'ok': true, 'data': entries};
  }

  // ── read_storage_value ─────────────────────────────────────────────
  Map<String, dynamic> _readStorageValue(Map<String, dynamic> p) {
    final key = p['key'] as String?;
    final backend = p['backend'] as String?;
    if (key == null || backend == null) {
      return {'ok': false, 'error': 'key and backend are required'};
    }
    final all = ref.read(storageEntriesProvider);
    final matches = all
        .where((e) => e.key == key && e.storageType.name == backend)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final latest = matches.isEmpty ? null : matches.first;
    if (latest == null) {
      return {'ok': false, 'error': 'No entry for $backend:$key'};
    }
    return {
      'ok': true,
      'data': {
        'backend': latest.storageType.name,
        'key': latest.key,
        'value': latest.value,
        'valueType': latest.value.runtimeType.toString(),
        'operation': latest.operation,
        'timestamp': latest.timestamp,
      },
    };
  }

  // ── get_performance_snapshot ───────────────────────────────────────
  Map<String, dynamic> _getPerformanceSnapshot(Map<String, dynamic> p) {
    final all = ref.read(performanceEntriesProvider);
    final deviceId = p['deviceId'] as String?;
    final filtered = deviceId == null
        ? all
        : all.where((e) => e.deviceId == deviceId);

    // Latest per metricType.
    final latest = <String, Map<String, dynamic>>{};
    for (final e in filtered) {
      final k = e.metricType.name;
      final existing = latest[k];
      if (existing == null || (existing['timestamp'] as int) < e.timestamp) {
        latest[k] = {
          'metricType': k,
          'value': e.value,
          'timestamp': e.timestamp,
        };
      }
    }
    return {'ok': true, 'data': latest.values.toList()};
  }

  // ── get_recent_errors ──────────────────────────────────────────────
  Map<String, dynamic> _getRecentErrors(Map<String, dynamic> p) {
    final all = ref.read(errorEntriesProvider);
    final deviceId = p['deviceId'] as String?;
    final severity = p['severity'] as String?; // 'warning' | 'error' | 'fatal'
    final limit = (p['limit'] as int?) ?? 100;

    var filtered = all;
    if (deviceId != null) {
      filtered = filtered.where((e) => e.deviceId == deviceId).toList();
    }
    if (severity != null) {
      filtered = filtered.where((e) => e.severity.name == severity).toList();
    }
    final entries = filtered.take(limit).map((e) => {
          'id': e.id,
          'deviceId': e.deviceId,
          'platform': e.platform.name,
          'severity': e.severity.name,
          'message': e.message,
          'timestamp': e.timestamp,
          'stackTrace': e.stackTrace,
          'source': e.source,
          'deviceInfo': e.deviceInfo,
          'metadata': e.metadata,
        }).toList();
    return {'ok': true, 'data': entries};
  }

  // ── get_recent_crashes ─────────────────────────────────────────────
  // ErrorEvent.kind? Actually platform: ErrorPlatform (ios/android/web).
  // Filter to native platforms + severity fatal/error to surface "crashes".
  Map<String, dynamic> _getRecentCrashes(Map<String, dynamic> p) {
    final all = ref.read(errorEntriesProvider);
    final deviceId = p['deviceId'] as String?;
    final platform = p['platform'] as String?; // 'ios' | 'android'
    final limit = (p['limit'] as int?) ?? 20;

    var filtered = all.where((e) =>
        (e.severity.name == 'fatal' || e.severity.name == 'error') &&
        e.platform.name != 'web'); // Native only.
    if (deviceId != null) {
      filtered = filtered.where((e) => e.deviceId == deviceId);
    }
    if (platform != null) {
      filtered = filtered.where((e) => e.platform.name == platform);
    }
    final entries = filtered.take(limit).map((e) => {
          'id': e.id,
          'deviceId': e.deviceId,
          'platform': e.platform.name,
          'severity': e.severity.name,
          'message': e.message,
          'timestamp': e.timestamp,
          'stackTrace': e.stackTrace,
          'source': e.source,
          'deviceInfo': e.deviceInfo,
          'metadata': e.metadata,
        }).toList();
    return {'ok': true, 'data': entries};
  }

  // ── get_database_schema ────────────────────────────────────────────
  // Walks all connected storage entries of type sqlite, returns the most
  // recent entry whose `operation` is 'schema'. The schema itself is
  // embedded in the entry's `value` (typically a `DatabaseSchema` map).
  Map<String, dynamic> _getDatabaseSchema(Map<String, dynamic> p) {
    final backend = (p['backend'] as String?) ?? 'sqlite';
    final all = ref.read(storageEntriesProvider);
    final matches = all
        .where((e) => e.storageType.name == backend && e.operation == 'schema')
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    if (matches.isEmpty) {
      return {
        'ok': true,
        'data': {
          'backend': backend,
          'schema': null,
          'hint': 'No schema captured yet — call a database query on the device first.',
        },
      };
    }
    final latest = matches.first;
    return {
      'ok': true,
      'data': {
        'backend': backend,
        'deviceId': latest.deviceId,
        'timestamp': latest.timestamp,
        'schema': latest.value,
      },
    };
  }

  Future<Map<String, dynamic>> _getReactHierarchy(Map<String, dynamic> p) async {
    final deviceId = p['deviceId'] as String?;
    if (deviceId == null || deviceId.isEmpty) {
      return {'ok': false, 'error': 'deviceId is required'};
    }
    return _sendCustomCommand(deviceId, 'get_react_hierarchy', {});
  }

  Future<Map<String, dynamic>> _sendCustomCommand(
    String deviceId,
    String command,
    Map<String, dynamic> args,
  ) async {
    final correlationId = _uuid.v4();
    final wsHandler = ref.read(wsMessageHandlerProvider);
    final completer = Completer<Map<String, dynamic>>();

    final sub = wsHandler.onCustomResult.listen((res) {
      if (res['correlationId'] == correlationId) {
        completer.complete(res);
      }
    });

    try {
      deviceServer.sendToDevice(
        deviceId,
        DCMessage(
          id: _uuid.v4(),
          type: WsMessageTypes.serverCustomCommand,
          deviceId: 'server',
          timestamp: DateTime.now().millisecondsSinceEpoch,
          correlationId: correlationId,
          payload: {
            'command': command,
            'args': args,
          },
        ),
      );

      final result = await completer.future.timeout(const Duration(seconds: 15));
      if (result.containsKey('error')) {
        return {'ok': false, 'error': result['error']};
      }
      return {'ok': true, 'data': result['result']};
    } on TimeoutException {
      return {'ok': false, 'error': 'Command timed out'};
    } catch (e) {
      return {'ok': false, 'error': e.toString()};
    } finally {
      await sub.cancel();
    }
  }
}

class _Transport {
  final String platform; // 'android' | 'ios'
  final String target;   // adb serial | simctl udid
  const _Transport(this.platform, this.target);
}