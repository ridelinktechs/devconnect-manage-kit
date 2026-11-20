import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/chrome_palette.dart';
import '../../../../core/utils/scroll/smooth_scroll_controller.dart';
import '../../../../models/storage/storage_entry.dart';
import '../../provider/storage_providers.dart';
import '../shared/storage_tokens.dart';
import 'storage_filter_chip.dart';

/// Operations in the order the chips list them; any others follow.
const _opOrder = ['write', 'read', 'delete', 'clear'];

/// The history's filters: a chip per operation, then one per storage type,
/// each with its count. They scroll sideways when they don't all fit.
class StorageFilterRow extends ConsumerStatefulWidget {
  const StorageFilterRow({super.key});

  @override
  ConsumerState<StorageFilterRow> createState() => _StorageFilterRowState();
}

class _StorageFilterRowState extends ConsumerState<StorageFilterRow> {
  final _scroll = SmoothScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = ChromePalette.of(context);
    final facets = ref.watch(storageFacetsProvider);
    final hiddenOps = ref.watch(storageHiddenOpsProvider);
    final shownTypes = ref.watch(storageTypeFilterProvider);
    final ops = [
      for (final op in _opOrder)
        if (facets.ops.containsKey(op)) op,
      for (final op in facets.ops.keys.toList()..sort())
        if (!_opOrder.contains(op)) op,
    ];
    final types = [
      for (final t in StorageType.values)
        if (facets.types.containsKey(t)) t,
    ];
    return Align(
      alignment: Alignment.centerLeft,
      child: SingleChildScrollView(
        controller: _scroll,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Row(
          children: [
            for (final op in ops)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: StorageFilterChip(
                  label: op.toUpperCase(),
                  color: storageOpColor(op),
                  count: facets.ops[op]!,
                  isActive: !hiddenOps.contains(op),
                  onTap: () =>
                      ref.read(storageHiddenOpsProvider.notifier).toggle(op),
                ),
              ),
            if (ops.isNotEmpty && types.isNotEmpty)
              Container(
                width: 1,
                height: 16,
                margin: const EdgeInsets.only(left: 2, right: 8),
                color: p.border,
              ),
            for (final type in types)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: StorageFilterChip(
                  label: storageTypeName(type),
                  color: storageTypeColor(type),
                  count: facets.types[type]!,
                  isActive: shownTypes.contains(type),
                  onTap: () =>
                      ref.read(storageTypeFilterProvider.notifier).toggle(type),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
