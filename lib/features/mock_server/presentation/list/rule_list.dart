import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/chrome_palette.dart';
import '../../../../core/utils/scroll/smooth_scroll_controller.dart';
import '../../../round/provider/round_providers.dart';
import 'rule_card.dart';

/// The rules as cards, with how many requests each one answered on the
/// device (from the Mock Audit log).
class RuleList extends ConsumerStatefulWidget {
  final String? selectedId;
  final ValueChanged<String> onSelect;

  const RuleList({super.key, required this.selectedId, required this.onSelect});

  @override
  ConsumerState<RuleList> createState() => _RuleListState();
}

class _RuleListState extends ConsumerState<RuleList> {
  final _scroll = SmoothScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = ChromePalette.of(context);
    final rules = ref.watch(mockRulesProvider);
    final hits = <String, (int, int)>{};
    for (final e in ref.watch(mockAuditEntriesProvider)) {
      if (e.matchedRuleId.isEmpty) continue;
      final (n, last) = hits[e.matchedRuleId] ?? (0, 0);
      hits[e.matchedRuleId] = (n + 1, math.max(last, e.timestamp));
    }
    final on = rules.where((r) => r.enabled).length;
    final eyebrow = DefaultTextStyle.of(context).style.copyWith(
      fontSize: 11,
      height: 1.2,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.6,
      color: p.textMuted,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Row(
            children: [
              Text('RULES', style: eyebrow),
              const SizedBox(width: 6),
              Text(
                '${rules.length}',
                style: chromeMono(
                  context,
                  size: 11,
                  color: p.textMuted,
                  weight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                '$on on · ${rules.length - on} paused',
                style: eyebrow.copyWith(
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
            itemCount: rules.length,
            separatorBuilder: (_, _) => const SizedBox(height: 6),
            itemBuilder: (context, i) {
              final rule = rules[i];
              final (count, last) = hits[rule.id] ?? (0, 0);
              return RuleCard(
                key: ValueKey(rule.id),
                rule: rule,
                selected: rule.id == widget.selectedId,
                hits: count,
                lastHitAt: count == 0 ? null : last,
                onTap: () => widget.onSelect(rule.id),
                onToggle: (v) =>
                    ref.read(mockRulesProvider.notifier).toggle(rule.id, v),
              );
            },
          ),
        ),
      ],
    );
  }
}
