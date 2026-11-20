part of '../ws_message_handler.dart';

extension _RoundMessages on WsMessageHandler {
  // ---- Round 2-5 handlers ----

  void _handleStateRound(DCMessage message) {
    final p = message.payload;
    final manager = switch (message.type) {
      WsMessageTypes.clientBlocChange => 'bloc',
      WsMessageTypes.clientProviderUpdate => 'provider',
      WsMessageTypes.clientReactQueryChange => 'react_query',
      WsMessageTypes.clientApolloOperation => 'apollo',
      _ => p['manager'] as String? ?? 'unknown',
    };
    final entry = StateRoundEntry(
      id: _uniqueOneShotId(message.id),
      deviceId: message.deviceId,
      manager: manager,
      action: p['action'] as String? ?? '',
      previousState:
          (p['previousState'] as Map?)?.cast<String, dynamic>() ?? const {},
      nextState: (p['nextState'] as Map?)?.cast<String, dynamic>() ?? const {},
      timestamp: message.timestamp,
      metadata: p['metadata'] as Map<String, dynamic>?,
    );
    _stateRoundController.add(entry);
  }

  void _handleGraphql(DCMessage message) {
    final p = message.payload;
    final operationId = _nonEmpty(p['operationId']);
    final operation = _nonEmpty(p['operation']) ?? 'anonymous';
    final isResponse = message.type != WsMessageTypes.clientGraphqlOperation;
    // Without an operationId (older SDKs) a response goes to the oldest
    // operation of the same name still waiting on this device.
    final pendingKey = '${message.deviceId}|$operation';
    final id =
        operationId ??
        (isResponse ? _takePending(_pendingGraphql, pendingKey) : null) ??
        _uniqueOneShotId(message.id);
    if (!isResponse && operationId == null) {
      _queuePending(_pendingGraphql, pendingKey, id);
    }
    _graphqlController.add(
      GraphqlEntry(
        id: id,
        deviceId: message.deviceId,
        operation: operation,
        type: _graphqlType(p['type']),
        variables: _jsonMap(p['variables']) ?? const {},
        isComplete: isResponse,
        latencyMs: p['latencyMs'] is num
            ? (p['latencyMs'] as num).toInt()
            : null,
        cacheHit: p['cacheHit'] == true,
        data: _jsonMap(p['data']),
        errors: p['errors'] is List
            ? [
                for (final e in (p['errors'] as List).whereType<Map>())
                  e.cast<String, dynamic>(),
              ]
            : null,
        error: _nonEmpty(p['error']),
        timestamp: message.timestamp,
        metadata: _jsonMap(p['metadata']),
      ),
    );
  }

  /// `query` / `mutation` / `subscription` from whatever the SDK sent —
  /// older Android SDKs send the operation's class name (`GetUserQuery`).
  static String _graphqlType(Object? raw) {
    final type = raw is String ? raw.toLowerCase() : '';
    if (type.contains('mutation')) return 'mutation';
    if (type.contains('subscription')) return 'subscription';
    return 'query';
  }

  static String? _nonEmpty(Object? v) => v is String && v.isNotEmpty ? v : null;

  static Map<String, dynamic>? _jsonMap(Object? v) =>
      v is Map ? v.cast<String, dynamic>() : null;

  /// Queues [id] under [key], capped so halves that never arrive can't
  /// pile up.
  void _queuePending(Map<String, List<String>> pending, String key, String id) {
    final queue = pending[key] ??= [];
    queue.add(id);
    if (queue.length > 64) queue.removeAt(0);
    if (pending.length > 256) pending.remove(pending.keys.first);
  }

  /// The oldest id queued under [key], dequeued; null if there is none.
  String? _takePending(Map<String, List<String>> pending, String key) {
    final queue = pending[key];
    if (queue == null || queue.isEmpty) return null;
    final id = queue.removeAt(0);
    if (queue.isEmpty) pending.remove(key);
    return id;
  }

  void _handleWebsocket(DCMessage message) {
    final p = message.payload;
    final rawConnectionId = _nonEmpty(p['connectionId']);
    final url = _nonEmpty(p['url']) ?? '';
    String connectionId;
    String direction;
    switch (message.type) {
      case WsMessageTypes.clientWebsocketOpen:
        direction = 'open';
        // SDKs are required to send a `connectionId`; if they don't,
        // mint one so the panel can still group later frames/close.
        connectionId = (rawConnectionId != null && rawConnectionId.isNotEmpty)
            ? rawConnectionId
            : _mintWebsocketConnectionId(url);
        _openWebsocketConnections[connectionId] = url;
        _trimWebsocketConnections();
        break;
      case WsMessageTypes.clientWebsocketClose:
        // A close carrying an error is how the SDKs report a failed socket.
        direction = _nonEmpty(p['error']) != null ? 'error' : 'close';
        // Same fallback as frames: older SDKs send no connectionId.
        connectionId = (rawConnectionId != null && rawConnectionId.isNotEmpty)
            ? rawConnectionId
            : _existingConnectionIdForUrl(url) ??
                  _mintWebsocketConnectionId(url);
        _openWebsocketConnections.remove(connectionId);
        break;
      default:
        // The SDKs say `send` / `receive`; the panel speaks `sent` / `received`.
        direction = switch (p['direction']) {
          'receive' || 'received' => 'received',
          _ => 'sent',
        };
        // Frames: fall back to the only open socket for this URL if
        // the SDK didn't attach a connectionId (older SDKs).
        connectionId = (rawConnectionId != null && rawConnectionId.isNotEmpty)
            ? rawConnectionId
            : _existingConnectionIdForUrl(url) ??
                  _mintWebsocketConnectionId(url);
        break;
    }
    final entry = WebsocketFrameEntry(
      id: _uniqueOneShotId(message.id),
      deviceId: message.deviceId,
      url: url,
      connectionId: connectionId,
      direction: direction,
      payload: switch (p['payload']) {
        final String text => text,
        null => _nonEmpty(p['error']) ?? '',
        final other => jsonEncode(other),
      },
      sizeBytes: p['sizeBytes'] is num ? (p['sizeBytes'] as num).toInt() : 0,
      timestamp: message.timestamp,
      closeCode: switch (p['closeCode'] ?? p['code']) {
        final num code => code.toInt(),
        _ => null,
      },
      closeReason: _nonEmpty(p['closeReason'] ?? p['reason']),
      metadata: _jsonMap(p['metadata']),
    );
    _websocketController.add(entry);
  }

  /// Mint a deterministic connection id from the URL when an SDK
  /// doesn't supply one. Uses the URL as-is so multiple events for the
  /// same socket collapse to a single id.
  String _mintWebsocketConnectionId(String url) {
    final seq = (++_wsConnectionSeq).toRadixString(36);
    final micros = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    return 'ws-$url-$micros-$seq';
  }

  String? _existingConnectionIdForUrl(String url) {
    for (final entry in _openWebsocketConnections.entries) {
      if (entry.value == url) return entry.key;
    }
    return null;
  }

  void _trimWebsocketConnections() {
    if (_openWebsocketConnections.length <= 512) return;
    final drop = _openWebsocketConnections.length - 256;
    final keys = _openWebsocketConnections.keys.toList(growable: false);
    for (var i = 0; i < drop; i++) {
      _openWebsocketConnections.remove(keys[i]);
    }
  }

  void _handleGrpc(DCMessage message) {
    final p = message.payload;
    final service = _nonEmpty(p['service']) ?? '';
    final method = _nonEmpty(p['method']) ?? '';
    // Android's events carry byte counts, flags and the raw status code;
    // keep them for the detail view.
    final metadata = <String, dynamic>{
      ...?_jsonMap(p['metadata']),
      for (final key in const [
        'fullMethod',
        'requestStreaming',
        'responseStreaming',
        'requestBytes',
        'responseBytes',
        'statusDescription',
      ])
        if (p[key] != null) key: p[key],
      'statusCode': ?_nonEmpty(p['status']),
    };
    GrpcCallEntry entry(String id) => GrpcCallEntry(
      id: id,
      deviceId: message.deviceId,
      service: service,
      method: method,
      request: _nonEmpty(p['request']) ?? '',
      response: _nonEmpty(p['response']),
      timestamp: message.timestamp,
      latencyMs: p['latencyMs'] is num ? (p['latencyMs'] as num).toInt() : null,
      status: _grpcStatus(p['status']),
      error: _nonEmpty(p['error']),
      metadata: metadata.isEmpty ? null : metadata,
    );
    // Legacy single-event format: everything on one message.
    if (message.type == WsMessageTypes.clientGrpcCall) {
      _grpcController.add(entry(_uniqueOneShotId(message.id)));
      return;
    }
    // Split start/end format (Android): a shared `callId` ties the halves
    // into one row.
    final callId = _nonEmpty(p['callId']);
    final isEnd = message.type == WsMessageTypes.clientGrpcCallEnd;
    String id;
    if (callId != null) {
      id = _grpcCanonicalId(callId, isEnd);
      if (isEnd) _openGrpcCalls.remove(id);
    } else {
      // Older Android SDKs send no callId: an end goes to the oldest
      // unfinished call of the same method on this device.
      final key = '${message.deviceId}|$service/$method';
      if (isEnd) {
        id = _takePending(_pendingGrpc, key) ?? _uniqueOneShotId(message.id);
      } else {
        id = _uniqueOneShotId(message.id);
        _queuePending(_pendingGrpc, key, id);
      }
    }
    _grpcController.add(entry(id));
  }

  /// `ok` / `cancelled` / `error` from a status in any casing — Android
  /// sends gRPC code names such as `OK` or `UNAVAILABLE`.
  static String? _grpcStatus(Object? raw) => switch (raw) {
    final String s when s.toLowerCase() == 'ok' => 'ok',
    final String s when s.toLowerCase() == 'cancelled' => 'cancelled',
    final String s when s.isNotEmpty => 'error',
    _ => null,
  };

  /// Round-trip id for split gRPC start/end events. Same shape as
  /// network round-trip — first start mints `callId` as canonical,
  /// end reuses it; concurrent same-callId disambiguates.
  String _grpcCanonicalId(String callId, bool isEnd) {
    if (isEnd) {
      final existing = _existingOpenGrpcCanonical(callId);
      if (existing != null) return existing;
      return callId;
    }
    final existing = _existingOpenGrpcCanonical(callId);
    if (existing != null) return _disambiguateGrpc(callId);
    _openGrpcCalls[callId] = callId;
    _trimOpenGrpcCalls();
    return callId;
  }

  String? _existingOpenGrpcCanonical(String callId) {
    for (final entry in _openGrpcCalls.entries) {
      if (entry.value == callId) return entry.key;
    }
    return null;
  }

  String _disambiguateGrpc(String base) {
    final seq = (++_grpcSeq).toRadixString(36);
    final micros = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    return '$base-$micros-$seq';
  }

  void _trimOpenGrpcCalls() {
    if (_openGrpcCalls.length <= 512) return;
    final drop = _openGrpcCalls.length - 256;
    final keys = _openGrpcCalls.keys.toList(growable: false);
    for (var i = 0; i < drop; i++) {
      _openGrpcCalls.remove(keys[i]);
    }
  }

  void _handleMockAudit(DCMessage message) {
    final p = message.payload;
    final entry = MockedRequestEntry.fromAuditPayload(
      p,
      id: _uniqueOneShotId(message.id),
      deviceId: message.deviceId,
      timestamp: message.timestamp,
    );
    _mockAuditController.add(entry);
  }
}
