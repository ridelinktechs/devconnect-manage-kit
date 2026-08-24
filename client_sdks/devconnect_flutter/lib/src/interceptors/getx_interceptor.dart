import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../devconnect_client.dart';

/// GetConnect HTTP interceptor for GetX that auto-captures all HTTP requests.
///
/// This interceptor works by duck-typing - it implements the same interface
/// as GetConnect's request/response modifiers without depending on GetX directly.
///
/// Usage:
/// ```dart
/// import 'package:get/get.dart';
///
/// class ApiProvider extends GetConnect {
///   @override
///   void onInit() {
///     httpClient.addRequestModifier(DevConnect.getConnectModifier());
///     httpClient.addResponseModifier(DevConnect.getConnectResponseModifier());
///     super.onInit();
///   }
/// }
/// ```
///
/// Or with a standalone GetConnect instance:
/// ```dart
/// final connect = GetConnect();
/// connect.httpClient.addRequestModifier(DevConnect.getConnectModifier());
/// connect.httpClient.addResponseModifier(DevConnect.getConnectResponseModifier());
/// ```
class DevConnectGetConnectInterceptor {
  final _uuid = const Uuid();
  final Map<String, _RequestInfo> _pendingRequests = {};

  /// Returns a request modifier function compatible with GetConnect's
  /// `httpClient.addRequestModifier()`.
  ///
  /// This captures outgoing request details and sends them to DevConnect.
  dynamic Function(dynamic) requestModifier() {
    return (dynamic request) {
      try {
        final requestId = _uuid.v4();
        final startTime = DateTime.now().millisecondsSinceEpoch;

        final String method = _tryGet<String?>(() => request.method?.toString()) ?? 'GET';
        final String url = _tryGet<String?>(() => request.url?.toString()) ?? '';
        // `dynamic` (not `String`) so nested Map/List header values can
        // survive — the desktop inspector JSON-encodes them for display.
        final Map<String, dynamic> headers = {};
        try {
          final h = request.headers;
          if (h is Map) {
            h.forEach((k, v) => headers[k.toString()] = v);
          }
        } catch (_) {}

        // Store request info for matching with response
        _pendingRequests[url] = _RequestInfo(
          requestId: requestId,
          startTime: startTime,
          method: method,
          url: url,
          headers: headers,
        );

        DevConnectClient.safeReportNetworkStart(
          requestId: requestId,
          method: method,
          url: url,
          headers: headers,
        );
      } catch (_) {}

      return request;
    };
  }

  /// Returns a response modifier function compatible with GetConnect's
  /// `httpClient.addResponseModifier()`.
  ///
  /// This captures response details and reports the completed request.
  dynamic Function(dynamic, dynamic) responseModifier() {
    return (dynamic request, dynamic response) {
      try {
        final String url = _tryGet<String?>(() => request.url?.toString()) ?? '';
        final info = _pendingRequests.remove(url);
        final requestId = info?.requestId ?? _uuid.v4();
        final startTime = info?.startTime ?? DateTime.now().millisecondsSinceEpoch;
        final String method = info?.method ?? _tryGet<String?>(() => request.method?.toString()) ?? 'GET';

        final int statusCode = _tryGet<int?>(() => response.statusCode as int?) ?? 0;

        // Request headers
        final Map<String, dynamic> requestHeaders = info?.headers ?? {};

        // Response headers — preserve nested Map/List values for
        // inspectable JSON display. Lists (multi-value headers like
        // Set-Cookie) are joined with ", " for backward compatibility.
        final Map<String, dynamic> responseHeaders = {};
        try {
          final h = response.headers;
          if (h is Map) {
            h.forEach((k, v) {
              if (v is List) {
                responseHeaders[k.toString()] = v.join(', ');
              } else {
                responseHeaders[k.toString()] = v;
              }
            });
          }
        } catch (_) {}

        // Response body
        dynamic responseBody;
        try {
          final body = response.body;
          if (body is Map || body is List) {
            responseBody = body;
          } else if (body is String) {
            try {
              responseBody = jsonDecode(body);
            } catch (_) {
              responseBody = body;
            }
          }
        } catch (_) {}

        // Check for errors
        final bool hasError = _tryGet<bool?>(() => response.hasError as bool?) ?? false;
        final String? errorMessage = hasError
            ? _tryGet<String?>(() => response.statusText?.toString())
            : null;

        DevConnectClient.safeReportNetworkComplete(
          requestId: requestId,
          method: method,
          url: url,
          statusCode: statusCode,
          startTime: startTime,
          requestHeaders: requestHeaders,
          responseHeaders: responseHeaders,
          responseBody: responseBody,
          error: errorMessage,
        );
      } catch (_) {}

      return response;
    };
  }

  static T? _tryGet<T>(T Function() getter) {
    try {
      return getter();
    } catch (_) {
      return null;
    }
  }
}

class _RequestInfo {
  final String requestId;
  final int startTime;
  final String method;
  final String url;
  final Map<String, dynamic> headers;

  _RequestInfo({
    required this.requestId,
    required this.startTime,
    required this.method,
    required this.url,
    required this.headers,
  });
}
