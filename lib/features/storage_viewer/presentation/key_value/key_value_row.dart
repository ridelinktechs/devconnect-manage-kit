import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../components/labels/tag_label.dart';
import '../../../../core/theme/chrome_palette.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../settings/presentation/shared/focus_ring.dart';
import '../../provider/storage_snapshot_providers.dart';
import '../shared/storage_tokens.dart';

/// One key of a store as a table row: the key, its value on one line and its
/// type, then edit and delete, which light up while the row is hovered.
/// Double-clicking the row edits too.
class KeyValueRow extends StatefulWidget {
  final String entryKey;
  final Object? value;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const KeyValueRow({
    super.key,
    required this.entryKey,
    required this.value,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<KeyValueRow> createState() => _KeyValueRowState();
}

class _KeyValueRowState extends State<KeyValueRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final p = ChromePalette.of(context);
    final loc = S.of(context);
    final text = storageValueText(widget.value);
    final (kind, color) = storageValueKind(widget.value);
    final accent = p.isDark ? ColorTokens.primaryLight : ColorTokens.primary;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 40,
        padding: const EdgeInsets.only(left: 12, right: 6),
        decoration: BoxDecoration(
          color: _hover ? p.hover : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            // Off the buttons: a double-tap detector holds taps back ~300ms.
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onDoubleTap: widget.onEdit,
                child: Row(
                  children: [
                    SizedBox(
                      width: 240,
                      child: Text(
                        widget.entryKey,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: chromeMono(
                          context,
                          size: 12,
                          color: accent,
                          weight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Tooltip(
                        message: text.length > 80 ? text : '',
                        waitDuration: const Duration(milliseconds: 500),
                        child: Text(
                          text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: chromeMono(
                            context,
                            size: 12,
                            color: widget.value == null ? p.textMuted : p.text,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    TagLabel(
                      text: kind,
                      color: storageInk(color, p.isDark),
                      fill: color.withValues(alpha: p.isDark ? 0.16 : 0.12),
                      mono: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 6),
            _RowAction(
              icon: LucideIcons.pencil,
              label: loc.storageKvEdit,
              lit: _hover,
              onTap: widget.onEdit,
            ),
            _RowAction(
              icon: LucideIcons.trash2,
              label: loc.storageKvDelete,
              lit: _hover,
              danger: true,
              onTap: widget.onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

/// A 28px round action at the end of a row: faint until the row is
/// hovered, washed on its own hover, in red when it deletes.
class _RowAction extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool lit;
  final bool danger;
  final VoidCallback onTap;

  const _RowAction({
    required this.icon,
    required this.label,
    required this.lit,
    this.danger = false,
    required this.onTap,
  });

  @override
  State<_RowAction> createState() => _RowActionState();
}

class _RowActionState extends State<_RowAction> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final p = ChromePalette.of(context);
    final ink = widget.danger ? ColorTokens.error : p.text;
    return Tooltip(
      message: widget.label,
      child: FocusRing(
        onTap: widget.onTap,
        radius: 14,
        label: widget.label,
        onHover: (v) => setState(() => _hover = v),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _hover ? ink.withValues(alpha: 0.12) : Colors.transparent,
          ),
          child: Icon(
            widget.icon,
            size: 13,
            color: _hover
                ? ink
                : p.textMuted.withValues(alpha: widget.lit ? 1 : 0.6),
          ),
        ),
      ),
    );
  }
}
