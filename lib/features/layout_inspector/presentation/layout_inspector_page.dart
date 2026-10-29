import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../components/feedback/empty_state.dart';
import '../../../core/theme/chrome_palette.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../../server/providers/server_providers.dart';
import '../provider/layout_providers.dart';

const _hoverColor = Color(0xFF3B82F6);
const _selectColor = Color(0xFFF59E0B);
// Box model, as browser devtools tint it.
const _paddingColor = Color(0x8C93C47D);
const _marginColor = Color(0x8CF6B26B);

/// Layout inspector: a capture of the app's screen with its element tree
/// (widgets, React components or Android views). Hover the screenshot to
/// see an element's bounds, click it — or pick it in the tree — to see its
/// properties.
class LayoutInspectorPage extends ConsumerStatefulWidget {
  const LayoutInspectorPage({super.key});

  @override
  ConsumerState<LayoutInspectorPage> createState() =>
      _LayoutInspectorPageState();
}

class _LayoutInspectorPageState extends ConsumerState<LayoutInspectorPage> {
  String? _hoveredId;
  String? _selectedId;
  final _expanded = <String>{};
  LayoutSnapshot? _seen;

  void _select(LayoutNode root, String id) => setState(() {
    _selectedId = id;
    _expanded.addAll(layoutPathTo(root, id).map((n) => n.id));
  });

  @override
  Widget build(BuildContext context) {
    final loc = S.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final devices = ref.watch(connectedDevicesProvider);
    final selectedDeviceId = ref.watch(selectedDeviceProvider);
    final target =
        devices.where((d) => d.deviceId == selectedDeviceId).firstOrNull ??
        (devices.length == 1 ? devices.single : null);
    final snapshots = ref.watch(layoutSnapshotsProvider);
    final notifier = ref.read(layoutSnapshotsProvider.notifier);
    final snapshot = target == null ? null : snapshots[target.deviceId];
    final capturing =
        target != null && notifier.pending.contains(target.deviceId);
    final root = snapshot?.root;
    if (!identical(snapshot, _seen)) {
      // A new capture: start from the top of its tree.
      _seen = snapshot;
      _hoveredId = null;
      _selectedId = null;
      _expanded
        ..clear()
        ..addAll([?root?.id]);
    }
    final divider = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.08);
    final selected = root == null || _selectedId == null
        ? null
        : layoutPathTo(root, _selectedId!).lastOrNull;

    return Column(
      children: [
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: isDark ? ColorTokens.darkBackground : Colors.white,
            border: Border(bottom: BorderSide(color: divider)),
          ),
          child: Row(
            children: [
              Icon(
                LucideIcons.scanSearch,
                size: 15,
                color: ColorTokens.primary,
              ),
              const SizedBox(width: 8),
              Text(
                loc.layoutTitle,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  target == null
                      ? ''
                      : '${target.appName} · ${target.deviceName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11.5, color: Colors.grey[500]),
                ),
              ),
              if (target != null)
                FilledButton.icon(
                  onPressed: capturing
                      ? null
                      : () => notifier.capture(target.deviceId),
                  icon: capturing
                      ? const SizedBox.square(
                          dimension: 12,
                          child: CircularProgressIndicator(strokeWidth: 1.5),
                        )
                      : const Icon(LucideIcons.camera, size: 14),
                  label: Text(loc.layoutCapture),
                  style: FilledButton.styleFrom(
                    backgroundColor: ColorTokens.primary,
                    foregroundColor: Colors.white,
                    visualDensity: VisualDensity.compact,
                    textStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: target == null
              ? EmptyState(
                  icon: LucideIcons.scanSearch,
                  title: loc.layoutTitle,
                  subtitle: loc.layoutNoDevice,
                )
              : snapshot == null || root == null
              ? EmptyState(
                  icon: LucideIcons.scanSearch,
                  title: loc.layoutTitle,
                  subtitle: loc.layoutHint,
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _ScreenView(
                        snapshot: snapshot,
                        root: root,
                        hoveredId: _hoveredId,
                        selected: selected,
                        isDark: isDark,
                        onHover: (id) {
                          if (id != _hoveredId) setState(() => _hoveredId = id);
                        },
                        onSelect: (id) => _select(root, id),
                      ),
                    ),
                    VerticalDivider(width: 1, color: divider),
                    SizedBox(
                      width: 380,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            flex: 3,
                            child: _Tree(
                              root: root,
                              expanded: _expanded,
                              hoveredId: _hoveredId,
                              selectedId: _selectedId,
                              isDark: isDark,
                              onToggle: (id) => setState(
                                () => _expanded.contains(id)
                                    ? _expanded.remove(id)
                                    : _expanded.add(id),
                              ),
                              onHover: (id) => setState(() => _hoveredId = id),
                              onSelect: (id) => _select(root, id),
                            ),
                          ),
                          Divider(height: 1, color: divider),
                          Expanded(
                            flex: 2,
                            child: _Properties(node: selected, isDark: isDark),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

/// The screenshot (or, without one, the elements' outlines), scaled to fit,
/// with the hovered and selected elements outlined on top.
class _ScreenView extends StatelessWidget {
  final LayoutSnapshot snapshot;
  final LayoutNode root;
  final String? hoveredId;
  final LayoutNode? selected;
  final bool isDark;
  final ValueChanged<String?> onHover;
  final ValueChanged<String> onSelect;

  const _ScreenView({
    required this.snapshot,
    required this.root,
    required this.hoveredId,
    required this.selected,
    required this.isDark,
    required this.onHover,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final size = snapshot.size;
    if (size.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = math.min(
          math.min(
            (constraints.maxWidth - 40) / size.width,
            (constraints.maxHeight - 40) / size.height,
          ),
          2.0,
        );
        if (scale <= 0) return const SizedBox.shrink();
        final hovered = hoveredId == null
            ? null
            : layoutPathTo(root, hoveredId!).lastOrNull;
        String? idAt(Offset local) => layoutElementAt(root, local / scale)?.id;
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (snapshot.screenshot == null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    S.of(context).layoutNoScreenshot,
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                ),
              Container(
                width: size.width * scale,
                height: size.height * scale,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.12)
                        : Colors.black.withValues(alpha: 0.12),
                  ),
                ),
                child: MouseRegion(
                  cursor: SystemMouseCursors.precise,
                  onHover: (e) => onHover(idAt(e.localPosition)),
                  onExit: (_) => onHover(null),
                  child: GestureDetector(
                    onTapUp: (e) {
                      if (idAt(e.localPosition) case final id?) onSelect(id);
                    },
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (snapshot.screenshot case final png?)
                          Image.memory(
                            png,
                            fit: BoxFit.fill,
                            gaplessPlayback: true,
                          ),
                        CustomPaint(
                          painter: _BoundsPainter(
                            root: root,
                            hovered: hovered,
                            selected: selected,
                            scale: scale,
                            outlineAll: snapshot.screenshot == null,
                            fontFamily: DefaultTextStyle.of(
                              context,
                            ).style.fontFamily,
                            outlineColor: isDark
                                ? Colors.white.withValues(alpha: 0.18)
                                : Colors.black.withValues(alpha: 0.18),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BoundsPainter extends CustomPainter {
  final LayoutNode root;
  final LayoutNode? hovered;
  final LayoutNode? selected;
  final double scale;
  final bool outlineAll;
  final Color outlineColor;
  final String? fontFamily;

  _BoundsPainter({
    required this.root,
    required this.hovered,
    required this.selected,
    required this.scale,
    required this.outlineAll,
    required this.outlineColor,
    required this.fontFamily,
  });

  Rect _scaled(Rect r) => Rect.fromLTWH(
    r.left * scale,
    r.top * scale,
    r.width * scale,
    r.height * scale,
  );

  @override
  void paint(Canvas canvas, Size size) {
    if (outlineAll) {
      final outline = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = outlineColor;
      void walk(LayoutNode n) {
        canvas.drawRect(_scaled(n.rect), outline);
        n.children.forEach(walk);
      }

      walk(root);
    }
    if (hovered case final h?) {
      final r = _scaled(h.rect);
      void ring(Rect outer, Rect inner, Color color) => canvas.drawPath(
        Path()
          ..fillType = PathFillType.evenOdd
          ..addRect(outer)
          ..addRect(inner),
        Paint()..color = color,
      );
      if (h.margin case final m?) {
        ring(_scaled(m.inflateRect(h.rect)), r, _marginColor);
      }
      final content = switch (h.padding) {
        final p? => _scaled(p.deflateRect(h.rect)),
        null => r,
      };
      if (content != r) ring(r, content, _paddingColor);
      canvas.drawRect(
        content,
        Paint()..color = _hoverColor.withValues(alpha: 0.18),
      );
      canvas.drawRect(
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = _hoverColor,
      );
    }
    if (selected case final s?) {
      final r = _scaled(s.rect);
      canvas.drawRect(
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = _selectColor,
      );
      // Name and size, above the box (or inside when it hugs the top).
      final label = TextPainter(
        text: TextSpan(
          text:
              ' ${s.name}  ${s.rect.width.toStringAsFixed(0)}×${s.rect.height.toStringAsFixed(0)} ',
          style: TextStyle(
            fontFamily: fontFamily,
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F2328),
            backgroundColor: _selectColor,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: size.width);
      final top = r.top - label.height >= 0 ? r.top - label.height : r.top;
      label.paint(
        canvas,
        Offset(r.left.clamp(0, math.max(0, size.width - label.width)), top),
      );
    }
  }

  @override
  bool shouldRepaint(_BoundsPainter old) =>
      old.hovered != hovered ||
      old.selected != selected ||
      old.scale != scale ||
      old.root != root;
}

class _Tree extends StatelessWidget {
  final LayoutNode root;
  final Set<String> expanded;
  final String? hoveredId;
  final String? selectedId;
  final bool isDark;
  final ValueChanged<String> onToggle;
  final ValueChanged<String?> onHover;
  final ValueChanged<String> onSelect;

  const _Tree({
    required this.root,
    required this.expanded,
    required this.hoveredId,
    required this.selectedId,
    required this.isDark,
    required this.onToggle,
    required this.onHover,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final rows = <(LayoutNode, int)>[];
    void walk(LayoutNode n, int depth) {
      rows.add((n, depth));
      if (expanded.contains(n.id)) {
        for (final c in n.children) {
          walk(c, depth + 1);
        }
      }
    }

    walk(root, 0);
    final mono = chromeMono(
      context,
      size: 11.5,
      color: isDark ? Colors.white : Colors.black87,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
          child: Text(
            S.of(context).layoutTree.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: Colors.grey[500],
            ),
          ),
        ),
        Expanded(
          child: MouseRegion(
            onExit: (_) => onHover(null),
            child: ListView.builder(
              itemCount: rows.length,
              itemExtent: 24,
              itemBuilder: (context, i) {
                final (node, depth) = rows[i];
                final isSelected = node.id == selectedId;
                final isHovered = node.id == hoveredId;
                return MouseRegion(
                  onEnter: (_) => onHover(node.id),
                  child: InkWell(
                    onTap: () => onSelect(node.id),
                    child: Container(
                      color: isSelected
                          ? _selectColor.withValues(alpha: 0.18)
                          : isHovered
                          ? _hoverColor.withValues(alpha: 0.12)
                          : null,
                      padding: EdgeInsets.only(left: 6 + depth * 12.0),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 18,
                            child: node.children.isEmpty
                                ? null
                                : GestureDetector(
                                    onTap: () => onToggle(node.id),
                                    child: Icon(
                                      expanded.contains(node.id)
                                          ? Icons.keyboard_arrow_down
                                          : Icons.keyboard_arrow_right,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                                  ),
                          ),
                          Flexible(
                            child: Text(
                              node.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: mono.copyWith(
                                fontWeight: isSelected ? FontWeight.w700 : null,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${node.rect.width.toStringAsFixed(0)}×${node.rect.height.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[500],
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _Properties extends StatelessWidget {
  final LayoutNode? node;
  final bool isDark;

  const _Properties({required this.node, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final loc = S.of(context);
    final node = this.node;
    final muted = TextStyle(
      fontSize: 11.5,
      height: 1.45,
      color: Colors.grey[500],
    );
    if (node == null) {
      return Padding(
        padding: const EdgeInsets.all(14),
        child: Text(loc.layoutPickElement, style: muted),
      );
    }
    final mono = chromeMono(
      context,
      size: 11.5,
      color: isDark ? Colors.white70 : Colors.black87,
    );
    final r = node.rect;
    String n(double v) => v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 1);
    String edges(EdgeInsets e) =>
        [e.left, e.top, e.right, e.bottom].map(n).join(', ');
    final rows = {
      'bounds': '${n(r.left)}, ${n(r.top)} · ${n(r.width)} × ${n(r.height)}',
      if (node.padding case final p?) 'padding': edges(p),
      if (node.margin case final m?) 'margin': edges(m),
      ...node.props,
    };
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Text(
          loc.layoutProperties.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
            color: Colors.grey[500],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          node.name,
          style: chromeMono(
            context,
            size: 13,
            color: _selectColor,
            weight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        for (final MapEntry(:key, :value) in rows.entries)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: SelectableText.rich(
              TextSpan(
                style: mono,
                children: [
                  TextSpan(
                    text: '$key: ',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
