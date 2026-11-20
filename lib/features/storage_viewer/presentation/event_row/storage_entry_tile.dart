// Lucian UX/UI Prompt #072 · MIT License (c) 2026 Seokwoooo · https://lucianlabs.dev/uxui-prompt/#072
// Lucian UX/UI Prompt #227 · MIT License (c) 2026 Seokwoooo · https://lucianlabs.dev/uxui-prompt/#227
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../components/labels/source_label.dart';
import '../../../../components/labels/tag_label.dart';
import '../../../../core/theme/chrome_palette.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../models/storage/storage_entry.dart';
import '../../../../server/providers/server_providers.dart';
import '../shared/storage_preview.dart';
import '../shared/storage_tokens.dart';

final _time = DateFormat('HH:mm:ss.SSS');

/// One storage operation in the history, as its own card like the Console's
/// logs and the State Inspector's changes (Lucian #072): a 3px bar in the
/// operation's color, a row of labels — the operation, the storage and its
/// store, the platform with the app and device — with the time on the
/// right, then the key with the value's shape, and the value. One that just
/// arrived glows for a moment, like the new orders of Lucian #227.
class StorageEntryTile extends ConsumerStatefulWidget {
  final StorageEntry entry;
  final bool isSelected;
  final VoidCallback onTap;

  /// Whether the operation just arrived, so it glows.
  final bool fresh;

  const StorageEntryTile({
    super.key,
    required this.entry,
    required this.isSelected,
    required this.onTap,
    this.fresh = false,
  });

  @override
  ConsumerState<StorageEntryTile> createState() => _StorageEntryTileState();
}

class _StorageEntryTileState extends ConsumerState<StorageEntryTile> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final p = ChromePalette.of(context);
    final entry = widget.entry;
    final selected = widget.isSelected;
    final device = ref.watch(
      connectedDevicesProvider.select(
        (devices) =>
            devices.where((d) => d.deviceId == entry.deviceId).firstOrNull,
      ),
    );
    final op = entry.operation.toLowerCase();
    final opColor = storageOpColor(op);
    final typeColor = storageTypeColor(entry.storageType);
    final accent = p.isDark ? ColorTokens.primaryLight : ColorTokens.primary;
    final gone = entry.value == null && (op == 'delete' || op == 'clear');
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
                        icon: storageOpIcon(op),
                        text: op.toUpperCase(),
                        color: storageInk(opColor, p.isDark),
                        fill: opColor.withValues(alpha: p.isDark ? 0.16 : 0.12),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: TagLabel(
                          text: storageLabel(entry.storageType, entry.storeId),
                          color: storageInk(typeColor, p.isDark),
                          fill: typeColor.withValues(
                            alpha: p.isDark ? 0.16 : 0.12,
                          ),
                        ),
                      ),
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
                    entry.key.isEmpty ? '(no key)' : entry.key,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: chromeMono(
                      context,
                      size: 12.5,
                      color: entry.key.isEmpty ? p.textMuted : p.text,
                      weight: FontWeight.w600,
                    ),
                  ),
                ),
                if (entry.value != null) ...[
                  const SizedBox(width: 8),
                  Text(storageShapeOf(entry.value), style: muted),
                ],
              ],
            ),
          ),
          const SizedBox(height: 5),
          SizedBox(
            height: 16,
            child: Text(
              gone ? '—' : storageValuePreview(entry.value),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: muted,
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
        label:
            '${op.toUpperCase()} ${storageTypeName(entry.storageType)} '
            '${entry.key}',
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
                      color: opColor,
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
