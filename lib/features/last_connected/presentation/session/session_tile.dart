import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../models/disconnected_session.dart';
import 'count_chip.dart';

class SessionTile extends StatelessWidget {
  final DisconnectedSession session;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const SessionTile({
    super.key,
    required this.session,
    required this.isSelected,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final d = session.deviceInfo;
    final time = DateFormat('HH:mm:ss').format(session.disconnectedAt);
    final platColor = _platformColor(d.platform);

    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? ColorTokens.selectedBg(
                    Theme.of(context).brightness == Brightness.dark,
                  )
                : null,
            border: Border(
              bottom: BorderSide(
                color: theme.dividerColor.withValues(alpha: 0.3),
                width: 0.5,
              ),
              left: BorderSide(
                color: isSelected ? ColorTokens.selectedAccent : platColor,
                width: isSelected ? 3 : 2,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Platform badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: platColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _platformLabel(d.platform),
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: platColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      d.appName,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Remove button
                  GestureDetector(
                    onTap: onRemove,
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Icon(
                        LucideIcons.x,
                        size: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(LucideIcons.clock, size: 10, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    'Disconnected $time',
                    style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                  ),
                  const Spacer(),
                  Text(
                    d.deviceName != d.osVersion
                        ? '${d.deviceName} · ${d.osVersion}'
                        : d.osVersion,
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.grey[500],
                      fontFamily: AppConstants.monoFontFamily,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Event counts
              Row(
                children: [
                  CountChip(
                    LucideIcons.terminal,
                    session.logs.length,
                    ColorTokens.logInfo,
                  ),
                  const SizedBox(width: 6),
                  CountChip(
                    LucideIcons.globe,
                    session.networkEntries.length,
                    ColorTokens.success,
                  ),
                  const SizedBox(width: 6),
                  CountChip(
                    LucideIcons.layers,
                    session.stateChanges.length,
                    ColorTokens.secondary,
                  ),
                  const SizedBox(width: 6),
                  CountChip(
                    LucideIcons.database,
                    session.storageEntries.length,
                    ColorTokens.warning,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Color _platformColor(String platform) {
  switch (platform.toLowerCase()) {
    case 'flutter':
      return const Color(0xFF02569B);
    case 'react_native':
    case 'reactnative':
      return const Color(0xFF61DAFB);
    case 'android':
      return const Color(0xFF3DDC84);
    default:
      return Colors.grey;
  }
}

String _platformLabel(String platform) {
  switch (platform.toLowerCase()) {
    case 'flutter':
      return 'FLUTTER';
    case 'react_native':
    case 'reactnative':
      return 'RN';
    case 'android':
      return 'ANDROID';
    default:
      return platform.toUpperCase();
  }
}
