import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../components/misc/status_badge.dart';
import '../../../../components/text/text_component.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../server/providers/server_providers.dart';
import '../../provider/all_events_provider.dart';
import '../buttons/pressable_button.dart';

/// Mini-header at the top of the detail panel: shows the event's type
/// icon/label, originating device, timestamp, and the screenshot + close
/// actions.
class DetailHeader extends ConsumerWidget {
  final UnifiedEvent event;
  final VoidCallback onClose;
  final VoidCallback onFullScreenshot;
  final VoidCallback? onTabScreenshot;
  final bool hasMultipleTabs;

  const DetailHeader({
    super.key,
    required this.event,
    required this.onClose,
    required this.onFullScreenshot,
    this.onTabScreenshot,
    this.hasMultipleTabs = false,
  });

  static (Color, IconData, String) staticTypeDetails(EventType type) {
    switch (type) {
      case EventType.log:
        return (ColorTokens.logInfo, LucideIcons.terminal, 'Log Detail');
      case EventType.network:
        return (ColorTokens.success, LucideIcons.globe, 'Network Detail');
      case EventType.state:
        return (
          ColorTokens.secondary,
          LucideIcons.layers,
          'State Detail'
        );
      case EventType.storage:
        return (
          ColorTokens.warning,
          LucideIcons.database,
          'Storage Detail'
        );
      case EventType.display:
        return (
          const Color(0xFF9B59B6),
          LucideIcons.monitor,
          'Display Detail'
        );
      case EventType.asyncOp:
        return (
          const Color(0xFFE67E22),
          LucideIcons.zap,
          'Async Operation'
        );
      case EventType.error:
        return (Colors.red, LucideIcons.alertTriangle, 'Error Detail');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final time = DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(
      DateTime.fromMillisecondsSinceEpoch(event.timestamp),
    );

    final devices = ref.watch(connectedDevicesProvider);
    final device =
        devices.where((d) => d.deviceId == event.deviceId).firstOrNull;

    final (typeColor, typeIcon, typeLabel) = staticTypeDetails(event.type);

    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: isDark ? ColorTokens.darkBackground : Colors.white,
      ),
      child: Row(
        children: [
          Icon(typeIcon, size: 14, color: typeColor),
          const SizedBox(width: 8),
          TextComponent(
            typeLabel,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: typeColor,
            ),
          ),
          const SizedBox(width: 10),
          if (device != null) ...[
            PlatformBadge(platform: device.platform),
            const SizedBox(width: 8),
          ],
          TextComponent(
            time,
            style: TextStyle(
              fontFamily: AppConstants.monoFontFamily,
              fontSize: 10,
              color: Colors.grey[500],
            ),
          ),
          const Spacer(),
          // Screenshot buttons
          Tooltip(
            message: S.of(context).captureFullTooltip,
            waitDuration: const Duration(milliseconds: 400),
            child: ActionButton(
              icon: LucideIcons.camera,
              label: S.of(context).captureFull,
              onTap: onFullScreenshot,
            ),
          ),
          if (hasMultipleTabs && onTabScreenshot != null) ...[
            const SizedBox(width: 4),
            Tooltip(
              message: S.of(context).captureTabTooltip,
              waitDuration: const Duration(milliseconds: 400),
              child: ActionButton(
                icon: LucideIcons.scanLine,
                label: S.of(context).captureTab,
                onTap: onTabScreenshot!,
              ),
            ),
          ],
          const SizedBox(width: 6),
          PressableButton(
            onTap: onClose,
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: Colors.grey.withValues(alpha: 0.1),
              ),
              child: Icon(LucideIcons.x, size: 14, color: Colors.grey[500]),
            ),
          ),
        ],
      ),
    );
  }
}