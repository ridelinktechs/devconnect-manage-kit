import 'package:flutter/material.dart';

import '../../core/theme/chrome_palette.dart';

/// Where an event came from: the platform by name in its brand color, then
/// the app and device.
class SourceLabel extends StatelessWidget {
  /// The handshake's `platform`, e.g. `react_native`.
  final String platform;

  /// "App · device".
  final String? source;

  const SourceLabel({super.key, required this.platform, this.source});

  @override
  Widget build(BuildContext context) {
    final p = ChromePalette.of(context);
    final (icon, brand) = platformLook(platform, isDark: p.isDark);
    final base = DefaultTextStyle.of(
      context,
    ).style.copyWith(fontSize: 10.5, height: 1.4);
    return Container(
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: 7),
      decoration: BoxDecoration(
        color: p.selected,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: p.border.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: brand),
          const SizedBox(width: 4),
          Text(switch (platform) {
            'react_native' => 'RN',
            'flutter' => 'Flutter',
            'android' => 'Android',
            _ => platform,
          }, style: base.copyWith(fontWeight: FontWeight.w800, color: brand)),
          if (source case final source?) ...[
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                source,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: base.copyWith(
                  fontWeight: FontWeight.w600,
                  color: p.textMuted,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
