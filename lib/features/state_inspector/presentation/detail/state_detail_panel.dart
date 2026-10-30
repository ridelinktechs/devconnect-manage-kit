import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../components/text/text_component.dart';
import '../../../../components/viewers/json_viewer.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/utils/files/screenshot_filename.dart';
import '../../../../core/utils/files/screenshot_utils.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../models/state/state_change.dart';
import 'detail_icon_btn.dart';
import 'detail_tab_bar.dart';
import 'diff_view.dart';
import 'state_json_tab_view.dart';

/// Right-pane detail of the selected state change (Diff / Before / After).
class StateDetailPanel extends StatefulWidget {
  final StateChange entry;
  final VoidCallback onClose;
  final VoidCallback onRestore;
  final VoidCallback onSnapshot;

  const StateDetailPanel({
    super.key,
    required this.entry,
    required this.onClose,
    required this.onRestore,
    required this.onSnapshot,
  });

  @override
  State<StateDetailPanel> createState() => _StateDetailPanelState();
}

class _StateDetailPanelState extends State<StateDetailPanel> {
  StateChange get entry => widget.entry;

  void _takeScreenshot(BuildContext context, bool isDark) {
    // Resolve a descriptive file name: state_<action>_<ts>_full.png
    final fileName = buildRichScreenshotName(
      type: 'state',
      subject: entry.actionName.isNotEmpty
          ? entry.actionName
          : entry.stateManagerType,
      suffix: '_full',
    );

    final screenshotWidget = Container(
      color: isDark ? ColorTokens.darkSurface : ColorTokens.lightSurface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: isDark ? ColorTokens.darkBackground : Colors.white,
            child: Row(
              children: [
                Icon(
                  LucideIcons.gitCommitHorizontal,
                  size: 16,
                  color: ColorTokens.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextComponent(
                    entry.actionName,
                    style: TextStyle(
                      fontFamily: AppConstants.monoFontFamily,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Diff
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextComponent(
                  'DIFF',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[500],
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                if (entry.diff.isEmpty)
                  TextComponent(
                    S.of(context).noChanges,
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  )
                else
                  ...entry.diff.map(
                    (d) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: TextComponent(
                        '${d.operation} ${d.path}: ${d.oldValue} → ${d.newValue}',
                        style: TextStyle(
                          fontFamily: AppConstants.monoFontFamily,
                          fontSize: 11,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Before
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextComponent(
                  'BEFORE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[500],
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                StateJsonTabView(data: entry.previousState),
              ],
            ),
          ),
          const Divider(height: 1),
          // After
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextComponent(
                  'AFTER',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[500],
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                StateJsonTabView(data: entry.nextState),
              ],
            ),
          ),
        ],
      ),
    );
    captureWidgetAsImage(context, screenshotWidget, fileName: fileName);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Container(
            color: isDark ? ColorTokens.darkBackground : Colors.white,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.gitCommitHorizontal,
                        size: 16,
                        color: ColorTokens.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextComponent(
                          entry.actionName,
                          style: TextStyle(
                            fontFamily: AppConstants.monoFontFamily,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      DetailIconBtn(
                        icon: LucideIcons.rotateCcw,
                        tooltip: S.of(context).stateRestoreHere,
                        isDark: isDark,
                        onTap: widget.onRestore,
                      ),
                      const SizedBox(width: 4),
                      DetailIconBtn(
                        icon: LucideIcons.bookmarkPlus,
                        tooltip: S.of(context).stateSaveSnapshot,
                        isDark: isDark,
                        onTap: widget.onSnapshot,
                      ),
                      const SizedBox(width: 4),
                      // Screenshot button
                      DetailIconBtn(
                        icon: LucideIcons.camera,
                        tooltip: S.of(context).captureAsImage,
                        isDark: isDark,
                        onTap: () => _takeScreenshot(context, isDark),
                      ),
                      const SizedBox(width: 4),
                      // Close button
                      DetailIconBtn(
                        icon: LucideIcons.x,
                        tooltip: S.of(context).close,
                        isDark: isDark,
                        onTap: widget.onClose,
                      ),
                    ],
                  ),
                ),
                DetailTabBar(
                  isDark: isDark,
                  accentColor: ColorTokens.secondary,
                  tabs: [
                    S.of(context).diff,
                    S.of(context).before,
                    S.of(context).after,
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                LazyTab(index: 0, builder: (_) => DiffView(diff: entry.diff)),
                LazyTab(
                  index: 1,
                  builder: (_) => StateJsonTabView(data: entry.previousState),
                ),
                LazyTab(
                  index: 2,
                  builder: (_) => StateJsonTabView(data: entry.nextState),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
