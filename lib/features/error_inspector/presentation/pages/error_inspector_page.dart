import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../components/text/text_component.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../components/inputs/search_field.dart';
import '../../../../components/lists/stable_list_view.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/utils/screenshot_utils.dart';
import '../../../../components/viewers/json_viewer.dart';
import '../../../../core/utils/toast_utils.dart';
import '../../../../core/utils/smooth_scroll_controller.dart';
import '../../../../models/log/error_event.dart';
import '../../provider/error_providers.dart';

Color _severityColor(ErrorSeverity severity) {
  switch (severity) {
    case ErrorSeverity.fatal:
      return Colors.red.shade900;
    case ErrorSeverity.crash:
      return Colors.red;
    case ErrorSeverity.error:
      return ColorTokens.logError;
    case ErrorSeverity.warning:
      return ColorTokens.logWarn;
    case ErrorSeverity.info:
      return ColorTokens.logInfo;
  }
}

String _platformLabel(ErrorPlatform platform) {
  switch (platform) {
    case ErrorPlatform.js: return 'JS';
    case ErrorPlatform.native: return 'Native';
    case ErrorPlatform.android: return 'Android';
    case ErrorPlatform.ios: return 'iOS';
  }
}

Color _platformColor(ErrorPlatform platform) {
  switch (platform) {
    case ErrorPlatform.js: return Colors.blue;
    case ErrorPlatform.native: return Colors.purple;
    case ErrorPlatform.android: return Colors.green;
    case ErrorPlatform.ios: return Colors.orange;
  }
}

class ErrorInspectorPage extends ConsumerStatefulWidget {
  const ErrorInspectorPage({super.key});

  @override
  ConsumerState<ErrorInspectorPage> createState() => _ErrorInspectorPageState();
}

class _ErrorInspectorPageState extends ConsumerState<ErrorInspectorPage> {
  final _scrollController = SmoothScrollController();
  final _selectedId = ValueNotifier<String?>(null);
  final _entryCount = ValueNotifier<int>(0);
  final _searchController = TextEditingController();
  bool _autoScroll = true;
  bool _programmaticScroll = false;
  int _visibleCount = 0;
  int _generation = 0;
  final List<ErrorEvent> _entries = [];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    ref.listenManual<List<ErrorEvent>>(
      filteredErrorEntriesProvider,
      (previous, next) {
        final prevLen = _entries.length;
        if (next.length > prevLen && previous != null && next.length - prevLen == next.length - previous.length) {
          _entries.addAll(next.sublist(prevLen));
          _entryCount.value = _entries.length;
          if (!_autoScroll) return;
          _visibleCount = _entries.length;
          setState(() {});
          _autoScrollIfNeeded();
        } else {
          _entries..clear()..addAll(next);
          _entryCount.value = _entries.length;
          _visibleCount = _entries.length;
          _generation++;
          setState(() {});
          if (_autoScroll) _autoScrollIfNeeded();
        }
      },
      fireImmediately: true,
    );
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    final reversed = ref.read(scrollDirectionProvider) == ScrollDirection.top;
    final atBottom = reversed
        ? pos.pixels <= pos.minScrollExtent + 2.0
        : pos.pixels >= pos.maxScrollExtent - 2.0;
    final distFromBottom = reversed
        ? pos.pixels - pos.minScrollExtent
        : pos.maxScrollExtent - pos.pixels;

    if (!_autoScroll && atBottom) {
      _autoScroll = true;
      _visibleCount = _entries.length;
      setState(() {});
      return;
    }

    if (_autoScroll && !_programmaticScroll && distFromBottom > 50.0) {
      _autoScroll = false;
      setState(() {});
      return;
    }

    if (!_autoScroll && _visibleCount < _entries.length) {
      if (distFromBottom < pos.viewportDimension * 1.5) {
        _visibleCount = _entries.length;
        setState(() {});
      }
    }
  }

  void _autoScrollIfNeeded() {
    if (!_autoScroll || _programmaticScroll) return;
    _programmaticScroll = true;
    _doAutoScroll();
  }

  void _doAutoScroll() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_autoScroll || !_scrollController.hasClients) {
        _programmaticScroll = false;
        return;
      }
      final reversed = ref.read(scrollDirectionProvider) == ScrollDirection.top;
      final pos = _scrollController.position;
      final target = reversed ? pos.minScrollExtent : pos.maxScrollExtent;
      final atTarget = reversed
          ? pos.pixels <= pos.minScrollExtent + 2.0
          : pos.pixels >= pos.maxScrollExtent - 2.0;
      if (atTarget) {
        _programmaticScroll = false;
        return;
      }
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
      ).whenComplete(() {
        if (!mounted || !_autoScroll || !_scrollController.hasClients) {
          _programmaticScroll = false;
          return;
        }
        final p = _scrollController.position;
        final done = reversed
            ? p.pixels <= p.minScrollExtent + 2.0
            : p.pixels >= p.maxScrollExtent - 2.0;
        if (!done) {
          _doAutoScroll();
        } else {
          _programmaticScroll = false;
        }
      });
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _selectedId.dispose();
    _entryCount.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _takeDetailScreenshot(BuildContext context, ErrorEvent entry) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = _severityColor(entry.severity);
    final time = DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(
      DateTime.fromMillisecondsSinceEpoch(entry.timestamp),
    );

    captureWidgetAsImage(
      context,
      Container(
        color: isDark ? ColorTokens.darkSurface : Colors.white,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: isDark ? ColorTokens.darkBackground : ColorTokens.lightSurface,
              child: Row(
                children: [
                  Icon(LucideIcons.alertTriangle, size: 16, color: color),
                  const SizedBox(width: 8),
                  _SeverityBadge(severity: entry.severity),
                  const SizedBox(width: 10),
                  _PlatformBadge(platform: entry.platform),
                  const SizedBox(width: 10),
                  Text(
                    time,
                    style: TextStyle(
                      fontFamily: AppConstants.monoFontFamily,
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.message,
                    style: TextStyle(
                      fontFamily: AppConstants.monoFontFamily,
                      fontSize: 13,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  if (entry.stackTrace != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      S.of(context).stackTrace,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[500],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.black26 : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        entry.stackTrace!,
                        style: TextStyle(
                          fontFamily: AppConstants.monoFontFamily,
                          fontSize: 11,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final errorCount = ref.watch(errorCountProvider);
    final fatalCount = ref.watch(fatalErrorCountProvider);
    final activeFilters = ref.watch(errorFilterProvider);

    return Column(
      children: [
        // ── Header bar ────────────────────────────────────────────────────
        // Anti-card-overuse: just a `border-b` divider, no background
        // container. Title left-aligned (variance 8) with the count pill
        // glowing red + pulsing when there are active errors (perpetual
        // motion; GSAP `repeat: -1` analog).
        Container(
          height: 56,
          padding: const EdgeInsets.fromLTRB(20, 0, 12, 0),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
              ),
            ),
          ),
          child: Row(
            children: [
              // Title — display weight, tight tracking
              Icon(LucideIcons.alertTriangle, size: 16, color: ColorTokens.logError),
              const SizedBox(width: 10),
              Text(
                S.of(context).errors,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  color: isDark
                      ? ColorTokens.lightBackground
                      : ColorTokens.darkNeutral,
                ),
              ),
              const SizedBox(width: 10),
              // Count pill with pulsing red dot when errors > 0
              ValueListenableBuilder<int>(
                valueListenable: _entryCount,
                builder: (context, count, _) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (count > 0)
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: _PulsingDot(
                            color: ColorTokens.logError,
                            size: 7,
                          ),
                        ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutCubic,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: count > 0
                              ? ColorTokens.logError.withValues(alpha: 0.12)
                              : (isDark
                                  ? Colors.white.withValues(alpha: 0.06)
                                  : Colors.black.withValues(alpha: 0.04)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: _CountUp(
                          value: count,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            fontFamily: AppConstants.monoFontFamily,
                            color: count > 0
                                ? ColorTokens.logError
                                : (isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600]),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(width: 16),

              // Platform filter chips — compact, color-tinted
              ...ErrorPlatform.values.map((platform) {
                final isActive = activeFilters.contains(platform);
                return Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: _PlatformFilterChip(
                    label: _platformLabel(platform),
                    isActive: isActive,
                    color: _platformColor(platform),
                    onTap: () {
                      final current = ref.read(errorFilterProvider);
                      if (isActive) {
                        ref.read(errorFilterProvider.notifier).state =
                            current.difference({platform});
                      } else {
                        ref.read(errorFilterProvider.notifier).state = {
                          ...current,
                          platform,
                        };
                      }
                    },
                  ),
                );
              }),

              const Spacer(),

              // Search
              SizedBox(
                width: 220,
                child: SearchField(
                  hintText: S.of(context).searchErrors,
                  controller: _searchController,
                  onClear: () {
                    _searchController.clear();
                    ref.read(errorSearchProvider.notifier).state = '';
                  },
                  onChanged: (v) => ref.read(errorSearchProvider.notifier).state = v,
                ),
              ),
              const SizedBox(width: 12),

              // Action group
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : Colors.black.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _IconBtn(
                      icon: LucideIcons.arrowDownToLine,
                      tooltip: _autoScroll ? S.of(context).autoScroll : S.of(context).stop,
                      isActive: _autoScroll,
                      onTap: () => setState(() => _autoScroll = !_autoScroll),
                    ),
                    const SizedBox(width: 2),
                    Consumer(
                      builder: (context, ref, _) {
                        final dir = ref.watch(scrollDirectionProvider);
                        final isTop = dir == ScrollDirection.top;
                        return _IconBtn(
                          icon: isTop
                              ? LucideIcons.arrowUpNarrowWide
                              : LucideIcons.arrowDownNarrowWide,
                          tooltip: isTop ? S.of(context).newestFirst : S.of(context).oldestFirst,
                          isActive: isTop,
                          onTap: () => ref.read(scrollDirectionProvider.notifier).state =
                              isTop ? ScrollDirection.bottom : ScrollDirection.top,
                        );
                      },
                    ),
                    const SizedBox(width: 2),
                    Container(
                      width: 1,
                      height: 18,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.08),
                    ),
                    const SizedBox(width: 2),
                    _IconBtn(
                      icon: LucideIcons.trash2,
                      tooltip: S.of(context).clearErrors,
                      isDanger: true,
                      onTap: () => ref.read(errorEntriesProvider.notifier).clear(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ── Unified info bar (replaces 2 cards + 4 platform chips) ────
        // No card containers, just a `border-b` + `divide-x` for visual
        // structure. Single accent color (red) for totals, monochrome for
        // platform counts. Tinted background only when count > 0 to
        // communicate "no errors" without shouting.
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: errorCount > 0
                ? ColorTokens.logError.withValues(alpha: 0.04)
                : Colors.transparent,
            border: Border(
              bottom: BorderSide(
                color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04),
              ),
            ),
          ),
          child: Row(
            children: [
              // Total — left-aligned, big monospace count, display weight
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildBarLabel(
                      icon: LucideIcons.alertTriangle,
                      label: S.of(context).totalErrors.toUpperCase(),
                      color: errorCount > 0
                          ? ColorTokens.logError
                          : (isDark ? Colors.grey.shade500 : Colors.grey.shade600),
                    ),
                    const SizedBox(width: 10),
                    _CountUp(
                      value: errorCount,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        fontFamily: AppConstants.monoFontFamily,
                        letterSpacing: -0.5,
                        color: errorCount > 0
                            ? ColorTokens.logError
                            : (isDark ? Colors.grey[300] : Colors.grey[700]),
                      ),
                    ),
                  ],
                ),
              ),
              _buildDivider(isDark),
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildBarLabel(
                      icon: LucideIcons.skull,
                      label: S.of(context).fatalCrash.toUpperCase(),
                      color: fatalCount > 0
                          ? Colors.red
                          : (isDark ? Colors.grey.shade500 : Colors.grey.shade600),
                    ),
                    const SizedBox(width: 10),
                    _CountUp(
                      value: fatalCount,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        fontFamily: AppConstants.monoFontFamily,
                        letterSpacing: -0.5,
                        color: fatalCount > 0
                            ? Colors.red
                            : (isDark ? Colors.grey[300] : Colors.grey[700]),
                      ),
                    ),
                  ],
                ),
              ),
              // Per-platform mini-bars (method prepends its own dividers)
              ..._buildPlatformCountBars(isDark),
            ],
          ),
        ),

        // ── Main content: list + detail panel ────────────────────────────
        Expanded(
          child: _entries.isEmpty
              ? _EmptyStateWithPulse(
                  title: S.of(context).noErrorsCaptured,
                  subtitle: S.of(context).errorsAppearHere,
                )
              : Row(
                  children: [
                    Expanded(
                      child: StableListView<ErrorEvent>(
                        controller: _scrollController,
                        reverse: ref.read(scrollDirectionProvider) == ScrollDirection.top,
                        generation: _generation,
                        childCount: _visibleCount,
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        entries: _entries,
                        itemExtent: 80,
                        idOf: (e) => e.id,
                        selectedId: _selectedId,
                        onSelect: (entry) {
                          final wasSelected = _selectedId.value == entry.id;
                          _selectedId.value = wasSelected ? null : entry.id;
                          if (!wasSelected && _autoScroll) {
                            _autoScroll = false;
                            _programmaticScroll = false;
                            if (_scrollController.hasClients) {
                              _scrollController.jumpTo(_scrollController.offset);
                            }
                            setState(() {});
                          }
                        },
                        contentBuilder: (context, entry) {
                          return _ErrorListItem(
                            entry: entry,
                            isSelected: _selectedId.value == entry.id,
                            onTap: () {
                              final wasSelected = _selectedId.value == entry.id;
                              _selectedId.value = wasSelected ? null : entry.id;
                            },
                            onCopy: () {
                              Clipboard.setData(ClipboardData(text: entry.stackTrace ?? entry.message));
                              showCopiedToast(context, label: S.of(context).stackTraceCopied);
                            },
                          );
                        },
                        decorationBuilder: (isSelected, isDark) {
                          return BoxDecoration(
                            color: isSelected
                                ? ColorTokens.selectedBg(isDark)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? ColorTokens.selectedBorder(isDark)
                                  : (isDark
                                      ? Colors.white.withValues(alpha: 0.04)
                                      : Colors.black.withValues(alpha: 0.04)),
                              width: 1,
                            ),
                          );
                        },
                      ),
                    ),
                    // Detail panel
                    ValueListenableBuilder<String?>(
                      valueListenable: _selectedId,
                      builder: (context, selectedIdValue, _) {
                        final selected = selectedIdValue != null
                            ? _entries.where((e) => e.id == selectedIdValue).firstOrNull
                            : null;
                        if (selected == null) return const SizedBox.shrink();
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            VerticalDivider(width: 1, color: isDark ? Colors.white10 : Colors.black12),
                            SizedBox(
                              width: MediaQuery.of(context).size.width * 0.35,
                              child: _ErrorDetailPanel(
                                key: ValueKey(selected.id),
                                entry: selected,
                                onClose: () => _selectedId.value = null,
                                onScreenshot: () => _takeDetailScreenshot(context, selected),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  // ── Tiny helpers (no card containers) ───────────────────────────────

  Widget _buildBarLabel({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
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
      ],
    );
  }

  Widget _buildDivider(bool isDark) {
    return Container(
      width: 1,
      height: 24,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      color: isDark
          ? Colors.white.withValues(alpha: 0.06)
          : Colors.black.withValues(alpha: 0.06),
    );
  }

  /// Replaces the old row-of-`_CountChip` widgets with a unified
  /// horizontal strip — each platform gets the same compact cell as
  /// total/fatal, just rendered with its own color dot.
  List<Widget> _buildPlatformCountBars(bool isDark) {
    final counts = ref.watch(errorCountByPlatformProvider);
    final widgets = <Widget>[];
    for (final platform in ErrorPlatform.values) {
      widgets.add(_buildDivider(isDark));
      final count = counts[platform] ?? 0;
      final color = _platformColor(platform);
      widgets.add(
        Expanded(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: count > 0
                      ? color
                      : color.withValues(alpha: 0.3),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _platformLabel(platform).toUpperCase(),
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
              _CountUp(
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
        ),
      );
    }
    return widgets;
  }

  Widget _buildPlatformCounts() {
    final counts = ref.watch(errorCountByPlatformProvider);
    return Row(
      children: [
        _CountChip(label: 'JS', count: counts[ErrorPlatform.js] ?? 0, color: Colors.blue),
        const SizedBox(width: 8),
        _CountChip(label: 'Native', count: counts[ErrorPlatform.native] ?? 0, color: Colors.purple),
        const SizedBox(width: 8),
        _CountChip(label: 'Android', count: counts[ErrorPlatform.android] ?? 0, color: Colors.green),
        const SizedBox(width: 8),
        _CountChip(label: 'iOS', count: counts[ErrorPlatform.ios] ?? 0, color: Colors.orange),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Count Pill
// ---------------------------------------------------------------------------

class _CountPill extends StatelessWidget {
  final int count;

  const _CountPill({required this.count});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          fontFamily: AppConstants.monoFontFamily,
          color: isDark ? Colors.grey[400] : Colors.grey[600],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// PulsingDot — small status indicator with perpetual motion
// (GSAP equivalent: a recursive tween with yoyo reverse)
//
// Used to draw the eye to a "live" status without being loud. Two
// stacked layers (expanding ring + solid dot) using `Curves.easeOutCubic`
// for the smooth deceleration GSAP ships out of the box.
// ---------------------------------------------------------------------------

class _PulsingDot extends StatefulWidget {
  final Color color;
  final double size;
  final Duration period;

  const _PulsingDot({
    required this.color,
    this.size = 8,
    this.period = const Duration(milliseconds: 1800),
  });

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.period)..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size * 3,
      height: widget.size * 3,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer expanding ring (perpetual "breathing" pulse).
          // Animate the color's alpha directly instead of wrapping in an
          // `Opacity` widget — that avoids intermediate offscreen render
          // passes on every animation tick (the inner Container is a
          // simple solid-color circle, so the Opacity layer is pure
          // overhead).
          AnimatedBuilder(
            animation: _ctrl,
            builder: (context, _) {
              return Transform.scale(
                scale: 0.6 + 0.8 * _ctrl.value,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    // Color alpha rides the same progress: starts at 0.6,
                    // fades to 0 as the ring expands.
                    color: widget.color.withValues(
                      alpha: 0.6 * (1 - _ctrl.value),
                    ),
                  ),
                ),
              );
            },
          ),
          // Solid dot (anchor)
          Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// CountUp — animates a number to its target value
// (GSAP equivalent: `gsap.to(target, {val: newVal, duration: 0.6, ease: "power3.out"})`)
// ---------------------------------------------------------------------------

class _CountUp extends StatelessWidget {
  final int value;
  final TextStyle? style;
  final Duration duration;
  final String Function(int)? formatter;

  const _CountUp({
    required this.value,
    this.style,
    this.duration = const Duration(milliseconds: 700),
    this.formatter,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value.toDouble()),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, v, _) {
        final n = v.toInt();
        return Text(
          formatter != null ? formatter!(n) : '$n',
          style: style,
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// EmptyStateWithPulse — rich empty state with breathing shield + rings
// Replaces the bland `EmptyState(icon: checkCircle, …)` with a layout
// that has actual motion: a stacked shield with two concentric
// breathing rings, dotted-grid backdrop hint, and a title that
// fades + slides in.
// ---------------------------------------------------------------------------

class _EmptyStateWithPulse extends StatefulWidget {
  final String title;
  final String subtitle;

  const _EmptyStateWithPulse({
    required this.title,
    required this.subtitle,
  });

  @override
  State<_EmptyStateWithPulse> createState() => _EmptyStateWithPulseState();
}

class _EmptyStateWithPulseState extends State<_EmptyStateWithPulse>
    with TickerProviderStateMixin {
  late final AnimationController _breathCtrl;
  late final AnimationController _entryCtrl;
  late final Animation<double> _entryOpacity;
  late final Animation<Offset> _entrySlide;

  @override
  void initState() {
    super.initState();
    // Slow breathing loop for the rings (perpetual motion, no user trigger)
    _breathCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);
    // One-shot entrance animation for the title + icon
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _entryOpacity = CurvedAnimation(
      parent: _entryCtrl,
      curve: Curves.easeOutCubic,
    );
    _entrySlide = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entryCtrl,
      curve: Curves.easeOutCubic,
    ));
    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _breathCtrl.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: FadeTransition(
        opacity: _entryOpacity,
        child: SlideTransition(
          position: _entrySlide,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated shield with breathing rings (perpetual motion)
              SizedBox(
                width: 120,
                height: 120,
                child: AnimatedBuilder(
                  animation: _breathCtrl,
                  builder: (context, _) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer ring
                        Transform.scale(
                          scale: 0.85 + 0.15 * _breathCtrl.value,
                          child: Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: ColorTokens.logError
                                    .withValues(alpha: 0.12 + 0.08 * _breathCtrl.value),
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                        // Inner ring
                        Transform.scale(
                          scale: 0.55 + 0.10 * (1 - _breathCtrl.value),
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: ColorTokens.logError
                                    .withValues(alpha: 0.20 + 0.10 * (1 - _breathCtrl.value)),
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                        // Shield icon
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: ColorTokens.logError.withValues(alpha: 0.10),
                            border: Border.all(
                              color: ColorTokens.logError.withValues(alpha: 0.30),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            LucideIcons.shieldCheck,
                            size: 28,
                            color: ColorTokens.logError,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  color: isDark
                      ? ColorTokens.lightBackground
                      : ColorTokens.darkNeutral,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey[500] : Colors.grey[600],
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Platform filter chip
// ---------------------------------------------------------------------------

class _PlatformFilterChip extends StatefulWidget {
  final String label;
  final bool isActive;
  final Color color;
  final VoidCallback onTap;

  const _PlatformFilterChip({
    required this.label,
    required this.isActive,
    required this.color,
    required this.onTap,
  });

  @override
  State<_PlatformFilterChip> createState() => _PlatformFilterChipState();
}

class _PlatformFilterChipState extends State<_PlatformFilterChip>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;

  // Short pop on tap — gsap.to(scale: 0.92, duration: 0.11) → scale: 1
  // (drives ScaleTransition below).
  late final AnimationController _tapCtrl;
  late final Animation<double> _tapScale;

  @override
  void initState() {
    super.initState();
    _tapCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 110),
    );
    // We drive `_tapCtrl` from 0 (no compression) to 1 (fully compressed)
    // and map to scale 1.0 → 0.92 with easeOut.
    _tapScale = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _tapCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _tapCtrl.dispose();
    super.dispose();
  }

  Future<void> _onTap() async {
    // 0 → 1: scale shrinks to 0.92; on completion, reverse back to 1.
    _tapCtrl.forward(from: 0);
    widget.onTap();
    await Future.delayed(const Duration(milliseconds: 110));
    if (!mounted) return;
    _tapCtrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = widget.color;

    // Background: active → filled tint, hover → faint tint, default → transparent
    final bg = widget.isActive
        ? c.withValues(alpha: isDark ? 0.18 : 0.14)
        : _hovered
            ? c.withValues(alpha: isDark ? 0.08 : 0.05)
            : Colors.transparent;

    // Text color: active → saturated, hover → 60%, default → 45% muted
    final textColor = widget.isActive
        ? c
        : _hovered
            ? c.withValues(alpha: 0.85)
            : c.withValues(alpha: 0.55);

    return Tooltip(
      message: '${widget.isActive ? "Hide" : "Show"} ${widget.label} errors',
      child: GestureDetector(
        onTap: _onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(8),
              border: widget.isActive
                  ? Border.all(color: c.withValues(alpha: 0.35), width: 1)
                  : Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.black.withValues(alpha: 0.06),
                      width: 1,
                    ),
            ),
            child: ScaleTransition(
              scale: _tapScale,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Color dot — pulses when active (perpetual motion)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.isActive
                          ? c
                          : c.withValues(alpha: _hovered ? 0.85 : 0.5),
                    ),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight:
                          widget.isActive ? FontWeight.w700 : FontWeight.w500,
                      color: textColor,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Icon Button
// ---------------------------------------------------------------------------

class _IconBtn extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final bool isActive;
  final bool isDanger;
  final VoidCallback onTap;

  const _IconBtn({
    required this.icon,
    required this.tooltip,
    this.isActive = false,
    this.isDanger = false,
    required this.onTap,
  });

  @override
  State<_IconBtn> createState() => _IconBtnState();
}

class _IconBtnState extends State<_IconBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color iconColor;
    Color bgColor;

    if (widget.isActive) {
      iconColor = ColorTokens.primary;
      bgColor = ColorTokens.primary.withValues(alpha: 0.15);
    } else if (widget.isDanger && _hovered) {
      iconColor = ColorTokens.error;
      bgColor = ColorTokens.error.withValues(alpha: 0.12);
    } else if (_hovered) {
      iconColor = isDark ? Colors.grey[300]! : Colors.grey[700]!;
      bgColor = isDark
          ? Colors.white.withValues(alpha: 0.08)
          : Colors.black.withValues(alpha: 0.06);
    } else {
      iconColor = isDark ? Colors.grey[500]! : Colors.grey[500]!;
      bgColor = Colors.transparent;
    }

    return Tooltip(
      message: widget.tooltip,
      child: GestureDetector(
        onTap: widget.onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(
              widget.icon,
              size: 14,
              color: iconColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? ColorTokens.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _CountChip({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$label: $count',
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500),
      ),
    );
  }
}

class _SeverityBadge extends StatelessWidget {
  final ErrorSeverity severity;

  const _SeverityBadge({required this.severity});

  @override
  Widget build(BuildContext context) {
    final color = _severityColor(severity);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        severity.name.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _PlatformBadge extends StatelessWidget {
  final ErrorPlatform platform;

  const _PlatformBadge({required this.platform});

  @override
  Widget build(BuildContext context) {
    final color = _platformColor(platform);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        _platformLabel(platform),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _ErrorListItem extends StatelessWidget {
  final ErrorEvent entry;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onCopy;

  const _ErrorListItem({
    required this.entry,
    required this.isSelected,
    required this.onTap,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final severityColor = _severityColor(entry.severity);
    final time = DateFormat('HH:mm:ss.SSS').format(
      DateTime.fromMillisecondsSinceEpoch(entry.timestamp),
    );

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05))
              : null,
          border: Border(
            left: BorderSide(
              color: severityColor,
              width: 3,
            ),
            bottom: BorderSide(
              color: isDark ? Colors.white10 : Colors.black12,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Severity & Platform
            Column(
              children: [
                _SeverityBadge(severity: entry.severity),
                const SizedBox(height: 4),
                _PlatformBadge(platform: entry.platform),
              ],
            ),
            const SizedBox(width: 12),
            // Message
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.message,
                    style: TextStyle(
                      fontSize: 13,
                      fontFamily: AppConstants.monoFontFamily,
                      color: isDark ? Colors.white.withValues(alpha: 0.87) : Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (entry.stackTrace != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      entry.stackTrace!.split('\n').first,
                      style: TextStyle(
                        fontSize: 11,
                        fontFamily: AppConstants.monoFontFamily,
                        color: Colors.grey[500],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            // Time & Actions
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 11,
                    fontFamily: AppConstants.monoFontFamily,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(LucideIcons.copy, size: 14),
                      onPressed: onCopy,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Copy',
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Error Detail Panel
// ---------------------------------------------------------------------------

class _ErrorDetailPanel extends ConsumerStatefulWidget {
  final ErrorEvent entry;
  final VoidCallback onClose;
  final VoidCallback onScreenshot;

  const _ErrorDetailPanel({
    super.key,
    required this.entry,
    required this.onClose,
    required this.onScreenshot,
  });

  @override
  ConsumerState<_ErrorDetailPanel> createState() => _ErrorDetailPanelState();
}

class _ErrorDetailPanelState extends ConsumerState<_ErrorDetailPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _messageScrollController = SmoothScrollController();
  final _stackTraceScrollController = SmoothScrollController();
  final _detailsScrollController = SmoothScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      animationDuration: ref.read(tabAnimationProvider),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _messageScrollController.dispose();
    _stackTraceScrollController.dispose();
    _detailsScrollController.dispose();
    super.dispose();
  }

  void _rebuildController() {
    final oldIndex = _tabController.index;
    _tabController.dispose();
    _tabController = TabController(
      length: 3,
      vsync: this,
      animationDuration: ref.read(tabAnimationProvider),
      initialIndex: oldIndex,
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final entry = widget.entry;
    final severityColor = _severityColor(entry.severity);

    ref.listen(tabAnimationProvider, (prev, next) {
      if (prev != next) _rebuildController();
    });

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? ColorTokens.darkBackground : Colors.white,
            border: Border(
              bottom: BorderSide(
                color: isDark ? Colors.white10 : Colors.black12,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(LucideIcons.alertTriangle, size: 16, color: severityColor),
              const SizedBox(width: 8),
              _SeverityBadge(severity: entry.severity),
              const SizedBox(width: 8),
              _PlatformBadge(platform: entry.platform),
              const SizedBox(width: 8),
              TextComponent(
                DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(
                  DateTime.fromMillisecondsSinceEpoch(entry.timestamp),
                ),
                style: TextStyle(
                  fontFamily: AppConstants.monoFontFamily,
                  fontSize: 11,
                  color: Colors.grey[500],
                ),
              ),
              const Spacer(),
              Tooltip(
                message: 'Capture full detail as image',
                waitDuration: const Duration(milliseconds: 400),
                child: GestureDetector(
                  onTap: _takeFullScreenshot,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        LucideIcons.camera,
                        size: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 2),
              Tooltip(
                message: 'Capture current tab only',
                waitDuration: const Duration(milliseconds: 400),
                child: GestureDetector(
                  onTap: _takeTabScreenshot,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        LucideIcons.scanLine,
                        size: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Tooltip(
                message: 'Close panel',
                child: GestureDetector(
                  onTap: widget.onClose,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        LucideIcons.x,
                        size: 16,
                        color: Colors.grey[500],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Tabs
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TabBar(
            controller: _tabController,
            labelStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            labelColor: ColorTokens.primary,
            unselectedLabelColor: isDark ? Colors.grey[500] : Colors.grey[600],
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isDark
                    ? ColorTokens.primary.withValues(alpha: 0.25)
                    : Colors.black.withValues(alpha: 0.06),
              ),
              boxShadow: isDark
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
            ),
            indicatorPadding: EdgeInsets.zero,
            dividerHeight: 0,
            splashFactory: NoSplash.splashFactory,
            overlayColor: WidgetStateProperty.all(Colors.transparent),
            padding: EdgeInsets.zero,
            labelPadding: EdgeInsets.zero,
            tabs: [
              Tab(height: 28, text: S.of(context).message),
              Tab(height: 28, text: 'Stack Trace'),
              Tab(height: 28, text: S.of(context).details),
            ],
          ),
        ),
        // Tab content
        Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Message tab
                LazyTab(
                  controller: _tabController,
                  index: 0,
                  builder: (_) => SingleChildScrollView(
                    controller: _messageScrollController,
                    padding: const EdgeInsets.all(16),
                    child: TextComponent(
                      entry.message,
                      style: TextStyle(
                        fontFamily: AppConstants.monoFontFamily,
                        fontSize: 13,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                ),
                // Stack trace tab
                LazyTab(
                  controller: _tabController,
                  index: 1,
                  builder: (_) => entry.stackTrace != null
                      ? SingleChildScrollView(
                          controller: _stackTraceScrollController,
                          padding: const EdgeInsets.all(16),
                          child: TextComponent(
                            entry.stackTrace!,
                            style: TextStyle(
                              fontFamily: AppConstants.monoFontFamily,
                              fontSize: 11,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                        )
                      : Center(
                          child: TextComponent(S.of(context).noStackTrace),
                        ),
                ),
                // Details tab
                LazyTab(
                  controller: _tabController,
                  index: 2,
                  builder: (_) => SingleChildScrollView(
                    controller: _detailsScrollController,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _DetailRow(label: S.of(context).platform, value: entry.platform.name),
                        _DetailRow(label: S.of(context).severity, value: entry.severity.name),
                        _DetailRow(label: S.of(context).source, value: entry.source ?? 'unknown'),
                        _DetailRow(label: S.of(context).deviceId, value: entry.deviceId),
                        _DetailRow(label: S.of(context).deviceInfo, value: entry.deviceInfo ?? 'unknown'),
                        if (entry.metadata != null) ...[
                          const SizedBox(height: 12),
                          TextComponent(
                            'Metadata',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[500],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.black26 : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: TextComponent(
                              entry.metadata.toString(),
                              style: TextStyle(
                                fontFamily: AppConstants.monoFontFamily,
                                fontSize: 11,
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
        ),
      ],
    );
  }

  // ---- Screenshot ----

  Future<void> _takeFullScreenshot() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    await captureWidgetAsImage(
      context,
      _buildFullScreenshotWidget(isDark),
    );
  }

  Future<void> _takeTabScreenshot() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    await captureWidgetAsImage(
      context,
      _buildTabScreenshotWidget(isDark, _tabController.index),
    );
  }

  Widget _buildFullScreenshotWidget(bool isDark) {
    final entry = widget.entry;
    final severityColor = _severityColor(entry.severity);
    final time = DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(
      DateTime.fromMillisecondsSinceEpoch(entry.timestamp),
    );

    return Container(
      color: isDark ? ColorTokens.darkSurface : Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            color: isDark ? ColorTokens.darkBackground : Colors.white,
            child: Row(
              children: [
                Icon(LucideIcons.alertTriangle, size: 16, color: severityColor),
                const SizedBox(width: 8),
                _SeverityBadge(severity: entry.severity),
                const SizedBox(width: 8),
                _PlatformBadge(platform: entry.platform),
                const SizedBox(width: 8),
                TextComponent(
                  time,
                  style: TextStyle(
                    fontFamily: AppConstants.monoFontFamily,
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Message section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextComponent(
                  'Message',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? ColorTokens.darkBackground : const Color(0xFFF0F0F0),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.black.withValues(alpha: 0.06),
                    ),
                  ),
                  child: TextComponent(
                    entry.message,
                    style: TextStyle(
                      fontFamily: AppConstants.monoFontFamily,
                      fontSize: 12,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Stack trace section
          if (entry.stackTrace != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextComponent(
                    'Stack Trace',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: severityColor.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: severityColor.withValues(alpha: 0.15),
                      ),
                    ),
                    child: TextComponent(
                      entry.stackTrace!,
                      style: TextStyle(
                        fontFamily: AppConstants.monoFontFamily,
                        fontSize: 11,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // Details section
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextComponent(
                  'Details',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? ColorTokens.darkBackground : const Color(0xFFF0F0F0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _screenshotDetailRow('Platform', entry.platform.name, isDark),
                      _screenshotDetailRow('Severity', entry.severity.name, isDark),
                      _screenshotDetailRow('Source', entry.source ?? 'unknown', isDark),
                      _screenshotDetailRow('Device ID', entry.deviceId, isDark),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      width: 600,
    );
  }

  Widget _buildTabScreenshotWidget(bool isDark, int tabIndex) {
    final entry = widget.entry;
    final severityColor = _severityColor(entry.severity);
    final time = DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(
      DateTime.fromMillisecondsSinceEpoch(entry.timestamp),
    );

    final tabLabels = ['Message', 'Stack Trace', 'Details'];
    final tabLabel = tabIndex >= 0 && tabIndex < tabLabels.length
        ? tabLabels[tabIndex]
        : 'Message';

    return Container(
      color: isDark ? ColorTokens.darkSurface : Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            color: isDark ? ColorTokens.darkBackground : Colors.white,
            child: Row(
              children: [
                Icon(LucideIcons.alertTriangle, size: 16, color: severityColor),
                const SizedBox(width: 8),
                _SeverityBadge(severity: entry.severity),
                const SizedBox(width: 8),
                _PlatformBadge(platform: entry.platform),
                const SizedBox(width: 8),
                TextComponent(time, style: TextStyle(fontFamily: AppConstants.monoFontFamily, fontSize: 11, color: Colors.grey[500])),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: ColorTokens.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: TextComponent(tabLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: ColorTokens.primary)),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Tab content
          Padding(
            padding: const EdgeInsets.all(16),
            child: tabIndex == 0
                ? TextComponent(entry.message, style: TextStyle(fontFamily: AppConstants.monoFontFamily, fontSize: 12, color: isDark ? Colors.white : Colors.black87))
                : tabIndex == 1
                    ? (entry.stackTrace != null
                        ? TextComponent(entry.stackTrace!, style: TextStyle(fontFamily: AppConstants.monoFontFamily, fontSize: 11, color: isDark ? Colors.white70 : Colors.black87))
                        : const TextComponent('No stack trace available'))
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _screenshotDetailRow('Platform', entry.platform.name, isDark),
                          _screenshotDetailRow('Severity', entry.severity.name, isDark),
                          _screenshotDetailRow('Source', entry.source ?? 'unknown', isDark),
                          _screenshotDetailRow('Device ID', entry.deviceId, isDark),
                        ],
                      ),
          ),
        ],
      ),
      width: 600,
    );
  }

  Widget _screenshotDetailRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: TextComponent(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey[500])),
          ),
          Expanded(
            child: TextComponent(value, style: TextStyle(fontFamily: AppConstants.monoFontFamily, fontSize: 10, color: isDark ? Colors.white70 : Colors.black87)),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: TextComponent(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.grey[500],
              ),
            ),
          ),
          Expanded(
            child: TextComponent(
              value,
              style: TextStyle(
                fontFamily: AppConstants.monoFontFamily,
                fontSize: 11,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}