import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/providers/app_update_provider.dart';

/// Compact "app version" pill anchored to the LEFT side of the title
/// bar (the right-side `LibUpdateTips` covers the SDK packages).
///
/// Mirrors the visual language of the SDK tip — amber accent for
/// "advisory, never error", mono font for version numbers, 1px inner
/// border for the liquid-glass refraction feel — but smaller and
/// only renders the desktop app's own version vs the latest GitHub
/// release.
///
/// States:
///   - **Update available** (most important): pill shows current
///     version with an amber `Update` chip. Hover expands the panel
///     with the latest version and a `View release` button that opens
///     the GitHub release page in the default browser.
///   - **Up to date**: subtle green checkmark, no hover expansion.
///   - **Loading** (initial / right after Retry): spinner.
///   - **Error** (offline / rate limit / no release published yet):
///     cloud-off icon, hover expands with retry.
///
/// The version comparison lives in [appUpdateProvider]; this widget
/// is presentation-only.
class AppUpdatePill extends ConsumerStatefulWidget {
  const AppUpdatePill({super.key});

  @override
  ConsumerState<AppUpdatePill> createState() => _AppUpdatePillState();
}

class _AppUpdatePillState extends ConsumerState<AppUpdatePill> {
  bool _hovered = false;

  static const _accent = Color(0xFFFBBF24); // amber — advisory
  static const _releasePageFallback =
      'https://github.com/ridelinktechs/devconnect-manage-kit/releases/latest';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final state = ref.watch(appUpdateProvider);
    final release = state.release;
    final hasUpdate = state.hasUpdate;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        height: _hovered ? null : 26,
        width: _hovered ? 320 : null,
        padding: EdgeInsets.symmetric(
          horizontal: _hovered ? 12 : 10,
          vertical: _hovered ? 10 : 5,
        ),
        decoration: BoxDecoration(
          color: _hovered
              ? (isDark
                  ? const Color(0xFF1F242B).withValues(alpha: 0.96)
                  : Colors.white.withValues(alpha: 0.97))
              : (isDark
                  ? const Color(0xFF1F242B).withValues(alpha: 0.85)
                  : Colors.white.withValues(alpha: 0.92)),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: _hovered
                ? (isDark
                    ? Colors.white.withValues(alpha: 0.10)
                    : Colors.black.withValues(alpha: 0.08))
                : (isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.05)),
          ),
          boxShadow: [
            if (_hovered)
              BoxShadow(
                color: _accent.withValues(alpha: isDark ? 0.18 : 0.12),
                blurRadius: 16,
                spreadRadius: -4,
                offset: const Offset(0, 6),
              ),
          ],
        ),
        child: _hovered
            ? _ExpandedPanel(
                isDark: isDark,
                state: state,
                onOpenRelease: () => _openRelease(release?.htmlUrl),
                onRetry: () =>
                    ref.read(appUpdateProvider.notifier).refresh(),
              )
            : _CollapsedPill(
                isDark: isDark,
                hasUpdate: hasUpdate,
                release: release,
                currentVersion: state.currentVersion,
                errored: state.error != null && state.fetchedAt != null,
                loading: state.fetchedAt == null,
              ),
      ),
    );
  }

  Future<void> _openRelease(String? url) async {
    final target = url ?? _releasePageFallback;
    // `Uri.tryParse` returns null on malformed input instead of
    // throwing — safer than `Uri.parse` here since the URL comes
    // from a third-party API response.
    final uri = Uri.tryParse(target);
    if (uri == null) return;
    // `externalApplication` asks the OS to open in the default browser
    // (Safari on macOS). Falls back to in-app webview if no handler.
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      // Last-ditch: try the in-app handler so the click is never
      // a dead-end. If that also fails we silently bail — the
      // hover panel stays visible with the URL it tried.
      await launchUrl(uri, mode: LaunchMode.inAppWebView);
    }
  }
}

// ─── Collapsed pill (rest state) ─────────────────────────────────────

class _CollapsedPill extends StatefulWidget {
  final bool isDark;
  final bool hasUpdate;
  final bool errored;
  final bool loading;
  final AppRelease? release;
  final String? currentVersion;

  const _CollapsedPill({
    required this.isDark,
    required this.hasUpdate,
    required this.errored,
    required this.loading,
    required this.release,
    required this.currentVersion,
  });

  @override
  State<_CollapsedPill> createState() => _CollapsedPillState();
}

class _CollapsedPillState extends State<_CollapsedPill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    if (widget.loading) _spin.repeat();
  }

  @override
  void didUpdateWidget(covariant _CollapsedPill old) {
    super.didUpdateWidget(old);
    if (widget.loading && !_spin.isAnimating) {
      _spin.repeat();
    } else if (!widget.loading && _spin.isAnimating) {
      _spin.stop();
    }
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    // Leading glyph — communicates the state without color alone so
    // the pill stays readable in any theme.
    Widget leading;
    Color leadingColor;
    if (widget.loading) {
      leading = RotationTransition(
        turns: _spin,
        child: Icon(LucideIcons.loader, size: 11, color: _AppUpdatePillState._accent),
      );
      leadingColor = _AppUpdatePillState._accent;
    } else if (widget.hasUpdate) {
      leading = Icon(LucideIcons.arrowUpCircle, size: 12, color: _AppUpdatePillState._accent);
      leadingColor = _AppUpdatePillState._accent;
    } else if (widget.errored) {
      leading = Icon(LucideIcons.cloudOff, size: 11, color: isDark ? Colors.white54 : Colors.black54);
      leadingColor = isDark ? Colors.white54 : Colors.black54;
    } else {
      leading = Icon(
        LucideIcons.check,
        size: 12,
        color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A),
      );
      leadingColor = isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        leading,
        const SizedBox(width: 6),
        // `v1.0.3` once package_info_plus resolves; falls back to `—`
        // for the brief window between widget mount and platform
        // channel response.
        Text(
          widget.currentVersion != null
              ? 'v${widget.currentVersion}'
              : '—',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            fontFamily: 'monospace',
            letterSpacing: 0.2,
            color: leadingColor,
          ),
        ),
        if (widget.hasUpdate) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: _AppUpdatePillState._accent,
              borderRadius: BorderRadius.circular(3),
            ),
            child: const Text(
              'UPDATE',
              style: TextStyle(
                fontSize: 8.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Expanded panel (hover state) ────────────────────────────────────

class _ExpandedPanel extends StatelessWidget {
  final bool isDark;
  final AppReleaseState state;
  final VoidCallback onOpenRelease;
  final VoidCallback onRetry;

  const _ExpandedPanel({
    required this.isDark,
    required this.state,
    required this.onOpenRelease,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final release = state.release;
    final hasUpdate = state.hasUpdate;
    final errored = state.error != null && state.fetchedAt != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(LucideIcons.appWindow, size: 12, color: _AppUpdatePillState._accent),
            const SizedBox(width: 6),
            Text(
              hasUpdate
                  ? 'Update available'
                  : errored
                      ? 'Live check unavailable'
                      : 'You are up to date',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black87,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            _VersionCell(
              label: 'Installed',
              version: state.currentVersion != null
                  ? 'v${state.currentVersion}'
                  : '—',
              isDark: isDark,
              accent: false,
            ),
            const SizedBox(width: 10),
            Icon(
              LucideIcons.arrowRight,
              size: 10,
              color: isDark ? Colors.white38 : Colors.black45,
            ),
            const SizedBox(width: 10),
            _VersionCell(
              label: 'Latest',
              version: release != null ? 'v${release.version}' : '—',
              isDark: isDark,
              accent: hasUpdate,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _PrimaryActionButton(
                label: 'View release',
                icon: LucideIcons.externalLink,
                isDark: isDark,
                accent: hasUpdate,
                onTap: onOpenRelease,
              ),
            ),
            if (errored) ...[
              const SizedBox(width: 8),
              _SecondaryActionButton(
                label: 'Retry',
                icon: LucideIcons.refreshCw,
                isDark: isDark,
                onTap: onRetry,
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _VersionCell extends StatelessWidget {
  final String label;
  final String version;
  final bool isDark;
  final bool accent;

  const _VersionCell({
    required this.label,
    required this.version,
    required this.isDark,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final color = accent ? _AppUpdatePillState._accent : (isDark ? Colors.white : Colors.black87);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 8.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: isDark ? Colors.white38 : Colors.black45,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          version,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            fontFamily: 'monospace',
            color: color,
          ),
        ),
      ],
    );
  }
}

class _PrimaryActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isDark;
  final bool accent;
  final VoidCallback onTap;

  const _PrimaryActionButton({
    required this.label,
    required this.icon,
    required this.isDark,
    required this.accent,
    required this.onTap,
  });

  @override
  State<_PrimaryActionButton> createState() => _PrimaryActionButtonState();
}

class _PrimaryActionButtonState extends State<_PrimaryActionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final accent = widget.accent;
    final isDark = widget.isDark;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: Container(
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: accent
                ? _AppUpdatePillState._accent
                : (isDark
                    ? Colors.white.withValues(alpha: 0.10)
                    : Colors.black.withValues(alpha: 0.06)),
            borderRadius: BorderRadius.circular(6),
            border: accent
                ? null
                : Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.10)
                        : Colors.black.withValues(alpha: 0.06),
                  ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 11,
                color: accent ? Colors.black87 : (isDark ? Colors.white : Colors.black87),
              ),
              const SizedBox(width: 5),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                  color: accent ? Colors.black87 : (isDark ? Colors.white : Colors.black87),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SecondaryActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isDark;
  final VoidCallback onTap;

  const _SecondaryActionButton({
    required this.label,
    required this.icon,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.10)
                : Colors.black.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 11, color: isDark ? Colors.white70 : Colors.black87),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}