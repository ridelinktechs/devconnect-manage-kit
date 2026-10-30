import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../models/state/state_change.dart';
import '../../provider/state_providers.dart';

/// One 44px row in the state change timeline.
class StateChangeTile extends ConsumerWidget {
  final StateChange entry;
  final VoidCallback onTap;

  const StateChangeTile({super.key, required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedId = ref.watch(selectedStateChangeIdProvider);
    final isSelected = selectedId == entry.id;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final time = DateFormat(
      'HH:mm:ss.SSS',
    ).format(DateTime.fromMillisecondsSinceEpoch(entry.timestamp));
    final changes = entry.diff.length;

    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          height: 44,
          padding: const EdgeInsets.only(right: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? ColorTokens.selectedBg(isDark)
                : Colors.transparent,
            border: Border(
              bottom: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.03)
                    : Colors.black.withValues(alpha: 0.04),
              ),
              left: BorderSide(
                color: isSelected
                    ? ColorTokens.selectedAccent
                    : ColorTokens.secondary,
                width: isSelected ? 3 : 2,
              ),
            ),
          ),
          child: Row(
            children: [
              const SizedBox(width: 12),
              // Timestamp
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
              // State manager badge
              Container(
                height: 22,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: ColorTokens.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.layers,
                      size: 10,
                      color: ColorTokens.secondary,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      entry.stateManagerType.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: ColorTokens.secondary,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // Action name
              Expanded(
                child: Text(
                  entry.actionName,
                  style: TextStyle(
                    fontFamily: AppConstants.monoFontFamily,
                    fontSize: 12,
                    color: isDark
                        ? ColorTokens.lightBackground
                        : ColorTokens.darkNeutral,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Changes count
              if (changes > 0) ...[
                const SizedBox(width: 8),
                Text(
                  '$changes change${changes > 1 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[500],
                    fontFamily: AppConstants.monoFontFamily,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
