// Lucian UX/UI Prompt #072 · MIT License (c) 2026 Seokwoooo · https://lucianlabs.dev/uxui-prompt/#072
// Lucian UX/UI Prompt #227 · MIT License (c) 2026 Seokwoooo · https://lucianlabs.dev/uxui-prompt/#227
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/chrome_palette.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/utils/format/log_message_summary.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../models/log/log_entry.dart';
import '../shared/level_color.dart';

final _time = DateFormat('HH:mm:ss.SSS');

/// One log in the Console list, as its own card in the manner of Lucian
/// #072's alert rows: a 3px bar in the level's color, then a row of labels —
/// the level, the platform with the app and device, the tag — with the time
/// on the right, and the message below. Warnings and errors sit on a wash of
/// their color; a log that just arrived glows for a moment like the new
/// orders of Lucian #227.
class LogEntryContent extends StatefulWidget {
  final LogEntry entry;
  final String? platform;

  /// "App · device" the log came from, when that device is known.
  final String? source;

  /// The identical logs in a row this one stands for, oldest first; empty
  /// when it stands for itself only.
  final List<LogEntry> run;

  /// Whether the log just arrived, so it glows.
  final bool fresh;

  /// The id of the picked log, if any.
  final ValueListenable<String?>? selection;

  const LogEntryContent({
    super.key,
    required this.entry,
    this.platform,
    this.source,
    this.run = const [],
    this.fresh = false,
    this.selection,
  });

  @override
  State<LogEntryContent> createState() => _LogEntryContentState();
}

class _LogEntryContentState extends State<LogEntryContent> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final p = ChromePalette.of(context);
    final entry = widget.entry;
    final level = entry.level;
    final ink = levelInk(level, isDark: p.isDark);
    final tint = levelColor(level);
    final accent = p.isDark ? ColorTokens.primaryLight : ColorTokens.primary;
    final loud = level == LogLevel.warn || level == LogLevel.error;

    final body = Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 12, 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 20,
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      _Label(
                        icon: levelIcon(level),
                        text: level.name.toUpperCase(),
                        color: ink,
                        fill: tint.withValues(alpha: p.isDark ? 0.16 : 0.12),
                      ),
                      if (widget.platform case final platform?) ...[
                        const SizedBox(width: 6),
                        Flexible(
                          child: _SourceLabel(
                            platform: platform,
                            source: widget.source,
                          ),
                        ),
                      ],
                      if (entry.tag case final tag?) ...[
                        const SizedBox(width: 6),
                        Flexible(
                          child: _Label(
                            text: tag,
                            color: p.textMuted,
                            fill: p.selected,
                            edge: p.border.withValues(alpha: 0.6),
                            mono: true,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                if (widget.run.length > 1) ...[
                  _RepeatCount(run: widget.run),
                  const SizedBox(width: 10),
                ],
                Text(
                  _time.format(
                    DateTime.fromMillisecondsSinceEpoch(entry.timestamp),
                  ),
                  style: chromeMono(context, size: 11, color: p.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            summarizeLogMessage(entry.message),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: chromeMono(
              context,
              size: 12.5,
              color: level == LogLevel.debug ? p.textMuted : p.text,
            ),
          ),
        ],
      ),
    );

    Widget frame(String? picked) {
      final on = picked == entry.id;
      var fill = loud
          ? Color.alphaBlend(
              tint.withValues(alpha: p.isDark ? 0.07 : 0.05),
              p.surface,
            )
          : p.surface;
      if (_hover) fill = Color.alphaBlend(p.hover, fill);
      if (on) {
        fill = Color.alphaBlend(
          accent.withValues(alpha: p.isDark ? 0.12 : 0.08),
          fill,
        );
      }
      final edge = on
          ? accent.withValues(alpha: 0.75)
          : _hover
          ? p.textMuted.withValues(alpha: 0.5)
          : loud
          ? tint.withValues(alpha: 0.35)
          : p.border;
      return TweenAnimationBuilder<double>(
        tween: Tween(begin: widget.fresh ? 1 : 0, end: 0),
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 1400),
        curve: Curves.ease,
        builder: (context, glow, child) => AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Color.alphaBlend(
              accent.withValues(alpha: 0.22 * glow),
              fill,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: edge),
          ),
          child: child,
        ),
        child: Stack(
          children: [
            Positioned.fill(child: body),
            Positioned(
              left: 0,
              top: 10,
              bottom: 10,
              width: 3,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: tint,
                  borderRadius: const BorderRadius.horizontal(
                    right: Radius.circular(3),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final selection = widget.selection;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: selection == null
          ? frame(null)
          : ValueListenableBuilder<String?>(
              valueListenable: selection,
              builder: (context, picked, _) => frame(picked),
            ),
    );
  }
}

/// A 20px rounded label: an optional glyph and a short text.
class _Label extends StatelessWidget {
  final IconData? icon;
  final String text;
  final Color color;
  final Color fill;
  final Color? edge;
  final bool mono;

  const _Label({
    this.icon,
    required this.text,
    required this.color,
    required this.fill,
    this.edge,
    this.mono = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: 7),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(6),
        border: edge == null ? null : Border.all(color: edge!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: mono
                  ? chromeMono(
                      context,
                      size: 10.5,
                      color: color,
                      weight: FontWeight.w600,
                    )
                  : DefaultTextStyle.of(context).style.copyWith(
                      fontSize: 10.5,
                      height: 1.4,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                      color: color,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Where the log came from: the platform by name in its brand color, then
/// the app and device.
class _SourceLabel extends StatelessWidget {
  final String platform;
  final String? source;

  const _SourceLabel({required this.platform, this.source});

  @override
  Widget build(BuildContext context) {
    final p = ChromePalette.of(context);
    final (icon, brand) = platformLook(platform, isDark: p.isDark);
    final base = DefaultTextStyle.of(
      context,
    ).style.copyWith(fontSize: 10.5, height: 1.4);
    return Container(
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: 7),
      decoration: BoxDecoration(
        color: p.selected,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: p.border.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: brand),
          const SizedBox(width: 4),
          Text(switch (platform) {
            'react_native' => 'RN',
            'flutter' => 'Flutter',
            'android' => 'Android',
            _ => platform,
          }, style: base.copyWith(fontWeight: FontWeight.w800, color: brand)),
          if (source case final source?) ...[
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                source,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: base.copyWith(
                  fontWeight: FontWeight.w600,
                  color: p.textMuted,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// How many times a folded log ran, as a pill; the tooltip says from when
/// to when.
class _RepeatCount extends StatelessWidget {
  final List<LogEntry> run;

  const _RepeatCount({required this.run});

  @override
  Widget build(BuildContext context) {
    final p = ChromePalette.of(context);
    String at(LogEntry e) =>
        _time.format(DateTime.fromMillisecondsSinceEpoch(e.timestamp));
    return Tooltip(
      message:
          '${S.of(context).consoleOccurrences}: ${run.length} · '
          '${at(run.first)} → ${at(run.last)}',
      child: Container(
        height: 20,
        padding: const EdgeInsets.symmetric(horizontal: 7),
        decoration: BoxDecoration(
          color: p.selected,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: p.border.withValues(alpha: 0.6)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.repeat2, size: 10, color: p.textMuted),
            const SizedBox(width: 3),
            Text(
              '${run.length}',
              style: chromeMono(
                context,
                size: 10.5,
                color: p.text,
                weight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
