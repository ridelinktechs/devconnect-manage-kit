import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../components/text/text_component.dart';
import '../../../../components/viewers/json_viewer.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/utils/code_generator.dart';
import '../../../../core/utils/screenshot_filename.dart';
import '../../../../core/utils/screenshot_utils.dart';
import '../../../../models/storage/storage_entry.dart';
import '../../../../server/providers/server_providers.dart';
import '../shared/storage_preview.dart';
import '../shared/storage_tokens.dart';

/// Builds the capture widget for either the full (header + metadata +
/// value) or data-only (key + value) screenshot. Used by the
/// detail panel's two screenshot buttons. Public top-level function
/// so the `DetailPanel` can call it without holding all the layout
/// logic itself.
Widget buildStorageScreenshot({
  required BuildContext context,
  required WidgetRef ref,
  required StorageEntry entry,
  required bool full,
  required bool isDark,
}) {
  final value = entry.value;
  final isAlreadyJson = value is Map || value is List;
  dynamic parsedJson;
  if (!isAlreadyJson && value is String) {
    try {
      parsedJson = jsonDecode(value);
      if (parsedJson is! Map && parsedJson is! List) parsedJson = null;
    } catch (_) {}
  }

  final isJsonLike = isAlreadyJson || parsedJson != null;
  final displayValue = isAlreadyJson
      ? value
      : (parsedJson ?? value);
  final mode = ref.read(bodyViewModeProvider);
  final devices = ref.read(connectedDevicesProvider);
  final platform = devices
          .where((d) => d.deviceId == entry.deviceId)
          .map((d) => d.platform)
          .firstOrNull ??
      'react_native';
  final codeLang = CodeGenerator.langForPlatform(platform);
  final codeLabel = CodeGenerator.labelFor(codeLang);

  final fileName = buildRichScreenshotName(
    type: 'storage',
    subject: '${entry.storageType.name}_${entry.key}',
    suffix: full ? '_full' : '_data',
  );

  // Build the value widget — respects 3 modes only when JSON-like,
  // otherwise renders raw text (same as the live panel).
  final Widget valueWidget;
  if (isJsonLike) {
    valueWidget = switch (mode) {
      BodyViewMode.tree =>
        JsonViewer(data: displayValue, initiallyExpanded: true),
      BodyViewMode.json => JsonPrettyViewer(data: displayValue),
      BodyViewMode.code => CodeViewer(
          generated: CodeGenerator.generate(displayValue, codeLang),
          lang: codeLang,
          languageLabel: codeLabel,
        ),
    };
  } else {
    valueWidget = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E1E1E)
            : const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.08),
        ),
      ),
      child: SelectableText(
        value?.toString() ?? 'null',
        style: TextStyle(
          fontFamily: AppConstants.monoFontFamily,
          fontSize: 12,
          height: 1.6,
          color: isDark ? const Color(0xFFD4D4D4) : const Color(0xFF1F2328),
        ),
      ),
    );
  }

  final divider = isDark
      ? Colors.white.withValues(alpha: 0.06)
      : Colors.black.withValues(alpha: 0.06);

  // Operation color matches the in-app panel:
  //   write → emerald, read → blue, delete/clear → red, default → amber.
  final opColor = storageOpAccentColor(entry.operation);
  final opUpper = entry.operation.toUpperCase();

  final children = <Widget>[
    // ── Badges (WRITE chip + asyncStorage chip) ───────────────
    Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Operation badge: dot + uppercase label
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: opColor.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
                color: opColor.withValues(alpha: 0.28), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                    color: opColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              TextComponent(
                opUpper,
                style: TextStyle(
                  fontFamily: AppConstants.monoFontFamily,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: opColor,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        // Storage type badge (e.g. asyncStorage)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.10)
                  : Colors.black.withValues(alpha: 0.08),
            ),
          ),
          child: TextComponent(
            entry.storageType.name,
            style: TextStyle(
              fontFamily: AppConstants.monoFontFamily,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? const Color(0xFFB0B0B0)
                  : const Color(0xFF4A4A4A),
              letterSpacing: 0.3,
            ),
          ),
        ),
      ],
    ),
    const SizedBox(height: 16),
    // ── KEY section ───────────────────────────────────────────
    TextComponent('KEY',
        style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: Colors.grey[500])),
    const SizedBox(height: 4),
    SelectableText(
      entry.key,
      style: TextStyle(
        fontFamily: AppConstants.monoFontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: isDark ? const Color(0xFFE8E8E8) : const Color(0xFF1A1A1A),
        height: 1.4,
      ),
    ),
    const SizedBox(height: 18),
    Container(height: 1, color: divider),
    const SizedBox(height: 18),
    // ── VALUE section ─────────────────────────────────────────
    TextComponent('VALUE',
        style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: Colors.grey[500])),
    const SizedBox(height: 8),
    valueWidget,
  ];

  // Metadata bento grid — only the full capture gets this section,
  // matching the in-app panel (SHAPE / SIZE / DEVICE / CAPTURED).
  if (full) {
    final capturedAt = DateFormat('HH:mm:ss.SSS').format(
      DateTime.fromMillisecondsSinceEpoch(entry.timestamp),
    );
    final monoPrimary = TextStyle(
      fontFamily: AppConstants.monoFontFamily,
      fontSize: 13,
      height: 1.5,
      color:
          isDark ? const Color(0xFFE8E8E8) : const Color(0xFF1A1A1A),
    );
    final monoSecondary = TextStyle(
      fontFamily: AppConstants.monoFontFamily,
      fontSize: 11,
      height: 1.5,
      color: isDark ? Colors.grey[500] : Colors.grey[600],
    );
    final metaLabelStyle = TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.2,
      color: isDark ? Colors.grey[500] : Colors.grey[600],
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
                  ? valueStyle
                  : valueStyle.copyWith(
                      fontFamily: AppConstants.monoFontFamily),
            ),
          ],
        );

    children.addAll([
      const SizedBox(height: 22),
      TextComponent('METADATA', style: metaLabelStyle),
      const SizedBox(height: 10),
      // Row 1: SHAPE / SIZE
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: metaCell('SHAPE', storageShapeOf(value), monoPrimary)),
          const SizedBox(width: 12),
          Expanded(child: metaCell('SIZE', _sizeLabel(value), monoPrimary)),
        ],
      ),
      const SizedBox(height: 12),
      // Row 2: DEVICE / CAPTURED
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: metaCell('DEVICE', entry.deviceId, monoSecondary),
          ),
          const SizedBox(width: 12),
          Expanded(child: metaCell('CAPTURED', capturedAt, monoPrimary)),
        ],
      ),
    ]);
  }

  final screenshotWidget = Container(
    color: isDark ? ColorTokens.darkSurface : ColorTokens.lightSurface,
    padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    ),
  );
  captureWidgetAsImage(context, screenshotWidget, fileName: fileName);
  // Return the widget so callers can compose with it; the side-effect
  // (file picker + capture) already ran above.
  return screenshotWidget;
}

/// Local helper — size label for the captured metadata grid. Kept
/// file-private because it's a trivial pair of branches that only
/// makes sense inside the screenshot builder.
String _sizeLabel(dynamic value) {
  if (value == null) return '0 B';
  final raw = value is String ? value : jsonEncode(value);
  return AppConstants.formatBytes(raw.length);
}

/// Icon picker for a storage operation (used in the live detail
/// panel header chips — not the screenshot, which uses a dot+label).
IconData storageOpIcon(String op) {
  switch (op.toLowerCase()) {
    case 'write':
      return LucideIcons.pencilLine;
    case 'delete':
    case 'clear':
      return LucideIcons.trash2;
    default:
      return LucideIcons.eye;
  }
}