import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../components/feedback/empty_state.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../models/state/state_change.dart';

class StateList extends StatelessWidget {
  final List<StateChange> entries;
  final ScrollController? controller;

  const StateList({super.key, required this.entries, this.controller});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return EmptyState(
        icon: LucideIcons.layers,
        title: S.of(context).noStateChanges,
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
        ).format(DateTime.fromMillisecondsSinceEpoch(e.timestamp));

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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: ColorTokens.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  e.stateManagerType.toUpperCase(),
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    color: ColorTokens.secondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  e.actionName,
                  style: TextStyle(
                    fontFamily: AppConstants.monoFontFamily,
                    fontSize: 11,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (e.diff.isNotEmpty)
                Text(
                  '${e.diff.length} changes',
                  style: TextStyle(fontSize: 9, color: Colors.grey[500]),
                ),
            ],
          ),
        );
      },
    );
  }
}
