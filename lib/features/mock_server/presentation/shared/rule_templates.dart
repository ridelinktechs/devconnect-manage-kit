import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../models/round/mock_entry.dart';

/// Ready-made rules the empty Mock Server page offers to start from.
enum RuleTemplate {
  success('Success', LucideIcons.circleCheck, Color(0xFF10B981)),
  serverError('Server error', LucideIcons.serverCrash, Color(0xFFE5484D)),
  slow('Slow', LucideIcons.hourglass, Color(0xFFFF8A3D));

  final String label;
  final IconData icon;
  final Color color;

  const RuleTemplate(this.label, this.icon, this.color);
}

var _sequence = 0;

/// A new enabled rule: a plain JSON answer, or [template]'s.
MockRule newMockRule([RuleTemplate? template]) {
  final now = DateTime.now().millisecondsSinceEpoch;
  final (name, url, status, body, delayMs) = switch (template) {
    null => ('New rule', '/api/example', 200, '{\n  "ok": true\n}', null),
    RuleTemplate.success => (
      'Users list',
      r'/api/users$',
      200,
      '{\n  "data": [\n    { "id": 1, "name": "Ada Lovelace" }\n  ]\n}',
      null,
    ),
    RuleTemplate.serverError => (
      'Server error',
      '/api/',
      500,
      '{\n  "error": "Internal Server Error"\n}',
      null,
    ),
    RuleTemplate.slow => (
      'Slow network',
      '/api/',
      200,
      '{\n  "ok": true\n}',
      3000,
    ),
  };
  return MockRule(
    id: 'r_${now}_${_sequence++}',
    name: name,
    method: 'GET',
    urlPattern: url,
    statusCode: status,
    headers: const {'Content-Type': 'application/json'},
    body: body,
    enabled: true,
    hitCount: 0,
    updatedAt: now,
    metadata: delayMs == null ? null : {'delayMs': delayMs},
  );
}
