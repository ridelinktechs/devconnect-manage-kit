import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/chrome_palette.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../settings/presentation/shared/focus_ring.dart';
import '../../../settings/presentation/tips/code_snippet.dart';
import '../shared/state_setup_code.dart';

/// "Set up in your Flutter app ›" under a control that needs app code; it
/// opens to that code for the selected device's platform, with a copy
/// button. Nothing shows for a platform without such code.
class SetupDisclosure extends StatefulWidget {
  /// The handshake `platform` of the selected device.
  final String platform;

  /// The control's code by platform: the file and the code.
  final Map<String, (String, String)> setup;

  const SetupDisclosure({
    super.key,
    required this.platform,
    required this.setup,
  });

  @override
  State<SetupDisclosure> createState() => _SetupDisclosureState();
}

class _SetupDisclosureState extends State<SetupDisclosure> {
  bool _open = false;
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final code = widget.setup[widget.platform];
    if (code == null) return const SizedBox.shrink();
    final p = ChromePalette.of(context);
    final (icon, brand) = platformLook(widget.platform, isDark: p.isDark);
    final name = platformName(widget.platform);
    final color = _hover || _open ? p.text : p.textMuted;
    final motion = !MediaQuery.disableAnimationsOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: FocusRing(
            onTap: () => setState(() => _open = !_open),
            radius: 8,
            selected: _open,
            label: S.of(context).stateSetupIn(name),
            onHover: (v) => setState(() => _hover = v),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: _hover ? p.hover : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 13, color: brand),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      S.of(context).stateSetupIn(name),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: DefaultTextStyle.of(context).style.copyWith(
                        fontSize: 12,
                        height: 1.3,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  AnimatedRotation(
                    turns: _open ? 0.25 : 0,
                    duration: motion
                        ? const Duration(milliseconds: 200)
                        : Duration.zero,
                    child: Icon(
                      LucideIcons.chevronRight,
                      size: 13,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_open) ...[
          const SizedBox(height: 6),
          CodeSnippet(label: '$name · ${code.$1}', code: code.$2),
        ],
      ],
    );
  }
}
