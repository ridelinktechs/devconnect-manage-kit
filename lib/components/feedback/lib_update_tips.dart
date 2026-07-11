import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/providers/sdk_versions_provider.dart';
import '../../l10n/app_localizations.dart';

/// Compact, dismissible "Tips" pill anchored at the top-right of the
/// title bar. Collapsed to a small amber dot + label, expands on
/// hover into a glass panel listing the SDKs the client app must be
/// on for DevConnect to ingest the full payload.
///
/// Design philosophy:
///   - **Rest state** is one dot + one short word. It must NEVER
///     compete with page content or block clicks.
///   - **Hover state** springs open with a soft cubic ease + tinted
///     glass refraction — feels deliberate, not a popover.
///   - **Self-dismiss**: panel collapses back to the dot when the
///     mouse leaves; we never block the screen.
///
/// Each row shows:
///   - **Installed** version (hardcoded below in `_SdkCatalog`).
///   - **Latest** version, fetched live from npm / pub.dev by
///     [sdkLatestVersionsProvider]. Skipped entirely on fetch failure.
///   - **Update** chip in amber when installed < latest.
///
/// When a new SDK ships, bump the matching `_SdkCatalog` entry. The
/// panel will keep showing the bumped number against whatever the
/// registry says is newest.
class LibUpdateTips extends ConsumerStatefulWidget {
  const LibUpdateTips({super.key});

  @override
  ConsumerState<LibUpdateTips> createState() => _LibUpdateTipsState();
}

class _LibUpdateTipsState extends ConsumerState<LibUpdateTips> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final loc = S.of(context);
    final accent = const Color(0xFFFBBF24); // amber — advisory, never error
    // Touching the provider here also kicks off the initial fetch —
    // the StateNotifier's constructor schedules it as soon as it's
    // first watched.
    final latestVersions = ref.watch(sdkLatestVersionsProvider);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        height: _hovered ? null : 28,
        width: _hovered ? 360 : 80,
        padding: EdgeInsets.symmetric(
          horizontal: _hovered ? 14 : 11,
          vertical: _hovered ? 12 : 6,
        ),
        decoration: BoxDecoration(
          color: _hovered
              ? (isDark
                  ? const Color(0xFF1F242B).withValues(alpha: 0.96)
                  : Colors.white.withValues(alpha: 0.97))
              : (isDark
                  ? const Color(0xFF1F242B).withValues(alpha: 0.85)
                  : Colors.white.withValues(alpha: 0.92)),
          borderRadius: BorderRadius.circular(_hovered ? 14 : 14),
          // 1px border even at rest so the pill reads as a discrete
          // chip, not a smudge floating in the title bar.
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
                color: accent.withValues(alpha: isDark ? 0.18 : 0.12),
                blurRadius: 18,
                spreadRadius: -4,
                offset: const Offset(0, 6),
              )
            else
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: _hovered
            ? _ExpandedPanel(
                accent: accent,
                isDark: isDark,
                loc: loc,
                sdkList: _SdkCatalog.entries,
                latestVersions: latestVersions,
                onRetry: () =>
                    ref.read(sdkLatestVersionsProvider.notifier).refresh(),
              )
            : _CollapsedPill(accent: accent, isDark: isDark, loc: loc),
      ),
    );
  }
}

// ─── Collapsed pill (rest state) ─────────────────────────────────────

class _CollapsedPill extends StatelessWidget {
  final Color accent;
  final bool isDark;
  final S loc;

  const _CollapsedPill({
    required this.accent,
    required this.isDark,
    required this.loc,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          LucideIcons.sparkles,
          size: 12,
          color: accent,
        ),
        const SizedBox(width: 6),
        Text(
          loc.sdkTipsPill,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }
}

// ─── Expanded panel (hover state) ────────────────────────────────────

class _ExpandedPanel extends StatelessWidget {
  final Color accent;
  final bool isDark;
  final S loc;
  final List<_SdkEntry> sdkList;
  final SdkLatestVersions latestVersions;
  final VoidCallback onRetry;

  const _ExpandedPanel({
    required this.accent,
    required this.isDark,
    required this.loc,
    required this.sdkList,
    required this.latestVersions,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(LucideIcons.sparkles, size: 13, color: accent),
            const SizedBox(width: 6),
            Text(
              loc.sdkTipsHeader,
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
        // Subtitle now does the heavy lifting. It explains *why*
        // updating the libraries matters, instead of just pointing at
        // a folder.
        Text(
          loc.sdkTipsSubtitle,
          style: TextStyle(
            fontSize: 9.5,
            color: isDark ? Colors.white54 : Colors.black54,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          height: 1,
          margin: const EdgeInsets.only(bottom: 6),
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.06),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final sdk in sdkList) ...[
              _SdkRow(
                entry: sdk,
                isDark: isDark,
                loc: loc,
                accent: accent,
                status: _statusFor(sdk),
                latest: _latestFor(sdk),
                onRetry: onRetry,
              ),
              const SizedBox(height: 6),
            ],
          ],
        ),
      ],
    );
  }

  String? _latestFor(_SdkEntry e) => switch (e.platform) {
        _SdkPlatform.flutter => latestVersions.flutter,
        _SdkPlatform.reactNative => latestVersions.reactNative,
        // Android: pretend installed == latest so the row renders as
        // up-to-date. Avoids a permanent spinner on a platform we
        // don't fetch yet.
        _SdkPlatform.android => e.version,
      };

  SdkVersionFetch _statusFor(_SdkEntry e) => switch (e.platform) {
        // Android has no live fetch wired in — show the row as
        // "loaded / up-to-date" using the installed version rather
        // than a permanent loading spinner.
        _SdkPlatform.android => SdkVersionFetch.loaded,
        _ => latestVersions.fetchStateFor(e.platform == _SdkPlatform.flutter),
      };
}

// ─── SDK entry data ──────────────────────────────────────────────────

class _SdkEntry {
  final _SdkPlatform platform;
  final String name;

  /// Fallback version shown only when there's no live fetch for this
  /// platform (currently just Android — no Maven fetch wired in).
  /// For Flutter / React Native the row always renders the version
  /// returned by [sdkVersionsProvider].
  final String? version;

  /// Install hint shown under the version pill. Static copy — the
  /// command doesn't change between releases, only the version tag.
  final String note;

  const _SdkEntry({
    required this.platform,
    required this.name,
    required this.note,
    this.version,
  });
}

enum _SdkPlatform { flutter, reactNative, android }

class _SdkCatalog {
  static const List<_SdkEntry> entries = [
    _SdkEntry(
      platform: _SdkPlatform.flutter,
      name: 'devconnect_manage_kit',
      note: 'pubspec.yaml → devconnect_manage_kit: ^<version>',
    ),
    _SdkEntry(
      platform: _SdkPlatform.reactNative,
      name: 'devconnect-manage-kit',
      note: 'npm i / yarn add / pnpm add devconnect-manage-kit@<version>',
    ),
    _SdkEntry(
      platform: _SdkPlatform.android,
      name: 'com.devconnect',
      version: '1.0.0',
      note: 'implementation("com.devconnect:devconnect:1.0.0")',
    ),
  ];
}

// ─── SDK row ──────────────────────────────────────────────────────────

class _SdkRow extends StatefulWidget {
  final _SdkEntry entry;
  final bool isDark;
  final S loc;
  final Color accent;
  final String? latest;
  final SdkVersionFetch status;
  final VoidCallback onRetry;

  const _SdkRow({
    required this.entry,
    required this.isDark,
    required this.loc,
    required this.accent,
    required this.latest,
    required this.status,
    required this.onRetry,
  });

  @override
  State<_SdkRow> createState() => _SdkRowState();
}

class _SdkRowState extends State<_SdkRow>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  late final AnimationController _loadingSpin;

  @override
  void initState() {
    super.initState();
    // Perpetual rotation for the loading indicator. Keeps the panel
    // feeling "alive" while the registry fetch is in flight, so the
    // user can see this row isn't the same as the offline state.
    _loadingSpin = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _loadingSpin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.entry;
    final isDark = widget.isDark;
    final loc = widget.loc;
    final accent = widget.accent;
    final latest = widget.latest;
    final status = widget.status;

    // What the top-row version pill shows:
    //   - Android (entry has hardcoded `version`): always that version.
    //     No fetch wired in, so `latest` is null.
    //   - Flutter / RN (entry has no baseline): the fetched latest,
    //     or "—" while loading / on error.
    final pillVersion = e.version ?? latest ?? '—';
    final isLive = e.version == null;

    String platformLabel(_SdkPlatform p) {
      switch (p) {
        case _SdkPlatform.flutter:
          return loc.sdkTipsFlutter;
        case _SdkPlatform.reactNative:
          return loc.sdkTipsReactNative;
        case _SdkPlatform.android:
          return loc.sdkTipsAndroid;
      }
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: _hovered
              ? (isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.04))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.04),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: isDark ? 0.16 : 0.14),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    platformLabel(e.platform),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                      color: accent,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    e.name,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'monospace',
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    loc.sdkTipsVersionLabel(pillVersion),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'monospace',
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            // Second-line status strip. Only meaningful for live-fetched
            // platforms (Flutter / RN). Android (no fetch) gets just the
            // install note — no spinner / no retry / no Update badge,
            // since there's nothing to compare against.
            // In the "loaded" state the top-row pill already shows the
            // fetched version, so the second row is intentionally empty
            // — the install note below the row carries the rest.
            if (isLive) ...[
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(left: 2),
                child: Row(
                  children: [
                    Text(
                      '→',
                      style: TextStyle(
                        fontSize: 10,
                        fontFamily: 'monospace',
                        color: isDark ? Colors.white38 : Colors.black45,
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (status == SdkVersionFetch.loading) ...[
                      RotationTransition(
                        turns: _loadingSpin,
                        child: Icon(
                          LucideIcons.loader,
                          size: 11,
                          color: isDark ? Colors.white54 : Colors.black54,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        loc.sdkTipsChecking,
                        style: TextStyle(
                          fontSize: 9.5,
                          color: isDark ? Colors.white54 : Colors.black54,
                        ),
                      ),
                    ] else if (status == SdkVersionFetch.error) ...[
                      Icon(
                        LucideIcons.cloudOff,
                        size: 11,
                        color: isDark ? Colors.white38 : Colors.black45,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        loc.sdkTipsOffline,
                        style: TextStyle(
                          fontSize: 9.5,
                          color: isDark ? Colors.white38 : Colors.black45,
                        ),
                      ),
                      const SizedBox(width: 6),
                      _RetryChip(
                        label: loc.sdkTipsRetry,
                        isDark: isDark,
                        onTap: widget.onRetry,
                      ),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 2),
              child: Text(
                e.note,
                style: TextStyle(
                  fontSize: 9.5,
                  fontFamily: 'monospace',
                  color: isDark ? Colors.white38 : Colors.black45,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact pill button shown next to the "Live check unavailable"
/// caption on the offline row. Click → `onTap`, which the parent
/// wires to `sdkLatestVersionsProvider.notifier.refresh()`.
///
/// Visually a tiny ghost chip: muted text on a tinted glass surface,
/// 1px inner border for the "liquid glass" refraction feel. Slight
/// scale-down on press for tactile feedback (skill rule: physical
/// push indicating success/action).
class _RetryChip extends StatefulWidget {
  final String label;
  final bool isDark;
  final VoidCallback onTap;

  const _RetryChip({
    required this.label,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_RetryChip> createState() => _RetryChipState();
}

class _RetryChipState extends State<_RetryChip> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.08),
              width: 0.7,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                LucideIcons.refreshCw,
                size: 9,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
              const SizedBox(width: 4),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}