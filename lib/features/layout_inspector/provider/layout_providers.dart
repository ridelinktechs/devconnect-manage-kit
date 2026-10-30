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

  /// A component's state (React), when the SDK reports it.
  final Map<String, String> state;
  final List<LayoutNode> children;

  /// A native view (`RCTView`…) rather than a component (React Native).
  final bool host;

  /// Whether the app's own code created it (Flutter, when it can tell).
  final bool? local;

  const LayoutNode(
    this.id,
    this.name,
    this.rect,
    this.props,
    this.children, {
    this.padding,
    this.margin,
    this.state = const {},
    this.host = false,
    this.local,
  });

  /// This node with other [children].
  LayoutNode withChildren(List<LayoutNode> children) => LayoutNode(
    id,
    name,
    rect,
    props,
    children,
    padding: padding,
    margin: margin,
    state: state,
    host: host,
    local: local,
  );

  /// The node and its subtree in the snapshot wire format.
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'x': rect.left,
    'y': rect.top,
    'w': rect.width,
    'h': rect.height,
    if (padding case final p?) 'padding': [p.left, p.top, p.right, p.bottom],
    if (margin case final m?) 'margin': [m.left, m.top, m.right, m.bottom],
    if (host) 'host': true,
    'local': ?local,
    'props': props,
    if (state.isNotEmpty) 'state': state,
    'children': [for (final c in children) c.toJson()],
  };

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
      state: {
        for (final MapEntry(:key, :value)
            in (json['state'] as Map? ?? const {}).entries)
          if (value != null) '$key': '$value',
      },
      host: json['host'] == true,
      local: json['local'] is bool ? json['local'] as bool : null,
    );
  }
}

/// Whether [node] belongs to the app rather than a library or the
/// platform: written in the app (Flutter), or anything but a native view
/// (React Native). Without either hint, everything does.
bool isAppElement(LayoutNode node) => node.local ?? !node.host;

/// [root] without the nodes [keep] turns down — their children take their
/// place. The root always stays.
LayoutNode layoutFiltered(LayoutNode root, bool Function(LayoutNode) keep) {
  List<LayoutNode> kept(LayoutNode node) {
    final children = [for (final c in node.children) ...kept(c)];
    return keep(node) ? [node.withChildren(children)] : children;
  }

  return root.withChildren([for (final c in root.children) ...kept(c)]);
}

/// Rows (by their head's id, see [layoutChainOf]) holding an element whose
/// name or any prop / state value contains [query], in tree order.
List<String> layoutSearch(LayoutNode root, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return const [];
  bool hit(LayoutNode n) =>
      n.name.toLowerCase().contains(q) ||
      n.props.values.any((v) => v.toLowerCase().contains(q)) ||
      n.state.values.any((v) => v.toLowerCase().contains(q));
  final heads = <String>{};
  // (node, the head of its row), children pushed last-first.
  final stack = <(LayoutNode, String)>[(root, root.id)];
  while (stack.isNotEmpty) {
    final (node, head) = stack.removeLast();
    if (hit(node)) heads.add(head);
    final sameBox =
        node.children.length == 1 && node.children.single.rect == node.rect;
    for (final child in node.children.reversed) {
      stack.add((child, sameBox ? head : child.id));
    }
  }
  return heads.toList();
}

/// Where [id] sits in [root] in terms that survive a new capture (ids
/// don't): each step's name and its place among same-named siblings.
List<(String, int)>? layoutSignature(LayoutNode root, String id) {
  final path = layoutPathTo(root, id);
  if (path.isEmpty) return null;
  return [
    for (var i = 1; i < path.length; i++)
      (
        path[i].name,
        path[i - 1].children
            .where((c) => c.name == path[i].name)
            .toList()
            .indexOf(path[i]),
      ),
  ];
}

/// The id at [signature] in [root] (see [layoutSignature]), or null.
String? layoutFindSignature(LayoutNode root, List<(String, int)> signature) {
  var node = root;
  for (final (name, ordinal) in signature) {
    final named = node.children.where((c) => c.name == name).toList();
    if (ordinal >= named.length) return null;
    node = named[ordinal];
  }
  return node.id;
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

  /// The SDK hit its element cap: part of the tree is missing.
  final bool truncated;

  const LayoutSnapshot(
    this.size,
    this.screenshot,
    this.root, {
    this.error,
    this.capturedAt,
    this.truncated = false,
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

/// Distance lines between boxes [a] and [b], as (from, to) pairs: from the
/// inner box to each side of the outer one when one holds the other, else
/// across the gaps between them. Overlapping boxes have none.
List<(Offset, Offset)> layoutMeasure(Rect a, Rect b) {
  final overlap = a.intersect(b);
  if (overlap == a || overlap == b) {
    final (inner, outer) = overlap == a ? (a, b) : (b, a);
    final c = inner.center;
    return [
      if (inner.top > outer.top)
        (Offset(c.dx, outer.top), Offset(c.dx, inner.top)),
      if (inner.bottom < outer.bottom)
        (Offset(c.dx, inner.bottom), Offset(c.dx, outer.bottom)),
      if (inner.left > outer.left)
        (Offset(outer.left, c.dy), Offset(inner.left, c.dy)),
      if (inner.right < outer.right)
        (Offset(inner.right, c.dy), Offset(outer.right, c.dy)),
    ];
  }
  // Lines run through the middle of what the boxes share on the other axis.
  final y = overlap.height > 0 ? overlap.center.dy : a.center.dy;
  final x = overlap.width > 0 ? overlap.center.dx : a.center.dx;
  return [
    if (b.left > a.right)
      (Offset(a.right, y), Offset(b.left, y))
    else if (a.left > b.right)
      (Offset(b.right, y), Offset(a.left, y)),
    if (b.top > a.bottom)
      (Offset(x, a.bottom), Offset(x, b.top))
    else if (a.top > b.bottom)
      (Offset(x, b.bottom), Offset(x, a.top)),
  ];
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

  /// Devices whose last capture got no answer within [timeout] — an SDK
  /// without layout support, or a release build.
  final unanswered = <String>{};

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
      unanswered.remove(deviceId);
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
          truncated: m['truncated'] == true,
        ),
      };
    });
    ref.onDispose(sub.cancel);
    return const {};
  }

  /// Drops [deviceId]'s capture: the page goes back to its hint.
  void clear(String deviceId) {
    unanswered.remove(deviceId);
    state = {...state}..remove(deviceId);
  }

  void capture(String deviceId) {
    pending.add(deviceId);
    unanswered.remove(deviceId);
    ref.read(wsMessageHandlerProvider).captureLayout(deviceId);
    state = {...state}; // show the spinner
    Timer(timeout, () {
      if (ref.mounted && pending.remove(deviceId)) {
        unanswered.add(deviceId);
        state = {...state};
      }
    });
  }
}
