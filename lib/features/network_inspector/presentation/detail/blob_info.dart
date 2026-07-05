import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../l10n/app_localizations.dart';

/// Empty-state-ish widget shown in place of a body viewer when the SDK
/// captured a binary blob. Renders the placeholder's label + size in a
/// neutral "data was hidden" message, so users know the request succeeded
/// but the payload is not displayable as text.
class BlobInfo extends StatelessWidget {
  final String label;
  final int sizeBytes;
  final bool isDark;

  const BlobInfo({
    super.key,
    required this.label,
    required this.sizeBytes,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.package,
                size: 28, color: isDark ? Colors.white38 : Colors.black38),
            const SizedBox(height: 12),
            Text(
              S.of(context).binaryBody(label),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? ColorTokens.lightBackground
                    : ColorTokens.darkNeutral,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              S.of(context).binaryBodySize(
                AppConstants.formatBytes(sizeBytes),
                sizeBytes,
              ),
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white54 : Colors.black54,
                fontFamily: AppConstants.monoFontFamily,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              S.of(context).binaryBodyHint,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white38 : Colors.black45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}