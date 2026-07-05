import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../l10n/app_localizations.dart';

/// Mono-font code line with a trailing copy glyph. Tapping the whole
/// row fires [onCopy] with the verbatim code string — same flow as the
/// inline copy buttons elsewhere in the app (clipboard + toast).
class CodeBlock extends StatelessWidget {
  final String code;
  final Color bg;
  final void Function(String, [String?]) onCopy;

  const CodeBlock({
    super.key,
    required this.code,
    required this.bg,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onCopy(code, S.of(context).copied),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  code,
                  style: const TextStyle(
                    fontFamily: AppConstants.monoFontFamily,
                    fontSize: 12,
                    color: ColorTokens.secondary,
                  ),
                ),
              ),
              Icon(LucideIcons.copy, size: 12, color: Colors.grey[500]),
            ],
          ),
        ),
      ),
    );
  }
}