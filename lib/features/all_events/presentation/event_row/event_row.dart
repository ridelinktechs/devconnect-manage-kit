import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../components/misc/service_tag.dart';
import '../../../../components/misc/status_badge.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/utils/duration_format.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/display/display_entry.dart';
import '../../../../models/network/network_entry.dart';
import '../../provider/all_events_provider.dart';
import '../buttons/mini_icon_button.dart';
import '../shared/type_info.dart';

/// One row in the All Events list. Visual states:
///
/// - **selected** — accent left border (3px), tinted background
/// - **network in flight** — amber left bar + warning-tinted background
/// - **network error** — red left bar + error-tinted background
/// - **default** — neutral 2px left bar in the type's accent color
class EventRow extends StatelessWidget {
  final UnifiedEvent event;
  final bool isSelected;
  final bool showDetail;
  final String? platform;
  final VoidCallback onTap;
  final VoidCallback onCopyTitle;

  const EventRow({
    super.key,
    required this.event,
    required this.isSelected,
    required this.showDetail,
    this.platform,
    required this.onTap,
    required this.onCopyTitle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final time = DateFormat('HH:mm:ss.SSS').format(
      DateTime.fromMillisecondsSinceEpoch(event.timestamp),
    );

    final typeInfo = typeInfoFor(event);

    // Left bar color: for network, show status-based color
    Color leftBarColor = typeInfo.color;
    if (event.type == EventType.network && event.rawData is NetworkEntry) {
      final netEntry = event.rawData as NetworkEntry;
      if (!netEntry.isComplete) {
        leftBarColor = ColorTokens.warning;
      } else if (netEntry.statusCode <= 0 || netEntry.statusCode >= 400) {
        leftBarColor = ColorTokens.error;
      } else {
        leftBarColor = ColorTokens.success;
      }
    }

    // Status-based background for network requests
    final isNetworkError = event.type == EventType.network &&
        event.rawData is NetworkEntry &&
        (event.rawData as NetworkEntry).isComplete &&
        ((event.rawData as NetworkEntry).statusCode <= 0 ||
            (event.rawData as NetworkEntry).statusCode >= 400);
    final isNetworkInProgress = event.type == EventType.network &&
        event.rawData is NetworkEntry &&
        !(event.rawData as NetworkEntry).isComplete;

    final bgColor = isSelected
        ? ColorTokens.selectedBg(isDark)
        : isNetworkError
            ? ColorTokens.error.withValues(alpha: isDark ? 0.08 : 0.05)
            : isNetworkInProgress
                ? ColorTokens.warning.withValues(alpha: isDark ? 0.08 : 0.05)
                : isDark
                    ? Colors.transparent
                    : Colors.white;

    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: bgColor,
            border: Border(
              bottom: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.03)
                    : Colors.black.withValues(alpha: 0.04),
              ),
              left: BorderSide(
                color: isSelected ? ColorTokens.selectedAccent : leftBarColor,
                width: isSelected ? 3 : 2,
              ),
            ),
          ),
          child: Row(
            children: [
              // Time
              SizedBox(
                width: 84,
                child: Text(
                  time,
                  style: TextStyle(
                    fontFamily: AppConstants.monoFontFamily,
                    fontSize: 10,
                    color: Colors.grey[500],
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              // Type badge
              Container(
                width: 56,
                height: 22,
                decoration: BoxDecoration(
                  color: typeInfo.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(typeInfo.icon, size: 10, color: typeInfo.color),
                    const SizedBox(width: 3),
                    Text(
                      typeInfo.label,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: typeInfo.color,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
              // Via badge (fetch / xhr) — only for network events that
              // reported which interceptor path handled the call.
              if (event.type == EventType.network &&
                  event.rawData is NetworkEntry) ...[
                _ViaBadge(
                    via: (event.rawData as NetworkEntry).via),
                const SizedBox(width: 4),
              ],
              const SizedBox(width: 8),
              // Platform badge
              if (platform != null) ...[
                PlatformBadge(platform: platform!),
                const SizedBox(width: 8),
              ],
              // Title
              Expanded(
                child: Tooltip(
                  message: _tooltipFor(event),
                  waitDuration: const Duration(milliseconds: 300),
                  child: Text(
                    event.title,
                    style: TextStyle(
                      fontFamily: AppConstants.monoFontFamily,
                      fontSize: 12,
                      color: event.level == 'error'
                          ? ColorTokens.error
                          : isDark
                              ? ColorTokens.lightBackground
                              : ColorTokens.darkNeutral,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (event.type == EventType.network &&
                  event.rawData is NetworkEntry &&
                  (event.rawData as NetworkEntry).serviceName != null) ...[
                ServiceTag(
                    name: (event.rawData as NetworkEntry).serviceName!),
                const SizedBox(width: 6),
              ],
              // Subtitle / Status indicator
              if (!showDetail) ...[
                if (event.type == EventType.network &&
                    event.rawData is NetworkEntry) ...[
                  if (!(event.rawData as NetworkEntry).isComplete) ...[
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: ColorTokens.warning,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      S.of(context).inProgress,
                      style: TextStyle(
                        fontSize: 10,
                        color: ColorTokens.warning,
                        fontFamily: AppConstants.monoFontFamily,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ] else ...[
                    StatusBadge(
                        statusCode:
                            (event.rawData as NetworkEntry).statusCode),
                    const SizedBox(width: 6),
                    if ((event.rawData as NetworkEntry).duration != null)
                      Text(
                        formatDuration(
                            (event.rawData as NetworkEntry).duration!),
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[500],
                          fontFamily: AppConstants.monoFontFamily,
                        ),
                      ),
                  ],
                ] else
                  Text(
                    event.subtitle,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[500],
                      fontFamily: AppConstants.monoFontFamily,
                    ),
                  ),
              ],
              // Copy button (only visible on hover would be ideal,
              // but for desktop quick-access is better)
              const SizedBox(width: 4),
              MiniIconButton(
                icon: LucideIcons.copy,
                tooltip: 'Copy',
                onTap: onCopyTitle,
              ),
              if (isSelected) ...[
                const SizedBox(width: 2),
                Icon(LucideIcons.chevronRight,
                    size: 12, color: ColorTokens.primary),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Per-event-type metadata shared by the row's type badge and the
  /// filter chip. Centralised so the two stay in lock-step visually.
  static TypeInfo typeInfoFor(UnifiedEvent event) {
    switch (event.type) {
      case EventType.log:
        return TypeInfo(
          color: _logColor(event.level),
          icon: LucideIcons.terminal,
          label: event.level.toUpperCase(),
        );
      case EventType.network:
        return TypeInfo(
          color: event.level == 'error'
              ? ColorTokens.error
              : ColorTokens.success,
          icon: LucideIcons.globe,
          label: 'API',
        );
      case EventType.state:
        return TypeInfo(
          color: ColorTokens.secondary,
          icon: LucideIcons.layers,
          label: 'STATE',
        );
      case EventType.storage:
        return TypeInfo(
          color: ColorTokens.warning,
          icon: LucideIcons.database,
          label: 'STORE',
        );
      case EventType.display:
        return TypeInfo(
          color: const Color(0xFF9B59B6),
          icon: LucideIcons.monitor,
          label: 'DISPLAY',
        );
      case EventType.asyncOp:
        return TypeInfo(
          color: const Color(0xFFE67E22),
          icon: LucideIcons.zap,
          label: event.rawData is AsyncOperationEntry
              ? (event.rawData as AsyncOperationEntry).status.name.toUpperCase()
              : 'ASYNC',
        );
      case EventType.error:
        return TypeInfo(
          color: Colors.red,
          icon: LucideIcons.alertTriangle,
          label: 'ERROR',
        );
    }
  }

  static Color _logColor(String level) {
    switch (level) {
      case 'debug':
        return ColorTokens.logDebug;
      case 'warn':
        return ColorTokens.logWarn;
      case 'error':
        return ColorTokens.logError;
      default:
        return ColorTokens.logInfo;
    }
  }

  /// Tooltip text shown on hover of the row title. For network events
  /// the user sees the full URL (URI-decoded so `%2C` becomes `,` etc.);
  /// for other event types the title itself is informative enough.
  static String _tooltipFor(UnifiedEvent event) {
    if (event.type == EventType.network &&
        event.rawData is NetworkEntry) {
      final raw = (event.rawData as NetworkEntry).url;
      try {
        return Uri.decodeFull(raw);
      } catch (_) {
        return raw;
      }
    }
    return event.title;
  }
}

/// Compact pill rendered next to the type badge on network event rows.
/// Shows `FETCH` / `XHR` so the user can see which interceptor path
/// reported the call. Hidden when `via` is unknown (older clients or
/// other platforms).
class _ViaBadge extends StatelessWidget {
  final String via;

  const _ViaBadge({required this.via});

  @override
  Widget build(BuildContext context) {
    Color? color;
    String? label;
    switch (via) {
      case NetworkVia.fetch:
        color = ColorTokens.info;
        label = 'FETCH';
        break;
      case NetworkVia.xhr:
        color = ColorTokens.warning;
        label = 'XHR';
        break;
    }
    if (label == null) return const SizedBox.shrink();

    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color!.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: AppConstants.monoFontFamily,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}