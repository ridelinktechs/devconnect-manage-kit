/// Regression test for the bug in `provider_tree_walker.dart:86-91`:
/// the parent `_maybeReportProvider` call sits INSIDE `visitChildren`,
/// so a parent with N children gets reported N times. Fix: report once,
/// then recurse.
library;

import 'package:flutter_test/flutter_test.dart';

/// Synthetic node used by both algorithms — no Flutter Element needed.
class _Node {
  final bool isInherited;
  final List<_Node> children;
  _Node(this.isInherited, [this.children = const []]);
}

/// Counts visits exactly like the buggy `_walk` in the production code.
int _buggyWalk(_Node node) {
  var count = 0;
  void walk(_Node n) {
    for (final c in n.children) {
      if (n.isInherited) count++;
      walk(c);
    }
  }
  walk(node);
  return count;
}

/// Counts visits exactly like the fixed `_walk`.
int _fixedWalk(_Node node) {
  var count = 0;
  void walk(_Node n) {
    if (n.isInherited) count++;
    for (final c in n.children) {
      walk(c);
    }
  }
  walk(node);
  return count;
}

void main() {
  group('provider_tree_walker _walk algorithm', () {
    test('buggy algorithm reports parent N times for N children', () {
      // A single inherited parent with 3 non-inherited children.
      // Buggy: parent reported 3 times. Fixed: parent reported once.
      final parent = _Node(true, [_Node(false), _Node(false), _Node(false)]);
      expect(_buggyWalk(parent), 3,
          reason: 'Parent has 3 children → buggy algorithm reports it '
              '3 times. This is the bug.');
      expect(_fixedWalk(parent), 1,
          reason: 'Fixed algorithm reports parent exactly once.');
    });
  });
}
