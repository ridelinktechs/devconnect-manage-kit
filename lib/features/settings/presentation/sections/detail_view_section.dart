import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../header/section_title.dart';

/// Detail View card — picks between tree/json/code for response body
/// rendering, plus the tab animation toggle + duration slider.
class DetailViewSection extends ConsumerWidget {
  const DetailViewSection({super.key});

  String _modeDescription(WidgetRef ref, BodyViewMode mode) {
    switch (mode) {
      case BodyViewMode.tree:
        return S.of(ref.context).treeModeDesc;
      case BodyViewMode.json:
        return S.of(ref.context).jsonModeDesc;
      case BodyViewMode.code:
        return S.of(ref.context).codeModeDesc;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewMode = ref.watch(bodyViewModeProvider);
    final animEnabled = ref.watch(tabAnimationEnabledProvider);
    final animMs = ref.watch(tabAnimationDurationProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(
          icon: LucideIcons.panelRight,
          title: S.of(context).detailView,
        ),
        Text(
          S.of(context).detailViewDesc,
          style: TextStyle(fontSize: 11, color: Colors.grey[500], height: 1.4),
        ),
        const SizedBox(height: 14),

        // Body view mode
        Row(
          children: [
            SizedBox(
              width: 100,
              child: Text(S.of(context).bodyView,
                  style: TextStyle(fontSize: 13, color: Colors.grey[500])),
            ),
            Expanded(
              child: SegmentedButton<BodyViewMode>(
                segments: [
                  ButtonSegment(
                    value: BodyViewMode.tree,
                    icon: Icon(LucideIcons.listTree, size: 14),
                    label: Text(S.of(context).tree),
                  ),
                  ButtonSegment(
                    value: BodyViewMode.json,
                    icon: Icon(LucideIcons.braces, size: 14),
                    label: Text(S.of(context).json),
                  ),
                  ButtonSegment(
                    value: BodyViewMode.code,
                    icon: Icon(LucideIcons.code, size: 14),
                    label: Text(S.of(context).code),
                  ),
                ],
                selected: {viewMode},
                onSelectionChanged: (value) {
                  ref
                      .read(bodyViewModeProvider.notifier)
                      .set(value.first);
                },
                style: ButtonStyle(
                  textStyle: WidgetStateProperty.all(
                    const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(left: 100),
          child: Text(
            _modeDescription(ref, viewMode),
            style: TextStyle(fontSize: 10, color: Colors.grey[600], height: 1.4),
          ),
        ),
        const SizedBox(height: 14),

        // Tab animation toggle
        Row(
          children: [
            SizedBox(
              width: 100,
              child: Text(S.of(context).tabAnimation,
                  style: TextStyle(fontSize: 13, color: Colors.grey[500])),
            ),
            Switch.adaptive(
              value: animEnabled,
              onChanged: (v) =>
                  ref.read(tabAnimationEnabledProvider.notifier).set(v),
            ),
            const SizedBox(width: 8),
            Text(
              animEnabled ? S.of(context).on : S.of(context).off,
              style: TextStyle(
                fontSize: 12,
                color: animEnabled
                    ? ColorTokens.primary
                    : Colors.grey[500],
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Duration slider (only when enabled)
        Opacity(
          opacity: animEnabled ? 1.0 : 0.45,
          child: IgnorePointer(
            ignoring: !animEnabled,
            child: Row(
              children: [
                SizedBox(
                  width: 100,
                  child: Text(S.of(context).duration,
                      style:
                          TextStyle(fontSize: 13, color: Colors.grey[500])),
                ),
                Expanded(
                  child: Slider(
                    value: animMs.toDouble(),
                    min: 0,
                    max: 1000,
                    divisions: 20,
                    label: '${animMs}ms',
                    onChanged: (v) => ref
                        .read(tabAnimationDurationProvider.notifier)
                        .set(v.round()),
                  ),
                ),
                SizedBox(
                  width: 54,
                  child: Text(
                    '${animMs}ms',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontFamily: AppConstants.monoFontFamily,
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}