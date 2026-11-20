import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../components/misc/status_badge.dart';
import '../../../../components/text/text_component.dart';
import '../../../../components/viewers/json_viewer.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/utils/code/code_generator.dart';
import '../../../../core/utils/format/duration_format.dart';
import '../../../../core/utils/network/network_url_formatter.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../models/log/log_entry.dart';
import '../../../../models/network/network_entry.dart';
import '../../../../models/state/state_change.dart';
import '../../../../models/storage/storage_entry.dart';
import '../../../../server/providers/server_providers.dart';
import '../../provider/all_events_provider.dart';
import '../network/headers_view.dart';
import '../shared/code_block.dart';
import '../shared/error_block.dart';
import '../shared/info_row.dart';
import '../shared/op_badge.dart';
import '../shared/section_label.dart';
import '../shared/tag_chip.dart';
import '../shared/type_badge.dart';
import 'diff_row.dart';
import 'network_detail.dart';

/// Full screenshot of [event]; [jsonMode] shows network bodies as pretty JSON.
class EventScreenshot extends StatelessWidget {
  final UnifiedEvent event;
  final bool isDark;
  final bool jsonMode;

  const EventScreenshot({
    super.key,
    required this.event,
    required this.isDark,
    required this.jsonMode,
  });

  @override
  Widget build(BuildContext context) => _buildScreenshotWidget(context, isDark);

  /// Builds the full detail widget for screenshot (no scroll constraints).
  Widget _buildScreenshotWidget(BuildContext context, bool isDark) {
    final time = DateFormat(
      'yyyy-MM-dd HH:mm:ss.SSS',
    ).format(DateTime.fromMillisecondsSinceEpoch(event.timestamp));

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
          _buildScreenshotContent(context, isDark),
        ],
      ),
    );
  }

  /// Content for screenshot — no SingleChildScrollView, no Expanded.
  /// Tabbed views are rendered as stacked sections.
  Widget _buildScreenshotContent(BuildContext context, bool isDark) {
    switch (event.type) {
      case EventType.log:
        if (event.rawData is LogEntry) {
          return _logScreenshot(event.rawData as LogEntry, isDark);
        }
        return _fallbackScreenshot(event, isDark);
      case EventType.network:
        if (event.rawData is NetworkEntry) {
          return _networkScreenshot(event.rawData as NetworkEntry, isDark);
        }
        return _fallbackScreenshot(event, isDark);
      case EventType.state:
        if (event.rawData is StateChange) {
          return _stateScreenshot(event.rawData as StateChange, isDark);
        }
        return _fallbackScreenshot(event, isDark);
      case EventType.storage:
        if (event.rawData is StorageEntry) {
          return _storageScreenshot(
            context,
            event.rawData as StorageEntry,
            isDark,
          );
        }
        return _fallbackScreenshot(event, isDark);
      case EventType.display:
      case EventType.asyncOp:
      case EventType.error:
        return _fallbackScreenshot(event, isDark);
    }
  }

  Widget _logScreenshot(LogEntry entry, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              LogLevelBadge(level: entry.level.name),
              if (entry.tag != null) ...[
                const SizedBox(width: 8),
                TagChip(entry.tag!),
              ],
            ],
          ),
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
                    color: isDark
                        ? ColorTokens.lightBackground
                        : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (entry.duration != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                if (jsonMode ||
                    !(entry.requestBody is Map || entry.requestBody is List))
                  JsonPrettyViewer(data: entry.requestBody)
                else
                  JsonViewer(data: entry.requestBody, initiallyExpanded: true),
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
                if (jsonMode ||
                    !(entry.responseBody is Map || entry.responseBody is List))
                  JsonPrettyViewer(data: entry.responseBody)
                else
                  JsonViewer(data: entry.responseBody, initiallyExpanded: true),
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
                DateFormat(
                  'yyyy-MM-dd HH:mm:ss.SSS',
                ).format(DateTime.fromMillisecondsSinceEpoch(entry.startTime)),
              ),
              if (entry.endTime != null)
                InfoRow(
                  'End Time',
                  DateFormat(
                    'yyyy-MM-dd HH:mm:ss.SSS',
                  ).format(DateTime.fromMillisecondsSinceEpoch(entry.endTime!)),
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
                JsonViewer(data: entry.previousState, initiallyExpanded: true),
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
                JsonViewer(data: entry.nextState, initiallyExpanded: true),
              ],
            ),
          ),
      ],
    );
  }

  Widget _storageScreenshot(
    BuildContext context,
    StorageEntry entry,
    bool isDark,
  ) {
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

    final devices = ProviderScope.containerOf(
      context,
      listen: false,
    ).read(connectedDevicesProvider);
    final platform =
        devices
            .where((d) => d.deviceId == entry.deviceId)
            .map((d) => d.platform)
            .firstOrNull ??
        'react_native';
    final codeLang = CodeGenerator.langForPlatform(platform);
    final codeLabel = CodeGenerator.labelFor(codeLang);

    final mode = ProviderScope.containerOf(
      context,
      listen: false,
    ).read(bodyViewModeProvider);

    final labelColor = isDark ? Colors.grey[500] : Colors.grey[600];
    final dividerColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.06);

    String formatShape() {
      final v = entry.value;
      if (v == null) return 'null';
      if (v is Map) {
        return 'Map · ${v.length} ${v.length == 1 ? "key" : "keys"}';
      }
      if (v is List) {
        return 'List · ${v.length} ${v.length == 1 ? "item" : "items"}';
      }
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
        BodyViewMode.tree => JsonViewer(data: value, initiallyExpanded: true),
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

    Widget metaCell(
      String label,
      String value,
      TextStyle valueStyle, {
      bool monospace = false,
    }) => Column(
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
                        'DEVICE',
                        entry.deviceId,
                        monoSecondary,
                        monospace: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: metaCell(
                        'CAPTURED',
                        DateFormat('HH:mm:ss.SSS').format(
                          DateTime.fromMillisecondsSinceEpoch(entry.timestamp),
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
}
