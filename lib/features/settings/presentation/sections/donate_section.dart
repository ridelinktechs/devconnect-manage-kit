import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/color_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../shared/donate_button.dart';

/// "Support DevConnect" card — heart icon + tagline + two [DonateButton]s
/// for Ko-fi and PayPal. Uses `Process.run` with platform-specific
/// `open` / `start` / `xdg-open` to launch the donation URLs.
class DonateSection extends StatelessWidget {
  const DonateSection({super.key});

  void _openUrl(String url) {
    if (Platform.isMacOS) {
      Process.run('open', [url]);
    } else if (Platform.isWindows) {
      Process.run('start', [url], runInShell: true);
    } else {
      Process.run('xdg-open', [url]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(LucideIcons.heart, size: 16, color: ColorTokens.error),
            const SizedBox(width: 8),
            Text(
              S.of(context).supportDevConnect,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          S.of(context).supportDevConnectDesc,
          style: TextStyle(fontSize: 12, color: Colors.grey[500], height: 1.4),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            DonateButton(
              label: S.of(context).kofi,
              icon: LucideIcons.coffee,
              color: const Color(0xFFFF5E5B),
              onTap: () => _openUrl('https://ko-fi.com/buivietphi'),
            ),
            const SizedBox(width: 10),
            DonateButton(
              label: S.of(context).paypal,
              icon: LucideIcons.creditCard,
              color: const Color(0xFF0070BA),
              onTap: () => _openUrl('https://paypal.me/buivietphi'),
            ),
          ],
        ),
      ],
    );
  }
}