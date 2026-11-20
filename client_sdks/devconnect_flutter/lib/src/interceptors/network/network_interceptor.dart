import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../../devconnect_client.dart';

/// HTTP client wrapper that automatically reports network requests to DevConnect.
///
/// Usage with `http` package:
/// ```dart
/// final client = DevConnectHttpClient(http.Client());
/// final response = await client.get(Uri.parse('https://api.example.com/users'));
/// ```
class DevConnectHttpClient {
  final dynamic _inner;
  final _uuid = const Uuid();

  DevConnectHttpClient(this._inner);

  Future<dynamic> get(Uri url, {Map<String, String>? headers}) async {
    return _intercepted('GET', url, headers: headers);
  }

  Future<dynamic> post(Uri url,
      {Map<String, String>? headers, dynamic body, String? encoding}) async {
    return _intercepted('POST', url, headers: headers, body: body);
  }

  Future<dynamic> put(Uri url,
      {Map<String, String>? headers, dynamic body}) async {
    return _intercepted('PUT', url, headers: headers, body: body);
  }

  Future<dynamic> patch(Uri url,
      {Map<String, String>? headers, dynamic body}) async {
    return _intercepted('PATCH', url, headers: headers, body: body);
  }

  Future<dynamic> delete(Uri url, {Map<String, String>? headers}) async {
    return _intercepted('DELETE', url, headers: headers);
  }

  Future<dynamic> _intercepted(
    String method,
    Uri url, {
    Map<String, String>? headers,
    dynamic body,
  }) async {
    final requestId = _uuid.v4();
    final startTime = DateTime.now().millisecondsSinceEpoch;
    final client = DevConnectClient.instance;

    dynamic requestBody;
    try {
      if (body is String) {
        requestBody = jsonDecode(body);
      } else if (body is Map) {
        requestBody = body;
      }
    } catch (_) {
      requestBody = body?.toString();
    }

    client.reportNetworkStart(
      requestId: requestId,
      method: method,
      url: url.toString(),
      headers: headers,
      body: requestBody,
    );

    try {
      late final dynamic response;

      switch (method) {
        case 'GET':
          response = await Function.apply(
              _inner.get, [url], {#headers: headers});
          break;
        case 'POST':
          response = await Function.apply(
              _inner.post, [url], {#headers: headers, #body: body});
          break;
        case 'PUT':
          response = await Function.apply(
              _inner.put, [url], {#headers: headers, #body: body});
          break;
        case 'PATCH':
          response = await Function.apply(
              _inner.patch, [url], {#headers: headers, #body: body});
          break;
        case 'DELETE':
          response = await Function.apply(
              _inner.delete, [url], {#headers: headers});
          break;
      }

      dynamic responseBody;
      try {
        responseBody = jsonDecode(response.body as String);
      } catch (_) {
        responseBody = response.body;
      }

      final responseHeaders = <String, String>{};
      if (response.headers is Map) {
        (response.headers as Map).forEach((k, v) {
          responseHeaders[k.toString()] = v.toString();
        });
      }

      client.reportNetworkComplete(
        requestId: requestId,
        method: method,
        url: url.toString(),
        statusCode: response.statusCode as int,
        startTime: startTime,
        requestHeaders: headers,
        responseHeaders: responseHeaders,
        requestBody: requestBody,
        responseBody: responseBody,
      );

      return response;
    } catch (e) {
      client.reportNetworkComplete(
        requestId: requestId,
        method: method,
        url: url.toString(),
        statusCode: 0,
        startTime: startTime,
        requestHeaders: headers,
        requestBody: requestBody,
        error: e.toString(),
      );
      rethrow;
    }
  }
}
