import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../shared/status_chip.dart';

/// Top header of the Settings page. Renders the gradient settings
/// logo + app title/version + two [StatusChip]s (server running /
/// device count). Uses dynamic `server` and `int deviceCount` to stay
/// decoupled from the concrete server/device models.
class PageHeader extends StatelessWidget {
  final dynamic server;
  final int deviceCount;

  const PageHeader({super.key, required this.server, required this.deviceCount});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6C5CE7), Color(0xFF8B7EF0)],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(LucideIcons.settings, size: 18, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              S.of(context).settings,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            Text(
              '${AppConstants.appName} v${AppConstants.appVersion}',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
        const Spacer(),
        StatusChip(
          color: server.isRunning ? ColorTokens.success : ColorTokens.error,
          label: server.isRunning ? S.of(context).serverRunning : S.of(context).serverStopped,
          icon: server.isRunning ? LucideIcons.wifi : LucideIcons.wifiOff,
        ),
        const SizedBox(width: 8),
        StatusChip(
          color: deviceCount > 0 ? ColorTokens.info : Colors.grey,
          label: '$deviceCount device${deviceCount != 1 ? 's' : ''}',
          icon: LucideIcons.smartphone,
        ),
      ],
    );
  }
}