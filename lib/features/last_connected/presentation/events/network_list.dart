import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../components/feedback/empty_state.dart';
import '../../../../components/misc/status_badge.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/utils/format/duration_format.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../models/network/network_entry.dart';

class NetworkList extends StatelessWidget {
  final List<NetworkEntry> entries;
  final ScrollController? controller;

  const NetworkList({super.key, required this.entries, this.controller});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return EmptyState(
        icon: LucideIcons.globe,
        title: S.of(context).noNetworkRequests,
      );
    }
    return ListView.builder(
      controller: controller,
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final e = entries[entries.length - 1 - index];
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final time = DateFormat(
          'HH:mm:ss.SSS',
        ).format(DateTime.fromMillisecondsSinceEpoch(e.startTime));

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : Colors.black.withValues(alpha: 0.05),
              ),
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 80,
                child: Text(
                  time,
                  style: TextStyle(
                    fontFamily: AppConstants.monoFontFamily,
                    fontSize: 9,
                    color: Colors.grey[500],
                  ),
                ),
              ),
              HttpMethodBadge(method: e.method),
              const SizedBox(width: 6),
              if (e.isComplete)
                StatusBadge(statusCode: e.statusCode)
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: ColorTokens.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '...',
                    style: TextStyle(fontSize: 10, color: ColorTokens.warning),
                  ),
                ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  e.url,
                  style: TextStyle(
                    fontFamily: AppConstants.monoFontFamily,
                    fontSize: 11,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (e.duration != null) ...[
                const SizedBox(width: 8),
                Text(
                  formatDuration(e.duration!),
                  style: TextStyle(
                    fontFamily: AppConstants.monoFontFamily,
                    fontSize: 10,
                    color: e.duration! < 200
                        ? ColorTokens.success
                        : e.duration! < 500
                        ? ColorTokens.warning
                        : ColorTokens.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
