import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/color_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../device_history/provider/device_history_providers.dart';
import '../header/section_title.dart';
import '../shared/icon_action.dart';

/// Cached Devices card — shows the list of devices that have ever
/// connected, persisted across restarts. Each row exposes a
/// "mark online/offline" toggle and a "forget" remove control via
/// [IconAction] buttons.
class DeviceHistorySection extends ConsumerWidget {
  const DeviceHistorySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(deviceHistoryProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SectionTitle(
          icon: LucideIcons.history,
          title: S.of(context).deviceHistory,
        ),
        Text(
          S.of(context).deviceHistoryDesc,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[500],
            height: 1.4,
          ),
        ),
        const SizedBox(height: 10),
        if (history.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Icon(LucideIcons.inbox, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 8),
                Text(
                  S.of(context).noDeviceHistory,
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          )
        else
          for (final entry in history)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: DeviceHistoryRow(entry: entry),
            ),
      ],
    );
  }
}

/// One persistent row inside [DeviceHistorySection]. Owns the
/// "mark online/offline" flip and the "forget" confirmation dialog.
class DeviceHistoryRow extends ConsumerStatefulWidget {
  final DeviceHistoryEntry entry;
  const DeviceHistoryRow({super.key, required this.entry});

  @override
  ConsumerState<DeviceHistoryRow> createState() => _DeviceHistoryRowState();
}

class _DeviceHistoryRowState extends ConsumerState<DeviceHistoryRow> {
  Color get _platformColor {
    final p = widget.entry.platform.toLowerCase();
    if (p == 'ios' || p == 'flutter') return const Color(0xFF58A6FF);
    if (p == 'android') return const Color(0xFF3DDC84);
    return Colors.grey;
  }

  IconData get _platformIcon {
    final p = widget.entry.platform.toLowerCase();
    if (p == 'ios') return LucideIcons.apple;
    if (p == 'android') return LucideIcons.smartphone;
    if (p == 'flutter' || p == 'react_native') return LucideIcons.boxes;
    return LucideIcons.monitor;
  }

  Future<void> _toggleOnline() async {
    // Locally flip the flag in the entry — no network call, this is just
    // a UI hint so the user can mark a stale "online" entry as gone.
    final updated = DeviceHistoryEntry(
      deviceId: widget.entry.deviceId,
      deviceName: widget.entry.deviceName,
      platform: widget.entry.platform,
      appName: widget.entry.appName,
      appVersion: widget.entry.appVersion,
      clientIp: widget.entry.clientIp,
      firstConnectedAt: widget.entry.firstConnectedAt,
      lastConnectedAt: widget.entry.lastConnectedAt,
      isOnline: !widget.entry.isOnline,
      totalConnections: widget.entry.totalConnections,
    );
    await ref
        .read(deviceHistoryProvider.notifier)
        .replaceEntry(widget.entry.deviceId, updated);
  }

  Future<void> _forget() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(S.of(context).forgetDevice),
        content: Text(S.of(context).forgetDeviceConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(S.of(context).cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: ColorTokens.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(S.of(context).forgetDevice),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref
          .read(deviceHistoryProvider.notifier)
          .forget(widget.entry.deviceId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = _platformColor;
    final entry = widget.entry;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.03)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: entry.isOnline
              ? ColorTokens.success.withValues(alpha: 0.3)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : Colors.black.withValues(alpha: 0.04)),
        ),
      ),
      child: Row(
        children: [
          Icon(_platformIcon, size: 14, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              entry.deviceName.isNotEmpty
                  ? entry.deviceName
                  : '${entry.deviceId.substring(0, entry.deviceId.length.clamp(0, 8))}…',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            '● ${entry.isOnline ? S.of(context).online : S.of(context).offline}',
            style: TextStyle(
              fontSize: 10,
              color: entry.isOnline ? ColorTokens.success : Colors.grey[500],
            ),
          ),
          const SizedBox(width: 6),
          // Toggle online/offline (e.g. mark a stale "online" as gone)
          IconAction(
            icon: entry.isOnline ? LucideIcons.wifiOff : LucideIcons.wifi,
            tooltip: entry.isOnline
                ? S.of(context).markOffline
                : S.of(context).markOnline,
            color: entry.isOnline ? Colors.grey[500]! : ColorTokens.success,
            onTap: _toggleOnline,
          ),
          const SizedBox(width: 2),
          // Forget — remove this entry from history
          IconAction(
            icon: LucideIcons.x,
            tooltip: S.of(context).forgetDevice,
            color: Colors.grey[500]!,
            onTap: _forget,
          ),
        ],
      ),
    );
  }
}