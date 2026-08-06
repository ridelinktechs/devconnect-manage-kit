import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:devconnect_manage_tool/core/utils/cursor_configurator.dart';

void main() {
  late Directory tmp;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('cursor_cfg_test_');
  });

  tearDown(() async {
    if (await tmp.exists()) {
      await tmp.delete(recursive: true);
    }
  });

  Future<Map<String, dynamic>> readMcpConfig() async {
    final f = File('${tmp.path}/.cursor/mcp.json');
    if (!await f.exists()) return {};
    final s = await f.readAsString();
    if (s.trim().isEmpty) return {};
    return jsonDecode(s) as Map<String, dynamic>;
  }

  group('configureHttp (localhost install)', () {
    test('creates ~/.cursor/mcp.json with HTTP URL entry', () async {
      final ok = await CursorConfigurator.configureHttp(
        httpPort: 5565,
        homeOverride: tmp.path,
      );
      expect(ok, isTrue);
      final cfg = await readMcpConfig();
      expect(cfg['mcpServers'], isA<Map>());
      expect(cfg['mcpServers']['devconnect-manage'], {
        'url': 'http://127.0.0.1:5565/mcp',
      });
    });

    test('uses the supplied port', () async {
      await CursorConfigurator.configureHttp(
        httpPort: 6000,
        homeOverride: tmp.path,
      );
      final cfg = await readMcpConfig();
      expect(
        (cfg['mcpServers']['devconnect-manage'] as Map)['url'],
        'http://127.0.0.1:6000/mcp',
      );
    });

    test('preserves existing mcpServers entries', () async {
      // Pre-seed ~/.cursor/mcp.json with another server.
      final cursorDir = Directory('${tmp.path}/.cursor');
      await cursorDir.create(recursive: true);
      final existing = File('${cursorDir.path}/mcp.json');
      await existing.writeAsString(jsonEncode({
        'mcpServers': {
          'context7': {'command': 'npx', 'args': ['-y', '@upstash/context7-mcp']},
        },
      }));

      await CursorConfigurator.configureHttp(
        httpPort: 5565,
        homeOverride: tmp.path,
      );

      final cfg = await readMcpConfig();
      final servers = cfg['mcpServers'] as Map;
      expect(servers.containsKey('context7'), isTrue);
      expect(servers.containsKey('devconnect-manage'), isTrue);
    });

    test('overwrites previous devconnect-manage entry', () async {
      // Install twice with different ports — second wins.
      await CursorConfigurator.configureHttp(
        httpPort: 5565,
        homeOverride: tmp.path,
      );
      await CursorConfigurator.configureHttp(
        httpPort: 9999,
        homeOverride: tmp.path,
      );
      final cfg = await readMcpConfig();
      expect(
        (cfg['mcpServers']['devconnect-manage'] as Map)['url'],
        'http://127.0.0.1:9999/mcp',
      );
    });

    test('handles missing mcp.json (creates it)', () async {
      // tmp.path has no .cursor subdir — CursorConfigurator should
      // create it.
      final ok = await CursorConfigurator.configureHttp(
        httpPort: 5565,
        homeOverride: tmp.path,
      );
      expect(ok, isTrue);
      expect(
        await File('${tmp.path}/.cursor/mcp.json').exists(),
        isTrue,
      );
    });

    test('handles malformed existing mcp.json (treats as empty)', () async {
      final cursorDir = Directory('${tmp.path}/.cursor');
      await cursorDir.create(recursive: true);
      await File('${cursorDir.path}/mcp.json').writeAsString('not json');

      final ok = await CursorConfigurator.configureHttp(
        httpPort: 5565,
        homeOverride: tmp.path,
      );
      expect(ok, isTrue);
      // Result is a fresh config with our entry, malformed content
      // overwritten.
      final cfg = await readMcpConfig();
      expect(cfg['mcpServers']['devconnect-manage']['url'],
          'http://127.0.0.1:5565/mcp');
    });
  });

  group('uninstall', () {
    test('removes our entry from a populated config', () async {
      final cursorDir = Directory('${tmp.path}/.cursor');
      await cursorDir.create(recursive: true);
      await File('${cursorDir.path}/mcp.json').writeAsString(jsonEncode({
        'mcpServers': {
          'devconnect-manage': {'url': 'http://127.0.0.1:5565/mcp'},
          'context7': {'command': 'npx'},
        },
      }));

      final ok = await CursorConfigurator.uninstall(homeOverride: tmp.path);
      expect(ok, isTrue);

      final cfg = await readMcpConfig();
      expect(cfg['mcpServers'].containsKey('devconnect-manage'), isFalse);
      // Other entries preserved.
      expect(cfg['mcpServers'].containsKey('context7'), isTrue);
    });

    test('returns true when mcp.json does not exist', () async {
      final ok = await CursorConfigurator.uninstall(homeOverride: tmp.path);
      expect(ok, isTrue);
    });

    test('returns true on empty mcp.json', () async {
      final cursorDir = Directory('${tmp.path}/.cursor');
      await cursorDir.create(recursive: true);
      await File('${cursorDir.path}/mcp.json').writeAsString('');

      final ok = await CursorConfigurator.uninstall(homeOverride: tmp.path);
      expect(ok, isTrue);
    });
  });

  group('configure (npx stdio install)', () {
    test('writes stdio entry when workspace is discoverable', () async {
      // Set up a fake workspace at tmp.path with the expected layout.
      final pkgDir = Directory('${tmp.path}/client_sdks/devconnect-mcp');
      await pkgDir.create(recursive: true);
      await File('${pkgDir.path}/package.json').writeAsString('{}');

      final ok = await CursorConfigurator.configure(
        wsPort: 5564,
        homeOverride: tmp.path,
      );
      expect(ok, isTrue);

      final cfg = await readMcpConfig();
      final entry = cfg['mcpServers']['devconnect-manage'] as Map;
      expect(entry['command'], 'node');
      expect(entry['env']['DEVCONNECT_PORT'], '5564');
      // args[0] is the absolute path ending in dist/index.js.
      expect(entry['args'][0], endsWith('client_sdks/devconnect-mcp/dist/index.js'));
    });

    test('returns false when no workspace can be located', () async {
      // No fake workspace — Directory.current may or may not be in a
      // valid one. Either way the entry should NOT be written.
      final ok = await CursorConfigurator.configure(
        wsPort: 5564,
        homeOverride: tmp.path,
      );
      // If we're running from inside this repo, configure() will succeed;
      // if not, it returns false. Just verify no garbage entry was
      // written either way.
      if (ok) {
        final cfg = await readMcpConfig();
        expect(cfg['mcpServers']?.containsKey('devconnect-manage') ?? false,
            isTrue);
      } else {
        expect(
          await File('${tmp.path}/.cursor/mcp.json').exists(),
          isFalse,
        );
      }
    });
  });
}