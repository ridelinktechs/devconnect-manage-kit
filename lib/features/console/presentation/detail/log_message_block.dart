import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../components/viewers/json_viewer.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/utils/code_generator.dart';
import '../../../../server/providers/server_providers.dart';
import 'plain_message_block.dart';

/// Renders the log message body with 3 view modes (Tree / JSON /
/// Code), same pattern as the All Events detail panel. JSON-parseable
/// messages get the toggle + viewer; plain text falls back to
/// [PlainMessageBlock] with no chrome.
class LogMessageBlock extends ConsumerWidget {
  final String message;
  final String deviceId;

  const LogMessageBlock({
    super.key,
    required this.message,
    required this.deviceId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mode = ref.watch(bodyViewModeProvider);

    final devices = ref.watch(connectedDevicesProvider);
    final platform = devices
            .where((d) => d.deviceId == deviceId)
            .map((d) => d.platform)
            .firstOrNull ??
        'react_native';
    final codeLang = CodeGenerator.langForPlatform(platform);

    return AsyncJsonParser(
      rawData: message,
      builder: (context, parsed, isJson) {
        // Plain text: skip the 3-mode toggle entirely. The user gets the
        // raw message without any view-mode chrome.
        if (!isJson) {
          return Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark
                  ? ColorTokens.darkBackground
                  : const Color(0xFFF0F0F0),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.06),
                width: 1,
              ),
            ),
            padding: const EdgeInsets.all(12),
            child: PlainMessageBlock(text: message, isDark: isDark),
          );
        }

        final body = DeferredBuilder(
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

        return Container(
          width: double.infinity,
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
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                child: ViewModeSwitcher(
                  current: mode,
                  codeLabel: CodeGenerator.labelFor(codeLang),
                  onChanged: (BodyViewMode m) =>
                      ref.read(bodyViewModeProvider.notifier).set(m),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: body,
              ),
            ],
          ),
        );
      },
    );
  }
}