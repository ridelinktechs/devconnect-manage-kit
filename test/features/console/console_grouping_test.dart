import 'package:flutter_test/flutter_test.dart';

import 'package:devconnect_manage_tool/features/console/presentation/detail/occurrences_block.dart';
import 'package:devconnect_manage_tool/features/console/provider/console_providers.dart';
import 'package:devconnect_manage_tool/models/log/log_entry.dart';

LogEntry _log(
  String id,
  String message, {
  LogLevel level = LogLevel.info,
  String device = 'd',
  String? tag,
  String? stackTrace,
  Map<String, dynamic>? metadata,
}) => LogEntry(
  id: id,
  deviceId: device,
  level: level,
  message: message,
  timestamp: DateTime(2026, 10, 28, 10, 21, 3, 45).millisecondsSinceEpoch,
  tag: tag,
  stackTrace: stackTrace,
  metadata: metadata,
);

void main() {
  test('folds only consecutive identical logs into the first', () {
    final grouped = groupRepeats([
      _log('1', 'polling'),
      _log('2', 'polling'),
      _log('3', 'polling'),
      _log('4', 'done'),
      _log('5', 'polling'),
      _log('6', 'polling', level: LogLevel.warn),
      _log('7', 'polling', level: LogLevel.warn, device: 'other'),
    ]);
    expect(grouped.entries.map((e) => e.id), ['1', '4', '5', '6', '7']);
    expect(grouped.runs.keys, ['1']);
    expect(grouped.runs['1']!.map((e) => e.id), ['1', '2', '3']);
  });

  test('gaps between repeats read short', () {
    expect(formatGap(const Duration(milliseconds: 520)), '520ms');
    expect(formatGap(const Duration(milliseconds: 1520)), '1.52s');
    expect(formatGap(const Duration(minutes: 2, seconds: 5)), '2m 05s');
  });

  test('exports readable text with stack and metadata indented', () {
    final text = formatLogsAsText([
      _log(
        '1',
        'Request failed',
        level: LogLevel.error,
        tag: 'api',
        stackTrace: 'at fetch\nat main\n',
        metadata: {'status': 500},
      ),
    ]);
    expect(
      text,
      '2026-10-28 10:21:03.045 [ERROR] [api] Request failed\n'
      '    at fetch\n'
      '    at main\n'
      '    {"status":500}\n',
    );
  });
}
