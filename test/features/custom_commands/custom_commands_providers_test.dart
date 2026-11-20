import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:devconnect_manage_tool/core/constants/ws_constants.dart';
import 'package:devconnect_manage_tool/features/custom_commands/provider/custom_commands_providers.dart';
import 'package:devconnect_manage_tool/server/providers/server_providers.dart';
import 'package:devconnect_manage_tool/server/ws_message_handler.dart';

import '../../helpers/fake_ws_server.dart';

void main() {
  late FakeWsServer server;
  late WsMessageHandler handler;
  late ProviderContainer container;

  setUp(() {
    server = FakeWsServer();
    handler = WsMessageHandler(server: server);
    container = ProviderContainer(
      overrides: [wsMessageHandlerProvider.overrideWithValue(handler)],
    );
  });
  tearDown(() {
    handler.dispose();
    container.dispose();
  });

  test('keeps each device\'s announced commands', () async {
    container.read(customCommandsProvider);
    server.emit(
      deviceMessage(WsMessageTypes.clientCustomCommands, {
        'commands': ['clearCache', 'setUser', 42],
      }),
    );
    await Future<void>.delayed(Duration.zero);
    expect(container.read(customCommandsProvider), {
      'dev': ['clearCache', 'setUser'],
    });
  });

  test('settles runs by correlationId, else by device + command', () async {
    final runs = container.read(commandRunsProvider.notifier);
    runs.run('dev', 'clearCache', null);
    runs.run('dev', 'setUser', {'id': 1});
    final ids = {
      for (final r in container.read(commandRunsProvider)) r.command: r.id,
    };
    expect(server.sent.map((m) => m.correlationId), [
      ids['clearCache'],
      ids['setUser'],
    ]);

    // RN / Flutter echo the id.
    server.emit(
      deviceMessage(WsMessageTypes.clientCustomCommandResult, {
        'command': 'clearCache',
        'result': {'ok': true},
      }, correlationId: ids['clearCache']),
    );
    // Android doesn't: matched on device + command, errors flagged.
    server.emit(
      deviceMessage(WsMessageTypes.clientCustomCommandResult, {
        'command': 'setUser',
        'status': 'error',
        'error': 'boom',
      }),
    );
    await Future<void>.delayed(Duration.zero);

    final byName = {
      for (final r in container.read(commandRunsProvider)) r.command: r,
    };
    expect(byName['clearCache']!.status, CommandRunStatus.ok);
    expect(byName['clearCache']!.result, {'ok': true});
    expect(byName['setUser']!.status, CommandRunStatus.error);
    expect(byName['setUser']!.error, 'boom');
  });

  // testWidgets for its fake clock.
  testWidgets('a run nobody answers times out', (tester) async {
    container.read(commandRunsProvider.notifier).run('dev', 'nope', null);
    await tester.pump(CommandRunsNotifier.timeout);
    expect(
      container.read(commandRunsProvider).single.status,
      CommandRunStatus.noResponse,
    );
  });
}
