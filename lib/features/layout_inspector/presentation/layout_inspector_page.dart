import 'dart:math' as math;
import 'dart:ui' show PointMode;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../components/feedback/empty_state.dart';
import '../../../core/theme/chrome_palette.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../../server/providers/server_providers.dart';
import '../provider/layout_providers.dart';

// Box model tints, as browser devtools draw them.
const _contentTint = Color(0xFF6FA8DC);
const _paddingTint = Color(0xFF93C47D);
const _marginTint = Color(0xFFF6B26B);

/// The selection accent: the hue of the app's selected rows, solid.
Color _accent(bool isDark) =>
    isDark ? const Color(0xFF14B8A6) : const Color(0xFF0EA5E9);

const _rowHeight = 26.0;

String _num(double v) => v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 1);

String _sizeOf(Rect r) => '${_num(r.width)} × ${_num(r.height)}';

/// Layout inspector: a capture of the app's screen with its element tree
/// (widgets, React components or Android views). Hover the screenshot to
/// see an element's box model, click it — or pick it in the tree, in the
/// path bar or with the arrow keys — to see its properties.
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
  final _treeScroll = ScrollController();
  final _treeFocus = FocusNode(debugLabel: 'layout tree');
  LayoutSnapshot? _seen;
  int _count = 0;

  @override
  void dispose() {
    _treeScroll.dispose();
    _treeFocus.dispose();
    super.dispose();
  }

  void _hover(String? id) {
    if (id != _hoveredId) setState(() => _hoveredId = id);
  }

  /// Selects [id], opens the rows above it and scrolls it into view.
  void _select(LayoutNode root, String id) {
    setState(() {
      _selectedId = id;
      _expanded.addAll(layoutPathTo(root, id).map((n) => n.id));
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _reveal(root, id));
  }

  void _reveal(LayoutNode root, String id) {
    if (!mounted || !_treeScroll.hasClients) return;
    final index = layoutTreeRows(
      root,
      _expanded,
    ).indexWhere((row) => row.$1.any((n) => n.id == id));
    if (index < 0) return;
    final position = _treeScroll.position;
    final top = index * _rowHeight;
    final double? target = top < position.pixels
        ? top
        : top + _rowHeight > position.pixels + position.viewportDimension
        ? top + _rowHeight - position.viewportDimension
        : null;
    if (target == null) return;
    _treeScroll.animateTo(
      target.clamp(0, position.maxScrollExtent),
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
    );
  }

  /// ↑ / ↓ move through the rows; → opens a row (then steps in), ← closes
  /// it (then steps out).
  KeyEventResult _onTreeKey(LayoutNode root, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final rows = layoutTreeRows(root, _expanded);
    final i = rows.indexWhere((row) => row.$1.any((n) => n.id == _selectedId));
    final row = i < 0 ? null : rows[i];
    String? next;
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowDown:
        next = rows[i < 0 ? 0 : math.min(i + 1, rows.length - 1)].$1.first.id;
      case LogicalKeyboardKey.arrowUp:
        next = rows[math.max(i - 1, 0)].$1.first.id;
      case LogicalKeyboardKey.arrowRight when row != null:
        final head = row.$1.first;
        if (row.$1.last.children.isEmpty) return KeyEventResult.handled;
        if (!_expanded.contains(head.id)) {
          setState(() => _expanded.add(head.id));
          return KeyEventResult.handled;
        }
        next = rows[i + 1].$1.first.id;
      case LogicalKeyboardKey.arrowLeft when row != null:
        final head = row.$1.first;
        if (_expanded.contains(head.id) && row.$1.last.children.isNotEmpty) {
          setState(() => _expanded.remove(head.id));
          return KeyEventResult.handled;
        }
        for (var j = i - 1; j >= 0; j--) {
          if (rows[j].$2 < row.$2) {
            next = rows[j].$1.first.id;
            break;
          }
        }
      default:
        return KeyEventResult.ignored;
    }
    if (next != null) _select(root, next);
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final loc = S.of(context);
    final palette = ChromePalette.of(context);
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
      _count = root == null ? 0 : layoutNodeCount(root);
      _expanded
        ..clear()
        ..addAll([?root?.id]);
    }
    final path = root == null || _selectedId == null
        ? const <LayoutNode>[]
        : layoutPathTo(root, _selectedId!);

    return Column(
      children: [
        _Toolbar(
          title: loc.layoutTitle,
          device: target == null
              ? null
              : (target.platform, '${target.appName} · ${target.deviceName}'),
          count: root == null ? null : _count,
          capturedAt: snapshot?.capturedAt,
          captureLabel: target == null ? null : loc.layoutCapture,
          capturing: capturing,
          onCapture: target == null
              ? null
              : () => notifier.capture(target.deviceId),
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
                      child: Column(
                        children: [
                          Expanded(
                            child: _Canvas(
                              snapshot: snapshot,
                              root: root,
                              hoveredId: _hoveredId,
                              selected: path.lastOrNull,
                              onHover: _hover,
                              onSelect: (id) => _select(root, id),
                            ),
                          ),
                          _PathBar(
                            path: path,
                            onHover: _hover,
                            onSelect: (id) => _select(root, id),
                          ),
                        ],
                      ),
                    ),
                    VerticalDivider(width: 1, color: palette.border),
                    SizedBox(
                      width: 400,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            flex: 5,
                            child: Focus(
                              focusNode: _treeFocus,
                              onKeyEvent: (_, event) => _onTreeKey(root, event),
                              child: _Tree(
                                rows: layoutTreeRows(root, _expanded),
                                count: _count,
                                error: snapshot.error,
                                expanded: _expanded,
                                hoveredId: _hoveredId,
                                selectedId: _selectedId,
                                scroll: _treeScroll,
                                onToggle: (id) => setState(
                                  () => _expanded.contains(id)
                                      ? _expanded.remove(id)
                                      : _expanded.add(id),
                                ),
                                onHover: _hover,
                                onSelect: (id) {
                                  _treeFocus.requestFocus();
                                  _select(root, id);
                                },
                              ),
                            ),
                          ),
                          Divider(height: 1, color: palette.border),
                          Expanded(
                            flex: 4,
                            child: _Properties(node: path.lastOrNull),
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

class _Toolbar extends StatelessWidget {
  final String title;

  /// (platform, "app · device")
  final (String, String)? device;
  final int? count;
  final DateTime? capturedAt;
  final String? captureLabel;
  final bool capturing;
  final VoidCallback? onCapture;

  const _Toolbar({
    required this.title,
    required this.device,
    required this.count,
    required this.capturedAt,
    required this.captureLabel,
    required this.capturing,
    required this.onCapture,
  });

  @override
  Widget build(BuildContext context) {
    final palette = ChromePalette.of(context);
    final muted = TextStyle(fontSize: 12, color: palette.textMuted);
    Widget meta(IconData icon, String text) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: palette.textMuted),
        const SizedBox(width: 5),
        Text(
          text,
          style: chromeMono(context, size: 12, color: palette.textMuted),
        ),
      ],
    );
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: palette.isDark ? ColorTokens.darkBackground : Colors.white,
        border: Border(bottom: BorderSide(color: palette.border)),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.scanSearch, size: 16, color: ColorTokens.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: palette.text,
            ),
          ),
          if (device case (final platform, final label)) ...[
            const SizedBox(width: 12),
            Icon(
              platformLook(platform, isDark: palette.isDark).$1,
              size: 13,
              color: platformLook(platform, isDark: palette.isDark).$2,
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: muted,
              ),
            ),
          ] else
            const Spacer(),
          if (count case final count?) ...[
            meta(LucideIcons.listTree, '$count'),
            const SizedBox(width: 14),
          ],
          if (capturedAt case final at?) ...[
            meta(LucideIcons.clock, DateFormat('HH:mm:ss').format(at)),
            const SizedBox(width: 14),
          ],
          if (captureLabel case final label?)
            FilledButton.icon(
              onPressed: capturing ? null : onCapture,
              icon: capturing
                  ? const SizedBox.square(
                      dimension: 12,
                      child: CircularProgressIndicator(strokeWidth: 1.5),
                    )
                  : const Icon(LucideIcons.camera, size: 14),
              label: Text(label),
              style: FilledButton.styleFrom(
                backgroundColor: ColorTokens.primary,
                foregroundColor: Colors.white,
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The screen on an artboard: the screenshot (or, without one, every
/// element's outline) in a device frame, with the hovered element's box
/// model and the selection drawn on top — clipped to the screen.
class _Canvas extends StatelessWidget {
  final LayoutSnapshot snapshot;
  final LayoutNode root;
  final String? hoveredId;
  final LayoutNode? selected;
  final ValueChanged<String?> onHover;
  final ValueChanged<String> onSelect;

  const _Canvas({
    required this.snapshot,
    required this.root,
    required this.hoveredId,
    required this.selected,
    required this.onHover,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final palette = ChromePalette.of(context);
    final size = snapshot.size;
    return ColoredBox(
      color: palette.codeBg,
      child: CustomPaint(
        painter: _DotGridPainter(
          palette.isDark
              ? Colors.white.withValues(alpha: 0.07)
              : Colors.black.withValues(alpha: 0.08),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (size.isEmpty) return const SizedBox.shrink();
            final scale = math.min(
              math.min(
                (constraints.maxWidth - 48) / size.width,
                (constraints.maxHeight - 48) / size.height,
              ),
              2.0,
            );
            if (scale <= 0) return const SizedBox.shrink();
            final hovered = hoveredId == null
                ? null
                : layoutPathTo(root, hoveredId!).lastOrNull;
            String? idAt(Offset local) =>
                layoutElementAt(root, local / scale)?.id;
            return Stack(
              children: [
                Center(
                  child: Container(
                    width: size.width * scale,
                    height: size.height * scale,
                    decoration: BoxDecoration(
                      color: palette.isDark
                          ? const Color(0xFF05070A)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: palette.border),
                      boxShadow: [
                        BoxShadow(
                          color: palette.shadow,
                          blurRadius: 28,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(13),
                      child: MouseRegion(
                        cursor: SystemMouseCursors.precise,
                        onHover: (e) => onHover(idAt(e.localPosition)),
                        onExit: (_) => onHover(null),
                        child: GestureDetector(
                          onTapUp: (e) {
                            if (idAt(e.localPosition) case final id?) {
                              onSelect(id);
                            }
                          },
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              if (snapshot.screenshot case final png?)
                                Image.memory(
                                  png,
                                  fit: BoxFit.fill,
                                  gaplessPlayback: true,
                                  filterQuality: FilterQuality.medium,
                                ),
                              CustomPaint(
                                painter: _OverlayPainter(
                                  root: root,
                                  hovered: hovered,
                                  selected: selected,
                                  scale: scale,
                                  outlineAll: snapshot.screenshot == null,
                                  isDark: palette.isDark,
                                  fontFamily: DefaultTextStyle.of(
                                    context,
                                  ).style.fontFamily,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (snapshot.screenshot == null)
                  Positioned(
                    left: 12,
                    top: 12,
                    right: 12,
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: _Notice(text: S.of(context).layoutNoScreenshot),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DotGridPainter extends CustomPainter {
  final Color color;

  _DotGridPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    const step = 16.0;
    canvas.drawPoints(
      PointMode.points,
      [
        for (var x = step / 2; x < size.width; x += step)
          for (var y = step / 2; y < size.height; y += step) Offset(x, y),
      ],
      Paint()
        ..color = color
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_DotGridPainter old) => old.color != color;
}

class _OverlayPainter extends CustomPainter {
  final LayoutNode root;
  final LayoutNode? hovered;
  final LayoutNode? selected;
  final double scale;
  final bool outlineAll;
  final bool isDark;
  final String? fontFamily;

  _OverlayPainter({
    required this.root,
    required this.hovered,
    required this.selected,
    required this.scale,
    required this.outlineAll,
    required this.isDark,
    required this.fontFamily,
  });

  Rect _scaled(Rect r) => Rect.fromLTRB(
    r.left * scale,
    r.top * scale,
    r.right * scale,
    r.bottom * scale,
  );

  void _ring(Canvas canvas, Rect outer, Rect inner, Color color) =>
      canvas.drawPath(
        Path()
          ..fillType = PathFillType.evenOdd
          ..addRect(outer)
          ..addRect(inner),
        Paint()..color = color,
      );

  @override
  void paint(Canvas canvas, Size size) {
    if (outlineAll) {
      final outline = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = (isDark ? Colors.white : Colors.black).withValues(
          alpha: 0.18,
        );
      final stack = [root];
      while (stack.isNotEmpty) {
        final node = stack.removeLast();
        canvas.drawRect(_scaled(node.rect), outline);
        stack.addAll(node.children);
      }
    }
    if (hovered case final h?) {
      final box = _scaled(h.rect);
      if (h.margin case final m?) {
        _ring(
          canvas,
          _scaled(m.inflateRect(h.rect)),
          box,
          _marginTint.withValues(alpha: 0.45),
        );
      }
      final content = switch (h.padding) {
        final p? => _scaled(p.deflateRect(h.rect)),
        null => box,
      };
      if (content != box) {
        _ring(canvas, box, content, _paddingTint.withValues(alpha: 0.45));
      }
      canvas.drawRect(
        content,
        Paint()..color = _contentTint.withValues(alpha: 0.4),
      );
      canvas.drawRect(
        box,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = _contentTint,
      );
    }
    if (selected case final s?) {
      canvas.drawRect(
        _scaled(s.rect),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = _accent(isDark),
      );
    }
    if (hovered ?? selected case final labelled?) {
      _label(canvas, size, labelled, _scaled(labelled.rect));
    }
  }

  /// Name and size in a dark tag above the box — below it, or inside it,
  /// when there's no room — kept inside the screen.
  void _label(Canvas canvas, Size size, LayoutNode node, Rect box) {
    final text = TextPainter(
      text: TextSpan(
        style: TextStyle(fontFamily: fontFamily, fontSize: 11),
        children: [
          TextSpan(
            text: node.name,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          TextSpan(
            text: '  ${_sizeOf(node.rect)}',
            style: const TextStyle(color: Color(0xFFB0B8C4)),
          ),
        ],
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: math.max(0, size.width - 16));
    final tag = Size(text.width + 12, text.height + 6);
    final above = box.top - tag.height - 4;
    final below = box.bottom + 4;
    final top = above >= 0
        ? above
        : below + tag.height <= size.height
        ? below
        : box.top + 4;
    final left = box.left.clamp(0, math.max(0, size.width - tag.width));
    final rect = Rect.fromLTWH(left.toDouble(), top, tag.width, tag.height);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(4)),
      Paint()..color = const Color(0xEB111827),
    );
    text.paint(canvas, rect.topLeft + const Offset(6, 3));
  }

  @override
  bool shouldRepaint(_OverlayPainter old) =>
      old.hovered != hovered ||
      old.selected != selected ||
      old.scale != scale ||
      old.root != root ||
      old.isDark != isDark;
}

/// The selected element's ancestry, one crumb per box (a chain shows its
/// outermost element), plus the box model legend.
class _PathBar extends StatelessWidget {
  final List<LayoutNode> path;
  final ValueChanged<String?> onHover;
  final ValueChanged<String> onSelect;

  const _PathBar({
    required this.path,
    required this.onHover,
    required this.onSelect,
  });

  static const _maxCrumbs = 6;

  @override
  Widget build(BuildContext context) {
    final palette = ChromePalette.of(context);
    final crumbs = [
      for (final (i, node) in path.indexed)
        if (i == 0 ||
            path[i - 1].children.length != 1 ||
            path[i - 1].rect != node.rect)
          node,
    ];
    final shown = crumbs.length > _maxCrumbs
        ? crumbs.sublist(crumbs.length - _maxCrumbs)
        : crumbs;
    final mono = chromeMono(context, size: 12, color: palette.textMuted);
    Widget swatch(Color tint, String label) => Padding(
      padding: const EdgeInsets.only(left: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.55),
              border: Border.all(color: tint),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(fontSize: 11, color: palette.textMuted)),
        ],
      ),
    );
    return Container(
      height: 36,
      padding: const EdgeInsets.only(left: 10, right: 14),
      decoration: BoxDecoration(
        color: palette.isDark ? ColorTokens.darkBackground : Colors.white,
        border: Border(top: BorderSide(color: palette.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: shown.isEmpty
                ? Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      S.of(context).layoutPickElement,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: palette.textMuted),
                    ),
                  )
                : LayoutBuilder(
                    // Scrolled to its end when too long; left-aligned when not.
                    builder: (context, constraints) => SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      reverse: true,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: constraints.maxWidth,
                        ),
                        child: Row(
                          children: [
                            if (shown.length < crumbs.length)
                              Text('…', style: mono),
                            for (final (i, node) in shown.indexed) ...[
                              if (i > 0 || shown.length < crumbs.length)
                                Icon(
                                  LucideIcons.chevronRight,
                                  size: 12,
                                  color: palette.textMuted,
                                ),
                              _Crumb(
                                label: node.name,
                                current: i == shown.length - 1,
                                onHover: (on) => onHover(on ? node.id : null),
                                onTap: () => onSelect(node.id),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
          swatch(_marginTint, 'margin'),
          swatch(_paddingTint, 'padding'),
          swatch(_contentTint, 'content'),
        ],
      ),
    );
  }
}

class _Crumb extends StatefulWidget {
  final String label;
  final bool current;
  final ValueChanged<bool> onHover;
  final VoidCallback onTap;

  const _Crumb({
    required this.label,
    required this.current,
    required this.onHover,
    required this.onTap,
  });

  @override
  State<_Crumb> createState() => _CrumbState();
}

class _CrumbState extends State<_Crumb> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final palette = ChromePalette.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        setState(() => _hovered = true);
        widget.onHover(true);
      },
      onExit: (_) {
        setState(() => _hovered = false);
        widget.onHover(false);
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: _hovered ? palette.hover : null,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            widget.label,
            style: chromeMono(
              context,
              size: 12,
              color: widget.current ? _accent(palette.isDark) : palette.text,
              weight: widget.current ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final Widget? trailing;

  const _SectionLabel(this.text, {this.trailing});

  @override
  Widget build(BuildContext context) {
    final palette = ChromePalette.of(context);
    return Row(
      children: [
        Text(
          text.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: palette.textMuted,
          ),
        ),
        const Spacer(),
        ?trailing,
      ],
    );
  }
}

class _Notice extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color? color;

  const _Notice({required this.text, this.icon = LucideIcons.info, this.color});

  @override
  Widget build(BuildContext context) {
    final palette = ChromePalette.of(context);
    final tint = color ?? palette.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color == null
            ? palette.surface
            : tint.withValues(alpha: palette.isDark ? 0.12 : 0.08),
        border: Border.all(
          color: color == null ? palette.border : tint.withValues(alpha: 0.4),
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(icon, size: 14, color: tint),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: SelectableText(
              text,
              style: TextStyle(fontSize: 12, height: 1.4, color: palette.text),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tree extends StatelessWidget {
  final List<(List<LayoutNode>, int)> rows;
  final int count;
  final String? error;
  final Set<String> expanded;
  final String? hoveredId;
  final String? selectedId;
  final ScrollController scroll;
  final ValueChanged<String> onToggle;
  final ValueChanged<String?> onHover;
  final ValueChanged<String> onSelect;

  const _Tree({
    required this.rows,
    required this.count,
    required this.error,
    required this.expanded,
    required this.hoveredId,
    required this.selectedId,
    required this.scroll,
    required this.onToggle,
    required this.onHover,
    required this.onSelect,
  });

  /// Deeper rows stop indenting so their names stay in view.
  static const _maxIndent = 18;
  static const _indentStep = 14.0;

  @override
  Widget build(BuildContext context) {
    final loc = S.of(context);
    final palette = ChromePalette.of(context);
    final accent = _accent(palette.isDark);
    final guide = palette.isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.07);
    final name = chromeMono(context, size: 12, color: palette.text);
    final meta = chromeMono(context, size: 11, color: palette.textMuted);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
          child: _SectionLabel(
            loc.layoutTree,
            trailing: Text('$count', style: meta),
          ),
        ),
        if (error case final error?)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: _Notice(
              text: '${loc.layoutTreeError}: $error',
              icon: LucideIcons.alertTriangle,
              color: const Color(0xFFF59E0B),
            ),
          ),
        Expanded(
          child: MouseRegion(
            onExit: (_) => onHover(null),
            child: ListView.builder(
              controller: scroll,
              itemCount: rows.length,
              itemExtent: _rowHeight,
              padding: const EdgeInsets.only(bottom: 8),
              itemBuilder: (context, i) {
                final (chain, depth) = rows[i];
                final node = chain.first;
                final isSelected = node.id == selectedId;
                final isHovered = node.id == hoveredId;
                final hasChildren = chain.last.children.isNotEmpty;
                final indent = math.min(depth, _maxIndent);
                return MouseRegion(
                  cursor: SystemMouseCursors.click,
                  onEnter: (_) => onHover(node.id),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onSelect(node.id),
                    onDoubleTap: hasChildren ? () => onToggle(node.id) : null,
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? ColorTokens.selectedBg(palette.isDark)
                            : isHovered
                            ? palette.hover
                            : null,
                        border: Border(
                          left: BorderSide(
                            color: isSelected ? accent : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                      child: CustomPaint(
                        painter: _IndentGuides(
                          levels: indent,
                          step: _indentStep,
                          color: guide,
                        ),
                        child: Padding(
                          padding: EdgeInsets.only(
                            left: 6 + indent * _indentStep,
                            right: 12,
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 16,
                                child: hasChildren
                                    ? GestureDetector(
                                        onTap: () => onToggle(node.id),
                                        child: Icon(
                                          expanded.contains(node.id)
                                              ? LucideIcons.chevronDown
                                              : LucideIcons.chevronRight,
                                          size: 13,
                                          color: palette.textMuted,
                                        ),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text.rich(
                                  TextSpan(
                                    text: node.name,
                                    style: name.copyWith(
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: isSelected ? accent : null,
                                    ),
                                    children: [
                                      if (chain.length > 1)
                                        TextSpan(
                                          text:
                                              ' › ${chain.length > 2 ? '… › ' : ''}'
                                              '${chain.last.name}',
                                          style: meta,
                                        ),
                                    ],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(_sizeOf(node.rect), style: meta),
                            ],
                          ),
                        ),
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

/// A faint vertical line per indent level, under each level's chevron.
class _IndentGuides extends CustomPainter {
  final int levels;
  final double step;
  final Color color;

  _IndentGuides({
    required this.levels,
    required this.step,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    for (var level = 0; level < levels; level++) {
      final x = 6 + level * step + 8.5;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(_IndentGuides old) =>
      old.levels != levels || old.color != color;
}

class _Properties extends StatelessWidget {
  final LayoutNode? node;

  const _Properties({required this.node});

  @override
  Widget build(BuildContext context) {
    final loc = S.of(context);
    final palette = ChromePalette.of(context);
    final node = this.node;
    if (node == null) {
      return Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionLabel(loc.layoutProperties),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  LucideIcons.mousePointerClick,
                  size: 16,
                  color: palette.textMuted,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    loc.layoutPickElement,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.45,
                      color: palette.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }
    final chain = layoutChainOf(node);
    final key = chromeMono(context, size: 12, color: palette.textMuted);
    final value = chromeMono(context, size: 12, color: palette.text);
    Widget prop(String name, String text) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 116,
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: key,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: SelectableText(text, style: value)),
        ],
      ),
    );
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
      children: [
        _SectionLabel(loc.layoutProperties),
        const SizedBox(height: 8),
        SelectableText(
          chain.map((c) => c.name).join(' › '),
          style: chromeMono(
            context,
            size: 13,
            color: _accent(palette.isDark),
            weight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        _BoxModel(
          rect: node.rect,
          padding: chain.map((c) => c.padding).nonNulls.firstOrNull,
          margin: chain.map((c) => c.margin).nonNulls.firstOrNull,
        ),
        const SizedBox(height: 6),
        Text(
          'x ${_num(node.rect.left)}   y ${_num(node.rect.top)}',
          textAlign: TextAlign.center,
          style: key.copyWith(fontSize: 11),
        ),
        // Each element of the row's chain has its own props.
        for (final member in chain)
          if (member.props.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              member.name,
              style: chromeMono(
                context,
                size: 12,
                color: palette.text,
                weight: FontWeight.w700,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 2),
              child: Divider(height: 1, color: palette.border),
            ),
            for (final MapEntry(key: name, value: text) in member.props.entries)
              prop(name, text),
          ],
      ],
    );
  }
}

/// Margin around padding around content, with every side's value — the
/// diagram browser devtools show.
class _BoxModel extends StatelessWidget {
  final Rect rect;
  final EdgeInsets? padding;
  final EdgeInsets? margin;

  const _BoxModel({
    required this.rect,
    required this.padding,
    required this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final palette = ChromePalette.of(context);
    final number = chromeMono(context, size: 11, color: palette.text);
    final caption = TextStyle(fontSize: 10, color: palette.textMuted);
    String side(double v) => v == 0 ? '–' : _num(v);
    Widget layer(String label, Color tint, EdgeInsets? edges, Widget child) {
      final e = edges ?? EdgeInsets.zero;
      return Container(
        padding: const EdgeInsets.fromLTRB(4, 2, 4, 4),
        decoration: BoxDecoration(
          color: tint.withValues(alpha: palette.isDark ? 0.14 : 0.18),
          border: Border.all(color: tint.withValues(alpha: 0.6)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 16,
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(label, style: caption),
                  ),
                  Center(child: Text(side(e.top), style: number)),
                ],
              ),
            ),
            Row(
              children: [
                SizedBox(
                  width: 30,
                  child: Text(
                    side(e.left),
                    textAlign: TextAlign.center,
                    style: number,
                  ),
                ),
                Expanded(child: child),
                SizedBox(
                  width: 30,
                  child: Text(
                    side(e.right),
                    textAlign: TextAlign.center,
                    style: number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(side(e.bottom), style: number),
          ],
        ),
      );
    }

    return layer(
      'margin',
      _marginTint,
      margin,
      layer(
        'padding',
        _paddingTint,
        padding,
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: _contentTint.withValues(alpha: palette.isDark ? 0.2 : 0.24),
            border: Border.all(color: _contentTint.withValues(alpha: 0.7)),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Center(
            child: Text(
              _sizeOf(rect),
              style: chromeMono(
                context,
                size: 12,
                color: palette.text,
                weight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
