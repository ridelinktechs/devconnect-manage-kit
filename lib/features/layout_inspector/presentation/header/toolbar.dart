import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/chrome_palette.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../settings/presentation/tips/page_guide_button.dart';
import '../shared/mini_button.dart';

class Toolbar extends StatelessWidget {
  final String title;

  /// (platform, "app · device")
  final (String, String)? device;
  final int? count;
  final DateTime? capturedAt;
  final String? captureLabel;
  final bool capturing;
  final VoidCallback? onCapture;

  /// Drops the capture on screen, when there's one.
  final VoidCallback? onClose;

  /// The export menu's items, when there's a capture to export.
  final List<Widget>? exports;

  const Toolbar({
    super.key,
    required this.title,
    required this.device,
    required this.count,
    required this.capturedAt,
    required this.captureLabel,
    required this.capturing,
    required this.onCapture,
    required this.onClose,
    required this.exports,
  });

  @override
  Widget build(BuildContext context) {
    final palette = ChromePalette.of(context);
    final muted = TextStyle(fontSize: 12, color: palette.textMuted);
    Widget meta(IconData icon, String text) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: palette.textMuted),
        const SizedBox(width: 5),
        Text(
          text,
          style: chromeMono(context, size: 12, color: palette.textMuted),
        ),
      ],
    );
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: palette.isDark ? ColorTokens.darkBackground : Colors.white,
        border: Border(bottom: BorderSide(color: palette.border)),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.scanSearch, size: 16, color: ColorTokens.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: palette.text,
            ),
          ),
          const PageGuideButton(route: '/layout'),
          if (device case (final platform, final label)) ...[
            const SizedBox(width: 12),
            Icon(
              platformLook(platform, isDark: palette.isDark).$1,
              size: 13,
              color: platformLook(platform, isDark: palette.isDark).$2,
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: muted,
              ),
            ),
          ] else
            const Spacer(),
          if (count case final count?) ...[
            meta(LucideIcons.listTree, '$count'),
            const SizedBox(width: 14),
          ],
          if (capturedAt case final at?) ...[
            meta(LucideIcons.clock, DateFormat('HH:mm:ss').format(at)),
            const SizedBox(width: 10),
          ],
          if (exports case final items?) ...[
            MenuAnchor(
              menuChildren: items,
              builder: (context, controller, _) => MiniButton(
                icon: LucideIcons.download,
                tooltip: S.of(context).layoutExport,
                onTap: () =>
                    controller.isOpen ? controller.close() : controller.open(),
              ),
            ),
          ],
          if (onClose case final close?)
            MiniButton(
              icon: LucideIcons.x,
              tooltip: S.of(context).layoutClose,
              onTap: close,
            ),
          if (exports != null || onClose != null) const SizedBox(width: 8),
          if (captureLabel case final label?)
            FilledButton.icon(
              onPressed: capturing ? null : onCapture,
              icon: capturing
                  ? const SizedBox.square(
                      dimension: 12,
                      child: CircularProgressIndicator(strokeWidth: 1.5),
                    )
                  : const Icon(LucideIcons.camera, size: 14),
              label: Text(label),
              style: FilledButton.styleFrom(
                backgroundColor: ColorTokens.primary,
                foregroundColor: Colors.white,
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
