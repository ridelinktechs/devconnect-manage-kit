import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../components/feedback/empty_state.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../core/utils/toast_utils.dart';
import '../../../models/round/mock_entry.dart';
import '../provider/round_providers.dart';

/// Round 4 — read-only audit log of which requests the SDK actually
/// matched against mock rules on the device. Wired into the Network
/// Inspector as the 4th tab so QA can correlate network traffic with
/// the rules currently installed on the device.
class MockAuditPanel extends ConsumerStatefulWidget {
  const MockAuditPanel({super.key});

  @override
  ConsumerState<MockAuditPanel> createState() => _MockAuditPanelState();
}

class _MockAuditPanelState extends ConsumerState<MockAuditPanel> {
  String _filter = 'all'; // all | matched | fallback

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entries = ref.watch(mockAuditDisplayProvider).items;
    final filtered = entries.where((e) {
      if (_filter == 'matched') return e.matchedRuleId.isNotEmpty;
      if (_filter == 'fallback') return e.matchedRuleId.isEmpty;
      return true;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FilterBar(
          current: _filter,
          onChanged: (v) => setState(() => _filter = v),
        ),
        Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.5)),
        Expanded(
          child: filtered.isEmpty
              ? EmptyState(
                  icon: LucideIcons.scrollText,
                  title: 'No audit entries',
                  subtitle:
                      'When the SDK matches (or falls through) a request, it sends an audit event here.',
                )
              : ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) =>
                      const Divider(height: 1),
                  itemBuilder: (context, i) =>
                      _AuditRow(entry: filtered[i]),
                ),
        ),
      ],
    );
  }
}

class _FilterBar extends StatelessWidget {
  final String current;
  final ValueChanged<String> onChanged;

  const _FilterBar({required this.current, required this.onChanged});

  static const _options = [
    ('all', 'All'),
    ('matched', 'Matched'),
    ('fallback', 'Fallback'),
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
          for (final (key, label) in _options) ...[
            _Pill(
              label: label,
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

class _Pill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Pill({
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

class _AuditRow extends ConsumerWidget {
  final MockedRequestEntry entry;
  const _AuditRow({required this.entry});

  static final _time = DateFormat('HH:mm:ss.SSS');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final matched = entry.matchedRuleId.isNotEmpty;
    final tcolor =
        matched ? const Color(0xFF10B981) : const Color(0xFFFDAA5E);

    final rule = matched
        ? ref.watch(mockRulesProvider.select((rs) =>
            rs.where((r) => r.id == entry.matchedRuleId).firstOrNull))
        : null;

    return InkWell(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: tcolor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                entry.method,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: tcolor,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.url,
                      style: theme.textTheme.bodyMedium,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        matched
                            ? LucideIcons.checkCircle
                            : LucideIcons.shieldOff,
                        size: 11,
                        color: tcolor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        matched
                            ? 'matched: ${rule?.name ?? entry.matchedRuleId}'
                            : 'no rule → real network',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: matched
                              ? tcolor
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(entry.statusCode.toString(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: _statusColor(entry.statusCode),
                    )),
                Text(_time.format(
                    DateTime.fromMillisecondsSinceEpoch(entry.timestamp)),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    )),
              ],
            ),
            const SizedBox(width: 4),
            IconButton(
              tooltip: 'Copy URL',
              icon: const Icon(LucideIcons.copy, size: 14),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: entry.url));
                showCopiedToast(context, label: 'URL copied');
              },
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(int status) {
    if (status >= 200 && status < 300) return const Color(0xFF10B981);
    if (status >= 300 && status < 400) return const Color(0xFF74B9FF);
    if (status >= 400 && status < 500) return const Color(0xFFFDAA5E);
    return const Color(0xFFEF4444);
  }
}