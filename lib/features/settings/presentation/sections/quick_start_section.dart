import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../header/section_title.dart';

/// "Quick Start" card — three side-by-side [StepCard]s (install / init /
/// connect) showing copy-paste code snippets for each platform.
class QuickStartSection extends StatelessWidget {
  final String ip;

  const QuickStartSection({super.key, required this.ip});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final codeBg = isDark ? ColorTokens.darkSurface : const Color(0xFFF0F0F0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(icon: LucideIcons.zap, title: S.of(context).quickStart),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: StepCard(
                number: '1',
                icon: LucideIcons.package,
                accent: const Color(0xFF42A5F5),
                title: S.of(context).installSdk,
                code: 'Flutter:  flutter pub add devconnect_manage_kit\n'
                    'RN:      yarn add devconnect-manage-kit\n'
                    'Android: implementation("com.github...")',
                codeBg: codeBg,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StepCard(
                number: '2',
                icon: LucideIcons.playCircle,
                accent: ColorTokens.primary,
                title: S.of(context).initialize,
                code: 'Flutter:  await DevConnect.init(appName: "MyApp");\n'
                    'RN:      await DevConnect.init({ appName: "MyApp" });\n'
                    'Android: DevConnect.init(ctx, appName = "MyApp")',
                codeBg: codeBg,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StepCard(
                number: '3',
                icon: LucideIcons.radio,
                accent: ColorTokens.success,
                title: S.of(context).connect,
                code: 'Emulator: auto-detect\n'
                    'WiFi:     host: "$ip"\n'
                    'USB:      see USB Tools above',
                codeBg: codeBg,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// One of the three numbered Quick Start cards: circle badge + icon +
/// title, followed by a mono-font code block (selectable text).
class StepCard extends StatelessWidget {
  final String number;
  final IconData icon;
  final Color accent;
  final String title;
  final String code;
  final Color codeBg;

  const StepCard({
    super.key,
    required this.number,
    required this.icon,
    required this.accent,
    required this.title,
    required this.code,
    required this.codeBg,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: accent.withValues(alpha: 0.4)),
              ),
              alignment: Alignment.center,
              child: Text(
                number,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: accent,
                  fontFamily: AppConstants.monoFontFamily,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(icon, size: 14, color: accent),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                title,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: codeBg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: SelectableText(
            code,
            style: TextStyle(
              fontFamily: AppConstants.monoFontFamily,
              fontSize: 10,
              color: isDark ? const Color(0xFF8B949E) : Colors.black87,
              height: 1.55,
            ),
          ),
        ),
      ],
    );
  }
}