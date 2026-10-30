import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/chrome_palette.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../provider/layout_providers.dart';
import '../shared/layout_style.dart';
import '../shared/tag_chip.dart';

/// Whole numbers, for the tree, where every column counts.
String _sizeRounded(Rect r) => '${r.width.round()} × ${r.height.round()}';

class ElementTree extends StatelessWidget {
  /// Every row's height: a row's offset is its index times this.
  static const rowHeight = 26.0;

  final List<(List<LayoutNode>, int)> rows;

  /// Rows holding a search match.
  final Set<String> matches;
  final Set<String> expanded;
  final String? hoveredId;
  final String? selectedId;
  final ScrollController scroll;
  final ValueChanged<String> onToggle;
  final ValueChanged<String?> onHover;
  final ValueChanged<String> onSelect;

  const ElementTree({
    super.key,
    required this.rows,
    required this.matches,
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
  static const _indentStep = 12.0;

  @override
  Widget build(BuildContext context) {
    final palette = ChromePalette.of(context);
    final accent = LayoutColors.accent(palette.isDark);
    final guide = palette.isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.07);
    final matchBg = LayoutColors.warning.withValues(
      alpha: palette.isDark ? 0.14 : 0.16,
    );
    final meta = chromeMono(context, size: 11, color: palette.textMuted);
    return MouseRegion(
      onExit: (_) => onHover(null),
      child: ListView.builder(
        controller: scroll,
        itemCount: rows.length,
        itemExtent: ElementTree.rowHeight,
        padding: const EdgeInsets.only(bottom: 8),
        itemBuilder: (context, i) {
          final (chain, depth) = rows[i];
          final node = chain.first;
          final isSelected = node.id == selectedId;
          final isHovered = node.id == hoveredId;
          final hasChildren = chain.last.children.isNotEmpty;
          final indent = math.min(depth, _maxIndent);
          // Nothing on screen: shown, but faded.
          final hidden = node.rect.width == 0 || node.rect.height == 0;
          final nameColor = isSelected
              ? accent
              : hidden
              ? palette.textMuted
              : palette.text;
          return Tooltip(
            message:
                '${chain.map((n) => n.name).join(' › ')}\n'
                '${formatSize(node.rect)}',
            waitDuration: const Duration(milliseconds: 700),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              onEnter: (_) => onHover(node.id),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onSelect(node.id),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? ColorTokens.selectedBg(palette.isDark)
                        : isHovered
                        ? palette.hover
                        : matches.contains(node.id)
                        ? matchBg
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
                            child: _NameAndTag(
                              name: node.name,
                              style: chromeMono(
                                context,
                                size: 12,
                                color: nameColor,
                                weight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                              // The native view the chain ends in.
                              tag: chain.length > 1 ? chain.last.name : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _sizeRounded(node.rect),
                            style: hidden
                                ? meta.copyWith(
                                    color: palette.textMuted.withValues(
                                      alpha: 0.55,
                                    ),
                                  )
                                : meta,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// A name, then a tag in whatever room is left: the name shortens only
/// once the tag is gone.
class _NameAndTag extends StatelessWidget {
  final String name;
  final TextStyle style;
  final String? tag;

  const _NameAndTag({required this.name, required this.style, this.tag});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (TextPainter(
          text: TextSpan(text: name, style: style),
          maxLines: 1,
          textDirection: TextDirection.ltr,
          textScaler: MediaQuery.textScalerOf(context),
        )..layout()).width;
        final room = constraints.maxWidth - width - 6;
        return Row(
          children: [
            Flexible(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: style,
              ),
            ),
            if (tag != null && room >= 28) ...[
              const SizedBox(width: 6),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: room),
                child: TagChip(tag!, dense: true),
              ),
            ],
          ],
        );
      },
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
