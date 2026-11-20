import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../components/viewers/json_viewer.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/theme_provider.dart';
import 'detail_tab_bar.dart';

/// Tree / Pretty viewer with a segmented-control tab bar at the top.
///
/// Each instance owns its own [DefaultTabController], so the Before and
/// After tabs in the parent panel keep their Tree/Pretty selection
/// independently.
class StateJsonTabView extends ConsumerWidget {
  final dynamic data;

  const StateJsonTabView({super.key, required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return DefaultTabController(
      length: 2,
      animationDuration: ref.watch(tabAnimationProvider),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: DetailTabBar(
              isDark: isDark,
              accentColor: ColorTokens.secondary,
              tabs: const ['Tree', 'Pretty'],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: JsonViewer(data: data, initiallyExpanded: true),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: JsonPrettyViewer(data: data),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
