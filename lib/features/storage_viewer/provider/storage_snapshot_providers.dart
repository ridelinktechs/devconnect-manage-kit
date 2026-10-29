import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../server/providers/server_providers.dart';

/// A store's contents as the app last reported them.
class StorageSnapshot {
  final Map<String, Object?> entries;
  final String? error;

  const StorageSnapshot(this.entries, [this.error]);
}

/// Each device's editable stores (`client:storage:all_data`), by device id
/// then storage type. Sorted by storage type.
final storageSnapshotsProvider =
    NotifierProvider<
      StorageSnapshotsNotifier,
      Map<String, Map<String, StorageSnapshot>>
    >(StorageSnapshotsNotifier.new);

class StorageSnapshotsNotifier
    extends Notifier<Map<String, Map<String, StorageSnapshot>>> {
  @override
  Map<String, Map<String, StorageSnapshot>> build() {
    final handler = ref.watch(wsMessageHandlerProvider);
    final sub = handler.onStorageSnapshot.listen((m) {
      final deviceId = m['deviceId'] as String;
      final storageType = m['storageType'] as String? ?? '';
      final entries = m['entries'];
      final stores = {
        ...?state[deviceId],
        storageType: StorageSnapshot(
          entries is Map ? entries.cast<String, Object?>() : const {},
          m['error'] as String?,
        ),
      };
      state = {
        ...state,
        deviceId: Map.fromEntries(
          stores.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
        ),
      };
    });
    ref.onDispose(sub.cancel);
    return const {};
  }
}

/// [value] as one editable / displayable line of text.
String storageValueText(Object? value) {
  if (value is String) return value;
  try {
    return jsonEncode(value);
  } catch (_) {
    return '$value';
  }
}

/// What to send for [text] typed over [original]: the same type it had,
/// since the app reads it back typed (`getInt`, `getString`, …). A new key
/// stays a string unless the text is a JSON object or array.
Object? parseStorageEdit(String text, Object? original) {
  switch (original) {
    case String():
      return text;
    case int():
      return int.tryParse(text.trim()) ?? text;
    case num():
      return num.tryParse(text.trim()) ?? text;
    case bool():
      final t = text.trim().toLowerCase();
      return t == 'true' ? true : (t == 'false' ? false : text);
  }
  final trimmed = text.trim();
  if (original is List ||
      original is Map ||
      trimmed.startsWith('{') ||
      trimmed.startsWith('[')) {
    try {
      return jsonDecode(trimmed);
    } on FormatException {
      return text;
    }
  }
  return text;
}
