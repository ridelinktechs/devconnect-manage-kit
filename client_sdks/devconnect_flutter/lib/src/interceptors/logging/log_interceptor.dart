import 'dart:async';

import '../../devconnect_client.dart';

/// Intercepts ALL developer-placed log calls from any logging library.
///
/// ## Auto-captured (via Zone print interception):
/// - `print('hello')`
/// - `debugPrint('hello')`
/// - `logger` package (Logger)
/// - `talker` package (Talker)
/// - `logging` package (dart:logging)
/// - `fimber` package (Fimber)
/// - `simple_logger` package
/// - `log_4_dart_2` package
///
/// ## All of the above use print() under the hood, so they are auto-captured.
///
/// ## Usage:
/// ```dart
/// DevConnectLogInterceptor.runZoned(() {
///   runApp(const MyApp());
/// });
/// ```
class DevConnectLogInterceptor {
  static final _frameworkPrefixes = <String>[
    'I/flutter',
    'D/flutter',
    'W/flutter',
    'E/flutter',
    'I/FlutterJNI',
    'D/EGL_emulation',
    'D/HostConnection',
    'I/Choreographer',
    'D/Surface',
    'I/System.out',
    'D/gralloc',
    'W/Gralloc',
    'D/OpenGLRenderer',
    'I/InputMethodManager',
    'V/PhoneWindow',
    'D/ViewRootImpl',
    'I/art',
    'I/zygote',
    'D/NetworkSecurityConfig',
    'W/art',
    'I/Ads',
    'D/FirebaseApp',
    'D/FirebaseCrashlytics',
    'I/FirebaseAuth',
    'I/DynamiteModule',
    'W/DynamiteModule',
    'D/ConnectivityManager',
    'D/IInputConnectionWrapper',
    'D/DecorView',
    'I/Process',
    'I/chatty',
    'D/skia',
    '--------- beginning of',
    'Restarted application',
    'Syncing files',
    'An Observatory debugger',
    'The Flutter DevTools debugger',
    'flutter: Observatory listening',
    'Another exception was thrown:',
    'The following assertion was thrown',
    'RenderFlex overflowed',
    'setState() called after dispose()',
    'Performing hot ',
  ];

  /// Run [body] in a Zone that captures print() output.
  static R runZoned<R>(R Function() body) {
    return Zone.current.fork(
      specification: ZoneSpecification(
        print: (Zone self, ZoneDelegate parent, Zone zone, String line) {
          parent.print(zone, line);
          if (_isFrameworkLog(line)) return;
          _sendLog(line);
        },
      ),
    ).run(body);
  }

  static bool _isFrameworkLog(String line) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) return true;

    for (final prefix in _frameworkPrefixes) {
      if (trimmed.startsWith(prefix)) return true;
    }

    // Filter Android logcat format: "X/Tag(PID): message"
    if (RegExp(r'^[VDIWEF]/[A-Za-z]').hasMatch(trimmed)) {
      return true;
    }

    return false;
  }

  static void _sendLog(String line) {
    try {
      String level = 'debug';
      String tag = 'print';
      String message = line;

      // ---- Detect "flutter: " prefix (debugPrint) ----
      if (line.startsWith('flutter: ')) {
        message = line.substring(9);
        tag = 'debugPrint';
      }

      // ---- Detect `logger` package patterns ----
      // logger outputs: "│ message" or "[E] message" or box-drawing chars
      final loggerMatch = _detectLoggerPackage(message);
      if (loggerMatch != null) {
        level = loggerMatch.level;
        tag = loggerMatch.tag;
        message = loggerMatch.message;
      }

      // ---- Detect `talker` package patterns ----
      // talker outputs: "[Talker] | 12:00:00 | INFO: message"
      else if (message.contains('[Talker]') || message.contains('[talker]')) {
        final talkerMatch = _detectTalker(message);
        if (talkerMatch != null) {
          level = talkerMatch.level;
          tag = talkerMatch.tag;
          message = talkerMatch.message;
        }
      }

      // ---- Detect `logging` package (dart:logging) ----
      // Output: "[INFO] mylogger: message" or "[WARNING] mylogger: message"
      else if (RegExp(r'^\[(FINE|FINER|FINEST|CONFIG|INFO|WARNING|SEVERE|SHOUT)\]').hasMatch(message)) {
        final loggingMatch = _detectLoggingPackage(message);
        if (loggingMatch != null) {
          level = loggingMatch.level;
          tag = loggingMatch.tag;
          message = loggingMatch.message;
        }
      }

      // ---- Detect `fimber` / `fimber_io` package ----
      // Output: "D/Tag: message" or "I/Tag: message" (Android logcat style)
      else if (RegExp(r'^[VDIWEFS]/\w+:').hasMatch(message)) {
        final fimberMatch = _detectFimber(message);
        if (fimberMatch != null) {
          level = fimberMatch.level;
          tag = fimberMatch.tag;
          message = fimberMatch.message;
        }
      }

      // ---- Detect `simple_logger` patterns ----
      // Output: "2024-01-01 12:00:00.000 [INFO] MyClass: message"
      else if (RegExp(r'^\d{4}-\d{2}-\d{2}\s\d{2}:\d{2}:\d{2}.*\[(DEBUG|INFO|WARNING|ERROR|TRACE)\]').hasMatch(message)) {
        final match = RegExp(r'\[(DEBUG|INFO|WARNING|ERROR|TRACE)\]\s*(\w+)?:?\s*(.*)').firstMatch(message);
        if (match != null) {
          level = _mapLevel(match.group(1)!);
          tag = match.group(2) ?? 'simple_logger';
          message = match.group(3) ?? message;
        }
      }

      // ---- Generic level detection from content ----
      else {
        final lower = message.toLowerCase();
        if (lower.startsWith('[error]') ||
            lower.startsWith('error:') ||
            lower.startsWith('exception:') ||
            lower.contains('══╡ EXCEPTION CAUGHT')) {
          level = 'error';
        } else if (lower.startsWith('[warning]') ||
            lower.startsWith('warning:') ||
            lower.startsWith('[warn]')) {
          level = 'warn';
        } else if (lower.startsWith('[info]') || lower.startsWith('info:')) {
          level = 'info';
        } else if (lower.startsWith('[debug]')) {
          level = 'debug';
        }
      }

      DevConnectClient.safeSendLog(
        level: level,
        message: message,
        tag: tag,
      );
    } catch (_) {}
  }

  /// Detect `logger` package output patterns.
  /// Formats: "│ message", box drawings, or level markers like "[E]", "[W]"
  static _LogMatch? _detectLoggerPackage(String msg) {
    // Skip box-drawing decoration lines
    if (msg.startsWith('┌') || msg.startsWith('├') ||
        msg.startsWith('└') || msg.startsWith('│─')) {
      return null; // decoration, skip entirely
    }

    // Content line: "│ actual message"
    if (msg.startsWith('│ ')) {
      return _LogMatch(
        level: 'debug',
        tag: 'logger',
        message: msg.substring(2).trim(),
      );
    }

    // Level markers from logger: [V], [D], [I], [W], [E], [F]
    final levelMatch = RegExp(r'^\[([VDIWEF])\]\s*(.*)').firstMatch(msg);
    if (levelMatch != null) {
      final l = levelMatch.group(1)!;
      String level;
      switch (l) {
        case 'V':
        case 'D':
          level = 'debug';
          break;
        case 'I':
          level = 'info';
          break;
        case 'W':
          level = 'warn';
          break;
        case 'E':
        case 'F':
          level = 'error';
          break;
        default:
          level = 'debug';
      }
      return _LogMatch(
        level: level,
        tag: 'logger',
        message: levelMatch.group(2)?.trim() ?? msg,
      );
    }

    return null;
  }

  /// Detect `talker` package output.
  /// Format: "[Talker] | HH:MM:SS | LEVEL: message"
  static _LogMatch? _detectTalker(String msg) {
    final match = RegExp(
      r'\[(?:T|t)alker\]\s*\|\s*[\d:]+\s*\|\s*(DEBUG|INFO|WARNING|ERROR|CRITICAL|VERBOSE|GOOD):\s*(.*)',
    ).firstMatch(msg);

    if (match != null) {
      return _LogMatch(
        level: _mapLevel(match.group(1)!),
        tag: 'talker',
        message: match.group(2)?.trim() ?? msg,
      );
    }

    // Simpler talker format: "[Talker] message"
    final simpleMatch = RegExp(r'\[(?:T|t)alker\]\s*(.*)').firstMatch(msg);
    if (simpleMatch != null) {
      return _LogMatch(
        level: 'info',
        tag: 'talker',
        message: simpleMatch.group(1)?.trim() ?? msg,
      );
    }

    return null;
  }

  /// Detect dart:logging package output.
  /// Format: "[INFO] loggerName: message"
  static _LogMatch? _detectLoggingPackage(String msg) {
    final match = RegExp(
      r'^\[(FINE|FINER|FINEST|CONFIG|INFO|WARNING|SEVERE|SHOUT)\]\s*(\w[\w.]*)?:?\s*(.*)',
    ).firstMatch(msg);

    if (match != null) {
      return _LogMatch(
        level: _mapLevel(match.group(1)!),
        tag: match.group(2) ?? 'logging',
        message: match.group(3)?.trim() ?? msg,
      );
    }
    return null;
  }

  /// Detect fimber/fimber_io package output.
  /// Format: "D/MyTag: message"
  static _LogMatch? _detectFimber(String msg) {
    final match = RegExp(r'^([VDIWEFS])/(\w+):\s*(.*)').firstMatch(msg);
    if (match != null) {
      final l = match.group(1)!;
      String level;
      switch (l) {
        case 'V':
        case 'D':
          level = 'debug';
          break;
        case 'I':
          level = 'info';
          break;
        case 'W':
          level = 'warn';
          break;
        case 'E':
        case 'S':
        case 'F':
          level = 'error';
          break;
        default:
          level = 'debug';
      }
      return _LogMatch(
        level: level,
        tag: match.group(2) ?? 'fimber',
        message: match.group(3)?.trim() ?? msg,
      );
    }
    return null;
  }

  static String _mapLevel(String raw) {
    switch (raw.toUpperCase()) {
      case 'VERBOSE':
      case 'DEBUG':
      case 'FINE':
      case 'FINER':
      case 'FINEST':
      case 'CONFIG':
      case 'TRACE':
        return 'debug';
      case 'INFO':
      case 'GOOD':
        return 'info';
      case 'WARNING':
      case 'WARN':
        return 'warn';
      case 'ERROR':
      case 'SEVERE':
      case 'SHOUT':
      case 'CRITICAL':
        return 'error';
      default:
        return 'debug';
    }
  }
}

class _LogMatch {
  final String level;
  final String tag;
  final String message;

  _LogMatch({required this.level, required this.tag, required this.message});
}
