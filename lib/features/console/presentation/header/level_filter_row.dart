import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/scroll/smooth_scroll_controller.dart';
import '../../../../models/log/log_entry.dart';
import '../../provider/console_providers.dart';
import 'level_filter_chip.dart';

/// The Console toolbar's level chips, one per level with its count. They
/// scroll sideways on the shared smooth controller when the window is too
/// narrow to show them all.
class LevelFilterRow extends ConsumerStatefulWidget {
  const LevelFilterRow({super.key});

  @override
  ConsumerState<LevelFilterRow> createState() => _LevelFilterRowState();
}

class _LevelFilterRowState extends ConsumerState<LevelFilterRow> {
  final _scroll = SmoothScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final active = ref.watch(consoleFilterProvider);
    final counts = ref.watch(consoleLevelCountsProvider);
    return Align(
      alignment: Alignment.centerLeft,
      child: SingleChildScrollView(
        controller: _scroll,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Row(
          children: [
            for (final level in LogLevel.values)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: LevelFilterChip(
                  level: level,
                  count: counts[level] ?? 0,
                  isActive: active.contains(level),
                  onTap: () =>
                      ref.read(consoleFilterProvider.notifier).toggle(level),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
