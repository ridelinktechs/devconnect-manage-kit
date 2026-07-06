import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../components/feedback/empty_state.dart';
import '../../../../components/viewers/json_viewer.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/utils/code_generator.dart';
import '../../../../core/utils/smooth_scroll_controller.dart';
import '../../../../server/providers/server_providers.dart';
import '../shared/section_label.dart';

/// Tab-style body viewer used by the network detail. Three modes
/// (`Tree` / `JSON` / `Code`) gated behind the global
/// [bodyViewModeProvider]. When the payload isn't JSON-shaped only the
/// `JSON` segment renders.
class BodyView extends ConsumerStatefulWidget {
  final dynamic body;
  final String label;
  final String? deviceId;
  final ValueChanged<bool>? onJsonModeChanged;

  const BodyView({
    super.key,
    required this.body,
    required this.label,
    this.deviceId,
    this.onJsonModeChanged,
  });

  @override
  ConsumerState<BodyView> createState() => _BodyViewState();
}

class _BodyViewState extends ConsumerState<BodyView> {
  final _scrollController = SmoothScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final viewMode = ref.watch(bodyViewModeProvider);

    // Treat null OR empty/whitespace-only strings as "no data" so the
    // caller renders an EmptyState instead of a blank JSON viewer.
    // AsyncJsonParser also normalises empty strings to null internally,
    // but checking here avoids spinning the parser for the obvious case.
    if (widget.body == null ||
        (widget.body is String && (widget.body as String).trim().isEmpty)) {
      return EmptyState(icon: LucideIcons.fileText, title: 'No ${widget.label}');
    }

    // Look up the connected device's platform to pick the Code language.
    final devices = ref.watch(connectedDevicesProvider);
    final platform = widget.deviceId == null
        ? 'react_native'
        : devices
                .where((d) => d.deviceId == widget.deviceId)
                .map((d) => d.platform)
                .firstOrNull ??
            'react_native';
    final codeLang = CodeGenerator.langForPlatform(platform);

    return AsyncJsonParser(
      rawData: widget.body,
      builder: (context, parsedBody, isJson) {
        final canToggle = isJson;
        final effectiveMode = canToggle ? viewMode : BodyViewMode.json;

        return Column(
          children: [
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
                  SectionLabel(widget.label),
                  const Spacer(),
                  if (canToggle) ...[
                    ViewModeSegment(
                      label: 'Tree',
                      active: effectiveMode == BodyViewMode.tree,
                      position: ViewSegmentPosition.start,
                      onTap: () {
                        ref
                            .read(bodyViewModeProvider.notifier)
                            .set(BodyViewMode.tree);
                        widget.onJsonModeChanged?.call(false);
                      },
                    ),
                    ViewModeSegment(
                      label: 'JSON',
                      active: effectiveMode == BodyViewMode.json,
                      position: ViewSegmentPosition.middle,
                      onTap: () {
                        ref
                            .read(bodyViewModeProvider.notifier)
                            .set(BodyViewMode.json);
                        widget.onJsonModeChanged?.call(true);
                      },
                    ),
                    ViewModeSegment(
                      label: CodeGenerator.labelFor(codeLang),
                      active: effectiveMode == BodyViewMode.code,
                      position: ViewSegmentPosition.end,
                      onTap: () {
                        ref
                            .read(bodyViewModeProvider.notifier)
                            .set(BodyViewMode.code);
                        widget.onJsonModeChanged?.call(false);
                      },
                    ),
                  ],
                ],
              ),
            ),
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

/// Inline Tree/JSON toggle for use inside a ScrollView (non-tabbed
/// contexts). Code mode falls back to TypeScript here because we don't
/// know the originating device.
class InlineJsonView extends ConsumerStatefulWidget {
  final dynamic data;
  final String label;

  const InlineJsonView({super.key, required this.data, required this.label});

  @override
  ConsumerState<InlineJsonView> createState() => _InlineJsonViewState();
}

class _InlineJsonViewState extends ConsumerState<InlineJsonView> {
  @override
  Widget build(BuildContext context) {
    final viewMode = ref.watch(bodyViewModeProvider);

    // Inline views don't know the device, so Code mode falls back to TS.
    final codeLang = CodeGenerator.langForPlatform('react_native');

    return AsyncJsonParser(
      rawData: widget.data,
      builder: (context, parsed, isJson) {
        final canToggle = isJson;
        final effectiveMode = canToggle ? viewMode : BodyViewMode.json;

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SectionLabel(widget.label),
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
              ],
            ),
            const SizedBox(height: 8),
            _buildInlineContent(
              parsed: parsed,
              canToggle: canToggle,
              mode: effectiveMode,
              codeLang: codeLang,
            ),
          ],
        );
      },
    );
  }

  Widget _buildInlineContent({
    required dynamic parsed,
    required bool canToggle,
    required BodyViewMode mode,
    required CodeLang codeLang,
  }) {
    if (!canToggle) return JsonPrettyViewer(data: widget.data);
    return DeferredBuilder(
      key: ValueKey(mode),
      builder: (_) {
        switch (mode) {
          case BodyViewMode.tree:
            return JsonViewer(data: parsed, initiallyExpanded: true);
          case BodyViewMode.json:
            return JsonPrettyViewer(data: widget.data);
          case BodyViewMode.code:
            final generated = CodeGenerator.generate(parsed, codeLang);
            return CodeViewer(
              generated: generated,
              lang: codeLang,
              languageLabel: CodeGenerator.labelFor(codeLang),
            );
        }
      },
    );
  }
}