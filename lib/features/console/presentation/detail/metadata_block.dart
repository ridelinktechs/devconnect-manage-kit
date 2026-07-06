import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../components/viewers/json_viewer.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/utils/code_generator.dart';
import '../../../../server/providers/server_providers.dart';

/// 3-mode (Tree / JSON / Code) toggle + viewer for the log metadata
/// map — same pattern as the message block but driven by the
/// separate `metadataViewModeProvider` so the metadata and message
/// can be in different modes simultaneously.
class MetadataBlock extends ConsumerWidget {
  final Map<String, dynamic> data;
  final String deviceId;

  const MetadataBlock({
    super.key,
    required this.data,
    required this.deviceId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mode = ref.watch(metadataViewModeProvider);
    final devices = ref.watch(connectedDevicesProvider);
    final platform = devices
            .where((d) => d.deviceId == deviceId)
            .map((d) => d.platform)
            .firstOrNull ??
        'react_native';
    final codeLang = CodeGenerator.langForPlatform(platform);
    final codeLabel = CodeGenerator.labelFor(codeLang);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? ColorTokens.darkBackground : const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.06),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: SizedBox(
              width: double.infinity,
              child: ViewModeSwitcher(
                current: mode,
                codeLabel: codeLabel,
                onChanged: (BodyViewMode m) =>
                    ref.read(metadataViewModeProvider.notifier).state = m,
              ),
            ),
          ),
          DeferredBuilder(
            key: ValueKey(mode),
            builder: (_) {
              switch (mode) {
                case BodyViewMode.tree:
                  return JsonViewer(data: data, initiallyExpanded: true);
                case BodyViewMode.json:
                  return JsonPrettyViewer(data: data);
                case BodyViewMode.code:
                  return CodeViewer(
                    generated: CodeGenerator.generate(data, codeLang),
                    lang: codeLang,
                    languageLabel: codeLabel,
                  );
              }
            },
          ),
        ],
      ),
    );
  }
}