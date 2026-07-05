import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../components/text/text_component.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/utils/duration_format.dart';
import '../../../../core/utils/smooth_scroll_controller.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/network/network_entry.dart';

/// Network timing view: large duration hero card with a 270° gauge, a
/// timeline (start/end), and a method/status info card.
///
/// Local copy of `TimingView` in `all_events/presentation/network/`. Kept
/// separate per the "no cross-feature imports" refactor convention.
///
/// Note: the in-header compact [TimingBar] lives in this file too — it's
/// the linear-progress variant used in the URL bar. The full-screen
/// [TimingTab] above is the gauge + cards variant.
class TimingTab extends StatefulWidget {
  final NetworkEntry entry;

  const TimingTab({super.key, required this.entry});

  @override
  State<TimingTab> createState() => _TimingTabState();
}

class _TimingTabState extends State<TimingTab> {
  final _scrollController = SmoothScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final duration = entry.duration;
    final startDt = DateTime.fromMillisecondsSinceEpoch(entry.startTime);
    final endDt = entry.endTime != null
        ? DateTime.fromMillisecondsSinceEpoch(entry.endTime!)
        : null;

    Color durationColor;
    String durationLabel;
    IconData durationIcon;
    if (duration == null) {
      durationColor = Colors.grey;
      durationLabel = 'In Progress';
      durationIcon = LucideIcons.loader;
    } else if (duration < 200) {
      durationColor = ColorTokens.success;
      durationLabel = 'Fast';
      durationIcon = LucideIcons.zap;
    } else if (duration < 500) {
      durationColor = ColorTokens.warning;
      durationLabel = 'Normal';
      durationIcon = LucideIcons.clock;
    } else if (duration < 2000) {
      durationColor = const Color(0xFFE5853D);
      durationLabel = 'Slow';
      durationIcon = LucideIcons.triangleAlert;
    } else {
      durationColor = ColorTokens.error;
      durationLabel = 'Very Slow';
      durationIcon = LucideIcons.circleAlert;
    }

    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Duration hero card
          if (duration != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    durationColor.withValues(alpha: 0.12),
                    durationColor.withValues(alpha: 0.04),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: durationColor.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: durationColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(durationIcon, size: 22, color: durationColor),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextComponent(
                        formatDuration(duration),
                        style: TextStyle(
                          fontFamily: AppConstants.monoFontFamily,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: durationColor,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      TextComponent(
                        durationLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: durationColor.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  SizedBox(
                    width: 56,
                    height: 56,
                    child: CustomPaint(
                      painter: GaugePainter(
                        ratio: (duration / 2000).clamp(0.0, 1.0),
                        color: durationColor,
                        isDark: isDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          // Timeline card
          TimingInfoCard(
            isDark: isDark,
            children: [
              TimingInfoRow(
                icon: LucideIcons.play,
                iconColor: ColorTokens.success,
                label: S.of(context).startTime,
                value: DateFormat('HH:mm:ss.SSS').format(startDt),
                subtitle: DateFormat('yyyy-MM-dd').format(startDt),
                isDark: isDark,
              ),
              if (endDt != null) ...[
                TimingDividerLine(isDark: isDark),
                TimingInfoRow(
                  icon: LucideIcons.square,
                  iconColor: ColorTokens.error,
                  label: S.of(context).endTime,
                  value: DateFormat('HH:mm:ss.SSS').format(endDt),
                  subtitle: DateFormat('yyyy-MM-dd').format(endDt),
                  isDark: isDark,
                ),
              ],
            ],
          ),
          if (entry.statusCode > 0) ...[
            const SizedBox(height: 12),
            TimingInfoCard(
              isDark: isDark,
              children: [
                TimingInfoRow(
                  icon: LucideIcons.arrowUpRight,
                  iconColor: ColorTokens.primary,
                  label: 'Method',
                  value: entry.method,
                  isDark: isDark,
                ),
                TimingDividerLine(isDark: isDark),
                TimingInfoRow(
                  icon: LucideIcons.hash,
                  iconColor: entry.statusCode >= 400
                      ? ColorTokens.error
                      : ColorTokens.success,
                  label: 'Status',
                  value: '${entry.statusCode}',
                  isDark: isDark,
                ),
              ],
            ),
          ],
          if (entry.error != null) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ColorTokens.error.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: ColorTokens.error.withValues(alpha: 0.15)),
              ),
              child: TextComponent(
                entry.error!,
                style: TextStyle(
                  fontFamily: AppConstants.monoFontFamily,
                  fontSize: 11,
                  color: ColorTokens.error.withValues(alpha: 0.9),
                  height: 1.5,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Card container that groups one or more [TimingInfoRow]s with a thin
/// border + rounded corners. Used for the timeline and status cards.
class TimingInfoCard extends StatelessWidget {
  final bool isDark;
  final List<Widget> children;
  const TimingInfoCard({
    super.key,
    required this.isDark,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? ColorTokens.darkBackground : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Column(children: children),
    );
  }
}

/// One labelled value row inside a [TimingInfoCard]. Icon, fixed-width
/// label, value (and optional subtitle) on the right.
class TimingInfoRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String? subtitle;
  final bool isDark;

  const TimingInfoRow({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.subtitle,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(icon, size: 14, color: iconColor),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: TextComponent(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[500],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextComponent(
                  value,
                  style: TextStyle(
                    fontFamily: AppConstants.monoFontFamily,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                if (subtitle != null)
                  TextComponent(
                    subtitle!,
                    style: TextStyle(
                      fontFamily: AppConstants.monoFontFamily,
                      fontSize: 10,
                      color: Colors.grey[500],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Thin 1px divider inside a [TimingInfoCard] with a left indent so the
/// line doesn't visually touch the icon column.
class TimingDividerLine extends StatelessWidget {
  final bool isDark;
  const TimingDividerLine({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 28),
      child: Divider(
        height: 1,
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.06),
      ),
    );
  }
}

/// 270° arc gauge for the duration hero. Draws a tinted background arc
/// then a value arc sized to the duration ratio.
class GaugePainter extends CustomPainter {
  final double ratio;
  final Color color;
  final bool isDark;

  GaugePainter({
    required this.ratio,
    required this.color,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2 - 4;
    const startAngle = 2.356;
    const sweepTotal = 4.712;

    // Background arc
    final bgPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      startAngle,
      sweepTotal,
      false,
      bgPaint,
    );

    // Value arc
    final valuePaint = Paint()
      ..color = color
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      startAngle,
      sweepTotal * ratio,
      false,
      valuePaint,
    );
  }

  @override
  bool shouldRepaint(GaugePainter old) =>
      old.ratio != ratio || old.color != color;
}

/// Compact linear-progress bar + duration label, used in the URL bar
/// inside the request detail panel. Different from the full
/// [TimingTab] hero card above — this is the at-a-glance hint when the
/// detail is collapsed.
class TimingBar extends StatelessWidget {
  final int duration;

  const TimingBar({super.key, required this.duration});

  @override
  Widget build(BuildContext context) {
    const maxWidth = 300.0;
    final ratio = (duration / 2000).clamp(0.0, 1.0);

    Color barColor;
    if (duration < 200) {
      barColor = ColorTokens.success;
    } else if (duration < 500) {
      barColor = ColorTokens.warning;
    } else {
      barColor = ColorTokens.error;
    }

    return Row(
      children: [
        SizedBox(
          width: maxWidth,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: ratio,
              backgroundColor: barColor.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation(barColor),
              minHeight: 4,
            ),
          ),
        ),
        const SizedBox(width: 8),
        TextComponent(
          formatDuration(duration),
          style: TextStyle(
            fontFamily: AppConstants.monoFontFamily,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: barColor,
          ),
        ),
      ],
    );
  }
}