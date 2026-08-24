/// Round 3: GraphQL operation entry. The desktop pairs operation +
/// response by [operation] name so a "GraphQL" tab can show start →
/// finish in one row.
class GraphqlEntry {
  final String id;
  final String deviceId;
  final String operation;
  final String type; // query | mutation | subscription
  final Map<String, dynamic> variables;
  final bool isComplete;
  final int? latencyMs;
  final bool cacheHit;
  final Map<String, dynamic>? data;
  final List<Map<String, dynamic>>? errors;
  final String? error;
  final int timestamp;
  final Map<String, dynamic>? metadata;

  const GraphqlEntry({
    required this.id,
    required this.deviceId,
    required this.operation,
    required this.type,
    required this.variables,
    required this.isComplete,
    required this.timestamp,
    this.latencyMs,
    this.cacheHit = false,
    this.data,
    this.errors,
    this.error,
    this.metadata,
  });

  GraphqlEntry copyWith({bool? isComplete, int? latencyMs, bool? cacheHit,
      Map<String, dynamic>? data, List<Map<String, dynamic>>? errors,
      String? error, Map<String, dynamic>? metadata}) =>
      GraphqlEntry(
        id: id,
        deviceId: deviceId,
        operation: operation,
        type: type,
        variables: variables,
        isComplete: isComplete ?? this.isComplete,
        latencyMs: latencyMs ?? this.latencyMs,
        cacheHit: cacheHit ?? this.cacheHit,
        data: data ?? this.data,
        errors: errors ?? this.errors,
        error: error ?? this.error,
        timestamp: timestamp,
        metadata: metadata ?? this.metadata,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'deviceId': deviceId,
        'operation': operation,
        'type': type,
        'variables': variables,
        'isComplete': isComplete,
        if (latencyMs != null) 'latencyMs': latencyMs,
        if (cacheHit) 'cacheHit': cacheHit,
        if (data != null) 'data': data,
        if (errors != null && errors!.isNotEmpty) 'errors': errors,
        if (error != null) 'error': error,
        'timestamp': timestamp,
        if (metadata != null) 'metadata': metadata,
      };

  factory GraphqlEntry.fromJson(Map<String, dynamic> json) => GraphqlEntry(
        id: json['id'] as String,
        deviceId: json['deviceId'] as String,
        operation: json['operation'] as String? ?? 'anonymous',
        type: json['type'] as String? ?? 'query',
        variables: (json['variables'] as Map?)?.cast<String, dynamic>() ?? const {},
        isComplete: json['isComplete'] as bool? ?? false,
        latencyMs: json['latencyMs'] as int?,
        cacheHit: json['cacheHit'] as bool? ?? false,
        data: (json['data'] as Map?)?.cast<String, dynamic>(),
        errors: (json['errors'] as List?)
            ?.whereType<Map>()
            .map((e) => e.cast<String, dynamic>())
            .toList(),
        error: json['error'] as String?,
        timestamp: json['timestamp'] as int? ?? 0,
        metadata: (json['metadata'] as Map?)?.cast<String, dynamic>(),
      );
}

/// Round 3: a single WebSocket frame (sent or received) over a tracked
/// socket connection.
class WebsocketFrameEntry {
  final String id;
  final String deviceId;
  final String url;
  final String direction; // sent | received | open | close | error
  final String payload;
  final int sizeBytes;
  final int timestamp;
  final Map<String, dynamic>? metadata;

  const WebsocketFrameEntry({
    required this.id,
    required this.deviceId,
    required this.url,
    required this.direction,
    required this.payload,
    required this.sizeBytes,
    required this.timestamp,
    this.metadata,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'deviceId': deviceId,
        'url': url,
        'direction': direction,
        'payload': payload,
        'sizeBytes': sizeBytes,
        'timestamp': timestamp,
        if (metadata != null) 'metadata': metadata,
      };

  factory WebsocketFrameEntry.fromJson(Map<String, dynamic> json) =>
      WebsocketFrameEntry(
        id: json['id'] as String,
        deviceId: json['deviceId'] as String,
        url: json['url'] as String? ?? '',
        direction: json['direction'] as String? ?? 'sent',
        payload: json['payload'] as String? ?? '',
        sizeBytes: json['sizeBytes'] as int? ?? 0,
        timestamp: json['timestamp'] as int? ?? 0,
        metadata: (json['metadata'] as Map?)?.cast<String, dynamic>(),
      );
}

/// Round 3: a single gRPC unary or streaming call observed on the wire.
class GrpcCallEntry {
  final String id;
  final String deviceId;
  final String service;
  final String method;
  final String request;
  final String? response;
  final int timestamp;
  final int? latencyMs;
  final String? status; // ok | error | cancelled | unknown
  final String? error;
  final Map<String, dynamic>? metadata;

  const GrpcCallEntry({
    required this.id,
    required this.deviceId,
    required this.service,
    required this.method,
    required this.request,
    required this.timestamp,
    this.response,
    this.latencyMs,
    this.status,
    this.error,
    this.metadata,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'deviceId': deviceId,
        'service': service,
        'method': method,
        'request': request,
        if (response != null) 'response': response,
        'timestamp': timestamp,
        if (latencyMs != null) 'latencyMs': latencyMs,
        if (status != null) 'status': status,
        if (error != null) 'error': error,
        if (metadata != null) 'metadata': metadata,
      };

  factory GrpcCallEntry.fromJson(Map<String, dynamic> json) => GrpcCallEntry(
        id: json['id'] as String,
        deviceId: json['deviceId'] as String,
        service: json['service'] as String? ?? '',
        method: json['method'] as String? ?? '',
        request: json['request'] as String? ?? '',
        response: json['response'] as String?,
        timestamp: json['timestamp'] as int? ?? 0,
        latencyMs: json['latencyMs'] as int?,
        status: json['status'] as String?,
        error: json['error'] as String?,
        metadata: (json['metadata'] as Map?)?.cast<String, dynamic>(),
      );
}
