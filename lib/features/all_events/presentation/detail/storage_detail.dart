import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../components/viewers/json_viewer.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/utils/code_generator.dart';
import '../../../../core/utils/screenshot_filename.dart';
import '../../../../core/utils/screenshot_utils.dart';
import '../../../../core/utils/smooth_scroll_controller.dart';
import '../../../../core/utils/toast_utils.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/device_info.dart';
import '../../../../server/providers/server_providers.dart';
import '../../../../models/storage/storage_entry.dart';
import '../buttons/header_icon_button.dart';
import '../shared/empty_value.dart';
import '../shared/label.dart';
import '../shared/meta_cell.dart';
import '../shared/op_badge.dart';
import '../shared/type_badge.dart';

/// Redressed storage detail panel: bento-style header (operation / type /
/// hero key), 2×2 metadata grid, and a 3-mode value viewer (Tree / JSON /
/// Code) for JSON-shaped payloads.
///
/// Plain string/number/bool values render as a single tinted monospace
/// block. Missing values show [EmptyValue].
class StorageDetail extends ConsumerStatefulWidget {
  final StorageEntry entry;
  final VoidCallback? onClose;
  const StorageDetail({
    super.key,
    required this.entry,
    this.onClose,
  });

  @override
  ConsumerState<StorageDetail> createState() =>
      _StorageDetailState();
}

class _StorageDetailState
    extends ConsumerState<StorageDetail> {
  final _scrollController = SmoothScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // ── Design tokens ─────────────────────────────────────────────
  // Off-black neutrals (anti-pure-black rule). One accent reserved
  // for the operation chip — everything else is desaturated.
  Color _textPrimary(bool isDark) =>
      isDark ? const Color(0xFFE8E8E8) : const Color(0xFF1A1A1A);
  Color _textSecondary(bool isDark) =>
      isDark ? const Color(0xFF8B8B8B) : const Color(0xFF6B6B6B);
  Color _divider(bool isDark) => isDark
      ? Colors.white.withValues(alpha: 0.06)
      : Colors.black.withValues(alpha: 0.06);

  Color _opColor() {
    switch (widget.entry.operation.toLowerCase()) {
      case 'write':
        return const Color(0xFF34D399); // emerald 400 — single accent
      case 'read':
        return const Color(0xFF60A5FA); // blue 400
      case 'delete':
      case 'clear':
        return const Color(0xFFF87171); // red 400
      default:
        return const Color(0xFFFBBF24); // amber 400
    }
  }

  String _shapeOf(dynamic v) {
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

  dynamic _parsedJson() {
    final v = widget.entry.value;
    if (v is! String) return null;
    try {
      final p = jsonDecode(v);
      if (p is Map || p is List) return p;
    } catch (_) {}
    return null;
  }

  dynamic _displayValue() {
    final v = widget.entry.value;
    if (v is Map || v is List) return v;
    return _parsedJson() ?? v;
  }

  bool get _isJsonLike {
    final v = widget.entry.value;
    if (v is Map || v is List) return true;
    return _parsedJson() != null;
  }

  String _sizeLabel() {
    final raw = widget.entry.value is String
        ? widget.entry.value as String
        : const JsonEncoder.withIndent('  ').convert(widget.entry.value);
    return AppConstants.formatBytes(raw.length);
  }

  String _captureText() {
    final v = widget.entry.value;
    return v is String ? v : const JsonEncoder.withIndent('  ').convert(v);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mode = ref.watch(bodyViewModeProvider);
    final devices = ref.watch(connectedDevicesProvider);
    final platform = devices
            .where((d) => d.deviceId == widget.entry.deviceId)
            .map((d) => d.platform)
            .firstOrNull ??
        'react_native';
    final codeLang = CodeGenerator.langForPlatform(platform);
    final codeLabel = CodeGenerator.labelFor(codeLang);

    final monoPrimary = TextStyle(
      fontFamily: AppConstants.monoFontFamily,
      fontSize: 13,
      height: 1.5,
      color: _textPrimary(isDark),
    );
    final monoSecondary = TextStyle(
      fontFamily: AppConstants.monoFontFamily,
      fontSize: 11,
      height: 1.5,
      color: _textSecondary(isDark),
    );

    return SingleChildScrollView(
      controller: _scrollController,
      physics: const ClampingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ──────────────────────────────────────────────────────────
          // 1) HEADER — operation accent + storage type + key chip
          // ──────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                OpBadge(label: widget.entry.operation, color: _opColor()),
                const SizedBox(width: 8),
                TypeBadge(label: widget.entry.storageType.name),
                const Spacer(),
                HeaderIconButton(
                  icon: LucideIcons.copy,
                  tooltip: S.of(context).copyKey,
                  isDark: isDark,
                  onTap: () => _copyText(context, widget.entry.key, 'Key'),
                ),
                const SizedBox(width: 4),
                HeaderIconButton(
                  icon: LucideIcons.camera,
                  tooltip: _isJsonLike
                      ? S.of(context).captureDataJson
                      : S.of(context).captureDataText,
                  isDark: isDark,
                  onTap: () =>
                      _captureData(isDark, devices, codeLang, codeLabel),
                ),
                const SizedBox(width: 4),
                HeaderIconButton(
                  icon: LucideIcons.x,
                  tooltip: S.of(context).close,
                  isDark: isDark,
                  onTap: () => widget.onClose?.call(),
                ),
              ],
            ),
          ),

          // ──────────────────────────────────────────────────────────
          // 2) KEY DISPLAY — large monospace, hero element
          // ──────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Label(text: 'KEY', isDark: isDark),
                    const Spacer(),
                    HeaderIconButton(
                      icon: LucideIcons.copy,
                      tooltip: 'Copy key',
                      isDark: isDark,
                      onTap: () => _copyText(context, widget.entry.key, 'Key'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SelectableText(
                  widget.entry.key,
                  style: TextStyle(
                    fontFamily: AppConstants.monoFontFamily,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                    color: _textPrimary(isDark),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          // ──────────────────────────────────────────────────────────
          // 3) METADATA GRID — 2x2 bento layout
          // ──────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Label(text: 'METADATA', isDark: isDark),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: MetaCell(
                        label: 'SHAPE',
                        value: _shapeOf(widget.entry.value),
                        valueStyle: monoPrimary,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: MetaCell(
                        label: 'SIZE',
                        value: _sizeLabel(),
                        valueStyle: monoPrimary,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: MetaCell(
                        label: 'DEVICE',
                        value: widget.entry.deviceId,
                        valueStyle: monoSecondary,
                        isDark: isDark,
                        monospace: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: MetaCell(
                        label: 'CAPTURED',
                        value: DateFormat('HH:mm:ss.SSS').format(
                          DateTime.fromMillisecondsSinceEpoch(
                              widget.entry.timestamp),
                        ),
                        valueStyle: monoPrimary,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ──────────────────────────────────────────────────────────
          // 4) DIVIDER — separates data zones
          // ──────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: Container(height: 1, color: _divider(isDark)),
          ),

          // ──────────────────────────────────────────────────────────
          // 5) VALUE SECTION — switcher + content
          // ──────────────────────────────────────────────────────────
          if (widget.entry.value != null && _isJsonLike) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              child: SizedBox(
                width: double.infinity,
                child: ViewModeSwitcher(
                  current: mode,
                  codeLabel: codeLabel,
                  onChanged: (m) =>
                      ref.read(bodyViewModeProvider.notifier).set(m),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: _buildValueContent(
                isDark: isDark,
                mode: mode,
                codeLang: codeLang,
                codeLabel: codeLabel,
              ),
            ),
          ] else if (widget.entry.value != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              child: Row(
                children: [
                  Label(text: 'VALUE', isDark: isDark),
                  const Spacer(),
                  HeaderIconButton(
                    icon: LucideIcons.copy,
                    tooltip: 'Copy value',
                    isDark: isDark,
                    onTap: () => _copyText(context, _captureText(), 'Value'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.03)
                      : Colors.black.withValues(alpha: 0.025),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _divider(isDark)),
                ),
                child: SelectableText(
                  widget.entry.value.toString(),
                  style: TextStyle(
                    fontFamily: AppConstants.monoFontFamily,
                    fontSize: 12,
                    height: 1.6,
                    color: _textPrimary(isDark),
                  ),
                ),
              ),
            ),
          ] else ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
              child: EmptyValue(isDark: isDark),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildValueContent({
    required bool isDark,
    required BodyViewMode mode,
    required CodeLang codeLang,
    required String codeLabel,
  }) {
    final value = _displayValue();

    return DeferredBuilder(
      key: ValueKey(mode),
      builder: (_) {
        switch (mode) {
          case BodyViewMode.tree:
            return Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: JsonViewer(data: value, initiallyExpanded: true),
            );
          case BodyViewMode.json:
            return Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: JsonPrettyViewer(data: value),
            );
          case BodyViewMode.code:
            return Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: CodeViewer(
                generated: CodeGenerator.generate(value, codeLang),
                lang: codeLang,
                languageLabel: codeLabel,
              ),
            );
        }
      },
    );
  }

  void _copyText(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    showCopiedToast(context, label: '$label copied');
  }

  // ── Screenshot: data only (KEY + VALUE in current view mode) ──
  void _captureData(
    bool isDark,
    List<DeviceInfo> devices,
    CodeLang codeLang,
    String codeLabel,
  ) {
    final value = _displayValue();
    final monoKey = TextStyle(
      fontFamily: AppConstants.monoFontFamily,
      fontSize: 14,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.2,
      color: _textPrimary(isDark),
    );
    final labelStyle = TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.2,
      color: isDark ? const Color(0xFF6B6B6B) : const Color(0xFF8B8B8B),
    );
    final divider = _divider(isDark);
    final mode = ref.read(bodyViewModeProvider);

    // Value widget: respect 3-mode only when the payload is JSON-like.
    // Plain text/number/bool capture as raw text — no switcher chrome.
    final Widget valueWidget;
    if (_isJsonLike) {
      valueWidget = switch (mode) {
        BodyViewMode.tree => JsonViewer(data: value, initiallyExpanded: true),
        BodyViewMode.json => JsonPrettyViewer(data: value),
        BodyViewMode.code => CodeViewer(
            generated: CodeGenerator.generate(value, codeLang),
            lang: codeLang,
            languageLabel: codeLabel,
          ),
      };
    } else if (widget.entry.value == null) {
      valueWidget = const SizedBox.shrink();
    } else {
      valueWidget = Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.03)
              : Colors.black.withValues(alpha: 0.025),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: divider),
        ),
        child: SelectableText(
          widget.entry.value.toString(),
          style: TextStyle(
            fontFamily: AppConstants.monoFontFamily,
            fontSize: 12,
            height: 1.6,
            color: _textPrimary(isDark),
          ),
        ),
      );
    }

    // Header style matches storageScreenshot for visual consistency
    // between full and data captures.
    final capturedAt = DateTime.now().toIso8601String().split('.').first;
    final labelColor = isDark ? Colors.grey[500] : Colors.grey[600];

    final capture = Container(
      color: isDark ? const Color(0xFF121212) : const Color(0xFFFAFAFA),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header context (matches storageScreenshot) ──
          Row(
            children: [
              Icon(LucideIcons.database,
                  size: 14, color: ColorTokens.warning),
              const SizedBox(width: 6),
              Text(
                'Storage Detail',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  color: labelColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '· ${widget.entry.storageType.name.toUpperCase()} · $capturedAt',
                  style: TextStyle(
                    fontSize: 10,
                    color: labelColor,
                    letterSpacing: 0.3,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          // ── Badges (mirror StorageDetail header row) ──
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              OpBadge(label: widget.entry.operation, color: _opColor()),
              const SizedBox(width: 8),
              TypeBadge(label: widget.entry.storageType.name),
            ],
          ),
          const SizedBox(height: 18),
          Container(height: 1, color: divider),
          const SizedBox(height: 18),
          Text('KEY', style: labelStyle),
          const SizedBox(height: 8),
          SelectableText(widget.entry.key, style: monoKey),
          const SizedBox(height: 18),
          Container(height: 1, color: divider),
          const SizedBox(height: 18),
          Text('VALUE', style: labelStyle),
          const SizedBox(height: 10),
          valueWidget,
        ],
      ),
    );

    captureWidgetAsImage(
      context,
      capture,
      fileName: _buildScreenshotName(devices, '_data'),
      onSaved: (path) {
        if (mounted) showScreenshotSavedToast(context, filePath: path);
      },
    );
  }

  String _buildScreenshotName(List<DeviceInfo> devices, String suffix) {
    final entry = widget.entry;
    // Note: appName intentionally omitted to avoid leaking the app
    // identifier into filenames shared with clients.
    return buildRichScreenshotName(
      type: entry.storageType.name,
      subject: entry.key,
      suffix: suffix,
    );
  }
}