import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/color_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/network/network_entry.dart';
import '../badges/net_stat_chip.dart';
import '../charts/network_waterfall_painter.dart';
import '../shared/format/speed.dart';

/// 150px-tall network panel: left label column (icon + "Network" +
/// `N reqs` + live count badge) + right chart area with 5 stat
/// chips and a [NetworkWaterfallPainter] waterfall.
class ProfilerNetworkRow extends StatelessWidget {
  final bool isDark;
  final List<NetworkEntry> networkHistory;
  final int activeRequests;
  final double reqPerSec;
  final double? avgResponse;
  final double errorRate;
  final double downloadSpeed;
  final double uploadSpeed;

  const ProfilerNetworkRow({
    super.key,
    required this.isDark,
    required this.networkHistory,
    required this.activeRequests,
    required this.reqPerSec,
    required this.avgResponse,
    required this.errorRate,
    required this.downloadSpeed,
    required this.uploadSpeed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      color: isDark ? ColorTokens.darkSurface : Colors.white,
      child: Row(
        children: [
          // Left label panel
          Container(
            width: 72,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : Colors.black.withValues(alpha: 0.04),
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(LucideIcons.globe, size: 14,
                    color: ColorTokens.chartBlue.withValues(alpha: 0.7)),
                const SizedBox(height: 4),
                Text(
                  S.of(context).network,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white54 : Colors.black45,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '${networkHistory.length} reqs',
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: ColorTokens.chartBlue,
                      height: 1,
                    ),
                  ),
                ),
                const Spacer(),
                if (activeRequests > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: ColorTokens.chartBlue.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '$activeRequests live',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                        color: ColorTokens.chartBlue,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Network chart area
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
              child: Column(
                children: [
                  // Network stat pills
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      NetStatChip(
                        label: 'req/s',
                        value: reqPerSec.toStringAsFixed(1),
                        color: ColorTokens.chartBlue,
                        isDark: isDark,
                      ),
                      NetStatChip(
                        label: 'avg',
                        value: avgResponse != null
                            ? '${avgResponse!.toStringAsFixed(0)}ms'
                            : '--',
                        color: ColorTokens.chartGreen,
                        isDark: isDark,
                      ),
                      NetStatChip(
                        label: 'err',
                        value: '${errorRate.toStringAsFixed(1)}%',
                        color: errorRate > 0
                            ? ColorTokens.chartRed
                            : ColorTokens.chartGreen,
                        isDark: isDark,
                      ),
                      NetStatChip(
                        label: '↓',
                        value: formatSpeed(downloadSpeed),
                        color: ColorTokens.chartGreen,
                        isDark: isDark,
                      ),
                      NetStatChip(
                        label: '↑',
                        value: formatSpeed(uploadSpeed),
                        color: const Color(0xFF8B5CF6),
                        isDark: isDark,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Network waterfall chart
                  Expanded(
                    child: networkHistory.length < 2
                        ? Center(
                            child: Text(
                              S.of(context).waitingForRequests,
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.white30 : Colors.black26,
                              ),
                            ),
                          )
                        : CustomPaint(
                            size: Size.infinite,
                            painter: NetworkWaterfallPainter(
                              entries: networkHistory,
                              isDark: isDark,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}