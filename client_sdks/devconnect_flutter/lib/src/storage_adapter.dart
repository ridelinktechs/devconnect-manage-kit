import 'dart:async';

/// A key-value store the desktop's Storage tab can list and edit. The
/// SDK's storage wrappers register theirs; see `DevConnect.registerStorage`
/// for other stores.
class DevConnectStorageAdapter {
  final FutureOr<Map<String, Object?>> Function() getAll;
  final FutureOr<void> Function(String key, Object? value) set;
  final FutureOr<void> Function(String key) remove;
  final FutureOr<void> Function() clear;

  const DevConnectStorageAdapter({
    required this.getAll,
    required this.set,
    required this.remove,
    required this.clear,
  });
}
