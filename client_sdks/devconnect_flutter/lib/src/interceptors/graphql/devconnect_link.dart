import 'dart:async';
import 'dart:convert';

import '../../devconnect_client.dart';

/// `gql_link`-compatible [Link] that intercepts every GraphQL operation
/// and emits `client:graphql_*` events to the desktop.
///
/// The consumer wires this in front of their existing link:
/// ```dart
/// final link = Link.from([
///   DevConnectLink(),
///   HttpLink('https://api.example.com/graphql'),
/// ]);
/// final client = GraphQLClient(link: link, cache: GraphQLCache());
/// ```
///
/// Implementation strategy: we don't import `gql_exec` directly (to keep
/// `devconnect_flutter` dep-free). Instead we duck-type the `Request`
/// object via dynamic dispatch: any object exposing `operation.operationName`
/// or `operation.toKey()` is treated as a GraphQL request.
///
/// This file works with `graphql_flutter` ≥ 5, `ferry`, or any other
/// `gql_link`-compatible client.
class DevConnectLink implements DevConnectLinkBase {
  @override
  Stream<DevConnectResponse> request(DevConnectRequest request, [DevConnectLinkBase? next]) async* {
    final startTime = DateTime.now().millisecondsSinceEpoch;
    final operationName = _safeName(request);
    final operationType = _safeType(request);
    final variables = _safeVariables(request);

    try {
      DevConnectClient.safeSend('client:graphql_operation', {
        'operation': operationName,
        'type': operationType,
        'variables': variables,
      });
    } catch (_) {}

    if (next == null) {
      // Without a downstream link we can't actually execute the request.
      // Emit a synthetic error so the desktop knows something went wrong.
      try {
        DevConnectClient.safeSend('client:graphql_response', {
          'operation': operationName,
          'type': operationType,
          'error': 'DevConnectLink has no inner link — chain a real Link after it',
        });
      } catch (_) {}
      yield* Stream.error(StateError('No downstream Link'));
      return;
    }

    try {
      // Forward without `next` as the gql_link forwarder. Passing `next`
      // (the inner Link) as its own forwarder makes it call
      // `forwarder.request(...)` → infinite recursion in any chain
      // with > 1 link. With no forwarder, the inner Link terminates the
      // chain (or invokes its own internal forwarder, the way HttpLink
      // does for real HTTP).
      yield* next.request(request);
      final endTime = DateTime.now().millisecondsSinceEpoch;
      try {
        DevConnectClient.safeSend('client:graphql_response', {
          'operation': operationName,
          'type': operationType,
          'latencyMs': endTime - startTime,
        });
      } catch (_) {}
    } catch (e, st) {
      final endTime = DateTime.now().millisecondsSinceEpoch;
      try {
        DevConnectClient.safeSend('client:graphql_response', {
          'operation': operationName,
          'type': operationType,
          'latencyMs': endTime - startTime,
          'error': e.toString(),
          'stack': st.toString(),
        });
      } catch (_) {}
      rethrow;
    }
  }
}

/// Duck-typed stand-in for the real `gql_exec.Link`. We avoid importing
/// `gql_exec` directly to keep this package dep-free.
abstract class DevConnectLinkBase {
  Stream<DevConnectResponse> request(DevConnectRequest request, [DevConnectLinkBase? next]);
}

abstract class DevConnectRequest {
  Map<String, dynamic> get context;
  String get operationName;
}

class DevConnectResponse {
  final Map<String, dynamic> data;
  final List<Map<String, dynamic>>? errors;
  final Map<String, dynamic> context;
  final Map<String, dynamic>? extensions;
  const DevConnectResponse({
    required this.data,
    this.errors,
    required this.context,
    this.extensions,
  });
}

// ---- Helpers ----

String _safeName(DevConnectRequest req) {
  try {
    if (req.operationName.isNotEmpty) return req.operationName;
    // Hash the variables as a fallback when there's no operation name.
    return 'anonymous-${req.context['hash'] ?? '?'}';
  } catch (_) {
    return 'unknown';
  }
}

String _safeType(DevConnectRequest req) {
  try {
    final contextType = req.context['operationType'];
    if (contextType is String) return contextType;
  } catch (_) {}
  return 'query';
}

Map<String, dynamic> _safeVariables(DevConnectRequest req) {
  try {
    final variables = req.context['variables'];
    if (variables is Map) {
      return Map<String, dynamic>.from(variables);
    }
  } catch (_) {}
  return {};
}

// ---- Helper bridge for consumers who don't use a Link chain ----

/// Push a GraphQL operation manually (e.g. when the app uses a non-`gql_link`
/// transport like `graphql` package's `Future Function(QueryOptions)` API).
class DevConnectGraphQLHelper {
  DevConnectGraphQLHelper._();

  static void reportOperation({
    required String operationName,
    required String operationType, // 'query' | 'mutation' | 'subscription'
    Map<String, dynamic>? variables,
  }) {
    try {
      DevConnectClient.safeSend('client:graphql_operation', {
        'operation': operationName,
        'type': operationType,
        if (variables != null) 'variables': variables,
      });
    } catch (_) {}
  }

  static void reportResponse({
    required String operationName,
    required String operationType,
    required int latencyMs,
    Map<String, dynamic>? data,
    List<dynamic>? errors,
    bool cacheHit = false,
  }) {
    try {
      DevConnectClient.safeSend('client:graphql_response', {
        'operation': operationName,
        'type': operationType,
        'latencyMs': latencyMs,
        if (data != null) 'data': _truncate(data, 4096),
        if (errors != null) 'errors': errors,
        'cacheHit': cacheHit,
      });
    } catch (_) {}
  }

  static void reportError({
    required String operationName,
    required String operationType,
    required int latencyMs,
    required Object error,
  }) {
    try {
      DevConnectClient.safeSend('client:graphql_response', {
        'operation': operationName,
        'type': operationType,
        'latencyMs': latencyMs,
        'error': error.toString(),
      });
    } catch (_) {}
  }

  static dynamic _truncate(dynamic value, int maxBytes) {
    try {
      final str = jsonEncode(value);
      if (str.length <= maxBytes) return value;
      return {'_truncated': true, 'preview': str.substring(0, maxBytes)};
    } catch (_) {
      return value;
    }
  }
}