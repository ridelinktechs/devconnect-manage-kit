part of '../ws_message_handler.dart';

extension _DisplayMessages on WsMessageHandler {
  void _handleDisplay(DCMessage message) {
    final p = message.payload;
    final entry = DisplayEntry(
      id: _uniqueOneShotId(message.id),
      deviceId: message.deviceId,
      name: p['name'] as String? ?? 'Display',
      timestamp: message.timestamp,
      value: p['value'],
      preview: p['preview'] as String?,
      image: p['image'] as String?,
      metadata: p['metadata'] as Map<String, dynamic>?,
    );
    _displayController.add(entry);
  }

  void _handleAsyncOperation(DCMessage message) {
    final p = message.payload;
    final entry = AsyncOperationEntry(
      id: _uniqueOneShotId(message.id),
      deviceId: message.deviceId,
      operationType: _parseAsyncOpType(
        p['operationType'] as String? ?? 'custom',
      ),
      description: p['description'] as String? ?? '',
      status: _parseAsyncOpStatus(p['status'] as String? ?? 'start'),
      timestamp: message.timestamp,
      duration: p['duration'] as int?,
      sagaName: p['sagaName'] as String?,
      error: p['error'] as String?,
      result: p['result'],
      metadata: p['metadata'] as Map<String, dynamic>?,
    );
    _asyncOpController.add(entry);
  }

  AsyncOperationType _parseAsyncOpType(String type) {
    switch (type) {
      case 'saga_take':
        return AsyncOperationType.sagaTake;
      case 'saga_put':
        return AsyncOperationType.sagaPut;
      case 'saga_call':
        return AsyncOperationType.sagaCall;
      case 'saga_fork':
        return AsyncOperationType.sagaFork;
      case 'saga_all':
        return AsyncOperationType.sagaAll;
      case 'saga_race':
        return AsyncOperationType.sagaRace;
      case 'saga_select':
        return AsyncOperationType.sagaSelect;
      case 'saga_delay':
        return AsyncOperationType.sagaDelay;
      case 'async_task':
        return AsyncOperationType.asyncTask;
      case 'background_job':
        return AsyncOperationType.backgroundJob;
      default:
        return AsyncOperationType.custom;
    }
  }

  AsyncOperationStatus _parseAsyncOpStatus(String status) {
    switch (status) {
      case 'resolve':
        return AsyncOperationStatus.resolve;
      case 'reject':
        return AsyncOperationStatus.reject;
      default:
        return AsyncOperationStatus.start;
    }
  }
}
