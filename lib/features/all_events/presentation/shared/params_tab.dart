import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../components/feedback/empty_state.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/utils/toast_utils.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Tab content for the URL query parameters. Each parameter is its own
/// cell: an uppercase label on top (the key) and the value rendered
/// below in monospace. Copy button appears on hover so the row chrome
/// stays calm by default.
class ParamsTab extends StatelessWidget {
  final Uri uri;

  const ParamsTab({super.key, required this.uri});

  @override
  Widget build(BuildContext context) {
    final params = uri.queryParametersAll;
    if (params.isEmpty) {
      return Center(
        child: EmptyState(
          icon: LucideIcons.list,
          title: 'No params',
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final entries = params.entries.toList();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      itemCount: entries.length,
      itemBuilder: (context, i) {
        final e = entries[i];
        // queryParametersAll keeps the value as a list when the same
        // key appears more than once (`?a=1&a=2`). Render that on one
        // line so the cell doesn't grow unexpectedly.
        final value = e.value.join(', ');
        return _ParamCell(
          keyName: e.key,
          value: value,
          isDark: isDark,
        );
      },
    );
  }
}

/// One cell in the params list. Vertical layout: key (small label) on
/// top, value (mono, full) below. Border between cells is the only
/// divider — no card background, keeping density high so the user
/// can scan many params without losing context.
class _ParamCell extends StatefulWidget {
  final String keyName;
  final String value;
  final bool isDark;

  const _ParamCell({
    required this.keyName,
    required this.value,
    required this.isDark,
  });

  @override
  State<_ParamCell> createState() => _ParamCellState();
}

class _ParamCellState extends State<_ParamCell> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final muted = widget.isDark
        ? ColorTokens.lightBackground.withValues(alpha: 0.4)
        : Colors.black45;
    final fg = widget.isDark
        ? ColorTokens.lightBackground
        : ColorTokens.darkNeutral;
    final divider = widget.isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.05);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: divider, width: 1),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Vertical stack: key label (top), value (bottom)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Key — small uppercase label, color-coded so the
                  // eye can latch onto the "what" before the value.
                  Text(
                    widget.keyName.toUpperCase(),
                    style: TextStyle(
                      fontFamily: AppConstants.monoFontFamily,
                      fontSize: 10,
                      color: ColorTokens.info,
                      letterSpacing: 0.6,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Value — selectable so the user can drag-copy part
                  // of a long value without taking the whole thing.
                  SelectableText(
                    widget.value,
                    style: TextStyle(
                      fontFamily: AppConstants.monoFontFamily,
                      fontSize: 12,
                      color: fg,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Copy button — appears on hover, stays out of the way
            // otherwise. Aligns to the top so a tall value cell still
            // puts the action near the key label.
            AnimatedOpacity(
              duration: const Duration(milliseconds: 120),
              opacity: _hovered ? 1.0 : 0.0,
              child: Tooltip(
                message: 'Copy ${widget.keyName}',
                waitDuration: const Duration(milliseconds: 300),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(
                          text: '${widget.keyName}=${widget.value}'));
                      showCopiedToast(context, label: 'Param copied');
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        LucideIcons.copy,
                        size: 12,
                        color: muted,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}