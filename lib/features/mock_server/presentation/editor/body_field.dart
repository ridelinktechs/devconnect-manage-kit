import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/chrome_palette.dart';
import '../../../settings/presentation/shared/focus_ring.dart';
import '../shared/mock_look.dart';
import 'rule_draft.dart';

/// The response body as a code box: a strip that says whether it is JSON
/// and can indent it, over a mono text area. Discard flashes it amber, like
/// the other fields.
class BodyField extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final int flash;
  final bool flashing;

  const BodyField({
    super.key,
    required this.controller,
    required this.onChanged,
    this.flash = 0,
    this.flashing = false,
  });

  @override
  State<BodyField> createState() => _BodyFieldState();
}

class _BodyFieldState extends State<BodyField>
    with SingleTickerProviderStateMixin {
  static const _ease = Cubic(0.2, 0.8, 0.2, 1);

  final _focus = FocusNode(debugLabel: 'Response body');
  late final AnimationController _flash = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  );

  @override
  void initState() {
    super.initState();
    _focus.addListener(_repaint);
  }

  void _repaint() => setState(() {});

  @override
  void didUpdateWidget(BodyField old) {
    super.didUpdateWidget(old);
    if (widget.flash != old.flash &&
        widget.flashing &&
        !MediaQuery.disableAnimationsOf(context)) {
      _flash.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _focus.removeListener(_repaint);
    _focus.dispose();
    _flash.dispose();
    super.dispose();
  }

  void _format() {
    final pretty = prettyJsonOr(widget.controller.text);
    widget.controller.text = pretty;
    widget.onChanged(pretty);
  }

  @override
  Widget build(BuildContext context) {
    final p = ChromePalette.of(context);
    final text = widget.controller.text;
    final json = text.trim().isEmpty ? null : isJson(text);
    final canFormat = json == true && prettyJsonOr(text) != text;
    final focused = _focus.hasFocus;
    final (stateLabel, stateColor, stateIcon) = switch (json) {
      null => ('Empty', p.textMuted, LucideIcons.minus),
      true => ('JSON', p.success, LucideIcons.check),
      false => (
        'Not JSON, sent as text',
        p.isDark ? const Color(0xFFFDAA5E) : const Color(0xFF9A6700),
        LucideIcons.triangleAlert,
      ),
    };
    final small = DefaultTextStyle.of(
      context,
    ).style.copyWith(fontSize: 12, height: 1.2, fontWeight: FontWeight.w700);

    return AnimatedBuilder(
      animation: _flash,
      builder: (context, child) {
        final t = _flash.value;
        final glow = !_flash.isAnimating
            ? 0.0
            : (t < 0.25 ? t / 0.25 : (1 - t) / 0.75);
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              if (glow > 0)
                BoxShadow(
                  color: const Color(
                    0xFFF59E0B,
                  ).withValues(alpha: 0.6 * _ease.transform(glow)),
                  spreadRadius: 3,
                ),
            ],
          ),
          child: child,
        );
      },
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: p.codeBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: focused ? mockAccent(p.isDark) : p.border,
            width: focused ? 2 : 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 40,
              padding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: p.border.withValues(alpha: 0.6)),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    'Response body',
                    style: small.copyWith(color: p.textMuted),
                  ),
                  const SizedBox(width: 10),
                  Icon(stateIcon, size: 13, color: stateColor),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      stateLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: small.copyWith(color: stateColor),
                    ),
                  ),
                  const Spacer(),
                  _FormatButton(enabled: canFormat, onTap: _format),
                ],
              ),
            ),
            TextField(
              controller: widget.controller,
              focusNode: _focus,
              onChanged: widget.onChanged,
              minLines: 8,
              maxLines: 22,
              style: chromeMono(context, size: 12.5, color: p.text),
              cursorColor: mockAccent(p.isDark),
              decoration: const InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.fromLTRB(16, 14, 16, 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Format": indents the body when it is JSON that isn't indented yet.
class _FormatButton extends StatefulWidget {
  final bool enabled;
  final VoidCallback onTap;

  const _FormatButton({required this.enabled, required this.onTap});

  @override
  State<_FormatButton> createState() => _FormatButtonState();
}

class _FormatButtonState extends State<_FormatButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final p = ChromePalette.of(context);
    final color = _hover ? p.text : p.textMuted;
    final body = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: _hover ? p.hover : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: p.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.wandSparkles, size: 12, color: color),
          const SizedBox(width: 6),
          Text(
            'Format',
            style: DefaultTextStyle.of(context).style.copyWith(
              fontSize: 12,
              height: 1.2,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
    if (!widget.enabled) {
      return Opacity(opacity: 0.45, child: ExcludeFocus(child: body));
    }
    return Tooltip(
      message: 'Indent the JSON',
      child: FocusRing(
        onTap: widget.onTap,
        radius: 8,
        label: 'Format JSON',
        onHover: (v) => setState(() => _hover = v),
        child: body,
      ),
    );
  }
}
