import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../devconnect_client.dart';

/// Dio-compatible interceptor that auto-captures all HTTP requests.
///
/// This interceptor works by duck-typing - it implements the same interface
/// as Dio's Interceptor without depending on the Dio package directly.
///
/// Usage:
/// ```dart
/// import 'package:dio/dio.dart';
///
/// final dio = Dio();
/// dio.interceptors.add(DevConnect.dioInterceptor());
/// // All requests through this Dio instance are now captured!
/// ```
class DevConnectDioInterceptor {
  final _uuid = const Uuid();
  final Map<String, int> _startTimes = {};

  /// Called when a request is about to be sent.
  /// Compatible with Dio's InterceptorSendCallback.
  void onRequest(dynamic options, dynamic handler) {
    try {
      final requestId = _uuid.v4();
      final startTime = DateTime.now().millisecondsSinceEpoch;

      // Store start time keyed by request hashCode
      _startTimes['${options.hashCode}'] = startTime;

      // Extract request info via duck typing
      final String method = options.method ?? 'GET';
      final String url = options.uri?.toString() ?? options.path ?? '';
      final Map<String, String> headers = {};
      try {
        final h = options.headers;
        if (h is Map) {
          h.forEach((k, v) => headers[k.toString()] = v.toString());
        }
      } catch (_) {}

      dynamic requestBody;
      try {
        final data = options.data;
        requestBody = _extractBody(data);
      } catch (_) {}

      // Store requestId on the options extras for later retrieval
      try {
        if (options.extra is Map) {
          options.extra['_dc_request_id'] = requestId;
          options.extra['_dc_start_time'] = startTime;
        }
      } catch (_) {}

      DevConnectClient.safeReportNetworkStart(
        requestId: requestId,
        method: method,
        url: url,
        headers: headers,
        body: requestBody,
      );
    } catch (_) {}

    // Continue the request
    try {
      handler.next(options);
    } catch (_) {}
  }

  /// Called when a response is received.
  void onResponse(dynamic response, dynamic handler) {
    try {
      final options = response.requestOptions;
      final String requestId =
          options?.extra?['_dc_request_id'] ?? _uuid.v4();
      final int startTime =
          options?.extra?['_dc_start_time'] ??
          _startTimes.remove('${options.hashCode}') ??
          DateTime.now().millisecondsSinceEpoch;

      final String method = options?.method ?? 'GET';
      final String url = options?.uri?.toString() ?? '';
      final int statusCode = response.statusCode ?? 0;

      // Request headers
      final Map<String, String> requestHeaders = {};
      try {
        final h = options?.headers;
        if (h is Map) {
          h.forEach((k, v) => requestHeaders[k.toString()] = v.toString());
        }
      } catch (_) {}

      // Response headers
      final Map<String, String> responseHeaders = {};
      try {
        final h = response.headers;
        // Dio headers have a .map property
        if (h != null) {
          try {
            final map = h.map;
            if (map is Map) {
              map.forEach((k, v) {
                if (v is List) {
                  responseHeaders[k.toString()] = v.join(', ');
                } else {
                  responseHeaders[k.toString()] = v.toString();
                }
              });
            }
          } catch (_) {}
        }
      } catch (_) {}

      // Response body
      dynamic responseBody;
      try {
        final data = response.data;
        if (data is Map || data is List) {
          responseBody = data;
        } else if (data is String) {
          try {
            responseBody = jsonDecode(data);
          } catch (_) {
            responseBody = data;
          }
        }
      } catch (_) {}

      // Request body
      dynamic requestBody;
      try {
        requestBody = _extractBody(options?.data);
      } catch (_) {}

      DevConnectClient.safeReportNetworkComplete(
        requestId: requestId,
        method: method,
        url: url,
        statusCode: statusCode,
        startTime: startTime,
        requestHeaders: requestHeaders,
        responseHeaders: responseHeaders,
        requestBody: requestBody,
        responseBody: responseBody,
      );
    } catch (_) {}

    try {
      handler.next(response);
    } catch (_) {}
  }

  /// Extract request body from various data types including FormData/multipart.
  dynamic _extractBody(dynamic data) {
    if (data == null) return null;
    if (data is Map || data is List) return data;
    if (data is String) {
      try { return jsonDecode(data); } catch (_) { return data; }
    }
    // Handle FormData / multipart — duck-typing (no Dio dependency).
    try {
      final fields = data.fields;
      final files = data.files;
      if (fields is List || files is List) {
        final result = <String, dynamic>{};
        // Text fields: List<MapEntry<String, String>>
        if (fields is List) {
          for (final entry in fields) {
            try { result[entry.key.toString()] = entry.value.toString(); }
            catch (_) {}
          }
        }
        // File fields: List<MapEntry<String, MultipartFile>>
        if (files is List && files.isNotEmpty) {
          final fileList = <Map<String, dynamic>>[];
          for (final entry in files) {
            try {
              final file = entry.value;
              fileList.add({
                'key': entry.key.toString(),
                'filename': file.filename?.toString(),
                'contentType': file.contentType?.toString(),
                'length': file.length,
              });
            } catch (_) {}
          }
          result['_files'] = fileList;
        }
        if (result.isNotEmpty) {
          result['_contentType'] = 'multipart/form-data';
          return result;
        }
      }
    } catch (_) {}
    // Fallback: toString
    try { return data.toString(); } catch (_) { return null; }
  }

  /// Called when an error occurs.
  void onError(dynamic error, dynamic handler) {
    try {
      final options = error.requestOptions;
      final String requestId =
          options?.extra?['_dc_request_id'] ?? _uuid.v4();
      final int startTime =
          options?.extra?['_dc_start_time'] ??
          _startTimes.remove('${options.hashCode}') ??
          DateTime.now().millisecondsSinceEpoch;

      final String method = options?.method ?? 'GET';
      final String url = options?.uri?.toString() ?? '';
      final int statusCode = error.response?.statusCode ?? 0;

      final Map<String, String> requestHeaders = {};
      try {
        final h = options?.headers;
        if (h is Map) {
          h.forEach((k, v) => requestHeaders[k.toString()] = v.toString());
        }
      } catch (_) {}

      dynamic responseBody;
      try {
        responseBody = error.response?.data;
      } catch (_) {}

      DevConnectClient.safeReportNetworkComplete(
        requestId: requestId,
        method: method,
        url: url,
        statusCode: statusCode,
        startTime: startTime,
        requestHeaders: requestHeaders,
        responseBody: responseBody,
        error: error.message?.toString() ?? error.toString(),
      );
    } catch (_) {}

    try {
      handler.next(error);
    } catch (_) {}
  }
}
