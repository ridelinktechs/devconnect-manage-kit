// Lucian UX/UI Prompt #072 · MIT License (c) 2026 Seokwoooo · https://lucianlabs.dev/uxui-prompt/#072
// Lucian UX/UI Prompt #227 · MIT License (c) 2026 Seokwoooo · https://lucianlabs.dev/uxui-prompt/#227
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../components/labels/source_label.dart';
import '../../../../components/labels/tag_label.dart';
import '../../../../core/theme/chrome_palette.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../models/state/state_change.dart';
import '../../../../server/providers/server_providers.dart';
import '../../provider/state_providers.dart';
import '../shared/diff_summary.dart';
import '../shared/manager_look.dart';

final _time = DateFormat('HH:mm:ss.SSS');

/// One state change in the timeline, as its own card like the Console's
/// logs (Lucian #072): a 3px bar in the state library's color, a row of
/// labels — the library and its store, the platform with the app and
/// device — with the time on the right, then the action with what it added,
/// changed and removed, and the paths it touched. A change that just
/// arrived glows for a moment, like the new orders of Lucian #227.
class StateChangeTile extends ConsumerStatefulWidget {
  final StateChange entry;
  final VoidCallback onTap;

  /// Whether the change just arrived, so it glows.
  final bool fresh;

  const StateChangeTile({
    super.key,
    required this.entry,
    required this.onTap,
    this.fresh = false,
  });

  @override
  ConsumerState<StateChangeTile> createState() => _StateChangeTileState();
}

class _StateChangeTileState extends ConsumerState<StateChangeTile> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final p = ChromePalette.of(context);
    final entry = widget.entry;
    final selected = ref.watch(
      selectedStateChangeIdProvider.select((id) => id == entry.id),
    );
    final device = ref.watch(
      connectedDevicesProvider.select(
        (devices) =>
            devices.where((d) => d.deviceId == entry.deviceId).firstOrNull,
      ),
    );
    final look = ManagerLook.of(entry.stateManagerType);
    final accent = p.isDark ? ColorTokens.primaryLight : ColorTokens.primary;
    final diff = DiffSummary.of(entry.diff);
    final keys = entry.nextState.keys.toList();
    final detail =
        diff.onlyLine ??
        (diff.isEmpty
            ? (keys.isEmpty
                  ? 'No state reported'
                  : 'state: ${keys.take(8).join(', ')}')
            : diff.paths.take(6).join(' · '));
    final more = diff.isEmpty
        ? keys.length - 8
        : (diff.only == null ? diff.paths.length - 6 : 0);
    final muted = chromeMono(context, size: 11, color: p.textMuted);

    final body = Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 12, 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 20,
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      TagLabel(
                        icon: look.icon,
                        text: look.label.toUpperCase(),
                        color: look.ink(p.isDark),
                        fill: look.color.withValues(
                          alpha: p.isDark ? 0.16 : 0.12,
                        ),
                      ),
                      if (look.store case final store?) ...[
                        const SizedBox(width: 6),
                        Flexible(
                          child: TagLabel(
                            text: store,
                            color: p.textMuted,
                            fill: p.selected,
                            edge: p.border.withValues(alpha: 0.6),
                            mono: true,
                          ),
                        ),
                      ],
                      if (device != null) ...[
                        const SizedBox(width: 6),
                        Flexible(
                          child: SourceLabel(
                            platform: device.platform,
                            source: '${device.appName} · ${device.deviceName}',
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  _time.format(
                    DateTime.fromMillisecondsSinceEpoch(entry.timestamp),
                  ),
                  style: muted,
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 18,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    entry.actionName.isEmpty
                        ? '(no action name)'
                        : entry.actionName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: chromeMono(
                      context,
                      size: 12.5,
                      color: entry.actionName.isEmpty ? p.textMuted : p.text,
                      weight: FontWeight.w600,
                    ),
                  ),
                ),
                if (!diff.isEmpty) ...[
                  const SizedBox(width: 8),
                  _DiffCounts(diff: diff),
                ],
              ],
            ),
          ),
          const SizedBox(height: 5),
          SizedBox(
            height: 16,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    detail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: muted,
                  ),
                ),
                if (more > 0) Text('  +$more', style: muted),
              ],
            ),
          ),
        ],
      ),
    );

    var fill = p.surface;
    if (_hover) fill = Color.alphaBlend(p.hover, fill);
    if (selected) {
      fill = Color.alphaBlend(
        accent.withValues(alpha: p.isDark ? 0.12 : 0.08),
        fill,
      );
    }
    final edge = selected
        ? accent.withValues(alpha: 0.75)
        : _hover
        ? p.textMuted.withValues(alpha: 0.5)
        : p.border;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Semantics(
        button: true,
        selected: selected,
        label: '${look.label} ${entry.actionName}',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: widget.fresh ? 1 : 0, end: 0),
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
                Positioned.fill(child: body),
                Positioned(
                  left: 0,
                  top: 12,
                  bottom: 12,
                  width: 3,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: look.color,
                      borderRadius: const BorderRadius.horizontal(
                        right: Radius.circular(3),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// What a change added, changed and removed, as `+2 ~3 −1` pills; the
/// signs carry the meaning as well as the colors.
class _DiffCounts extends StatelessWidget {
  final DiffSummary diff;

  const _DiffCounts({required this.diff});

  @override
  Widget build(BuildContext context) {
    final p = ChromePalette.of(context);
    final parts = [
      if (diff.added > 0) ('+${diff.added}', p.success, '${diff.added} added'),
      if (diff.changed > 0)
        (
          '~${diff.changed}',
          p.isDark ? ColorTokens.warning : const Color(0xFF9A6700),
          '${diff.changed} changed',
        ),
      if (diff.removed > 0)
        (
          '−${diff.removed}',
          p.isDark ? ColorTokens.logError : const Color(0xFFCF222E),
          '${diff.removed} removed',
        ),
    ];
    return Tooltip(
      message: parts.map((x) => x.$3).join(' · '),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (i, (text, color, _)) in parts.indexed) ...[
            if (i > 0) const SizedBox(width: 4),
            Container(
              height: 18,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withValues(alpha: p.isDark ? 0.16 : 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                text,
                style: chromeMono(
                  context,
                  size: 10.5,
                  color: color,
                  weight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
