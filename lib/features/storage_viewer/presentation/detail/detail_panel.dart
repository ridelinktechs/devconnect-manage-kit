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
import '../../../../core/utils/smooth_scroll_controller.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/storage/storage_entry.dart';
import '../../../../server/providers/server_providers.dart';
import '../shared/storage_preview.dart';
import '../shared/storage_tokens.dart';
import 'detail_icon_btn.dart';
import 'meta_chip.dart';
import 'meta_divider.dart';
import 'metadata_footer.dart';
import 'screenshot_builder.dart';

/// Right-pane detail panel that swaps content based on the selected
/// storage entry. Owns:
///   • the per-tab screenshot machinery (full + data) via
///     [buildStorageScreenshot]
///   • the 3-mode (tree/json/code) body view, or a plain text fallback
///     for non-JSON values
///   • the metadata footer
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final time = DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(
      DateTime.fromMillisecondsSinceEpoch(entry.timestamp),
    );
    final mode = ref.watch(bodyViewModeProvider);

    final devices = ref.watch(connectedDevicesProvider);
    final platform = devices
            .where((d) => d.deviceId == entry.deviceId)
            .map((d) => d.platform)
            .firstOrNull ??
        'react_native';
    final codeLang = CodeGenerator.langForPlatform(platform);
    final codeLabel = CodeGenerator.labelFor(codeLang);

    final opColor = storageOpColor(entry.operation);
    final tColor = storageTypeColor(entry.storageType);

    return Container(
      color: isDark ? ColorTokens.darkSurface : ColorTokens.lightSurface,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
            decoration: BoxDecoration(
              color: isDark ? ColorTokens.darkBackground : Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.06),
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(LucideIcons.database, size: 14, color: ColorTokens.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextComponent(
                        entry.key,
                        style: TextStyle(
                          fontFamily: AppConstants.monoFontFamily,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DetailIconBtn(
                      icon: LucideIcons.camera,
                      tooltip: S.of(context).captureFullTooltip,
                      isDark: isDark,
                      onTap: () {
                        buildStorageScreenshot(
                          context: context,
                          ref: ref,
                          entry: entry,
                          full: true,
                          isDark: isDark,
                        );
                      },
                    ),
                    const SizedBox(width: 4),
                    DetailIconBtn(
                      icon: LucideIcons.scanLine,
                      tooltip: S.of(context).captureTabTooltip,
                      isDark: isDark,
                      onTap: () {
                        buildStorageScreenshot(
                          context: context,
                          ref: ref,
                          entry: entry,
                          full: false,
                          isDark: isDark,
                        );
                      },
                    ),
                    const SizedBox(width: 4),
                    DetailIconBtn(
                      icon: LucideIcons.x,
                      tooltip: S.of(context).close,
                      isDark: isDark,
                      onTap: widget.onClose,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    MetaChip(
                      icon: storageOpIcon(entry.operation),
                      label: entry.operation.toUpperCase(),
                      color: opColor,
                      isDark: isDark,
                    ),
                    const SizedBox(width: 6),
                    MetaChip(
                      icon: LucideIcons.database,
                      label: entry.storageType.name,
                      color: tColor,
                      isDark: isDark,
                    ),
                    const SizedBox(width: 6),
                    MetaChip(
                      icon: LucideIcons.clock,
                      label: time,
                      color: Colors.grey,
                      isDark: isDark,
                      isMono: true,
                    ),
                    const Spacer(),
                  ],
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: AsyncJsonParser(
              rawData: entry.value,
              builder: (context, parsedJson, isJson) {
                final isAlreadyJson =
                    entry.value is Map || entry.value is List;
                // For Tree/JSON: prefer the parsed JSON when available so
                // string-encoded JSON renders correctly in both modes.
                final displayValue = isAlreadyJson
                    ? entry.value
                    : (parsedJson ?? entry.value);

                // Plain text payload: skip the 3-mode toggle entirely and
                // show the raw value as a single styled block. Users can
                // still copy via the icon-button in the header.
                if (!isJson) {
                  return SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            TextComponent(
                              'Value',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(width: 8),
                            MetaChip(
                              icon: LucideIcons.hardDrive,
                              label: _sizeLabel(),
                              color: Colors.grey,
                              isDark: isDark,
                              isMono: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Container(
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
                            entry.value?.toString() ?? 'null',
                            style: TextStyle(
                              fontFamily: AppConstants.monoFontFamily,
                              fontSize: 12,
                              height: 1.6,
                              color: isDark
                                  ? const Color(0xFFD4D4D4)
                                  : const Color(0xFF1F2328),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const MetaDivider(),
                        const SizedBox(height: 12),
                        MetadataFooter(
                          entry: entry,
                          isDark: isDark,
                          stats: storageValueStats(entry.value),
                        ),
                      ],
                    ),
                  );
                }

                return SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section header
                      Row(
                        children: [
                          TextComponent(
                            'Value',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(width: 8),
                          MetaChip(
                            icon: LucideIcons.hardDrive,
                            label: _sizeLabel(),
                            color: Colors.grey,
                            isDark: isDark,
                            isMono: true,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // View switcher (own row so its inner Expanded row gets
                      // a real width — placing it inside a parent Row collapsed
                      // the Container's intrinsic width to ~0, hiding it).
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
                        builder: (_) {
                          switch (mode) {
                            case BodyViewMode.tree:
                              return JsonViewer(
                                data: displayValue,
                                initiallyExpanded: true,
                              );
                            case BodyViewMode.json:
                              return JsonPrettyViewer(data: displayValue);
                            case BodyViewMode.code:
                              return CodeViewer(
                                generated: CodeGenerator.generate(
                                  displayValue,
                                  codeLang,
                                ),
                                lang: codeLang,
                                languageLabel: codeLabel,
                              );
                          }
                        },
                      ),
                      const SizedBox(height: 20),
                      const MetaDivider(),
                      const SizedBox(height: 12),
                      MetadataFooter(
                        entry: entry,
                        isDark: isDark,
                        stats: storageValueStats(entry.value),
                      ),
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