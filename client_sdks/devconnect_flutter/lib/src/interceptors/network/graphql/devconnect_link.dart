import 'dart:async';

import 'package:uuid/uuid.dart';

import '../../../devconnect_client.dart';

/// Link that reports every GraphQL operation it forwards as
/// `client:graphql_operation` / `client:graphql_response` events.
///
/// It is built on this package's own [DevConnectLinkBase] types (no
/// `gql_link` dependency), so it does not plug into a `gql_link` chain
/// itself. For `graphql_flutter` / ferry, paste the `DevConnectGqlLink`
/// adapter from the README: it reports through the same API,
/// `DevConnect.reportGraphQLOperation` / `DevConnect.reportGraphQLResponse`.
class DevConnectLink implements DevConnectLinkBase {
  @override
  Stream<DevConnectResponse> request(DevConnectRequest request, [DevConnectLinkBase? next]) async* {
    final operation = request.operationName;
    final operationId = DevConnectGraphQLHelper.reportOperation(
      operationName: operation,
      operationType: request.operationType,
      variables: request.variables,
    );
    final watch = Stopwatch()..start();

    if (next == null) {
      // Without a downstream link we can't actually execute the request.
      // Emit a synthetic error so the desktop knows something went wrong.
      DevConnectGraphQLHelper.reportResponse(
        operationId: operationId,
        operation: operation,
        latencyMs: 0,
        error: 'DevConnectLink has no inner link — chain a real Link after it',
      );
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
      await for (final response in next.request(request)) {
        DevConnectGraphQLHelper.reportResponse(
          operationId: operationId,
          operation: operation,
          latencyMs: watch.elapsedMilliseconds,
          data: response.data,
          errors: response.errors,
        );
        yield response;
      }
    } catch (e) {
      DevConnectGraphQLHelper.reportResponse(
        operationId: operationId,
        operation: operation,
        latencyMs: watch.elapsedMilliseconds,
        error: e.toString(),
      );
      rethrow;
    }
  }
}

/// Duck-typed stand-in for the real `gql_exec.Link`. We avoid importing
/// `gql_exec` directly to keep this package dep-free.
abstract class DevConnectLinkBase {
  Stream<DevConnectResponse> request(DevConnectRequest request, [DevConnectLinkBase? next]);
}

/// A GraphQL operation, as [DevConnectLink] reports it.
abstract class DevConnectRequest {
  /// Null or empty for an anonymous operation.
  String? get operationName;

  /// 'query' | 'mutation' | 'subscription'.
  String get operationType;

  Map<String, dynamic> get variables;
}

class DevConnectResponse {
  final Map<String, dynamic>? data;
  final List<Map<String, dynamic>>? errors;
  final Map<String, dynamic> context;
  final Map<String, dynamic>? extensions;
  const DevConnectResponse({
    this.data,
    this.errors,
    this.context = const {},
    this.extensions,
  });
}

// ---- Helper bridge for consumers who don't use a Link chain ----

/// Push a GraphQL operation manually (e.g. when the app uses a non-`gql_link`
/// transport like `graphql` package's `Future Function(QueryOptions)` API).
class DevConnectGraphQLHelper {
  DevConnectGraphQLHelper._();

  /// Reports an operation and returns its `operationId`; pass it to
  /// [reportResponse] when the result arrives.
  static String reportOperation({
    String? operationName,
    required String operationType, // 'query' | 'mutation' | 'subscription'
    Map<String, dynamic>? variables,
  }) {
    final operationId = const Uuid().v4();
    DevConnectClient.safeSend('client:graphql_operation', {
      'operationId': operationId,
      'operation': _operationName(operationName),
      'type': operationType,
      'variables': variables ?? const <String, dynamic>{},
    });
    return operationId;
  }

  /// Reports the result of a [reportOperation] operation: the server's
  /// [data] / [errors], or [error] when the request itself failed.
  static void reportResponse({
    required String operationId,
    String? operation,
    required int latencyMs,
    Map<String, dynamic>? data,
    List<Object?>? errors,
    String? error,
  }) {
    DevConnectClient.safeSend('client:graphql_response', {
      'operationId': operationId,
      'operation': _operationName(operation),
      'latencyMs': latencyMs,
      if (data != null) 'data': data,
      if (errors != null) 'errors': [for (final e in errors) _graphQLError(e)],
      if (error != null) 'error': error,
    });
  }
}

String _operationName(String? name) =>
    name == null || name.isEmpty ? 'anonymous' : name;

/// `{message, path?, locations?}` from a map or a gql `GraphQLError`.
Map<String, dynamic> _graphQLError(Object? error) {
  if (error is Map) return {for (final e in error.entries) '${e.key}': e.value};
  dynamic read(dynamic Function() field) {
    try {
      return field();
    } catch (_) {
      return null;
    }
  }

  final dynamic e = error;
  final path = read(() => e.path);
  final locations = read(() => e.locations);
  return {
    'message': '${read(() => e.message) ?? error}',
    if (path is List) 'path': path,
    if (locations is List)
      'locations': [
        for (final l in locations)
          read(() => {'line': l.line, 'column': l.column}) ?? '$l',
      ],
  };
}
