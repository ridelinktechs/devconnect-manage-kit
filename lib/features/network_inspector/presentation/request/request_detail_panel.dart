import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
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
import '../../../../models/network/network_entry.dart';
import '../../../../server/providers/server_providers.dart';
import '../detail/body_tab.dart';
import '../detail/headers_tab.dart';
import '../detail/timing_tab.dart';
import '../shared/copy_action_chip.dart';
import '../shared/detail_tab_bar.dart';
import '../shared/detect_blob_payload.dart';
import '../shared/header_icon_button.dart';

/// Right-pane detail panel that swaps content based on the selected
/// network request. Owns the screenshot machinery (full + per-tab) and
/// the capture flash/saved-toast overlays. Routes per-tab content to
/// [HeadersTab] / [BodyTab] / [TimingTab].
class RequestDetailPanel extends ConsumerStatefulWidget {
  final NetworkEntry entry;
  final VoidCallback onClose;

  const RequestDetailPanel({
    super.key,
    required this.entry,
    required this.onClose,
  });

  @override
  ConsumerState<RequestDetailPanel> createState() =>
      _RequestDetailPanelState();
}

class _RequestDetailPanelState extends ConsumerState<RequestDetailPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      animationDuration: ref.read(tabAnimationProvider),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _rebuildController() {
    final oldIndex = _tabController.index;
    _tabController.dispose();
    _tabController = TabController(
      length: 4,
      vsync: this,
      animationDuration: ref.read(tabAnimationProvider),
      initialIndex: oldIndex,
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final entry = widget.entry;

    ref.listen(tabAnimationProvider, (prev, next) {
      if (prev != next) _rebuildController();
    });

    return Column(
      children: [
        // ---- Header bar ----
        Container(
          color: isDark ? ColorTokens.darkBackground : Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Method + status + URL + screenshot buttons + close
              Padding(
                padding:
                    const EdgeInsets.only(left: 12, right: 4, top: 8, bottom: 4),
                child: Row(
                  children: [
                    HttpMethodBadge(method: entry.method),
                    const SizedBox(width: 6),
                    if (entry.isComplete) ...[
                      StatusBadge(statusCode: entry.statusCode),
                      const SizedBox(width: 8),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: ColorTokens.warning.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 10,
                              height: 10,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                color: ColorTokens.warning,
                              ),
                            ),
                            const SizedBox(width: 5),
                            TextComponent(
                              S.of(context).inProgressDots,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: ColorTokens.warning,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Tooltip(
                        message: entry.url,
                        waitDuration: const Duration(milliseconds: 300),
                        child: TextComponent(
                          entry.url,
                          style: TextStyle(
                            fontFamily: AppConstants.monoFontFamily,
                            fontSize: 12,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    // Screenshot buttons
                    Tooltip(
                      message: S.of(context).captureFullTooltip,
                      waitDuration: const Duration(milliseconds: 400),
                      child: HeaderIconButton(
                        icon: LucideIcons.camera,
                        tooltip: S.of(context).captureFull,
                        onPressed: _takeFullScreenshot,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Tooltip(
                      message: S.of(context).captureTabTooltip,
                      waitDuration: const Duration(milliseconds: 400),
                      child: HeaderIconButton(
                        icon: LucideIcons.scanLine,
                        tooltip: S.of(context).captureTab,
                        onPressed: _takeTabScreenshot,
                      ),
                    ),
                    const SizedBox(width: 2),
                    // Close button
                    HeaderIconButton(
                      icon: LucideIcons.x,
                      tooltip: S.of(context).close,
                      onPressed: widget.onClose,
                    ),
                  ],
                ),
              ),

              // Timing bar
              if (entry.duration != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: TimingBar(duration: entry.duration!),
                ),

              const SizedBox(height: 6),

              // Copy actions row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    CopyActionChip(
                      icon: LucideIcons.link,
                      label: S.of(context).copyUrl,
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: entry.url));
                        _showCopied(S.of(context).urlCopied);
                      },
                    ),
                    const SizedBox(width: 6),
                    CopyActionChip(
                      icon: LucideIcons.route,
                      label: S.of(context).copyPath,
                      onTap: () {
                        try {
                          final uri = Uri.parse(entry.url);
                          final path = uri.path.isNotEmpty ? uri.path : entry.url;
                          Clipboard.setData(ClipboardData(text: path));
                          _showCopied(S.of(context).pathCopied);
                        } catch (_) {
                          Clipboard.setData(ClipboardData(text: entry.url));
                          _showCopied(S.of(context).pathCopied);
                        }
                      },
                    ),
                    const SizedBox(width: 6),
                    CopyActionChip(
                      icon: LucideIcons.terminal,
                      label: S.of(context).copyCurl,
                      onTap: () {
                        Clipboard.setData(
                            ClipboardData(text: _buildCurl(entry)));
                        _showCopied(S.of(context).curlCopied);
                      },
                    ),
                    const SizedBox(width: 6),
                    CopyActionChip(
                      icon: LucideIcons.upload,
                      label: S.of(context).copyRequest,
                      onTap: () {
                        final body = entry.requestBody;
                        final text = body is String
                            ? body
                            : (body != null
                                ? const JsonEncoder.withIndent('  ')
                                    .convert(body)
                                : '');
                        Clipboard.setData(ClipboardData(text: text));
                        _showCopied(S.of(context).requestCopied);
                      },
                    ),
                    const SizedBox(width: 6),
                    CopyActionChip(
                      icon: LucideIcons.download,
                      label: S.of(context).copyResponse,
                      onTap: () {
                        final body = entry.responseBody;
                        final text = body is String
                            ? body
                            : (body != null
                                ? const JsonEncoder.withIndent('  ')
                                    .convert(body)
                                : '');
                        Clipboard.setData(ClipboardData(text: text));
                        _showCopied(S.of(context).responseCopied);
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Tabs
              DetailTabBar(
                controller: _tabController,
                isDark: isDark,
                accentColor: ColorTokens.primary,
                tabs: const ['Headers', 'Request', 'Response', 'Timing'],
              ),
            ],
          ),
        ),

        // ---- Tab views ----
        Expanded(
          child: Container(
            color: isDark ? ColorTokens.darkSurface : ColorTokens.lightSurface,
            child: TabBarView(
              controller: _tabController,
              children: [
                LazyTab(
                  controller: _tabController,
                  index: 0,
                  builder: (_) => HeadersTab(entry: entry),
                ),
                LazyTab(
                  controller: _tabController,
                  index: 1,
                  builder: (_) => BodyTab(
                    body: entry.requestBody,
                    label: 'Request',
                    deviceId: entry.deviceId,
                  ),
                ),
                LazyTab(
                  controller: _tabController,
                  index: 2,
                  builder: (_) => BodyTab(
                    body: entry.responseBody,
                    label: 'Response',
                    deviceId: entry.deviceId,
                  ),
                ),
                LazyTab(
                  controller: _tabController,
                  index: 3,
                  builder: (_) => TimingTab(entry: entry),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ---- Screenshot ----

  Future<void> _captureAndSave(Widget screenshotWidget, {String? fileName}) async {
    try {
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
      await Future.delayed(const Duration(milliseconds: 300));

      final boundary = overlayKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) {
        overlayEntry.remove();
        return;
      }

      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      overlayEntry.remove();

      if (byteData == null) return;

      final pngBytes = byteData.buffer.asUint8List();
      final baseName = (fileName == null || fileName.isEmpty)
          ? 'devconnect_network_${DateTime.now().millisecondsSinceEpoch}'
          : fileName;
      final outName =
          baseName.endsWith('.png') ? baseName : '$baseName.png';
      final location = await getSaveLocation(
        suggestedName: outName,
        acceptedTypeGroups: [
          const XTypeGroup(label: 'PNG Image', extensions: ['png']),
        ],
      );

      if (location == null) return;

      final file = File(location.path);
      await file.writeAsBytes(pngBytes);

      if (mounted) _showSavedToast(file.path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: TextComponent('Screenshot failed: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
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
                          GestureDetector(
                            onTap: () {
                              entry.remove();
                              Process.run('open', ['-R', path]);
                            },
                            child: MouseRegion(
                              cursor: SystemMouseCursors.click,
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
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () => entry.remove(),
                            child: MouseRegion(
                              cursor: SystemMouseCursors.click,
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

  Future<void> _takeFullScreenshot() async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final subject = _urlPath(widget.entry.url);
    final fileName = buildRichScreenshotName(
      type: 'network',
      subject: subject,
      suffix: '_full',
    );
    await _captureAndSave(_buildFullScreenshotWidget(isDark),
        fileName: fileName);
  }

  Future<void> _takeTabScreenshot() async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final subject = _urlPath(widget.entry.url);
    final fileName = buildRichScreenshotName(
      type: 'network',
      subject: subject,
      suffix: '_tab',
    );
    await _captureAndSave(
        _buildTabScreenshotWidget(isDark, _tabController.index),
        fileName: fileName);
  }

  String _urlPath(String url) {
    try {
      final p = Uri.parse(url).path;
      return p.isEmpty ? url : p;
    } catch (_) {
      return url;
    }
  }

  Widget _buildFullScreenshotWidget(bool isDark) {
    final entry = widget.entry;
    final time = DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(
      DateTime.fromMillisecondsSinceEpoch(entry.startTime),
    );

    dynamic parsedReqBody = entry.requestBody;
    if (parsedReqBody is String) {
      try {
        parsedReqBody = jsonDecode(parsedReqBody);
      } catch (_) {}
    }
    final reqIsBlob = detectBlobPayload(parsedReqBody);
    dynamic parsedResBody = entry.responseBody;
    if (parsedResBody is String) {
      try {
        parsedResBody = jsonDecode(parsedResBody);
      } catch (_) {}
    }
    final resIsBlob = detectBlobPayload(parsedResBody);

    return Container(
      color: isDark ? ColorTokens.darkSurface : ColorTokens.lightSurface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            color: isDark ? ColorTokens.darkBackground : Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    HttpMethodBadge(method: entry.method),
                    const SizedBox(width: 6),
                    if (entry.isComplete)
                      StatusBadge(statusCode: entry.statusCode),
                    const Spacer(),
                    TextComponent(time,
                        style: TextStyle(
                            fontSize: 10,
                            fontFamily: AppConstants.monoFontFamily,
                            color: Colors.grey[500])),
                  ],
                ),
                const SizedBox(height: 6),
                TextComponent(entry.url,
                    style: TextStyle(
                      fontFamily: AppConstants.monoFontFamily,
                      fontSize: 11,
                      color: (entry.isComplete &&
                              (entry.statusCode <= 0 ||
                                  entry.statusCode >= 400))
                          ? ColorTokens.error
                          : isDark
                              ? ColorTokens.lightBackground
                              : ColorTokens.darkNeutral,
                    )),
                if (entry.duration != null) ...[
                  const SizedBox(height: 6),
                  TimingBar(duration: entry.duration!),
                ],
              ],
            ),
          ),
          const Divider(height: 1),
          // Headers section
          _screenshotSection('Request Headers', isDark),
          ...entry.requestHeaders.entries.map((e) =>
              _screenshotHeaderRow(e.key, e.value, isDark)),
          if (entry.responseHeaders.isNotEmpty) ...[
            _screenshotSection('Response Headers', isDark),
            ...entry.responseHeaders.entries.map((e) =>
                _screenshotHeaderRow(e.key, e.value, isDark)),
          ],
          // Request body
          if (parsedReqBody != null) ...[
            _screenshotSection('Request Body', isDark),
            Padding(
              padding: const EdgeInsets.all(12),
              child: reqIsBlob.$1 != null
                  ? _screenshotBlobNote(reqIsBlob, isDark)
                  : parsedReqBody is Map || parsedReqBody is List
                      ? JsonViewer(data: parsedReqBody, initiallyExpanded: true)
                      : JsonPrettyViewer(data: parsedReqBody),
            ),
          ],
          // Response body
          if (parsedResBody != null) ...[
            _screenshotSection('Response Body', isDark),
            Padding(
              padding: const EdgeInsets.all(12),
              child: resIsBlob.$1 != null
                  ? _screenshotBlobNote(resIsBlob, isDark)
                  : parsedResBody is Map || parsedResBody is List
                      ? JsonViewer(data: parsedResBody, initiallyExpanded: true)
                      : JsonPrettyViewer(data: parsedResBody),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTabScreenshotWidget(bool isDark, int tabIndex) {
    final entry = widget.entry;
    const tabNames = ['Headers', 'Request', 'Response', 'Timing'];

    Widget tabContent;
    switch (tabIndex) {
      case 0: // Headers
        tabContent = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _screenshotSection('Request Headers', isDark),
            ...entry.requestHeaders.entries.map((e) =>
                _screenshotHeaderRow(e.key, e.value, isDark)),
            if (entry.responseHeaders.isNotEmpty) ...[
              _screenshotSection('Response Headers', isDark),
              ...entry.responseHeaders.entries.map((e) =>
                  _screenshotHeaderRow(e.key, e.value, isDark)),
            ],
          ],
        );
        break;
      case 1: // Request body
        tabContent = _buildBodyScreenshot(
            entry.requestBody, 'Request Body', isDark);
        break;
      case 2: // Response body
        tabContent = _buildBodyScreenshot(
            entry.responseBody, 'Response Body', isDark);
        break;
      case 3: // Timing
      default:
        tabContent = Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (entry.duration != null) ...[
                TextComponent('Duration: ${formatDuration(entry.duration!)}',
                    style: TextStyle(
                        fontFamily: AppConstants.monoFontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87)),
                const SizedBox(height: 8),
                TimingBar(duration: entry.duration!),
              ],
              const SizedBox(height: 8),
              TextComponent(
                  'Start: ${DateFormat('HH:mm:ss.SSS').format(DateTime.fromMillisecondsSinceEpoch(entry.startTime))}',
                  style: TextStyle(
                      fontFamily: AppConstants.monoFontFamily,
                      fontSize: 11,
                      color: Colors.grey[500])),
              if (entry.endTime != null)
                TextComponent(
                    'End: ${DateFormat('HH:mm:ss.SSS').format(DateTime.fromMillisecondsSinceEpoch(entry.endTime!))}',
                    style: TextStyle(
                        fontFamily: AppConstants.monoFontFamily,
                        fontSize: 11,
                        color: Colors.grey[500])),
            ],
          ),
        );
        break;
    }

    return Container(
      color: isDark ? ColorTokens.darkSurface : ColorTokens.lightSurface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mini header
          Container(
            padding: const EdgeInsets.all(12),
            color: isDark ? ColorTokens.darkBackground : Colors.white,
            child: Row(
              children: [
                HttpMethodBadge(method: entry.method),
                const SizedBox(width: 6),
                if (entry.isComplete)
                  StatusBadge(statusCode: entry.statusCode),
                const SizedBox(width: 8),
                Expanded(
                  child: TextComponent(entry.url,
                      style: TextStyle(
                        fontFamily: AppConstants.monoFontFamily,
                        fontSize: 11,
                        color: isDark
                            ? ColorTokens.lightBackground
                            : ColorTokens.darkNeutral,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: ColorTokens.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: TextComponent(tabNames[tabIndex],
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: ColorTokens.primary)),
                ),
              ],
            ),
          ),
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

    final viewMode = ref.read(bodyViewModeProvider);
    final canToggle = parsed is Map || parsed is List;
    final effectiveMode = canToggle ? viewMode : BodyViewMode.json;

    final devices = ref.read(connectedDevicesProvider);
    final platform = devices
            .where((d) => d.deviceId == widget.entry.deviceId)
            .map((d) => d.platform)
            .firstOrNull ??
        'react_native';
    final codeLang = CodeGenerator.langForPlatform(platform);

    return Padding(
      padding: const EdgeInsets.all(12),
      child: _buildBodyContent(parsed, canToggle, effectiveMode, codeLang),
    );
  }

  Widget _buildBodyContent(
      dynamic parsed, bool canToggle, BodyViewMode mode, CodeLang codeLang) {
    if (!canToggle) return JsonPrettyViewer(data: parsed);
    return DeferredBuilder(
      key: ValueKey(mode),
      builder: (_) {
        switch (mode) {
          case BodyViewMode.tree:
            return JsonViewer(data: parsed, initiallyExpanded: true);
          case BodyViewMode.json:
            return JsonPrettyViewer(data: parsed);
          case BodyViewMode.code:
            return CodeViewer(
              generated: CodeGenerator.generate(parsed, codeLang),
              lang: codeLang,
              languageLabel: CodeGenerator.labelFor(codeLang),
            );
        }
      },
    );
  }

  Widget _screenshotSection(String title, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: isDark ? const Color(0xFF1C2128) : const Color(0xFFEEF0F2),
      child: TextComponent(title,
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.black87)),
    );
  }

  Widget _screenshotHeaderRow(String key, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 180,
            child: TextComponent(key,
                style: TextStyle(
                    fontFamily: AppConstants.monoFontFamily,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? const Color(0xFF9CDCFE)
                        : const Color(0xFF0451A5))),
          ),
          Expanded(
            child: TextComponent(value,
                style: TextStyle(
                    fontFamily: AppConstants.monoFontFamily,
                    fontSize: 11,
                    color: isDark
                        ? const Color(0xFFCE9178)
                        : const Color(0xFFA31515))),
          ),
        ],
      ),
    );
  }

  void _showCopied(String message) {
    showCopiedToast(context, label: message);
  }

  String _buildCurl(NetworkEntry entry) {
    final buf = StringBuffer("curl -X ${entry.method} '${entry.url}'");
    entry.requestHeaders.forEach((k, v) {
      buf.write(" \\\n  -H '$k: $v'");
    });
    if (entry.requestBody != null) {
      final body = entry.requestBody is String
          ? entry.requestBody as String
          : const JsonEncoder().convert(entry.requestBody);
      buf.write(" \\\n  -d '$body'");
    }
    return buf.toString();
  }

  Widget _screenshotBlobNote((String?, int?) blob, bool isDark) {
    final type = blob.$1 ?? 'blob';
    final bytes = blob.$2 ?? 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextComponent(
        '$type payload ($bytes bytes) — binary, cannot be inspected.\nIdentify the action via the X-Amz-Target header.',
        style: TextStyle(
          fontFamily: AppConstants.monoFontFamily,
          fontSize: 11,
          color: isDark ? Colors.white60 : Colors.black54,
        ),
      ),
    );
  }
}