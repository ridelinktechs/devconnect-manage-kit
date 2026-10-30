import 'package:flutter/material.dart';

import '../../../../core/theme/color_tokens.dart';
import '../../../../l10n/generated/app_localizations.dart';

/// Top tab bar switching between Redux, State Managers and State Tools.
class StateManagerTabBar extends StatelessWidget {
  const StateManagerTabBar({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.5)),
        ),
      ),
      child: TabBar(
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        labelColor: ColorTokens.primary,
        unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
        indicatorColor: ColorTokens.primary,
        indicatorWeight: 2,
        labelStyle: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w500,
        ),
        tabs: [
          const Tab(text: 'Redux'),
          const Tab(text: 'State Managers'),
          Tab(text: S.of(context).stateToolsTab),
        ],
      ),
    );
  }
}
