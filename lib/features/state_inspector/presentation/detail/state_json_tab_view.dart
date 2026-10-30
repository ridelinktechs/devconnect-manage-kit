import 'package:flutter/material.dart';

import '../../../../components/viewers/json_viewer.dart';
import '../../../../core/theme/color_tokens.dart';
import 'detail_tab_bar.dart';

/// Tree / Pretty viewer with a segmented-control tab bar at the top.
///
/// Each instance owns its own [DefaultTabController], so the Before and
/// After tabs in the parent panel keep their Tree/Pretty selection
/// independently.
class StateJsonTabView extends StatelessWidget {
  final dynamic data;

  const StateJsonTabView({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return DefaultTabController(
      length: 2,
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
