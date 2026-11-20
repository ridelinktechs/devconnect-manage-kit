// Lucian UX/UI Prompt #072 · MIT License (c) 2026 Seokwoooo · https://lucianlabs.dev/uxui-prompt/#072
// Lucian UX/UI Prompt #227 · MIT License (c) 2026 Seokwoooo · https://lucianlabs.dev/uxui-prompt/#227
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../components/labels/tag_label.dart';
import '../../../../core/theme/chrome_palette.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../models/round/mock_entry.dart';
import '../../../settings/presentation/controls/stretch_switch.dart';
import '../../../settings/presentation/shared/focus_ring.dart';
import '../shared/mock_look.dart';

final _time = DateFormat('HH:mm:ss');

/// One rule in the Mock Server list, as a card like the Console's logs
/// (Lucian #072): a 3px bar in the answer's status color, the method and
/// name with the rule's switch, the URL pattern, then labels for the answer
/// and the requests the device answered with it. A new hit makes the card
/// glow for a moment, like the new orders of Lucian #227.
class RuleCard extends StatefulWidget {
  final MockRule rule;
  final bool selected;

  /// Requests the device answered with this rule, and when the last was.
  final int hits;
  final int? lastHitAt;
  final VoidCallback onTap;
  final ValueChanged<bool> onToggle;

  const RuleCard({
    super.key,
    required this.rule,
    required this.selected,
    required this.hits,
    this.lastHitAt,
    required this.onTap,
    required this.onToggle,
  });

  @override
  State<RuleCard> createState() => _RuleCardState();
}

class _RuleCardState extends State<RuleCard> {
  bool _hover = false;
  int _glow = 0;

  @override
  void didUpdateWidget(RuleCard old) {
    super.didUpdateWidget(old);
    if (widget.hits > old.hits) _glow++;
  }

  @override
  Widget build(BuildContext context) {
    final p = ChromePalette.of(context);
    final rule = widget.rule;
    final on = rule.enabled;
    final accent = p.isDark ? ColorTokens.primaryLight : ColorTokens.primary;
    final tint = on ? statusTint(rule.statusCode) : p.border;
    final md = rule.metadata ?? const <String, dynamic>{};
    final delay = (md['delayMs'] as num?)?.toInt() ?? 0;
    final scope = md['scope'];
    final ids = scope is Map && scope['deviceIds'] is List
        ? (scope['deviceIds'] as List).length
        : 0;
    final expires = md['expiresAt'] is String
        ? DateTime.tryParse(md['expiresAt'] as String)
        : null;
    final name = rule.name.trim().isEmpty ? '(unnamed rule)' : rule.name;
    final base = DefaultTextStyle.of(context).style;
    final dim = on ? 1.0 : 0.5;

    final body = Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 24,
            child: Row(
              children: [
                Expanded(
                  child: Opacity(
                    opacity: dim,
                    child: Row(
                      children: [
                        TagLabel(
                          text: rule.method.toUpperCase(),
                          color: methodInk(rule.method, isDark: p.isDark),
                          fill: ColorTokens.httpMethodColor(
                            rule.method,
                          ).withValues(alpha: p.isDark ? 0.16 : 0.12),
                          mono: true,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: base.copyWith(
                              fontSize: 13.5,
                              height: 1.3,
                              fontWeight: FontWeight.w700,
                              color: p.text,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                StretchSwitch(
                  value: on,
                  onChanged: widget.onToggle,
                  label: '${on ? 'Pause' : 'Turn on'} $name',
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Opacity(
            opacity: dim,
            child: Text(
              rule.urlPattern.isEmpty ? '—' : rule.urlPattern,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: chromeMono(context, size: 12, color: p.textMuted),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 20,
            child: Row(
              children: [
                Expanded(
                  child: Opacity(
                    opacity: dim,
                    child: Row(
                      children: [
                        Flexible(
                          child: TagLabel(
                            text:
                                '${rule.statusCode} ${statusReason(rule.statusCode)}'
                                    .trim(),
                            color: statusInk(rule.statusCode, isDark: p.isDark),
                            fill: statusTint(
                              rule.statusCode,
                            ).withValues(alpha: p.isDark ? 0.16 : 0.12),
                          ),
                        ),
                        for (final (maxWidth, tip, label) in [
                          if (delay > 0)
                            (
                              64.0,
                              'Answers after ${formatDelay(delay)}',
                              TagLabel(
                                icon: LucideIcons.timer,
                                text: formatDelay(delay),
                                color: p.textMuted,
                                fill: p.selected,
                                edge: p.border.withValues(alpha: 0.6),
                              ),
                            ),
                          if (ids > 0)
                            (
                              44.0,
                              'Only on $ids device${ids == 1 ? '' : 's'}',
                              TagLabel(
                                icon: LucideIcons.smartphone,
                                text: '$ids',
                                color: p.textMuted,
                                fill: p.selected,
                                edge: p.border.withValues(alpha: 0.6),
                              ),
                            ),
                          if (expires != null)
                            expires.isBefore(DateTime.now())
                                ? (
                                    72.0,
                                    'Expired at ${md['expiresAt']}: it no '
                                        'longer answers',
                                    TagLabel(
                                      icon: LucideIcons.clock3,
                                      text: 'expired',
                                      color: mockDanger(p.isDark),
                                      fill: p.selected,
                                      edge: p.border.withValues(alpha: 0.6),
                                    ),
                                  )
                                : (
                                    28.0,
                                    'Answers until ${md['expiresAt']}',
                                    TagLabel(
                                      icon: LucideIcons.clock3,
                                      text: '',
                                      color: p.textMuted,
                                      fill: p.selected,
                                      edge: p.border.withValues(alpha: 0.6),
                                    ),
                                  ),
                        ]) ...[
                          const SizedBox(width: 6),
                          ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: maxWidth),
                            child: Tooltip(message: tip, child: label),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _Hits(hits: widget.hits, lastHitAt: widget.lastHitAt),
              ],
            ),
          ),
        ],
      ),
    );

    var fill = p.surface;
    if (_hover) fill = Color.alphaBlend(p.hover, fill);
    if (widget.selected) {
      fill = Color.alphaBlend(
        accent.withValues(alpha: p.isDark ? 0.12 : 0.08),
        fill,
      );
    }
    final edge = widget.selected
        ? accent.withValues(alpha: 0.75)
        : _hover
        ? p.textMuted.withValues(alpha: 0.5)
        : p.border;

    return FocusRing(
      onTap: widget.onTap,
      radius: 12,
      selected: widget.selected,
      label: name,
      onHover: (v) => setState(() => _hover = v),
      child: TweenAnimationBuilder<double>(
        key: ValueKey(_glow),
        tween: Tween(begin: _glow == 0 ? 0 : 1, end: 0),
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 1400),
        curve: Curves.ease,
        builder: (context, glow, child) => AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Color.alphaBlend(
              accent.withValues(alpha: 0.22 * glow),
              fill,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: edge),
          ),
          child: child,
        ),
        child: Stack(
          children: [
            body,
            Positioned(
              left: 0,
              top: 12,
              bottom: 12,
              width: 3,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                decoration: BoxDecoration(
                  color: tint,
                  borderRadius: const BorderRadius.horizontal(
                    right: Radius.circular(3),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// How many requests the device answered with the rule: a green dot once
/// it has, with the time of the last one in the tooltip.
class _Hits extends StatelessWidget {
  final int hits;
  final int? lastHitAt;

  const _Hits({required this.hits, this.lastHitAt});

  @override
  Widget build(BuildContext context) {
    final p = ChromePalette.of(context);
    final at = lastHitAt;
    final text = hits == 0 ? 'no hits' : '$hits hit${hits == 1 ? '' : 's'}';
    return Tooltip(
      message: at == null
          ? 'The device hasn\'t answered a request with this rule yet'
          : 'Last answered at ${_time.format(DateTime.fromMillisecondsSinceEpoch(at))}',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hits > 0) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: p.success,
              ),
            ),
            const SizedBox(width: 5),
          ],
          Text(
            text,
            style: chromeMono(
              context,
              size: 11,
              color: hits == 0 ? p.textMuted : p.text,
              weight: hits == 0 ? FontWeight.w500 : FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
