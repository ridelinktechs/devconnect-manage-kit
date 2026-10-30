import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../components/feedback/empty_state.dart';
import '../../../../components/text/text_component.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/utils/scroll/smooth_scroll_controller.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../models/state/state_change.dart';

/// Diff tab: one card per added, removed or changed state path.
class DiffView extends StatefulWidget {
  final List<StateDiffEntry> diff;

  const DiffView({super.key, required this.diff});

  @override
  State<DiffView> createState() => _DiffViewState();
}

class _DiffViewState extends State<DiffView> {
  final _scrollController = SmoothScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final diff = widget.diff;
    if (diff.isEmpty) {
      return EmptyState(
        icon: LucideIcons.equal,
        title: S.of(context).noChangesDetected,
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: diff.length,
      itemBuilder: (context, index) {
        final d = diff[index];
        Color opColor;
        IconData opIcon;
        switch (d.operation) {
          case 'add':
            opColor = ColorTokens.success;
            opIcon = LucideIcons.plus;
            break;
          case 'remove':
            opColor = ColorTokens.error;
            opIcon = LucideIcons.minus;
            break;
          default:
            opColor = ColorTokens.warning;
            opIcon = LucideIcons.arrowRight;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: opColor.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: opColor.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(opIcon, size: 12, color: opColor),
                  const SizedBox(width: 6),
                  TextComponent(
                    d.path,
                    style: TextStyle(
                      fontFamily: AppConstants.monoFontFamily,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: opColor,
                    ),
                  ),
                ],
              ),
              if (d.oldValue != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    TextComponent(
                      '- ',
                      style: TextStyle(
                        fontFamily: AppConstants.monoFontFamily,
                        fontSize: 11,
                        color: ColorTokens.error,
                      ),
                    ),
                    Expanded(
                      child: TextComponent(
                        '${d.oldValue}',
                        style: TextStyle(
                          fontFamily: AppConstants.monoFontFamily,
                          fontSize: 11,
                          color: ColorTokens.error.withValues(alpha: 0.8),
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if (d.newValue != null) ...[
                const SizedBox(height: 2),
                Row(
                  children: [
                    TextComponent(
                      '+ ',
                      style: TextStyle(
                        fontFamily: AppConstants.monoFontFamily,
                        fontSize: 11,
                        color: ColorTokens.success,
                      ),
                    ),
                    Expanded(
                      child: TextComponent(
                        '${d.newValue}',
                        style: TextStyle(
                          fontFamily: AppConstants.monoFontFamily,
                          fontSize: 11,
                          color: ColorTokens.success,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
