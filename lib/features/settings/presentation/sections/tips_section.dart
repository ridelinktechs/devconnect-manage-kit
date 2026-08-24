import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../l10n/app_localizations.dart';
import '../header/section_title.dart';

/// "Tips & Shortcuts" card — a 2-column grid of small clickable cards,
/// one per feature page. Clicking a card opens a modal with the full
/// tip body. Designed to sit below `QuickStartSection` so newcomers see
/// "how do I connect?" before "what can I do once I'm connected?"
///
/// Tips live in code (not ARB) because they reference feature-specific
/// UI vocabulary that's only useful in English — duplicating across 5
/// locales for a non-feature reference card is wasted effort. The
/// section header + description are localized.
class TipsSection extends StatelessWidget {
  const TipsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final tips = _buildTips(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(
          icon: LucideIcons.lightbulb,
          title: S.of(context).tipsAndShortcuts,
        ),
        Text(
          S.of(context).tipsAndShortcutsDesc,
          style: TextStyle(fontSize: 11, color: Colors.grey[500], height: 1.4),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            // 2 cols on wide settings pane, 1 col on narrow. The page
            // caps at 820px; at <560px the cards become single-col for
            // cramped viewports (window resize, split-screen).
            final cols = constraints.maxWidth >= 560 ? 2 : 1;
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (var i = 0; i < tips.length; i++)
                  SizedBox(
                    width: cols == 2
                        ? (constraints.maxWidth - 10) / 2
                        : constraints.maxWidth,
                    child: _TipCard(
                      tip: tips[i],
                      isDark: isDark,
                      onTap: () => _showTipDialog(context, tips[i]),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  /// Opens a modal dialog with the tip's full body. Uses [AlertDialog]
  /// so it inherits the platform's modal styling without us having to
  /// hand-roll a sheet.
  void _showTipDialog(BuildContext context, _Tip tip) {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1C1F23) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          title: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: tip.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(tip.icon, size: 16, color: tip.color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  tip.title,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          content: Text(
            tip.body,
            style: TextStyle(
              fontSize: 13,
              height: 1.55,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(S.of(ctx).ok),
            ),
          ],
        );
      },
    );
  }

  /// One tip per feature page. Keep bodies to 2-3 short sentences; this
  /// is a reminder, not documentation. The icon + color match the
  /// feature's own sidebar accent so users can recognize the page at a
  /// glance.
  List<_Tip> _buildTips(BuildContext context) => [
    _Tip(
      icon: LucideIcons.layoutDashboard,
      color: const Color(0xFF58A6FF),
      title: S.of(context).tipAllEventsTitle,
      body: S.of(context).tipAllEventsBody,
    ),
    _Tip(
      icon: LucideIcons.globe,
      color: const Color(0xFF3FB950),
      title: S.of(context).tipNetworkTitle,
      body: S.of(context).tipNetworkBody,
    ),
    _Tip(
      icon: LucideIcons.terminal,
      color: const Color(0xFF58A6FF),
      title: S.of(context).tipConsoleTitle,
      body: S.of(context).tipConsoleBody,
    ),
    _Tip(
      icon: LucideIcons.layers,
      color: const Color(0xFFD2A8FF),
      title: S.of(context).tipStateTitle,
      body: S.of(context).tipStateBody,
    ),
    _Tip(
      icon: LucideIcons.database,
      color: const Color(0xFFE3B341),
      title: S.of(context).tipStorageTitle,
      body: S.of(context).tipStorageBody,
    ),
    _Tip(
      icon: LucideIcons.hardDrive,
      color: const Color(0xFFD2A8FF),
      title: S.of(context).tipDatabaseTitle,
      body: S.of(context).tipDatabaseBody,
    ),
    _Tip(
      icon: LucideIcons.gauge,
      color: const Color(0xFF3FB950),
      title: S.of(context).tipPerformanceTitle,
      body: S.of(context).tipPerformanceBody,
    ),
    _Tip(
      icon: LucideIcons.bug,
      color: const Color(0xFFF85149),
      title: S.of(context).tipLeaksTitle,
      body: S.of(context).tipLeaksBody,
    ),
    _Tip(
      icon: LucideIcons.timer,
      color: const Color(0xFF8B949E),
      title: S.of(context).tipBenchmarkTitle,
      body: S.of(context).tipBenchmarkBody,
    ),
    _Tip(
      icon: LucideIcons.alertTriangle,
      color: const Color(0xFFE3B341),
      title: S.of(context).tipErrorsTitle,
      body: S.of(context).tipErrorsBody,
    ),
    _Tip(
      icon: LucideIcons.server,
      color: const Color(0xFF14A096),
      title: S.of(context).tipMockTitle,
      body: S.of(context).tipMockBody,
    ),
    _Tip(
      icon: LucideIcons.history,
      color: const Color(0xFF8B949E),
      title: S.of(context).tipHistoryTitle,
      body: S.of(context).tipHistoryBody,
    ),
  ];
}

class _Tip {
  final IconData icon;
  final Color color;
  final String title;
  final String body;

  const _Tip({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });
}

/// Single card in the tips grid. Hover/press feedback shows it's
/// clickable; the body preview is a 2-line ellipsis so the grid stays
/// scannable without expanding every card.
class _TipCard extends StatefulWidget {
  final _Tip tip;
  final bool isDark;
  final VoidCallback onTap;

  const _TipCard({
    required this.tip,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_TipCard> createState() => _TipCardState();
}

class _TipCardState extends State<_TipCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final tip = widget.tip;
    final isDark = widget.isDark;

    final bg = _hovered
        ? tip.color.withValues(alpha: isDark ? 0.10 : 0.06)
        : (isDark
            ? Colors.white.withValues(alpha: 0.02)
            : Colors.black.withValues(alpha: 0.02));

    final border = _hovered
        ? tip.color.withValues(alpha: 0.35)
        : (isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.08));

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: tip.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(tip.icon, size: 14, color: tip.color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tip.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      tip.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.5,
                        height: 1.4,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                LucideIcons.chevronRight,
                size: 12,
                color: _hovered
                    ? tip.color
                    : (isDark ? Colors.white24 : Colors.black26),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
