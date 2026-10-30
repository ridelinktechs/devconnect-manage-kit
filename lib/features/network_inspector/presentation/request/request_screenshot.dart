import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../components/misc/status_badge.dart';
import '../../../../components/text/text_component.dart';
import '../../../../components/viewers/json_viewer.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/utils/code/code_generator.dart';
import '../../../../core/utils/format/duration_format.dart';
import '../../../../models/network/network_entry.dart';
import '../detail/timing_tab.dart';
import '../shared/detect_blob_payload.dart';

/// What a request screenshot shows: the whole request, or only the detail
/// panel tab [tabIndex] (headers, request, response, timing). A body tab
/// shows its JSON in [viewMode], its Code view in [codeLang].
class RequestScreenshot extends StatelessWidget {
  final NetworkEntry entry;
  final bool isDark;
  final int? tabIndex;
  final BodyViewMode viewMode;
  final CodeLang codeLang;

  const RequestScreenshot({
    super.key,
    required this.entry,
    required this.isDark,
    this.tabIndex,
    required this.viewMode,
    required this.codeLang,
  });

  @override
  Widget build(BuildContext context) => switch (tabIndex) {
    final index? => _buildTabScreenshotWidget(isDark, index),
    null => _buildFullScreenshotWidget(isDark),
  };

  /// Decode percent-encoded characters so users see `,` instead of
  /// `%2C` etc. — matches the All Events detail panel.
  String _decoded(String url) {
    try {
      return Uri.decodeFull(url);
    } catch (_) {
      return url;
    }
  }

  Widget _buildFullScreenshotWidget(bool isDark) {
    final time = DateFormat(
      'yyyy-MM-dd HH:mm:ss.SSS',
    ).format(DateTime.fromMillisecondsSinceEpoch(entry.startTime));

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
                    TextComponent(
                      time,
                      style: TextStyle(
                        fontSize: 10,
                        fontFamily: AppConstants.monoFontFamily,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                TextComponent(
                  _decoded(entry.url),
                  style: TextStyle(
                    fontFamily: AppConstants.monoFontFamily,
                    fontSize: 11,
                    height: 1.35,
                    color:
                        (entry.isComplete &&
                            (entry.statusCode <= 0 || entry.statusCode >= 400))
                        ? ColorTokens.error
                        : isDark
                        ? ColorTokens.lightBackground
                        : ColorTokens.darkNeutral,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
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
          ...entry.requestHeaders.entries.map(
            (e) => _screenshotHeaderRow(e.key, e.value, isDark),
          ),
          if (entry.responseHeaders.isNotEmpty) ...[
            _screenshotSection('Response Headers', isDark),
            ...entry.responseHeaders.entries.map(
              (e) => _screenshotHeaderRow(e.key, e.value, isDark),
            ),
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
    const tabNames = ['Headers', 'Request', 'Response', 'Timing'];

    Widget tabContent;
    switch (tabIndex) {
      case 0: // Headers
        tabContent = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _screenshotSection('Request Headers', isDark),
            ...entry.requestHeaders.entries.map(
              (e) => _screenshotHeaderRow(e.key, e.value, isDark),
            ),
            if (entry.responseHeaders.isNotEmpty) ...[
              _screenshotSection('Response Headers', isDark),
              ...entry.responseHeaders.entries.map(
                (e) => _screenshotHeaderRow(e.key, e.value, isDark),
              ),
            ],
          ],
        );
        break;
      case 1: // Request body
        tabContent = _buildBodyScreenshot(
          entry.requestBody,
          'Request Body',
          isDark,
        );
        break;
      case 2: // Response body
        tabContent = _buildBodyScreenshot(
          entry.responseBody,
          'Response Body',
          isDark,
        );
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
                TextComponent(
                  'Duration: ${formatDuration(entry.duration!)}',
                  style: TextStyle(
                    fontFamily: AppConstants.monoFontFamily,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                TimingBar(duration: entry.duration!),
              ],
              const SizedBox(height: 8),
              TextComponent(
                'Start: ${DateFormat('HH:mm:ss.SSS').format(DateTime.fromMillisecondsSinceEpoch(entry.startTime))}',
                style: TextStyle(
                  fontFamily: AppConstants.monoFontFamily,
                  fontSize: 11,
                  color: Colors.grey[500],
                ),
              ),
              if (entry.endTime != null)
                TextComponent(
                  'End: ${DateFormat('HH:mm:ss.SSS').format(DateTime.fromMillisecondsSinceEpoch(entry.endTime!))}',
                  style: TextStyle(
                    fontFamily: AppConstants.monoFontFamily,
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
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
                if (entry.isComplete) StatusBadge(statusCode: entry.statusCode),
                const SizedBox(width: 8),
                Expanded(
                  child: TextComponent(
                    _decoded(entry.url),
                    style: TextStyle(
                      fontFamily: AppConstants.monoFontFamily,
                      height: 1.35,
                      fontSize: 11,
                      color: isDark
                          ? ColorTokens.lightBackground
                          : ColorTokens.darkNeutral,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: ColorTokens.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: TextComponent(
                    tabNames[tabIndex],
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: ColorTokens.primary,
                    ),
                  ),
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
        child: TextComponent(
          'No $label',
          style: TextStyle(color: Colors.grey[500], fontSize: 12),
        ),
      );
    }
    dynamic parsed = body;
    if (parsed is String) {
      try {
        parsed = jsonDecode(parsed);
      } catch (_) {}
    }

    final canToggle = parsed is Map || parsed is List;
    final effectiveMode = canToggle ? viewMode : BodyViewMode.json;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: _buildBodyContent(parsed, canToggle, effectiveMode, codeLang),
    );
  }

  Widget _buildBodyContent(
    dynamic parsed,
    bool canToggle,
    BodyViewMode mode,
    CodeLang codeLang,
  ) {
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
      child: TextComponent(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white70 : Colors.black87,
        ),
      ),
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
            child: TextComponent(
              key,
              style: TextStyle(
                fontFamily: AppConstants.monoFontFamily,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? const Color(0xFF9CDCFE)
                    : const Color(0xFF0451A5),
              ),
            ),
          ),
          Expanded(
            child: TextComponent(
              value,
              style: TextStyle(
                fontFamily: AppConstants.monoFontFamily,
                fontSize: 11,
                color: isDark
                    ? const Color(0xFFCE9178)
                    : const Color(0xFFA31515),
              ),
            ),
          ),
        ],
      ),
    );
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
