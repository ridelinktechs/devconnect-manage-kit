import 'package:flutter/material.dart';

import '../../core/utils/position_retained_scroll_physics.dart';

/// A high-performance ListView that prevents visible items from rebuilding
/// when new items are appended or selection changes.
///
/// Key optimizations:
/// - Custom [SliverChildDelegate] with [shouldRebuild] = false when item count
///   is unchanged — parent rebuilds (e.g. selection, layout) do NOT cause
///   existing list items to re-run their builder.
/// - [ValueNotifier]-based selection — only the decoration layer of the
///   selected/deselected items updates; text content is preserved via the
///   [ValueListenableBuilder.child] parameter.
/// - [RepaintBoundary] on each item — isolates repaints so one item changing
///   does not repaint neighbors.
///
/// Usage:
/// ```dart
/// StableListView<LogEntry>(
///   entries: _entries,            // local mutable list (grows via addAll)
///   itemExtent: 64,
///   reverse: isReversed,
///   generation: _generation,      // increment on full replace only
///   controller: _scrollController,
///   selectedId: _selectedId,      // ValueNotifier<String?>
///   idOf: (e) => e.id,
///   contentBuilder: (ctx, entry) => Text(entry.message),
///   decorationBuilder: (isSelected, isDark) => BoxDecoration(...),
/// )
/// ```
class StableListView<T> extends StatelessWidget {
  /// The list of entries. Must be the SAME list object that grows via addAll —
  /// never replaced wholesale (use [ref.listenManual] for this pattern).
  final List<T> entries;

  /// Fixed height per item — enables O(1) layout.
  final double itemExtent;

  /// If true, newest items (high indices) appear at the top.
  final bool reverse;

  /// Monotonically increasing counter. Increment when the list is fully
  /// replaced (e.g. filter change / clear+addAll). Do NOT increment on
  /// append-only updates. Controls [shouldRebuild] — existing visible items
  /// are only rebuilt when the generation changes.
  final int generation;

  /// External scroll controller.
  final ScrollController? controller;

  /// Padding around the scroll view.
  final EdgeInsetsGeometry? padding;

  /// Extract a unique, stable ID from each entry.
  final String Function(T entry) idOf;

  /// Currently selected entry ID. Drives highlight without rebuilding items.
  final ValueNotifier<String?> selectedId;

  /// Called when an item is tapped. Typically sets [selectedId.value].
  final void Function(T entry)? onSelect;

  /// Builds the inner content of each item. This widget is created ONCE per
  /// item and reused across selection changes (passed as [ValueListenableBuilder.child]).
  final Widget Function(BuildContext context, T entry) contentBuilder;

  /// Returns a [BoxDecoration] for selected / unselected state.
  /// Called whenever selection changes for a specific item.
  final BoxDecoration Function(bool isSelected, bool isDark)? decorationBuilder;

  /// Custom scroll physics. When null, defaults to
  /// [PositionRetainedScrollPhysics] for reversed lists (prevents drift when
  /// new items are added above the viewport) and platform default otherwise.
  final ScrollPhysics? physics;

  /// Item padding.
  final EdgeInsetsGeometry itemPadding;

  /// How many items the ListView should expose. When null, uses
  /// [entries.length]. Set this to implement load-more: keep [entries] full
  /// but only reveal [childCount] items to the viewport.
  final int? childCount;

  const StableListView({
    super.key,
    required this.entries,
    required this.itemExtent,
    this.reverse = false,
    this.generation = 0,
    this.childCount,
    this.controller,
    this.padding,
    this.physics,
    required this.idOf,
    required this.selectedId,
    this.onSelect,
    required this.contentBuilder,
    this.decorationBuilder,
    this.itemPadding = const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
  });

  @override
  Widget build(BuildContext context) {
    return ListView.custom(
      controller: controller,
      reverse: reverse,
      padding: padding,
      itemExtent: itemExtent,
      physics: physics ??
          (reverse ? const PositionRetainedScrollPhysics() : null),
      childrenDelegate: _StableChildDelegate<T>(
        entries: entries,
        generation: generation,
        childCount: childCount,
        idOf: idOf,
        selectedId: selectedId,
        onSelect: onSelect,
        contentBuilder: contentBuilder,
        decorationBuilder: decorationBuilder,
        itemPadding: itemPadding,
      ),
    );
  }
}

/// Custom delegate that prevents rebuilding existing children when only the
/// list length stays the same (e.g. parent layout change, selection change).
class _StableChildDelegate<T> extends SliverChildDelegate {
  final List<T> entries;
  final int generation;
  final int? childCount;
  final String Function(T) idOf;
  final ValueNotifier<String?> selectedId;
  final void Function(T)? onSelect;
  final Widget Function(BuildContext, T) contentBuilder;
  final BoxDecoration Function(bool, bool)? decorationBuilder;
  final EdgeInsetsGeometry itemPadding;

  const _StableChildDelegate({
    required this.entries,
    required this.generation,
    this.childCount,
    required this.idOf,
    required this.selectedId,
    this.onSelect,
    required this.contentBuilder,
    this.decorationBuilder,
    required this.itemPadding,
  });

  @override
  Widget? build(BuildContext context, int index) {
    final count = childCount ?? entries.length;
    if (index < 0 || index >= count) return null;
    final entry = entries[index];
    final id = idOf(entry);

    // Content is built ONCE and passed as `child` — never rebuilt on
    // selection change.
    final content = contentBuilder(context, entry);

    return RepaintBoundary(
      key: ValueKey(id),
      child: GestureDetector(
        onTap: onSelect != null ? () => onSelect!(entry) : null,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Padding(
            padding: itemPadding,
            child: ValueListenableBuilder<String?>(
              valueListenable: selectedId,
              builder: (context, selectedValue, child) {
                final isSelected = id == selectedValue;
                if (decorationBuilder != null) {
                  final isDark =
                      Theme.of(context).brightness == Brightness.dark;
                  return Container(
                    decoration: decorationBuilder!(isSelected, isDark),
                    child: child,
                  );
                }
                return child!;
              },
              child: content, // ← preserved across selection changes
            ),
          ),
        ),
      ),
    );
  }

  @override
  int get estimatedChildCount => childCount ?? entries.length;

  @override
  bool shouldRebuild(covariant _StableChildDelegate<T> oldDelegate) {
    // Only rebuild existing children when the data is fully replaced
    // (generation change). Append-only updates (same generation, different
    // length) do NOT rebuild existing items — new items are discovered via
    // estimatedChildCount. Selection is handled by ValueListenableBuilder.
    return generation != oldDelegate.generation;
  }

  @override
  int? findIndexByKey(Key key) {
    if (key is ValueKey<String>) {
      final idx = entries.indexWhere((e) => idOf(e) == key.value);
      return idx == -1 ? null : idx;
    }
    return null;
  }
}

/// A drop-in replacement for [SliverChildBuilderDelegate] that only rebuilds
/// existing children when [generation] changes. Use this for any ListView that
/// should NOT rebuild visible items on parent setState / provider changes.
class StableBuilderDelegate extends SliverChildDelegate {
  final Widget Function(BuildContext, int) builder;
  final int childCount;
  final int generation;
  final int? Function(Key)? findChildIndexCallback;

  const StableBuilderDelegate({
    required this.builder,
    required this.childCount,
    this.generation = 0,
    this.findChildIndexCallback,
  });

  @override
  Widget? build(BuildContext context, int index) {
    if (index < 0 || index >= childCount) return null;
    return builder(context, index);
  }

  @override
  int get estimatedChildCount => childCount;

  @override
  bool shouldRebuild(covariant StableBuilderDelegate oldDelegate) {
    return generation != oldDelegate.generation;
  }

  @override
  int? findIndexByKey(Key key) => findChildIndexCallback?.call(key);
}
