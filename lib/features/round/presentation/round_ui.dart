import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/color_tokens.dart';

/// Shared widget library for the Round pages (mock server + layout
/// inspector). Keeps the chrome consistent across both: same toolbar
/// height, same row height, same selection treatment, same corner
/// radii. Internal use — not exported from the package.

const double _barHeight = 44;
const double _rowHeight = 40;
const double _rButton = 6;
const double _rPanel = 8;
const double _rChip = 4;

final _hhmmss = DateFormat('HH:mm:ss');

String formatHmSs(int millis) =>
    _hhmmss.format(DateTime.fromMillisecondsSinceEpoch(millis));

String formatHmSsMs(int millis) =>
    DateFormat('HH:mm:ss.SSS').format(DateTime.fromMillisecondsSinceEpoch(millis));

void showCopiedToast(BuildContext context, {String? label}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(label ?? 'Copied'),
      duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

// ============================================================
// PageBar — top toolbar with title + count + actions
// ============================================================

class PageBar extends StatelessWidget {
  final IconData icon;
  final String title;
  final int? count;
  final String? countLabel;
  final List<Widget> actions;

  const PageBar({
    super.key,
    required this.icon,
    required this.title,
    this.count,
    this.countLabel,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: _barHeight,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: ColorTokens.hairline(context), width: 1),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          if (count != null) ...[
            const SizedBox(width: 6),
            Text(
              '${countLabel ?? ''} $count'.trim(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
          const Spacer(),
          for (final a in actions) ...[
            const SizedBox(width: 6),
            a,
          ],
        ],
      ),
    );
  }
}

// ============================================================
// ActionButton — toolbar button with 3 styles
// ============================================================

enum ActionStyle { primary, ghost, danger }

class ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool loading;
  final ActionStyle style;

  const ActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.loading = false,
    this.style = ActionStyle.ghost,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final disabled = onTap == null || loading;

    Color bg;
    Color fg;
    switch (style) {
      case ActionStyle.primary:
        bg = theme.colorScheme.primary;
        fg = theme.colorScheme.onPrimary;
        break;
      case ActionStyle.danger:
        bg = ColorTokens.error;
        fg = Colors.white;
        break;
      case ActionStyle.ghost:
        bg = theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6);
        fg = theme.colorScheme.onSurfaceVariant;
        break;
    }
    if (disabled) {
      bg = bg.withValues(alpha: 0.5);
      fg = fg.withValues(alpha: 0.7);
    }

    return InkWell(
      onTap: disabled ? null : onTap,
      borderRadius: BorderRadius.circular(_rButton),
      child: Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(_rButton),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (loading)
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  valueColor: AlwaysStoppedAnimation(fg),
                ),
              )
            else
              Icon(icon, size: 12, color: fg),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: fg,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// ListHeader — section title above a list
// ============================================================

class ListHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const ListHeader({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: ColorTokens.hairline(context), width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

// ============================================================
// ListRow — selectable list item with leading + trailing
// ============================================================

class ListRow extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;
  final Widget? leading;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onAuxTap;

  const ListRow({
    super.key,
    required this.selected,
    required this.onTap,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onAuxTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      onSecondaryTap: onAuxTap,
      child: Container(
        height: _rowHeight,
        decoration: BoxDecoration(
          color: selected
              ? ColorTokens.selectedBg(isDark)
              : Colors.transparent,
          border: Border(
            bottom:
                BorderSide(color: ColorTokens.hairline(context), width: 0.5),
            left: BorderSide(
              color: selected
                  ? ColorTokens.selectedAccent
                  : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DefaultTextStyle.merge(
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                    child: title,
                  ),
                  if (subtitle != null)
                    DefaultTextStyle.merge(
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      child: subtitle!,
                    ),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

// ============================================================
// MethodBadge — compact HTTP-method chip
// ============================================================

class MethodBadge extends StatelessWidget {
  final String method;
  const MethodBadge(this.method, {super.key});

  @override
  Widget build(BuildContext context) {
    final color = ColorTokens.httpMethodColor(method);
    return Container(
      width: 48,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(_rChip),
      ),
      alignment: Alignment.center,
      child: Text(
        method.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          fontFamily: 'monospace',
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ============================================================
// MetricChip — labeled pill for headers / metadata
// ============================================================

class MetricChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const MetricChip({
    super.key,
    required this.label,
    required this.value,
    this.color = Colors.grey,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(_rChip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 10,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// DetailHeader — header above detail pane
// ============================================================

class DetailHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> meta;
  final Widget? trailing;

  const DetailHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.meta = const [],
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom:
              BorderSide(color: ColorTokens.hairline(context), width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle?.isNotEmpty ?? false)
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontFamily: 'monospace',
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing!,
              ],
            ],
          ),
          if (meta.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(spacing: 6, runSpacing: 4, children: meta),
          ],
        ],
      ),
    );
  }
}

// ============================================================
// CodePanel — monospace code block
// ============================================================

class CodePanel extends StatelessWidget {
  final String code;
  final VoidCallback? onCopy;
  const CodePanel({super.key, required this.code, this.onCopy});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(_rPanel),
        border: Border.all(color: ColorTokens.hairline(context)),
      ),
      padding: const EdgeInsets.all(10),
      child: Stack(
        children: [
          SelectableText(
            code,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 11.5,
              height: 1.4,
            ),
          ),
          if (onCopy != null)
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                icon: const Icon(LucideIcons.copy, size: 12),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: code));
                  showCopiedToast(context);
                },
                visualDensity: VisualDensity.compact,
                tooltip: 'Copy',
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================
// DirectionBadge — Request/Response pill
// ============================================================

class DirectionBadge extends StatelessWidget {
  final String text; // e.g. "→" or "REQ" or "RES"
  final Color color;
  const DirectionBadge(this.text,
      {super.key, this.color = Colors.grey});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(_rChip),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}
