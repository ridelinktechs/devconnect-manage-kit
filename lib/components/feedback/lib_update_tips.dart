import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
/// Versions mirror what `client_sdks/<sdk>/...` currently ships.
/// When you bump a version there, bump the same number in
/// `_SdkCatalog` below.
class LibUpdateTips extends StatefulWidget {
  const LibUpdateTips({super.key});

  @override
  State<LibUpdateTips> createState() => _LibUpdateTipsState();
}

class _LibUpdateTipsState extends State<LibUpdateTips> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final loc = S.of(context);
    final accent = const Color(0xFFFBBF24); // amber — advisory, never error

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        height: _hovered ? null : 28,
        width: _hovered ? 340 : 80,
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

  const _ExpandedPanel({
    required this.accent,
    required this.isDark,
    required this.loc,
    required this.sdkList,
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
              _SdkRow(entry: sdk, isDark: isDark, loc: loc),
              const SizedBox(height: 6),
            ],
          ],
        ),
      ],
    );
  }
}

// ─── SDK entry data ──────────────────────────────────────────────────

class _SdkEntry {
  final _SdkPlatform platform;
  final String name;
  final String version;
  final String note;

  const _SdkEntry({
    required this.platform,
    required this.name,
    required this.version,
    required this.note,
  });
}

enum _SdkPlatform { flutter, reactNative, android }

class _SdkCatalog {
  static const List<_SdkEntry> entries = [
    _SdkEntry(
      platform: _SdkPlatform.flutter,
      name: 'devconnect_manage_kit',
      version: '1.0.4',
      note: 'pubspec.yaml → devconnect_manage_kit: ^1.0.4',
    ),
    _SdkEntry(
      platform: _SdkPlatform.reactNative,
      name: 'devconnect-manage-kit',
      version: '1.0.5',
      note: 'npm i / yarn add / pnpm add devconnect-manage-kit@1.0.5',
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

  const _SdkRow({
    required this.entry,
    required this.isDark,
    required this.loc,
  });

  @override
  State<_SdkRow> createState() => _SdkRowState();
}

class _SdkRowState extends State<_SdkRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final e = widget.entry;
    final isDark = widget.isDark;
    final loc = widget.loc;
    const accent = Color(0xFFFBBF24);

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
                    loc.sdkTipsVersionLabel(e.version),
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