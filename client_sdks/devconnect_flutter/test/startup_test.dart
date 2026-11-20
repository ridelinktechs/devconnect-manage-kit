import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:devconnect_manage_kit/devconnect_manage_kit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the app starts before the desktop answers', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    final received = <Map<String, dynamic>>[];
    final handshake = Completer<void>();
    var attempts = 0;
    server.listen((request) async {
      // The first connection never gets an answer, like an unroutable host.
      if (++attempts == 1) return;
      final socket = await WebSocketTransformer.upgrade(request);
      socket.add(jsonEncode({'type': 'server:hello', 'payload': {}}));
      socket.listen((data) {
        final message = jsonDecode(data as String) as Map<String, dynamic>;
        received.add(message);
        if (message['type'] == 'client:handshake') handshake.complete();
      });
    });
    // As after auto-detection, which ends once DevConnect's interceptor is
    // installed: DevConnect's own connection mustn't count as app traffic.
    final previous = HttpOverrides.current;
    HttpOverrides.global = DevConnectHttpOverrides();
    addTearDown(() => HttpOverrides.global = previous);

    final ran = Completer<void>();
    unawaited(DevConnect.initAndRunApp(
      appName: 'test',
      host: '127.0.0.1',
      port: server.port,
      auto_: false,
      autoInterceptHttp: false,
      autoInterceptLogs: false,
      autoPerformance: false,
      autoMemoryLeak: false,
      autoBenchmark: false,
      autoError: false,
      runApp: () async => ran.complete(),
    ));
    // Init is in flight: there is no client yet.
    DevConnect.log('too early');
    DevConnect.registerCommand('ping', (_) => 'pong');

    await ran.future.timeout(const Duration(seconds: 2));
    DevConnect.log('started');

    // The stalled connection times out and the retry gets through.
    await handshake.future.timeout(const Duration(seconds: 15));
    expect(attempts, 2);
    expect(received.map((m) => m['payload']['message']), contains('started'));
    expect(received.map((m) => m['type']),
        isNot(contains('client:network:request_start')));
  });
}
