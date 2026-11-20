import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../components/labels/tag_label.dart';
import '../../../../components/viewers/json_viewer.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/chrome_palette.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/utils/code/code_generator.dart';
import '../../../../core/utils/scroll/smooth_scroll_controller.dart';
import '../../../../core/utils/ui/toast_utils.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../models/storage/storage_entry.dart';
import '../../../../server/providers/server_providers.dart';
import '../shared/storage_preview.dart';
import 'metadata_footer.dart';
import 'screenshot_builder.dart';
import 'storage_detail_header.dart';

/// Right-pane detail panel for the selected storage operation: the
/// [StorageDetailHeader], the value in the Tree / JSON / Code views (or as
/// plain text when it isn't JSON), and the [MetadataFooter].
class StorageDetailPanel extends ConsumerStatefulWidget {
  final StorageEntry entry;
  final VoidCallback onClose;

  const StorageDetailPanel({
    super.key,
    required this.entry,
    required this.onClose,
  });

  @override
  ConsumerState<StorageDetailPanel> createState() => _StorageDetailPanelState();
}

class _StorageDetailPanelState extends ConsumerState<StorageDetailPanel> {
  final _scrollController = SmoothScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  StorageEntry get entry => widget.entry;

  String _sizeLabel() {
    final v = entry.value;
    if (v == null) return '0 B';
    final raw = v is String ? v : jsonEncode(v);
    return AppConstants.formatBytes(raw.length);
  }

  void _copy() {
    final v = entry.value;
    Clipboard.setData(
      ClipboardData(
        text: v is String ? v : const JsonEncoder.withIndent('  ').convert(v),
      ),
    );
    showCopiedToast(context);
  }

  void _capture({required bool full}) => buildStorageScreenshot(
    context: context,
    ref: ref,
    entry: entry,
    full: full,
    isDark: Theme.of(context).brightness == Brightness.dark,
  );

  @override
  Widget build(BuildContext context) {
    final p = ChromePalette.of(context);
    final mode = ref.watch(bodyViewModeProvider);
    final device = ref.watch(
      connectedDevicesProvider.select(
        (devices) =>
            devices.where((d) => d.deviceId == entry.deviceId).firstOrNull,
      ),
    );
    final source = device == null
        ? null
        : '${device.appName} · ${device.deviceName}';
    final codeLang = CodeGenerator.langForPlatform(
      device?.platform ?? 'react_native',
    );
    final codeLabel = CodeGenerator.labelFor(codeLang);
    final size = _sizeLabel();

    return Container(
      color: p.isDark ? ColorTokens.darkSurface : ColorTokens.lightSurface,
      child: Column(
        children: [
          StorageDetailHeader(
            entry: entry,
            source: source,
            onCopy: _copy,
            onCapture: () => _capture(full: true),
            onCaptureValue: () => _capture(full: false),
            onClose: widget.onClose,
          ),
          Expanded(
            child: AsyncJsonParser(
              rawData: entry.value,
              builder: (context, parsedJson, isJson) {
                final isAlreadyJson = entry.value is Map || entry.value is List;
                // For Tree/JSON: prefer the parsed JSON when available so
                // string-encoded JSON renders correctly in both modes.
                final displayValue = isAlreadyJson
                    ? entry.value
                    : (parsedJson ?? entry.value);
                return SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ValueHeading(
                        size: size,
                        shape: storageShapeOf(entry.value),
                      ),
                      const SizedBox(height: 8),
                      if (!isJson)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: p.codeBg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: p.border),
                          ),
                          child: SelectableText(
                            entry.value?.toString() ?? 'null',
                            style: chromeMono(
                              context,
                              size: 12,
                              color: p.text,
                            ).copyWith(height: 1.6),
                          ),
                        )
                      else ...[
                        // Own row so its inner Expanded row gets a real
                        // width; inside a parent Row it collapsed to ~0.
                        SizedBox(
                          width: double.infinity,
                          child: ViewModeSwitcher(
                            current: mode,
                            codeLabel: codeLabel,
                            onChanged: (BodyViewMode m) =>
                                ref.read(bodyViewModeProvider.notifier).set(m),
                          ),
                        ),
                        const SizedBox(height: 12),
                        DeferredBuilder(
                          key: ValueKey(mode),
                          builder: (_) => switch (mode) {
                            BodyViewMode.tree => JsonViewer(
                              data: displayValue,
                              initiallyExpanded: true,
                            ),
                            BodyViewMode.json => JsonPrettyViewer(
                              data: displayValue,
                            ),
                            BodyViewMode.code => CodeViewer(
                              generated: CodeGenerator.generate(
                                displayValue,
                                codeLang,
                              ),
                              lang: codeLang,
                              languageLabel: codeLabel,
                            ),
                          },
                        ),
                      ],
                      const SizedBox(height: 20),
                      MetadataFooter(entry: entry, source: source, size: size),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// "VALUE" with the value's size and shape beside it.
class _ValueHeading extends StatelessWidget {
  final String size;
  final String shape;

  const _ValueHeading({required this.size, required this.shape});

  @override
  Widget build(BuildContext context) {
    final p = ChromePalette.of(context);
    return Row(
      children: [
        Text(
          S.of(context).storageKvValue.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: p.textMuted,
          ),
        ),
        const SizedBox(width: 10),
        TagLabel(
          text: size,
          color: p.textMuted,
          fill: p.selected,
          edge: p.border.withValues(alpha: 0.6),
          mono: true,
        ),
        const SizedBox(width: 6),
        Flexible(
          child: TagLabel(
            text: shape,
            color: p.textMuted,
            fill: p.selected,
            edge: p.border.withValues(alpha: 0.6),
            mono: true,
          ),
        ),
      ],
    );
  }
}
