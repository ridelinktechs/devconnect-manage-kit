import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../components/inputs/search_field.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/mcp_clients.dart';
import '../../../../core/providers/mcp_pairing_provider.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/utils/mcp_install_checker.dart';
import '../../../../core/utils/smooth_scroll_controller.dart';
import '../../../../l10n/app_localizations.dart';
import 'mcp_cli_cards.dart';

/// Centered modal panel that slides up from the bottom of the screen.
/// Replaces the previous top-right Dynamic Island position so the
/// three client cards can stack vertically with full width to breathe.
///
/// Contains:
///   - Header strip with section title + subtitle + close button.
///   - Three client cards (Claude Code / Codex / Cursor) stacked vertically.
///   - Recent activity (last 5 install attempts, lazy-loaded).
///
/// Tapping the backdrop or hitting Esc dismisses.
class McpPanel extends ConsumerWidget {
  const McpPanel({super.key});

  /// Push the panel onto the navigator stack with the spring animation.
  static Future<void> show(BuildContext context) {
    return Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.black.withValues(alpha: 0.42),
        barrierDismissible: true,
        transitionDuration: const Duration(milliseconds: 240),
        reverseTransitionDuration: const Duration(milliseconds: 180),
        pageBuilder: (context, anim, sec) => const McpPanel(),
        transitionsBuilder: (context, anim, sec, child) {
          final offset = Tween<Offset>(
            begin: const Offset(0, 0.05),
            end: Offset.zero,
          ).chain(CurveTween(curve: Curves.easeOutCubic)).animate(anim);
          return FadeTransition(
            opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
            child: SlideTransition(position: offset, child: child),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Stack(
      children: [
        const Positioned.fill(child: _ModalBackdrop()),
        // Center the panel inside a max-width container so it doesn't
        // stretch to ultrawide displays. Vertically anchored just below
        // the title bar.
        Positioned.fill(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 56, bottom: 32),
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: const _PanelCard(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ModalBackdrop extends StatelessWidget {
  const _ModalBackdrop();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).maybePop(),
      child: const SizedBox.expand(),
    );
  }
}

class _PanelCard extends ConsumerStatefulWidget {
  const _PanelCard();

  @override
  ConsumerState<_PanelCard> createState() => _PanelCardState();
}

class _PanelCardState extends ConsumerState<_PanelCard> {
  final _scrollController = SmoothScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Kick off a fresh install-status check as soon as the panel
    // mounts. The result populates `mcpInstallStatusProvider` so each
    // card shows "Installed / Not installed / Unhealthy / Unknown"
    // without the user having to click anything.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(mcpInstallStatusProvider.notifier).refreshAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = S.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = const Color(0xFFFBBF24);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 760),
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF1F242B).withValues(alpha: 0.97)
                : Colors.white.withValues(alpha: 0.98),
            borderRadius: BorderRadius.circular(18),
            // Liquid-glass refraction: 1px outer border + tinted
            // shadow so the edge feels physical, not floating.
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.08),
            ),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: isDark ? 0.20 : 0.14),
                blurRadius: 36,
                spreadRadius: -8,
                offset: const Offset(0, 16),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.40 : 0.14),
                blurRadius: 40,
                offset: const Offset(0, 22),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _PanelHeader(accent: accent),
                  Flexible(
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            loc.mcpSectionSubtitle,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: isDark ? Colors.white60 : Colors.black54,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const McpCliCards(),
                          const SizedBox(height: 20),
                          const _RecentActivity(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PanelHeader extends StatelessWidget {
  final Color accent;
  const _PanelHeader({required this.accent});

  @override
  Widget build(BuildContext context) {
    final loc = S.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.05),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: isDark ? 0.16 : 0.14),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'MCP',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: accent,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            loc.mcpSectionTitle,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const Spacer(),
          _CloseButton(isDark: isDark),
        ],
      ),
    );
  }
}

class _CloseButton extends StatefulWidget {
  final bool isDark;
  const _CloseButton({required this.isDark});

  @override
  State<_CloseButton> createState() => _CloseButtonState();
}

class _CloseButtonState extends State<_CloseButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final color =
        widget.isDark ? Colors.white70 : Colors.black.withValues(alpha: 0.7);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () => Navigator.of(context).maybePop(),
      child: AnimatedScale(
        scale: _pressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: widget.isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(7),
            border: Border.all(
              color: widget.isDark
                  ? Colors.white.withValues(alpha: 0.10)
                  : Colors.black.withValues(alpha: 0.06),
            ),
          ),
          child: Icon(LucideIcons.x, size: 12, color: color),
        ),
      ),
    );
  }
}

/// Install-history timeline with a search box + filter chips. The
/// history is capped at 200 (`mcpInstallHistoryProvider`); we render
/// every matching entry, not just the last 5, so power-users can scroll
/// through their install/uninstall trail.
class _RecentActivity extends ConsumerStatefulWidget {
  const _RecentActivity();

  @override
  ConsumerState<_RecentActivity> createState() => _RecentActivityState();
}

class _RecentActivityState extends ConsumerState<_RecentActivity> {
  final _searchCtrl = TextEditingController();
  final _searchScrollCtrl = SmoothScrollController();
  String _query = '';
  final Set<McpAction> _actionFilters = {};
  final Set<McpResult?> _resultFilters = {};

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchScrollCtrl.dispose();
    super.dispose();
  }

  /// Substring match across command / stdout / stderr / client name.
  bool _matchesQuery(InstallAttempt e) {
    if (_query.isEmpty) return true;
    final q = _query.toLowerCase();
    if ((e.command ?? '').toLowerCase().contains(q)) return true;
    if ((e.stdout ?? '').toLowerCase().contains(q)) return true;
    if ((e.stderr ?? '').toLowerCase().contains(q)) return true;
    final clientName = switch (e.clientId) {
      McpClientId.claudeCode => 'claude',
      McpClientId.codex => 'codex',
      McpClientId.cursor => 'cursor',
      null => '',
    };
    return clientName.contains(q);
  }

  bool _matchesFilters(InstallAttempt e) {
    if (_actionFilters.isNotEmpty && !_actionFilters.contains(e.action)) {
      return false;
    }
    if (_resultFilters.isNotEmpty && !_resultFilters.contains(e.result)) {
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final loc = S.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final history = ref.watch(mcpInstallHistoryProvider);

    if (history.isEmpty) {
      return _EmptyState(
        title: loc.mcpInstallHistory,
        body: 'No installs yet. Click Run on a card above to test.',
        isDark: isDark,
      );
    }

    final filtered =
        history.where((e) => _matchesQuery(e) && _matchesFilters(e)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(text: loc.mcpInstallHistory, isDark: isDark),
        const SizedBox(height: 8),

        // Search + filter row.
        SearchField(
          controller: _searchCtrl,
          hintText: 'Search command, output, client…',
          onChanged: (v) => setState(() => _query = v),
          onClear: _query.isEmpty
              ? null
              : () {
                  _searchCtrl.clear();
                  setState(() => _query = '');
                },
        ),
        const SizedBox(height: 8),

        // Filter chips: action + result.
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _FilterChip(
              label: 'Install',
              selected: _actionFilters.contains(McpAction.run),
              onTap: () =>
                  setState(() => _toggleAction(McpAction.run, _actionFilters)),
              accent: const Color(0xFFFBBF24),
              isDark: isDark,
            ),
            _FilterChip(
              label: 'Uninstall',
              selected: _actionFilters.contains(McpAction.uninstall),
              onTap: () => setState(() =>
                  _toggleAction(McpAction.uninstall, _actionFilters)),
              accent: const Color(0xFFFF6B6B),
              isDark: isDark,
            ),
            _FilterChip(
              label: 'Copy',
              selected: _actionFilters.contains(McpAction.copy),
              onTap: () =>
                  setState(() => _toggleAction(McpAction.copy, _actionFilters)),
              accent: const Color(0xFF60A5FA),
              isDark: isDark,
            ),
            const SizedBox(width: 4),
            _ResultDot(
              color: ColorTokens.success,
              selected: _resultFilters.contains(McpResult.success),
              onTap: () => setState(() =>
                  _toggleResult(McpResult.success, _resultFilters)),
              isDark: isDark,
            ),
            _ResultDot(
              color: ColorTokens.error,
              selected: _resultFilters.contains(McpResult.failed),
              onTap: () => setState(() =>
                  _toggleResult(McpResult.failed, _resultFilters)),
              isDark: isDark,
            ),
            _ResultDot(
              color: ColorTokens.warning,
              selected:
                  _resultFilters.contains(McpResult.timeout) ||
                      _resultFilters.contains(McpResult.notFound),
              onTap: () => setState(() {
                _toggleResult(McpResult.timeout, _resultFilters);
                _toggleResult(McpResult.notFound, _resultFilters);
              }),
              isDark: isDark,
            ),
            if (_actionFilters.isNotEmpty || _resultFilters.isNotEmpty) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => setState(() {
                  _actionFilters.clear();
                  _resultFilters.clear();
                }),
                child: Text(
                  'Clear',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),

        // Result count + list.
        Row(
          children: [
            Text(
              '${filtered.length} of ${history.length}',
              style: TextStyle(
                fontSize: 10,
                fontFamily: AppConstants.monoFontFamily,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),

        if (filtered.isEmpty)
          _NoMatches(isDark: isDark)
        else
          Container(
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.03)
                  : Colors.black.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.05),
              ),
            ),
            // Inner scroll so very long filtered lists don't push the
            // rest of the panel off-screen.
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: SingleChildScrollView(
                controller: _searchScrollCtrl,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < filtered.length; i++) ...[
                      _HistoryRow(entry: filtered[i], isDark: isDark),
                      if (i < filtered.length - 1)
                        Container(
                          height: 1,
                          margin: const EdgeInsets.symmetric(horizontal: 12),
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.04)
                              : Colors.black.withValues(alpha: 0.03),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _toggleAction(McpAction a, Set<McpAction> set) {
    set.contains(a) ? set.remove(a) : set.add(a);
  }

  void _toggleResult(McpResult? r, Set<McpResult?> set) {
    set.contains(r) ? set.remove(r) : set.add(r);
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color accent;
  final bool isDark;
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.accent,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: selected
              ? accent.withValues(alpha: isDark ? 0.20 : 0.16)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : Colors.black.withValues(alpha: 0.04)),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: selected
                ? accent.withValues(alpha: 0.45)
                : (isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.06)),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
            color: selected
                ? accent
                : (isDark ? Colors.white60 : Colors.black54),
          ),
        ),
      ),
    );
  }
}

/// Tiny colored dot for filtering by result — same look as the status
/// dots on each row so the visual language stays consistent.
class _ResultDot extends StatelessWidget {
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  final bool isDark;
  const _ResultDot({
    required this.color,
    required this.selected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: isDark ? 0.22 : 0.18)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoMatches extends StatelessWidget {
  final bool isDark;
  const _NoMatches({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 14),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.02)
            : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.04)
              : Colors.black.withValues(alpha: 0.04),
        ),
      ),
      child: Column(
        children: [
          Icon(
            LucideIcons.searchX,
            size: 16,
            color: isDark ? Colors.white38 : Colors.black38,
          ),
          const SizedBox(height: 6),
          Text(
            'No matching entries',
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final bool isDark;
  const _SectionLabel({required this.text, required this.isDark});

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          color: isDark ? Colors.white70 : Colors.black87,
        ),
      );
}

class _HistoryRow extends StatelessWidget {
  final InstallAttempt entry;
  final bool isDark;
  const _HistoryRow({required this.entry, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(entry.result);
    final label = _actionLabel(entry);
    final time = _relativeTime(entry.timestamp);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            time,
            style: TextStyle(
              fontSize: 10.5,
              fontFamily: AppConstants.monoFontFamily,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(McpResult? r) => switch (r) {
        McpResult.success => ColorTokens.success,
        McpResult.failed => ColorTokens.error,
        McpResult.timeout => ColorTokens.warning,
        McpResult.notFound => ColorTokens.warning,
        null => Colors.grey,
      };

  String _actionLabel(InstallAttempt e) {
    final clientName = switch (e.clientId) {
      McpClientId.claudeCode => 'Claude Code',
      McpClientId.codex => 'Codex',
      McpClientId.cursor => 'Cursor',
      null => '',
    };
    return switch (e.action) {
      McpAction.run => 'Installed $clientName',
      McpAction.copy => 'Copied $clientName',
      McpAction.uninstall => 'Uninstalled $clientName',
    };
  }

  String _relativeTime(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}

class _EmptyState extends StatelessWidget {
  final String title;
  final String body;
  final bool isDark;
  const _EmptyState({
    required this.title,
    required this.body,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(text: title, isDark: isDark),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.03)
                  : Colors.black.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.05),
              ),
            ),
            child: Text(
              body,
              style: TextStyle(
                fontSize: 11.5,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            ),
          ),
        ],
      );
}