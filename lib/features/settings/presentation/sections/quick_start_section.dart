import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/chrome_palette.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../header/section_title.dart';
import '../quickstart/install_box.dart';

/// Quick Start card — an install box per platform (Flutter / React Native
/// / Android) with the code that starts the SDK, then how each kind of
/// device reaches this machine at [ip] on [port].
class QuickStartSection extends StatelessWidget {
  final String ip;
  final int port;

  const QuickStartSection({super.key, required this.ip, required this.port});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final p = ChromePalette.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(icon: LucideIcons.zap, title: s.quickStart),
        Text(
          s.quickStartDesc,
          style: TextStyle(fontSize: 12, height: 1.45, color: p.textMuted),
        ),
        const SizedBox(height: 14),
        InstallBox(
          nextLabel: s.quickStartNext,
          copyLabel: s.copy,
          copiedLabel: s.copied,
          targets: const [
            (
              name: 'Flutter',
              prompt: true,
              before: ['flutter pub add '],
              package: 'devconnect_manage_kit',
              after: '',
              next: [
                '// main.dart › main()',
                'await DevConnect.initAndRunApp(',
                "  appName: 'MyApp',",
                '  runApp: () async => runApp(const MyApp()),',
                ');',
              ],
            ),
            (
              name: 'React Native',
              prompt: true,
              before: ['yarn add ', 'npm install '],
              package: 'devconnect-manage-kit',
              after: '',
              next: [
                '// App.tsx',
                'import { DevConnect } from "devconnect-manage-kit";',
                'DevConnect.init({ appName: "MyApp" });',
              ],
            ),
            (
              name: 'Android',
              prompt: false,
              before: ['implementation("'],
              package: 'io.github.buivietphi:devconnect-android:1.1.0',
              after: '")',
              next: [
                '// MyApp.kt › onCreate()',
                'DevConnect.installForApp(',
                '    context = this,',
                '    appName = "MyApp",',
                '    enabled = BuildConfig.DEBUG,',
                ')',
              ],
            ),
          ],
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _Hint(
              icon: LucideIcons.monitorSmartphone,
              text: s.quickStartEmulator,
            ),
            _Hint(icon: LucideIcons.wifi, text: s.quickStartWifi, value: ip),
            _Hint(
              icon: LucideIcons.usb,
              text: s.quickStartUsb,
              value: 'adb reverse tcp:$port tcp:$port',
            ),
          ],
        ),
      ],
    );
  }
}

/// A way to connect: icon, a few words and an optional value in mono.
class _Hint extends StatelessWidget {
  final IconData icon;
  final String text;
  final String? value;

  const _Hint({required this.icon, required this.text, this.value});

  @override
  Widget build(BuildContext context) {
    final p = ChromePalette.of(context);
    final value = this.value;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: p.text.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: p.border.withValues(alpha: 0.8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: p.textMuted),
          const SizedBox(width: 7),
          Text(text, style: TextStyle(fontSize: 12, color: p.text)),
          if (value != null) ...[
            const SizedBox(width: 7),
            Text(
              value,
              style: chromeMono(
                context,
                size: 11.5,
                color: p.textMuted,
                weight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
