// Lucian UX/UI Prompt #072 · MIT License (c) 2026 Seokwoooo · https://lucianlabs.dev/uxui-prompt/#072
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/chrome_palette.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../models/storage/storage_entry.dart';
import '../../../settings/presentation/shared/focus_ring.dart';
import '../shared/storage_tokens.dart';

const _spring = Cubic(0.34, 1.45, 0.64, 1);

/// The top of the storage detail panel, styled as an inline alert of Lucian
/// #072 like the Console's: a wash and a 3px bar in the operation's color,
/// its glyph on a solid tile, the operation and the storage, the key, then
/// when and where it happened.
class StorageDetailHeader extends StatelessWidget {
  final StorageEntry entry;

  /// "App · device" the operation came from, when that device is known.
  final String? source;
  final VoidCallback onCopy;
  final VoidCallback onCapture;
  final VoidCallback onCaptureValue;
  final VoidCallback onClose;

  const StorageDetailHeader({
    super.key,
    required this.entry,
    this.source,
    required this.onCopy,
    required this.onCapture,
    required this.onCaptureValue,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final p = ChromePalette.of(context);
    final loc = S.of(context);
    final c = storageOpColor(entry.operation);
    final l = c.computeLuminance();
    final onTile = 1.05 / (l + 0.05) >= (l + 0.05) / 0.067
        ? Colors.white
        : const Color(0xFF1F2328);
    final time = DateFormat(
      'yyyy-MM-dd HH:mm:ss.SSS',
    ).format(DateTime.fromMillisecondsSinceEpoch(entry.timestamp));
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
        decoration: BoxDecoration(
          color: Color.alphaBlend(c.withValues(alpha: 0.10), p.surface),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: c.withValues(alpha: 0.22)),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: -14,
              top: 0,
              bottom: 0,
              width: 3,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: c,
                  borderRadius: const BorderRadius.horizontal(
                    right: Radius.circular(3),
                  ),
                ),
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: c,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(
                    storageOpIcon(entry.operation),
                    size: 16,
                    color: onTile,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${entry.operation.toUpperCase()} · '
                        '${storageLabel(entry.storageType, entry.storeId)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.28,
                          color: p.text,
                        ),
                      ),
                      const SizedBox(height: 4),
                      SelectableText(
                        entry.key.isEmpty ? '(no key)' : entry.key,
                        minLines: 1,
                        maxLines: 2,
                        style: chromeMono(
                          context,
                          size: 12.5,
                          color: p.text,
                          weight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        [time, ?source].join('  ·  '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: chromeMono(
                          context,
                          size: 11.5,
                          color: p.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                _RoundButton(
                  icon: LucideIcons.copy,
                  label: loc.storageCopyValue,
                  tint: c,
                  onTap: onCopy,
                ),
                _RoundButton(
                  icon: LucideIcons.camera,
                  label: loc.captureFullTooltip,
                  tint: c,
                  onTap: onCapture,
                ),
                _RoundButton(
                  icon: LucideIcons.scanLine,
                  label: loc.captureTabTooltip,
                  tint: c,
                  onTap: onCaptureValue,
                ),
                _RoundButton(
                  icon: LucideIcons.x,
                  label: loc.close,
                  tint: c,
                  onTap: onClose,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A 28px round action: washes in the operation's color on hover and
/// squeezes a little when pressed.
class _RoundButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color tint;
  final VoidCallback onTap;

  const _RoundButton({
    required this.icon,
    required this.label,
    required this.tint,
    required this.onTap,
  });

  @override
  State<_RoundButton> createState() => _RoundButtonState();
}

class _RoundButtonState extends State<_RoundButton> {
  bool _hover = false;
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final p = ChromePalette.of(context);
    return Tooltip(
      message: widget.label,
      child: Listener(
        onPointerDown: (_) => setState(() => _down = true),
        onPointerUp: (_) => setState(() => _down = false),
        onPointerCancel: (_) => setState(() => _down = false),
        child: AnimatedScale(
          scale: _down ? 0.85 : 1,
          duration: const Duration(milliseconds: 300),
          curve: _spring,
          child: FocusRing(
            onTap: widget.onTap,
            radius: 14,
            label: widget.label,
            onHover: (v) => setState(() => _hover = v),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _hover
                    ? widget.tint.withValues(alpha: 0.14)
                    : Colors.transparent,
              ),
              child: Icon(
                widget.icon,
                size: 14,
                color: _hover ? p.text : p.textMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
