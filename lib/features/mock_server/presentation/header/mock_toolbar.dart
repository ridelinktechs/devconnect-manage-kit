import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/chrome_palette.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../server/providers/server_providers.dart';
import '../../../round/provider/round_providers.dart';
import '../../../settings/presentation/shared/action_button.dart';
import '../../../settings/presentation/shared/status_chip.dart';
import '../../../settings/presentation/tips/page_guide_button.dart';
import '../shared/mock_look.dart';

/// The Mock Server's title bar: how many rules there are, which device they
/// go to and whether it is kept in step, and the page's actions.
class MockToolbar extends ConsumerWidget {
  final VoidCallback onAdd;
  final VoidCallback onPush;
  final VoidCallback onClear;

  const MockToolbar({
    super.key,
    required this.onAdd,
    required this.onPush,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final p = ChromePalette.of(context);
    final rules = ref.watch(mockRulesProvider);
    final target = ref.watch(roundActionTargetProvider);
    final allDevices = ref.watch(selectedDeviceProvider) == allDevicesValue;
    final device = target == null
        ? null
        : ref
              .watch(connectedDevicesProvider)
              .where((d) => d.deviceId == target)
              .firstOrNull;
    final synced =
        target != null && ref.watch(mockRulesSyncProvider).contains(target);
    final full = device?.deviceName ?? target ?? '';
    final name = full.length > 16 ? '${full.substring(0, 15)}…' : full;

    final (chip, tip) = switch ((target, synced)) {
      (null, _) => (
        StatusChip(
          color: p.textMuted,
          icon: LucideIcons.smartphone,
          label: allDevices ? 'All devices: pick one' : 'No device selected',
        ),
        'Pick one device in the bottom bar to push the rules to it',
      ),
      (_, false) => (
        StatusChip(
          color: p.isDark ? ColorTokens.warning : const Color(0xFF9A6700),
          label: '$name · not pushed',
        ),
        '"Push all" sends every rule; after that, saves, switches and '
            'deletes reach the device on their own',
      ),
      (_, true) => (
        StatusChip(color: p.success, pulse: true, label: '$name · live'),
        'Saves, switches and deletes reach this device on their own; it '
            'gets the rules back when it reconnects',
      ),
    };

    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: p.isDark ? ColorTokens.darkBackground : Colors.white,
      child: Row(
        children: [
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        LucideIcons.server,
                        size: 16,
                        color: ColorTokens.primary,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Mock Server',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                      const PageGuideButton(route: '/mock-server'),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Tooltip(
                      message: full.isEmpty ? tip : '$full\n$tip',
                      child: chip,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ActionButton(
            label: 'Clear device',
            icon: LucideIcons.eraser,
            color: mockDanger(p.isDark),
            onTap: target == null ? null : onClear,
          ),
          const SizedBox(width: 8),
          ActionButton(
            label: 'Push all',
            icon: LucideIcons.send,
            color: synced ? mockAccent(p.isDark) : ColorTokens.primary,
            filled: !synced,
            onTap: target == null || rules.isEmpty ? null : onPush,
          ),
          const SizedBox(width: 8),
          ActionButton(
            label: 'Add rule',
            icon: LucideIcons.plus,
            color: rules.isEmpty ? ColorTokens.primary : mockAccent(p.isDark),
            filled: rules.isEmpty,
            onTap: onAdd,
          ),
        ],
      ),
    );
  }
}
