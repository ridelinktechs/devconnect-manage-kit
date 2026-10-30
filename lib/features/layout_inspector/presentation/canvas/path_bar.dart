import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/chrome_palette.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../provider/layout_providers.dart';
import '../shared/layout_style.dart';

/// The selected element's ancestry, one crumb per box (a chain shows its
/// outermost element), plus the box model legend.
class PathBar extends StatelessWidget {
  final List<LayoutNode> path;
  final ValueChanged<String?> onHover;
  final ValueChanged<String> onSelect;

  const PathBar({
    super.key,
    required this.path,
    required this.onHover,
    required this.onSelect,
  });

  static const _maxCrumbs = 5;

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
          swatch(LayoutColors.margin, 'margin'),
          swatch(LayoutColors.padding, 'padding'),
          swatch(LayoutColors.content, 'content'),
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
              color: widget.current
                  ? LayoutColors.accent(palette.isDark)
                  : palette.text,
              weight: widget.current ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
