import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../components/inputs/search_field.dart';
import '../../../../core/theme/chrome_palette.dart';
import '../../../../l10n/app_localizations.dart';
import '../shared/layout_style.dart';
import '../shared/mini_button.dart';

/// The tree's search field and, while searching, which match is current
/// with arrows to the others. Enter / ⇧ Enter step too.
class TreeSearchBar extends StatelessWidget {
  final TextEditingController controller;

  /// How many rows match, and the current one's index.
  final int matches;
  final int current;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  /// 1 for the next match, -1 for the previous one.
  final ValueChanged<int> onStep;

  const TreeSearchBar({
    super.key,
    required this.controller,
    required this.matches,
    required this.current,
    required this.onChanged,
    required this.onClear,
    required this.onStep,
  });

  @override
  Widget build(BuildContext context) {
    final loc = S.of(context);
    final palette = ChromePalette.of(context);
    final meta = chromeMono(context, size: 11, color: palette.textMuted);
    return Row(
      children: [
        Expanded(
          child: Focus(
            canRequestFocus: false,
            skipTraversal: true,
            onKeyEvent: (_, event) {
              if (event is! KeyDownEvent ||
                  event.logicalKey != LogicalKeyboardKey.enter) {
                return KeyEventResult.ignored;
              }
              onStep(HardwareKeyboard.instance.isShiftPressed ? -1 : 1);
              return KeyEventResult.handled;
            },
            child: SearchField(
              controller: controller,
              hintText: loc.layoutSearchHint,
              onChanged: onChanged,
              onClear: controller.text.isEmpty ? null : onClear,
            ),
          ),
        ),
        if (controller.text.trim().isNotEmpty) ...[
          const SizedBox(width: 6),
          Text(
            matches == 0 ? '0/0' : '${current + 1}/$matches',
            style: matches == 0
                ? meta.copyWith(color: LayoutColors.measure)
                : meta,
          ),
          const SizedBox(width: 2),
          MiniButton(
            icon: LucideIcons.chevronUp,
            tooltip: loc.jsonPrevMatch,
            onTap: matches == 0 ? null : () => onStep(-1),
          ),
          MiniButton(
            icon: LucideIcons.chevronDown,
            tooltip: loc.jsonNextMatch,
            onTap: matches == 0 ? null : () => onStep(1),
          ),
        ],
      ],
    );
  }
}
