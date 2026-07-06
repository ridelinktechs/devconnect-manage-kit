import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/providers/tab_visibility_provider.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../header/section_title.dart';

/// Per-tab toggle rows. Each row uses the tab's accent color so the
/// enabled/disabled transition is visually consistent with the icon in
/// the app's main navigation.
class TabVisibilitySection extends ConsumerWidget {
  const TabVisibilitySection({super.key});

  List<(TabKey, String, IconData, Color)> _getTabs(BuildContext context) => [
    (TabKey.console, S.of(context).console, LucideIcons.terminal, const Color(0xFF58A6FF)),
    (TabKey.network, S.of(context).network, LucideIcons.globe, ColorTokens.success),
    (TabKey.state, S.of(context).state, LucideIcons.layers, ColorTokens.secondary),
    (TabKey.storage, S.of(context).storage, LucideIcons.database, ColorTokens.warning),
    (TabKey.database, S.of(context).database, LucideIcons.hardDrive, const Color(0xFFD2A8FF)),
    (TabKey.performance, S.of(context).performance, LucideIcons.gauge, ColorTokens.chartGreen),
    (TabKey.memoryLeaks, S.of(context).memoryLeaks, LucideIcons.bug, ColorTokens.chartRed),
    (TabKey.history, S.of(context).history, LucideIcons.history, Colors.grey),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabledTabs = ref.watch(tabVisibilityProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(
          icon: LucideIcons.layoutGrid,
          title: S.of(context).tabVisibility,
        ),
        Text(
          S.of(context).tabVisibilityDesc,
          style: TextStyle(fontSize: 11, color: Colors.grey[500], height: 1.4),
        ),
        const SizedBox(height: 12),
        ..._getTabs(context).map((t) {
          final (key, label, icon, color) = t;
          final isEnabled = enabledTabs.contains(key);

          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: GestureDetector(
              onTap: () =>
                  ref.read(tabVisibilityProvider.notifier).toggle(key),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isEnabled
                        ? color.withValues(alpha: 0.06)
                        : isDark
                            ? Colors.white.withValues(alpha: 0.02)
                            : Colors.grey.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isEnabled
                          ? color.withValues(alpha: 0.2)
                          : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        icon,
                        size: 16,
                        color: isEnabled ? color : Colors.grey[600],
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isEnabled
                                ? (isDark ? Colors.white : Colors.black87)
                                : Colors.grey[500],
                          ),
                        ),
                      ),
                      if (!isEnabled)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Icon(
                            LucideIcons.lock,
                            size: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      SizedBox(
                        width: 40,
                        height: 22,
                        child: FittedBox(
                          child: Switch(
                            value: isEnabled,
                            onChanged: (_) => ref
                                .read(tabVisibilityProvider.notifier)
                                .toggle(key),
                            activeTrackColor: color.withValues(alpha: 0.5),
                            activeThumbColor: color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}