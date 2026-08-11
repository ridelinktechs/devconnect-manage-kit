import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:uuid/uuid.dart';

import '../devconnect_client.dart';

/// HttpOverrides that globally intercepts ALL HttpClient requests.
///
/// This captures requests from http package, Firebase, OAuth2, image loading,
/// and ANY Dart code that uses HttpClient under the hood.
///
/// Usage:
/// ```dart
/// void main() async {
///   await DevConnect.init(appName: 'MyApp');
///   HttpOverrides.global = DevConnect.httpOverrides();
///   runApp(MyApp());
/// }
/// ```
///
/// This single line captures:
/// - http package requests (get, post, put, delete)
/// - Firebase REST API calls
/// - OAuth2 token requests
/// - Image.network() loading
/// - Any custom HttpClient usage
class DevConnectHttpOverrides extends HttpOverrides {
  final HttpOverrides? _previous;

  DevConnectHttpOverrides() : _previous = HttpOverrides.current;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final innerClient = _previous != null
        ? _previous!.createHttpClient(context)
        : super.createHttpClient(context);
    return _DevConnectHttpClient(innerClient);
  }
}

class _DevConnectHttpClient implements HttpClient {
  final HttpClient _inner;
  final _uuid = const Uuid();

  _DevConnectHttpClient(this._inner);

  // Intercept all request methods
  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async {
    final request = await _inner.openUrl(method, url);
    return _DevConnectHttpClientRequest(request, method, url, _uuid);
  }

  @override
  Future<HttpClientRequest> getUrl(Uri url) => openUrl('GET', url);

  @override
  Future<HttpClientRequest> postUrl(Uri url) => openUrl('POST', url);

  @override
  Future<HttpClientRequest> putUrl(Uri url) => openUrl('PUT', url);

  @override
  Future<HttpClientRequest> patchUrl(Uri url) => openUrl('PATCH', url);

  @override
  Future<HttpClientRequest> deleteUrl(Uri url) => openUrl('DELETE', url);

  @override
  Future<HttpClientRequest> headUrl(Uri url) => openUrl('HEAD', url);

  @override
  Future<HttpClientRequest> open(
          String method, String host, int port, String path) =>
      _inner.open(method, host, port, path).then((request) =>
          _DevConnectHttpClientRequest(
              request, method, request.uri, _uuid));

  @override
  Future<HttpClientRequest> get(String host, int port, String path) =>
      open('GET', host, port, path);

  @override
  Future<HttpClientRequest> post(String host, int port, String path) =>
      open('POST', host, port, path);

  @override
  Future<HttpClientRequest> put(String host, int port, String path) =>
      open('PUT', host, port, path);

  @override
  Future<HttpClientRequest> patch(String host, int port, String path) =>
      open('PATCH', host, port, path);

  @override
  Future<HttpClientRequest> delete(String host, int port, String path) =>
      open('DELETE', host, port, path);

  @override
  Future<HttpClientRequest> head(String host, int port, String path) =>
      open('HEAD', host, port, path);

  // Delegate all other properties/methods to inner client
  @override
  set autoUncompress(bool value) => _inner.autoUncompress = value;
  @override
  bool get autoUncompress => _inner.autoUncompress;
  @override
  set connectionTimeout(Duration? value) => _inner.connectionTimeout = value;
  @override
  Duration? get connectionTimeout => _inner.connectionTimeout;
  @override
  set idleTimeout(Duration value) => _inner.idleTimeout = value;
  @override
  Duration get idleTimeout => _inner.idleTimeout;
  @override
  set maxConnectionsPerHost(int? value) =>
      _inner.maxConnectionsPerHost = value;
  @override
  int? get maxConnectionsPerHost => _inner.maxConnectionsPerHost;
  @override
  set userAgent(String? value) => _inner.userAgent = value;
  @override
  String? get userAgent => _inner.userAgent;
  @override
  void addCredentials(
          Uri url, String realm, HttpClientCredentials credentials) =>
      _inner.addCredentials(url, realm, credentials);
  @override
  void addProxyCredentials(String host, int port, String realm,
          HttpClientCredentials credentials) =>
      _inner.addProxyCredentials(host, port, realm, credentials);
  @override
  set authenticate(
          Future<bool> Function(Uri url, String scheme, String? realm)? f) =>
      _inner.authenticate = f;
  @override
  set authenticateProxy(
          Future<bool> Function(
                  String host, int port, String scheme, String? realm)?
              f) =>
      _inner.authenticateProxy = f;
  @override
  set badCertificateCallback(
          bool Function(X509Certificate cert, String host, int port)?
              callback) =>
      _inner.badCertificateCallback = callback;
  @override
  void close({bool force = false}) => _inner.close(force: force);
  @override
  set connectionFactory(
          Future<ConnectionTask<Socket>> Function(
                  Uri url, String? proxyHost, int? proxyPort)?
              f) =>
      _inner.connectionFactory = f;
  @override
  set findProxy(String Function(Uri url)? f) => _inner.findProxy = f;
  @override
  set keyLog(Function(String line)? callback) => _inner.keyLog = callback;
}

class _DevConnectHttpClientRequest implements HttpClientRequest {
  final HttpClientRequest _inner;
  final String _method;
  final Uri _url;
  final String _requestId;
  final int _startTime;
  final List<int> _bodyBytes = [];
  Future<HttpClientResponse>? _closeFuture;

  _DevConnectHttpClientRequest(this._inner, this._method, this._url, Uuid uuid)
      : _requestId = uuid.v4(),
        _startTime = DateTime.now().millisecondsSinceEpoch {
    // Report request start — dart:io headers are always String→List<String>,
    // so we don't need to defend against nested objects here. The desktop
    // inspector still gets the full multi-value list (joined with ", ").
    final headers = <String, dynamic>{};
    _inner.headers.forEach((name, values) {
      headers[name] = values.join(', ');
    });

    DevConnectClient.safeReportNetworkStart(
      requestId: _requestId,
      method: _method,
      url: _url.toString(),
      headers: headers,
    );
  }

  @override
  Future<HttpClientResponse> close() {
    return _closeFuture ??= _doClose();
  }

  Future<HttpClientResponse> _doClose() async {
    try {
      final response = await _inner.close();

      // Capture response — dart:io headers are always String→List<String>,
      // so we don't need to defend against nested objects here.
      final responseHeaders = <String, dynamic>{};
      response.headers.forEach((name, values) {
        responseHeaders[name] = values.join(', ');
      });

      final requestHeaders = <String, dynamic>{};
      _inner.headers.forEach((name, values) {
        requestHeaders[name] = values.join(', ');
      });

      // Try to parse request body
      dynamic requestBody;
      if (_bodyBytes.isNotEmpty) {
        try {
          final bodyStr = utf8.decode(_bodyBytes);
          try {
            requestBody = jsonDecode(bodyStr);
          } catch (_) {
            requestBody = bodyStr;
          }
        } catch (_) {}
      }

      // Wrap response to capture body
      return _DevConnectHttpClientResponse(
        response,
        _requestId,
        _method,
        _url.toString(),
        _startTime,
        requestHeaders,
        responseHeaders,
        requestBody,
      );
    } catch (e) {
      DevConnectClient.safeReportNetworkComplete(
        requestId: _requestId,
        method: _method,
        url: _url.toString(),
        statusCode: 0,
        startTime: _startTime,
        error: e.toString(),
      );
      rethrow;
    }
  }

  @override
  void add(List<int> data) {
    _bodyBytes.addAll(data);
    _inner.add(data);
  }

  @override
  void write(Object? object) {
    final str = object?.toString() ?? '';
    _bodyBytes.addAll(utf8.encode(str));
    _inner.write(object);
  }

  // Delegate everything else
  @override
  bool get bufferOutput => _inner.bufferOutput;
  @override
  set bufferOutput(bool value) => _inner.bufferOutput = value;
  @override
  int get contentLength => _inner.contentLength;
  @override
  set contentLength(int value) => _inner.contentLength = value;
  @override
  Encoding get encoding => _inner.encoding;
  @override
  set encoding(Encoding value) => _inner.encoding = value;
  @override
  bool get followRedirects => _inner.followRedirects;
  @override
  set followRedirects(bool value) => _inner.followRedirects = value;
  @override
  int get maxRedirects => _inner.maxRedirects;
  @override
  set maxRedirects(int value) => _inner.maxRedirects = value;
  @override
  bool get persistentConnection => _inner.persistentConnection;
  @override
  set persistentConnection(bool value) =>
      _inner.persistentConnection = value;
  @override
  HttpHeaders get headers => _inner.headers;
  @override
  Uri get uri => _inner.uri;
  @override
  String get method => _inner.method;
  @override
  HttpConnectionInfo? get connectionInfo => _inner.connectionInfo;
  @override
  List<Cookie> get cookies => _inner.cookies;
  @override
  Future<HttpClientResponse> get done => close();
  @override
  void addError(Object error, [StackTrace? stackTrace]) =>
      _inner.addError(error, stackTrace);
  @override
  Future addStream(Stream<List<int>> stream) {
    return _inner.addStream(stream.map((data) {
      _bodyBytes.addAll(data);
      return data;
    }));
  }
  @override
  void writeAll(Iterable objects, [String separator = ""]) {
    for (final obj in objects) {
      _bodyBytes.addAll(utf8.encode(obj.toString()));
      if (separator.isNotEmpty) _bodyBytes.addAll(utf8.encode(separator));
    }
    _inner.writeAll(objects, separator);
  }
  @override
  void writeCharCode(int charCode) {
    _bodyBytes.add(charCode);
    _inner.writeCharCode(charCode);
  }
  @override
  void writeln([Object? object = ""]) {
    final str = '${object ?? ''}\n';
    _bodyBytes.addAll(utf8.encode(str));
    _inner.writeln(object);
  }
  @override
  Future flush() => _inner.flush();
  @override
  void abort([Object? exception, StackTrace? stackTrace]) =>
      _inner.abort(exception, stackTrace);
}

class _DevConnectHttpClientResponse extends Stream<List<int>>
    implements HttpClientResponse {
  final HttpClientResponse _inner;
  final String _requestId;
  final String _method;
  final String _url;
  final int _startTime;
  final Map<String, dynamic> _requestHeaders;
  final Map<String, dynamic> _responseHeaders;
  final dynamic _requestBody;
  bool _reported = false;
  final List<int> _bodyBytes = [];

  _DevConnectHttpClientResponse(
    this._inner,
    this._requestId,
    this._method,
    this._url,
    this._startTime,
    this._requestHeaders,
    this._responseHeaders,
    this._requestBody,
  );

  void _reportComplete() {
    if (_reported) return;
    _reported = true;

    try {
      dynamic responseBody;
      if (_bodyBytes.isNotEmpty) {
        try {
          final bodyStr = utf8.decode(_bodyBytes);
          try {
            responseBody = jsonDecode(bodyStr);
          } catch (e) {
            responseBody = bodyStr;
          }
        } catch (e) {
          responseBody = '${_bodyBytes.length} bytes';
        }
      }

      DevConnectClient.safeReportNetworkComplete(
        requestId: _requestId,
        method: _method,
        url: _url,
        statusCode: _inner.statusCode,
        startTime: _startTime,
        requestHeaders: _requestHeaders,
        responseHeaders: _responseHeaders,
        requestBody: _requestBody,
        responseBody: responseBody,
      );
    } catch (e) {
      // Fallback: at least send metadata without body
      try {
        DevConnectClient.safeReportNetworkComplete(
          requestId: _requestId,
          method: _method,
          url: _url,
          statusCode: _inner.statusCode,
          startTime: _startTime,
          requestHeaders: _requestHeaders,
          responseHeaders: _responseHeaders,
        );
      } catch (_) {}
    }
  }

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    // Safely proxy the stream using map.
    // This ensures our body capture cannot be bypassed by onData reassignment
    // while perfectly preserving stream semantics (pause, resume, etc).
    final interceptedStream = _inner.map((data) {
      _bodyBytes.addAll(data);
      return data;
    });

    return interceptedStream.listen(
      onData,
      onError: (Object error, StackTrace stackTrace) {
        _reportComplete();
        if (onError != null) {
          if (onError is void Function(Object, StackTrace)) {
            onError(error, stackTrace);
          } else if (onError is void Function(Object)) {
            onError(error);
          }
        }
      },
      onDone: () {
        _reportComplete();
        onDone?.call();
      },
      cancelOnError: cancelOnError,
    );
  }

  // Delegate all properties
  @override
  int get statusCode => _inner.statusCode;
  @override
  String get reasonPhrase => _inner.reasonPhrase;
  @override
  int get contentLength => _inner.contentLength;
  @override
  HttpHeaders get headers => _inner.headers;
  @override
  bool get isRedirect => _inner.isRedirect;
  @override
  bool get persistentConnection => _inner.persistentConnection;
  @override
  List<Cookie> get cookies => _inner.cookies;
  @override
  X509Certificate? get certificate => _inner.certificate;
  @override
  HttpConnectionInfo? get connectionInfo => _inner.connectionInfo;
  @override
  HttpClientResponseCompressionState get compressionState =>
      _inner.compressionState;
  @override
  List<RedirectInfo> get redirects => _inner.redirects;
  @override
  Future<HttpClientResponse> redirect(
          [String? method, Uri? url, bool? followLoops]) =>
      _inner.redirect(method, url, followLoops);
  @override
  Future<Socket> detachSocket() => _inner.detachSocket();
}
