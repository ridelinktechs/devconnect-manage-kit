import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/scroll/smooth_scroll_controller.dart';
import '../../provider/state_providers.dart';
import '../shared/manager_look.dart';
import 'manager_filter_chip.dart';

/// One chip per state library in the timeline, with its count. They scroll
/// sideways on the shared smooth controller when they don't all fit.
class ManagerFilterRow extends ConsumerStatefulWidget {
  const ManagerFilterRow({super.key});

  @override
  ConsumerState<ManagerFilterRow> createState() => _ManagerFilterRowState();
}

class _ManagerFilterRowState extends ConsumerState<ManagerFilterRow> {
  final _scroll = SmoothScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final managers = ref.watch(stateManagerCountsProvider);
    final hidden = ref.watch(stateHiddenManagersProvider);
    return Align(
      alignment: Alignment.centerLeft,
      child: SingleChildScrollView(
        controller: _scroll,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Row(
          children: [
            for (final m in managers)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ManagerFilterChip(
                  look: ManagerLook.of(m.type),
                  count: m.count,
                  isActive: !hidden.contains(m.key),
                  onTap: () => ref
                      .read(stateHiddenManagersProvider.notifier)
                      .toggle(m.key),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
