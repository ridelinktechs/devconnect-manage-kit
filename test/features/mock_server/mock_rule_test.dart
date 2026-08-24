import 'package:flutter_test/flutter_test.dart';
import 'package:devconnect_manage_tool/models/round/mock_entry.dart';

void main() {
  group('MockRule toWireJson', () {
    test('toWireJson does not place response headers into match.headers', () {
      const rule = MockRule(
        id: 'r_1',
        name: 'Get Users',
        method: 'GET',
        urlPattern: '/api/users',
        statusCode: 200,
        headers: {'Content-Type': 'application/json', 'X-Custom': '123'},
        body: '{"ok": true}',
        enabled: true,
        hitCount: 0,
        updatedAt: 1000,
      );

      final wire = rule.toWireJson();

      expect(wire['id'], 'r_1');
      expect(wire['name'], 'Get Users');
      expect(wire['enabled'], true);

      // Match should only have method and url unless matchHeaders is in metadata
      expect(wire['match']['method'], 'GET');
      expect(wire['match']['url'], '/api/users');
      expect(wire['match'].containsKey('headers'), isFalse);

      // Response should have status, body, and headers
      expect(wire['response']['status'], 200);
      expect(wire['response']['body'], '{"ok": true}');
      expect(wire['response']['headers'], {
        'Content-Type': 'application/json',
        'X-Custom': '123',
      });
    });

    test('toWireJson forwards delayMs, scope, expiresAt, and matchHeaders from metadata', () {
      const rule = MockRule(
        id: 'r_2',
        name: 'Post Item',
        method: 'POST',
        urlPattern: '/api/items',
        statusCode: 201,
        headers: {'Content-Type': 'application/json'},
        body: '{"created": true}',
        enabled: true,
        hitCount: 1,
        updatedAt: 2000,
        metadata: {
          'delayMs': 250,
          'scope': {'deviceIds': ['dev_1', 'dev_2']},
          'expiresAt': '2026-12-31T23:59:59Z',
          'matchHeaders': {'Authorization': '^Bearer '},
        },
      );

      final wire = rule.toWireJson();

      expect(wire['match']['headers'], {'Authorization': '^Bearer '});
      expect(wire['response']['delayMs'], 250);
      expect(wire['scope'], {'deviceIds': ['dev_1', 'dev_2']});
      expect(wire['expiresAt'], '2026-12-31T23:59:59Z');
    });
  });

  group('MockedRequestEntry fromAuditPayload', () {
    test('parses payload with method and url from Android SDK', () {
      final payload = {
        'ruleId': 'r_1',
        'status': 200,
        'url': 'https://example.com/api/users',
        'method': 'POST',
      };

      final entry = MockedRequestEntry.fromAuditPayload(
        payload,
        id: 'msg_1',
        deviceId: 'android_dev',
        timestamp: 5000,
      );

      expect(entry.id, 'msg_1');
      expect(entry.deviceId, 'android_dev');
      expect(entry.method, 'POST');
      expect(entry.url, 'https://example.com/api/users');
      expect(entry.matchedRuleId, 'r_1');
      expect(entry.statusCode, 200);
      expect(entry.timestamp, 5000);
    });

    test('parses minimal wire payload from Flutter/RN SDK', () {
      final payload = {
        'ruleId': 'r_2',
        'status': 404,
        'requestId': 'req_99',
      };

      final entry = MockedRequestEntry.fromAuditPayload(
        payload,
        id: 'msg_2',
        deviceId: 'rn_dev',
        timestamp: 6000,
      );

      expect(entry.id, 'msg_2');
      expect(entry.matchedRuleId, 'r_2');
      expect(entry.statusCode, 404);
      expect(entry.method, 'GET');
      expect(entry.url, '');
    });
  });
}
