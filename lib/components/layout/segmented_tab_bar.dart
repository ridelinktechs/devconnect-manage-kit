import 'package:flutter/material.dart';

import '../../core/theme/chrome_palette.dart';
import '../../core/theme/color_tokens.dart';

/// One tab of a [SegmentedTabBar].
class SegmentedTab {
  final IconData icon;
  final String label;

  /// How many items the tab holds; shown after the label when above zero.
  final int count;

  /// What the tab holds, shown on hover.
  final String? tooltip;

  const SegmentedTab({
    required this.icon,
    required this.label,
    this.count = 0,
    this.tooltip,
  });
}

/// Tabs as a segmented control — icon, label and live count each, the
/// selected one raised on a card in [accent] — driving [controller] like a
/// [TabBar] would. A [secondary] bar (tabs inside a tab) is lower and
/// flatter: no tray, the selected tab only tinted.
class SegmentedTabBar extends StatelessWidget {
  final TabController controller;
  final List<SegmentedTab> tabs;
  final Color accent;
  final bool secondary;

  const SegmentedTabBar({
    super.key,
    required this.controller,
    required this.tabs,
    this.accent = ColorTokens.primary,
    this.secondary = false,
  });

  @override
  Widget build(BuildContext context) {
    final palette = ChromePalette.of(context);
    return Container(
      height: secondary ? 38 : 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(bottom: BorderSide(color: palette.border)),
      ),
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) => SegmentedTabs(
          tabs: tabs,
          index: controller.index,
          onSelect: controller.animateTo,
          accent: accent,
          secondary: secondary,
          animate: controller.animationDuration > Duration.zero,
        ),
      ),
    );
  }
}

/// [SegmentedTabBar]'s tray on its own, to pick one of [tabs] that aren't
/// pages of a [TabBarView].
class SegmentedTabs extends StatelessWidget {
  final List<SegmentedTab> tabs;
  final int index;
  final ValueChanged<int> onSelect;
  final Color accent;
  final bool secondary;

  /// Whether the selection animates; when it doesn't, it switches at once.
  final bool animate;

  const SegmentedTabs({
    super.key,
    required this.tabs,
    required this.index,
    required this.onSelect,
    this.accent = ColorTokens.primary,
    this.secondary = false,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    final palette = ChromePalette.of(context);
    return Container(
      padding: EdgeInsets.all(secondary ? 0 : 3),
      decoration: BoxDecoration(
        color: secondary
            ? null
            : palette.isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (i, tab) in tabs.indexed)
            _TabButton(
              tab: tab,
              selected: index == i,
              accent: accent,
              secondary: secondary,
              palette: palette,
              animate: animate,
              onTap: () => onSelect(i),
            ),
        ],
      ),
    );
  }
}

class _TabButton extends StatefulWidget {
  final SegmentedTab tab;
  final bool selected;
  final Color accent;
  final bool secondary;
  final ChromePalette palette;

  /// Whether tabs animate; when they don't, the selection switches at once.
  final bool animate;
  final VoidCallback onTap;

  const _TabButton({
    required this.tab,
    required this.selected,
    required this.accent,
    required this.secondary,
    required this.palette,
    required this.animate,
    required this.onTap,
  });

  @override
  State<_TabButton> createState() => _TabButtonState();
}

class _TabButtonState extends State<_TabButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final tab = widget.tab;
    final palette = widget.palette;
    final selected = widget.selected;
    final secondary = widget.secondary;
    final fg = selected
        ? widget.accent
        : (_hovered ? palette.text : palette.textMuted);
    final button = Semantics(
      button: true,
      selected: selected,
      label: tab.label,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: widget.animate
                ? const Duration(milliseconds: 150)
                : Duration.zero,
            height: secondary ? 26 : 28,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: selected
                  ? (secondary
                        ? widget.accent.withValues(alpha: 0.12)
                        : palette.isDark
                        ? Colors.white.withValues(alpha: 0.09)
                        : palette.pillActive)
                  : (_hovered ? palette.hover : Colors.transparent),
              borderRadius: BorderRadius.circular(7),
              border: Border.all(
                color: selected && !secondary
                    ? (palette.isDark
                          ? widget.accent.withValues(alpha: 0.4)
                          : Colors.black.withValues(alpha: 0.06))
                    : Colors.transparent,
              ),
              boxShadow: selected && !secondary && !palette.isDark
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(tab.icon, size: 14, color: fg),
                const SizedBox(width: 6),
                Text(
                  tab.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: fg,
                  ),
                ),
                if (tab.count > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: (selected ? widget.accent : palette.textMuted)
                          .withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${tab.count}',
                      style: chromeMono(
                        context,
                        size: 10.5,
                        color: fg,
                        weight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
    return tab.tooltip == null
        ? button
        : Tooltip(
            message: tab.tooltip,
            waitDuration: const Duration(milliseconds: 400),
            child: button,
          );
  }
}
