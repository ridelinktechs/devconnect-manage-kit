import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../server/providers/server_providers.dart';

/// One element on the app's screen: widget, React component or Android view.
class LayoutNode {
  final String id;
  final String name;

  /// On-screen bounds, in the app's logical pixels (dp).
  final Rect rect;

  /// Space inside / around [rect], when the SDK reports it.
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Map<String, String> props;
  final List<LayoutNode> children;

  const LayoutNode(
    this.id,
    this.name,
    this.rect,
    this.props,
    this.children, {
    this.padding,
    this.margin,
  });

  /// Parses a `client:layout:snapshot` node; null if it isn't one.
  static LayoutNode? fromJson(Object? json) {
    if (json is! Map) return null;
    double n(Object? v) => v is num ? v.toDouble() : 0;
    // [left, top, right, bottom]
    EdgeInsets? insets(Object? v) => v is List && v.length == 4
        ? EdgeInsets.fromLTRB(n(v[0]), n(v[1]), n(v[2]), n(v[3]))
        : null;
    return LayoutNode(
      '${json['id']}',
      '${json['name'] ?? '?'}',
      Rect.fromLTWH(n(json['x']), n(json['y']), n(json['w']), n(json['h'])),
      {
        for (final MapEntry(:key, :value)
            in (json['props'] as Map? ?? const {}).entries)
          if (value != null) '$key': '$value',
      },
      [
        for (final child in json['children'] as List? ?? const [])
          ?LayoutNode.fromJson(child),
      ],
      padding: insets(json['padding']),
      margin: insets(json['margin']),
    );
  }
}

/// The app's screen as captured: its size, a screenshot when the SDK could
/// take one, and the element tree.
class LayoutSnapshot {
  final Size size;
  final Uint8List? screenshot;
  final LayoutNode? root;

  /// Why the SDK couldn't read the element tree, if it couldn't.
  final String? error;
  final DateTime? capturedAt;

  const LayoutSnapshot(
    this.size,
    this.screenshot,
    this.root, {
    this.error,
    this.capturedAt,
  });
}

/// A PNG's pixel size, read from its header; null if [bytes] isn't a PNG.
Size? pngSize(Uint8List bytes) {
  const signature = [0x89, 0x50, 0x4E, 0x47];
  if (bytes.length < 24) return null;
  for (var i = 0; i < signature.length; i++) {
    if (bytes[i] != signature[i]) return null;
  }
  final header = ByteData.sublistView(bytes);
  return Size(header.getUint32(16).toDouble(), header.getUint32(20).toDouble());
}

/// The tree as listed: one row per chain (see [layoutChainOf]) with its
/// depth; a row's children are listed only when it's [expanded].
List<(List<LayoutNode>, int)> layoutTreeRows(
  LayoutNode root,
  Set<String> expanded,
) {
  final rows = <(List<LayoutNode>, int)>[];
  // Iterative, children pushed last-first: trees run hundreds deep.
  final stack = <(LayoutNode, int)>[(root, 0)];
  while (stack.isNotEmpty) {
    final (node, depth) = stack.removeLast();
    final chain = layoutChainOf(node);
    rows.add((chain, depth));
    if (!expanded.contains(node.id)) continue;
    final children = chain.last.children;
    for (var i = children.length - 1; i >= 0; i--) {
      stack.add((children[i], depth + 1));
    }
  }
  return rows;
}

/// How many elements [root]'s tree holds.
int layoutNodeCount(LayoutNode root) {
  var count = 0;
  final stack = [root];
  while (stack.isNotEmpty) {
    count++;
    stack.addAll(stack.removeLast().children);
  }
  return count;
}

/// [node] and the nodes under it drawing exactly its box, each the only
/// child of the one before (`View` → `RCTView`): one row in the tree.
List<LayoutNode> layoutChainOf(LayoutNode node) {
  final chain = [node];
  while (chain.last.children.length == 1 &&
      chain.last.children.single.rect == node.rect) {
    chain.add(chain.last.children.single);
  }
  return chain;
}

/// The path from [root] to the element under [point]: at each level the
/// smallest child holding it (the last one when tied — it paints on top).
List<LayoutNode> layoutPathAt(LayoutNode root, Offset point) {
  if (!root.rect.contains(point)) return const [];
  final path = [root];
  for (var node = root; ;) {
    LayoutNode? best;
    for (final child in node.children) {
      if (!child.rect.contains(point)) continue;
      final area = child.rect.width * child.rect.height;
      if (best == null || area <= best.rect.width * best.rect.height) {
        best = child;
      }
    }
    if (best == null) return path;
    path.add(best);
    node = best;
  }
}

/// The element under [point]: the innermost box there, named by the
/// outermost element drawing exactly that box (`Text` rather than its
/// `RichText`, a component rather than the view it renders).
LayoutNode? layoutElementAt(LayoutNode root, Offset point) {
  final path = layoutPathAt(root, point);
  if (path.isEmpty) return null;
  return path.firstWhere((n) => n.rect == path.last.rect);
}

/// The path from [root] to the element [id], or empty.
List<LayoutNode> layoutPathTo(LayoutNode root, String id) {
  if (root.id == id) return [root];
  for (final child in root.children) {
    final path = layoutPathTo(child, id);
    if (path.isNotEmpty) return [root, ...path];
  }
  return const [];
}

/// Each device's last layout snapshot, and which captures are still running.
final layoutSnapshotsProvider =
    NotifierProvider<LayoutSnapshotsNotifier, Map<String, LayoutSnapshot?>>(
      LayoutSnapshotsNotifier.new,
    );

class LayoutSnapshotsNotifier extends Notifier<Map<String, LayoutSnapshot?>> {
  /// An app without layout support never answers.
  static const timeout = Duration(seconds: 15);

  /// Devices with a capture in flight.
  final pending = <String>{};

  @override
  Map<String, LayoutSnapshot?> build() {
    final handler = ref.watch(wsMessageHandlerProvider);
    final sub = handler.onLayoutSnapshot.listen((m) {
      final deviceId = m['deviceId'] as String;
      final screenshot = m['screenshot'];
      Uint8List? png;
      if (screenshot is String && screenshot.isNotEmpty) {
        try {
          png = base64Decode(screenshot);
        } on FormatException {
          png = null;
        }
      }
      double n(Object? v) => v is num ? v.toDouble() : 0;
      final size = Size(n(m['width']), n(m['height']));
      // The screenshot sets the canvas shape: the reported window size can
      // differ from what was captured (system bars, split screen), and a
      // stretched picture puts every box off.
      final picture = png == null ? null : pngSize(png);
      pending.remove(deviceId);
      state = {
        ...state,
        deviceId: LayoutSnapshot(
          picture == null || picture.width == 0
              ? size
              : Size(size.width, size.width * picture.height / picture.width),
          png,
          LayoutNode.fromJson(m['root']),
          error: m['error'] is String ? m['error'] as String : null,
          capturedAt: DateTime.now(),
        ),
      };
    });
    ref.onDispose(sub.cancel);
    return const {};
  }

  void capture(String deviceId) {
    pending.add(deviceId);
    ref.read(wsMessageHandlerProvider).captureLayout(deviceId);
    state = {...state}; // show the spinner
    Timer(timeout, () {
      if (ref.mounted && pending.remove(deviceId)) state = {...state};
    });
  }
}
