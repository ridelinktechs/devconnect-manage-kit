part of '../ws_message_handler.dart';

extension _StateMessages on WsMessageHandler {
  void _handleState(DCMessage message) {
    final p = message.payload;
    final diffList =
        (p['diff'] as List<dynamic>?)
            ?.map((d) => StateDiffEntry.fromJson(d as Map<String, dynamic>))
            .toList() ??
        [];

    final entry = StateChange(
      id: _uniqueOneShotId(message.id),
      deviceId: message.deviceId,
      stateManagerType: p['stateManager'] as String? ?? 'unknown',
      actionName: p['action'] as String? ?? '',
      previousState: (p['previousState'] as Map<String, dynamic>?) ?? {},
      nextState: (p['nextState'] as Map<String, dynamic>?) ?? {},
      diff: diffList,
      timestamp: message.timestamp,
    );
    _stateController.add(entry);
  }
}
