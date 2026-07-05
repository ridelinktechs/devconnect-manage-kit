import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../components/feedback/empty_state.dart';
import '../../../../components/text/text_component.dart';
import '../../../../components/viewers/json_viewer.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/utils/code_generator.dart';
import '../../../../core/utils/smooth_scroll_controller.dart';
import '../../../../core/utils/toast_utils.dart';
import '../../../../server/providers/server_providers.dart';
import '../shared/detect_blob_payload.dart';
import 'blob_info.dart';

/// Tab body viewer for a single network request/response body. Three
/// modes (`Tree` / `JSON` / `Code`) gated behind the global
/// [bodyViewModeProvider]. When the payload isn't JSON-shaped only the
/// `JSON` segment renders.
///
/// Pre-render short-circuits:
/// - **null / empty / whitespace body** → `EmptyState("No <label>")`
/// - **binary blob placeholder** (e.g. `&lt;blob 4096 bytes&gt;`) →
///   [BlobInfo] so users see size + label instead of "null"
class BodyTab extends ConsumerStatefulWidget {
  final dynamic body;
  final String label;
  final String deviceId;

  const BodyTab({
    super.key,
    required this.body,
    required this.label,
    required this.deviceId,
  });

  @override
  ConsumerState<BodyTab> createState() => _BodyTabState();
}

class _BodyTabState extends ConsumerState<BodyTab> {
  final _scrollController = SmoothScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final viewMode = ref.watch(bodyViewModeProvider);

    // Treat null OR empty/whitespace-only strings as "no data" so the
    // caller renders an EmptyState instead of a blank JSON viewer.
    if (widget.body == null ||
        (widget.body is String && (widget.body as String).trim().isEmpty)) {
      return EmptyState(
        icon: LucideIcons.fileText,
        title: 'No ${widget.label}',
      );
    }

    final blob = detectBlobPayload(widget.body);
    if (blob.$1 != null) {
      return BlobInfo(
        label: widget.label,
        sizeBytes: blob.$2 ?? 0,
        isDark: isDark,
      );
    }

    // Look up the connected device's platform so Code mode exports the
    // right language. Falls back to TypeScript (RN) when not connected.
    final devices = ref.watch(connectedDevicesProvider);
    final platform = devices
            .where((d) => d.deviceId == widget.deviceId)
            .map((d) => d.platform)
            .firstOrNull ??
        'react_native';
    final codeLang = CodeGenerator.langForPlatform(platform);

    return AsyncJsonParser(
      rawData: widget.body,
      builder: (context, parsedBody, isJson) {
        final canToggle = isJson;
        // When the body is a primitive string, Tree mode can't show anything
        // structured so we implicitly fall back to JSON mode.
        final effectiveMode = canToggle ? viewMode : BodyViewMode.json;

        return Column(
          children: [
            // Toggle bar — 3-way Tree / JSON / Code segmented toggle
            Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.black.withValues(alpha: 0.06),
                  ),
                ),
              ),
              child: Row(
                children: [
                  TextComponent(widget.label, style: theme.textTheme.titleSmall),
                  const Spacer(),
                  if (canToggle) ...[
                    ViewModeSegment(
                      label: 'Tree',
                      active: effectiveMode == BodyViewMode.tree,
                      position: ViewSegmentPosition.start,
                      onTap: () => ref
                          .read(bodyViewModeProvider.notifier)
                          .set(BodyViewMode.tree),
                    ),
                    ViewModeSegment(
                      label: 'JSON',
                      active: effectiveMode == BodyViewMode.json,
                      position: ViewSegmentPosition.middle,
                      onTap: () => ref
                          .read(bodyViewModeProvider.notifier)
                          .set(BodyViewMode.json),
                    ),
                    ViewModeSegment(
                      label: CodeGenerator.labelFor(codeLang),
                      active: effectiveMode == BodyViewMode.code,
                      position: ViewSegmentPosition.end,
                      onTap: () => ref
                          .read(bodyViewModeProvider.notifier)
                          .set(BodyViewMode.code),
                    ),
                  ],
                  const SizedBox(width: 8),
                  // Copy body button
                  GestureDetector(
                    onTap: () {
                      final text = parsedBody is String
                          ? parsedBody
                          : const JsonEncoder.withIndent('  ')
                              .convert(parsedBody);
                      Clipboard.setData(ClipboardData(text: text));
                      showCopiedToast(context, label: '${widget.label} copied');
                    },
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Icon(LucideIcons.copy,
                          size: 14, color: Colors.grey[500]),
                    ),
                  ),
                ],
              ),
            ),
            // Body content — each viewer handles its own scrolling.
            // Keeping bounded constraints so JsonPrettyViewer / JsonViewer
            // can virtualize (shrinkWrap: false) instead of measuring
            // every single line.
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _buildContent(
                  parsedBody: parsedBody,
                  canToggle: canToggle,
                  mode: effectiveMode,
                  codeLang: codeLang,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildContent({
    required dynamic parsedBody,
    required bool canToggle,
    required BodyViewMode mode,
    required CodeLang codeLang,
  }) {
    if (!canToggle) {
      // Primitive / non-JSON body: only the pretty JSON viewer is meaningful.
      return JsonPrettyViewer(data: parsedBody);
    }
    return DeferredBuilder(
      key: ValueKey(mode),
      builder: (_) {
        switch (mode) {
          case BodyViewMode.tree:
            return JsonViewer(data: parsedBody, initiallyExpanded: true);
          case BodyViewMode.json:
            return JsonPrettyViewer(data: widget.body);
          case BodyViewMode.code:
            final generated = CodeGenerator.generate(parsedBody, codeLang);
            return SingleChildScrollView(
              child: CodeViewer(
                generated: generated,
                lang: codeLang,
                languageLabel: CodeGenerator.labelFor(codeLang),
              ),
            );
        }
      },
    );
  }
}