import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:devconnect_manage_kit/devconnect_manage_kit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late WebSocket app;
  final fromApp = <Map<String, dynamic>>[];

  setUpAll(() async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    final connected = Completer<WebSocket>();
    server.listen((request) async {
      final socket = await WebSocketTransformer.upgrade(request);
      socket.add(jsonEncode({'type': 'server:hello', 'payload': {}}));
      if (!connected.isCompleted) connected.complete(socket);
    });
    await DevConnect.init(
      appName: 'test',
      host: '127.0.0.1',
      port: server.port,
      auto_: false,
      autoPerformance: false,
      autoMemoryLeak: false,
      autoBenchmark: false,
    );
    app = await connected.future.timeout(const Duration(seconds: 5));
    app.listen(
      (data) => fromApp.add(jsonDecode(data as String) as Map<String, dynamic>),
    );
  });

  tearDown(() {
    DevConnect.onStateRestore = null;
    DevConnect.onReduxDispatch = null;
  });

  /// Sends [type] to the app the way the desktop does.
  void fromDesktop(String type, Object? payload) =>
      app.add(jsonEncode({'type': type, 'payload': payload}));

  /// Waits for the app to handle what was sent.
  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 150));

  test(
      'a restored state reaches DevConnect.onStateRestore, nested values '
      'and nulls included', () async {
    final got = Completer<Map<String, dynamic>>();
    DevConnect.onStateRestore = got.complete;
    final state = {
      'user': {'name': 'Ada', 'nick': null},
      'items': [
        1,
        {'id': 2},
      ],
    };
    fromDesktop('server:state:restore', {'state': state});
    expect(await got.future.timeout(const Duration(seconds: 3)), state);
  });

  test('an action dispatched from the desktop reaches onReduxDispatch',
      () async {
    final got = Completer<Map<String, dynamic>>();
    DevConnect.onReduxDispatch = got.complete;
    fromDesktop('server:redux:dispatch', {
      'action': {'type': 'LOGOUT', 'reason': 'test'},
    });
    expect(await got.future.timeout(const Duration(seconds: 3)), {
      'type': 'LOGOUT',
      'reason': 'test',
    });
  });

  test(
      'a command without its payload, or with the wrong kind, reaches no '
      'handler and the next one still does', () async {
    final actions = <Map<String, dynamic>>[];
    final states = <Map<String, dynamic>>[];
    DevConnect.onReduxDispatch = actions.add;
    DevConnect.onStateRestore = states.add;
    fromDesktop('server:redux:dispatch', {});
    fromDesktop('server:redux:dispatch', {'action': null});
    fromDesktop('server:redux:dispatch', {
      'action': [1, 2],
    });
    fromDesktop('server:state:restore', {'state': 'not a map'});
    fromDesktop('server:state:restore', null);
    fromDesktop('server:redux:dispatch', {
      'action': {'type': 'OK'},
    });
    await settle();
    expect(actions, [
      {'type': 'OK'},
    ]);
    expect(states, isEmpty);
  });

  test(
      'a handler that throws shows in the desktop\'s Console and does not '
      'stop the next command', () async {
    final actions = <String>[];
    DevConnect.onReduxDispatch = (a) {
      actions.add(a['type'] as String);
      if (a['type'] == 'BOOM') throw StateError('reducer failed');
    };
    fromDesktop('server:redux:dispatch', {
      'action': {'type': 'BOOM'},
    });
    fromDesktop('server:redux:dispatch', {
      'action': {'type': 'AFTER'},
    });
    await settle();
    expect(actions, ['BOOM', 'AFTER']);
    final error = fromApp.lastWhere((m) => m['type'] == 'client:log');
    expect(error['payload']['level'], 'error');
    expect(
      error['payload']['message'],
      'onReduxDispatch threw: Bad state: reducer failed',
    );
  });

  test('sendStateSnapshot sends the state to the desktop', () async {
    DevConnect.sendStateSnapshot(
      stateManager: 'riverpod',
      state: {'counter': 42},
    );
    await settle();
    final snapshot = fromApp.lastWhere(
      (m) => m['type'] == 'client:state:snapshot',
    );
    expect(snapshot['payload'], {
      'stateManager': 'riverpod',
      'state': {'counter': 42},
    });
  });
}
