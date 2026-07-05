import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../models/log/error_event.dart';
import '../../provider/error_providers.dart';
import '../shared/count_up.dart';
import '../shared/error_tokens.dart' show platformColor, platformLabel;

/// Stats strip rendered below the toolbar — "Total / Fatal" on the
/// left, then a [PlatformCountCell] per [ErrorPlatform] (JS / Native /
/// Android / iOS) on the right.
///
/// Visual treatment:
/// - No card container; just a 24-px-tall row of monochrome cells
///   separated by 1px dividers — fits the "data zone" feel of the page
/// - Each per-platform cell has a 6-px color dot (saturated when
///   count > 0, dimmed when 0) so platforms with no errors read as
///   "muted/zero" rather than "missing"
class InfoBar extends ConsumerWidget {
  const InfoBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final total = ref.watch(errorCountProvider);
    final fatal = ref.watch(fatalErrorCountProvider);
    final counts = ref.watch(errorCountByPlatformProvider);

    return Row(
      children: [
        _Cell(
          icon: LucideIcons.activity,
          label: 'TOTAL',
          value: total,
          color: Colors.grey,
          isDark: isDark,
        ),
        _Divider(isDark: isDark),
        _Cell(
          icon: LucideIcons.zap,
          label: 'FATAL',
          value: fatal,
          color: Colors.red,
          isDark: isDark,
        ),
        for (final platform in ErrorPlatform.values) ...[
          _Divider(isDark: isDark),
          _PlatformCountCell(platform: platform, count: counts[platform] ?? 0),
        ],
      ],
    );
  }
}

class _Cell extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final Color color;
  final bool isDark;

  const _Cell({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          CountUp(
            value: value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFamily: AppConstants.monoFontFamily,
              letterSpacing: -0.3,
              color: value > 0
                  ? (isDark ? Colors.grey[200] : Colors.grey[800])
                  : (isDark ? Colors.grey[500] : Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }
}

/// One per-platform cell. Renders the color dot + uppercase platform
/// label + animated count. When the count is zero, the dot fades and
/// the text drops to muted grey so platforms with no errors read as
/// "muted/zero" rather than "missing".
class _PlatformCountCell extends StatelessWidget {
  final ErrorPlatform platform;
  final int count;

  const _PlatformCountCell({required this.platform, required this.count});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = platformColor(platform);
    return Expanded(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: count > 0 ? color : color.withValues(alpha: 0.3),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            platformLabel(platform).toUpperCase(),
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: count > 0
                  ? (isDark ? Colors.grey[200] : Colors.grey[800])
                  : (isDark ? Colors.grey[500] : Colors.grey[600]),
            ),
          ),
          const SizedBox(width: 8),
          CountUp(
            value: count,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFamily: AppConstants.monoFontFamily,
              letterSpacing: -0.3,
              color: count > 0
                  ? (isDark ? Colors.grey[200] : Colors.grey[800])
                  : (isDark ? Colors.grey[500] : Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }
}

/// 1×24-px vertical divider that separates [InfoBar] cells.
class _Divider extends StatelessWidget {
  final bool isDark;
  const _Divider({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 24,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      color: isDark
          ? Colors.white.withValues(alpha: 0.06)
          : Colors.black.withValues(alpha: 0.06),
    );
  }
}