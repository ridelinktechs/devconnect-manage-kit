import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../components/text/text_component.dart';
import '../../../../components/viewers/json_viewer.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/utils/screenshot_filename.dart';
import '../../../../core/utils/screenshot_utils.dart';
import '../../../../core/utils/smooth_scroll_controller.dart';
import '../../../../core/utils/toast_utils.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/log/error_event.dart';
import '../shared/copy_button.dart';
import '../shared/error_tokens.dart' show severityColor;
import '../shared/platform_badge.dart';
import '../shared/severity_badge.dart';
import 'detail_row.dart';

/// Right-pane detail panel that swaps content based on the selected
/// error. Owns the per-tab screenshot machinery (full + current tab)
/// via [captureWidgetAsImage]. Routes per-tab content under:
///   1. **Message** — full message in mono scrollable block
///   2. **Stack Trace** — full stack trace (or empty state)
///   3. **Details** — key/value list (platform, severity, source, etc.)
class ErrorDetailPanel extends ConsumerStatefulWidget {
  final ErrorEvent entry;
  final VoidCallback onClose;

  const ErrorDetailPanel({
    super.key,
    required this.entry,
    required this.onClose,
  });

  @override
  ConsumerState<ErrorDetailPanel> createState() => _ErrorDetailPanelState();
}

class _ErrorDetailPanelState extends ConsumerState<ErrorDetailPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _messageScrollController = SmoothScrollController();
  final _stackTraceScrollController = SmoothScrollController();
  final _detailsScrollController = SmoothScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      animationDuration: ref.read(tabAnimationProvider),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _messageScrollController.dispose();
    _stackTraceScrollController.dispose();
    _detailsScrollController.dispose();
    super.dispose();
  }

  void _rebuildController() {
    final oldIndex = _tabController.index;
    _tabController.dispose();
    _tabController = TabController(
      length: 3,
      vsync: this,
      animationDuration: ref.read(tabAnimationProvider),
      initialIndex: oldIndex,
    );
    setState(() {});
  }

  void _copyText(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    showCopiedToast(context, label: '$label copied');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final entry = widget.entry;
    final severityClr = severityColor(entry.severity);

    ref.listen(tabAnimationProvider, (prev, next) {
      if (prev != next) _rebuildController();
    });

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? ColorTokens.darkBackground : Colors.white,
            border: Border(
              bottom: BorderSide(
                color: isDark ? Colors.white10 : Colors.black12,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(LucideIcons.alertTriangle, size: 16, color: severityClr),
              const SizedBox(width: 8),
              SeverityBadge(severity: entry.severity),
              const SizedBox(width: 8),
              PlatformBadge(platform: entry.platform),
              const SizedBox(width: 8),
              TextComponent(
                DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(
                  DateTime.fromMillisecondsSinceEpoch(entry.timestamp),
                ),
                style: TextStyle(
                  fontFamily: AppConstants.monoFontFamily,
                  fontSize: 11,
                  color: Colors.grey[500],
                ),
              ),
              const Spacer(),
              Tooltip(
                message: 'Capture full detail as image',
                waitDuration: const Duration(milliseconds: 400),
                child: GestureDetector(
                  onTap: _takeFullScreenshot,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        LucideIcons.camera,
                        size: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 2),
              Tooltip(
                message: 'Capture current tab only',
                waitDuration: const Duration(milliseconds: 400),
                child: GestureDetector(
                  onTap: _takeTabScreenshot,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        LucideIcons.scanLine,
                        size: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Tooltip(
                message: 'Close panel',
                child: GestureDetector(
                  onTap: widget.onClose,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        LucideIcons.x,
                        size: 16,
                        color: Colors.grey[500],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Tabs
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TabBar(
            controller: _tabController,
            labelStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            labelColor: ColorTokens.primary,
            unselectedLabelColor: isDark ? Colors.grey[500] : Colors.grey[600],
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isDark
                    ? ColorTokens.primary.withValues(alpha: 0.25)
                    : Colors.black.withValues(alpha: 0.06),
              ),
              boxShadow: isDark
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
            ),
            indicatorPadding: EdgeInsets.zero,
            dividerHeight: 0,
            splashFactory: NoSplash.splashFactory,
            overlayColor: WidgetStateProperty.all(Colors.transparent),
            padding: EdgeInsets.zero,
            labelPadding: EdgeInsets.zero,
            tabs: [
              Tab(height: 28, text: S.of(context).message),
              Tab(height: 28, text: 'Stack Trace'),
              Tab(height: 28, text: S.of(context).details),
            ],
          ),
        ),
        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // Message tab
              LazyTab(
                controller: _tabController,
                index: 0,
                builder: (_) => SingleChildScrollView(
                  controller: _messageScrollController,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          TextComponent(
                            S.of(context).message,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[500],
                            ),
                          ),
                          const Spacer(),
                          CopyButton(
                            tooltip: 'Copy message',
                            onTap: () => _copyText(
                              context,
                              entry.message,
                              'Message',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      TextComponent(
                        entry.message,
                        style: TextStyle(
                          fontFamily: AppConstants.monoFontFamily,
                          fontSize: 13,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Stack trace tab
              LazyTab(
                controller: _tabController,
                index: 1,
                builder: (_) => entry.stackTrace != null
                    ? SingleChildScrollView(
                        controller: _stackTraceScrollController,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                TextComponent(
                                  'Stack Trace',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[500],
                                  ),
                                ),
                                const Spacer(),
                                CopyButton(
                                  tooltip: 'Copy stack trace',
                                  onTap: () => _copyText(
                                    context,
                                    entry.stackTrace!,
                                    'Stack trace',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            TextComponent(
                              entry.stackTrace!,
                              style: TextStyle(
                                fontFamily: AppConstants.monoFontFamily,
                                fontSize: 11,
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      )
                    : Center(
                        child: TextComponent(S.of(context).noStackTrace),
                      ),
              ),
              // Details tab
              LazyTab(
                controller: _tabController,
                index: 2,
                builder: (_) => SingleChildScrollView(
                  controller: _detailsScrollController,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DetailRow(label: S.of(context).platform, value: entry.platform.name),
                      DetailRow(label: S.of(context).severity, value: entry.severity.name),
                      // Null-coalesce fallbacks for optional fields — leave
                      // verbatim from the original to preserve behavior when
                      // upstream SDKs omit them.
                      DetailRow(label: S.of(context).source, value: entry.source ?? 'unknown'),
                      DetailRow(label: S.of(context).deviceId, value: entry.deviceId),
                      DetailRow(label: S.of(context).deviceInfo, value: entry.deviceInfo ?? 'unknown'),
                      if (entry.metadata != null) ...[
                        const SizedBox(height: 12),
                        TextComponent(
                          'Metadata',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[500],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.black26 : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: TextComponent(
                            entry.metadata.toString(),
                            style: TextStyle(
                              fontFamily: AppConstants.monoFontFamily,
                              fontSize: 11,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---- Screenshot ----

  Future<void> _takeFullScreenshot() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final entry = widget.entry;
    final subject = entry.source ?? entry.severity.name;
    final fileName = buildRichScreenshotName(
      type: 'error',
      subject: subject,
      suffix: '_full',
    );
    await captureWidgetAsImage(
      context,
      _buildFullScreenshotWidget(isDark),
      fileName: fileName,
    );
  }

  Future<void> _takeTabScreenshot() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final entry = widget.entry;
    final subject = entry.source ?? entry.severity.name;
    final fileName = buildRichScreenshotName(
      type: 'error',
      subject: subject,
      suffix: '_tab',
    );
    await captureWidgetAsImage(
      context,
      _buildTabScreenshotWidget(isDark, _tabController.index),
      fileName: fileName,
    );
  }

  Widget _buildFullScreenshotWidget(bool isDark) {
    final entry = widget.entry;
    final severityClr = severityColor(entry.severity);
    final time = DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(
      DateTime.fromMillisecondsSinceEpoch(entry.timestamp),
    );

    return Container(
      color: isDark ? ColorTokens.darkSurface : Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            color: isDark ? ColorTokens.darkBackground : Colors.white,
            child: Row(
              children: [
                Icon(LucideIcons.alertTriangle, size: 16, color: severityClr),
                const SizedBox(width: 8),
                SeverityBadge(severity: entry.severity),
                const SizedBox(width: 8),
                PlatformBadge(platform: entry.platform),
                const SizedBox(width: 8),
                TextComponent(
                  time,
                  style: TextStyle(
                    fontFamily: AppConstants.monoFontFamily,
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Message section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextComponent(
                  'Message',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? ColorTokens.darkBackground : const Color(0xFFF0F0F0),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.black.withValues(alpha: 0.06),
                    ),
                  ),
                  child: TextComponent(
                    entry.message,
                    style: TextStyle(
                      fontFamily: AppConstants.monoFontFamily,
                      fontSize: 12,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Stack trace section
          if (entry.stackTrace != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextComponent(
                    'Stack Trace',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: severityClr.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: severityClr.withValues(alpha: 0.15),
                      ),
                    ),
                    child: TextComponent(
                      entry.stackTrace!,
                      style: TextStyle(
                        fontFamily: AppConstants.monoFontFamily,
                        fontSize: 11,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // Details section
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextComponent(
                  'Details',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? ColorTokens.darkBackground : const Color(0xFFF0F0F0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _screenshotDetailRow('Platform', entry.platform.name, isDark),
                      _screenshotDetailRow('Severity', entry.severity.name, isDark),
                      _screenshotDetailRow('Source', entry.source ?? 'unknown', isDark),
                      _screenshotDetailRow('Device ID', entry.deviceId, isDark),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      width: 600,
    );
  }

  Widget _buildTabScreenshotWidget(bool isDark, int tabIndex) {
    final entry = widget.entry;
    final severityClr = severityColor(entry.severity);
    final time = DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(
      DateTime.fromMillisecondsSinceEpoch(entry.timestamp),
    );

    // Bounds check — if `tabIndex` is out of range, fall back to the
    // first tab's label. Prevents a screenshot crash if the tab
    // controller is in an unexpected state when the user clicks
    // "Capture tab".
    const tabLabels = ['Message', 'Stack Trace', 'Details'];
    final tabLabel = tabIndex >= 0 && tabIndex < tabLabels.length
        ? tabLabels[tabIndex]
        : 'Message';

    return Container(
      color: isDark ? ColorTokens.darkSurface : Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            color: isDark ? ColorTokens.darkBackground : Colors.white,
            child: Row(
              children: [
                Icon(LucideIcons.alertTriangle, size: 16, color: severityClr),
                const SizedBox(width: 8),
                SeverityBadge(severity: entry.severity),
                const SizedBox(width: 8),
                PlatformBadge(platform: entry.platform),
                const SizedBox(width: 8),
                TextComponent(time, style: TextStyle(fontFamily: AppConstants.monoFontFamily, fontSize: 11, color: Colors.grey[500])),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: ColorTokens.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: TextComponent(tabLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: ColorTokens.primary)),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Tab content
          Padding(
            padding: const EdgeInsets.all(16),
            child: tabIndex == 0
                ? TextComponent(entry.message, style: TextStyle(fontFamily: AppConstants.monoFontFamily, fontSize: 12, color: isDark ? Colors.white : Colors.black87))
                : tabIndex == 1
                    ? (entry.stackTrace != null
                        ? TextComponent(entry.stackTrace!, style: TextStyle(fontFamily: AppConstants.monoFontFamily, fontSize: 11, color: isDark ? Colors.white70 : Colors.black87))
                        : const TextComponent('No stack trace available'))
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _screenshotDetailRow('Platform', entry.platform.name, isDark),
                          _screenshotDetailRow('Severity', entry.severity.name, isDark),
                          _screenshotDetailRow('Source', entry.source ?? 'unknown', isDark),
                          _screenshotDetailRow('Device ID', entry.deviceId, isDark),
                        ],
                      ),
          ),
        ],
      ),
      width: 600,
    );
  }

  Widget _screenshotDetailRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: TextComponent(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey[500])),
          ),
          Expanded(
            child: TextComponent(value, style: TextStyle(fontFamily: AppConstants.monoFontFamily, fontSize: 10, color: isDark ? Colors.white70 : Colors.black87)),
          ),
        ],
      ),
    );
  }
}