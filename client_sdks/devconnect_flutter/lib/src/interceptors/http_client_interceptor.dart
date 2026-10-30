import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:uuid/uuid.dart';

import '../devconnect_client.dart';
import 'mock_server_interceptor.dart';

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
    await DevConnectClient.applyNetworkConditions(url);
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
      DevConnectClient.applyNetworkConditions(
              Uri(scheme: 'http', host: host, port: port, path: path))
          .then((_) => _inner.open(method, host, port, path))
          .then((request) => _DevConnectHttpClientRequest(
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
  late final _body = _BodyCapture(_inner.headers);
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
      final rule = _mockRule();
      final response = rule == null
          ? await _inner.close()
          : _MockHttpClientResponse(await buildMockResponse(rule,
              method: _method, url: _url.toString(), requestId: _requestId));

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
      final requestBody = _body.decode(_inner.headers);

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

  bool _mockChecked = false;
  MockRule? _mock;

  /// The desktop mock rule answering this request, if any. Decided once the
  /// headers are final — first body write, flush or close — and a match
  /// aborts the real request before anything is sent (openUrl has already
  /// connected, so the host must still be reachable).
  MockRule? _mockRule() {
    if (_mockChecked) return _mock;
    _mockChecked = true;
    final headers = <String, String>{};
    _inner.headers.forEach((name, values) => headers[name] = values.join(', '));
    // A WebSocket handshake needs a real socket.
    if (headers.containsKey('upgrade')) return null;
    _mock = findMockMatch(_method, _url.toString(), headers);
    if (_mock != null) _inner.abort();
    return _mock;
  }

  @override
  void add(List<int> data) {
    _body.add(data);
    if (_mockRule() == null) _inner.add(data);
  }

  @override
  void write(Object? object) {
    final str = object?.toString() ?? '';
    _body.add(utf8.encode(str));
    if (_mockRule() == null) _inner.write(object);
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
    if (_mockRule() != null) return stream.forEach(_body.add);
    return _inner.addStream(stream.map((data) {
      _body.add(data);
      return data;
    }));
  }
  @override
  void writeAll(Iterable objects, [String separator = ""]) {
    for (final obj in objects) {
      _body.add(utf8.encode(obj.toString()));
      if (separator.isNotEmpty) _body.add(utf8.encode(separator));
    }
    if (_mockRule() == null) _inner.writeAll(objects, separator);
  }
  @override
  void writeCharCode(int charCode) {
    _body.add(utf8.encode(String.fromCharCode(charCode)));
    if (_mockRule() == null) _inner.writeCharCode(charCode);
  }
  @override
  void writeln([Object? object = ""]) {
    final str = '${object ?? ''}\n';
    _body.add(utf8.encode(str));
    if (_mockRule() == null) _inner.writeln(object);
  }
  @override
  Future flush() => _mockRule() == null ? _inner.flush() : Future.value();
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
  late final _body = _BodyCapture(_inner.headers);

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
      final responseBody = _body.decode(_inner.headers);

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
      _body.add(data);
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

/// A body of no stated type, or of one that's neither text nor a known
/// binary, is kept for the report up to this many bytes, so a big download
/// doesn't pile up in memory.
const _maxBodyBytes = 1024 * 1024;

/// Images up to this many bytes are sent for the desktop to show; bigger
/// ones only by their size.
const _maxImageBytes = 10 * 1024 * 1024;

/// Text longer than this is sent undecoded: the desktop parses it itself,
/// off its UI thread.
const _maxDecodeChars = 1024 * 1024;

/// A request or response body on its way through, kept for the report:
/// text whole, an image up to [_maxImageBytes], an event stream or other
/// binary not at all, anything else up to [_maxBodyBytes]. The bytes
/// themselves pass through untouched.
class _BodyCapture {
  _BodyCapture(this._headers);

  final HttpHeaders _headers;
  final _bytes = BytesBuilder();
  var _length = 0;

  /// How many bytes of the body are kept (one past [_maxImageBytes] tells a
  /// bigger image).
  late final int _keep = switch (_headers.contentType) {
    final type? when type.mimeType == 'text/event-stream' => 0,
    final type? when _isText(type) => 1 << 62,
    final type? when type.primaryType == 'image' => _maxImageBytes + 1,
    final type? when _isBinary(type) => 0,
    _ => _maxBodyBytes,
  };

  void add(List<int> data) {
    final room = _keep - _bytes.length;
    if (room > 0) _bytes.add(data.length <= room ? data : data.sublist(0, room));
    _length += data.length;
  }

  /// The body as JSON or text, an image as a `data:` URL, or by its size
  /// when it's an event stream or other binary (`N bytes`, which the
  /// desktop shows as binary). Of anything else, its first [_maxBodyBytes].
  dynamic decode(HttpHeaders headers) {
    if (_length == 0) return null;
    try {
      final type = headers.contentType;
      if (type?.mimeType == 'text/event-stream') {
        return '<event stream, $_length bytes>';
      }
      if (type != null && _isText(type)) {
        final text = utf8.decode(_bytes.takeBytes(), allowMalformed: true);
        if (text.length > _maxDecodeChars) return text;
        try {
          return jsonDecode(text);
        } catch (_) {
          return text;
        }
      }
      if (type?.primaryType == 'image' && _length <= _maxImageBytes) {
        return 'data:${type!.mimeType};base64,'
            '${base64Encode(_bytes.takeBytes())}';
      }
      if (type?.primaryType == 'image' || (type != null && _isBinary(type))) {
        return '$_length bytes';
      }
      if (_length > _maxBodyBytes) {
        final head = utf8.decode(_bytes.toBytes(), allowMalformed: true);
        return '$head…[truncated, $_length bytes]';
      }
      final text = utf8.decode(_bytes.toBytes());
      try {
        return jsonDecode(text);
      } catch (_) {
        return text;
      }
    } catch (_) {
      return '$_length bytes'; // not UTF-8
    }
  }
}

/// Whether a body of [type] is text, which is reported whole.
bool _isText(ContentType type) =>
    type.primaryType == 'text' ||
    const ['json', 'xml', 'javascript', 'x-www-form-urlencoded', 'graphql']
        .any(type.subType.contains);

/// Whether a body of [type] is binary that's reported by its size alone.
bool _isBinary(ContentType type) =>
    type.mimeType == 'application/octet-stream' ||
    const {'audio', 'video', 'font'}.contains(type.primaryType);

/// A mock rule's canned response, served without the network.
class _MockHttpClientResponse extends Stream<List<int>>
    implements HttpClientResponse {
  _MockHttpClientResponse(MockedHttpResponse mock)
      : statusCode = mock.status,
        headers = _MockHttpHeaders(mock.headers),
        _body = utf8.encode(mock.body);

  final List<int> _body;
  @override
  final int statusCode;
  @override
  final HttpHeaders headers;

  @override
  StreamSubscription<List<int>> listen(void Function(List<int> event)? onData,
          {Function? onError, void Function()? onDone, bool? cancelOnError}) =>
      Stream.value(_body).listen(onData,
          onError: onError, onDone: onDone, cancelOnError: cancelOnError);

  @override
  int get contentLength => _body.length;
  @override
  String get reasonPhrase => '';
  @override
  bool get isRedirect => false;
  @override
  List<RedirectInfo> get redirects => const [];
  @override
  bool get persistentConnection => false;
  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;
  @override
  List<Cookie> get cookies => const [];
  @override
  X509Certificate? get certificate => null;
  @override
  HttpConnectionInfo? get connectionInfo => null;
  @override
  Future<HttpClientResponse> redirect(
          [String? method, Uri? url, bool? followLoops]) =>
      Future.error(UnsupportedError('A mocked response cannot redirect'));
  @override
  Future<Socket> detachSocket() =>
      Future.error(UnsupportedError('A mocked response has no socket'));
}

/// Headers of a mocked response, names lower-cased like dart:io's.
class _MockHttpHeaders implements HttpHeaders {
  _MockHttpHeaders(Map<String, String> headers) {
    headers.forEach(set);
    final type = value(HttpHeaders.contentTypeHeader);
    if (type != null) contentType = ContentType.parse(type);
  }

  final _values = <String, List<String>>{};

  @override
  DateTime? date, expires, ifModifiedSince;
  @override
  String? host;
  @override
  int? port;
  @override
  ContentType? contentType;
  @override
  int contentLength = -1;
  @override
  bool persistentConnection = false, chunkedTransferEncoding = false;

  @override
  List<String>? operator [](String name) => _values[name.toLowerCase()];
  @override
  String? value(String name) => this[name]?.join(', ');
  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) =>
      (_values[name.toLowerCase()] ??= []).add('$value');
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) =>
      _values[name.toLowerCase()] = ['$value'];
  @override
  void remove(String name, Object value) => this[name]?.remove('$value');
  @override
  void removeAll(String name) => _values.remove(name.toLowerCase());
  @override
  void forEach(void Function(String name, List<String> values) action) =>
      _values.forEach(action);
  @override
  void noFolding(String name) {}
  @override
  void clear() => _values.clear();
}
