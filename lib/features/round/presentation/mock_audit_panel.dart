import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../components/feedback/empty_state.dart';
import '../../../core/utils/ui/toast_utils.dart';
import '../../../models/round/mock_entry.dart';
import '../provider/round_providers.dart';

/// Round 4 — read-only audit log of which requests the SDK actually
/// matched against mock rules on the device. Wired into the Network
/// Inspector as a tab so QA can correlate network traffic with
/// the rules currently installed on the device.
class MockAuditPanel extends ConsumerStatefulWidget {
  const MockAuditPanel({super.key});

  @override
  ConsumerState<MockAuditPanel> createState() => _MockAuditPanelState();
}

class _MockAuditPanelState extends ConsumerState<MockAuditPanel> {
  @override
  Widget build(BuildContext context) {
    // Every audit event is a request a rule answered: the SDKs send
    // nothing for requests that went to the network.
    final entries = ref.watch(mockAuditDisplayProvider).items;
    return entries.isEmpty
        ? EmptyState(
            icon: LucideIcons.scrollText,
            title: 'No audit entries',
            subtitle:
                'Requests the app answered with a Mock Server rule instead of the network appear here.',
          )
        : ListView.separated(
            itemCount: entries.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) => _AuditRow(entry: entries[i]),
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