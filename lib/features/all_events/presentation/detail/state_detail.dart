import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../components/feedback/empty_state.dart';
import '../../../../components/text/text_component.dart';
import '../../../../components/viewers/json_viewer.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/utils/smooth_scroll_controller.dart';
import '../../../../core/utils/toast_utils.dart';
import '../../../../models/state/state_change.dart';
import '../shared/body_view.dart';
import '../shared/detail_tab_bar.dart';
import '../shared/copy_button.dart';
import '../shared/tag_chip.dart';
import 'diff_row.dart';

/// Right-pane detail for state-change events. Three tabs:
///
/// - **Diff** — list of [DiffRow]s showing each field-level change.
/// - **Previous** — full state body before the change.
/// - **Next** — full state body after the change.
class StateDetail extends ConsumerStatefulWidget {
  final StateChange entry;
  final ValueChanged<int>? onTabChanged;
  final ValueChanged<bool>? onJsonModeChanged;

  const StateDetail({
    super.key,
    required this.entry,
    this.onTabChanged,
    this.onJsonModeChanged,
  });

  @override
  ConsumerState<StateDetail> createState() => _StateDetailState();
}

class _StateDetailState extends ConsumerState<StateDetail>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _diffScrollController = SmoothScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = _makeController();
    _tabController.addListener(_onTabIndexChange);
  }

  TabController _makeController([int initialIndex = 0]) {
    return TabController(
      length: 3,
      vsync: this,
      animationDuration: ref.read(tabAnimationProvider),
      initialIndex: initialIndex,
    );
  }

  void _onTabIndexChange() {
    if (!_tabController.indexIsChanging) {
      widget.onTabChanged?.call(_tabController.index);
    }
  }

  void _rebuildController() {
    final oldIndex = _tabController.index;
    _tabController.removeListener(_onTabIndexChange);
    _tabController.dispose();
    _tabController = _makeController(oldIndex);
    _tabController.addListener(_onTabIndexChange);
    setState(() {});
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabIndexChange);
    _tabController.dispose();
    _diffScrollController.dispose();
    super.dispose();
  }

  StateChange get entry => widget.entry;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    ref.listen(tabAnimationProvider, (prev, next) {
      if (prev != next) _rebuildController();
    });
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              TagChip(entry.stateManagerType, color: ColorTokens.secondary),
              const SizedBox(width: 8),
              Expanded(
                child: TextComponent(
                  entry.actionName,
                  style: const TextStyle(
                    fontFamily: AppConstants.monoFontFamily,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              CopyButton(
                tooltip: 'Copy action',
                onTap: () => _copyText(context, entry.actionName, 'Action'),
              ),
            ],
          ),
        ),
        DetailTabBar(
          controller: _tabController,
          isDark: isDark,
          accentColor: ColorTokens.secondary,
          tabs: const ['Diff', 'Previous', 'Next'],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              LazyTab(
                controller: _tabController,
                index: 0,
                builder: (_) => entry.diff.isEmpty
                    ? EmptyState(
                        icon: LucideIcons.gitCompare, title: 'No diff')
                    : ListView.builder(
                        controller: _diffScrollController,
                        padding: const EdgeInsets.all(12),
                        itemCount: entry.diff.length,
                        itemBuilder: (context, index) =>
                            DiffRow(diff: entry.diff[index]),
                      ),
              ),
              LazyTab(
                controller: _tabController,
                index: 1,
                builder: (_) => entry.previousState.isEmpty
                    ? EmptyState(
                        icon: LucideIcons.layers,
                        title: 'No previous state')
                    : BodyView(
                        body: entry.previousState,
                        label: 'Previous State',
                        deviceId: entry.deviceId,
                        onJsonModeChanged: widget.onJsonModeChanged,
                      ),
              ),
              LazyTab(
                controller: _tabController,
                index: 2,
                builder: (_) => entry.nextState.isEmpty
                    ? EmptyState(
                        icon: LucideIcons.layers,
                        title: 'No next state')
                    : BodyView(
                        body: entry.nextState,
                        label: 'Next State',
                        deviceId: entry.deviceId,
                        onJsonModeChanged: widget.onJsonModeChanged,
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

void _copyText(BuildContext context, String text, String label) {
  Clipboard.setData(ClipboardData(text: text));
  showCopiedToast(context, label: '$label copied');
}