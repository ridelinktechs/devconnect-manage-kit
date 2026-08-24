import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../components/feedback/empty_state.dart';
import '../../../components/viewers/json_viewer.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../models/round/state_round_entry.dart';
import '../provider/round_providers.dart';

/// Round 2 panel — shows BLoC / Provider / React Query / Apollo events
/// with a manager-type filter chip row at the top. Reuses the same
/// row-list + diff/Before/After detail layout as the legacy Redux State
/// Inspector, but operates on [StateRoundEntry] entries.
class StateRoundPanel extends ConsumerStatefulWidget {
  const StateRoundPanel({super.key});

  @override
  ConsumerState<StateRoundPanel> createState() => _StateRoundPanelState();
}

class _StateRoundPanelState extends ConsumerState<StateRoundPanel> {
  String? _selectedId;
  int _detailTab = 0; // 0 = diff, 1 = before, 2 = after
  int _jsonSubTab = 0; // 0 = tree, 1 = pretty

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entries = ref.watch(filteredStateRoundProvider);
    final selected = _selectedId == null
        ? null
        : entries.where((e) => e.id == _selectedId).firstOrNull;
    final filter = ref.watch(stateRoundManagerFilterProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ManagerFilterRow(current: filter, onChanged: (v) {
          ref.read(stateRoundManagerFilterProvider.notifier).state = v;
        }),
        Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.5)),
        Expanded(
          child: entries.isEmpty
              ? EmptyState(
                  icon: LucideIcons.layers,
                  title: 'No state-manager events',
                  subtitle: 'BLoC, Provider, React Query, Apollo events will appear here.',
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: 380,
                      child: _RoundList(
                        entries: entries,
                        selectedId: _selectedId,
                        onSelect: (id) => setState(() => _selectedId = id),
                      ),
                    ),
                    VerticalDivider(
                        width: 1, color: theme.dividerColor.withValues(alpha: 0.5)),
                    Expanded(
                      child: selected == null
                          ? EmptyState(
                              icon: LucideIcons.mousePointerClick,
                              title: 'Select an event',
                              subtitle: 'Pick a row on the left to inspect its diff.',
                            )
                          : _StateRoundDetail(
                              entry: selected,
                              tab: _detailTab,
                              onTab: (i) => setState(() => _detailTab = i),
                              jsonTab: _jsonSubTab,
                              onJsonTab: (i) => setState(() => _jsonSubTab = i),
                            ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _ManagerFilterRow extends StatelessWidget {
  final String current;
  final ValueChanged<String> onChanged;

  const _ManagerFilterRow({required this.current, required this.onChanged});

  static const _options = [
    ('all', 'All', LucideIcons.layers),
    ('bloc', 'BLoC', LucideIcons.boxes),
    ('provider', 'Provider', LucideIcons.network),
    ('react_query', 'React Query', LucideIcons.database),
    ('apollo', 'Apollo', LucideIcons.atom),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      color: theme.colorScheme.surface,
      child: Row(
        children: [
          for (final (key, label, icon) in _options) ...[
            _Chip(
              label: label,
              icon: icon,
              selected: current == key,
              onTap: () => onChanged(key),
            ),
            const SizedBox(width: 4),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: selected
          ? ColorTokens.primary.withValues(alpha: 0.18)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 14,
                  color: selected
                      ? ColorTokens.primary
                      : theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: selected
                      ? ColorTokens.primary
                      : theme.colorScheme.onSurfaceVariant,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoundList extends StatelessWidget {
  final List<StateRoundEntry> entries;
  final String? selectedId;
  final ValueChanged<String> onSelect;

  const _RoundList({
    required this.entries,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: entries.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final entry = entries[i];
        final isSelected = entry.id == selectedId;
        return _RoundRow(
          entry: entry,
          selected: isSelected,
          onTap: () => onSelect(entry.id),
        );
      },
    );
  }
}

class _RoundRow extends StatelessWidget {
  final StateRoundEntry entry;
  final bool selected;
  final VoidCallback onTap;

  const _RoundRow({
    required this.entry,
    required this.selected,
    required this.onTap,
  });

  static final _timeFmt = DateFormat('HH:mm:ss.SSS');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ts = _timeFmt.format(
        DateTime.fromMillisecondsSinceEpoch(entry.timestamp));
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 44,
        color: selected
            ? theme.colorScheme.primary.withValues(alpha: 0.10)
            : null,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Container(
              width: 3,
              height: 24,
              color: selected
                  ? ColorTokens.primary
                  : Colors.transparent,
            ),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _managerColor(entry.manager).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _managerShort(entry.manager),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: _managerColor(entry.manager),
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                entry.action,
                style: theme.textTheme.bodyMedium,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            Text(
              ts,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _managerShort(String m) {
    switch (m) {
      case 'bloc':
        return 'BLoC';
      case 'provider':
        return 'PRV';
      case 'react_query':
        return 'RQ';
      case 'apollo':
        return 'APO';
      default:
        return m.toUpperCase();
    }
  }

  static Color _managerColor(String m) {
    switch (m) {
      case 'bloc':
        return const Color(0xFF00CEC9);
      case 'provider':
        return const Color(0xFFFDAA5E);
      case 'react_query':
        return const Color(0xFF74B9FF);
      case 'apollo':
        return const Color(0xFFFD79A8);
      default:
        return ColorTokens.primary;
    }
  }
}

class _StateRoundDetail extends StatelessWidget {
  final StateRoundEntry entry;
  final int tab;
  final ValueChanged<int> onTab;
  final int jsonTab;
  final ValueChanged<int> onJsonTab;

  const _StateRoundDetail({
    required this.entry,
    required this.tab,
    required this.onTab,
    required this.jsonTab,
    required this.onJsonTab,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tabs = const ['Diff', 'Before', 'After'];
    final subTabs = const ['Tree', 'Pretty'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DetailHeader(entry: entry),
        _TabBar3(
          tabs: tabs,
          current: tab,
          onSelect: onTab,
        ),
        Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.5)),
        Expanded(
          child: tab == 0
              ? _DiffBody(before: entry.previousState, after: entry.nextState)
              : Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _TabBar2(
                        tabs: subTabs,
                        current: jsonTab,
                        onSelect: onJsonTab,
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: _JsonBody(
                          data: tab == 1 ? entry.previousState : entry.nextState,
                          useTree: jsonTab == 0,
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

class _DetailHeader extends StatelessWidget {
  final StateRoundEntry entry;
  const _DetailHeader({required this.entry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
              color: theme.dividerColor.withValues(alpha: 0.5)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(entry.action.isEmpty ? '(unnamed action)' : entry.action,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text('${entry.manager} · ${entry.deviceId}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              )),
        ],
      ),
    );
  }
}

class _TabBar3 extends StatelessWidget {
  final List<String> tabs;
  final int current;
  final ValueChanged<int> onSelect;
  const _TabBar3({
    required this.tabs,
    required this.current,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          for (var i = 0; i < tabs.length; i++) ...[
            _PillTab(
              label: tabs[i],
              selected: i == current,
              onTap: () => onSelect(i),
            ),
            const SizedBox(width: 4),
          ],
        ],
      ),
    );
  }
}

class _TabBar2 extends StatelessWidget {
  final List<String> tabs;
  final int current;
  final ValueChanged<int> onSelect;
  const _TabBar2({
    required this.tabs,
    required this.current,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        for (var i = 0; i < tabs.length; i++) ...[
          _PillTab(
            label: tabs[i],
            selected: i == current,
            onTap: () => onSelect(i),
          ),
          const SizedBox(width: 4),
        ],
      ],
    );
  }
}

class _PillTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _PillTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: selected
          ? ColorTokens.primary.withValues(alpha: 0.18)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: selected
                  ? ColorTokens.primary
                  : theme.colorScheme.onSurfaceVariant,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _DiffBody extends StatelessWidget {
  final Map<String, dynamic> before;
  final Map<String, dynamic> after;
  const _DiffBody({required this.before, required this.after});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final added = _diffKeys(before, after);
    final removed = _diffKeys(after, before);
    if (added.isEmpty && removed.isEmpty) {
      return Center(
        child: Text(
          'No changes',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        for (final k in added)
          _DiffRow(label: k, value: after[k], type: _DiffType.added),
        for (final k in removed)
          _DiffRow(label: k, value: before[k], type: _DiffType.removed),
      ],
    );
  }

  List<String> _diffKeys(Map<String, dynamic> a, Map<String, dynamic> b) {
    return a.keys.where((k) {
      if (!b.containsKey(k)) return true;
      return _deepEqual(a[k], b[k]) == false;
    }).toList();
  }

  bool _deepEqual(dynamic a, dynamic b) {
    if (a == b) return true;
    if (a is Map && b is Map) {
      if (a.length != b.length) return false;
      for (final k in a.keys) {
        if (!b.containsKey(k) || !_deepEqual(a[k], b[k])) return false;
      }
      return true;
    }
    if (a is List && b is List) {
      if (a.length != b.length) return false;
      for (var i = 0; i < a.length; i++) {
        if (!_deepEqual(a[i], b[i])) return false;
      }
      return true;
    }
    return false;
  }
}

enum _DiffType { added, removed }

class _DiffRow extends StatelessWidget {
  final String label;
  final dynamic value;
  final _DiffType type;

  const _DiffRow({
    required this.label,
    required this.value,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAdd = type == _DiffType.added;
    final color =
        isAdd ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(isAdd ? LucideIcons.plus : LucideIcons.minus,
                  size: 12, color: color),
              const SizedBox(width: 6),
              Text(label,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value.toString(),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _JsonBody extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool useTree;
  const _JsonBody({required this.data, required this.useTree});

  @override
  Widget build(BuildContext context) {
    return useTree ? JsonViewer(data: data) : JsonPrettyViewer(data: data);
  }
}
