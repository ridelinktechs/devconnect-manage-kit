import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../components/misc/status_badge.dart';
import '../../../../components/text/text_component.dart';
import '../../../../components/viewers/json_viewer.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/utils/code_generator.dart';
import '../../../../core/utils/duration_format.dart';
import '../../../../core/utils/screenshot_filename.dart';
import '../../../../core/utils/toast_utils.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/log/error_event.dart';
import '../../../../models/log/log_entry.dart';
import '../../../../models/network/network_entry.dart';
import '../../../../models/state/state_change.dart';
import '../../../../models/storage/storage_entry.dart';
import '../../../../core/utils/network_url_formatter.dart';
import '../../../../server/providers/server_providers.dart';
import '../../provider/all_events_provider.dart';
import '../buttons/pressable_button.dart';
import '../detail/detail_header.dart';
import '../detail/diff_row.dart';
import '../detail/error_detail.dart';
import '../detail/fallback_detail.dart';
import '../detail/log_detail.dart';
import '../detail/network_detail.dart';
import '../detail/state_detail.dart';
import '../detail/storage_detail.dart';
import '../network/headers_view.dart';
import '../shared/code_block.dart';
import '../shared/error_block.dart';
import '../shared/info_row.dart';
import '../shared/op_badge.dart';
import '../shared/section_label.dart';
import '../shared/tag_chip.dart';
import '../shared/type_badge.dart';

/// Right-pane detail panel that swaps content based on the event type:
/// log / network / state / storage / display / async / error.
///
/// Owns the screenshot machinery (full + per-tab) and the capture
/// flash/saved-toast overlays. Routes type-specific UI to the matching
/// `*Detail` widget under `detail/`.
class EventDetailPanel extends ConsumerStatefulWidget {
  final UnifiedEvent event;
  final VoidCallback onClose;

  const EventDetailPanel({
    super.key,
    required this.event,
    required this.onClose,
  });

  @override
  ConsumerState<EventDetailPanel> createState() => _EventDetailPanelState();
}

class _EventDetailPanelState extends ConsumerState<EventDetailPanel> {
  // ignore: unused_field
  int _currentTabIndex = 0;
  bool _currentJsonMode = false;
  final _contentKey = GlobalKey();

  Future<void> _captureAndSave(Widget screenshotWidget,
      {String? fileName}) async {
    try {
      // Show capture flash animation
      _showCaptureFlash();

      final overlayKey = GlobalKey();
      final theme = Theme.of(context);

      late OverlayEntry overlayEntry;
      overlayEntry = OverlayEntry(
        builder: (_) => Positioned(
          left: -10000,
          top: 0,
          child: RepaintBoundary(
            key: overlayKey,
            child: Theme(
              data: theme,
              child: Material(
                child: SizedBox(
                  width: 600,
                  child: screenshotWidget,
                ),
              ),
            ),
          ),
        ),
      );

      Overlay.of(context).insert(overlayEntry);
      await Future.delayed(const Duration(milliseconds: 600));

      final boundary = overlayKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) {
        overlayEntry.remove();
        return;
      }

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      overlayEntry.remove();

      if (byteData == null) return;

      final pngBytes = byteData.buffer.asUint8List();

      final baseName = (fileName == null || fileName.isEmpty)
          ? 'dcmt_${DateTime.now().millisecondsSinceEpoch}'
          : fileName;
      final withExt =
          baseName.endsWith('.png') ? baseName : '$baseName.png';

      final location = await getSaveLocation(
        suggestedName: withExt,
        acceptedTypeGroups: [
          const XTypeGroup(label: 'PNG Image', extensions: ['png']),
        ],
      );

      if (location == null) return;

      // Force saved file's name to withExt regardless of what OS returns.
      final savedPath = _ensureFilename(location.path, withExt);
      final xfile = XFile.fromData(
        pngBytes,
        mimeType: 'image/png',
        name: withExt,
        length: pngBytes.lengthInBytes,
      );
      await xfile.saveTo(savedPath);

      if (mounted) showScreenshotSavedToast(context, filePath: savedPath);
    } catch (e) {
      if (mounted) _showErrorToast('$e');
    }
  }

  String _ensureFilename(String path, String desiredName) {
    final sep = path.contains(r'\') ? r'\' : '/';
    final last = path.lastIndexOf(sep);
    if (last == -1) return '$path$sep$desiredName';
    return '${path.substring(0, last + 1)}$desiredName';
  }

  void _showCaptureFlash() {
    final overlay = Overlay.of(context);
    late OverlayEntry flashEntry;
    flashEntry = OverlayEntry(
      builder: (_) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.35, end: 0.0),
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
        onEnd: () {
          if (flashEntry.mounted) flashEntry.remove();
        },
        builder: (context, value, _) => IgnorePointer(
          child: Container(
            color: Colors.white.withValues(alpha: value),
          ),
        ),
      ),
    );
    overlay.insert(flashEntry);
  }

  void _showSavedToast(String path) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => Positioned(
        bottom: 32,
        left: 0,
        right: 0,
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) => Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: Transform.scale(
                  scale: 0.92 + 0.08 * value,
                  child: child,
                ),
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 380),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF131A24)
                      : const Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.black.withValues(alpha: 0.06),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 32,
                      offset: const Offset(0, 8),
                    ),
                    if (isDark)
                      BoxShadow(
                        color: ColorTokens.success.withValues(alpha: 0.08),
                        blurRadius: 40,
                        spreadRadius: -4,
                      ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 3,
                      margin: const EdgeInsets.symmetric(horizontal: 40),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            ColorTokens.success.withValues(alpha: 0.0),
                            ColorTokens.success,
                            ColorTokens.success.withValues(alpha: 0.0),
                          ],
                        ),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  ColorTokens.success.withValues(alpha: 0.2),
                                  ColorTokens.success.withValues(alpha: 0.08),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: ColorTokens.success
                                    .withValues(alpha: 0.2),
                              ),
                            ),
                            child: const Icon(
                              LucideIcons.checkCheck,
                              size: 18,
                              color: ColorTokens.success,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextComponent(
                                  S.of(context).screenshotSaved,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? ColorTokens.lightBackground
                                        : const Color(0xFF1E293B),
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                TextComponent(
                                  path.split('/').last,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontFamily: AppConstants.monoFontFamily,
                                    color: isDark
                                        ? Colors.grey[500]
                                        : Colors.grey[600],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          PressableButton(
                            onTap: () {
                              entry.remove();
                              Process.run('open', ['-R', path]);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isDark
                                      ? [
                                          const Color(0xFF1A2332),
                                          const Color(0xFF1E2A3A),
                                        ]
                                      : [
                                          const Color(0xFFF0F4F8),
                                          const Color(0xFFE8EDF2),
                                        ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.1)
                                      : Colors.black.withValues(alpha: 0.08),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    LucideIcons.folderOpen,
                                    size: 13,
                                    color: isDark
                                        ? ColorTokens.lightBackground
                                        : const Color(0xFF374151),
                                  ),
                                  const SizedBox(width: 6),
                                  TextComponent(
                                    S.of(context).reveal,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: isDark
                                          ? ColorTokens.lightBackground
                                          : const Color(0xFF374151),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          PressableButton(
                            onTap: () => entry.remove(),
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.04)
                                    : Colors.black.withValues(alpha: 0.04),
                              ),
                              child: Icon(LucideIcons.x,
                                  size: 13,
                                  color: isDark
                                      ? Colors.grey[600]
                                      : Colors.grey[400]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 5), () {
      if (entry.mounted) entry.remove();
    });
  }

  void _showErrorToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: TextComponent('Screenshot failed: $message'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _takeFullScreenshot() async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final capture = _buildScreenshotWidget(theme, isDark);
    final fileName = _buildEventScreenshotName('_full');
    await _captureAndSave(capture, fileName: fileName);
  }

  /// Builds a descriptive file name for event screenshots:
  /// `<type>_<keyOrTitle>_<isoTimestamp>_<suffix>.png`
  String _buildEventScreenshotName(String suffix) {
    final event = widget.event;
    final type = event.type.name;

    String subject = event.title;
    if (event.rawData is StorageEntry) {
      subject = (event.rawData as StorageEntry).key;
    } else if (event.rawData is NetworkEntry) {
      final url = (event.rawData as NetworkEntry).url;
      try {
        subject = Uri.parse(url).path.isEmpty ? url : Uri.parse(url).path;
      } catch (_) {
        subject = url;
      }
    } else if (event.rawData is LogEntry) {
      final tag = (event.rawData as LogEntry).tag;
      if (tag != null && tag.isNotEmpty) subject = tag;
    } else if (event.rawData is StateChange) {
      final sc = event.rawData as StateChange;
      subject = sc.actionName.isNotEmpty
          ? sc.actionName
          : sc.stateManagerType;
    }

    return buildRichScreenshotName(
      type: type,
      subject: subject,
      suffix: suffix,
    );
  }

  Future<void> _takeTabScreenshot() async {
    await _captureLiveContent();
  }

  /// Captures the currently visible content (with user's expand/collapse state).
  Future<void> _captureLiveContent() async {
    try {
      _showCaptureFlash();

      final boundary = _contentKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final pngBytes = byteData.buffer.asUint8List();
      final fileName =
          'dcmt_${DateTime.now().millisecondsSinceEpoch}.png';
      final location = await getSaveLocation(
        suggestedName: fileName,
        acceptedTypeGroups: [
          const XTypeGroup(label: 'PNG Image', extensions: ['png']),
        ],
      );
      if (location == null) return;

      final file = File(location.path);
      await file.writeAsBytes(pngBytes);
      if (mounted) _showSavedToast(file.path);
    } catch (e) {
      if (mounted) _showErrorToast('$e');
    }
  }

  /// Builds the full detail widget for screenshot (no scroll constraints).
  Widget _buildScreenshotWidget(ThemeData theme, bool isDark) {
    final event = widget.event;
    final time = DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(
      DateTime.fromMillisecondsSinceEpoch(event.timestamp),
    );

    Color typeColor;
    IconData typeIcon;
    String typeLabel;
    switch (event.type) {
      case EventType.log:
        typeColor = ColorTokens.logInfo;
        typeIcon = LucideIcons.terminal;
        typeLabel = S.of(context).logDetail;
        break;
      case EventType.network:
        typeColor = ColorTokens.success;
        typeIcon = LucideIcons.globe;
        typeLabel = S.of(context).networkDetail;
        break;
      case EventType.state:
        typeColor = ColorTokens.secondary;
        typeIcon = LucideIcons.layers;
        typeLabel = S.of(context).stateDetail;
        break;
      case EventType.storage:
        typeColor = ColorTokens.warning;
        typeIcon = LucideIcons.database;
        typeLabel = S.of(context).storageDetail;
        break;
      case EventType.display:
        typeColor = const Color(0xFF9B59B6);
        typeIcon = LucideIcons.monitor;
        typeLabel = S.of(context).displayDetail;
        break;
      case EventType.asyncOp:
        typeColor = const Color(0xFFE67E22);
        typeIcon = LucideIcons.zap;
        typeLabel = S.of(context).asyncOperation;
        break;
      case EventType.error:
        typeColor = Colors.red;
        typeIcon = LucideIcons.alertTriangle;
        typeLabel = S.of(context).errorDetail;
        break;
    }

    return Container(
      color: isDark ? ColorTokens.darkSurface : ColorTokens.lightSurface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: isDark ? ColorTokens.darkBackground : Colors.white,
            ),
            child: Row(
              children: [
                Icon(typeIcon, size: 14, color: typeColor),
                const SizedBox(width: 8),
                TextComponent(
                  typeLabel,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: typeColor,
                  ),
                ),
                const Spacer(),
                TextComponent(
                  time,
                  style: TextStyle(
                    fontFamily: AppConstants.monoFontFamily,
                    fontSize: 10,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          _buildScreenshotContent(isDark),
        ],
      ),
    );
  }

  /// Content for screenshot — no SingleChildScrollView, no Expanded.
  /// Tabbed views are rendered as stacked sections.
  Widget _buildScreenshotContent(bool isDark) {
    switch (widget.event.type) {
      case EventType.log:
        if (widget.event.rawData is LogEntry) {
          return _logScreenshot(widget.event.rawData as LogEntry, isDark);
        }
        return _fallbackScreenshot(widget.event, isDark);
      case EventType.network:
        if (widget.event.rawData is NetworkEntry) {
          return _networkScreenshot(
              widget.event.rawData as NetworkEntry, isDark);
        }
        return _fallbackScreenshot(widget.event, isDark);
      case EventType.state:
        if (widget.event.rawData is StateChange) {
          return _stateScreenshot(
              widget.event.rawData as StateChange, isDark);
        }
        return _fallbackScreenshot(widget.event, isDark);
      case EventType.storage:
        if (widget.event.rawData is StorageEntry) {
          return _storageScreenshot(
              widget.event.rawData as StorageEntry, isDark);
        }
        return _fallbackScreenshot(widget.event, isDark);
      case EventType.display:
      case EventType.asyncOp:
      case EventType.error:
        return _fallbackScreenshot(widget.event, isDark);
    }
  }

  Widget _logScreenshot(LogEntry entry, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            LogLevelBadge(level: entry.level.name),
            if (entry.tag != null) ...[
              const SizedBox(width: 8),
              TagChip(entry.tag!),
            ],
          ]),
          const SizedBox(height: 16),
          const SectionLabel('Message'),
          const SizedBox(height: 6),
          CodeBlock(text: entry.message, isDark: isDark),
          if (entry.metadata != null && entry.metadata!.isNotEmpty) ...[
            const SizedBox(height: 16),
            const SectionLabel('Metadata'),
            const SizedBox(height: 6),
            JsonViewer(data: entry.metadata, initiallyExpanded: true),
          ],
          if (entry.stackTrace != null) ...[
            const SizedBox(height: 16),
            const SectionLabel('Stack Trace'),
            const SizedBox(height: 6),
            ErrorBlock(text: entry.stackTrace!, isDark: isDark),
          ],
        ],
      ),
    );
  }

  Widget _networkScreenshot(NetworkEntry entry, bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? ColorTokens.darkBackground : Colors.white,
            border: Border(
              bottom: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.06),
              ),
            ),
          ),
          child: Row(
            children: [
              HttpMethodBadge(method: entry.method),
              const SizedBox(width: 8),
              if (entry.isComplete) ...[
                StatusBadge(statusCode: entry.statusCode),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: TextComponent(
                  formatUrlPretty(entry.url),
                  style: TextStyle(
                    fontFamily: AppConstants.monoFontFamily,
                    fontSize: 11,
                    height: 1.35,
                    color:
                        isDark ? ColorTokens.lightBackground : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (entry.duration != null)
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TimingBar(duration: entry.duration!),
          ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionLabel('REQUEST HEADERS'),
              const SizedBox(height: 8),
              HeaderTable(headers: entry.requestHeaders, isScreenshot: true),
              const SizedBox(height: 20),
              const SectionLabel('RESPONSE HEADERS'),
              const SizedBox(height: 8),
              HeaderTable(headers: entry.responseHeaders, isScreenshot: true),
            ],
          ),
        ),
        const Divider(height: 1),
        if (entry.requestBody != null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionLabel('REQUEST BODY'),
                const SizedBox(height: 8),
                if (_currentJsonMode ||
                    !(entry.requestBody is Map || entry.requestBody is List))
                  JsonPrettyViewer(data: entry.requestBody)
                else
                  JsonViewer(
                      data: entry.requestBody, initiallyExpanded: true),
              ],
            ),
          ),
        if (entry.requestBody != null) const Divider(height: 1),
        if (entry.responseBody != null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionLabel('RESPONSE BODY'),
                const SizedBox(height: 8),
                if (_currentJsonMode ||
                    !(entry.responseBody is Map || entry.responseBody is List))
                  JsonPrettyViewer(data: entry.responseBody)
                else
                  JsonViewer(
                      data: entry.responseBody, initiallyExpanded: true),
              ],
            ),
          ),
        if (entry.responseBody != null) const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionLabel('TIMING'),
              const SizedBox(height: 8),
              InfoRow(
                'Start Time',
                DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(
                  DateTime.fromMillisecondsSinceEpoch(entry.startTime),
                ),
              ),
              if (entry.endTime != null)
                InfoRow(
                  'End Time',
                  DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(
                    DateTime.fromMillisecondsSinceEpoch(entry.endTime!),
                  ),
                ),
              if (entry.duration != null)
                InfoRow('Duration', formatDuration(entry.duration!)),
              if (entry.error != null) ...[
                const SizedBox(height: 12),
                const SectionLabel('Error'),
                const SizedBox(height: 6),
                ErrorBlock(text: entry.error!, isDark: isDark),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _stateScreenshot(StateChange entry, bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              TagChip(entry.stateManagerType,
                  color: ColorTokens.secondary),
              const SizedBox(width: 8),
              Expanded(
                child: TextComponent(
                  entry.actionName,
                  style: const TextStyle(
                    fontFamily: AppConstants.monoFontFamily,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        if (entry.diff.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionLabel('DIFF'),
                const SizedBox(height: 8),
                ...entry.diff.map((d) => DiffRow(diff: d)),
              ],
            ),
          ),
        if (entry.diff.isNotEmpty) const Divider(height: 1),
        if (entry.previousState.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionLabel('PREVIOUS STATE'),
                const SizedBox(height: 8),
                JsonViewer(
                    data: entry.previousState, initiallyExpanded: true),
              ],
            ),
          ),
        if (entry.previousState.isNotEmpty) const Divider(height: 1),
        if (entry.nextState.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionLabel('NEXT STATE'),
                const SizedBox(height: 8),
                JsonViewer(
                    data: entry.nextState, initiallyExpanded: true),
              ],
            ),
          ),
      ],
    );
  }

  Widget _storageScreenshot(StorageEntry entry, bool isDark) {
    Color opColorFor(StorageEntry e) {
      switch (e.operation.toLowerCase()) {
        case 'write':
          return const Color(0xFF34D399);
        case 'read':
          return const Color(0xFF60A5FA);
        case 'delete':
        case 'clear':
          return const Color(0xFFF87171);
        default:
          return const Color(0xFFFBBF24);
      }
    }

    final devices = ProviderScope.containerOf(context, listen: false)
        .read(connectedDevicesProvider);
    final platform = devices
            .where((d) => d.deviceId == entry.deviceId)
            .map((d) => d.platform)
            .firstOrNull ??
        'react_native';
    final codeLang = CodeGenerator.langForPlatform(platform);
    final codeLabel = CodeGenerator.labelFor(codeLang);

    final mode = ProviderScope.containerOf(context, listen: false)
        .read(bodyViewModeProvider);

    final labelColor = isDark ? Colors.grey[500] : Colors.grey[600];
    final dividerColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.06);

    String formatShape() {
      final v = entry.value;
      if (v == null) return 'null';
      if (v is Map) return 'Map · ${v.length} ${v.length == 1 ? "key" : "keys"}';
      if (v is List) return 'List · ${v.length} ${v.length == 1 ? "item" : "items"}';
      if (v is String) {
        if (v.isEmpty) return 'String · empty';
        final t = v.trim();
        if ((t.startsWith('{') && t.endsWith('}')) ||
            (t.startsWith('[') && t.endsWith(']'))) {
          return 'String · JSON-shaped';
        }
        return 'String';
      }
      return v.runtimeType.toString();
    }

    String formatSize() {
      final raw = entry.value is String
          ? entry.value as String
          : const JsonEncoder.withIndent('  ').convert(entry.value);
      return AppConstants.formatBytes(raw.length);
    }

    dynamic parseJson() {
      final v = entry.value;
      if (v is! String) return null;
      try {
        final p = jsonDecode(v);
        if (p is Map || p is List) return p;
      } catch (_) {}
      return null;
    }

    dynamic displayValue() {
      final v = entry.value;
      if (v is Map || v is List) return v;
      return parseJson() ?? v;
    }

    bool isJsonLike() {
      final v = entry.value;
      if (v is Map || v is List) return true;
      return parseJson() != null;
    }

    Widget buildValueWidget() {
      if (!isJsonLike()) {
        return CodeBlock(text: '${entry.value}', isDark: isDark);
      }
      final value = displayValue();
      return switch (mode) {
        BodyViewMode.tree =>
          JsonViewer(data: value, initiallyExpanded: true),
        BodyViewMode.json => JsonPrettyViewer(data: value),
        BodyViewMode.code => CodeViewer(
            generated: CodeGenerator.generate(value, codeLang),
            lang: codeLang,
            languageLabel: codeLabel,
          ),
      };
    }

    final monoPrimary = TextStyle(
      fontFamily: AppConstants.monoFontFamily,
      fontSize: 13,
      height: 1.5,
      color: isDark ? const Color(0xFFE8E8E8) : const Color(0xFF1A1A1A),
    );
    final monoSecondary = TextStyle(
      fontFamily: AppConstants.monoFontFamily,
      fontSize: 11,
      height: 1.5,
      color: labelColor,
    );
    final metaLabelStyle = TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.2,
      color: labelColor,
    );

    Widget metaCell(String label, String value, TextStyle valueStyle,
            {bool monospace = false}) =>
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextComponent(label, style: metaLabelStyle),
            const SizedBox(height: 4),
            TextComponent(
              value,
              style: monospace
                  ? valueStyle.copyWith(fontFamily: AppConstants.monoFontFamily)
                  : valueStyle,
            ),
          ],
        );

    return Container(
      color: isDark ? ColorTokens.darkSurface : ColorTokens.lightSurface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                OpBadge(label: entry.operation, color: opColorFor(entry)),
                const SizedBox(width: 8),
                TypeBadge(label: entry.storageType.name),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextComponent('METADATA', style: metaLabelStyle),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: metaCell('SHAPE', formatShape(), monoPrimary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: metaCell('SIZE', formatSize(), monoPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: metaCell(
                          'DEVICE', entry.deviceId, monoSecondary,
                          monospace: true),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: metaCell(
                        'CAPTURED',
                        DateFormat('HH:mm:ss.SSS').format(
                          DateTime.fromMillisecondsSinceEpoch(
                              entry.timestamp),
                        ),
                        monoPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
            child: Container(height: 1, color: dividerColor),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionLabel('Key'),
                const SizedBox(height: 6),
                CodeBlock(text: entry.key, isDark: isDark),
              ],
            ),
          ),
          if (entry.value != null) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionLabel('Value'),
                  const SizedBox(height: 6),
                  buildValueWidget(),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _fallbackScreenshot(UnifiedEvent event, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('Title'),
          const SizedBox(height: 6),
          CodeBlock(text: event.title, isDark: isDark),
          const SizedBox(height: 16),
          const SectionLabel('Details'),
          const SizedBox(height: 6),
          CodeBlock(text: event.subtitle, isDark: isDark),
          if (event.rawData != null) ...[
            const SizedBox(height: 16),
            const SectionLabel('Raw Data'),
            const SizedBox(height: 6),
            if (event.rawData is Map || event.rawData is List)
              JsonViewer(data: event.rawData, initiallyExpanded: true)
            else
              CodeBlock(text: '${event.rawData}', isDark: isDark),
          ],
        ],
      ),
    );
  }

  Widget _buildTabScreenshotWidget(
      ThemeData theme, bool isDark, int tabIndex) {
    final event = widget.event;
    final time = DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(
      DateTime.fromMillisecondsSinceEpoch(event.timestamp),
    );

    final (typeColor, typeIcon, typeLabel) =
        DetailHeader.staticTypeDetails(event.type);

    final header = Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: isDark ? ColorTokens.darkBackground : Colors.white,
      ),
      child: Row(
        children: [
          Icon(typeIcon, size: 14, color: typeColor),
          const SizedBox(width: 8),
          TextComponent(typeLabel,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: typeColor)),
          const SizedBox(width: 10),
          TextComponent(time,
              style: TextStyle(
                  fontFamily: AppConstants.monoFontFamily,
                  fontSize: 10,
                  color: Colors.grey[500])),
        ],
      ),
    );

    Widget tabContent;
    if (event.type == EventType.network && event.rawData is NetworkEntry) {
      final entry = event.rawData as NetworkEntry;
      final urlBar = Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? ColorTokens.darkBackground : Colors.white,
          border: Border(
            bottom: BorderSide(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.06),
            ),
          ),
        ),
        child: Row(
          children: [
            HttpMethodBadge(method: entry.method),
            const SizedBox(width: 8),
            if (entry.isComplete) ...[
              StatusBadge(statusCode: entry.statusCode),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: TextComponent(formatUrlPretty(entry.url),
                  style: TextStyle(
                      fontFamily: AppConstants.monoFontFamily,
                      fontSize: 11,
                      height: 1.35,
                      color: isDark
                          ? ColorTokens.lightBackground
                          : Colors.black87),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      );
      final timingBar = entry.duration != null
          ? Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: TimingBar(duration: entry.duration!),
            )
          : null;

      const tabNames = ['Headers', 'Request', 'Response', 'Timing'];
      final tabLabel = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: SectionLabel(tabNames[tabIndex]),
      );

      Widget body;
      switch (tabIndex) {
        case 0:
          body = Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionLabel('Request Headers'),
                const SizedBox(height: 8),
                HeaderTable(headers: entry.requestHeaders, isScreenshot: true),
                const SizedBox(height: 20),
                const SectionLabel('Response Headers'),
                const SizedBox(height: 8),
                HeaderTable(headers: entry.responseHeaders, isScreenshot: true),
              ],
            ),
          );
          break;
        case 1:
          body = _buildBodyScreenshot(
              entry.requestBody, 'Request Body', isDark);
          break;
        case 2:
          body = _buildBodyScreenshot(
              entry.responseBody, 'Response Body', isDark);
          break;
        case 3:
        default:
          body = Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InfoRow(
                  'Start Time',
                  DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(
                    DateTime.fromMillisecondsSinceEpoch(entry.startTime),
                  ),
                ),
                if (entry.endTime != null)
                  InfoRow(
                    'End Time',
                    DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(
                      DateTime.fromMillisecondsSinceEpoch(entry.endTime!),
                    ),
                  ),
                if (entry.duration != null)
                  InfoRow('Duration', formatDuration(entry.duration!)),
                if (entry.error != null) ...[
                  const SizedBox(height: 12),
                  const SectionLabel('Error'),
                  const SizedBox(height: 6),
                  ErrorBlock(text: entry.error!, isDark: isDark),
                ],
              ],
            ),
          );
          break;
      }

      tabContent = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          urlBar,
          if (timingBar != null) timingBar,
          const Divider(height: 1),
          tabLabel,
          body,
        ],
      );
    } else if (event.type == EventType.state &&
        event.rawData is StateChange) {
      final entry = event.rawData as StateChange;
      const tabNames = ['Diff', 'Previous', 'Next'];
      Widget body;
      switch (tabIndex) {
        case 0:
          body = entry.diff.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: TextComponent('No diff'))
              : Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children:
                        entry.diff.map((d) => DiffRow(diff: d)).toList(),
                  ),
                );
          break;
        case 1:
          body = _buildBodyScreenshot(
              entry.previousState.isEmpty ? null : entry.previousState,
              'Previous State',
              isDark);
          break;
        case 2:
        default:
          body = _buildBodyScreenshot(
              entry.nextState.isEmpty ? null : entry.nextState,
              'Next State',
              isDark);
          break;
      }
      tabContent = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SectionLabel(tabNames[tabIndex]),
          ),
          body,
        ],
      );
    } else {
      tabContent = _buildScreenshotContent(isDark);
    }

    return Container(
      color: isDark ? ColorTokens.darkSurface : ColorTokens.lightSurface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header,
          const Divider(height: 1),
          tabContent,
        ],
      ),
    );
  }

  Widget _buildBodyScreenshot(dynamic body, String label, bool isDark) {
    if (body == null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: TextComponent('No $label',
            style: TextStyle(color: Colors.grey[500], fontSize: 12)),
      );
    }
    dynamic parsed = body;
    if (parsed is String) {
      try {
        parsed = jsonDecode(parsed);
      } catch (_) {}
    }
    final useJson = _currentJsonMode;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel(label),
          const SizedBox(height: 8),
          if (useJson || !(parsed is Map || parsed is List))
            JsonPrettyViewer(data: parsed)
          else
            JsonViewer(data: parsed, initiallyExpanded: true),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: isDark ? ColorTokens.darkSurface : ColorTokens.lightSurface,
      child: Column(
        children: [
          DetailHeader(
            event: widget.event,
            onClose: widget.onClose,
            onFullScreenshot: _takeFullScreenshot,
            onTabScreenshot: _takeTabScreenshot,
            hasMultipleTabs: widget.event.type == EventType.network ||
                widget.event.type == EventType.state,
          ),
          const Divider(height: 1),
          Expanded(
            child: RepaintBoundary(
              key: _contentKey,
              child: _buildContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (widget.event.type) {
      case EventType.log:
        if (widget.event.rawData is LogEntry) {
          return LogDetail(entry: widget.event.rawData as LogEntry);
        }
        return FallbackDetail(event: widget.event);
      case EventType.network:
        if (widget.event.rawData is NetworkEntry) {
          return NetworkDetail(
            entry: widget.event.rawData as NetworkEntry,
            onTabChanged: (i) => _currentTabIndex = i,
            onJsonModeChanged: (v) => _currentJsonMode = v,
          );
        }
        return FallbackDetail(event: widget.event);
      case EventType.state:
        if (widget.event.rawData is StateChange) {
          return StateDetail(
            entry: widget.event.rawData as StateChange,
            onTabChanged: (i) => _currentTabIndex = i,
            onJsonModeChanged: (v) => _currentJsonMode = v,
          );
        }
        return FallbackDetail(event: widget.event);
      case EventType.storage:
        if (widget.event.rawData is StorageEntry) {
          return StorageDetail(
            entry: widget.event.rawData as StorageEntry,
          );
        }
        return FallbackDetail(event: widget.event);
      case EventType.display:
      case EventType.asyncOp:
        return FallbackDetail(event: widget.event);
      case EventType.error:
        if (widget.event.rawData is ErrorEvent) {
          return ErrorDetail(entry: widget.event.rawData as ErrorEvent);
        }
        return FallbackDetail(event: widget.event);
    }
  }
}