import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../components/misc/service_tag.dart';
import '../../../../components/misc/status_badge.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/utils/duration_format.dart';
import '../../../../core/utils/network_url_formatter.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../server/providers/server_providers.dart';
import '../../../../models/network/network_entry.dart';

/// One row in the Network Inspector's request list.
///
/// Visual states:
/// - **selected** — primary-tinted background + selected-border
/// - **error** — error-tinted background + error border
/// - **in-flight** — warning-tinted background + warning border
/// - **default** — surface background, neutral border
///
/// Left bar color reflects status: pending (info), error (error),
/// success (success), redirect (warning).
class RequestCard extends ConsumerWidget {
  final NetworkEntry entry;
  final bool isSelected;
  final VoidCallback onTap;

  const RequestCard({
    super.key,
    required this.entry,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final time = DateFormat('HH:mm:ss.SSS').format(
      DateTime.fromMillisecondsSinceEpoch(entry.startTime),
    );

    final devices = ref.watch(connectedDevicesProvider);
    final device =
        devices.where((d) => d.deviceId == entry.deviceId).firstOrNull;

    // Parse URL
    Uri? uri;
    try {
      uri = Uri.parse(entry.url);
    } catch (_) {}
    final path = uri?.path ?? entry.url;
    // Prefix scheme so the user can read the request at a glance —
    // matches what curl-style tooling shows.
    final host = uri == null
        ? ''
        : '${uri.scheme.isEmpty ? 'https' : uri.scheme}://${uri.host}';
    // Card title is the path (compact) — the full scheme+host lives
    // in the badge row below, so we don't repeat it on the title.
    final displayUrl = path;
    final formatted = parseFormattedUrl(entry.url);
    final isRootPath = path == '/' || path.isEmpty;
    final titleText = (entry.serviceAction != null && isRootPath)
        ? entry.serviceAction!
        : displayUrl;
    // Compact query hint for the second line of the title block. Empty when
    // the URL has no query string — the row stays a single line in that case.
    final queryHint = formatted == null || formatted.queryParams.isEmpty
        ? null
        : formatted.queryParams
            .take(2)
            .map((p) => p.value.isEmpty ? p.key : '${p.key}=${p.value}')
            .join(', ') +
            (formatted.queryParams.length > 2
                ? ' + ${formatted.queryParams.length - 2}'
                : '');

    // Left bar color based on status code
    final Color leftBarColor;
    if (!entry.isComplete) {
      leftBarColor = ColorTokens.info;
    } else if (entry.statusCode <= 0 || entry.statusCode >= 400) {
      leftBarColor = ColorTokens.error;
    } else if (entry.statusCode < 300) {
      leftBarColor = ColorTokens.success;
    } else {
      leftBarColor = ColorTokens.warning;
    }

    // Source badge color
    Color sourceColor;
    String sourceLabel;
    switch (entry.source) {
      case 'library':
        sourceColor = ColorTokens.warning;
        sourceLabel = 'LIB';
        break;
      case 'system':
        sourceColor = Colors.grey;
        sourceLabel = 'SYS';
        break;
      default:
        sourceColor = ColorTokens.primary;
        sourceLabel = 'APP';
    }

    // Via badge (fetch / xhr) — distinguishes which interceptor path
    // reported this entry. Hidden when unknown (older clients / other
    // platforms).
    Color? viaColor;
    String? viaLabel;
    switch (entry.via) {
      case NetworkVia.fetch:
        viaColor = ColorTokens.info;
        viaLabel = 'FETCH';
        break;
      case NetworkVia.xhr:
        viaColor = ColorTokens.warning;
        viaLabel = 'XHR';
        break;
    }

    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: isSelected
                  ? ColorTokens.selectedBg(isDark)
                  : (entry.isComplete && (entry.statusCode <= 0 || entry.statusCode >= 400))
                      ? ColorTokens.error.withValues(alpha: isDark ? 0.08 : 0.05)
                      : !entry.isComplete
                          ? ColorTokens.warning.withValues(alpha: isDark ? 0.08 : 0.05)
                          : isDark
                              ? ColorTokens.darkBackground
                              : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? ColorTokens.selectedBorder(isDark)
                    : (entry.isComplete && (entry.statusCode <= 0 || entry.statusCode >= 400))
                        ? ColorTokens.error.withValues(alpha: isDark ? 0.25 : 0.2)
                        : !entry.isComplete
                            ? ColorTokens.warning.withValues(alpha: isDark ? 0.2 : 0.15)
                            : isDark
                                ? const Color(0xFF30363D)
                                : const Color(0xFFE1E4E8),
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                children: [
                  // Left color bar
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: 4,
                    child: Container(
                      color: leftBarColor,
                    ),
                  ),

                  // Content
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
                    child: Row(
                      children: [
                        // Badges row (compact)
                        if (device != null) ...[
                          PlatformBadge(platform: device.platform),
                          const SizedBox(width: 4),
                        ],
                        HttpMethodBadge(method: entry.method),
                        const SizedBox(width: 4),
                        // URL + host
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                titleText,
                                style: TextStyle(
                                  fontFamily: AppConstants.monoFontFamily,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: (entry.isComplete && (entry.statusCode <= 0 || entry.statusCode >= 400))
                                      ? ColorTokens.error
                                      : isDark
                                          ? ColorTokens.lightBackground
                                          : ColorTokens.darkNeutral,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (queryHint != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  '? $queryHint',
                                  style: TextStyle(
                                    fontFamily: AppConstants.monoFontFamily,
                                    fontSize: 10,
                                    color: Colors.grey[500],
                                    fontStyle: FontStyle.italic,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  if (entry.serviceName != null) ...[
                                    ServiceTag(name: entry.serviceName!),
                                    const SizedBox(width: 4),
                                  ],
                                  // Source badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: sourceColor.withValues(alpha: 0.10),
                                      border: Border.all(
                                        color: sourceColor.withValues(alpha: 0.22),
                                        width: 1,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      sourceLabel,
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: sourceColor,
                                        letterSpacing: 0.3,
                                        fontFamily: AppConstants.monoFontFamily,
                                      ),
                                    ),
                                  ),
                                  // Via badge (fetch / xhr path) — same
                                  // chrome as source badge so the two
                                  // read as siblings.
                                  if (viaLabel != null) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: viaColor!.withValues(alpha: 0.10),
                                        border: Border.all(
                                          color: viaColor.withValues(alpha: 0.22),
                                          width: 1,
                                        ),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        viaLabel,
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                          color: viaColor,
                                          letterSpacing: 0.3,
                                          fontFamily: AppConstants.monoFontFamily,
                                        ),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(width: 4),
                                  if (entry.isComplete)
                                    StatusBadge(statusCode: entry.statusCode)
                                  else ...[
                                    SizedBox(
                                      width: 10,
                                      height: 10,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 1.5,
                                        color: ColorTokens.warning,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      S.of(context).inProgress,
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: ColorTokens.warning,
                                        fontFamily: AppConstants.monoFontFamily,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                  if (host.isNotEmpty) ...[
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        host,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey[500],
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 8),

                        // Duration + timestamp
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (entry.duration != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _durationColor(entry.duration!)
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  formatDuration(entry.duration!),
                                  style: TextStyle(
                                    fontFamily: AppConstants.monoFontFamily,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: _durationColor(entry.duration!),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 4),
                            Text(
                              time,
                              style: TextStyle(
                                fontFamily: AppConstants.monoFontFamily,
                                fontSize: 10,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
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

  Color _durationColor(int ms) {
    if (ms < 200) return ColorTokens.success;
    if (ms < 500) return ColorTokens.warning;
    return ColorTokens.error;
  }
}