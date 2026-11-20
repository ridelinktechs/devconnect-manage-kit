import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/providers/tab_visibility_provider.dart';
import '../../../../core/theme/chrome_palette.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../controls/stretch_switch.dart';
import '../header/section_title.dart';

/// Every tab of the sidebar that can be hidden, as a grid of switches in
/// sidebar order. Each tile's icon keeps the tab's accent color while the
/// tab shows.
class TabVisibilitySection extends ConsumerWidget {
  const TabVisibilitySection({super.key});

  List<(TabKey, String, IconData, Color)> _getTabs(BuildContext context) {
    final s = S.of(context);
    return [
      (
        TabKey.console,
        s.console,
        LucideIcons.terminal,
        const Color(0xFF58A6FF),
      ),
      (TabKey.network, s.network, LucideIcons.globe, ColorTokens.success),
      (TabKey.state, s.state, LucideIcons.layers, ColorTokens.secondary),
      (TabKey.storage, s.storage, LucideIcons.database, ColorTokens.warning),
      (
        TabKey.database,
        s.database,
        LucideIcons.hardDrive,
        const Color(0xFFD2A8FF),
      ),
      (
        TabKey.performance,
        s.performance,
        LucideIcons.gauge,
        ColorTokens.chartGreen,
      ),
      (
        TabKey.memoryLeaks,
        s.memoryLeaks,
        LucideIcons.bug,
        ColorTokens.chartRed,
      ),
      (
        TabKey.benchmark,
        s.tabBenchmark,
        LucideIcons.timer,
        const Color(0xFF8B949E),
      ),
      (
        TabKey.error,
        s.errors,
        LucideIcons.alertTriangle,
        ColorTokens.chartAmber,
      ),
      (TabKey.display, s.tabDisplay, LucideIcons.eye, const Color(0xFF79C0FF)),
      (
        TabKey.asyncOps,
        s.tabAsync,
        LucideIcons.workflow,
        const Color(0xFFA371F7),
      ),
      (
        TabKey.layout,
        s.tabLayout,
        LucideIcons.scanSearch,
        const Color(0xFFF0883E),
      ),
      (
        TabKey.commands,
        s.tabCommands,
        LucideIcons.squareTerminal,
        ColorTokens.chartBlue,
      ),
      (
        TabKey.mockServer,
        s.tabMockServer,
        LucideIcons.server,
        const Color(0xFF14A096),
      ),
      (TabKey.history, s.history, LucideIcons.history, const Color(0xFF8B949E)),
    ];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabledTabs = ref.watch(tabVisibilityProvider);
    final p = ChromePalette.of(context);
    final s = S.of(context);
    final tabs = _getTabs(context);
    final shown = tabs.where((t) => enabledTabs.contains(t.$1)).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SectionTitle(
                icon: LucideIcons.layoutGrid,
                title: s.tabVisibility,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: p.text.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$shown / ${tabs.length}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: p.textMuted,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
        Text(
          s.tabVisibilityDesc,
          style: TextStyle(fontSize: 12, height: 1.45, color: p.textMuted),
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final cols = constraints.maxWidth >= 620
                ? 3
                : (constraints.maxWidth >= 400 ? 2 : 1);
            final width = (constraints.maxWidth - 8 * (cols - 1)) / cols;
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final t in tabs)
                  SizedBox(
                    width: width,
                    child: _TabTile(
                      label: t.$2,
                      icon: t.$3,
                      color: t.$4,
                      enabled: enabledTabs.contains(t.$1),
                      onToggle: () =>
                          ref.read(tabVisibilityProvider.notifier).toggle(t.$1),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(LucideIcons.pin, size: 13, color: p.textMuted),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                s.tabsAlwaysShown,
                style: TextStyle(fontSize: 12, color: p.textMuted),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// One tab: icon tile, name and switch; the whole tile toggles it and
/// lights up on hover.
class _TabTile extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool enabled;
  final VoidCallback onToggle;

  const _TabTile({
    required this.label,
    required this.icon,
    required this.color,
    required this.enabled,
    required this.onToggle,
  });

  @override
  State<_TabTile> createState() => _TabTileState();
}

class _TabTileState extends State<_TabTile> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final p = ChromePalette.of(context);
    final on = widget.enabled;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onToggle,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 52,
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
          decoration: BoxDecoration(
            color: _hover ? p.hover : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: on
                  ? widget.color.withValues(alpha: 0.28)
                  : p.border.withValues(alpha: 0.7),
            ),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: on
                      ? widget.color.withValues(alpha: p.isDark ? 0.16 : 0.12)
                      : p.text.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  on ? widget.icon : LucideIcons.lock,
                  size: 15,
                  color: on ? widget.color : p.textMuted,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: on ? p.text : p.textMuted,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              StretchSwitch(
                value: on,
                label: widget.label,
                color: widget.color,
                onChanged: (_) => widget.onToggle(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
